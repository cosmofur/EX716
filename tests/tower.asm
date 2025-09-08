I common.mc
L screen.ld
L random.ld
L softstack.ld
L heapmgr.ld

# Tower Defense
#
# Logic, rather than trying to use the screen display as the map
# We'll take a more 1 dimentional view of the world.
#
# Enemies will walk a 'path' that has X,Y location, and will be a simple
# structured list.
# For memory sake, the path will be limited to a max of 1600 cells, but will rarely be that large. The displayed map will be a max of 40x40.
# Enemies will 'walk' speed of 1-4, at speed 1, it will take 4 cycles to pass
# through a single cell. At speed 4 it will take 1 cycle.
# Towers will have a list of what map cells are 'near' them. Max range of any tower
# will be 5x5 square around it. Lower powered towwers might only have a 2x2 or 3x3
#
# Variables and initial data
:NumTowers 0
:NumWaveEnemys 0
:Score 0
:Index1 0
:Index2 0
:Index3 0
:Index4 0
:Index5 0
:Index6 0
:Index7 0
:Index8 0
:Index9 0
:MainHeapID 0
:TowerHeapID 0
:PathHeapID 0
:EnemyHeapID 0
#
#
# Function Init
:Init
   @MA2V 0 Score
   @MA2V 0 TowerHeapID
   # Define the main 'large' memor
   @PUSH 0xf800   #  leave a little memory on top for future
   @SUB ENDOFCODE # Need to define this at well end of code.
   @PUSH ENDOFCODE
   @CALL HeapDefineMemory
   @POPI MainHeapID
   # We may need a larger soft stack, so lets give a bit extra space inside the Heap
   @PUSHI MainHealID
   @PUSH 0x400     # 1K for stack
   @CALL HeapNewObject
   # TOS have the lower address of the stack space.
   # We need to modify the order so its, (TOP,BOTTOM)
   @DUP           # Save copy so we can calulate TOP
   @ADD 0x400
   @SWP           # Change order to match requirments
   @CALL SetSSStack   # Doesn't leave anything in stack, so return address should be on top.
   @RET
#
#
# Function SetupMap(MapID)
# This will fill out the PATH data for a map. We want to support multipl maps, but for now we have just one.
:SetupMap
   @PUSHRETURN
   =MapID Index4
   @POPI MapID
   @PUSHI MapID @SHL     # Byte to word
   @ADD MapIDIndex
   @POPI Index1          # Index1 will point to start of map data.
   @PUSHI MapID @SHL @ADD 2
   @ADD MapIDIndex
   @POPI Index2          # Index2 is size of PATH in length.
   # Clear out any PathHeapID if any.
   @PUSHI PathHeapID
   @IF_NOTZERO
      @PUSHI MainHeapID
      @PUSHI PathHeapID
      @CALL HeapDeleteObject     # Remove any old Path Data
   @ENDIF
   @POPNULL
   # Create a new PathHeapID
   @PUSHI MainHeapID
   @PUSHI Index2 @SHL            # Will need two bytes for each step in the PATH
   @CALL HeapNewObject
   @POPI PathHeapID
   # Now the Towers structure is a bit more complex
   # Each one has verson,(X,Y), SizeOfInRange, List[...SizeOfInRange]
   # Since we haven't yet allowd the player to put any towers, we'll clear out any current tower list and create a new one
   # the new one will only have one entry of which only the 'Version' field will be set, indicaiting End Of List
   @PUSHI TowerHeapID
   @IF_NOTZERO
      @PUSHI MainHeapID
      @PUSHI TowerHeapID
      @CALL HeapDeleteObject     # Remove any old Tower Data
   @ENDIF
   @POPNULL 
   #
   @PUSHI MainHeapID
   @PUSHI 3           # Just saving the Version as zero for END OF LIST
   @CALL HeapNewObject
   @POPI TowerHeapID
   @PUSH 0 @POPII TowerHeapID     # Put a 16b zero at begining of TowerHeap.
   #
   # Now use the MapID as an index pointing to where original mapdata is stored.
   @PUSHI MapDataIndex
   @IF_LT_V MapID
      @PRT "Map ID: " @PRTI MapID @PRT " is not a valid mapid."
      @END
   @ENDIF
   @POPNULL
   # Use the DataIndex to find the real start of map data
   @PUSH MapDataIndex @ADD 2 @PUSHI MapID @SHL @ADDS @PUSHS
   @POPI MapID
   #
   # First word in Pathdata is its size.
   # Define array pointers
   =PathDataCounter Index1
   =PathDataSize Index2
   =PathPtr Index3
   #
   @PUSHII MapID @POPI PathDataSize
   @INC2I MapID             # Now points at first word of map data.
   # Now setup a Path that is large enough for the MapData, PathSize*2 + 4
   PUSHI MainHeapID @PUSHI PathHeapID @PUSHI PathDataSize @SHL @ADD 4
   @CALL HeapResize
   @POPI PathHeapID
   @MV2V PathHeapID PathPtr
   @PUSHI PathDataSize @POPII PathPtr # Put the path size in first word
   @INC2I PathPtr
   #
   @ForIA2V PathDataCounter 0 PathDataSize
       @PUSHII MapID
       @INC2I MapID
       @POPII PathPtr
       @INC2I PathPtr
   @Next PathDataCounter
   @PUSH 0 @POPII PathPtr    # Put zero in last word to mark end of map.
   @POPRETURN
   @RET
