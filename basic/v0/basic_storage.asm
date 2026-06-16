I common.mc
# basic/v0/basic_storage.asm
# BASIC v0 – Program Line Storage (ESX716 compliant)
#
# Line record format:
#   WORD line_number
#   WORD next_ptr
#   BYTE text...
#   BYTE 0
#
# Invariants:
#   - Lines sorted ascending by line number
#   - No duplicate line numbers
#   - ProgramStart == 0 means empty program
#   - FreePtr always points to first unused byte

# --------------------------------------------------
# Global state
# --------------------------------------------------
G PROGRAM_MEMORY_START

:ProgramStart
    0           # WORD

:ProgramEnd
    0           # WORD

:FreePtr
    0           # WORD

=LINE_HEADER_SIZE 4


# --------------------------------------------------
# InitProgramStorage
# --------------------------------------------------

:InitProgramStorage
    @PUSHI 0
    @POPI ProgramStart

    @PUSHI 0
    @POPI ProgramEnd

    @PUSH _END_
    @POPI FreePtr
@RET


# --------------------------------------------------
# FindLine
# --------------------------------------------------
# IN:
#   LineNum (argument passed on stack)
#
# OUT (via stack): (CurPtr, PrevPtr, Found)
# --------------------------------------------------

:FindLine
    @PUSHRETURN
    @LocalVar LineNum 01
    @LocalVar CurPtr  02
    @LocalVar PrevPtr 03
    @LocalVar Found   04
    @LocalVar CurNum  05

    @POPI LineNum
    
    @MA2V 0 PrevPtr

    @PUSHI ProgramStart
    @POPI CurPtr

    @MA2V 0 Found

    @PUSH 0
    @WHILE_ZERO
        @POPNULL
        @IF_EQ_AV 0 CurPtr
	    @PUSH 1       # Break Loop Not Found
        @ELSE
            @PUSHII CurPtr
            @POPI CurNum

            @IF_EQ_VV CurNum LineNum
	       @MA2V 1 Found
               @JMP FLBreakWhile
            @ENDIF

            @PUSHI CurNum
	    @IF_GT_V LineNum
	       @POPNULL
               @JMP FLBreakWhile
            @ENDIF
            @POPNULL
            @MV2V CurPtr PrevPtr
            @PUSHI CurPtr  # Next Address after CurPtr will be next line ptr
            @ADD 2
            @PUSHS
            @POPI CurPtr
            @PUSHI Found     # While continue until break or Found != 0
	@ENDIF
    @ENDWHILE
    @POPNULL
    :FLBreakWhile

    @PUSHI CurPtr    
    @PUSHI PrevPtr
    @PUSHI Found

    
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN
    @RET


# --------------------------------------------------
# InsertOrDeleteLine
# --------------------------------------------------
# IN:
#   stack:
#     LineNum
#     TextPtr
#     TextLen
# --------------------------------------------------

:InsertOrDeleteLine
    @PUSHRETURN
    @LocalVar LineNum 01
    @LocalVar TextPtr 02
    @LocalVar TextLen 03
    @LocalVar Found   04    
    @LocalVar PrevPtr 05
    @LocalVar CurPtr  06    

    @POPI TextLen
    @POPI TextPtr
    @POPI LineNum

    @PUSHI LineNum
    @CALL FindLine
    @POPI Found
    @POPI PrevPtr
    @POPI CurPtr

    @IF_EQ_AV 0 TextLen
        @IF_NEQ_AV 0 Found
            @Call(VV) DeleteLine CurPtr PrevPtr
        @ENDIF
        @JMP IOD_Exit   # Force break to end of function.
    @ENDIF

    @IF_NEQ_AV 0 Found
        @PUSHI LineNum @Call(VVVV) ReplaceLine TextLen TextPtr PrevPtr CurPtr    
    @ELSE
        @PUSHI LineNum @Call(VVVV) InsertLine TextLen TextPtr PrevPtr CurPtr
    @ENDIF
:IOD_Exit
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN    
@RET


# --------------------------------------------------
# InsertLine(LineNumer, TextLen, TextPtr, PrevPtr, CurPtr)
# --------------------------------------------------

:InsertLine
@PUSHRETURN
    @LocalVar LineNum       01
    @LocalVar TextLen       02
    @LocalVar TextPtr       03
    @LocalVar NewPtr        04
    @LocalVar NextPtrSave   05
    @LocalVar BuffPtr       06
    @LocalVar PrevPtr       07
    @LocalVar CurPtr        08
    @LocalVar RecPtr        09

    @POPI CurPtr
    @POPI PrevPtr
    @POPI TextPtr
    @POPI TextLen
    @POPI LineNum

    @IF_EQ_AV 0 ProgramStart
       @MA2V 0 PrevPtr
       @MA2V 0 CurPtr
    @ENDIF

    @MV2V FreePtr NewPtr
    @MV2V NewPtr RecPtr

    @PUSHI LineNum @POPII NewPtr     # Save LineNum [FreePtr]

    @INC2I NewPtr                    # Save CurPtr [FreePtr+2]
    @PUSHI CurPtr
    @POPII NewPtr

    @INC2I NewPtr

    @Call(VVV) strncpy NewPtr TextPtr TextLen  # Save String starting at [FreePtr+4]

    @PUSHI NewPtr
    @ADDI TextLen
    @POPI NewPtr                     # This is the address we need to force to be zero

    @PUSH 0
    @STOREBI NewPtr

    @IF_NEQ_AV 0 PrevPtr
       @PUSHI RecPtr
       @PUSHI PrevPtr
       @ADD 2
       @POPS              # Put PrevPtr at [FreePtr+2]
    @ENDIF

    @IF_EQ_AV 0 PrevPtr               # If no Previous, then mark as ProgramStart
       @MV2V RecPtr ProgramStart
    @ENDIF

    @IF_EQ_AV 0 CurPtr               # If no CurPtr(Next) then mark as ProgramEnd
       @MV2V RecPtr ProgramEnd
    @ENDIF

    @PUSHI RecPtr
    @ADD 4
    @ADDI TextLen
    @ADD 1
    @POPI FreePtr

