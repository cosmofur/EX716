############################################################
# Text FS
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

=EV_EXIT 1

############################################################
# Program locals
############################################################

# Globals
   # Terminal dimensions
   :Columns         0
   :Rows            0

   # Event system
   :EventID         0
   :EventTable      0
   :Running         0

   # Heap and software stack
   :ObjectSize      0
   :HEAP_ID         0
   :SoftStackStart  0
   :SoftStackEnd    0

   #########################################################
   # Add test-specific locals below.
   #########################################################


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
   # Read terminal dimensions and clear the screen.
   #
   # WinResize updates WinWidth and WinHeight. It does not
   # return the dimensions on the data stack.
   #########################################################

   @CALL WinResize
   @MV2V WinWidth Columns
   @MV2V WinHeight Rows
   @CALL WinClear

   #########################################################
   # TEST SETUP
   #
   # Calculate screen positions and draw the initial display.
   #########################################################


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


   #########################################################
   # Enable terminal mouse reporting.
   #########################################################

   @CALL TermMouseEnable

   #########################################################
   # Main event loop.
   #########################################################

   @PUSHI Running
   @WHILE_NOTZERO
      @POPNULL

      @CALL EventPoll
      @POPI EventID

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
