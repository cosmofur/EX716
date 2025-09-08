I common.mc
L softstack.ld
L random.ld
L heapmgr.ld
L string.ld
L screen.ld

M LocalVar = %1 Var%2 @PUSHLOCALI Var%2
M RestoreVar @POPLOCAL Var%1
##############################################
# Data Structure Info

# Bot Structure
=BofsHealth 0                     # Bot health
=BofsXloc BofsHealth+2            # X Location
=BofsYloc BofsXloc+2              # Y Location
=BofsRule BofsYloc+2              # Movement rule (prefered direction)
=BofsAggres BofsRule+2            # Aggression level of Bot
=BofsRange BofsAggres+2           # Min Range to attack.
=BofsDamage BofsRange+2           # Damage Bot Does per turn
=BofsDlimit BofsDamage+2          # Max distance Bot will go before turning.

# MicroMap Structure
=MMofsBiom 0                      # Biom determins tree/land/water types %
=MMofsRow1 MMofsBiom+2            # [-1,-1][0,-1][1,-1]  Top row of 3x3 terrain
=MMofsRow2 MMofsRow1+6            # [-1,0][0,0][1,0]     Middle row of 3x3 terrain
=MMofsRow3 MMofsRow2+6            # [-1,1][0,1][1,1]     Bottom row of 3x3 terrain
#
# The world map is a sparce graph made up of tiles each tile contains a fixed random seed
# which is used to recreate the body part of that tile, when its needed.
# Bots can only travel in lines of adjacent tiles so we can used a linked list method to find adjacent tiles.
=TMofsBiom 0                      # Biom of tile.
=TMofsX1 TMofsBiom+2              # Map is read (X,Y)-(X2,Y2) Origin is UPPER left so Top Y < Bootom Y
=TMofsY1 TMofsX1+2
=TMofsX2 TMofsY1+2              # Map is read (X,Y)-(X2,Y2) Origin is UPPER left so Top Y < Bootom Y
=TMofsY2 TMofsX2+2
=TMofsChangeList TMofsY2+2      # Pointer to list of modifiers form base seed.
=TMofsSeed TMofsChangeList+2    # Random Seed used to create TM
=TMofsNorth TMofsSeed+2         # Tile in Direction
=TMofsSouth TMofsNorth+2
=TMofsEast TMofsSouth+2
=TMofsWest TMofsEast+2



# Map type maps
#
# A map cell is 'moveto' if higher byte has bit 1, or 0x1000 is set
=MoveToMask 0x1000
# Lower nibble of Byte determins object type upper nibble assigns a color
# 0 = Grass/dirt
# 1 = Tree
# 2 = Rock
# 3 = Flowing Water (river/stream)
# 4 = Deep Water (lake, sea)
# 5 = Rubble (destoryed city, village)
# 6 = Mountain (Hill or clifs)
# 7 = Small City    (Have 1-2 shops)
# 8 = Large City    (Have 2-4 shows)
# 9 = Village       (Have 0-1 shops)
# A = CaveEmpty     (% Mob or single battle)
# B = CaveFilled    (% Mob portal to Cave Sub-Mpa)
# C = Tower         (% Mob % enhansed tresure)
# D = Trap          (% Mob extra damage)
# E = Fairy         (+/-% Mob +/-% Health)
# F = Hole          Blocks path.
# Upper nibble is color. tied to Biom



=NoticeKilled 1                   # Visual notice enemy was killed.


###############################################
#Function GameLoop(days)
:GameLoop
@PUSHRETURN
@LocalVar InDays 1
@LocalVar Index1 2

@POPI InDays

@ForIA2V Index1 0 InDays
   @CALL DoBots
   @CALL DoPlayerAuto
   @CALL DisplayMap
   @CALL DoCommand
@Next Index1
@RestoreVar 2
@RestoreVar 1
@POPRETURN
@RET
###############################################
# Function DoBots
:DoBots
@PUSHRETURN
@LocalVar Index1 1


@ForIA2V Index1 0 ActiveArmy
   @PUSHI Index1
   @CALL BotBattle
   @IF_ZERO
      @POPNULL
      @PUSHI Index1
      @CALL BotMove
   @ELSE
      @POPNULL
   @ENDIF
