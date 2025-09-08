############### Game of Life
I common.mc
L heapmgr.ld
L softstack.ld
L random.ld
#
# Cell Data Offsets
=XOFFSET 0
=YOFFSET 2
=AliveOFFSET 4   # Byte
=AdjTableOFFSET 5 # 16 bytes
=ALIVEFLAG 1
=DEADFLAG 0
=CellHashNumBuckets 1024
=CellHashMaxTries 8
=CellSize 21
#
# Global Storage
:MainHeap 0
:MaxPossibleCells 0
:CurrentNumCells 0
:ActiveCellTable 0
:CellHashTable 0
:CellHashTable1 0
:CellHashTable2 0
:DeadNeighborList 0
:DeadNeighborCount 0
:DeadNeighborMax 512      # Start with 512 possible neighboors grow if needed.

#
# Because we will be deailing with Cell Objects we'll add some utility macros here.
#
# SetX group
# SetCell.X(Cell, Constant X Val)
M SetCell.X @PUSH %2 @PUSHI %1 @POPS    # we skip the ADD XOFFSET since its known to be zero
# SetCell.X(Cell, Variable X Val)
M SetCell.XI @PUSHI %2 @PUSHI %1 @POPS
# SetCell.XS(Cell) From Stack
M SetCell.XS @PUSHI %1 @POPS
#
# SetY Group
# SetCell.Y(Cell, Constant Y Val)
M SetCell.Y @PUSH %2 @PUSHI %1 @ADD YOFFSET @POPS
# SetCell.YI(Cell, Variable Y Val)
M SetCell.YI @PUSHI %2 @PUSHI %1 @ADD YOFFSET @POPS
# SetCell.YS(Cell) From Stack
M SetCell.YS @PUSHI %1 @ADD YOFFSET @POPS
#
# GetX group
# No need for a GetCell.X as its meaningless
# GetCell.XI(Cell, Var)
M GetCell.XI @PUSHI %1 @PUSHS @POPI %2
# GetCell.XS(Cell) to stack
M GetCell.XS @PUSHI %1 @PUSHS
#
# GetY group
# GetCell.YI(Cell,Var)
M GetCell.YI @PUSHI %1 @ADD YOFFSET @PUSHS @POPI %2
# GetCell.YS(Cell) to stack
M GetCell.YS @PUSHI %1 @ADD YOFFSET @PUSHS
#
# AliveGroup Byte structure so need to preserved high byte when Setting.
# SetCell.Alive(Cell, Constant Value)
M SetCell.Alive @PUSHI %1 @ADD AliveOFFSET @PUSHS @AND 0xff00 \
                @PUSH %2 @ORS @PUSHI %1 @ADD AliveOFFSET @POPS
# SetCell.AliveI(Cell, Variable)
M SetCell.AliveI @PUSHI %1 @ADD AliveOFFSET @PUSHS @AND 0xff00 \
                @PUSHI %2 @ORS @PUSHI %1 @ADD AliveOFFSET @POPS
# SetCell.AliveS(Cell) Value on Stack
M SetCell.AliveS @PUSHI %1 @ADD AliveOFFSET @PUSHS @AND 0xff00 \
                 @ORS @PUSHI %1 @ADD AliveOFFSET @POPS
# GetCell.AliveI(Cell, Variable)
M GetCell.AliveI @PUSHI %1 @ADD AliveOFFSET @PUSHS @AND 0xff \
                 @POPI %2
# GetCell.AliveS(Cell) saves to stack
M GetCell.AliveS @PUSHI %1 @ADD AliveOFFSET @PUSHS @AND 0xff
#
# Adj group, do to complexity value is on stack or left on stack.
# SetCell.Adj(Cell, Index)
#
# SetCell.Adj Index is constant
M SetCell.Adj @PUSHI %1 @ADD AdjTableOFFSET @PUSH %2 @SHL @ADDS @POPS
# SetCell.AdjI Index is variable
M SetCell.AdjI @PUSHI %1 @ADD AdjTableOFFSET @PUSHI %2 @SHL @ADDS @POPS
# GetCell.Adj Index is constant
M GetCell.Adj @PUSHI %1 @ADD AdjTableOFFSET @PUSH %2 @SHL @ADDS @PUSHS
# GetCell.AdjI Index is variable
M GetCell.Adj @PUSHI %1 @ADD AdjTableOFFSET @PUSHI %2 @SHL @ADDS @PUSHS

