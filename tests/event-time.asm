I common.mc
L softstack.ld
L heapmgr.ld
L screen.ld
L event.ld
L timetool.ld
#
#
# Verified conventions:
#   - Define heap from ENDOFCODE through 0xff00.
#   - Allocate 0x400 bytes for the software stack.
#   - Pass the value of HEAP_ID to EventTableNew.
#   - WinResize updates WinWidth and WinHeight globals.
#   - WinClear is called after WinResize.
#   - EventAdd arguments should normally be pushed explicitly.
#   - Value expressions use "@PUSHI Variable @ADD Constant",
#     not address expressions such as "Variable+Constant".
############################################################

I common.mc
L softstack.ld
L mul.ld
L heapmgr.ld
L screen.ld
L event.ld

############################################################
# Test-specific event IDs belong here.
############################################################

=EV_EXIT 100
=EV_TZ_DOWN 200
=EV_TZ_UP 300
=EV_CLOCKTICK 400

############################################################
# Data Strucutres
############################################################
# Clock Structure
=CLOCK_ZONE_off    0
=CLOCK_Index_off   2
=CLOCK_Flags_off   4
=CLOCK_Obj_Size CLOCK_Flags_off+2


############################################################
# Program locals
############################################################


   # Terminal dimensions
   :Columns      0
   :Rows         0

   # Event system
   :EventID      0
   :EventTable   0
   :Running      0

   # Heap and software stack
   :ObjectSize   0
   :HEAP_ID      0
   :SoftStackStart 0
   :SoftStackEnd 0

   # Clock Data
   :ClockTableSize 0
   =NUMBER_CLOCKS 5
   :ClockTable 0
   :ClockLowWord 0
   :ClockHighWord 0
   :Seconds 0
   :Minutes 0
   :Hour 0
   :Day 0
   :Month 0
   :Year 0
   

   # Common Indexs and Temps
   :Index01 0
   :Index02 0
   :Temp1   0
   :LocationY 0
   :LocationX 0

   # Exit Button Info
   :ExitX 30
   :ExitY 3
   
   =OneSec 1
   =RepeatTimer 1

   # Button,Clock locations
   =DownButtonX 5
   =FirstButtonY 4
   =UpButtonX DownButtonX+10   #  characters for the time info

   

############################################################
# Main
############################################################

:Main .Org Main

   @MA2V 1 Running

   #########################################################
   # Define heap memory.
   #########################################################

   @PUSH 0xff00
   @SUB ENDOFCODE
   @POPI ObjectSize

   @Call(AV) HeapDefineMemory ENDOFCODE ObjectSize
   @POPI HEAP_ID

   #########################################################
   # Allocate and initialize a 0x400-byte software stack.
   #########################################################

   @Call(VA) HeapNewObject HEAP_ID 0x400
   @POPI SoftStackStart

   @PUSHI SoftStackStart
   @ADD 0x400
   @POPI SoftStackEnd

   @Call(VV) SetSSStack SoftStackEnd SoftStackStart

   #########################################################
   # Create the active event table.
   #########################################################

   @Call(V) EventTableNew HEAP_ID
   @POPI EventTable

   #########################################################
   # Create the Clock Table
   #########################################################

   @PUSH CLOCK_Obj_Size
   @PUSH NUMBER_CLOCKS
   @CALL MULU
   @POPI ClockTableSize
   @Call(VV) HeapNewObject HEAP_ID ClockTableSize
   @POPI ClockTable

   @ForIA2B Index01 0 NUMBER_CLOCKS
     #
     # Set Clock ZONE
     @PUSHI Index01 @SUB 5      # UTM - 5 for Ruff EST
     @LISTV_FILL_AT_S ClockTable Index01 CLOCK_Obj_Size CLOCK_ZONE_off
     #
     # Set Clock Index
     @LISTV_FILL_AT_V ClockTable Index01 CLOCK_Obj_Size CLOCK_Index_off Index01
     # Set Flags
     @LISTV_FILL_AT_A ClockTable Index01 CLOCK_Obj_Size CLOCK_Flags_off  0
   @Next Index01

   #########################################################
   # Read terminal dimensions and clear the screen.
   #
   # WinResize updates WinWidth and WinHeight. It does not
   # return the dimensions on the data stack.
   #########################################################

   @CALL WinResize
   @MV2V WinWidth Columns
   @MV2V WinHeight Rows
   @CALL WinClear

   @Call(VV) WinCursor ExitX ExitY
   @PRT "Exit"

   #########################################################
   # EVENT REGISTRATION
   #
   # Push EventAdd arguments explicitly:
   #
   #   @PUSH  EventType
   #   @PUSHI X1
   #   @PUSHI Y1
   #   @PUSHI X2
   #   @PUSHI Y2
   #   @PUSH  EventID
   #   @CALL  EventAdd
   #
   # For a calculated coordinate:
   #
   #   @PUSHI X1
   #   @ADD 3
   #
   # Do not use X1+3 when the desired meaning is value(X1)+3.
   #########################################################

   # Setup Exit Button
   @PUSH MouseEventClick
   @PUSHI ExitX
   @PUSHI ExitY
   @PUSHI ExitX @ADD 3
   @PUSHI ExitY
   @PUSH EV_EXIT
   @CALL EventAdd

   # Setup Timer
   @PUSH TimerEvent
   @PUSH OneSec
   @PUSH RepeatTimer
   @PUSH 0
   @PUSH 0
   @PUSH EV_CLOCKTICK
   @CALL EventAdd

   # Setup Left <- Button
   @PUSH MouseEventClick
   @PUSH DownButtonX-1
   @PUSH FirstButtonY
   @PUSH DownButtonX+4
   @PUSH FirstButtonY @ADD NUMBER_CLOCKS
   @PUSH EV_TZ_DOWN
   @CALL EventAdd

   # Setup Right -> Button
   @PUSH MouseEventClick
   @PUSH UpButtonX
   @PUSH FirstButtonY
   @PUSH UpButtonX+2
   @PUSH FirstButtonY @ADD NUMBER_CLOCKS
   @PUSH EV_TZ_UP
   @CALL EventAdd
   


   #########################################################
   # Enable terminal mouse reporting.
   #########################################################

   @CALL TermMouseEnable

   #########################################################
   # Main event loop.
   #########################################################
   @TTYRAW
   @PUSHI Running
   @WHILE_NOTZERO
      @POPNULL

      @CALL EventPoll
      @POPI EventID
