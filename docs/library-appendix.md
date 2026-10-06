# EX716 Macro and Library Appendix

This appendix is a quick lookup for the interfaces used most often. It groups
families instead of listing every mechanically generated variant. In macro
names, `A` means an immediate address/value, `V` a value loaded from a variable,
`P` an indirect value, and `S` values already on the hardware stack.

## Common macro library

The classic definitions are in `lib/common.mc`; CPU24 segmented equivalents
are in `lib/commonDS.mc`. Unless noted, both provide the same source interface.

| Macro or family | Summary |
| --- | --- |
| `@PUSH`, `@PUSHI`, `@PUSHII`, `@PUSHS` | Push an immediate, direct-memory, indirect-memory, or stack-addressed value. These are native instruction wrappers and define the basic operand vocabulary. |
| `@POPI`, `@POPII`, `@POPS`, `@POPNULL`, `@SWP`, `@DUP` | Store, discard, exchange, or duplicate hardware-stack values. Use these explicitly when stack ownership matters. |
| `@MA2V`, `@MV2V` | Move an immediate value to a variable, or copy one variable to another. They are readable shorthands for push/store pairs. |
| `@LOAD*`, `@STORE*`, `@LOADB*`, `@STOREB*` | Load/store words or bytes through direct and indirect addresses. Byte stores preserve the neighboring byte in the containing word. |
| `@INCI`, `@DECI`, `@INC2I`, `@DEC2I` | Increment/decrement a memory variable by one or two. The two-byte forms are useful for walking word fields. |
| `@CMP*`, `@ADD*`, `@SUB*`, `@AND*`, `@OR*`, `@XOR*` | Native and convenience arithmetic/logic families across immediate, variable, indirect, and stack operands. Results remain on the hardware stack unless stored or discarded. |
| `@JZ`, `@JNZ`, `@JLT`, `@JLE`, `@JGT`, `@JGE` | Jump on zero/nonzero or signed comparison state. Signed forms account for overflow as well as the negative flag. |
| `@JULT`, `@JULE`, `@JUGT`, `@JUGE` | Unsigned comparison branches based on carry/zero state. Use these for addresses, sizes, and other unsigned values. |
| `@CALL`, `@CALLI`, `@RET` | Push a return address and jump directly/indirectly; `RET` jumps to the saved address. The callee must preserve the return value while consuming parameters. |
| `@Call(signature)` | Push up to five arguments according to an `A`, `V`, or `P` signature, then call the routine. For example, `@Call(VVA) F X Y 10` passes two variable values and one immediate. |
| `@PUSHRETURN`, `@POPRETURN` | Move a routine's hardware-stack return address to/from protected software-stack storage. Use them around routines that accept parameters or leave results. |
| `@Locals`, `@Local`, `@EndLocals` | Define a readable local-variable frame backed by the common temporary-variable convention. Locals are valid only inside the matching block. |
| `@PUSHI2` ... `@PUSHI5`; `@POPI2` ... `@POPI5` | Group repeated pushes or pops for argument handling. Remember that pop order is the reverse of push order. |
| `@PRT`, `@PRTLN`, `@PRTNL`, `@PRTSP` | Print literal text, text plus newline, a newline, or spaces through emulator CAST services. Literal strings are embedded in the code stream. |
| `@PRTI`, `@PRTUI`, `@PRTHEXI`, `@PRTSI` | Print a signed/unsigned integer, hexadecimal word, or string whose address is held in a variable. `*TOP` forms print a duplicate and preserve the original stack value. |
| `@READI`, `@READS`, `@READC`, `@READCNW` | Read an integer, string, character, or nonblocking character through POLL services. Character reads store a 16-bit tagged result: high byte 0=data, 1=EOF, 2=no input (nonblocking only), or 3=I/O error; the low byte contains data only when the status is 0. In cooked mode, Ctrl-Z (`0x1a`) is treated as EOF; raw mode preserves it as data. |
| C `<stdio.h>` console streams | `stdin`, `stdout`, `stderr`, basic character/line I/O, stream status, and formatted output are available through the current C runtime. `FILE` is opaque and console-only for now; `stdout` and `stderr` share the CAST output device. DiskOS-backed C streams are not yet implemented. |
| `@TTYNOECHO`, `@TTYECHO`, `@TTYRAW`, `@TTYRAWOFF` | Control terminal echo and raw mode. Restore terminal state before normal program exit when it was changed. |
| EX716 `<termios.h>` subset | `tcgetattr`/`tcsetattr` model only stdin plus `TCSANOW`, `ICANON`, and `ECHO`. This is a compatibility shim, not POSIX termios: other flags/actions/descriptors are rejected, and initial state is assumed cooked with echo enabled. |
| `@DISKSEL`, `@DISKSEEK`, `@DISKREAD`, `@DISKWRITE`, `@DISKSYNC` | Low-level virtual-disk device operations. Application file I/O should normally use `diskos.ld` instead. |
| `@STRSTACK` | Place a short NUL-terminated string on temporary stack-backed storage and leave its address for a call. Treat the address as temporary rather than heap-owned. |
| `@FUNCTION`, `@ENDFUNCTION`, `@USE` / `#USE` | Mark dynamically linkable routine boundaries and dependencies. Only requested routines and their declared dependencies are retained. |
| `@END`, `@StackDump`, `@DEBUGTOGGLE` | Stop emulation, display stack state, or toggle emulator diagnostics. These are host services rather than portable computation. |
| `@CSO`, `@DSO`, `@ESO`, `@SGET`, `@SSET` | CPU24-only segment override/get/set operations supplied by `commonDS.mc`. An override affects only the next applicable memory instruction. |
| `@FJMP`, `@FCALL`, `@FENTER`, `@FRET` | CPU24 Ring 1 far-control convention for crossing code banks and preserving bank plus return offset. Use the complete convention at both caller and callee. |

