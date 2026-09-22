? CPU24
MF FUNCCALC_CPU24 1
M FC_TARGET_ENTER @PUSH 1 @SSET SegDS @PUSH 1 @ADM
M FC_TARGET_EXIT @PUSH 0 @ADM
M FC_TARGET_HEAP_INIT @PUSH __DEND @PUSH 0xf800 @SUB __DEND
.DATA 1
I commonDS.mc
ENDBLOCK
! CPU24
M FC_TARGET_ENTER
M FC_TARGET_EXIT
M FC_TARGET_HEAP_INIT @PUSH END__ @PUSH 0xf800 @SUB END__
I common.mc
ENDBLOCK
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
# FCMemPrintFrameVars(label,frameptr):void "Prints variables stored in one frame table."
# FCMemPrintTableVars(label,tableptr):void "Prints active variable names and values from one table."
# FCMemPrintValue(valueptr):void "Prints a compact diagnostic rendering of a stored value."
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
# FCDispatchLazyFunction(name,argptr,closeptr):[matched] "Dispatches lazy calls such as IF and BLOCK before eager arg parsing."
# FCDispatchFunctionParsed(name):[matched] "Dispatches a parsed-argument function call."
# FCDispatchUserFunctionParsed(name):[matched] "Placeholder hook for parsed DEFUN calls."
# FCDispatchBuiltinParsed(name):[matched] "Dispatches parsed-argument builtins."
# FCBuiltinAbsParsed(argcount):void "Evaluates parsed ABS argument."
# FCBuiltinMinParsed(argcount):void "Evaluates parsed MIN over one or more numeric args."
# FCBuiltinLenParsed(argcount):void "Evaluates parsed LEN argument."
# FCBuiltinValParsed(argcount):void "Evaluates parsed VAL argument."
# FCBuiltinStrParsed(argcount):void "Evaluates parsed STR$ argument."
# FCBuiltinSplitParsed(argcount):void "Evaluates parsed SPLIT arguments."
# FCBuiltinIfLazy(argptr,closeptr):void "Evaluates lazy IF(condition,true,false)."
# FCBuiltinBlockLazy(argptr,closeptr):void "Executes a current-frame semicolon statement block."
# FCBuiltinCommentParsed(argcount):void "Parses and discards COMMENT metadata arguments."
# FCDispatchFunction(name,argptr):[matched] "Dispatches builtins, then user hook."
# FCDispatchUserFunction(name,argptr):[matched] "Placeholder hook for DEFUN lookup."
# FCDispatchBuiltin(name,argptr):[matched] "Dispatches supported built-in functions."
# FCBuiltinAbs(argptr):void "Evaluates ABS(number)."
# FCBuiltinMin(argptr):void "Evaluates MIN(number,number)."
# FCBuiltinLen(argptr):void "Evaluates LEN(string)."
# FCBuiltinVal(argptr):void "Evaluates VAL(string)."
# FCBuiltinStr(argptr):void "Evaluates STR$(number)."
# FCBuiltinSplit(argptr):void "Evaluates SPLIT(string,start,stop)."
# FCBuiltinComment(argptr):void "Compatibility no-op COMMENT function."
# FCStoreEval(slot):void "Stores the current Eval value into a variable slot."
# FCStorePointerValue(slot,type,payload):void "Stores a pointer payload value into a variable slot."
# FCFindOrAllocSlot(name):[slot] "Finds or allocates in current frame or globals."
# FCFindSlot(name):[slot] "Finds current-frame variable first, then global frame."
# FCFindSlotInTable(table,name):[slot] "Finds an active variable slot in one table."
# FCFindOrAllocSlotInTable(table,name):[slot] "Finds or allocates a slot in one table."
# FCAllocSlotInTable(table):[slot,table] "Allocates a slot in one table, growing as needed."
# FCSymTableGrow(table):[tableptr] "Doubles a heap-backed variable table."
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
# FCDefineFunction(argptr):void "Collects and stores a multiline DEFUN body."
# FCListFuncStatement(argptr):void "Prints stored function statement text for debugging."
# FCCallFuncStatement(argptr):void "Temporarily calls a stored function with parsed args."
# FCDebugStatement(argptr):void "Turns temporary function debug tracing ON or OFF."
# FCParamListFromText(paramptr):[listptr] "Builds a list of parameter-name strings."
# FCBindArgsToParams(funcptr,argcount):[ok] "Binds parsed call args to stored parameter names."
# FCInvokeFunction(funcptr,argcount):[ok] "Invokes a stored function using parsed args and leaves return in Eval."
# FCExprCleanupAdd(ptr):void "Adds one heap string/object to the expression cleanup pool."
# FCReleaseExprCleanup():void "Frees expression-scoped temporary strings."
# FCSetEvalFromArg(type,low,high,flags):void "Copies one parsed argument record into Eval storage."
# FCFramePush():[frameptr] "Creates a new local frame and makes it current."
# FCFramePop():void "Destroys the current local frame and restores the previous one."
# FCFrameCurrentTable():[tableptr] "Returns the active local table or zero."
# FCListGet(listptr,index):[itemptr] "Returns one pointer from a list by index."
# FCFuncObjectNew(arity,bodylist):[funcptr] "Creates a function object payload."
# FCFuncObjectRetain(funcptr):void "Increments a function object reference count."
# FCFuncObjectRelease(funcptr):void "Decrements a function object reference count and frees at zero."
# FCFuncObjectFree(funcptr):void "Frees a function object and owned body list."
# FCFuncObjectList(funcptr):void "Prints a function object body list."
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
=FC_VAL_FLAG_BORROW 0x0100
=FC_LIST_COUNT 0
=FC_LIST_CAPACITY 2
=FC_LIST_ITEMS 4
=FC_LIST_MINCAP 4
=FC_FUNC_REFCOUNT 0
=FC_FUNC_ARITY 2
=FC_FUNC_PARAMS 4
=FC_FUNC_BODY 6
=FC_FUNC_SIZE 8
=FC_FRAME_PREV 0
=FC_FRAME_TABLE 2
=FC_FRAME_SIZE 4
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

