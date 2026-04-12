M USE_ONLY 1
I common.mc
I basic_common.h
L hexdump.ld
L softstack.ld
L string.ld
L diskos.ld
L lmath.ld
L mul.ld
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
    @StackDump
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
    @LocalVar StrPtr 01
    @LocalVar Ch     02
    @LocalVar WorkBuf 03
    @LocalVar LineNum 04
    @LocalVar TextPtr 05
    @LocalVar TextLen 06
    # No multiply for constants so use add three times to get sizeable buffer.

    @POPI StrPtr
#    @Call(A) RmComments StrPtr
#    @POPI StrPtr

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
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
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
    @LocalVar BufPtr 01
    @LocalVar FileName 02
    @LocalVar StrLength 03
    @LocalVar FileData 04
    @LocalVar Index1 05

    @POPI BufPtr
    @WHEN
       @PUSHII BufPtr @AND 0xff
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
          @PUSHII BufPtr @AND 0xff
          @IF_NEQ_A STRING_TOKEN
             @POPNULL
             @PRTLN "SAVE requires a quoted filename. SAVE \"name\""
             @JMP PCExit
          @ENDIF
          @POPNULL
          @INCI BufPtr          
          @PUSHII BufPtr @AND 0xff      # Get Length.
          @POPI StrLength
          @INCI StrLength               # Add a spot for the Null
          @Call(VV) HeapNewObject RunTimeHeap StrLength
          @POPI FileData
          @DECI StrLength               # Return StrLength to real length
          @INCI BufPtr                  # Point to first letter in string          
          @ForIA2V Index1 0 StrLength
              # FileData[I]=BufPtr[I]&0xff
              @PUSHI BufPtr @ADDI Index1
              @PUSHS
              @AND 0xff                 # Want just byte, but also get null term for free
              @PUSHI FileData @ADDI Index1
              @POPS
          @Next Index1          
          # Call Save
          @Call(V) SAVEMEM FileData
          @Call(VV) HeapDeleteObject RunTimeHeap FileData @IF_GT_A 0 @PRT "Error with filename." @JMP BasicPanic @ENDIF @POPNULL
          @JMP PCExit
          @CBREAK
       @CASE LOADCODE
          @POPNULL
          @PUSHII BufPtr @AND 0xff
          @IF_NEQ_A STRING_TOKEN
             @POPNULL
             @PRTLN "LOAD requires a quoted filename. SAVE \"name\""
             @JMP PCExit
          @ENDIF
          @POPNULL
          @INCI BufPtr          
          @PUSHII BufPtr @AND 0xff      # Get Length.
          @POPI StrLength
          @INCI StrLength               # Add a spot for the Null
          @Call(VV) HeapNewObject RunTimeHeap StrLength
          @POPI FileData
          @DECI StrLength               # Return StrLength to real length
          @INCI BufPtr                  # Point to first letter in string          
          @ForIA2V Index1 0 StrLength
              # FileData[I]=BufPtr[I]&0xff
              @PUSHI BufPtr @ADDI Index1
              @PUSHS
              @AND 0xff                 # Want just byte, but also get null term for free
              @PUSHI FileData @ADDI Index1
              @POPS
          @Next Index1          
          # Call Load
          @Call(V) LOADMEM FileData
          @Call(VV) HeapDeleteObject RunTimeHeap FileData @IF_GT_A 0 @PRT "Error with filename." @JMP BasicPanic @ENDIF @POPNULL
          @PUSHI BufPtr @ADD StrLength @ADD 1 @POPI BufPtr  # Move to next word in command line.
          @JMP PCExit          
          @CBREAK
       @CASE PRINTCMDCODE
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
       @CDEFAULT
          @PRTLN "Unknown Command"
          @POPNULL           # Consume Selector
          @JMP PCExit
          @CBREAK
       @ENDCASE
   @ENDWHEN
   @POPNULL
 :PCExit
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
 @POPRETURN
 @RET
 
    
#--------------------------------------------------
# NextToken(InPtr):(TokenType,StartPtr,EndPtr,NextPtr)
#
# TokenType:
#   0 = EOS
#   VAR_TOKEN
#   INT_TOKEN
#   FLOAT_TOKEN
#   LONG_TOKEN
#   STRING_TOKEN
#   ASCII operator OR special operator token
#
# StartPtr = first character of token
# EndPtr   = first character AFTER token
# NextPtr  = same as EndPtr (convenience)
#
# Uses WHEN loops for predicate-driven scanning.
#--------------------------------------------------

