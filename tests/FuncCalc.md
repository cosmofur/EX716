# FuncCalc Language Guide

FuncCalc is a small, interactive, expression-oriented language implemented in
EX716 assembly. It supports signed 32-bit integer arithmetic, strings,
variables, reusable statement lists, and user-defined functions.

## Starting FuncCalc

Run the same source with either the original CPU or the experimental segmented
CPU24 runtime:

```sh
python3 cpu.py tests/FuncCalc.asm
python3 cpu24.py tests/FuncCalc.asm
```

FuncCalc displays an `FC>` prompt. Enter `HELP` for a short command summary and
`QUIT` or `EXIT` to leave.

## Values and identifiers

FuncCalc currently has these user-visible value types:

- Signed 32-bit integers
- Strings
- Stored statement lists
- User-defined functions

Integer literals are decimal. Negative values are formed with unary `-`.
Strings are enclosed in double quotes. String escape sequences are not
currently implemented.

Names begin with a letter or underscore. Remaining characters may contain
letters, digits, underscores, or `$`. Keep the spelling and case of user names
consistent. Commands and built-in function names may be entered in upper- or
lowercase, although the examples use uppercase.

Examples:

```text
COUNT=12
offset_2=-7
GREETING="Hello"
TOTAL$="42"
```

Assigning a new value to an existing name replaces its old value.

## Expressions

The arithmetic operators, from highest to lowest precedence, are:

1. Parentheses and function calls
2. Unary negation: `-value`
3. Multiplication, division, and remainder: `*`, `/`, `%`
4. Addition and subtraction: `+`, `-`
5. Signed comparisons: `<`, `<=`, `>`, `>=`
6. Logical AND: `&&`
7. Logical OR: `||`

Comparisons and logical operators return integer `1` for true and `0` for false. Logical operands use zero as false and any nonzero integer as true.

All arithmetic uses signed 32-bit integers. Arithmetic operators do not
concatenate strings. Division or remainder by zero reports an error.

```text
PRINT 2+3*4
PRINT (2+3)*4
PRINT -12/5
PRINT 17%5
PRINT 10 >= 2
PRINT 1 < 2 && 3 < 4
PRINT 0 || 7

A=100
B=A/4+3
PRINT B
```

An expression may also appear by itself. Its result is evaluated and then
discarded.

## Statements

Multiple statements can be entered on one line by separating them with
semicolons. Semicolons inside a string or parenthesized expression do not split
the line.

```text
A=10; B=20; PRINT A+B
```

### Assignment

```text
name=expression
```

The expression may produce an integer or string. Stored lists and functions are
created with `LIST` and `DEFUN` rather than ordinary assignment.

New names created by assignment are global. Inside a function, parameters are
implicitly local and assignment to a parameter updates that local value. Use
`LOCAL` to create another name in the current function frame:

```text
LOCAL temporary=expression
```

`LOCAL` outside a function reports an error. A `BLOCK` uses the current frame,
so its unmarked assignments are global unless they update an existing local or
parameter; `LOCAL` explicitly creates a local name.

### Printing

Both forms below are accepted:

```text
PRINT expression
PRINT(expression)
```

Examples:

```text
PRINT 40+2
PRINT "hello"
PRINT STR$(2026)
```

### Ending the session

```text
QUIT
EXIT
```

## Built-in functions

### `ABS(value)`

Returns the absolute value of one integer.

```text
PRINT ABS(-17)
```

### `MIN(value, ...)`

Returns the smallest of one or more integer arguments.

```text
PRINT MIN(8,-3,12,4)
```

### `LEN(string)`

Returns the number of characters in a string.

```text
NAME="Ada"
PRINT LEN(NAME)
```

### `VAL(string)`

Converts a decimal string to a signed 32-bit integer.

```text
N=VAL("1234")
PRINT N+1
```

### `STR$(integer)`

Converts an integer to a decimal string.

```text
TEXT=STR$(-716)
PRINT TEXT
```

### `SPLIT(string, start, stop)`

Returns a substring using inclusive, one-based indexes. `start` must be at
least 1. A stop position beyond the end of the string is clipped to the string
length. Invalid or reversed ranges return an empty string.

