#
I common.mc
#M DEBUGSCREEN 1
L screen.ld
L event.ld
L timetool.ld
L mul.ld
L div.ld
L random.ld
M DefArray16 %REPEAT %1 0 0 %ENDR
##################
# Constants
##################
=MAX_BOMBS 8
=MAX_MISSILES 4
=MAX_CITIES 3
=R_MAX 6
=MISSLE_SPEED 2
=MouseField 101
=KeyTyped 201
##################
# Global State
##################
:GroundY 0
:BaseX 0
:BombX @DefArray16 MAX_BOMBS
:BombY @DefArray16 MAX_BOMBS
:BombAlive @DefArray16 MAX_BOMBS
:BombTX @DefArray16 MAX_BOMBS
:BombDX8 @DefArray16 MAX_BOMBS
:BombXF @DefArray16 MAX_BOMBS
:ActiveBombs 0
:CityX @DefArray16 MAX_CITIES

:MissX @DefArray16 MAX_MISSILES
:MissY @DefArray16 MAX_MISSILES
:MissDX @DefArray16 MAX_MISSILES
:MissDY @DefArray16 MAX_MISSILES
:MissState @DefArray16 MAX_MISSILES
:MissR @DefArray16 MAX_MISSILES
:MissXF @DefArray16 MAX_MISSILES
:ActiveMissiles 0
:MainHeapID 0
:MainEventTable 0
:KeyTable "Q" $$12 $$3 $$0



##################
# INIT Function
##################
:Start
@PUSHRETURN
   @PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
   @CALL HeapDefineMemory
   @POPI MainHeapID

   @CALL WinResize
   @CALL WinClear
   @CALL WinHideCursor

   @CALL TermMouseEnable
   @CALL SetUpScreen
   @CALL InitBombs
   @CALL InitMissiles
   @CALL SetupEvents
   @CALL MainLoop
   @CALL TermMouseDisable

@POPRETURN
@RET
##################
# SetupScreen
##################
:SetUpScreen
@PUSHRETURN
  @PUSHI WinHeight
  @SUB 3
  @POPI GroundY
  @PUSHI WinWidth
  @SHR
  @POPI BaseX
  #
  # Draw Initial cities
  @CALL DrawCities
@POPRETURN
@RET
##################
# DrawCities
##################
:DrawCities
@PUSHRETURN
   @PUSHI WinWidth @SHR @SHR  # /4
   @DUP
   @POPI CityX                # City 0
   @CALL DrawCity
   @PUSHI WinWidth @SHR       # /2
   @DUP
   @POPI CityX+2              # City 1
   @CALL DrawCity
   @PUSHI WinWidth @SHL @ADDI WinWidth   # *3
   @SHR @SHR  # / 4
   @DUP
   @POPI CityX+4              # City 2
   @CALL DrawCity
@POPRETURN
@RET
###################
# DrawCity
###################
:DrawCity
@PUSHRETURN
   @LocalVar XLoc 01
   @POPI XLoc

   @Call(vv) WinCursor XLoc GroundY
   @PRT "###"
   @PUSHI XLoc
   @PUSHI GroundY @SUB 1
   @CALL WinCursor
   @PRT "###"
   @PUSHI XLoc
   @PUSHI GroundY @SUB 2
   @CALL WinCursor
   @PRT "###"
   @RestoreVar 01
@POPRETURN
@RET
#####################
# InitBombs
####################
:InitBombs
@PUSHRETURN
    @LocalVar _i 01
    @LocalVar BombAlive_Idx 02
    @LocalVar BombX_Idx 03
    @LocalVar BombY_Idx 04

    @MA2V BombAlive BombAlive_Idx
    @MA2V BombX BombX_Idx
    @MA2V BombY BombY_Idx

    @ForIA2B _i 0 MAX_BOMBS
       @PUSH 0 @POPII BombAlive_Idx
    @Next _i

    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#####################
# InitMissiles
#####################
:InitMissiles
@PUSHRETURN
   @LocalVar _i 01
   @LocalVar MissState_Idx 02
   @LocalVar MissR_Idx 03

   @MA2V MissState MissState_Idx
   @MA2V MissR MissR_Idx

   @ForIA2B _i 0 MAX_MISSILES
      @PUSH 0 @POPII MissState_Idx
      @PUSH 0 @POPII MissR_Idx
      @INC2I MissState_Idx
      @INC2I MissR_Idx
   @Next _i

   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#####################
