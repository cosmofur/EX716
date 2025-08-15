# EX716 Assembler - Lesson 6: Instructions and core library summary.

This lesson catalogs the available instructions and macros for EX716 programming and explains the naming conventions used throughout.

---

## 🧠 Understanding Instruction vs Macro Notation

The EX716 instruction set uses **two different naming conventions**, depending on whether you're using a core hardware-supported
instruction or a higher-level macro.

### 1. Core Instruction Notation (`@OP`, `@OPI`, `@OPII`)

Core instructions use suffixes to indicate **how the operand is resolved**:

| Suffix   | Meaning                     |
|----------|-----------------------------|
| _(none)_ | Direct value (literal)      |
| `I`      | Indirect (fixed variable)   |
| `II`     | Double indirect (pointer)   |

These instructions operate in a **stack-based** context, where the first operand is always the **top of the stack (TOS)**. The suffix
defines how to fetch the second operand.

Example:
- `@ADD` — Add Direct value to TOS
- `@ADDI` — Add value from variable to TOS
- `@ADDII` — Add value from pointer-to-variable to TOS

This is simple, compact, and ideal for low-level instructions.

---
Examples:
- `@ADDVV` — Add variable to variable
- `@CMPVA` — Compare variable to direct value
- `@SUBAV` — Subtract variable from constant

This notation is necessary because suffixes like `I` and `II` no longer express both operands. For example, you can't write a
readable macro for “constant + constant” using suffixes alone.

Instead, the macro system uses **explicit operand role encoding**—and while slightly more verbose, it scales better for compound
logic and higher abstraction.

---



| Instruction | Core Opcode | Description                       |
|-------------|-------------|-----------------------------------|
| @ADD        | Core        | Add Direct value with TOS         |
| @ADDI       | Core        | Add Variable value with TOS       |
| @ADDII      | Core        | Add Value at Ptr with TOS         |
| @ADDS       | Core        | Add top two stack items together  |
| @ADM        | Core        | Enable admin mode (future)        |
| @AND        | Core        | Bitwise AND Direct with TOS       |
| @ANDI       | Core        | AND Variable value with TOS       |
| @ANDII      | Core        | AND Value at Ptr with TOS         |
| @ANDS       | Core        | AND top two stack items together  |
| @CAST       | Core        | Send value to device              |
| @CMP        | Core        | Compare TOS with Direct value     |
| @CMPI       | Core        | Compare TOS with Variable value   |
| @CMPII      | Core        | Compare TOS with Value at Ptr     |
| @CMPS       | Core        | Compare SFT with TOS              |
| @COMP2      | Core        | Two’s complement of TOS           |
| @DUP        | Core        | Duplicate top of stack            |
| @FCLR       | Core        | Clear condition flags             |
| @FLOD       | Core        | Restore ZNCO from stack           |
| @FSAV       | Core        | Save ZNCO to stack                |
| @INV        | Core        | Bitwise invert                    |
| @JMP        | Core        | Unconditional jump                |
| @JMPC       | Core        | Jump if carry set                 |
| @JMPI       | Core        | Jump to indirect address          |
| @JMPO       | Core        | Jump if overflow                  |
| @JMPS       | Core        | Jump to HW stack top              |
| @JMPN       | Core        | Jump if negative                  |
| @JMPZ       | Core        | Jump if zero                      |
| @NOP        | Core        | Do nothing                        |
| @OR         | Core        | Bitwise OR                        |
| @ORI        | Core        | OR Variable value with TOS        |
| @ORII       | Core        | OR Value at Ptr with TOS          |
| @ORS        | Core        | OF top two stack items together   |
| @POLL       | Core        | Query device or status            |
| @POPNULL    | Core        | Pop top and discard               |
| @POPI       | Core        | Pop into memory by address        |
| @POPII      | Core        | Pop to next word address          |
| @POPS       | Core        | Pop to HW stack                   |
| @PUSH       | Core        | Push Direct value to TOS          |
| @PUSHI      | Core        | Push Variable Value to TOS        |
| @PUSHII     | Core        | Push Value at Ptr with TOS        |
| @PUSHS      | Core        | Replace TOS with value @ address  |
| @RLTC       | Core        | Rotate Left Through Carry         |
| @RRTC       | Core        | Rotage Right Through Carry        |
| @SCLR       | Core        | Clear HW stack                    |
| @SHL        | Core        | Logical shift left                |
| @SHR        | Core        | Logical shift right               |
| @SRTP       | Core        | Push HW stack depth or -1         |
| @SUB        | Core        | Subtract TOS from Direct value    |
| @SUBI       | Core        | Subtract TOS from Variable value  |
| @SUBII      | Core        | Subtract TOS from Value at Ptr    |
| @SUBS       | Core        | Subtrace top two stack items      |
| @SWP        | Core        | Swap top two stack items          |
| @XOR        | Core        | Bitwise XOR                       |
| @XORI       | Core        | XOR Variable value with TOS       |
| @XORII      | Core        | XOR Value at Ptr with TOS         |
| @XORS       | Core        | XOR top two stack items together  |