```text
PRINT SPLIT("EX716 computer",1,5)
PRINT SPLIT("abcdef",2,4)
```

### `INPUT([prompt])`

Reads one line from the console and returns it as a string. The optional
prompt must be a string and is printed without adding a newline.

```text
NAME=INPUT("Name: ")
PRINT NAME
```

### `INPUTINT([prompt])`

Reads one line from the console and converts it to a signed 32-bit integer.
The optional prompt must be a string and is printed without adding a newline.

```text
COUNT=INPUTINT("Count: ")
PRINT COUNT+1
```

### `GETKEY([wait])`

Reads one character without echo and returns it as a one-character string.
With no argument, or with a nonzero numeric argument, `GETKEY` waits for a
key. With a zero argument it polls and returns an empty string when no key is
ready. `TRUE` and `FALSE` can be used for clarity. Interactive polling depends
on raw terminal mode; call `TTYRAW()` once before a polling loop and restore
the terminal afterward with `TTYCOOKED()`.

```text
KEY=GETKEY()
KEY=GETKEY(TRUE)
KEY=GETKEY(FALSE)
```

### `TTYRAW()` and `TTYCOOKED()`

`TTYRAW()` puts the terminal into raw, no-echo mode for responsive calls to
`GETKEY(FALSE)`. The setting persists instead of being toggled for every key
poll. `TTYCOOKED()` restores cooked input and echo.

```text
TTYRAW()
WHILE(TRUE,{KEY=GETKEY(FALSE); IF(KEY="Q",BREAK,COMMENT("no key"))})
TTYCOOKED()
```

### `IF(condition, true-expression, false-expression)`

Evaluates the numeric condition and then evaluates only the selected branch.
Zero is false and a nonzero integer is true. Because `IF` is lazy, the branch
not selected has no side effects.

```text
PRINT IF(1,"yes","no")
PRINT IF(0,10/0,42)
```

### `BLOCK(statement; ...)`

Executes a semicolon-separated statement block in the current variable frame.
It is lazy: the statements are executed by `BLOCK`, rather than evaluated as
ordinary function arguments.

```text
BLOCK(A=5; B=A*2; PRINT B)
```

`RETURN` is primarily intended for user-defined functions. A return stops the
remaining statements in the current compiled block.

Braces are an alternate spelling of `BLOCK(` and its closing `)`:

```text
{ A=5; B=A*2; PRINT B }
```

This has the same execution and scope rules as
`BLOCK(A=5; B=A*2; PRINT B)`.

A brace block may also span input lines; FuncCalc uses the continuation prompt
until the closing brace:

```text
{
A=5
B=A*2; PRINT B
}
```

### `WHILE(test, statement; ...)`

Repeatedly evaluates the numeric test and executes the statement body while it
is nonzero. The body is compiled once and may contain semicolon-separated
statements.

```text
I=0
WHILE(I<5,I=I+1; PRINT I)
```

### `FOR({initialize}, test, {statement; ...})`

Executes the initialization block once, evaluates the numeric test before each
iteration, and executes the body while the test is nonzero. The entire loop is
written inline; it does not use a separate definition/end structure.

```text
FOR({I=0},I<5,{I=I+1; PRINT I})
```

Initialization and body blocks are compiled once. Assignments follow the same
scope rules as `BLOCK`: existing parameters and explicit `LOCAL` names remain
local, while previously unknown names are global. `RETURN`, `BREAK`, nested
`BREAK(depth)`, and `CONTINUE` use the same behavior as in `WHILE`.

`CONTINUE` skips the remaining statements in the current loop body. `BREAK`
exits the current loop. `BREAK(depth)` exits the requested number of nested
loops, where the default depth is one:

```text
I=0
WHILE(I<10,I=I+1; IF(I>=5,BLOCK(BREAK),0); PRINT I)
```

```text
WHILE(1,WHILE(1,BREAK(2)))
```

`BREAK` and `CONTINUE` outside an active `WHILE` or `FOR` report an error. A
break depth must be positive and cannot exceed the current loop nesting depth.

### `SWITCH(value, case, statement, ..., default)`

