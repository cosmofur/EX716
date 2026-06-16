! __LIB_EVENT_LOADED
M __LIB_EVENT_LOADED 1
I event.ref

#########################
# These are the main public Functions.
#
G TermMouseDisable          # Disable Mouse, puts back into default mode ()
G TermMouseEnable           # Enable Mouse, clicks generate ANSI Location info ()
G EventAdd                  # Add event to Event Table (Type,X1,Y1,X2,Y2,EventID)
G EventPoll                 # Polls an Event Table returns 0, or ID of matched event. ():EventID
G EventList                 # Prints for debugging Event Table ()
G EventTableNew             # Creates a New Event table (HeapID):EventTableID
G EventSetActive            # Switches current active eventtable to Active  (EventTableID)
G EventGetActive            # Returns the current Active eventtable ():EventTableID
G CSICODE                   # Points to the CSICODE "<ESC>[" string
##########################
# These are public meta data to recall additional information about last registed event.
# These are Variables, not functions.
# Gets updated with each call to EventPoll
G LastEventType         # One of [MouseEvent,KeyEvent,TimerEvent]
G LastEventID           # EventID of the latest event
G LastEventTSLo         # For 32 bit Time data, Low word
G LastEventTSHi         # For 32 bit Time data, High word
G LastMouseX            # location of last mouse click X
G LastMouseY            # location of last mouse click Y
G LastMouseBtn          # Which mouse button was clicked.
G LastMouseFlags        # OR'ed [MF_PRESS|MF_RELEASE|MF_DRAG|MF_WHEEL|MF_ALT|MF_CTRL]
G LastMouseRawB         # Raw byte from Mouse click value
G LastMouseTerm         # Raw String data from mouse
G MF_PRESS              # Codes for Mouse Click
G MF_RELEASE
G MF_DRAG
G MF_WHEEL
G MF_SHIFT
G MF_ALT
G MF_CTRL
G LastKeyMatchPtr       # Ptr into string match for keyboard events
G LastKeyLen            # N.U.
G LastKeyChar           # ASCII code of last key (Single byte events only)
G LastTimerDur          # Seconds of Duraction based on request
G LastTimeRep           # 0/1 if it was set to auto repeat
G LastTimerELap         # Elapsed file time (real vs requested duration)
G LastTimerSkip         # How many periods where skipped this poll
G MouseEvent            # Mouse event 'constant'
G MouseEventClick       # Mouse Event Click
G MouseEventRelease     # Mouse Event Release
G TimerEvent            # Timer event 'constant'
G KeyEvent              # Key event 'constant'

# These functions manage the event queue for caching events.
G ReadKeyTimeOut
G KeyEnQueue G KeyDeQueue G KeyQueueSize G KeyReadMouseSeq G KeySearchMouse
G KeySearchKeyBoard G KeySearchTimer


# ActiveEventTable is a pointer to active event loop,
# You can query it directly for status, but use the EventSetActive and EventGetActive for sanity checks.
G ActiveEventTable
# If you plan on using multiple EventTables, remember to update your copy of the EventID with EventGetActive
# after any change to the table, such as with EventAdd
#

=MF_PRESS   0x0001
=MF_RELEASE 0x0002
=MF_DRAG    0x0004
=MF_WHEEL   0x0008
=MF_SHIFT   0x0010   # SGR adds 4 to b for shift
=MF_ALT     0x0020   #   ... 8 for meta/alt
=MF_CTRL    0x0040   #   ... 16 for ctrl
=MouseEvent        0xf     # MF_PRESS | MF_RELEASE | MF_DRAG | MG_WHEEL
=MouseEventClick   0x1     # MF_PRESS
=MouseEventRelease 0x2     # MF_RELEASE
=TimerEvent 0x0100         # Keep away from bitmasks used for Mouse eventss
=KeyEvent 0x0200
=MouseEventDetected 1
#
#
# Strucure of Event Table entries.
=EventRecordSize 12
=ActiveEventTableHeaderSize 6
=EventMaxUsedHeadOff 2
=EventBackupHeapOff 4
=EventMaxLocOff 2
=EventIDOff 4
=EventTypeOff 6
=EventExOneOff 8
=EventExTwoOff 10
=TimerStartOff 0
=TimerDurOff 8
=TimerRepOff 10


########################################
# function EventTableNew(HeapID):EventTable
# Creates an EventTable which will contain a unique list of events to monitor
@FUNCTION EventTableNew
:EventTableNew
@PUSHRETURN
@Locals
@Local HeapID
@POPI HeapID
   @Call(vA) HeapNewObject HeapID EventRecordSize+ActiveEventTableHeaderSize
   @POPI ActiveEventTable
   @PUSH 1 @PUSHI ActiveEventTable @ADD EventMaxUsedHeadOff @POPS   # Sets allocated rows in table
   @PUSHI HeapID @PUSHI ActiveEventTable @ADD EventBackupHeapOff @POPS  # Saves HeapID for later resizes.
   @PUSHI ActiveEventTable
