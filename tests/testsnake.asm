I common.mc
L string.asm
L screen.asm
L random.asm
#
# This test is for a simple version of the classic Snake game
#
# For Debugging in non ascii terminal, past this to define the fake screen size.
#    [24;80Ru
#
# Key Logic Layout
#
#    1) Init screen and Variables
#    2) Put a random food partical somewhere.
#    3) Main loop:
#            Erase Snake Tail
#            Read Key for New Snake head location
#            Check for lose condition
#                 T: End
#            Shift Snake data down one.
#            Check for Food
#                 T: Grow Snake by food size.
#            Print Snake
#
# Subroutens we will need:
#
#   ReadKeyBoard()
#   CreateFood()
#   DisplaySnake()
#   GrowSnake()
#   ShiftArray()
#   RandomNumber(1 to Range)
#
#   
#  Main Init
#
# Initilzie the random number generator.
@PRT "Enter a game number(Seed Random):"
   @READI NewSeed
   @PUSHI NewSeed
   @CALL rndsetseed
#  Setup screen, clear it and set terminal to No Echo
   @CALL ScrInit
   @CALL ScrClear
   @TTYNOECHO
# Print a line across top of screen for info bar
@PUSH 1 @PUSH 1 @CALL ScrMove
@ForIfA2V RullerIndex 1 ScrWidth RullerLoop
   @PRT "-"
@NextNamed RullerIndex RullerLoop
# Center the original Snake Head location save it as first item in array.
  @PUSHI ScrWidth @RTR @POPI CURX        # CURX = ScrWidth/2
  @PUSHI ScrHeight @RTR @POPI CURY       # CURY = ScrHeight/2
  @MC2M 2 ArryIndx
  @MM2M CURX ArryBuff                    # Array[0,0]=CURX
  @MM2M CURY ArryBuff+2                  # Array[0,1]=CURY
  @MM2M CURX ArryBuff+4 
  @MM2M CURY ArryBuff+6 
  @MM2M CURX ArryBuff+8 
  @MM2M CURY ArryBuff+10
  @PUSHI ArryBuff                         # Setup TailX/Y to point to 'end' of snake (which starts as same as head)
  @POPI TailX                            # TailX == Array[0,0]
  @PUSHI ArryBuff+2
  @POPI TailY                            # TailY == Array[0,1]
  @CALL CreateFood
   
# Main Game Loop
:mainloop
   @CALL DisplaySnake                    # DisplaySnake handles the input IO and display. But not game end condition.
   @CALL DebugPrint
   @JMP mainloop       # Loop forever until exit condition.

# ReadKeyBoard
#  Reads the keyboard for directions and also possible quit commands
:RKReturn 0
:RKStrIn 0 0
:CXIdx 0
:CYIdx 0
:ReadKeyBoard
  @POPI RKReturn
  @PUSH ArryBuff        # Keyboard commands can only change the snake's head values (index 0)
  @DUP    @POPI CXIdx   # CXIdx is pointer to current Array[ArryIndx,0]
  @ADD 2  @POPI CYIdx   # CYIdy is pointer to current Array[ArryIndx,1]
  @CALL DebugPrint
  @READC RKStrIn        # Read on character without echo from keyboard
  # Start of Case like logic for keyboard.
  @PUSH "q" b0          # Turn Byte 'q' into Word 00'q'
  @CMPI RKStrIn @POPNULL
  @JNZ NotQKey          # If RKStrIn == "q" then
      @PRT "Quit"
      @TTYECHO          #Turn Echo back on
      @END              # Exit program
  :NotQKey
  @PUSH "w" b0
  @CMPI RKStrIn @POPNULL
  @JNZ NotWKey          # If RKStrIn == "w" then
      @PUSH 1
      @PUSHII CYIdx     # Array[ArrayIndex,1]--
      @SUBS
      @POPII CYIdx
      @JMP EndCase
  :NotWKey
  @PUSH "s" b0
  @CMPI RKStrIn @POPNULL
  @JNZ NotSKey          # If RKStrIn == "s" then
      @PUSHII CYIdx     # Array[ArrayIndex,1]++
      @ADD 1
      @POPII CYIdx
      @JMP EndCase
  :NotSKey
  @PUSH "a" b0
  @CMPI RKStrIn @POPNULL
  @JNZ NotAKey          # If RKStrIn == "a" then
      @PUSH 1
      @PUSHII CXIdx     # Array[ArrayIndex,0]--
      @SUBS
      @POPII CXIdx
      @JMP EndCase
  :NotAKey
  @PUSH "d" b0
  @CMPI RKStrIn @POPNULL
  @JNZ EndCase          # If RKStrIn == "d" then
      @PUSH 1
      @PUSHII CXIdx     # Array[ArrayIndex,0]++
      @ADDS
      @POPII CXIdx
      @JMP EndCase