---
### 1A. Core adjactent macros.

These macros operate like core instructions but use a single variable (indirect) as their source and/or destination. They follow the I suffix pattern from the core set but are implemented as compound macros. These are heavily used in loop control and common arithmetic tasks.

|-------------|-------------|------------------------------------|
| @INCI       | Compound    | Increment variable by 1            |
| @DECI       | Compound    | Decrement variable by 1            |
| @INC2I      | Compound    | Increment variable by 2            |
| @DEC2I      | Compound    | Decrement variable by 2            |
| @ABSI       | Compound    | Pushs absolute value of variable   |


---

### 2. Macro Notation (`@ADDVV`, `@CMPVA`, etc.)

Macros that operate on **two operands** (e.g., two variables, or variable and constant) use a **symbolic dual-letter** notation:

| Symbol | Operand Type          |
|--------|------------------------|
| `A`    | Direct (constant)      |
| `V`    | Variable               |


| Instruction | Core Opcode | Description                        |
|-------------|-------------|------------------------------------|
| @CMPVV      | Compound    | Compare Variable vs Variable       |
| @CMPVA      | Compound    | Compare Variable vs Direct         |
| @CMPAV      | Compound    | Compare Direct vs Variable         |
| @ADDVV      | Compound    | Add Variable + Variable            |
| @ADDVA      | Compound    | Add Variable + Direct              |
| @ADDAV      | Compound    | Add Direct + Variable              |
| @SUBVV      | Compound    | Subtract Variable - Variable       |
| @SUBVA      | Compound    | Subtract Variable - Direct         |
| @SUBAV      | Compound    | Subtract Direct - Variable         |
| @ORVV       | Compound    | Bitwise OR Variable \| Variable    |
| @ORVA       | Compound    | Bitwise OR Variable \| Direct      |
| @ORAV       | Compound    | Bitwise OR Direct \| Variable      |
| @ANDVV      | Compound    | Bitwise AND Variable & Variable    |
| @ANDVA      | Compound    | Bitwise AND Variable & Direct      |
| @ANDAV      | Compound    | Bitwise AND Direct & Variable      |
| @XORVV      | Compound    | Bitwise XOR Variable ^ Variable    |
| @XORVA      | Compound    | Bitwise XOR Variable ^ Direct      |
| @XORAV      | Compound    | Bitwise XOR Direct ^ Variable      |
| @MA2V       | Compound    | Move Direct to Var                 |
| @MV2V       | Compound    | Move Var to Var                    |

## Compound Jump and Call Macros

These macros improve readability by abstracting flag logic into common forms like `@JGT`, `@JMPNZ`, `@CALLZ`.

*Why?* EX716’s core `JMPZ`, `JMPN`, etc. can be cryptic. These macros clarify conditional intent and add negated variants that don’t exist in hardware.

---

| Instruction | Core Opcode | Description                           |
|-------------|-------------|---------------------------------------|
| @JMPNZ      | Compound    | Jump if TOS not zero                  |
| @JMPZI      | Compound    | Jump if Variable not zero             |
| @JMPNZI     | Compound    | Jump if Variable is non-zero          |
| @JMPNC      | Compound    | Jump if carry flag is clear           |
| @JMPNO      | Compound    | Jump if overflow flag is clear        |
| @JGT        | Compound    | Jump if neither Z or N set            |
| @JGE        | Compound    | Jump if N or Z is set                 |
| @JLT        | Compound    | Jump if Z or N is clear               |
| @JLE        | Compound    | Jump if N is clear                    |
| @JNZ        | Compound    | Jump if Z is clear                    |
| @JZ         | Compound    | Jump if Z is set                      |
| @CALL       | Compound    | Call fixed address                    |
| @CALLZ      | Compound    | Call only if ZF is set                |
| @CALLNZ     | Compound    | Call only if ZF is not set            |
| @RET        | Compound    | Return from subroutine (pop to PC)    |

The idea behind these is, the core instructions do not provide negative versions of the core 'JMPZ' and other flags, here are their logical reverse as well as somewhat clearer terms for dealing with Greater and Less than tests than the NF by itself expresses.


Following table is the core output macros that handle all the major IO though 'device driver' like calls.

## Output Macros

These simulate external smart printers or terminals that can handle full numbers or strings without requiring base conversion. Devices have DMA to memory and can directly pull blocks of memory to the device, for example for strings.