# Setup Events
#####################
:SetupEvents
@PUSHRETURN
   @Call(v) EventTableNew MainHeapID
   @POPI MainEventTable
   @PUSH MouseEvent @PUSH 0 @PUSH 1 @PUSHI WinWidth @PUSHI GroundY @PUSH MouseField
   @CALL EventAdd
   @PUSH KeyEvent @PUSH KeyTable @PUSH 0 @PUSH 0 @PUSH 0 @PUSH KeyTyped
   @CALL EventAdd
@POPRETURN
@RET
##################
# Main Loop
##################
:MainLoop
@PUSHRETURN
   @PUSH 0
   @WHILE_ZERO
      @CALL EventPoll
      @IF_NOTZERO      
         @CALL HandleEvent
         @POPNULL         
      @ELSE
         @POPNULL
         @CALL UpdateBombs
         @CALL UpdateMissiles
         @CALL DetectHits
      @ENDIF
      @CALL RenderFrame
      #
      # Sleep some time here possible 33 ms
    @ENDWHILE
    @POPNULL
@POPRETURN
@RET
##########################
# HandleEvent
##########################
:HandleEvent
@PUSHRETURN
    @IF_EQ_A MouseField
       @Call(vv) LaunchMissile [ LastMouseX, LastMouseY ]
    @ENDIF
    @IF_EQ_A KeyTyped
       @CALL TermMouseDisable
       @StackDump
       @CALL ColorReset
       @CALL WinShowCursor
       @END
    @ENDIF
    @POPNULL
