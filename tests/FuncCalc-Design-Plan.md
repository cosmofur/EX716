# FuncCalc Design Plan

This document is the standing architectural roadmap for FuncCalc. It should be
consulted before making major language or runtime changes in later sessions.

## Current direction and decisions still needed

CPU24 is the supported target; `FuncCalc.asm` forwards to `FuncCalc24.asm`.
String concatenation is implemented. A pseudo-terminal regression starter is
`python3 tests/test_funccalc24.py` (add `--fast` for the native engine); both
pass arithmetic, string, INPUT, INPUTINT and WRITE checks. Cover both execution
engines, arithmetic, string ownership, INPUT/INPUTINT, WRITE, GETKEY and TTY
restoration, nested calls, error recovery, and repeated cleanup. The separate
`cpu24-string-regression.asm` currently exposes a `strtok` stack underflow on
the final token when the input has no trailing delimiter.

### Ownership options

1. Parent-owned arenas: each call allocates temporaries in an arena owned by
   its caller. The caller supplies a result slot; returning a value copies it
   into that slot. Persistent mutations allocate in the destination owner's
   arena. Reset an arena only after all borrowers are finished.
2. Reference-counted shared values: calls retain and release shared heap
   objects, and returning a value transfers or retains a reference. This makes
   sharing straightforward but needs a policy for cycles in mutable lists.
3. Hybrid: parent-owned call temporaries and result slots, with separately
   owned, reference-counted long-lived mutable objects. Explicitly copy or
   promote values when they escape a call; define cycle handling before lists
   can contain themselves.

The parent-owned approach fits the intended rule, but requires an explicit
owner for global assignments, function definitions and mutations, plus a rule
for aliases and recursive calls. Parent-owned does not imply allocating every
value on the hardware or software stack. Allocation failure and rollback must
also be specified. The existing string borrowing flags and function reference
counts are implementation details to migrate, not yet this contract.

### Executable lists and functions

A code list can be a typed, validated object with a magic/version header and
an ordered sequence of statements. A function can be either (a) a distinct
descriptor containing parameters and a reference to such a code list, or (b)
one executable list whose header also records its parameters and calling
convention. Both support runtime function generation if constructors validate
the header, representation, ownership and parameter names. The descriptor
keeps ordinary data lists separate from executable objects; the unified form
is simpler to inspect and construct, but mutable code needs rules for active
calls and invalid or forged headers. A magic number alone is not sufficient
type, bounds, lifetime or integrity validation. Decide whether generated code
contains source strings or compiled statements, and whether editing code while
it is executing is prohibited, copied, or versioned.

### Error recovery

Centralize error reporting and establish a recovery checkpoint at a REPL
command boundary. Record the software-stack position and scope/cleanup marks,
active frames, expression temporaries, loop and return state, segment/address
mode, and terminal mode. A handler must release or roll back owned resources
before restoring the checkpoint, then return to a known REPL continuation.
`SCLR` clears the hardware stack; `SRPT` reports its depth and can check a
boundary, but neither restores prior contents or unwinds the separate software
stack. An unconditional `SCLR` inside an ordinary call destroys return
addresses, so a nonlocal recovery path must jump to a checkpoint rather than
return through abandoned frames. Define how allocation failures and errors
during cleanup behave before converting the existing error sites.

## Recommended development order

1. Formalize the Value model.
2. Turn LIST into a real general-purpose collection.
3. Make functions genuinely first-class.
4. Introduce explicit execution contexts.
5. Build cofunctions, `YIELD`, and `RESUME` on those contexts.
6. Expand the standard library coherently.
7. Add further language syntax and sugar.

One small feature should come early: string concatenation, because it will be
useful while developing everything else.

## 1. Make LIST a real data structure

This is the first user-visible priority.

`LIST` currently has an unfortunate double meaning. From the language user's
perspective:

```text
LIST FOO=A=1; B=2; PRINT A+B
EXEC FOO
```

means “compile this sequence of statements and store it.” Internally, FuncCalc
already has a general pointer-list implementation:

```text
FCListNew
FCListAppend
FCListGet
FCListFree
FCListFreeItems
```

Separate these concepts before extending the language much further:

```text
LIST       = general language collection
CODE       = compiled executable statement list
FUNCTION   = parameter list + CODE
```

The language could then support operations such as:

```text
A=LIST(10,20,30)
PRINT LEN(A)
PRINT GET(A,2)

A=APPEND(A,40)
SET(A,2,99)
```

The runtime type model should become:

```text
Value
 ├── I32
 ├── STRING
 ├── LIST
 ├── FUNCTION
 └── CODE
```

Avoid independently adding arrays, tuples, dictionaries, and structures unless
there is a demonstrated need. Lua's success with one capable aggregate type is
a useful model. Eventually a LIST should be able to contain arbitrary Values:

```text
X=LIST(10,"HELLO",OTHERLIST,SOMEFUNCTION)
```

This would substantially increase expressive power without substantially
increasing language complexity.

## 2. Formalize the Value abstraction

The implementation is already partway there. It has:

```text
FC_TYPE_EMPTY
FC_TYPE_I32
FC_TYPE_STR
FC_TYPE_LIST
FC_TYPE_FUNC
```

and heap value objects containing type and payload information.

Make this rule explicit:

> Everything that can be stored, passed, returned, or placed in a list is a
> FuncCalc Value.

Centralize operations conceptually equivalent to:

```text
ValueCopy()
ValueRetain()
ValueRelease()
ValueEqual()
ValueTruth()
ValuePrint()
```

Individual features should not each implement their own understanding of
strings, functions, and lists. With a central Value abstraction, future types
such as `COFUNCTION`, `CODE`, `FILE`, and `MAP` can be added without invasive
changes throughout the interpreter.

