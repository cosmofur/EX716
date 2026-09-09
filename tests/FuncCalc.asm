I common.mc
L softstack.ld
L heapmgr.ld
L string.ld
L lmath.ld

# FuncCalc - line oriented function calculator prototype in EX716 assembly.
#
# Implemented first slice:
#   NAME=number
#   NAME="visible ascii text"
#   NAME=OTHERVAR
#   PRINT(NAME), PRINT("text"), PRINT(123)
#   QUIT / EXIT
#
# Parser extension labels are kept explicit so expression parsing, DEFUN blocks,
# WHILE blocks, string slices, and builtin dispatch can be attached without
# changing the variable table/runtime storage model.
#
# Callable function map:
# function():void "Program entry; initializes runtime and enters the REPL."
# FCInit():void "Creates the heap, soft stack, and initial variable table."
# FCReadLine():[lineptr] "Allocates and reads one input line from the console."
# FCFreeString(ptr):void "Deletes a heap string/object when ptr is non-zero."
# FCHandleLine(inptr):void "Dispatches one REPL line to commands or a statement list."
# FCCompileStatementList(inptr):[listptr] "Builds linked statement objects from a semicolon list."
# FCCompileStatement(src,len):[stmtptr] "Creates one statement object from a source slice."
# FCExecStatementList(listptr):void "Executes linked statements until end or RETURN."
# FCExecStatement(stmtptr):void "Executes one compiled statement object."
# FCFreeStatementList(listptr):void "Frees linked statement objects and owned text."
# FCStatementLinkedToList(stmtptr):[listptr] "Moves linked statement nodes into a pointer list."
# FCExecCodeList(listptr):void "Executes statement nodes stored in a pointer list."
# FCFreeCodeList(listptr):void "Frees a pointer list of statement nodes and owned text."
# FCFindStatementSep(ptr):[sepptr] "Finds a top-level semicolon outside strings/grouping."
# FCHelpStatement():void "Prints the built-in help text."
# FCMemStatement():void "Prints variable table and heap memory statistics."
# FCCleanStatement(argptr):void "Deletes all variables or one named variable."
# FCListStatement(argptr):void "Temporarily compiles LIST name=statements into a stored list."
# FCExecListStatement(argptr):void "Temporarily executes a stored statement list variable."
# FCAssignStatement(inptr):void "Parses NAME=expression and stores the result."
# FCPrintStatement(inptr):void "Evaluates and prints an expression."
# FCEvalExpr(exprptr):void "Evaluates an expression into EvalType/EvalI32/EvalStr."
# FCParseExpr(inptr):[newptr] "Parses additive numeric expressions."
# FCParseTerm(inptr):[newptr] "Parses multiplicative numeric expressions."
# FCParseUnary(inptr):[newptr] "Parses unary negation."
# FCParsePrimary(inptr):[newptr] "Parses literals, variables, grouping, and calls."
# FCScanNumberEnd(ptr):[endptr] "Returns the first byte after a decimal integer."
# FCScanNameEnd(ptr):[endptr] "Returns the first byte after a name/function token."
# FCEvalAtom(exprptr):void "Compatibility wrapper for primary expression parsing."
# FCEvalFunctionCall(exprptr):[matched] "Compatibility wrapper for call parsing."
# FCFindCloseParen(openptr):[closeptr] "Finds the matching close parenthesis."
# FCFindArgComma(ptr):[commaptr] "Finds a top-level comma in an argument list."
# FCParseArgList(argptr):[arg...,argcount] "Parses call args and pushes value records plus count."
# FCPushEvalArg():[type,low,high,flags] "Transfers current Eval state into one stack arg record."
# FCReleaseArg(type,low,high,flags):void "Frees one parsed arg record if it owns heap storage."
# FCDiscardArgs(count):void "Releases count parsed arg records from the stack."
# FCDispatchFunctionParsed(name):[matched] "Dispatches a parsed-argument function call."
# FCDispatchUserFunctionParsed(name):[matched] "Placeholder hook for parsed DEFUN calls."
# FCDispatchBuiltinParsed(name):[matched] "Dispatches parsed-argument builtins."
# FCBuiltinAbsParsed(argcount):void "Evaluates parsed ABS argument."
# FCBuiltinMinParsed(argcount):void "Evaluates parsed MIN over one or more numeric args."
# FCBuiltinLenParsed(argcount):void "Evaluates parsed LEN argument."
# FCBuiltinValParsed(argcount):void "Evaluates parsed VAL argument."
# FCBuiltinStrParsed(argcount):void "Evaluates parsed STR$ argument."
# FCBuiltinSplitParsed(argcount):void "Evaluates parsed SPLIT arguments."
# FCDispatchFunction(name,argptr):[matched] "Dispatches builtins, then user hook."
# FCDispatchUserFunction(name,argptr):[matched] "Placeholder hook for DEFUN lookup."
# FCDispatchBuiltin(name,argptr):[matched] "Dispatches supported built-in functions."
# FCBuiltinAbs(argptr):void "Evaluates ABS(number)."
# FCBuiltinMin(argptr):void "Evaluates MIN(number,number)."
# FCBuiltinLen(argptr):void "Evaluates LEN(string)."
# FCBuiltinVal(argptr):void "Evaluates VAL(string)."
# FCBuiltinStr(argptr):void "Evaluates STR$(number)."
# FCBuiltinSplit(argptr):void "Evaluates SPLIT(string,start,stop)."
# FCStoreEval(slot):void "Stores the current Eval value into a variable slot."
# FCStorePointerValue(slot,type,payload):void "Stores a pointer payload value into a variable slot."
# FCFindOrAllocSlot(name):[slot] "Finds an existing variable slot or allocates one."
# FCFindSlot(name):[slot] "Finds an active variable slot by name."
# FCAllocSlot():[slot] "Allocates the next variable slot, growing the table if needed."
# FCSymTableGrow():[tableptr] "Doubles the heap-backed variable table."
# FCValueFromEval():[valueptr] "Creates a heap value object from current Eval state."
# FCLoadValue(valueptr):void "Loads a heap value object into current Eval state."
# FCDeleteValue(valueptr):void "Deletes a heap value object and owned nested storage."
# FCReleaseEvalString():void "Frees the current temporary Eval string if owned."
# FCSubStringDup(src,len):[dst] "Copies len bytes from src into a new heap string."
# FCStringDup(src):[dst] "Duplicates a null-terminated string into heap storage."
# FCListNew(capacity):[listptr] "Creates a heap list of pointer slots plus terminator."
# FCListAppend(listptr,itemptr):[listptr] "Appends one pointer, growing the list if needed."
# FCListFree(listptr):void "Frees a heap list object but not its pointed-to items."
# FCListFreeItems(listptr):void "Frees every pointed-to item, then the list object."
# FCStrEq(left,right):[equal] "Returns true only when two strings match exactly."
# FCDeleteAllSlots():void "Deletes all active variable names and values."
# FCDeleteSlot(slot):void "Deletes one slot and compacts the active slot list."
# FCValidName(name):[valid] "Checks FuncCalc variable/function name syntax."
# FCValidNameTailChar(ptr):[valid] "Checks one non-leading name character."
# FCSkipWhite(ptr):[ptr] "Skips spaces and tabs."
# FCTrimRight(str):void "Trims trailing spaces and tabs in place."
# FCClearVarTable(table):void "Clears all slots in a variable table."
# FCParseStatementList(inptr):[listptr] "Compatibility wrapper for statement-list compilation."
# FCParseExpression(exprptr):void "Compatibility wrapper for expression evaluation."
# FCDefineFunction():void "Placeholder for DEFUN support."
# FCWhileBlock():void "Placeholder for WHILE support."

=FC_INITIAL_SLOTS 20
=FC_NAME_LEN 8
=FC_TABLE_TOTAL 0
=FC_TABLE_ACTIVE 2
=FC_TABLE_SLOTBYTES 4
=FC_TABLE_HEADER 6
=FC_SLOT_HASH1 0
=FC_SLOT_HASH2 2
=FC_SLOT_FLAGS 4
=FC_SLOT_TYPE 6
=FC_SLOT_NAMEPTR 8
=FC_SLOT_VALUEPTR 10
=FC_SLOT_SIZE 12
=FC_SLOT_EMPTY 0
=FC_SLOT_ACTIVE 1
=FC_SLOT_DELETED 2
=FC_TYPE_EMPTY 0
=FC_TYPE_I32 1
=FC_TYPE_STR 2
=FC_TYPE_LIST 3
=FC_TYPE_FUNC 4
=FC_VAL_TYPE 0
=FC_VAL_LOW 2
=FC_VAL_HIGH 4
=FC_VAL_SIZE 6
=FC_LIST_COUNT 0
=FC_LIST_CAPACITY 2
=FC_LIST_ITEMS 4
=FC_LIST_MINCAP 4
=FC_ARG_VAL 0
=FC_ARG_HEAP 1
=FC_STMT_NEXT 0
=FC_STMT_TYPE 2
=FC_STMT_TEXTPTR 4
=FC_STMT_AUXPTR 6
=FC_STMT_SIZE 8
=FC_STMT_ASSIGN 1
=FC_STMT_PRINT 2
=FC_STMT_EXPR 3
=FC_STMT_RETURN 4

:MainHeapID 0
:LinePtr 0
:QuitFlag 0
:EqPtr 0
:NamePtr 0
:ValuePtr 0
:FoundSlot 0
:FreeSlot 0
:VarTablePtr 0
:ValueObjPtr 0
:EvalType 0
:EvalI32 0  0
:LeftI32 0 0
:EvalStr 0
:EvalStrObj 0
:EvalStrOwned 0
:ExprOpPtr 0
:FCArgEndPtr 0
:FCReturnFlag 0
:PrintBuff "00000000000\0"
:FcPrompt "FC> \0"
:MsgIntro "FuncCalc assembly prototype. QUIT exits.\0"
:MsgErr "ERR\0"
:MsgOk "OK\0"
:KwQuit "QUIT\0"
:KwExit "EXIT\0"
:KwPrint "PRINT\0"
:KwMem "MEM\0"
:KwClean "CLEAN\0"
:KwHelp "HELP\0"
:KwList "LIST\0"
:KwExec "EXEC\0"
:KwAbs "ABS\0"
:KwMin "MIN\0"
:KwLen "LEN\0"
:KwVal "VAL\0"
:KwStr "STR$\0"
:KwSplit "SPLIT\0"
:KwReturn "RETURN\0"
:Main . Main
@CALL FCInit
@PRTS MsgIntro @PRTNL
@MA2V 0  QuitFlag
@PUSHI QuitFlag
@WHILE_ZERO
   @POPNULL
   @PRTSTR FcPrompt
   @CALL FCReadLine
   @POPI LinePtr
   @PUSHI LinePtr
   @CALL FCHandleLine
   @PUSHI LinePtr
   @CALL FCFreeString
   @PUSHI QuitFlag
@ENDWHILE
@POPNULL
@PRTLN "Bye."
@END

:FCInit
@PUSH END__ @PUSH 0xf800 @SUB END__
@CALL HeapDefineMemory
@POPI MainHeapID
@PUSHI MainHeapID @PUSH 0x600
@CALL HeapNewObject @IF_ULT_A 100 @PRTLN "Heap stack failed" @END @ENDIF
@DUP @ADD 0x600 @SWP
@CALL SetSSStack
@PUSHI MainHeapID @PUSH 246
@CALL HeapNewObject @IF_ULT_A 100 @PRTLN "Heap vars failed" @END @ENDIF
@POPI VarTablePtr
@PUSH FC_INITIAL_SLOTS @PUSHI VarTablePtr @ADD FC_TABLE_TOTAL @POPS
@PUSH 0 @PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @POPS
@PUSH FC_SLOT_SIZE @PUSHI VarTablePtr @ADD FC_TABLE_SLOTBYTES @POPS
@RET

