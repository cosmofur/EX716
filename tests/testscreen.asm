I common.mc
L string.asm
L screen.asm
# When debugging, try to manually enter the screen query codes
#           [24;80Ru
# Where 24 is screen height and 80 is width.
@CALL ScrInit
@CALL ScrClear
@TTYNOECHO
@PUSH 0 @PUSH 0
@CALL ScrMove
@PRTS RullerStr
# For debug, disable CSICODE after screen INIT
#@PUSH "E" b0
#@POPI CSICODE
@PUSHI ScrWidth
@RTR     # /2
###@POPI CurX
@PUSHI ScrHeight
@RTR     # /2
###@POPI CurY
@MC2M 0 SAsize        # Start snake off with '1' body part
@CALL PutSD           # Save CurX and CurY to top of snake head
@MM2M SAdata CurX     # 0th index is always original X and 0+2 is original Y
@MM2M SAdata+2 CurY
@CALL UpdateCurs
:MainLoop
   # Test to see if the XLoc is still on screen (also allow for blank border)
   @PUSHI CurX
   @PUSHI CurY
   @CALL UpdateCurs
   @POPI CurY
   @POPI CurX
   @JMP MainLoop

:UpdateCurs
   @POPI UCReturn
   @POPI UCCurY
   @POPI UCCurX
   @READC UCCmdStr
   @PUSHI UCCurX
   @PUSHI UCCurY
   @CALL ScrMove
   @PRT "-"            #Clear any old 'X'
   #
   @PUSH "q" b0         # Quit on 'q'
   @CMPI UCCmdStr @POPNULL
   @JNZ NotQkey
      @TTYECHO
      @END
   :NotQkey
   @PUSH "w" b0
   @CMPI UCCmdStr @POPNULL
   @JNZ NotWkey
       @DECI UCCurY
       @JMP UCEndCase
   :NotWkey
   @PUSH "s" b0
   @CMPI UCCmdStr @POPNULL
   @JNZ NotSkey
       @INCI UCCurY
       @JMP UCEndCase
   :NotSkey
   @PUSH "a" b0
   @CMPI UCCmdStr @POPNULL
   @JNZ NotAkey
      @DECI UCCurX
      @JMP UCEndCase
   :NotAkey
   @PUSH "d" b0
   @CMPI UCCmdStr @POPNULL
   @JNZ NotDkey
      @INCI UCCurX
      @JMP UCEndCase
   :NotDkey
   :UCEndCase
#
# Now validate the UCCurX and UCCurY
   @PUSH 1
   @PUSHI ScrWidth  # Width - 1
   @SUBS 
   @CMPI UCCurX    # UCCurX - (Width - 1) =>  Flags
   @POPNULL
   @JGT OffRightSide
   @PUSH 2
   @CMPI UCCurX    # UCCurX - 2 => Flags
   @POPNULL
   @JLE OffLeftSide
   # Test to see if the YLoc is still on screen (Allow for Ruler line border)   
   @PUSH 1
   @PUSHI ScrHeight
   @SUBS
   @CMPI UCCurY    # UCCurY - Hieght => Flags
   @POPNULL
   @JGT OffBottomSide
   @PUSH 2
   @CMPI UCCurY    # UCCurY - 2 => Flags
   @POPNULL
   @JLE OffTopSide
   @JMP UCPrintX
   :OffRightSide
     @PUSH 1
     @SUBI ScrWidth
     @POPI UCCurX
     @JMP UCPrintX
   :OffLeftSide
     @MC2M 2 UCCurX
     @JMP UCPrintX
   :OffTopSide
     @MC2M 2 UCCurY
     @JMP UCPrintX
   :OffBottomSide
     @PUSH 1
     @SUBI ScrHeight
     @POPI UCCurY
     @JMP UCPrintX
   #
   :UCPrintX
   @PUSHI UCCurX
   @PUSHI UCCurY
   @CALL ScrMove
   @PRT "X"
   @PUSHI UCCurX
   @PUSHI UCCurY
   @PUSHI UCReturn
   @PUSH 0 @PUSH 0 @CALL ScrMove
   @PRTI UCCurX @PRT "-"
   @PUSH 5 @PUSH 0 @CALL ScrMove
   @PRTI UCCurY @PRT "-"
   @PUSH 10 @PUSH 0 @CALL ScrMove
   @PRTS UCCmdStr
   @RET
# Put Snake Data into array (X,Y)
#     We have no need for a 'pop' snake data, as snakes only 'grow'
:PutSD
@POPI PSDReturn   # Save Return Address
@PUSHI SASize
# Calculate the offsets for this index from top of array
@RTL      # Index * 2
@DUP
@POPI  SATmpXOff
@RTL      # Index * 2
@POPI  SATmpYOff
@PUSHI SAdata
@ADDI SATmpYOFF
# At this point stack will have X,Y,(SAdata+Yoffset)
# That's exactly when POPS makes most sense.
@POPS
# Now do the X value
@PUSHI SAdata
@ADDI SATmpXOFF
@POPS
#
@INCI SAsize 
@PUSHI PSDReturn
@RET
:PSDReturn 0
:SATmpXOFF 0
:SATmpYOFF 0




:UCCurX 0
:UCCurY 0
:UCReturn 0
:UCCmdStr 0 0
:RullerStr
"+----------------------------------------------------------------------------+" b0
:CurX 0
:CurY 0
:SCore 0
:SASize 0
# Clear a nice sized array 20 x 8 or 160 words
:SAdata
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
