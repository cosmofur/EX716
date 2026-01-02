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
:PROGRAM_MEMORY_START 0

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
            @PUSHI CurNum	    
            @IF_EQ_VV CurNum LineNum
	       @POPNULL
	       @MA2V 1 Found
               @PUSH 1   # Break Loop Found
            @ENDIF
	    @IF_GT_V LineNum
	       @POPNULL
	       @PUSH 1   # Break Loop Not Found
            @ENDIF
            @MV2V CurPtr PrevPtr
            @PUSHI CurPtr  # Next Address after CurPtr will be next line ptr
            @ADD 2
            @PUSHS
            @POPI CurPtr
	@ENDIF
    @ENDWHILE
    @POPNULL
    
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
    @ADD 2               # But more clear than PUSH PUSH POPS is POPII
    @POPII CurPtr         # This mean save NewPtr+2 at address CurPtr points at.


    @CALL CopyTextToNewLine

    @IF_EQ_AV 0 PrevPtr
        @PUSHI NewPtr
        @POPI ProgramStart
    @ELSE
        @PUSHI PrevPtr
        @ADD 2
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
        @ADD 2
        @PUSHS
        @POPI ProgramStart
    @ELSE
        @PUSHI CurPtr
        @ADD 2
        @PUSHS
        @POPI NextPtr

        @PUSHI PrevPtr
        @ADD 2
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
    @ADD LINE_HEADER_SIZE
    @POPI Dst

    @PUSH 0              # Add some test for While to chew
    @WHILE_ZERO
        @IF_EQ_AV 0 Len
            @PUSHI 0
            @STOREBII Dst
            @POPNULL
        @PUSH 1  # Break Loop
        @ELSE
        @LOADBII Src
        @POPI Ch
        @PUSHI Ch
        @STOREBII Dst

        @INCI Src       # Minor syntqax issues 'I' for variables
        @INCI Dst
        @DECI Len
     @ENDIF
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
    @ADD LINE_HEADER_SIZE
    @POPI Ptr

    @PUSH 1
    @WHILE_NOTZERO       # exit when Ch=null
        @POPNULL    
        @LOADBII Ptr
        @POPI Ch
        @INCI Ptr
        @PUSHI Ch
    @ENDWHILE
    @POPNULL
    @RestoreVar 02
    @RestoreVar 01
    
@RET

