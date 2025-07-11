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
