I common.mc
I basic_common.h
L softstack.ld
D heapmgr.ld
L hexdump.ld
L mul.ld
L div.ld
D string.ld
#L diskos_stub.ld
D diskos.ld
D lmath.ld
I basic_header.asm
I basic_storage.asm
I basic_support.asm
I basic_eval.asm


# basic/v2/basic_main.asm
# BASIC v2 – Editor Shell (ESX716 compliant)
#
# Responsibilities:
#   - Prompt
#   - Read full line via READSI
#   - Distinguish program lines vs commands
#   - Dispatch to storage layer
#




# --------------------------------------------------
# BASIC entry point
# --------------------------------------------------

:BasicMain    
    @CALL SystemInit
    @CALL ProgramInit

:MainLoop
    @SRTP
    @IF_NOTZERO
       @POPNULL
       @StackDump
    @ELSE
       @POPNULL
    @ENDIF
    @PRT "> "

    # Read a full line (device handles editing & termination)
    @READSI InputBuf
    @PRTNL
    @PRTSI InputBuf @PRTNL
    # If empty line, reprompt
    @LOADBII InputBuf
    @IF_ZERO
        @POPNULL
        @JMP MainLoop
    @ENDIF
    @POPNULL
    @Call(V) FixUpCaseCmd InputBuf
    @Call(V) ParseLineOrCommand InputBuf    

    @JMP MainLoop

#---------------------------------------------------
# FixUpCaseCmd(InStr)
#---------------------------------------------------
 :FixUpCaseCmd
@PUSHRETURN
@Locals
    @Local InStr
    @Local LenStr
    @Local QuoteFlag
    @Local ESCFlag
    @Local Ch

    @POPI InStr

    @Call(V) strlen InStr
    @POPI LenStr

    @MA2V 0 QuoteFlag
    @MA2V 0 ESCFlag

    @PUSHI LenStr
    @WHILE_GT_A 0
       @POPNULL

       # Ch = low byte at InStr
       @PUSHII InStr
       @AND 0xff
       @POPI Ch

       # If Ch == '"' and previous char was not escape, toggle QuoteFlag.

       @IF_EQ_AV "\"\0" Ch
          @IF_EQ_AV 0 ESCFlag
              @PUSHI QuoteFlag
              @INV
              @AND 1
              @POPI QuoteFlag
          @ENDIF
       @ENDIF

       # Escape only applies from this char to the next char.
       # So compute the next ESCFlag from current Ch.
       @MA2V 0 ESCFlag

       @IF_EQ_AV "\\\0" Ch
          @POPNULL
          @MA2V 1 ESCFlag
       @ENDIF

       # Outside quotes, uppercase a-z.
       @IF_EQ_AV 0 QuoteFlag
          @PUSHI Ch
          @IF_GE_A "a\0" 
             @IF_LE_A "z\0"
                @SUB 32
                @POPI Ch

                # Store modified low byte, preserving existing high byte.
                @PUSHII InStr
                @AND 0xff00
                @ORI Ch
                @POPII InStr
             @ELSE
                @POPNULL
             @ENDIF
          @ELSE
             @POPNULL
          @ENDIF
       @ENDIF

       @INCI InStr
       @DECI LenStr
       @PUSHI LenStr
   @ENDWHILE
   @POPNULL
@EndLocals
@POPRETURN
@RET   

# --------------------------------------------------
# ParseLineOrCommand
# --------------------------------------------------
# IN:
#   TOS = pointer to input buffer
# --------------------------------------------------

