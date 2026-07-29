! __LIB_EVENT_LOADED
M __LIB_EVENT_LOADED 1
I event.ref
L mul.ld

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
G CISCODE                   # Points to the CISCODE "<ESC>[" string
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
G EventTableFree        # Frees heap for table.

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
=KeyRangeEvent 0x300
=MouseEventDetected 1
#
#
# Strucure of Event Table entries.
=EventTableHeaderSize 6
=EventUsedHeadOff     0
=EventMaxUsedHeadOff  2
=EventBackupHeapOff   4
=EventRecordSize 12
=EventDataOneOff 0
=EventDataTwoOff 2
=EventIDOff 4
=EventTypeOff 6
=EventExOneOff 8
=EventExTwoOff 10

=EventMinLocOff 0
=EventMaxLocOff 2

=MouseMinLocOff EventMinLocOff
=MouseMaxLocOff EventMaxLocOff
=KeyMatchPtrOff EventExOneOff
=KeyASCIIStartOff EventExOneOff
=KeyASCIIEndOff EventExTwoOff


=TimerStartOff EventDataOneOff
=TimerDurOff EventExOneOff
=TimerRepOff EventExTwoOff
#
#



########################################
# function EventTableNew(HeapID):EventTable
# Creates an EventTable which will contain a unique list of events to monitor
@FUNCTION EventTableNew
:EventTableNew
@PUSHRETURN
@Locals
@Local HeapID
@POPI HeapID
   @Call(vA) HeapNewObject HeapID EventRecordSize+EventTableHeaderSize
   @POPI ActiveEventTable
   @FILL_AT_A ActiveEventTable EventUsedHeadOff 0
   @FILL_AT_A ActiveEventTable EventMaxUsedHeadOff 1
   @FILL_AT_V ActiveEventTable EventBackupHeapOff HeapID
   @PUSHI ActiveEventTable
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#########################################
# function: EventTableFree(EventTableID)
@FUNCTION EventTableFree
:EventTableFree
@PUSHRETURN
@Locals
@Local EventTableID
@POPI EventTableID
   @IF_EQ_AV 0 EventTableID
      # Event table not setup, nothing to kill.
   @ELSE
      @GET_FROM EventTableID EventBackupHeapOff    # Get HeapID
      @PUSHI EventTableID
      @CALL HeapDeleteObject
      @IF_NOTZERO
         @PRT "ERR:MEM"
         @END
      @ENDIF
      @IF_EQ_VV ActiveEventTable EventTableID
         @MA2V 0 ActiveEventTable
      @ENDIF
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
##########################################
# function: EventSetActive(EventTableID)
# This function sets the ActiveEventTable
@FUNCTION EventSetActive
:EventSetActive
@SWP
@POPI ActiveEventTable
@RET
@ENDFUNCTION
##########################################
# function: EventGetActive():EventTableID
# Queries what the current ActiveEventTable is.
@FUNCTION EventGetActive
:EventGetActive
@PUSHI ActiveEventTable
@SWP
@RET
@ENDFUNCTION


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
@PRTS CISCODE @PRT "?1000l"
@PRTS CISCODE @PRT "?1006l"
@RET
@ENDFUNCTION
########################################
# Function: TermMouseEnable()
@FUNCTION TermMouseEnable
:TermMouseEnable
@PRTS CISCODE @PRT "?1000h"
@PRTS CISCODE @PRT "?1006h"
@RET
@ENDFUNCTION

