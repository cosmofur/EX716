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

    @MV2V ProgramStart Ptr

    @PUSH 0
    @WHILE_ZERO
        @LOADI Ptr
        @IF_ZERO
            @POPNULL
            @WHILEBREAK
        @ENDIF

        # Print line number
        @LOADII Ptr
        @PRTTOP
        @POPNULL
        @PRT " "

        # Print text (Ptr + 4)
        @LOADI Ptr
        @ADDI 4
	@POPI StrPtr
        @PRTSTRI StrPtr

        @PRTNL

        # Follow next_ptr
        @LOADI Ptr
        @ADDI 2
        @LOAD     # replace TOS with value at address[TOS]
        @STOREI Ptr
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