@EndLocals
@POPRETURN
@RET
ENDBLOCK
#########################################
# function: EventTableFree(EventTableID)
@FUNCTION EventTableFree
:EventTableFree
@PUSHRETURN
@Locals
@Local EventTableID
@POPI EventID
   @IF_EQ_AV 0 EventTableID
      # Event table not setup, nothing to kill.
   @ELSE
      @PUSHI EventID @ADD EventBackupHeapOff @POPS   # Get HeapID
      @PUSHI EventTableID
      @CALL HeapDeleteObject @IF_NOTZERO
         @PRT "Memory Error deleteing Event Table:" @PRTTOP
         @END
      @ENDIF
   @ENDIF
   @MA2V 0 ActiveEventTable
@EndLocals
@POPRETURN
@RET
ENDBLOCK
##########################################
# function: EventSetActive(EventTableID)
# This function sets the ActiveEventTable
@FUNCTION EventSetActive
:EventSetActive
@SWP
@POPI ActiveEventTable
@RET
ENDBLOCK
##########################################
# function: EventGetActive():EventTableID
# Queries what the current ActiveEventTable is.
@FUNCTION EventGetActive
:EventGetActive
@PUSHI ActiveEventTable
@SWP
@RET
ENDBLOCK


# For MouseEvents:
#   (Type=MouseEvent, X1, Y1, X2, Y2, EventID)
#
# For KeyboardEvents:
#   (Type=KeyEvent, StrPtr, 0, 0, 0, EventID)
#     - StrPtr points to string of keys to watch for
#
# For TimerEvents:
#   (Type=TimerEvent, Duration(sec), RepeatFlag, 0, 0, EventID)
#     - RepeatFlag = 0 one-shot, 1 periodic


########################################
# Function: TermMouseDisable()
@FUNCTION TermMouseDisable
:TermMouseDisable
@PRTS CSICODE @PRT "?1000l"
@PRTS CSICODE @PRT "?1006l"
@RET
ENDBLOCK
########################################
# Function: TermMouseEnable()
@FUNCTION TermMouseEnable
:TermMouseEnable
@PRTS CSICODE @PRT "?1000h"
@PRTS CSICODE @PRT "?1006h"
@RET
ENDBLOCK

#######################################
# Macros for EventAdd
# Ensures (%1, %2) such that %1 <= %2 Both must be variable lables, not constants.
M QuickMinI @PUSHI %1 @PUSHI %2 @IF_GT_S @SWP @POPI %2 @POPI %1 @ELSE @POPNULL @POPNULL @ENDIF
#
# Combines 1,2 into word so %1 is high byte and %2 is low.
M EncodeLoc @PUSHI %2 @SHL @SHL @SHL @SHL @SHL @SHL @SHL @SHL @PUSHI %1 @AND 0xff @ORS

# For MouseEvents:
#   (Type=MouseEvent, X1, Y1, X2, Y2, EventID)
#
# For KeyboardEvents:
#   (Type=KeyEvent, StrPtr, 0, 0, 0, EventID)
#     - StrPtr points to string of keys to watch for
#
# For TimerEvents:
#   (Type=TimerEvent, Duration(sec), RepeatFlag, 0, 0, EventID)
#     - RepeatFlag = 0 one-shot, 1 periodic