? FUNCCALC_CPU24
;MainHeapID 2 0
;LinePtr 2 0
;QuitFlag 2 0
;EqPtr 2 0
;NamePtr 2 0
;ValuePtr 2 0
;FoundSlot 2 0
;FreeSlot 2 0
;VarTablePtr 2 0
;GlobalFramePtr 2 0
;CurrentFramePtr 2 0
;ValueObjPtr 2 0
;EvalType 2 0
;EvalI32 4 0 0
;LeftI32 4 0 0
;EvalStr 2 0
;EvalStrObj 2 0
;EvalStrOwned 2 0
;EvalValueFlags 2 0
;FCExprCleanupList 2 0
;ExprOpPtr 2 0
;FCArgEndPtr 2 0
;FCReturnFlag 2 0
;FCDebugFlag 2 0
;PrintBuff 12 "00000000000\0"
;FcPrompt 5 "FC> \0"
;FcContPrompt 5 "... \0"
;MsgIntro 41 "FuncCalc assembly prototype. QUIT exits.\0"
;MsgErr 4 "ERR\0"
;MsgOk 3 "OK\0"
;KwQuit 5 "QUIT\0"
;KwExit 5 "EXIT\0"
;KwPrint 6 "PRINT\0"
;KwMem 4 "MEM\0"
;KwMemVar 7 "MEMVAR\0"
;KwClean 6 "CLEAN\0"
;KwHelp 5 "HELP\0"
;KwList 5 "LIST\0"
;KwExec 5 "EXEC\0"
;KwDefun 6 "DEFUN\0"
;KwEndDef 7 "ENDDEF\0"
;KwListFunc 9 "LISTFUNC\0"
;KwCallFunc 9 "CALLFUNC\0"
;KwDebug 6 "DEBUG\0"
;MemGlobalsLabel 8 "Globals\0"
;MemLocalsLabel 7 "Locals\0"
;KwOn 3 "ON\0"
;KwOff 4 "OFF\0"
;MetaCommentA 11 "COMMENT(0)\0"
;MetaCommentB 2 ")\0"
;SemiText 2 0x003b
;KwAbs 4 "ABS\0"
;KwMin 4 "MIN\0"
;KwLen 4 "LEN\0"
;KwVal 4 "VAL\0"
;KwStr 5 "STR$\0"
;KwSplit 6 "SPLIT\0"
;KwComment 8 "COMMENT\0"
;KwIf 3 "IF\0"
;KwBlock 6 "BLOCK\0"
;KwReturn 7 "RETURN\0"
ENDBLOCK
! FUNCCALC_CPU24
:MainHeapID 0
:LinePtr 0
:QuitFlag 0
:EqPtr 0
:NamePtr 0
:ValuePtr 0
:FoundSlot 0
:FreeSlot 0
:VarTablePtr 0
:GlobalFramePtr 0
:CurrentFramePtr 0
:ValueObjPtr 0
:EvalType 0
:EvalI32 0  0
:LeftI32 0 0
:EvalStr 0
:EvalStrObj 0
:EvalStrOwned 0
:EvalValueFlags 0
:FCExprCleanupList 0
:ExprOpPtr 0
:FCArgEndPtr 0
:FCReturnFlag 0
:FCDebugFlag 0
:PrintBuff "00000000000\0"
:FcPrompt "FC> \0"
:FcContPrompt "... \0"
:MsgIntro "FuncCalc assembly prototype. QUIT exits.\0"
:MsgErr "ERR\0"
:MsgOk "OK\0"
:KwQuit "QUIT\0"
:KwExit "EXIT\0"
:KwPrint "PRINT\0"
:KwMem "MEM\0"
:KwMemVar "MEMVAR\0"
:KwClean "CLEAN\0"
:KwHelp "HELP\0"
:KwList "LIST\0"
:KwExec "EXEC\0"
:KwDefun "DEFUN\0"
:KwEndDef "ENDDEF\0"
:KwListFunc "LISTFUNC\0"
:KwCallFunc "CALLFUNC\0"
:KwDebug "DEBUG\0"
:MemGlobalsLabel "Globals\0"
:MemLocalsLabel "Locals\0"
:KwOn "ON\0"
:KwOff "OFF\0"
:MetaCommentA "COMMENT(0)\0"
:MetaCommentB ")\0"
:SemiText 0x003b
:KwAbs "ABS\0"
:KwMin "MIN\0"
:KwLen "LEN\0"
:KwVal "VAL\0"
:KwStr "STR$\0"
:KwSplit "SPLIT\0"
:KwComment "COMMENT\0"
:KwIf "IF\0"
:KwBlock "BLOCK\0"
:KwReturn "RETURN\0"
ENDBLOCK
:Main . Main
@FC_TARGET_ENTER
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
@FC_TARGET_EXIT
@END

:FCInit
@FC_TARGET_HEAP_INIT
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
@Call(V) FCClearVarTable VarTablePtr
@Call(VA) HeapNewObject MainHeapID FC_FRAME_SIZE @POPI GlobalFramePtr
@PUSH 0 @PUSHI GlobalFramePtr @ADD FC_FRAME_PREV @POPS
@PUSHI VarTablePtr @PUSHI GlobalFramePtr @ADD FC_FRAME_TABLE @POPS
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
@Call(VA) FCStrEq cmdcopy KwMemVar
@IF_NOTZERO
   @POPNULL @CALL FCMemVarStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VA) FCStrEq cmdcopy KwMem
@IF_NOTZERO
   @POPNULL @CALL FCMemStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VAA) strncmp cmdcopy KwClean 5
@IF_ZERO
   @POPNULL @PUSHI inptr @ADD 5 @CALL FCCleanStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VAA) strncmp cmdcopy KwDefun 5
@IF_ZERO
   @POPNULL @PUSHI inptr @ADD 5 @CALL FCDefineFunction @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VAA) strncmp cmdcopy KwListFunc 8
@IF_ZERO
   @POPNULL @PUSHI inptr @ADD 8 @CALL FCListFuncStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VAA) strncmp cmdcopy KwCallFunc 8
@IF_ZERO
   @POPNULL @PUSHI inptr @ADD 8 @CALL FCCallFuncStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@Call(VAA) strncmp cmdcopy KwDebug 5
@IF_ZERO
   @POPNULL @PUSHI inptr @ADD 5 @CALL FCDebugStatement @JMP FCHandleDone
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
@PRTLN "  MEMVAR"
@PRTLN "  CLEAN [name]"
@PRTLN "  LIST name=stmt[;stmt]"
@PRTLN "  EXEC name"
@PRTLN "  DEFUN name(args)"
@PRTLN "  LISTFUNC name"
@PRTLN "  CALLFUNC name(args)"
@PRTLN "  DEBUG ON|OFF"
@PRTLN "  ABS(expr), MIN(expr,expr)"
@PRTLN "  IF(cond,true,false), BLOCK(stmt[;stmt])"
@PRTLN "  LEN(str), VAL(str), STR$(int)"
@PRTLN "  SPLIT(str,start,stop)"
@PRTLN "  COMMENT(str[,args])"
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
@Call(AV) FCMemPrintFrameVars MemGlobalsLabel GlobalFramePtr
@PUSHI CurrentFramePtr
@IF_NOTZERO
   @POPNULL @Call(AV) FCMemPrintFrameVars MemLocalsLabel CurrentFramePtr
@ELSE
   @POPNULL @PRTLN "Locals: <none>"
@ENDIF
@Call(V) HeapListMap MainHeapID
@RET

:FCMemVarStatement
@Call(AV) FCMemPrintFrameVars MemGlobalsLabel GlobalFramePtr
@PUSHI CurrentFramePtr
@IF_NOTZERO
   @POPNULL @Call(AV) FCMemPrintFrameVars MemLocalsLabel CurrentFramePtr
@ELSE
   @POPNULL @PRTLN "Locals: <none>"
@ENDIF
@RET

:FCMemPrintFrameVars
@PUSHRETURN
@Locals
   @Local labelptr
   @Local frameptr
   @Local tableptr
@POPI frameptr
@POPI labelptr
@PUSHI frameptr
@IF_NOTZERO
   @POPNULL
   @PUSHI frameptr @ADD FC_FRAME_TABLE @PUSHS @POPI tableptr
   @Call(VV) FCMemPrintTableVars labelptr tableptr
@ELSE
   @POPNULL
   @PRTSI labelptr @PRTLN ": <none>"
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCMemPrintTableVars
@PUSHRETURN
@Locals
   @Local labelptr
   @Local tableptr
   @Local active
   @Local idx
   @Local slot
   @Local nameptr
   @Local valptr
