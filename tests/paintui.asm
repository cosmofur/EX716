#######################
# UI Editor
I common.mc
L softstack.ld
L heapmgr.ld
L screen.ld
L lmath.ld
L string.ld
L event.ld
L mul.ld
L div.ld
L display.ld

=StackSizeDefault 0x400

:MainHeap 0
:SoftStackStart 0
:ObjectSize
:SoftStackEnd 0

:CtrlMenuEventTable 0
:CanvasEventTable 0
:MenuEnabled 0

:CanvasData 0         # String Object of Screen Data
:CanvasSize 0
:CanvasCursor -1
:CanvasBoxMode 0
:CanvasBoxX1 -1
:CanvasBoxY1 -1
:CanvasBoxX2 -1
:CanvasBoxY2 -1

######################################
# Constants
######################################
=EV_MenuClick 100
=EV_MenuESC 110
=EV_CanvasClick 200
=EV_CanvasKey 210
=EV_CanvasESC 220
=EV_CanvasCR 230

=MODE_BoxMode1 100
=MODE_BoxMode2 200
=MODE_BoxMode3 300
=MODE_Default 0
######################################
# Stack Setup
######################################
:SetupStack
# Can't use stack while setting it up. So no locals or PUSHRETURN
   @PUSH 0xff00
   @SUB END__
   @POPI ObjectSize
   @Call(AV) HeapDefineMemory END__ ObjectSize
   @POPI MainHeap
   @Call(VA) HeapNewObject MainHeap StackSizeDefault
   @IF_LT_A 100
      @PRTLN "Error out of memory"
      @END
   @ENDIF
   
   @POPI SoftStackStart  

   @PUSHI SoftStackStart
   @ADD StackSizeDefault
   @POPI SoftStackEnd

   @Call(VV) SetSSStack SoftStackEnd SoftStackStart
@RET

#######################################
# SetupGlobals
#######################################
:SetupGlobals
@PUSHRETURN
@Locals
    @Local Index1
    @Local Index2

    @CALL WinResize   # Setup WinWidth and WinHeight
    @IF_NEQ_AV 0 CanvasData
       @Call(VV) HeapDeleteObject MainHeap CanvasData
    @ENDIF
    @Call(VV) MULU WinWidth WinHeight
    @POPI CanvasSize
    @Call(VV) HeapNewObject MainHeap CanvasSize
    @POPI CanvasData
    @MV2V CanvasData Index2
    @ForIA2V Index1 1 CanvasSize
       @PUSH " \0"
       @POPII Index2
       @INCI Index2
    @Next Index1
    
@EndLocals
@POPRETURN
@RET

   
########################################
# SetupEvents
# Initilizes Event Tables
########################################
:SetupEvents
@PUSHRETURN
@Locals
   @Local Zero

# Most common Event Add is AVVVVA so create custom macro for most common form.
M AddCommonEvent \
   @PUSH %1 \     # EventType Mouse  Key     KeyRange  Timer
   @PUSHI %2 \    #           X1     StrPtr  ASCII     Secs
   @PUSHI %3 \    #           Y1     0       ASCII     Repeat
   @PUSHI %4 \    #           X2     0       0         0
   @PUSHI %5 \    #           Y2     0       0         0
   @PUSH %6 \     # EventID
   @CALL EventAdd
# Second most common is AAAAAA 
M AddConstantEvent \
   @PUSH %1 \     # EventType Mouse  Key     KeyRange  Timer
   @PUSH %2 \     #           X1     StrPtr  ASCII     Secs
   @PUSH %3 \     #           Y1     0       ASCII     Repeat
   @PUSH %4 \     #           X2     0       0         0
   @PUSH %5 \     #           Y2     0       0         0
   @PUSH %6 \     # EventID
   @CALL EventAdd

   @MA2V 0 Zero

   @Call(V) EventTableNew MainHeap
   @POPI CtrlMenuEventTable
   @Call(V) EventTableNew MainHeap
   @POPI CanvasEventTable

   @Call(V) EventSetActive CtrlMenuEventTable

   @AddCommonEvent MouseEvent Zero Zero WinWidth WinHeight EV_MenuClick
   @AddConstantEvent KeyRangeEvent 27 27 0 0 EV_MenuESC
   

   @Call(V) EventSetActive CanvasEventTable

   @AddCommonEvent MouseEvent Zero Zero WinWidth WinHeight EV_CanvasClick
   @AddConstantEvent KeyRangeEvent "a\0" "z\0" 0 0 EV_CanvasKey
   @AddConstantEvent KeyRangeEvent 27 27 0 0 EV_CanvasESC
   @AddConstantEvent KeyRangeEvent 10 13 0 0 EV_CanvasCR
