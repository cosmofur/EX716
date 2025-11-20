# EX716

An experimental toy CPU emulator inspired by fictional 1970s microcomputers.  
EX716 aims to make assembly/machine code experimentation approachable by avoiding the complexity and legacy quirks of real CPUs from the era.

While EX716 is not optimized for performance and would be easily outpaced by even the most basic modern microcontroller, it has value as an educational tool and as an assembly language playground.

---

## Overview

EX716 is a fictional hybrid 8-bit/16-bit CPU with a consistent and idealized instruction set.  
It has influences from processors such as the Intel 8085, RCA 1802, and the Apple I.

### Features:

- 16-bit internal data path and ALU  
- Little-endian storage for all large numbers  
- 64K of directly accessible memory  
- Stack-based architecture with a 255-byte (127-word) hardware stack  
- No hardware floating point or BCD  
- Best suited for single-threaded programs  

---

## Hypothetical Hardware Description

- **Package**: 48–64 pins  
- **Data Bus**: 24 bits (8-bit opcode + 16-bit parameter), serialized or parallel  
- **Address Bus**: 16-bit  
- **Optional**: External page register via I/O for extended memory  
- **Control Pins**:
  - Read / Write / Ready  
  - Data / Memory selector  
  - Chip disable  

---

## Instruction Format

- Most instructions are:
  - 8-bit opcode (OPT)
  - 16-bit parameter (PRM)

- Supported addressing modes:
  - Direct
  - Indirect
  - Double Indirect
  - Stack

- Operates primarily on 16-bit values

---

## Addressing Modes

| Mode           | Description                                                             |
|----------------|-------------------------------------------------------------------------|
| **Direct**     | PRM contains immediate value. No write support.                         |
| **Indirect**   | PRM contains memory address of value. One extra memory cycle.           |
| **Dbl Indirect** | PRM points to address which holds another address. Two extra cycles.  |
| **Stack**      | Operands from top of stack (TOS) and second (SFT). No PRM fetch needed. |

---

## Instruction Groups

Instruction groups vary by addressing mode:

- **Direct**: `ADD`, `CMP`, `PUSH`  
- **Indirect**: `ADDI`, `CMPI`, `PUSHI`  
- **Double Indirect**: `ADDII`, `CMPII`, `PUSHII`  
- **Stack**: `ADDS`, `CMPS`, `PUSHS`  

**Examples**:

```
PUSH, PUSHI, PUSHII, PUSHS  
POP, POPI, POPII, POPS  
CMP, CMPI, CMPII, CMPS  
ADD, ADDI, ADDII, ADDS  
SUB, SUBI, SUBII, SUBS  
AND, ANDI, ANDII, ANDS  
OR, ORI, ORII, ORS  
XOR, XORI, XORII, XORS  
```

**Notes**:

- Stack-mode ops consume one or two stack items; result replaces top of stack  
- Subtraction is always `A - B`  
  - A = SFT (second from top)  
  - B = TOS (top of stack)

---

## Special Instructions

| Instruction         | Function                                      |
|---------------------|-----------------------------------------------|
| `JMP`, `JMPI`, `JMPS` | Jump variants                                |
| `JMPZ`, `JMPN`, `JMPO`| Conditional jumps based on flags             |
| `NOP`               | No operation                                  |
| `DUP`               | Duplicate TOS                                 |
| `SWP`               | Swap TOS and SFT                              |
| `CAST`, `POLL`      | Device I/O                                    |
| `RRTC`, `RLTC`, `SHR`, `SHL` | Bitwise shift/rotate                |
| `INV`               | Invert TOS                                    |
| `COMP2`             | Two's complement of TOS                       |
| `FCLR`, `FSAV`, `FLOD` | Flag control                              |

---

## Macro Assembler

EX716 includes a built-in macro assembler with a unique syntax.  
It supports single-pass assembly with deferred label resolution and structured macros.

### Directives

- `.` or `.ORG`: Set insertion and entry point  
- `.DATA`: Start data segment  
- `:` and `;`: Define labels for code and data  
- `@MACRO`: Invoke macro with `%1` to `%9` args  
- `=`: Set constant label  
- `M`, `MF`, `MC`: Define, set, or clear macros  
- `I`, `L`: Include or load files/libraries  
- `!`, `?`, `ENDBLOCK`: Macro conditionals  

### Literals

- `"text"`: 8 bit ascii string data inserted at point. /n /t type escapes supported.
- `'text'`: 8 bit ascii string RAW no '/' escape formating.
- `$123`, `0x1234`, `0b1010`: Numeric formats  
- `$$`,`$`,`$$$`: Byte 8b / word 16b / longword storage  32b