:EndCase
# For ease, keep CURX and CURY updated as well.
@PUSHII CXIdx
@POPI CURX
@PUSHII CYIdx
@POPI CURY
@PUSHI RKReturn
@RET
#
# CreateFood calculates a random location for food.
#
:CreateFood
   # We want the random food location to be on screen and not too close to the edges
   @PUSH 3
   @SUBI ScrWidth   # ScrWidth - 3
   @CALL rndint
   @ADD 1
   @POPI FoodX      # FoodX = 1+RNDINT(ScrWidth - 3)
   @PUSH 3
   @SUBI ScrHeight   # SrcHeight - 3
   @CALL rndint
   @ADD 2            # Want to avoid status line on top
   @POPI FoodY       # FoodY = 2+RNDINT(ScrHeight - 3)
   @PUSHI FoodX @PUSHI FoodY
   @CALL ScrMove
   @PRT "F"          # Print "F" at FoodX,FoodY
   @RET
#
# DisplaySnake, prints the snake
#
:DSArryPtr 0
:DSIndex 0

:DisplaySnake
   # First erase old snake head.
   	
   # If ArryIndx > 0, we need to 'shift' the array.
   @PUSHI ArryIndx
   @CMP 0 @POPNULL
   @JMPZ NoShiftNeeded
     @CALL ShiftArray
   :NoShiftNeeded
   @CALL ReadKeyBoard
   # Test for food
   @PUSHI CURX
   @CMPI FoodX @POPNULL
   @JNZ NoFood
   @PUSHI CURY
   @CMPI FoodY @POPNULL
   @JNZ NoFood
      # Both FoodX and FoodY matches so we found food.
      @CALL GrowSnake
      @CALL CreateFood      
   :NoFood
   @MC2M ArryBuff DSArryPtr
   @PUSHII TailX  @PUSHII TailY @CALL ScrMove @PRT " "   
   @PUSHI CURX @PUSHI CURY @CALL ScrMove @PRT "S"
   @ForIfA2V DSIndex 0 ArryIndx NextTail
      @PUSHII DSArryPtr    # PUSH Array[Index,0]
      @INC2I DSArryPtr
      @PUSHII DSArryPtr    # PUSH Array[Index,1]
      @INC2I DSArryPtr
      @CALL ScrMove
      @PRT "s"	
   @NextNamed DSIndex NextTail

 @RET
#
# GrowSnake procedure Adds one to the ArryIndx and copies the tail data to new cell
:GSPtr 0
:GrowSnake
  @PUSHI ArryIndx @RTL @RTL    # PTR = Index*(4 Bytes) + ArrayBuff
  @ADD ArryBuff
  @POPI GSPtr        # GSPtr points to offset of index + address of buffer
  @PUSHII GSPtr      # Save on stack current Array Tails X and Y
  @INC2I GSPtr 
  @PUSHII GSPtr
  @SWP               # Swap their order becuase we want X first
  @INC2I GSPtr       # Save the X value at Arry(Index+1,0)
  @POPII GSPtr
  @INC2I GSPtr       # Save the Y Value at Arry(Index+1,1)
  @POPII GSPtr
  @INCI ArryIndx     # Name make ArryIndx point to new tail
@RET

# ShiftArray moves all the array data up one step closer to the tail
:SAPtr 0
:SBPtr 0
:SAIndex1 0
###############
:ShiftArray
# Set SAPtr to 'last' entry of snake data so we can work backwards
#  SAPtr = (ArryBuff * 8) + ArryBuff
@PUSHI ArryIndx
@RTL @RTL   # There are 4 bytes in each XY entry, so Left Shift 2
@ADD ArryBuff
@POPI SBPtr
@PUSH 4
@SUBI SBPtr # SAPtr = SBPtr - 4
@POPI SAPtr
# Save what ever last entry way befor as new TailX,Y
@PUSHII SBPtr @POPI TailX
@PUSHI SBPtr @ADD 2 @PUSHS @POPI TailY   # This is how to do math on address and save new value
@ForIfA2V SAIndex1 0 ArryIndx SAForLoop
   @PUSHII SAPtr @POPII SBPtr         # Save the X part of A pointer to B pointer
   # This line is a little tricky.
   #  Aval=( [ SAPtr + 2]); Bval= SBPtr + 2; [Bval] = Aval
   @PUSHI SAPtr @ADD 2 @PUSHS  # Aval (on stack)
   @PUSHI SBPtr @ADD 2         # Bval (on stack)
   @POPS                       # Put Aval at addrss of Bval, Saves Y part of A to B
   @MM2M SAPtr SBPtr           # Save A pointer as Future B pointer
   @PUSHI 4 @SUB SAPtr @POPI SAPtr  # Mova A pointer down 2 words.
@NextNamed SAIndex1 SAForLoop 
@RET

:DebugPrint
@PUSH 1 @PUSH 1 @CALL ScrMove
@PRT "(X,Y)=" @PRTI CURX @PRT "," @PRTI CURY
@PRT " FoodXY=" @PRTI FoodX @PRT "," @PRTI FoodY
@PRT " TailSize=" @PRTI ArryIndx
@PRT " HeadXY=" @PRTI ArryBuff @PRT "," @PRTI ArryBuff+2 @PRT "-----"
@PRT " TailX=" @PRTI TailX @PRT "," @PRT " TailY=" @PRTI TailY
@RET

	

# Storage
:ArryIndx 0
:CURX 0
:CURY 0
:RullerIndex 0
:NewSeed 0
:FoodX 0
:FoodY 0
:TailX 0
:TailY 0

:ArryBuff
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