#    @PUSH 0 @POPII FreePtr

    @RestoreVar 09
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


# --------------------------------------------------
# ReplaceLine
# --------------------------------------------------

:ReplaceLine
    @PUSHRETURN
    @LocalVar CurPtr 01   @POPI CurPtr
    @LocalVar PrevPtr 02  @POPI PrevPtr
    @LocalVar TextPtr 03  @POPI TextPtr
    @LocalVar TextLen 04  @POPI TextLen
    @LocalVar LineNum 05 @POPI LineNum
    @Call(VV) DeleteLine CurPtr PrevPtr
    @Call(v) FindLine LineNum
    @POPI Found    @POPI PrevPtr    @POPI CurPtr
    @IF_EQ_AV 0 Found
       @PUSHI LineNum @Call(VVVV) InsertLine TextLen TextPtr PrevPtr CurPtr
    @ELSE
       @PRT "Error: Edit of " @PRTI LineNum @PRTLN " Failed to free memory."
    @ENDIF
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN
    
@RET
# --------------------------------------------------
# DeleteLine(CurPtr, PrevPtr) -> NextPtr
#
# Deletes the record at CurPtr, compacts memory,
# fixes all links, updates ProgramStart/End/FreePtr,
# and RETURNS NextPtr on stack.
# --------------------------------------------------

:DeleteLine
@PUSHRETURN
    @LocalVar CurPtr      01   # input
    @LocalVar PrevPtr     02   # input
    @LocalVar DelPtr      03   # invariant delete address
    @LocalVar NextPtr     04   # invariant logical successor
    @LocalVar TextLen     05
    @LocalVar RecSize     06
    @LocalVar SrcPtr      07
    @LocalVar MoveLen     08
    @LocalVar ScanPtr     09
    @LocalVar TmpPtr      10

    # ------------------------------------------
    # Inputs
    # ------------------------------------------
    @POPI PrevPtr
    @POPI CurPtr

    @MV2V CurPtr DelPtr        # DelPtr = CurPtr

    # ------------------------------------------
    # NextPtr = [DelPtr + 2]
    # ------------------------------------------
    @PUSHI DelPtr
    @ADD 2
    @PUSHS
    @POPI NextPtr

    # ------------------------------------------
    # Logical unlink
    # ------------------------------------------
    @IF_EQ_AV 0 PrevPtr
        @MV2V DelPtr ProgramStart
    @ELSE
        @PUSHI NextPtr
        @PUSHI PrevPtr
        @ADD 2
        @POPS                # [PrevPtr+2] = NextPtr
    @ENDIF

    # ------------------------------------------
    # Fast exit: deleting last record
    # ------------------------------------------
    @IF_EQ_VV CurPtr ProgramEnd
        @IF_EQ_AV 0 PrevPtr
            # deleting the only record
            @MA2V 0 ProgramStart
            @MA2V 0 ProgramEnd
            @MV2V CurPtr FreePtr
            @PUSH 0
            @POPII FreePtr
            @MA2V 0 CurPtr
            @MA2V 0 PrevPtr            
            @JMP DLC_Exit
        @ELSE
            # deleting last but not first
            @MV2V PrevPtr ProgramEnd
            @MV2V CurPtr FreePtr
            @PUSH 0
            @POPII FreePtr
            @JMP DLC_Exit
        @ENDIF
    @ENDIF

    # ------------------------------------------
    # TextLen = strlen(DelPtr + 4)
    # ------------------------------------------
    @PUSHI DelPtr
    @ADD 4
    @CALL strlen
    @POPI TextLen

    # RecSize = 4 + TextLen + 1
    @PUSHI TextLen
    @ADD 5
    @POPI RecSize

    # ------------------------------------------
    # Compact memory
    #   SrcPtr  = DelPtr + RecSize
    #   MoveLen = FreePtr - SrcPtr
    # ------------------------------------------
    @PUSHI DelPtr
    @ADDI RecSize
    @POPI SrcPtr

    @PUSHI FreePtr
    @SUBI SrcPtr
    @POPI MoveLen

    @SafeMove(VVV) SrcPtr DelPtr MoveLen

    # ------------------------------------------
    # Fix FreePtr
    # ------------------------------------------
    @PUSHI FreePtr
    @SUBI RecSize
    @POPI FreePtr

    @PUSH 0
    @POPII FreePtr

    # ------------------------------------------
    # Fix ProgramEnd
    # ------------------------------------------
    @PUSHI ProgramEnd
    @IF_GT_V DelPtr
        @SUBI RecSize
        @POPI ProgramEnd
    @ELSE
        @POPNULL
    @ENDIF

    # ------------------------------------------
    # Fix all next-pointers
    # ------------------------------------------
    @MV2V ProgramStart ScanPtr

    @WHILE_NEQ_AV 0 ScanPtr
        # TmpPtr = [ScanPtr + 2]
        @PUSHI ScanPtr
        @ADD 2
        @PUSHS
        @POPI TmpPtr

        @PUSHI TmpPtr
        @IF_GT_V DelPtr
            @SUBI RecSize
            @POPI TmpPtr

            @PUSHI TmpPtr
            @PUSHI ScanPtr
            @ADD 2
            @POPS
        @ELSE
            @POPNULL
        @ENDIF

        @MV2V TmpPtr ScanPtr
    @ENDWHILE

:DLC_Exit


    @RestoreVar 10
    @RestoreVar 09
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