@EndLocals
@POPRETURN
@RET
#############################################
# DisplayMenu
#############################################
:DisplayMenu
@PUSHRETURN
@Locals
   @Local MenuWidth
   @Local MenuHeight

   @MA2V 20 MenuWidth
   @MA2V 8 MenuHeight

   @Call(AAVV) WinClearRect 0 0 MenuWidth MenuHeight
   @MA2V 0 BOXMODE
   @Call(AAVV) WinBox 0 0 MenuWidth MenuHeight

   @Call(AA) WinCursor 2 2
   @PRT "BOX"
   @Call(AA) WinCursor 2 3
   @PRT "Menu 2"
   @Call(AA) WinCursor 2 4
   @PRT "Menu 3"   
   @Call(AA) WinCursor 2 5
   @PRT "Menu 4"
   @Call(AA) WinCursor 2 6
   @PRT "Menu 5"
   @Call(AA) WinCursor 2 7
   @PRT "Exit"
@EndLocals
@POPRETURN
@RET
###########################################
# DisplayCanvas
###########################################
:DisplayCanvas
@PUSHRETURN
@Locals
   
   @CALL WinClear
   @Call(AA) WinCursor 1 1
   @PRTSI CanvasData
@EndLocals
@POPRETURN
@RET

##########################################
# FillBetween(X1,Y1,X2,Y2)
##########################################
:FillBetween
@PUSHRETURN
@Locals
    @Local I1
    @Local J1
    @Local KeepIt
    @Local X1
    @Local X2
    @Local Y1
    @Local Y2
    @Local StrPtr
    @Local FillWidth

    @POPI4 Y2 X2 Y1 X1
    @INCI X1
    @INCI Y1
    @DECI X2
    @DECI Y2
    @QuickMinI X1 X2
    @QuickMinI Y1 Y2
    

    @Call(VV) MULU Y1 WinWidth
    @ADDI X1
    @ADDI CanvasData
    @POPI StrPtr
    @PUSHI X2
    @SUBI X1
    @POPI FillWidth
    
    @ForIV2V I1 Y1 Y2
        @Call(VV) WinCursor X1 I1
        @PUSHI StrPtr
        @ADDI FillWidth
        @PUSHS
        @POPI KeepIt
        @PUSH 0
        @PUSHI StrPtr
        @ADDI FillWidth
        @POPS
        @PRTSI StrPtr
        @PUSHI KeepIt
        @PUSHI StrPtr
        @ADDI FillWidth
        @POPS
        @PUSHI StrPtr
        @ADDI WinWidth
        @POPI StrPtr
    @Next I1
@EndLocals
@POPRETURN
@RET
        
        
############################################
# CanvasClickEvent
############################################
:CanvasClickEvent
@PUSHRETURN
@Locals
    @IF_NEQ_AV MODE_Default CanvasBoxMode
        @IF_EQ_AV -1 CanvasBoxX1
           # BoxMode, first click
           @MV2V LastMouseX CanvasBoxX1
           @MV2V LastMouseY CanvasBoxY1
           @MV2V CanvasBoxX1 CanvasBoxX2
           @MV2V CanvasBoxY1 CanvasBoxY2           
        @ELSE
           # Second or later clicks, first erase any box drawn before
           @MA2V 2 BOXMODE
           @Call(VVVV) WinBox CanvasBoxX1 CanvasBoxY1 CanvasBoxX2 CanvasBoxY2
           @Call(VVVV) FillBetween CanvasBoxX1 CanvasBoxY1 CanvasBoxX2 CanvasBoxY2
           @MV2V LastMouseX CanvasBoxX2
           @MV2V LastMouseY CanvasBoxY2
           @MA2V 1 BOXMODE           
           @Call(VVVV) WinBox CanvasBoxX1 CanvasBoxY1 CanvasBoxX2 CanvasBoxY2
        @ENDIF
    @ELSE
        # Normal Click just moves the cursor insert point
        @Call(VV) MULU LastMouseY WinWidth
        @ADDI LastMouseX
        @POPI CanvasCursor
        @Call(VV) WinCursor LastMouseX LastMouseY
    @ENDIF
@EndLocals
@POPRETURN
@RET
##########################################
# CanvasKeyEvent
##########################################
:CanvasKeyEvent
@PUSHRETURN
@Locals
   @Local CharPtr
   
   @PUSHI CanvasData
   @ADDI CanvasCursor
   @POPI CharPtr

   @PUSHI CanvasSize
   @IF_LT_V CanvasCursor
      @POPNULL
      @PRTCHI LastKeyChar      
      @PUSHI LastKeyChar
      @STOREBI CharPtr
      @INCI CanvasCursor
   @ELSE
      @POPNULL
   @ENDIF