## Structured programming library

`lib/structure.asm` is included by the classic common library;
`lib/structureDS.ld` is its segmented counterpart. Most tests inspect stack
values without removing them, so clean up operands after the block when needed.

| Macro or family | Summary |
| --- | --- |
| `@IF_ZERO`, `@IF_NOTZERO` | Begin a conditional based on the top stack value. The tested value remains present for explicit cleanup. |
| `@IF_EQ_*`, `@IF_NEQ_*` | Compare stack, immediate, and variable combinations for equality/inequality. Suffixes identify the left/right operand sources. |
| `@IF_LT_*`, `@IF_LE_*`, `@IF_GT_*`, `@IF_GE_*` | Begin a signed relational conditional. Use the unsigned family for sizes and addresses. |
| `@IF_ULT_*`, `@IF_ULE_*`, `@IF_UGT_*`, `@IF_UGE_*` | Begin an unsigned relational conditional using carry-aware comparisons. |
| `@IF_INRANGE_*`, `@IF_UINRANGE_*` | Test whether a value is inside signed or unsigned bounds. Variants select immediate or variable bounds. |
| `@IF_NEG`, `@IF_POS`, `@IF_ZFLAG`, `@IF_CARRY`, `@IF_OVERFLOW` | Begin a branch based directly on processor flags; `NOT*` forms invert selected flag tests. Use immediately after the operation whose flags matter. |
| `@ELSE`, `@ENDIF` | Select the alternate arm and close an `IF` block. Macro state supplies unique labels, so blocks may be nested. |
| `@WHILE_*`, `@ENDWHILE` | Repeat while a built-in zero/equality/relational test remains true. The condition is checked at the top, so the body may execute zero times. |
| `@WHEN`, `@DO_ZERO` / `@DO_NOTZERO`, `@ENDWHEN` | Build a top-tested loop with a multiline custom condition. The condition code must leave a zero/nonzero value for `DO_*`. |
| `@LOOP`, `@UNTIL_ZERO` / `@UNTIL_NOTZERO` | Build a bottom-tested loop that executes at least once. Condition preparation appears immediately before `UNTIL_*`. |
| `@WHILEBREAK`, `@WHILECONTINUE`, `@FORBREAK`, `@FORCONTINUE` | Exit or continue the nearest supported loop. Existing macro nesting rules limit use from deeply nested conditional blocks. |
| `@SWITCH`, `@CASE`, `@CASE_V`, `@CDEFAULT`, `@ENDCASE` | Select among immediate/variable cases while sharing a single switch value. End an ordinary arm with `@CBREAK` unless fall-through is intentional. |
| `@CASE_RANGE_*`, `@CASE_URANGE_*` | Match signed or unsigned case ranges with immediate/variable endpoints. |
| `@CBREAK`, `@CASE_FALLTHRU` | Leave the switch or explicitly continue into the next case. These make case termination visible in source. |
| `@ForIA2B`, `@ForIV2V` and other `@For*` forms | Initialize an index and iterate between immediate (`A`), variable (`V`), or stack (`S`) bounds. `up`/`down` forms state direction explicitly. |
| `@Next`, `@NextBy`, `@NextByI`, `@NextByV` | Close a `For` loop and advance by one, an immediate step, or a variable step. Match the index used by the opening macro. |
| `@QuickMinI`, `@QuickMinAI` | Reorder two variables, or an immediate and variable, into low-to-high order. These are helpers used by range constructs. |

