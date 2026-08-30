# EX716 Development System

The **EX716 Development System** is a complete experimental software and hardware development environment centered around a custom 16-bit stack-oriented processor.

Rather than being just another assembler, EX716 explores how far assembly language can be pushed toward the convenience of higher-level languages while preserving complete control over the generated machine code.

The project includes:

* A custom 16-bit CPU architecture
* A macro assembler
* A dependency-aware linker
* Dynamic function libraries
* An integrated emulator and debugger
* Structured assembly language
* Standard runtime libraries
* Experimental higher-level language implementations (BASIC, Forth, and others)

The long-term goal is to provide a practical development environment that is suitable for software experimentation while remaining simple enough to implement in FPGA hardware.

---

# Design Philosophy

EX716 is built around several core principles:

* Assembly language should remain readable.
* High-level programming constructs should have little or no runtime overhead.
* Libraries should scale without increasing application size.
* Tooling should encourage maintainable software.
* Every layer of the system should remain understandable.

Rather than hiding assembly language, EX716 attempts to make assembly programming resemble writing in a structured systems language.

---

# Major Features

## CPU

* 16-bit stack-oriented architecture
* 64K word address space
* Compact instruction encoding
* Hardware evaluation stack
* Indirect addressing
* FPGA-friendly instruction set

## Assembler

* Powerful macro language
* Structured programming macros
* Automatic forward reference resolution
* Local label scoping
* Conditional assembly
* Expression evaluation
* Source-level debugging support

## Linker

* Automatic dependency resolution
* Function-level linking
* Dynamic library support
* Dead-code elimination
* Automatic dependency tracking

## Emulator

* Interactive debugger
* Source-level stepping
* Symbol lookup
* Memory inspection
* Stack inspection
* Virtual disk support

---

# Command-Line Options

Common `cpu.py` options include:

| Option | Purpose |
| ------ | ------- |
| `-g` | Run the interactive debugger. Generated dynamic-library temp files are cleaned up when the debugger exits. |
| `-K` | Keep generated dynamic-library temp files in the system temp directory for deeper debugging. |
| `-d` | Increase assembly or runtime debug output. May be repeated for more detail. |
| `-l` | Print an assembled source listing. |
| `-c` | Write a hex dump of the assembled image. |
| `-O` | Write a binary dump of the assembled image. |
| `-w addr` | Add a watch address to the debug listing. |
| `-b addr` | Set a debugger breakpoint. |
| `-e command` | Pass an initial command to the debugger. |

---

# Platform Notes

EX716 is primarily developed on Linux and WSL, and also runs in POSIX-like Python environments such as Termux. Native Windows support is best-effort: assembler and non-interactive emulator paths should import cleanly, while terminal raw-mode features are limited compared with POSIX terminals.

`CPUPATH` uses the host platform path separator: `:` on Linux, WSL, macOS, and Termux; `;` on native Windows.

## Optional C Fast Mode

The `-f` fast emulator path uses the optional `cpuCfunc` Python extension built from `speedCPU.c`:

```sh
make check
make
```

The Makefile derives Python include paths, NumPy include paths, and the extension suffix from the selected `PYTHON`, so the built file uses the host Python ABI name such as `cpuCfunc.cpython-312-x86_64-linux-gnu.so`. A compatibility `cpuCfunc.so` copy is also written on POSIX builds.

The current C backend still uses POSIX terminal APIs, so native Windows builds are intentionally rejected by the Makefile. Use WSL/Linux/Termux for `-f`, or run `cpu.py` without `-f` on native Windows.

---

# Project Layout

| Directory       | Purpose                               |
| --------------- | ------------------------------------- |
| `cpu.py`        | Assembler, linker, emulator, debugger |
| `common.mc`     | Core macro library                    |
| `structure.asm` | Structured programming macros         |
| `lib/`          | Standard libraries                    |
| `tests/`        | Example programs and regression tests |
| `docs/`         | Project documentation (planned)       |

---

# Writing Programs

A minimal EX716 program looks like this:

```assembly
I common.mc

:Main

    @PRTLN "Hello World"

@END

.ORG Main
```

Most applications include `common.mc`, which provides the standard macro language used throughout the project.

---

# Source File Directives

The assembler provides several mechanisms for incorporating additional source files.

