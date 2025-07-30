# 📚 EX716 Assembler - Lesson 7: Standard Library Overview

The EX716 core CPU is intentionally minimalist, but real-world programs need more functionality than 52 instructions can offer. Rather than baking everything into the core, functionality is extended using a set of modular, loadable **libraries** (`.ld` files).

These libraries are written in EX716 macro assembly and provide features traditionally handled by OS calls or high-level runtime environments.

> **Loading a Library:**  
> Use `L filename.ld` to include a library. Public entry points are defined using the `G` macro and label mangling ensures internal names don’t collide.

---

## 📦 Library Summary

| Library        | Description                             |
|----------------|-----------------------------------------|
| `div.ld`       | Provides `DIV` and `MOD` operations     |
| `heapmgr.ld`   | Heap allocator / free / re-use system   |
| `lmath.ld`     | 32-bit math (add, sub, shift, etc)      |
| `mul.ld`       | Integer multiply (signed/unsigned)      |
| `random.ld`    | Simple pseudo-random generator          |
| `screen.ld`    | ANSI terminal cursor/screen control     |
| `softstack.ld` | Allocate and manage software stacks     |
| `string.ld`    | String comparison, copy, length         |
| `timetool.ld`  | Time calculations (epoch math, offsets) |

---

## 🔢 `div.ld` — Division & Modulo

**Depends on:** `softstack.ld`, `common.mc`  
**Exports:** `DIVU`, `DIV`

- `DIVU` = Unsigned division  
- `DIV` = Signed division  

Push operands as `A B`, where it calculates `A / B`. Division by zero triggers an error.  
Returns **two** values: Quotient and Remainder.  
To get just the quotient, pop twice and discard the remainder.

---

## 🧱 `heapmgr.ld` — Heap Memory Manager

**Depends on:** `softstack.ld`, `common.mc`  
All heap addresses must be ≥ `0x100`. Smaller values are treated as error codes.

```text
G HeapDefineMemory(low_addr, size)        → heap_id
G HeapNewObject(heap_id, size)            → object
G HeapResizeObject(heap_id, obj, size)    → object
G HeapDeleteObject(heap_id, obj)          → status
G HeapListMap(heap_id)                    → prints/inspects
G GetObjectRealSize(heap_id, obj)         → size
G HeapAppend(obj1, obj2, offset)          → modifies obj1
```

---

## 🧮 `lmath.ld` — 32-bit Integer Math

**Depends on:** `string.ld`, `common.mc`  
All operands are **pointers to 32-bit little-endian integers in memory**.  
There is also an assembler prefix `$$$` to embed a 32-bit literal at the current memory address, though it cannot be pushed directly.

Provides:

- Arithmetic: `ADD32`, `SUB32`, `CMP32`, `DIV32`, `DIV32U`, `MUL32`
- Bitwise: `AND32`, `OR32`, `INV32`, `SHL32`, `SHR32`
- Conversions: `INT2LONG`, `LONG2INT`, `i32tos`, `stoi32`
- I/O: `PRT32BIN`, `PRT32HEX`
- Vector forms: `ADD32VVV`, `DIV32VVVV`, etc.

> This library is large and will be covered in detail in a future lesson.

---

## ✖️ `mul.ld` — 16-bit Multiplication

**Depends on:** `softstack.ld`, `common.mc`  

```text
G MULU(A, B)   → Unsigned result (16-bit)
G MUL(A, B)    → Signed result (16-bit)
```

Returns a single value. Use `lmath.ld` for wider results.

---

## 🎲 `random.ld` — Pseudorandom Numbers

**Depends on:** `softstack.ld`, `lmath.ld`, `mul.ld`, `common.mc`  

```text
G rnd16()          → 16-bit random (0–0xFFFF)
G rndint(limit)    → Random mod limit
G rndsetseed(seed) → Set PRNG seed
G frnd16()         → Faster, weaker PRNG
G frndint(limit)   → Faster with range
G xorshift16(seed) → Mix entropy
```

> This is a lightweight, non-cryptographic generator.

---

## 🖥️ `screen.ld` — ANSI Terminal Control

**Depends on:** `heapmgr.ld`, `string.ld`, `common.mc`  
Provides cursor and screen control for ANSI-compatible terminals.

```text
G WinClear          G WinCursor          G WinWidth         G WinHeight
G WinResize         G WinPlot            G WinHideCursor    G WinShowCursor
G ColorReset        G ColorFGSet         G ColorBGSet       G CSICODE
G WinNorth          G WinSouth           G WinEast          G WinWest
```

> A future lesson will demonstrate creating screen-based interfaces using this library.

---

## 📥 `softstack.ld` — Software Stack Management

**Depends on:** `common.mc`  
Defines a software-managed memory stack in contrast to the CPU's hardware stack.

### Core Functions

```text
G SetSSStack(ptr)              → Initialize soft stack
G SaveSSStack / RestoreSSStack
G __SS_TOP / __SS_BOTTOM / __SS_SP  → Variable definding Soft Stack
G __MOVE_HW_SS / __MOVE_SS_HW  → POP HW, PUSH SW or POP SW, PUSH HW
```

### Macros

```text
M PUSHRETURN     → Push return and switch stack
M PUSHHW         → Push value to HW stack
M PUSHLOCAL      → Push constant to soft stack
M PUSHLOCALI     → Push variable to soft stack
M LocalVar = %1  → Define + push local var
M RestoreVar     → Pop back to var
M POPHW          → Pop soft stack, push to HW stack
M POPRETURN      → Restores return to HW stack
M POPLOCAL       → Pop Soft Stack directly to variable
M POPLOCALII     → Pop Soft Stack to pointers location
M TOPLOCAL       → DUP's Soft Stack, Pop copy to HW Stack
```

---

## ✍️ `string.ld` — Null-Terminated String Functions

**Depends on:** `div.ld`, `mul.ld`, `softstack.ld`, `heapmgr.ld`, `common.mc`  
Implements common C-style functions.

```text
G strlen, strcpy, strncpy, strcat, strncat, strcmp, strncmp, strstr, strfndc
G memcpy, itos, stoi, stoifirst, strtok, splitstr, SplitDelete
G strUpCase, strLowCase, HexDump
G ISAlpha, ISAlphaNum, ISNumeric
```

---

## ⏰ `timetool.ld` — Time Functions

**Depends on:** `lmath.ld`, `mul.ld`, `div.ld`, `common.mc`  

```text
G Time2Units     → Convert time value into calendar fields
G IsLeapYear     → True if year is leap
G DaysInYear     → 365 or 366
G DaysInMonth    → Month length
G TimeCalabrate  → Setup time baseline
G Sleep, SleepMilli
```

---

Let me know if you'd like to go into the full syntax, register usage, or calling conventions for any specific function set next.