:ParseLineOrCommand
@PUSHRETURN
@Locals
    @Local StrPtr
    @Local Ch
    @Local WorkBuf
    @Local LineNum
    @Local TextPtr
    @Local TextLen
    # No multiply for constants so use add three times to get sizeable buffer.

    @POPI StrPtr

    @Call(v) ISNumeric StrPtr
    @IF_NOTZERO
        #      Line data with Line Number
        @POPNULL
        @Call(VA) HeapNewObject RunTimeHeap TOLKBUF_SIZE @IF_ULT_A 100 @PRT "Memory Error" @POPNULL @JMP BasicPanic @ENDIF
        @POPI WorkBuf
        @Call(v) ParseLineNumber StrPtr  # return (linenum, textptr, textlen)        
        @POPI TextLen @POPI TextPtr @POPI LineNum
        @IF_NEQ_AV 0 TextLen
           # If there no content to the line, do not call TokenizeStr
           # TextLen of zero means delete that linenum
           @Call(vvAA) TokenizeStr TextPtr WorkBuf TOLKBUF_SIZE KeyWordTable
           @POPI TextLen
        @ENDIF        
        @Call(VVV) InsertOrDeleteLine LineNum WorkBuf TextLen
        @Call(VV) HeapDeleteObject RunTimeHeap WorkBuf @IF_GT_A 0 @PRT "Error Deleting Heap" @JMP BasicPanic @ENDIF @POPNULL
    @ELSE
        @POPNULL
        # Command Data, no line number
        @Call(VA) HeapNewObject RunTimeHeap TOLKBUF_SIZE @IF_ULT_A 100 @PRT "Memory Error" @POPNULL @JMP BasicPanic @ENDIF
        @POPI WorkBuf
        @Call(vvAA) TokenizeStr StrPtr WorkBuf TOLKBUF_SIZE CommandTable
        @POPI TextLen
        @Call(v) ExecuteCommand WorkBuf
        @Call(VV) HeapDeleteObject RunTimeHeap WorkBuf @IF_GT_A 0 @PRT "Error Deleting Heap" @JMP BasicPanic @ENDIF @POPNULL
    @ENDIF
@EndLocals
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
@Locals
    @Local Acc
    @Local Ptr
    @Local Ch
    @Local TextPtr
    @Local TextLen

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
       @LOADBII  Ptr
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
    @LOADBII  Ptr
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
@EndLocals
@POPRETURN
@RET


# --------------------------------------------------
# ExecuteCommand
# --------------------------------------------------
# Simple v0 command dispatch
# --------------------------------------------------

