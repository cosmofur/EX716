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
M INC2 @PUSHI %1 @ADD 2 @POPI %1
M DEC2 @PUSHI %1 @SUB 2 @POPI %1
=MapWidth 10
=MapHeight 6
@CALL WinInit
@CALL WinClear
@CALL SetUpBoard
@MC2M 0 LoopCount
:MainLoop
  @CALL WinRefresh
  @MC2M 0 CountLive
  @MC2M 0 AliveListCount
  @MC2M 0 DeadListCount
  @MC2M MapMemory MapPointer
  @ForIfA2B Yidx 0 MapHeight OuterFor
     @ForIfA2B Xidx 0 MapWidth InnerFor
        # Map Pointer is pointing at the 'active' cell we want to count up the 8 cells around it.
	@MC2M 0 Neighboors
	@PUSHI Xidx @CMP 0 @POPNULL              # If X == 0 skip west tests
	@JMPZ SkipW
          @PUSHI Yidx @CMP 0 @POPNULL            # If Y == 0 skip north west tests
	  @JMPZ SkipNW
	    @PUSHI MapPointer @SUB 2             # NW is PTR - width*2 - 2
            @SUB MapWidth @SUB MapWidth          # We SUB MapWidth twice since Cells are 2 bytes long
	    @POPI NeighPtr @PUSHII NeighPtr      # This is equivlent to Push to stack Map[NeighPtr]
	    @ADDI Neighboors @POPI Neighboors   #Add Value to Neighboors
	  :SkipNW
	  # Safe to do the basic "West" test.
            @PUSHI MapPointer @SUB 2 @POPI NeighPtr @PUSHII NeighPtr
	    @ADDI Neighboors @POPI Neighboors
	  @PUSHI Yidx @ADD 1 @CMP MapHeight @POPNULL    # If (Y+1) == MapHeight skip South West test
	  @JMPZ SkipSW
	    @PUSHI MapPointer @SUB 2             # SW is PTR + width*2 - 2
            @ADD MapWidth @ADD MapWidth          # We ADD MapWidth twice since Cells are 2 bytes long
	    @POPI NeighPtr @PUSHII NeighPtr     # Push Map[Ptr]
	    @ADDI Neighboors @POPI Neighboors   #Add Value to Neighboors
	  :SkipSW                               # More than one label can point to same location
	  :SkipW
	# Now do same tests for the East Side
        @PUSHI Xidx @ADD 1 @CMP MapWidth @POPNULL      # If ( X+1) == WinWidth then skip East tests
	@JMPZ SkipE
	  @PUSHI Yidx @CMP 0 @POPNULL           # If Y == 0 skip north east tests
	  @JMPZ SkipNE
	  @PUSHI MapPointer @ADD 2
	  @SUB MapWidth @SUB MapWidth           # Since Cells are 2 bytes long to get NE we Sub 2xWidth+2
	  @POPI NeighPtr @PUSHII NeighPtr       # Push Map[Ptr]
	  @ADDI Neighboors @POPI Neighboors     # Add values stores there to Neighboors
	:SkipNE
	# Save to do basic "East" test.
	  @PUSHI MapPointer @ADD 2 @POPI NeighPtr @PUSHII NeighPtr
	  @ADDI Neighboors @POPI Neighboors    # Get value at PTR + 2 and add to Neighboors
	@PUSHI Yidx @ADD 1 @CMP MapHeight @POPNULL  # if Y+1 == MapHeight Skip to NorthSouth
	@JMPZ SkipNS
	  @PUSHI MapPointer @ADD 2              # SE is +2 + 2*Width
	  @ADD MapWidth @ADD MapWidth
	  @POPI NeighPtr @PUSHII NeighPtr       #  Push Map[ptr]
	  @ADDI Neighboors @POPI Neighboors
	:SkipNS                                 # We are using 2 lables here but they basicly mean same thing
	:SkipE
	# Now do the Northern Cell Test if we can.
	@PUSHI Yidx @CMP 0 @POPNULL
	@JMPZ SkipNorth                         # Can test north is Y == 0
	  @PUSHI MapPointer
	  @SUB MapWidth @SUB MapWidth           # N = PTR - 2*Width
	  @POPI NeighPtr @PUSHII NeighPtr       #  Push Map[Ptr]
	  @ADDI Neighboors @POPI Neighboors     # Add value to Neighboors
	:SkipNorth
	@PUSHI Yidx @ADD 1 @CMP MapHeight @POPNULL  # If Y+1 == Heigh skip to result
	@JMPZ UseCount
	  @PUSHI MapPointer
	  @ADD MapWidth @ADD MapWidth           # S = PTR + 2*Width
	  @POPI NeighPtr @PUSHII NeighPtr       # Push Map[Ptr]
	  @ADDI Neighboors @POPI Neighboors

        :UseCount
