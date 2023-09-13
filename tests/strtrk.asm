I common.mc
L screen.ld
L random.ld
L div.ld
L mul.ld
L tangental.ld
# List of major functions:
# InitGame(Seed,Dificulty)
# GetIndex(Index) Turns 1D Array Index of Gal Structure into memory pointer to same, with some error checks
# DrawStarMap     Prints 8x8 galactic map
# PrtShipStats    Begining of a Computer mode output, reports current ship and game info.
# MarkSeen(Index), scans and saves to Galctic Map, local quad and the 8 around it.
# PrintQuad(Index) Turns 1D index into X,Y map coordinates. 0-7,0-7 and print them.
# DistSpace(X1,Y1,X2,Y2) Returns integer distacne between two points on 0-7,0-7 grid
# ConfCurrentQuad(QuadIndex,SectorIndex) Setup Object array for Stars,StarBases and Klingns in named quad.
# KlingonAI, Handles the logic for Klingons that are 'off screen' including attacking distant starbases
# Command1,  User Interface, prompts and calls related functions
# ParseNumber(String)  Turns sting in [0-7][.[0-9]] format into two integers
# CheckDock  Examins the current Enterprise location, and if StarBase is close will refule and repair




# Star trek. 
# Galaxy is an 8x8 grid of quadrant, and each quadrant is also 8x8
# We'll have some small random numbers of Star-Bases for refueling and some larger number of Klingon's to hunt.
#
# To 'save' memory, each quadrant is kept only as three numbers of data.
#    1: Number of stars 0-5
#    2: Number of Bases 0-1
#    3: Number of Klingon 0-N
#
# The relative location of Stars and Bases and Klingon will be randomized each time we re-enter a quadrant
#
# Since we don't have Floating point math, we'll be using a hybrid math object to handle direction and targeting.
# Example Dir 0.0 is straight 0 degrees east or Y=0 X=1
#         Dir 1.0 is North East 45 degrees or Y=1 X=1
#         Dir 0.5 is NEE 22.7 degrees or Y=1 X=2 
#         Dir 3.0 is NW or 135 degrees or Y=1 X=-1
#
#               N
#            3  2  1
#             \ | / 
#           4 --+-- 0
#              /| \
#             5 6  7
#    Each major direction is a digit between 0 and 7 and between them are 9 micro adjustments.
#         each micro adjustment is about 4.7 degrees, which makes .5 about the 1/2 way point between the major directions.
#
# Commands:
# Short Range Scan  S
# Long Range Scan   L
# Galactic Map      G
# Warp(Dir) Dist    W#[.#] 1-8[.1-8]  Warps to Quadrant in Direction of Distance. 
# Impulse Dir Dist  I#[.#] 1-8        Impulse speed is in 1/8th quadrant units.
# Phaser Dir        P#[.#]            Phaser Energy Weapon. Does limited damage, but can be fired often
# Torpedo Dir       T#[.#]            Photon Torpedo, more damage, limited supply.
# C                 C                 Computer, reports ship condition and Direction information for nearby targets
# Deflector Shields D                 Toggles Deflector Shields, uses 10 energey per turn and shields up to 250 damage.
#
# Quadrant Data: Total of 8 bytes: Address(N) is BaseMem+(N<<3)
# Fields
# 0-1       Stars
# 2-3       Bases
# 4-5       Klingon's
# 6-7       Random-Seed
# We are going to print the Title in small bits so we can use it as a status
# bar during initialization. Each call will print an addition N characters
# when it hits end of string, it will just stop.
:Title 
"          ______ _______ ______ ______    _______ ______  ______ __  __ \n"
"         / __  //__  __// __  // __  /   /__  __// __  / / ____// / / / \n"
"        / / /_/   / /  / /_/ // /_/ /      / /  / /_/ / / /__  / /// \n"
"        _| |     / /  / __  //   __/      / /  /   __/ / __ / /  / \n"
"      / /_/ /   / /  / / / // /| |       / /  / /| |  / /___ / /| | \n"
"     /_____/   /_/  /_/ /_//_/  |_|     /_/  /_/  |_|/_____//_/  |_| \n"
" \n"
"                 __________________           __ \n"
"                |_________________|)____.---'--`---.____ \n"
"                              ||    |----.________.----/\n"
"                              ||     / /    `--'\n"
"                            __||____/ /_\n"
"                           |___         | \n"
"                               ^^^^^^^^^^\n" b0
:TitleLimit Title
:LocalChar 0


:TitlePrintNext
@SWP          # TOS will hold number of characters to print
@WHILE_NOTZERO
   @SUB 1
   @PUSHII TitleLimit
   @AND 0xff
   @IF_NOTZERO   # Have not hit end of title string yet.
     @POPI LocalChar
     @PRTSTRI LocalChar
     @INCI TitleLimit
  @ELSE
     @POPNULL @POPNULL # Remove the Null Char and the Char Count
     @PUSH 0           # Force Char Count to zero to exit while
     @MA2V Title TitleLimit  #Reset for possible future printings.
  @ENDIF
@ENDWHILE
@POPNULL
@RET


=StarsOffset 0
=BaseOffset 2
=KlingOffset 4
=SeedOffset 6
=SeenOffset 8
=StarCode 1
=BaseCode 2
=KlingonCode 3
=EnterpriseCode 5

# Major Global Variables
:ReturnI 0
:Difficulty 0
:GameSeedI 0
:MaxKlingons 0
:KlingonsSkill 0
:MaxEnergy 0
:CurrentEnergy 0
:StarBases 0
:TempQuad 0
:EnterpQuad 0     # X,Y stored as word bits 345 are X and bits 012 are Y
:EnterSect 0      # X,Y stored as word bits 345 are X and bits 012 are Y
:Index1 0
:Index2 0
:Index3 0
:DeflectUpDown 0    # Deflector Shields are up, if not zero
:DeflectorHealth 0  # As deflectors absorb damage, they drop in effect
:ObjectArray
. ObjectArray+256
:ObjectArrayCount 0
# Function: Procedure InitGame(Seed,Difficulty)
#   Initialize the main game arrays and global variables
#
:InitGame
   @PUSH 10 @CALL TitlePrintNext
   @POPI ReturnI
   @POPI Difficulty
   @POPI GameSeedI
   @PUSHI GameSeedI @CALL rndsetseed
