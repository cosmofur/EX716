
# EX716 Assembler - Lesson 5: Style Guidelines and Library Design

## 🧭 Overview

This chapter introduces best practices for writing readable, modular, and reusable EX716 code. We’ll cover two key topics:

1. **Assembler Coding Style** – conventions for function layout, indentation, and control flow blocks.  
2. **Library Files** – how to encapsulate logic, safely reuse code, and avoid label collisions using the `L`, `!`, and `G` features.

---

## 📦 Library Files vs. Include Files

### `L` – Library Files

Library files are included using the `L` directive and are meant to behave more like *modules* or *namespaces* in high-level languages. They support:

- **Automatic label mangling**: All labels in a library are internally renamed to avoid collisions unless marked as global.
- **Private state**: Locals in the library are inaccessible to outside code unless exposed via `G`.
- **One-time loading**: Use `!` guards to ensure libraries are only loaded once, even with nested includes.

> Library search paths are defined by the `CPUPATH` environment variable, and library files should be placed accordingly.

### `I` – Include Files

In contrast, `I` files are raw includes. Every label or macro is inserted verbatim into the current scope. You can use them for small macro or constant headers, but avoid using them for shared code logic unless you want to risk name collisions.

---

## 🧰 Building a Library File

Here’s a pattern for a safe and reusable library file:

```asm
! MY_LIBRARY_GUARD          ; Prevent double-inclusion
M MY_LIBRARY_GUARD true     ; Mark as already loaded

G myfunc G sharedvar        ; Expose public functions/variables

; Body of library begins here

:myfunc
  ; Do something useful

ENDBLOCK                    ; Closes the conditional block started by !
```

---

## 🔒 Global (`G`) and Local Labels

- Every label is considered **local** unless explicitly exported via `G`.
- `G` declarations must come **before the label is used**, or the label will be auto-mangled.
- Think of `G` like a `public` keyword in other languages.

---

## 🪛 Overriding Global Functions

You can override a library's global function in the main file by simply redefining it:

```asm
G myfunc

; Save the old one
:myfunc_original
  ; ... call original logic

:myfunc
  ; Custom behavior
  @CALL myfunc_original
```

This works because the original `G` value is available *until* your redefinition shadows it further down the file.

---

## 🧼 Function Style Guide

While EX716 doesn’t enforce function semantics, here’s a recommended structure:

```asm
##################################################
# Function: DoSomething(param1, param2)
:DoSomething
@PUSHRETURN               ; Save return address
@LocalVar 01#             ; Local variable (acts like a register)
@LocalVar 02#

   @POPI param1
   @POPI param2

   @IF_A
      @PUSH "Valid"
   @ELSE
      @PUSH "Invalid"
   @ENDIF

   @WHILE_V
      ; Loop body
   @ENDWHILE

   @SWITCH
   @CASE 1
      ; Handle case 1
      @CBREAK
   @CASE 2
      ; Handle case 2
      @CBREAK
   @CDEFAULT
      ; Default case
      @CBREAK
   @ENDCASE

@RestoreVar 02#           ; Reverse order of LocalVar
@RestoreVar 01#
@POPRETURN
@RET
```

---

## 🧑‍🏫 Indentation and Readability Rules

- Label definitions start at column 1.
- Main function body is indented 3 spaces.
- Control structures (`IF`, `ELSE`, `WHILE`, etc.) align vertically.
- Case blocks within `SWITCH` are also indented 3 spaces.

This structure allows visual scanning of the function shape and nesting depth.

---

## 🔖 Naming Conventions (Optional but Recommended)

- Library guard macros: `! MYLIBNAME_LOADED`
- Global symbols: `G MyLibrary.myfunc`
- Local variables: `@LocalVar 01#` (comment the purpose nearby)
- Labels inside library: keep simple (`:init`, `:loop`), since they get mangled automatically

---

## 📚 Summary

| Topic              | Best Practice                                  |
|-------------------|-------------------------------------------------|
| Library inclusion  | Use `L` with `!` guard and `M` macro            |
| Globals            | Declare with `G` *before* first use             |
| Reuse              | Override `G` functions by redefining later      |
| Function layout    | Use `@PUSHRETURN`, `@LocalVar`, and indent      |
| Control flow       | Align `IF`, `ELSE`, `ENDIF`, `SWITCH`, `CASE`   |

---