@POPI tableptr
@POPI labelptr
@PRTSI labelptr @PRT " ActiveSlots: "
@PUSHI tableptr @ADD FC_TABLE_ACTIVE @PUSHS @PRTTOP @POPNULL @PRTNL
@PUSHI tableptr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@PUSHI tableptr @ADD FC_TABLE_HEADER @POPI slot
@MA2V 0 idx
@PUSHI idx
@WHILE_LT_V active
   @POPNULL
   @PUSHI slot @ADD FC_SLOT_NAMEPTR @PUSHS @POPI nameptr
   @PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @POPI valptr
   @PRT "  " @PRTSI nameptr @PRT " = "
   @Call(V) FCMemPrintValue valptr
   @PRTNL
   @PUSHI slot @ADD FC_SLOT_SIZE @POPI slot
   @INCI idx
   @PUSHI idx
@ENDWHILE
@POPNULL
@EndLocals
@POPRETURN
@RET

:FCMemPrintValue
@PUSHRETURN
@Locals
   @Local valptr
   @Local typev
   @Local low
   @Local high
   @Local payload
   @Local flags
@POPI valptr
@PUSHI valptr
@IF_ZERO
   @POPNULL @PRT "<null>"
   @JMP FCMemPrintValueDone
@ENDIF
@POPNULL
@PUSHII valptr @AND 0xff @POPI typev
@PUSHI typev
@SWITCH
   @CASE FC_TYPE_I32
      @POPNULL
      @PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI low
      @PUSHI valptr @ADD FC_VAL_HIGH @PUSHS @POPI high
      @Call(AVVA) i32tos PrintBuff low high 10
      @PRTS PrintBuff
      @CBREAK
   @CASE FC_TYPE_STR
      @POPNULL
      @PUSHII valptr @AND 0xff00 @POPI flags
      @PUSHI flags
      @IF_EQ_A FC_VAL_FLAG_BORROW
         @POPNULL
         @PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI payload
      @ELSE
         @POPNULL
         @PUSHI valptr @ADD 2 @POPI payload
      @ENDIF
      @PRTSI payload
      @CBREAK
   @CASE FC_TYPE_FUNC
      @POPNULL @PRT "<FUNC>" @CBREAK
   @CASE FC_TYPE_LIST
      @POPNULL @PRT "<LIST>" @CBREAK
   @CDEFAULT
      @POPNULL @PRT "<EMPTY>" @CBREAK
@ENDCASE
:FCMemPrintValueDone
@EndLocals
@POPRETURN
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

:FCDefineFunction
@PUSHRETURN
@Locals
   @Local argptr
   @Local nameend
   @Local paren
   @Local endparen
   @Local param
   @Local arity
   @Local paramlist
   @Local lineptr
   @Local linecopy
   @Local body
   @Local lineno
   @Local done
   @Local linked
   @Local bodylist
   @Local funcptr
   @Local slot
@POPI argptr
@Call(V) FCSkipWhite argptr @POPI argptr
@Call(VA) strfndc argptr "(\0" @POPI paren
@PUSHI paren
@IF_ZERO
   @POPNULL @PRTLN "ERR DEFUN expected name(args)"
   @JMP FCDefineDone
@ENDIF
@POPNULL
@PUSHII paren @AND 0xff00 @PUSHI paren @POPS
@MV2V argptr NamePtr
@Call(V) FCTrimRight NamePtr
@Call(V) FCValidName NamePtr
@IF_ZERO
   @POPNULL @PRTLN "ERR bad name"
   @JMP FCDefineDone
@ENDIF
@POPNULL
@PUSHI paren @ADD 1 @POPI param
@Call(VA) strfndc param ")\0" @POPI endparen
@PUSHI endparen
@IF_ZERO
   @POPNULL @PRTLN "ERR DEFUN expected )"
   @JMP FCDefineDone
@ENDIF
@POPNULL
@PUSHII endparen @AND 0xff00 @PUSHI endparen @POPS
@Call(V) FCParamListFromText param @POPI paramlist
@PUSHI paramlist @ADD FC_LIST_COUNT @PUSHS @POPI arity
@Call(VA) HeapNewObject MainHeapID 2048 @POPI body
@PUSH 0 @POPII body
@MA2V 1 lineno
@MA2V 0 done
@PUSHI done
@WHILE_ZERO
   @POPNULL
   @PRTSTR FcContPrompt
   @CALL FCReadLine @POPI lineptr
   @Call(V) FCStringDup lineptr @POPI linecopy
   @Call(V) strUpCase linecopy
   @Call(V) FCTrimRight linecopy
   @Call(VA) strcmp linecopy KwEndDef
   @IF_ZERO
      @POPNULL
      @MA2V 1 done
   @ELSE
      @POPNULL
      @Call(VV) strcat body MetaCommentA
      @Call(VV) strcat body SemiText
      @Call(VV) strcat body lineptr
      @Call(VV) strcat body SemiText
      @INCI lineno
   @ENDIF
   @Call(V) FCFreeString linecopy
   @Call(V) FCFreeString lineptr
   @PUSHI done
@ENDWHILE
@POPNULL
@Call(V) FCCompileStatementList body @POPI linked
@Call(V) FCStatementLinkedToList linked @POPI bodylist
@Call(VVV) FCFuncObjectNew arity paramlist bodylist @POPI funcptr
@Call(V) FCFindOrAllocSlot NamePtr @POPI slot
@PUSHI slot
@IF_ZERO
   @POPNULL
   @Call(V) FCFuncObjectFree funcptr
   @PRTLN "ERR variable table full"
@ELSE
   @POPNULL
   @Call(VAV) FCStorePointerValue slot FC_TYPE_FUNC funcptr
   @PRTS MsgOk @PRTNL
@ENDIF
@Call(V) FCFreeString body
:FCDefineDone
@EndLocals
@POPRETURN
@RET

:FCListFuncStatement
@PUSHRETURN
@Locals
   @Local argptr
   @Local slot
   @Local valptr
   @Local typev
   @Local funcptr
@POPI argptr
@Call(V) FCSkipWhite argptr @POPI argptr
@Call(V) FCTrimRight argptr
@Call(V) FCFindSlot argptr @POPI slot
@PUSHI slot
@IF_ZERO
   @POPNULL @PRTLN "ERR no such function"
   @JMP FCListFuncDone
@ENDIF
@POPNULL
@PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @POPI valptr
@PUSHII valptr @AND 0xff @POPI typev
@PUSHI typev
@IF_EQ_A FC_TYPE_FUNC
   @POPNULL
   @PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI funcptr
   @Call(V) FCFuncObjectList funcptr
@ELSE
   @POPNULL @PRTLN "ERR variable is not a function"
@ENDIF
:FCListFuncDone
@EndLocals
@POPRETURN
@RET


:FCDebugStatement
@PUSHRETURN
@Locals
   @Local argptr
@POPI argptr
@Call(V) FCSkipWhite argptr @POPI argptr
@Call(V) FCStringDup argptr @POPI argptr
@Call(V) strUpCase argptr
@Call(V) FCTrimRight argptr
@Call(VA) strcmp argptr KwOn
@IF_ZERO
   @POPNULL
   @MA2V 1 FCDebugFlag
   @PRTLN "OK debug on"
   @JMP FCDebugDone
