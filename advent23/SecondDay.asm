I common.mc
L string.ld
L softstack.ld
L lmath.ld

:Var01 0
:Var02 0
:Var03 0
:Var04 0
:Var05 0
:Var06 0
:Var07 0
:Var08 0
:Var09 0
:Var10 0
# Function SkipWhite(strptr):Length
:SkipWhite
=SWStrPtr Var01
=SWConsumed Var02
@PUSHRETURN
@PUSHLOCALI SWStrPtr
@PUSHLOCALI SWConsumed
:Break2
@POPI SWStrPtr
@MA2V 0 SWConsumed
@PUSHII SWStrPtr @AND 0xff
@WHILE_NOTZERO
   @SWITCH
   @CASE_RANGE "0\0" "9\0"
      @POPNULL
      @PUSH 0
      @CBREAK
   @CASE_RANGE "A\0" "Z\0"
      @POPNULL
      @PUSH 0
      @CBREAK
   @CASE_RANGE "a\0" "z\0"
      @POPNULL
      @PUSH 0
      @CBREAK
   @CASE 0
      @CBREAK
   @CDEFAULT
      @POPNULL
      @INCI SWConsumed
      @INCI SWStrPtr
      @PUSHII SWStrPtr @AND 0xff      
      @CBREAK
   @ENDCASE
@ENDWHILE
@POPNULL
@PUSHI SWConsumed
@POPLOCAL SWConsumed
@POPLOCAL SWStrPtr
@POPRETURN
@RET


#Function NextWord(strptr,wordbuffer)
# Fills wordbuffer with next word in strptr
# Skips whilespace in begining and end
# Terminates word if not in set [0-9a-zA-Z]
# Returns length of strptr consumed.
:NextWord
=WordStrPtr Var01
=StrLength Var02
=Consumed Var03
=WordBufferPtr Var04
=ValidChar Var05
@PUSHRETURN
@PUSHLOCALI WordStrPtr
@PUSHLOCALI StrLength
@PUSHLOCALI Consumed
@PUSHLOCALI WordBufferPtr
@PUSHLOCALI ValidChar
#
@POPI WordBufferPtr
@POPI WordStrPtr
#
@MA2V 0 Consumed
@PUSH 0 @POPII WordBufferPtr  # Zero Terms any old data
:Break1
@PUSHI WordStrPtr
@CALL SkipWhite
@POPI Consumed
@PUSHI Consumed @ADDI WordStrPtr @POPI WordStrPtr
@PUSHII WordStrPtr @AND 0xff
# For next while loop will use the flag tos to test when condition has been met
@WHILE_NOTZERO
    @MA2V 0 ValidChar
    @SWITCH
    @CASE_RANGE "0\0" "9\0"
        @MA2V 1 ValidChar
        @CBREAK
    @CASE_RANGE "a\0" "z\0"
        @MA2V 1 ValidChar
        @CBREAK
    @CASE_RANGE "A\0" "Z\0"
        @MA2V 1 ValidChar
        @CBREAK
    @CDEFAULT
        @MA2V 0 ValidChar
        @CBREAK
    @ENDCASE
    @IF_EQ_AV 1 ValidChar
        @POPII WordBufferPtr
        @INCI WordBufferPtr
        @INCI Consumed
        @INCI WordStrPtr
        @PUSHII WordStrPtr @AND 0xff
    @ELSE
        @POPNULL
        @INCI Consumed
        @INCI WordStrPtr
        @PUSHI ValidChar
    @ENDIF
@ENDWHILE
@POPNULL
@PUSHI WordStrPtr
@CALL SkipWhite
@ADDI Consumed @POPI Consumed
@PUSHI Consumed @ADDI WordStrPtr @POPI WordStrPtr
@PUSHI Consumed
@POPLOCAL ValidChar
@POPLOCAL WordBufferPtr
@POPLOCAL Consumed
@POPLOCAL StrLength
@POPLOCAL WordStrPtr
@POPRETURN
@RET

#Function GameParse(StrPtr, max red, max green, max blue): Return 0 or game number, if valid
# Identify number of Game, then scan forward for # color patterns
# If # is <= max of that color for all entries, game is valid return game # as return else zero
:GameParse
=MaxRed Var01
=MaxGreen Var02
=MaxBlue Var03
=GameNumber Var04
=StrPtr Var05
=ItemValue Var06
=CurColor Var07
=CurMax Var08
@PUSHRETURN
@PUSHLOCALI MaxRed
@PUSHLOCALI MaxGreen
@PUSHLOCALI MaxBlue
@PUSHLOCALI GameNumber
@PUSHLOCALI StrPtr
@PUSHLOCALI ItemValue
@PUSHLOCALI CurColor
@PUSHLOCALI CurMax

