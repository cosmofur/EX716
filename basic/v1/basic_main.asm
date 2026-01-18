I common.mc
L softstack.ld
L mul.ld
L string.ld
I basic_header.asm
I basic_diskos.asm    # Storage makes calls to simple disk os
I basic_storage.asm
I basic_support.asm
# basic/v1/basic_main.asm
# BASIC v1 – Editor Shell (ESX716 compliant)
#
# Responsibilities:
#   - Prompt
#   - Read full line via READSI
#   - Distinguish program lines vs commands
#   - Dispatch to storage layer
#


# Constants
=ARG_TYPE_NUM  0
=ARG_TYPE_STR 1
=ARG_TYPE_WORD 3
=ARG_WORDS  3
=LISTCODE 100
=NEWCODE 105
=QUITCODE 110
=RUNCODE 115
=SAVECODE 120
=LOADCODE 125



# --------------------------------------------------
# Input buffer (READSI requires full 256 bytes)
# --------------------------------------------------

=INPUTBUF_SIZE 256

:InputBuf
.ORG InputBuf+INPUTBUF_SIZE


# --------------------------------------------------
# BASIC entry point
# --------------------------------------------------

:BasicMain    
    @CALL InitProgramStorage

:MainLoop
    @PRT "> "

    # Read a full line (device handles editing & termination)
    @READS InputBuf

    # If empty line, reprompt
    @LOADBI InputBuf
    @IF_ZERO
        @POPNULL
        @JMP MainLoop
    @ENDIF
    @POPNULL
    @Call(A) ParseLineOrCommand InputBuf

    @JMP MainLoop


# --------------------------------------------------
# ParseLineOrCommand
# --------------------------------------------------
# IN:
#   TOS = pointer to input buffer
# --------------------------------------------------

:ParseLineOrCommand
@PUSHRETURN
    @LocalVar BufPtr 01
    @LocalVar Ch     02
    @POPI BufPtr

    @Call(v) ISNumeric BufPtr
    @IF_NOTZERO
        @Call(v) ParseLineNumber BufPtr
        @CALL InsertOrDeleteLine
    @ELSE
        @CALL ExecuteCommand
    @ENDIF
    @POPNULL
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


# --------------------------------------------------
# ParseLineNumber
# --------------------------------------------------
# IN:
#   BufPtr
# OUT (stack):
#   LineNum
#   TextPtr
#   TextLen
# --------------------------------------------------

:ParseLineNumber
@PUSHRETURN
    @LocalVar Acc     01
    @LocalVar Ptr     02
    @LocalVar Ch      03
    @LocalVar TextPtr 04
    @LocalVar TextLen 05

    @POPI BufPtr
    @MV2V BufPtr Ptr
    @Call(v) stoifirst Ptr
    @POPI Acc
    # Now scan forward to find first non space character

    @MV2V Ptr TextPtr   # Base value in case of early exit.
    @MA2V 0 TextLen
    @PUSH 0
    @WHILE_ZERO
       @POPNULL
       @INCI Ptr       
       @LOADBII Ptr
       @IF_EQ_A " \0"
          # Space means just continue.
          @POPNULL
          @PUSH 0
       @ELSE
          # Not space, check for digit.
          @POPNULL
          @Call(v) ISNumeric Ptr
          @IF_ZERO
             # Only get here is not space or digit
             @POPNULL
             @PUSH 1   # Break While Loop
          @ELSE
             # Was digit so just continue.
             @POPNULL
             @PUSH 0
          @ENDIF
       @ENDIF
    @ENDWHILE
    @POPNULL
    # Its possible that PTR is pointing at null EOS
    @LOADBII Ptr
    @IF_NOTZERO
       @Call(v) strlen Ptr
       @POPI TextLen
       @MV2V Ptr TextPtr
    @ENDIF
    @POPNULL

    # Return values on stack (order matters!)
    @PUSHI Acc
    @PUSHI TextPtr
    @PUSHI TextLen
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


# --------------------------------------------------
# ExecuteCommand
# --------------------------------------------------
# Simple v0 command dispatch
# --------------------------------------------------