# First set the adjustable values based on difficulty
   @PUSHI Difficulty
   @SWITCH
   @CASE 1
     @PUSH 5 @CALL rndint
     @MA2V 5 MaxKlingons
     @ADDI MaxKlingons @POPI MaxKlingons
     @MA2V 2000 MaxEnergy
     @MA2V 25 KlingonsSkill
     @MA2V 5 StarBases
     @CBREAK
   @CASE 2
     @PUSH 10 @CALL rndint
     @MA2V 10 MaxKlingons
     @ADDI MaxKlingons @POPI MaxKlingons
     @MA2V 1500 MaxEnergy
     @MA2V 50 KlingonsSkill
     @MA2V 3 StarBases
     @CBREAK
   @CDEFAULT
     @PUSH 10 @CALL rndint
     @MA2V 15 MaxKlingons
     @ADDI MaxKlingons @POPI MaxKlingons
     @MA2V 1000 MaxEnergy
     @MA2V 60 KlingonsSkill 
     @MA2V 2 StarBases
     @CBREAK
   @ENDCASE
   @MV2V MaxEnergy CurrentEnergy
   @POPNULL
@ForIA2B Index1 0 64     # Fill in number of stars and a random seed, zero 'seen'   
   @PUSH 10 @CALL TitlePrintNext
   @PUSHI Index1
   @CALL GetIndex
   @DUP @DUP             # On stack will be address Cell three times.
   @PUSH 5
   @CALL rndint          # 0-4
   @SWP
   @POPS                 # Move stars into place.   
   @ADD SeedOffset       # on stack 2 remaining address Cell, add seed offset to top one.
   @PUSH 4000            # Gen random seed between 0 - 3999
   @CALL rndint
   @SWP
   @POPS                 # After this stack will have 1 remaining Address cell
   @ADD SeenOffset       # Set 'seen' to zero
   @PUSH 0
   @SWP
   @POPS
@Next Index1
# Now loop through all the Star Bases and put exactly one in unique quadrants.
@ForIA2V Index1 0 StarBases
   @PUSH 10 @CALL TitlePrintNext
   @PUSH 0
   @WHILE_ZERO          # 
     @POPNULL           # 
     @PUSH 64           # 8x8 quads
     @CALL rndint       # Select a random quad to put a star-base 
#     @PRT "Base Located at : " @DUP @CALL PrintQuad @PRT " "
     @CALL GetIndex       # Get the memory address where Quad(N) is stored.
     @POPI TempQuad       # TempQuad is address of data structure for index 
     @PUSHI TempQuad      #
     @ADD BaseOffset
     @PUSHS
     @IF_ZERO
        @POPNULL
        @PUSH 1
        @PUSHI TempQuad
        @ADD BaseOffset
        @POPS            # Mem[Index].BaseOffset = 1
        @PUSH 1
        @PUSHI TempQuad
        @ADD SeenOffset
        @POPS            # Mem[Index].SeenOffset = 1
        @PUSH 1
     @ELSE
        @POPNULL          # Already have a station here, try again.
        @POPNULL
        @POPNULL
        @PUSH 0           # This will make the While loop try again
     @ENDIF
   @ENDWHILE
   @POPNULL
@Next Index1
#
# Now do the same thing for Klingon's, but we will allow up to 3 Klingon's in a quadrant.
@ForIA2V Index1 0 MaxKlingons     # 0
   @PUSH 10 @CALL TitlePrintNext
   @PUSH 0                        # 1
   @WHILE_ZERO                    # 1
      @POPNULL                    # 0
      @PUSH 64                    # 1
      @CALL rndint       # Find a possible quad to put the Klingon 1
      @POPI TempQuad     # 0
      @PUSHI TempQuad    # 1
      @CALL GetIndex     # 1
      @ADD KlingOffset   # 1
      @DUP               # 2
      @PUSHS             # 2 Fetch Current Klingon Count
      @IF_LT_A 3         # We only allow up to 3 Klingon's in a starting quad.
         @ADD 1          # 2
         @SWP            # 2
         @POPS           # 0
         @PUSH 1         # exit inner whileloop 1
      @ELSE
         @POPNULL        # Already reached 3 Klingon's, so just repeated while 1
         @POPNULL
         @PUSH 0         # 2
      @ENDIF
   @ENDWHILE
   @POPNULL
@Next Index1
@PUSH 1000 @CALL TitlePrintNext
#
# Now set Enterprise's location
@PUSH 64 
@CALL rndint
@POPI EnterpQuad
@PUSH 64
@CALL rndint
@POPI EnterSect
# Now mark the 8 around Enterprise as 'seen'
@PUSHI EnterpQuad
@CALL MarkSeen
# Now for the current Quad, create local map.
@PUSHI EnterpQuad
@PUSHI EnterSect
@CALL ConfCurrentQuad
@PRTLN "               `--------' "
@PRTNL
@PUSHI ReturnI
@RET
#
# Function GetIndex(N) returns the low-address of the byte structure at index N
:GetIndex
@SWP
@RTL @DUP @RTL @RTL @ADDS  # == Mul x 10
@ADD MapDataStart
@IF_LT_A MapDataStart
  @PRT "Error code Under: " @PRTHEXTOP @PRT " Out of range\n"
@ENDIF
@IF_GT_A MapDataStop
  @PRT "Error code Over: " @PRTHEXTOP @PRT " Out of range\n"
@ENDIF
@SWP
@RET
#
:MapDataStart
. MapDataStart+4096
:MapDataStop
# Function DrawStarMap() Entire Galaxy 
# 
:DrawStarMap
@PRTLN "Key: KBS, Klingon, Bases, Stars"
@CALL PrtShipStats
@PRTNL
@PRTLN "   1   2   3   4   5   6   7   8  "
@PRTLN " +---+---+---+---+---+---+---+---+"
@MA2V 0 Index2
@ForIA2B Index1 0 8  # Lines (or Y)
   @PUSHI Index1 @ADD 1 @PRTTOP @POPNULL  # Print Row Number
   @PRT "|"
   @ForIA2B Index2 0 8  # Columns (or X)
       @PUSHI Index1 @RTL @RTL @RTL 
       @ADDI Index2
       @CALL GetIndex
       @DUP @ADD SeenOffset @PUSHS     # Check if we've scanned this Quad
       @IF_NOTZERO
          @POPNULL
          @DUP @DUP  # TOS had address of top of structure, we need it several times
          @ADD KlingOffset @PUSHS
          @PRTTOP @POPNULL   # Print the # of Klingons
          @ADD BaseOffset @PUSHS
          @PRTTOP @POPNULL    #Print # StarBases
          @PUSHS              # This time we don't need to add an offset
          @PRTTOP @POPNULL    # Print # Stars
       @ELSE
          @POPNULL @POPNULL
          @PRT "---"
       @ENDIF
       @PRT "|"
   @Next Index2
    @PRTLN "\n +---+---+---+---+---+---+---+---+"