########################################
# Function: EventAdd(Type,X1,Y1,X2,Y2,EventID)
#
#
@FUNCTION EventAdd
:EventAdd
@PUSHRETURN
@Locals
@Local Type       # 1 = mouse, 2 = timer, 3 = Keyboard
@Local X1         # Mouse: X1, Timer: Max Seconds, Keyboard:StrPtr(In)
@Local Y1         # Mouse: Y1, Timer: 0|1 del:repeat
@Local X2         # Mouse: X2  Timer: NR, KeyBoard: NR
@Local Y2         # Mouse: Y2
@Local EventID
@Local Index1
@Local MAESize
@Local MAEMaxSize
@Local MTHeapID
@Local Index2
@Local InsertSpot
#
@POPI EventID @POPI Y2 @POPI X2 @POPI Y1 @POPI X1 @POPI Type
    # Extract table header data
    @PUSHI ActiveEventTable @PUSHS @POPI MAESize                  # Current Number of used records
    @PUSHI ActiveEventTable @ADD EventMaxUsedHeadOff @PUSHS @POPI MAEMaxSize # Max possible without resize
    @PUSHI ActiveEventTable @ADD EventBackupHeapOff @PUSHS @POPI MTHeapID    # HeapID for resizeing
    @PUSHI ActiveEventTable @ADD ActiveEventTableHeaderSize @POPI Index1           # First Record after headers
    #
    # See if EventID exists already, which case this is a replace.
    @MA2V -1 InsertSpot   # For cases with no matching EventID
    @ForIA2V Index2 0 MAESize
        @PUSHI Index1 @ADD EventIDOff @PUSHS   # EventID
        @IF_EQ_V EventID
           # Exact match
           @POPNULL
           @MA2V Index1 InsertSpot
           @FORBREAK         # Note this only works because IF is 'top' level in loop
        @ELSE
           @POPNULL
           @PUSHI Index1 @ADD EventRecordSize @POPI Index1   # Move to next Entry
        @ENDIF
    @Next Index2
    @IF_EQ_AV -1 InsertSpot
       # Never found so create new entry.
       @IF_EQ_VV MAESize MAEMaxSize
           # Time to expand the table with HeapResize
           @PUSHI MTHeapID
           @PUSHI ActiveEventTable
           @PUSHI MAEMaxSize       # Need to turn max size into bytes in table space.
           @ADD 10                # Allocate 10 new cells for growth.
           @PUSH EventRecordSize
           @CALL MUL              # Multiply
           @ADD ActiveEventTableHeaderSize     # Add the Header part.
           @CALL HeapResizeObject
           @IF_ULT_A 100
               @PRT "Error Can not allocate memory for mouse table growth."
               @END
           @ENDIF
           @POPI ActiveEventTable
           @PUSHI MAEMaxSize @ADD 10     # Reset Max size record to new size
           @PUSHI ActiveEventTable @ADD EventMaxUsedHeadOff @POPS  # Writes new max size
           #
       @ENDIF
       @PUSHI MAESize @PUSH EventRecordSize @CALL MUL
       @ADDI ActiveEventTable
       @ADD ActiveEventTableHeaderSize @POPI InsertSpot
       @INCI MAESize
       @PUSHI MAESize @PUSHI ActiveEventTable  @POPS # Save it in header First record is used record count.
   @ELSE
       # Here means  InsertSpot has a non -1 value, so there is pre-existing EventID Cell
   @ENDIF
   #
   # Here means InsertSpot is pointer to cell that needs data
   #
   # 0               MinLoc(X1,Y1<<8): Or
   # 2               MaxLoc(X2,Y2<<8)
   # 4               EventID
   # 6               EventType (0:mouse,1:Key,2:Timer)
   # 8               EventExOneOff Timer Counter or Str Ptr
   # 10              EventExTwoOff Timer Max Value
   @PUSHI Type
   @SWITCH
   @CASE_RANGE 1 MouseEvent # mouse events are all in range 1 to 15
      # Mouse
      # Quick function to swap variable values to V1 will be < V2
      @QuickMinI X1 X2
      @QuickMinI Y1 Y2
      #
      @EncodeLoc X1 Y1
      @PUSHI InsertSpot @POPS           # InsertSpot[0,1] = MinLoc
      @EncodeLoc X2 Y2
      @PUSHI InsertSpot @ADD EventMaxLocOff  @POPS    # Save to InsertSpot[2,3]
      @PUSHI EventID @PUSHI InsertSpot @ADD EventIDOff  @POPS    # InsertSpot[4,5]=EvenID
      @PUSHI Type @PUSHI InsertSpot @ADD EventTypeOff @POPS       # InsertSpot[6,7]=Type
      # For mouse EventData1/2 are not used.
      @CBREAK
   @CASE KeyEvent # KeyBoard
      # KeyBoard Event
      # X1 = StrPtr to string listing what to keep eye out for. Keys that do not match will be ignored.
      @PUSHI Type @PUSHI InsertSpot @ADD EventTypeOff @POPS
      @PUSHI X1   @PUSHI InsertSpot @ADD EventExOneOff @POPS
      @PUSHI EventID @PUSHI InsertSpot @ADD EventIDOff  @POPS    # InsertSpot[4,5]=EvenID
      @CBREAK
   @CASE TimerEvent  # Timer
      # Timer Event
      # Mouse MinLoc == Start time
      @PUSHI Type @PUSHI InsertSpot @ADD EventTypeOff @POPS
      @GETTIME
      @POPNULL # Drop High 16
      @PUSHI InsertSpot @ADD TimerStartOff @POPS
      @PUSHI X1   @PUSHI InsertSpot @ADD TimerDurOff @POPS
      @PUSHI Y1   @PUSHI InsertSpot @ADD TimerRepOff @POPS
      @PUSHI EventID @PUSHI InsertSpot @ADD EventIDOff  @POPS    # InsertSpot[4,5]=EvenID
      @CBREAK
   @CDEFAULT
      @PRT "Error Not valid event type:"
      @END
      @CBREAK
   @ENDCASE
   @POPNULL