#
# 
#
# Function AddEnemy(Number, Type)
# This will insert a new enemy into the enemyheap, first looking for a free 'dead' enemy then
# expanding the heap if required.
#
:AddEnemy
@PUSHRETURN
=EType Index1
=NumberAdd Index2
=NewEntry Index3
=LIndex1 Index4
=CurrentECount Index5
=OIndex1 Index6
=EType Index7
=NewECount Index8
=StartSearch Index9

   @POPI EType
   @POPI NewECount
   
   # The EnemyHeapID structure is
   #  size , entries(Health,PathIndex,Level, Varient) 8 bytes
   @PUSHII EnemyHeapID
   @POPI CurrentECount
   @MA2V 0 NewCount        # If we find some dead Enemies, we'll move the search start index from last found.
   @ForIA2V OIndex1 0 NewCount
      @ForIV2V LIndex1 NewCount CurrentECount
          @MV2V LIndex1 NewCount
          @PUSHI EnemyHeapID @ADD 2
          @PUSHI LIndex1 @SHL @SHL @SHL @ADDS # Mul LIndex1 * 8 for offset
          @PUSHS
          @IF_ZERO
             @MV2V CurrentECount Lindex   # Breaks the Inner For Loop
          @ENDIF
          @POPNULL          
      @Next LIndex1
      @IF_NE_VV NewCount CurrentECount # Will only be true if a dead enmey was found.
         # Insert point will be NewCount set to zero and prepare bring to life.
         @PUSHI EnemyHeapID @ADD 2
         @PUSHI NewCount @SHL @SHL @SHL @ADDS
         # Reminder of enemy data structure
         #  0 Health, +2 PathIndex, +4 Level, +6 Varient
         @DUP @PUSH 10 @SWP @POPS                  # 0th Give Enemy some health 
         @DUP @ADD 2 @PUSH 0 @SWP @POPS       # 2 bytes Set it at start of path
         @DUP @ADD 4 @PUSHI EType @SWP @POPS  # Will control speed and armor
         @ADD 6 @PUSHI EVary @SWP @POPS       # GLYPH options?
      @ELSE
         # None of the existing enemies are 'dead' so add a new one.
         @PUSHI MainHeapID
         @PUSHI EnemyHeapID
           @PUSHI MainHeapID
           @PUSHI EnemyHeapID
           @CALL GetObjectRealSize
           @ADD 8                # Enlarge EnemyHeapID by 8 bytes
         @CALL HeapResizeObject
         @POPI EnemyHeapID       # Get the 'new' resized enemyheap
         @PUSHI 
         

         
         
         
       