#
@POPI MaxBlue
@POPI MaxGreen
@POPI MaxRed
@POPI StrPtr
#
@PUSHI StrPtr @PUSH WordBuffer
@CALL NextWord
@ADDI StrPtr @POPI StrPtr  # Move StrPtr to next word or end of line
@PUSH "Ga"                 # Valididate that first word is "Game"
@CMPI WordBuffer
@IF_ZFLAG
   # we have no 'Not' ZFLAG IF rule, but we also do not requre any body in the true clause.
@ELSE
   @PRTLN "First Word in Line was not Game, Data error."
   @END
@ENDIF
@POPNULL
# Now get number after word Game
@PUSHI StrPtr @PUSH WordBuffer
@CALL NextWord


@ADDI StrPtr @POPI StrPtr  # Move StrPtr to next word or end of line
@PUSH WordBuffer
@CALL stoi
@POPI GameNumber
#
@PUSHII StrPtr @AND 0xff   # Repease until end of string

@WHILE_NOTZERO
   @POPNULL
   @PUSHI StrPtr @PUSH WordBuffer
   @CALL NextWord
   @ADDI StrPtr @POPI StrPtr  # Move StrPtr to next word or end of line
   # First word in any pair should be a quanity.
   @PUSH WordBuffer
   @CALL stoi
   @POPI ItemValue   
   # Second word should be color name
   @PUSHI StrPtr @PUSH WordBuffer
   @CALL NextWord
   @ADDI StrPtr @POPI StrPtr  # Move StrPtr to next word or end of line
   #
   @PUSHI WordBuffer
   @POPI CurColor        # We only need first two charaters to ID color
   #
   @PUSHI CurColor
   # Our Switch statment takes advantage that the first 2 letters in each color is unique.
   @SWITCH
   @CASE "re"   # Red
      @PUSHI ItemValue
      @IF_GT_V MaxRed
         @MA2V 0 GameNumber    # By Setting GameNumber to zero we mark invalid game
      @ENDIF
      @POPNULL
      @CBREAK
   @CASE "gr"   # Green
      @PUSHI ItemValue
      @IF_GT_V MaxGreen
         @MA2V 0 GameNumber    # By Setting GameNumber to zero we mark invalid game
      @ENDIF
      @POPNULL
      @CBREAK
   @CASE "bl"   # Blue
      @PUSHI ItemValue
      @IF_GT_V MaxBlue
         @MA2V 0 GameNumber    # By Setting GameNumber to zero we mark invalid game
      @ENDIF
      @POPNULL
      @CBREAK
   @CDEFAULT
      @PRTLN "Invalid Color data in Data"
      @END
      @CBREAK
   @ENDCASE
   @POPNULL
   @PUSHII StrPtr @AND 0xff
@ENDWHILE   
@POPNULL
@PUSHI StrPtr
@PUSHI GameNumber

@POPLOCAL CurMax
@POPLOCAL CurColor
@POPLOCAL ItemValue
@POPLOCAL StrPtr
@POPLOCAL GameNumber
@POPLOCAL MaxBlue
@POPLOCAL MaxGreen
@POPLOCAL MaxRed

@POPRETURN
@RET
      
:Main . Main
=DataPtr Var01
=GameSum Var02

@MA2V DataList DataPtr
@MA2V 0  GameSum
@PUSHI DataPtr @SUB DataListEnd
@WHILE_NOTZERO
   @POPNULL
   @PUSHI DataPtr @PUSH 12 @PUSH 13 @PUSH 14
   @CALL GameParse
   @PRT "Game: " @PRTTOP @PRTSP
   @ADDI GameSum @POPI GameSum
   @PRTI GameSum @PRTNL
   @POPI DataPtr
   @INCI DataPtr
   @PUSHI DataPtr @SUB DataListEnd   
@ENDWHILE
@PRT "Sum: " @PRTI GameSum
@END





# Buffer for word data
:WordBuffer 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
:DataList1
"Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green\0"
"Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue\0"
"Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red\0"
"Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red\0"
"Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green\0"
:DataListEnd1