:FCReadLine
@PUSHRETURN
@Locals
   @Local NewLine
@PUSHI MainHeapID @PUSH 255
@CALL HeapNewObject @IF_ULT_A 100 @PRTLN "Heap line failed" @END @ENDIF
@POPI NewLine
@READSI NewLine
@PUSHI NewLine
@EndLocals
@POPRETURN
@RET

:FCFreeString
@PUSHRETURN
@Locals
   @Local ptr
@POPI ptr
@PUSHI ptr
@IF_NOTZERO
   @POPNULL
   @Call(VV) HeapDeleteObject MainHeapID ptr @POPNULL
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCHandleLine
@PUSHRETURN
@Locals
   @Local inptr
   @Local cmdcopy
   @Local stmtlist
@POPI inptr
@Call(V) FCSkipWhite inptr @POPI inptr
@Call(V) FCStringDup inptr @POPI cmdcopy
@Call(V) strUpCase cmdcopy
@Call(V) FCTrimRight cmdcopy
@Call(VA) strcmp cmdcopy KwQuit
@IF_ZERO
   @POPNULL @MA2V 1 QuitFlag @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VA) strcmp cmdcopy KwExit
@IF_ZERO
   @POPNULL @MA2V 1 QuitFlag @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VA) strcmp cmdcopy KwHelp
@IF_ZERO
   @POPNULL @CALL FCHelpStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VA) strcmp cmdcopy KwMem
@IF_ZERO
   @POPNULL @CALL FCMemStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VAA) strncmp cmdcopy KwClean 5
@IF_ZERO
   @POPNULL @PUSHI inptr @ADD 5 @CALL FCCleanStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VAA) strncmp cmdcopy KwList 4
@IF_ZERO
   @POPNULL @PUSHI inptr @ADD 4 @CALL FCListStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VAA) strncmp cmdcopy KwExec 4
@IF_ZERO
   @POPNULL @PUSHI inptr @ADD 4 @CALL FCExecListStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(V) FCCompileStatementList inptr @POPI stmtlist
@MA2V 0 FCReturnFlag
@Call(V) FCExecStatementList stmtlist
@Call(V) FCFreeStatementList stmtlist
:FCHandleDone
@Call(V) FCFreeString cmdcopy
@EndLocals
@POPRETURN
@RET


:FCHelpStatement
@PRTLN "Commands:"
@PRTLN "  NAME=number|string|expr"
@PRTLN "  PRINT expr"
@PRTLN "  MEM"
@PRTLN "  CLEAN [name]"
@PRTLN "  LIST name=stmt[;stmt]"
@PRTLN "  EXEC name"
@PRTLN "  ABS(expr), MIN(expr,expr)"
@PRTLN "  LEN(str), VAL(str), STR$(int)"
@PRTLN "  SPLIT(str,start,stop)"
@PRTLN "  HELP"
@PRTLN "  QUIT"
@RET

:FCMemStatement
@PRT "MEM TotalSlots: "
@PUSHI VarTablePtr @ADD FC_TABLE_TOTAL @PUSHS @PRTTOP @POPNULL @PRTNL
@PRT "MEM ActiveSlots: "
@PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @PUSHS @PRTTOP @POPNULL @PRTNL
@PRT "MEM HeapAvailable: "
@Call(V) HeapAvailable MainHeapID @PRTTOP @POPNULL @PRTNL
@Call(V) HeapListMap MainHeapID
@RET

:FCCleanStatement
@PUSHRETURN
@Locals
   @Local argptr
   @Local slot
@POPI argptr
@Call(V) FCSkipWhite argptr @POPI argptr
@PUSHII argptr @AND 0xff
@IF_ZERO
   @POPNULL
   @CALL FCDeleteAllSlots
   @PRTLN "OK cleaned all"
   @JMP FCCleanDone
@ENDIF
@POPNULL
@Call(V) FCTrimRight argptr
@Call(V) FCFindSlot argptr @POPI slot
@PUSHI slot
@IF_ZERO
   @POPNULL
   @PRTLN "ERR no such variable"
@ELSE
   @POPNULL
   @Call(V) FCDeleteSlot slot
   @PRTLN "OK cleaned variable"
@ENDIF
:FCCleanDone
@EndLocals
@POPRETURN
@RET

:FCListStatement
@PUSHRETURN
@Locals
   @Local argptr
   @Local slot
   @Local linked
   @Local listptr
@POPI argptr
@Call(V) FCSkipWhite argptr @POPI argptr
@Call(VA) strfndc argptr "=\0" @POPI EqPtr
@PUSHI EqPtr
@IF_ZERO
   @POPNULL @PRTLN "ERR LIST expected name=statements"
   @JMP FCListStmtDone
@ENDIF
@POPNULL
@PUSHII EqPtr @AND 0xff00 @PUSHI EqPtr @POPS
@MV2V argptr NamePtr
@Call(V) FCTrimRight NamePtr
@Call(V) FCValidName NamePtr
@IF_ZERO
   @POPNULL @PRTLN "ERR bad name"
   @JMP FCListStmtDone
@ENDIF
@POPNULL
@Call(V) FCFindOrAllocSlot NamePtr @POPI slot
@PUSHI slot
@IF_ZERO
   @POPNULL @PRTLN "ERR variable table full"
   @JMP FCListStmtDone
@ENDIF
@POPNULL
@PUSHI EqPtr @ADD 1 @CALL FCSkipWhite @POPI argptr
@Call(V) FCCompileStatementList argptr @POPI linked
@Call(V) FCStatementLinkedToList linked @POPI listptr
@Call(VAV) FCStorePointerValue slot FC_TYPE_LIST listptr
@PRTS MsgOk @PRTNL
:FCListStmtDone
@EndLocals
@POPRETURN
@RET

:FCExecListStatement
@PUSHRETURN
@Locals
   @Local argptr
   @Local slot
   @Local valptr
   @Local typev
   @Local listptr
@POPI argptr
@Call(V) FCSkipWhite argptr @POPI argptr
@Call(V) FCTrimRight argptr
@Call(V) FCFindSlot argptr @POPI slot
@PUSHI slot
@IF_ZERO
   @POPNULL @PRTLN "ERR no such list"
   @JMP FCExecListDone
@ENDIF
@POPNULL
@PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @POPI valptr
@PUSHII valptr @AND 0xff @POPI typev
@PUSHI typev
@IF_EQ_A FC_TYPE_LIST
   @POPNULL
   @PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI listptr
   @MA2V 0 FCReturnFlag
   @Call(V) FCExecCodeList listptr
@ELSE
   @POPNULL @PRTLN "ERR variable is not a list"
@ENDIF
:FCExecListDone
@EndLocals
@POPRETURN
@RET

:FCAssignStatement
@PUSHRETURN
@Locals
   @Local inptr
   @Local TargetSlot
@POPI inptr
@Call(VA) strfndc inptr "=\0" @POPI EqPtr
@PUSHI EqPtr
@IF_ZERO
   @POPNULL @PRTLN "ERR expected assignment or PRINT"
   @JMP FCAssignDone
@ENDIF
@POPNULL
@PUSHII EqPtr @AND 0xff00 @PUSHI EqPtr @POPS       # terminate name in-place
@MV2V inptr NamePtr
@PUSHI EqPtr @ADD 1 @CALL FCSkipWhite @POPI ValuePtr
@Call(V) FCTrimRight NamePtr
@Call(V) FCValidName NamePtr
@IF_ZERO
   @POPNULL @PRTLN "ERR bad name"
   @JMP FCAssignDone
@ENDIF
@POPNULL
@Call(V) FCFindOrAllocSlot NamePtr @POPI TargetSlot
@PUSHI TargetSlot
@IF_ZERO
   @POPNULL @PRTLN "ERR variable table full"
   @JMP FCAssignDone
@ENDIF
@POPNULL
@Call(V) FCEvalExpr ValuePtr
@Call(V) FCStoreEval TargetSlot
@PRTS MsgOk @PRTNL
:FCAssignDone
@EndLocals
@POPRETURN
@RET

:FCPrintStatement
@PUSHRETURN
@Locals
   @Local inptr
   @Local closeptr
@POPI inptr
@Call(V) FCSkipWhite inptr @POPI inptr
@Call(V) FCTrimRight inptr
@Call(V) FCEvalExpr inptr
@PUSHI EvalType
@SWITCH
   @CASE FC_TYPE_I32
      @POPNULL
      @Call(AVVA) i32tos PrintBuff EvalI32 EvalI32+2 10
      @PRTS PrintBuff @PRTNL
      @CBREAK
   @CASE FC_TYPE_STR
      @POPNULL
      @PRTSI EvalStr
      @PRTNL
      @CALL FCReleaseEvalString
      @CBREAK
   @CDEFAULT
      @POPNULL @PRTLN "ERR nothing to print" @CBREAK
@ENDCASE
@EndLocals
@POPRETURN
@RET



:FCCompileStatementList
@PUSHRETURN
@Locals
   @Local inptr
   @Local sep
   @Local seglen
   @Local stmt
   @Local head
   @Local tail
   @Local done
@POPI inptr
@MA2V 0 head
@MA2V 0 tail
@MA2V 0 done
@PUSHI done
@WHILE_ZERO
   @POPNULL
   @Call(V) FCSkipWhite inptr @POPI inptr
   @Call(V) FCFindStatementSep inptr @POPI sep
   @PUSHI sep
   @IF_ZERO
      @POPNULL
      @Call(V) strlen inptr @POPI seglen
      @MA2V 1 done
   @ELSE
      @POPNULL
      @PUSHI sep @SUBI inptr @POPI seglen
   @ENDIF
   @PUSHI seglen
   @IF_NOTZERO
      @POPNULL
      @Call(VV) FCCompileStatement inptr seglen @POPI stmt
      @PUSHI stmt
      @IF_NOTZERO
         @POPNULL
         @PUSHI head
         @IF_ZERO
            @POPNULL
            @MV2V stmt head
            @MV2V stmt tail
         @ELSE
            @POPNULL
            @PUSHI stmt @PUSHI tail @ADD FC_STMT_NEXT @POPS
            @MV2V stmt tail
         @ENDIF
      @ELSE
         @POPNULL
      @ENDIF
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI done
   @IF_ZERO
      @POPNULL
      @PUSHI sep @ADD 1 @POPI inptr
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI done
@ENDWHILE
@POPNULL
@PUSHI head
@EndLocals
@POPRETURN
@RET

:FCCompileStatement
@PUSHRETURN
@Locals
   @Local src
   @Local len
   @Local text
   @Local typeptr
   @Local cmdcopy
   @Local stmt
   @Local typev
@POPI len
@POPI src
@Call(VV) FCSubStringDup src len @POPI text
@Call(V) FCTrimRight text
@Call(V) FCSkipWhite text @POPI typeptr
@Call(V) FCStringDup typeptr @POPI cmdcopy
@Call(V) strUpCase cmdcopy
@MA2V FC_STMT_EXPR typev
@Call(VAA) strncmp cmdcopy KwPrint 5
@IF_ZERO
   @POPNULL
   @MA2V FC_STMT_PRINT typev
@ELSE
   @POPNULL
   @Call(VAA) strncmp cmdcopy KwReturn 6
   @IF_ZERO
      @POPNULL
      @MA2V FC_STMT_RETURN typev
   @ELSE
      @POPNULL
      @Call(VA) strfndc typeptr "=\0"
      @IF_NOTZERO
         @POPNULL
         @MA2V FC_STMT_ASSIGN typev
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
@ENDIF
@Call(VA) HeapNewObject MainHeapID FC_STMT_SIZE @POPI stmt
@PUSH 0 @PUSHI stmt @ADD FC_STMT_NEXT @POPS
@PUSHI typev @PUSHI stmt @ADD FC_STMT_TYPE @POPS
@PUSHI text @PUSHI stmt @ADD FC_STMT_TEXTPTR @POPS
@PUSH 0 @PUSHI stmt @ADD FC_STMT_AUXPTR @POPS
@Call(V) FCFreeString cmdcopy
@PUSHI stmt
@EndLocals
@POPRETURN
@RET

