I common.mc
L string.ld
#
#
# basic/v0/basic_support.asm
# BASIC v0 – Support Functions
#
# Purpose:
#   - BASIC-specific helpers that do not belong in libraries
#   - Resolve editor-shell dispatch targets
#
# This file intentionally avoids:
#   - String algorithms (use string.ld)
#   - Tokenization
#   - Program execution
#
# Included by basic_main.asm after string.ld and basic_storage.asm


# --------------------------------------------------
# ListProgram
# --------------------------------------------------
# Walk BASIC program storage and print each line
#
# Uses program storage invariants:
#   WORD line_number
#   WORD next_ptr
#   BYTE text...
#   BYTE 0
# --------------------------------------------------

:ListProgram
    @LocalVar Ptr 01
    @LocalVar StrPtr 02

    @PRT "Program Memory: " @PRTHEXI ProgramStart @PRT "-" @PRTHEXI ProgramEnd @PRTNL
    @MV2V ProgramStart Ptr
    @PUSH 0
    @WHILE_ZERO
    
        @PUSHI Ptr
        @IF_ZERO
            @POPNULL
            @WHILEBREAK
        @ENDIF
        @POPNULL

        @PRTHEXI Ptr @PRT ">"

        # Print line number
        @PUSHII Ptr
        @PRTTOP
        @POPNULL
        @PRT " ["

       # For Debug also print the Hex of the Next Ptr
        @PUSHI Ptr @ADD 2 @PUSHS
        @PRTHEXTOP
        @POPNULL
        @PRT "] "

        # Print text (Ptr + 4)
        @PUSHI Ptr
        @ADD 4
	@POPI StrPtr
        @PRTSTRI StrPtr

        @PRTNL

        # Follow next_ptr
        @PUSHI Ptr
        @ADD 2
        @PUSHS
        @POPI Ptr

    @ENDWHILE
    @POPNULL
    @RestoreVar 02
    @RestoreVar 01
@RET


# --------------------------------------------------
# RunStub
# --------------------------------------------------
# Placeholder for BASIC execution engine
# --------------------------------------------------

:RunStub
    @PRTLN "RUN: NOT IMPLEMENTED"
@RET