@POPRETURN
@RET
###########################
# Launch Missile
###########################
:LaunchMissile
@PUSHRETURN
    @LocalVar TX 01
    @LocalVar TY 02
    @LocalVar _i 03
    @LocalVar DX 04
    @LocalVar DY 05
    @LocalVar Steps 06
    @LocalVar XF 07       # fixed X (8.3)
    @LocalVar DX8 08      # ΔX << 3 / steps

    @POPI TY
    @POPI TX

    # DY = TY - (GroundY-1)
    @PUSHI TY
    @PUSHI GroundY @SUB 1 @SUBS
    @POPI DY

    # Steps = |DY|   # missile climbs 1 per frame
    @ABSI DY
    @POPI Steps

    # Find free missile
    @ForIA2B _i 0 MAX_MISSILES
        @PUSHI _i @SHL @ADD MissState @PUSHS
        @IF_EQ_A 0
            @POPNULL

            # MissState[_i] = 1
            @PUSH 1
            @PUSHI _i @SHL @ADD MissState
            @POPS

            # Initial X = BaseX
            @PUSHI BaseX
            @PUSHI _i @SHL @ADD MissX
            @POPS

            # Initial Y = GroundY-1
            @PUSHI GroundY @SUB 1
            @PUSHI _i @SHL @ADD MissY
            @POPS

            # DeltaX = TX - BaseX
            @PUSHI TX
            @SUBI BaseX
            @POPI DX

            # XF = BaseX << 3
            @PUSHI BaseX
            @SHLN 3
            @POPI XF

            # DX8 = (DeltaX << 3) / Steps
            @PUSHI DX
            @SHLN 3
            @PUSHI Steps
            @CALL DIV          # signed division correct
            @POPI DX8

            # Save XF into MissXF[_i]
            @PUSHI XF
            @PUSHI _i @SHL @ADD MissXF
            @POPS

            # Save DX8 into MissDX[_i]
            @PUSHI DX8
            @PUSHI _i @SHL @ADD MissDX
            @POPS

            # MissDY = -1 (moves upward)
            @PUSH -1
            @PUSHI _i @SHL @ADD MissDY
            @POPS

            @FORBREAK
        @ENDIF
        @POPNULL
    @Next _i

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


 #############################
 # SpawnBomb
 #############################
 :SpawnBomb
 @PUSHRETURN
    @LocalVar _i 01  @LocalVar ixAlive 02  @LocalVar ixX 03
    @LocalVar ixY 04  @LocalVar ixTX 05  @LocalVar ixDX 06
    @LocalVar ixXF 07  @LocalVar StartX 08  @LocalVar TargetX 09
    @LocalVar DiffX 10  @LocalVar Height 11 @LocalVar EntryMask 12
    @LocalVar EntryOffset 13


    # Our Minimal width is 16 units and should never really be that small
    # We want to use a MASK to keep the bombs entry to be centered by and easy to caclulate
    # range, without haveing to use an expensive 'MOD'function.
    # So we calcualate a MASK and OFFSET to 'center' a 16,32 or 64 character wide window

    @MA2V 0xf EntryMask
    @PUSHI WinWidth @SUB 15 @SHR # (Width-15)/2
    @POPI EntryOffset

    @PUSHI WinWidth
    @IF_GT_A 31              # If wide enough make the entry window 32 characters centered
        @MA2V 0x1f EntryMask
        @PUSHI WinWidth @SUB 31 @SHR # (Width-31)/2
        @POPI EntryOffset
    @ELSE  @IF_GT_A 63
        @MA2V 0x3f EntryMask # If wide enough make entry window 64 character centered
        @PUSHI WinWidth @SUB 63 @SHR # (Width-31)/2
        @POPI EntryOffset
        @ENDIF
    @ENDIF

    @MA2V BombAlive ixAlive
    @MA2V BombX ixX
    @MA2V BombY ixY
    @MA2V BombTX ixTX
    @MA2V BombDX8 ixDX
    @MA2V BombXF ixXF

    @MV2V GroundY Height

    @ForIA2B _i 0 MAX_BOMBS
       @PUSHII ixAlive
       @IF_EQ_A 0
          @POPNULL
          @CALL rnd16
          @ANDI EntryMask     # use mask rather than MOD to contrain rnd to range.
          @ADDI EntryOffset
          @POPI StartX

          # 3 Cities so compute target
          @CALL rnd16 @AND 3
          @WHILE_EQ_A 3
            @POPNULL
            @CALL rnd16 @AND 3
          @ENDWHILE
          # TOS is City Number
          @SHR @ADD CityX @PUSHS  # Get the X index of CityX[TOS*2]
          @POPI TargetX
          @PUSHI TargetX @POPI ixTX
          #
          # DiffX = TargetX - StartX
          @PUSHI TargetX
          @SUBI StartX
          @POPI DiffX
          #
          # DX_Fixed = (DiffX << 3) / Height
          @PUSHI DiffX
          @SHLN 3
          @PUSHI Height
          @CALL DIVU
          @IF_ZERO
             @POPNULL
             @PUSHI DiffX
             @IF_LT_A 0
                @POPNULL
                @PUSH -1
             @ELSE
                @POPNULL
                @PUSH 1
             @ENDIF
          @ENDIF
          @POPII ixDX           # BombDX8
          #
          # X_Fiex=StartX << 3
          @PUSHI StartX
          @SHLN 3
          @POPII ixXF
          #
          # Alive=1
          @PUSH 1
          @INCI ActiveBombs
          @POPII ixAlive
          @FORBREAK
      @ENDIF
      @POPNULL
      @INC2I ixAlive @INC2I ixX @INC2I ixY
      @INC2I ixTX @INC2I ixDX @INC2I ixXF
   @Next _i

   @RestoreVar 08   @RestoreVar 07
   @RestoreVar 06   @RestoreVar 05
   @RestoreVar 04   @RestoreVar 03
   @RestoreVar 02   @RestoreVar 01

@POPRETURN
@RET




#############################
# UpdateBombs
#############################
:UpdateBombs
@PUSHRETURN
   @LocalVar _i      01   @LocalVar ixAlive 02   @LocalVar ixX     03
   @LocalVar ixY     04   @LocalVar ixTX    05   @LocalVar ixDX    06
   @LocalVar ixXF    07

   @MA2V BombAlive ixAlive
   @MA2V BombX     ixX
   @MA2V BombY     ixY
   @MA2V BombTX    ixTX
   @MA2V BombDX8   ixDX
   @MA2V BombXF    ixXF

   @ForIA2B _i 0 MAX_BOMBS
      @PUSHII ixAlive
      @IF_NEQ_A 0
         @POPNULL
         # Y += 1 ( Bomb falls 1 unit)
         @PUSHII ixY
         @ADD 1
         @POPII ixY
         # Xf += DX8 (fixed point update)
         @PUSHII ixXF
         @ADDII ixDX    # XF += DX8
         @POPII ixXF
         # Integer X = XF >> 3
         @PUSHII ixXF
         @SHRN 3          # SHRN is macro for multiple shifts constant
         @POPII ixX
         #
         # Check for Ground hit (add city destroyed later)
         @PUSHII ixY
         @IF_GE_A GroundY
            @POPNULL
            @PUSH 0
            @POPII ixAlive
            # Should check if ixX is near a city and if its not been destoryed yet, then end game when all three are destoryed.
         @ENDIF
         @POPNULL
      @ELSE
         @POPNULL
      @ENDIF

      @INC2I ixAlive @INC2I ixX @INC2I ixY
      @INC2I ixTX @INC2I ixDX @INC2I ixXF
   @Next _i

   @RestoreVar 07    @RestoreVar 06   @RestoreVar 05 
   @RestoreVar 04    @RestoreVar 03   @RestoreVar 02 
   @RestoreVar 01 

