# Function Index for `cpu.py`

Auto-generated from source + `.info`.

## Class: **AssemblerContext**

### `__init__(self)`  
*Line 196*

### `restore_tty()`  
*Line 302*
- **Description:** Restore terminal settings after raw/no-echo input modes.

### `restore_tty()`  
*Line 308*
- **Description:** Restore terminal settings after raw/no-echo input modes.
- **Docstring:**
```
Turn echo off, leave canonical mode as-is.
```

### `PollSetNoEchoFunc(arg=None)`  
*Line 317*
- **Description:** Enable terminal input without local echo for single-character reads.
- **Docstring:**
```
Turn echo back on, leave canonical mode as-is.
```

### `PollSetEchoFunc(arg=None)`  
*Line 323*
- **Description:** Re-enable terminal echo after no-echo mode.
- **Docstring:**
```
Put terminal into full raw mode, save old settings.
```

### `PollSetRawFunc(arg=None)`  
*Line 330*
- **Description:** Put terminal in raw mode for unbuffered character input.

### `PollReSetRawFunc(arg=None)`  
*Line 344*
- **Description:** Restore terminal from raw mode back to previous configuration.

### `PollTTYStateFunc(arg=None)`  
*Line 367*
- **Description:** Return current TTY mode/state information.
- **Docstring:**
```
Restore terminal state saved by tty_setraw.
```

### `tty_reset(_fd=sys.stdin.fileno())`  
*Line 388*
- **Description:** Force terminal settings back to sane defaults.

### `shandler(signum, frame)`  
*Line 399*
- **Description:** Signal handler for break/interrupt during assembly or debug.

### `is_string_numeric(s)`  
*Line 408*
- **Description:** Return True if string matches decimal/hex/octal/binary integer syntax.

### `digitsonly(s)`  
*Line 411*
- **Description:** Return True if string contains only digit characters.

### `create_new_filename(original_filename, new_extension)`  
*Line 417*
- **Description:** Generate a new output filename based on prefix or numeric suffix.

### `create_new_unique()`  
*Line 427*
- **Description:** Return a guaranteed-unique temporary filename.

### `validatestr(instr, typecode)`  
*Line 433*
- **Description:** Parse string for 0x, 0o, 0b prefixes and validate numeric syntax.

### `UpdateVarHistory(varname, value, address)`  
*Line 456*
- **Description:** Record a variable's assigned value and the memory address where it was defined.

### `FindHistoricVal(varname, testaddress, context=None)`  
*Line 461*
- **Description:** "Return the value of a local variable name whose definitions may occur multiple times

### `FindLabelMatch(varname, context: AssemblerContext)`  
*Line 496*
- **Description:** "Look up a label by exact or prefix match

### `Sort_And_Combine_Labels(inboundtext)`  
*Line 517*
- **Description:** "Return human-readable label list

## Class: **InputFileData**

### `__init__(self)`  
*Line 554*
- **Description:** TODO: describe __init__

### `add_entry(self, filename, line_number, memory_address)`  
*Line 559*
- **Description:** Record mapping of (filename,line) → memory address for symbolic debugging.

### `get_line_info(self, memory_address, exact=False)`  
*Line 570*
- **Description:** Return symbolic source mapping for a given memory address.

### `get_nearest_address(self, filename, line_number)`  
*Line 581*
- **Description:** Return nearest lower-or-equal symbolic address.

### `safeprint(*args, **kwargs)`  
*Line 615*
- **Description:** Print while escaping unprintable characters.

## Class: **microcpu**

### `switcher(self, optcall, argument)`  
*Line 639*
- **Description:** TODO: describe switcher

### `__init__(self, origin, memsize)`  
*Line 645*
- **Description:** Initialize memory, registers, flags, stacks, handlers, and execution state.

### `insertbyte(self, location, value)`  
*Line 667*
- **Description:** Write a single byte to memory at the specified address.

### `getwordstack(self, index)`  
*Line 672*
- **Description:** Fetch a 16-bit value from the hardware stack.

### `getwordmem(self, index)`  
*Line 675*
- **Description:** Fetch a 16-bit value from RAM.

