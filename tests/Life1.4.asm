I common.mc
L softstack.ld
L heapmgr.ld
L random.ld

:MainHeap 0

##############
# A variation of 1d game of life.
# Rather than based on 2d world grid, each generation is generated as a 1D array
# Rule is new 'line' is based on number of adjacent cells in the previous generation
# I call this 1.5D rather than 1D because it looks back up to 2 generations rather than just one.
#
# C1 is the current generation
# P1 is the parent generation
# P2 is the grandparent generation
#
# Each cell C1[X] counts:
#
#   P1[X-2], P1[X-1], P1[X+1], P1[X+2]
#   P2[X-1],          P2[X+1]
#
# Then it tests that againt the following rule constants
#
# If P1[X] was alive:
#    It survives when:
#       MinNeighboors <= COUNT <= MaxNeighboors
#
# If P1[X] was dead:
#    It is born when:
#       BeBornMin <= COUNT <= BeBornMax
#
# The fact it looks back 2 generations rather than one is the main variation vs Wolframs rules
#
###############################
#
# Constants
=MinNeighboors 3
=MaxNeighboors 5
=BeBornMin 2
=BeBornMax 2
=LineWindow 75
=LineWidth 128
=MaxGenerations 30
###############################
# Array Functions Macros, all arrays are 'words' for speed.
# (If memory was a concern I'd used bitmaps)
#
#========================
# Get?(Array,Index)
M GetV @PUSHI %2 @SHL @ADDI %1 @PUSHS
M GetA @PUSH %2 @SHL @ADDI %1 @PUSHS
# Put?(Array,Index,Value)
M PutV @PUSHI %3 @PUSHI %2 @SHL @ADDI %1 @POPS
M PutA @PUSH %3 @PUSHI %2 @SHL @ADDI %1 @POPS
# Stack Version
M PutS @PUSHI %2 @SHL @ADDI %1 @POPS
#==============================
#==============================
# CountAlive(P1,P2,X)
#
# Counts:
#   P1[X-2], P1[X-1], P1[X+1], P1[X+2]
#   P2[X-1],          P2[X+1]
#
# Does not include P1[X] or P2[X].
#==============================
:CountAlive
@PUSHRETURN
@Locals
   @Local P1
   @Local P2
   @Local X1
   @Local Index1
   @Local LowVal
   @Local HighVal
   @Local Count

   @POPI3 X1 P2 P1

   @PUSHI X1
   @AND 0x7f
   @POPI X1

   @MA2V 0 Count

   #--------------------------------
   # Parent generation: X-2 through X+2,
   # excluding X.
   #--------------------------------
   @PUSHI X1
   @SUB 2
   @IF_LT_A 0
      @POPNULL
      @PUSH 0
   @ENDIF
   @POPI LowVal

   @PUSHI X1
   @ADD 3   # Add 3 rather than 2 because For loop is non-inclusive for HighVal
   @IF_GT_A LineWidth
      @POPNULL
      @PUSH LineWidth
   @ENDIF
   @POPI HighVal

   @ForIV2V Index1 LowVal HighVal
      @IF_NEQ_VV Index1 X1
         @GetV P1 Index1
         @IF_NOTZERO
            @INCI Count
         @ENDIF
         @POPNULL
      @ENDIF
   @Next Index1

   #--------------------------------
   # Grandparent generation: X-1 through X+1,
   # excluding X.
   #--------------------------------
   @PUSHI X1
   @SUB 1
   @IF_LT_A 0
      @POPNULL
      @PUSH 0
   @ENDIF
   @POPI LowVal

   @PUSHI X1
   @ADD 2
   @IF_GT_A LineWidth
      @POPNULL
      @PUSH LineWidth
   @ENDIF
   @POPI HighVal

   @ForIV2V Index1 LowVal HighVal
      @IF_NEQ_VV Index1 X1
         @GetV P2 Index1
         @IF_NOTZERO
            @INCI Count
         @ENDIF
         @POPNULL
      @ENDIF
   @Next Index1

   @PUSHI Count
@EndLocals
@POPRETURN
@RET
#====================================
# SetupArray(Size):ArrayPtr
#====================================
:SetupArray
@PUSHRETURN
@Locals
   @Local Size
   @POPI Size

   @PUSHI Size
   @SHL
   @POPI Size
   @Call(VV) HeapNewObject MainHeap Size
   @IF_LT_A 100
      @POPNULL
      @PRT "Memory Error"
      @END
   @ENDIF
@EndLocals
@POPRETURN
@RET
#=====================================
# ClearArray(Array)
#=====================================
:ClearArray
@PUSHRETURN
@Locals
   @Local Array
   @Local Index1

   @POPI Array

   @ForIA2B Index1 0 LineWidth
       @PutA Array Index1 0
   @Next Index1