@POPRETURN
@RET

#############################
# UpdateMissiles  (fixed-point version)
#############################
:UpdateMissiles
@PUSHRETURN
    @LocalVar _i 01
    @LocalVar ixX      02
    @LocalVar ixY      03
    @LocalVar ixDX     04
    @LocalVar ixDY     05
    @LocalVar ixState  06
    @LocalVar ixR      07
    @LocalVar ixXF     08

    @ForIA2B _i 0 MAX_MISSILES

       @PUSHI _i @SHL
       @DUP @ADD MissState @POPI ixState
       @DUP @ADD MissX     @POPI ixX
       @DUP @ADD MissY     @POPI ixY
       @DUP @ADD MissDX    @POPI ixDX
       @DUP @ADD MissDY    @POPI ixDY
       @DUP @ADD MissR     @POPI ixR
       @ADD MissXF         @POPI ixXF

       @PUSHII ixState
       @SWITCH

       ########################################################
       # CASE 1 — Missile in flight
       ########################################################
       @CASE 1
           @POPNULL

           # XF += DX8
           @PUSHII ixXF
           @ADDII ixDX
           @POPII ixXF

           # Y += DY  (DY is negative: missile moves upward)
           @PUSHII ixY
           @ADDII ixDY
           @POPII ixY

           # X = XF >> 3
           @PUSHII ixXF
           @SHRN 3
           @POPII ixX

           # Did missile reach the top or go past?
           @PUSHII ixY
           @IF_LE_A 10
               @POPNULL
               @PUSH 2
               @POPII ixState     # enter explosion expand state
               @PUSH 1
               @POPII ixR         # radius begins at 1
           @ENDIF
           @POPNULL

           @CBREAK

       ########################################################
       # CASE 2 — Explosion expanding
       ########################################################
       @CASE 2
           @POPNULL

           @PUSHII ixR @ADD 1 @POPII ixR     # R++

           @PUSHII ixR
           @IF_GE_A R_MAX
               @POPNULL
               @PUSH 3
               @POPII ixState        # switch to shrinking
           @ENDIF
           @POPNULL

           @CBREAK

       ########################################################
       # CASE 3 — Explosion shrinking
       ########################################################
       @CASE 3
           @POPNULL

           @PUSHII ixR @SUB 1 @POPII ixR    # R--

           @PUSHII ixR
           @IF_LE_A 0
               @POPNULL
               @PUSH 0
               @POPII ixState         # missile now free
               @DECI ActiveMissiles   # optional counter
           @ENDIF
           @POPNULL

           @CBREAK

       ########################################################
       # Default: invalid state
       ########################################################
       @CDEFAULT
           @POPNULL
           @CBREAK

       @ENDCASE

       # Increment all array pointers for next loop iteration
       @INC2I ixState
       @INC2I ixX
       @INC2I ixY
       @INC2I ixDX
       @INC2I ixDY
       @INC2I ixR
       @INC2I ixXF

    @Next _i

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


 #########################
 # DetectHits
 #########################
 :DetectHits
 @PUSHRETURN
    @LocalVar _b 01
    @LocalVar bx 02
    @LocalVar by 03
    @LocalVar _m 04
    @LocalVar dx 05
    @LocalVar dy 06

    @ForIA2B _b 0 MAX_BOMBS
       @PUSHI _b @SHL @ADD BombAlive @PUSHS # BombAlive[_b]
       @IF_NEQ_A 0
          @POPNULL
          # bx=BombX[_b]  by=BombY[_b]
          @PUSHI _b @SHL
          @DUP               # Word Index value of _b
          @ADD BombX @PUSHS
          @POPI bx
          @ADD BombY @PUSHS
          @POPI by
          @ForIA2B _m 0 MAX_MISSILES
             @PUSHI _m @SHL @ADD MissState @PUSHS # MissState[_m]
             @IF_NEQ_A 0
                @POPNULL
                # dx=bx-MissX[-M]  dy=by-MissY[_m]
                @PUSHI _m @SHL
                @ADD MissX @PUSHS     # MissX[_m]
                @PUSHI bx
                @SWP @SUBS @POPI dx   # bx-MissX[_m]
                @PUSHI _m @SHL
                @ADD MissY @PUSHS     # MissY[_m]
                @PUSHI by
                @SWP @SUBS @POPI dy   # by-MissY[_m]
                #
                # Here we are using the mul.ld MUL function, but would a look up table be better?
                # r2=(dx^2+dy^2)
                @Call(vv) MUL dx dx
                @Call(vv) MUL dy dy
                @ADDS               # r2 on stack
                @PUSHI _m @SHL @ADD MissR @PUSHS  # MissR[_m]
                @DUP
                @CALL MUL          # MissR[_m]^2
                @IF_LE_S            # r2<MissR^2
                   # Missle Hit Bomb
                   # Add explosion graph here?
                   @PUSH 0
                   @PUSHI _b @SHL @ADD BombAlive
                   @POPS         # BombAlive[_b] = 0
                @ENDIF
                @POPNULL
                @POPNULL
             @ELSE
                @POPNULL
             @ENDIF
          @Next _m
       @ELSE
          @POPNULL
       @ENDIF
    @Next _b

    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