#######################################
# Macros for EventAdd
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
# For KeyRangeEvent:
#   (Type=KeyRangeEvent, Low ASCII, High ASCII, 0, 0, EventID)
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
@POPI EventID
@POPI2 Y2 X2
@POPI2 Y1 X1
@POPI Type 
    # Extract table header data
    @GET_FROM ActiveEventTable EventUsedHeadOff @POPI MAESize
    @GET_FROM ActiveEventTable EventMaxUsedHeadOff @POPI MAEMaxSize
    @GET_FROM ActiveEventTable EventBackupHeapOff @POPI MTHeapID
    @PTR_AT ActiveEventTable EventTableHeaderSize @POPI Index1           # First Record after headers
    #
    # See if EventID exists already, which case this is a replace.
    @MA2V -1 InsertSpot   # For cases with no matching EventID
    @ForIA2V Index2 0 MAESize
        @GET_FROM Index1 EventIDOff
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
           @ADD EventTableHeaderSize     # Add the Header part.
           @CALL HeapResizeObject
           @IF_ULT_A 100
               @PRT "ERR:MEM"
               @END
           @ENDIF
           @POPI ActiveEventTable
           @PUSHI MAEMaxSize @ADD 10     # Reset Max size record to new size
           @FILL_AT_S ActiveEventTable EventMaxUsedHeadOff
           #
       @ENDIF
       @PUSHI MAESize @PUSH EventRecordSize @CALL MUL
       @ADDI ActiveEventTable
       @ADD EventTableHeaderSize @POPI InsertSpot
       @INCI MAESize
       @FILL_AT_V ActiveEventTable EventUsedHeadOff MAESize
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
      @FILL_AT_S InsertSpot MouseMinLocOff
      @EncodeLoc X2 Y2
      @FILL_AT_S InsertSpot MouseMaxLocOff
      # InsertSpot[4,5]=EvenID
      @FILL_AT_V InsertSpot EventIDOff EventID
      # InsertSpot[6,7]=Type
      @FILL_AT_V InsertSpot EventTypeOff Type
      # For mouse EventData1/2 are not used.
      @CBREAK
   @CASE KeyEvent # KeyBoard based on fixed strings
      # KeyBoard Event
      # X1 = StrPtr to string listing what to keep eye out for. Keys that do not match will be ignored.
      @FILL_AT_V InsertSpot EventTypeOff Type
      @FILL_AT_V InsertSpot KeyMatchPtrOff X1
      @FILL_AT_V InsertSpot EventIDOff EventID
      @CBREAK
   @CASE KeyRangeEvent # KeyBoard based on ascii ranges
      # X1=Start ASCII code, Y1=Stop Ascii Code
      @QuickMinI X1 Y1
      
      @FILL_AT_V InsertSpot EventTypeOff Type
      @FILL_AT_V InsertSpot KeyASCIIStartOff X1
      @FILL_AT_V InsertSpot KeyASCIIEndOff Y1      
      @FILL_AT_V InsertSpot EventIDOff EventID 
      @CBREAK
      
   @CASE TimerEvent  # Timer
      # Timer Event
      # Mouse MinLoc == Start time
      @FILL_AT_V InsertSpot EventTypeOff Type
      
      @GETTIME
      @POPNULL   # Discard high word
      @FILL_AT_S InsertSpot TimerStartOff

      @FILL_AT_V InsertSpot TimerDurOff X1
      @FILL_AT_V InsertSpot TimerRepOff Y1
      @FILL_AT_V InsertSpot EventIDOff EventID
      
      @CBREAK
   @CDEFAULT
      @PRT "ERR:ETY"
      @END
      @CBREAK
   @ENDCASE
   @POPNULL
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#########################################
# Function ReadKeyTimeOut
# Polls for next character but also times out if not seen in limited number cycles
@FUNCTION ReadKeyTimeOut
:ReadKeyTimeOut
@PUSHRETURN
@Locals
@Local CHin
   @PUSH 0
   @WHILE_LT_A 3
      @READCNW CHin
      @IF_EQ_AV 0 CHin
         @ADD 1
      @ELSE
         @WHILEBREAK
      @ENDIF
   @ENDWHILE
   @IF_LT_A 3
      @POPNULL
      @PUSHI CHin @AND 0xff
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
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
@ENDFUNCTION
########################################
# Function KeyQueueSize()
@FUNCTION KeyQueueSize
:KeyQueueSize
#
# Light enough code we don't need to save locals
@PUSHRETURN
   @PUSHI QBufferTail @AND 0xff
   @PUSHI QBufferHead @AND 0xff
   @SUBS                       # Sub Tail-Head
   @AND KQ_MASK                   # Mod 32
@POPRETURN
@RET
@ENDFUNCTION

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
@ENDFUNCTION

