I common.mc
L screen.ld        # screen control functions
L timetool.ld      # for delay between frames
L string.ld        # for strlen()
L mul.ld           # for MULU
L random.ld        # for random direction changes

=FaceRight 0
=FaceLeft  1

# ----------------------------------------------------------------------
# DrawCow(UpX,UpY,Dir)
# Draws cow facing Dir (1=Right, -1=Left) starting at X,Y
# ----------------------------------------------------------------------
:DrawCow
@PUSHRETURN
@LocalVar UpX 01
@LocalVar UpY 02
@LocalVar Dir 03
@LocalVar Index1 04
@LocalVar CowStr 05
@LocalVar CowWidth 06
@POPI Dir

@POPI UpY
@POPI UpX
   @PUSH RightCow @CALL strlen @ADD 1 @POPI CowWidth
   @ForIA2B Index1 0 8
      # Set cursor at left side of cow
      @PUSHI UpX
      @PUSHI UpY @ADDI Index1
      @CALL WinCursor
      @IF_EQ_AV 1 Dir
          @PUSH RightCow
      @ELSE
          @PUSH LeftCow
      @ENDIF
      @PUSHI CowWidth @PUSHI Index1 @CALL MULU
      @ADDS
      @POPI CowStr
      @PRTSI CowStr
   @Next Index1
@RestoreVar 06 @RestoreVar 05 @RestoreVar 04 @RestoreVar 03
@RestoreVar 02 @RestoreVar 01
@POPRETURN
@RET

:LeftCow

"                   \0"
"  (__)             \0"
"  (oo)\_______     \0"
"  (__)       )\/\  \0"
"      ||----w |    \0"
"      ||     ||    \0"
"                   \0"
"                   \0"
:RightCow
"                   \0"
"             (__)  \0"
"     _______/(oo)  \0"
"  /\/(       (__)  \0"
"    | w----||      \0"
"    ||     ||      \0"
"                   \0"
"                   \0"

# ----------------------------------------------------------------------
# DemoCow
# Clears screen, sets limits, animates cow bouncing inside
# ----------------------------------------------------------------------
:DemoCow
  @PUSHRETURN
  @LocalVar CowX 01
  @LocalVar CowY 02
  @LocalVar CowDX 03
  @LocalVar CowDY 04
  @LocalVar Distance 05
  @LocalVar Index01 06
  @LocalVar CowDir 07
  @LocalVar WinRightLimit 08
  @LocalVar WinLeftLimit 09
  @LocalVar WinTopLimit 10
  @LocalVar WinBotLimit 11
 


  @MA2V 1 CowDX
  @MA2V 0 CowDY

  @PUSHI WinWidth @SUB 24 @POPI WinRightLimit
  @MA2V 20 WinLeftLimit
  @PUSHI WinHeight @SUB 10 @POPI WinBotLimit
  @MA2V 3 WinTopLimit

  @MA2V FaceRight CowDir
  @PUSHI WinWidth @SHR @SUB 11 @POPI CowX
  @PUSHI WinHeight @SHR @SUB 3 @POPI CowY
  @MA2V 10 Distance

  @ForIA2B Index01 0 100
     # Reverse direction if we near an edge
     @PUSHI CowX
     @ADDI CowDX
     @POPI CowX     
     @PUSHI CowX
     @IF_ULE_V WinLeftLimit
        @PUSH 1 @PUSH 2 @CALL WinCursor @PRT "Cow Left Edge: " @PRTI CowX @PRT "        "
        @MV2V WinLeftLimit CowX
        @MA2V FaceRight CowDir
        @MA2V -1 CowDX
     @ENDIF
     @IF_UGE_V WinRightLimit
        @PUSH 1 @PUSH 2 @CALL WinCursor @PRT "Cow Right Edge: " @PRTI CowX @PRT "        "     
        @MV2V WinRightLimit CowX
        @MA2V FaceLeft CowDir
        @MA2V 1 CowDX
     @ENDIF
     @POPNULL

     @PUSH CowY
     @ADDI CowDY
     @POPI CowY
     @PUSHI CowY
     @IF_ULE_V WinTopLimit
        @PUSH 1 @PUSH 2 @CALL WinCursor @PRT "Cow Top Edge: " @PRTI CowY @PRT "        "          
        @MV2V WinTopLimit CowY
        @MA2V 1 CowDY
     @ENDIF
     @IF_UGE_V WinBotLimit
        @PUSH 1 @PUSH 2 @CALL WinCursor @PRT "Cow Bot Edge: " @PRTI CowY @PRT "        "               
        @MV2V WinBotLimit CowY     
        @MA2V -1 CowDY
     @ENDIF
     @POPNULL


     @DECI Distance
     @IF_EQ_AV 0 Distance
        # Walk a number of steps, then pick a new random direction
        @PUSH 8 @CALL frndint
        @ADD 2
        @POPI Distance
        @PUSH 2 @CALL frndint
        @PUSH 1 @PUSH 3 @CALL WinCursor @PRT "Rnd: " @PRTTOP
        @IF_EQ_A 1
           @MA2V -1 CowDX
        @ELSE
           @MA2V 1 CowDX
        @ENDIF
        @POPNULL
        @PUSH 2 @CALL frndint
        @IF_EQ_A 1
           @MA2V -1 CowDY
        @ELSE
           @MA2V 1 CowDY
        @ENDIF
        @POPNULL                  
     @ENDIF
     @PUSH 1 @CALL Sleep
     
     @PUSHI CowX @PUSHI CowY @PUSHI CowDX @CALL DrawCow
  @Next Index01

 @RestoreVar 11 @RestoreVar 10 @RestoreVar 09 @RestoreVar 08
 @RestoreVar 07 @RestoreVar 06 @RestoreVar 05 @RestoreVar 04
 @RestoreVar 03 @RestoreVar 02 @RestoreVar 01
@POPRETURN
@RET

:Main . Main
@CALL TimeCalabrate
@CALL WinClear
@GETTIME @POPNULL 
@POPNULL @PUSH 101
@CALL rndsetseed
@CALL DemoCow
@END
