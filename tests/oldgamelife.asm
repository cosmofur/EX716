# Game of Life.
# This is to demo a slightly more complex 'game' program.
# At this time, it does not include a useful editor so you have to compile in your starting board.
# See bellow
# But some of the ideas we are going to explore here.
#  1) Sub Routine (we already do this a lot with library, but here it will be in the main code)
#  2) 2D arrays. Our limited board will be a 70x23 array with fixed size. (to fix in screen)
#      We'll do more complex data structures like linked lists....later.
#
I common.mc
L mul.ld
L screen2.asm
#
=MapWidth 10
=MapHeight 6
@CALL WinInit
@CALL WinClear
@CALL SetUpBoard
@MC2M 0 LoopCount
:MainLoop
  @CALL WinRefresh
  @MC2M 0 CountLive
  @ForIfA2B Xidx 0 MapWidth OuterFor
     @ForIfA2B Yidx 0 MapHeight InnerFor
        @PUSHI Xidx @PUSHI Yidx
	@CALL CalcRules  # Set SubRoutine for expected return Codes
	@CMP 0           # Has no neighboors, started already dead
	@JMPZ NoChange
	@CMP 1           # Alive by itself...dies from lonelyness
	@JMPZ Dead
	@CMP 2           # Alive but only one neighboor...sorry need a village, dead
	@JMPZ Dead
	@CMP 3           # Alive with 2 neighboors, dodged a bullet.
	@JMPZ NoChange
	@CMP 4           # Alive with 3 neighboors, Nice and comfortable
	@JMPZ NoChange
	@CMP 5           # Alive with 4 neighoors...that's too crowded, sorry charlly dead
	@JMPZ Dead
	@CMP 6           # Currently dead, but has exactly 3 neighboors. Happy Birthday
	@POPNULL
	@JMPZ Alive
	@JMP PastFate
        :Dead
	@PUSHI Xidx @PUSHI Yidx @PUSH 0   #Put zero for 'dead' at this cell	
	@CALL CellSet
	@PUSHI Xidx @PUSHI Yidx @PUSH SpaceStr
	@CALL WinWrite
	@DECI CountLive
	@JMP PastFate
	:Alive
	@StackDump
	@PUSHI Xidx @PUSHI Yidx @PUSH 1   #Put zero for 'alive' at this cell	
	@CALL CellSet
	@PUSHI Xidx @PUSHI Yidx @PUSH StarStr
	@CALL WinWrite	
	@INCI CountLive
	@JMP PastFate
	:NoChange
	# Nothing to do here. It already alive (or dead) and nothing changed.
   :PastFate
   @POPNULL
   @NextNamed Yidx InnerFor
 @NextNamed Xidx OuterFor
 @CALL WinRefresh
 @INCI LoopCount
 @PUSH 0
 @CMPI CountLive
 @POPNULL
 @JMPZ EndGame
@JMP MainLoop
:EndGame
@PRTLN "End of game"
@END

#
# Our First function is 'CellSet' which means we need to calculate the Array position of an X*Y value
# Note that to make 'local' variables unique to this function we start each one with 'CS'
:CellSet
  @POPI CSReturnAddr
  @POPI CSNewVal
  @POPI CSYval
  @POPI CSXval
  @PUSHI CSYval
  @PUSH MapWidth    # Double width as its MapWidth Words long, not Bytes
  @PUSH MapWidth
  @ADDS
  @CALL MUL         # Y * width + X will be the offset
  @PUSHI CSXval     # Need to double up Xvals as cells are words not bytes
  @PUSHI CSXval
  @ADDS
  @ADDS
  @ADD MapMemory
  @POPI CSCellSpot
  @PUSHI CSNewVal
  @POPII CSCellSpot
  @PUSHI CSReturnAddr
  @RET
# Local storage for CellSet
:CSReturnAddr 0
:CSNewVal 0
:CSYval 0
:CSXval 0
:CSCellSpot 0
# We will also need a 'CellGet' which will return the value in the named cell.
# Any invalid index ( less than 0 or more than valid dimentions will just return zero
# Note that to make 'local' variables unique to this funciton we start each one with 'CG'
# 
:CellGet
  @POPI CGReturnAddr
  @POPI CGYval
  @POPI CGXval
  @PUSHI CGYval @CMP MapHeight @POPNULL  # if Y is > Height result will be N-flag
  @JMPN CGAlwaysZero
  @PUSHI CGXval @CMP MapWidth @POPNULL   # if X is > Width result will be N-Flag
  @JMPN CGAlwaysZero
  @PUSHI CGYval
  @PUSH MapWidth     # Words of 2 bytes long, so we double our width.
  @PUSH MapWidth
  @ADDS
  @CALL MUL          # Y*Width + X == Cell Offset
  @ADDI CGXval       # We also double our width here.
  @ADDI CGXval
  @ADD MapMemory
  @POPI CGCellSpot
  @PUSHII CGCellSpot
  @PUSHI CGReturnAddr
  @RET              # Normal Return

  :CGAlwaysZero
  @PUSH 0
  @PUSHI CGReturnAddr
  @RET              # Always Zero return