########################
# RenderFrame
########################
:RenderFrame
@PUSHRETURN
    @LocalVar _i 01

    # Draw Bombs
    @ForIA2B _i 0 MAX_BOMBS
       @PUSHI _i @SHL @ADD BombAlive @PUSHS # BombAlive[_i]
       @IF_EQ_A 1
           # PUSH BombX[_i],BombY[_i]
           @PUSHI _i @SHL  @ADD BombX @PUSHS
           @PUSHI _i @SHL  @ADD BombY @PUSHS
           @CALL WinCursor
           @PRT "."
       @ENDIF
       @POPNULL
    @Next _i
    # Draw missles + explosions
    @ForIA2B _i 0 MAX_MISSILES
       @PUSHI _i @SHL @ADD MissState @PUSHS # MissState[_i]
       @IF_EQ_A 1
          # PUSH MissX[_i] Missy[_i]
          @PUSHI _i @SHL  @ADD MissX @PUSHS
          @PUSHI _i @SHL  @ADD MissY @PUSHS
          @CALL WinCursor
          @PRT "^"
       @ENDIF
       @IF_EQ_A 2            # MissState[_i] == 2
          # Explosion
          @PUSHI _i @SHL @ADD MissX @PUSHS
          @PUSHI _i @SHL @ADD MissY @PUSHS          
          @PUSHI _i @SHL @ADD MissR @PUSHS
          @CALL DrawExplosion
       @ENDIF
       @POPNULL
    @Next _i

    # Redraw Cities and Base
    @CALL DrawCities
    @Call(vv) WinCursor BaseX GroundY
    @PRT "^"

    @RestoreVar 01
@POPRETURN
@RET