@EndLocals
@POPRETURN
@RET
ENDBLOCK
#########################################
# Function ReadKeyTimeOut
# Polls for next character but also times out if not seen in 10 cycles
@FUNCTION ReadKeyTimeOut
:ReadKeyTimeOut
@PUSHRETURN
@Locals
@Local CHin
   @PUSH 0
   @WHILE_LT_A 2
      @READCNW CHin
      @IF_EQ_AV 0 CHin
         @ADD 1
      @ELSE
         @WHILEBREAK
      @ENDIF
   @ENDWHILE
   @IF_LT_A 10
      @POPNULL
      @PUSHI CHin @AND 0xff
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF
@EndLocals
@POPRETURN
@RET
ENDBLOCK
########################################
#
=KQ_MASK 0x1f
########################################
# Funtion KeyEnQueue(ch)
@FUNCTION KeyEnQueue
:KeyEnQueue
@PUSHRETURN
@Locals
@Local Head
@Local Tail
@Local NextTail
@Local ChIN
@Local Address
#
@POPI ChIN
    @PUSHI QBufferHead @AND 0xff @POPI Head
    @PUSHI QBufferTail @AND 0xff @POPI Tail
    @PUSHI Tail @ADD 1 @AND KQ_MASK      # Wrap using mod32 mask
    @POPI NextTail
    @IF_EQ_VV Head NextTail
       # Queue is Full
    @ELSE
       @PUSH QBuffer @ADD 1 @ADDI Tail @POPI Address
       @PUSHI ChIN @AND 0xff       # Buffer[tail+2]=CH
       @PUSHII Address @AND 0xff00 # Preserve High Byte
       @ORS                        # Combine low and high
       @POPII Address              # Save it back to [Address]
       # Save Tail which is Mod'ed +1 old tail back to QBufferTail
       @PUSHI QBufferTail @AND 0xff00    # Preserve High Byte
       @ORI NextTail
       @POPI QBufferTail
    @ENDIF
@EndLocals
@POPRETURN
@RET
ENDBLOCK
########################################
# Function KeyQueueSize()
@FUNCTION
:KeyQueueSize
#
# Light enough code we don't need to save locals
@PUSHRETURN
   @PUSHI QBufferTail @AND 0xff
   @PUSHI QBufferHead @AND 0xff
   @SUBS                       # Sub Tail-Head
   @AND KQ_MASK                   # Mod 32
#@SWP   # put (retaddr) on top so @RET pops it; leaves size to caller
@POPRETURN
@RET
ENDBLOCK

#########################################
# Function KeyDeQueue
@FUNCTION KeyDeQueue
:KeyDeQueue
@PUSHRETURN
@Locals
@Local Head
@Local Tail
    @PUSHI QBufferHead @AND 0xff @POPI Head
    @PUSHI QBufferTail @AND 0xff @POPI Tail
    @IF_EQ_VV Head Tail
        @PUSH 0          # Return Nill Empty
    @ELSE
       @PUSH QBuffer @ADD 1 @ADDI Head @PUSHS  # ch=QBuffer[head+2]
       @AND 0xff
       # Result CH is on stack
       # Now add 1 to Head and replace in its spot on the table
       @PUSHI Head @ADD 1 @AND KQ_MASK   # Head+1 Mod 32
       @PUSHI QBufferHead @AND 0xff00 # Protect High Bytes
       @ORS                           # Combine Head to low Byte
       @POPI QBufferHead
    @ENDIF
@EndLocals
@POPRETURN
@RET
ENDBLOCK