#
# Swap Active Hash table.
M SwapHashTable @IF_EQ_VV CellHashTable CellHashTable1 \
                   @MV2V CellHashTable2 CellHashTable \
                @ELSE \
                   @MV2V CellHashTable1 CellHashTable \
                @ENDIF
                

### Some Constant tables
:ReverseAdj
7 6 5 4 3 2 1 0
:AdJDirection
#:AdjDirection
-1 -1
0 -1
1 -1
-1 0
1 0
-1 1
0 1
1 1





#########################################
# Function init
:init
   @PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
   @CALL HeapDefineMemory
   @POPI MainHeap
# Set up memory for the SoftStack allow upto 1000 bytes of soft stack.
   = SoftStackSize 1000
   @PUSHI MainHeap @PUSH SoftStackSize
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 114" @END @ENDIF
   @DUP @ADD SoftStackSize @SWP
   @CALL SetSSStack
# Setup the global Varables
   @PUSHI 0xf800 @SUB ENDOFCODE # large heap size
   @SHR @SHR @SHR @SHR @SHR # >> 5 aprox 32 bytes per object, rounded up.
   @POPI MaxPossibleCells
   @MA2V 0 CurrentNumCells

   @PUSHI MainHeap @PUSHI 0x400 @SHL
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 126" @END @ENDIF
   @POPI ActiveCellTable
   # We calculate the Heapsize by CellHashNumBuckts*6
   @PUSHI MainHeap
   @PUSH CellHashNumBuckets @SHL @DUP @SHL @ADDS
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 131" @END @ENDIF
   @POPI CellHashTable1
   @PUSHI MainHeap
   @PUSH CellHashNumBuckets @SHL @DUP @SHL @ADDS
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 135" @END @ENDIF
   @POPI CellHashTable2
   
   
   @GETTIME
   @POPNULL
   @CALL rndsetseed
 @RET
###############################################
# Function AddActive(InCell)
:AddActive
@PUSHRETURN
    @PUSHI CurrentNumCells
    @IF_LT_A 0x400       
       @SHL @ADDI ActiveCellTable @POPS
       @INCI CurrentNumCells
    @ELSE
       @PRT "Too many active cells:\n"
       @POPNULL
    @ENDIF
@POPRETURN
@RET
#################################################
# Function FindCell(InX,InY):-1 or CellID
# Seaches for alive cells in ActiveCell list and see if X,Y match
:FindCell
@PUSHRETURN
@LocalVar InX 01
@LocalVar InY 02
@LocalVar Index 03
@LocalVar TestCell 04
#
@POPI InY
@POPI InX
    @ForIA2V Index 0 CurrentNumCells
       # Get the cell to test
       @PUSHI ActiveCellTable
       @PUSHI Index @SHL
       @ADDS
       @PUSHS
       @POPI TestCell
       #
       # Is it alive?
       @GetCell.AliveS TestCell
       @IF_EQ_A ALIVEFLAG
          @POPNULL
          @GetCell.XS TestCell
          @IF_EQ_V InX
             @POPNULL
             @GetCell.YS TestCell
             @IF_EQ_V InY
                 # Result Matches, exit with result
                 @POPNULL
                 @PUSHI TestCell
                 @JMP FCQuickExit
             @ELSE
                 @POPNULL
             @ENDIF
          @ELSE
             @POPNULL
          @ENDIF
       @ELSE
          @POPNULL
       @ENDIF
    @Next Index
    @PUSH -1
    :FCQuickExit
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

    

##################################################
# Function NewLiveCell(X,Y)
# Creates a new Cell and finds all its neighboors
:NewLiveCell
@PUSHRETURN
@LocalVar InX 01
@LocalVar InY 02
@LocalVar NewCell 03
@LocalVar DX 04
@LocalVar DY 05
@LocalVar NX 06
@LocalVar NY 07
@LocalVar Index 08
@LocalVar Neighbor 09
@LocalVar RevIndex 10

