! MOUSELIBSEEN
#L string.ld
M MouseLibSeen 1
G MouseInit G KeyEnQueue G KeyDeQueue G KeyQueueSize G KeyReadMouseSeq G KeySearchMouse
G KeySearchKeyBoard G KeySearchTimer G MouseDisable G MouseAddEvent G ReadKeyTimeOut
G MouseEventLoop G CSICODE
########################################
# Event Meta Data Struture:
# While EventLoop returns an EventID, the extra informaton learned about events is stored here.
#
# Globablize all the Meta data values for recall
G LastEventType G LastEventID G LastEventTSLo G LastEventTSHi G LastMouseX
G LastMouseY G LastMouseBtn G LastMouseFlags G LastMouseRawB G LastMouseTerm
G MF_PRESS G MF_RELEASE G MF_DRAG G MF_WHEEL G MF_SHIFT G MF_ALT G MF_CTRL
G LastKeyMatchPtr G LastKeyLen G LastKeyChar G LastTimerDur G LastTimeRep
G LastTimerELap G LastTimerSkip G MouseEvent G TimerEvent G KeyEvent
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
=MF_PRESS   0x0001
=MF_RELEASE 0x0002
=MF_DRAG    0x0004
=MF_WHEEL   0x0008
=MF_SHIFT   0x0010   # SGR adds 4 to b for shift
=MF_ALT     0x0020   #   ... 8 for meta/alt
=MF_CTRL    0x0040   #   ... 16 for ctrl
=MouseEvent 1
=TimerEvent 2
=KeyEvent 3

#   Keyboard Meta Data
:LastKeyMatchPtr 0
:LastKeyLen 0
:LastKeyChar 0          # Only for single byte keyboard events.
#   Timer Metadata
:LastTimerDur 0         # Seconds of Duraction based on request
:LastTimeRep  0         # 0/1 if it was set to auto repeat
:LastTimerELap 0        # Elapsed file time (real vs requested duration)
:LastTimerSkip 0        # How many periods where skipped this poll

########################################
# function: MouseInit(HeapID)
:MouseInit
@PUSHRETURN
@LocalVar HeapID 01
#
@POPI HeapID
   @IF_EQ_AV 0 MouseTable
      # Define MouseTable
      # MouseTable[0:1] = MouseTableSize
      # MouseTable[2:3] = MaxUsedTableSize (tells when we need to resize)
      # MouseTable[4:5] = Backup copy of HeapID for destory or resize events
      # Real table data will tart at MouseTable[6:]
      =MouseRecordSize 12
      =MouseTableHeaderSize 6
      =MouseMaxUsedHeadOff 2
      =MouseBackupHeapOff 4
      =EventMaxLocOff 2
      =EventIDOff 4
      =EventTypeOff 6
      =EventExOneOff 8
      =EventExTwoOff 10
      =TimerStartOff 0
      =TimerDurOff 8
      =TimerRepOff 10
      @PUSHI HeapID @PUSH MouseRecordSize+MouseTableHeaderSize
      @CALL HeapNewObject  @IF_ULT_A 100 @PRT "Memory Error 330" @END @ENDIF
      @POPI MouseTable
      @PUSH 1 @PUSHI MouseTable @ADD MouseMaxUsedHeadOff @POPS   # Sets allocated rows in table
      @PUSHI HeapID @PUSHI MouseTable @ADD MouseBackupHeapOff @POPS  # Saves HeapID for later resizes.
      @PUSH 0 @POPI QBufferHead       # Clear out Queue
   @ENDIF
   @PUSH 0 @POPII MouseTable  # Zeros out number active rows.
   @PRTS CSICODE @PRT "?1000h"
   @PRTS CSICODE @PRT "?1006h"
@RestoreVar 01
@POPRETURN
@RET
:MouseTable 0         # only one word store used if mouse functions never initilzied.
# Structures
# Offset          Field
# 0               MinLoc(X1,Y1<<8)
# 2               MaxLoc(X2,Y2<<8)
# 4               EventID
# 6               EventType (1:mouse,2:Key,3:Timer)
# 8               EventExOneOff Timer Counter or Str Ptr
# 10              EventExTwoOff Timer Max Value
########################################
# Function: MouseDisable()
:MouseDisable
@PRTS CSICODE @PRT "?1000l"
@PRTS CSICODE @PRT "?1006l"
@RET
#######################################
# Macros for MouseAddEvent
# Ensures (%1, %2) such that %1 <= %2 Both must be variable lables, not constants.
M QuickMinI @PUSHI %1 @PUSHI %2 @IF_GT_S @SWP @POPI %2 @POPI %1 @ELSE @POPNULL @POPNULL @ENDIF
#
# Combines 1,2 into word so %1 is high byte and %2 is low.
M EncodeLoc @PUSHI %1 @SHL @SHL @SHL @SHL @SHL @SHL @SHL @SHL @PUSHI %2 @AND 0xff @ORS