########################################
# Function: KeyReadMouseSeq():(x,y)
# Only handles the <ESC>[<btn;XVal;YValM mouse events.
# Mouse and screen events are 1 base, meaning upper left is 1,1 not 0,0
@FUNCTION KeyReadMouseSeq
:KeyReadMouseSeq
@PUSHRETURN
@Locals
@Local ChIN
@Local CurVal
    @MA2V 0 LastMouseX
    @MA2V 0 LastMouseY
    @MA2V 0 CurVal
    @MA2V -1 LastMouseRawB
    @PUSH 0
    @WHILE_ZERO
       @POPNULL
       @CALL ReadKeyTimeOut  @AND 0xff
       @SWITCH
       @CASE ";\0"
          @POPNULL
          @IF_EQ_AV -1 LastMouseRawB
             @MV2V CurVal LastMouseRawB
             @MA2V 0 CurVal
          @ELSE
             @MV2V CurVal LastMouseX
             @MA2V 0 CurVal
          @ENDIF
          @PUSH 0
          @CBREAK
       @CASE "M\0"
          @POPI LastMouseTerm        # save if its M or m
          @MV2V CurVal LastMouseY
          @PUSH 1      # Break While loop
          @CBREAK
       @CASE "m\0"
          @POPI LastMouseTerm         # save if its M or m
          @MV2V CurVal LastMouseY
          @PUSH 1      # Break While loop
          @CBREAK
       @CASE_RANGE "0\0" "9\0"
          @SUB "0\0"  # ASCII 0 to number 0
          @PUSHI CurVal
          @SHL         # X2
          @DUP
          @SHL @SHL    # X8
          @ADDS        # X10
          @ADDS
          @POPI CurVal
          @PUSH 0      # Continue
          @CBREAK
       @CDEFAULT
          # Not a valid character for mouse event.
          @POPNULL
          @MA2V -1 LastMouseX
          @MA2V -1 LastMouseY
          @PUSH 1      # Break the look
          @CBREAK
       @ENDCASE
    @ENDWHILE
    @POPNULL
    # Process result into meta data
    # Compute LastMouseBtn
    @PUSHI LastMouseRawB @PUSHS @AND 0x0040
    @IF_NOTZERO
       @POPNULL
       # wheel: up if (RawB & 1)==0, down if ==1
       @PUSHI LastMouseRawB @PUSHS @AND 0x0001
       @IF_ZERO @POPNULL  @PUSH 3  @ELSE @POPNULL @PUSH 4 @ENDIF
       @POPI LastMouseBtn
     @ELSE
        @POPNULL
        @PUSHI LastMouseRawB @PUSHS @AND 0x0003 @POPI LastMouseBtn
    @ENDIF
    # Set up flags
    @MA2V 0 LastMouseFlags
    @PUSH 0
    @IF_EQ_AV "M\0" LastMouseTerm @OR MF_PRESS @ENDIF
    @IF_EQ_AV "m\0" LastMouseTerm @OR MF_RELEASE @ENDIF
    @PUSHI LastMouseRawB @AND 0x20
    @IF_NOTZERO @POPNULL @OR MF_DRAG @ELSE @POPNULL @ENDIF
    @PUSHI LastMouseRawB @AND 0x40
    @IF_NOTZERO @POPNULL @OR MF_WHEEL @ELSE @POPNULL @ENDIF
    @PUSHI LastMouseRawB @AND 0x04
    @IF_NOTZERO @POPNULL @OR MF_SHIFT @ELSE @POPNULL @ENDIF
    @PUSHI LastMouseRawB @AND 0x08
    @IF_NOTZERO @POPNULL @OR MF_ALT @ELSE @POPNULL @ENDIF
    @PUSHI LastMouseRawB @AND 0x10
    @IF_NOTZERO @POPNULL @OR MF_CTRL @ELSE @POPNULL @ENDIF
    @POPI LastMouseFlags

    @PUSHI LastMouseX
    @PUSHI LastMouseY
@EndLocals
@POPRETURN
@RET
ENDBLOCK
############################################
# Helper Macros for the ActiveEventTable Search functions
M ExtractXMin @PUSHII %1 @AND 0xff
M ExtractYMin @PUSHI %1 @ADD 1 @PUSHS @AND 0xff
M ExtractXMax @PUSHI %1 @ADD 2 @PUSHS @AND 0xff
M ExtractYMax @PUSHI %1 @ADD 3 @PUSHS @AND 0xff
# Inclusive Compare: Returns 1 on stack is V between A and B unsiged.
# All three paramstes must be simple variables or address of values.
M Between_U \
  @PUSHI %1 @IF_ULT_V %2 \
               @POPNULL @PUSH 0 \
            @ELSE \
               @IF_UGT_V %3 \
                  @POPNULL @PUSH 0 \
               @ELSE \
                  @POPNULL @PUSH 1 \
               @ENDIF \
            @ENDIF
##########################################
# Funtion: KeySearchMouse(x,y) -> EventID | 0
@FUNCTION KeySearchMouse
:KeySearchMouse
@PUSHRETURN
@Locals
@Local X1
@Local Y1
@Local MTSize
@Local Base
@Local Rec
@Local MinX
@Local MinY
@Local MaxX
@Local MaxY
@Local Result

