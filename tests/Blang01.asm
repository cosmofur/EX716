I common.mc
L tokenizer.ld
L softstack.ld
L string.ld
#
#
#
=CLSCODE 1
=IFCODE CLSCODE+1
=THENCODE IFCODE+1
=ELSECODE THENCODE+1
=ENDIFCODE ELSECODE+1
=WHILECODE ENDIFCODE+1
=WENDCODE WHILECODE+1
=GOTOCODE WENDCODE+1
=GOSUBCODE GOTOCODE+1
=RETURNCODE GOSUBCODE+1
=FORCODE RETURNCODE+1
=TOCODE FORCODE+1
=NEXTCODE TOCODE+1
=REMCODE NEXTCODE+1
=PRINTCODE REMCODE+1
=INPUTCODE PRINTCODE+1
=ENDCODE INPUTCODE+1
=QUITCODE ENDCODE+1
=OPENPARENCODE QUITCODE+1
=CLOSEPARENCODE OPENPARENCODE+1
=EQUALCODE CLOSEPARENCODE+1
=LESSTHANCODE EQUALCODE+1
=GREATERCODE LESSTHANCODE+1
=ASSIGNCODE GREATERCODE+1
=NOTEQUALCODE ASSIGNCODE+1
=NOTLESSTHANCODE NOTEQUALCODE+1
=NOTGREATERCODE NOTLESSTHANCODE+1
=ADDCODE NOTGREATERCODE+1
=SUBCODE ADDCODE+1
=MULCODE SUBCODE+1
=DIVCODE MULCODE+1
=ASSIGNCODE DIVCODE+1
=COLONCODE ASSIGNCODE+1
=EDITCODE COLONCODE+1
=QUOTECODE EDITCODE+1
=PLUSCODE QUOTECODE+1
=DASHCODE PLUSCODE+1
=MULCODE DASHCODE+1
=DIVCODE MULCODE+1
=ISNUMCODE DIVCODE+1
=ISSTRINGCODE ISNUMCODE+1
=ISFUNCCODE ISSTRINGCODE+1



#
#
G MemSpaceSet
G LowMemStart
G HighMemStop
G VarMemTop
G VarMemBottom
G VarMemUsed
G InputBuffer1
G ScratchBuffer1
G StackMemTop
G StackMemBottom
G StackSize

:LowMemStart 0
:HighMemStop 0
:VarMemTop 0
:VarMemBottom 0
:VarMemUsed 0
:InputBuffer1 0
:ScratchBuffer1 0
:StackMemTop 0
:StackMemBottom 0
:StackSize 0
:RR1 0                # Common registers
:RR2 0
:RR3 0
:RR4 0
:BuffPtr 0
:BuffSize 0
:CurrentLineNum 0
:MaxLineNum 0
:LineDirTop 0


#
# Memory Management Functions:
# Function MemSpaceSet(ENDOFCODE,lowmem, highmem, stacksize )
#    sets the low and high mem ranges for the reserved storage
#    Address
#    0-NN    ENDOFCODE      VarMemBottom (Grows Up)
#    HIMEM-0x203-stacksize  VarMemTop   (Limit of space for variables)
#    HIMEM-0x201-stacksize  StackBottom (Limit of stack)
#    HIMEM-0x201 StackTop (Grows Down)
#    HIMEM-0x1ff ScratchBuffer1
#    HIMEM-0xff  InputBuffer1
#    
#    HIMEM
#    
:MemSpaceSet
@SWP
@POPI StackSize        # We'll use this to calculate StackMemTop/Bottom later
@SWP @POPI HighMemStop
@SWP @POPI LowMemStart
@SWP @POPI ENDOFCODE
# 
@PUSHI HighMemStop
@SUB 255
@POPI InputBuffer1
#
@PUSHI InputBuffer1
@SUB 255
@POPI ScratchBuffer1
#
@PUSHI ScratchBuffer1
@SUB 2
@POPI StackMemTop
#
@PUSHI StackMemTop
@SUBI StackSize
@POPI StackMemBottom
#
@PUSHI StackMemBottom
@SUB 2
@POPI VarMemTop
#
@PUSH ENDOFCODE
@POPI VarMemBottom
@MA2V 0 VarMemUsed
#
# Now set the Software stack to use the defined spaces.
@PUSHI StackMemTop @PUSHI StackMemBottom 
@CALL SetSSStack
# Return Address should still be at top of HW stack.
@MV2V VarMemUsed LineDirTop
@RET
#
# Function SaveLine(linenumber,buffer, buffsize)
# Saves a formated buffer at linenumber location. Erase and replace existing lines or create new entry if needed.
#
# Structure of the 'Line' Entry
# W:Pntr to next Line
# W:Line Number
# W:Line Length in bytes
# B:0=Raw,1=compressed
# Data
:SaveLine
@PUSHRETURN
#
@PUSHLOCAL RR1
@PUSHLOCAL RR2
@PUSHLOCAL BuffPtr
@PUSHLOCAL BuffSize
#
@POPI BuffSize
@POPI BuffPtr
@POPI CurrentLineNum
#
@PUSHI CurrentLineNum @AND 0x7fff # We don't allow linenumbers larger than 32K
@IF_ZERO
   # We do not allow a 0 linenumber. We use that value to id the end of the chain.
   @PRTLN "Invalid Line Number"
