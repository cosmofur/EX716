# EX716 Development System

The EX716 project is a complete experimental computing environment consisting of:

- A custom 16-bit stack-oriented CPU architecture
- A macro assembler
- An emulator/debugger
- A growing standard library system
- A structured assembly language
- Experimental higher-level language support (Forth, BASIC, etc.)

The project is intended both as a practical development platform and as an exploration of CPU, compiler, operating system, and language design.

---

# Project Components

| Component | Description |
|------------|-------------|
| cpu.py | Assembler, linker, emulator, debugger |
| common.mc | Core macro library |
| structure.asm | Structured programming macros |
| lib/*.ld | Standard libraries |
| tests/* | Sample programs and regression tests |

---

# CPU Architecture

The EX716 is a 16-bit stack-based processor.

Key characteristics:

- 16-bit word size
- 64K word address space
- Hardware evaluation stack
- Flag register
- Indirect addressing support
- Fast instruction decoding
- Compact opcode encoding

The CPU is intentionally simple enough to implement in FPGA hardware while remaining practical for larger software projects.

---

# Programming Model

The EX716 is programmed primarily through its macro assembler.

Raw machine instructions are available, but most software uses:

- Structured programming macros
- Function macros
- Library modules
- Local variable support
- Software stack support

The goal is to allow assembly language to be written using techniques normally associated with higher-level languages.

---

# Source File Structure

Typical program:

```assembly
I common.mc

:Main

@PRTLN "Hello World"

@END
.ORG Main

| Directive | Purpose                             |
| --------- | ----------------------------------- |
| I file    | Include file in current label scope |
| L file    | Load file in local scope            |
| M         | Define macro                        |
| MF        | Define macro variable               |
| G         | Declare global symbol               |
| =         | Define constant                     |
| :         | Define label                        |
| .ORG      | Define current address and entry    |
Labels

Labels define memory locations.

:Start

Labels may be:

Global
Local
Generated automatically by macros

The assembler performs automatic forward-reference resolution.

Constants

Constants are defined with:

=BufferSize 1024

Constants may participate in assembler expressions.

Macro System

The macro system is one of the most powerful parts of the EX716 toolchain.

Macros are expanded dynamically by the assembler.

Example:

M INC \
   @ADD 1

Usage:

@INC
Macro Parameters

Parameters use:

%1
%2
%3
...

Example:

M ADDTO \
   @ADD %1

Usage:

@ADDTO 10
Macro Variables

Macros may define variables:

MF Counter 10

Referenced as:

{Counter}

Variables may contain:

Numbers
Strings
Expressions
Macro Expressions

Expression evaluation:

MF Count %EVAL {Count}+1

Supports:

Arithmetic
Parentheses
Macro variables
Constants
Macro Logical Stack (MLS)

The Macro Logical Stack allows nested macro state to be managed safely.

Operations:

Command	Meaning
%S	Push current macro context (No output)
%V	Top of stack
%W	One level below top
%P	Pop stack (No output)

Example:
%S
...
_%V_Label
...
%P

MLS is heavily used by structured programming macros.

Conditional Assembly

Conditional assembly is block-based.

Supported forms include:

IFNDEF also ! SYMBOL
IFDEF  also ? SYMBOL
IF_EQ
IF_NE
IF_LT
IF_GT

Example:

! DEBUG

   P Debug Build

ENDBLOCK

Blocks may be nested.

Block Execution Engine

The assembler maintains a conditional block stack.

Each block tracks:

Nesting depth
Execution state
Conditional type

Commands inside disabled blocks are skipped while still maintaining nesting integrity.

This guarantees that deeply nested conditionals remain balanced.

Structured Programming

EX716 provides high-level structured constructs.

Examples:

@IF_EQ_A Value
   ...
@ENDIF
@WHILE_NE_A Value
   ...
@ENDWHILE

Supported constructs include:

IF
ELSE
ENDIF
WHILE
ENDWHILE
LOOP
UNTIL
WHEN
SWITCH
CASE

These expand into labels and jumps during assembly.

ELSE Support

ELSE is implemented entirely through macro expansion.

Example:

@IF_EQ_A Value

   @PRTLN "Equal"

@ELSE

   @PRTLN "Not Equal"

@ENDIF

The assembler correctly tracks nesting and matching ENDIF blocks.

Functions

Functions are library-managed code blocks.

Example:

@FUNCTION AddNumbers

:AddNumbers

...

@RET

ENDBLOCK

Functions may be selectively linked through the dependency system.

USE_ONLY Linking

Large libraries can be selectively linked.

Enable:

M __EX716_USE_ONLY 1

Mark required functions:

@USE strcpy
@USE itos32

Only referenced functions and their dependencies are assembled.

Benefits:

Smaller binaries
Faster assembly
Cleaner dependency tracking
Local Variables

The assembler supports automatic local variable management.

Example:

@Locals
   @Local Count
   @Local Index

Cleanup:

@EndLocals

These expand into save/restore sequences.

Software Stack Library

The standard soft stack library provides:

Recursive call support
Local variable storage
Additional stack depth

Common macros:

@PUSHRETURN
@POPRETURN

@PUSHLOCAL
@POPLOCAL
Standard Libraries

Common libraries include:

Library	Purpose
softstack.ld	Software stack
string.ld	String functions
screen.ld	ANSI terminal support
heapmgr.ld	Dynamic memory
random.ld	Random numbers
mul.ld	Multiplication
div.ld	Division
lmath.ld	32-bit math
timetool.ld	Timing support
Emulator (cpu.py)

The assembler and emulator are integrated.

Usage:

cpu.py source.asm

Common flags:

Flag	Description
-g	Interactive debugger
-d	Debug output, repeat for additioal levels of debug output.
-l	Listing file
-c	Compile object file
-r	Remote debugger
Debugger

The debugger supports:

Single stepping
Breakpoints
Memory inspection
Stack inspection
Symbol lookup
Source mapping

Example:

0104> n        < Execute Next Optcode
0107> s        < Step to Next 'Line' in program, avoids stepping into function calls or complex macros.
010a> c        < Continue until program ends or breakpoint reached.
Source-Level Debugging

Every generated instruction is mapped back to its originating source line.

This includes:

Main source files
Included libraries
Macro expansions

Macro-generated code retains the line number of the macro invocation rather than the internal lines of the macro definition.

This makes debugging significantly easier.

Forward References

The assembler supports:

Forward label references
Multi-pass resolution
Deferred expression evaluation

Symbol resolution occurs automatically after assembly.

Disk Simulation

The emulator includes a simple disk simulation system.

Features:

32 MB virtual disks
512-byte sectors
Seek/read/write operations

Example:

@DISKSEL 0
@DISKSEEK 100
@DISKREAD Buffer
Design Goals

The EX716 project emphasizes:

Readable assembly language
Structured programming
Small implementation size
FPGA friendliness
Educational value
Experimentation with language and CPU design

The project intentionally explores how far assembly language can be pushed toward high-level language usability while remaining transparent and efficient.

Appendix A: Core Instruction Set




Here are the 'core' instructions; many additional 'macro' instructions are
defined in the `common.mc` file. Instructions in this list will assemble into single
opcodes and are therefore the most efficient to use for performance.
                           Byte
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
| SRPT     | 0x37  | 55  | 1    | Stack Report, Push stack size, -1 on error.   |

Summary: Core instructions
NOP, PUSH, DUP, POPNULL, SWP, POP, CMP, ADD, SUB, OR, AND, XOR, JMPZ, JMPC, JMPO, JMP, JMPI, JMPS, CAST, POLL, RRTC, RLTC, SHR, SHL, INV, COMP2, FCLR, FSAV, FLOD, ADM, SCLR, SRPT

There are about 32 instructions if you consider the 'S', 'I', 'II', and default as variants of the same instruction.

ADM mode currently does nothing, but future plans is to enable memory banking, soft and hw interups and protected memory functions as features controled by Adm mode.