@POPI Y1
@POPI X1
    @MA2V -1 Result
    @PUSHII ActiveEventTable @POPI MTSize
    @PUSHI ActiveEventTable @ADD ActiveEventTableHeaderSize @POPI Base
    @ForIV2A Rec MTSize 0
       # Skip any non-mouse event
       @PUSHI Base @ADD EventTypeOff @PUSHS
       @ANDI LastMouseFlags
       @IF_ZERO
          @POPNULL
       @ELSE
          @POPNULL
          @ExtractXMin Base @POPI MinX   #Min X
          @ExtractYMin Base @POPI MinY  #Min Y
          @ExtractXMax Base @POPI MaxX  #Max X
          @ExtractYMax Base @POPI MaxY  #Max Y
          @Between_U X1 MinX MaxX
          @IF_NOTZERO
             @POPNULL
             @Between_U Y1 MinY MaxY
             @IF_NOTZERO
                 @POPNULL
                 @PUSHI Base @ADD EventIDOff @PUSHS
                 @POPI Result
                 @PUSHI MTSize @SUB 1 @POPI Rec # Break For
             @ELSE
                 @POPNULL
             @ENDIF
          @ELSE
             @POPNULL
          @ENDIF
      @ENDIF
      @PUSHI Base @ADD EventRecordSize @POPI Base
   @NextBy Rec -1
   @IF_EQ_AV -1 Result
      @PUSH 0      # Return null if no match
   @ELSE
      @PUSHI Result
   @ENDIF
@EndLocals
@POPRETURN
@RET
ENDBLOCK

########################################
# Function FindCh(String,Char):(0|Ptr)
# Retirs ptr to where in String Char is, or 0
@FUNCTION FindCh
:FindCh
@PUSHRETURN
@Locals
@Local Index1
@Local CharIn
@Local StringPtr
@Local Result
@POPI CharIn
@POPI StringPtr
   @MA2V 0 Result
   @PUSHII StringPtr @AND 0xff
   @WHILE_NOTZERO
       @IF_EQ_V CharIn
          @MV2V StringPtr Result
          @POPNULL
          @PUSH 0
       @ELSE
          @POPNULL
          @INCI StringPtr
          @PUSHII StringPtr @AND 0xff
       @ENDIF
   @ENDWHILE
   @POPNULL
   @PUSHI Result
@EndLocals
@POPRETURN
@RET
ENDBLOCK

########################################
# Function: KeySearchKeyBoard(ch) -> EventID|0
@FUNCTION KeySearchKeyBoard
:KeySearchKeyBoard
@PUSHRETURN
@Locals
@Local CHR
@Local MTSize
@Local Base
@Local InPtr
@Local C
@Local Rec
@Local Result
@POPI CHR
   @MA2V -1 Result
   @PUSHII ActiveEventTable @POPI MTSize
   @PUSHI ActiveEventTable @ADD ActiveEventTableHeaderSize @POPI Base
   @INCI MTSize
   @ForIV2A Rec MTSize 0
      @PUSHI Base @ADD EventTypeOff @PUSHS
      # Skip non keyboard events
      @IF_NEQ_A KeyEvent
          @POPNULL
      @ELSE
         @POPNULL
         @PUSHI Base @ADD EventExOneOff @PUSHS @POPI InPtr
         @PUSHI InPtr
         @PUSHI CHR
         @CALL FindCh
         @IF_NOTZERO
            @POPI LastKeyMatchPtr
            @PUSHI CHR @AND 0xff @POPI LastKeyChar
            # Input Matches Event
            @PUSHI Base @ADD EventIDOff @PUSHS
            @POPI Result
            @PUSHI MTSize @SUB 1 @POPI Rec # Break For loop
         @ELSE
            @POPNULL
         @ENDIF
      @ENDIF
      @PUSHI Base @ADD EventRecordSize @POPI Base
   @NextBy Rec -1
   @IF_EQ_AV -1 Result
      @PUSH 0
   @ELSE
      @PUSHI Result
   @ENDIF
@EndLocals
@POPRETURN
@RET
ENDBLOCK