@Next Index1
@ForIA2V Index1 0 ActiveCity
   @PUSHI Index1
   @CALL CityUpdate
@Next Index1
@ForIA2V Index1 0 Traders
   @PUSHI Index1
   @CALL DoTraders
@Next Index1

@RestoreVar 1
@POPRETURN
@RET
#################################################
# Function BotBattle(BotID)
:BotBattle
@PUSHRETURN
@LocalVar BotID 1
@LocalVar BotPtr 2
@LocalVar EnemyPtr 3

#
@POPI BotID
#
@PUSHI BotID @PUSH BotStructSize @CALL MULU
@POPI BotPtr
@PUSHI BotPtr
@ADD BofsHealth @PUSHS
@IF_ZERO
   @POPNULL
   #Dead Bot just skip for now.
@ELSE
   # Alive.
   @POPNULL
   @PUSHI BotPtr   @ADD BofsXloc @PUSHS
   @PUSHI BotPtr   @ADD BofsYloc @PUSHS  
   @PUSHI BotPtr   @ADD BofsTeam @PUSHS
   @CALL BotScan
   @IF_NOTZERO
      # Nearest Enemy
      @POPI EnemyPtr
      @PUSHI BotPtr   @ADD BofsXloc @PUSHS
      @PUSHI BotPtr   @ADD BofsYloc @PUSHS
      @PUSHI EnemyPtr   @ADD BofsXloc @PUSHS
      @PUSHI EnemyPtr   @ADD BofsYloc @PUSHS
      @CALL Distance
      @PUSHI BotPtr   @ADD BofsRange @PUSHS
      @IF_LT_S
         # In Range
         @POPNULL @POPNULL
         @PUSHI EnemyPtr   @ADD BofsAggres @PUSHS
         @PUSHI BotPtr     @ADD BofsAggres @PUSHS
         @IF_LT_S
            # Enemy is less agressive than Bot, Bot will attack.
            @POPNULL
            @POPNULL
            @PUSHI EnemyPtr @ADD BofsHealth @PUSHS
            @PUSHI BotPtr  @ADD BofsDamage @PUSHS
            @SUBS
            @IF_LE_A 0               
               @POPNULL
               @PUSH NoticeKilled
               @PUSHI EnemyPtr
               @CALL Noteification
               @PUSH 0
               @PUSHI EnemyPtr @ADD BofsHealth @POPS  # Makes Enemy Bot as dead.
            @ELSE
               # Enemy still alive, save its damage
               @PUSHI EnemyPtr @ADD BofsHealth @POPS  # Makes Enemy Bot health changed.
               @PUSH NoticeHurt
               @PUSHI EnemyPtr
               @CALL Notification
            @ENDIF
         @ELSE
            @POPNULL @POPNULL
         @ENDIF
     @ELSE
        @POPNULL @POPNULL
     @ENDIF
  @ENDIF
@ENDIF
@PUSH 0
@RestoreVar 3
@RestoreVar 2
@RestoreVar 1
@POPRETURN
@RET
#################################################
# Function BotMove(BotID)
:BotMove
@LocalVar BotID 1
@LocalVar BotPtr 2
@LocalVar DeltaX 3
@LocalVar DeltaY 4
@LocalVar MicroMapPtr
@POPI BotID
@PUSHI BotID @PUSH BotStructSize @CALL MULU
@POPI BotPtr
@ADD BofsHealth @PUSHS
@IF_ZERO
  @POPNULL
  # Dead Bots don't move.