@ENDIF
@POPNULL
@Call(VA) strcmp argptr KwOff
@IF_ZERO
   @POPNULL
   @MA2V 0 FCDebugFlag
   @PRTLN "OK debug off"
@ELSE
   @POPNULL
   @PRTLN "ERR DEBUG expects ON or OFF"
@ENDIF
:FCDebugDone
@Call(V) FCFreeString argptr
@EndLocals
@POPRETURN
@RET

:FCCallFuncStatement
@PUSHRETURN
@Locals
   @Local argptr
   @Local paren
   @Local endparen
   @Local slot
   @Local valptr
   @Local typev
   @Local funcptr
   @Local argcount
   @Local ok
@POPI argptr
@Call(V) FCSkipWhite argptr @POPI argptr
@Call(VA) strfndc argptr "(\0" @POPI paren
@PUSHI paren
@IF_ZERO
   @POPNULL @PRTLN "ERR CALLFUNC expected name(args)"
   @JMP FCCallFuncDone
@ENDIF
@POPNULL
@PUSHII paren @AND 0xff00 @PUSHI paren @POPS
@MV2V argptr NamePtr
@Call(V) FCTrimRight NamePtr
@PUSHI paren @ADD 1 @POPI argptr
@Call(VA) strfndc argptr ")\0" @POPI endparen
@PUSHI endparen
@IF_ZERO
   @POPNULL @PRTLN "ERR CALLFUNC expected )"
   @JMP FCCallFuncDone
@ENDIF
@POPNULL
@Call(V) FCFindSlot NamePtr @POPI slot
@PUSHI slot
@IF_ZERO
   @POPNULL @PRTLN "ERR no such function"
   @JMP FCCallFuncDone
@ENDIF
@POPNULL
@PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @POPI valptr
@PUSHII valptr @AND 0xff @POPI typev
@PUSHI typev
@IF_NEQ_A FC_TYPE_FUNC
   @POPNULL @PRTLN "ERR variable is not a function"
   @JMP FCCallFuncDone
@ENDIF
@POPNULL
@PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI funcptr
@Call(V) FCParseArgList argptr
@POPI argcount
@Call(VV) FCInvokeFunction funcptr argcount @POPI ok
@PUSHI ok
@IF_NOTZERO
   @POPNULL
   @PUSHI EvalType
   @IF_EQ_A FC_TYPE_I32
      @POPNULL
      @Call(AVVA) i32tos PrintBuff EvalI32 EvalI32+2 10
      @PRTS PrintBuff @PRTNL
   @ELSE
      @POPNULL
      @PUSHI EvalType
      @IF_EQ_A FC_TYPE_STR
         @POPNULL
         @PRTSI EvalStr @PRTNL
         @CALL FCReleaseEvalString
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
@CALL FCReleaseExprCleanup
:FCCallFuncDone
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
@MV2V inptr NamePtr
@Call(V) FCStoreEval TargetSlot
@CALL FCReleaseExprCleanup
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
   @CASE FC_TYPE_FUNC
      @POPNULL
      @PRTLN "<FUNC>"
      @CBREAK
   @CASE FC_TYPE_LIST
      @POPNULL
      @PRTLN "<LIST>"
      @CBREAK
   @CDEFAULT
      @POPNULL @PRTLN "ERR nothing to print" @CBREAK
@ENDCASE
@CALL FCReleaseExprCleanup
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
         @PUSHI ch
         @IF_EQ_A "@\0"
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
   @Local callend
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
      @Call(V) FCExprCleanupAdd EvalStrObj
      @MA2V 0 EvalStrOwned
      @MA2V 0 EvalStrObj
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
         @PUSHI FCDebugFlag
         @IF_NOTZERO
            @POPNULL @PRT "DBG ERR group expected ) at " @PRTHEXI inptr @PRT " ch=" @PUSHII inptr @AND 0xff @PRTHEXTOP @POPNULL @PRTNL
         @ELSE
            @POPNULL
         @ENDIF
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
               @PUSHI FCDebugFlag
               @IF_NOTZERO
                  @POPNULL
                  @PRT "DBG CALL " @PRTSI namecopy @PRT " arg=" @PRTHEXI ValuePtr @PRT " close=" @PRTHEXI closeptr @PRTNL
               @ELSE
                  @POPNULL
               @ENDIF
               @Call(VVV) FCDispatchLazyFunction namecopy ValuePtr closeptr @POPI result
               @PUSHI result
               @IF_ZERO
                  @POPNULL
                  @Call(V) FCParseArgList ValuePtr
                  @MV2V FCArgEndPtr callend
                  @PUSHI namecopy @CALL FCDispatchFunctionParsed @POPI result
                  @MV2V callend inptr
               @ELSE
                  @POPNULL
                  @PUSHI closeptr @ADD 1 @POPI inptr
               @ENDIF
            @ELSE
               @POPNULL
               @PUSHI FCDebugFlag
               @IF_NOTZERO
                  @POPNULL @PRT "DBG ERR call expected ) name=" @PRTSI namecopy @PRT " open=" @PRTHEXI endptr @PRTNL
               @ELSE
                  @POPNULL
               @ENDIF
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
   @Local argflag
@IF_EQ_AV FC_TYPE_STR EvalType
   @PUSHI EvalStrOwned
   @IF_NOTZERO
      @POPNULL
      @MV2V EvalStrObj argstr
      @MA2V FC_ARG_HEAP argflag
      @MA2V 0 EvalStrOwned
   @ELSE
      @POPNULL
      @MV2V EvalStr argstr
      @MA2V FC_ARG_VAL argflag
   @ENDIF
   @PUSH FC_TYPE_STR
   @PUSHI argstr
   @PUSH 0
   @PUSHI argflag
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


:FCDispatchLazyFunction
@PUSHRETURN
@Locals
   @Local name
   @Local argptr
   @Local closeptr
   @Local result
@POPI closeptr
@POPI argptr
@POPI name
@MA2V 0 result
@Call(VA) strcmp name KwIf
@IF_ZERO
   @POPNULL
   @Call(VV) FCBuiltinIfLazy argptr closeptr
   @MA2V 1 result
   @JMP FCDispatchLazyFunctionDone
@ENDIF
@POPNULL
@Call(VA) strcmp name KwBlock
@IF_ZERO
   @POPNULL
   @Call(VV) FCBuiltinBlockLazy argptr closeptr
   @MA2V 1 result
   @JMP FCDispatchLazyFunctionDone
@ENDIF
@POPNULL
:FCDispatchLazyFunctionDone
@PUSHI result
@EndLocals
@POPRETURN
@RET

:FCBuiltinIfLazy
@PUSHRETURN
@Locals
   @Local argptr
   @Local closeptr
   @Local comma1
   @Local comma2
   @Local save1
   @Local save2
   @Local saveclose
   @Local branchptr
@POPI closeptr
@POPI argptr
@Call(V) FCFindArgComma argptr @POPI comma1
@PUSHI comma1
@IF_ZERO
   @POPNULL @PRTLN "ERR IF expects three args" @MA2V FC_TYPE_EMPTY EvalType @JMP FCBuiltinIfLazyDone
@ENDIF
@POPNULL
@Call(V) FCEvalExpr argptr
@PUSHI EvalType
@IF_NEQ_A FC_TYPE_I32
   @POPNULL @PRTLN "ERR IF condition expects number" @MA2V FC_TYPE_EMPTY EvalType @JMP FCBuiltinIfLazyDone