@Next Index1
@RET
#
# Function Print Ship Stats
:PrtShipStats
@PRT "Ent: ("
@PUSHI EnterpQuad @CALL PrintQuad
@PRT ") Erg:"
@PRTI MaxEnergy
@PRT " Base:"
@PRTI StarBases
@PRT " Klng:"
@PRTI MaxKlingons
@RET
#
# Function MarkSeen(Quad) Marks the 8 cells around Quad as 'seen'
:NSX1 0
:NSY1 0
:SX1 0
:SY1 0
:SFMS 0
:Index1MS 0
:Index2MS 0
:MarkSeen
@SWP # Save return
@DUP
@POPI TempQuad
@PUSH 8
@CALL DIV
@POPI SY1       # X offset Part
@POPI SX1       # Y offset Par
@ForIA2B Index1MS -1 2         # We go to 2 because we terminate loop at 2 but run -1 to 1
   @ForIA2B Index2MS -1 2
      @PUSHI SX1 @ADDI Index1MS @POPI NSX1 # NX=SX+I
      @PUSHI SY1 @ADDI Index2MS @POPI NSY1 # NY=SY+J
      @MA2V 0 SFMS   # Set condition flag to 0
      # We need all the following tests to all be true, any fail, we skip to next index
      @PUSHI NSX1
      @IF_GT_A 0x7fff @MA2V 1 SFMS @ENDIF   # I don't use 'one line' IF's too often...but it works here
      @IF_GT_A 7 @MA2V 1 SFMS @ENDIF
      @POPNULL
      @PUSHI NSY1
      @IF_GT_A 0x7fff @MA2V 1 SFMS @ENDIF
      @IF_GT_A 7 @MA2V 1 SFMS @ENDIF
      @POPNULL
      @PUSHI SFMS
      @IF_ZERO
         @PUSHI NSY1 @PUSHI NSX1
         @RTL @RTL @RTL                   # Index = X*8+Y
         @ADDS
         @CALL GetIndex
         @ADD SeenOffset  @PUSH 1  @SWP @POPS  # [Index].Seen=1
      @ENDIF
      @POPNULL
   @Next Index2MS
@Next Index1MS
@RET
#
# Function PrintQuat(location) Turn Int 64 into 8x8 comma version 
:PrintQuad
@SWP
@DUP
@RTR @RTR @RTR @AND 7 @ADD 1 @PRTTOP @POPNULL
@PRT ","
@AND 7 @ADD 1 @PRTTOP @POPNULL
@RET
#
# Function Distance Calculator
# DistSpace(X1,Y1,X2,Y2): Distance
# Distance is using a look table as it faster than doing the whole Floating Point thing
# We are dealing with 8x8 integer cells, so there is a maximum of 64 possible distance.
#
:DistSpace
@POPI ReturnDS
@POPI Y2DS
@POPI X2DS
@POPI Y1DS
@POPI X1DS
# First Normalize: 
@PUSHI Y2DS
@IF_LT_V Y1DS
   @PUSHI Y1DS @POPI Y2DS @POPI Y1DS  # Swap Y2DS and Y1DS to avoid Negative distance
@ELSE
   @POPNULL
@ENDIF
@PUSHI X2DS
@IF_LT_V X1DS
   @PUSHI X1DS @POPI X2DS @POPI X1DS  # Swap X2DS and X1DS to avoid Negative distance
@ELSE
   @POPNULL
@ENDIF
# Make X1 and Y2 the now relative to the origin point
@PUSHI Y2DS @SUBI Y1DS @POPI Y1DS
@PUSHI X2DS @SUBI X2DS @POPI X1DS
#
# Simplest cases are if Y1 or X1 == zero, which means distance is just the other variable
@PUSH 0
@IF_EQ_V Y1DS
   @POPNULL
   @PUSHI X1DS
   @PUSHI ReturnDS
   @RET
@ENDIF
@IF_EQ_V X1DS
   @POPNULL
   @PUSHI Y1DS
   @PUSHI ReturnDS
   @RET
@ENDIF
@POPNULL
# Before we start doing multiples to get the index of the square root table
# lets first make sure the values X1 and Y1 are in range 1-7
@PUSH 7
@IF_LT_V X1DS
   @PRT "Error: Space anononmly, too many dimensions"
   @END
@ENDIF
@IF_LT_V Y1DS
   @PRT "Error: Space anononmly, too many dimensions"
   @END
@ENDIF
@POPNULL
# Now we know the multiplications will be < 8x8
# Is it more efficient to use the MUL function or just add in a loop?
# My own time tests show that for small numbers like this it can be 3 times faster to use ADDs in a loop
@PUSH 0
# This should be equivalent of X1*8+Y1
@ForIV2V MulV1 0 X1DS
   @ADD 8
@Next MulV1
@ADDI Y1DS
# Worth noting here that all the fixed values in the SQRTTable are < 256 so we can use byte
# data for the lookups, just remember to zero out the high byte.
@ADD SQRTable
@PUSHS         # On stack was 1D Index and we added base address of table. Get the value now.
@AND 0xff
@PUSH ReturnDS
@RET
:ReturnDS 0
:Y1DS 0
:Y2DS 0
:X1DS 0
:X2DS 0
:MulV1 0
# This is precalculated 8x8 distant table INT(SQRT(X^2+Y^2)) as 1<= X |Y <= 8 our range is small
# 8x8 bytes of results are stored as a lookup table.
:SQRTable
b0  b1  b2  b3  b4  b5  b6  b7
b1  b1  b2  b3  b4  b5  b6  b7
b2  b2  b3  b4  b4  b5  b6  b7
b3  b3  b4  b4  b5  b6  b7  b8
b4  b4  b4  b5  b6  b6  b7  b8
b5  b5  b5  b6  b6  b7  b8  b9
b6  b6  b6  b7  b7  b8  b8  b9
b7  b7  b7  b8  b8  b9  b9  b10
@END
#
#
# Function ConfCurrentQuad(Quadnumber,Sector),
# configures the current quadrant. Building out where
# the stars as well as ware any Klingons or StarBases that might be in that quad.
# If this quad is different than the 'last' one that had Klingons in it, it will also
# re-initialize the Klingon ships. 
# The idea being that, you can 'leave' a quad in middle of battle to repair, but if you
# encounter any other Klingons, the ones in the original quad will have had time to also repair.
# But if you return directly back to the quad you where in the last time you saw Klingons
# again, they will be in the same health state as you left them. 
# Though there is a chance they might shift around a bit as we may overwrite their AY data
# if any quad you visit has more stars than this one.
:ConfCurrentQuad
@POPI ReturnCCQ
@POPI EnterSectCCQ 
@POPI ActiveQuadCCQ
#
@MA2V 0 ObjectsInQuadCCQ
#