:ExecuteCommand
@PUSHRETURN
@Locals
    @Local BufPtr
    @Local FileName
    @Local StrLength
    @Local FileData
    @Local Index1

    @POPI BufPtr
    @WHEN
       @LOADBII BufPtr
       @IF_EQ_A EOL_TOKEN    # Loop until EOL code
          @POPNULL
          @PUSH 0
       @ELSE
          @PUSH 1
       @ENDIF
    @DO_NOTZERO
      @POPNULL
       @INCI BufPtr
       @SWITCH
       @CASE LISTCODE
          @POPNULL
          @CALL ListProgram
          @JMP PCExit
          @CBREAK
       @CASE NEWCODE
          @POPNULL
          @PRTLN "Initilize..."       
          @CALL ProgramInit
          @JMP PCExit
          @CBREAK
       @CASE QUITCODE
          @POPNULL
          @PRTLN "Bye..."
          @END
          @CBREAK
       @CASE RUNCODE
          @POPNULL
          @CALL BasicRun
          @JMP PCExit
          @CBREAK
       @CASE SAVECODE
          @POPNULL
          # Save must be followed by a Quoted Filename.
          @LOADBII BufPtr
          @IF_NEQ_A STRING_TOKEN
             @POPNULL
             @PRTLN "SAVE requires a quoted filename. SAVE \"name\""
             @JMP PCExit
          @ENDIF
          @POPNULL
          @Call(VA) ParseQuotedArgument BufPtr DIR_FN_SIZE
          @IF_NOTZERO
             @POPNULL
             @POPI2 BufPtr FileData
          @ELSE
             @Call(AA)  BasicRaiseError ERR_SYNTAX 0
          @ENDIF
          # Call Save
          @Call(V) SAVEMEM FileData
          @Call(VV) HeapDeleteObject RunTimeHeap FileData @IF_GT_A 0 @PRT "Error with filename." @JMP BasicPanic @ENDIF @POPNULL
          @JMP PCExit
          @CBREAK
       @CASE LOADCODE
          @POPNULL
          @LOADBII BufPtr
          @IF_NEQ_A STRING_TOKEN
             @POPNULL
             @PRTLN "LOAD requires a quoted filename. LOAD \"name\""
             @JMP PCExit
          @ENDIF
          @POPNULL
          @Call(VA) ParseQuotedArgument BufPtr DIR_FN_SIZE
          @IF_NOTZERO
             @POPNULL
             @POPI2 BufPtr FileData
          @ELSE
             @Call(AA)  BasicRaiseError ERR_SYNTAX 0
          @ENDIF
          # Call Load
          @Call(V) LOADMEM FileData
          @Call(VV) HeapDeleteObject RunTimeHeap FileData @IF_GT_A 0 @PRT "Error with filename." @JMP BasicPanic @ENDIF @POPNULL
          @PUSHI BufPtr @ADD StrLength @ADD 1 @POPI BufPtr  # Move to next word in command line.
          @JMP PCExit          
          @CBREAK
       @CASE TYPECODE
          @POPNULL
          @LOADBII BufPtr
          @IF_NEQ_A STRING_TOKEN
             @POPNULL
             @PRTLN "TYPE requires a quoted filename. TYPE \"name\""
             @JMP PCExit
          @ENDIF
          @POPNULL
          @Call(VA) ParseQuotedArgument BufPtr DIR_FN_SIZE
          @IF_NOTZERO
             @POPNULL
             @POPI2 BufPtr FileData
          @ELSE
             @Call(AA)  BasicRaiseError ERR_SYNTAX 0
          @ENDIF
          @POPNULL
          @Call(VA) ParseQuotedArgument BufPtr DIR_FN_SIZE
          @IF_NOTZERO
             @POPNULL
             @POPI2 BufPtr FileData
          @ELSE
             @Call(AA)  BasicRaiseError ERR_SYNTAX 0
          @ENDIF
          # Call Type
          @Call(V) TYPEFILE FileData
          @Call(VV) HeapDeleteObject RunTimeHeap FileData @IF_GT_A 0 @PRT "Error with filename." @JMP BasicPanic @ENDIF @POPNULL
          @PUSHI BufPtr @ADD StrLength @ADD 1 @POPI BufPtr  # Move to next word in command line.
          @JMP PCExit          
          @CBREAK
       @CASE DIRCODE
          @POPNULL
          @LOADBII BufPtr
          @IF_NEQ_A STRING_TOKEN
              # Default is wildcard pattern
              @Call(VV) HeapNewObject RunTimeHeap 10
              @POPI FileData
              @STRSETI "*\0" FileData
          @ELSE
              @Call(VA) ParseQuotedArgument BufPtr DIR_FN_SIZE
              @IF_NOTZERO
                  @POPNULL
                  @POPI2 BufPtr FileData
              @ELSE
                  @POPNULL
                  @Call(AA)  BasicRaiseError ERR_SYNTAX 0
              @ENDIF
         @ENDIF
         @Call(V)  DIRDISK FileData
         @Call(VV) HeapDeleteObject RunTimeHeap FileData @IF_GT_A 0 @PRT "Error with filename." @JMP BasicPanic @ENDIF @POPNULL
         @PUSHI BufPtr @ADD StrLength @ADD 1 @POPI BufPtr  # Move to next word in command line.
         @JMP PCExit
         @CBREAK
       @CASE DELETECODE
         @POPNULL
         @PUSHII BufPtr @AND 0xff
         @IF_NEQ_A STRING_TOKEN
             @PRTLN "DELETE requires filename."
             @JMP PCExit
         @ENDIF
         @POPNULL
         @Call(VA) ParseQuotedArgument BufPtr DIR_FN_SIZE
         @IF_NOTZERO
             @POPNULL
             @POPI2 BufPtr FileData
         @ELSE
             @Call(AA)  BasicRaiseError ERR_SYNTAX 0
         @ENDIF
         # Call Delete/Erase
         @Call(V) ERASEDISK FileData
         @Call(VV) HeapDeleteObject RunTimeHeap FileData
         @IF_GT_A 0
            @Call(AA) BasicRaiseError ERR_MEMORY 0
         @ENDIF
         @POPNULL
         @JMP PCExit
         @CBREAK
       @CASE MEM_CODE
         @POPNULL
         @PRT "Memory Report\n"
         @Call(V) HeapListMap RunTimeHeap
         @PRT "InputBuf: " @PRTHEXI InputBuf @PRT "\n"
         @PRT "VarFirstEntry: " @PRTHEXI VarFirstEntry @PRT "\n"
         @PRT "LineTableBase: " @PRTHEXI LineTableBase @PRT "\n"
         @StackDump
         @PRTNL
         @CBREAK
         
       @CASE PRINT_CODE
          @POPNULL

          @DECI BufPtr
          @Call(V) PrintCommand BufPtr
          @IF_ULT_A 100
             @PRTLN "Error:"
             @POPNULL
          @ELSE
             @POPI BufPtr
          @ENDIF
          @CBREAK
       @CASE LET_CODE
          @POPNULL
          @Call(V) ParseLET BufPtr
          @IF_ULT_A 100
             @Call(AA) BasicRaiseError ERR_SYNTAX 0
          @ELSE
             @POPI BufPtr
          @ENDIF
          @CBREAK
       @CDEFAULT
          @PRTLN "Unknown Command"
          @POPNULL           # Consume Selector
          @JMP PCExit
          @CBREAK
       @ENDCASE
   @ENDWHEN
   @POPNULL
 :PCExit
 @EndLocals
 @POPRETURN
 @RET