@EndLocals
@POPRETURN
@RET
#=====================================
# FixedArray(Array, pattern)
#=====================================
:FixedArray
@PUSHRETURN
@Locals
    @Local Array
    @Local Pattern
    @Local Cursor
    @Local Index1

    @POPI Pattern
    @POPI Array

    @PUSH LineWidth
    @SHR
    @SUB 8       # Center Cursor based on 1/2 width of word
    @POPI Cursor
    @PRT "Pattern: " 
    @ForIA2B Index1 0 16
       @PUSHI Pattern
       @AND 0x1
       @IF_NOTZERO
          @PRT "*"
          @PutA Array Cursor 1
       @ELSE
          @PRT " "
       @ENDIF
       @POPNULL
       @INCI Cursor
       @PUSHI Pattern
       @SHR
       @POPI Pattern
    @Next Index1
    @PRTNL
@EndLocals
@POPRETURN
@RET
       
    
#=====================================
# SeedArray(Array)
#=====================================
:SeedArray
@PUSHRETURN
@Locals
   @Local Array
   @Local Index1

   @POPI Array

   @ForIA2B Index1 0 LineWidth
       @CALL frnd16 @AND 0xf
       @IF_LT_A 3
         @PutA Array Index1 1
       @ELSE
         @PutA Array Index1 0
       @ENDIF
       @POPNULL
   @Next Index1
@EndLocals
@POPRETURN
@RET

##############################
# Main
##############################
:Main .Org Main
@Locals
   @Local P1
   @Local P2
   @Local C1
   @Local Index1
   @Local WX1
   @Local WX2
   @Local GenerationLeft
   
   
   @PUSH 0xf000 @SUB ENDOFCODE
   @POPI MainHeap
   @Call(AV) HeapDefineMemory ENDOFCODE MainHeap
   @POPI MainHeap

   # Set random seed
   @GETTIME
   @POPNULL      # Use lower word of 32 bit time
   @CALL rndsetseed

   @MA2V MaxGenerations GenerationLeft

   @PRTLN "+-------------------------------------------+"
   @PRTLN "|               LIFE 1.5                    |"
   @PRTLN "| Rules:                                    |"
   @PRT   "| Survival Count " @PRTREF MinNeighboors
   @PRT " through " @PRTREF MaxNeighboors
   @PRTLN "\t\t\t\t|"
   @PRT   "| Birth Count " @PRTREF BeBornMin
   @PRT " through " @PRTREF BeBornMax
   @PRTLN "\t\t\t\t\t|"
   @PRT   "| Max Generations: " @PRTI GenerationLeft
   @PRTLN "\t\t\t\t|"
   @PRTLN "+-------------------------------------------+"
   @Call(A) SetupArray LineWidth
   @POPI P1
   @Call(A) SetupArray LineWidth
   @POPI P2
   @Call(A) SetupArray LineWidth
   @POPI C1
#
# Seed first patterns with 16 bit binary pattern which will be centered in Array
#
   @Call(V) ClearArray P1
   @PRT "P1:"
   #                         0123456789ABCDEF   
   @Call(VA) FixedArray P1 0b1111110011111111
   @Call(V) ClearArray P2  
   @PRT "P2:"
   #                         0123456789ABCDEF      
   @Call(VA) FixedArray P2 0b1111110011111111

#
   # Calculate WX1 and WX2
   @PUSH LineWidth
   @SHR
   @PUSH LineWindow
   @SHR
   @SUBS
   @POPI WX1
   @PUSHI WX1
   @ADD LineWindow
   @POPI WX2

   @PUSH 0
   @WHILE_ZERO
      @Call(V) ClearArray C1
      @ForIA2B Index1 0 LineWidth
         @Call(VVV) CountAlive P1 P2 Index1
         @GetV P1 Index1
         @IF_NOTZERO
            # Previously Alive
            @POPNULL
            @IF_GE_A MinNeighboors
               @IF_LE_A MaxNeighboors
                  @PutA C1 Index1 1
               @ENDIF
            @ENDIF
            @POPNULL
         @ELSE
            # Previouls dead
            @POPNULL
            @IF_GE_A BeBornMin
               @IF_LE_A BeBornMax
                 @PutA C1 Index1 1
               @ENDIF
            @ENDIF
            @POPNULL
         @ENDIF
      @Next Index1
      @PRTNL
      @DECI GenerationLeft
      @ForIV2V Index1 WX1 WX2
         @GetV C1 Index1
         @IF_ZERO
            # Dead
            @PRT " "
         @ELSE
            # Alive
            @PRT "*"
         @ENDIF
         @POPNULL
      @Next Index1
      # Now Rotate C1<P1 P1<P2 P2<C1
      @PUSHI3 P2 P1 C1
      @POPI3 P1 P2 C1
      @IF_EQ_AV 0 GenerationLeft
         # Time to reseed
         @Call(V) SeedArray P1
         @Call(V) SeedArray P2
         @Call(V) ClearArray C1
         @PRT "\n---------------------------NEW_GENERATION------------------"
         @MA2V MaxGenerations GenerationLeft
      @ENDIF
  @ENDWHILE
@END


:ENDOFCODE
