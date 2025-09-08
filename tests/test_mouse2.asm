I common.mc
L screen.ld
# @ENABLETRACE
#@ENABLERETTRACE
L mouse.ld
:MainHeapID 0
:RunFlag 0

=UI_TOP          1
=UI_LEFT         1
=UI_RIGHT        60        # outer border width; adjust as needed
=UI_BOTTOM       20

# Text field box (single line, no wrap)
=TF_X1           7         # left of text field interior
=TF_Y1           3         # row of the text field interior
=TF_W            20        # interior width; fits comfortably in box
=TF_X2           TF_X1+TF_W-1
=TF_Y2           TF_Y1

# Labels at right side
=COUNT_LABEL_X   30
=COUNT_LABEL_Y    10
=QUIT_LABEL_X    30
=QUIT_LABEL_Y     12

# Buttons (mouse zones)
=BTN_UP_LABEL_X   10
=BTN_UP_LABEL_Y   10
=BTN_LO_LABEL_X   10
=BTN_LO_LABEL_Y   12

# Make clickable boxes around labels:
=BTN_UP_X1       BTN_UP_LABEL_X
=BTN_UP_Y1       BTN_UP_LABEL_Y
=BTN_UP_X2       BTN_UP_LABEL_X+4
=BTN_UP_Y2       BTN_UP_LABEL_Y+1

=BTN_LO_X1       BTN_LO_LABEL_X
=BTN_LO_Y1       BTN_LO_LABEL_Y
=BTN_LO_X2       BTN_LO_LABEL_X+4
=BTN_LO_Y2       BTN_LO_LABEL_Y+1

=BTN_QUIT_X1     QUIT_LABEL_X
=BTN_QUIT_Y1     QUIT_LABEL_Y
=BTN_QUIT_X2     QUIT_LABEL_X+5
=BTN_QUIT_Y2     QUIT_LABEL_Y+1

###############
# Event IDs
###############
=EID_UPPER       101
=EID_LOWER       102
=EID_QUIT        199
=EID_TIMER       500
=EID_TYPEKEY     600
=EID_DELKEY      700
=EID_QUITKEY     198

###############
# Timer policy
###############
=TICKS_10_SEC    10       
=COUNTER_START    0

#################
# Storage
#################
:TextBuf 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
:TextLen 0
:CountVal
:DelKeys "\b" $$8 $$127 0
:CtrlQKeys "QQ" $$0x11 $$26 0
:KeyBoardKeys "abcdefghijklnopqrstuvwxuzABCDEFGHIJKLMNOPRSTUVWXYZ+-()1234567890!@#$%^&*()_[]{}:;\0"




#####################################
# Function RegisterMouseZones
# Setup the Events
:RegisterMouseZones
@PUSHRETURN
   @PUSH MouseEvent @PUSH BTN_UP_X1 @PUSH BTN_UP_Y1 @PUSH BTN_UP_X2 @PUSH BTN_UP_Y2 @PUSH EID_UPPER @CALL MouseAddEvent
   @PUSH MouseEvent @PUSH BTN_LO_X1 @PUSH BTN_LO_Y1 @PUSH BTN_LO_X2 @PUSH BTN_LO_Y2 @PUSH EID_LOWER @CALL MouseAddEvent
   @PUSH MouseEvent @PUSH BTN_QUIT_X1 @PUSH BTN_QUIT_Y1 @PUSH BTN_QUIT_X2 @PUSH BTN_QUIT_Y2 @PUSH EID_QUIT @CALL MouseAddEvent
   @PUSH TimerEvent @PUSH 10 @PUSH 1 @PUSH 0 @PUSH 0 @PUSH EID_TIMER @CALL MouseAddEvent
   @PUSH KeyEvent @PUSH KeyBoardKeys @PUSH 0 @PUSH 0 @PUSH 0 @PUSH EID_TYPEKEY @CALL MouseAddEvent
   @PUSH KeyEvent @PUSH DelKeys      @PUSH 0 @PUSH 0 @PUSH 0 @PUSH EID_DELKEY  @CALL MouseAddEvent
   @PUSH KeyEvent @PUSH CtrlQKeys    @PUSH 0 @PUSH 0 @PUSH 0 @PUSH EID_QUITKEY    @CALL MouseAddEvent   
@POPRETURN
@RET


:Main . Main
   @CALL WinClear
   @CALL WinHideCursor
   @PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
   @CALL HeapDefineMemory
   @POPI MainHeapID
   @PUSHI MainHeapID @CALL MouseInit
   @CALL RegisterMouseZones

   @MA2V 1 RunFlag
   @WHILE_NEQ_AV 0 RunFlag
      @CALL MouseEventLoop
      @IF_NOTZERO
         @PUSH 2 @PUSH 2 @CALL WinCursor
         @PRT "Event: " @PRTHEXTOP
      @ENDIF
      @POPNULL
   @ENDWHILE
   @CALL MouseDisable
   @CALL WinShowCursor
   @END
   
:ENDOFCODE
