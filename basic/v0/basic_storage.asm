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

# As it maybe usefull adding a STOREB
M STOREBII @AND 0xff @PUSHII %1 @AND 0xff00 @ORS @POPII %1
M LOADBII @PUSHII %1 @AND 0xff
M STOREBI @AND 0xff @PUSHI %1 @AND 0xff00 @ORS @POPII %1
M LOADBI @PUSHI %1 @AND 0xff

# --------------------------------------------------
# Global state
# --------------------------------------------------

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

    @PUSHI PROGRAM_MEMORY_START
    @POPI FreePtr
@RET


# --------------------------------------------------
# FindLine
# --------------------------------------------------
# IN:
#   LineNum (argument passed on stack)
#
# OUT (via variables):
#   Found   = 0/1
#   PrevPtr = previous line (0 if none)
#   CurPtr  = current line (match or insertion point)
# --------------------------------------------------

:FindLine
    @LocalVar LineNum 01
    @LocalVar CurPtr  02
    @LocalVar PrevPtr 03
    @LocalVar Found   04
    @LocalVar CurNum  05

    @POPI LineNum

    @PUSHI 0
    @POPI PrevPtr

    @PUSHI ProgramStart
    @POPI CurPtr

    @PUSHI 0
    @POPI Found

    @PUSH 0
    @WHILE_ZERO
        @IF_EQ_AV 0 CurPtr
            @BREAK
        @ENDIF

        @PUSHI CurPtr
        @LOAD
        @POPI CurNum

        @IF_EQ_VV CurNum LineNum
            @PUSHI 1
            @POPI Found
            @BREAK
        @ENDIF

        @IF_GT_VV CurNum LineNum
            @BREAK
        @ENDIF

        @MV2V CurPtr PrevPtr
        @PUSHI CurPtr
        @ADDI 2
        @LOAD
        @POPI CurPtr
    @ENDWHILE
    @POPNULL
    
    @PUSHI Found
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    
	
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

    @POPI TextLen
    @POPI TextPtr
    @POPI LineNum

    @PUSHI LineNum
    @CALL FindLine
    @POPI Found

    @IF_EQ_AV 0 TextLen
        @IF_NEQ_AV 0 Found
            @CALL DeleteLine
        @ENDIF
        @RET
    @ENDIF

    @IF_NEQ_AV 0 Found
        @CALL ReplaceLine
    @ELSE
        @CALL InsertLine
    @ENDIF

    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @POPRETURN    
@RET


# --------------------------------------------------
# InsertLine
# --------------------------------------------------

:InsertLine
    @LocalVar NewPtr 01
    @LocalVar CurPtr 02
    @LocalVar PrevPtr 03

    @MV2V FreePtr NewPtr

    @PUSHI NewPtr
    @PUSHI LineNum
    @POPS                 # I believe this is what you meant by @STORE
                          # POPS mean use TOS as address, and SFT as value
    @PUSHI NewPtr
    @ADDI 2               # But more clear than PUSH PUSH POPS is POPII
    @POPII CurPtr         # This mean save NewPtr+2 at address CurPtr points at.


    @CALL CopyTextToNewLine

    @IF_EQ_AV 0 PrevPtr
        @PUSHI NewPtr
        @POPI ProgramStart
    @ELSE
        @PUSHI PrevPtr
        @ADDI 2
        @PUSHI NewPtr
        @POPS
    @ENDIF

    @IF_EQ_AV 0 CurPtr
        @PUSHI NewPtr
        @POPI ProgramEnd
    @ENDIF

    @CALL AdvanceFreePtr
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01    
@RET


# --------------------------------------------------
# ReplaceLine
# --------------------------------------------------

:ReplaceLine
    @CALL DeleteLine
    @CALL InsertLine
@RET


# --------------------------------------------------
# DeleteLine
# --------------------------------------------------

:DeleteLine
    @LocalVar NextPtr 01

    @IF_EQ_AV 0 PrevPtr
        @PUSHI CurPtr
        @ADDI 2
        @LOAD
        @POPI ProgramStart
    @ELSE
        @PUSHI CurPtr
        @ADDI 2
        @LOAD
        @POPI NextPtr

        @PUSHI PrevPtr
        @ADDI 2
        @PUSHI NextPtr
        @POPS
    @ENDIF

    @IF_EQ_VV CurPtr ProgramEnd
        @MV2V PrevPtr ProgramEnd
    @ENDIF
    @RestoreVar 01
@RET


# --------------------------------------------------
# CopyTextToNewLine
# --------------------------------------------------

:CopyTextToNewLine
    @LocalVar Src 01
    @LocalVar Dst 02
    @LocalVar Len 03
    @LocalVar Ch  04

    @MV2V TextPtr Src
    @MV2V TextLen Len

    @MV2V NewPtr Dst
    @PUSHI Dst
    @ADDI LINE_HEADER_SIZE
    @POPI Dst

    @PUSH 0              # Add some test for While to chew
    @WHILE_ZERO
        @IF_EQ_AV 0 Len
            @PUSHI 0
            @STOREBII Dst
            @BREAK
        @ENDIF

        @LOADBII Src
        @POPI Ch
        @PUSHI Ch
        @STOREBII Dst

        @INCI Src       # Minor syntqax issues 'I' for variables
        @INCI Dst
        @DECI Len
    @ENDWHILE
    @POPNULL            # Get rid of zero
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@RET


# --------------------------------------------------
# AdvanceFreePtr
# --------------------------------------------------

:AdvanceFreePtr
    @LocalVar Ptr 01
    @LocalVar Ch  02

    @MV2V NewPtr Ptr
    @PUSHI Ptr
    @ADDI LINE_HEADER_SIZE
    @POPI Ptr

    @PUSH 0
    @WHILE_ZERO
        @LOADBII Ptr
        @POPI Ch
        @INCI Ptr
        @IF_NOTZERO
            @CONTINUE
        @ENDIF
        @BREAK
    @ENDWHILE
    @POPNULL
    @RestoreVar 02
    @RestoreVar 01
    
@RET