:FCExecStatementList
@PUSHRETURN
@Locals
   @Local stmt
   @Local nextstmt
@POPI stmt
@PUSHI stmt
@WHILE_NOTZERO
   @POPI stmt
   @PUSHI stmt @ADD FC_STMT_NEXT @PUSHS @POPI nextstmt
   @Call(V) FCExecStatement stmt
   @PUSHI FCReturnFlag
   @IF_NOTZERO
      @POPNULL
      @PUSH 0
   @ELSE
      @POPNULL
      @PUSHI nextstmt
   @ENDIF
@ENDWHILE
@POPNULL
@EndLocals
@POPRETURN
@RET

:FCExecStatement
@PUSHRETURN
@Locals
   @Local stmt
   @Local typev
   @Local text
   @Local runptr
   @Local workptr
@POPI stmt
@PUSHI stmt @ADD FC_STMT_TYPE @PUSHS @POPI typev
@PUSHI stmt @ADD FC_STMT_TEXTPTR @PUSHS @POPI text
@Call(V) FCSkipWhite text @POPI runptr
@PUSHI typev
@SWITCH
   @CASE FC_STMT_ASSIGN
      @POPNULL
      @Call(V) FCStringDup runptr @POPI workptr
      @Call(V) FCAssignStatement workptr
      @Call(V) FCFreeString workptr
      @CBREAK
   @CASE FC_STMT_PRINT
      @POPNULL
      @PUSHI runptr @ADD 5 @CALL FCPrintStatement
      @CBREAK
   @CASE FC_STMT_RETURN
      @POPNULL
      @PUSHI runptr @ADD 6 @CALL FCEvalExpr
      @MA2V 1 FCReturnFlag
      @CBREAK
   @CASE FC_STMT_EXPR
      @POPNULL
      @Call(V) FCEvalExpr runptr
      @CALL FCReleaseEvalString
      @CBREAK
   @CDEFAULT
      @POPNULL
      @PRTLN "ERR bad statement"
      @CBREAK
@ENDCASE
@EndLocals
@POPRETURN
@RET

:FCFreeStatementList
@PUSHRETURN
@Locals
   @Local stmt
   @Local nextstmt
   @Local objptr
@POPI stmt
@PUSHI stmt
@WHILE_NOTZERO
   @POPI stmt
   @PUSHI stmt @ADD FC_STMT_NEXT @PUSHS @POPI nextstmt
   @PUSHI stmt @ADD FC_STMT_TEXTPTR @PUSHS @POPI objptr
   @PUSHI objptr
   @IF_NOTZERO
      @POPNULL
      @Call(VV) HeapDeleteObject MainHeapID objptr @POPNULL
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI stmt @ADD FC_STMT_AUXPTR @PUSHS @POPI objptr
   @PUSHI objptr
   @IF_NOTZERO
      @POPNULL
      @Call(VV) HeapDeleteObject MainHeapID objptr @POPNULL
   @ELSE
      @POPNULL
   @ENDIF
   @Call(VV) HeapDeleteObject MainHeapID stmt @POPNULL
   @PUSHI nextstmt
@ENDWHILE
@POPNULL
@EndLocals
@POPRETURN
@RET

:FCStatementLinkedToList
@PUSHRETURN
@Locals
   @Local stmt
   @Local nextstmt
   @Local listptr
@POPI stmt
@Call(A) FCListNew 4 @POPI listptr
@PUSHI stmt
@WHILE_NOTZERO
   @POPI stmt
   @PUSHI stmt @ADD FC_STMT_NEXT @PUSHS @POPI nextstmt
   @PUSH 0 @PUSHI stmt @ADD FC_STMT_NEXT @POPS
   @Call(VV) FCListAppend listptr stmt @POPI listptr
   @PUSHI nextstmt
@ENDWHILE
@POPNULL
@PUSHI listptr
@EndLocals
@POPRETURN
@RET

:FCExecCodeList
@PUSHRETURN
@Locals
   @Local listptr
   @Local count
   @Local idx
   @Local itemslot
   @Local stmt
@POPI listptr
@PUSHI listptr @ADD FC_LIST_COUNT @PUSHS @POPI count
@MA2V 0 idx
@PUSHI idx
@WHILE_LT_V count
   @POPNULL
   @PUSHI idx @SHL @ADD FC_LIST_ITEMS @ADDI listptr @POPI itemslot
   @PUSHI itemslot @PUSHS @POPI stmt
   @Call(V) FCExecStatement stmt
   @PUSHI FCReturnFlag
   @IF_NOTZERO
      @POPNULL
      @MV2V count idx
   @ELSE
      @POPNULL
      @INCI idx
   @ENDIF
   @PUSHI idx
@ENDWHILE
@POPNULL
@EndLocals
@POPRETURN
@RET

:FCFreeCodeList
@PUSHRETURN
@Locals
   @Local listptr
   @Local count
   @Local idx
   @Local itemslot
   @Local stmt
@POPI listptr
@PUSHI listptr
@IF_NOTZERO
   @POPNULL
   @PUSHI listptr @ADD FC_LIST_COUNT @PUSHS @POPI count
   @MA2V 0 idx
   @PUSHI idx
   @WHILE_LT_V count
      @POPNULL
      @PUSHI idx @SHL @ADD FC_LIST_ITEMS @ADDI listptr @POPI itemslot
      @PUSHI itemslot @PUSHS @POPI stmt
      @Call(V) FCFreeStatementList stmt
      @INCI idx
      @PUSHI idx
   @ENDWHILE
   @POPNULL
   @Call(VV) HeapDeleteObject MainHeapID listptr @POPNULL
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCFindStatementSep
@PUSHRETURN
@Locals
   @Local ptr
   @Local ch
   @Local depth
   @Local instr
   @Local result
   @Local done
@POPI ptr
@MA2V 0 depth
@MA2V 0 instr
@MA2V 0 result
@MA2V 0 done
@PUSHI done
@WHILE_ZERO
   @POPNULL
   @PUSHII ptr @AND 0xff @POPI ch
   @PUSHI ch
   @IF_ZERO
      @POPNULL
      @MA2V 1 done
   @ELSE
      @POPNULL
      @PUSHI instr
      @IF_NOTZERO
         @POPNULL
         @PUSHI ch
         @IF_EQ_A "\"\0"
            @MA2V 0 instr
         @ENDIF
         @POPNULL
      @ELSE
         @POPNULL
         @PUSHI ch
         @IF_EQ_A "\"\0"
            @MA2V 1 instr
         @ENDIF
         @POPNULL
         @PUSHI ch
         @IF_EQ_A "(\0"
            @PUSHI depth @ADD 1 @POPI depth
         @ENDIF
         @POPNULL
         @PUSHI ch
         @IF_EQ_A ")\0"
            @PUSHI depth
            @IF_NOTZERO
               @POPNULL
               @PUSHI depth @SUB 1 @POPI depth
            @ELSE
               @POPNULL
            @ENDIF
         @ENDIF
         @POPNULL
         @PUSHI ch
         @IF_EQ_A ";\0"
            @PUSHI depth
            @IF_ZERO
               @POPNULL
               @MV2V ptr result
               @MA2V 1 done
            @ELSE
               @POPNULL
            @ENDIF
         @ENDIF
         @POPNULL
      @ENDIF
   @ENDIF
   @PUSHI done
   @IF_ZERO
      @POPNULL
      @INCI ptr
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI done
@ENDWHILE
@POPNULL
@PUSHI result
@EndLocals
@POPRETURN
@RET

# FCEvalExpr(exprptr) sets EvalType/EvalI32/EvalStr.
# Recursive descent entry point. Parse routines return the updated input pointer
# and leave the evaluated value in EvalType/EvalI32/EvalStr.
:FCEvalExpr
@PUSHRETURN
@Locals
   @Local expr
   @Local endptr
@POPI expr
@Call(V) FCParseExpr expr @POPI endptr
@EndLocals
@POPRETURN
@RET

:FCParseExpr
@PUSHRETURN
@Locals
   @Local inptr
   @Local ch
   @Local op
   @Local leftlow
   @Local lefthigh
   @Local done
@POPI inptr
@MA2V 0 done
@Call(V) FCParseTerm inptr @POPI inptr
@PUSHI done
@WHILE_ZERO
   @POPNULL
   @Call(V) FCSkipWhite inptr @POPI inptr
   @PUSHII inptr @AND 0xff @POPI ch
   @MA2V 0 op
   @PUSHI ch
   @IF_EQ_A "+\0"
      @MV2V ch op
   @ENDIF
   @POPNULL
   @PUSHI ch
   @IF_EQ_A "-\0"
      @MV2V ch op
   @ENDIF
   @POPNULL
   @PUSHI op
   @IF_ZERO
      @POPNULL
      @MA2V 1 done
   @ELSE
      @POPNULL
      @IF_NEQ_AV FC_TYPE_I32 EvalType
         @PRTLN "ERR expression expects numbers"
         @MA2V FC_TYPE_EMPTY EvalType
         @MA2V 1 done
      @ELSE
         @M32V2V EvalI32 leftlow
         @INCI inptr
         @Call(V) FCParseTerm inptr @POPI inptr
         @IF_NEQ_AV FC_TYPE_I32 EvalType
            @PRTLN "ERR expression expects numbers"
            @MA2V FC_TYPE_EMPTY EvalType
            @MA2V 1 done
         @ELSE
            @PUSHI op
            @IF_EQ_A "+\0"
               @POPNULL
               @Call32(VV) ADD32S leftlow EvalI32
               @POP32I(V) EvalI32
            @ELSE
               @POPNULL
               @Call32(VV) SUB32S leftlow EvalI32
               @POP32I(V) EvalI32
            @ENDIF
            @MA2V FC_TYPE_I32 EvalType
         @ENDIF
      @ENDIF
   @ENDIF
   @PUSHI done
@ENDWHILE
@POPNULL
@PUSHI inptr
@EndLocals
@POPRETURN
@RET

:FCParseTerm
@PUSHRETURN
@Locals
   @Local inptr
   @Local ch
   @Local op
   @Local leftlow
   @Local lefthigh
   @Local remlow
   @Local remhigh
   @Local done
@POPI inptr
@MA2V 0 done
@Call(V) FCParseUnary inptr @POPI inptr
@PUSHI done
@WHILE_ZERO
   @POPNULL
   @Call(V) FCSkipWhite inptr @POPI inptr
   @PUSHII inptr @AND 0xff @POPI ch
   @MA2V 0 op
   @PUSHI ch
   @IF_EQ_A "*\0"
      @MV2V ch op
   @ENDIF
   @POPNULL
   @PUSHI ch
   @IF_EQ_A "/\0"
      @MV2V ch op
   @ENDIF
   @POPNULL
   @PUSHI ch
   @IF_EQ_A "%\0"
      @MV2V ch op
   @ENDIF
   @POPNULL
   @PUSHI op
   @IF_ZERO
      @POPNULL
      @MA2V 1 done
   @ELSE
      @POPNULL
      @IF_NEQ_AV FC_TYPE_I32 EvalType
         @PRTLN "ERR term expects numbers"
         @MA2V FC_TYPE_EMPTY EvalType
         @MA2V 1 done
      @ELSE
         @M32V2V EvalI32 leftlow
         @INCI inptr
         @Call(V) FCParseUnary inptr @POPI inptr
         @IF_NEQ_AV FC_TYPE_I32 EvalType
            @PRTLN "ERR term expects numbers"
            @MA2V FC_TYPE_EMPTY EvalType
            @MA2V 1 done
         @ELSE
            @PUSHI op
            @IF_EQ_A "*\0"
               @POPNULL
               @Call32(VV) MUL32S leftlow EvalI32
               @POP32I(V) EvalI32
            @ELSE
               @POPNULL
               @PUSHI EvalI32 @ORI EvalI32+2
               @IF_ZERO
                  @POPNULL
                  @PRTLN "ERR divide by zero"
                  @MA2V FC_TYPE_EMPTY EvalType
                  @MA2V 1 done
               @ELSE
                  @POPNULL
                  @Call32(VV) DIV32S leftlow EvalI32
                  @POP32I(V) EvalI32
                  @POP32I(V) remlow
                  @PUSHI op
                  @IF_EQ_A "%\0"
                     @M32V2V remlow EvalI32
                  @ENDIF
                  @POPNULL
               @ENDIF
            @ENDIF
            @IF_EQ_AV 0 done
               @MA2V FC_TYPE_I32 EvalType
            @ENDIF
         @ENDIF
      @ENDIF
   @ENDIF
   @PUSHI done