---

## Common Macros

Some examples:

```
@CALL, @RET, @JMPNZ, @PRTLN, @PRTI, @PRTS  
@DISKSEL, @DISKSEEK, @DISKREAD, @DISKWRITE  
```

See `common.mc` for the full list.

---

## Structured Macros

Support for structured programming, similar to C-like control structures:

```
@IF_*, @ELSE, @ENDIF  
@WHILE_*, @DO, @ENDWHILE  
@LOOP, @UNTIL_ZERO, @UNTIL_NOTZERO  
@SWITCH, @CASE, @CDEFAULT, @ENDCASE  
@FORIA2B, @FORIV2A, @NEXT, @NEXTBY  
```

Macro Function System

The EX716 assembler includes an inline macro expression evaluator that allows limited arithmetic, bitfield, and repetition logic to be performed entirely at assembly time.
All macro expressions begin with % and are evaluated left-to-right in a single pass.
Grouping and precedence are controlled explicitly with parentheses.

Expression Grouping

Parentheses are written as %( and %).
These may be nested and define an evaluation boundary; the entire grouped expression is replaced by its resulting value.

Example:

%AND[%(%OR[4 8]%) 2]   ; → 0x0


Numeric Width Rules

All macro arithmetic is performed using 16-bit unsigned integers.

Prefix modifiers adjust literal width:

Prefix	Size	Notes
$$	8-bit	Truncated to 8 bits
$$$	32-bit	Zero-padded or truncated to 16 bits internally


Macro Logical Stack (MLS)

The Macro Logical Stack is a small internal stack used to keep track of unique identifiers and symbolic values during macro expansion.
It acts as a means for macros to share or propagate context — for example, ensuring that @ENDWHILE pairs with the correct @WHILE instance.

Token	Action
%S	Push current macro argument (%0) onto MLS
%V	Replace with top of MLS (no pop)
%W	Replace with second-from-top of MLS
%P	Pop (discard) top of MLS, emit nothing

The primary use of the MLS is to maintain unique strings that can be embedded into label or macro names, allowing macros to safely nest and generate unique symbol scopes.
This system enables higher-level structured constructs such as @IF … @ENDIF and @WHILE … @ENDWHILE to function without collision.


Core Macro Functions
Function	Parameters	Description
%STRLEN [v1]	String	Computes the length of v1. Stores the numeric result in %LEN. Emits nothing.
%LEN	—	Expands to the most recent value set by %STRLEN. Useful for embedding string lengths.
%LINE	—	Expands to a comment marker showing the current filename and line number.
%REPEAT [v1] body %ENDR	Count, text block	Repeats body v1 times. Each repetition re-evaluates all inner % expressions.
%AND [v1 v2]	Two numbers	Bitwise AND → pushes result to MLS.
%OR [v1 v2]	Two numbers	Bitwise OR → pushes result to MLS.
%Field [start width value]	Three numbers	Extracts width bits from value starting at start, then left-shifts back into position. Equivalent to:
((value >> start) & ((1 << width) - 1)) << start
%Bit [bit value]	Two numbers	Returns 1 if bit bit in value is set, else 0. Equivalent to:
((value >> bit) & 1)
Examples

String length

%STRLEN "Hello"
.WORD %LEN        ; emits constant 5


Bit and field extraction

%Bit 3 0b1001            ; → 1
%Field 4 4 0xABCD        ; → 0x0B0


Stacked operations

%S                       ; save current %0
%Field 0 3 %V            ; extract 3 bits
%AND %V 0x07             ; mask result


Repetition

%REPEAT 4 
   @NOP
%ENDR
; expands to four NOP instructions

Implementation Notes

All macro functions expand inline — no deferred parsing beyond %(/%).

Numeric results can be inserted anywhere a literal is valid.

The %Field and %Bit functions are commonly used for instruction encoding or packed register formats.

%STRLEN and %LEN are often used to embed string sizes in structure definitions.

Nested macro evaluation is deterministic; all stack operations occur within the macro evaluation phase, not at runtime.

Would you like me to extend this section with an example of how %Field and %Bit are used together in a .REG or instruction encoding macro? It would bridge neatly into your later floating-point or opcode-definition examples.

---
## Function Call Helpers

To simplify common @CALL patterns, shorthand macros exist for up to four parameters:

```
Call(##)   → expands to @PUSH / @PUSHI + @CALL


Each letter in ## describes an argument type:

Symbol	Meaning
A	Immediate constant
v	Simple variable
```
Example:

| Macro                | Equivalent                    |
|----------------------|-------------------------------|
| Call(A) F 123        | @PUSH 123 @CALL F             |
| Call(Av) F 45 Cat    | @PUSH 45 @PUSHI Cat @CALL F   |
| Call(v) F Dog        | @PUSHI Dog @CALL F            |
| Call(vv) F Dog Cat   | @PUSHI Dog @PUHSI Cat @CALL F |
---
Example: Nested Scoping with WHILE / ENDWHILE

Structured macros such as @WHILE and @ENDWHILE use the MLS to track loop identity and prevent label collisions between nested loops.

M WHILE_GT_A \
   %S \
   :_%V_LoopTop \
   @CMP %1 \
   @JLE _%V_ExitLoop \
   :_%0_True

M ENDWHILE \
   @JMP _%W_LoopTop \
   :_%V_ExitLoop \
   %P


When expanded, the %S pushes a unique instance ID also stored in %0, which is unique every time the macro is evaluated.
The %V and %W operators then substitute that ID into label names, so each loop generates its own :_LoopTop and :_ExitLoop pair without interfering with other nested loops.
Finally, %P discards the label ID once the block ends.

Example: Logical Blocks and String Concatenation

The Forth compiler uses logical macro blocks and multi-append macros to define data that grows over multiple invocations.
The !…ENDBLOCK form provides conditional execution of macro definitions, while MA allows appending to an existing macro variable.

# DEFPRELOAD defines a block of string memory that holds raw Forth code to act as preload.
# Multiple PRELOADS will be appended to each other.

M PreCodeVal "( start preload )"

M DEFPRELOAD \
  ! PreCodeExists \
    MF PreCodeExists 1 \
  ENDBLOCK \
  MA PreCodeVal %1


Here:

! PreCodeExists … ENDBLOCK executes only the first time, defining the initial macro flag.

MA appends to the existing macro PreCodeVal, concatenating additional preload text each time @DEFPRELOAD is used.

MF would have replaced the value instead of appending it.

This pattern is common for building composite string definitions, code preload blocks, or concatenated initialization data.
---
## Emulator (`cpu.py`)

### Usage

```bash
./cpu.py source.asm [flags]
```

### Environment

- `CPUPATH`: Colon-separated paths for `lib/` and `test/`

### Flags

| Flag | Function                                 |
|------|------------------------------------------|
| `-c` | Compile to `.o` binary format            |
| `-d` | Debug mode (opcode trace)                |
| `-g` | Enter interactive debugger               |
| `-l` | List disassembled output                 |
| `-r` | Enable remote Python debugger            |

---

## Debugger Commands

| Command | Description                                      |
|---------|--------------------------------------------------|
| `b`     | Set or list breakpoints                          |
| `c`     | Continue execution                               |
| `cb`    | Clear all breakpoints                            |
| `d`     | Disassemble current or specified address range   |
| `g`     | Goto specific address                            |
| `h`     | Help summary                                     |
| `hex`   | Hex dump of memory                               |
| `hexi`  | Hex dump of memory starting at lable             |
| `m`     | Modify memory (inline or interactive)            |
| `n`     | Next instruction                                 |
| `s`     | Step over (skip over function call)              |
| `p`     | Print address contents                           |
| `pa`    | Print Any (optional pattern) search lables       |
| `ps`    | Print hardware stack contents                    |
| `q`     | Quit debugger                                    |
| `r`     | Reset program counter                            |
| `w`     | Set memory watchpoint                            |

---

## Disk I/O Simulation

EX716 includes macros for simulating simple 1970s-style disk pack access:

- `@DISKSEL A`, `@DISKSELI V`: Select disk  
- `@DISKSEEK A`, `@DISKSEEKI V`: Seek to sector  
- `@DISKWRITE V`: Write 512 bytes from memory  
- `@DISKREAD A`: Read 512 bytes to memory  
- `@DISKREADI V`: Read 512 bytes to address stored in variable  

Each simulated disk is:

- 32MB total
- 64K sectors per disk
- 512 bytes per sector


## Appendix A: Core Instruction Set
Here are the 'core' instructions, many additional 'macro' instructions are
defined in the commom.mc file. These in this list will assemble into single
optcodes and are therefore the most efficent to use for performance.