| Directive | Purpose                                                                  |
| --------- | ------------------------------------------------------------------------ |
| `I file`  | Textually include another source file into the current label scope.      |
| `L file`  | Assemble another source file using its own local label scope.            |
| `D file`  | Import a dynamic library. No code is linked until requested with `#USE`. |

For macro libraries, `I` is generally appropriate.

For modern runtime libraries, `D` is recommended.

Example:

```assembly
I common.mc

D string.ld
D heapmgr.ld
```

---

# Dynamic Libraries

Dynamic libraries are one of the defining features of EX716.

Unlike traditional assembly projects, importing a library does **not** automatically include every routine.

Instead, functions are linked individually as they are needed.

Example:

```assembly
D string.ld

#USE strcpy
#USE strlen
```

Only the requested functions and the routines they depend upon are included in the final executable.

Unused code is never assembled into the application.

This allows large libraries to remain practical while keeping executables compact.

When a dynamic library is filtered, `cpu.py` creates a generated `dynlib_*` copy in the system temporary directory and assembles that generated file. Normal runs, including `-g` debugger sessions, remove these generated files on exit and prune older generated copies for the same source library when creating a new one. Use `-K` with `-g` when you intentionally want to keep the generated `dynlib_*` file for deeper inspection. On Linux, WSL, and Termux these files normally live under `/tmp`; on native Windows they use Python's system temp directory.

---

# Programming Model

Most EX716 software is written using:

* Structured programming macros
* Library functions
* Automatic local variables
* Software stack support
* Function dependency tracking

Raw instructions remain available whenever complete control is required.

---

# Structured Programming

EX716 provides structured control-flow constructs that expand entirely during assembly.

Examples include:

* `@IF`
* `@ELSE`
* `@ENDIF`
* `@WHEN`
* `@DO`
* `@WHILE`
* `@ENDWHILE`
* `@LOOP`
* `@UNTIL`
* `@SWITCH`
* `@CASE`

Example:

```assembly
@IF_EQ_A Value

    @PRTLN "Equal"

@ELSE

    @PRTLN "Not Equal"

@ENDIF
```

These constructs generate ordinary labels and branches with no runtime interpreter.

---

# Functions

Library routines are organized using `@FUNCTION` and `@ENDFUNCTION`.

Example:

```assembly
@FUNCTION strcpy

:strcpy

    ...

@RET

@ENDFUNCTION
```

These directives define exported function boundaries for the dependency-aware linker.

Every exported library routine should use this form.

---

# Local Variables

The assembler supports automatic local-variable allocation.

Example:

```assembly
@Locals
    @Local Count
    @Local Index
    @Local Buffer
```

Local variables improve readability by eliminating manual frame-offset calculations.

Most non-trivial routines should use `@Locals`.

---

# Recommended Function Layout

The preferred organization for library routines is:

```assembly
@FUNCTION Example

:Example

@PUSHRETURN

@Locals
    @Local Arg1
    @Local Arg2
    @Local Temp

    @POPI2 Arg1 Arg2

    ...

@EndLocals
@POPRETURN
@RET

@ENDFUNCTION
```

Using a consistent layout makes library code easier to read and maintain.

---

# Parameter Passing

Arguments are passed on the hardware stack.

To simplify parameter handling, EX716 provides grouped push/pop macros.

Instead of:

```assembly
@POPI Dest
@POPI Source
```

prefer:

```assembly
@POPI2 Dest Source
```

Likewise:

```assembly
@PUSHI3 Count Index Buffer
```

is generally preferred over three individual `@PUSHI` instructions.

Grouped parameter macros improve readability while reducing repetitive code.

Keep in mind that order matters, POP in reverse order as PUSH.

---

# Macro System

The macro language provides:

* Parameterized macros
* Macro variables
* Expression evaluation
* Conditional assembly
* Automatic label generation
* Nested macro state management

Most of the higher-level language features of EX716 are implemented entirely through macro expansion.

---

# Standard Libraries

The standard library continues to grow and currently includes functionality such as:

* String handling
* Heap management
* Software stack
* ANSI terminal support
* Random numbers
* Integer multiplication
* Integer division
* 32-bit arithmetic
* Timing utilities
* Disk and filesystem support

Applications typically use only a small subset of each library because of automatic dependency resolution.

---

# Emulator and Debugger