@ENDWHILE
@POPNULL
@PUSHI inptr
@EndLocals
@POPRETURN
@RET

:FCParseUnary
@PUSHRETURN
@Locals
   @Local inptr
@POPI inptr
@Call(V) FCSkipWhite inptr @POPI inptr
@PUSHII inptr @AND 0xff
@IF_EQ_A "-\0"
   @POPNULL
   @INCI inptr
   @Call(V) FCParseUnary inptr @POPI inptr
   @IF_EQ_AV FC_TYPE_I32 EvalType
      @Call32(V) COMP232 EvalI32
      @POP32I(V) EvalI32
      @MA2V FC_TYPE_I32 EvalType
   @ELSE
      @PRTLN "ERR - expects number"
      @MA2V FC_TYPE_EMPTY EvalType
   @ENDIF
@ELSE
   @POPNULL
   @Call(V) FCParsePrimary inptr @POPI inptr
@ENDIF
@PUSHI inptr
@EndLocals
@POPRETURN
@RET

:FCParsePrimary
@PUSHRETURN
@Locals
   @Local inptr
   @Local endptr
   @Local savech
   @Local slot
   @Local namecopy
   @Local closeptr
   @Local result
@POPI inptr
@Call(V) FCSkipWhite inptr @POPI inptr
@PUSHII inptr @AND 0xff
@SWITCH
   @CASE "\"\0"
      @POPNULL
      @INCI inptr
      @Call(VA) strfndc inptr "\"\0" @POPI endptr
      @PUSHI endptr
      @IF_NOTZERO
         @POPNULL
         @PUSHII endptr @POPI savech
         @PUSH 0 @POPII endptr
         @Call(V) FCStringDup inptr @POPI EvalStr
         @PUSHI savech @POPII endptr
         @PUSHI endptr @ADD 1 @POPI inptr
      @ELSE
         @POPNULL
         @Call(V) FCStringDup inptr @POPI EvalStr
         @Call(V) strlen inptr @ADDI inptr @POPI inptr
      @ENDIF
      @MV2V EvalStr EvalStrObj
      @MA2V 1 EvalStrOwned
      @MA2V FC_TYPE_STR EvalType
      @CBREAK
   @CASE "(\0"
      @POPNULL
      @INCI inptr
      @Call(V) FCParseExpr inptr @POPI inptr
      @Call(V) FCSkipWhite inptr @POPI inptr
      @PUSHII inptr @AND 0xff
      @IF_EQ_A ")\0"
         @POPNULL
         @INCI inptr
      @ELSE
         @POPNULL
         @PRTLN "ERR expected )"
         @MA2V FC_TYPE_EMPTY EvalType
      @ENDIF
      @CBREAK
   @CASE_RANGE "0\0" "9\0"
      @POPNULL
      @Call(V) FCScanNumberEnd inptr @POPI endptr
      @PUSHII endptr @POPI savech
      @PUSH 0 @POPII endptr
      @Call(V) stoi32 inptr @POP32I(V) EvalI32
      @PUSHI savech @POPII endptr
      @MV2V endptr inptr
      @MA2V 0 EvalStr
      @MA2V 0 EvalStrObj
      @MA2V 0 EvalStrOwned
      @MA2V FC_TYPE_I32 EvalType
      @CBREAK
   @CDEFAULT
      @POPNULL
      @Call(V) FCScanNameEnd inptr @POPI endptr
      @PUSHI endptr
      @IF_EQ_V inptr
         @POPNULL
         @PRTLN "ERR unknown atom"
         @MA2V FC_TYPE_EMPTY EvalType
      @ELSE
         @POPNULL
         @PUSHII endptr @POPI savech
         @PUSH 0 @POPII endptr
         @PUSHI endptr @ADD 1 @POPI ValuePtr
         @PUSHI savech @AND 0xff
         @IF_EQ_A "(\0"
            @POPNULL
            @Call(V) FCStringDup inptr @POPI namecopy
            @Call(V) strUpCase namecopy
            @PUSHI savech @POPII endptr
            @Call(V) FCFindCloseParen endptr @POPI closeptr
            @PUSHI closeptr
            @IF_NOTZERO
               @POPNULL
               @Call(V) FCParseArgList ValuePtr
               @PUSHI namecopy @CALL FCDispatchFunctionParsed @POPI result
               @MV2V FCArgEndPtr inptr
            @ELSE
               @POPNULL
               @PRTLN "ERR expected )"
               @MA2V FC_TYPE_EMPTY EvalType
            @ENDIF
            @Call(V) FCFreeString namecopy
         @ELSE
            @POPNULL
            @Call(V) FCFindSlot inptr @POPI slot
            @PUSHI savech @POPII endptr
            @PUSHI slot
            @IF_ZERO
               @POPNULL
               @PRTLN "ERR unknown atom"
               @MA2V FC_TYPE_EMPTY EvalType
            @ELSE
               @POPNULL
               @PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @CALL FCLoadValue
               @MV2V endptr inptr
            @ENDIF
         @ENDIF
      @ENDIF
      @CBREAK
@ENDCASE
:FCParsePrimaryDone
@PUSHI inptr
@EndLocals
@POPRETURN
@RET

:FCScanNumberEnd
@PUSHRETURN
@Locals
   @Local ptr
   @Local ch
   @Local keepgoing
@POPI ptr
@MA2V 1 keepgoing
@PUSHI keepgoing
@WHILE_NOTZERO
   @POPNULL
   @PUSHII ptr @AND 0xff @POPI ch
   @MA2V 0 keepgoing
   @PUSHI ch
   @IF_UGE_A "0\0"
      @IF_ULE_A "9\0"
         @MA2V 1 keepgoing
      @ENDIF
   @ENDIF
   @POPNULL
   @PUSHI keepgoing
   @IF_NOTZERO
      @POPNULL
      @INCI ptr
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI keepgoing
@ENDWHILE
@POPNULL
@PUSHI ptr
@EndLocals
@POPRETURN
@RET

:FCScanNameEnd
@PUSHRETURN
@Locals
   @Local ptr
   @Local ch
   @Local keepgoing
@POPI ptr
@MA2V 1 keepgoing
@PUSHI keepgoing
@WHILE_NOTZERO
   @POPNULL
   @PUSHII ptr @AND 0xff @POPI ch
   @MA2V 0 keepgoing
   @PUSHI ch
   @IF_UGE_A "A\0"
      @IF_ULE_A "Z\0"
         @MA2V 1 keepgoing
      @ENDIF
   @ENDIF
   @POPNULL
   @PUSHI ch
   @IF_UGE_A "a\0"
      @IF_ULE_A "z\0"
         @MA2V 1 keepgoing
      @ENDIF
   @ENDIF
   @POPNULL
   @PUSHI ch
   @IF_UGE_A "0\0"
      @IF_ULE_A "9\0"
         @MA2V 1 keepgoing
      @ENDIF
   @ENDIF
   @POPNULL
   @PUSHI ch
   @IF_EQ_A "_\0"
      @MA2V 1 keepgoing
   @ENDIF
   @POPNULL
   @PUSHI ch
   @IF_EQ_A "$\0"
      @MA2V 1 keepgoing
   @ENDIF
   @POPNULL
   @PUSHI keepgoing
   @IF_NOTZERO
      @POPNULL
      @INCI ptr
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI keepgoing
@ENDWHILE
@POPNULL
@PUSHI ptr
@EndLocals
@POPRETURN
@RET

# Compatibility hook for older call sites. New parsing goes through FCParsePrimary.
:FCEvalAtom
@PUSHRETURN
@Locals
   @Local expr
   @Local endptr
@POPI expr
@Call(V) FCParsePrimary expr @POPI endptr
@EndLocals
@POPRETURN
@RET

# FCEvalFunctionCall(exprptr): if expr is NAME(args), set Eval* and return 1.
# Kept for compatibility; the recursive parser dispatches function calls directly.
:FCEvalFunctionCall
@PUSHRETURN
@Locals
   @Local expr
   @Local endptr
   @Local result
@POPI expr
@MA2V FC_TYPE_EMPTY EvalType
@Call(V) FCParsePrimary expr @POPI endptr
@PUSHI EvalType
@IF_EQ_A FC_TYPE_EMPTY
   @POPNULL
   @MA2V 0 result
@ELSE
   @POPNULL
   @MA2V 1 result
@ENDIF
@PUSHI result
@EndLocals
@POPRETURN
@RET

:FCFindCloseParen
@PUSHRETURN
@Locals
   @Local openptr
   @Local ptr
   @Local depth
   @Local nextopen
   @Local nextclose
   @Local result
@POPI openptr
@MA2V 0 result
@MA2V 0 depth
@PUSHI openptr @ADD 1 @POPI ptr
:FCCloseScanLoop
@Call(VA) strfndc ptr 0x28 @POPI nextopen
@Call(VA) strfndc ptr 0x29 @POPI nextclose
@PUSHI nextclose
@IF_ZERO
   @POPNULL
   @JMP FCCloseDone
@ENDIF
@POPNULL
@PUSHI nextopen
@IF_NOTZERO
   @POPNULL
   @PUSHI nextopen
   @IF_ULT_V nextclose
      @POPNULL
      @PUSHI depth @ADD 1 @POPI depth
      @PUSHI nextopen @ADD 1 @POPI ptr
      @JMP FCCloseScanLoop
   @ENDIF
   @POPNULL
@ELSE
   @POPNULL
@ENDIF
@PUSHI depth
@IF_ZERO
   @POPNULL
   @MV2V nextclose result
   @JMP FCCloseDone
@ENDIF
@POPNULL
@PUSHI depth @SUB 1 @POPI depth
@PUSHI nextclose @ADD 1 @POPI ptr
@JMP FCCloseScanLoop
:FCCloseDone
@PUSHI result
@EndLocals
@POPRETURN
@RET

:FCFindArgComma
@PUSHRETURN
@Locals
   @Local ptr
   @Local depth
   @Local ch
   @Local result
@POPI ptr
@MA2V 0 result
@MA2V 0 depth
@PUSHII ptr @AND 0xff
@WHILE_NOTZERO
   @POPI ch
   @PUSHI ch
   @IF_EQ_A "(\0"
      @POPNULL
      @PUSHI depth @ADD 1 @POPI depth
   @ELSE
      @POPNULL
      @PUSHI ch
      @IF_EQ_A ")\0"
         @POPNULL
         @PUSHI depth
         @IF_NOTZERO
            @POPNULL
            @PUSHI depth @SUB 1 @POPI depth
         @ELSE
            @POPNULL
         @ENDIF
      @ELSE
         @POPNULL
         @PUSHI ch
         @IF_EQ_A ",\0"
            @POPNULL
            @PUSHI depth
            @IF_ZERO
               @POPNULL
               @MV2V ptr result
               @PUSH 0
               @JMP FCFindArgCommaDone
            @ENDIF
            @POPNULL
         @ELSE
            @POPNULL
         @ENDIF
      @ENDIF
   @ENDIF
   @PUSHI ptr @ADD 1 @POPI ptr
   @PUSHII ptr @AND 0xff
