! TOKENSKIP
M TOKENSKIP 1

I common.mc
L string.ld
L softstack.ld 
###########
# Global
G GetNextWord
G Tokenize
# Storage
:EndKeyWordData 0
:KeyWordDataBase 0
:ENDOFCODE 0


# This library provides two major functions
# GetNextWord which acts as a way to extract 'words' from a larger string
# Tokenize which maps the found words to a keyword database
#
# The keyword data base is 16b int, "string\0" array.
# One way to generate the data base 'inline' would be.
# M StoreKeyWord %0Next %1 %2 :%0Next 
# :KeyWordDataBase
# @StoreKeyWord IntValue "String\0"
# ...
# :EndKeyWordData


#
###########
# Reuse
# Define local variable names
#
# We use this technique to show how a variable can have multiple names

:TermCharPtr
:InputString
:RR1 0
:SepCharPtr
:TokenPtr
:RR2 0
:StringInPtr
:NextToken
:RR3 0
:StringOutPtr
:TokenFound
:RR4 0
:Consumed
:RR5 0
:BreakFlag
:RR6 0
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

@PUSHLOCALI RR1 @PUSHLOCALI RR2 @PUSHLOCALI RR3 @PUSHLOCALI RR4 @PUSHLOCALI RR5 @PUSHLOCALI RR6
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
    @CMP 34        # 34 is ascii double quote 
    @IF_ZFLAG
       # This block is for the case of quoted text
       @MA2V 0 BreakFlag
       @PUSH 0          # Do the loop at least once.
       @WHILE_ZERO
          @POPNULL
          @POPII StringOutPtr
          @INCI StringInPtr
          @INCI StringOutPtr
          @INCI Consumed
          @PUSHII StringInPtr @AND 0xff
          @CMP 92     # Ascii code for backslash
          @IF_ZFLAG   # This block will make sure what ever follows the backslash will be inserted into string. Even quote
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
@POPLOCAL RR6 @POPLOCAL RR5 @POPLOCAL RR4 @POPLOCAL RR3 @POPLOCAL RR2 @POPLOCAL RR1
@POPRETURN
@RET
#
# Function Tokenize(string,KeyWordDataBase,EndKeyWordData):[type, value]
# 
:Tokenize
@PUSHRETURN
@PUSHLOCALI RR1 @PUSHLOCALI RR2 @PUSHLOCALI RR3 @PUSHLOCALI RR4

@POPI EndKeyWordData
@POPI KeyWordDataBase
@POPI InputString
@PUSHII InputString @AND 0xff
@IF_NOTZERO
   
@MV2V KeyWordDataBase TokenPtr
@MA2V 0 TokenFound
@PUSHI TokenPtr
@WHILE_LT_V EndKeyWordData
#   @PRT "Ptr: " @PRTI TokenPtr @PRT " != " @PRTI EndKeyWordData @PRTNL
   @PUSHS
   @POPI NextToken
   @INC2I TokenPtr
   @PUSHII TokenPtr   # Save on stack the possible Token ID code
   @INC2I TokenPtr
   @PUSHI TokenPtr
   @PUSHI InputString
   @CALL strcmp
   @IF_EQ_A 0
      @POPNULL
      # On Stack should be the Token ID already
      @PUSHI EndKeyWordData # EndKeyWordData forces loop to exit
      @POPI TokenPtr
      @MA2V 1 TokenFound
   @ELSE
      @POPNULL @POPNULL  # Remove the strcmp result and the unneeded token ID
      @MV2V NextToken TokenPtr
   @ENDIF
   @PUSHI TokenPtr   
@ENDWHILE
@POPNULL
@PUSHI TokenFound
@IF_ZERO
   @POPNULL
   # If here, then keyword was not a tokenized value
   # Our main concern now will be, is it a either an integer or a user defined label/value/function
   @PUSH 999        # Default for undefined tolkens. likely variables or functions.    
   @PUSHII InputString
   @AND 0xff      # Look at first character   
   @IF_GE_A "0\0"
      @IF_LE_A "9\0"
         # Its a number
         @POPNULL
         @PUSH 998           # For cases where input was a number.
      @ENDIF
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
@ELSE
  @POPNULL
  @PUSH 0
@ENDIF
@POPLOCAL RR4 @POPLOCAL RR3 @POPLOCAL RR2 @POPLOCAL RR1
@POPRETURN
@RET

ENDBLOCK