:NextToken
@PUSHRETURN
    @LocalVar InPtr     01
    @LocalVar CH        02
    @LocalVar CH2       03
    @LocalVar StartPtr  04
    @LocalVar EndPtr    05
    @LocalVar NextPtr   06
    @LocalVar TokenType 07
    @LocalVar SeenDot   08
    @LocalVar AlphaFlag 09
    #------------------------------------------
    # Initialize
    #------------------------------------------
    @POPI InPtr

    @MV2V InPtr StartPtr
    @MV2V InPtr EndPtr
    @MV2V InPtr NextPtr
    @MA2V 0 TokenType

    #------------------------------------------
    # Skip whitespace
    #
    # while (*InPtr != 0 AND IsWhiteSpace(*InPtr))
    #    InPtr++
    #------------------------------------------
    @WHEN
        @PUSHII InPtr @AND 0xff @POPI CH
        @IF_EQ_AV 0 CH
            @PUSH 0
        @ELSE
            @Call(V) IsWhiteSpace CH
        @ENDIF
    @DO_NOTZERO
        @POPNULL
        @INCI InPtr
    @ENDWHEN
    @POPNULL
    @MV2V InPtr StartPtr

    #------------------------------------------
    # Check for EOS
    #------------------------------------------

    @PUSHII InPtr @AND 0xff @POPI CH
    @IF_EQ_AV 0 CH
        @MA2V 0 TokenType
        @JMP NT_DONE
    @ENDIF

    #==========================================
    # STRING TOKEN
    #
    # Format: " ... "
    #------------------------------------------
    @IF_EQ_AV "\"\0" CH    
        @INCI InPtr    # skip opening quote
        @MV2V InPtr StartPtr        
        @WHEN
            @PUSHII InPtr @AND 0xff @POPI CH
            @IF_EQ_AV 0 CH
                @PUSH 0
            @ELSE
                @IF_EQ_AV "\"\0" CH
                    @PUSH 0
                @ELSE
                    @PUSH 1
                @ENDIF
            @ENDIF
        @DO_NOTZERO
            @POPNULL
            @INCI InPtr
        @ENDWHEN
        @POPNULL
        # For strings EndPtr and NextPtr differ as the trailing quote needs to be skipped.
        @MV2V InPtr EndPtr
        @PUSHI InPtr @ADD 1 @POPI NextPtr
        @MA2V STRING_TOKEN TokenType
        @JMP NT_DONE
    @ENDIF
    #==========================================
    # NUMBER TOKEN
    #
    # Format: digit+ [. digit+]
    #
    # Float support ready
    #------------------------------------------
    @IF_EQ_AV "-\0" CH
       @PUSH 1               # If first character is '-' then still a digit, but only for first character.
    @ELSE
       @Call(V) IsDigit CH   # Handle test for 0-9
    @ENDIF
    @IF_NOTZERO
        @POPNULL
        @MA2V 0 SeenDot
        @MV2V InPtr StartPtr        
        @WHEN
            @PUSHII InPtr @AND 0xff @POPI CH
            @Call(V) IsDigit CH
            @IF_NOTZERO
                @POPNULL
                @PUSH 1
            @ELSE
                @POPNULL
                @IF_EQ_AV ".\0" CH
                    @IF_EQ_AV 0 SeenDot
                        @MA2V 1 SeenDot
                        @PUSH 1
                    @ELSE
                        @PUSH 0
                    @ENDIF
                @ELSE
                    @PUSH 0
                @ENDIF
            @ENDIF
        @DO_NOTZERO
            @POPNULL
            @INCI InPtr
        @ENDWHEN
        @POPNULL
        @IF_EQ_AV 1 SeenDot
           @MA2V FLOAT_TOKEN TokenType
        @ELSE
           @MA2V INT_TOKEN TokenType
        @ENDIF
        @JMP NT_SET_END
    @ELSE
        @POPNULL
    @ENDIF
    #==========================================
    # IDENTIFIER OR KEYWORD
    #
    # Format:
    #    Letter or _
    #    followed by Letter|Digit|_
    #------------------------------------------
    @Call(V) IsLetter CH
    @POPI AlphaFlag
    @IF_EQ_AV "_\0" CH
        @MA2V 1 AlphaFlag
    @ENDIF
    @IF_EQ_AV 1 AlphaFlag
        @WHEN
            @PUSHII InPtr @AND 0xff @POPI CH
            @Call(V) IsIdentChar CH
        @DO_NOTZERO
            @POPNULL
            @INCI InPtr
        @ENDWHEN
        @POPNULL
        @MA2V VAR_TOKEN TokenType
        @JMP NT_SET_END
    @ENDIF
    #==========================================
    # OPERATOR TOKEN
    #
    # Handles:
    #   + - * / = < > ( ) , ; :
    #   <= >= <>
    #------------------------------------------
    @Call(V) IsOperator CH
    @IF_NOTZERO
        @POPNULL    
        @MV2V CH TokenType     # default: ASCII operator
        # Peek next character without consuming
        @MV2V InPtr StartPtr        
        @PUSHI InPtr @ADD 1 @PUSHS @AND 0xff @POPI CH2
        @PUSHI CH
        @SWITCH
         # Test first character, if one that MIGHT be followed by a second char, do the extra tests
         # else just use the first character ASCII as the token to use.
         @CASE "<\0"
             @POPNULL
             @IF_EQ_AV "=\0" CH2
                 @INCI InPtr
                 @MA2V LE_TOKEN TokenType
             @ENDIF
             @IF_EQ_AV ">\0" CH2
                 @INCI InPtr
                 @MA2V NE_TOKEN TokenType
             @ENDIF
             @CBREAK
         @CASE ">\0"
             @POPNULL
             @IF_EQ_AV "=\0" CH2
                 @INCI InPtr
                 @MA2V GE_TOKEN TokenType
             @ENDIF
             @CBREAK
         @CASE "=\0"
             @POPNULL
             @IF_EQ_AV "<\0" CH2
                @INCI InPtr
                @MA2V LE_TOKEN TokenType
             @ENDIF
             @IF_EQ_AV ">\0" CH2
                @INCI InPtr
                @MA2V GE_TOKEN TokenType
             @ENDIF
             @CBREAK
         @CDEFAULT
             @POPNULL
             @CBREAK
        @ENDCASE
        
        @INCI InPtr
        @JMP NT_SET_END
    @ELSE
        @POPNULL
    @ENDIF
    
    #==========================================
    # UNKNOWN CHARACTER
    #
    # Treat as single-character token
    #------------------------------------------
    @MV2V CH TokenType
    @INCI InPtr