:DataList
"Game 1: 4 green, 3 blue, 11 red; 7 red, 5 green, 10 blue; 3 green, 8 blue, 8 red; 4 red, 12 blue; 15 red, 3 green, 10 blue\0"
"Game 2: 3 red, 1 blue, 2 green; 1 blue, 9 green; 1 red, 10 green\0"
"Game 3: 5 green, 9 red, 4 blue; 3 green, 7 blue; 12 blue, 3 green, 3 red; 3 blue, 7 red, 2 green; 7 blue, 3 green, 10 red\0"
"Game 4: 2 green, 2 blue; 12 red, 9 green, 2 blue; 13 green, 15 red, 4 blue; 14 red, 3 green, 5 blue; 6 red, 1 green; 1 blue, 2 red, 2 green\0"
"Game 5: 2 green, 6 blue; 1 red, 3 green, 5 blue; 3 green, 4 blue; 3 blue, 5 green, 1 red; 5 blue\0"
"Game 6: 5 green, 1 blue, 3 red; 8 green, 15 red; 16 green, 5 red, 1 blue\0"
"Game 7: 1 blue, 3 red, 11 green; 18 red, 16 blue, 5 green; 13 blue, 5 green; 1 red, 8 green, 15 blue\0"
"Game 8: 1 green, 14 blue, 1 red; 10 blue; 1 green\0"
"Game 9: 4 green, 12 blue, 1 red; 14 blue; 2 blue, 4 green; 4 green, 1 red, 10 blue\0"
"Game 10: 11 green, 9 red; 12 red, 9 green; 5 red, 7 blue, 5 green; 6 green, 1 blue, 12 red; 3 red, 3 blue; 16 red, 9 blue, 7 green\0"
"Game 11: 11 green, 1 red, 9 blue; 2 red, 13 green, 5 blue; 5 green, 2 red, 5 blue; 5 green, 7 blue; 1 red, 5 blue, 1 green\0"
"Game 12: 5 green, 1 red; 1 red, 4 green; 1 blue, 12 green; 15 green, 4 blue; 4 blue, 19 green; 16 green, 4 blue\0"
"Game 13: 1 red, 9 green, 5 blue; 10 blue, 7 green, 1 red; 3 green, 2 red, 14 blue; 16 blue, 3 red\0"
"Game 14: 9 red, 1 blue, 2 green; 16 blue, 7 red; 2 green, 3 red, 14 blue; 1 green, 9 blue\0"
"Game 15: 6 blue; 4 blue; 1 red, 16 blue, 3 green\0"
"Game 16: 14 green, 5 red, 1 blue; 1 red, 1 blue; 5 blue\0"
"Game 17: 1 blue, 1 green, 3 red; 2 red, 2 blue, 2 green; 1 blue, 1 red; 1 red, 2 green, 2 blue; 2 blue; 1 green, 2 red, 1 blue\0"
"Game 18: 4 blue, 2 green, 1 red; 1 green, 1 red, 10 blue; 1 green, 1 red, 2 blue; 1 red, 5 blue; 3 green, 6 blue; 1 red, 1 green, 7 blue\0"
"Game 19: 1 blue, 13 green, 12 red; 7 blue, 2 green, 1 red; 1 blue, 3 red, 3 green; 3 blue, 8 green, 10 red; 7 blue, 2 green\0"
"Game 20: 1 red, 17 blue; 10 blue, 5 green; 9 green, 1 red, 3 blue; 1 red, 5 green, 1 blue\0"
"Game 21: 3 red, 6 blue, 5 green; 4 blue, 1 red, 7 green; 6 blue, 4 red, 9 green\0"
"Game 22: 11 blue, 2 red, 6 green; 16 blue, 5 red, 6 green; 12 red, 2 green, 10 blue; 14 blue, 2 green, 11 red\0"
"Game 23: 3 red, 5 green; 10 blue, 1 green, 9 red; 2 red, 10 green, 9 blue; 9 blue, 7 green\0"
"Game 24: 8 blue, 1 red; 3 red, 9 blue; 9 green, 2 red, 8 blue\0"
"Game 25: 2 red, 1 green, 1 blue; 1 green, 12 blue, 2 red; 2 red, 1 blue; 2 blue; 1 green, 10 blue; 6 blue\0"
"Game 26: 2 red; 4 green, 1 red, 7 blue; 11 blue, 2 red, 4 green; 1 red, 1 blue; 1 red, 5 green, 12 blue\0"
"Game 27: 1 red, 7 green, 8 blue; 13 green, 12 blue, 1 red; 6 red, 1 green, 10 blue; 8 red, 2 blue, 2 green; 11 blue, 4 green, 4 red\0"
"Game 28: 1 red, 8 blue, 3 green; 12 green, 4 blue; 1 red, 4 blue, 11 green; 7 blue, 10 green, 10 red; 11 blue, 7 red, 8 green; 10 red, 2 green, 2 blue\0"
"Game 29: 4 green, 2 red; 1 blue, 11 red; 2 blue, 3 green, 1 red; 16 red; 3 green, 8 red, 1 blue; 2 blue, 7 green, 12 red\0"
"Game 30: 1 blue, 3 green; 4 green, 2 blue; 3 red, 5 blue; 4 green, 1 red\0"
"Game 31: 2 red, 2 blue, 3 green; 2 green, 3 blue, 8 red; 7 red, 16 blue, 2 green; 5 red, 20 blue, 2 green\0"
"Game 32: 2 red, 1 green, 4 blue; 4 green, 4 red, 1 blue; 4 red, 4 blue; 1 blue, 4 red, 2 green; 4 blue, 3 green, 4 red\0"
"Game 33: 11 green, 4 blue, 10 red; 2 green, 13 red, 7 blue; 13 red, 2 blue, 8 green; 15 red, 9 blue, 12 green; 14 red, 10 green, 2 blue; 13 red, 7 green\0"
"Game 34: 11 red, 6 blue, 4 green; 16 red, 7 blue, 4 green; 6 red, 18 green, 6 blue; 3 blue, 16 red, 3 green; 2 red, 3 blue, 17 green; 3 green, 9 red, 6 blue\0"
"Game 35: 6 green, 10 red, 12 blue; 4 red, 1 blue, 2 green; 3 green, 8 blue, 7 red; 6 red, 12 blue, 2 green\0"
"Game 36: 4 green, 2 blue, 2 red; 3 green, 10 red, 1 blue; 1 blue, 3 green, 2 red; 2 green, 1 red; 1 blue, 5 red\0"
"Game 37: 3 blue, 1 red, 2 green; 8 red, 4 green, 10 blue; 4 red, 4 green\0"
"Game 38: 13 green, 3 red, 2 blue; 1 red, 13 green, 2 blue; 20 green, 3 red, 2 blue; 1 red, 2 blue, 12 green\0"
"Game 39: 13 blue, 1 red, 8 green; 5 red, 3 green, 8 blue; 6 blue, 4 green; 18 blue, 7 green, 1 red; 4 green, 3 blue, 5 red; 6 blue, 4 red, 1 green\0"
"Game 40: 2 red, 2 blue, 9 green; 1 blue, 2 red, 12 green; 16 green, 11 blue, 1 red; 1 green, 2 red; 3 blue, 2 red\0"
"Game 41: 7 blue, 1 red; 4 blue, 1 red; 3 blue, 1 red, 2 green; 13 blue\0"
"Game 42: 18 red, 1 green, 13 blue; 2 blue, 2 green, 7 red; 16 red, 12 blue; 1 green, 10 blue, 14 red\0"
"Game 43: 15 red, 6 green, 2 blue; 3 blue, 9 red, 3 green; 13 red\0"
"Game 44: 2 blue, 5 green, 3 red; 4 red, 4 blue, 19 green; 5 red, 3 blue, 9 green; 19 green, 6 red, 5 blue\0"
"Game 45: 5 red, 4 green, 13 blue; 12 red, 10 blue; 3 green, 9 blue, 5 red; 10 blue, 18 red, 5 green; 16 red, 6 green, 17 blue\0"
"Game 46: 3 green; 3 green, 2 blue; 4 blue, 2 red, 3 green; 5 blue, 3 green, 4 red; 1 green, 1 blue\0"
"Game 47: 2 blue, 1 red, 10 green; 2 red; 6 red, 1 blue; 16 red, 2 blue, 8 green; 5 blue, 8 red, 7 green\0"
"Game 48: 11 green, 4 red, 2 blue; 2 blue, 5 green, 8 red; 9 green, 6 red; 3 red, 3 green, 1 blue; 2 blue, 12 green, 17 red\0"
"Game 49: 10 blue, 4 green, 1 red; 10 red, 10 blue; 12 blue, 7 red; 13 blue, 6 green\0"
"Game 50: 1 red, 19 green, 7 blue; 4 red, 1 green, 5 blue; 16 green, 8 red, 8 blue\0"
"Game 51: 12 green, 18 blue; 13 green, 14 blue, 4 red; 7 green, 4 red, 14 blue; 8 green, 2 blue, 3 red; 16 blue, 8 green\0"
"Game 52: 9 blue, 9 green, 3 red; 8 blue, 1 green, 13 red; 2 red, 8 blue, 9 green; 13 red, 4 green; 6 green, 15 red; 11 blue, 11 red, 9 green\0"
"Game 53: 2 red, 4 green, 3 blue; 5 blue, 16 green; 4 blue, 8 red, 12 green\0"
"Game 54: 6 red, 16 green; 6 red, 15 green; 8 green, 8 red, 2 blue\0"
"Game 55: 9 red, 2 green; 4 blue; 2 green, 2 red, 7 blue; 1 red, 16 blue, 1 green; 17 blue, 5 red\0"
"Game 56: 14 green, 3 red, 9 blue; 14 blue, 15 green, 2 red; 8 red, 13 blue, 15 green; 15 blue, 2 red, 12 green; 3 red, 7 blue, 10 green; 10 blue, 13 green\0"
"Game 57: 1 blue, 10 green, 2 red; 4 blue, 9 green, 11 red; 2 blue\0"
"Game 58: 4 red, 2 blue, 5 green; 1 blue, 5 green, 4 red; 3 green, 4 red, 8 blue; 4 blue, 7 green; 5 green, 4 blue; 1 blue, 6 red\0"
"Game 59: 5 blue, 4 red, 3 green; 8 blue, 12 green, 5 red; 5 red, 8 blue, 15 green\0"
"Game 60: 6 red, 12 blue, 1 green; 10 blue, 20 green, 4 red; 6 blue, 1 green, 5 red; 9 red, 12 blue, 14 green; 15 green, 1 red, 14 blue; 10 green, 13 blue\0"
"Game 61: 1 blue, 12 green, 3 red; 4 green, 1 red, 4 blue; 8 red, 4 green, 6 blue\0"
"Game 62: 6 blue, 7 green, 3 red; 6 blue, 3 red, 3 green; 11 green, 6 red, 2 blue; 2 red, 6 blue, 3 green; 2 green, 3 blue, 3 red; 3 blue, 11 green, 11 red\0"
"Game 63: 5 green, 6 blue, 4 red; 6 green, 12 blue; 3 green, 9 blue, 10 red; 1 blue, 4 red, 5 green\0"
"Game 64: 10 green, 14 red; 1 blue, 9 red; 3 green, 10 blue, 14 red; 5 green, 3 blue, 12 red; 5 blue, 12 red, 13 green\0"
"Game 65: 1 red, 5 green, 10 blue; 14 red, 5 green, 10 blue; 10 blue, 10 red\0"
"Game 66: 9 green, 8 blue, 1 red; 8 red, 14 blue; 8 red, 7 blue, 2 green; 4 blue, 3 green, 5 red; 2 red, 8 green, 8 blue\0"
"Game 67: 4 red, 3 green, 3 blue; 4 green, 1 blue, 4 red; 1 blue, 3 red; 10 blue; 16 blue, 6 red, 4 green\0"
"Game 68: 6 blue, 6 green, 9 red; 4 blue, 9 red, 3 green; 3 blue, 8 red\0"
"Game 69: 4 green, 12 red, 3 blue; 2 red, 3 blue; 2 blue, 4 red, 2 green; 1 blue, 3 red\0"
"Game 70: 4 red, 3 green, 15 blue; 1 green, 4 red; 1 red, 1 green, 5 blue\0"
"Game 71: 4 blue, 2 red, 10 green; 7 red, 6 blue, 11 green; 4 blue, 7 red, 8 green\0"
"Game 72: 9 red, 9 blue, 1 green; 4 red, 6 green, 5 blue; 3 green, 7 red, 2 blue\0"
"Game 73: 3 green, 9 red; 4 green, 15 red; 12 red, 2 blue; 14 red, 3 green\0"
"Game 74: 2 red, 6 blue, 1 green; 3 red, 6 blue; 1 green, 12 blue, 14 red\0"
"Game 75: 3 green, 18 red; 1 green, 7 red, 1 blue; 2 red, 2 green, 3 blue; 11 red; 2 red, 3 green, 2 blue\0"
"Game 76: 6 green, 2 red, 5 blue; 13 green, 5 blue; 5 blue, 1 red, 1 green\0"
"Game 77: 4 blue, 6 green, 3 red; 15 red, 1 green; 4 green, 11 red, 13 blue; 8 blue, 6 green, 9 red; 3 blue, 1 green, 11 red; 3 green, 3 red\0"
"Game 78: 11 green, 1 blue, 2 red; 7 red, 16 blue, 11 green; 9 blue, 10 red, 6 green; 1 green, 8 blue, 10 red; 8 blue, 6 red, 1 green\0"
"Game 79: 2 blue, 5 green, 4 red; 1 blue, 1 red, 1 green; 1 blue, 5 red, 10 green; 6 red, 3 green, 3 blue; 8 red, 9 green, 6 blue; 7 blue, 6 green, 13 red\0"
"Game 80: 10 green, 7 blue, 5 red; 5 red, 1 green, 6 blue; 8 blue, 2 red, 8 green\0"
"Game 81: 3 green, 10 red; 6 blue, 8 green, 14 red; 4 green, 4 blue, 13 red; 5 blue, 11 green, 6 red; 16 red, 8 green, 5 blue; 6 green, 18 red, 6 blue\0"
"Game 82: 13 red, 1 green, 7 blue; 8 green, 4 blue, 12 red; 18 red, 5 green, 3 blue; 13 red, 4 green, 9 blue\0"
"Game 83: 1 red, 3 green, 4 blue; 5 blue, 4 green, 1 red; 3 green, 1 red, 12 blue; 4 green, 11 blue\0"
"Game 84: 3 blue, 10 green, 2 red; 3 red, 8 blue; 11 blue, 12 red, 14 green; 2 red, 11 green, 2 blue\0"
"Game 85: 8 blue, 2 green, 1 red; 13 blue, 6 red; 3 blue, 5 green\0"
"Game 86: 16 red, 8 blue; 7 blue; 16 red, 16 blue, 1 green; 15 blue, 11 red; 2 green, 7 red, 5 blue\0"
"Game 87: 6 green, 9 blue, 4 red; 1 red, 1 green, 4 blue; 5 blue, 13 green, 3 red; 2 green, 4 red; 16 blue, 10 green, 3 red\0"
"Game 88: 1 blue, 14 red; 14 red, 3 blue, 8 green; 1 blue, 5 green\0"
"Game 89: 12 green, 14 blue, 3 red; 2 red, 3 blue, 3 green; 2 blue, 8 green; 1 red, 3 green, 15 blue; 3 red, 5 blue\0"
"Game 90: 3 blue, 17 red, 11 green; 2 red, 2 blue, 7 green; 7 blue; 8 blue, 4 green, 10 red; 1 blue, 4 red\0"
"Game 91: 10 red, 9 blue, 8 green; 5 blue, 10 red, 2 green; 11 red, 17 green, 7 blue; 12 blue, 16 red, 18 green; 20 green, 5 blue, 15 red\0"
"Game 92: 1 green, 14 red, 1 blue; 2 blue, 6 green; 9 red, 6 green; 5 blue, 5 red, 2 green; 3 blue, 3 green, 10 red; 5 blue, 1 red\0"
"Game 93: 10 green, 1 red, 6 blue; 16 red, 5 blue, 2 green; 3 red, 7 green, 11 blue; 12 green, 5 blue, 4 red; 8 green, 7 blue, 10 red; 1 red, 5 blue\0"
"Game 94: 3 blue, 1 red, 3 green; 1 blue, 4 green, 4 red; 9 green\0"
"Game 95: 3 green, 5 blue, 9 red; 2 green, 9 red, 2 blue; 12 red, 9 green; 11 green, 9 red, 9 blue; 9 blue, 6 green, 10 red; 13 red, 2 blue, 5 green\0"
"Game 96: 2 red, 19 blue, 2 green; 10 blue, 1 red, 2 green; 9 blue, 1 red; 2 green, 3 blue; 1 green, 1 red, 11 blue\0"
"Game 97: 6 green, 7 blue, 5 red; 7 green, 1 red, 11 blue; 6 green, 6 red, 5 blue; 2 red, 9 blue, 1 green\0"
"Game 98: 5 green, 8 red, 15 blue; 16 green, 9 blue, 8 red; 5 blue, 3 red, 2 green; 13 blue, 12 green, 4 red; 2 red, 15 green, 3 blue; 1 green, 11 blue, 2 red\0"
"Game 99: 1 green, 7 blue, 6 red; 16 blue, 9 red; 1 green, 17 red, 12 blue; 15 red, 7 blue; 8 blue, 14 red\0"
"Game 100: 5 blue, 11 red, 6 green; 11 red, 2 blue, 5 green; 6 blue, 6 green; 2 blue, 6 red, 15 green; 7 red, 4 blue, 7 green\0"
:DataListEnd