@ENDIF
@POPNULL
@CALL FCReleaseEvalString
@PUSHI comma1 @ADD 1 @POPI branchptr
@Call(V) FCFindArgComma branchptr @POPI comma2
@PUSHI FCDebugFlag
@IF_NOTZERO
   @POPNULL
   @PRT "DBG IF arg=" @PRTHEXI argptr @PRT " close=" @PRTHEXI closeptr @PRT " c1=" @PRTHEXI comma1 @PRT " c2=" @PRTHEXI comma2 @PRTNL
@ELSE
   @POPNULL
@ENDIF
@PUSHI comma2
@IF_ZERO
   @POPNULL @PRTLN "ERR IF expects three args" @MA2V FC_TYPE_EMPTY EvalType @JMP FCBuiltinIfLazyDone
@ENDIF
@POPNULL
# Lazy IF does not mutate shared statement text; expression parsing stops at commas/paren.
@PUSHI EvalI32 @ORI EvalI32+2
@IF_NOTZERO
   @POPNULL
   @PUSHI FCDebugFlag
   @IF_NOTZERO
      @POPNULL @PRT "DBG IF TRUE branch=" @PRTHEXI comma1 @PRTNL
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI comma1 @ADD 1 @POPI branchptr
   @Call(V) FCEvalExpr branchptr
@ELSE
   @POPNULL
   @PUSHI FCDebugFlag
   @IF_NOTZERO
      @POPNULL @PRT "DBG IF FALSE branch=" @PRTHEXI comma2 @PRTNL
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI comma2 @ADD 1 @POPI branchptr
   @Call(V) FCEvalExpr branchptr
@ENDIF
:FCBuiltinIfLazyDone
@EndLocals
@POPRETURN
@RET

:FCBuiltinBlockLazy
@PUSHRETURN
@Locals
   @Local argptr
   @Local closeptr
   @Local saveclose
   @Local linked
   @Local listptr
@POPI closeptr
@POPI argptr
@PUSHII closeptr @POPI saveclose
@PUSH 0 @POPII closeptr
@MA2V 0 FCReturnFlag
@Call(V) FCCompileStatementList argptr @POPI linked
@Call(V) FCStatementLinkedToList linked @POPI listptr
@Call(V) FCExecCodeList listptr
@PUSHI FCReturnFlag
@IF_ZERO
   @POPNULL
   @MA2V FC_TYPE_EMPTY EvalType
@ELSE
   @POPNULL
@ENDIF
@MA2V 0 FCReturnFlag
@Call(V) FCFreeCodeList listptr
@PUSHI saveclose @POPII closeptr
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
@PUSHRETURN
@Locals
   @Local name
   @Local argcount
   @Local slot
   @Local valptr
   @Local typev
   @Local funcptr
   @Local ok
@POPI name
@POPI argcount
@Call(V) FCFindSlot name @POPI slot
@PUSHI slot
@IF_ZERO
   @POPNULL
   @PRTLN "ERR unknown function"
   @Call(V) FCDiscardArgs argcount
   @MA2V FC_TYPE_EMPTY EvalType
   @PUSH 1
   @JMP FCDispatchUserFunctionParsedDone
@ENDIF
@POPNULL
@PUSHI slot @ADD FC_SLOT_VALUEPTR @PUSHS @POPI valptr
@PUSHII valptr @AND 0xff @POPI typev
@PUSHI typev
@IF_NEQ_A FC_TYPE_FUNC
   @POPNULL
   @PRTLN "ERR variable is not a function"
   @Call(V) FCDiscardArgs argcount
   @MA2V FC_TYPE_EMPTY EvalType
   @PUSH 1
   @JMP FCDispatchUserFunctionParsedDone
@ENDIF
@POPNULL
@PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI funcptr
@Call(VV) FCInvokeFunction funcptr argcount @POPI ok
@PUSHI ok
:FCDispatchUserFunctionParsedDone
@EndLocals
@POPRETURN
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
@Call(VA) strcmp name KwComment
@IF_ZERO
   @POPNULL
   @CALL FCBuiltinCommentParsed
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
@Call(VA) strcmp name KwComment
@IF_ZERO
   @POPNULL
   @Call(V) FCBuiltinComment argptr
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

:FCBuiltinCommentParsed
@PUSHRETURN
@Locals
   @Local count
@POPI count
@PUSHI count
@IF_ZERO
   @POPNULL
   @PRTLN "ERR COMMENT expects args"
@ELSE
   @POPNULL
   @Call(V) FCDiscardArgs count
@ENDIF
@MA2V FC_TYPE_EMPTY EvalType
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
@PUSHI comma1 @ADD 1 @POPI branchptr
@Call(V) FCFindArgComma branchptr @POPI comma2
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
   @PUSHI comma1 @ADD 1 @POPI branchptr
   @Call(V) FCEvalExpr branchptr
   @IF_EQ_AV FC_TYPE_I32 EvalType
      @PUSHI EvalI32 @POPI start
      @PUSHI comma2 @ADD 1 @POPI branchptr
   @Call(V) FCEvalExpr branchptr
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

:FCBuiltinComment
@POPNULL
@MA2V FC_TYPE_EMPTY EvalType
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
   @Local tableptr
@POPI name
@Call(V) FCFindSlot name @POPI FoundSlot
@PUSHI FoundSlot
@IF_ZERO
   @POPNULL
   @CALL FCFrameCurrentTable @POPI tableptr
   @PUSHI tableptr
   @IF_ZERO
      @POPNULL
      @MV2V VarTablePtr tableptr
   @ELSE
      @POPNULL
   @ENDIF
   @Call(VV) FCFindOrAllocSlotInTable tableptr name @POPI FoundSlot
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
   @Local frameptr
   @Local tableptr
@POPI name
@MA2V 0 FoundSlot
@MV2V CurrentFramePtr frameptr
@PUSHI frameptr
@IF_NOTZERO
   @POPNULL
   @PUSHI frameptr @ADD FC_FRAME_TABLE @PUSHS @POPI tableptr
   @Call(VV) FCFindSlotInTable tableptr name @POPI FoundSlot
@ELSE
   @POPNULL
@ENDIF
@PUSHI FoundSlot
@IF_ZERO
   @POPNULL
   @PUSHI GlobalFramePtr
   @IF_NOTZERO
      @POPNULL
      @PUSHI GlobalFramePtr @ADD FC_FRAME_TABLE @PUSHS @POPI tableptr
   @ELSE
      @POPNULL
      @MV2V VarTablePtr tableptr
   @ENDIF
   @Call(VV) FCFindSlotInTable tableptr name @POPI FoundSlot
@ELSE
   @POPNULL
@ENDIF
@PUSHI FoundSlot
@EndLocals
@POPRETURN
@RET

:FCFindOrAllocSlotInTable
@PUSHRETURN
@Locals
   @Local tableptr
   @Local name
   @Local slot
   @Local newtable
@POPI name
@POPI tableptr
@Call(VV) FCFindSlotInTable tableptr name @POPI slot
@PUSHI slot
@IF_ZERO
   @POPNULL
   @Call(V) FCAllocSlotInTable tableptr @POPI2 newtable slot
   @PUSHI tableptr
   @IF_EQ_V VarTablePtr
      @POPNULL
      @MV2V newtable VarTablePtr
   @ELSE
      @POPNULL
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
@PUSHI slot
@EndLocals
@POPRETURN
@RET