@ELSE
   @IF_GT_V MaxLineNum
      # Line Number is higher than previously seen ones.
      @MV2V CurrentLineNum MaxLineNum
   @ENDIF
   @POPNULL
   @MV2V VarMemBottom RR1
   @PUSH 1 # Start While loop
   @MV2V RR1 RR2       # RR2 will hold the 'previous' line for inserting new one.
   @WHILE_NOTZERO
      @INC2I RR1
      @PUSHII RR1
      @IF_EQ_V CurrentLineNumber
         # Found existing line that matches. Need to erase it, and replace with new one.
         @DEC2I RR1  # Move RR1 back to the begining of this block.
         



#
# Function LoadLine(linenumber,buffer)
# Fetches from the Var space a line for the buffer.
# If linenumber>MaxLineNum, just return with empty buffer
:LoadLine
@PUSHRETURN
@PUSHLOCAL RR1
@PUSHLOCAL RR2
@POPI CurrentLineNum
@POPI RR2
@PUSH 0 @POPII RR2 # Nulls the Return Buffer to be empty
@PUSHI CurrentLineNum @ADDI MaxLineNum
@IF_LT_V CurrentLineNum
    # Rolled over the 64K and ended up outside of valid memory.
    @POPNULL
    @PUSH 0
@ELSE
   @MV2V VarMemBottom RR1
   @PUSHII RR1      # Pointer to next line
   @WHILE_NOTZERO
      @INC2I RR1
      @PUSHII RR1      # Data ID
      @IF_EQ_V CurrentLineNum
         @POPNULL @POPNULL
         @INC2I RR1
         @PUSHI RR2
         @PUSHI RR1
         @CALL strcpy
         @PUSH 0         # Break the while loop
      @ELSE
         # Wasn't this line, so follow pointer to next line
         @POPNULL	 
      @ENDIF
    @ENDWHILE
    @POPNULL
@ENDIF
@POPNULL
@POPLOCAL RR2
@POPLOCAL RR1
@POPRETURN
@RET
#
#
# function Turn string into uppercase except within quotes
:FixCase
@PUSHRETURN
@PUSHLOCALI RR1    # String Ptr
@PUSHLOCALI RR2    # Character value
@PUSHLOCALI RR3    # In Quoted text flag
@POPI RR1      # Ptr to begining of string
@PUSHII RR1 @AND 0xff
@MA2V 0 RR3
@WHILE_NOTZERO
    @IF_EQ_VA RR3 1
        # In side quoted text. Look for ending quote.
        @IF_EQ_A 92   # Backslash, to allow quoteing of special characters
           @INCI RR1
        @ELSE
           @IF_EQ_A 34   # Double Quote
              @MA2V 0 RR3
           @ENDIF
        @ENDIF
     @ELSE      # Not inside Quotes
        @IF_EQ_A 34     # Switch ti inside quotes mode.
           @MA2V 1 RR3
        @ELSE
            @IF_GE_A "a\0"        # Lower Case A
                @IF_LE_A "z\0"    # Lower Case Z
                    @SUB 32       # Change to Uppercase
                    @PUSHII RR1 @AND 0xff00      # Pull in upper byte of word
                    @ORS
                    @POPII RR1                   # Put back as uppercase
                    @PUSH 1                      # Place keeper for while loop logic
                @ENDIF
            @ENDIF
        @ENDIF
     @ENDIF
     @POPNULL
     @INCI RR1
     @PUSHII RR1 @AND 0xff
@ENDWHILE
@POPNULL
@POPLOCAL RR3
@POPLOCAL RR2
@POPLOCAL RR1
@POPRETURN
@RET
         