@ENDWHILE
:FCFindArgCommaDone
@POPNULL
@PUSHI result
@EndLocals
@POPRETURN
@RET


:FCParseArgList
@PUSHRETURN
@Locals
   @Local inptr
   @Local count
   @Local ch
   @Local done
@POPI inptr
@MA2V 0 count
@MA2V 0 done
@Call(V) FCSkipWhite inptr @POPI inptr
@PUSHII inptr @AND 0xff
@IF_EQ_A ")\0"
   @POPNULL
   @PUSHI inptr @ADD 1 @POPI FCArgEndPtr
   @PUSHI count
   @JMP FCParseArgListDone
@ENDIF
@POPNULL
@PUSHI done
@WHILE_ZERO
   @POPNULL
   @Call(V) FCParseExpr inptr @POPI inptr
   @CALL FCPushEvalArg
   @INCI count
   @Call(V) FCSkipWhite inptr @POPI inptr
   @PUSHII inptr @AND 0xff @POPI ch
   @PUSHI ch
   @IF_EQ_A ",\0"
      @POPNULL
      @INCI inptr
   @ELSE
      @POPNULL
      @PUSHI ch
      @IF_EQ_A ")\0"
         @POPNULL
         @PUSHI inptr @ADD 1 @POPI FCArgEndPtr
         @MA2V 1 done
      @ELSE
         @POPNULL
         @PRTLN "ERR expected , or )"
         @MA2V 1 done
         @MV2V inptr FCArgEndPtr
      @ENDIF
   @ENDIF
   @PUSHI done
@ENDWHILE
@POPNULL
@PUSHI count
:FCParseArgListDone
@EndLocals
@POPRETURN
@RET

:FCPushEvalArg
@PUSHRETURN
@Locals
   @Local argstr
@IF_EQ_AV FC_TYPE_STR EvalType
   @PUSHI EvalStrOwned
   @IF_NOTZERO
      @POPNULL
      @MV2V EvalStrObj argstr
      @MA2V 0 EvalStrOwned
   @ELSE
      @POPNULL
      @Call(V) FCStringDup EvalStr @POPI argstr
   @ENDIF
   @PUSH FC_TYPE_STR
   @PUSHI argstr
   @PUSH 0
   @PUSH FC_ARG_HEAP
@ELSE
   @PUSH FC_TYPE_I32
   @PUSHI EvalI32
   @PUSHI EvalI32+2
   @PUSH FC_ARG_VAL
@ENDIF
@CALL FCReleaseEvalString
@EndLocals
@POPRETURN
@RET

:FCReleaseArg
@PUSHRETURN
@Locals
   @Local typev
   @Local low
   @Local high
   @Local flags
@POPI flags
@POPI high
@POPI low
@POPI typev
@PUSHI flags
@IF_EQ_A FC_ARG_HEAP
   @POPNULL
   @PUSHI low
   @IF_NOTZERO
      @POPNULL
      @Call(VV) HeapDeleteObject MainHeapID low @POPNULL
   @ELSE
      @POPNULL
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCDispatchFunctionParsed
@PUSHRETURN
@Locals
   @Local name
   @Local result
@POPI name
@MA2V 0 result
@Call(V) FCDispatchBuiltinParsed name @POPI result
@PUSHI result
@IF_ZERO
   @POPNULL
   @Call(V) FCDispatchUserFunctionParsed name @POPI result
@ELSE
   @POPNULL
@ENDIF
@PUSHI result
@EndLocals
@POPRETURN
@RET

:FCDispatchUserFunctionParsed
# Placeholder hook for the future DEFUN label table. ArgCount is already on stack.
@POPNULL
@PUSH 0
@RET

:FCDispatchBuiltinParsed
@PUSHRETURN
@Locals
   @Local name
   @Local result
@POPI name
@MA2V 0 result
@Call(VA) strcmp name KwAbs
@IF_ZERO
   @POPNULL
   @CALL FCBuiltinAbsParsed
   @MA2V 1 result
   @JMP FCDispatchBuiltinParsedDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwMin
@IF_ZERO
   @POPNULL
   @CALL FCBuiltinMinParsed
   @MA2V 1 result
   @JMP FCDispatchBuiltinParsedDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwLen
@IF_ZERO
   @POPNULL
   @CALL FCBuiltinLenParsed
   @MA2V 1 result
   @JMP FCDispatchBuiltinParsedDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwVal
@IF_ZERO
   @POPNULL
   @CALL FCBuiltinValParsed
   @MA2V 1 result
   @JMP FCDispatchBuiltinParsedDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwStr
@IF_ZERO
   @POPNULL
   @CALL FCBuiltinStrParsed
   @MA2V 1 result
   @JMP FCDispatchBuiltinParsedDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwSplit
@IF_ZERO
   @POPNULL
   @CALL FCBuiltinSplitParsed
   @MA2V 1 result
   @JMP FCDispatchBuiltinParsedDone
@ENDIF
@POPNULL
:FCDispatchBuiltinParsedDone
@PUSHI result
@EndLocals
@POPRETURN
@RET

:FCDispatchFunction
@PUSHRETURN
@Locals
   @Local name
   @Local argptr
   @Local result
@POPI argptr
@POPI name
@MA2V 0 result
@Call(VV) FCDispatchBuiltin name argptr @POPI result
@PUSHI result
@IF_ZERO
   @POPNULL
   @Call(VV) FCDispatchUserFunction name argptr @POPI result
@ELSE
   @POPNULL
@ENDIF
@PUSHI result
@EndLocals
@POPRETURN
@RET

:FCDispatchUserFunction
# Placeholder hook for the future DEFUN label table.
@POPNULL
@POPNULL
@PUSH 0
@RET

:FCDispatchBuiltin
@PUSHRETURN
@Locals
   @Local name
   @Local argptr
   @Local result
@POPI argptr
@POPI name
@MA2V 0 result
@Call(VA) strcmp name KwAbs
@IF_ZERO
   @POPNULL
   @Call(V) FCBuiltinAbs argptr
   @MA2V 1 result
   @JMP FCDispatchBuiltinDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwMin
@IF_ZERO
   @POPNULL
   @Call(V) FCBuiltinMin argptr
   @MA2V 1 result
   @JMP FCDispatchBuiltinDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwLen
@IF_ZERO
   @POPNULL
   @Call(V) FCBuiltinLen argptr
   @MA2V 1 result
   @JMP FCDispatchBuiltinDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwVal
@IF_ZERO
   @POPNULL
   @Call(V) FCBuiltinVal argptr
   @MA2V 1 result
   @JMP FCDispatchBuiltinDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwStr
@IF_ZERO
   @POPNULL
   @Call(V) FCBuiltinStr argptr
   @MA2V 1 result
   @JMP FCDispatchBuiltinDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwSplit
@IF_ZERO
   @POPNULL
   @Call(V) FCBuiltinSplit argptr
   @MA2V 1 result
   @JMP FCDispatchBuiltinDone
@ENDIF
@POPNULL
:FCDispatchBuiltinDone
@PUSHI result
@EndLocals
@POPRETURN
@RET


:FCDiscardArgs
@PUSHRETURN
@Locals
   @Local count
   @Local idx
@POPI count
@MA2V 0 idx
@PUSHI idx
@WHILE_LT_V count
   @POPNULL
   @CALL FCReleaseArg
   @INCI idx
   @PUSHI idx
@ENDWHILE
@POPNULL
@EndLocals
@POPRETURN
@RET

:FCBuiltinAbsParsed
@PUSHRETURN
@Locals
   @Local count
   @Local typev
   @Local low
   @Local high
   @Local flags
@POPI count
@PUSHI count
@IF_NEQ_A 1
   @POPNULL
   @PRTLN "ERR ABS expects one arg"
   @Call(V) FCDiscardArgs count
   @MA2V FC_TYPE_EMPTY EvalType
   @JMP FCBuiltinAbsParsedDone
@ENDIF
@POPNULL
@POPI4 flags high low typev
@PUSHI typev
@IF_EQ_A FC_TYPE_I32
   @POPNULL
   @MV2V low EvalI32
   @MV2V high EvalI32+2
   @PUSHI EvalI32+2 @AND 0x8000
   @IF_NOTZERO
      @POPNULL
      @Call32(V) COMP232 EvalI32
      @POP32I(V) EvalI32
   @ELSE
      @POPNULL
   @ENDIF
   @MA2V FC_TYPE_I32 EvalType
@ELSE
   @POPNULL
   @PRTLN "ERR ABS expects number"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
@PUSHI typev @PUSHI low @PUSHI high @PUSHI flags @CALL FCReleaseArg
:FCBuiltinAbsParsedDone
@EndLocals
@POPRETURN
@RET

:FCBuiltinMinParsed
@PUSHRETURN
@Locals
   @Local count
   @Local idx
   @Local typev
   @Local low
   @Local high
   @Local flags
   @Local bestlow
   @Local besthigh
   @Local valid
@POPI count
@MA2V 1 valid
@PUSHI count
@IF_ZERO
   @POPNULL
   @PRTLN "ERR MIN expects args"
   @MA2V FC_TYPE_EMPTY EvalType
   @JMP FCBuiltinMinParsedDone
@ENDIF
@POPNULL
@MA2V 0 idx
@PUSHI idx
@WHILE_LT_V count
   @POPNULL
   @POPI4 flags high low typev
   @PUSHI typev
   @IF_EQ_A FC_TYPE_I32
      @POPNULL
      @PUSHI idx
      @IF_ZERO
         @POPNULL
         @MV2V low bestlow
         @MV2V high besthigh
      @ELSE
         @POPNULL
         @Call32(VV) CMP32S low bestlow
         @IF32_LT
            @MV2V low bestlow
            @MV2V high besthigh
         @ENDIF
      @ENDIF
   @ELSE
      @POPNULL
      @PRTLN "ERR MIN expects numbers"
      @MA2V 0 valid
   @ENDIF
   @PUSHI typev @PUSHI low @PUSHI high @PUSHI flags @CALL FCReleaseArg
   @INCI idx
   @PUSHI idx
@ENDWHILE
@POPNULL
@PUSHI valid
@IF_NOTZERO
   @POPNULL
   @MV2V bestlow EvalI32
   @MV2V besthigh EvalI32+2
   @MA2V FC_TYPE_I32 EvalType
@ELSE
   @POPNULL
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
:FCBuiltinMinParsedDone
@EndLocals
@POPRETURN
@RET

:FCBuiltinLenParsed
@PUSHRETURN
@Locals
   @Local count
   @Local typev
   @Local low
   @Local high
   @Local flags
@POPI count
@PUSHI count
@IF_NEQ_A 1
   @POPNULL
   @PRTLN "ERR LEN expects one arg"
   @Call(V) FCDiscardArgs count
   @MA2V FC_TYPE_EMPTY EvalType
   @JMP FCBuiltinLenParsedDone
@ENDIF
@POPNULL
@POPI4 flags high low typev
@PUSHI typev
@IF_EQ_A FC_TYPE_STR
   @POPNULL
   @Call(V) strlen low @POPI EvalI32
   @MA2V 0 EvalI32+2
   @MA2V FC_TYPE_I32 EvalType
@ELSE
   @POPNULL
   @PRTLN "ERR LEN expects string"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