########################################
# Function: KeyReadMouseSeq():status (0|1)
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
    @PUSHI LastMouseRawB @AND 0x0040
    @IF_NOTZERO
       @POPNULL
       # wheel: up if (RawB & 1)==0, down if ==1
       @PUSHI LastMouseRawB @AND 0x0001
       @IF_ZERO @POPNULL  @PUSH 3  @ELSE @POPNULL @PUSH 4 @ENDIF
       @POPI LastMouseBtn
     @ELSE
        @POPNULL
        @PUSHI LastMouseRawB @AND 0x0003 @POPI LastMouseBtn
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

    @IF_EQ_AV -1 LastMouseX
       # No result
       @PUSH 0
    @ELSE
       @PUSH 1
    @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
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
    @PTR_AT ActiveEventTable EventTableHeaderSize @POPI Base
    @ForIV2A Rec MTSize 0
       # Skip any non-mouse event
       @GET_FROM Base EventTypeOff
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
                 @GET_FROM Base EventIDOff
                 @POPI Result
                 @PUSHI MTSize @SUB 1 @POPI Rec # Break For
             @ELSE
                 @POPNULL
             @ENDIF
          @ELSE
             @POPNULL
          @ENDIF
      @ENDIF      
      @PTR_AT Base EventRecordSize @POPI Base
   @NextBy Rec -1
   @IF_EQ_AV -1 Result
      @PUSH 0      # Return null if no match
   @ELSE
      @PUSHI Result
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

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
@ENDFUNCTION

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
@Local FirstKey
@Local LastKey
@Local Rec
@Local Result
@Local Type
@POPI CHR
   @MA2V -1 Result
   @PUSHII ActiveEventTable @POPI MTSize
   @PTR_AT ActiveEventTable EventTableHeaderSize @POPI Base

   @ForIV2A Rec MTSize 0
      @GET_FROM Base EventTypeOff
      @POPI Type
      @PUSHI Type
      @SWITCH
      @CASE KeyEvent
         # Mapped String Event
         @POPNULL
         @GET_FROM Base EventExOneOff
         @POPI InPtr
         
         @PUSHI InPtr
         @PUSHI CHR
         @CALL FindCh
         
         @IF_NOTZERO
            @POPI LastKeyMatchPtr
            
            @PUSHI CHR
            @AND 0xff
            @POPI LastKeyChar
            
            @MA2V 1 LastKeyLen
            
            @GET_FROM Base EventIDOff
            @POPI Result
            
            @PUSHI MTSize
            @SUB 1
            @POPI Rec
         @ELSE
            @POPNULL
         @ENDIF
         @CBREAK
      @CASE KeyRangeEvent
         # ASCII Range Inclusive event
         # Normalize CHR to be 8 bit
         @PUSHI CHR
         @AND 0xff
         @POPI CHR

         @GET_FROM Base KeyASCIIStartOff
         @POPI FirstKey
         @GET_FROM Base KeyASCIIEndOff
         @POPI LastKey

         @Between_U CHR FirstKey LastKey
         @IF_NOTZERO
            @POPNULL

            @PUSHI CHR
            @AND 0xff
            @POPI LastKeyChar

            @MA2V 1 LastKeyLen
            @MA2V 0 LastKeyMatchPtr

            @GET_FROM Base EventIDOff
            @POPI Result

            @PUSHI MTSize
            @SUB 1
            @POPI Rec
         @ELSE
            @POPNULL
         @ENDIF
         @CBREAK
      @CDEFAULT
#         @POPNULL
         @CBREAK
      @ENDCASE
      @POPNULL
   @PTR_AT Base EventRecordSize
   @POPI Base
   
   @NextBy Rec -1
   
   @IF_EQ_AV -1 Result
      @PUSH 0
   @ELSE
      @PUSHI Result
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

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
   @GET_FROM ActiveEventTable EventUsedHeadOff @POPI MTSize
   @PTR_AT ActiveEventTable EventTableHeaderSize @POPI Base
   @ForIV2A Rec MTSize 0
       @GET_FROM Base EventTypeOff
       @IF_NEQ_A TimerEvent
          @POPNULL
       @ELSE
          @POPNULL
          @GET_FROM Base TimerDurOff @POPI Dur
          @IF_EQ_AV 0 Dur
             # Do Nothing.
          @ELSE

             @GET_FROM Base TimerStartOff @POPI Start
             @GET_FROM Base TimerRepOff @POPI Rep
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
                @GET_FROM Base EventIDOff @POPI Result
                @IF_EQ_AV 0 Rep
                    # One Time timer, mark as disabled.
                    @FILL_AT_A Base EventTypeOff 0
                    @MA2V 0 LastTimeRep
                @ELSE
                   # periodic: advance Start forward by k*Dur past Now
                   # while Elap >= Dur: Start += Dur; Elap -= Dur
                   # This allows events to more closely match real time incriments.
                   @MA2V 1 LastTimeRep
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
                   @FILL_AT_V Base TimerStartOff Start
                @ENDIF
                @PUSHI MTSize @SUB 1 @POPI Rec # Break Outer loop
             @ELSE
                @POPNULL
             @ENDIF
         @ENDIF
     @ENDIF
     @PTR_AT Base EventRecordSize @POPI Base
  @NextBy Rec -1


  @IF_EQ_AV -1 Result
     @PUSH 0
  @ELSE
     @PUSHI Result
  @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

