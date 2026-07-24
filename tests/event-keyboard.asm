############################################################
# event-test-template.asm
#
# Common framework for event.ld regression and demonstration
# programs.
#
# Test-specific work is marked with:
#     TEST SETUP
#     EVENT REGISTRATION
#     EVENT HANDLING
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
L string.ld

############################################################
# Test-specific event IDs belong here.
############################################################

:EV_NONE         0
:EV_TEXT_CHAR    1
:EV_BOX1_CLICK   2
:EV_BOX2_CLICK   3
:EV_EXIT_CLICK   4
:EV_CLEAR_CLICK  5

############################################################
# Text Box Structure
############################################################
=TB_X1_off 0
=TB_Y1_off 2
=TB_X2_off 4
=TB_Y2_off 6
=TB_BufferPtr_off 8
=TB_Capacity_off 10
=TB_Length_off 12
=TB_CursorPos_off 14
=TB_Flags_off 16
=TB_Obj_Size TB_Flags_off+2

############################################################
# Program Globals
############################################################

   # Terminal dimensions
   :Columns 0
   :Rows 0

   # Event system
   :EventID 0
   :EventTable 0
   :Running 0

   # Heap and software stack
   :ObjectSize 0
   :HEAP_ID 0
   :SoftStackStart 0
   :SoftStackEnd 0
   #
   # Object locations
  :Box1X1 0
  :Box1X2 0
  :Box1Y1 0
  :Box1Y2 0
  :Box2X1 0
  :Box2X2 0
  :Box2Y1 0
  :Box2Y2 0
  :ExitX1 0
  :ExitX2 0
  :ButtonY 0
  :ClearX1 0
  :ClearX2 0
  # Wigit pointers
  :Box1Ptr 0
  :Box2Ptr 0
  :Button1Ptr 0
  :Button2Ptr 0
  :ActiveTextBox 0
#########################################################
# Text Fields
#########################################################
:ExitText "Exit\0"
:ClearText "Clear\0"