:ExecuteCommand
@PUSHRETURN
    @LocalVar ArgCount  01
    @LocalVar ArgTblPtr 02
    @LocalVar StrPtr 03

    @Call(A) RmComments InputBuf   # Remove any Comments if any from InputBuf returns StrPtr
    @POPI StrPtr

    @Call(VAA) TokenizeCommand StrPtr PCArgTable 8

    @POPI ArgCount

    @MA2V PCArgTable ArgTblPtr

    @PUSHII ArgTblPtr
    @IF_NEQ_A ARG_TYPE_WORD
       @POPNULL
       @PRT "Error Not Valid KeyWord."
       @JMP PCExit
    @ENDIF
    @POPNULL
    
    # It KeyWord
    @INC2I ArgTblPtr
    @PUSHII ArgTblPtr   # Get ptr to String
    # Set ArgTblPtr to point to next table entry, ( skip past TailPtr for now )
    @PUSHI ArgTblPtr @ADD 4 @POPI ArgTblPtr

    # Call CmdTableLookup for key word.
    @PUSH CommandTable
    @CALL CmdTableLookup   # String Ptr still on Stack (Str,CommandTable)

    @SWITCH
    @CASE LISTCODE
       @POPNULL
       @CALL ListProgram
       @JMP PCExit
       @CBREAK
    @CASE NEWCODE
       @POPNULL
       @PRTLN "Initilize..."       
       @CALL InitProgramStorage
       @JMP PCExit
       @CBREAK
    @CASE QUITCODE
       @POPNULL
       @PRTLN "Bye..."
       @END
       @CBREAK
    @CASE RUNCODE
       @POPNULL
       @PRTNL "Run not yet ready."
       @JMP PCExit
       @CBREAK
    @CASE SAVECODE
       @POPNULL
       @PUSHI ArgCount
       @IF_NEQ_A 1
          @POPNULL
          @PRTLN "SAVE requires a filename. SAVE \"name\""
          @JMP PCExit
       @ENDIF

       # First (and only) argument must be string
       @PUSHII ArgTblPtr
       @IF_NEQ_A ARG_TYPE_STR
          @POPNULL
          @PRTLN "SAVE requires a quoted filename. SAVE \"name\""
          @JMP PCExit
       @ENDIF
       @POPNULL

       # Advance to string payload
       @INC2I ArgTblPtr
       @PUSHII ArgTblPtr      # push filename pointer

       # Call Save
       @CALL SAVEMEM

       @JMP PCExit
       @CBREAK

    @CASE LOADCODE
       @POPNULL
       @PUSHI ArgCount
       @IF_NEQ_A 1
          @POPNULL
          @PRTLN "LOAD requires a filename. LOAD \"name\""
          @JMP PCExit
       @ENDIF

       @PUSHII ArgTblPtr
       @IF_NEQ_A ARG_TYPE_STR
          @POPNULL
          @PRTLN "LOAD requires a quoted filename. LOAD \"name\""
          @JMP PCExit
       @ENDIF
       @POPNULL

       @INC2I ArgTblPtr
       @PUSHII ArgTblPtr      # filename pointer

       @CALL LOADMEM

       @JMP PCExit
       @CBREAK
    @CDEFAULT
       @PRTLN "Unknown Command"
       @POPNULL
       @JMP PCExit
       @CBREAK
    @ENDCASE
 :PCExit
    # Someday we may want to try continue parsing for multiple commands on a line, but not yet
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
 @POPRETURN
 @RET
:PCArgTable
0 0 0
0 0 0
0 0 0
0 0 0
0 0 0
0 0 0
0 0 0
0 0 0
:CommandTable
4 "LIST" LISTCODE
3 "NEW" NEWCODE
4 "QUIT" QUITCODE
3 "RUN" RUNCODE
4 "SAVE" SAVECODE
4 "LOAD" LOADCODE
0               # End Of Table
 
    
#--------------------------------------------------
# TokenizeCommand(StrPtr, ArgTablePtr, MaxArgs) : ArgCount
#--------------------------------------------------
:TokenizeCommand
@PUSHRETURN
    @LocalVar StrPtr      01
    @LocalVar ArgBase     02
    @LocalVar MaxArgs     03
    @LocalVar ArgCount    04
    @LocalVar HeadPtr     05
    @LocalVar TailPtr     06
    @LocalVar TmpPtr      07
    @LocalVar _I          08


    @POPI MaxArgs
    @POPI ArgBase
    @POPI StrPtr

    @MA2V 0 ArgCount