########################################
# Function: TermInputPoll():InputType
#
# Reads at most one new terminal input item.
#
# Returns:
#   0          No input available
#   KeyEvent   Keyboard byte(s) queued
#   MouseEvent Mouse metadata updated
#
@FUNCTION TermInputPoll
:TermInputPoll
@PUSHRETURN
@Locals
   @Local RawCh
   @Local NextCh
   @Local ThirdCh
   @Local InputType

   @MA2V 0 InputType

   @CALL ReadKeyTimeOut
   @POPI RawCh

   @IF_EQ_AV 0 RawCh
      # No input available.

   @ELSE
      @IF_EQ_AV "\e\0" RawCh
         # ESC can be a standalone key or the start of an ANSI sequence.
         @CALL ReadKeyTimeOut
         @POPI NextCh

         @IF_EQ_AV 0 NextCh
            # Nothing followed ESC immediately.
            # Treat it as a standalone Escape key.
            @Call(A) KeyEnQueue "\e\0"
            @MA2V KeyEvent InputType

         @ELSE
            @IF_EQ_AV "[\0" NextCh
               # CSI sequence: ESC [
               @CALL ReadKeyTimeOut
               @POPI ThirdCh

               @IF_EQ_AV "<\0" ThirdCh
                  # SGR mouse sequence: ESC [ <
                  #
                  # Current KeyReadMouseSeq interface returns:
                  #     X, Y, Status
                  @CALL KeyReadMouseSeq

                  @IF_NOTZERO
                     @MA2V MouseEvent InputType
                  @ENDIF
                  @POPNULL       # Status
               @ELSE
                  # Not a mouse CSI sequence.
                  # Preserve all bytes for keyboard processing.
                  @Call(A) KeyEnQueue "\e\0"

                  @Call(A) KeyEnQueue "[\0"

                  @Call(V) KeyEnQueue ThirdCh

                  @MA2V KeyEvent InputType
               @ENDIF

            @ELSE
               # ESC followed by a non-CSI byte.
               # Preserve both bytes.
               @Call(A) KeyEnQueue "\e\0"

               @Call(V) KeyEnQueue NextCh

               @MA2V KeyEvent InputType
            @ENDIF
         @ENDIF

      @ELSE
         # Ordinary keyboard byte.
         @Call(V) KeyEnQueue RawCh
         @MA2V KeyEvent InputType
      @ENDIF
   @ENDIF

   @PUSHI InputType

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

########################################
# Function: EventDispatch(InputType):(EventID,MatchedType)
#
# InputType:
#   0          No newly decoded input
#   KeyEvent   Keyboard bytes may be queued
#   MouseEvent Mouse metadata contains a decoded mouse event
#
# Returns:
#   EventID     Application-defined event ID, or 0
#   MatchedType MouseEvent, KeyEvent, TimerEvent, or 0
#
@FUNCTION EventDispatch
:EventDispatch
@PUSHRETURN
@Locals
   @Local InputType
   @Local Result
   @Local MatchedType
   @Local QueueSize

   @POPI InputType

   @MA2V 0 Result
   @MA2V 0 MatchedType

   ####################################
   # Mouse input has first priority.
   @IF_EQ_AV MouseEvent InputType
      @PUSHI LastMouseX
      @PUSHI LastMouseY
      @CALL KeySearchMouse
      @POPI Result

      @IF_NEQ_AV 0 Result
         @MA2V MouseEvent MatchedType
      @ENDIF
   @ENDIF

   ####################################
   # If mouse did not match, process one queued keyboard byte.
   #
   # Check the queue regardless of InputType. A prior CSI sequence
   # may have left additional bytes queued for later polls.
   @IF_EQ_AV 0 Result
      @CALL KeyQueueSize
      @POPI QueueSize

      @IF_NEQ_AV 0 QueueSize
         @CALL KeyDeQueue
         @CALL KeySearchKeyBoard
         @POPI Result

         @IF_NEQ_AV 0 Result
            @MA2V KeyEvent MatchedType
         @ENDIF
      @ENDIF
   @ENDIF

   ####################################
   # If no input event matched, check timers.
   #
   # This prevents unmatched keyboard input from starving timers.
   @IF_EQ_AV 0 Result
      @CALL KeySearchTimer
      @POPI Result

      @IF_NEQ_AV 0 Result
         @MA2V TimerEvent MatchedType
      @ENDIF
   @ENDIF

   # Return EventID followed by MatchedType.
   @PUSHI Result
   @PUSHI MatchedType

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