#-------------------------------
# MatchToken(PtrA,PtrB, Len):(0|1)
# Searches string for exact match of LEN characters between PtrA and  PtrB
#-------------------------------
:MatchToken
@PUSHRETURN
@Locals
   @Local PtrA
   @Local PtrB
   @Local Len

   @POPI Len
   @POPI PtrB
   @POPI PtrA

   @Call(VVV) strncmp PtrA PtrB Len
   # MatchToken return 1 for true and 0 for false, but strncmp returns 0 for 'equal' (like Z Flag)
   # So our logic requires a forced reversal

   @IF_ZERO
      @POPNULL
      @PUSH 1
   @ELSE
      @POPNULL
      @PUSH 0       # MatchToken returns 1 on true, and 0 on false.
   @ENDIF

@EndLocals
@POPRETURN
@RET

#-----------------------------------------------------
# NextToken(InPtr):(TokenType,StartPtr,EndPtr)
#------------------------------------------------------
:NextToken
@PUSHRETURN
@Locals
    @Local InPtr
    @Local CurPtr
    @Local TblPtr
    @Local StartPtr
    @Local Len
    @Local TOK
    @Local Match
    @Local CH

    @POPI InPtr
    @MV2V InPtr CurPtr

    #------------------------------------------
    # Skip whitespace
    #
    # while (*InPtr != 0 AND IsWhiteSpace(*InPtr))
    #    InPtr++
    #------------------------------------------
    @WHEN
        @LOADBII CurPtr @POPI CH
        @IF_EQ_AV 0 CH
            @PUSH 0
        @ELSE
            @Call(V) IsWhiteSpace CH
        @ENDIF
    @DO_NOTZERO
        @POPNULL
        @INCI CurPtr
    @ENDWHEN
    @POPNULL
    @LOADBII CurPtr @POPI CH
    @MV2V CurPtr StartPtr

    # Check for Line End
    @IF_EQ_AV 0 CH
        @PUSH 0
        @PUSH 0
        @PUSH 0
       @JMP NTReturnBlock
    @ENDIF
    # Check for quoted strings.
    @IF_EQ_AV "\"\0" CH
       # It is a string, look for matching end quote.
       @INCI CurPtr  # Add StartPtr here.       
       @LOADBII CurPtr
       @WHEN
          @IF_ZERO
              # Invalid end of line or end of string without ending quote
              @Call(AA) BasicRaiseError ERR_SYNTAX 0
          @ENDIF
          @IF_EQ_A "\"\0"
              # Reached End Of string
              @POPNULL      # Get rid of testing character
              @PUSH 0
          @ENDIF
       @DO_NOTZERO
          @POPNULL
          @INCI CurPtr
          @LOADBII CurPtr
       @ENDWHEN
       # When we reach he StartPtr is at first character of string
       # and CurPtr is at the ending quote
       @POPNULL
       # Prepare the results for exit.
       @PUSH STRING_TOKEN
       @PUSHI StartPtr
       @PUSHI CurPtr
       @ADD 1        # make next InPtr start after second quote
       @JMP NTReturnBlock
    @ENDIF
   
    # Now check for numbers

    @Call(v) ISNumeric CurPtr
    @IF_NOTZERO
       # Like string we'll just loop until end of number, but unlike string will not error if reach EOL
       @WHILE_NOTZERO
           @POPNULL
           @INCI CurPtr
           @Call(v) ISNumeric CurPtr
           @IF_ZERO
              @LOADBII CurPtr
              @IF_EQ_A ".\0"
                  # It's a float just allow it for now.
                  @POPNULL    #Remove  "."
                  @POPNULL    #Remove default 0
                  @PUSH 1
              @ELSE
                  @POPNULL    # Remove non numeric character
                  # Leave zero on stack
              @ENDIF
           @ENDIF
       @ENDWHILE
       @POPNULL
       # Prepare the results exit.
       @PUSH INT_TOKEN
       @PUSHI StartPtr
       @PUSHI CurPtr
       @JMP  NTReturnBlock
    @ELSE
       @POPNULL
    @ENDIF
         
    # Reach Here means search the TokenTable next

    @MA2V TokenTable TblPtr

    @LOADBII TblPtr
    @WHILE_NOTZERO
       @POPI Len
       @INCI TblPtr   # Get past LEN byte
       @Call(VVV) MatchToken TblPtr CurPtr Len
       @POPI Match
       @IF_EQ_AV 0 Match
          # No Match Found Move TblPtr to next entry.
          @PUSHI TblPtr     # Still pointing at entry LEN
          @ADDI Len         # End of string
          @ADD 2           # Past the TokenID
          @POPI TblPtr
          @LOADBII TblPtr
       @ELSE
          # A match was found.
          # Out InPtr needs to be updated to CurPtr+LEN
          # Fill at return form and jump to return block.
          @PUSHI TblPtr  @ADDI Len  @PUSHS  # Token ID
          @PUSHI StartPtr                           # Where it started
          @PUSHI CurPtr  @ADDI Len                  # New InPtr location
          @JMP NTReturnBlock  # (Match, CurPtr, NextInPtr)
       @ENDIF
    @ENDWHILE
    @POPNULL
    # We reach here means no matchs in TokenTable
    # Next option is user or funciton variable.
    @Call(V) ISAlphaNum CurPtr
    @WHILE_NOTZERO
       @POPNULL
       @INCI CurPtr
       @Call(V) ISAlphaNum CurPtr
    @ENDWHILE
    @POPNULL
    @LOADBII CurPtr
    @SWITCH
    @CASE "%\0" @INCI CurPtr @CBREAK
    @CASE "#\0" @INCI CurPtr @CBREAK
    @CASE "$\0" @INCI CurPtr @CBREAK
    @CDEFAULT @CBREAK
    @ENDCASE
    @POPNULL
    
    @PUSH VAR_TOKEN
    @PUSHI StartPtr
    @PUSHI CurPtr
