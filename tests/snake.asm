I common.mc
L screen.ld
L random.ld

# Putting this hear to take care of bugs which jump to 0000
@PRT "Bad Entry:"
@StackDump
@END

:PackNum   # Given two number X and Y, packs lower bytes into one number
# Top of Stack will go to 'high' byte and SFT will go to 'low' byte
@POPI SNReturn
@SWP           # It is easier to deal with the Low Byte first
@AND 0xff
@POPI PNLow
@AND 0xff
@POPI PNHigh
@PUSHI PNLow
@PUSHI SNReturn
@RET
:PNLow b0
:PNHigh 0      # We are wasteing one byte, the 'high' byte of PNHigh as that will also be zero
#

:SplitNum  # Given XY word, return two words X and Y
@POPI SNReturn
@POPI LowByte   
@PUSHI HighByte   # Y value starts at HighByte
@AND 0xff         # Only care about the lower byte part of Y
@PUSHI LowByte    # Now get the X part
@AND 0xff         # Mask off the remainder of the Y part
@SWP
@PUSHI SNReturn
@RET
:SNReturn 0
#
#
:ClearOld
@PUSHI CHX
@PUSHI CHY
@CALL WinCursor
@PRT " "
@RET
#
# DrawPlay
:DrawPlay
@PUSHI CHX
@PUSHI CHY
@CALL WinCursor
@PRT "@"
@RET

:Init
@CALL WinClear
@CALL WinHideCursor
@MA2V 0 Score
@MA2V 2 HeadIdx
@MA2V 0 TailIdx
#
# Initilzie CX,CY to center of screen.
@PUSHI WinWidth
@RTR
@POPI CHX
@PUSHI WinHeight
@RTR
@POPI CHY
@PUSHI CHX
@RTR
@PUSHI CHY
@CALL WinCursor
# Prompt the user to enter two characters 'any' and <enter>
# We'll use the human reaction time between these two to create a unique seed for random
@PRT "Hit S<ENTER> to start:"  # We are cheating here by suggesting an 'S' But any will do
@PUSH 0
@WHILE_ZERO
  @POPNULL
  @INCI Rseed
  @READCNW CHIN
  @PUSHI CHIN
  @ADDI Rseed
  @POPI Rseed
  @PUSHI CHIN
@ENDWHILE
@POPNULL @PUSH 0
# Now look only of a <ENTER>
@WHILE_NEQ_A 10
  @POPNULL
  @INC2I Rseed
  @READCNW CHIN
  @PUSHI CHIN
  @DUP  
  @ADDI Rseed
  @POPI Rseed 
@ENDWHILE
@POPNULL
@PUSHI Rseed
@CALL rndsetseed
@CALL WinClear
@TTYNOECHO
@RET
:CHX 0
:CHY 0
:RFX 0
:RFY 0
:PRX 0
:PRY 0
:RVal 0
:Rseed 0
:CHIN  0 0
:Continue 0
:HeadIdx 0
:TailIdx 0
:NULL 0
#
:Main

@CALL Init

# This first call to Insert sets our initial length of snake to 1
@CALL InsertHead