#--------------------------------------------------
# Parse loop
#--------------------------------------------------
:CP_Loop
    # Stop if ArgCount >= MaxArgs
    @PUSHI ArgCount
    @IF_GE_V MaxArgs
        @POPNULL
        @JMP CP_Done
    @ENDIF
    @POPNULL

    # NextToken(StrPtr)
    @PUSHI StrPtr
    @CALL NextToken

    @IF_ZERO
        @POPNULL
        @JMP CP_Done
    @ENDIF

    # Stack: HeadPtr TailPtr
    @POPI TailPtr    
    @POPI HeadPtr

    # Determine storage slot:
    # TmpPtr = ArgBase + ArgCount*3
    @Call(VA) MUL ArgCount ARG_WORDS
    @SHL               # Mul * 2, for bytes from words.
    @ADDI ArgBase
    @POPI TmpPtr

    # IsNumeric(HeadPtr)?
    @PUSHI HeadPtr
    @CALL ISNumeric
    @IF_NOTZERO
        # ---- numeric ----
        @POPNULL
        @PUSHI HeadPtr
        @CALL stoifirst

        # store Type
        @PUSH ARG_TYPE_NUM
        @PUSHI TmpPtr
        @POPS           
        # store Value
        @INC2I TmpPtr
        @PUSHI TmpPtr
        @POPS

    @ELSE
        # If not a number then it is a string, we have two types
        # Quoted strings, which can be longish, or WORDs which
        # are normally commands or keywords.
        @POPNULL
        @PUSHII HeadPtr @AND 0xff
        @IF_EQ_A "\"\0"
           @POPNULL
           # ---- string ----
           # store Type
           @PUSH ARG_TYPE_STR
           @PUSHI TmpPtr
           @POPS
        @ELSE
           @POPNULL
           # ---- WORD ----
           # store Type
           @PUSH ARG_TYPE_WORD
           @PUSHI TmpPtr
           @POPS           
        @ENDIF
        @INC2I TmpPtr
        # store Value = HeadPtr
        @PUSHI HeadPtr
        @PUSHI TmpPtr
        @POPS
    @ENDIF

    # store TailPtr
    @PUSHI TailPtr
    @INC2I TmpPtr
    @POPII TmpPtr


    # Advance StrPtr
    @MV2V TailPtr StrPtr

    @INCI ArgCount
    @JMP CP_Loop

#--------------------------------------------------
# Exit
#--------------------------------------------------
:CP_Done
    @PUSHI ArgCount

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


#-----------------------------------------------
# NextToken(StrPtr):[0|HeadPtr,TailPtr]
# NextToken skips white space, returns 0 if EOS is hit else returns Ptr to first char of word, and Ptr to just after word
# If First character of 'word' is quote, Moves to first real letter, TailPtr will point to after matching quote.
#-----------------------------------------------
:NextToken
@PUSHRETURN
   @LocalVar StrPtr 01
   @LocalVar HeadPtr 02
   @LocalVar TailPtr 03

   @POPI StrPtr
   @MV2V StrPtr HeadPtr      # Fall though values,
   @MV2V StrPtr TailPtr

   # Skip Leading Spaces
   @PUSHII StrPtr @AND 0xff
   @WHILE_EQ_A " \0"
      @POPNULL
      @INCI StrPtr
      @PUSHII StrPtr @AND 0xff
   @ENDWHILE
   @MV2V StrPtr HeadPtr
   @IF_ZERO
      # Hit EOF return 0
      @POPNULL
      @PUSH 0
      @JMP NWExit
   @ENDIF
   # Found valid first word, test if quoted string
   @IF_EQ_A "\"\0"
      @POPNULL
      @INCI StrPtr
      @PUSHII StrPtr @AND 0xff
      @WHILE_NEQ_A "\"\0"
         @POPNULL
         @INCI StrPtr
         @PUSHII StrPtr @AND 0xff
         @IF_ZERO
            # Handle case where no second quote found before EOS
            @POPNULL
            @MV2V StrPtr TailPtr
            @JMP No2ndQuoteExit
         @ENDIF
      @ENDWHILE
      @POPNULL
      #
      # StrPtr should be pointing at quote, so move it just past it.
      @INCI StrPtr
      @MV2V StrPtr TailPtr
      :No2ndQuoteExit
      # End of dealing with quoted strings.
   @ELSE
      # Was not a quoted string, nor end of string, so search until next white space (or EOS)
      @WHEN
      # Continue while char != ' ' AND char != 0
        @IF_EQ_A " \0"  @POPNULL  @PUSH 0  @ENDIF
        @IF_NEQ_A 0     @POPNULL  @PUSH 1  @ENDIF
        @DO_NOTZERO
           @POPNULL
           @INCI StrPtr
           @PUSHII StrPtr @AND 0xff
       @ENDWHEN
       @POPNULL