############################################
# DrawExplosion(Xpos, Ypos, R)
# Centered, solid fill, 2 cursor moves per row
############################################
:DrawExplosion
@PUSHRETURN
    @LocalVar R         01
    @LocalVar Xpos      02
    @LocalVar Ypos      03
    @LocalVar Ptr       04
    @LocalVar Height    05
    @LocalVar Width     06
    @LocalVar RowPtr    07
    @LocalVar RowBits   08
    @LocalVar TmpX      09
    @LocalVar TmpY      10
    @LocalVar LeftCol   11
    @LocalVar RightCol  12
    @LocalVar Mask      13
    @LocalVar row       14
    @LocalVar bitcount  15
    @LocalVar idx       16

    @POPI R
    @POPI Ypos
    @POPI Xpos

    ###########################################
    # Lookup Explosion[R] table pointer
    ###########################################
    @PUSHI R
    @SHL                     # R * 2
    @ADD ExPtrTable @PUSHS
    @POPI Ptr

    ###########################################
    # Load Height and Width
    ###########################################
    @PUSHII Ptr   @POPI Height
    @INCI Ptr
    @PUSHII Ptr   @POPI Width
    @INCI Ptr

    @MV2V Ptr RowPtr

    ###########################################
    # Compute TmpX = Xpos - (Width >> 1)
    # Compute TmpY = Ypos - (Height >> 1)
    ###########################################
    @PUSHI Width @SHR @POPI LeftCol    # reuse LeftCol as temp
    @PUSHI Xpos @SUBI LeftCol @POPI TmpX

    @PUSHI Height @SHR @POPI RightCol  # temporary
    @PUSHI Ypos @SUBI RightCol @POPI TmpY

    ###########################################
    # Row loop
    ###########################################
    @ForIA2B row 0 Height
        @PUSHII RowPtr @POPI RowBits

        #######################################
        # Find LeftCol = first '1' bit
        #######################################
        @MA2V 0x8000 Mask      # MSB
        @MA2V 0 LeftCol

        @PUSHII RowPtr @POPI RowBits
        @INCI RowPtr                    # Prepare PTR for next loop
        @PUSH 1
        @WHILE_NOTZERO
            @POPNULL
            @DUP @ANDI Mask
            @IF_NOTZERO
                @POPNULL
                @PUSH 0     # Break While
            @ELSE
                @POPNULL
                @INCI LeftCol
                @PUSHI Mask @SHR @POPI Mask
                @PUSH 1     # Continue
            @ENDIF
        @ENDWHILE
        @POPNULL

        # Move the Cursor to the left most place where explosion begins on line.
        @PUSHI LeftCol @ADDI TmpX
        @PUSHI TmpY @ADDI row
        @CALL WinCursor
        #######################################
        # Print '*' until RightCol (scan forward)
        #######################################
        @PUSH 1
        @WHILE_NOTZERO
            @POPNULL
            @DUP @ANDI Mask
            @IF_NOTZERO
                @POPNULL
                @PRT "*"
                @PUSH 1   # Continue loop
            @ELSE
                @POPNULL
                @PUSHI Mask @SHR @POPI Mask
                @PUSH 0   # Break While
            @ENDIF
        @ENDWHILE
        @POPNULL
    @Next row

    ###########################################
    # Cleanup
    ###########################################
    @RestoreVar 16 @RestoreVar 15 @RestoreVar 14 @RestoreVar 13
    @RestoreVar 12 @RestoreVar 11 @RestoreVar 10 @RestoreVar 09
    @RestoreVar 08 @RestoreVar 07 @RestoreVar 06 @RestoreVar 05
    @RestoreVar 04 @RestoreVar 03 @RestoreVar 02 @RestoreVar 01

@POPRETURN
@RET


:ExPtrTable
$$ExplosionR1
$$ExplosionR2
$$ExplosionR3
$$ExplosionR4
$$ExplosionR5
$$ExplosionR6
#############################
# Small 1 R explosion spark
:ExplosionR1
:ExplosionR1_Width 3
:ExplosionR1_Height 3
0b0100000000000000
0b1110000000000000
0b0100000000000000
# 2 R explosion
:ExplosionR2
:ExplosionR2_Width 5
:ExplosionR2_Height 5
0b0010000000000000
0b0111000000000000
0b1111100000000000
0b0111000000000000
0b0010000000000000
# 3 R explosion
:ExplosionR3
:ExplosionR3_Width 6
:ExplosionR3_Height 5
0b0011000000000000
0b0111100000000000
0b1111110000000000
0b0111100000000000
0b0011000000000000

# 4 R explosion
:ExplosionR4
:ExplosionR4_Width 7
:ExplosionR4_Height 7
0b0001000000000000
0b0011100000000000
0b0111110000000000
0b1111111000000000
0b0111110000000000
0b0011100000000000
0b0001000000000000
# 5 R explosion
:ExplosionR5
:ExplosionR5_Width 8
:ExplosionR5_Height 7
0b0001100000000000
0b0011110000000000
0b0111111000000000
0b1111111100000000
0b0111111000000000
0b0011110000000000
0b0001100000000000
# 6 R explosion
:ExplosionR6
:ExplosionR6_Width 9
:ExplosionR6_Height 9
0b0000100000000000
0b0001110000000000
0b0011111000000000
0b0111111100000000
0b1111111110000000
0b0111111100000000
0b0011111000000000
0b0001110000000000
0b0000100000000000
:Main . Main
@CALL Start
@END

:ENDOFCODE