| Instruction     | Core Opcode | Description                                 |
|-----------------|-------------|---------------------------------------------|
| @PRT            | Compound    | Print following quoted strin                |
| @PRTI           | Compound    | Print value of variable as signed integer   |
| @PRTUI          | Compound    | Print value as unsigned integer             |
| @PRTHEXI        | Compound    | Print variable as hexadecimal               |
| @PRTHEXII       | Compound    | Print pointer-to-value as hexadecimal       |
| @PRTCH          | Compound    | Print Ascii character of Direct value       |
| @PRTCHI         | Compound    | Print variable as ASCII character           |
| @PRTCHS         | Compound    | Print Ascii character of value on TOS       |
| @PRTSTR         | Compound    | Print string at address (constant fixed)    |
| @PRTSTRI        | Compound    | Print string at pointer variable            |
| @PRTS           | Compound    | Print string at pointer variable == PRTSRI  |
| @PRTSI          | Compound    | Print null-terminated string from ptr       |
| @PRTSS          | Compound    | Print 2-byte (16-bit) string from stack     |
| @PRT32          | Compound    | Print next two stack items as 32-bit int    |
| @PRT32I         | Compound    | Print 32-bit integer from variable pair     |
| @PRT32S         | Compound    | Print 32-bit integer from HW stack pair     |
| @PRTSGNI        | Compound    | Print signed integer with sign from var     |
| @PRTBINI        | Compound    | Print variable as binary string             |
| @PRTNL          | Compound    | Print newline                               |
| @PRTSP          | Compound    | Print space character                       |
| @PRTREF         | Compound    | Print value of a pointer reference          |
| @PRTTOP         | Compound    | Print top of stack without popping          |
| @PRTHEXTOP      | Compound    | Print top of stack in hex (no pop)          |
| @PRTSGNTOP      | Compound    | Print top of stack signed (no pop)          |

*Historical Note:* 
While uncommon in modern systems, many early computers and embedded systems from the 1960s and 70s offloaded display formatting to hardware or peripheral devices. For example, the Apollo Guidance Computer sent raw numerical data to the DSKY interface, which handled the conversion and display of human-readable digits. Similarly, early microcomputers like the COSMAC ELF and Altair 8800 used hex displays and segment drivers that directly interpreted binary or BCD values without CPU-based string formatting.

This emulator follows that tradition: output macros simulate smart I/O devices that handle formatting internally—just as early hardware might have used dedicated logic or microcontrollers to convert binary values into readable output.

---

## Input Macros

Input macros similarly assume buffered, smart devices that return structured data.

| Instruction     | Core Opcode | Description                                   |
|-----------------|-------------|-----------------------------------------------|
| @READI          | Compound    | Read signed integer into variable             |
| @PROMPT         | Compound    | Print prompt string, then read integer        |
| @READS          | Compound    | Read string input to address at Direct value  |
| @READSI         | Compound    | Read string into memory starting at ptr       |
| @READC          | Compound    | Read single ASCII character into TOS          |
| @READCNW        | Compound    | Read character with no wait (non-blocking)    |
| @TTYNOECHO      | Compound    | Disable input echoing                         |
| @TTYECHO        | Compound    | Enable input echoing                          |


The following don't exactly fit in with the other tables.


## Utility and Storage Macros

Macros for system control, debugging, and disk/tape I/O. They simulate controllers and other subsystems with simplified command logic.

| Instruction     | Core Opcode | Description                                              |
|-----------------|-------------|----------------------------------------------------------|
| @END            | Compound    | Halt execution and return to monitor/debugger           |
| @TOP            | Compound    | Duplicates TOS and POPI's a copy to Variable            |
| @StackDump      | Compound    | Dump stack contents to console/debug output             |
| @GETTIME        | Compound    | Get system time (32 bits two words on stack)            |
| @DISKSEL        | Compound    | Select disk unit by Direct value                        |
| @DISKSELI       | Compound    | Select disk unit by value from variable                 |
| @DISKSEEK       | Compound    | Seek disk to address Direct value                       |
| @DISKSEEKI      | Compound    | Seek disk to address from variable                      |
| @DISKWRITE      | Compound    | Write memory block to disk starting at Direct Address   |
| @DISKWRITEI     | Compound    | Write from address stored in variable                   |
| @DISKSYNC       | Compound    | Flush disk write buffers (sync)                         |
| @DISKREAD       | Compound    | Read from disk to address starting at Direct Address    |
| @DISKREADI      | Compound    | Read from disk to address in variable                   |
| @TAPESEL        | Compound    | Select tape device by Direct value                      |
| @TAPESELI       | Compound    | Select tape device from variable                        |
| @TAPEWRITE      | Compound    | Write block of memory to tape from Direct Address       |
| @TAPEWRITEI     | Compound    | Write block of var address to tape                      |
| @TAPEREAD       | Compound    | Read block from tape to memory at Direct Address        |
| @TAPEREADI      | Compound    | Read block from tape to var address                     |
| @TAPEREWIND     | Compound    | Rewind tape device to start                             |
| @DEBUGTOGGLE    | Compound    | Toggle debugging output or mode                         |