Evaluates `value` once, then evaluates case expressions in order. The statement
or brace block belonging to the first equal case is executed. If no case
matches, the final statement or block is executed as the default. Unselected
statements are lazy and have no side effects.

```text
SWITCH(1,
       1, PRINT "one",
       2, {PRINT "two"; PRINT X},
       PRINT "default")
```

Selectors and cases may be numeric or string expressions. `TRUE` and `FALSE`
are numeric constants `1` and `0`, allowing a switch to replace an `ELSE IF`
tree:

```text
COW="COW"
SWITCH(TRUE,
       1>X,       {PRINT "X<1"},
       10>X,      {PRINT "X<10"},
       ANIMAL=COW,{PRINT "Its a cow"},
       PRINT "Nothing fit")
```

Numeric and string equality accept `=` or `==`; inequality uses `!=`.

### `COMMENT(value, ...)`

Accepts and discards its arguments. It is useful for attaching metadata or
notes to stored code without changing the result.

```text
COMMENT("calculate invoice total",2026)
```

## Stored statement lists

`LIST` compiles statements and stores them under a name. `EXEC` runs the stored
list later.

```text
LIST REPORT=A=7; B=A*6; PRINT B
EXEC REPORT
```

The list retains compiled statements, not merely the final result. Variables
are resolved when the list executes, so a list can use values assigned after
the list was created.

```text
LIST SHOW=PRINT VALUE
VALUE=10
EXEC SHOW
VALUE=25
EXEC SHOW
```

## User-defined functions

Begin a definition with `DEFUN name(parameters)`. FuncCalc changes to the
`...` continuation prompt until an `ENDDEF` line is entered.

```text
DEFUN DOUBLE(X)
RETURN X*2
ENDDEF
```

Parameters are implicitly stored in a local frame. A function can read global
variables, and assignments to parameter or explicitly `LOCAL` names remain in
its current frame. Assigning a previously unknown name creates a global.
Arguments are evaluated before the function is invoked. The number of supplied
arguments must exactly match the parameter count.

Functions can be called directly in expressions:

```text
PRINT DOUBLE(21)
ANSWER=DOUBLE(10)+1
```

`CALLFUNC` is an interactive command that invokes a function and prints a
returned integer or string:

```text
CALLFUNC DOUBLE(9)
```

Use `RETURN expression` to produce a value and stop the remaining function
body. A function that reaches its end without `RETURN` has no value.

A longer example:

```text
DEFUN SMALLER(A,B)
RETURN IF(A-B,MIN(A,B),A)
ENDDEF

PRINT SMALLER(12,7)
```

Use `LISTFUNC` to inspect a stored function's parameters and compiled body:

```text
LISTFUNC DOUBLE
```

## Variables and memory commands

### `MEMVAR`

Lists active global variables and, while a function is running, its local
variables.

### `MEM`

Displays variable-table counts, available heap memory, variables, and the heap
object map.

### `CLEAN name`

Deletes one variable and releases its owned value:

```text
CLEAN TEMP
```

### `CLEAN`

Deletes all active variables, stored lists, and functions:

```text
CLEAN
```

### `DEBUG ON` and `DEBUG OFF`

Enable or disable FuncCalc's parser and function-call diagnostics.

## Example sessions

### Unit conversion

```text
FC> DEFUN FTOC(F)
... RETURN (F-32)*5/9
... ENDDEF
OK
FC> PRINT FTOC(77)
25
```

### String extraction

```text
FC> RECORD="EX716:READY"
FC> MODEL=SPLIT(RECORD,1,5)
FC> STATE=SPLIT(RECORD,7,LEN(RECORD))
FC> PRINT MODEL
EX716
FC> PRINT STATE
READY
```

### Reusable calculation

```text
FC> LIST TOTAL=SUBTOTAL=1250; TAX=SUBTOTAL*7/100; PRINT SUBTOTAL+TAX
OK
FC> EXEC TOTAL
1337
```

## Current limitations

- Arithmetic operators accept integers only; strings are not concatenated.
- String literals do not support escape sequences.
- Integer literals are decimal only.
- FuncCalc is an experimental interpreter and reports most language failures
  as `ERR ...` messages rather than recovering with structured exceptions.