@PUSHI ActiveQuadCCQ @CALL GetIndex  @POPI QuadIndexCCQ  # QuadIndex=Ptr to Quad Struct
@PUSHII QuadIndexCCQ @POPI StarCountCCQ                  # Stars at 0th location
@PUSHI QuadIndexCCQ @ADD BaseOffset @PUSHS               # Bases next
@POPI BaseCountCCQ
@PUSHI QuadIndexCCQ @ADD KlingOffset @PUSHS              # Klingons next
@POPI KlingCountCCQ
@PUSHI QuadIndexCCQ @ADD SeedOffset @PUSHS               # Cell's local Seed
@POPI QuadSeedCCQ
@PRT "Generating Quad: " @PRTI ActiveQuadCCQ @PRT " Stars: " @PRTI StarCountCCQ @PRT " Bases: " @PRTI BaseCountCCQ @PRT " Klingons: " @PRTI KlingCountCCQ @PRTNL
#
# Before We start creating the Map of Stars and Bases
# Save the active Random Seed and set it to a fixed one
# assosicated with this Quad.
@CALL rndgetseed
@POPI PreserveSeedCCQ
@PUSHI QuadSeedCCQ
@CALL rndsetseed
#
@MA2V ObjectArray ArryPtrCCQ   # Each Object in Quad is stored as 3 words, X,Y,Type
# We probably could have saved all this in one word as X and Y are 0-7 values and type is <=5 so 9 bits are all we need
# But for now we'll do this in the 'in-efficient' way of 3 words per object
# First Insert the Enterprise location. (This way we won't run into stars before we get to see the local map)
@PUSHI EnterSectCCQ @RTR @RTR @RTR @AND 0b0111 # Bits 345 are the X part
@POPII ArryPtrCCQ @INC2I ArryPtrCCQ
@PUSHI EnterSectCCQ @AND 0b0111     # Mask 0-7 is the Y part
@POPII ArryPtrCCQ @INC2I ArryPtrCCQ
@PUSH EnterpriseCode @POPII ArryPtrCCQ @INC2I ArryPtrCCQ   # Code to ID Enterprise on map
#
# Setup the stars, worth remembering that if StarCountCCQ is already zero, for loop will not run.
@ForIA2V Index1CCQ 0 StarCountCCQ
   @PUSH 1
   @WHILE_NOTZERO
      @POPNULL
      @PUSH 8 @CALL rndint @POPI TXCCQ
      @PUSH 8 @CALL rndint @POPI TYCCQ
      @PUSHI TXCCQ @PUSHI TYCCQ @PUSH ObjectArray @PUSHI Index1CCQ 
      @CALL CheckExists
   @ENDWHILE
   @POPNULL
   @PUSHI TXCCQ @POPII ArryPtrCCQ   # Just reminder POPII means mem[[ArrayPtr]]=value
   @INC2I ArryPtrCCQ
   @PUSHI TYCCQ @POPII ArryPtrCCQ
   @INC2I ArryPtrCCQ
   @PUSH StarCode @POPII ArryPtrCCQ  # Code 1 for stars
   @INC2I ArryPtrCCQ
@Next Index1CCQ
#
# Setup base if any.
@ForIA2V Index1CCQ 0 BaseCountCCQ          # Seems silly to use For here, its either 0 or 1
   @PUSH 1                                 # But this lets us use the same For style loop
   @WHILE_NOTZERO                          # as for Klingons and Stars, for readability.
      @POPNULL
      @PUSH 8 @CALL rndint @POPI TXCCQ
      @PUSH 8 @CALL rndint @POPI TYCCQ
      @PUSHI TXCCQ @PUSHI TYCCQ @PUSH ObjectArray @PUSHI Index1CCQ 
      @CALL CheckExists
   @ENDWHILE
   @PUSHI TXCCQ @POPII ArryPtrCCQ
   @INC2I ArryPtrCCQ
   @PUSHI TYCCQ @POPII ArryPtrCCQ
   @INC2I ArryPtrCCQ
   @PUSH BaseCode @POPII ArryPtrCCQ  # Code 2 for Bases
   @INC2I ArryPtrCCQ
@Next Index1CCQ
# Now Klingons
@ForIA2V Index1CCQ 0 KlingCountCCQ
   @PUSH 1
   @WHILE_NOTZERO
      @POPNULL
      @PUSH 8 @CALL rndint @POPI TXCCQ
      @PUSH 8 @CALL rndint @POPI TYCCQ
      @PUSHI TXCCQ @PUSHI TYCCQ @PUSH ObjectArray @PUSHI Index1CCQ 
      @CALL CheckExists
   @ENDWHILE
   @POPNULL
   @PUSHI TXCCQ @POPII ArryPtrCCQ
   @INC2I ArryPtrCCQ
   @PUSHI TYCCQ @POPII ArryPtrCCQ
   @INC2I ArryPtrCCQ
   @PUSH KlingonCode @POPII ArryPtrCCQ  # Code 3 for Klingons
   @INC2I ArryPtrCCQ
   @PUSHI ActiveQuadCCQ
   @IF_EQ_V LastSeenCCQ
      # If this is a case of returning to battle after leaving it.
      # Then we leave the old Klingon Health values.
   @ELSE
      # New set of Klingons means new health values.
      @PUSHI Index1CCQ @RTL
      @ADD KlingHealthArray
      @PUSH 100 @SWP @POPS# KlingHealthArray[Index]=100
   @ENDIF
   @POPNULL
   @MV2V ActiveQuadCCQ LastSeenCCQ        # We update this when we see Klingons.
@Next Index1CCQ
@PUSHI KlingCountCCQ @ADDI BaseCountCCQ @ADDI StarCountCCQ @ADD 1  # Last 1 is for the Enterprise itself
@POPI ObjectArrayCount  # Save the total for later printouts