########################################################
# Debug Macros
########################################################
:StackInfo 0
M StackSet @SRTP @POPI StackInfo
M StackCheck @SRTP @PUSHI StackInfo @ADD %1 @CMPS @IF_ZFLAG @ELSE @PRT "Stack Off:" @StackDump @ENDIF @POPNULL @POPNULL
#M StackSet
#M StackCheck MF %1 0
  

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

   # Locate the two boxes

   # Large box X's will be Screen minux  1/8 width of the screen.
   @PUSHI WinWidth
   @SHRN 3  # Div by 8
   @POPI Box1X1
   @PUSHI WinWidth
   @SUBI Box1X1
   @POPI Box1X2
   # Large Box Y's start row 3 to 3/4 height of screen
   @MA2V 3 Box1Y1
   @PUSHI WinHeight
   @SHRN 2   # Div by 4
   @DUP     # 1/4 height
   @DUP     # 1/4 height
   @ADDS    # 1/2 height
   @ADDS    # 3/4 height
   @POPI Box1Y2
   #
   # Small Box is Centered Width-8 wide
   # 3 lines high and starts at WinHeight - 4
   @MA2V 4 Box2X1
   @PUSHI WinWidth
   @SUB 4
   @POPI Box2X2
   @PUSHI WinHeight
   @SUB 4
   @POPI Box2Y1
   @PUSHI Box2Y1
   @ADD 3
   @POPI Box2Y2
   #
   # Now buttons
   # Both Buttons will be on line 1
   @MA2V 1 ButtonY
   # Exit Will be 5
   @MA2V 5 ExitX1
   @PUSHI ExitX1
   @ADD 4        # 4 letters in Exit
   @POPI ExitX2
   # Clear will be WinWidth - 10
   @PUSHI WinWidth
   @SUB 10
   @POPI ClearX1
   @PUSHI ClearX1
   @ADD 5          # Five letters in Clear
   @POPI ClearX2

   @CALL WinClear
   @Call(VVVA) ButtonDraw ExitX1 ExitX2 ButtonY ExitText
   @Call(VVVA) ButtonDraw ClearX1 ClearX2 ButtonY ClearText
   
   @Call(VVVV) WinBox Box1X1 Box1Y1 Box1X2 Box1Y2
   @Call(VVVV) WinBox Box2X1 Box2Y1 Box2X2 Box2Y2
   
   


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


   @PUSH KeyRangeEvent
   @PUSH " \0"          # ASCII 0x20
   @PUSH "~\0"          # ASCII 0x7e
   @PUSH 0
   @PUSH 0
   @PUSH EV_TEXT_CHAR
   @CALL EventAdd

   @PUSH MouseEventClick
   @PUSHI Box1X1
   @PUSHI Box1Y1
   @PUSHI Box1X2
   @PUSHI Box1Y2
   @PUSH EV_BOX1_CLICK
   @CALL EventAdd

   @PUSH MouseEventClick
   @PUSHI Box2X1
   @PUSHI Box2Y1
   @PUSHI Box2X2
   @PUSHI Box2Y2
   @PUSH EV_BOX2_CLICK
   @CALL EventAdd

   @PUSH MouseEventClick
   @PUSHI ExitX1
   @PUSHI ButtonY
   @PUSHI ExitX2
   @PUSHI ButtonY
   @PUSH EV_EXIT_CLICK
   @CALL EventAdd

   @PUSH MouseEventClick
   @PUSHI ClearX1
   @PUSHI ButtonY
   @PUSHI ClearX2
   @PUSHI ButtonY
   @PUSH EV_CLEAR_CLICK
   @CALL EventAdd

   ########################################################
   # Create the TextBoxes
   ########################################################

   @Call(VVVV) TextBoxInit Box1X1 Box1Y1 Box1X2 Box1Y2
   @POPI Box1Ptr
   @Call(VVVV) TextBoxInit Box2X1 Box2Y1 Box2X2 Box2Y2
   @POPI Box2Ptr
   
   @MV2V Box1Ptr ActiveTextBox


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

      @CASE EV_BOX1_CLICK
         @POPNULL
         @MV2V Box1Ptr ActiveTextBox
         @Call(VV) WinCursor Box2X1 Box2Y1
         @PRT "+-----------"
         @Call(VV) WinCursor Box1X1 Box1Y1
         @PRT "+<Active>---"
         @CBREAK
      @CASE EV_BOX2_CLICK
         @POPNULL
         @MV2V Box2Ptr ActiveTextBox         
         @Call(VV) WinCursor Box1X1 Box1Y1
         @PRT "+-----------"
         @Call(VV) WinCursor Box2X1 Box2Y1
         @PRT "+<Active>---"         
         @CBREAK
      @CASE EV_EXIT_CLICK
         @POPNULL
         @MA2V 0 Running
         @CBREAK
      @CASE EV_TEXT_CHAR
         @POPNULL
         @IF_NEQ_AV 0 ActiveTextBox
            @Call(VV) TextBoxPutChar ActiveTextBox LastKeyChar
            @Call(V) TextBoxShow ActiveTextBox
         @ENDIF
         @CBREAK
      @CASE EV_CLEAR_CLICK
         @POPNULL
         @IF_NEQ_AV 0 ActiveTextBox
            @Call(V) TextBoxClear ActiveTextBox
            @Call(V) TextBoxShow ActiveTextBox
         @ENDIF
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
   @IF_NOTZERO
      @PRT "Error On Exit"
   @ENDIF
   @POPNULL

   # Leave the shell prompt on a clean line.
   @Call(VV) WinCursor 1 Rows
   @PRTNL

@END

################################################################
# TextBoxInit(X1,Y1,X2,Y2):TB_Ptr
################################################################
:TextBoxInit
@PUSHRETURN
@Locals
   @Local X1
   @Local X2
   @Local Y1
   @Local Y2
   @Local TextBoxPtr
   @Local BuffSize
   @Local Capacity
   @Local BuffPtr

   @POPI4 Y2 X2 Y1 X1

   @MA2V 0 TextBoxPtr