:FCFindSlotInTable
@PUSHRETURN
@Locals
   @Local tableptr
   @Local name
   @Local idx
   @Local slot
   @Local active
   @Local result
@POPI name
@POPI tableptr
@MA2V 0 result
@PUSHI tableptr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@PUSHI tableptr @ADD FC_TABLE_HEADER @POPI slot
@MA2V 0 idx
@PUSHI idx
@WHILE_LT_V active
   @POPNULL
   @PUSHI slot @ADD FC_SLOT_NAMEPTR @PUSHS @PUSHI name @CALL FCStrEq
   @IF_NOTZERO
      @POPNULL
      @MV2V slot result
      @PUSH 0
      @JMP FCFindTableDoneLoop
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI slot @ADD FC_SLOT_SIZE @POPI slot
   @INCI idx
   @PUSHI idx
@ENDWHILE
:FCFindTableDoneLoop
@POPNULL
@PUSHI result
@EndLocals
@POPRETURN
@RET

:FCAllocSlot
@PUSHRETURN
@Locals
   @Local slot
   @Local tableptr
@Call(V) FCAllocSlotInTable VarTablePtr @POPI2 tableptr slot
@MV2V tableptr VarTablePtr
@PUSHI slot
@EndLocals
@POPRETURN
@RET

:FCAllocSlotInTable
@PUSHRETURN
@Locals
   @Local tableptr
   @Local total
   @Local active
   @Local slot
   @Local offset
@POPI tableptr
@PUSHI tableptr @ADD FC_TABLE_TOTAL @PUSHS @POPI total
@PUSHI tableptr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@PUSHI active
@IF_UGE_V total
   @POPNULL
   @Call(V) FCSymTableGrow tableptr @POPI tableptr
   @PUSHI tableptr
   @IF_ZERO
      @POPNULL
      @PUSH 0
      @PUSH 0
      @JMP FCAllocTableDone
   @ENDIF
   @POPNULL
   @PUSHI tableptr @ADD FC_TABLE_TOTAL @PUSHS @POPI total
   @PUSHI tableptr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@ELSE
   @POPNULL
@ENDIF
@PUSHI active @SHL @SHL @POPI offset
@PUSHI active @SHL @SHL @SHL @ADDI offset @POPI offset
@PUSHI tableptr @ADD FC_TABLE_HEADER @ADDI offset @POPI slot
@PUSHI active @ADD 1 @PUSHI tableptr @ADD FC_TABLE_ACTIVE @POPS
@PUSH 0 @PUSHI slot @ADD FC_SLOT_HASH1 @POPS
@PUSH 0 @PUSHI slot @ADD FC_SLOT_HASH2 @POPS
@PUSH FC_SLOT_EMPTY @PUSHI slot @ADD FC_SLOT_FLAGS @POPS
@PUSH FC_TYPE_EMPTY @PUSHI slot @ADD FC_SLOT_TYPE @POPS
@PUSH 0 @PUSHI slot @ADD FC_SLOT_NAMEPTR @POPS
@PUSH 0 @PUSHI slot @ADD FC_SLOT_VALUEPTR @POPS
@PUSHI slot
@PUSHI tableptr
:FCAllocTableDone
@EndLocals
@POPRETURN
@RET

:FCSymTableGrow
@PUSHRETURN
@Locals
   @Local tableptr
   @Local oldtotal
   @Local newtotal
   @Local bytes
   @Local newtable
@POPI tableptr
@PUSHI tableptr @ADD FC_TABLE_TOTAL @PUSHS @POPI oldtotal
@PUSHI oldtotal @SHL @POPI newtotal
@PUSHI newtotal @SHL @SHL @POPI bytes
@PUSHI newtotal @SHL @SHL @SHL @ADDI bytes @POPI bytes
@PUSHI bytes @ADD FC_TABLE_HEADER @POPI bytes
@Call(VVV) HeapResizeObject MainHeapID tableptr bytes
@POPI newtable
@PUSHI newtable
@IF_ULT_A 100
   @POPNULL
   @PUSH 0
   @JMP FCSymTableGrowDone
@ENDIF
@POPNULL
@PUSHI newtotal @PUSHI newtable @ADD FC_TABLE_TOTAL @POPS
@PUSHI newtable
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
   @PUSHI EvalValueFlags
   @IF_EQ_A FC_VAL_FLAG_BORROW
      @POPNULL
      @Call(VA) HeapNewObject MainHeapID FC_VAL_SIZE @POPI valptr
      @PUSH FC_TYPE_STR @OR FC_VAL_FLAG_BORROW @POPII valptr
      @PUSHI EvalStr @PUSHI valptr @ADD FC_VAL_LOW @POPS
      @PUSH 0 @PUSHI valptr @ADD FC_VAL_HIGH @POPS
   @ELSE
      @POPNULL
      @Call(V) strlen EvalStr @ADD 1 @POPI strlenv
      @PUSHI MainHeapID @PUSHI strlenv @ADD 2 @CALL HeapNewObject
      @POPI valptr
      @PUSH FC_TYPE_STR @POPII valptr
      @PUSHI valptr @ADD 2 @POPI payload
      @Call(VVV) memcpy payload EvalStr strlenv
   @ENDIF
@ELSE
   @Call(VA) HeapNewObject MainHeapID FC_VAL_SIZE
   @POPI valptr
   @PUSHI EvalType @POPII valptr
   @PUSHI EvalI32 @PUSHI valptr @ADD FC_VAL_LOW @POPS
   @PUSHI EvalI32+2 @PUSHI valptr @ADD FC_VAL_HIGH @POPS
   @IF_EQ_AV FC_TYPE_FUNC EvalType
      @PUSHI EvalI32 @CALL FCFuncObjectRetain
   @ENDIF
@ENDIF
@PUSHI valptr
@EndLocals
@POPRETURN
@RET

:FCLoadValue
@PUSHRETURN
@Locals
   @Local valptr
   @Local typev
   @Local flags
@POPI valptr
@PUSHII valptr @AND 0xff @POPI typev
@PUSHII valptr @AND 0xff00 @POPI flags
@MV2V typev EvalType
@MV2V flags EvalValueFlags
@IF_EQ_AV FC_TYPE_STR EvalType
   @PUSHI flags
   @IF_EQ_A FC_VAL_FLAG_BORROW
      @POPNULL
      @PUSHI valptr @ADD FC_VAL_LOW @PUSHS @POPI EvalStr
   @ELSE
      @POPNULL
      @PUSHI valptr @ADD 2 @POPI EvalStr
   @ENDIF
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
   @MA2V 0 EvalValueFlags
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
         @Call(V) FCFuncObjectRelease payload
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
@MA2V 0 EvalValueFlags
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


:FCFramePush
@PUSHRETURN
@Locals
   @Local frameptr
   @Local tableptr
