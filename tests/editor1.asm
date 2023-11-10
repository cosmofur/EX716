I common.mc
L string.ld
L softstack.ld 
###########
# Global
:InputBuffer
. InputBuffer+255
:InputBufferPtr 0
:ObjectArray
. ObjectArray+255
:ObjectArrayPtr 0
#
###########
# Reuse
:R1 0
:R2 0
:R3 0
:R4 0
:R5 0
:R6 0
###########
#
# Function ISAplhaNum(String):T|F
# Return T|F if first char in string is in set [A-Za-z0-9_]
:ISAlphaNum
@PUSHRETURN
@PUSHS
@AND 0xff
@SWITCH
@CASE_RANGE "a\0" "z\0"
   @PUSH 1
   @CBREAK
@CASE_RANGE "A\0" "Z\0"
   @PUSH 1
   @CBREAK
@CASE_RANGE "0\0" "9\0"
   @PUSH 1
   @CBREAK
@CASE_RANGE "_\0"
   @PUSH 1
   @CBREAK
@CDEFAULT
   @PUSH 0
   @CBREAK
@ENDCASE
@SWP
@POPNULL
@POPRETURN
@RET
#
# Function IsAlpha(string):T|F
# Return T|F if first char in string is in set [A-Za-z]
:ISAlpha
@PUSHRETURN
@PUSHS
@AND 0xff
@SWITCH
@CASE_RANGE "a\0" "z\0"
   @PUSH 1
   @CBREAK
@CASE_RANGE "A\0" "Z\0"
   @PUSH 1
   @CBREAK
@CDEFAULT
   @PUSH 0
   @CBREAK
@ENDCASE
@SWP
@POPNULL
@POPRETURN
@RET

#
# Function ISNumeric(String):T|F
# Return T|F if first char in string is in set [0-9]
@PUSHRETURN
@PUSHS
@AND 0xff
@SWITCH
@CASE_RANGE "0\0" "9\0"
   @PUSH 1
   @CBREAK
@CDEFAULT
   @PUSH 0
   @CBREAK
@ENDCASE
@SWP
@POPNULL
@POPRETURN
@RET
#
#
# Function GetNextWord(string,returnbuffer,"Termination Characters","Seperator Characters"):length_consumed
# Scan String for one 'word' and returns that word in the returnbuffer, which must be sufficent length
# End of word is determined by matching either one of the Termination Characters or Seperator Characters, or EOS
# If a Termination Character is found the return length will not include that character so next call will start on that spot
# else if Seperator Character was found, returned length will include that character so it will be cutout from next call.
# In addition to the normal 'word' extraction, also know about quoted text and return as single 'word' quoted strings.
#
:GetNextWord
@PUSHRETURN
# Define local variable names
=TermCharPtr R1
=SepCharPtr R2
=StringInPtr R3
=StringOutPtr R4
=Consumed R5
=BreakFlag R6
@PUSHLOCAL R1 @PUSHLOCAL R2 @PUSHLOCAL R3 @PUSHLOCAL R4 @PUSHLOCAL R5 @PUSHLOCAL R6
#
@POPI SepCharPtr
@POPI TermCharPtr
@POPI StringOutPtr
@POPI StringInPtr
@MA2V 0 Consumed
@PUSH 0 @POPII StringOutPtr     # Null out the Output string
#@PRT "Input:" @PRTSI StringInPtr @PRT ":\n"
#@PRT "Seperation Strings: " @PRTSI SepCharPtr @PRTNL
#@PRT "Termination Strings: " @PRTSI TermCharPtr @PRTNL

#
@PUSHII StringInPtr @AND 0xff
@IF_NOTZERO        # Skip whole logic is string is already empty
    @CMP 34        # 34 is ascii double quote "
    @IF_ZFLAG
#       @POPNULL
       # This block is for the case of quoted text
       :Break1
       @MA2V 0 BreakFlag
