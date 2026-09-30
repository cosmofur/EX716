# 📚 EX716 Assembler - Lesson 7: Standard Library Overview

The EX716 core CPU is intentionally minimalist, but real-world programs need more functionality than the core instruction set can offer. Rather than baking everything into the core, functionality is extended using a set of modular, loadable **libraries** (`.ld` files).

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
| `event.ld`     | Terminal mouse, keyboard, and timer events |
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
G HeapAvailable(heap_id)                  → free bytes
G GetObjectRealSize(heap_id, obj)         → usable object size
G HeapAppend(obj1, obj2, offset)          → appends obj2 to obj1
G HeapDefrag(heap_id)                     → merges adjacent free objects
G HeapValidate(heap_id)                   → 0 or validation error
```

---

## 🧮 `lmath.ld` — 32-bit Integer Math

**Depends on:** `shift16.ld`, `string.ld`, `common.mc`  
All operands are **pointers to 32-bit little-endian integers in memory**.  
There is also an assembler prefix `$$$` to embed a 32-bit literal at the current memory address, though it cannot be pushed directly.

Provides:

- Arithmetic: `ADD32S`, `ADD32U`, `SUB32S`, `SUB32U`, `MUL32U`, `MUL32S`, `DIV32U`, `DIV32S`
- Compatibility aliases: `ADD32`, `SUB32`, `CMP32`
- Bitwise: `AND32`, `OR32`, `XOR32`, `INV32`, `SHL32`, `SHR32`
- Bit helpers: `SetBit32`, `ClearBit32`, `SHL16x32`, `SHR16x32`, `SHL3264`
- Conversions: `i32tos`, `stoi32`
- Flags/constants: `Flags32`, `C32Flag`, `N32Flag`, `Z32Flag`, `O32Flag`, `ZERO32`, `ONE32`, `TWO32`, `OVF32`

> This library is large and will be covered in detail in a future lesson.

---

## ✖️ `mul.ld` — 16-bit Multiplication

**Depends on:** `softstack.ld`, `common.mc`  

```text
G MULU(A, B)   → Unsigned result (16-bit)
G MUL(A, B)    → Signed result (16-bit)
```

Returns a single 16b value. Use `lmath.ld` for wider results.

---

## 🎲 `random.ld` — Pseudorandom Numbers

**Depends on:** `softstack.ld`, `lmath.ld`, `mul.ld`, `common.mc`  

```text
G rnd16()          → 16-bit random (0–0xFFFF)
G rndint(limit)    → Random mod limit
G rndsetseed(seed) → Set PRNG seed
G frnd16()         → Faster, weaker PRNG
G frndint(limit)   → Faster with range
```

> This is a lightweight, non-cryptographic generator.

---

## 🖥️ `screen.ld` — ANSI Terminal Control

**Depends on:** `heapmgr.ld`, `string.ld`, `common.mc`  
Provides cursor and screen control for ANSI-compatible terminals.

```text
G WinClear          G WinResize         G WinWidth         G WinHeight
G WinClearRect      G WinCursor         G WinHideCursor    G WinShowCursor
G WinNorth          G WinSouth          G WinEast          G WinWest
G ColorReset        G ColorFGSet        G ColorBGSet       G WinPlot
G WinBox            G WinScrollRegion   G WinResetScrollRegion
G WinScrollUp       G WinScrollDown     G WinUnderLineOn   G WinUnderLineOff
G WinBoldOn         G WinBoldOff        G CISCODE
```

> A future lesson will demonstrate creating screen-based interfaces using this library.

---

## 🧭 `event.ld` — Terminal Event Handling

**Depends on:** `common.mc`, `heapmgr.ld`, `mul.ld`

Provides a table-based event system for terminal mouse, keyboard, and timer events. Programs create an event table on the heap, register the events they care about, then call `EventPoll` to check whether one has fired.

### Core Functions

```text
G TermMouseEnable       G TermMouseDisable
G EventTableNew         G EventTableFree
G EventSetActive        G EventGetActive
G EventAdd              G EventPoll
G EventList
```

`EventAdd` uses the same six stack arguments for all event types:

```text
EventAdd(Type, X1, Y1, X2, Y2, EventID)
```

- Mouse events: `Type=MouseEvent`, `X1/Y1` to `X2/Y2` describe the hit rectangle.
- Keyboard events: `Type=KeyEvent`, `X1` is a pointer to the string of keys to watch.
- Timer events: `Type=TimerEvent`, `X1` is the duration in seconds and `Y1` is the repeat flag (`0` one-shot, `1` periodic).

`EventPoll()` returns `0` when nothing matched, or the matching `EventID`.

### Core variables

```text
G CISCODE           G ActiveEventTable       G LastEventType
G LastEventID       G LastEventTSLo          G LastEventTSHi
G LastMouseX        G LastMouseY             G LastMouseBtn
G LastMouseFlags    G LastMouseRawB          G LastMouseTerm
G MF_PRESS          G MF_RELEASE             G MF_DRAG
G MF_WHEEL          G MF_SHIFT               G MF_ALT
G MF_CTRL           G LastKeyMatchPtr        G LastKeyLen
G LastKeyChar       G LastTimerDur           G LastTimeRep
G LastTimerELap     G LastTimerSkip
G MouseEvent        G MouseEventClick        G MouseEventRelease
G TimerEvent        G KeyEvent
```

The lower-level queue/search helpers are also exported for advanced code:

```text
G ReadKeyTimeOut    G KeyEnQueue             G KeyDeQueue
G KeyQueueSize      G KeyReadMouseSeq        G KeySearchMouse
G KeySearchKeyBoard G KeySearchTimer
```

After a successful `EventPoll`, the `Last...` variables describe the matched event.

---

## 📥 `softstack.ld` — Software Stack Management

**Depends on:** `common.mc`  
Defines a software-managed memory stack in contrast to the CPU's hardware stack.

### Core Functions

```text
G SetSSStack(ptr)              → Initialize soft stack
G SaveSSStack / RestoreSSStack
G __SS_TOP / __SS_BOTTOM / __SS_SP  → Variables defining the soft stack
G __MOVE_HW_SS / __MOVE_SS_HW  → POP HW, PUSH SW or POP SW, PUSH HW
```

### Macros

```text
M PUSHRETURN     → Saves return address to SW Stack (Alias PUSHHW)
M PUSHHW         → Moves HW:TOS to SW:TOS
M PUSHLOCAL      → Push constant to soft stack
M PUSHLOCALI     → Push variable to soft stack
M LocalVar       → Defines Local variable, preserves old value.
M RestoreVar     → Frees Local variable, restores previous value.
M POPHW          → Moves SW:TOS to HW:TOS
M POPRETURN      → Restores return form SW Stack (Alias POPHW)
M POPLOCAL       → Pop Soft Stack directly to variable
M POPLOCALII     → Pop Soft Stack to pointers location
M TOPLOCAL       → DUP's Soft Stack, Pop copy to HW Stack
```

---

## ✍️ `string.ld` — Null-Terminated String Functions

**Depends on:** `div.ld`, `mul.ld`, `softstack.ld`, `heapmgr.ld`, `common.mc`  
Implements common C-style functions.

```text
strlen, strcpy, strncpy, strcat, strncat, strcmp, strncmp, strstr, strfndc
memcpy, itos, stoi, stoifirst, strtok, splitstr, SplitDelete
strUpCase, strLowCase, ISAlpha, ISAlphaNum, ISNumeric
```
Main functions:
```
strlen(A)      → String Length
strcpy(A,B)    → Copies StrB overwrite StrA
strncpy(A,B,mx)→ Copies up to mx of strB over StrA
strcat(A,B)    → Appends StrB to StrA (does not resize A)
strncat(A,B,mx)→ Appends up to mx of StrB to StrA
strcmp(A,B)    → Compares A to B, A-B
strncmp(A,B,mx)→ Compares A[:mx] to B[:mx]
strstr(A,B)    → Address where substring B is found in A, or null
strfndc(A,c)   → First instance of char c or null
memcpy(A,B,mx) → Copy mx bytes from B to A. Not Null Terminated.
itos(A,I,B)    → Turn value I into string A using base B
stoi(A)        → Returns integer value of A, support 0x# 0o# and 0b# default decimal
stoifirst(A)   → Like stoi but tolerant of non-null string terminators
strtok(A,ch)   → Walk through A finding tokens delimited by character ch.
splitstr(A,B,HeapID) → Returns new heap array of A split by set in B, needs HeapID
SplitDelete(Obj,HeapID) → Clean up heap object created by splitstr
strUpCase(A)    → Modify A so all alpha are uppercase
strLowCase(A)   → Modify A so all alpha are lowercase
ISAlpha(A)      → true if 1st char in A is in range [A-Z,a-z]
IsAlphaNum(A)   → true if 1st char in A is in range [A-Z,a-z,0-9,_]
ISNumeric(A)    → true if 1st character is in range [0-9]
```
  
---

## ⏰ `timetool.ld` — Time Functions

**Depends on:** `lmath.ld`, `mul.ld`, `div.ld`, `common.mc`  

```text
G Time2Units     → Convert time value into calendar fields
G IsLeapYear     → True if year is leap
G DaysInYear     → 365 or 366
G DaysInMonth    → Month length
G TimeCalabrate  → Set up time baseline
G Sleep, SleepMilli
```

---