@PUSHI typev @PUSHI low @PUSHI high @PUSHI flags @CALL FCReleaseArg
:FCBuiltinLenParsedDone
@EndLocals
@POPRETURN
@RET

:FCBuiltinValParsed
@PUSHRETURN
@Locals
   @Local count
   @Local typev
   @Local low
   @Local high
   @Local flags
@POPI count
@PUSHI count
@IF_NEQ_A 1
   @POPNULL
   @PRTLN "ERR VAL expects one arg"
   @Call(V) FCDiscardArgs count
   @MA2V FC_TYPE_EMPTY EvalType
   @JMP FCBuiltinValParsedDone
@ENDIF
@POPNULL
@POPI4 flags high low typev
@PUSHI typev
@IF_EQ_A FC_TYPE_STR
   @POPNULL
   @Call(V) stoi32 low @POP32I(V) EvalI32
   @MA2V FC_TYPE_I32 EvalType
@ELSE
   @POPNULL
   @PRTLN "ERR VAL expects string"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
@PUSHI typev @PUSHI low @PUSHI high @PUSHI flags @CALL FCReleaseArg
:FCBuiltinValParsedDone
@EndLocals
@POPRETURN
@RET

:FCBuiltinStrParsed
@PUSHRETURN
@Locals
   @Local count
   @Local typev
   @Local low
   @Local high
   @Local flags
@POPI count
@PUSHI count
@IF_NEQ_A 1
   @POPNULL
   @PRTLN "ERR STR$ expects one arg"
   @Call(V) FCDiscardArgs count
   @MA2V FC_TYPE_EMPTY EvalType
   @JMP FCBuiltinStrParsedDone
@ENDIF
@POPNULL
@POPI4 flags high low typev
@PUSHI typev
@IF_EQ_A FC_TYPE_I32
   @POPNULL
   @MV2V low EvalI32
   @MV2V high EvalI32+2
   @Call(AVVA) i32tos PrintBuff EvalI32 EvalI32+2 10
   @Call(A) FCStringDup PrintBuff @POPI EvalStr
   @MV2V EvalStr EvalStrObj
   @MA2V 1 EvalStrOwned
   @MA2V FC_TYPE_STR EvalType
@ELSE
   @POPNULL
   @PRTLN "ERR STR$ expects number"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
@PUSHI typev @PUSHI low @PUSHI high @PUSHI flags @CALL FCReleaseArg
:FCBuiltinStrParsedDone
@EndLocals
@POPRETURN
@RET

:FCBuiltinSplitParsed
@PUSHRETURN
@Locals
   @Local count
   @Local type3
   @Local low3
   @Local high3
   @Local flags3
   @Local type2
   @Local low2
   @Local high2
   @Local flags2
   @Local type1
   @Local low1
   @Local high1
   @Local flags1
   @Local slen
   @Local start
   @Local stop
   @Local outlen
@POPI count
@PUSHI count
@IF_NEQ_A 3
   @POPNULL
   @PRTLN "ERR SPLIT expects three args"
   @Call(V) FCDiscardArgs count
   @MA2V FC_TYPE_EMPTY EvalType
   @JMP FCBuiltinSplitParsedDone
@ENDIF
@POPNULL
@POPI4 flags3 high3 low3 type3
@POPI4 flags2 high2 low2 type2
@POPI4 flags1 high1 low1 type1
@PUSHI type1
@IF_EQ_A FC_TYPE_STR
   @POPNULL
   @PUSHI type2
   @IF_EQ_A FC_TYPE_I32
      @POPNULL
      @PUSHI type3
      @IF_EQ_A FC_TYPE_I32
         @POPNULL
         @MV2V low2 start
         @MV2V low3 stop
         @Call(V) strlen low1 @POPI slen
         @PUSHI start
         @IF_LT_A 1
            @POPNULL
            @Call(VA) FCSubStringDup low1 0 @POPI EvalStr
            @MV2V EvalStr EvalStrObj
            @JMP FCSplitParsedMade
         @ENDIF
         @POPNULL
         @PUSHI stop
         @IF_LT_V start
            @POPNULL
            @Call(VA) FCSubStringDup low1 0 @POPI EvalStr
            @MV2V EvalStr EvalStrObj
            @JMP FCSplitParsedMade
         @ENDIF
         @POPNULL
         @PUSHI start
         @IF_GT_V slen
            @POPNULL
            @Call(VA) FCSubStringDup low1 0 @POPI EvalStr
            @MV2V EvalStr EvalStrObj
            @JMP FCSplitParsedMade
         @ENDIF
         @POPNULL
         @PUSHI stop
         @IF_GT_V slen
            @POPNULL
            @MV2V slen stop
         @ELSE
            @POPNULL
         @ENDIF
         @PUSHI stop @SUBI start @ADD 1 @POPI outlen
         @PUSHI low1 @ADDI start @SUB 1 @PUSHI outlen @CALL FCSubStringDup @POPI EvalStr
         @MV2V EvalStr EvalStrObj
         :FCSplitParsedMade
         @MA2V 1 EvalStrOwned
         @MA2V FC_TYPE_STR EvalType
      @ELSE
         @POPNULL
         @PRTLN "ERR SPLIT indexes must be numbers"
         @MA2V FC_TYPE_EMPTY EvalType
      @ENDIF
   @ELSE
      @POPNULL
      @PRTLN "ERR SPLIT indexes must be numbers"
      @MA2V FC_TYPE_EMPTY EvalType
   @ENDIF
@ELSE
   @POPNULL
   @PRTLN "ERR SPLIT expects string"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
@PUSHI type3 @PUSHI low3 @PUSHI high3 @PUSHI flags3 @CALL FCReleaseArg
@PUSHI type2 @PUSHI low2 @PUSHI high2 @PUSHI flags2 @CALL FCReleaseArg
@PUSHI type1 @PUSHI low1 @PUSHI high1 @PUSHI flags1 @CALL FCReleaseArg
:FCBuiltinSplitParsedDone
@EndLocals
@POPRETURN
@RET

:FCBuiltinAbs
@PUSHRETURN
@Locals
   @Local argptr
@POPI argptr
@Call(V) FCEvalExpr argptr
@IF_EQ_AV FC_TYPE_I32 EvalType
   @PUSHI EvalI32+2 @AND 0x8000
   @IF_NOTZERO
      @POPNULL
      @Call32(V) COMP232 EvalI32
      @POP32I(V) EvalI32
   @ELSE
      @POPNULL
   @ENDIF
   @MA2V FC_TYPE_I32 EvalType
@ELSE
   @PRTLN "ERR ABS expects number"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCBuiltinMin
@PUSHRETURN
@Locals
   @Local argptr
   @Local comma
@POPI argptr
@Call(V) FCFindArgComma argptr @POPI comma
@PUSHI comma
@IF_ZERO
   @POPNULL
   @PRTLN "ERR MIN expects two args"
   @MA2V FC_TYPE_EMPTY EvalType
   @JMP FCBuiltinMinDone
@ENDIF
@POPNULL
@PUSHII comma @AND 0xff00 @PUSHI comma @POPS
@Call(V) FCEvalExpr argptr
@IF_EQ_AV FC_TYPE_I32 EvalType
   @M32V2V EvalI32 LeftI32
   @PUSHI comma @ADD 1 @CALL FCEvalExpr
   @IF_EQ_AV FC_TYPE_I32 EvalType
      @Call32(VV) CMP32S LeftI32 EvalI32
      @IF32_LT
         @M32V2V LeftI32 EvalI32
      @ENDIF
      @MA2V FC_TYPE_I32 EvalType
   @ELSE
      @PRTLN "ERR MIN expects numbers"
      @MA2V FC_TYPE_EMPTY EvalType
   @ENDIF
@ELSE
   @PRTLN "ERR MIN expects numbers"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
:FCBuiltinMinDone
@EndLocals
@POPRETURN
@RET

:FCBuiltinLen
@PUSHRETURN
@Locals
   @Local argptr
   @Local src
@POPI argptr
@Call(V) FCEvalExpr argptr
@IF_EQ_AV FC_TYPE_STR EvalType
   @PUSHI EvalStr @POPI src
   @Call(V) strlen src @POPI EvalI32
   @MA2V 0 EvalI32+2
   @CALL FCReleaseEvalString
   @MA2V FC_TYPE_I32 EvalType
@ELSE
   @PRTLN "ERR LEN expects string"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCBuiltinVal
@PUSHRETURN
@Locals
   @Local argptr
   @Local src
@POPI argptr
@Call(V) FCEvalExpr argptr
@IF_EQ_AV FC_TYPE_STR EvalType
   @PUSHI EvalStr @POPI src
   @Call(V) stoi32 src @POP32I(V) EvalI32
   @CALL FCReleaseEvalString
   @MA2V FC_TYPE_I32 EvalType
@ELSE
   @PRTLN "ERR VAL expects string"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCBuiltinStr
@PUSHRETURN
@Locals
   @Local argptr
@POPI argptr
@Call(V) FCEvalExpr argptr
@IF_EQ_AV FC_TYPE_I32 EvalType
   @Call(AVVA) i32tos PrintBuff EvalI32 EvalI32+2 10
   @Call(A) FCStringDup PrintBuff @POPI EvalStr
   @MV2V EvalStr EvalStrObj
   @MA2V 1 EvalStrOwned
   @MA2V FC_TYPE_STR EvalType
@ELSE
   @PRTLN "ERR STR$ expects number"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCBuiltinSplit
@PUSHRETURN
@Locals
   @Local argptr
   @Local comma1
   @Local comma2
   @Local src
   @Local srcowned
   @Local slen
   @Local start
   @Local stop
   @Local outlen
@POPI argptr
@Call(V) FCFindArgComma argptr @POPI comma1
@PUSHI comma1
@IF_ZERO
   @POPNULL
   @PRTLN "ERR SPLIT expects three args"
   @MA2V FC_TYPE_EMPTY EvalType
   @JMP FCBuiltinSplitDone
@ENDIF
@POPNULL
@PUSHII comma1 @AND 0xff00 @PUSHI comma1 @POPS
@PUSHI comma1 @ADD 1 @CALL FCFindArgComma @POPI comma2
@PUSHI comma2
@IF_ZERO
   @POPNULL
   @PRTLN "ERR SPLIT expects three args"
   @MA2V FC_TYPE_EMPTY EvalType
   @JMP FCBuiltinSplitDone
@ENDIF
@POPNULL
@PUSHII comma2 @AND 0xff00 @PUSHI comma2 @POPS
@Call(V) FCEvalExpr argptr
@IF_EQ_AV FC_TYPE_STR EvalType
   @PUSHI EvalStr @POPI src
   @PUSHI EvalStrOwned @POPI srcowned
   @Call(V) strlen src @POPI slen
   @MA2V 0 EvalStrOwned
   @PUSHI comma1 @ADD 1 @CALL FCEvalExpr
   @IF_EQ_AV FC_TYPE_I32 EvalType
      @PUSHI EvalI32 @POPI start
      @PUSHI comma2 @ADD 1 @CALL FCEvalExpr
      @IF_EQ_AV FC_TYPE_I32 EvalType
         @PUSHI EvalI32 @POPI stop
         @PUSHI start
         @IF_LT_A 1
            @POPNULL
            @Call(VA) FCSubStringDup src 0 @POPI EvalStr
            @MV2V EvalStr EvalStrObj
            @JMP FCSplitMade
         @ENDIF
         @POPNULL
         @PUSHI stop
         @IF_LT_V start
            @POPNULL
            @Call(VA) FCSubStringDup src 0 @POPI EvalStr
            @MV2V EvalStr EvalStrObj
            @JMP FCSplitMade
         @ENDIF
         @POPNULL
         @PUSHI start
         @IF_GT_V slen
            @POPNULL
            @Call(VA) FCSubStringDup src 0 @POPI EvalStr
            @MV2V EvalStr EvalStrObj
            @JMP FCSplitMade
         @ENDIF
         @POPNULL
         @PUSHI stop
         @IF_GT_V slen
            @POPNULL
            @MV2V slen stop
         @ELSE
            @POPNULL
         @ENDIF
         @PUSHI stop @SUBI start @ADD 1 @POPI outlen
         @PUSHI src @ADDI start @SUB 1 @PUSHI outlen @CALL FCSubStringDup @POPI EvalStr
         @MV2V EvalStr EvalStrObj
         :FCSplitMade
         @MA2V 1 EvalStrOwned
         @MA2V FC_TYPE_STR EvalType
      @ELSE
         @PRTLN "ERR SPLIT indexes must be numbers"
         @MA2V FC_TYPE_EMPTY EvalType
      @ENDIF
   @ELSE
      @PRTLN "ERR SPLIT indexes must be numbers"
      @MA2V FC_TYPE_EMPTY EvalType
   @ENDIF
   @PUSHI srcowned
   @IF_NOTZERO
      @POPNULL @Call(VV) HeapDeleteObject MainHeapID src @POPNULL
   @ELSE
      @POPNULL
   @ENDIF