# Local Storage
:CGReturnAddr 0
:CGYval 0
:CGXval 0
:CGCellSpot 0
#
# Our next function is CalcRules
#  To explain this, we need to go over Conways's game of life rules.
#  Any Live Cell with less than 2 neighboors, dies
#  Any live Cell with 2 or 3 neighboors Lives
#  Any Live Cell with more than 3 neighboors dies
#  Any Dead Cell with exactly 3 live neighboors is re-born as a live cell.
#
#  Our coutiung will then vary based on if the current cell is alive or dead.
#   If its currently alive, we will just count IT and the adjacent cells. (1 to max of 5)
#   If its currently dead, we will count DOWN from 9, which means we'll return exactly 6 if there are 3 live neighboors
#
:CalcRules
@POPI CRReturnAddr
@POPI CRYval
@POPI CRXval
#@PRT "("
#@PRTI CRXval
#@PRT ","
#@PRTI CRYval
#@PRT ")"
@MC2M 0 CRCellCount
# First count up the alive cells N,E,S and W of current
# Look to Cell 'North' of current
@PUSHI CRXval
@PUSHI CRYval
@SUB 1
@CALL CellGet   # (X, Y-1) Return's 1 is alive.
#@PRT " N:"
#@PRTTOP
@ADDI CRCellCount
@POPI CRCellCount   # CRCellCount + result
#Look to Cell 'East' of current
@PUSHI CRXval
@ADD 1
@PUSHI CRYval
@CALL CellGet   # (X+1, Y)
#@PRT " E:"
#@PRTTOP
@ADDI CRCellCount
@POPI CRCellCount   # CRCellCount + result
# Look at Cell 'South' of current
@PUSHI CRXval
@PUSHI CRYval
@ADD 1
@CALL CellGet  # (X, Y+1)
#@PRT " S:"
#@PRTTOP
@ADDI CRCellCount
@POPI CRCellCount   # CRCellCount + result
# Look at Cell 'west' of current
@PUSHI CRXval
@SUB 1
@PUSHI CRYval
@CALL CellGet  # (X-1, Y)
#@PRT " W:"
#@PRTTOP
#@PRT ","
@ADDI CRCellCount
@POPI CRCellCount   # CRCellCount + result
#@PRT "CellCount:"
#@PRTI CRCellCount
#@PRTNL
#
# Now we know the count of adjacent live cells.
# We have to check if the current cell is alive as well.
@PUSHI CRXval @PUSHI CRYval @CALL CellGet
CMP 0
@JMPZ DoDeadLogic
# Here means 'alive' so add 1 to total alive count
@INCI CRCellCount
@PUSHI CRCellCount
@PUSHI CRReturnAddr

@RET
# Here means current cell is 'dead' so we do reverse math.
:DoDeadLogic
@PUSH 9           # On entry CellCount is between 0 and 4
@SUBI CRCellCount # 9 - 3 == 6 which is the only value that will result in a birth.
@PUSHI CRReturnAddr

@RET
#
# Initilzies the Window with the initial setup
:SetUpBoard
@ForIfA2B Xidx 0 MapWidth Outersetup
   @ForIfA2B Yidx 0 MapHeight Innersetup
      @PUSHI Xidx
      @PUSHI Yidx
      @CALL CellGet
      @CMP 0
      @POPNULL
      @PUSHI Xidx
      @PUSHI Yidx      
      @JMPZ SUSpace
         @PUSH StarStr
         @JMP SUSkipFwrd
      :SUSpace
         @PUSH SpaceStr
      :SUSkipFwrd
      @CALL WinWrite
   @NextNamed Yidx Innersetup
@NextNamed Xidx Outersetup
@RET
      

# Local variables
:CRReturnAddr 0
:CRYval 0
:CRXval 0
:CRCellCount 0
#
# Main Loop Variables
:Xidx 0
:Yidx 0
:CountLive 0
:SpaceStr " " b0
:StarStr "*" b0
:LoopCount 0
##
##
## Now lets define our starting memory
# We'll Store a few diffrent maps here, Just rename the one you want to see
# as 'MapMemory' to make it the active map.
# This first map is of a simple 'glider'
:MapMemory3
0 1 2 3 4 5 6 7 8 9
10 11 12 13 14 15 16 17 18 19
20 21 22 23 24 25 26 27 28 29
30 31 32 33 34 35 36 37 38 39
40 41 42 43 44 45 46 47 48 49
50 51 52 53 54 55 56 57 58 59

:MapMemory
# 1 2 3 4 5 6 7 8 9
0 0 0 0 0 0 0 0 0 0  # 0
0 0 1 0 0 0 0 0 0 0  # 1
0 0 1 0 0 0 1 1 1 0  # 2
0 0 1 0 0 0 0 0 0 0  # 3
0 0 0 0 0 0 0 0 0 0  # 4
0 0 0 0 0 0 0 0 0 0  # 5
:MapMemory2
# Our array is 70x23
# 1 2 3 4 5 6 7 8 9 A 1 2 3 4 5 6 7 8 9 B 1 2 3 4 5 6 7 8 9 C 1 2 3 4 5
# 6 7 8 9 D 1 2 3 4 5 6 7 8 9 E 1 2 3 4 5 6 7 8 9 F 1 2 3 4 5
# L0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L1
0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L2
0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L3
0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L4
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L5
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L6
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L7
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L8
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L9
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L10
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L11
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L12
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L13
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L14
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L15
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L16
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L17
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L18
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L19
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L20
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L21
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L22
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# L23
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