# Restore the 'random' seed so game continues with normal randomness.
@PUSHI PreserveSeedCCQ
@CALL rndsetseed
@PUSHI ReturnCCQ
@RET
:ReturnCCQ 0
:EnterSectCCQ 0
:TXCCQ 0
:TYCCQ 0
:ActiveQuadCCQ 0
:ObjectsInQuadCCQ 0
:QuadIndexCCQ 0
:StarCountCCQ 0
:BaseCountCCQ 0
:KlingCountCCQ 0
:PreserveSeedCCQ 0
:QuadSeedCCQ 0
:ArryPtrCCQ 0
:LastSeenCCQ 0
:Index1CCQ 0
:KlingHealthArray   #This is how we define a 'large' block of memory.
. KlingHealthArray+64
#
# CheckExists(TestX,TestY,ArryPtr,SizeArray): 0 if not found, or value if found
# Our Arry assumes 6 bytes or 3 words for each entry, cells 0,1 are the index values, cell 2 is not used here.
:CheckExists
@POPI ReturnCE
@POPI SizeCE
@POPI ArryPtrCE
@POPI TestYCE
@POPI TestXCE
@ForIA2V IndexCE 0 SizeCE
   @PUSHI IndexCE @RTL  # Index*2
   @ADDI IndexCE  @RTL  # +Index *2 == Index*6
   @ADDI ArryPtrCE
   @POPI CellIndexCE
   @PUSHII CellIndexCE   # Get the 0 cell, or X value
   @IF_EQ_V TestXCE
        @POPNULL
        @INC2I CellIndexCE
        @PUSHII CellIndexCE  # Get the 1 cell or Y value
        @IF_EQ_V TestYCE
            @POPNULL
            @INC2I CellIndexCE
            @PUSHII CellIndexCE  # Get they type of value in cell
            @PUSHI ReturnCE
            @RET
        @ENDIF
   @ENDIF
   @POPNULL
@Next IndexCE
@PUSH 0                      # No Match found return 0
@PUSHI ReturnCE
@RET
:ReturnCE 0
:SizeCE 0
:ArryPtrCE 0   
:CellIndexCE 0
:TestYCE 0
:TestXCE 0
:IndexCE 0
:ArryPtrCE 0
:MIdx 0
#
#
# SRSDisplay(Quad) Displays the Short range map.
:SRSDisplay
@POPI ReturnSRS
@MA2V ObjectArray ArryPtrCCQ         # Reusing the same memory and structures as ConfCurrentQuad
@PRT   "              ("
@PUSHI EnterpQuad @CALL PrintQuad 
#@PRT "[" @PUSHI EnterSectCCQ @CALL PrintQuad @PRT "]"
@PRTLN ")   " # some space for possible future screen refresh logic
#
# Debug
#
#@ForIA2V Index1 0 ObjectArrayCount
#   @PUSHI Index1 @RTL @ADDI Index1 @RTL   # Index*6
#   @ADD ObjectArray
#   @PRT "["
#   @DUP @PUSHS @ADD 1 @PRTTOP @PRT "," @POPNULL
#   @DUP @ADD 2 @PUSHS @ADD 1 @PRTTOP @PRT "," @POPNULL
#   @ADD 4 @PUSHS @PRTTOP @PRT "]" @POPNULL
#@Next Index1
#@PRTNL

@PRTLN "  1   2   3   4   5   6   7   8  "
#@PRTLN " +===+===+===+===+===+===+===+===+"
@ForIA2B IndexY 0 8
   @ForIA2B IndexX 0 8
      @PUSHI IndexX
      @IF_ZERO
         @PUSHI IndexY @ADD 1
         @PRTLN " |---+---+---+---+---+---+---+---|"
         @PRTTOP
         @PRT "|"
         @POPNULL
      @ENDIF
      @POPNULL
      @PUSHI IndexX
      @PUSHI IndexY
      @PUSH ObjectArray
      @PUSHI ObjectArrayCount
      @CALL CheckExists
      @SWITCH
      @CASE 0
         @PRT "   |"
         @CBREAK
      @CASE StarCode
         @PRT " * |"
         @CBREAK
      @CASE BaseCode
         @PRT "<+>|"
         @CBREAK
      @CASE KlingonCode
         @PRT " K |"
         @CBREAK
      @CASE EnterpriseCode
         @PRT "@-=|"
         @CBREAK
      @CDEFAULT
         @PRT " . |"
         @CBREAK
      @ENDCASE
      @POPNULL
   @Next IndexX
   @PRTNL
@Next IndexY
@PRTLN " +---+---+---+---+---+---+---+---+"
@PUSHI ReturnSRS
@RET
:IndexX 0
:IndexY 0
:ReturnSRS 0
#
# Test of  DistSpace function

@ForIA2B MIdx 0 20
   @PRT "Test: " @PRTI MIdx @PRT "("
   @PUSH 8  @CALL rndint @PRTTOP @PRT "," 
   @PUSH 8  @CALL rndint @PRTTOP @PRT ")-("
   @PUSH 8  @CALL rndint @PRTTOP @PRT ","
   @PUSH 8  @CALL rndint @PRTTOP @PRT ")="
   @CALL DistSpace
   @PRTTOP @PRTNL
   @POPNULL
@Next MIdx
#
#
# Function KlingonAI
# Loops though all the possible Klingons, and based on KlingonSkill level make them do something.
:KlingonAI
@PUSHI MaxKlingons
@IF_ZERO
   @PRTLN "\nYou have Won!\n\n"
   # Do the end game cleanup
   @END