#       @INCI StringInPtr
#       @PUSHII StringInPtr @AND 0xff 
#       @INCI Consumed
       @PUSH 0          # Do the loop at least once.
       @WHILE_ZERO
          @POPNULL
          @POPII StringOutPtr
          @INCI StringInPtr
          @INCI StringOutPtr
          @INCI Consumed
          @PUSHII StringInPtr @AND 0xff
          @CMP 92     # Ascii code for backslash
          @IF_ZFLAG   # This block will make sure what ever follows the backslash will be inserted into string. Even "
                      # Maybe later I'll ask the codes for \n \m \r and \t but for now, they have to be explicitly entered.
             @INCI StringInPtr
             @INCI Consumed             
             @PUSHII StringInPtr @AND 0xff
          @ELSE
             @IF_EQ_A 34
                @POPNULL
                @INCI Consumed
                @MA2V 1 BreakFlag
             @ENDIF
         @ENDIF
         @PUSHI BreakFlag
      @ENDWHILE
      @POPNULL
      @PUSHI Consumed
    @ELSE
        # This block is for the case of 'normal' words
        @PUSHI TermCharPtr
        @SWP
        @CALL strfndc
        @IF_NOTZERO
           @POPNULL
           @PUSHII StringInPtr @AND 0xff   
           @POPII StringOutPtr
           @INCI Consumed
           @PUSH 0
        @ELSE
           @POPNULL
           @PUSH 1
           @WHILE_NOTZERO
             @POPNULL
             @PUSHI SepCharPtr
             @PUSHII StringInPtr @AND 0xff
             @CALL strfndc
             @IF_NOTZERO
                @INCI StringInPtr
                @INCI Consumed
             @ENDIF
           @ENDWHILE
           @POPNULL
           @PUSHII StringInPtr @AND 0xff   
        @ENDIF
        @WHILE_NOTZERO
           @PUSHI SepCharPtr
           @SWP         # order is (string,char) for strfndc, so swap them
           @CALL strfndc
           @IF_NOTZERO
              # Case for found char in Seperation List
              @POPNULL     # Remove the found address
              # Found match in Terminat string
              @INCI Consumed     # this extra incriment is what's diffrent between SepChar and TermChar
              @PUSH 0      # This will terminate the while loop
        #      @PRT "\nMatched Seperation String: " @PRTI Consumed @PRT "\n"
           @ELSE
              # Case for found char in Termination List
              @POPNULL
              @PUSHI TermCharPtr      
              @PUSHII StringInPtr @AND 0xff
              @CALL strfndc
              @IF_NOTZERO
                 @POPNULL
                 @PUSH 0
        #         @PRT "\nMatched Termination String: " @PRTI Consumed @PRT "\n"         
              @ELSE
                 # Last Case, character was not in either list.
                 @POPNULL
                 @PUSHII StringInPtr @AND 0xff
                 @POPII StringOutPtr
                 @INCI StringInPtr
                 @INCI StringOutPtr
                 @INCI Consumed
                 @PUSHII StringInPtr @AND 0xff         
              @ENDIF
           @ENDIF
        @ENDWHILE
        @POPNULL
        @PUSHI Consumed
    @ENDIF
@ELSE
  @POPNULL    # String was empty
  @PUSH 0
@ENDIF
@POPLOCAL R6 @POPLOCAL R5 @POPLOCAL R4 @POPLOCAL R3 @POPLOCAL R2 @POPLOCAL R1
:Break2
@POPRETURN
@RET
#
# Function Tolkenize(string):[type, value]
# 
:Tolkenize
@PUSHRETURN
@PUSHLOCAL R1 @PUSHLOCAL R2 @PUSHLOCAL R3 @PUSHLOCAL R4
=InputString R1
=TolkenPtr R2
=NextTolken R3
=TolkenFound R4
@POPI InputString
@MA2V KeyWordDataBase TolkenPtr
@MA2V 0 TolkenFound
@PUSHI TolkenPtr
@WHILE_NEQ_A EndKeyWordData
   @PRT "Ptr: " @PRTI TolkenPtr @PRT " != " @PRTREF EndKeyWordData @PRTNL
   @PUSHS
   @POPI NextTolken
   @INC2I TolkenPtr
   @PUSHI TolkenPtr
   @PUSHI InputString
   @CALL strcmp
   @IF_ZFLAG
      @POPNULL
      @PUSHI TolkenPtr
      @CALL strlen
      @ADDI TolkenPtr
      @PUSHS        # Get the tolken value for this keyword
      @PUSH EndKeyWordData  # Jump While to end of loop
      @MA2V 1 TolkenFound
   @ELSE
      @POPNULL
      @MV2V NextTolken TolkenPtr
      @PUSHI TolkenPtr
   @ENDIF