########################################
# Function: MouseAddEvent(Type,X1,Y1,X2,Y2,EventID)
#
#
:MouseAddEvent
@PUSHRETURN
@LocalVar Type 01       # 1 = mouse, 2 = timer, 3 = Keyboard
@LocalVar X1 02         # Mouse: X1, Timer: Max Seconds, Keyboard:StrPtr(In)
@LocalVar Y1 03         # Mouse: Y1, Timer: 0|1 del:repeat
@LocalVar X2 04         # Mouse: X2  Timer: NR, KeyBoard: NR
@LocalVar Y2 05         # Mouse: Y2
@LocalVar EventID 06
@LocalVar Index1 07
@LocalVar MAESize 08
@LocalVar MAEMaxSize 09
@LocalVar MTHeapID 10
@LocalVar Index2 11
@LocalVar InsertSpot 12
#
@POPI EventID @POPI Y2 @POPI X2 @POPI Y1 @POPI X1 @POPI Type
    # Extract table header data
    @PUSHI MouseTable @PUSHS @POPI MAESize                  # Current Number of used records
    @PUSHI MouseTable @ADD MouseMaxUsedHeadOff @PUSHS @POPI MAEMaxSize # Max possible without resize
    @PUSHI MouseTable @ADD MouseBackupHeapOff @PUSHS @POPI MTHeapID    # HeapID for resizeing
    @PUSHI MouseTable @ADD MouseTableHeaderSize @POPI Index1           # First Record after headers
    #
    # See if EventID exists already, which case this is a replace.
    @MA2V -1 InsertSpot   # For cases with no matching EventID
    @ForIA2V Index2 0 MAESize
        @PUSHI Index1 @ADD EventIDOff @PUSHS   # EventID
        @IF_EQ_V EventID
           # Exact match
           @MA2V Index1 InsertSpot
           @FORBREAK         # Note this only works because IF is 'top' level in loop
        @ELSE
           @PUSHI Index1 @ADD MouseRecordSize @POPI Index1   # Move to next Entry
        @ENDIF
    @Next Index2
    @IF_EQ_AV -1 InsertSpot
       # Never found so create new entry.
       @IF_EQ_VV MAESize MAEMaxSize
           # Time to expand the table with HeapResize
           @PUSHI MTHeapID
           @PUSHI MouseTable
           @PUSHI MAEMaxSize       # Need to turn max size into bytes in table space.
           @ADD 10                # Allocate 10 new cells for growth.
           @PUSH MouseRecordSize
           @CALL MUL              # Multiply
           @ADD MouseTableHeaderSize     # Add the Header part.
           @CALL HeapResizeObject
           @IF_ULT_A 100
               @PRT "Error Can not allocate memory for mouse table growth."
               @END
           @ENDIF
           @POPI MouseTable
           @PUSHI MAEMaxSize @ADD 10     # Reset Max size record to new size
           @PUSHI MouseTable @ADD MouseMaxUsedHeadOff @POPS  # Writes new max size
           #
       @ENDIF
       @PUSHI MAESize @PUSH MouseRecordSize @CALL MUL @ADDI MouseTable
       @ADD MouseTableHeaderSize @POPI InsertSpot
       @INCI MAESize
       @PUSHI MAESize @PUSHI MouseTable  @POPS # Save it in header First record is used record count.
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
   @CASE MouseEvent # mouse
      # Mouse
      # Quick function to swap variable values to V1 will be < V2
      @QuickMinI X1 X2
      @QuickMinI Y1 Y2
      #
      @EncodeLoc X1 Y1
      @PUSHI InsertSpot @POPS           # InsertSpot[0,1] = MinLoc
      @EncodeLoc Y2 X2
      @PUSHI InsertSpot @ADD EventMaxLocOff  @POPS    # Save to InsertSpot[2,3]
      @PUSHI EventID @PUSHI InsertSpot @ADD EventIDOff  @POPS    # InsertSpot[4,5]=EvenID
      @PUSHI Type @PUSHI InsertSpot @ADD EventTypeOff @POPS       # InsertSpot[6,7]=Type
      # For mouse EventData1/2 are not used.
      @CBREAK
   @CASE KeyEvent # KeyBoard
      # KeyBoard Event   
      # X1 = StrPtr to string listing what to key eye out for. Keys that do not match will be ignored.
      # Y1 = StrPtr value of character key that triggered event.
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
@RestoreVar 12 @RestoreVar 11 @RestoreVar 10 @RestoreVar 09 @RestoreVar 08
@RestoreVar 07 @RestoreVar 06 @RestoreVar 05 @RestoreVar 04 @RestoreVar 03
@RestoreVar 02 @RestoreVar 01
@POPRETURN
@RET
#########################################
# Function ReadKeyTimeOut
# Polls for next character but also times out if not seen in 10 cycles
:ReadKeyTimeOut
@PUSHRETURN
@LocalVar CHin   01
   @PUSH 0
   @WHILE_LT_A 10
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
@RestoreVar 01
@POPRETURN
@RET
########################################
#
:KeyBuffer 0 0 0 0 # 8 byte buffer
0 0 0 0 0 0 0 0 0 0 0 0 0 0
:QBufferHead $$0
:QBufferTail $$0
=KQ_MASK 0x1f
# Set 16 words => 32 bytes + 1b for high byte of 32nd entry
:QBuffer 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 $$0
########################################
# Funtion KeyEnQueue(ch)
:KeyEnQueue
@PUSHRETURN
@LocalVar Head 01
@LocalVar Tail 02
@LocalVar NextTail 03
@LocalVar ChIN 04
@LocalVar Address 05
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
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
########################################
# Function KeyQueueSize()
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

