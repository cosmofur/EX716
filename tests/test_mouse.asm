I common.mc
L screen.ld
# @ENABLETRACE
#@ENABLERETTRACE
L mouse.ld
:MainHeapID 0
:RunFlag 0

###############
# Layout constants (1-based screen coords)
###############
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

:CountBuffer 0 0 0 0 0 0 0 0
##################
# Text Lables
#################
:CountLabel "Count:\0"
:QuitLabel "QUIT\0"
:UpperLabel "UPCase\0"
:LowerLabel "LOWCase\0"





##################################################
# Function: PrintAt(SX,SY,StrPtr)
:PrintAt
@PUSHRETURN
@LocalVar StrPtr 01
@LocalVar SX 02
@LocalVar SY 03
@POPI StrPtr
@POPI SY
@POPI SX
   @PUSHII StrPtr
   @IF_NOTZERO
      @PUSHI SX @PUSHI SY
      @CALL WinCursor
      @PRTSI StrPtr
   @ENDIF
   @POPNULL
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
############################################################
# Optimized straight-line box drawing with IBM line chars
# Depends on: WinCursor, PRTS
# Uses CP437 codes:
#   H (─)=0xC4, V (│)=0xB3, TL(┌)=0xDA, TR(┐)=0xBF, BL(└)=0xC0, BR(┘)=0xD9
############################################################

=CH_H   0xC4
=CH_V   0xB3
=CH_TL  0xDA
=CH_TR  0xBF
=CH_BL  0xC0
=CH_BR  0xD9

# Scratch buffers used by helpers
:CharBuf 0 0              # single 8-bit char + NUL
:CharBufPtr CharBuf
:RunBuf  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0          # ~80 bytes; grow if needed

############################################################
# New DrawBox(x1,y1,x2,y2)
# Draws a single-line rectangle using IBM line glyphs.
############################################################
:DrawBox
@PUSHRETURN

@LocalVar X1 01 @LocalVar Y1 02 @LocalVar X2 03 @LocalVar Y2 04
@LocalVar Index1 05

@POPI Y2 @POPI X2 @POPI Y1 @POPI X1

@PUSHI X1 @PUSHI Y1 @CALL WinCursor @PRT "+"
@INCI X1
@ForIV2V Index1 X1 X2
   @PRT "-"
@Next Index1
@PRT "+"
@DECI X1
@DECI X2
@PUSHI X1 @PUSHI Y2 @CALL WinCursor @PRT "+"
@ForIV2V Index1 X1 X2
   @PRT "-"
@Next Index1
@PRT "+"
@INCI X2
@INCI Y1
@ForIV2V Index1 Y1 Y2
   @PUSHI X1 @PUSHI Index1 @CALL WinCursor
   @PRT "|"
   @PUSHI X2 @PUSHI Index1 @CALL WinCursor
   @PRT "|"
@Next Index1
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

####################################################
# Function RenderUI
# Print the full screen.
:RenderUI
   @PUSHRETURN
   @CALL WinClear
   #
   @PUSH UI_LEFT @PUSH UI_TOP @PUSH UI_RIGHT @PUSH UI_BOTTOM @CALL DrawBox
   @PUSH TF_X1-1 @PUSH TF_Y1-1 @PUSH TF_X2+1 @PUSH TF_Y2+1  @CALL DrawBox
   @PUSH BTN_UP_X1-1 @PUSH BTN_UP_Y1-1 @PUSH BTN_UP_X2+1 @PUSH BTN_UP_Y2+1 @CALL DrawBox
   @PUSH BTN_LO_X1-1 @PUSH BTN_LO_Y1-1 @PUSH BTN_LO_X2+1 @PUSH BTN_LO_Y2+1 @CALL DrawBox
   @PUSH BTN_QUIT_X1-1 @PUSH BTN_QUIT_Y1-1 @PUSH BTN_QUIT_X2+1 @PUSH BTN_QUIT_Y2+1 @CALL DrawBox

   #
   # Label Click Buttons,   
   @PUSH COUNT_LABEL_X @PUSH COUNT_LABEL_Y @PUSH CountLabel @CALL PrintAt
   @PUSH QUIT_LABEL_X @PUSH QUIT_LABEL_Y @PUSH QuitLabel @CALL PrintAt
   @PUSH BTN_UP_LABEL_X @PUSH BTN_UP_LABEL_Y @PUSH UpperLabel @CALL PrintAt
   @PUSH BTN_LO_LABEL_X @PUSH BTN_LO_LABEL_Y @PUSH LowerLabel @CALL PrintAt
   #
