# EX716 Macro System Tutorial and Reference

This guide introduces the macro system used by the EX716 assembler. It is designed both as a practical tutorial for beginners and a technical reference for experienced users.

---

## 1. What Are Macros?

Macros in EX716 are **purely compile-time constructs**. Think of them as instructions given to a very fast assistant ("a trained imp") who rewrites parts of your source code by pasting in other bits of source text before the assembler sees it.

At runtime, macros no longer exist. Their expansions are hard-coded into your program as if you had typed them by hand.

---

## 2. Basic Macro Expansion and `%` Parameters

Macros can be defined using the `M` directive:

```asm
M EXAMPLE_PUSH %1 \
  PUSH %1
```

When you call this macro:

```asm
@EXAMPLE_PUSH $1234
```

It expands into:

```asm
PUSH $1234
```

### `%1` to `%9`

You can use up to 9 positional parameters. `%1` is replaced with the first argument, `%2` with the second, and so on.

### `%0`: The Unique Token

Every macro expansion gets a unique `%0` token that is **different each time the macro is used**. This makes it useful for generating unique labels or identifiers:

```asm
M SAFEJUMP \
  JMP safe_exit_%0 \
: safe_exit_%0
```

Each time `@SAFEJUMP` is used, it creates a new label like `safe_exit_42`, `safe_exit_43`, etc.

This is essential for macros that generate jump labels or temporary data blocks to avoid collisions.

---

## 3. `%S`, `%V`, `%P`, and `%W`: Scoped Message Passing

These special macro variables allow macros to **communicate with each other** across different layers of nested macro structures.

| Symbol | Meaning / Use Case                                                                  |
| ------ | ----------------------------------------------------------------------------------- |
| `%S`   | Saves the current `%0` to the macro stack so later macros can access it             |
| `%V`   | The most recent value saved with `%S`; can be reused multiple times like `%0`       |
| `%P`   | Pops or drops the current `%V` so the previous `%S` becomes active again            |
| `%W`   | Accesses the previous `%V` without removing the current one (like a stack SFT peek) |

### Special Commands

| Command       | Meaning                                                      |
| ------------- | ------------------------------------------------------------ |
| `%STRLEN val` | Calculates the character length of the expanded string `val` |
| `%%LEN`       | Replaced with the number last calculated by `%STRLEN`        |

---

### Advanced Macro Example

This macro inserts a structure in memory that looks like a linked list and creates labels to track both the data and the list node:

```asm
MF LINK 0
M DEFWORD :Word_%2 \
           @LINK MF LINK_%2 \
           %STRLEN %1 \
           $$%3+%%LEN \
           $1 \
           :%2
```

Example call at memory location `0x1400`:

```asm
@DEFWORD "Hello Text" DataStart 0x80
```

Resulting memory layout:

```
Address   | Contents
----------|----------------------------------------
0x1400    | LINK pointer (initially 0)
0x1402    | Flag byte = 0x80 + 10 = 0x8A
0x1403    | "Hello Text"
```

* `Macro LINK` becomes `Word_DataStart`
* `Word_DataStart` = `0x1400`
* `DataStart` = `0x140F`

In a control macro like `@IF_ZERO`, `%S` might be set to "IF" and `%V` to a unique ID. The `@ELSE` and `@ENDIF` macros reference those to ensure correct nesting.

---

## 4. Macro Scope and Overwriting

Macros can be **redefined multiple times** within a source file. The most recent definition takes precedence:

```asm
MF MODE safe
... some code using @MODE
MF MODE debug
... later code using @MODE
```

This lets macros act like scoped configuration or control flags, much like global variables in scripts.

> **Note:** This behavior is **linear** and based on **file order**. The last definition before usage is applied.

---

## 5. Conditional Blocks: `?` and `!`

Conditional macro blocks allow selective inclusion of code depending on macro definitions.

### Syntax

```asm
! MACRO_NAME
  ... code included only if MACRO_NAME is NOT defined
ENDBLOCK

? MACRO_NAME
  ... code included only if MACRO_NAME IS defined
ENDBLOCK
```

### Use Case

Prevent duplicate library loading:

```asm
! LOADED_STRUCTURE_LIB
  I structure.mc
  MF LOADED_STRUCTURE_LIB true
ENDBLOCK
```

---

## 6. `MF` vs. `M`: Macro Values vs. Macro Code

* `M` defines **multi-line macro code blocks** (lines must end in `\`, except the last).
* `MF` defines **single-word flags or values** and is ideal for macro logic or toggles.

### Example Use of `MF`

```asm
MF DEBUG true
? DEBUG
  P "Debug Mode Active {DEBUG}"
ENDBLOCK
```

The macro system will substitute `{DEBUG}` with `true`.

### Use in structured macros

```asm
MF _%V_ElseFlag true
```

Used by `@ENDIF` to check if `@ELSE` was triggered in the same block.

### Clearing a Macro

```asm
MF DEBUG ""    # Clears DEBUG by assigning it an empty value
```

---

## Summary

* Macros expand at assembly time; they don’t exist at runtime.
* `%1`–`%9` are positional parameters; `%0` is a unique label ID.
* `%S`, `%V`, `%P`, `%W` provide scoped, stack-like coordination.
* Macros can be redefined as needed; the last definition applies.
* `?` and `!` blocks support conditional logic.
* `MF` is used for setting short macro flags and messages.
* `M` defines full macro text blocks using continuation (`\`).

---

For more examples, study the included `common.mc` and `structures.ld` files in the EX716 toolkit.