### `dumpstack(self,stack)`  
*Line 678*
- **Description:** Display current contents of the hardware stack.

### `FindWhatLine(self, address)`  
*Line 699*
- **Description:** Map an instruction address back to a source line.

### `FindAddressLine(self, line_info)`  
*Line 707*
- **Description:** Return stored mapping for filename/line to memory address.

### `raiseerror(self, idcode)`  
*Line 719*
- **Description:** Raise a CPU/runtime error with diagnostic output.

### `lowbyte(self, invalue)`  
*Line 798*
- **Description:** Return low 8 bits of a 16-bit value.

### `highbyte(self, invalue)`  
*Line 802*
- **Description:** Return high 8 bits of a 16-bit value.

### `fetchAcum(self, address)`  
*Line 806*
- **Description:** Return accumulator value (direct or loaded).

### `StoreAcum(self, address, value)`  
*Line 823*
- **Description:** Store accumulator value into memory.

### `getwordat(self, address)`  
*Line 837*
- **Description:** Return a 16-bit value from an explicit address.

### `putwordat(self, address, value)`  
*Line 847*
- **Description:** Store a 16-bit value to an explicit address.

### `optNOP(self, count)`  
*Line 854*
- **Description:** TODO: describe optNOP

### `optPUSH(self, invalue)`  
*Line 857*
- **Description:** Push literal operand onto TOS. EX716 Emulator Function

### `optDUP(self, address)`  
*Line 867*
- **Description:** Duplicate TOS. EX716 Emulator Function

### `optPUSHI(self, address)`  
*Line 877*
- **Description:** Push value loaded Indirect from address operand. (I = Indirect)

### `optPUSHII(self, address)`  
*Line 891*
- **Description:** Push value loaded via Double Indirect pointer dereference. (II = Pointer)

### `optPUSHS(self, address)`  
*Line 907*
- **Description:** Push from soft stack / secondary stack. (S = Stack variant)

### `optPOPNULL(self, address)`  
*Line 912*
- **Description:** Pop and discard TOS.

### `optSWP(self, address)`  
*Line 920*
- **Description:** Swap TOS and SFT.

### `optPOPI(self, address)`  
*Line 931*
- **Description:** Pop TOS and store to address loaded Indirect.

### `optPOPII(self, firstaddress)`  
*Line 947*
- **Description:** Pop TOS and store through Double Indirect.

### `optPOPS(self, notused)`  
*Line 957*
- **Description:** Pop TOS into soft stack.

### `SetFlags(self, A1, WasSubt)`  
*Line 965*
- **Description:** TODO: describe SetFlags

### `OverCarryTest(self, a, b, c, IsSubtraction)`  
*Line 973*
- **Description:** TODO: describe OverCarryTest

### `optCMP(self, asvalue)`  
*Line 1003*
- **Description:** TODO: describe optCMP

### `optCMPS(self, address)`  
*Line 1010*
- **Description:** Compare SFT − TOS using stack values only.

### `optCMPI(self, address)`  
*Line 1017*
- **Description:** Compare TOS with operand loaded Indirect.

### `optCMPII(self, address)`  
*Line 1024*
- **Description:** Compare TOS with operand loaded through Double Indirect.

### `optADD(self, invalue)`  
*Line 1031*
- **Description:** TODO: describe optADD

### `optADDS(self, invalue)`  
*Line 1039*
- **Description:** TOS = SFT + TOS (stack-only form).

### `optADDI(self, address)`  
*Line 1048*
- **Description:** TOS = TOS + value loaded Indirect.

### `optADDII(self, address)`  
*Line 1054*
- **Description:** TOS = TOS + value loaded Double Indirect.

### `optSUB(self, invalue)`  
*Line 1062*
- **Description:** TOS = TOS − direct operand.

### `optSUBS(self, invalue)`  
*Line 1071*
- **Description:** TOS = SFT − TOS (stack-only form).

### `optSUBI(self, address)`  
*Line 1080*
- **Description:** TOS = TOS − value loaded Indirect.

### `optSUBII(self, address)`  
*Line 1088*
- **Description:** TOS = TOS − value loaded Double Indirect.

