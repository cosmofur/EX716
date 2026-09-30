# Function Index for `cpu(12).py`

> Generated from the Python AST. Call relationships are static approximations: dynamic dispatch, indirect calls through tables, string-built names, and runtime-selected callbacks may be under-reported.

- Source file: `cpu(12).py`
- Functions/methods indexed: **177**
- Root functions detected: [`main`](#main), [`safeprint`](#safeprint)
- Reachable from root call tree: **86**
- Orphan/disconnected from root call tree: **91**


## Major Function Groups

### Assembler context / conditional block state

State attached to a single assembly run: labels, macro variables, conditional-block stack, comparison, and conditional execution.

[`AssemblerContext.__init__`](#assemblercontextinit), [`AssemblerContext.max_macro_arg_index`](#assemblercontextmaxmacroargindex), [`AssemblerContext.define_macro`](#assemblercontextdefinemacro), [`AssemblerContext.macro_or_label_exists`](#assemblercontextmacroorlabelexists), [`AssemblerContext.push_block`](#assemblercontextpushblock), [`AssemblerContext._next_block_id`](#assemblercontextnextblockid), [`AssemblerContext.pop_block`](#assemblercontextpopblock), [`AssemblerContext.handle_elseblock`](#assemblercontexthandleelseblock), [`AssemblerContext.current_block`](#assemblercontextcurrentblock), [`AssemblerContext.parent_executing`](#assemblercontextparentexecuting), [`AssemblerContext.is_executing`](#assemblercontextisexecuting), [`AssemblerContext.smart_compare`](#assemblercontextsmartcompare), [`AssemblerContext.eval_cond_arg`](#assemblercontextevalcondarg), [`AssemblerContext.evaluate_condition`](#assemblercontextevaluatecondition), [`AssemblerContext.eval_arg`](#assemblercontextevalarg)

### Assembly loading, labels, directives, and memory emission

File loading, assembler command execution, directive handling, symbol definition, and output-memory construction.

[`create_new_filename`](#createnewfilename), [`FindLabelMatch`](#findlabelmatch), [`Sort_And_Combine_Labels`](#sortandcombinelabels), [`handle_semicolon`](#handlesemicolon), [`fileonpath`](#fileonpath), [`handle_skipped_command`](#handleskippedcommand), [`read_next_source_command`](#readnextsourcecommand), [`loadfile`](#loadfile), [`consumed_one_source_command`](#consumedonesourcecommand), [`skip_one_source_command`](#skiponesourcecommand), [`execute_assembler_command`](#executeassemblercommand), [`IsLabelActive`](#islabelactive)

### CPU emulator core and opcode handlers

The microcoded/emulated EX716 instruction set plus CPU memory, stack, flags, error, and instruction-dispatch support.

[`microcpu.__init__`](#microcpuinit), [`microcpu.insertbyte`](#microcpuinsertbyte), [`microcpu.getwordmem`](#microcpugetwordmem), [`microcpu.dumpstk`](#microcpudumpstk), [`microcpu.FindWhatLine`](#microcpufindwhatline), [`microcpu.FindAddressLine`](#microcpufindaddressline), [`microcpu.raiseerror`](#microcpuraiseerror), [`microcpu.lowbyte`](#microcpulowbyte), [`microcpu.highbyte`](#microcpuhighbyte), [`microcpu.fetchStack`](#microcpufetchstack), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.putwordat`](#microcpuputwordat), [`microcpu.optNOP`](#microcpuoptnop), [`microcpu.optPUSH`](#microcpuoptpush), [`microcpu.optDUP`](#microcpuoptdup), [`microcpu.optPUSHI`](#microcpuoptpushi), [`microcpu.optPUSHII`](#microcpuoptpushii), [`microcpu.optPUSHS`](#microcpuoptpushs), [`microcpu.optPOPNULL`](#microcpuoptpopnull), [`microcpu.optSWP`](#microcpuoptswp), [`microcpu.optPOPI`](#microcpuoptpopi), [`microcpu.optPOPII`](#microcpuoptpopii), [`microcpu.optPOPS`](#microcpuoptpops), [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.OverCarryTest`](#microcpuovercarrytest), [`microcpu.optCMP`](#microcpuoptcmp), [`microcpu.optCMPS`](#microcpuoptcmps), [`microcpu.optCMPI`](#microcpuoptcmpi), [`microcpu.optCMPII`](#microcpuoptcmpii), [`microcpu.optADD`](#microcpuoptadd), [`microcpu.optADDS`](#microcpuoptadds), [`microcpu.optADDI`](#microcpuoptaddi), [`microcpu.optADDII`](#microcpuoptaddii), [`microcpu.optSUB`](#microcpuoptsub), [`microcpu.optSUBS`](#microcpuoptsubs), [`microcpu.optSUBI`](#microcpuoptsubi), [`microcpu.optSUBII`](#microcpuoptsubii), [`microcpu.optOR`](#microcpuoptor), [`microcpu.optORS`](#microcpuoptors), [`microcpu.optORI`](#microcpuoptori), [`microcpu.optORII`](#microcpuoptorii), [`microcpu.optAND`](#microcpuoptand), [`microcpu.optANDS`](#microcpuoptands), [`microcpu.optANDI`](#microcpuoptandi), [`microcpu.optANDII`](#microcpuoptandii), [`microcpu.optXOR`](#microcpuoptxor), [`microcpu.optXORS`](#microcpuoptxors), [`microcpu.optXORI`](#microcpuoptxori), [`microcpu.optXORII`](#microcpuoptxorii), [`microcpu.optJMPZ`](#microcpuoptjmpz), [`microcpu.optJMPN`](#microcpuoptjmpn), [`microcpu.optJMPC`](#microcpuoptjmpc), [`microcpu.optJMPO`](#microcpuoptjmpo), [`microcpu.optJMP`](#microcpuoptjmp), [`microcpu.optJMPI`](#microcpuoptjmpi), [`microcpu.optJMPS`](#microcpuoptjmps), [`microcpu.optRRTC`](#microcpuoptrrtc), [`microcpu.optRLTC`](#microcpuoptrltc), [`microcpu.optSHR`](#microcpuoptshr), [`microcpu.optSHL`](#microcpuoptshl), [`microcpu.optINV`](#microcpuoptinv), [`microcpu.optCOMP2`](#microcpuoptcomp2), [`microcpu.optFCLR`](#microcpuoptfclr), [`microcpu.optFSAV`](#microcpuoptfsav), [`microcpu.optFLOD`](#microcpuoptflod), [`microcpu.optADM`](#microcpuoptadm), [`microcpu.optSCLR`](#microcpuoptsclr), [`microcpu.optSRPT`](#microcpuoptsrpt)

### Macro expansion and macro command processing

Macro definition/invocation pipeline, `%` and brace expansion, repeat/control constructs, and macro side effects.

[`next_macro_arg`](#nextmacroarg), [`expand_brace_refs`](#expandbracerefs), [`parse_percent_arg`](#parsepercentarg), [`expand_macro_pipeline`](#expandmacropipeline), [`substitute_macro_params_only`](#substitutemacroparamsonly), [`substitute_macro_stack_opts`](#substitutemacrostackopts), [`expand_percent_functions`](#expandpercentfunctions), [`OLD_ReplaceMacVars_OLD`](#oldreplacemacvarsold), [`find_matching_percent_paren`](#findmatchingpercentparen), [`macro_arg_value`](#macroargvalue), [`macro_stack_value`](#macrostackvalue), [`macro_take_raw_frame`](#macrotakerawframe), [`macro_pop_frame`](#macropopframe), [`macro_apply_backfill`](#macroapplybackfill), [`macro_has_pending_text`](#macrohaspendingtext), [`macro_take_next_statement`](#macrotakenextstatement), [`expand_macro_invocation`](#expandmacroinvocation), [`expand_macro_invocation_text`](#expandmacroinvocationtext), [`parse_macro_definition_command`](#parsemacrodefinitioncommand)

### Miscellaneous utilities

Small helpers that do not fit cleanly into the other categories.

[`skip_ws`](#skipws), [`create_new_unique`](#createnewunique), [`microcpu._handle_return_code`](#microcpuhandlereturncode), [`removecomments`](#removecomments), [`check_loss`](#checkloss), [`Str2Word`](#str2word), [`Str32Word`](#str32word), [`Str2Byte`](#str2byte), [`getkeyfromval`](#getkeyfromval), [`hexdump`](#hexdump), [`parse_arg`](#parsearg), [`parse_expression`](#parseexpression), [`IsUserSymbol`](#isusersymbol), [`IsCompilerGenerated`](#iscompilergenerated), [`FinalSymbolReport`](#finalsymbolreport), [`read_next_physical_line`](#readnextphysicalline), [`queue_tail`](#queuetail), [`enqueue_front`](#enqueuefront), [`longest_prefix_match`](#longestprefixmatch), [`resolve_all_forward_references`](#resolveallforwardreferences), [`CloseLocalHistories`](#closelocalhistories)

### Parsing, tokenizing, and expression/value decoding

Lexical helpers, expression decoding, symbol/local expansion, numeric conversion, and first-pass value handling.

[`quote_escape_string`](#quoteescapestring), [`escape_for_reinsertion`](#escapeforreinsertion), [`is_string_numeric`](#isstringnumeric), [`digitsonly`](#digitsonly), [`validatestr`](#validatestr), [`microcpu.evalpc`](#microcpuevalpc), [`microcpu._evalpc_c`](#microcpuevalpcc), [`microcpu._evalpc_py`](#microcpuevalpcpy), [`GetQuoted`](#getquoted), [`GetRawQuoted`](#getrawquoted), [`nextwordplus`](#nextwordplus), [`nextwordequation`](#nextwordequation), [`nextword`](#nextword), [`IsLocalVar`](#islocalvar), [`FirstPassVal`](#firstpassval), [`decode_token`](#decodetoken), [`DecodeStr`](#decodestr), [`split_at_semicolon_outside_quotes`](#splitatsemicolonoutsidequotes), [`expand_unquoted_text`](#expandunquotedtext), [`split_source_commands`](#splitsourcecommands), [`looks_numeric`](#looksnumeric)

### Program entry / top-level control

Startup, shutdown, signal handling, and global debug/printing support.

[`dprint`](#dprint), [`shandler`](#shandler), [`safeprint`](#safeprint), [`main`](#main)

### Source map and debugger helpers

Mappings from source lines to memory addresses, debugger interaction, disassembly, breakpoints, watchpoints, and diagnostics.

[`UpdateVarHistory`](#updatevarhistory), [`FindHistoricVal`](#findhistoricval), [`InputFileData.__init__`](#inputfiledatainit), [`InputFileData.add_entry`](#inputfiledataaddentry), [`InputFileData.get_line_info`](#inputfiledatagetlineinfo), [`InputFileData.get_nearest_address`](#inputfiledatagetnearestaddress), [`DissAsm`](#dissasm), [`debugger`](#debugger)

### Terminal, keyboard, and POLL/CAST host I/O

Host-side terminal mode, keyboard polling, emulated CAST/POLL device services, and stdout/stderr bridge behavior.

[`PollSetNoEchoFunc`](#pollsetnoechofunc), [`PollSetEchoFunc`](#pollsetechofunc), [`PollSetRawFunc`](#pollsetrawfunc), [`PollReSetRawFunc`](#pollresetrawfunc), [`PollTTYStateFunc`](#pollttystatefunc), [`tty_reset`](#ttyreset), [`microcpu.optCAST`](#microcpuoptcast), [`microcpu.optPOLL`](#microcpuoptpoll)


## Orphan / Disconnected Function Bushes

A function is marked **orphan** when no static path from top-level execution/`main` reaches it. Some entries may still be runtime-reachable through opcode tables, callback dictionaries, debugger commands, or string-based dispatch.

- **Bush 3** (3): [`AssemblerContext.current_block`](#assemblercontextcurrentblock), [`AssemblerContext.handle_elseblock`](#assemblercontexthandleelseblock), [`AssemblerContext.parent_executing`](#assemblercontextparentexecuting)
- **Bush 4** (2): [`InputFileData.add_entry`](#inputfiledataaddentry), [`read_next_physical_line`](#readnextphysicalline)
- **Bush 5** (2): [`OLD_ReplaceMacVars_OLD`](#oldreplacemacvarsold), [`parse_arg`](#parsearg)
- **Bush 6** (1): [`AssemblerContext.__init__`](#assemblercontextinit)
- **Bush 7** (1): [`AssemblerContext.eval_cond_arg`](#assemblercontextevalcondarg)
- **Bush 8** (1): [`AssemblerContext.smart_compare`](#assemblercontextsmartcompare)
- **Bush 9** (1): [`CloseLocalHistories`](#closelocalhistories)
- **Bush 10** (1): [`FindLabelMatch`](#findlabelmatch)
- **Bush 11** (1): [`InputFileData.__init__`](#inputfiledatainit)
- **Bush 12** (1): [`IsUserSymbol`](#isusersymbol)
- **Bush 13** (1): [`check_loss`](#checkloss)
- **Bush 14** (1): [`escape_for_reinsertion`](#escapeforreinsertion)
- **Bush 15** (1): [`find_matching_percent_paren`](#findmatchingpercentparen)
- **Bush 16** (1): [`is_string_numeric`](#isstringnumeric)
- **Bush 17** (1): [`macro_apply_backfill`](#macroapplybackfill)
- **Bush 18** (1): [`macro_arg_value`](#macroargvalue)
- **Bush 19** (1): [`macro_has_pending_text`](#macrohaspendingtext)
- **Bush 20** (1): [`macro_pop_frame`](#macropopframe)
- **Bush 21** (1): [`macro_stack_value`](#macrostackvalue)
- **Bush 22** (1): [`macro_take_next_statement`](#macrotakenextstatement)
- **Bush 23** (1): [`macro_take_raw_frame`](#macrotakerawframe)
- **Bush 24** (1): [`microcpu.__init__`](#microcpuinit)
- **Bush 25** (1): [`microcpu.dumpstk`](#microcpudumpstk)
- **Bush 26** (1): [`microcpu.optADM`](#microcpuoptadm)
- **Bush 27** (1): [`microcpu.optCAST`](#microcpuoptcast)
- **Bush 28** (1): [`microcpu.optDUP`](#microcpuoptdup)
- **Bush 29** (1): [`microcpu.optFCLR`](#microcpuoptfclr)
- **Bush 30** (1): [`microcpu.optFLOD`](#microcpuoptflod)
- … 20 additional small bushes omitted from this summary; individual function entries still mark reachability.


## Linked Function Index


### Assembler context / conditional block state

- [`AssemblerContext.__init__`](#assemblercontextinit)
- [`AssemblerContext._next_block_id`](#assemblercontextnextblockid)
- [`AssemblerContext.current_block`](#assemblercontextcurrentblock)
- [`AssemblerContext.define_macro`](#assemblercontextdefinemacro)
- [`AssemblerContext.eval_arg`](#assemblercontextevalarg)
- [`AssemblerContext.eval_cond_arg`](#assemblercontextevalcondarg)
- [`AssemblerContext.evaluate_condition`](#assemblercontextevaluatecondition)
- [`AssemblerContext.handle_elseblock`](#assemblercontexthandleelseblock)
- [`AssemblerContext.is_executing`](#assemblercontextisexecuting)
- [`AssemblerContext.macro_or_label_exists`](#assemblercontextmacroorlabelexists)
- [`AssemblerContext.max_macro_arg_index`](#assemblercontextmaxmacroargindex)
- [`AssemblerContext.parent_executing`](#assemblercontextparentexecuting)
- [`AssemblerContext.pop_block`](#assemblercontextpopblock)
- [`AssemblerContext.push_block`](#assemblercontextpushblock)
- [`AssemblerContext.smart_compare`](#assemblercontextsmartcompare)

### Assembly loading, labels, directives, and memory emission

- [`FindLabelMatch`](#findlabelmatch)
- [`IsLabelActive`](#islabelactive)
- [`Sort_And_Combine_Labels`](#sortandcombinelabels)
- [`consumed_one_source_command`](#consumedonesourcecommand)
- [`create_new_filename`](#createnewfilename)
- [`execute_assembler_command`](#executeassemblercommand)
- [`fileonpath`](#fileonpath)
- [`handle_semicolon`](#handlesemicolon)
- [`handle_skipped_command`](#handleskippedcommand)
- [`loadfile`](#loadfile)
- [`read_next_source_command`](#readnextsourcecommand)
- [`skip_one_source_command`](#skiponesourcecommand)

### CPU emulator core and opcode handlers

- [`microcpu.FindAddressLine`](#microcpufindaddressline)
- [`microcpu.FindWhatLine`](#microcpufindwhatline)
- [`microcpu.OverCarryTest`](#microcpuovercarrytest)
- [`microcpu.SetFlags`](#microcpusetflags)
- [`microcpu.StoreAcum`](#microcpustoreacum)
- [`microcpu.__init__`](#microcpuinit)
- [`microcpu.dumpstk`](#microcpudumpstk)
- [`microcpu.fetchStack`](#microcpufetchstack)
- [`microcpu.getwordat`](#microcpugetwordat)
- [`microcpu.getwordmem`](#microcpugetwordmem)
- [`microcpu.highbyte`](#microcpuhighbyte)
- [`microcpu.insertbyte`](#microcpuinsertbyte)
- [`microcpu.lowbyte`](#microcpulowbyte)
- [`microcpu.optADD`](#microcpuoptadd)
- [`microcpu.optADDI`](#microcpuoptaddi)
- [`microcpu.optADDII`](#microcpuoptaddii)
- [`microcpu.optADDS`](#microcpuoptadds)
- [`microcpu.optADM`](#microcpuoptadm)
- [`microcpu.optAND`](#microcpuoptand)
- [`microcpu.optANDI`](#microcpuoptandi)
- [`microcpu.optANDII`](#microcpuoptandii)
- [`microcpu.optANDS`](#microcpuoptands)
- [`microcpu.optCMP`](#microcpuoptcmp)
- [`microcpu.optCMPI`](#microcpuoptcmpi)
- [`microcpu.optCMPII`](#microcpuoptcmpii)
- [`microcpu.optCMPS`](#microcpuoptcmps)
- [`microcpu.optCOMP2`](#microcpuoptcomp2)
- [`microcpu.optDUP`](#microcpuoptdup)
- [`microcpu.optFCLR`](#microcpuoptfclr)
- [`microcpu.optFLOD`](#microcpuoptflod)
- [`microcpu.optFSAV`](#microcpuoptfsav)
- [`microcpu.optINV`](#microcpuoptinv)
- [`microcpu.optJMP`](#microcpuoptjmp)
- [`microcpu.optJMPC`](#microcpuoptjmpc)
- [`microcpu.optJMPI`](#microcpuoptjmpi)
- [`microcpu.optJMPN`](#microcpuoptjmpn)
- [`microcpu.optJMPO`](#microcpuoptjmpo)
- [`microcpu.optJMPS`](#microcpuoptjmps)
- [`microcpu.optJMPZ`](#microcpuoptjmpz)
- [`microcpu.optNOP`](#microcpuoptnop)
- [`microcpu.optOR`](#microcpuoptor)
- [`microcpu.optORI`](#microcpuoptori)
- [`microcpu.optORII`](#microcpuoptorii)
- [`microcpu.optORS`](#microcpuoptors)
- [`microcpu.optPOPI`](#microcpuoptpopi)
- [`microcpu.optPOPII`](#microcpuoptpopii)
- [`microcpu.optPOPNULL`](#microcpuoptpopnull)
- [`microcpu.optPOPS`](#microcpuoptpops)
- [`microcpu.optPUSH`](#microcpuoptpush)
- [`microcpu.optPUSHI`](#microcpuoptpushi)
- [`microcpu.optPUSHII`](#microcpuoptpushii)
- [`microcpu.optPUSHS`](#microcpuoptpushs)
- [`microcpu.optRLTC`](#microcpuoptrltc)
- [`microcpu.optRRTC`](#microcpuoptrrtc)
- [`microcpu.optSCLR`](#microcpuoptsclr)
- [`microcpu.optSHL`](#microcpuoptshl)
- [`microcpu.optSHR`](#microcpuoptshr)
- [`microcpu.optSRPT`](#microcpuoptsrpt)
- [`microcpu.optSUB`](#microcpuoptsub)
- [`microcpu.optSUBI`](#microcpuoptsubi)
- [`microcpu.optSUBII`](#microcpuoptsubii)
- [`microcpu.optSUBS`](#microcpuoptsubs)
- [`microcpu.optSWP`](#microcpuoptswp)
- [`microcpu.optXOR`](#microcpuoptxor)
- [`microcpu.optXORI`](#microcpuoptxori)
- [`microcpu.optXORII`](#microcpuoptxorii)
- [`microcpu.optXORS`](#microcpuoptxors)
- [`microcpu.putwordat`](#microcpuputwordat)
- [`microcpu.raiseerror`](#microcpuraiseerror)

### Macro expansion and macro command processing

- [`OLD_ReplaceMacVars_OLD`](#oldreplacemacvarsold)
- [`expand_brace_refs`](#expandbracerefs)
- [`expand_macro_invocation`](#expandmacroinvocation)
- [`expand_macro_invocation_text`](#expandmacroinvocationtext)
- [`expand_macro_pipeline`](#expandmacropipeline)
- [`expand_percent_functions`](#expandpercentfunctions)
- [`find_matching_percent_paren`](#findmatchingpercentparen)
- [`macro_apply_backfill`](#macroapplybackfill)
- [`macro_arg_value`](#macroargvalue)
- [`macro_has_pending_text`](#macrohaspendingtext)
- [`macro_pop_frame`](#macropopframe)
- [`macro_stack_value`](#macrostackvalue)
- [`macro_take_next_statement`](#macrotakenextstatement)
- [`macro_take_raw_frame`](#macrotakerawframe)
- [`next_macro_arg`](#nextmacroarg)
- [`parse_macro_definition_command`](#parsemacrodefinitioncommand)
- [`parse_percent_arg`](#parsepercentarg)
- [`substitute_macro_params_only`](#substitutemacroparamsonly)
- [`substitute_macro_stack_opts`](#substitutemacrostackopts)

### Miscellaneous utilities

- [`CloseLocalHistories`](#closelocalhistories)
- [`FinalSymbolReport`](#finalsymbolreport)
- [`IsCompilerGenerated`](#iscompilergenerated)
- [`IsUserSymbol`](#isusersymbol)
- [`Str2Byte`](#str2byte)
- [`Str2Word`](#str2word)
- [`Str32Word`](#str32word)
- [`check_loss`](#checkloss)
- [`create_new_unique`](#createnewunique)
- [`enqueue_front`](#enqueuefront)
- [`getkeyfromval`](#getkeyfromval)
- [`hexdump`](#hexdump)
- [`longest_prefix_match`](#longestprefixmatch)
- [`microcpu._handle_return_code`](#microcpuhandlereturncode)
- [`parse_arg`](#parsearg)
- [`parse_expression`](#parseexpression)
- [`queue_tail`](#queuetail)
- [`read_next_physical_line`](#readnextphysicalline)
- [`removecomments`](#removecomments)
- [`resolve_all_forward_references`](#resolveallforwardreferences)
- [`skip_ws`](#skipws)

### Parsing, tokenizing, and expression/value decoding

- [`DecodeStr`](#decodestr)
- [`FirstPassVal`](#firstpassval)
- [`GetQuoted`](#getquoted)
- [`GetRawQuoted`](#getrawquoted)
- [`IsLocalVar`](#islocalvar)
- [`decode_token`](#decodetoken)
- [`digitsonly`](#digitsonly)
- [`escape_for_reinsertion`](#escapeforreinsertion)
- [`expand_unquoted_text`](#expandunquotedtext)
- [`is_string_numeric`](#isstringnumeric)
- [`looks_numeric`](#looksnumeric)
- [`microcpu._evalpc_c`](#microcpuevalpcc)
- [`microcpu._evalpc_py`](#microcpuevalpcpy)
- [`microcpu.evalpc`](#microcpuevalpc)
- [`nextword`](#nextword)
- [`nextwordequation`](#nextwordequation)
- [`nextwordplus`](#nextwordplus)
- [`quote_escape_string`](#quoteescapestring)
- [`split_at_semicolon_outside_quotes`](#splitatsemicolonoutsidequotes)
- [`split_source_commands`](#splitsourcecommands)
- [`validatestr`](#validatestr)

### Program entry / top-level control

- [`dprint`](#dprint)
- [`main`](#main)
- [`safeprint`](#safeprint)
- [`shandler`](#shandler)

### Source map and debugger helpers

- [`DissAsm`](#dissasm)
- [`FindHistoricVal`](#findhistoricval)
- [`InputFileData.__init__`](#inputfiledatainit)
- [`InputFileData.add_entry`](#inputfiledataaddentry)
- [`InputFileData.get_line_info`](#inputfiledatagetlineinfo)
- [`InputFileData.get_nearest_address`](#inputfiledatagetnearestaddress)
- [`UpdateVarHistory`](#updatevarhistory)
- [`debugger`](#debugger)

### Terminal, keyboard, and POLL/CAST host I/O

- [`PollReSetRawFunc`](#pollresetrawfunc)
- [`PollSetEchoFunc`](#pollsetechofunc)
- [`PollSetNoEchoFunc`](#pollsetnoechofunc)
- [`PollSetRawFunc`](#pollsetrawfunc)
- [`PollTTYStateFunc`](#pollttystatefunc)
- [`microcpu.optCAST`](#microcpuoptcast)
- [`microcpu.optPOLL`](#microcpuoptpoll)
- [`tty_reset`](#ttyreset)


## Function Details


### `dprint`

**Location:** line 142  

**Group:** Program entry / top-level control  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Debugging or diagnostic output helper.

**Arguments:**

- `level`
- `*args` — Argument list.
- `**kwargs` — Keyword argument dictionary.

**Expected output:** None / side effects only.

**Called by:** [`AssemblerContext.define_macro`](#assemblercontextdefinemacro), [`AssemblerContext.eval_cond_arg`](#assemblercontextevalcondarg), [`AssemblerContext.handle_elseblock`](#assemblercontexthandleelseblock), [`AssemblerContext.is_executing`](#assemblercontextisexecuting), [`AssemblerContext.pop_block`](#assemblercontextpopblock), [`AssemblerContext.push_block`](#assemblercontextpushblock), [`DecodeStr`](#decodestr), [`FirstPassVal`](#firstpassval), [`OLD_ReplaceMacVars_OLD`](#oldreplacemacvarsold), [`UpdateVarHistory`](#updatevarhistory), … +8 more

**Calls:** [`safeprint`](#safeprint)


### `skip_ws`

**Location:** line 148  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `s` — Input string.
- `i=0`

**Expected output:** Returns i.

**Called by:** [`AssemblerContext.evaluate_condition`](#assemblercontextevaluatecondition), [`consumed_one_source_command`](#consumedonesourcecommand)

**Calls:** None detected.


### `quote_escape_string`

**Location:** line 230  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Function to make sure already proccessed strings that removed escaped codes, will put them back.

**Arguments:**

- `s` — Input string.

**Expected output:** Returns '"' + ''.join((escmap.get(c, c) for c in.

**Called by:** None detected.

**Calls:** None detected.


### `escape_for_reinsertion`

**Location:** line 242  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `s` — Input string.

**Expected output:** Returns ''.join((escmap.get(c, c) for c in s)).

**Called by:** None detected.

**Calls:** None detected.


### `AssemblerContext.__init__`

**Location:** line 270  

**Group:** Assembler context / conditional block state  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Assembler context method that manages labels, macro state, source state, or comparison/evaluation behavior.

**Arguments:**

- `self` — instance object

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `AssemblerContext.max_macro_arg_index`

**Location:** line 338  

**Group:** Assembler context / conditional block state  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Assembler/macro-control helper used to manage macro definitions, conditional blocks, or conditional-expression evaluation.

**Arguments:**

- `self` — instance object
- `body`

**Expected output:** Returns max(nums, default=0).

**Called by:** [`AssemblerContext.define_macro`](#assemblercontextdefinemacro), [`execute_assembler_command`](#executeassemblercommand)

**Calls:** None detected.


### `AssemblerContext.define_macro`

**Location:** line 342  

**Group:** Assembler context / conditional block state  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Assembler/macro-control helper used to manage macro definitions, conditional blocks, or conditional-expression evaluation.

**Arguments:**

- `self` — instance object
- `name`
- `body`
- `filename=None` — Current source filename used for diagnostics and local-symbol resolution.
- `resolved_filename=None` — Canonical/resolved source path used for source mapping and diagnostics.
- `line_num=None` — 1-based source line number used for source mapping/error reports.

**Expected output:** None / side effects only.

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`AssemblerContext.max_macro_arg_index`](#assemblercontextmaxmacroargindex), [`dprint`](#dprint)


### `AssemblerContext.macro_or_label_exists`

**Location:** line 350  

**Group:** Assembler context / conditional block state  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Assembler/macro-control helper used to manage macro definitions, conditional blocks, or conditional-expression evaluation.

**Arguments:**

- `self` — instance object
- `name`

**Expected output:** Returns bool.

**Called by:** [`AssemblerContext.evaluate_condition`](#assemblercontextevaluatecondition)

**Calls:** [`IsLocalVar`](#islocalvar)


### `AssemblerContext.push_block`

**Location:** line 365  

**Group:** Assembler context / conditional block state  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Assembler/macro-control helper used to manage macro definitions, conditional blocks, or conditional-expression evaluation.

**Arguments:**

- `self` — instance object
- `executing`
- `block_type='UNKNOWN'`

**Expected output:** None / side effects only.

**Called by:** [`handle_skipped_command`](#handleskippedcommand), [`loadfile`](#loadfile)

**Calls:** [`AssemblerContext._next_block_id`](#assemblercontextnextblockid), [`dprint`](#dprint)


### `AssemblerContext._next_block_id`

**Location:** line 377  

**Group:** Assembler context / conditional block state  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Assembler/macro-control helper used to manage macro definitions, conditional blocks, or conditional-expression evaluation.

**Arguments:**

- `self` — instance object

**Expected output:** Returns self._block_counter.

**Called by:** [`AssemblerContext.push_block`](#assemblercontextpushblock)

**Calls:** None detected.


### `AssemblerContext.pop_block`

**Location:** line 383  

**Group:** Assembler context / conditional block state  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Assembler/macro-control helper used to manage macro definitions, conditional blocks, or conditional-expression evaluation.

**Arguments:**

- `self` — instance object

**Expected output:** None / side effects only.

**Called by:** [`handle_skipped_command`](#handleskippedcommand), [`loadfile`](#loadfile)

**Calls:** [`dprint`](#dprint), [`microcpu.raiseerror`](#microcpuraiseerror), [`safeprint`](#safeprint)


### `AssemblerContext.handle_elseblock`

**Location:** line 395  

**Group:** Assembler context / conditional block state  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Assembler/macro-control helper used to manage macro definitions, conditional blocks, or conditional-expression evaluation.

**Arguments:**

- `self` — instance object

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`AssemblerContext.current_block`](#assemblercontextcurrentblock), [`AssemblerContext.parent_executing`](#assemblercontextparentexecuting), [`dprint`](#dprint)


### `AssemblerContext.current_block`

**Location:** line 424  

**Group:** Assembler context / conditional block state  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Assembler/macro-control helper used to manage macro definitions, conditional blocks, or conditional-expression evaluation.

**Arguments:**

- `self` — instance object

**Expected output:** Returns NoneType, self.MacroBlockStack[-1].

**Called by:** [`AssemblerContext.handle_elseblock`](#assemblercontexthandleelseblock)

**Calls:** None detected.


### `AssemblerContext.parent_executing`

**Location:** line 429  

**Group:** Assembler context / conditional block state  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Assembler context method that manages labels, macro state, source state, or comparison/evaluation behavior.

**Arguments:**

- `self` — instance object

**Expected output:** Returns all((b['executing'] for b in self.MacroB.

**Called by:** [`AssemblerContext.handle_elseblock`](#assemblercontexthandleelseblock)

**Calls:** None detected.


### `AssemblerContext.is_executing`

**Location:** line 432  

**Group:** Assembler context / conditional block state  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Assembler context method that manages labels, macro state, source state, or comparison/evaluation behavior.

**Arguments:**

- `self` — instance object

**Expected output:** Returns result.

**Called by:** [`loadfile`](#loadfile), [`read_next_physical_line`](#readnextphysicalline)

**Calls:** [`dprint`](#dprint)


### `AssemblerContext.smart_compare`

**Location:** line 437  

**Group:** Assembler context / conditional block state  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Compare two strings using numeric rules when BOTH can be parsed as integers. Supports: - decimal integers (e.g., "12", "-5") - hex integers with 0x prefix (e.g., "0xFF", "-0x20") Otherwise falls back to lexicographic comparison. Returns: -1...

**Arguments:**

- `self` — instance object
- `a`
- `b`

**Expected output:** Returns -1, NoneType, int, int(s, 10), int(s, 16).

**Called by:** None detected.

**Calls:** None detected.


### `AssemblerContext.eval_cond_arg`

**Location:** line 483  

**Group:** Assembler context / conditional block state  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Assembler context method that manages labels, macro state, source state, or comparison/evaluation behavior.

**Arguments:**

- `self` — instance object
- `line` — Current source text or command fragment being parsed.
- `filename=None` — Current source filename used for diagnostics and local-symbol resolution.

**Expected output:** Returns tuple.

**Called by:** None detected.

**Calls:** [`dprint`](#dprint), [`expand_brace_refs`](#expandbracerefs), [`microcpu.raiseerror`](#microcpuraiseerror), [`nextword`](#nextword)


### `AssemblerContext.evaluate_condition`

**Location:** line 520  

**Group:** Assembler context / conditional block state  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Assembler/macro-control helper used to manage macro definitions, conditional blocks, or conditional-expression evaluation.

**Arguments:**

- `self` — instance object
- `key`
- `line` — Current source text or command fragment being parsed.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns tuple.

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`AssemblerContext.eval_arg`](#assemblercontextevalarg), [`AssemblerContext.macro_or_label_exists`](#assemblercontextmacroorlabelexists), [`microcpu.raiseerror`](#microcpuraiseerror), [`nextwordequation`](#nextwordequation), [`nextwordplus`](#nextwordplus), [`skip_ws`](#skipws)


### `AssemblerContext.eval_arg`

**Location:** line 556  

**Group:** Assembler context / conditional block state  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Assembler context method that manages labels, macro state, source state, or comparison/evaluation behavior.

**Arguments:**

- `self` — instance object
- `arg` — Input argument value.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns arg, value.

**Called by:** [`AssemblerContext.evaluate_condition`](#assemblercontextevaluatecondition)

**Calls:** [`FirstPassVal`](#firstpassval), [`expand_unquoted_text`](#expandunquotedtext)


### `PollSetNoEchoFunc`

**Location:** line 653  

**Group:** Terminal, keyboard, and POLL/CAST host I/O  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Turn echo off, leave canonical mode as-is.

**Arguments:**

- `arg=None` — Input argument value.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optPOLL`](#microcpuoptpoll)

**Calls:** None detected.


### `PollSetEchoFunc`

**Location:** line 659  

**Group:** Terminal, keyboard, and POLL/CAST host I/O  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Turn echo back on, leave canonical mode as-is.

**Arguments:**

- `arg=None` — Input argument value.

**Expected output:** None / side effects only.

**Called by:** [`debugger`](#debugger), [`microcpu.optPOLL`](#microcpuoptpoll)

**Calls:** None detected.


### `PollSetRawFunc`

**Location:** line 666  

**Group:** Terminal, keyboard, and POLL/CAST host I/O  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Put terminal into full raw mode, save old settings.

**Arguments:**

- `arg=None` — Input argument value.

**Expected output:** None / side effects only.

**Called by:** [`debugger`](#debugger), [`microcpu.optPOLL`](#microcpuoptpoll)

**Calls:** None detected.


### `PollReSetRawFunc`

**Location:** line 680  

**Group:** Terminal, keyboard, and POLL/CAST host I/O  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Restore terminal to state before PollSetRaw was called.

**Arguments:**

- `arg=None` — Input argument value.

**Expected output:** None / side effects only.

**Called by:** [`debugger`](#debugger), [`microcpu.optPOLL`](#microcpuoptpoll)

**Calls:** None detected.


### `PollTTYStateFunc`

**Location:** line 703  

**Group:** Terminal, keyboard, and POLL/CAST host I/O  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `arg=None` — Input argument value.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optPOLL`](#microcpuoptpoll)

**Calls:** None detected.


### `tty_reset`

**Location:** line 724  

**Group:** Terminal, keyboard, and POLL/CAST host I/O  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Restore terminal state saved by tty_setraw.

**Arguments:**

- `_fd=sys.stdin.fileno()`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `shandler`

**Location:** line 735  

**Group:** Program entry / top-level control  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `signum`
- `frame`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`debugger`](#debugger)


### `is_string_numeric`

**Location:** line 744  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `s` — Input string.

**Expected output:** Returns str(s).isdigit().

**Called by:** None detected.

**Calls:** None detected.


### `digitsonly`

**Location:** line 747  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `s` — Input string.

**Expected output:** Returns digits if digits else '0'.

**Called by:** [`microcpu.FindAddressLine`](#microcpufindaddressline)

**Calls:** None detected.


### `create_new_filename`

**Location:** line 753  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** File/source loading helper used by the assembler or runtime support.

**Arguments:**

- `original_filename`
- `new_extension`

**Expected output:** Returns new_filename.

**Called by:** [`main`](#main)

**Calls:** None detected.


### `create_new_unique`

**Location:** line 763  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:** None.

**Expected output:** Returns 'U_%06x_' % UniqueID.

**Called by:** [`expand_macro_invocation_text`](#expandmacroinvocationtext)

**Calls:** None detected.


### `validatestr`

**Location:** line 770  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** return "U_%06x%0x4_" % (UniqueID,current_context.address)

**Arguments:**

- `instr`
- `typecode` — Numeric base selector, usually 2, 8, 10, or 16.

**Expected output:** Returns int(instr, 0).

**Called by:** [`Str32Word`](#str32word)

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `UpdateVarHistory`

**Location:** line 798  

**Group:** Source map and debugger helpers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** global LocVarHist LocVarHist.setdefault(varname, []).append((int(value), int(address)))

**Arguments:**

- `varname`
- `value` — Value to store, compare, or encode.
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** [`execute_assembler_command`](#executeassemblercommand), [`handle_semicolon`](#handlesemicolon)

**Calls:** [`dprint`](#dprint)


### `FindHistoricVal`

**Location:** line 822  

**Group:** Source map and debugger helpers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Expression/symbol evaluation helper used during assembly and macro expansion.

**Arguments:**

- `varname`
- `testaddress`
- `context=None` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns NoneType, best['value'], bool.

**Called by:** [`debugger`](#debugger), [`decode_token`](#decodetoken), [`expand_brace_refs`](#expandbracerefs)

**Calls:** None detected.


### `FindLabelMatch`

**Location:** line 875  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `varname`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns NoneType, context.FileLabels[potential_matches[0]], context.FileLabels[varname].

**Called by:** None detected.

**Calls:** None detected.


### `Sort_And_Combine_Labels`

**Location:** line 896  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `inboundtext`

**Expected output:** Returns ' '.join(groups['other'] + groups['M']), inboundtext.

**Called by:** [`DissAsm`](#dissasm)

**Calls:** None detected.


### `handle_semicolon`

**Location:** line 928  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns rest[used:].lstrip().

**Called by:** [`execute_assembler_command`](#executeassemblercommand)

**Calls:** [`DecodeStr`](#decodestr), [`IsLocalVar`](#islocalvar), [`UpdateVarHistory`](#updatevarhistory), [`microcpu.raiseerror`](#microcpuraiseerror), [`nextword`](#nextword), [`nextwordequation`](#nextwordequation)


### `InputFileData.__init__`

**Location:** line 970  

**Group:** Source map and debugger helpers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Source-to-address mapping helper used by the debugger and error reporting to correlate memory locations with input lines.

**Arguments:**

- `self` — instance object

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `InputFileData.add_entry`

**Location:** line 975  

**Group:** Source map and debugger helpers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Source-to-address mapping helper used by the debugger and error reporting to correlate memory locations with input lines.

**Arguments:**

- `self` — instance object
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `line_number` — 1-based source line number used for source mapping/error reports.
- `memory_address`

**Expected output:** None / side effects only.

**Called by:** [`read_next_physical_line`](#readnextphysicalline)

**Calls:** None detected.


### `InputFileData.get_line_info`

**Location:** line 986  

**Group:** Source map and debugger helpers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Source-to-address mapping helper used by the debugger and error reporting to correlate memory locations with input lines.

**Arguments:**

- `self` — instance object
- `memory_address`
- `exact=False`

**Expected output:** Returns NoneType, self.address_map[memory_address], self.address_map[nearest_lower_address].

**Called by:** [`microcpu.FindWhatLine`](#microcpufindwhatline), [`microcpu.dumpstk`](#microcpudumpstk), [`microcpu.optCAST`](#microcpuoptcast)

**Calls:** None detected.


### `InputFileData.get_nearest_address`

**Location:** line 997  

**Group:** Source map and debugger helpers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Source-to-address mapping helper used by the debugger and error reporting to correlate memory locations with input lines.

**Arguments:**

- `self` — instance object
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `line_number` — 1-based source line number used for source mapping/error reports.

**Expected output:** Returns NoneType, tuple.

**Called by:** [`microcpu.FindAddressLine`](#microcpufindaddressline)

**Calls:** None detected.


### `safeprint`

**Location:** line 1031  

**Group:** Program entry / top-level control  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Debugging or diagnostic output helper.

**Arguments:**

- `*args` — Argument list.
- `**kwargs` — Keyword argument dictionary.

**Expected output:** None / side effects only.

**Called by:** [`AssemblerContext.pop_block`](#assemblercontextpopblock), [`DecodeStr`](#decodestr), [`DissAsm`](#dissasm), [`Str32Word`](#str32word), [`debugger`](#debugger), [`decode_token`](#decodetoken), [`dprint`](#dprint), [`execute_assembler_command`](#executeassemblercommand), [`fileonpath`](#fileonpath), [`hexdump`](#hexdump), … +4 more

**Calls:** None detected.


### `microcpu.__init__`

**Location:** line 1055  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `self` — instance object
- `origin` — Initial program counter/origin address for a CPU instance.
- `memsize` — Number of bytes allocated for emulated memory.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `microcpu.insertbyte`

**Location:** line 1078  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Low-level CPU memory/word helper used by the emulator and device/opcode implementations.

**Arguments:**

- `self` — instance object
- `location`
- `value` — Value to store, compare, or encode.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optPOPI`](#microcpuoptpopi), [`microcpu.putwordat`](#microcpuputwordat)

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.getwordmem`

**Location:** line 1083  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Low-level CPU memory/word helper used by the emulator and device/opcode implementations.

**Arguments:**

- `self` — instance object
- `index`

**Expected output:** Returns int(self.memspace[index]) + (int(self.me.

**Called by:** [`debugger`](#debugger), [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optCAST`](#microcpuoptcast), [`microcpu.optPOLL`](#microcpuoptpoll), [`microcpu.optPUSHI`](#microcpuoptpushi)

**Calls:** None detected.


### `microcpu.dumpstk`

**Location:** line 1086  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Hardware-stack helper for reading, writing, or reporting stack state.

**Arguments:**

- `self` — instance object
- `stack`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`InputFileData.get_line_info`](#inputfiledatagetlineinfo)


### `microcpu.FindWhatLine`

**Location:** line 1098  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** Returns '%s:%d' % tresult, str.

**Called by:** [`DissAsm`](#dissasm), [`debugger`](#debugger), [`microcpu.optCAST`](#microcpuoptcast), [`microcpu.raiseerror`](#microcpuraiseerror)

**Calls:** [`InputFileData.get_line_info`](#inputfiledatagetlineinfo)


### `microcpu.FindAddressLine`

**Location:** line 1106  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `self` — instance object
- `line_info`

**Expected output:** Returns FileLineData.get_nearest_address(OutFile.

**Called by:** [`debugger`](#debugger)

**Calls:** [`InputFileData.get_nearest_address`](#inputfiledatagetnearestaddress), [`digitsonly`](#digitsonly)


### `microcpu.raiseerror`

**Location:** line 1118  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `self` — instance object
- `idcode`

**Expected output:** None / side effects only.

**Called by:** [`AssemblerContext.eval_cond_arg`](#assemblercontextevalcondarg), [`AssemblerContext.evaluate_condition`](#assemblercontextevaluatecondition), [`AssemblerContext.pop_block`](#assemblercontextpopblock), [`DecodeStr`](#decodestr), [`FirstPassVal`](#firstpassval), [`OLD_ReplaceMacVars_OLD`](#oldreplacemacvarsold), [`Str32Word`](#str32word), [`consumed_one_source_command`](#consumedonesourcecommand), [`execute_assembler_command`](#executeassemblercommand), [`expand_macro_invocation_text`](#expandmacroinvocationtext), … +41 more

**Calls:** [`debugger`](#debugger), [`microcpu.FindWhatLine`](#microcpufindwhatline), [`microcpu.getwordat`](#microcpugetwordat), [`safeprint`](#safeprint)


### `microcpu.lowbyte`

**Location:** line 1198  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Low-level CPU memory/word helper used by the emulator and device/opcode implementations.

**Arguments:**

- `self` — instance object
- `invalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** Returns invalue & 255.

**Called by:** [`microcpu.optPOPI`](#microcpuoptpopi), [`microcpu.putwordat`](#microcpuputwordat), [`resolve_all_forward_references`](#resolveallforwardreferences)

**Calls:** None detected.


### `microcpu.highbyte`

**Location:** line 1202  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Low-level CPU memory/word helper used by the emulator and device/opcode implementations.

**Arguments:**

- `self` — instance object
- `invalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** Returns (invalue & 65280) >> 8.

**Called by:** [`microcpu.optPOPI`](#microcpuoptpopi), [`microcpu.putwordat`](#microcpuputwordat), [`resolve_all_forward_references`](#resolveallforwardreferences)

**Calls:** None detected.


### `microcpu.fetchStack`

**Location:** line 1206  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Hardware-stack helper for reading, writing, or reporting stack state.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** Returns int(self.hwstack[index]).

**Called by:** [`DissAsm`](#dissasm), [`debugger`](#debugger), [`microcpu.optADD`](#microcpuoptadd), [`microcpu.optADDS`](#microcpuoptadds), [`microcpu.optAND`](#microcpuoptand), [`microcpu.optANDS`](#microcpuoptands), [`microcpu.optCAST`](#microcpuoptcast), [`microcpu.optCMP`](#microcpuoptcmp), [`microcpu.optCMPI`](#microcpuoptcmpi), [`microcpu.optCMPS`](#microcpuoptcmps), … +17 more

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.StoreAcum`

**Location:** line 1215  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Hardware-stack helper for reading, writing, or reporting stack state.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.
- `value` — Value to store, compare, or encode.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optADD`](#microcpuoptadd), [`microcpu.optADDS`](#microcpuoptadds), [`microcpu.optAND`](#microcpuoptand), [`microcpu.optANDS`](#microcpuoptands), [`microcpu.optCOMP2`](#microcpuoptcomp2), [`microcpu.optINV`](#microcpuoptinv), [`microcpu.optOR`](#microcpuoptor), [`microcpu.optORS`](#microcpuoptors), [`microcpu.optPUSHS`](#microcpuoptpushs), [`microcpu.optRLTC`](#microcpuoptrltc), … +8 more

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.getwordat`

**Location:** line 1228  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Low-level CPU memory/word helper used by the emulator and device/opcode implementations.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** Returns a, int.

**Called by:** [`DissAsm`](#dissasm), [`debugger`](#debugger), [`microcpu._evalpc_py`](#microcpuevalpcpy), [`microcpu.optADDI`](#microcpuoptaddi), [`microcpu.optADDII`](#microcpuoptaddii), [`microcpu.optANDI`](#microcpuoptandi), [`microcpu.optANDII`](#microcpuoptandii), [`microcpu.optCAST`](#microcpuoptcast), [`microcpu.optCMPI`](#microcpuoptcmpi), [`microcpu.optCMPII`](#microcpuoptcmpii), … +11 more

**Calls:** [`microcpu.getwordmem`](#microcpugetwordmem), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.putwordat`

**Location:** line 1238  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Low-level CPU memory/word helper used by the emulator and device/opcode implementations.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.
- `value` — Value to store, compare, or encode.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optPOLL`](#microcpuoptpoll), [`microcpu.optPOPS`](#microcpuoptpops)

**Calls:** [`microcpu.highbyte`](#microcpuhighbyte), [`microcpu.insertbyte`](#microcpuinsertbyte), [`microcpu.lowbyte`](#microcpulowbyte), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optNOP`

**Location:** line 1245  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `NOP` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `count` — Opcode operand slot that is ignored for this instruction.

**Expected output:** May return None.

**Called by:** None detected.

**Calls:** None detected.


### `microcpu.optPUSH`

**Location:** line 1248  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Implements the EX716 `PUSH` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `invalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** [`debugger`](#debugger), [`microcpu.optFSAV`](#microcpuoptfsav), [`microcpu.optPOLL`](#microcpuoptpoll), [`microcpu.optSRPT`](#microcpuoptsrpt)

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optDUP`

**Location:** line 1256  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `DUP` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optPUSHI`

**Location:** line 1264  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `PUSHI` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordmem`](#microcpugetwordmem), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optPUSHII`

**Location:** line 1274  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `PUSHII` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optPUSHS`

**Location:** line 1286  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `PUSHS` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack), [`microcpu.getwordat`](#microcpugetwordat)


### `microcpu.optPOPNULL`

**Location:** line 1291  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Implements the EX716 `POPNULL` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** [`debugger`](#debugger), [`microcpu.optCAST`](#microcpuoptcast), [`microcpu.optPOLL`](#microcpuoptpoll)

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optSWP`

**Location:** line 1299  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `SWP` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optPOPI`

**Location:** line 1308  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Implements the EX716 `POPI` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** [`debugger`](#debugger), [`microcpu.optPOPII`](#microcpuoptpopii)

**Calls:** [`microcpu.highbyte`](#microcpuhighbyte), [`microcpu.insertbyte`](#microcpuinsertbyte), [`microcpu.lowbyte`](#microcpulowbyte), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optPOPII`

**Location:** line 1322  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `POPII` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `firstaddress`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optPOPI`](#microcpuoptpopi), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optPOPS`

**Location:** line 1332  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `POPS` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `notused` — Opcode operand slot that is ignored for this instruction.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.fetchStack`](#microcpufetchstack), [`microcpu.putwordat`](#microcpuputwordat), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.SetFlags`

**Location:** line 1340  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Updates arithmetic/logic condition flags for subsequent conditional jumps and debugging.

**Arguments:**

- `self` — instance object
- `A1`
- `WasSubt`

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optADD`](#microcpuoptadd), [`microcpu.optADDS`](#microcpuoptadds), [`microcpu.optAND`](#microcpuoptand), [`microcpu.optANDS`](#microcpuoptands), [`microcpu.optCMP`](#microcpuoptcmp), [`microcpu.optCMPI`](#microcpuoptcmpi), [`microcpu.optCMPS`](#microcpuoptcmps), [`microcpu.optCOMP2`](#microcpuoptcomp2), [`microcpu.optINV`](#microcpuoptinv), [`microcpu.optOR`](#microcpuoptor), … +6 more

**Calls:** None detected.


### `microcpu.OverCarryTest`

**Location:** line 1348  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Updates arithmetic/logic condition flags for subsequent conditional jumps and debugging.

**Arguments:**

- `self` — instance object
- `a`
- `b`
- `c`
- `IsSubtraction`

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optADD`](#microcpuoptadd), [`microcpu.optADDS`](#microcpuoptadds), [`microcpu.optCMP`](#microcpuoptcmp), [`microcpu.optCMPI`](#microcpuoptcmpi), [`microcpu.optCMPS`](#microcpuoptcmps), [`microcpu.optSUB`](#microcpuoptsub), [`microcpu.optSUBI`](#microcpuoptsubi), [`microcpu.optSUBS`](#microcpuoptsubs)

**Calls:** None detected.


### `microcpu.optCMP`

**Location:** line 1378  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `CMP` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `asvalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.OverCarryTest`](#microcpuovercarrytest), [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optCMPS`

**Location:** line 1385  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `CMPS` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.OverCarryTest`](#microcpuovercarrytest), [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optCMPI`

**Location:** line 1392  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `CMPI` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optCMPII`](#microcpuoptcmpii)

**Calls:** [`microcpu.OverCarryTest`](#microcpuovercarrytest), [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.fetchStack`](#microcpufetchstack), [`microcpu.getwordat`](#microcpugetwordat)


### `microcpu.optCMPII`

**Location:** line 1399  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `CMPII` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optCMPI`](#microcpuoptcmpi), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optADD`

**Location:** line 1406  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ADD` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `invalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optADDI`](#microcpuoptaddi)

**Calls:** [`microcpu.OverCarryTest`](#microcpuovercarrytest), [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optADDS`

**Location:** line 1414  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ADDS` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `invalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.OverCarryTest`](#microcpuovercarrytest), [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optADDI`

**Location:** line 1423  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ADDI` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optADDII`](#microcpuoptaddii)

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optADD`](#microcpuoptadd), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optADDII`

**Location:** line 1429  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ADDII` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optADDI`](#microcpuoptaddi), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optSUB`

**Location:** line 1437  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `SUB` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `invalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.OverCarryTest`](#microcpuovercarrytest), [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optSUBS`

**Location:** line 1446  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `SUBS` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `invalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.OverCarryTest`](#microcpuovercarrytest), [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optSUBI`

**Location:** line 1455  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `SUBI` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optSUBII`](#microcpuoptsubii)

**Calls:** [`microcpu.OverCarryTest`](#microcpuovercarrytest), [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack), [`microcpu.getwordat`](#microcpugetwordat)


### `microcpu.optSUBII`

**Location:** line 1463  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `SUBII` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optSUBI`](#microcpuoptsubi), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optOR`

**Location:** line 1471  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `OR` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `ivalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optORI`](#microcpuoptori)

**Calls:** [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optORS`

**Location:** line 1479  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ORS` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `ivalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optORI`

**Location:** line 1488  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ORI` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optORII`](#microcpuoptorii)

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optOR`](#microcpuoptor), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optORII`

**Location:** line 1494  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ORII` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optORI`](#microcpuoptori), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optAND`

**Location:** line 1502  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `AND` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `ivalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optANDI`](#microcpuoptandi)

**Calls:** [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optANDS`

**Location:** line 1510  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ANDS` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `ivalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optANDI`

**Location:** line 1519  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ANDI` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optANDII`](#microcpuoptandii)

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optAND`](#microcpuoptand), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optANDII`

**Location:** line 1525  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ANDII` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optANDI`](#microcpuoptandi), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optXOR`

**Location:** line 1532  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `XOR` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `ivalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optXORI`](#microcpuoptxori)

**Calls:** [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optXORS`

**Location:** line 1539  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `XORS` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `ivalue` — Immediate operand value supplied by the decoded instruction.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optXORI`

**Location:** line 1548  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `XORI` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** [`microcpu.optXORII`](#microcpuoptxorii)

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optXOR`](#microcpuoptxor), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optXORII`

**Location:** line 1554  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `XORII` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.optXORI`](#microcpuoptxori), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optJMPZ`

**Location:** line 1562  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `JMPZ` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optJMPN`

**Location:** line 1569  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `JMPN` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optJMPC`

**Location:** line 1576  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `JMPC` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optJMPO`

**Location:** line 1583  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `JMPO` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optJMP`

**Location:** line 1590  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `JMP` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optJMPI`

**Location:** line 1596  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `JMPI` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.getwordat`](#microcpugetwordat)


### `microcpu.optJMPS`

**Location:** line 1600  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `JMPS` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optCAST`

**Location:** line 1605  

**Group:** Terminal, keyboard, and POLL/CAST host I/O  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `CAST` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** May return None.

**Called by:** None detected.

**Calls:** [`InputFileData.get_line_info`](#inputfiledatagetlineinfo), [`microcpu.FindWhatLine`](#microcpufindwhatline), [`microcpu.fetchStack`](#microcpufetchstack), [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.getwordmem`](#microcpugetwordmem), [`microcpu.optPOPNULL`](#microcpuoptpopnull), [`microcpu.raiseerror`](#microcpuraiseerror), [`safeprint`](#safeprint)


### `microcpu.optPOLL`

**Location:** line 1869  

**Group:** Terminal, keyboard, and POLL/CAST host I/O  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `POLL` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** May return None.

**Called by:** None detected.

**Calls:** [`PollReSetRawFunc`](#pollresetrawfunc), [`PollSetEchoFunc`](#pollsetechofunc), [`PollSetNoEchoFunc`](#pollsetnoechofunc), [`PollSetRawFunc`](#pollsetrawfunc), [`PollTTYStateFunc`](#pollttystatefunc), [`microcpu.fetchStack`](#microcpufetchstack), [`microcpu.getwordmem`](#microcpugetwordmem), [`microcpu.optPOPNULL`](#microcpuoptpopnull), [`microcpu.optPUSH`](#microcpuoptpush), [`microcpu.putwordat`](#microcpuputwordat), … +2 more


### `microcpu.optRRTC`

**Location:** line 2041  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `RRTC` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `unused`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optRLTC`

**Location:** line 2053  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `RLTC` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `unused`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optSHR`

**Location:** line 2065  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `SHR` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `unused`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optSHL`

**Location:** line 2074  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `SHL` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `unused`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optINV`

**Location:** line 2082  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `INV` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optCOMP2`

**Location:** line 2090  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `COMP2` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.SetFlags`](#microcpusetflags), [`microcpu.StoreAcum`](#microcpustoreacum), [`microcpu.fetchStack`](#microcpufetchstack)


### `microcpu.optFCLR`

**Location:** line 2098  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `FCLR` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `microcpu.optFSAV`

**Location:** line 2101  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `FSAV` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.optPUSH`](#microcpuoptpush)


### `microcpu.optFLOD`

**Location:** line 2104  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `FLOD` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu.optADM`

**Location:** line 2113  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `ADM` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `microcpu.optSCLR`

**Location:** line 2118  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `SCLR` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `microcpu.optSRPT`

**Location:** line 2121  

**Group:** CPU emulator core and opcode handlers  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Implements the EX716 `SRPT` opcode/emulated instruction. It updates CPU state, memory, stack, flags, or program counter according to that instruction form.

**Arguments:**

- `self` — instance object
- `address` — 16-bit memory address or assembler output address, depending on context.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`microcpu.optPUSH`](#microcpuoptpush)


### `microcpu.evalpc`

**Location:** line 2128  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Main evaluate loop – dispatches to Python or C backend depending on context.Fast.

**Arguments:**

- `self` — instance object
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `dosteps`

**Expected output:** Returns self._evalpc_c(context, dosteps), self._evalpc_py(context, dosteps).

**Called by:** [`debugger`](#debugger), [`main`](#main)

**Calls:** [`microcpu._evalpc_c`](#microcpuevalpcc), [`microcpu._evalpc_py`](#microcpuevalpcpy)


### `microcpu._evalpc_c`

**Location:** line 2184  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Expression/symbol evaluation helper used during assembly and macro expansion.

**Arguments:**

- `self` — instance object
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `dosteps`

**Expected output:** Returns ReturnCode.

**Called by:** [`microcpu.evalpc`](#microcpuevalpc)

**Calls:** [`microcpu._handle_return_code`](#microcpuhandlereturncode)


### `microcpu._evalpc_py`

**Location:** line 2307  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Expression/symbol evaluation helper used during assembly and macro expansion.

**Arguments:**

- `self` — instance object
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `dosteps`

**Expected output:** Returns int.

**Called by:** [`microcpu.evalpc`](#microcpuevalpc)

**Calls:** [`microcpu.getwordat`](#microcpugetwordat), [`microcpu.raiseerror`](#microcpuraiseerror)


### `microcpu._handle_return_code`

**Location:** line 2381  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `self` — instance object
- `code`

**Expected output:** None / side effects only.

**Called by:** [`microcpu._evalpc_c`](#microcpuevalpcc)

**Calls:** [`debugger`](#debugger)


### `removecomments`

**Location:** line 2411  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `inline`

**Expected output:** Returns ''.join(out).rstrip(), str.

**Called by:** [`debugger`](#debugger), [`expand_macro_invocation`](#expandmacroinvocation), [`loadfile`](#loadfile), [`read_next_physical_line`](#readnextphysicalline), [`read_next_source_command`](#readnextsourcecommand)

**Calls:** None detected.


### `GetQuoted`

**Location:** line 2447  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `inline`

**Expected output:** Returns tuple.

**Called by:** [`OLD_ReplaceMacVars_OLD`](#oldreplacemacvarsold), [`debugger`](#debugger), [`expand_percent_functions`](#expandpercentfunctions), [`nextword`](#nextword)

**Calls:** None detected.


### `GetRawQuoted`

**Location:** line 2491  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `inline`

**Expected output:** Returns tuple.

**Called by:** [`nextword`](#nextword)

**Calls:** None detected.


### `next_macro_arg`

**Location:** line 2505  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Macro expansion or macro-definition helper used by the assembler pipeline.

**Arguments:**

- `s` — Input string.

**Expected output:** Returns tuple.

**Called by:** [`consumed_one_source_command`](#consumedonesourcecommand), [`expand_macro_invocation_text`](#expandmacroinvocationtext)

**Calls:** None detected.


### `nextwordplus`

**Location:** line 2536  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Tokenizer/parser helper for extracting assembler words, arguments, or command fragments.

**Arguments:**

- `ltext`

**Expected output:** Returns tuple.

**Called by:** [`AssemblerContext.evaluate_condition`](#assemblercontextevaluatecondition), [`consumed_one_source_command`](#consumedonesourcecommand), [`execute_assembler_command`](#executeassemblercommand), [`expand_macro_invocation_text`](#expandmacroinvocationtext), [`expand_percent_functions`](#expandpercentfunctions), [`loadfile`](#loadfile), [`macro_take_raw_frame`](#macrotakerawframe), [`parse_macro_definition_command`](#parsemacrodefinitioncommand)

**Calls:** [`nextword`](#nextword)


### `nextwordequation`

**Location:** line 2552  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Tokenizer/parser helper for extracting assembler words, arguments, or command fragments.

**Arguments:**

- `line` — Current source text or command fragment being parsed.

**Expected output:** Returns tuple.

**Called by:** [`AssemblerContext.evaluate_condition`](#assemblercontextevaluatecondition), [`FirstPassVal`](#firstpassval), [`consumed_one_source_command`](#consumedonesourcecommand), [`handle_semicolon`](#handlesemicolon), [`parse_percent_arg`](#parsepercentarg)

**Calls:** [`nextword`](#nextword)


### `check_loss`

**Location:** line 2576  

**Group:** Miscellaneous utilities  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `label`
- `before`
- `after`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `nextword`

**Location:** line 2582  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Tokenizer/parser helper for extracting assembler words, arguments, or command fragments.

**Arguments:**

- `ltext`

**Expected output:** Returns tuple.

**Called by:** [`AssemblerContext.eval_cond_arg`](#assemblercontextevalcondarg), [`OLD_ReplaceMacVars_OLD`](#oldreplacemacvarsold), [`consumed_one_source_command`](#consumedonesourcecommand), [`debugger`](#debugger), [`execute_assembler_command`](#executeassemblercommand), [`handle_semicolon`](#handlesemicolon), [`nextwordequation`](#nextwordequation), [`nextwordplus`](#nextwordplus), [`parse_arg`](#parsearg)

**Calls:** [`GetQuoted`](#getquoted), [`GetRawQuoted`](#getrawquoted)


### `Str2Word`

**Location:** line 2666  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `instr`

**Expected output:** Returns Result.

**Called by:** [`FirstPassVal`](#firstpassval), [`Str2Byte`](#str2byte), [`debugger`](#debugger), [`decode_token`](#decodetoken), [`execute_assembler_command`](#executeassemblercommand), [`main`](#main), [`parse_arg`](#parsearg), [`resolve_all_forward_references`](#resolveallforwardreferences)

**Calls:** [`Str32Word`](#str32word)


### `Str32Word`

**Location:** line 2673  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `instr`

**Expected output:** Returns instr, int(result) & 4294967295.

**Called by:** [`Str2Word`](#str2word)

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror), [`safeprint`](#safeprint), [`validatestr`](#validatestr)


### `Str2Byte`

**Location:** line 2717  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `instr`

**Expected output:** Returns Str2Word(instr) & 255.

**Called by:** [`debugger`](#debugger)

**Calls:** [`Str2Word`](#str2word)


### `DissAsm`

**Location:** line 2722  

**Group:** Source map and debugger helpers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `start`
- `length`
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns i.

**Called by:** [`debugger`](#debugger), [`main`](#main)

**Calls:** [`Sort_And_Combine_Labels`](#sortandcombinelabels), [`getkeyfromval`](#getkeyfromval), [`hexdump`](#hexdump), [`microcpu.FindWhatLine`](#microcpufindwhatline), [`microcpu.fetchStack`](#microcpufetchstack), [`microcpu.getwordat`](#microcpugetwordat), [`safeprint`](#safeprint)


### `getkeyfromval`

**Location:** line 2809  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Expression/symbol evaluation helper used during assembly and macro expansion.

**Arguments:**

- `val`
- `my_dict`

**Expected output:** May return None.

**Called by:** [`DissAsm`](#dissasm)

**Calls:** None detected.


### `hexdump`

**Location:** line 2843  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Debugging or diagnostic output helper.

**Arguments:**

- `startaddr`
- `length`
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** None / side effects only.

**Called by:** [`DissAsm`](#dissasm), [`debugger`](#debugger)

**Calls:** [`safeprint`](#safeprint)


### `fileonpath`

**Location:** line 2878  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Allow use of the CPUPATH OS Enviroment variable to find library directories.

**Arguments:**

- `filename` — Current source filename used for diagnostics and local-symbol resolution.

**Expected output:** Returns candidate.

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`safeprint`](#safeprint)


### `IsLocalVar`

**Location:** line 2898  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `inlabel`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns f'{inlabel}___{context.LocalID}', inlabel.

**Called by:** [`AssemblerContext.macro_or_label_exists`](#assemblercontextmacroorlabelexists), [`decode_token`](#decodetoken), [`execute_assembler_command`](#executeassemblercommand), [`handle_semicolon`](#handlesemicolon)

**Calls:** None detected.


### `parse_arg`

**Location:** line 2930  

**Group:** Miscellaneous utilities  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Parse a single argument from `segment`. Handles literals, macro vars, and nested %( ... %). Returns (string_value, chars_consumed).

**Arguments:**

- `segment`
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns tuple.

**Called by:** [`OLD_ReplaceMacVars_OLD`](#oldreplacemacvarsold)

**Calls:** [`Str2Word`](#str2word), [`expand_macro_pipeline`](#expandmacropipeline), [`nextword`](#nextword)


### `expand_brace_refs`

**Location:** line 2970  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Universal {name} expansion. This should run after macro argument substitution, but before normal assembler command handling. Resolution order: 1. MacroData symbolic value 2. Historic/current label value 3. Preserve unresolved {name}, unless...

**Arguments:**

- `text` — Input text block.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.
- `preserve_unresolved=True` — When true, unresolved labels/braces are preserved instead of treated as fatal immediately.

**Expected output:** Returns ''.join(out).

**Called by:** [`AssemblerContext.eval_cond_arg`](#assemblercontextevalcondarg), [`FirstPassVal`](#firstpassval), [`execute_assembler_command`](#executeassemblercommand)

**Calls:** [`FindHistoricVal`](#findhistoricval), [`dprint`](#dprint)


### `parse_percent_arg`

**Location:** line 3050  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns tuple.

**Called by:** [`expand_percent_functions`](#expandpercentfunctions)

**Calls:** [`FirstPassVal`](#firstpassval), [`expand_unquoted_text`](#expandunquotedtext), [`microcpu.raiseerror`](#microcpuraiseerror), [`nextwordequation`](#nextwordequation)


### `expand_macro_pipeline`

**Location:** line 3074  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Macro expansion or macro-definition helper used by the assembler pipeline.

**Arguments:**

- `text` — Input text block.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.
- `do_stack_ops=True`

**Expected output:** Returns text.

**Called by:** [`OLD_ReplaceMacVars_OLD`](#oldreplacemacvarsold), [`execute_assembler_command`](#executeassemblercommand), [`expand_macro_invocation_text`](#expandmacroinvocationtext), [`parse_arg`](#parsearg)

**Calls:** [`expand_percent_functions`](#expandpercentfunctions), [`expand_unquoted_text`](#expandunquotedtext), [`substitute_macro_stack_opts`](#substitutemacrostackopts)


### `substitute_macro_params_only`

**Location:** line 3083  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Macro expansion or macro-definition helper used by the assembler pipeline.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns ''.join(out).

**Called by:** [`expand_macro_invocation_text`](#expandmacroinvocationtext)

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `substitute_macro_stack_opts`

**Location:** line 3138  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Macro expansion or macro-definition helper used by the assembler pipeline.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns ''.join(out).

**Called by:** [`expand_macro_pipeline`](#expandmacropipeline)

**Calls:** [`microcpu.raiseerror`](#microcpuraiseerror)


### `expand_percent_functions`

**Location:** line 3209  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns ''.join(out).

**Called by:** [`expand_macro_pipeline`](#expandmacropipeline)

**Calls:** [`GetQuoted`](#getquoted), [`expand_unquoted_text`](#expandunquotedtext), [`microcpu.raiseerror`](#microcpuraiseerror), [`nextwordplus`](#nextwordplus), [`parse_percent_arg`](#parsepercentarg)


### `OLD_ReplaceMacVars_OLD`

**Location:** line 3314  

**Group:** Macro expansion and macro command processing  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** # Replace simple macro variables/functions only. # Deliberately DOES NOT expand: # %REPEAT ... %ENDR # %( ... %) # Those belong to expand_macro_text(), because they have sequencing # and side-effect semantics.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns tuple.

**Called by:** None detected.

**Calls:** [`GetQuoted`](#getquoted), [`dprint`](#dprint), [`expand_macro_pipeline`](#expandmacropipeline), [`microcpu.raiseerror`](#microcpuraiseerror), [`nextword`](#nextword), [`parse_arg`](#parsearg)


### `FirstPassVal`

**Location:** line 3580  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** code, and only is a 'value' used by the assembler. Then it CAN NOT be defered for a second pass. We need that 'word' of storage to hold temporary values that will later be replaed. All other values (such as when labels are themselves used a...

**Arguments:**

- `instr`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `filename=None` — Current source filename used for diagnostics and local-symbol resolution.
- `allow_braces=True` — Allows `{symbol}` style expressions while decoding values.

**Expected output:** Returns tuple.

**Called by:** [`AssemblerContext.eval_arg`](#assemblercontextevalarg), [`execute_assembler_command`](#executeassemblercommand), [`parse_percent_arg`](#parsepercentarg)

**Calls:** [`DecodeStr`](#decodestr), [`Str2Word`](#str2word), [`dprint`](#dprint), [`expand_brace_refs`](#expandbracerefs), [`microcpu.raiseerror`](#microcpuraiseerror), [`nextwordequation`](#nextwordequation)


### `parse_expression`

**Location:** line 3627  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Splits expression into (prefix, base_expr, modifiers[]). Example: '$$label+4-0x10' -> ('$$', 'label', ['+4', '-0x10'])

**Arguments:**

- `expr`

**Expected output:** Returns tuple.

**Called by:** [`DecodeStr`](#decodestr)

**Calls:** None detected.


### `decode_token`

**Location:** line 3654  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Decodes a single token — either a literal or label.

**Arguments:**

- `token`
- `curaddress`
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.
- `JUSTRESULT`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns int, tuple.

**Called by:** [`DecodeStr`](#decodestr)

**Calls:** [`FindHistoricVal`](#findhistoricval), [`IsLocalVar`](#islocalvar), [`Str2Word`](#str2word), [`dprint`](#dprint), [`safeprint`](#safeprint)


### `find_matching_percent_paren`

**Location:** line 3721  

**Group:** Macro expansion and macro command processing  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Given text[start:start+2] == "%(", return the index just after the matching "%)". Supports nested %( ... %) groups. Example: text = "%(A+%(B%)%)" start = 0 returns len(text)

**Arguments:**

- `text` — Input text block.
- `start`

**Expected output:** Returns -1, i.

**Called by:** None detected.

**Calls:** None detected.


### `macro_arg_value`

**Location:** line 3753  

**Group:** Macro expansion and macro command processing  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Return current macro argument %n from the current macro frame. n=0 returns %0. n=1 returns %1.

**Arguments:**

- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `n`

**Expected output:** Returns context.MacroVars[slot], str.

**Called by:** None detected.

**Calls:** None detected.


### `macro_stack_value`

**Location:** line 3768  

**Group:** Macro expansion and macro command processing  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Expand MacroStack references. %V = top of MacroStack %W = second item from top This assumes MacroStack is the global list you are already using.

**Arguments:**

- `which`

**Expected output:** Returns str, str(MacroStack[-1]), str(MacroStack[-2]).

**Called by:** None detected.

**Calls:** None detected.


### `DecodeStr`

**Location:** line 3792  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Expression/symbol evaluation helper used during assembly and macro expansion.

**Arguments:**

- `instr`
- `curaddress`
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.
- `JUSTRESULT`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns base_result[1], curaddress, int, result.

**Called by:** [`FirstPassVal`](#firstpassval), [`execute_assembler_command`](#executeassemblercommand), [`handle_semicolon`](#handlesemicolon)

**Calls:** [`decode_token`](#decodetoken), [`dprint`](#dprint), [`microcpu.raiseerror`](#microcpuraiseerror), [`parse_expression`](#parseexpression), [`safeprint`](#safeprint)


### `IsUserSymbol`

**Location:** line 3925  

**Group:** Miscellaneous utilities  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `sym`

**Expected output:** Returns bool.

**Called by:** None detected.

**Calls:** None detected.


### `IsCompilerGenerated`

**Location:** line 3936  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `sym`

**Expected output:** Returns sym.startswith('_J_') or sym.startswith(.

**Called by:** [`resolve_all_forward_references`](#resolveallforwardreferences)

**Calls:** None detected.


### `FinalSymbolReport`

**Location:** line 3943  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** None / side effects only.

**Called by:** [`main`](#main)

**Calls:** None detected.


### `macro_take_raw_frame`

**Location:** line 4018  

**Group:** Macro expansion and macro command processing  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Consume text from context.MacroLine through ENDMACENDMAC. Return the raw text before the marker.

**Arguments:**

- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns tuple.

**Called by:** None detected.

**Calls:** [`nextwordplus`](#nextwordplus)


### `macro_pop_frame`

**Location:** line 4043  

**Group:** Macro expansion and macro command processing  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Macro expansion or macro-definition helper used by the assembler pipeline.

**Arguments:**

- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `macro_apply_backfill`

**Location:** line 4049  

**Group:** Macro expansion and macro command processing  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Macro expansion or macro-definition helper used by the assembler pipeline.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns line.

**Called by:** None detected.

**Calls:** None detected.


### `macro_has_pending_text`

**Location:** line 4055  

**Group:** Macro expansion and macro command processing  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Return True when there is macro-generated text waiting to be drained. For now this preserves the old ActiveMacro-driven behavior. Later, ActiveMacro can probably be removed and MacroLine/backfill can become the source of truth.

**Arguments:**

- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns context.ActiveMacro and (bool(context.Ma.

**Called by:** None detected.

**Calls:** None detected.


### `read_next_physical_line`

**Location:** line 4073  

**Group:** Miscellaneous utilities  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Read the next logical source line. Returns: (line, segments, ExitOut) line: The old behavior: continuation lines merged with spaces. segments: Comment-stripped physical fragments. Trailing continuation backslashes are removed. This preserve...

**Arguments:**

- `infile`
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns tuple.

**Called by:** None detected.

**Calls:** [`AssemblerContext.is_executing`](#assemblercontextisexecuting), [`InputFileData.add_entry`](#inputfiledataaddentry), [`dprint`](#dprint), [`removecomments`](#removecomments)


### `macro_take_next_statement`

**Location:** line 4139  

**Group:** Macro expansion and macro command processing  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Pull one logical statement from context.MacroLine. Statement terminators: - ';' outside quoted strings AND outside %REPEAT/%ENDR bodies - ENDMACENDMAC outside quoted strings, recognized as a token - EOF / no remaining MacroLine text

**Arguments:**

- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns tuple.

**Called by:** None detected.

**Calls:** None detected.


### `queue_tail`

**Location:** line 4262  

**Group:** Miscellaneous utilities  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `cmdq`
- `cmd`
- `tail`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `split_at_semicolon_outside_quotes`

**Location:** line 4274  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Tokenizer/parser helper for extracting assembler words, arguments, or command fragments.

**Arguments:**

- `text` — Input text block.

**Expected output:** Returns tuple.

**Called by:** [`execute_assembler_command`](#executeassemblercommand), [`parse_macro_definition_command`](#parsemacrodefinitioncommand)

**Calls:** None detected.


### `enqueue_front`

**Location:** line 4308  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `cmdq`
- `cmd`
- `text` — Input text block.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `origin=None` — Initial program counter/origin address for a CPU instance.

**Expected output:** May return None.

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`split_source_commands`](#splitsourcecommands)


### `handle_skipped_command`

**Location:** line 4323  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `key`
- `size`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns line[consumed:].strip(), line[size:].strip().

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`AssemblerContext.pop_block`](#assemblercontextpopblock), [`AssemblerContext.push_block`](#assemblercontextpushblock), [`consumed_one_source_command`](#consumedonesourcecommand), [`microcpu.raiseerror`](#microcpuraiseerror)


### `expand_unquoted_text`

**Location:** line 4338  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `body`
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns ''.join(out).strip().

**Called by:** [`AssemblerContext.eval_arg`](#assemblercontextevalarg), [`expand_macro_pipeline`](#expandmacropipeline), [`expand_percent_functions`](#expandpercentfunctions), [`loadfile`](#loadfile), [`parse_percent_arg`](#parsepercentarg)

**Calls:** [`consumed_one_source_command`](#consumedonesourcecommand), [`expand_macro_invocation_text`](#expandmacroinvocationtext), [`microcpu.raiseerror`](#microcpuraiseerror)


### `expand_macro_invocation`

**Location:** line 4418  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Macro expansion or macro-definition helper used by the assembler pipeline.

**Arguments:**

- `cmd`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns expand_macro_invocation_text(removecomme.

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`expand_macro_invocation_text`](#expandmacroinvocationtext), [`removecomments`](#removecomments)


### `expand_macro_invocation_text`

**Location:** line 4427  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Macro expansion or macro-definition helper used by the assembler pipeline.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.
- `append_rest=True`

**Expected output:** Returns expanded.

**Called by:** [`expand_macro_invocation`](#expandmacroinvocation), [`expand_unquoted_text`](#expandunquotedtext)

**Calls:** [`create_new_unique`](#createnewunique), [`expand_macro_pipeline`](#expandmacropipeline), [`microcpu.raiseerror`](#microcpuraiseerror), [`next_macro_arg`](#nextmacroarg), [`nextwordplus`](#nextwordplus), [`substitute_macro_params_only`](#substitutemacroparamsonly)


### `read_next_source_command`

**Location:** line 4476  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Read one logical source command from infile. Rules: - Physical lines may continue with trailing backslash. - Comments are removed before checking for continuation. - Blank/comment-only lines are skipped. - Returned object is a SourceCommand...

**Arguments:**

- `infile`
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `wfilename`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns NoneType, SourceCommand(text=text, filename=filena.

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`dprint`](#dprint), [`removecomments`](#removecomments)


### `parse_macro_definition_command`

**Location:** line 4546  

**Group:** Macro expansion and macro command processing  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Parse: M name body ; MC name body ; # if you still use MC as macro define Returns: macro_name, macro_body, rest_after_semicolon

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `key`
- `size`
- `cmdq=None`

**Expected output:** Returns tuple.

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`nextwordplus`](#nextwordplus), [`split_at_semicolon_outside_quotes`](#splitatsemicolonoutsidequotes)


### `loadfile`

**Location:** line 4575  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Load file is also the effective main loop for the assembler def loadfile(filename, offset, CPU, LorgFlag,  LocalID, context: AssemblerContext):

**Arguments:**

- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `offset`
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.
- `LorgFlag`
- `LocalID`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** Returns context.address.

**Called by:** [`debugger`](#debugger), [`execute_assembler_command`](#executeassemblercommand), [`main`](#main)

**Calls:** [`AssemblerContext.define_macro`](#assemblercontextdefinemacro), [`AssemblerContext.evaluate_condition`](#assemblercontextevaluatecondition), [`AssemblerContext.is_executing`](#assemblercontextisexecuting), [`AssemblerContext.pop_block`](#assemblercontextpopblock), [`AssemblerContext.push_block`](#assemblercontextpushblock), [`dprint`](#dprint), [`enqueue_front`](#enqueuefront), [`execute_assembler_command`](#executeassemblercommand), [`expand_macro_invocation`](#expandmacroinvocation), [`expand_unquoted_text`](#expandunquotedtext), … +7 more


### `longest_prefix_match`

**Location:** line 4678  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `s` — Input string.
- `d`

**Expected output:** Returns NoneType, key.

**Called by:** [`consumed_one_source_command`](#consumedonesourcecommand)

**Calls:** None detected.


### `consumed_one_source_command`

**Location:** line 4684  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU=None` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns i, i + kused, used.

**Called by:** [`expand_unquoted_text`](#expandunquotedtext), [`handle_skipped_command`](#handleskippedcommand), [`skip_one_source_command`](#skiponesourcecommand)

**Calls:** [`longest_prefix_match`](#longestprefixmatch), [`microcpu.raiseerror`](#microcpuraiseerror), [`next_macro_arg`](#nextmacroarg), [`nextword`](#nextword), [`nextwordequation`](#nextwordequation), [`nextwordplus`](#nextwordplus), [`skip_ws`](#skipws)


### `skip_one_source_command`

**Location:** line 4745  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `line` — Current source text or command fragment being parsed.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU=None` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** Returns line[used:].lstrip().

**Called by:** None detected.

**Calls:** [`consumed_one_source_command`](#consumedonesourcecommand)


### `split_source_commands`

**Location:** line 4749  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Split expanded source text into SourceCommand objects. Semicolon is a command separator only when not inside: - double quotes: "..." - single quotes: '...' - backquote macro-protection: `...` Backquotes are preserved here. They are macro-ex...

**Arguments:**

- `text` — Input text block.
- `filename` — Current source filename used for diagnostics and local-symbol resolution.
- `resolved_filename` — Canonical/resolved source path used for source mapping and diagnostics.
- `line_num` — 1-based source line number used for source mapping/error reports.
- `address` — 16-bit memory address or assembler output address, depending on context.
- `origin='file'` — Initial program counter/origin address for a CPU instance.

**Expected output:** Returns out.

**Called by:** [`enqueue_front`](#enqueuefront)

**Calls:** None detected.


### `execute_assembler_command`

**Location:** line 4820  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `cmd`
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** May return None.

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`AssemblerContext.max_macro_arg_index`](#assemblercontextmaxmacroargindex), [`DecodeStr`](#decodestr), [`FirstPassVal`](#firstpassval), [`IsLocalVar`](#islocalvar), [`Str2Word`](#str2word), [`UpdateVarHistory`](#updatevarhistory), [`dprint`](#dprint), [`expand_brace_refs`](#expandbracerefs), [`expand_macro_pipeline`](#expandmacropipeline), [`handle_semicolon`](#handlesemicolon), … +6 more


### `resolve_all_forward_references`

**Location:** line 5179  

**Group:** Miscellaneous utilities  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `context` — AssemblerContext carrying labels, macro state, file state, and options.
- `CPU` — microcpu instance used for memory access, opcode helpers, and fatal error reporting.

**Expected output:** None / side effects only.

**Called by:** [`loadfile`](#loadfile)

**Calls:** [`IsCompilerGenerated`](#iscompilergenerated), [`Str2Word`](#str2word), [`dprint`](#dprint), [`microcpu.highbyte`](#microcpuhighbyte), [`microcpu.lowbyte`](#microcpulowbyte)


### `CloseLocalHistories`

**Location:** line 5250  

**Group:** Miscellaneous utilities  

**Reachability:** **ORPHAN / disconnected from static `main` tree**  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `local_id`
- `end_address`

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** None detected.


### `debugger`

**Location:** line 5264  

**Group:** Source map and debugger helpers  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Debugging or diagnostic output helper.

**Arguments:**

- `passline`
- `context` — AssemblerContext carrying labels, macro state, file state, and options.

**Expected output:** None / side effects only.

**Called by:** [`main`](#main), [`microcpu._handle_return_code`](#microcpuhandlereturncode), [`microcpu.raiseerror`](#microcpuraiseerror), [`shandler`](#shandler)

**Calls:** [`DissAsm`](#dissasm), [`FindHistoricVal`](#findhistoricval), [`GetQuoted`](#getquoted), [`IsLabelActive`](#islabelactive), [`PollReSetRawFunc`](#pollresetrawfunc), [`PollSetEchoFunc`](#pollsetechofunc), [`PollSetRawFunc`](#pollsetrawfunc), [`Str2Byte`](#str2byte), [`Str2Word`](#str2word), [`hexdump`](#hexdump), … +14 more


### `looks_numeric`

**Location:** line 5991  

**Group:** Parsing, tokenizing, and expression/value decoding  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `tok`

**Expected output:** Returns bool, tok.isdigit(), tok[1:].isdigit(), tok[2:].isdigit().

**Called by:** [`debugger`](#debugger)

**Calls:** None detected.


### `IsLabelActive`

**Location:** line 6013  

**Group:** Assembly loading, labels, directives, and memory emission  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Utility/helper function used by the assembler/emulator support code.

**Arguments:**

- `name`
- `pc`

**Expected output:** Returns bool.

**Called by:** [`debugger`](#debugger)

**Calls:** None detected.


### `main`

**Location:** line 6027  

**Group:** Program entry / top-level control  

**Reachability:** reachable from `main`/top-level root  

**Summary:** Command-line entry point. Parses options, initializes assembler/CPU state, loads source, and runs/debugs the generated program.

**Arguments:** None.

**Expected output:** None / side effects only.

**Called by:** None detected.

**Calls:** [`DissAsm`](#dissasm), [`FinalSymbolReport`](#finalsymbolreport), [`Str2Word`](#str2word), [`create_new_filename`](#createnewfilename), [`debugger`](#debugger), [`dprint`](#dprint), [`loadfile`](#loadfile), [`microcpu.evalpc`](#microcpuevalpc), [`safeprint`](#safeprint)