@ENDWHILE

@PUSHI TolkenFound
@IF_ZERO
   @POPNULL
   # If here, then keyword was not a tolkenized value
   # For now just call it a lable
   @PUSH VARBASIC
@ELSE
   @POPNULL
@ENDIF
@POPLOCAL R4 @POPLOCAL R3 @POPLOCAL R2 @POPLOCAL R1
@POPRETURN
@RET
#
# Test Data
# 
:InPut1 "IF THEN A=CAT ENDIF\0"
:InPut1Ptr 0
:OutPut1 "-----------------------------------------------------------------------------"
:SepString " ,:\0"
:TermString "(<>=-+)^%$\0"
:Main . Main

@PUSH 1
@MA2V InPut1 InPut1Ptr
@WHILE_NOTZERO
  @POPNULL
  @PUSHI InPut1Ptr @PUSH OutPut1 @PUSH TermString @PUSH SepString
  @CALL GetNextWord
  @PRTS OutPut1 @PRT " -- " @PRTTOP  @PRT " : "
  @PUSHI OutPut1
  @CALL Tolkenize @PRTTOP @PRTNL
  @DUP
  @ADDI InPut1Ptr @POPI InPut1Ptr
@ENDWHILE
@END

=PRINTOPT 101
=NEXTOPT  102
=IFOPT    103
=THENOPT  104
=ELSEOPT  105
=FOROPT   106
=NEXTOPT  107
=GOTOOPT  108
=GOSUBOPT 109
=RETURNOPT 110
=REMOPT   111
=DIMOPT   112
=READOPT  113
=DATAOPT  114
=RESTOREOPT 115
=STOPOPT  116
=ENDIFOPT 117
=CLSOPT   118
=RUNOPT   119
=LISTOPT  120
=NEWOPT   121
=ONOPT    122
=ENDOPT   123
=DEFINEOPT 124
=VARBASIC 150
=VARSTRING 151
=VARLONG 152
=VARBARRY 153
=VARSTARRY 154
=VARLGARRY 155


:KeyWordDataBase
NextWord1
"PRINT\0" PRINTOPT
:NextWord1
NextWord2
"INPUT\0" NEXTOPT
:NextWord2
NextWord3
"IF\0" IFOPT
:NextWord3
NextWord4
"THEN\0" THENOPT
:NextWord4
NextWord5
"ELSE\0" ELSEOPT
:NextWord5
NextWord6
"FOR\0" FOROPT
:NextWord6
NextWord7
"NEXT\0" NEXTOPT
:NextWord7
NextWord8
"GOTO\0" GOTOOPT
:NextWord8
NextWord9
"GOSUB\0" GOSUBOPT
:NextWord9
NextWord10
"RETURN" RETURNOPT
:NextWord10
NextWord11
"REM\0" REMOPT
:NextWord11
NextWord12
"DIM\0" DIMOPT
:NextWord12
NextWord13
"READ\0" READOPT
:NextWord13
NextWord14
"DATA\0" DATAOPT
:NextWord14
NextWord15
"RESTORE\0" RESTOREOPT
:NextWord15
NextWord16
"STOP\0" STOPOPT
:NextWord16
NextWord17
"ENDIF\0" ENDIFOPT
:NextWord17
NextWord18
"CLS\0" CLSOPT
:NextWord18
NextWord19
"RUN\0" RUNOPT
:NextWord19
NextWord20
"LIST\0" LISTOPT
:NextWord20
NextWord21
"NEW\0" NEWOPT
:NextWord21
NextWord22
"ON\0" ONOPT
:NextWord22
NextWord23
"END\0" ENDOPT
:NextWord23
NextWord24
"DEFINE\0" DEFINEOPT
:NextWord24
:EndKeyWordData