@ENDIF
@POPNULL
@ForIA2B IndexQuad 0 64
   @IF_EQ_VV IndexQuad EnterpQuad
      # If this is true, then if any Klingons are in this Quad we already will handle it 
      # with the combat operations. This loop is for off screen Klingons only
   @ELSE
      @PUSHI IndexQuad
      @CALL GetIndex
      @DUP
      @ADD KlingOffset
      @POPI KlingCntPtr    # Points to the array index where count of this Quads Klingons is kept
      @ADD BaseOffset
      @POPI BaseCntPtr
      @PUSHII KlingCntPtr
      @POPI LocalKlingCnt
      @PUSHI LocalKlingCnt
      @WHILE_NOTZERO
           @DECI LocalKlingCnt
           @POPNULL
           # There be Klingon's here.
           # There may even be more than one, so do this in loop
           #
           # First question, are there any StarBases here?
           @PUSHII BaseCntPtr
           @IF_NOTZERO
              @POPNULL
              # There is a star-base here, attack it!
              # Rule is for each Klingon in Quad, there is a 1/16th chance to destroy the base.
              @PRTLN "WARNING!!!!!"
              @PRT "SOS Call from Star-Base " @PRTI IndexQuad @PRT " In Quadrant (" 
              @PUSHI IndexQuad @CALL PrintQuad @PRTLN ") It is Under Attack!"
              @PUSH 16 @CALL rndint
              @IF_ZERO
                  @PRT "..........The Star-Base HAS BEEN DESTROYED!...........\n\n\n\n"
                  @POPII BaseCntPtr     # Zero Out star base from this Quad
                  @DECI StarBases       # Subtract one from total Star-Base Count. 
              @ELSE
                  @POPNULL
              @ENDIF
           @ELSE
               # No star base here, so Klingon needs to decide if it's going to stay in this Quad or move
               # to an adjactent one...and how 'smart' it is can help it move towards the direction the 
               # Enterprise is currently. 'Smarter' Klingons will eventually swam the Enterprise if it
               # is not moving.
               @POPNULL
               @PUSH 100 @CALL rndint
               @IF_GT_A 10         # 10% chance of just staying here doing star mapping.
                  # So Klingon going to move, but which direction?
                  # Smarter Klingons will magicly know where the Enterprise is and will head that way
                  # Lowest KlingonSkill is 25, highest is 60
                  # So we'll use RND(50)+Skill > 70 means head towards the Enterprise
                  @POPNULL
                  @PUSHI IndexQuad @DUP
                  # Get the Klingons galatic poition
                  @AND 0x7 @POPI LSY 
                  @RTR @RTR @RTR @AND 0x7 @POPI LSX
                  @PUSH 50 @CALL rndint @ADDI KlingonsSkill
                  @IF_GT_A 70
                      @POPNULL
                      # Target Enterprise (We know we're Not IN the same quad as enterprise from earlier test)
                      @PUSHI EnterpQuad @DUP
                      @AND 0x7 @POPI QUY
                      @RTR @RTR @RTR @AND 0x7 @POPI QUX
                      @PUSHI QUY
                      @IF_LT_V LSY   # Enterprise is above Klingon, move north
                         @DECI LSY
                      @ELSE
                         @INCI LSY
                      @ENDIF
                      @POPNULL
                      @PUSHI QUX
                      @IF_LT_V LSX   # Enterprise is Left of Klingon Move West
                         @DECI LSX
                      @ELSE
                         @INCI LSX
                      @ENDIF
                      @POPNULL
                  @ELSE
                     @POPNULL
                     # Klingon wants to move but don't care about Enterprise
                     @PUSH 3 @CALL rndint @SUB 1  # 0-2 =1 == -1 to +1
                     @ADDI LSX @POPI LSX
                     @PUSH 3 @CALL rndint @SUB 1  # 0-2 =1 == -1 to +1
                     @ADDI LSY @POPI LSY
                  @ENDIF
                  # This is a chance the above will make Klingon go off map.
                  # Fix that.
                  @PUSHI LSX
                  @AND 0x8000 #Negative Test
                  @IF_NOTZERO
                     @MA2V 0 LSX
                  @ENDIF
                  @POPNULL
                  @PUSHI LSY
                  @AND 0x8000 #Negative Test
                  @IF_NOTZERO
                     @MA2V 0 LSY
                  @ENDIF
                  @POPNULL
                  @PUSHI LSX 
                  @IF_GT_A 7
                     @MA2V 7 LSX
                  @ENDIF
                  @POPNULL
                  @PUSHI LSY
                  @IF_GT_A 7
                     @MA2V 7 LSY
                  @ENDIF
                  @POPNULL
                  # Now remove the Klingon from the Current Quad
                  @PUSHII KlingCntPtr
                  @SUB 1
                  @POPII KlingCntPtr
                  # Put it in it's new Quad
                  @PUSHI LSX @RTL @RTL @RTL @ADDI LSY
                  @CALL GetIndex
                  @ADD KlingOffset
                  @DUP      #Will need it twice
                  @PUSHS    # Fetch it
                  @ADD 1    
                  @SWP
                  @POPS     # Put it back
              @ELSE
                 @POPNULL
              @ENDIF
           @ENDIF
           @PUSHI LocalKlingCnt           
      @ENDWHILE
      @POPNULL
   @ENDIF   # Way back up there, was test if Enterprise was in this quad.
@Next IndexQuad
@RET
                  

           
      
:KlingCntPtr 0
:LocalKlingCnt 0
:BaseCntPtr 0
:IndexQuad 0
#
#
:LSX 0
:LSY 0
:QUX 0
:QUY 0
:V1In 0
:V2In 0
:TimeUsed 0
:CmdString "                                         " b0
#
# Function. Command1 First simple pass of navigation tests
:Command1
# Give the Klingons a chance to move first.
@CALL KlingonAI
@PRT "==> "
@READS CmdString

# Most actions take 1 unit of time.
@MA2V 1 TimeUsed
@PUSHI EnterpQuad @AND 0x7 @POPI QUY
@PUSHI EnterpQuad @RTR @RTR @RTR @AND 0x7 @POPI QUX
@PUSHI EnterSect @AND 0x7 @POPI LSY
@PUSHI EnterSect @RTR @RTR @RTR @AND 0x7 @POPI LSX
@PRT "\nLocation(" @PRTI QUX @PRT "." @PRTI LSX @PRT "," @PRTI QUY @PRT "." @PRTI LSY @PRTLN ")"
@PUSHI CmdString
@AND 0xff
@SWITCH
@CASE "n\0"
   @PUSHI LSY @SUB 1 @AND 0xff
   @IF_LT_A 8      @POPI LSY @PRTLN "Inpulse N"
   @ELSE
      @POPNULL # No change
   @ENDIF
   @CBREAK
@CASE "s\0"
   @PUSHI LSY @ADD 1 @AND 0xff
   @IF_LT_A 8      @POPI LSY @PRTLN "Inpulse S"
   @ELSE
      @POPNULL # No change
   @ENDIF
   @CBREAK
@CASE "N\0"
   @PUSHI QUY @SUB 1 @AND 0xff
   @IF_LT_A 8      @POPI QUY @PRTLN "Warp N"
   @ELSE
      @POPNULL # No change
   @ENDIF
   @CBREAK
@CASE "S\0"
   @PUSHI QUY @ADD 1 @AND 0xff
   @IF_LT_A 8      @POPI QUY @PRTLN "Warp S"
   @ELSE
      @POPNULL # No change
   @ENDIF
   @CBREAK
@CASE "e\0"
   @PUSHI LSX @ADD 1 @AND 0xff
   @IF_LT_A 8        @POPI LSX @PRTLN "Inpulse E"
   @ELSE
      @POPNULL # No change
   @ENDIF
   @CBREAK
@CASE "w\0"
   @PUSHI LSX @SUB 1 @AND 0xff
   @IF_LT_A 8        @POPI LSX @PRTLN "Inpulse W"
   @ELSE
      @POPNULL # No change
   @ENDIF
   @CBREAK
@CASE "E\0"
   @PUSHI QUX @ADD 1 @AND 0xff
   @IF_LT_A 8        @POPI QUX @PRTLN "Warp E"
   @ELSE
      @POPNULL # No change
   @ENDIF
   @CBREAK