@ELSE
   @PRTLN "ERR SPLIT expects string"
   @MA2V FC_TYPE_EMPTY EvalType
@ENDIF
:FCBuiltinSplitDone
@EndLocals
@POPRETURN
@RET

:FCStoreEval
@PUSHRETURN
@Locals
   @Local slot
   @Local oldval
   @Local newval
@POPI slot
@PUSHI slot @ADD FC_SLOT_FLAGS @PUSHS
@IF_EQ_A FC_SLOT_ACTIVE
   @POPNULL
@ELSE
   @POPNULL
   @Call(V) FCStringDup NamePtr
   @PUSHI slot @ADD FC_SLOT_NAMEPTR @POPS
   @PUSH FC_SLOT_ACTIVE @PUSHI slot @ADD FC_SLOT_FLAGS @POPS
@ENDIF
@PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @POPI oldval
@PUSHI oldval
@IF_NOTZERO
   @POPNULL
   @Call(V) FCDeleteValue oldval
@ELSE
   @POPNULL
@ENDIF
@CALL FCValueFromEval @POPI newval
@PUSHI newval @PUSHI slot @ADD FC_SLOT_VALUEPTR @POPS
@PUSHI EvalType @PUSHI slot @ADD FC_SLOT_TYPE @POPS
@CALL FCReleaseEvalString
@EndLocals
@POPRETURN
@RET

:FCStorePointerValue
@PUSHRETURN
@Locals
   @Local slot
   @Local typev
   @Local payload
   @Local oldval
   @Local newval
@POPI payload
@POPI typev
@POPI slot
@PUSHI slot @ADD FC_SLOT_FLAGS @PUSHS
@IF_EQ_A FC_SLOT_ACTIVE
   @POPNULL
@ELSE
   @POPNULL
   @Call(V) FCStringDup NamePtr
   @PUSHI slot @ADD FC_SLOT_NAMEPTR @POPS
   @PUSH FC_SLOT_ACTIVE @PUSHI slot @ADD FC_SLOT_FLAGS @POPS
@ENDIF
@PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @POPI oldval
@PUSHI oldval
@IF_NOTZERO
   @POPNULL
   @Call(V) FCDeleteValue oldval
@ELSE
   @POPNULL
@ENDIF
@Call(VA) HeapNewObject MainHeapID FC_VAL_SIZE @POPI newval
@PUSHI typev @POPII newval
@PUSHI payload @PUSHI newval @ADD FC_VAL_LOW @POPS
@PUSH 0 @PUSHI newval @ADD FC_VAL_HIGH @POPS
@PUSHI newval @PUSHI slot @ADD FC_SLOT_VALUEPTR @POPS
@PUSHI typev @PUSHI slot @ADD FC_SLOT_TYPE @POPS
@EndLocals
@POPRETURN
@RET

:FCFindOrAllocSlot
@PUSHRETURN
@Locals
   @Local name
@POPI name
@Call(V) FCFindSlot name @POPI FoundSlot
@PUSHI FoundSlot
@IF_ZERO
   @POPNULL @CALL FCAllocSlot @POPI FoundSlot
@ELSE
   @POPNULL
@ENDIF
@PUSHI FoundSlot
@EndLocals
@POPRETURN
@RET

:FCFindSlot
@PUSHRETURN
@Locals
   @Local name
   @Local idx
   @Local slot
   @Local active
@POPI name
@MA2V 0 FoundSlot
@PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@PUSHI VarTablePtr @ADD FC_TABLE_HEADER @POPI slot
@MA2V 0 idx
@PUSHI idx
@WHILE_LT_V active
   @POPNULL
   @PUSHI slot @ADD FC_SLOT_NAMEPTR @PUSHS @PUSHI name @CALL FCStrEq
   @IF_NOTZERO
      @POPNULL
      @MV2V slot FoundSlot
      @PUSH 0
      @JMP FCFindDoneLoop
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI slot @ADD FC_SLOT_SIZE @POPI slot
   @INCI idx
   @PUSHI idx
@ENDWHILE
:FCFindDoneLoop
@POPNULL
@PUSHI FoundSlot
@EndLocals
@POPRETURN
@RET

:FCAllocSlot
@PUSHRETURN
@Locals
   @Local total
   @Local active
   @Local slot
   @Local offset
@PUSHI VarTablePtr @ADD FC_TABLE_TOTAL @PUSHS @POPI total
@PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@PUSHI active
@IF_UGE_V total
   @POPNULL
   @CALL FCSymTableGrow
   @IF_ZERO
      @POPNULL
      @PUSH 0
      @JMP FCAllocDone
   @ENDIF
   @POPNULL
   @PUSHI VarTablePtr @ADD FC_TABLE_TOTAL @PUSHS @POPI total
   @PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@ELSE
   @POPNULL
@ENDIF
@PUSHI active @SHL @SHL @POPI offset
@PUSHI active @SHL @SHL @SHL @ADDI offset @POPI offset
@PUSHI VarTablePtr @ADD FC_TABLE_HEADER @ADDI offset @POPI slot
@PUSHI active @ADD 1 @PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @POPS
@PUSH 0 @PUSHI slot @ADD FC_SLOT_HASH1 @POPS
@PUSH 0 @PUSHI slot @ADD FC_SLOT_HASH2 @POPS
@PUSH FC_SLOT_EMPTY @PUSHI slot @ADD FC_SLOT_FLAGS @POPS
@PUSH FC_TYPE_EMPTY @PUSHI slot @ADD FC_SLOT_TYPE @POPS
@PUSH 0 @PUSHI slot @ADD FC_SLOT_NAMEPTR @POPS
@PUSH 0 @PUSHI slot @ADD FC_SLOT_VALUEPTR @POPS
@PUSHI slot
:FCAllocDone
@EndLocals
@POPRETURN
@RET


:FCSymTableGrow
@PUSHRETURN
@Locals
   @Local oldtotal
   @Local newtotal
   @Local bytes
   @Local newtable
@PUSHI VarTablePtr @ADD FC_TABLE_TOTAL @PUSHS @POPI oldtotal
@PUSHI oldtotal @SHL @POPI newtotal
@PUSHI newtotal @SHL @SHL @POPI bytes
@PUSHI newtotal @SHL @SHL @SHL @ADDI bytes @POPI bytes
@PUSHI bytes @ADD FC_TABLE_HEADER @POPI bytes
@Call(VVV) HeapResizeObject MainHeapID VarTablePtr bytes
@POPI newtable
@PUSHI newtable
@IF_ULT_A 100
   @POPNULL
   @PUSH 0
   @JMP FCSymTableGrowDone
@ENDIF
@POPNULL
@MV2V newtable VarTablePtr
@PUSHI newtotal @PUSHI VarTablePtr @ADD FC_TABLE_TOTAL @POPS
@PUSHI VarTablePtr
:FCSymTableGrowDone
@EndLocals
@POPRETURN
@RET

:FCValueFromEval
@PUSHRETURN
@Locals
   @Local valptr
   @Local strlenv
   @Local payload
@IF_EQ_AV FC_TYPE_STR EvalType
   @Call(V) strlen EvalStr @ADD 1 @POPI strlenv
   @PUSHI MainHeapID @PUSHI strlenv @ADD 2 @CALL HeapNewObject
   @POPI valptr
   @PUSH FC_TYPE_STR @POPII valptr
   @PUSHI valptr @ADD 2 @POPI payload
   @Call(VVV) memcpy payload EvalStr strlenv
@ELSE
   @Call(VA) HeapNewObject MainHeapID FC_VAL_SIZE
   @POPI valptr
   @PUSH FC_TYPE_I32 @POPII valptr
   @PUSHI EvalI32 @PUSHI valptr @ADD FC_VAL_LOW @POPS
   @PUSHI EvalI32+2 @PUSHI valptr @ADD FC_VAL_HIGH @POPS
@ENDIF
@PUSHI valptr
@EndLocals
@POPRETURN
@RET

:FCLoadValue
@PUSHRETURN
@Locals
   @Local valptr
@POPI valptr
@PUSHII valptr @AND 0xff @POPI EvalType
@IF_EQ_AV FC_TYPE_STR EvalType
   @PUSHI valptr @ADD 2 @POPI EvalStr
   @MA2V 0 EvalStrObj
   @MA2V 0 EvalStrOwned
   @MA2V 0 EvalI32
   @MA2V 0 EvalI32+2
@ELSE
   @PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI EvalI32
   @PUSHI valptr @ADD FC_VAL_HIGH @PUSHS @POPI EvalI32+2
   @MA2V 0 EvalStr
   @MA2V 0 EvalStrObj
   @MA2V 0 EvalStrOwned
@ENDIF
@EndLocals
@POPRETURN
@RET


:FCDeleteValue
@PUSHRETURN
@Locals
   @Local valptr
   @Local typev
   @Local payload
@POPI valptr
@PUSHI valptr
@IF_NOTZERO
   @POPNULL
   @PUSHII valptr @AND 0xff @POPI typev
   @PUSHI typev
   @IF_EQ_A FC_TYPE_LIST
      @POPNULL
      @PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI payload
      @Call(V) FCFreeCodeList payload
   @ELSE
      @POPNULL
      @PUSHI typev
      @IF_EQ_A FC_TYPE_FUNC
         @POPNULL
         @PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI payload
         @Call(V) FCFreeCodeList payload
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
   @Call(VV) HeapDeleteObject MainHeapID valptr @POPNULL
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCReleaseEvalString
@PUSHI EvalStrOwned
@IF_NOTZERO
   @POPNULL
   @PUSHI EvalStrObj
   @IF_NOTZERO
      @POPNULL
      @Call(VV) HeapDeleteObject MainHeapID EvalStrObj @POPNULL
   @ELSE
      @POPNULL
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
@MA2V 0 EvalStr
@MA2V 0 EvalStrObj
@MA2V 0 EvalStrOwned
@RET

:FCSubStringDup
@PUSHRETURN
@Locals
   @Local src
   @Local len
   @Local dst
   @Local endptr
@POPI len
@POPI src
@PUSHI MainHeapID @PUSHI len @ADD 1 @CALL HeapNewObject
@POPI dst
@Call(VVV) strncpy dst src len
@PUSHI dst @ADDI len @POPI endptr
@PUSHII endptr @AND 0xff00 @PUSHI endptr @POPS
@PUSHI dst
@EndLocals
@POPRETURN
@RET

:FCStringDup
@PUSHRETURN
@Locals
   @Local src
   @Local dst
   @Local len
@POPI src
@Call(V) strlen src @ADD 1 @POPI len
@Call(VV) HeapNewObject MainHeapID len
@POPI dst
@Call(VVV) memcpy dst src len
@PUSHI dst
@EndLocals
@POPRETURN
@RET


