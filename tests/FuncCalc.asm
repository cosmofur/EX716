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

=FC_MAX_VARS 32
=FC_NAME_LEN 8
=FC_SLOT_SIZE 16
=FC_VAR_BYTES 512
=FC_TYPE_EMPTY 0
=FC_TYPE_I32 1
=FC_TYPE_STR 2

:MainHeapID 0
:LinePtr 0
:QuitFlag 0
:EqPtr 0
:NamePtr 0
:ValuePtr 0
:FoundSlot 0
:FreeSlot 0
:VarTablePtr 0
:EvalType 0
:EvalI32 0  0
:EvalStr 0
:PrintBuff "00000000000\0"
:FcPrompt "FC> \0"
:MsgIntro "FuncCalc assembly prototype. QUIT exits.\0"
:MsgErr "ERR\0"
:MsgOk "OK\0"
:KwQuit "QUIT\0"
:KwExit "EXIT\0"
:KwPrint "PRINT\0"
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
@PUSHI MainHeapID @PUSH FC_VAR_BYTES
@CALL HeapNewObject @IF_ULT_A 100 @PRTLN "Heap vars failed" @END @ENDIF
@POPI VarTablePtr
@CALL FCClearVarTable
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
@SWP
@IF_NOTZERO
   @PUSHI MainHeapID @SWP @CALL HeapDeleteObject @POPNULL
@ELSE
   @POPNULL
@ENDIF
@RET

:FCHandleLine
@PUSHRETURN
@Locals
   @Local inptr
@POPI inptr
@PUSHI inptr @CALL FCSkipWhite @POPI inptr
@PUSHI inptr @PUSH KwQuit @CALL strcmp
@IF_ZERO
   @POPNULL @MA2V 1 QuitFlag @JMP FCHandleDone
@ENDIF
@POPNULL
@PUSHI inptr @PUSH KwExit @CALL strcmp
@IF_ZERO
   @POPNULL @MA2V 1 QuitFlag @JMP FCHandleDone
@ENDIF
@POPNULL
@PUSHI inptr @PUSH KwPrint @PUSH 5 @CALL strncmp
@IF_ZERO
   @POPNULL @PUSHI inptr @ADD 5 @CALL FCPrintStatement @JMP FCHandleDone
@ENDIF
@POPNULL
@PUSHI inptr @CALL FCAssignStatement
:FCHandleDone
@EndLocals
@POPRETURN
@RET

:FCAssignStatement
@PUSHRETURN
@Locals
   @Local inptr
@POPI inptr
@PUSHI inptr @PUSH "=\0" @CALL strfndc @POPI EqPtr
@PUSHI EqPtr
@IF_ZERO
   @POPNULL @PRTLN "ERR expected assignment or PRINT"
   @JMP FCAssignDone
@ENDIF
@POPNULL
@PUSHII EqPtr @AND 0xff00 @PUSHI EqPtr @POPS       # terminate name in-place
@MV2V inptr NamePtr
@PUSHI EqPtr @ADD 1 @CALL FCSkipWhite @POPI ValuePtr
@PUSHI NamePtr @CALL FCTrimRight
@PUSHI NamePtr @CALL FCValidName
@IF_ZERO
   @POPNULL @PRTLN "ERR bad name"
   @JMP FCAssignDone
@ENDIF
@POPNULL
@PUSHI NamePtr @CALL FCFindOrAllocSlot @POPI FoundSlot
@PUSHI FoundSlot
@IF_ZERO
   @POPNULL @PRTLN "ERR variable table full"
   @JMP FCAssignDone
@ENDIF
@POPNULL
@PUSHI ValuePtr @CALL FCEvalAtom
@PUSHI FoundSlot @CALL FCStoreEval
@PRTS MsgOk @PRTNL
:FCAssignDone
@EndLocals
@POPRETURN
@RET

:FCPrintStatement
@PUSHRETURN
@Locals
   @Local inptr
@POPI inptr
@PUSHI inptr @CALL FCSkipWhite @POPI inptr
@PUSHII inptr @AND 0xff
@IF_EQ_A "(\0"
   @POPNULL @INCI inptr
@ELSE
   @POPNULL
@ENDIF
@PUSHI inptr @PUSH ")\0" @CALL strfndc @POPI EqPtr
@PUSHI EqPtr
@IF_NOTZERO
   @POPNULL
   @PUSHII EqPtr @AND 0xff00 @PUSHI EqPtr @POPS
@ELSE
   @POPNULL
@ENDIF
@PUSHI inptr @CALL FCTrimRight
@PUSHI inptr @CALL FCEvalAtom
@PUSHI EvalType
@SWITCH
   @CASE FC_TYPE_I32
      @POPNULL
      @PUSH PrintBuff @PUSHI EvalI32 @PUSHI EvalI32+2 @PUSH 10 @CALL i32tos
      @PRTS PrintBuff @PRTNL
      @CBREAK
   @CASE FC_TYPE_STR
      @POPNULL @PRTSI EvalStr @PRTNL @CBREAK
   @CDEFAULT
      @POPNULL @PRTLN "ERR nothing to print" @CBREAK