This is especially important because temporary strings and expression cleanup
already introduce ownership complexity. Centralizing lifetime rules now should
prevent much greater difficulty later.

## 3. Make functions genuinely first-class

This is the largest language capability to add before cofunctions.

FuncCalc already has `FC_TYPE_FUNC`, reference-counted function objects, and
function values stored in variable slots. The language still restricts their
creation and use, however. Move toward:

```text
DEFUN DOUBLE(X)
    RETURN X*2
ENDDEF

F=DOUBLE
PRINT F(10)
```

Anonymous functions could eventually use syntax such as:

```text
FUNCTION(X,{ RETURN X*2 })
```

Closures are not required initially. The important rule is to make
`function -> Value` completely true. Lists can then contain functions:

```text
OPS=LIST(ADD,SUBTRACT,MULTIPLY)
```

and facilities such as `MAP(values,function)` can be built without inventing a
separate execution mechanism.

## 4. Design cofunctions around suspended execution

Do not implement cofunctions as a special case of `WHILE`. Establish the
runtime model first.

A normal call is conceptually:

```text
CALL
  ↓
create frame
  ↓
execute statements
  ↓
RETURN
  ↓
destroy frame
```

A cofunction is:

```text
CALL
  ↓
create frame
  ↓
execute
  ↓
YIELD
  ↓
preserve frame, instruction position, locals, and execution state
  ↓
RESUME
  ↓
continue
```

The difficult part is not `YIELD`; it is making execution resumable. Compiled
statements are already linked objects, which is promising. Replace implicit
execution state with an explicit structure:

```text
ExecutionContext
    current_statement
    frame
    function
    parent_context
    state
```

`YIELD` can then stop advancement of `current_statement` while preserving the
context.

Possible eventual syntax:

```text
COFUN COUNT()
    LOCAL I=0
    WHILE(TRUE,{
        YIELD I
        I=I+1
    })
ENDCO

C=COUNT()

PRINT RESUME(C)
PRINT RESUME(C)
PRINT RESUME(C)
```

This should produce:

```text
0
1
2
```

Build execution-context machinery first; expose `COFUN`, `YIELD`, and `RESUME`
only afterward.

## 5. Resolve expression versus statement semantics

Make an explicit language-design decision about the boundary between
expressions and statements.

The runtime currently has `FC_STMT_EXPR`, while special lazy constructs look
like functions:

```text
IF(...)
BLOCK(...)
WHILE(...)
FOR(...)
SWITCH(...)
```

Standalone expressions are also allowed as statements, with their values
discarded. Decide and document which control constructs return values.

For example:

```text
X=IF(C,10,20)
```

clearly fits the language. Consider whether these should also return values:

```text
X=BLOCK(A=10; A+5)

X=SWITCH(A,
         1,10,
         2,20,
         0)
```

The initial recommendation is:

- `IF` and `SWITCH` should return values.
- `BLOCK`, `WHILE`, and `FOR` should remain statement/control-oriented unless
  a compelling use case appears.

This preserves FuncCalc's hybrid nature without making everything an
expression solely for theoretical elegance.

## 6. Build a small, coherent standard library

Once the runtime abstractions are stable, add a focused library rather than a
large collection of unrelated functions. The current library includes `ABS`,
`MIN`, `LEN`, `VAL`, `STR$`, `SPLIT`, input/key functions, and TTY controls.

Suggested additions, in approximate order:

| Area | Additions |
|---|---|
| Strings | `CONCAT`, `FIND`, `LEFT$`, `RIGHT$`, `UPPER$`, `LOWER$`, `TRIM$` |
| Math | `MAX`, `SIGN`, `MOD`, `POW`, perhaps `RND` |
| Lists | `LIST`, `LEN`, `GET`, `SET`, `APPEND`, `INSERT`, `DELETE` |
| Types | `TYPE`, perhaps `ISINT`, `ISSTR`, `ISLIST`, `ISFUNC` |
| Conversion | Existing `VAL`, `STR$`, perhaps character/ASCII conversion |
| Functions | First-class function invocation |
| Runtime | Eventually `COFUN`, `RESUME`, `YIELD`, `DONE` |

Do not add floating point unless the EX716 provides a compelling reason. A
clean 32-bit-integer language fits the machine well.

Add string concatenation early. Operator overloading with `+` is preferable if
it can remain clear and reliable:

```text
PRINT "X="+STR$(X)
```

Otherwise provide `CONCAT("HELLO ","WORLD")`.

## 7. Improve error handling before the library becomes large

FuncCalc currently reports most failures as `ERR ...`. Structured exceptions
are not necessarily required, but the runtime should have a central error
object or state containing at least:

```text
error code
source line
source position
message
current function
```

Nested calls will otherwise make failures difficult to diagnose. Aim for
messages of this general form:

```text
ERR: SPLIT: argument 2 must be integer
  in function PARSE at line 7
  called from MAIN at line 23
```

The `DEFUN` collector already inserts `COMMENT(0)` metadata while constructing
function bodies. Use that existing direction for source and debugging metadata
rather than attaching debugging information much later.

## Architectural relationship

```text
                  VALUE
                    │
       ┌────────────┼─────────────┐
       ↓            ↓             ↓
     STRING        LIST        FUNCTION
                                  │
                                  ↓
                         Execution Context
                                  │
                          ┌───────┴───────┐
                          ↓               ↓
                     normal call      COFUNCTION
                                          │
                                     YIELD/RESUME
```

If these foundational abstractions are correct, `MAP`, callbacks, cooperative
tasks, generators, event loops, and richer collections become combinations of
existing mechanisms instead of special cases in a large assembly interpreter.
As `FuncCalcCore.asm` approaches 6,000 lines, strong internal abstractions are
likely to provide more value than another twenty isolated built-ins.