@ELSE
  @POPNULL
  # Set Possible locations Based on Move Rule
  @PUSHI BotPtr @ADD BofsRule @PUSHS
  @SWITCH
  @CASE 0
     @MA2V 0 DeltaX @MA2V -1 DeltaY
     @CBREAK
  @CASE 1
     @MA2V 1 DeltaX @MA2V -1 DeltaY
     @CBREAK
  @CASE 2
     @MA2V 1 DeltaX @MA2V 0 DeltaY
     @CBREAK
  @CASE 3
     @MA2V 1 DeltaX @MA2V 1 DeltaY
     @CBREAK
  @CASE 4
     @MA2V 0 DeltaX @MA2V 1 DeltaY
     @CBREAK
  @CASE 5
     @MA2V -1 DeltaX @MA2V 1 DeltaY
     @CBREAK
  @CASE 6
     @MA2V -1 DeltaX @MA2V 0 DeltaY
     @CBREAK
  @CASE 7
     @MA2V -1 DeltaX @MA2V -1 DeltaY
     @CBREAK
  @CASE 8            # Knight Move 1
     @MA2V 2 DeltaX @MA2V 1 DeltaY
     @CBREAK
  @CASE 9            # Knight Move 2
     @MA2V 2 DeltaX @MA2V -1 DeltaY
     @CBREAK
  @CASE 10           # Knight Move 3
     @MA2V 1 DeltaX @MA2V 2 DeltaY
     @CBREAK
  @CASE 11           # Knight Move 4
     @MA2V 1 DeltaX @MA2V -2 DeltaY
     @CBREAK     
  @CASE 12           # Knight Move 5
     @MA2V -2 DeltaX @MA2V -1 DeltaY
     @CBREAK
  @CASE 12           # Knight Move 6
     @MA2V -2 DeltaX @MA2V 1 DeltaY
     @CBREAK
  @CDEFAULT
     # No Valid Move
     @CBREAK
  @ENDCASE

  # Use these deltas to fetch a micro map around this XY point
  @PUSHI BotPtr @ADD BofsXloc @PUSHS
  @ADDI DeltaX
  @PUSHI BotPtr @ADD BofsYloc @PUSHS
  @ADDI DeltaY
  @CALL FetchMicroMap
  @POPI MicroMapPtr
  # We want to make sure is a valid 'moveto' land type
  @PUSHI MicroMapPtr @ADD 8       # 3x3 mini map is 18 words long Center word is 8 bytes in.
  @PUSHS
  @AND MoveToMask
  @IF_ZERO
     # Center of Map does is not set MoveTo so can't make this move.
     # Instead don't update the location and pick a new Direction Rule
     # TOS should still have current rule
     @PUSH 1
     @WHILE_NOTZERO
        @POPNULL
        @PUSH 13
        @CALL rndint
        @IF_EQ_S
            # Hit same as current rule, retry.
            @PUSH 1
        @ELSE
            # Replace Bot rule with new one.
            @PUSHI BotPtr @ADD BofsRule @POPS
            @PUSH 0 # Break While
        @ENDIF
     @ENDWHILE
     @POPNULL
  @ELSE
     # Center of minimap was a valid moveto so just accept it and move Bot
     @PUSHI BotPtr @ADD BofsXloc @PUSHS @ADDI DeltaX
     @PUSHI BotPtr @ADD BofsXloc @POPS
     @PUSHI BotPtr @ADD BofsYloc @PUSHS @ADDI DeltaY
     @PUSHI BotPtr @ADD BofsYloc @POPS
     # Now consider how far Bot is willing to go before turning.
     @PUSHI BotPtr @ADD BofsDlimit @PUSHS
     @SUB 1
     @IF_LT_A 1
        # Gone far enough to consider turning.
        # Our Logic for turning is to go add/sub 0-2 from current Rule and then limit result to valid range of 0-12
        @PUSH 5
        @CALL rndint
        @SUB 2
        @PUSHI BotPtr @ADD BofsRule @PUSHS
        @ADDS
        @IF_LT_A 0
           @ADD 12
        @ELSE
           @IF_GT_A 12
              @SUB 12
           @ENDIF
        @ENDIF
        @PUSHI BotPtr @ADD BofsRule @POPS
        # Reset the Dlimit to 5 to 10 steps
        @PUSH 5
        @CALL rndint
        @ADD 5
        @PUSHI BotPtr @ADD BofsDlimit @POPS
     @ELSE
        # Dlimit wasn't 0 yet, so subract 1 and save it.
        SUB 1
        @PUSHI BotPtr @ADD BofsDlimit @POPS        
     @ENDIF
  @ENDIF

     
     
  
  
  