###### Validate X#,Y# are valid ranges
#    Macro ForceRangeAV(Var,Low_constant, HighVariable)
#  Exits with 0 result if X# or Y# are out of range.

    M ForceRangeAV \
           @PUSHI %1 @AND 0x7fff \
           @IF_INRANGE_AV %2 %3 @ELSE \
              @Call(AA) WinCursor 70 3 \
              @PRT "ERR Invalid Win Size:" \
              @PRTI X1 @PRTSP @PRTI Y1 @PRTSP @PRTI X2 @PRTSP @PRTI Y2 \
              @JMP TBExit \
           @ENDIF \
           @POPI %1

   @ForceRangeAV X1 1 WinWidth
   @ForceRangeAV X2 1 WinWidth
   @ForceRangeAV Y1 1 WinHeight
   @ForceRangeAV Y2 1 WinHeight

   @QuickMinI X1 X2
   @QuickMinI Y1 Y2

   # Draw the Box1
   @Call(VVVV) WinBox X1 Y1 X2 Y2

   # Acutual text box is within this larger box.
   @INCI X1
   @INCI Y1
   @DECI X2
   @DECI Y2

   # Create the Table Object
   @Call(VA) HeapNewObject HEAP_ID TB_Obj_Size
   @IF_LT_A 100
      @PRT "Memory Error:"
      @JMP TBExit
   @ENDIF
   @POPI TextBoxPtr

   # Calculate size of buffer
   @PUSHI X2
   @SUBI X1
   @ADD 1
   @PUSHI Y2
   @SUBI Y1
   @ADD 1
   @CALL MULU
   @POPI Capacity
   @PUSHI Capacity
   @ADD 1        # Add extra byte for null
   @POPI BuffSize

   @FILL_AT_V TextBoxPtr TB_Capacity_off Capacity
   # Save in Object XY values
   @FILL_AT_V TextBoxPtr TB_X1_off X1
   @FILL_AT_V TextBoxPtr TB_X2_off X2
   @FILL_AT_V TextBoxPtr TB_Y1_off Y1
   @FILL_AT_V TextBoxPtr TB_Y2_off Y2
   # Initialize string buffer info
   @FILL_AT_A TextBoxPtr TB_Length_off 0
   @FILL_AT_A TextBoxPtr TB_CursorPos_off 0
   @FILL_AT_A TextBoxPtr TB_Flags_off 0

   @Call(VV) HeapNewObject HEAP_ID BuffSize   
   @IF_LT_A 100
      @POPNULL
      @Call(VV) HeapDeleteObject HEAP_ID TextBoxPtr
      @MA2V 0 TextBoxPtr
      @PRT "Memory Error:"
      @JMP TBExit
   @ENDIF
   @FILL_AT_S TextBoxPtr TB_BufferPtr_off
   # Put a null zero at the first word of new buffer.
   @PUSH 0
   @GET_FROM TextBoxPtr TB_BufferPtr_off
   @POPS
   # Finish up.
   :TBExit
   @PUSHI TextBoxPtr
@EndLocals
@POPRETURN
@RET