#
#
#
# function Main
:SepString " ,:\0"
:TermString "(<>=-+)^%$\0"
:Main
@PUSH ENDOFCODE
@PUSH 0xfc00
@PUSH 0xff00
@PUSH 0xff
@CALL MemSpaceSet
#
@PRT "BK-LANG01 Free:("
@PUSHI HighMemStop @SUBI VarMemBottom @SUB 0x3ff
@PRTTOP @POPNULL @PRT ")\n"
#
@PUSH 1
@WHILE_NOTZERO
  @PRT "> "
  @READSI InputBuffer1
  @PUSHI InputBuffer1
  @CALL FixCase      # Change all none quoted text to uppercase.
  @WHILE_NOTZERO
     @POPNULL
     @PUSHI InputBuffer1 @PUSHI ScratchBuffer1 @PUSH TermString @PUSH SepString 
     @CALL GetNextWord
     @PRTSI InputBuffer1 @PRT " -- " @PRTTOP  @PRT " : "
     @ADDI InputBuffer1 @POPI InputBuffer1
     @PUSHI ScratchBuffer1 @PUSH KeyWordDataBase @PUSH EndKeyWordData
     @CALL Tokenize @PRTTOP @PRTNL
     @SWITCH
     @CASE QUITCODE
        @END
	@CBREAK
     @CASE 999
        @PRT "Dynamic: " @PRTSI ScratchBuffer1 @PRTNL
        @POPNULL
	@PUSH 1
	@CBREAK
     @CASE 998
        @PRT "Number: " @PRTSI ScratchBuffer1 @PRTNL
        @POPNULL
        @PUSH 1
        @CBREAK
     @CASE 0
        # End of Line
	@CBREAK
     @CDEFAULT
        @POPNULL  
        @PUSH 1
	@CBREAK
     @ENDCASE
  @ENDWHILE
  @POPNULL
@ENDWHILE
@END

M StoreKeyWord %0Next %1 %2 :%0Next 

:KeyWordDataBase
@StoreKeyWord CLSCODE "CLS\0" 
@StoreKeyWord IFCODE "IF\0"
@StoreKeyWord THENCODE "THEN\0"
@StoreKeyWord ELSECODE "ELSE\0"
@StoreKeyWord ENDIFCODE "ENDIF\0"
@StoreKeyWord WHILECODE "WHILE\0"
@StoreKeyWord WENDCODE "WEND\0"
@StoreKeyWord GOTOCODE "GOTO\0"
@StoreKeyWord GOSUBCODE "GOSUB\0"
@StoreKeyWord RETURNCODE "RETURN\0"
@StoreKeyWord FORCODE "FOR\0"
@StoreKeyWord TOCODE "TO\0"
@StoreKeyWord NEXTCODE "NEXT\0"
@StoreKeyWord REMCODE "REM\0"
@StoreKeyWord PRINTCODE "PRINT\0"
@StoreKeyWord INPUTCODE "INPUT\0"
@StoreKeyWord ENDCODE "END\0"
@StoreKeyWord QUITCODE "QUIT\0"
@StoreKeyWord OPENPARENCODE "(\0"
@StoreKeyWord CLOSEPARENCODE ")\0"
@StoreKeyWord EQUALCODE "==\0"
@StoreKeyWord LESSTHANCODE "<\0"
@StoreKeyWord GREATERCODE ">\0"
@StoreKeyWord ASSIGNCODE "=\0"
@StoreKeyWord NOTEQUALCODE "!=\0"
@StoreKeyWord NOTLESSTHANCODE ">=\0"
@StoreKeyWord NOTGREATERCODE "<=\0"
@StoreKeyWord ADDCODE "+\0"
@StoreKeyWord SUBCODE "-\0"
@StoreKeyWord MULCODE "*\0"
@StoreKeyWord DIVCODE "/\0"
@StoreKeyWord COLONCODE ":\0"
@StoreKeyWord EDITCODE "EDIT\0"
@StoreKeyWord QUOTECODE 33
@StoreKeyWord PLUSCODE "+"
@StoreKeyWord DASHCODE "-"
@StoreKeyWord MULCODE "*"
@StoreKeyWord DIVCODE "/"

:EndKeyWordData
EndKeyWordData 0 "END__notmatch__\0"         # This makes the 'next' address exactly EndKeyWordData
:ENDOFCODE  # Managed Storage will exist past this point.
. Main