:NTReturnBlock
@EndLocals
@POPRETURN
@RET


#--------------------------------------------------
# RmComments(StrPtr):StrPtr
#--------------------------------------------------
:RmComments
@PUSHRETURN
@Locals
   @Local StrPtr
   @Local QuoteFlag
   @Local RetPtr

   @POPI StrPtr
   @MV2V StrPtr RetPtr
   @MA2V 0 QuoteFlag      # Toggle to deal with possible '#'s in quoted text.

   @LOADBII StrPtr
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
      @LOADBII StrPtr
    @ENDWHILE
    # No Comments, just return the string unchanged.
    @POPNULL
    @PUSHI RetPtr
 :RMCExit
@EndLocals
@POPRETURN
@RET

#---------------------------------------------------
# CmdTableLookup(StrPtr,StrLen,Table)
#---------------------------------------------------
:CmdTableLookup
@PUSHRETURN
@Locals
   @Local StrPtr
   @Local TablePtr
   @Local StrLength
   @Local InStrLen

   @POPI TablePtr
   @POPI InStrLen
   @POPI StrPtr

   @PUSHII TablePtr
   @WHILE_NOTZERO
      @POPI StrLength
      @INC2I TablePtr
      @IF_EQ_VV StrLength InStrLen
         @Call(VVV) strncmp StrPtr TablePtr StrLength
         @IF_ZERO
            # Command ==s value
            @POPNULL
            @PUSHI TablePtr @ADDI StrLength @PUSHS
            @JMP CTLEXIT
         @ENDIF
         @POPNULL
      @ENDIF
      @PUSHI TablePtr @ADDI StrLength @ADD 2 @POPI TablePtr
      @PUSHII TablePtr
   @ENDWHILE
   @POPNULL
   # Exit this way means no match use -1 as failure flag
   @PUSH -1
   :CTLEXIT