@Call(VA) HeapNewObject MainHeapID FC_FRAME_SIZE @POPI frameptr
@PUSHI CurrentFramePtr @PUSHI frameptr @ADD FC_FRAME_PREV @POPS
@PUSHI MainHeapID @PUSH 246 @CALL HeapNewObject @POPI tableptr
@PUSH FC_INITIAL_SLOTS @PUSHI tableptr @ADD FC_TABLE_TOTAL @POPS
@PUSH 0 @PUSHI tableptr @ADD FC_TABLE_ACTIVE @POPS
@PUSH FC_SLOT_SIZE @PUSHI tableptr @ADD FC_TABLE_SLOTBYTES @POPS
@Call(V) FCClearVarTable tableptr
@PUSHI tableptr @PUSHI frameptr @ADD FC_FRAME_TABLE @POPS
@MV2V frameptr CurrentFramePtr
@PUSHI frameptr
@EndLocals
@POPRETURN
@RET

:FCFramePop
@PUSHRETURN
@Locals
   @Local frameptr
   @Local tableptr
   @Local prevptr
@MV2V CurrentFramePtr frameptr
@PUSHI frameptr
@IF_NOTZERO
   @POPNULL
   @PUSHI frameptr @ADD FC_FRAME_PREV @PUSHS @POPI prevptr
   @PUSHI frameptr @ADD FC_FRAME_TABLE @PUSHS @POPI tableptr
   @PUSHI tableptr
   @IF_NOTZERO
      @POPNULL
      @Call(V) FCDeleteAllSlotsInTable tableptr
      @Call(VV) HeapDeleteObject MainHeapID tableptr @POPNULL
   @ELSE
      @POPNULL
   @ENDIF
   @Call(VV) HeapDeleteObject MainHeapID frameptr @POPNULL
   @MV2V prevptr CurrentFramePtr
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCFrameCurrentTable
@PUSHRETURN
@Locals
   @Local frameptr
   @Local tableptr
@MV2V CurrentFramePtr frameptr
@MA2V 0 tableptr
@PUSHI frameptr
@IF_NOTZERO
   @POPNULL
   @PUSHI frameptr @ADD FC_FRAME_TABLE @PUSHS @POPI tableptr
@ELSE
   @POPNULL
@ENDIF
@PUSHI tableptr
@EndLocals
@POPRETURN
@RET


:FCDeleteAllSlotsInTable
@PUSHRETURN
@Locals
   @Local tableptr
   @Local active
   @Local idx
   @Local slot
   @Local objptr
@POPI tableptr
@PUSHI tableptr @ADD FC_TABLE_ACTIVE @PUSHS @POPI active
@PUSHI tableptr @ADD FC_TABLE_HEADER @POPI slot
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
@PUSH 0 @PUSHI tableptr @ADD FC_TABLE_ACTIVE @POPS
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



:FCFuncObjectNew
@PUSHRETURN
@Locals
   @Local arity
   @Local paramlist
   @Local bodylist
   @Local funcptr
@POPI bodylist
@POPI paramlist
@POPI arity
@Call(VA) HeapNewObject MainHeapID FC_FUNC_SIZE @POPI funcptr
@PUSH 1 @PUSHI funcptr @ADD FC_FUNC_REFCOUNT @POPS
@PUSHI arity @PUSHI funcptr @ADD FC_FUNC_ARITY @POPS
@PUSHI paramlist @PUSHI funcptr @ADD FC_FUNC_PARAMS @POPS
@PUSHI bodylist @PUSHI funcptr @ADD FC_FUNC_BODY @POPS
@PUSHI funcptr
@EndLocals
@POPRETURN
@RET

:FCFuncObjectRetain
@PUSHRETURN
@Locals
   @Local funcptr
   @Local refcount
@POPI funcptr
@PUSHI funcptr
@IF_NOTZERO
   @POPNULL
   @PUSHI funcptr @ADD FC_FUNC_REFCOUNT @PUSHS @POPI refcount
   @INCI refcount
   @PUSHI refcount @PUSHI funcptr @ADD FC_FUNC_REFCOUNT @POPS
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCFuncObjectRelease
@PUSHRETURN
@Locals
   @Local funcptr
   @Local refcount
@POPI funcptr
@PUSHI funcptr
@IF_NOTZERO
   @POPNULL
   @PUSHI funcptr @ADD FC_FUNC_REFCOUNT @PUSHS @POPI refcount
   @PUSHI refcount
   @IF_GT_A 1
      @POPNULL
      @DECI refcount
      @PUSHI refcount @PUSHI funcptr @ADD FC_FUNC_REFCOUNT @POPS
   @ELSE
      @POPNULL
      @Call(V) FCFuncObjectFree funcptr
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET


:FCFuncObjectFree
@PUSHRETURN
@Locals
   @Local funcptr
   @Local bodylist
@POPI funcptr
@PUSHI funcptr
@IF_NOTZERO
   @POPNULL
   @PUSHI funcptr @ADD FC_FUNC_BODY @PUSHS @POPI bodylist
   @PUSHI bodylist
   @IF_NOTZERO
      @POPNULL
      @Call(V) FCFreeCodeList bodylist
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI funcptr @ADD FC_FUNC_PARAMS @PUSHS @POPI bodylist
   @PUSHI bodylist
   @IF_NOTZERO
      @POPNULL
      @Call(V) FCListFreeItems bodylist
   @ELSE
      @POPNULL
   @ENDIF
   @Call(VV) HeapDeleteObject MainHeapID funcptr @POPNULL
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCFuncObjectList
@PUSHRETURN
@Locals
   @Local funcptr
   @Local bodylist
   @Local arity
@POPI funcptr
@PUSHI funcptr @ADD FC_FUNC_ARITY @PUSHS @POPI arity
@PRT "FUNC Args: "
@PUSHI arity @PRTTOP @POPNULL @PRTNL
@PUSHI funcptr @ADD FC_FUNC_PARAMS @PUSHS @CALL FCListStringList
@PUSHI funcptr @ADD FC_FUNC_BODY @PUSHS @POPI bodylist
@Call(V) FCListCodeList bodylist
@EndLocals
@POPRETURN
@RET

:FCListStringList
@PUSHRETURN
@Locals
   @Local listptr
   @Local count
   @Local idx
   @Local itemslot
   @Local text
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
      @PUSHI itemslot @PUSHS @POPI text
      @PRT "ARG "
      @PUSHI idx @ADD 1 @PRTTOP @POPNULL
      @PRT ": "
      @PRTSI text
      @PRTNL
      @INCI idx
      @PUSHI idx
   @ENDWHILE
   @POPNULL
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET


:FCListCodeList
@PUSHRETURN
@Locals
   @Local listptr
   @Local count
   @Local idx
   @Local itemslot
   @Local stmt
   @Local text
@POPI listptr
@PUSHI listptr @ADD FC_LIST_COUNT @PUSHS @POPI count
@MA2V 0 idx
@PUSHI idx
@WHILE_LT_V count
   @POPNULL
   @PUSHI idx @SHL @ADD FC_LIST_ITEMS @ADDI listptr @POPI itemslot
   @PUSHI itemslot @PUSHS @POPI stmt
   @PUSHI stmt @ADD FC_STMT_TEXTPTR @PUSHS @POPI text
   @PRTSI text
   @PRTNL
   @INCI idx
   @PUSHI idx
@ENDWHILE
@POPNULL
@EndLocals
@POPRETURN
@RET


:FCParamListFromText
@PUSHRETURN
@Locals
   @Local paramptr
   @Local cur
   @Local sep
   @Local seglen
   @Local listptr
   @Local itemptr
   @Local done