@ENDCASE
@EndLocals
@POPRETURN
@RET

# FCEvalAtom(exprptr) sets EvalType/EvalI32/EvalStr.
# This is the attachment point for the full recursive expression parser:
#   ParseExpr -> ParseTerm -> ParseUnary -> ParsePrimary -> DispatchFunction.
:FCEvalAtom
@PUSHRETURN
@Locals
   @Local expr
   @Local slot
@POPI expr
@PUSHI expr @CALL FCSkipWhite @POPI expr
@PUSHII expr @AND 0xff
@SWITCH
   @CASE "\"\0"
      @POPNULL
      @INCI expr
      @PUSHI expr @PUSH "\"\0" @CALL strfndc
      @POPI EqPtr
      @PUSHI EqPtr
      @IF_NOTZERO
         @POPNULL
         @PUSHII EqPtr @AND 0xff00 @PUSHI EqPtr @POPS
      @ELSE
         @POPNULL
      @ENDIF
      @PUSHI expr @CALL FCStringDup @POPI EvalStr
      @MA2V FC_TYPE_STR EvalType
      @CBREAK
   @CASE_RANGE "0\0" "9\0"
      @POPNULL
      @PUSHI expr @CALL stoi32 @POP32I(V) EvalI32
      @MA2V 0 EvalStr
      @MA2V FC_TYPE_I32 EvalType
      @CBREAK
   @CDEFAULT
      @POPNULL
      @PUSHI expr @CALL FCTrimRight
      @PUSHI expr @CALL FCFindSlot @POPI slot
      @PUSHI slot
      @IF_ZERO
         @POPNULL @PRTLN "ERR unknown atom" @MA2V FC_TYPE_EMPTY EvalType
      @ELSE
         @POPNULL
         @PUSHII slot @AND 0xff @POPI EvalType
         @PUSHI slot @ADD 10 @PUSHS @POPI EvalI32
         @PUSHI slot @ADD 12 @PUSHS @POPI EvalI32+2
         @PUSHI slot @ADD 14 @PUSHS @POPI EvalStr
      @ENDIF
      @CBREAK
@ENDCASE
@EndLocals
@POPRETURN
@RET

:FCStoreEval
@PUSHRETURN
@Locals
   @Local slot
@POPI slot
@PUSHI EvalType @POPII slot
@PUSHI slot @ADD 1 @PUSHI NamePtr @CALL strcpy
@PUSHI EvalI32 @PUSHI slot @ADD 10 @POPS
@PUSHI EvalI32+2 @PUSHI slot @ADD 12 @POPS
@PUSHI EvalStr @PUSHI slot @ADD 14 @POPS
@EndLocals
@POPRETURN
@RET

:FCFindOrAllocSlot
@PUSHRETURN
@Locals
   @Local name
@POPI name
@PUSHI name @CALL FCFindSlot @POPI FoundSlot
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
# First-slice lookup: compare against the single heap-backed slot.
@PUSHRETURN
@Locals
   @Local name
@POPI name
@PUSHII VarTablePtr @AND 0xff
@IF_NOTZERO
   @POPNULL
   @PUSHI VarTablePtr @ADD 1 @PUSHI name @CALL strcmp
   @IF_ZERO
      @POPNULL @PUSHI VarTablePtr @JMP FCFindDone
   @ELSE
      @POPNULL
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
@PUSH 0
:FCFindDone
@EndLocals
@POPRETURN
@RET

:FCAllocSlot
# First-slice allocator: return the first heap-backed slot.
# The multi-slot scan belongs with the full symbol table pass.
@PUSHRETURN
@PUSHI VarTablePtr
@POPRETURN
@RET

:FCStringDup
@PUSHRETURN
@Locals
   @Local src
   @Local dst
   @Local len
@POPI src
@PUSHI src @CALL strlen @POPI len
@PUSHI MainHeapID @PUSHI len @ADD 1 @CALL HeapNewObject
@POPI dst
@PUSHI dst @PUSHI src @CALL strcpy
@PUSHI dst
@EndLocals
@POPRETURN
@RET

:FCValidName
@PUSHRETURN
@Locals
   @Local name
   @Local len
@POPI name
@PUSHI name @CALL strlen @POPI len
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
@PUSHI str @CALL strlen @ADDI str @POPI end
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
         @POPNULL @PUSHI str
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
   @Local idx
   @Local slot
@MV2V VarTablePtr slot
@ForIA2V idx 0  FC_MAX_VARS
   @PUSH 0  @PUSHI slot @POPS
   @PUSHI slot @ADD FC_SLOT_SIZE @POPI slot
@Next idx
@EndLocals
@POPRETURN
@RET

# Future block parser entry points for the requested complete language:
:FCParseStatementList
@PRTLN "ERR statement lists not implemented yet"
@RET
:FCParseExpression
@PRTLN "ERR expressions not implemented yet"
@RET
:FCDispatchBuiltin
@PRTLN "ERR builtin dispatch not implemented yet"
@RET
:FCDefineFunction
@PRTLN "ERR DEFUN not implemented yet"
@RET
:FCWhileBlock
@PRTLN "ERR WHILE not implemented yet"
@RET