#
@POPI InY
@POPI InX

   @PUSHI MainHeap @PUSH CellSize
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Out of memory." @END @ENDIF
   @POPI NewCell
   # Save the new Cell in the lookup table.
   @PUSHI NewCell @CALL AddActive
   
   @SetCell.XI NewCell InX
   @SetCell.YI NewCell InY
   @PUSH ALIVEFLAG @SetCell.AliveS NewCell
   @MA2V 0 Index
   # Zero out any memory junk in table.
   @ForIA2B Index 0 8
       @PUSH 0
       @SetCell.AdjI NewCell Index
   @Next Index
   @ForIA2B DX -1 2
      @ForIA2B DY -1 2
          @PUSH 0
          @IF_EQ_AV 0 DX
             @IF_EQ_AV 0 DY
                 @POPNULL
                 @PUSH 1
                 # Mark to skip 0,0
             @ENDIF
          @ENDIF
          @IF_ZERO
             @PUSHI InX @ADDI DX
             @PUSHI InY @ADDI DY
             @CALL FindCell             
             @IF_EQ_A -1
                # No Neighbor in that direction
                @POPNULL
             @ELSE
                # Save neighbor to Adj index
                @DUP @POPI Neighbor
                # Save Neighbor ptr to NewCell's Adj index
                @SetCell.AdjI NewCell Index
                
                # Get the Reverse Index
                @PUSH 7 @SUBI Index @POPI RevIndex
                # Save the NewCell ptr at the Neighbor's RevIndex
                @PUSHI NewCell
                @SetCell.AdjI Neighbor RevIndex
             @ENDIF
          @ENDIF
          @POPNULL
          @INCI Index
       @Next DY
    @Next DX
    @PUSHI NewCell
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
##############################################
# Function: HashCoord(x,y)
:HashCoord
@PUSHRETURN
@LocalVar X1 01
@LocalVar Y1 02
   @POPI Y1
   @POPI X1
   #
   # (X * 73 ) xor (Y * 193)
   #
   @PUSHI X1 @SHL @DUP @SHL @SHL @ADDS @SUB X1  # X1*9
   @PUSHI X1 @SHL @SHL @SHL @SHL @SHL @SHL      # X1*64
   @ADDS  @SUBI X1                              # X1*73
   #
   @PUSHI Y1 @SHL @SHL @SHL @SHL @SHL @SHL      # Y1*64
   @DUP @SHL @ADDS                              # Y1*128+Y1*64+Y1=Y1*193
   @ADDI Y1
   #
   @XORS         # (X*73) xor (Y*193)
   #
   # X1 << 2
   @PUSH X1 @SHL @SHL
   @XORS
   #
   @AND 0x3ff
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

##############################################
# Function SearchHash(X,Y): (-1 or Cell)
:SearchHash
@PUSHRETURN
@LocalVar X1 01
@LocalVar Y1 02
@LocalVar Limit 03
@LocalVar Index 04
@LocalVar Result 05

#
   @POPI Y1
   @POPI X1
   @PRT "SearchHash-IN:" @StackDump
   @MA2V 0 Limit
   #
   @PUSHI X1 @PUSHI Y1 @CALL HashCoord
   @POPI Index
   #
   @MA2V -1 Result

   @PUSHI Limit
   @WHILE_LT_A CellHashMaxTries
      @PUSHI Index @ADD 4 @PUSHS   # CellPtr is offset 4
      @IF_NOTZERO
         @POPNULL
         @PUSHII Index             # X is offset 0
         @IF_EQ_V X1
            @POPNULL
            @INC2I Index           # y is offset 2
            @PUSHII Index
            @IF_EQ_V Y1
               # X,Y match and Cell's not zero
               @POPNULL
               @PUSHI Index @ADD 4 @PUSHS
               @POPI Result
               @JMP SHExit
            @ENDIF
            @POPNULL
         @ELSE
            @POPNULL
         @ENDIF
      @ENDIF
      @POPNULL
      @INCI Limit
      @PUSHI Limit
   @ENDWHILE
   @POPNULL
   :SHExit
   @PUSHI Result
   @PRT "SearchHash-OUT:" @StackDump   
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
      
   