@CALL RandFood
#
@MA2V 0 CHIN       # CHIN[0]=0
@MA2V 1 Continue
@PUSHI Continue
@LOOP
   @READCNW CHIN    # This is the No Wait version of Read Character. 0 is no input is waiting.
   @PUSHI CHIN
   @SWITCH
       @CASE 0x0061   # "a"
          @POPNULL
          @PUSHI CHX
	  @IF_GT_A 0
	     @DECI CHX
	  @ENDIF
	  @POPNULL
	  @CBREAK
       @CASE 0x0064   # "d"
          @POPNULL
          @PUSHI CHX
	  @IF_LT_V WinWidth
	     @INCI CHX
	  @ENDIF
	  @POPNULL
	  @CBREAK
       @CASE 0x0077   # "w"
          @POPNULL
          @PUSHI CHY
	  @IF_GT_A 0
	    @DECI CHY
	  @ENDIF
	  @POPNULL
	  @CBREAK
       @CASE 0x0073   # "s"
          @POPNULL
          @PUSHI CHY
	  @IF_LT_V WinHeight
	    @INCI CHY
	  @ENDIF
	  @POPNULL
	  @CBREAK
       @CASE 0x0051  # "Q"        Quit
          @MA2V 0 Continue
	  @POPNULL
          @CALL WinShowCursor
          @PUSH 0
          @PUSHI WinHeight
          @CALL WinCursor
	  @CBREAK
       @CASE 0x0072   # "r"
          @POPNULL
          @CALL WinClear
          @CALL WinHideCursor
          @PUSHI RFX @PUSHI RFY
          @CALL WinCursor
          @PRTI RVal
          @CALL ScoreBoard
          @ForIV2V Index TailIdx HeadIdx
              @PUSHI Index
              @IF_GE_V MaxLength
                 @POPNULL
                 @PUSH 0
              @ENDIF              
              @PUSH SnakeData      # PUSH SnakeData[Index]
              @ADDS
              @PUSHS
              @CALL SplitNum
              @CALL WinCursor
              @PRT "s"
          @NextBy Index 2
          @PUSHI CHX @PUSHI CHY
          @CALL WinCursor
          @PRTI "@"
          @CBREAK
       @CASE 0x006C   # "l"
          @POPNULL                                                 # 0
          @CALL ListData
          @CBREAK
       @CDEFAULT
          # Do nothing
	  @POPNULL
	  @CBREAK
    @ENDCASE
    @IF_EQ_VV CHX RFX
       @IF_EQ_VV CHY RFY
          @ForIA2V Null 0 RVal
             @CALL InsertHead
             @INC2I HeadIdx
	  @Next Null
	  @PUSHI Score
	  @ADDI RVal
	  @POPI Score
          @CALL ScoreBoard
          @CALL RandFood
       @ENDIF
    @ENDIF
    @CALL InsertHead
    @POPNULL
    @PUSHI Continue
@UNTIL_ZERO
@TTYECHO
@END
#
# Put the CHX,CHY at the tail

:InsertHead
@IF_EQ_VV CHX PRX
   @IF_EQ_VV CHY PRY
      # Still looking at same as last instance point. Do nothing
      @RET
   @ENDIF
@ENDIF
# Its a new location, deal with it.
@PUSHI TailIdx @ADD SnakeData @PUSHS  # PUSH SnakeData[TailIdx]
@IF_NOTZERO
   @CALL SplitNum                        # Turn compressed XY into 2 numbers
   @CALL WinCursor
   @PRT " "
@ELSE
   @POPNULL
@ENDIF
# Now reset the old data to zero
#@PUSH 0
#@PUSHI TailIdx
#@ADD SnakeData
#@POPS
#
# Then put an 's' where the head 'used' to be. 
#
#@PUSHI HeadIdx
#@ADD SnakeData
#@PUSHS
#@CALL SplitNum
@PUSHI PRX @PUSHI PRY
@CALL WinCursor
@PRT "s"

@MV2V CHX PRX
@MV2V CHY PRY

#
# Now we move both TailIdx and HeadIdx up one word and insert the new location for head at HeadIdx
#
@PUSHI HeadIdx @ADD 2     # We rotate Idx's from 0 to 1023 and back again to zero
@IF_GE_V MaxLength
   @POPNULL @PUSH 0
@ENDIF
@POPI HeadIdx
@PUSHI TailIdx @ADD 2
@IF_GE_V MaxLength
   @POPNULL @PUSH 0
@ENDIF
@POPI TailIdx
#
#
@PUSHI CHX @PUSHI CHY @CALL PackNum  # Push compacted X,Y onto stack
#
# Before we use this to print the new head location, lets make sure we didn't bump into ourbody
#
@DUP             # Save the COMPXY for laster printing
@CALL InBody     # InBody is a function to see if COMPXY is in the list already.
@IF_ZERO         # Zero means no match, so we're good.
  @POPNULL
  @PUSHI HeadIdx
  @ADD SnakeData   # SnakeData[HeadIdx]=CompactXY
  @POPS          # Save that DUP'ed COMPXY to new HeadIdx address.
  #
  # Now print the 'Head'
  @PUSHI CHX @PUSHI CHY @CALL WinCursor
  @PRT "@"