## Major standard-library services

Import these `.ld` files with `D`/`#USE` for dependency-selected linking or
with `L` when following an existing statically linked program.

### `lmath.ld`

`lmath.ld` contains both the current 32-bit routines and their `@Call32`,
`@POP32I`, and related helper macros. The legacy `lib/lmath.md` macro file is
not part of the current library interface.

| Service | Summary |
| --- | --- |
| `ADD32[S/U]`, `SUB32[S/U]` | Add or subtract two-word 32-bit values; signed/unsigned forms establish the corresponding emulated flags. |
| `CMP32S`, `CMP32U`, `SetFlags32` | Compare 32-bit values and publish `C32Flag`, `N32Flag`, `Z32Flag`, and `O32Flag` state. |
| `MUL32S`, `MUL32U`, `DIV32S`, `DIV32U` | Perform signed or unsigned 32-bit multiplication and division. |
| `AND32`, `OR32`, `XOR32`, `INV32`, `COMP232` | Apply 32-bit boolean operations, inversion, or two's complement. |
| `SHL32`, `SHR32`, fixed/small variants | Shift a two-word 32-bit value; specialized one/eight/small-count forms avoid general-loop overhead. |
| `MUL16x32U`, `SHL16x32`, `SHR16x32`, `SHL3264` | Bridge 16-, 32-, and 64-bit intermediate operations used by arithmetic code. |
| `SetBit32`, `ClearBit32` | Set or clear a selected bit in a 32-bit value. |
| `DIV10_32U`, `i32tos`, `stoi32` | Support decimal conversion and unsigned divide-by-ten for 32-bit numbers. |

### `random.ld`

| Service | Summary |
| --- | --- |
| `rndsetseed` | Set the generator seed so runs can be reproduced. |
| `rnd16` | Return the next 16-bit pseudorandom value from the lightweight generator. |
| `rndint` | Return a bounded integer from the lightweight generator. |
| `frnd16` | Return a 16-bit result from the fuller 32-bit LCG state. |
| `frndint` | Return a bounded integer using the fuller generator. |

### `string.ld`

| Service | Summary |
| --- | --- |
| `strlen`, `strcpy`, `strncpy`, `strcat`, `strncat` | Measure, copy, and concatenate NUL-terminated strings with bounded variants where supplied. |
| `strcmp`, `strncmp` | Compare complete strings or at most a specified number of characters. |
| `strchr`, `strrchr`, `strstr`, `strfndc` | Find a character, last character, substring, or delimiter-related position. |
| `memcpy` | Copy an explicit number of bytes without interpreting NUL terminators. |
| `itos`, `stoi`, `stoifirst` | Convert integers to/from text, including parsing the first numeric portion. |
| `ISAlphaNum`, `ISAlpha`, `ISNumeric` | Classify a character according to common text categories. |
| `strtok`, `splitstr`, `SplitDelete` | Tokenize or split text and release split results created by the library. |
| `strUpCase`, `strLowCase` | Convert string characters to upper or lower case in place. |
| `@STRSET`, `@STRSETI` | Macro helpers for copying a literal/string source into direct or indirect destinations. |

### `heapmgr.ld`

| Service | Summary |
| --- | --- |
| `HeapDefineMemory` | Turn an address range into a heap and return its heap ID. |
| `HeapNewObject` | Allocate an object and return its object ID/address; small values below 100 are reserved for errors. |
| `HeapResizeObject` | Resize an existing object, possibly returning a changed object ID. |
| `HeapDeleteObject` | Release an object owned by the specified heap. |
| `HeapAvailable`, `GetObjectRealSize` | Report total free space or the physical size of one allocation. |
| `HeapDefrag` | Coalesce/reorganize free heap space. |
| `HeapAppend` | Combine object data with an offset and return the resulting object. |
| `HeapListMap`, `HeapValidate` | Print allocator state or validate heap metadata for diagnostics. |

### `softstack.ld`

| Service | Summary |
| --- | --- |
| `SetSSStack` | Configure the software-stack bottom/top range; call this before deep use when the default area is insufficient. |
| `__MOVE_HW_SS`, `__MOVE_SS_HW` | Move values between the hardware evaluation stack and the memory-backed software stack. Normally use higher-level macros. |
| `SaveStack`, `RestoreStack` | Save and restore software-stack state around a protected operation. |
| `__SS_TOP`, `__SS_BOTTOM`, `__SS_SP` | Exported stack bounds and current pointer for diagnostics and low-level integration. |

For exact parameter order and return contracts, read the comment immediately
above the selected routine in its `.ld` file; this appendix intentionally
describes services rather than reproducing every internal implementation.