@EndLocals
@POPRETURN
@RET
#--------------------------------------------------
# TokenizeStr(InPtr,OutPtr, MaxOutSize, TablePtr)
#--------------------------------------------------
:TokenizeStr
@PUSHRETURN
@Locals
   @Local InPtr
   @Local OutPtr
   @Local MaxOutSize
   @Local CurPtr
   @Local TokenType
   @Local StartPtr
   @Local EndPtr
   @Local Length
   @Local TokenCode
   @Local OutSize
   @Local TablePtr
   @Local FutureSize

   @POPI TablePtr
   @POPI MaxOutSize
   @POPI OutPtr
   @POPI InPtr

   @MA2V 0 OutSize
   @MV2V InPtr CurPtr
   @PUSH 0 @POPII OutPtr    # Null out OutPtr 1st word for clearity.
   @WHEN
      @Call(V) NextToken CurPtr
      @POPI EndPtr
      @POPI StartPtr
      @POPI TokenType
      @PUSHI TokenType    # TokenType of zero is EOS
   @DO_NOTZERO
      @POPNULL
      @PUSHI EndPtr       # Length=EndPtr-StartPtr
      @SUBI StartPtr
      @POPI Length      
      # Calculate future size to prevent overflow
      @PUSHI TokenType
      @SWITCH
      @CASE STRING_TOKEN
         @POPNULL
         @PUSH 2 @ADDI Length @POPI FutureSize
         @CBREAK
      @CASE INT_TOKEN
         @POPNULL
         @PUSH 2 @ADDI Length @POPI FutureSize
         @CBREAK
      @CASE VAR_TOKEN
         @POPNULL
         @MA2V -1 FutureSize   # Defer until after CmdTableLookup
         @CBREAK
      @CDEFAULT
         @POPNULL
         @MA2V 1 FutureSize
         @CBREAK
      @ENDCASE

      # String?
      @IF_EQ_AV STRING_TOKEN TokenType
         @PUSHI FutureSize
         @ADDI OutSize
         @IF_ULE_V MaxOutSize
            @POPNULL
            @Call(VVV) EmitByte OutPtr TokenType OutSize @POPI OutSize @POPI OutPtr
            @PUSHI Length
            @IF_GT_A 2
               @SUB 2     # Get rid of paired quotes.
            @ENDIF
            @POPI Length
            @INCI StartPtr
            @Call(VVV) EmitByte OutPtr Length OutSize @POPI OutSize @POPI OutPtr
            @Call(VVVV) EmitBlock OutPtr StartPtr Length OutSize @POPI OutSize @POPI OutPtr
            @JMP TK_CONTINUE
         @ELSE
            @POPNULL
            @Call(AA) BasicRaiseError ERR_SYNTAX 0         
         @ENDIF
      @ENDIF
      # Number?
      @PUSHI TokenType
      @IF_INRANGE_AB INT_TOKEN LONG_TOKEN     # All numeric types must in adjact and in this range.
         @POPNULL
         @PUSHI FutureSize
         @ADDI OutSize
         @IF_ULE_V MaxOutSize
            @POPNULL
            @Call(VVV) EmitByte OutPtr TokenType OutSize @POPI OutSize @POPI OutPtr
            @Call(VVV) EmitByte OutPtr Length OutSize @POPI OutSize @POPI OutPtr
            @Call(VVVV) EmitBlock OutPtr StartPtr Length OutSize @POPI OutSize @POPI OutPtr
            @JMP TK_CONTINUE
         @ELSE
            @POPNULL
            @Call(AA) BasicRaiseError ERR_SYNTAX 0
         @ENDIF
      @ELSE
         @POPNULL
      @ENDIF
      # Identifier/Keyword ?
      @IF_EQ_AV VAR_TOKEN TokenType         
         @Call(VVV) CmdTableLookup StartPtr Length TablePtr
         @POPI TokenCode
         @PUSHI TokenCode
         @IF_NEQ_A -1
            @MA2V 1 FutureSize
         @ELSE
            @PUSH 2
            @ADDI Length
            @POPI FutureSize
         @ENDIF
         @POPNULL
         @PUSHI FutureSize
         @ADDI OutSize         
         @IF_ULE_V MaxOutSize
            @POPNULL
            @PUSHI TokenCode
            @IF_NEQ_A -1
               @POPI TokenCode
               @Call(VVV) EmitByte OutPtr TokenCode OutSize @POPI OutSize @POPI OutPtr
            @ELSE
               @POPNULL
               @Call(VAV) EmitByte OutPtr VAR_TOKEN OutSize @POPI OutSize @POPI OutPtr
               @Call(VVV) EmitByte OutPtr Length OutSize @POPI OutSize @POPI OutPtr
               @Call(VVVV) EmitBlock OutPtr StartPtr Length OutSize @POPI OutSize @POPI OutPtr
            @ENDIF
            @JMP TK_CONTINUE
         @ELSE
            @POPNULL
            @Call(AA) BasicRaiseError ERR_SYNTAX 0
         @ENDIF
      @ENDIF
      # Operator or single char token, fallthough default
      @Call(VVV) EmitByte OutPtr TokenType OutSize @POPI OutSize @POPI OutPtr
   :TK_CONTINUE
 #--------------------------------------------