### `optOR(self, ivalue)`  
*Line 1096*
- **Description:** TODO: describe optOR

### `optORS(self, ivalue)`  
*Line 1104*
- **Description:** TOS = SFT | TOS (stack-only form).

### `optORI(self, address)`  
*Line 1113*
- **Description:** TOS = TOS | value loaded Indirect.

### `optORII(self, address)`  
*Line 1119*
- **Description:** TOS = TOS | value loaded Double Indirect.

### `optAND(self, ivalue)`  
*Line 1127*
- **Description:** TOS = TOS & direct operand.

### `optANDS(self, ivalue)`  
*Line 1135*
- **Description:** TOS = SFT & TOS (stack-only form).

### `optANDI(self, address)`  
*Line 1144*
- **Description:** TOS = TOS & operand loaded Indirect.

### `optANDII(self, address)`  
*Line 1150*
- **Description:** TOS = TOS & operand loaded Double Indirect.

### `optXOR(self, ivalue)`  
*Line 1157*
- **Description:** TOS = TOS ^ direct operand.

### `optXORS(self, ivalue)`  
*Line 1164*
- **Description:** TOS = SFT ^ TOS (stack-only form).

### `optXORI(self, address)`  
*Line 1174*
- **Description:** TOS = TOS ^ value loaded Indirect.

### `optXORII(self, address)`  
*Line 1180*
- **Description:** TOS = TOS ^ value loaded Double Indirect.

### `optJMPZ(self, address)`  
*Line 1188*
- **Description:** TODO: describe optJMPZ

### `optJMPN(self, address)`  
*Line 1195*
- **Description:** Jump if negative flag is set.

### `optJMPC(self, address)`  
*Line 1202*
- **Description:** Jump if carry flag is set.

### `optJMPO(self, address)`  
*Line 1209*
- **Description:** Jump if overflow flag is set.

### `optJMP(self, address)`  
*Line 1216*
- **Description:** Unconditional jump.

### `optJMPI(self, address)`  
*Line 1222*
- **Description:** Jump to address loaded Indirect.

### `optJMPS(self,address)`  
*Line 1226*
- **Description:** Jump to address taken from TOS.

### `optCAST(self, address)`  
*Line 1231*
- **Description:** TODO: describe optCAST

### `optPOLL(self, address)`  
*Line 1471*
- **Description:** Poll hardware or I/O source.

### `optRRTC(self, unused)`  
*Line 1643*
- **Description:** Rotate TOS right through carry.

### `optRLTC(self, unused)`  
*Line 1655*
- **Description:** Rotate TOS left through carry.

### `optSHR(self, unused)`  
*Line 1667*
- **Description:** Logical right shift of TOS.

### `optSHL(self, unused)`  
*Line 1676*
- **Description:** Logical left shift of TOS.

### `optINV(self, address)`  
*Line 1684*
- **Description:** Bitwise invert TOS.

### `optCOMP2(self, address)`  
*Line 1692*
- **Description:** Replace TOS with its two’s complement.

### `optFCLR(self, address)`  
*Line 1700*
- **Description:** Clear condition flags register.

### `optFSAV(self, address)`  
*Line 1703*
- **Description:** Push flags register onto soft stack.

### `optFLOD(self, address)`  
*Line 1706*
- **Description:** Pop flags register from soft stack.

### `optADM(self,address)`  
*Line 1716*
- **Description:** Administrative/system instruction (page register, admin mode, or privileged actions).

### `optSCLR(self,address)`  
*Line 1721*
- **Description:** Clear hardware or soft-state register (architecture-dependent).

### `optSRPT(self,address)`  
*Line 1724*
- **Description:** "Push current soft-stack depth

### `evalpc(self, context, dosteps)`  
*Line 1731*
- **Description:** TODO: describe evalpc

### `_evalpc_c_OLD(self, context, dosteps)`  
*Line 1783*
- **Description:** Legacy C-accelerated execution loop (retained for comparison).

### `_evalpc_c(self, context, dosteps)`  
*Line 1814*
- **Description:** Current optimized C-accelerated execution core.

### `step_one()`  
*Line 1823*
- **Description:** Execute a single instruction cycle.