#      @Call(AA) WinCursor 60 15 @PRTI EventID @PRT "   "

      #######################################################
      # EVENT HANDLING
      #
      # Add event cases here. Every case should leave the
      # stack balanced.
      #######################################################

      @PUSHI EventID
      @SWITCH

      @CASE EV_EXIT
         @POPNULL
         @MA2V 0 Running
         @CBREAK
      @CASE EV_CLOCKTICK
         @POPNULL
         @GETTIME      
         @POPI2 ClockHighWord ClockLowWord
         @Call(A) Time2Units ClockLowWord
         @POPI3 Seconds Minutes Hour
         @POPNULL @POPNULL @POPNULL
         

         @ForIA2B Index01 0 NUMBER_CLOCKS
            @LISTV_GET_FROM ClockTable Index01 CLOCK_Obj_Size CLOCK_Index_off
            @ADD FirstButtonY
            @POPI LocationY
            @Call(AV) WinCursor DownButtonX LocationY
            @PRT "<="
            # Caclulate offset
            @LISTV_GET_FROM ClockTable Index01 CLOCK_Obj_Size CLOCK_ZONE_off
            @ADDI Hour
            @PRTTOP
            @POPNULL
            @PRT ":"
            @PRTI Minutes
            @PRT "."
            @PRTI Seconds
            @PRT "   "
            @Call(AV) WinCursor UpButtonX LocationY
            @PRT "=>"
         @Next Index01
         @CBREAK
     @CASE EV_TZ_DOWN
        @PUSHI LastMouseY
        @SUB FirstButtonY
        @POPI Index01
        @LISTV_GET_FROM ClockTable Index01 CLOCK_Obj_Size CLOCK_ZONE_off
        @SUB 1
        @IF_LT_A -23
           @POPNULL
           @PUSH 1
        @ENDIF
        @LISTV_FILL_AT_S ClockTable Index01 CLOCK_Obj_Size CLOCK_ZONE_off
        @CBREAK
     @CASE EV_TZ_UP
        @PUSHI LastMouseY
        @SUB FirstButtonY
        @POPI Index01
        @LISTV_GET_FROM ClockTable Index01 CLOCK_Obj_Size CLOCK_ZONE_off
        @ADD 1
        @IF_GT_A 23
           @POPNULL
           @PUSH 1
        @ENDIF
        @LISTV_FILL_AT_S ClockTable Index01 CLOCK_Obj_Size CLOCK_ZONE_off
        @CBREAK
      @CDEFAULT
         # EventID 0 or an event not handled by this test.
         @POPNULL
         @CBREAK

      @ENDCASE

      @PUSHI Running
   @ENDWHILE
   @POPNULL

   #########################################################
   # Restore terminal state and release resources.
   #########################################################

   @CALL TermMouseDisable
   @Call(V) EventTableFree EventTable

   # Leave the shell prompt on a clean line.
   @Call(VV) WinCursor 1 Rows
   @PRTNL

@END

:ENDOFCODE
