############################################################
# event-mouse-test.asm
#
# Validates:
#   EventTableNew
#   EventAdd mouse regions
#   EventPoll mouse dispatch
#   LastMouseX / LastMouseY
#   TermMouseEnable / TermMouseDisable
############################################################

I common.mc
L softstack.ld
L mul.ld
L heapmgr.ld
L screen.ld
L event.ld

# By default larger Call(VVVVV) is 5 variables, adding custom for this file
M Call(VVVVVV) @PUSHI %2     @PUSHI %3     @PUSHI %4     @PUSHI %5  @PUSHI %6   @CALL %1

=EV_TEST 1
=EV_EXIT 2

@Locals
   @Local Columns
   @Local Rows
   @Local CenterX
   @Local CenterY
   @Local TestX
   @Local TestY
   @Local ExitX
   @Local ExitY
   @Local CountX
   @Local CountY
   @Local ClickCount
   @Local EventID
   @Local EventTable
   @Local ObjectSize
   @Local HEAP_ID
   @Local SoftStackStart
   @Local SoftStackEnd

:Main .Org Main

   @MA2V 0 ClickCount

   @PUSH 0xff00 @SUB ENDOFCODE
   @POPI ObjectSize 
   @Call(AV) HeapDefineMemory ENDOFCODE ObjectSize
   @POPI HEAP_ID

   # Set asside 0x400 bytes for the soft stack.
   @Call(VA) HeapNewObject HEAP_ID 0x400 
   @POPI SoftStackStart
   @PUSHI SoftStackStart
   @ADD 0x400
   @POPI SoftStackEnd

   # Set Softstack to between these two addresses
   @Call(VV) SetSSStack SoftStackEnd SoftStackStart

   @Call(V) EventTableNew HEAP_ID
   @POPI EventTable

   @CALL WinResize
   @MV2V WinWidth Columns
   @MV2V WinHeight Rows
   @CALL WinClear

   # Center of terminal.
   @PUSHI Columns @SHR @POPI CenterX
   @PUSHI Rows @SHR @POPI CenterY

   # "Test" centered approximately.
   @PUSHI CenterX @SUB 2 @POPI TestX
   @MV2V CenterY TestY

   # "Exit" centered two rows above bottom.
   @PUSHI CenterX @SUB 2 @POPI ExitX
   @PUSHI Rows @SUB 2 @POPI ExitY

   # Counter display beneath Test.
   @PUSHI TestX @SUB 4 @POPI CountX
   @PUSHI TestY @ADD 2 @POPI CountY

   @Call(VV) WinCursor TestX TestY
   @PRT "Test"

   @Call(VV) WinCursor ExitX ExitY
   @PRT "Exit"

   @Call(VV) WinCursor CountX CountY
   @PRT "Click count: 0"

   # Register the exact four-character label areas.
   @PUSH MouseEventClick
   @PUSHI TestX
   @PUSHI TestY
   @PUSHI TestX @ADD 3
   @PUSHI TestY
   @PUSH EV_TEST
   @CALL EventAdd 

   @PUSH MouseEventClick
   @PUSHI ExitX
   @PUSHI ExitY
   @PUSHI ExitX @ADD 3
   @PUSHI ExitY
   @PUSH EV_EXIT
   @CALL EventAdd
      

   @CALL TermMouseEnable

   @PUSH 0
   @WHILE_ZERO
      @POPNULL

      @CALL EventPoll
      @POPI EventID

      @PUSHI EventID
      @SWITCH

      @CASE EV_TEST
         @POPNULL
         @INCI ClickCount

         @Call(VV) WinCursor CountX CountY
         @PRT "Click count: "
         @PRTI ClickCount
         @PRT "      "

         @PUSH 0
         @CBREAK

      @CASE EV_EXIT
         @POPNULL
         @PUSH 1
         @CBREAK

      @CDEFAULT
         @POPNULL
         @PUSH 0
         @CBREAK

      @ENDCASE
   @ENDWHILE
   @POPNULL

   @CALL TermMouseDisable
   @Call(V) EventTableFree EventTable

   @Call(VV) WinCursor 1 Rows
   @PRTNL

@EndLocals
@END
:ENDOFCODE
