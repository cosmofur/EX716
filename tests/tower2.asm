I common.mc
L softstack.ld
L heapmgr.ld
L random.ld
L screen.ld


# Tower Defense
#
#
# Data structures:
# Tower
#    int: Type      1=single target 2=area
#    int: Health    100 to 0, tower gets rebuilt when drops < 1
#    AttackList.
#        int: CoveredCount   # number of map cells tower can reach
#        int Targets[CoverdCount]
#
# Enemy
#    int: Type     int value id's enemies abilities.
#    int: Health
#    int: Speed    Number steps perturn
#    int: Damage
#
# Map
#    int: Length
#    int: Cells[Length,2]
#         x,y
# TowerList
#    int: Size
#    Tower
#
########################
# Storage
:MainHeapPtr 0
:TowerHeapPtr 0
:EnemyHeapPtr 0
:MapHeapPtr 0
:Score1 0
:MapID 0
#######################
# Local Macros
# SafeNewObject just calls HeapNewObect but deals with errors more cleanly.
M SafeNewObject :%0L @CALL HeapNewObject @IF_ULT_A 255 @PRT "Heap Error " @PRTHEXTOP @PRT " at " @PRTREF %0L @PRTNL @END @ENDIF
#######################
:Main . Main
@CALL InitMemory
@CALL SimpPrintMap
@END

#######################
# Function SimpPrintMap
:CharStr 00000
:SimpPrintMap
@PUSHRETURN
@PUSHII MapHeapPtr
@CALL WinClear
@POPI Var01        # Size of map in 4 byte cells
@PUSHI MapHeapPtr
@ADD 2
@POPI Var02         # Var2 points to first entry of map data
@ForIA2V Var03 0 Var01
    :Break1
    @PUSHI Var03 @SHL @SHL @ADDI Var02  # mem[var3*2+Var2]
    @PUSHS @ADD 4 @POPI Var04        # X Value of item
    @PUSHI Var03 @SHL @SHL @ADD 2 @ADDI Var02 #  mem[var3*2+2+Var2]
    @PUSHS @ADD 1 @POPI Var05  # Y Value of item
    @PUSHI Var04 @PUSHI Var05
    @CALL WinCursor
    @PRT "*="
@Next Var03

@PUSH 0 @PUSH 20 @CALL WinCursor
#@PRTNL
@PRT ">"
@POPRETURN
@RET

#######################
# Function InitMemory, load first map.
:InitMemory
# Define Main Heap
@PUSH 0xf800
@SUB ENDOFCODE
@PUSH ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeapPtr
@PUSHI MainHeapPtr
# Define space for software Stack
@PUSH 0x400
@SafeNewObject
@DUP
@ADD 0x400
@SWP
@CALL SetSSStack
# Define Tower Heap, start with enough room for the tower counter.
# Structure will be TowerCount, Ptr to 1st tower, Each tower structure is
#     Tower { Ptr: Next-Tower, int: Health, int: type, Map X,Y,
#             int: Count of MapCells covered
#             [0..Count]=word(Byte X, Byte Y)

@PUSHI MainHeapPtr
@PUSH 2
@SafeNewObject
@POPI TowerHeapPtr
@PUSH 0 @POPII TowerHeapPtr     # First word is number of active towers.
#
# We prepare the EnemyHeap for up to 100 enemies but it might grow later.
# Each Enemy takes 4 words of storage. + a word for a counter.
@PUSHI MainHeapPtr
@PUSH 802
@SafeNewObject
@POPI EnemyHeapPtr
@MV2V EnemyHeapPtr Var01     # Var01 will be array pointer for now
@PUSH 100 @POPII Var01       # put enemy count in first word.
@INC2I Var01
@ForIA2B Var02 0 100
   @PUSH 1                   # All the first wave area always low level type 1's
   @PUSHI Var01    @ADD Var02   @POPS    @INC2I Var01 # Set Tpe
   @PUSH 10                 # Start with 10 health for first wave.
   @PUSHI Var01    @ADD Var02   @ADD 2 @POPS    @INC2I Var01 # Set Health
   @PUSH 1                  # Slowest possible enemies
   @PUSHI Var01    @ADD Var02   @ADD 4 @POPS    @INC2I Var01 # Set Health
   @PUSH 1                  # Minimal damage they do when they die
   @PUSHI Var01    @ADD Var02   @ADD 6 @POPS    @INC2I Var01 # Set Health
@Next Var02
#
# Setup Map, I want to support multiple maps.
# But that will be later
#
@MA2V Map1Start MapID
# Set var1 and var to the first two words in mapdata
@PUSHII MapID @POPI Var01
@PUSHI MapID @ADD 2 @PUSHS @POPI Var02
# Use delta between Var1,Var2 to reserve memory for MapHeapPtr
@PUSHI Var02 @SUBI Var01 # In Bytes
@DUP                     # Save for later
@ADD 2                   # For the Length field
@PUSHI MainHeapPtr @SWP   # Order is HeapPtr then size
@SafeNewObject
@POPI MapHeapPtr
@SHR @SHR                # 4 bytes in each cell, Length is number of cells.
@POPII MapHeapPtr        # Save Length at first word.
@PUSHI MapHeapPtr @ADD 2
@POPI Var04              # Var4 will be cursor into map data.
@PRT "Copying from " @PRTHEXI Var01 @PRT " to " @PRTHEXI Var02 @PRT " to " @PRTHEXI Var04 @PRTNL
@ForIV2V Var03 Var01 Var02   # Copy the map data.
   @PUSHII Var03 @POPII Var04
   @INCI Var04
@Next Var03
@StackDump
@RET
#
# First two words of map data is the addresses where it's stored.
:Map1Start
Map1Start+4
Map1End
# This first test map will be a simple 10x10 space
# 0123456789
#0
#1    ***    
#2  *** ***
#3  *     *
#4I** *****
#5    *
#6 ****
#7 *    ****O 
#8 * ****
#9 ***
# Following pairs of number are the X,Y of the road
0 4, 1 4, 2 4, 2 3, 2 2, 3 2, 4 2, 4 1, 5 1, 6 1,6 2, 7 2, 8 2, 9 2, 9 3
9 4, 8 4, 7 4, 6 4, 4 4, 4 5, 4 6, 3 6, 2 6, 1 6, 1 7, 1 8, 1 9, 2 9, 3 9 
3 8 3 8 5 8 6 8 6 7 7 7 8 7 9 7
:Map1End



:ENDOFCODE

   