@CASE "W\0"
   @PUSHI QUX @SUB 1 @AND 0xff
   @IF_LT_A 8        @POPI QUX @PRTLN "Warp W"
   @ELSE
      @POPNULL # No change
   @ENDIF
   @CBREAK
@CASE "G\0"
   @MA2V 0 TimeUsed   # Drawing Galactic Map is a 'free' move
   @CALL DrawStarMap
   @CBREAK
@CASE "L\0"
   @PUSHI EnterpQuad
   @CALL MarkSeen
   @CALL DrawStarMap
   @CBREAK
@CASE "M\0"
   @CALL SRSDisplay
   @CBREAK
@CASE "P\0"       # Photon Torpedo
   @PUSH CmdString
   @ADD 1
   @CALL ParseNumber 
   @POPNULL # First return val is length of string used.
   @POPI V1In 
   @POPI V2In
   @PRT "In Case " @StackDump
   @PUSHI EnterSect @RTR @RTR @RTR @AND 0x7  # Push CurX
   @PUSHI EnterSect @AND 0x7                 # Push CurY
   @PUSHI V1In @PUSHI V2In                    # Angle S.A
   @PUSH 8                                   # Sector is 8x8
   @PRTLN "Fire along: " @PRTI V1In @PRT "." @PRTI V2In @PRTNL
   @CALL FireTrack
   @PRTLN "---------"
   @CBREAK
@CASE "Q\0"
   @END
   @CBREAK
@CDEFAULT
   @CBREAK
@ENDCASE
@POPNULL
@PUSHI QUX @RTL @RTL @RTL @ADDI QUY @POPI EnterpQuad
@PUSHI LSX @RTL @RTL @RTL @ADDI LSY @POPI EnterSect
@RET
#
# Function: ParseNumber(String)
# We have a special number format N[.M]
# N is in range 0-7 and M is 0-9
# This is used is several cases like navagation and targeting.
# Returns [length,Val1, Val2].
# If length == 0: No number found and val1=val2=0
# If Val1=9 then Error was detected 
#
:CharPN 0
:Index1PN 0
:Result1PN 0
:Val1PN 0
:Val2PN 0
:ReturnPN 0
:StrPtrPN 0
:StrLenPN 0
:StatePN 0
#
:ParseNumber
@POPI ReturnPN
@POPI StrPtrPN
@MA2V 0 Result1PN
@MA2V 0 StatePN     
@MV2V StrPtrPN StrLenPN         # Will use to calculate acutual LEN used later.
@PUSH 1
@WHILE_NOTZERO
    @POPNULL
    @PUSHII StrPtrPN @AND 0xff  # Get Next Character
    @POPI CharPN
    # We use StatePN as a tiny state machine
    # State 0:  ptr while CharPN == WhiteSpace
    # State 1:  must be character in range 0-7
    # State 2:  Move to state 3 if ch="." else exit
    # State 3:  must be characterin range 0-9, then exit
    # State 4:  Unexpected character, error exit.
    # State 5:  Successful Exit
    @PUSHI StatePN
    @SWITCH
    @CASE 0
       @POPNULL
       @PUSHI CharPN
       @IF_EQ_A " \0"
           @INCI StrPtrPN
       @ELSE
           @MA2V 1 StatePN    # Once a non-space is found move to state 1
       @ENDIF
       @CBREAK
    @CASE 1                   # Valididate that 1st digit in range 0-7
       @POPNULL
       @PUSHI CharPN
       @IF_LT_A "0\0"
           @PRTLN "Under Not Digit"
           @MA2V 4 StatePN
       @ELSE
           @IF_GT_A "7\0"     # For first digit, only 0-7 allowed.
              @PRTLN "Over Not Digit"
              @MA2V 4 StatePN
           @ELSE
              @DUP            # Leave a copy on stack to be poped off later.
              @SUB "0\0"      # Valid character subtract ord("0") to get value
              @POPI Val1PN
              @MA2V 2 StatePN
              @INCI StrPtrPN
           @ENDIF
       @ENDIF
       @CBREAK
    @CASE 2                   # Validate that next character is "." or exit
       @POPNULL
       @PUSHI CharPN
       @IF_EQ_A ".\0"         # If "." then move to State 3
          @INCI StrPtrPN
          @MA2V 3 StatePN
       @ELSE                  # Anything else means it was just a 1 digit value
          @MA2V 0 Val2PN
          @MA2V 5 StatePN
       @ENDIF
       @CBREAK
    @CASE 3                   # Must be char in range 0-9 or error
       @POPNULL
       @PUSHI CharPN
       @IF_LT_A "0\0"
          @MA2V 4 StatePN
       @ELSE
          @IF_GT_A "9\0"
             @MA2V 4 StatePN             
          @ELSE
              @DUP            # Leave a copy on stack to be poped off later.
              @SUB "0\0"      # Valid character subtract ord("0") to get value
              @POPI Val2PN
              @MA2V 5 StatePN   # Successfull, so good exit.
              @INCI StrPtrPN
          @ENDIF
       @ENDIF
       @CBREAK
    # We don't need a case for state 5 as it just an exit code.
    @CDEFAULT
       @CBREAK
    @ENDCASE
    @POPNULL
    @PUSHI StatePN
    @IF_GE_A 4
       @IF_EQ_A 4
           @PRTLN "Syntax Error. Inproperly formated Number"
           @MA2V 9 Val1PN
       @ENDIF
       @POPNULL
       @PUSH 0        # End the While loop if at either exit case
    @ELSE
       @POPNULL
       @PUSH 1        # Continue the While Loop
    @ENDIF
@ENDWHILE
@POPNULL
@PUSHI Val2PN
@PUSHI Val1PN
@PUSHI StrPtrPN
@SUBI StrLenPN        # This should calculate LEN used
@PUSHI ReturnPN
@RET
#
# Function CheckDock
#     Checks to see if Enterprise is within 2 units of a starbase. Is so, restocks supplies.
:CheckDock
#
# Check if there Are any starbases in current quad and dock if close enough.
:CheckDock
@PUSHI EnterpQuad
@CALL GetIndex
@ADD BaseOffset
@PUSHS
@IF_NOTZERO
   # THere's a base here. See where it is.
   @ForIA2V IndexCD 0 ObjectArrayCount
       @PUSHI IndexCD  @RTL @DUP @RTL @ADDS # X*2+X*4 = X*6
       @ADD ObjectArray @DUP @POPI BasePtr
       @ADD 4 @PUSHS   # See if this objet is the Starbase
       @IF_EQ_A BaseCode
          @PUSHI EnterSect @RTR @RTR @RTR @AND 0x7  # Enterprise's X
          @PUSHI EnterSect @AND 0x7                 # Enterprise's Y
          @PUSHI BasePtr @PUSHS                     # Base's X
          @PUSHI BasePtr ADD 2 @PUSHS               # Base's Y
          @CALL DistSpace
          @IF_LT_A 2
             @PRTLN "Ship Docked."
             @MV2V MaxEnergy CurrentEnergy
          @ENDIF
          @POPNULL
        @ENDIF
        @POPNULL
    @Next IndexCD