# DEBUG: raw token slice from input
#--------------------------------------------
   
   @MV2V EndPtr CurPtr
   @ENDWHEN
   @POPNULL
   
   @Call(VAV) EmitByte OutPtr EOL_TOKEN OutSize @POPI OutSize @POPI OutPtr
   @PUSHI OutSize
@EndLocals

@POPRETURN
@RET
####
#-----------------------------
# BasicPanic
# catastrophic, recover to command line
#-----------------------------
:BasicPanic
   @MA2V RET_ERROR RET_CODE
   @MA2V ERR_INTERNAL_FAULT RET_ERRTYPE
   @MV2V BPC RET_ERRLINE
   @POPI RET_ERRINFO    # Top of stack will have calling address
   @SCLR
   @MV2V __SS_TOP __SS_SP
   @INC2I __SS_SP
   @JMP MainLoop        # JMPS rather than call as no reason to return here.
#-------------------------------------
# BasicRaiseError(ERR_TYPE, ERR_DOMAIN)
# Put system into error state allow roll back.
#-------------------------------------
:BasicRaiseError
@PRT "ERROR AT ADDRESS: " @PRTHEXTOP @PRTNL
@PUSHRETURN
   @LocalVar ERR_TYPE 01
   @LocalVar ERR_DOMAIN 02

   @POPI ERR_DOMAIN
   @POPI ERR_TYPE
   @PRT "ERROR CODE: " @PRTI ERR_TYPE
   
   @IF_NEQ_AV 0 LRL
      @PRT "Line Number: " @PUSHII LRL @PRTTOP @POPNULL
   @ENDIF
   @PRTNL   
   @StackDump
   @MA2V RET_ERROR RET_CODE
   @PUSHI ERR_TYPE
   @SWITCH
   @CASE ERR_NONE         @PRTLN "? Unknown Error:"     @CBREAK
   @CASE ERR_SYNTAX       @PRTLN "? Syntax Error:"       @CBREAK
   @CASE ERR_DIV_ZERO     @PRTLN "? Divide by Zero:"     @CBREAK
   @CASE ERR_UNDEF_VAR    @PRTLN "? Undefined Variable:" @CBREAK
   @CASE ERR_BAD_GOTO     @PRTLN "? Invalid GOTO:"       @CBREAK
   @CASE ERR_BAD_RETURN   @PRTLN "? Invalid Return:"     @CBREAK
   @CASE ERR_OUT_RANGE    @PRTLN "? Out of Range:"       @CBREAK
   @CASE ERR_MEMORY       @PRTLN "? Memory Error:"       @CBREAK
   @CASE ERR_STACK_OVERFLOW @PRTLN "? Stack Overflow:"    @CBREAK
   @CASE ERR_BAD_NEXT     @PRTLN "? NEXT Without FOR:"  @CBREAK
   @CASE ERR_STRING_SPACE @PRTLN "? String Space Error:" @CBREAK
   @CASE ERR_NO_FILE_HANDLES @PRTLN "? Filesystm out of handles :"     @CBREAK
   @CASE ERR_FILE_NOT_FOUND @PRTLN "? File Not Found :"     @CBREAK
   @CASE ERR_FILE_OPEN_FAIL  @PRTLN "? Open File Error :"     @CBREAK
   @CASE ERR_FILE_READ_FAIL @PRTLN "? Read File Error:"     @CBREAK
   @CASE ERR_FILE_WRITE_FAIL @PRTLN "? Write File Error :"     @CBREAK
   @CASE ERR_INTERNAL_FAULT @PRTLN "? Internal Fault :"     @CBREAK
   @CASE ERR_UNDEF_LINE @PRTLN "? Undefined Line:"          @CBREAK
   @CDEFAULT
         @PRTLN "? Unknown Error:"
         @CBREAK
   @ENDCASE
   @POPNULL
      

   @IF_EQ_AV 1 RUN_ACTIVE
      @MV2V BPC RET_ERRLINE
   @ELSE
      @MA2V 0 RET_ERRLINE
   @ENDIF
   @RestoreVar 02
   @RestoreVar 01   
   @POPRETURN
   @CALL BasicPanic