The assembler and emulator are integrated into a single tool.

Typical usage:

```
cpu.py program.asm
```

Common options include:

| Option | Description                                    |
| ------ | ---------------------------------------------- |
| `-g`   | Interactive debugger                           |
| `-d`   | Debug output (repeat for additional verbosity) |
| `-l`   | Generate listing file                          |
| `-c`   | Produce object file                            |
| `-r`   | Remote debugger                                |

The debugger supports:

* Source-level stepping
* Instruction stepping
* Breakpoints
* Stack inspection
* Memory inspection
* Symbol lookup
* Source mapping

Macro-generated code is automatically mapped back to the original source line, making debugging significantly easier than traditional assembly language.

---

# Disk Simulation

The emulator contains a built-in virtual disk system for operating system and filesystem development.

Features include:

* Virtual disks
* Sector-based I/O
* Read/write operations
* Filesystem experimentation

This allows operating-system development without requiring physical hardware.

---

# Zero-Cost Abstractions

One of the primary goals of EX716 is to provide higher-level programming conveniences without introducing runtime overhead.

Examples include:

* Structured programming constructs expand into ordinary branches.
* `@FUNCTION` and `@ENDFUNCTION` exist only for the assembler and linker.
* `#USE` performs dependency tracking at assembly time.
* Dynamic libraries eliminate unused functions rather than introducing runtime dispatch.
* Local-variable support expands into ordinary stack operations.

These features improve readability and maintainability while preserving efficient generated code.

---

# Current Status

EX716 is an active experimental project.

Current areas of development include:

* CPU architecture refinement
* Additional standard libraries
* Filesystem enhancements
* BASIC language implementation
* Forth language experimentation
* FPGA implementation
* Improved documentation

---

# Design Goals

The EX716 project emphasizes:

* Readable assembly language
* Structured programming
* Small implementation size
* Efficient generated code
* FPGA friendliness
* Educational value
* Language experimentation
* Long-term maintainability

The project explores the boundary between assembly language and higher-level languages while keeping the generated machine code transparent and predictable.

---

# License

License information will be added as the project matures.

---

# Appendix A - Core Instruction Set

The following table lists every **native CPU instruction** implemented by the EX716 processor.

Unlike the many convenience macros provided by `common.mc`, each instruction shown here assembles directly into a **single machine opcode**. For performance-critical code, these are the lowest-level operations available and always represent the most compact implementation.

Most application software is written using the higher-level macros provided by `common.mc`, which expand into combinations of these core instructions.