##############################################
# Function: KeySearchTimer() -> EventID | 0
@FUNCTION KeySearchTimer
:KeySearchTimer
@PUSHRETURN
@Locals
@Local MTSize
@Local Base
@Local Rec
@Local Start
@Local Dur
@Local Rep
@Local Now
@Local Elap
@Local Result
   @MA2V -1 Result
   @PUSHI ActiveEventTable @PUSHS @POPI MTSize
   @PUSHI ActiveEventTable @ADD ActiveEventTableHeaderSize @POPI Base
   @ForIV2A Rec MTSize 0
       @PUSHI Base @ADD EventTypeOff @PUSHS
       @IF_NEQ_A TimerEvent
          @POPNULL
       @ELSE
          @POPNULL
          @PUSHI Base @ADD TimerDurOff  @PUSHS @POPI Dur
          @IF_EQ_AV 0 Dur
             # Do Nothing.
          @ELSE

             @PUSHI Base @ADD TimerStartOff @PUSHS @POPI Start
             @PUSHI Base @ADD TimerRepOff   @PUSHS @POPI Rep
             # Now = low16(Unix time)
             @GETTIME
             @POPNULL  # Get Rid of high 16
             @POPI Now

             # Elap = (Now - Start) Mod 0xffff (wrap safe)
             @PUSHI Now @SUBI Start @POPI Elap

             # If Dur <= Elap then event fire
             @PUSHI Dur
             @IF_ULE_V Elap
                # Event detected Push EventID to result
                @POPNULL
                @PUSHI Base @ADD EventIDOff @PUSHS @POPI Result
                @IF_EQ_AV 0 Rep
                    # One Time timer, mark as disabled.
                    @PUSH 0 @PUSHI Base @ADD EventTypeOff @POPS
                    @MV2V 0 LastTimeRep
                @ELSE
                   # periodic: advance Start forward by k*Dur past Now
                   # while Elap >= Dur: Start += Dur; Elap -= Dur
                   # This allows events to more closely match real time incriments.
                   @MV2V 1 LastTimeRep
                   @MA2V 0 LastTimerSkip
                   @PUSH 0
                   @WHILE_ZERO
                      @POPNULL
                      @PUSHI Dur
                      @IF_ULE_V Elap
                          @POPNULL
                          @PUSHI Start @ADDI Dur @POPI Start
                          @PUSHI Elap @SUBI Dur @POPI Elap
                          @INCI LastTimerSkip
                          @PUSH 0
                      @ELSE
                          @POPNULL
                          @PUSH 1
                      @ENDIF
                   @ENDWHILE
                   @POPNULL
                   # Save the updated Start time in record
                   @MV2V Elap LastTimerELap
                   @MV2V Dur LastTimerDur
                   @PUSHI Start @PUSHI Base @ADD TimerStartOff @POPS
                @ENDIF
                @PUSHI MTSize @SUB 1 @POPI Rec # Break Outer loop
             @ELSE
                @POPNULL
             @ENDIF
         @ENDIF
     @ENDIF
     @PUSHI Base @ADD EventRecordSize @POPI Base
  @NextBy Rec -1


  @IF_EQ_AV -1 Result
     @PUSH 0
  @ELSE
     @PUSHI Result
  @ENDIF
@EndLocals
@POPRETURN
@RET
ENDBLOCK


########################################
# Function: EventPoll:EventID
# Mouse Event.
@FUNCTION EventPoll
:EventPoll
@PUSHRETURN
@Locals
@Local MouseXVal @LocalVar MouseYVal 02 @LocalVar MouseEventCode 03
   # Fast exit if there nothing in ActiveEventTable to search for.
   @MA2V 0 MouseEventCode
   @PUSHII ActiveEventTable   # Mouse table will be zero if never defined.
   @IF_ZERO
      # nothing to do, just exit with zero as event id.
   @ELSE
      @POPNULL        # OK Mouse Table has some data, we'll review it later.
      @CALL ReadKeyTimeOut
      @IF_EQ_A 0
         @POPNULL
         # Zero on first char read, do nothing
      @ELSE
         @IF_EQ_A "\e\0"
            # Start of possible ESC sequence
            @POPNULL
            @CALL ReadKeyTimeOut
            @AND 0xff              # Make sure we are only dealing with 1 character.
            @SWITCH
            @CASE 0
                # Nothing immeditly followed ESC so its probably just the
                @POPNULL
                @PUSH "\e\0"       # Add the ESC to the Queue
                @CALL KeyEnQueue
                @CBREAK
            @CASE "[\0"
                # All Mouse sequences start <ESC>[ but it might still be something else.
                @POPNULL
                @CALL ReadKeyTimeOut
                @IF_EQ_A "<\0"
                    # Start of Mouse Sequence
                    @POPNULL
                    @CALL KeyReadMouseSeq     #parse Mouse Sequce into X,Y
                    @IF_NOTZERO
                       @POPI MouseYVal
                       @POPI MouseXVal
                       @MA2V MouseEventDetected MouseEventCode      # Flags that there is a mouse event to check
                    #
                       # If Mouse sequence was invalid, leaves 0 on stack.
                    @ENDIF
                @ELSE
                    # Was not a Mouse event, so queue it up so can be decord by calling functions.
                    @PUSH "\e\0" @CALL KeyEnQueue
                    @PUSH "[\0" @CALL KeyEnQueue
                    # What ever it was still on stack
                    @CALL KeyEnQueue
                @ENDIF
                @CBREAK
             @CDEFAULT
                # Not a <ESC>[ sequeucne so just put it on the queue
                @PUSH "\e\0" @CALL KeyEnQueue
                @CALL KeyEnQueue
                @CBREAK
             @ENDCASE
         @ELSE
             # Was not started by an <ESC> so treat as normal key.
             @IF_NOTZERO
                @CALL KeyEnQueue
             @ELSE
                @POPNULL
             @ENDIF
         @ENDIF
      @ENDIF
      # When we get here, we should now know if there was a mouse or key event and queue it up.
      # We handle MouseEvents before Key Events.
      @IF_EQ_AV MouseEventDetected MouseEventCode
          @PUSHI MouseXVal @PUSHI MouseYVal
          @CALL KeySearchMouse
      @ELSE
          @CALL KeyQueueSize
          @IF_ZERO
             @POPNULL
             @CALL KeySearchTimer
          @ELSE
             # Not zero there is a key to deal with.
             @POPNULL
             @PRTERR "Before KeyDeQueue" @StackDump
             @CALL KeyDeQueue
             @PRTERR "After KeyDeQueue" @StackDump
             @CALL KeySearchKeyBoard
             @PRTERR "After KeySearchKeyBoard" @StackDump
         @ENDIF
      @ENDIF
   @ENDIF
 @EndLocals
 @POPRETURN
 @RET
 ENDBLOCK
