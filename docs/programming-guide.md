# Programming EX716: CPU, Instructions, and Style

This guide describes the current programming model shared by `cpu.py` and
`cpu24.py`. It is the place to start before reading individual library source
files. `cpu.py` is the classic 16-bit machine; `cpu24.py` retains that model in
Ring 0 and adds banked code/data for Ring 1.

## 1. The machine model

EX716 is a 16-bit, stack-oriented CPU. Most operations use the hardware
evaluation stack: `@PUSH 7 @PUSH 5 @ADDS` leaves `12` on top. Memory addresses,
instruction operands, and ordinary integers are 16 bits. Arithmetic wraps at
16 bits and sets zero, negative, carry, and overflow flags for later branches.

The source spelling `@NAME` invokes a macro. The basic instruction macros in
`common.mc` emit a native opcode; higher-level macros may emit several
instructions and labels. There is no runtime macro interpreter.

Operand suffixes are consistent across the instruction set:

| Suffix | Operand source | Example |
| --- | --- | --- |
| none | immediate value encoded after the opcode | `@ADD 4` |
| `I` | value at a direct memory address | `@ADDI Count` |
| `II` | value through a pointer stored at an address | `@ADDII CountPtr` |
| `S` | value already on the hardware stack | `@ADDS` |

For two stack values, the older value is the left operand and the top value is
the right operand. Thus `@PUSH 9 @PUSH 4 @SUBS` produces `5`.

## 2. Native instruction families

These are the native instructions implemented by both emulators. Each emits a
single opcode; macros such as `@CALL`, `@IF_*`, and `@PRT` are conveniences built
from them.

| Family | Instructions | Effect |
| --- | --- | --- |
| Stack and load | `PUSH`, `DUP`, `PUSHI`, `PUSHII`, `PUSHS` | Push an immediate, duplicate the top, or load from direct, indirect, or stack-supplied memory. |
| Stack and store | `POPNULL`, `SWP`, `POPI`, `POPII`, `POPS` | Discard/swap stack values or store through direct, indirect, or stack-supplied addresses. |
| Compare | `CMP`, `CMPS`, `CMPI`, `CMPII` | Compare without keeping a result; update processor flags. |
| Arithmetic | `ADD`, `ADDS`, `ADDI`, `ADDII`; `SUB`, `SUBS`, `SUBI`, `SUBII` | Perform 16-bit addition or subtraction and update flags. |
| Boolean | `OR*`, `AND*`, `XOR*` | Bitwise operations in immediate, stack, direct, and indirect forms. |
| Branch | `JMPZ`, `JMPN`, `JMPC`, `JMPO`, `JMP`, `JMPI`, `JMPS` | Conditional branch on a flag, or jump directly/indirectly/from the stack. |
| Host I/O | `CAST`, `POLL` | Send a request to, or receive a value from, an emulator device. Prefer standard I/O macros. |
| Bits | `RRTC`, `RLTC`, `SHR`, `SHL`, `INV`, `COMP2` | Rotate, shift, invert, or take the two's complement of the top value. |
| Flags | `FCLR`, `FSAV`, `FLOD` | Clear, save, or restore processor flags. |
| Control | `ADM`, `SCLR`, `SRPT` | Change administrative mode, clear the hardware stack, or report its depth. |

`JMPZ`, `JMPN`, `JMPC`, and `JMPO` test the corresponding flag from the most
recent flag-setting operation. Higher-level signed comparisons use both
negative and overflow state, so prefer `@IF_LT_*`, `@JLT`, and their relatives
instead of hand-coding signed tests.

## 3. A `cpu.py` program

`cpu.py` has one 64 KiB address space. Code, static data, heap, and stacks must
fit without overlap.

```assembly
I common.mc

:Counter 0

:Main . Main
    @MA2V 3 Counter
    @PUSHI Counter
    @PRT "Counter = " @PRTTOP @PRTNL
    @POPNULL
    @END
```

The `I common.mc` include supplies native instruction spellings, I/O helpers,
call helpers, and the structured macros from `structure.asm`. `:Main . Main`
defines the label and makes it the legacy entry address. Static values declared
with `:` share the same address space as code.

## 4. The `cpu24.py` modes

`cpu24.py` can run ordinary `common.mc` programs in compatible Ring 0. Its Ring
1 mode forms physical addresses as `(bank << 16) | offset`, giving code and data
separate 64 KiB logical windows selected by segment registers.

| Feature | `cpu.py` / CPU24 Ring 0 | CPU24 Ring 1 |
| --- | --- | --- |
| Addressing | one 16-bit space | 8-bit bank plus 16-bit offset |
| Standard include | `I common.mc` | `.DATA 1` then `I commonDS.mc` |
| Static data | `:Name initializer` | `::Name initializer` in the selected data bank |
| Entry | legacy `.ORG` idiom | `.ENTRY label` is preferred |
| Ordinary data access | single memory space | uses DS |
| Ordinary instruction fetch | single memory space | uses CS |
| Cross-bank flow | not applicable | `@FJMP` / `@FCALL` conventions |

CPU24 adds these native instructions:

| Instruction | Purpose |
| --- | --- |
| `CSO`, `DSO`, `ESO` | Override the segment used by the immediately following memory operation. |
| `SSO` | Stack-segment override reserved for Ring 2; it is not available in Ring 1. |
| `SGET selector` | Push the current segment-bank value (`SegCS`, `SegDS`, or `SegES`). |
| `SSET selector` | Pop and set DS or ES; CS cannot be changed this way. |
| `FJMPS` | Pop a bank and offset and transfer execution across code banks in Ring 1. |

The segmented common library also provides `@FJMP bank offset`, `@FCALL bank
offset`, `@FENTER`, and `@FRET`. A far callee uses the far-entry/far-return
convention; do not pair an ordinary `@CALL` with `@FRET`.

```assembly
.DATA 1
I commonDS.mc

::Counter 0
::Message "Hello from banked data\0"

.CODE 0
:Main
.ENTRY Main
    @PUSH 1
    @SSET SegDS
    @PUSH 1
    @ADM

    @MA2V 3 Counter
    @PRTS Message @PRTNL

    @PUSH 0
    @ADM
    @END
```

`.CODE bank` selects placement for following code. `.DATA bank` selects the
data bank and makes `::` labels logical offsets within it. A data initializer
determines width: `$$0` is a byte, `0` is a word, `$$$0` is a 32-bit long, and
`$$0 * 64` is a 64-byte buffer. `::__ value` emits unnamed continuation data.

Set DS and enter Ring 1 before touching banked data. Returning to Ring 0 with
`@PUSH 0 @ADM` clears the segment registers. See `CPU2CPU24.txt` for a detailed
porting checklist.

## 5. Calls, parameters, and local storage

Arguments are pushed left to right and the callee pops them right to left.
The `@Call(...)` family documents operand kinds while doing those pushes:

```assembly
@Call(VVA) DiskFileWrite FilePtr Buffer 80
```

Here `V` means push a variable's value (`PUSHI`), `A` means push an immediate
address/value (`PUSH`), and `P` means push through a pointer (`PUSHII`). Use the
shortest signature matching the number and kinds of arguments.

A conventional routine saves its return address, allocates named locals, and
restores everything before returning:

```assembly
:AddToTotal
@PUSHRETURN
@Locals
    @Local Amount
    @POPI Amount
    @PUSHI Total @ADDI Amount @POPI Total
@EndLocals
@POPRETURN
@RET
```

Library exports additionally use `@FUNCTION Name` and `@ENDFUNCTION`. These
markers let the dependency-aware linker include only routines named by `#USE`.

## 6. Source and linking directives

| Directive | Use |
| --- | --- |
| `I file` | Textually include macros or source in the current label scope. |
| `L file` | Assemble a library/source file with its own local-label scope. |
| `D file` | Register a dynamic library; code is selected later with `#USE`. |
| `#USE name` | Request a dynamic function and its declared dependencies. |
| `G name` | Export a symbol from a library scope. |

Prefer `D library.ld` plus `#USE Function` in applications that need only a
small part of a library. Existing programs also use `L`; follow the surrounding
program unless size or dependency selection is part of the change.

## 7. Style guide

- Include `common.mc` for classic/Ring 0 code and `commonDS.mc` only for a
  deliberately segmented CPU24 build. Do not mix their storage models.
- Keep one macro invocation per source line when expansion or nested macro
  state could be ambiguous. Short, established sequences on one line are fine.
- Use `CamelCase` for routines and meaningful variables; reserve leading
  underscores for local/internal labels. Keep labels descriptive rather than
  encoding numeric addresses.
- Write stack contracts above public routines, for example
  `# Parse(Buffer, Length):Status`, and document ownership of heap objects.
- Balance every pushed argument and temporary on every branch. Consume boolean
  and comparison operands explicitly; structured tests often leave their
  original value on the stack.
- Prefer `@Call(...)`, grouped `@PUSHI2`/`@POPI2`, `@MA2V`, and `@MV2V` when
  they make value flow clearer. Use raw instructions when exact flag or stack
  behavior is the point.
- Use structured `@IF_*`, `@WHILE_*`, `@WHEN`, and `@For*` constructs for normal
  flow. Use direct jumps for cleanup paths or when the structure would obscure
  the actual machine behavior.
- Pair heap allocation with `HeapDeleteObject` and file opens with `DiskClose`
  on success and failure paths. Check error returns before dereferencing them.
- For CPU24, keep code labels under `:` and data under `::`; use segment
  overrides only for a known cross-segment access.
- End runnable programs with `@END`, keep reusable library routines between
  `@FUNCTION`/`@ENDFUNCTION`, and leave the hardware stack at the documented
  depth.

## 8. Build and debug loop

```sh
python3 cpu.py program.asm
python3 cpu.py -g program.asm
python3 cpu24.py program24.asm
python3 cpu24.py -g program24.asm
```

Useful options include `-l` for a listing, repeated `-d` for diagnostics, `-b`
for a breakpoint, and `-w` for a watched address. In CPU24 debugging, addresses
and source locations are segment-aware. Start with the normal Python emulator;
the optional `-f` backend is a speed optimization, not a different programming
model.