##############################################
# Function: InsertCellHash
:InsertCellHash
@PUSHRETURN
@LocalVar CellPtr 01
@LocalVar Y1 02
@LocalVar X1 03
@LocalVar Index 04
@LocalVar SlotAddr 05
@LocalVar Tries 06
#
    @POPI CellPtr
    @POPI Y1
    @POPI X1

    @PUSHI X1 @PUSHI Y1 @CALL HashCoord
#    @PRT "(" @PRTI X1 @PRT "," @PRTI Y1 @PRT ")=" @PRTTOP @PRT " "
    @POPI Index
    @PUSH 0 # Return Code 0 means success
    @PUSH 0
    @WHILE_LT_A CellHashMaxTries
       @POPI Tries
       @PUSHI Index
       @SHL @DUP @SHL @ADDS        # == X6
       @ADDI CellHashTable
       @POPI SlotAddr
       @PUSHII SlotAddr      # Get Slot.X
       @PUSHI SlotAddr @ADD 2 @PUSHS  # Get Slot.Y
       # Stack (Slot.Y,Slot.X)
       @IF_EQ_V Y1
          @POPNULL
          @IF_EQ_V X1      # Stack(Slot.X)
              # Slot.X == X and Slot.Y == Y
              @POPNULL
              @PUSHI CellPtr
              @PUSHI SlotAddr @ADD 4
              @POPS       # Save CellPtr at Slot.Ptr
              @JMP ICHBreak        # Break While
          @ELSE
              @POPNULL      # Stack(Slot.X)
          @ENDIF
       @ELSE
          @POPNULL @POPNULL # Stack(Slow.Y,Slot.X)
       @ENDIF
       @PUSHII SlotAddr      # Get Slot.X
       @PUSHI SlotAddr @ADD 2 @PUSHS  # Get Slot.Y
       @IF_EQ_A 0
          @POPNULL
          @IF_EQ_A 0
             @POPNULL
             # Fill in empty Slot
             @PUSHI X1 @PUSHI SlotAddr @POPS
             @PUSHI Y1 @PUSHI SlotAddr @ADD 2 @POPS
             @PUSHI CellPtr @PUSHI SlotAddr @ADD 4 @POPS
             @JMP ICHExit
          @ELSE
             @POPNULL
          @ENDIF
       @ELSE
          @POPNULL @POPNULL
       @ENDIF
       #
       # Falls though for Hash Collision
       @INCI Tries
       @PUSHI Index
       @ADD 1
       @IF_GT_A CellHashNumBuckets
           @MA2V 0 Index
       @ENDIF
       @POPI Index
       :
       @PUSHI Tries
   @ENDWHILE
   @PRT "InsertCellHash: Too many collisions\n"
   @POPNULL
   @POPNULL   
   @PUSH -1
   :ICHBreak        # Break Whil   
   :ICHExit
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
###################################################
# Function: HashMapPrint
# Debug function to print the hashmap
:HashMapPrint
@PUSHRETURN
@LocalVar Index 01
@LocalVar X1 02
@LocalVar Y1 03
   @MV2V CellHashTable Index
   @ForIA2B Y1 0 32
      @ForIA2B X1 0 32
          @PUSHII Index
          @PUSHI Index @ADD 2 @POPI Index
          @PUSHII Index
          @PUSHI Index @ADD 2 @POPI Index          
          @ADDS
          @IF_ZERO
             @PRT "."
          @ELSE
             @PRT "X"
          @ENDIF
          @POPNULL
      @Next X1
      @PRTNL
  @Next Y1
  @END
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#
####################################################
# Function ClearHashTable
# Clears the current active Hash Table
:ClearHashTable
@PUSHRETURN
@LocalVar Index 01
   @ForIA2B Index 0 CellHashNumBuckets
       # Put Ptr to Hashtable Entry on Stack
       @PUSHI Index @SHL @DUP @SHL @ADDS
       @ADDI CellHashTable
       #
       @DUP
       @PUSH 0 @SWP @POPS    # Handes 1st word (X)
       #
       @DUP @ADD 2
       @PUSH 0 @SWP @POPS    # Handes 2nd word (Y)
       #
       @ADD 4                # No dup here, last one.
       @PUSH 0 @SWP @POPS    # Handes Cell Ptr
    @Next Index