@POPI paramptr
@Call(A) FCListNew 4 @POPI listptr
@Call(V) FCSkipWhite paramptr @POPI cur
@PUSHII cur @AND 0xff
@IF_ZERO
   @POPNULL
   @JMP FCParamListDone
@ENDIF
@POPNULL
@MA2V 0 done
@PUSHI done
@WHILE_ZERO
   @POPNULL
   @Call(VA) strfndc cur ",\0" @POPI sep
   @PUSHI sep
   @IF_ZERO
      @POPNULL
      @Call(V) strlen cur @POPI seglen
      @MA2V 1 done
   @ELSE
      @POPNULL
      @PUSHI sep @SUBI cur @POPI seglen
   @ENDIF
   @Call(VV) FCSubStringDup cur seglen @POPI itemptr
   @Call(V) FCTrimRight itemptr
   @Call(V) FCValidName itemptr
   @IF_ZERO
      @POPNULL
      @PRTLN "ERR bad parameter"
   @ELSE
      @POPNULL
      @Call(VV) FCListAppend listptr itemptr @POPI listptr
   @ENDIF
   @PUSHI done
   @IF_ZERO
      @POPNULL
      @PUSHI sep @ADD 1 @POPI cur
      @Call(V) FCSkipWhite cur @POPI cur
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI done
@ENDWHILE
@POPNULL
:FCParamListDone
@PUSHI listptr
@EndLocals
@POPRETURN
@RET


:FCInvokeFunction
@PUSHRETURN
@Locals
   @Local funcptr
   @Local argcount
   @Local ok
@POPI argcount
@POPI funcptr
@MA2V 0 ok
@CALL FCFramePush @POPNULL
@Call(VV) FCBindArgsToParams funcptr argcount @POPI ok
@PUSHI ok
@IF_NOTZERO
   @POPNULL
   @MA2V 0 FCReturnFlag
   @PUSHI funcptr @ADD FC_FUNC_BODY @PUSHS @CALL FCExecCodeList
   @PUSHI FCReturnFlag
   @IF_ZERO
      @POPNULL
      @MA2V FC_TYPE_EMPTY EvalType
   @ELSE
      @POPNULL
   @ENDIF
   @MA2V 0 FCReturnFlag
@ELSE
   @POPNULL
@ENDIF
@CALL FCFramePop
@PUSHI ok
@EndLocals
@POPRETURN
@RET

:FCExprCleanupAdd
@PUSHRETURN
@Locals
   @Local objptr
@POPI objptr
@PUSHI objptr
@IF_NOTZERO
   @POPNULL
   @PUSHI FCExprCleanupList
   @IF_ZERO
      @POPNULL
      @Call(A) FCListNew 4 @POPI FCExprCleanupList
   @ELSE
      @POPNULL
   @ENDIF
   @Call(VV) FCListAppend FCExprCleanupList objptr @POPI FCExprCleanupList
@ELSE
   @POPNULL
@ENDIF
@EndLocals
@POPRETURN
@RET

:FCReleaseExprCleanup
@PUSHRETURN
@PUSHI FCExprCleanupList
@IF_NOTZERO
   @POPNULL
   @Call(V) FCListFreeItems FCExprCleanupList
   @MA2V 0 FCExprCleanupList
@ELSE
   @POPNULL
@ENDIF
@POPRETURN
@RET

:FCBindArgsToParams
@PUSHRETURN
@Locals
   @Local funcptr
   @Local argcount
   @Local arity
   @Local params
   @Local tableptr
   @Local idx
   @Local paramname
   @Local slot
   @Local typev
   @Local low
   @Local high
   @Local flags
   @Local ok
@POPI argcount
@POPI funcptr
@MA2V 0 ok
@PUSHI funcptr @ADD FC_FUNC_ARITY @PUSHS @POPI arity
@PUSHI funcptr @ADD FC_FUNC_PARAMS @PUSHS @POPI params
@PUSHI argcount
@IF_NEQ_V arity
   @POPNULL
   @PRTLN "ERR wrong arg count"
   @Call(V) FCDiscardArgs argcount
   @JMP FCBindArgsDone
@ENDIF
@POPNULL
@CALL FCFrameCurrentTable @POPI tableptr
@PUSHI tableptr
@IF_ZERO
   @POPNULL
   @PRTLN "ERR no local frame"
   @Call(V) FCDiscardArgs argcount
   @JMP FCBindArgsDone
@ENDIF
@POPNULL
@MV2V arity idx
@PUSHI idx
@WHILE_NOTZERO
   @POPNULL
   @DECI idx
   @POPI flags
   @POPI high
   @POPI low
   @POPI typev
   @Call(VV) FCListGet params idx @POPI paramname
   @Call(VV) FCFindOrAllocSlotInTable tableptr paramname @POPI slot
   @PUSHI slot
   @IF_ZERO
      @POPNULL
      @PRTLN "ERR local table full"
      @PUSHI typev @PUSHI low @PUSHI high @PUSHI flags @CALL FCReleaseArg
      @Call(V) FCDiscardArgs idx
      @JMP FCBindArgsDone
   @ENDIF
   @POPNULL
   @MV2V paramname NamePtr
   @PUSHI typev @PUSHI low @PUSHI high @PUSHI flags @CALL FCSetEvalFromArg
   @Call(V) FCStoreEval slot
   @PUSHI typev
   @IF_EQ_A FC_TYPE_STR
      @POPNULL
      @PUSHI flags
      @IF_EQ_A FC_ARG_HEAP
         @POPNULL
         @Call(V) FCExprCleanupAdd low
      @ELSE
         @POPNULL
      @ENDIF
   @ELSE
      @POPNULL
      @PUSHI typev @PUSHI low @PUSHI high @PUSHI flags @CALL FCReleaseArg
   @ENDIF
   @PUSHI idx
@ENDWHILE
@POPNULL
@MA2V 1 ok
:FCBindArgsDone
@PUSHI ok
@EndLocals
@POPRETURN
@RET

:FCSetEvalFromArg
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
@MV2V typev EvalType
@PUSHI typev
@IF_EQ_A FC_TYPE_STR
   @POPNULL
   @MV2V low EvalStr
   @MA2V 0 EvalStrObj
   @MA2V 0 EvalStrOwned
   @MA2V FC_VAL_FLAG_BORROW EvalValueFlags
   @MA2V 0 EvalI32
   @MA2V 0 EvalI32+2
@ELSE
   @POPNULL
   @MV2V low EvalI32
   @MV2V high EvalI32+2
   @MA2V 0 EvalStr
   @MA2V 0 EvalStrObj
   @MA2V 0 EvalStrOwned
   @MA2V 0 EvalValueFlags
@ENDIF
@EndLocals
@POPRETURN
@RET


:FCListGet
@PUSHRETURN
@Locals
   @Local listptr
   @Local index
   @Local count
   @Local itemslot
@POPI index
@POPI listptr
@PUSHI listptr @ADD FC_LIST_COUNT @PUSHS @POPI count
@PUSHI index
@IF_ULT_V count
   @POPNULL
   @PUSHI index @SHL @ADD FC_LIST_ITEMS @ADDI listptr @POPI itemslot
   @PUSHI itemslot @PUSHS
@ELSE
   @POPNULL
   @PUSH 0
@ENDIF
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
:FCWhileBlock
@PRTLN "ERR WHILE not implemented yet"
@RET