#	@PRT "("
#	@PRTI Xidx
#	@PRT ","
#	@PRTI Yidx
#	@PRT "): "
#	@PRTI Neighboors
#	@PRT " - "
	# At this point we have the count of live cells around the test point
	# The Rules for Game of Life read.
	# If a Cell is alive
	#    It will die if <= 2 neighboors
	#    It will also die if >= 4 neighboors
	#    If in range 2-3 it will remain alive.
	# If a Cell if currently dead
	#    If will remain dead if has anything but 3 neighboors
	#    if it has 3, it will wake up and be born alive.
	#
	# First test to see if we're currently alive or dead.
	@PUSHII MapPointer @CMP 0 @POPNULL
	@JMPZ CurrentlyDead                  # If cell is zero, then we're already dead.
	#
	# if here, then we're currently alive.
	# We remain alive if Neighboors == 2 or 3 only.
	@PUSHI Neighboors
	@CMP 2
	@JMPZ RemainsAlive
	@CMP 3
	@JMPZ RemainsAlive
	#
	# Dropping here, means dead.
	@POPNULL        # Clean up from the CMP
#	@PRT "X "
	@PUSH MapPointer     # We'll be putting this value at deaad[deadcount]
	@PUSHI DeadListCount @PUSHI DeadListCount @ADDS  # Calc offset in words
	@PUSH DeadList @ADDS # Ptr to dead[count]
	@POPS       # POP's MapPointer to dead[count]
	@INCI DeadListCount     # count ++
	@PUSHI Xidx @PUSHI Yidx @PUSH SpaceStr
	@CALL WinWrite
	@JMP FinishLoop
	:RemainsAlive
	@INCI CountLive      # Alive so count it.
#	@PRT "- "
	@JMP FinishLoop
	#
	#
	:CurrentlyDead
	# The only reason this will change is if Neighboors == 3
	@PUSHI Neighboors
	@CMP 3
	@POPNULL
	@JMPZ IsBorn
	# Other wise it doesn't change
	@JMP FinishLoop
	:IsBorn
#	@PRT "! "
	@PUSH MapPointer      # We'll be putting this value at alive[alivecount]
	@PUSHI AliveListCount @PUSHI AliveListCount   # Call offset in words
	@PUSH AliveList @ADDS # Offset converted to pointer
	@POPS                 # PUSH MapPointer to alive[cout]
	@INCI AliveListCount
	@PUSHI Xidx @PUSHI Yidx @PUSH StarStr
	@CALL WinWrite	
	@INC2 CountLive       # Take count
    # Finish inner loop
    :FinishLoop
    @INC2 MapPointer
   @NextNamed Xidx InnerFor
 @NextNamed Yidx OuterFor
 # Now go though the Alive and Dead Lists to update data for next generation.
 :BreakLine1
 @ForIfV2V ListIdx ZeroStore AliveListCount ForLoopLive
    @PUSH 1       # The value we plan to store at mem[alive[idx]]
    @PUSHI ListIdx @DUP @ADDS   # Words not bytes, so index*2
    @ADD AliveList      # [Address+Offset]
    @PUSHS              # Value should be address of original MapPointer
    @POPS               # POP's 1 to address
 @NextNamed ListIdx ForLoopLive
 :BreakLine2
 @ForIfV2V ListIdx ZeroStore DeadListCount ForLoopDead
    @PUSH 0       # The value we plan to store at mem[dead[idx]]
    @PUSHI ListIdx @DUP @ADDS   # Words not bytes, so index*2
    @ADD DeadList      # [Address+Offset]
    @PUSHS              # Value should be address of original MapPointer
    @POPS               # POP's 0 to address
 @NextNamed ListIdx ForLoopDead
 @PUSH 0x40
 @ADDI LoopCount
 @POPI StrNum
 @PUSH 1 @PUSH 4
 @PUSH StrNum
 @CALL WinWrite
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
:StrNum
"   " b0 b0 b0


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
      

# Main Loop Variables
:Xidx 0
:Yidx 0
:CountLive 0
:SpaceStr " " b0
:StarStr "*" b0
:LoopCount 0
:NeighPtr 0
:MapPointer 0
:Neighboors 0
:ListIdx 0
:ListItemPtr 0
:ZeroStore 0
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
0 0 1 0 0 0 0 0 0 0  # 2
0 0 1 0 0 0 0 0 0 0  # 3
0 0 0 0 0 0 0 0 0 0  # 4
0 0 0 0 0 0 0 0 0 0  # 5

:DeadListCount 0
:DeadList
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 
:DeadListEnd
:AliveListCount 0
:AliveList
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
:AliveListEnd
