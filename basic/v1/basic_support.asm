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

    @PRT "Program Memory: "
    @PUSHI FirstLinePtr @PRTHEXTOP @PRT "-" @ADDI ProgramUsed @PRTHEXTOP @POPNULL
    @PRT " Used: " @PRTHEXI ProgramUsed @PRTNL

@PRTNL

    @PUSHI ProgramArenaBase @ADD 2 @PUSHS
    @POPI Ptr
    @PUSH 0
    @WHILE_ZERO    
        @IF_EQ_AV 0 Ptr
            @WHILEBREAK
        @ENDIF

        @PRTHEXI Ptr @PRT ">"

        # Print line number
        @FETCH_REL Ptr
        @PRTTOP
        @POPNULL
        @PRT " ["

       # For Debug also print the Hex of the Next Ptr
        @FETCH_REL_OFF Ptr 2
        @PRTHEXTOP
        @POPNULL
        @PRT "] "

        # Print text (Ptr + 4)
        @PUSH_REL_TO_ABS Ptr
        @ADD 4
	@POPI StrPtr
        @PRTSTRI StrPtr

        @PRTNL

        # Follow next_ptr
        @FETCH_REL_OFF Ptr 2
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

#---------------------------------------------------
# LineCountCode
# Returns number of lines currently in memory.
#---------------------------------------------------
:LineCountCode
@PUSHRETURN
   @LocalVar Ptr 01
   @LocalVar LineCount 02
   
   @MA2V 0 LineCount
   @MV2V FirstLinePtr Ptr
   @PUSH 0
   @WHILE_ZERO
       @FETCH_REL Ptr
       @IF_ZERO
          @POPNULL
          @WHILEBREAK
       @ENDIF
       @POPNULL
       @INCI LineCount
       @FETCH_REL_OFF Ptr 2
       @POPI Ptr
   @ENDWHILE
   @POPNULL
   @PUSHI LineCount
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#-----------------------------------
# CleanQuotes(StrPtr):StrPtr
# Moves StrPtr to just past first quote if any
# then turns the second quote, if any, into NULL
#-----------------------------------
:CleanQuotes
@PUSHRETURN
    @LocalVar StrPtr 01
    @LocalVar CharPtr 02
    @LocalVar StrLen 03
    @LocalVar Index 04
    
    @POPI StrPtr

    # IF 1st char is quote, inc StrPtr past quote
    @PUSHII StrPtr @AND 0xff
    @IF_EQ_A "\"\0"
       @INCI StrPtr
    @ENDIF
    @POPNULL

    @Call(V) strlen StrPtr
    @POPI StrLen
    @MA2V 0 Index

    @MV2V StrPtr CharPtr

    # Change any remaining quotes with null
    @ForIA2V Index 0 StrLen
       @PUSHII CharPtr
       @DUP
       @AND 0xff
       @IF_EQ_A "\"\0"
          # Is a quote, replace with null
          @POPNULL
          @AND 0xff00    # Keep high byte
          @POPII CharPtr
       @ELSE
          @POPNULL
          @POPNULL
       @ENDIF
       @INCI CharPtr
    @Next Index
    #
    @PUSHI StrPtr
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

    
          

    