#########################################
# Function KeyDeQueue
:KeyDeQueue
@PUSHRETURN
@LocalVar Head 01
@LocalVar Tail 02
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
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

########################################
# Function: KeyReadMouseSeq():(x,y)
# Only handles the <ESC>[<btn;XVal;YValM mouse events.
# Mouse and screen events are 1 base, meaning upper left is 1,1 not 0,0
:KeyReadMouseSeq
@PUSHRETURN
@LocalVar ChIN 01
@LocalVar CurVal 02
    @MA2V 0 LastMouseX
    @MA2V 0 LastMouseY
    @MA2V 0 CurVal
    @MA2V -1 LastMouseRawB
    @PUSH 0
    @WHILE_ZERO
       @POPNULL
       @CALL ReadKeyTimeOut  @AND 0xff
       @PRT "."
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
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
############################################
# Helper Macros for the MouseTable Search functions
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
:KeySearchMouse
@PUSHRETURN
@LocalVar X1 01
@LocalVar Y1 02
@LocalVar MTSize 03
@LocalVar Base 04
@LocalVar Rec 05
@LocalVar MinX 06
@LocalVar MinY 07
@LocalVar MaxX 08
@LocalVar MaxY 09
@LocalVar Result 10

@POPI Y1
@POPI X1
    @MA2V -1 Result
    @PUSHII MouseTable @POPI MTSize
    @PUSHI MouseTable @ADD MouseTableHeaderSize @POPI Base
    @ForIA2V Rec 0 MTSize
       # Skip any non-mouse event
       @PUSHI Base @ADD EventTypeOff @PUSHS
       @IF_NEQ_A MouseEvent
          @POPNULL
       @ELSE
          @POPNULL
          @ExtractXMin Base @POPI MinX   #Min X
          @ExtractYMin Base @POPI MinY  #Min Y
          @ExtractXMax Base @POPI MaxX  #Max X
          @ExtractYMax Base @POPI MaxY  #Max Y
#          @PRT "Is " @PRTI X1 @PRT "," @PRTI Y1 @PRT " Between X:" @PRTI MinX @PRT " - " @PRTI MaxX @PRT " and Y: " @PRTI MinY @PRT " - " @PRTI MaxY @PRTNL
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
      @PUSHI Base @ADD MouseRecordSize @POPI Base
   @Next Rec
   @IF_EQ_AV -1 Result
      @PUSH 0      # Return null if no match
   @ELSE
      @PUSHI Result
   @ENDIF
@RestoreVar 10
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

########################################
# Function FindCh(String,Char):(0|Ptr)
# Retirs ptr to where in String Char is, or 0
:FindCh
@PUSHRETURN
@LocalVar Index1 01
@LocalVar CharIn 02
@LocalVar StringPtr 03
@LocalVar Result 04
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
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