:FCDeleteAllSlots
@PUSHRETURN
@Locals
   @Local active
   @Local idx
   @Local slot
   @Local objptr
@PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@PUSHI VarTablePtr @ADD FC_TABLE_HEADER @POPI slot
@MA2V 0 idx
@PUSHI idx
@WHILE_LT_V active
   @POPNULL
   @PUSHI slot @ADD FC_SLOT_NAMEPTR @PUSHS @POPI objptr
   @PUSHI objptr
   @IF_NOTZERO
      @POPNULL @Call(VV) HeapDeleteObject MainHeapID objptr @POPNULL
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @POPI objptr
   @PUSHI objptr
   @IF_NOTZERO
      @POPNULL @Call(V) FCDeleteValue objptr
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI slot @ADD FC_SLOT_SIZE @POPI slot
   @INCI idx
   @PUSHI idx
@ENDWHILE
@POPNULL
@PUSH 0 @PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @POPS
@EndLocals
@POPRETURN
@RET

:FCDeleteSlot
@PUSHRETURN
@Locals
   @Local slot
   @Local objptr
   @Local active
   @Local lastslot
   @Local offset
@POPI slot
@PUSHI slot @ADD FC_SLOT_NAMEPTR @PUSHS @POPI objptr
@PUSHI objptr
@IF_NOTZERO
   @POPNULL @Call(VV) HeapDeleteObject MainHeapID objptr @POPNULL
@ELSE
   @POPNULL
@ENDIF
@PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @POPI objptr
@PUSHI objptr
@IF_NOTZERO
   @POPNULL @Call(V) FCDeleteValue objptr
@ELSE
   @POPNULL
@ENDIF
@PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@PUSHI active @SUB 1 @POPI active
@PUSHI active @SHL @SHL @POPI offset
@PUSHI active @SHL @SHL @SHL @ADDI offset @POPI offset
@PUSHI VarTablePtr @ADD FC_TABLE_HEADER @ADDI offset @POPI lastslot
@PUSHI slot
@IF_NEQ_V lastslot
   @POPNULL
   @Call(VVA) memcpy slot lastslot FC_SLOT_SIZE
@ELSE
   @POPNULL
@ENDIF
@PUSH 0 @PUSHI lastslot @ADD FC_SLOT_HASH1 @POPS
@PUSH 0 @PUSHI lastslot @ADD FC_SLOT_HASH2 @POPS
@PUSH FC_SLOT_EMPTY @PUSHI lastslot @ADD FC_SLOT_FLAGS @POPS
@PUSH FC_TYPE_EMPTY @PUSHI lastslot @ADD FC_SLOT_TYPE @POPS
@PUSH 0 @PUSHI lastslot @ADD FC_SLOT_NAMEPTR @POPS
@PUSH 0 @PUSHI lastslot @ADD FC_SLOT_VALUEPTR @POPS
@PUSHI active @PUSHI VarTablePtr @ADD FC_TABLE_ACTIVE @POPS
@EndLocals
@POPRETURN
@RET



:FCListNew
@PUSHRETURN
@Locals
   @Local capacity
   @Local bytes
   @Local listptr
@POPI capacity
@PUSHI capacity
@IF_LT_A FC_LIST_MINCAP
   @POPNULL
   @MA2V FC_LIST_MINCAP capacity
@ELSE
   @POPNULL
@ENDIF
@PUSHI capacity @ADD 1 @SHL @ADD FC_LIST_ITEMS @POPI bytes
@Call(VV) HeapNewObject MainHeapID bytes @POPI listptr
@PUSH 0 @PUSHI listptr @ADD FC_LIST_COUNT @POPS
@PUSHI capacity @PUSHI listptr @ADD FC_LIST_CAPACITY @POPS
@PUSH 0 @PUSHI listptr @ADD FC_LIST_ITEMS @POPS
@PUSHI listptr
@EndLocals
@POPRETURN
@RET

:FCListAppend
@PUSHRETURN
@Locals
   @Local listptr
   @Local itemptr
   @Local count
   @Local capacity
   @Local newcap
   @Local bytes
   @Local itemslot
   @Local newlist
@POPI itemptr
@POPI listptr
@PUSHI listptr @ADD FC_LIST_COUNT @PUSHS @POPI count
@PUSHI listptr @ADD FC_LIST_CAPACITY @PUSHS @POPI capacity
@PUSHI count
@IF_UGE_V capacity
   @POPNULL
   @PUSHI capacity @SHL @POPI newcap
   @PUSHI newcap @ADD 1 @SHL @ADD FC_LIST_ITEMS @POPI bytes
   @Call(VVV) HeapResizeObject MainHeapID listptr bytes @POPI newlist
   @PUSHI newlist
   @IF_ULT_A 100
      @POPNULL
      @PUSH 0
      @JMP FCListAppendDone
   @ENDIF
   @POPNULL
   @MV2V newlist listptr
   @MV2V newcap capacity
   @PUSHI capacity @PUSHI listptr @ADD FC_LIST_CAPACITY @POPS
@ELSE
   @POPNULL
@ENDIF
@PUSHI count @SHL @ADD FC_LIST_ITEMS @ADDI listptr @POPI itemslot
@PUSHI itemptr @PUSHI itemslot @POPS
@INCI count
@PUSHI count @PUSHI listptr @ADD FC_LIST_COUNT @POPS
@PUSHI count @SHL @ADD FC_LIST_ITEMS @ADDI listptr @POPI itemslot
@PUSH 0 @PUSHI itemslot @POPS
@PUSHI listptr
:FCListAppendDone
@EndLocals
@POPRETURN
@RET

:FCListFree
@PUSHRETURN
@Locals
   @Local listptr
@POPI listptr
@PUSHI listptr
@IF_NOTZERO
   @POPNULL
   @Call(VV) HeapDeleteObject MainHeapID listptr @POPNULL
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCListFreeItems
@PUSHRETURN
@Locals
   @Local listptr
   @Local count
   @Local idx
   @Local itemslot
   @Local itemptr
@POPI listptr
@PUSHI listptr
@IF_NOTZERO
   @POPNULL
   @PUSHI listptr @ADD FC_LIST_COUNT @PUSHS @POPI count
   @MA2V 0 idx
   @PUSHI idx
   @WHILE_LT_V count
      @POPNULL
      @PUSHI idx @SHL @ADD FC_LIST_ITEMS @ADDI listptr @POPI itemslot
      @PUSHI itemslot @PUSHS @POPI itemptr
      @PUSHI itemptr
      @IF_NOTZERO
         @POPNULL
         @Call(VV) HeapDeleteObject MainHeapID itemptr @POPNULL
      @ELSE
         @POPNULL
      @ENDIF
      @INCI idx
      @PUSHI idx
   @ENDWHILE
   @POPNULL
   @Call(VV) HeapDeleteObject MainHeapID listptr @POPNULL
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCStrEq
@PUSHRETURN
@Locals
   @Local left
   @Local right
   @Local leftlen
   @Local rightlen
   @Local result
@POPI right
@POPI left
@MA2V 0 result
@Call(V) strlen left @POPI leftlen
@Call(V) strlen right @POPI rightlen
@PUSHI leftlen
@IF_EQ_V rightlen
   @POPNULL
   @Call(VV) strcmp left right
   @IF_ZERO
      @POPNULL
      @MA2V 1 result
   @ELSE
      @POPNULL
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
@PUSHI result
@EndLocals
@POPRETURN
@RET

:FCValidName
@PUSHRETURN
@Locals
   @Local name
   @Local len
@POPI name
@Call(V) strlen name @POPI len
@PUSHI len
@IF_ZERO
   @POPNULL @PUSH 0  @JMP FCValidDone
@ENDIF
@IF_GT_A FC_NAME_LEN
   @POPNULL @PUSH 0  @JMP FCValidDone
@ENDIF
@POPNULL
@PUSH 1
:FCValidDone
@EndLocals
@POPRETURN
@RET

:FCValidNameTailChar
@SWP
@IF_GE_A "A\0" @IF_LE_A "Z\0" @POPNULL @PUSH 1 @RET @ENDIF @ENDIF
@IF_GE_A "a\0" @IF_LE_A "z\0" @POPNULL @PUSH 1 @RET @ENDIF @ENDIF
@IF_GE_A "0\0" @IF_LE_A "9\0" @POPNULL @PUSH 1 @RET @ENDIF @ENDIF
@IF_EQ_A "_\0" @POPNULL @PUSH 1 @RET @ENDIF
@POPNULL @PUSH 0
@RET

:FCSkipWhite
@PUSHRETURN
@Locals
   @Local ptr
@POPI ptr
@PUSHII ptr @AND 0xff
@WHILE_NOTZERO
   @IF_EQ_A " \0"
      @POPNULL @INCI ptr @PUSHII ptr @AND 0xff
   @ELSE
      @IF_EQ_A "\t\0"
         @POPNULL @INCI ptr @PUSHII ptr @AND 0xff
      @ELSE
         @POPNULL @PUSH 0
      @ENDIF
   @ENDIF
@ENDWHILE
@POPNULL
@PUSHI ptr
@EndLocals
@POPRETURN
@RET

:FCTrimRight
@PUSHRETURN
@Locals
   @Local str
   @Local end
@POPI str
@Call(V) strlen str @ADDI str @POPI end
@PUSHI end
@WHILE_GT_V str
   @POPNULL
   @DECI end
   @PUSHII end @AND 0xff
   @IF_EQ_A " \0"
      @POPNULL @PUSH 0  @POPII end
   @ELSE
      @IF_EQ_A "\t\0"
         @POPNULL @PUSH 0  @POPII end
      @ELSE
         @POPNULL @MV2V str end
      @ENDIF
   @ENDIF
   @PUSHI end
@ENDWHILE
@POPNULL
@EndLocals
@POPRETURN
@RET

:FCClearVarTable
@PUSHRETURN
@Locals
   @Local table
   @Local idx
   @Local slot
   @Local total
@POPI table
@PUSHI table @ADD FC_TABLE_TOTAL @PUSHS @POPI total
@PUSHI table @ADD FC_TABLE_HEADER @POPI slot
@MA2V 0 idx
@PUSHI idx
@WHILE_LT_V total
   @POPNULL
   @PUSH 0 @PUSHI slot @ADD FC_SLOT_HASH1 @POPS
   @PUSH 0 @PUSHI slot @ADD FC_SLOT_HASH2 @POPS
   @PUSH FC_SLOT_EMPTY @PUSHI slot @ADD FC_SLOT_FLAGS @POPS
   @PUSH FC_TYPE_EMPTY @PUSHI slot @ADD FC_SLOT_TYPE @POPS
   @PUSH 0 @PUSHI slot @ADD FC_SLOT_NAMEPTR @POPS
   @PUSH 0 @PUSHI slot @ADD FC_SLOT_VALUEPTR @POPS
   @PUSHI slot @ADD FC_SLOT_SIZE @POPI slot
   @INCI idx
   @PUSHI idx
@ENDWHILE
@POPNULL
@EndLocals
@POPRETURN
@RET

# Future block parser entry points for the requested complete language:
:FCParseStatementList
@PUSHRETURN
@Locals
   @Local inptr
   @Local listptr
@POPI inptr
@Call(V) FCCompileStatementList inptr @POPI listptr
@PUSHI listptr
@EndLocals
@POPRETURN
@RET

:FCParseExpression
@PUSHRETURN
@Locals
   @Local exprptr
@POPI exprptr
@Call(V) FCEvalExpr exprptr
@EndLocals
@POPRETURN
@RET
:FCDefineFunction
@PRTLN "ERR DEFUN not implemented yet"
@RET
:FCWhileBlock
@PRTLN "ERR WHILE not implemented yet"
@RET
