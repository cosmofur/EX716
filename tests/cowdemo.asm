I common.mc
L screen.ld        # bring in all the screen functions
L timetool.ld      # for delay between frames
L string.ld
L mul.ld
L random.ld

@LocalVar YCenter 01
@LocalVar XCenter 02
@LocalVar Index 03

=FaceRight 0
=FaceLeft 1

# ----------------------------------------------------------------------
# DrawCow(UpX,UpY,Dir)
# Draw cow facing Dir (0=Right, 1=Left) starting at X,Y
# ----------------------------------------------------------------------

:DrawCow
@PUSHRETURN
@LocalVar UpX 01
@LocalVar UpY 02
@LocalVar Dir 03
@LocalVar Index1 04
@LocalVar Index2 05
@LocalVar CowStr 06
@LocalVar CowWidth 07
@POPI Dir
@POPI UpY
@POPI UpX
   @PUSH RightCow @CALL strlen @ADD 1 @POPI CowWidth
   @ForIA2B Index1 0 8
      # Set Cursor at begining left side of cow
      @PUSHI UpX
      @PUSHI UpY @ADDI Index1
      @CALL WinCursor
      @IF_EQ_AV FaceLeft Dir
          @PUSH RightCow
      @ELSE
          @PUSH LeftCow
      @ENDIF
      @PUSHI CowWidth @PUSHI Index1 @CALL MULU
      @ADDS
      @POPI CowStr      
      @PRTSI CowStr
    @Next Index1
@RestoreVar 07 @RestoreVar 06 @RestoreVar 05
@RestoreVar 04 @RestoreVar 03 @RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


:LeftCow
#123456789ABCDEF01234
"                   \0"
"  (__)             \0"
"  (oo)\_______     \0"
"  (__)       )\/\  \0"
"      ||----w |    \0"
"      ||     ||    \0"
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
# Clears screen, sets limits, then animates a cow
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


  @MA2V 1 CowDir
  @PUSHI WinWidth @SHR @SUB 11 @POPI CowX
  @PUSHI WinHeight @SHR @SUB 3 @POPI CowY
  @MA2V 10 Distance


  @ForIA2B Index01 0 100
     # Reverse Direction is we near any edge
     @PUSHI CowX
     @IF_ULT_V WinLeftLimit
        @MA2V FaceRight CowDir
        @MA2V -1 CowDX
     @ENDIF
     @IF_UGT_V WinRightLimit
        @MA2V FaceLeft CowDir
        @MA2V 1 CowDir
     @ENDIF
     @ADDI CowDX
     @POPI CowX

     @PUSHI CowY
     @IF_ULT_V WinTopLimit
        @MA2V 1 CowDY
     @ENDIF
     @IF_UGT_V WinBotLimit
        @MA2V -1 CowDY
     @ENDIF
     @ADDI CowDY
     @POPI CowY

     @DECI Distance
     @IF_EQ_AV 0 Distance
        # Walk a 'disance' steps, then pick a new random direction and distance to go
        @PUSH 8 @CALL frndint
        @ADD 2
        @POPI Distance
        # Min Distance is 2
        @PUSH 2
        @CALL frndint
        @IF_EQ_A 1
           @MA2V -1 CowDX
        @ELSE
           @MA2V 1 CowDX
        @ENDIF
        @POPNULL
        @PUSH 2
        @CALL frndint
        @IF_EQ_A 1
           @MA2V -1 CowDY
        @ELSE
           @MA2V 1 CowDY
        @ENDIF
        @PUSH 1 @CALL Sleep
        @POPNULL
     @ENDIF
     @PUSH 1 @PUSH 1 @CALL WinCursor @PRT "Cow: " @PRTSGNI CowDir @PRT " X:" @PRTSGNI CowX @PRT " Y:" @PRTSGNI CowY
     @PRT " DX:" @PRTSGNI CowDX @PRT " DY: " @PRTSGNI CowDY @PRT " Dir: " @PRTSGNI CowDir @PRT "   "
     @PUSHI CowX @PUSHI CowY @PUSHI CowDir @CALL DrawCow
  @Next Index01
  
 @RestoreVar 11   @RestoreVar 10   @RestoreVar 09   @RestoreVar 08
 @RestoreVar 07   @RestoreVar 06   @RestoreVar 05   @RestoreVar 04
 @RestoreVar 03   @RestoreVar 02   @RestoreVar 01
@POPRETURN
@RET

:Main . Main
@PRT "..."
@CALL TimeCalabrate
@CALL WinClear
@GETTIME @POPNULL
@CALL rndsetseed
@CALL DemoCow
@END