#       @INCI StrPtr
       
       @MV2V StrPtr TailPtr
   @ENDIF
   # Found a word, return Head and Tail Values
   @PUSHI HeadPtr
   @PUSHI TailPtr
:NWExit
   # If we jump to NWExit, we skip the Head/Tail PUSH and 0 should be alreayd on TOS
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET


#-----------------------------------------------
# TryNextNum(StrPtr): (Success[, Num, TailPtr])
#
# Returns:
#    Success !=0 then Num and TailPtr are available
#    Success ==0 then nothing else on stack.
#-----------------------------------------------
:TryNextNum
@PUSHRETURN
   @LocalVar StrPtr 01
   @LocalVar TailPtr 02

   @POPI StrPtr

   @Call(V) NextToken StrPtr

   @IF_ZERO
      @PUSH 0
      @JMP NWNExit
   @ENDIF
   @POPI TailPtr
   @POPI StrPtr

   @Call(V) ISNumeric StrPtr
   @IF_ZERO
      @POPNULL
      @PUSH 0
      @JMP NWNExit
   @ENDIF
   @POPNULL
   @PUSH 1  # Get this far then we're getting a valid number.
   @Call(V) stoifirst StrPtr
   # Num result on TOS
   @PUSHI TailPtr
   :NWNExit
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
         
#--------------------------------------------------
# RmComments(StrPtr):StrPtr
#--------------------------------------------------
:RmComments
@PUSHRETURN
   @LocalVar StrPtr 01
   @LocalVar QuoteFlag 02
   @LocalVar RetPtr 03

   @POPI StrPtr
   @MV2V StrPtr RetPtr
   @MA2V 0 QuoteFlag      # Toggle to deal with possible '#'s in quoted text.

   @PUSHII StrPtr @AND 0xff
   @WHILE_NOTZERO
      @IF_EQ_A "#\0"
         # Found Quote, but check to see if we're in a quoted string.
         @IF_EQ_AV 0 QuoteFlag
            # Not in Quote so this terminates string here.
            @POPNULL
            @PUSHII StrPtr
            @AND 0xff00    # Turn Low Byte into Null where '#' was
            @POPII StrPtr
            @PUSHI RetPtr  # Setup for Return.
            @JMP RMCExit
         @ELSE
            # We are in Quoted string so igore '#'
         @ENDIF
      @ELSE
         @IF_EQ_A "\"\0"
            # Found Quote toggle QuoteFlag
            @PUSHI QuoteFlag
            @INV
            @AND 1
            @POPI QuoteFlag
         @ENDIF
      @ENDIF
      @POPNULL
      @INCI StrPtr
      @PUSHII StrPtr @AND 0xff
    @ENDWHILE
    # No Comments, just return the string unchanged.
    @POPNULL
    @PUSHI RetPtr
 :RMCExit
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#---------------------------------------------------
# CmdTableLookup(StrPtr,Table)
#---------------------------------------------------
:CmdTableLookup
@PUSHRETURN
   @LocalVar StrPtr    01
   @LocalVar TablePtr  02
   @LocalVar StrLength 03

   @POPI TablePtr
   @POPI StrPtr

   @PUSHII TablePtr
   @WHILE_NOTZERO
      @POPI StrLength
      @INC2I TablePtr
      @Call(VVV) strncmp StrPtr TablePtr StrLength
      @IF_ZERO
         # Command ==s value
         @POPNULL
         @PUSHI TablePtr @ADDI StrLength @PUSHS
         @JMP CTLEXIT
      @ENDIF
      @POPNULL
      @PUSHI TablePtr @ADDI StrLength @ADD 2 @POPI TablePtr
      @PUSHII TablePtr
   @ENDWHILE
   @POPNULL
   # Exit this way means no match use -1 as failure flag
   @PUSH -1
   :CTLEXIT
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

   
         
       


# End of Code, start of data
:ENDOFCODE
=PROGRAM_MEMORY_START ENDOFCODE

# --------------------------------------------------
# Program entry point
# --------------------------------------------------
. BasicMain