################################################################
# TextBoxShow(TextBoxPtr)
################################################################
:TextBoxShow
@PUSHRETURN
@Locals
    @Local TextBoxPtr
    @Local StrPtr
    @Local X1
    @Local Y1
    @Local X2
    @Local Y2
    @Local MaxWidth
    @Local SaveSpot
    @Local Remaining
    @Local SavedWord
    
    @POPI TextBoxPtr
    @GET_FROM TextBoxPtr TB_X1_off
    @POPI X1
    @GET_FROM TextBoxPtr TB_Y1_off
    @POPI Y1
    @GET_FROM TextBoxPtr TB_X2_off
    @POPI X2
    @GET_FROM TextBoxPtr TB_Y2_off
    @POPI Y2
    @GET_FROM TextBoxPtr TB_BufferPtr_off
    @POPI StrPtr

    @PUSHI X2
    @SUBI X1
    @ADD 1
    @POPI MaxWidth

    @Call(VVVV) WinClearRect X1 Y1 X2 Y2
    @Call(VV) WinCursor X1 Y1

    @Call(V) strlen StrPtr
    @POPI Remaining
    @StackSet
    @PUSHI Remaining
    @WHILE_NOTZERO 
        @IF_LE_V MaxWidth
           @POPNULL
           @PRTSTRI StrPtr
           @MA2V 0 Remaining           
        @ELSE
           @POPNULL
           @PUSHI StrPtr  # Cut off MaxWidth Part of string
           @ADDI MaxWidth
           @POPI SaveSpot

           @PUSHII SaveSpot  # Location to cut
           @POPI SavedWord   # Save it for later

           @PUSHI SavedWord  # Fill null in at cut.
           @AND 0xff00
           @POPII SaveSpot

           @PRTSTRI StrPtr   # Print to Null

           @PUSHI SavedWord  # Restore null'ed byte
           @POPII SaveSpot

           @PUSHI StrPtr     # Move StrPtr forward MaxWidth
           @ADDI MaxWidth
           @POPI StrPtr

           @PUSHI Remaining
           @SUBI MaxWidth
           @POPI Remaining

           @INCI Y1
           @PUSHI Y1
           @IF_GT_V Y2
              @MA2V 0 Remaining
           @ELSE
              @Call(VV) WinCursor X1 Y1
           @ENDIF
       @ENDIF
       @PUSHI Remaining
     @ENDWHILE
     @POPNULL
@EndLocals
@POPRETURN
@RET

##############################################
# ButtonDraw(X1,X2,Y, StrPtr):void
#############################################
:ButtonDraw
@PUSHRETURN
@Locals
   @Local X1
   @Local X2
   @Local Y1
   @Local StrPtr

   @POPI4 StrPtr Y1 X2 X1

   @Call(VV) WinCursor X1 Y1
   @PRTSTRI StrPtr
@EndLocals
@POPRETURN
@RET

   
           
    
    
    

    

@Locals

@EndLocals
@POPRETURN
@RET

################################################################
# TextBoxPutChar(TB_Ptr,Char):Status
################################################################
:TextBoxPutChar
@PUSHRETURN
@Locals
   @Local TextBoxPtr
   @Local Char
   @Local MaxLength
   @Local BuffString
   @Local CurLength

   @POPI2 Char TextBoxPtr

   @PUSHI Char @AND 0xff @POPI Char
   @GET_FROM TextBoxPtr TB_Capacity_off
   @POPI MaxLength
   @GET_FROM TextBoxPtr TB_BufferPtr_off
   @POPI BuffString
   @GET_FROM TextBoxPtr TB_Length_off
   @POPI CurLength
   @PUSHI CurLength
   @IF_ULT_V MaxLength
      @POPNULL
      @PUSHI Char
      @PUSHI BuffString
      @ADDI CurLength
      @POPS
      @INCI CurLength
      @FILL_AT_V TextBoxPtr TB_Length_off CurLength
   @ELSE
      @POPNULL
   @ENDIF
   
@EndLocals
@POPRETURN
@RET

################################################################
# TextBoxClear(TB_Ptr)
################################################################
:TextBoxClear
@PUSHRETURN
@Locals
   @Local TextBoxPtr
   @Local BuffPtr

   @POPI TextBoxPtr

   @GET_FROM TextBoxPtr TB_BufferPtr_off
   @POPI BuffPtr

   # Empty string.
   @PUSH 0
   @PUSHI BuffPtr
   @POPS

   # Reset object state.
   @FILL_AT_A TextBoxPtr TB_Length_off 0
   @FILL_AT_A TextBoxPtr TB_CursorPos_off 0
@EndLocals
@POPRETURN
@RET

################################################################
# TextBoxDestory(TB_Ptr)
################################################################
:TextBoxDestory
@PUSHRETURN
@Locals

@EndLocals
@POPRETURN
@RET

:ENDOFCODE