@ENDIF
@POPNULL
@RET          
:IndexCD 0
:BasePtr 0

#
#
# function: FireTrack(Start_X,Start_Y,DIR1,DIR2,SCALE)
# Based on shottype will fire either a phaserbeem or a Torpedo at DIR1.DIR2, and return list of points
:FireTrack
@POPI ReturnFT
@POPI ScaleFT
@POPI Dir2FT
@POPI Dir1FT
@POPI Y1FT
@POPI X1FT
# Turn DIR's into an angle
:Break1A
@PUSHI Dir1FT @PUSH 450 @CALL MUL  # Dir1*450 for a 0-3590 circle*10
@PUSHI Dir2FT @PUSH 45 @CALL MUL   # Dir2*45 (4.5 degrees) for space between
@ADDS
@PUSH 10 @CALL DIV  @SWP @POPNULL # Leaves a 0-360 angle on TOS
# Calculate the Delta where the end points will be on the maps current scale

@POPI AngleFT
:Break2
@PUSHI AngleFT @CALL COSD  # Cos(Angle)
@PUSHI ScaleFT @CALL MUL   # * Scale
@PUSH 1000 @CALL DIV @SWP @POPNULL
@POPI DeltaXFT
@PUSHI AngleFT @CALL SIND  # Sin(Angle)
@PUSHI ScaleFT @CALL MUL   # * Scale
@PUSH 1000 @CALL DIV @SWP @POPNULL
@POPI DeltaYFT
:Break1

#
# Set the End Point at edge of map at current sale
@PUSHI X1FT @ADDI DeltaXFT @POPI X2FT
@PUSHI Y1FT @ADDI DeltaYFT @POPI Y2FT
#
@MA2V 0 MisslePathSize   # Initilize point list
# First change order so X2 > X1
@PUSHI X2FT
@IF_LT_V X1FT
    @PUSHI X1FT
    @SWP
    @POPI X1FT
    @POPI X2FT
@ELSE
    @POPNULL
@ENDIF
# First change order so Y2 > Y1
@PUSHI Y2FT
@IF_LT_V Y1FT
    @PUSHI Y1FT
    @SWP
    @POPI Y1FT
    @POPI Y2FT
@ELSE
    @POPNULL
@ENDIF
# Setup Deltas.
@PUSHI X2FT @SUBI X1FT @POPI DXFT
@PUSHI Y2FT @SUBI Y1FT @POPI DYFT
#
@MV2V Y1FT CurYFT
@MA2V MisslePathData PathPtr   # Point to start of list
#
@PRT "Line (" @PRTSGNI X1FT @PRT "," @PRTSGNI Y1FT @PRT ")-("
@PRTSGNI X2FT @PRT "," @PRTSGNI Y2FT @PRTLN ")"
#IF DX is zero then draw a vertical line, without slope
@PUSHI DXFT
@IF_ZERO
   @POPNULL
   @ForIV2V CurYFT Y1FT Y2FT
      @PUSHI CurYFT @PUSHI X1FT
      @POPII PathPtr @INC2I PathPtr  # Save Point
      @POPII PathPtr @INC2I PathPtr
      @INCI MisslePathSize
   @Next CurYFT
@ELSE
   @ForIV2V CurXFT X1FT X2FT
      @PUSHI CurYFT @PUSHI CurXFT
      @POPII PathPtr @INC2I PathPtr
      @POPII PathPtr @INC2I PathPtr  # Save Point
      @INCI MisslePathSize
      @PUSHI DRIVFT
      @IF_GT_A 0
          @INCI CurYFT
          @PUSHI DXFT @RTL @SUBS @POPI DRIVFT # D = D - 2*dx
      @ELSE
          @POPNULL
      @ENDIF
      @PUSHI DRIVFT
      @PUSHI DYFT @RTL @ADDS @POPI DRIVFT # D = D + 2*dy
   @Next CurXFT
@ENDIF
@MA2V MisslePathData PathPtr   # Point to start of list
@ForIA2V CurYFT 0 MisslePathSize
   @PUSHII PathPtr @INC2I PathPtr
   @PRTSGNTOP @PRT ","
   @PUSHII PathPtr @INC2I PathPtr
   @PRTSGNTOP @PRTNL
   @POPNULL @POPNULL
@Next CurYFT
@PRT "End: " @StackDump
@PUSHI ReturnFT
@RET


# The furthest a weapan can fire is 10 units. So we will need a max of 20 words or 40 bytes of path info
:MisslePathData
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
:MisslePathSize 0
:PathPtr 0
:ReturnFT 0
:Dir1FT 0
:Dir2FT 0
:ScaleFT 0
:DeltaXFT 0
:DeltaYFT 0
:X1FT 0
:X2FT 0
:Y1FT 0
:Y2FT 0
:DXFT 0
:DYFT 0
:DRIVFT 0
:CurXFT 0
:CurYFT 0
:AngleFT 0
#
# Main Entry Point.
#
#
:Main . Main
# Init(RndSeed,Difficulty)
@PUSH 100 @PUSH 1
@CALL InitGame
@MA2V 0o43 EnterpQuad
@MA2V 0o44 EnterSect
@CALL DrawStarMap
@PUSH 1
@WHILE_NOTZERO
   @PUSHI EnterpQuad
   @PUSHI EnterSect
   @CALL ConfCurrentQuad
#   @CALL SRSDisplay
   @PRTLN "(NnSsEeWw: Move, L:ong Range Scan, G:alactic Map, M:ap Sector Q:uit)"
   @CALL Command1
@ENDWHILE
@END

# Junk calls bellow here for debug
#
#@PUSH ObjectArray @RTL @DUP @RTL @ADDS # X*2+X*4=X*6
#@POPI Index2
#@MA2V 0 Index3

@PRT "Objects In Quad: " @PRTI Index2 @PRTNL
@ForIA2B EnterpQuad 0 64
  @PRTNL
  @PUSHI EnterpQuad
  @PUSH 64 @CALL rndint
  @CALL ConfCurrentQuad
  @CALL SRSDisplay
  @POPNULL
  @PRT "Did " @PRTI EnterpQuad @PRT " "
@Next EnterpQuad
@END