#@PUSH BTN_UP_X1 @PUSH BTN_UP_Y1 @PUSH BTN_UP_X2 @PUSH BTN_UP_Y1 @PUSH LineChar @CALL WinPlot
#   @PUSH BTN_LO_X1 @PUSH BTN_LO_Y1 @PUSH BTN_LO_X2 @PUSH BTN_LO_Y1 @PUSH LineChar @CALL WinPlot
   #
   @PUSH CountVal @CALL RenderCount
   @POPRETURN
@RET
################################################
# Function RenderCount(CV)
# Print Count to right of <Count>
:RenderCount
@PUSHRETURN
@LocalVar CV 01
@LocalVar Tmp 02
@POPI CV
#
   @PUSH CountBuffer @PUSHI CV @PUSH 10 @CALL itos
   @PUSH COUNT_LABEL_X+8 @PUSHI COUNT_LABEL_Y @PUSH CountBuffer @CALL PrintAt
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
###############################################
# Function RenderTextField
:RenderTextField
@PUSHRETURN
@LocalVar Index 01
   @PUSH TF_X1 @PUSH TF_Y1 @CALL WinCursor
   @PUSH TF_X1 @PUSH TF_Y1 @PUSH TextBuf @CALL PrintAt
@RestoreVar 01
@POPRETURN
@RET
###############################################
# Function TextPushChar(CH)
:TextPushChar
@PUSHRETURN
@LocalVar CH 01
@AND 0xff       # Make sure CH is single byte
@POPI CH
   @PUSHI TextLen
   @IF_GE_A TF_W
      # Field full, exit
   @ELSE
      @PUSH TextBuf @ADDI TextLen
      @DUP
      @PUSHS @AND 0xff00   # Get Upper Byte
      @ORI CH
      @SWP
      @POPS
      @INCI TextLen
   @ENDIF
   @POPNULL
@RestoreVar 01
@POPRETURN
@RET
######################################
# Function TextBackSpace
:TextBackSpace
@PUSHRETURN
   @PUSHI TextLen
   @IF_NOTZERO
      @DECI TextLen
      @PUSH 0 @PUSH TextBuf @ADDI TextLen @POPS
      @CALL RenderTextField @PRT " "
   @ENDIF
   @POPNULL
@POPRETURN
@RET

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

:KeyBoardKeys "abcdefghijklnopqrstuvwxuzABCDEFGHIJKLMNOPRSTUVWXYZ+-()1234567890!@#$%^&*()_[]{}:;\0"
:DelKeys "\b" $$8 $$127 0
:CtrlQKeys "QQ" $$0x11 $$26 0

:Main . Main

   @PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
   @CALL HeapDefineMemory
   @POPI MainHeapID


   @CALL WinResize
   @PUSHI MainHeapID
   @CALL MouseInit
   @CALL WinHideCursor

   @MA2V COUNTER_START  CountVal
   @MA2V 0 TextLen
   @PUSH 0 @PUSH TextBuf @POPS
   @TTYNOECHO
   @CALL RegisterMouseZones
   @CALL RenderUI

   @MA2V 1 RunFlag
   @PUSH -1
   @MA2V 0 TCounter
   @WHILE_NEQ_AV 0 RunFlag
      @CALL MouseEventLoop
      @IF_NOTZERO
#         @PUSH 50 @PUSH 5 @ADDI TCounter @CALL WinCursor @PRTHEXTOP
         @PUSHI TCounter @ADD 1 @AND 0x3 @POPI TCounter
         @SWITCH
         @CASE EID_UPPER
             @PUSHI TextBuf
             @CALL strUpCase
             @CALL RenderTextField
             @POPNULL
             @CBREAK
         @CASE EID_LOWER
             @PUSHI TextBuf
             @CALL strLowCase
             @CALL RenderTextField
             @POPNULL
             @CBREAK
         @CASE EID_QUIT
             @POPNULL
             @MA2V 0 RunFlag
             @CBREAK
         @CASE EID_QUITKEY
             @POPNULL
             @MA2V 0 RunFlag
             @CBREAK             
         @CASE EID_TYPEKEY
             @WHILE_EQ_A EID_TYPEKEY
                @PUSHI LastKeyChar
                 @CALL TextPushChar
                @CALL RenderTextField
                @POPNULL
             @ENDWHILE
             @CBREAK
         @CASE EID_DELKEY
             @WHILE_EQ_A EID_DELKEY         
                @CALL TextBackSpace
                @CALL RenderTextField
                @POPNULL
             @ENDWHILE
             @CBREAK
         @CASE EID_TIMER
             @INCI CountVal
             @PUSHI CountVal @CALL RenderCount
             @POPNULL
             @CBREAK
         @CDEFAULT
             @POPNULL
             @CBREAK
         @ENDCASE
      @ELSE
         @POPNULL
      @ENDIF
   @ENDWHILE
   @POPNULL
   @TTYECHO   
   @CALL MouseDisable
   @CALL WinShowCursor
   @END
   
:TCounter 0   



:ENDOFCODE