@EndLocals
@POPRETURN
@RET
##########################################
# CanvasCREvent
##########################################
:CanvasCREvent
@PUSHRETURN
@Locals
   @Local BoxXI
   @Local BoxYI
   @Local DataPtr1
   @Local DataPtr2

   # On CR if in BOX mode, draw final box.
   @IF_NEQ_AV MODE_Default CanvasBoxMode
       @IF_NEQ_AV -1 CanvasBoxX1     # -1 if just entered Box mode but didn't select a box
       # In Box Mode draw final box
           @Call(VV) MULU CanvasBoxY1 WinWidth
           @ADDI CanvasBoxX1
           @POPI DataPtr1
           @Call(VV) MULU CanvasBoxY2 WinWidth
           @ADDI CanvasBoxX1
           @POPI DataPtr2
           @ForIV2V BoxXI CanvasBoxX1 CanvasBoxX2
               @PUSH "-\0"
               @STOREBI DataPtr1
               @PUSH "-\0"
               @STOREBI DataPtr2
               @INCI DataPtr1
               @INCI DataPtr2
           @Next BoxXI
           @Call(VV) MULU CanvasBoxY1 WinWidth
           @ADDI CanvasBoxX1
           @POPI DataPtr1
           @PUSHI DataPtr1
           @ADDI CanvasBoxX2
           @SUBI CanvasBoxX1
           @POPI DataPtr2
           @ForIV2V BoxYI CanvasBoxX1 CanvasBoxX2
               @PUSH "|\0"
               @STOREBI DataPtr1
               @PUSH "|\0"
               @STOREBI DataPtr2
               @PUSHI DataPtr1
               @ADDI WinWidth
               @POPI DataPtr1
               @PUSHI DataPtr2
               @ADDI WinWidth
               @POPI DataPtr2
           @Next BoxYI
           @Call(VV) MULU CanvasBoxY1 WinWidth
           @ADDI CanvasBoxX1
           @POPI DataPtr1
           @PUSH "+\0"
           @STOREBI DataPtr1           
           @Call(VV) MULU CanvasBoxY2 WinWidth
           @ADDI CanvasBoxX1
           @POPI DataPtr2
           @PUSH "+\0"
           @STOREBI DataPtr2
           @PUSHI DataPtr1 @ADDI CanvasBoxX2 @SUBI CanvasBoxX1
           @POPI DataPtr1
           @PUSH "+\0"
           @STOREBI DataPtr2
           @PUSHI DataPtr1 @ADDI CanvasBoxX2 @SUBI CanvasBoxX1
           @POPI DataPtr2
           @PUSH "+\0"
           @STOREBI DataPtr2
           # Now get out of Box mode
           @MA2V -1 CanvasBoxX1
           @MA2V -1 CanvasBoxY1
           @MA2V MODE_Default CanvasBoxMode
       @ENDIF           
   @ELSE
       # If not in box mode, then move cursor to begining of next line
       @Call(VV) DIVU CanvasCursor WinWidth
       @ADD 1
       @IF_LE_V WinHeight
          @POPI BoxYI
          @POPNULL   # Get rid of unneedeed MOD
          @Call(VV) MULU BoxYI WinWidth
          @POPI CanvasCursor
       @ELSE
          @POPNULL
          @POPNULL
       @ENDIF
   @ENDIF
@EndLocals
@POPRETURN
@RET

############################################
# DoMenuAction
############################################
:DoMenuAction
@PUSHRETURN
@Locals
   @Local YValue
   @Local LoopExit
   @POPI2 YValue LoopExit


   @PUSHI YValue
   @SWITCH
   @CASE 1    # Box Mode
      @MA2V MODE_BoxMode1 MODE_Default
      @CBREAK
   @CASE 2
      @PRT "Menu 2"
      @CBREAK
   @CASE 3
      @PRT "Menu 3"
      @CBREAK
   @CASE 4
      @PRT "Menu 4"
      @CBREAK
   @CASE 5
      @PRT "Menu 5"
      @CBREAK      
   @CASE 6
      @MA2V 1 LoopExit
      @CBREAK
   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL
   @PUSHI LoopExit
@EndLocals
@POPRETURN
@RET

   
               

   
############################################
# MainEventLoop
############################################
:MainEventLoop
@POPRETURN
@Locals
    @Local EventID

    @PUSH 0
    @WHILE_ZERO
       @CALL EventPoll
       @POPI EventID

       @PUSHI EventID
       @SWITCH
       @CASE EV_MenuClick
          # Menu Select
          @POPNULL
          @PUSHI LastMouseY
          @SUB 2
          @CALL DoMenuAction
          @CBREAK
       @CASE EV_MenuESC
          @POPNULL
          @Call(V) EventSetActive CanvasEventTable
          @CALL DisplayCanvas
          @CBREAK
       @CASE EV_CanvasClick
          @POPNULL
          @CALL CanvasClickEvent
          @CBREAK
       @CASE EV_CanvasKey
          @POPNULL
          @CALL CanvasKeyEvent
          @CBREAK
       @CASE EV_CanvasESC
          @POPNULL
          @Call(V) EventSetActive CtrlMenuEventTable
          @CALL DisplayCanvas
          @CBREAK
       @CDEFAULT
          @POPNULL
          @CBREAK          
       @ENDCASE
   @ENDWHILE
   @CALL WinClear
@EndLocals
@POPRETURN
@RET

:Main .Org Main
   @CALL SetupStack
   @CALL SetupGlobals
   @CALL SetupEvents
   @CALL DisplayCanvas
   @CALL TermMouseEnable
   @CALL MainEventLoop
   @CALL TermMouseDisable
   @END


   
       