@RestoreVar 01
@POPRETURN
@RET

#####################################################
# Function CountNeightbors(Cell)
:CountNeighbors
@PUSHRETURN
@LocalVar InCell 01
@LocalVar DX 02
@LocalVar DY 03
@LocalVar CX 04
@LocalVar CY 05
@LocalVar Index 06
@LocalVar Count 07
#
   @POPI InCell
   #
   @MA2V 0 Count
   @PUSHI InCell @PUSHS @POPI CX
   @PUSHI InCell @ADD 2 @PUSHS @POPI CY
   # Table named ADJDirection olds the deltas for x and y in each direction   
   @ForIA2B Index 0 7
       # Use AdjDirection Lookup take to get two 0,1,-1 deltas for x and t
       @PUSHI Index @SHL
       @DUP
       @ADD AdJDirection
       @PUSHS @POPI DX
       @ADD 2
       @ADD AdJDirection
       @PUSHS
       @POPI DY
       @PUSHI DX @ADDI CX
       @PUSHI DY @ADDI CY
       @CALL SearchHash
       @IF_EQ_A -1
          # Not found
          @PUSHI DX @ADDI CX
          @PUSHI DY @ADDI DY
          @CALL RegisterDeadNeighbor
       @ELSE
          @INCI Count
       @ENDIF
       @POPNULL
   @Next Index
   @PUSHI Count
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

####################################################
# Function RegisterDeadNeighbor(X,Y)
:RegisterDeadNeighbor
@PUSHRETURN
@LocalVar X1 01
@LocalVar Y1 02
@LocalVar NewCell 03
@LocalVar Index 04
#
@POPI Y1
@POPI X1
   # Check to see if this deadneighbor has a old entry
   @SwapHashTable
   @PUSHI X1 @PUSHI Y1 @CALL SearchHash
   @IF_EQ_A -1
      # Neighbor wasn't previously seen.
      @POPNULL
      # Create a 'new' cell but also modify it by marking it 'dead'
      @PUSHI X1 @PUSHI Y1 @CALL NewLiveCell
      @POPI NewCell
      @PUSH DEADFLAG
      @SetCell.AliveS NewCell
      # Now add X,Y to DeadNeighborCount
      @PUSHI DeadNeighborCount @ADD 1
      @IF_GT_V DeadNeighborMax
         @POPNULL
         # The DeadNeighborList size need to be adjusted.
         @PUSHI MainHeap
         @PUSHI DeadNeighborList
         @PUSHI DeadNeighborCount @ADD 1024
         @CALL HeapResizeObject
         @POPI DeadNeighborList
         @PUSHI DeadNeighborCount @ADD 256   # Each Entry if 4 bytes so 1/4 the real size
      @ENDIF
      @DUP
      @POPI DeadNeighborCount      # Either way new DNC will be on TOS
      @SUB 1 @SHL @SHL @ADDI DeadNeighborList @POPI Index
      @PUSHI X1 @POPII Index
      @PUSHI Y1 @PUSHI Index @ADD 2 @POPS
   @ELSE
      @POPNULL
   @ENDIF
   @SwapHashTable
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

###################################################
# Function EvaluateDeadNeighbors
# Test if dead cells shoud become alive.
:EvaluateDeadNeighbors
@PUSHRETURN
@LocalVar Index 01
@LocalVar X1 02
@LocalVar Y1 03
@LocalVar CellPtr 04
#
   @ForIA2V Index 0 DeadNeighborCount
       # Four Bytes in each entry.
       @PUSHI Index @SHL @SHL
       @DUP
       @PUSHS @POPI X1
       @ADD 2
       @PUSHS @POPI Y1
       @PUSHI X1 @PUSHI Y1
       @CALL SearchHash
       @POPI CellPtr
       @IF_EQ_AV -1 CellPtr
          @PRT "Error: Corrupt entry in Neighbor list"
       @ELSE
          @PUSHI CellPtr
          @CALL CountNeighbors
          @IF_EQ_A 3
              @SetCell.Alive CellPtr ALIVEFLAG
              @PUSHI CellPtr
              @CALL AddActive
          @ENDIF
          @POPNULL
      @ENDIF
   @Next Index