#------------------------------------------
# Finalize token boundaries
#------------------------------------------
:NT_SET_END
    @MV2V InPtr EndPtr
    @MV2V InPtr NextPtr
#------------------------------------------
# Return values
#------------------------------------------
:NT_DONE

    @PUSHI TokenType
    @PUSHI StartPtr
    @PUSHI EndPtr
    @PUSHI NextPtr

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
# CmdTableLookup(StrPtr,StrLen,Table)
#---------------------------------------------------
:CmdTableLookup
@PUSHRETURN
   @LocalVar StrPtr    01
   @LocalVar TablePtr  02
   @LocalVar StrLength 03
   @LocalVar InStrLen  04

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
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#--------------------------------------------------
# TokenizeStr(InPtr,OutPtr, MaxOutSize, TablePtr)
#--------------------------------------------------
:TokenizeStr
@PUSHRETURN
   @LocalVar InPtr      01
   @LocalVar OutPtr     02
   @LocalVar MaxOutSize 03
   @LocalVar CurPtr     04
   @LocalVar TokenType  05
   @LocalVar StartPtr   06
   @LocalVar EndPtr     07
   @LocalVar NextPtr    08
   @LocalVar Length     09
   @LocalVar TokenCode  10
   @LocalVar OutSize    11
   @LocalVar TablePtr   12
   @LocalVar FutureSize 13

   @POPI TablePtr
   @POPI MaxOutSize
   @POPI OutPtr
   @POPI InPtr

   @MA2V 0 OutSize
   @MV2V InPtr CurPtr
   @PUSH 0 @POPII OutPtr    # Null out OutPtr 1st word for clearity.
   @WHEN
      @Call(V) NextToken CurPtr
      @POPI NextPtr
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
               @Call(VAV) EmitByte ( OutPtr VAR_TOKEN OutSize ) @POPI OutSize @POPI OutPtr
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
   
   @MV2V NextPtr CurPtr
   @ENDWHEN
   @POPNULL
   
   @Call(VAV) EmitByte OutPtr EOL_TOKEN OutSize @POPI OutSize @POPI OutPtr
   @PUSHI OutSize
   @RestoreVar 13
   @RestoreVar 12
   @RestoreVar 11
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
   @CASE ERR_STRING_SPACE @PRTLN "? String Space Error:" @CBREAK
   @CASE ERR_NO_FILE_HANDLES @PRTLN "? Filesystm out of handles :"     @CBREAK
   @CASE ERR_FILE_NOT_FOUND @PRTLN "? File Not Found :"     @CBREAK
   @CASE ERR_FILE_OPEN_FAIL  @PRTLN "? Open File Error :"     @CBREAK
   @CASE ERR_FILE_READ_FAIL @PRTLN "? Read File Error:"     @CBREAK
   @CASE ERR_FILE_WRITE_FAIL @PRTLN "? Write File Error :"     @CBREAK
   @CASE ERR_INTERNAL_FAULT @PRTLN "? Internal Fault :"     @CBREAK
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
    @LocalVar InCode 01
    @LocalVar TablePtr 02
    @LocalVar StrSize 03
    @LocalVar Index 04
    @LocalVar CharHold 05

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
    @RestoreVar 05
    @RestoreVar 04
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