### `_evalpc_py(self, context, dosteps)`  
*Line 1936*
- **Description:** Pure Python execution loop.

### `_handle_return_code(self, code)`  
*Line 2011*
- **Description:** Interpret halts, breaks, and return codes.

### `removecomments(inline)`  
*Line 2040*
- **Description:** TODO: describe removecomments

### `GetQuoted(inline)`  
*Line 2105*
- **Description:** Extract quoted string token with escapes.

### `GetRawQuoted(inline)`  
*Line 2149*
- **Description:** Extract quoted string without interpreting escapes.

### `nextwordplus(ltext)`  
*Line 2166*
- **Description:** Return next token plus number of characters consumed.

### `nextword(ltext)`  
*Line 2182*
- **Description:** Return next parsed token.

### `Str2Word(instr)`  
*Line 2219*
- **Description:** Convert numeric string to a 16-bit word.

### `Str32Word(instr)`  
*Line 2226*
- **Description:** Convert numeric string to a 32-bit word.

### `Str2Byte(instr)`  
*Line 2270*
- **Description:** Convert numeric string to an 8-bit byte.

### `DissAsm(start, length, CPU)`  
*Line 2275*
- **Description:** Disassemble a machine instruction into human-readable format.

### `reverse_lookup(my_dict)`  
*Line 2369*
- **Description:** Return mnemonic given opcode value.

### `getkeyfromval(val, my_dict)`  
*Line 2374*
- **Description:** Reverse-search dictionary to find key for matching value.

### `hexdump(startaddr, length, CPU)`  
*Line 2408*
- **Description:** Format region of memory as hex dump.

### `fileonpath(filename)`  
*Line 2443*
- **Description:** Search PATH-like list for file.

### `IsLocalVar(inlabel,  context: AssemblerContext)`  
*Line 2463*
- **Description:** Return True if token refers to a local variable name.

### `parse_arg(segment, filename, context)`  
*Line 2477*
- **Description:** Parse assembler argument, including stack, indirect, and size modes.

### `ReplaceMacStr(line, filename, context)`  
*Line 2519*
- **Description:** Perform macro string substitution.

### `ReplaceMacVars(line,  filename, context: AssemblerContext)`  
*Line 2525*
- **Description:** Substitute macro variables with bound values.

### `FirstPassVal(instr,  context: AssemblerContext)`  
*Line 2716*
- **Description:** Compute value of expression in first assembler pass.

### `parse_expression(expr)`  
*Line 2737*
- **Description:** Parse full symbolic expression into evaluable form.

### `decode_token(token, curaddress, CPU,  JUSTRESULT, context: AssemblerContext)`  
*Line 2764*
- **Description:** Interpret token as symbol, number, or operator.

### `DecodeStr(instr, curaddress, CPU,  JUSTRESULT, context: AssemblerContext)`  
*Line 2815*
- **Description:** Evaluate expression string and return numeric value.

### `loadfile(filename, offset, CPU, LorgFlag,  LocalID, context: AssemblerContext)`  
*Line 2877*
- **Description:** Load and assemble source file (multi-pass).

### `debugger(passline, context: AssemblerContext)`  
*Line 3344*
- **Description:** Interactive debugger for stepping and breakpoints.

### `main()`  
*Line 3972*
- **Description:** Top-level driver entry for standalone execution.

## Top-Level Functions

### `get_key()`  
*Line 96*
- **Description:** TODO: describe get_key

### `setup_raw()`  
*Line 106*
- **Description:** TODO: describe setup_raw

### `restore_tty(state)`  
*Line 110*
- **Description:** TODO: describe restore_tty

### `setup_raw(fd=sys.stdin.fileno())`  
*Line 117*
- **Description:** TODO: describe setup_raw

### `restore_tty(state)`  
*Line 140*
- **Description:** TODO: describe restore_tty

### `get_key(fd=sys.stdin.fileno())`  
*Line 147*
- **Description:** TODO: describe get_key

### `quote_escape_string(s)`  
*Line 170*
- **Description:** TODO: describe quote_escape_string

### `escape_for_reinsertion(s)`  
*Line 182*
- **Description:** TODO: describe escape_for_reinsertion