@RestoreVar 04   
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
####################################################
# Function UpdateActiveCelllist
# Scans HashTable and build active cell list
:UpdateActiveCelllist
@PUSHRETURN
@LocalVar Index 01
@LocalVar Ptr 02
   @MA2V 0 CurrentNumCells
   #
   @ForIA2B Index 0 CurrentNumCells
       @PUSHI Index
       @SHL @DUP @SHL @ADDS     # X6
       @ADDI CellHashTable
       @ADD 4
       @PUSHS @POPI Ptr
       @IF_EQ_AV 0 Ptr
          # Skip Zero Cells
       @ELSE
          @GetCell.AliveS Ptr
          @IF_EQ_A ALIVEFLAG
             @PUSHI Ptr
             @CALL AddActive
          @ENDIF
          @POPNULL
       @ENDIF
   @Next Index
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

####################################################
# Function: LoadInitialPattern
# Loads a few hardcoded live cells into the grid
# Example: A glider at (10, 10)
:LoadInitialPattern
@PUSHRETURN

    # Push X, Y pairs and call NewLiveCell
    @PUSH 10 @PUSH 10 @CALL NewLiveCell @POPNULL
    @PUSH 11 @PUSH 11 @CALL NewLiveCell @POPNULL
    @PUSH 12 @PUSH 09 @CALL NewLiveCell @POPNULL
    @PUSH 12 @PUSH 10 @CALL NewLiveCell @POPNULL
    @PUSH 12 @PUSH 11 @CALL NewLiveCell @POPNULL

@POPRETURN
@RET

####################################################
# Function: DrawGrid(Left,Top)
# Render a small portion of the board to the terminal
:DrawGrid
@PUSHRETURN
@LocalVar Y 01
@LocalVar X 02
@LocalVar Cell 03
@LocalVar Left 04
@LocalVar Top 05

@POPI Top
@POPI Left

# Optional: Move cursor to top left
#@PRT ESCAPE_CODE_FOR_HOME_CURSOR   # "\e[H" or similar if supported
@PRT "\e[H"

@ForIA2B Y 0 19
    @ForIA2B X 0 39
        @PUSHI X @ADDI Left
        @PUSHI Y @ADDI Top
        @CALL SearchHash
        @POPI Cell
        @IF_EQ_AV -1 Cell
            @PRT "."  # dead
        @ELSE
            @PRT "*"  # alive
        @ENDIF
        @POPNULL
    @Next X
    @PRT "\n"
@Next Y

@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET



####################################################
# Function MainGameLoop
:MainGameLoop
@PUSHRETURN
@LocalVar Index1 01
@LocalVar CurrentCell 02
@LocalVar ThisLoopsNumCells 03
#
   # Clear the 'not active' HashTable
   @SwapHashTable 
   @CALL ClearHashTable
   @SwapHashTable 
   #
   # We take snapshot of CNS as it might incriment  while we calculate this
   # loop, and do not want newly created cells be procsessed until next loop.
   @MV2V CurrentNumCells ThisLoopsNumCells
   @ForIA2V Index1 0 ThisLoopsNumCells
      @PUSHI Index1 @SHL @ADDI ActiveCellTable @PUSHS
      @POPI CurrentCell
      @PUSHI CurrentCell
      @CALL CountNeighbors
      @IF_INRANGE_AB 2 3
         @SwapHashTable 
         @PUSHI CurrentCell @CALL InsertCellHash
         @SwapHashTable 
      @ENDIF

      @PUSHI CurrentCell
      @CALL RegisterDeadNeighbor
   @Next Index1
   #
   @CALL EvaluateDeadNeighbors
   #
   @SwapHashTable 
   @CALL UpdateActiveCelllist
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
   


      
:Main . Main
   @CALL init
   @CALL LoadInitialPattern
   @PUSH 0
   @WHILE_ZERO
      @PUSH 0 @PUSH 0
      @CALL DrawGrid
      @CALL MainGameLoop
   @ENDWHILE
   
   
:ENDOFCODE