@ELSE
  # Oh No...we lost Blink that 10 times to user then exit
  @ForIA2B Null 0 10
     @PUSH 5 @PUSH 10 @CALL WinCursor
     @PRT "-----You Lost-----"
     @ForIA2B Index 0 500 @Next Index     # 500 Ops delay..no real time delay yet
     @PUSH 5 @PUSH 10 @CALL WinCursor
     @PRT "                  " 
     @ForIA2B Index 0 500 @Next Index
  @Next Null
  @PUSH 0 @PUSH 11 @CALL WinCursor
  @CALL WinShowCursor
  @TTYECHO
  @END
@ENDIF  
# We pass no parameters in, so return address should already be on stack.
@RET

#
# InBody takes a COMPXY number and searchs between head and tail for any matches
# it returns the Index if there is one, or zero if none.
:InBody
@POPI IBReturn
@POPI CMPVAL
@ForIV2V IBIndex TailIdx HeadIdx
  @PUSHI IBIndex
  @IF_GT_V MaxLength
     @POPNULL
     @PUSH 0
     @MA2V 0 IBIndex
  @ENDIF
  @ADD SnakeData
  @PUSHS
  @IF_EQ_V CMPVAL
     @POPNULL
     @PUSHI IBIndex
     @PUSHI IBReturn
     @RET
  @ENDIF
  @POPNULL
@NextBy IBIndex 2
@PUSH 0
@PUSHI IBReturn
@RET
:CMPVAL 0
:IBReturn 0
:IBIndex 0

# Randomized Food location and value
:RandFood
@PUSH 1
@WHILE_NOTZERO
  @POPNULL
  @PUSHI WinWidth
  @SUB 4
  @CALL rndint
  @ADD 2
  @POPI RFX
  @PUSHI WinHeight
  @SUB 4
  @CALL rndint
  @ADD 2
  @POPI RFY
  # The following test is to make sure we put the new food someplace there no tail
  @PUSHI RFX @PUSHI RFY @CALL PackNum
  @CALL InBody          # This will leave zero on stack is RFX,RFY aren't part of snake already
@ENDWHILE
@POPNULL
@PUSH 9
@CALL rndint    # Return 0-8
@ADD 1   # Range is 1-9
@POPI RVal
@PUSHI RFX
@PUSHI RFY
@CALL WinCursor
@PRTI RVal
@RET
#
# Print ScoreBoard
:ScoreBoard
@PUSH 5 @PUSH 1
@CALL WinCursor
@PRT "Score: " @PRTI Score @PRT "  "
@RET

:LowByte b0
:HighByte b0
:BufferByte b0  # Overflow from when we push a word the 'HighByte'
:SnakeLength 0
:InsertPoint 0
:HeadPoint 0
:SnakeNewLength 0
:MaxLength 2048
:Score 0
:Index 0
:Index2 0
:Null 0
# Reserve 2048 for SnakeData
:SnakeData
# Each line here is 64 2 byte words. Or 128 bytes long x 16 lines
# We'll only use the low bytes for the CX/Y and mask the high bytes
. SnakeData+4096
#
# Just a debug listing of the tail data
:ListData
@PUSH 0 @PUSH 0 @CALL WinCursor                                # 0
@PRT "Tail: " @PRTI TailIdx @PRT " To " @PRTI HeadIdx @PRT "    \n"      # 0
@ForIV2V LDIndex TailIdx HeadIdx
   @PUSHI LDIndex                                                # +1
   @IF_GT_V MaxLength
     @PRTLN "Hit Max reset to Zero"                           # 1
     @POPNULL                                                 # 0
     @PUSH 0                                                  # 1
   @ENDIF
     @POPI LDIndex                                                 # 0
     @PUSHI LDIndex                                                # 1
     @ADD SnakeData                                              # 1
     @PUSHS                                                      # 1
     @PRT "(" @PRTI LDIndex @PRT ") "
     @PRT "CMPXY: " @PRTHEXTOP @PRTSP
     @CALL SplitNum                                              # 2
     @SWP                                                        # 2
     @PRTHEXTOP @PRT "," @POPNULL                                # 1
     @PRTHEXTOP @PRTNL @POPNULL                                  # 0
@NextBy LDIndex 2
@RET
:LDIndex 0

# Last '.' needs to identify the entry point of the program
. Main