@RET

#--------------------------
# CodeToString(InCode)
#-------------------------
:CodeToString
@PUSHRETURN
@Locals
    @Local InCode
    @Local TablePtr
    @Local StrSize
    @Local Index
    @Local CharHold

    @AND 0xff
    @DUP
    @POPI InCode
    @IF_LT_A 0x7f
       @PRT "\"" @PRTCHI InCode @PRT "\""
       @POPNULL
    @ELSE
       @POPNULL
       @MA2V KeyWordTable TablePtr
       @PUSHII TablePtr
       @WHILE_NOTZERO
           @POPI StrSize
           @PUSHI TablePtr
           @ADDI StrSize
           @ADD 2
           @PUSHS
           @IF_EQ_V InCode
              @POPNULL
              @INC2I TablePtr
              @PRT " " 
              @ForIA2V Index 0 StrSize
                 @PUSHI TablePtr
                 @ADDI Index
                 @PUSHS
                 @AND 0xff
                 @POPI CharHold
                 @PRTCHI CharHold
              @Next Index
              @PRT " "
              @JMP CTSBreakWhile
           @ENDIF
           @POPNULL
           @PUSHI TablePtr
           @ADDI StrSize
           @ADD 4
           @POPI TablePtr
           @PUSHII TablePtr
       @ENDWHILE
       @POPNULL
    @ENDIF
    :CTSBreakWhile
@EndLocals
@POPRETURN
@RET
#----------------------------------------
# BasicCheckBreak():BreakFlag
#----------------------------------------
:BasicCheckBreak
@PUSHRETURN

   @INCI BreakPollCounter
   @PUSHI BreakPollCounter @ANDI BreakPollMask
   @IF_ZERO
      @LocalVar CH 01
      @READCNW CH
      @PUSHI CH
      @IF_NOTZERO
         @AND 0xff
         @IF_EQ_A "Q\0"
            @MA2V 1 BreakFlag
         @ENDIF
      @ENDIF
      @POPNULL
      @RestoreVar 01
   @ENDIF
   @POPNULL

   @PUSHI BreakFlag
@POPRETURN
@RET



    
# End of Code, start of data
:ENDOFCODE
=PROGRAM_MEMORY_START ENDOFCODE

# --------------------------------------------------
# Program entry point
# --------------------------------------------------
.ORG BasicMain
M SIZESINCECOMMENT basic_main.h
@SIZESINCE  