| Name     | Hex   | Dec | Size | Summary                                       |
|----------|-------|-----|------|-----------------------------------------------|
| NOP      | 0x00  | 0   | 1    | No operation                                  |
| PUSH     | 0x01  | 1   | 3    | Push immediate value onto stack               |
| DUP      | 0x02  | 2   | 1    | Duplicate top of stack                        |
| PUSHI    | 0x03  | 3   | 3    | Push value from address onto stack            |
| PUSHII   | 0x04  | 4   | 3    | Push value from address stored at another     |
| PUSHS    | 0x05  | 5   | 1    | Push value from address at TOS                |
| POPNULL  | 0x06  | 6   | 1    | Pop and discard top of stack                  |
| SWP      | 0x07  | 7   | 1    | Swap top two values on stack                  |
| POPI     | 0x08  | 8   | 3    | Pop and store to memory address               |
| POPII    | 0x09  | 9   | 3    | Pop and store to address stored in memory     |
| POPS     | 0x0A  | 10  | 1    | Pop and store using two values on stack       |
| CMP      | 0x0B  | 11  | 3    | Compare with immediate, set flags             |
| CMPS     | 0x0C  | 12  | 1    | Compare top two stack values                  |
| CMPI     | 0x0D  | 13  | 3    | Compare memory value with TOS                 |
| CMPII    | 0x0E  | 14  | 3    | Compare indirect memory value with TOS        |
| ADD      | 0x0F  | 15  | 3    | Add immediate to TOS                          |
| ADDS     | 0x10  | 16  | 1    | Add top two stack values                      |
| ADDI     | 0x11  | 17  | 3    | Add memory value to TOS                       |
| ADDII    | 0x12  | 18  | 3    | Add indirect memory value to TOS              |
| SUB      | 0x13  | 19  | 3    | Subtract immediate from TOS                   |
| SUBS     | 0x14  | 20  | 1    | Subtract TOS from second top of stack         |
| SUBI     | 0x15  | 21  | 3    | Subtract memory value from TOS                |
| SUBII    | 0x16  | 22  | 3    | Subtract indirect memory value from TOS       |
| OR       | 0x17  | 23  | 3    | Bitwise OR with immediate                     |
| ORS      | 0x18  | 24  | 1    | Bitwise OR of top two stack values            |
| ORI      | 0x19  | 25  | 3    | Bitwise OR with memory value                  |
| ORII     | 0x1A  | 26  | 3    | Bitwise OR with indirect memory value         |
| AND      | 0x1B  | 27  | 3    | Bitwise AND with immediate                    |
| ANDS     | 0x1C  | 28  | 1    | Bitwise AND of top two stack values           |
| ANDI     | 0x1D  | 29  | 3    | Bitwise AND with memory value                 |
| ANDII    | 0x1E  | 30  | 3    | Bitwise AND with indirect memory value        |
| XOR      | 0x1F  | 31  | 3    | Bitwise XOR with immediate                    |
| XORS     | 0x20  | 32  | 1    | Bitwise XOR of top two stack values           |
| XORI     | 0x21  | 33  | 3    | Bitwise XOR with memory value                 |
| XORII    | 0x22  | 34  | 3    | Bitwise XOR with indirect memory value        |
| JMPZ     | 0x23  | 35  | 3    | Jump if zero flag is set                      |
| JMPN     | 0x24  | 36  | 3    | Jump if negative flag is set                  |
| JMPC     | 0x25  | 37  | 3    | Jump if carry flag is set                     |
| JMPO     | 0x26  | 38  | 3    | Jump if overflow flag is set                  |
| JMP      | 0x27  | 39  | 3    | Unconditional jump                            |
| JMPI     | 0x28  | 40  | 3    | Jump to address stored in memory              |
| JMPS     | 0x29  | 41  | 1    | Jump to address on top of stack               |
| CAST     | 0x2A  | 42  | 3    | Output value to device                        |
| POLL     | 0x2B  | 43  | 3    | Input value from device                       |
| RRTC     | 0x2C  | 44  | 1    | Rotate right through carry                    |
| RLTC     | 0x2D  | 45  | 1    | Rotate left through carry                     |
| SHR      | 0x2E  | 46  | 1    | Shift right                                   |
| SHL      | 0x2F  | 47  | 1    | Shift left                                    |
| INV      | 0x30  | 48  | 1    | Invert top of stack                           |
| COMP2    | 0x31  | 49  | 1    | Two's complement of top of stack              |
| FCLR     | 0x32  | 50  | 1    | Clear flags                                   |
| FSAV     | 0x33  | 51  | 1    | Save flag state to stack                      |
| FLOD     | 0x34  | 52  | 1    | Load flag state from stack                    |
| ADM      | 0x35  | 53  | 1    | Enter admin mode (experimental)               |
| SCLR     | 0x36  | 54  | 1    | Stack Clear, zeros out HW Stack.              |
| SRPT     | 0x37  | 55  | 1    | Stack Repot, Push stack size, -1 on error.    |