########################################
# Function: EventPoll():EventID
#
# Coordinates terminal input, event dispatch, and common metadata.
#
@FUNCTION EventPoll
:EventPoll
@PUSHRETURN
@Locals
   @Local InputType
   @Local Result
   @Local MatchedType
   @Local EventCount

   @MA2V 0 InputType
   @MA2V 0 Result
   @MA2V 0 MatchedType

   ####################################
   # No table means there is nothing to poll.
   @IF_EQ_AV 0 ActiveEventTable
      @JMP EventPollDone
   @ENDIF

   ####################################
   # Do not consume terminal input when the table has no events.
   @GET_FROM ActiveEventTable EventUsedHeadOff
   @POPI EventCount

   @IF_EQ_AV 0 EventCount
      @JMP EventPollDone
   @ENDIF

   ####################################
   # Decode at most one new terminal input item.
   @CALL TermInputPoll
   @POPI InputType

   ####################################
   # Match decoded/queued input or an expired timer.
   @PUSHI InputType
   @CALL EventDispatch

   # EventDispatch returns EventID, MatchedType.
   @POPI MatchedType
   @POPI Result

   ####################################
   # Update common metadata only when an event matched.
   @IF_NEQ_AV 0 Result
      @MV2V Result LastEventID
      @MV2V MatchedType LastEventType

      # GETTIME  return Low,High with High on TOS.
      @GETTIME
      @POPI LastEventTSHi
      @POPI LastEventTSLo
   @ENDIF

:EventPollDone
   @PUSHI Result

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

########################################
# Function: EventPoll:EventID
# Mouse Event.
@FUNCTION EventPoll
:EventPoll_OLD
@PUSHRETURN
@Locals
   @Local MouseXVal
   @Local MouseYVal
   @Local MouseEventCode
   @Local Result
   @Local MatchedType
   
   # Fast exit if there nothing in ActiveEventTable to search for.
   @MA2V 0 Result
   @MA2V 0 MatchedType
   @MA2V 0 MouseEventCode

   @IF_NEQ_AV 0 ActiveEventTable
     @GET_FROM ActiveEventTable EventUsedHeadOff
     @IF_NOTZERO
        @POPNULL
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
                         @POPNULL
                         @POPI MouseYVal
                         @POPI MouseXVal
                         @MA2V MouseEventDetected MouseEventCode      # Flags that there is a mouse event to check
                         # If Mouse sequence was invalid, leaves 0 on stack.
                         @MV2V MouseEventCode Result
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
          @CALL KeyDeQueue
          @CALL KeySearchKeyBoard
      @ENDIF
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
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
   @PUSHI ActiveEventTable @ADD EventTableHeaderSize @POPI Base

   @PRTNL
   @PRT "ActiveEventTable (" @PRTHEXI MTSize @PRT " records)" @PRTNL

   @ForIA2V Index 0 MTSize
      # Decode min/max coords
      @ExtractXMin Base @POPI X1
      @ExtractYMin Base @POPI Y1
      @ExtractXMax Base @POPI X2
      @ExtractYMax Base @POPI Y2

      # EventID
      @GET_FROM Base EventIDOff @POPI EventID

      # Type
      @GET_FROM Base EventTypeOff @POPI Type

      # Print line
      @PRT "Event:ID=" @PRTHEXI EventID
      @PRT " T=" @PRTHEXI Type
      @PRT " X1=" @PRTHEXI X1
      @PRT " Y1=" @PRTHEXI Y1
      @PRT " X2=" @PRTHEXI X2
      @PRT " Y2=" @PRTHEXI Y2
      @PRTNL

      # Next record
      @PTR_AT Base EventRecordSize @POPI Base      
   @Next Index

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
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
