# EX716 Assembler - Lesson 3: Directives and Core Instructions

Up to now, we've been walking the edge between machine language and
assembly.

To take the first full step into assembly, we need to introduce the
syntax and keywords of the assembler language.

We've already talked about the main purpose of the assembler: to insert
numbers into memory — but in a way that makes development easier.

So let’s talk about the *language* features that make this possible.
These are **keywords** that send instructions to the assembler itself
(not the CPU).

Most are single-letter codes or short symbolic commands.

---

## Assembler Directive Keywords

| Code                    | Action                                                                |
|-------------------------|-----------------------------------------------------------------------|
| `@{name} [args]`        | Expand macro `{name}` with optional args. Injects text into source.   |
| `M {name} body`         | Defines a macro. The body continues until end of line.                |
| `:{name} [value]`       | Defines a label set to current memory address. Used for code or data. |
| `;{name} [size] [val]`  | Similar to `:`, but used for defining ROM/code-separated data.        |
| `= {name} [value]`      | Constant definition. Value is assigned directly.                      |
| `. or .ORG [value]`     | Sets the current memory address for code generation.                  |
| `.DATA [value]`         | Used with `;` to define code/data split memory layout.                |
| `L filename`            | Load library file. Labels are private unless marked global.           |
| `I filename`            | Insert file inline. Labels are global.                                |
| `P text`                | Prints at assembly time. Useful for diagnostics.                      |
| `! MacroName`           | If macro is NOT defined, include block until `ENDBLOCK`.              |
| `? MacroName`           | If macro IS defined, include block until `ENDBLOCK`.                  |
| `MF MacroName Value`    | Single-token macro definition. Use `""` to undefine.                  |
| `MA MacroName Value`    | Appends token to an existing macro.                                   |
| `G label`               | Mark label as global for export.                                      |

---

## Core Instruction Set (Subset)

Most instructions in EX716 follow a consistent family naming pattern
based on how operands are provided:

- **Base form**: operates on the top of the stack and an immediate value.
- **`I` form**: uses the parameter as an address in memory (i.e., a simple variable).
- **`II` form**: treats the parameter as a pointer, and uses the value it points to
  (e.g., array or table access).

This consistent convention applies to most arithmetic, logic, and print operations.

---

### 📥 Stack and Memory Access

| Operation    | Meaning                                     |
|--------------|---------------------------------------------|
| `PUSH val`   | Push an immediate value onto the stack      |
| `PUSHI var`  | Push the value at address `var`             |
| `PUSHII ptr` | Push the value pointed to by address `ptr`  |
| `POPI var`   | Same as above (convenience macro)           |
| `POPII ptr`  | Pop to memory location pointed to by `ptr`  |
| `POPNULL`    | Discard top of stack                        |
| `DUP`        | Duplicate the top of stack                  |

---

### 🧮 Arithmetic and Comparison
All the following functions have Direct, Indirect, and double Indirect
forms.
For example:
| Operation     | Description                     |
|---------------|---------------------------------|
| 'ADD' val     | Adds val to TOS                 |
| 'ADDI' var    | Adds val stored in var to TOS   |
| 'ADDII' ptr   | Adds val ptr points at to TOS   |
| 'ADDS'        | Adds SFT to TOP                 |

---

| Operation     | Description                                             |
|---------------|---------------------------------------------------------|
| 'ADD'[,I,II,S]| Add values, results saved at TOS                        |
| 'SUB'[,I,II,S]| Subtract values, results saved at TOS                   |
| 'CMP'[,I,II,S]| Set flags as if it had Subtracted values                |
| 'AND'[,I,II,S]| Bitwise logic between TOS and value                     |
| 'OR'[,I,II,S] | Bitwise logic between TOS and value                     |
| 'XOR'[,I,II,S]| Bitwise logic between TOS and value                     |
---

### 🧭 Branching and Control Flow

| Operation     | Description                              |
|---------------|------------------------------------------|
| `JMP addr`    | Unconditional jump                       |
| `JMPZ addr`   | Jump if Zero Flag (ZF) is set            |
| `JMPN addr`   | Jump if Negative Flag (NF) is set        |
| `JMPO addr`   | Jump if Overflow Flag (OF) is set        |
| `JMPC addr`   | Jump if Carry Flag (CF) is set           |
| `NOP`         | Do nothing                               |

---

### 🖨 Output and Debug

| Operation     | Description                                         |
|---------------|-----------------------------------------------------|
| `PRT val`     | Print a literal string or immediate value           |
| `PRTI var`    | Print value at memory address                       |
| `PRTS var`    | Print null-terminated string starting at `var`      |
| `PRTSI ptr`   | Print string from pointer-to-pointer                |
| `PRTTOP`      | Print the current top value on the stack            |

---

This instruction set is sufficient to write a wide range of stack-based logic, including:

- Loops and conditional branches
- Table access and numeric processing
- Simple debugging output and diagnostics

Structured control flow (e.g., `IF`, `WHILE`, `SWITCH`) is built on top of these primitives using macros, and will be introduced in Lesson 4.
---

## 🧪 Sample Program #1: Find Max in Table

```asm
I common.mc

. 0x1000
:START
  @PUSH DataTable
  @POPI Index
  @PUSH 0
  @POPI MaxFound

  :LoopTop
    @PUSHII Index
    @CMP -1
    @JMPZ EndLoop

    @CMPI MaxFound
    @JMPN SkipStore
    @JMP StoreNewMax

  :SkipStore
    @PUSHI Index
    @ADD 2
    @POPI Index
    @JMP LoopTop

  :StoreNewMax
    @POPI MaxFound
    @JMP SkipStore

  :EndLoop
    @PRT "Max value found:\n"
    @PRTI MaxFound
    @END

:Index       0
:MaxFound    0

:DataTable
17 23 14 98 45 -1




## 🧪 Sample Program #2: Generate First 10 Fibonacci Numbers
I common.mc

. 0x1000
:START
  @PUSH 10           # Number of values to generate
  @POPI Count
  @PUSH FibTable
  @POPI Index

  @PUSH 0
  @POPI Prev
  @PUSH 1
  @POPI Curr

  :LoopTop
    @PUSHI Count
    @CMP 0
    @JMPZ Done

    @PUSHI Curr
    @POPII Index        # Store current value to table
    @PUSHI Index
    @ADD 2
    @POPI Index         # Index += 1 (word address)

    @PUSHI Curr
    @PUSHI Prev
    @ADDS
    @POPI Temp          # Temp = Curr + Prev

    @PUSHI Curr
    @POPI Prev          # Prev = Curr
    @PUSHI Temp
    @POPI Curr          # Curr = Temp

    @PUSHI Count
    @SUB 1
    @POPI Count
    @JMP LoopTop

  :Done
    @PRT "Fibonacci Sequence:\n"
    @PUSH FibTable
    @POPI PrintIndex
    @PUSH 10
    @POPI PrintCount

  :PrintLoop
    @PUSHI PrintCount
    @CMP 0
    @JMPZ End

    @PUSHII PrintIndex
    @PRTTOP
    @PRT "\n"
    @POPNULL

    @PUSHI PrintIndex
    @ADD 2
    @POPI PrintIndex

    @PUSHI PrintCount
    @SUB 1
    @POPI PrintCount

    @JMP PrintLoop

  :End
  @END

:Count        0
:Index        0
:Prev         0
:Curr         0
:Temp         0
:PrintIndex   0
:PrintCount   0

:FibTable
0 0 0 0 0 0 0 0 0 0