########################################
# Function: KeySearchKeyBoard(ch) -> EventID|0
:KeySearchKeyBoard
@PUSHRETURN
@LocalVar CH     01
@LocalVar MTSize 02
@LocalVar Base   03
@LocalVar InPtr  04
@LocalVar C      05
@LocalVar Rec    06
@LocalVar Result 07
@POPI CH
   @MA2V -1 Result
   @PUSHII MouseTable @POPI MTSize
   @PUSHI MouseTable @ADD MouseTableHeaderSize @POPI Base
   @ForIA2V Rec 0 MTSize
      @PUSHI Base @ADD EventTypeOff @PUSHS
      # Skip non keyboard events
      @IF_NEQ_A KeyEvent
          @POPNULL
      @ELSE
         @POPNULL
         @PUSHI Base @ADD EventExOneOff @PUSHS @POPI InPtr
         @PUSHI InPtr
         @PUSHI CH
         @CALL FindCh
         @IF_NOTZERO
            @POPI LastKeyMatchPtr
            @MV2V CH LastKeyChar
            # Input Matches Event
            @PUSHI Base @ADD EventIDOff @PUSHS
            @POPI Result
            @PUSHI MTSize @SUB 1 @POPI Rec # Break For loop
         @ELSE
            @POPNULL
         @ENDIF
      @ENDIF
      @PUSHI Base @ADD MouseRecordSize @POPI Base
   @Next Rec
   @IF_EQ_AV -1 Result
      @PUSH 0
   @ELSE
      @PUSHI Result
   @ENDIF
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

##############################################
# Function: KeySearchTimer() -> EventID | 0
:KeySearchTimer
@PUSHRETURN
@LocalVar MTSize 01
@LocalVar Base   02
@LocalVar Rec    03
@LocalVar Start  04
@LocalVar Dur    05
@LocalVar Rep    06
@LocalVar Now    07
@LocalVar Elap   08
@LocalVar Result 09
   @MA2V -1 Result
   @PUSHI MouseTable @PUSHS @POPI MTSize
   @PUSHI MouseTable @ADD MouseTableHeaderSize @POPI Base
   @ForIA2V Rec 0 MTSize
       @PUSHI Base @ADD EventTypeOff @PUSHS
       @IF_NEQ_A TimerEvent
          @POPNULL
       @ELSE
          @POPNULL
          @PUSHI Base @ADD TimerDurOff  @PUSHS @POPI Dur
          @IF_EQ_AV 0 Dur
             # Do Nothing.
          @ELSE
             @POPNULL
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
                   @PUSH 0
                   @MA2V 0 LastTimerSkip
                   @WHILE_ZERO
                      @POPNULL
                      @PUSHI Dur
                      @IF_ULE_V Elap
                          @POPNULL
                          @PUSHI Start @ADDI Dur @POPI Start
                          @PUSHI Elap @SUBI Dur @POPI Elap
                          @PUSH 0
                          @INCI LastTimerSkip
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
     @PUSHI Base @ADD MouseRecordSize @POPI Base
  @Next Rec
  @IF_EQ_AV -1 Result
     @PUSH 0
  @ELSE
     @PUSHI Result
  @ENDIF
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


########################################
# Function: MouseEventLoop:EventID
# Mouse Event.
:MouseEventLoop
@PUSHRETURN
@LocalVar MouseXVal 01
@LocalVar MouseYVal 02
@LocalVar MouseEventCode 03

   # Fast exit if there nothing in MouseTable to search for.
   @PUSHI MouseTable @PUSHS
   @MA2V 0 MouseEventCode
   @IF_ZERO
      # nothing to do, just exit with zero as event id.
   @ELSE
      @TTYNOECHO
      # We start At StateIdle
      @POPNULL
      # Setup flags and state
#      @READCNW KeyBuffer
      @CALL ReadKeyTimeOut
#      @STRSET "\e[0;10;10M" KeyBuffer
      @IF_EQ_A 0
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
                       @MA2V 1 MouseEventCode      # Flags that there is a mouse event to check
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
      @IF_EQ_AV 1 MouseEvent
          @PUSHI MouseXVal @PUSHI MouseYVal
          @CALL KeySearchMouse
      @ENDIF

      # After Mouse events, check for Keyboard events.
      #
      @CALL KeyQueueSize
      @IF_ZERO
        # That will also be our result.
        @POPNULL
      @ELSE
        # Not zero there is a key to deal with.
        @POPNULL
        @CALL KeyDeQueue
        @CALL KeySearchKeyBoard
      @ENDIF
      # After Keyboard check Timer events
      @CALL KeySearchTimer
   @ENDIF
   @TTYECHO
 @RestoreVar 03
 @RestoreVar 02
 @RestoreVar 01
 @POPRETURN
 @RET

M SIZESINCECOMMENT mouse.ld
@SIZESINCE
ENDBLOCK