###########################
# Mouse Test
@FUNCTION EventList
:EventList
@PUSHRETURN
@Locals
@Local MTSize
@Local Index
@Local Base
@Local X1
@Local Y1
@Local X2
@Local Y2
@Local EventID
@Local Type

   # Load header values
   @PUSHI ActiveEventTable @PUSHS @POPI MTSize       # number of used entries
   @PUSHI ActiveEventTable @ADD ActiveEventTableHeaderSize @POPI Base

   @PRTNL
   @PRT "ActiveEventTable (" @PRTHEXI MTSize @PRT " records)" @PRTNL

   @ForIA2V Index 0 MTSize
      # Decode min/max coords
      @ExtractXMin Base @POPI X1
      @ExtractYMin Base @POPI Y1
      @ExtractXMax Base @POPI X2
      @ExtractYMax Base @POPI Y2

      # EventID
      @PUSHI Base @ADD EventIDOff @PUSHS @POPI EventID

      # Type
      @PUSHI Base @ADD EventTypeOff @PUSHS @POPI Type

      # Print line
      @PRT "Event:ID=" @PRTHEXI EventID
      @PRT " T=" @PRTHEXI Type
      @PRT " X1=" @PRTHEXI X1
      @PRT " Y1=" @PRTHEXI Y1
      @PRT " X2=" @PRTHEXI X2
      @PRT " Y2=" @PRTHEXI Y2
      @PRTNL

      # Next record
      @PUSHI Base @ADD EventRecordSize @POPI Base
   @Next Index

@EndLocals
@POPRETURN
@RET
ENDBLOCK
############# Storage
########################################
# Event Meta Data Struture:
# While EventLoop returns an EventID, the extra informaton learned about events is stored here.
#
#   Common Headers
:LastEventType 0
:LastEventID 0
:LastEventTSLo 0
:LastEventTSHi 0
#   Mouse Meta Data
:LastMouseX 0
:LastMouseY 0
:LastMouseBtn 0         # 0=left 1=middle 2=right, 3=wheel_up, 4=wheel_down
:LastMouseFlags 0       # Bitfield Press/Relase/Drag/Shift/Alt/Ctrl/Wheel
:LastMouseRawB 0        # Raw Button info
:LastMouseTerm 0        # M or m for click vs Relase
:ActiveEventTable 0     # Global Stored Active Event Table
########################################
# Event Meta Data Struture:
# While EventLoop returns an EventID, the extra informaton learned about events is stored here.
#
#   Common Headers
:LastEventType 0
:LastEventID 0
:LastEventTSLo 0
:LastEventTSHi 0
#   Mouse Meta Data
:LastMouseX 0
:LastMouseY 0
:LastMouseBtn 0         # 0=left 1=middle 2=right, 3=wheel_up, 4=wheel_down
:LastMouseFlags 0       # Bitfield Press/Relase/Drag/Shift/Alt/Ctrl/Wheel
:LastMouseRawB 0        # Raw Button info
:LastMouseTerm 0        # M or m for click vs Relase
:ActiveEventTable 0     # Global Stored Active Event Table
#   Keyboard Meta Data
:LastKeyMatchPtr 0
:LastKeyLen 0
:LastKeyChar 0          # 2 byte string Only for single byte keyboard events.
#   Timer Metadata
:LastTimerDur 0         # Seconds of Duraction based on request
:LastTimeRep  0         # 0/1 if it was set to auto repeat
:LastTimerELap 0        # Elapsed file time (real vs requested duration)
:LastTimerSkip 0        # How many periods where skipped this poll

:KeyBuffer 0 0 0 0 # 8 byte buffer
0 0 0 0 0 0 0 0 0 0 0 0 0 0
:QBufferHead $$0
:QBufferTail $$0
# Set 16 words => 32 bytes + 1b for high byte of 32nd entry
:QBuffer 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 $$0



M SIZESINCECOMMENT mouse.ld
@SIZESINCE
ENDBLOCK