| Name    | Hex  | Dec | Bytes | Description                                        |
| ------- | ---- | --: | ----: | -------------------------------------------------- |
| NOP     | 0x00 |   0 |     1 | No operation                                       |
| PUSH    | 0x01 |   1 |     3 | Push immediate value onto the hardware stack       |
| DUP     | 0x02 |   2 |     1 | Duplicate the top stack value                      |
| PUSHI   | 0x03 |   3 |     3 | Push value stored at memory address                |
| PUSHII  | 0x04 |   4 |     3 | Push value using indirect addressing               |
| PUSHS   | 0x05 |   5 |     1 | Push value from address held on the stack          |
| POPNULL | 0x06 |   6 |     1 | Discard the top stack value                        |
| SWP     | 0x07 |   7 |     1 | Swap the top two stack values                      |
| POPI    | 0x08 |   8 |     3 | Store top stack value into memory                  |
| POPII   | 0x09 |   9 |     3 | Store using indirect addressing                    |
| POPS    | 0x0A |  10 |     1 | Store using address supplied on the stack          |
| CMP     | 0x0B |  11 |     3 | Compare immediate value, update flags              |
| CMPS    | 0x0C |  12 |     1 | Compare top two stack values                       |
| CMPI    | 0x0D |  13 |     3 | Compare memory value with stack                    |
| CMPII   | 0x0E |  14 |     3 | Compare indirect memory value                      |
| ADD     | 0x0F |  15 |     3 | Add immediate value                                |
| ADDS    | 0x10 |  16 |     1 | Add top two stack values                           |
| ADDI    | 0x11 |  17 |     3 | Add memory value                                   |
| ADDII   | 0x12 |  18 |     3 | Add indirect memory value                          |
| SUB     | 0x13 |  19 |     3 | Subtract immediate value                           |
| SUBS    | 0x14 |  20 |     1 | Subtract top stack value from second               |
| SUBI    | 0x15 |  21 |     3 | Subtract memory value                              |
| SUBII   | 0x16 |  22 |     3 | Subtract indirect memory value                     |
| OR      | 0x17 |  23 |     3 | Bitwise OR with immediate                          |
| ORS     | 0x18 |  24 |     1 | Bitwise OR of top two stack values                 |
| ORI     | 0x19 |  25 |     3 | Bitwise OR with memory value                       |
| ORII    | 0x1A |  26 |     3 | Bitwise OR with indirect memory value              |
| AND     | 0x1B |  27 |     3 | Bitwise AND with immediate                         |
| ANDS    | 0x1C |  28 |     1 | Bitwise AND of top two stack values                |
| ANDI    | 0x1D |  29 |     3 | Bitwise AND with memory value                      |
| ANDII   | 0x1E |  30 |     3 | Bitwise AND with indirect memory value             |
| XOR     | 0x1F |  31 |     3 | Bitwise XOR with immediate                         |
| XORS    | 0x20 |  32 |     1 | Bitwise XOR of top two stack values                |
| XORI    | 0x21 |  33 |     3 | Bitwise XOR with memory value                      |
| XORII   | 0x22 |  34 |     3 | Bitwise XOR with indirect memory value             |
| JMPZ    | 0x23 |  35 |     3 | Jump if Zero flag is set                           |
| JMPN    | 0x24 |  36 |     3 | Jump if Negative flag is set                       |
| JMPC    | 0x25 |  37 |     3 | Jump if Carry flag is set                          |
| JMPO    | 0x26 |  38 |     3 | Jump if Overflow flag is set                       |
| JMP     | 0x27 |  39 |     3 | Unconditional jump                                 |
| JMPI    | 0x28 |  40 |     3 | Jump through memory address                        |
| JMPS    | 0x29 |  41 |     1 | Jump to address on top of stack                    |
| CAST    | 0x2A |  42 |     3 | Write value to an I/O device                       |
| POLL    | 0x2B |  43 |     3 | Read value from an I/O device                      |
| RRTC    | 0x2C |  44 |     1 | Rotate right through carry                         |
| RLTC    | 0x2D |  45 |     1 | Rotate left through carry                          |
| SHR     | 0x2E |  46 |     1 | Shift right                                        |
| SHL     | 0x2F |  47 |     1 | Shift left                                         |
| INV     | 0x30 |  48 |     1 | Bitwise invert                                     |
| COMP2   | 0x31 |  49 |     1 | Two's complement                                   |
| FCLR    | 0x32 |  50 |     1 | Clear processor flags                              |
| FSAV    | 0x33 |  51 |     1 | Push current flag register onto the stack          |
| FLOD    | 0x34 |  52 |     1 | Restore flags from the stack                       |
| ADM     | 0x35 |  53 |     1 | Enter Administrative Mode (reserved)               |
| SCLR    | 0x36 |  54 |     1 | Clear the hardware stack                           |
| SRPT    | 0x37 |  55 |     1 | Push current stack depth (`-1` indicates an error) |

## Instruction Families

Many instructions exist in several closely related forms.

For example:

| Variant | Meaning                                      |
| ------- | -------------------------------------------- |
| `ADD`   | Immediate operand                            |
| `ADDI`  | Operand stored in memory                     |
| `ADDII` | Operand obtained through indirect addressing |
| `ADDS`  | Operand taken from the hardware stack        |

The same naming convention applies to most arithmetic, logical, comparison, and memory operations. While the processor implements 56 distinct opcodes, these naturally group into approximately 32 instruction families.

## Performance Considerations

The instructions listed in this appendix always assemble into a **single CPU instruction**.

Many convenience macros provided by `common.mc` expand into two or more of these operations. They are generally preferred for readability, but performance-critical code can use the native instruction set directly when maximum efficiency is required.

## Administrative Mode

`ADM` is currently reserved and has no effect in the current implementation.

It exists as part of the processor's long-term roadmap and is intended to provide privileged processor services such as:

* Memory banking
* Hardware interrupt control
* Software interrupt support
* Protected memory operations
* Future operating system services

The exact capabilities of Administrative Mode are expected to evolve as the EX716 architecture continues to mature.

