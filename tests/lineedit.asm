I common.mc
L screen.ld
L string.ld
L softstack.ld
L heapmgr.ld
#M DEBUG 1
M LocalVar = %1 Var%2 @PUSHLOCALI Var%2
M RestoreVar @POPLOCAL Var%1
M StatusPrint @PUSH 1 @PUSH 23 @CALL WinCursor
#################################################
# Shared Variables
:Var01 0 :Var02 0 :Var03 0 :Var04 0 :Var05 0 :Var06 0 :Var07 0 :Var08 0 :Var09 0
:Var10 0 :Var11 0 :Var12 0 :Var13 0 :Var14 0 :Var15 0 :Var16 0
##################################################
# Function SimRead
# EachCall will send next byte in message until null.
:SimIndex 0
:SimData "abcde" $$8 "END" $$10 $$13 0 0 
:SimRead
@PUSH SimData
@ADDI SimIndex
@PUSHS
@AND 0xff
@INCI SimIndex
@SWP
@RET



#
#
##################################################
# Function: VisReadLine(Flag,X,Y,Width,VWidth,Cursor,Buffer):ExitCode
:VisReadLine
@PUSHRETURN
@LocalVar InFlag 01           # Controls behavior
@LocalVar InX 02              # X location on screen where leftmost part of field starts.
@LocalVar InY 03              # Y Location on screen where field starts
@LocalVar InWidth 04          # Limit on Buffer size.
@LocalVar VWidth 05           # Limit on how much of buffer to show. (Window on buffer)
@LocalVar InCursor 06         # If Buffer already has content, where does cursor start can be > VWidth
@LocalVar InBuffer 07         # The Buffer for this line
@LocalVar Pos 08              # Current Potion in the buffer
@LocalVar ScreenStart 09      # First character visible on screen
@LocalVar Length 10           # Current text length
@LocalVar UChar 11            # Input Character
@LocalVar UOver 12
@LocalVar ExitCode 13         # Code to use when time to exit
@LocalVar NeedDraw 14         # Set to 1 when Redraw is needed.
@LocalVar MaxLen 15
#
@POPI InBuffer
@POPI InCursor
@POPI VWidth
@POPI InWidth
@POPI InY
@POPI InX
@POPI InFlag
#
@MV2V InCursor Pos
@MA2V 0 ScreenStart
@MA2V -1 ExitCode
@PUSHI InBuffer @CALL strlen @POPI Length
@MV2V Length MaxLen

@PUSHI VWidth
@IF_LT_A 2
   @PRT "The Smallest buffer allowd is 2 bytes"
@ENDIF
@POPNULL

#
# Flag values
#  bit     Effect
#  0       1:Clear InBuffer 0: Preserve value
#  10      TBD
#  100     1:Exit On UDArrow 0: Ignore up/down arrow
#  1000    1:Exit On any CTRL 0: Ctrl codes used for editing.
#
#
@PUSHI InFlag @AND 0b1
@IF_NOTZERO
   # Flat Bit 0, clear buffer on entry
   @PUSH 0 @POPII InBuffer
@ENDIF
@POPNULL
#
# Display inital buffer if any
@PUSHI InX @PUSHI InY
@PUSHI InBuffer @ADDI ScreenStart
@PUSHI VWidth
@PUSHI Pos @SUBI ScreenStart
@CALL UpdateScreen
@MA2V 0 NeedDraw
#
#
@PUSH 1
@TTYNOECHO
@WHILE_NOTZERO
   @READC UChar
   # Check for Arrow Key codes.
   @PUSHI UChar
   @IF_EQ_A 0x5b1b       # <ESC>[ 2 letter code.
      # We are dealing with 3 byte codes for the arrow keys
      @POPNULL
      @PUSHI UOver
      @SWITCH
      @CASE "A\0"       # Up Arrow (Worth Nothing we zero term the mini string, due to 16 bit rules.)
         @MA2V 0x10 UChar
         @CBREAK
      @CASE "B\0"      # Down Arrow
         @MA2V 0xe UChar
         @CBREAK
      @CASE "C\0"      # Right Arrow
         @MA2V 0x6 UChar
         @CBREAK
      @CASE "D\0"      # Left Arrow
         @MA2V 02 UChar 
         @CBREAK
      @CDEFAULT
         @MA2V 0 UChar    # Null it out for other escape codes
         @CBREAK
      @ENDCASE
      @POPNULL
      @PUSHI UChar
   @ENDIF
   @IF_EQ_A 0x7f
      @POPNULL
      @PUSH 0x8
   @ENDIF
   @IF_EQ_A 0xd
      @POPNULL
      @PUSH 0xa
   @ENDIF   
   @SWITCH
   @CASE 0xa             # LF
       @MV2V 1 ExitCode
       @MA2V 1 NeedDraw       
       @JMP KeyExit
       @CBREAK
   @CASE 0x8             # BS
       @PUSHI Pos
       @IF_GT_A 0
          @PUSHI InBuffer @PUSHI Pos @SUB 1 @PUSHI Length @PUSHI InWidth
          @CALL RemoveChar
          @POPI Length
          @DECI Pos
          @DECI MaxLen
       @ENDIF
       @POPNULL
       @MA2V 1 NeedDraw
       @CBREAK
   @CASE_RANGE 32 127
       @PUSHI Length
       @PUSHI InWidth @SUB 1
       @IF_LT_S
          @POPNULL @POPNULL
          @PUSHI InBuffer @PUSHI Pos @PUSHI UChar @PUSHI Length @PUSHI InWidth
          @CALL InsertChar
          @POPI Length
          @INCI Pos
       @ELSE
          @POPNULL @POPNULL
       @ENDIF
       @PUSHI Pos
       @IF_GT_V MaxLen
          @MV2V Pos MaxLen
       @ENDIF
       @POPNULL
       @MA2V 1 NeedDraw              
       @CBREAK
   @CASE 0x2            # Left Arrow
       @PUSHI Pos
       @IF_GT_A 0
          @DECI Pos          
       @ENDIF
       @POPNULL
       @MA2V 1 NeedDraw              
       @CBREAK
   @CASE 0x6            # Right Arrow
       @PUSHI Pos
       @IF_LT_V Length
          @INCI Pos
       @ENDIF
       @POPNULL
       @MA2V 1 NeedDraw              
       @CBREAK
   @CASE 0x10           # Uparrow
       @PUSHI InFlag
       @AND 0x4         # Flag bit 4 exit on up/down arrow
       @IF_NOTZERO
          @POPNULL
          @POPNULL
          @MA2V 1 ExitCode
          @JMP KeyExit
       @ENDIF
       @POPNULL       
       @MA2V 1 NeedDraw              
       @CBREAK
   @CASE 0x0e          # Down Arrow
       @PUSHI InFlag
       @AND 0x4         # Flag bit 4 exit on up/down arrow
       @IF_NOTZERO
          @POPNULL
          @POPNULL
          @MA2V 1 ExitCode
          @JMP KeyExit
       @ENDIF
       @POPNULL       
       @MA2V 1 NeedDraw              
       @CBREAK
   @CASE 0xc           # Ctl-L Redraw
       @MA2V 1 NeedDraw
       @CBREAK
   @CASE 0x1           # Ctl-A Home
       @MA2V 1 NeedDraw
       @MA2V 0 Pos
       @CBREAK
   @CASE 0x5
       @MA2V 1 NeedDraw   
       @MV2V Length Pos
       @CBREAK
   @CASE_RANGE 1 32
       @PUSHI InFlag
       @AND 0x8
       @IF_NOTZERO
          @POPNULL
          @POPNULL
          @MA2V 1 ExitCode
          @JMP KeyExit
       @ENDIF
       @POPNULL
       @MA2V 1 NeedDraw
       @CBREAK
   @CASE 0
       @POPNULL
       @CBREAK
   @CDEFAULT
       # Invalid character, just ignore.
       @PRT "\nInvalid"
       @CBREAK
   @ENDCASE
   @POPNULL
   @IF_EQ_AV 0 UChar
   @ELSE
#      @PUSH 30 @PUSH 9 @CALL WinCursor @StackDump   
   @ENDIF
   # Handle Line/Screen Scrolling
   @PUSHI Pos
   @PUSHI ScreenStart
   @IF_LT_S
      @MV2V Pos ScreenStart
   @ELSE
      @ADDI VWidth
      @IF_GE_S
         @PUSHI Pos @SUBI VWidth @ADD 1
         @POPI ScreenStart
      @ENDIF
   @ENDIF
   @POPNULL   @POPNULL
   # Display Screen
   @IF_EQ_AV 0 NeedDraw
   @ELSE
      @PUSHI InX @PUSHI InY
      @PUSHI InBuffer @ADDI ScreenStart
      @PUSHI VWidth
      @PUSHI Pos @SUBI ScreenStart
      @CALL UpdateScreen
      @MA2V 0 NeedDraw
   @ENDIF
   #
   # This is to skip over the KeyExit Code.
   @IF_EQ_AV -1 ExitCode      
   @ELSE
      :KeyExit
      @PUSHI Pos
      @PUSHI UChar
      @PUSH 0
      @PUSHI  InBuffer @ADDI MaxLen
      @DUP
      @PUSHS @AND 0x00ff
      @SWP @POPS
   @ENDIF
@ENDWHILE
@POPNULL
@RestoreVar 15
@RestoreVar 14
@RestoreVar 13
@RestoreVar 12
@RestoreVar 11
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


#
####################################################
# Function RemoveChar(Buffer, Index,Length, MaxWidth):Length
# Removes one character from buffer
:RemoveChar
@PUSHRETURN
@LocalVar Buffer 01
@LocalVar Index 02
@LocalVar MaxWidth 03
@LocalVar Length 04
@LocalVar ICnt 05
#
@POPI MaxWidth
@POPI Length
@POPI Index
@POPI Buffer
@IF_EQ_AV 0 Length
   # If Length is zero, just return with zero.
   @PUSH 0
@ELSE
    @ForIV2V ICnt Index Length
       @PUSHI Buffer @ADDI ICnt @ADD 1 @PUSHS
       @PUSHI Buffer @ADDI ICnt @POPS
    @Next ICnt
    @PUSH 0 @PUSHI Buffer @ADDI Length  @POPS
    @PUSHI Length @SUB 1
 @ENDIF
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


####################################################
# Function InserChar(Buffer, Index, UChar, Length, MaxWidth): Length
:InsertChar
@PUSHRETURN
@LocalVar Buffer 01
@LocalVar Index 02
@LocalVar UChar 03
@LocalVar Length 04
@LocalVar MaxWidth 05
@LocalVar Icnt 06
#
@POPI MaxWidth
@POPI Length
@POPI UChar
@POPI Index
@POPI Buffer
#
@PUSHI Length
@PUSHI MaxWidth @SUB 1
@IF_GE_S
   @POPNULL @POPNULL
   # No room to insert, just return MaxWidth as Length
   @PUSHI MaxWidth
@ELSE
   @POPNULL @POPNULL
    @ForIV2V ICnt Length Index
       @PUSHI Buffer @ADDI ICnt @SUB 1 @PUSHS
       @PUSHI Buffer @ADDI ICnt @POPS
    @NextBy ICnt  -1
    @PUSHI Buffer @ADDI Index
    @DUP
    @PUSHS @AND 0xff00 @ORI UChar
    @SWP @POPS
    @INCI Length
    @INCI Index
    @IF_EQ_VV Index Length
       @PUSHI Buffer @ADDI Length
       @PUSHI Buffer @ADDI Length @PUSHS
       @AND 0xff @SWP @POPS
    @ENDIF
@ENDIF
@POPNULL
@PUSHI UChar
@PUSHI Length
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


#####################################################
# Function UpdateScreen(InX,InY,Buffer, VWidth, CursorOffset)
:UpdateScreen
@PUSHRETURN
@LocalVar InX 01
@LocalVar InY 02
@LocalVar Buffer 03
@LocalVar VWidth 04
@LocalVar CursorOffset 05
@LocalVar SaveWord 06
#
@POPI CursorOffset
@POPI VWidth
@POPI Buffer
@POPI InY
@POPI InX
#@PUSH 30 @PUSH 5 @CALL WinCursor @StackDump

#
@CALL WinHideCursor
@PUSHI InX @PUSHI InY
@CALL WinCursor
@PUSHI Buffer @ADDI VWidth @PUSHS
@POPI SaveWord
@PUSH 0 @PUSHI Buffer @ADDI VWidth @POPS
@PRTSTRI Buffer @PRT "."
@PUSHI SaveWord
@PUSHI Buffer @ADDI VWidth @POPS
@PUSHI InX @ADDI CursorOffset @ADD 1
@PUSHI InY
@CALL WinCursor
@CALL WinShowCursor
@MA2V 0 NeedDraw
#@PUSH 30 @PUSH 7 @CALL WinCursor @StackDump

@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

###############################################
# Function TransCode(UChar):UChar
# Coverts Arrow and Function keys into single byte codes.
:TransCode
@PUSHRETURN
@LocalVar UChar 01
@LocalVar Index1 02
@LocalVar NewChar 03
@LocalVar PostNew 04
@POPI UChar
#
@IF_EQ_AV 27 UChar    # Check for Escape for possible arrow keys
   ! DEBUG
       @READCNW NewChar
   ENDBLOCK
   ? DEBUG
       @CALL SimRead
       @POPI NewChar
       @IF_EQ_AV 27 NewChar
   ENDBLOCK
   
       @PUSHI NewChar
       @IF_EQ_AV "[\0" NewChar
          @POPNULL
          @MA2V 49 Index1         # Force the for Loop to exit next time.
          # Start of an arrow key
          @PUSH 0          
          @WHILE_ZERO
              @POPNULL
              ? DEBUG              
              @CALL SimRead
              @POPI NewChar
              ENDBLOCK
              ! DEBUG
              @READCNW NewChar      # Keek reading until we get the 3rd character
              ENDBLOCK
              @PUSHI NewChar
          @ENDWHILE
          @SWITCH
#          @PUSH 30 @PUSH 11 @CALL WinCursor @StackDump             
          @CASE "A\0"       # UP
             @POPNULL
             @MA2V 0x10 UChar         # ^P
             @CBREAK
          @CASE "B\0"       # Down
             @POPNULL
             @MA2V 0xe UChar          # ^N
             @CBREAK
          @CASE "C\0"       # Right
             @POPNULL
             @MA2V 0x6 UChar          # ^F
             @CBREAK
          @CASE "D\0"       # Left
             @POPNULL
             @MA2V 0x2 UChar          # ^B
             @CBREAK
          @CDEFAULT        # Anything else.
             @POPNULL
             @CBREAK
          @ENDCASE            
       @ELSE
          @POPNULL
       @ENDIF
@ENDIF
@PUSHI UChar
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

:MainHeap 0
:LineArray 0
:CurrentLine 0
:CurCursor 0
:CurrVisLine 0
:MaxCurLine 0
:MaxPosLine 0
:CmdMode 0

# Setup A heap and give the softstack a full 1K to work with.
################################
:MInit
@PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeap
@PUSHI MainHeap @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 475" @END @ENDIF
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
@PUSHI MainHeap @PUSH 200      # 200 bytes 100 lines for init MaxPosLine
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 487" @END @ENDIF
@POPI LineArray
# Zero out the original array, entrys of zero will mean needs to be created.
@ForIA2B Var01 0 100
   @PUSH 0
   @PUSHI LineArray
   @PUSHI Var01 @SHL
   @ADDS
   @POPS
@Next Var01

@RET
#
#
################################
:ScreenRefresh
@PUSHRETURN
@LocalVar Index1 01
@LocalVar LowVisable 02
@LocalVar HighVisable 03
@LocalVar YLine 04
@LocalVar StrTemp 05
@CALL WinClear
@PUSHI CurrentLine @PUSHI WinHeight @SHR @SUBS
@IF_LT_A 0   @POPNULL   @PUSH 0 @ENDIF
@POPI LowVisable
@PUSHI LowVisable @ADDI WinHeight @SUB 2 @POPI HighVisable
@MA2V 1 YLine
@PUSHI HighVisable
@IF_GT_V MaxCurLine
   @POPNULL
   @PUSHI MaxCurLine
@ENDIF
@POPI HighVisable
@INCI HighVisable
@ForIV2V Index1 LowVisable HighVisable
    @PUSHI LineArray
    @PUSHI Index1 @SHL
    @ADDS @PUSHS @POPI StrTemp
    @PRTSTRI StrTemp
    @INCI YLine
@Next Index1
@PUSH 0
@PUSHI CurrentLine @SUBI LowVisable
@DUP @POPI CurrVisLine
@CALL WinCursor
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


    



:Main . Main
@CALL WinClear
#@StatusPrint @PRT "Startup..."
#
@CALL MInit
#
@MA2V 0 MaxCurLine
@MA2V 20 MaxPosLine
@PUSHI MainHeap @PUSHI MaxPosLine @SHL @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 536" @END @ENDIF
@POPI LineArray
#
#
# Setup a blank 200 byte line for the first line of the text.
@PUSHI MainHeap @PUSH 200 @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 540" @END @ENDIF
@POPII LineArray
@PUSH 0 @PUSHI LineArray @PUSHS @POPS
#
#
@MA2V 0 CmdMode
@MA2V 0 CurrentLine
@MA2V 0 CurCursor
@CALL ScreenRefresh

@TTYNOECHO
@PUSH 0
@IF_NOTZERO
  @PUSH 0b1100
  @PUSH 0 @PUSH 30
  @PUSH 200
  @PUSHI WinWidth @SUB 4
  @PUSH 0
  @PUSHII LineArray
  @CALL VisReadLine
  @PRT "\nFirst Return value: "
  @PUSHII LineArray @POPI Var02 @PRTSTRI Var02
  @POPNULL
  @POPI Var01
  @PUSH 0b1100
  @PUSH 0 @PUSH 32
  @PUSH 200
  @PUSHI WinWidth @SUB 4
  @PUSHI Var01
  @PUSHII LineArray
  @CALL VisReadLine
  @PRT "\nSecond Return value:    "
  @PUSHII LineArray @POPI Var02 @PRTSTRI Var02
  @PRTNL  
  @TTYECHO
@ENDIF

@PUSH 1

@WHILE_NOTZERO
     @POPNULL
     # Setup Call to Line Editor
     @PUSH 0b1100                       # Flags
     @PUSH 0 @PUSHI CurrVisLine         # X Y
     @PUSH 200                          # Max Line Length
     @PUSHI WinWidth @SUB 4  # Screen Width
     @PUSHI CurCursor
     @PUSHI LineArray @PUSHI CurrentLine @SHL @ADDS @PUSHS
     @IF_ZERO
        # Need to create a new line
        @PUSHI MainHeap @PUSH 200
        @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 583" @END @ENDIF
        @DUP
        @PUSHI LineArray @PUSHI CurrentLine @SHL @ADDS @POPS
     @ENDIF
     @CALL VisReadLine
     :Debug01
     @PRT "Return Code is:" @StackDump @PRT " ----->" @PRTTOP @PRTNL
     @IF_EQ_A 15
         @POPNULL
         @POPNULL
         @POPNULL
         @PUSH 0
     @ELSE
         @POPNULL
         @POPNULL
         @POPNULL
         @PUSH 1
     @ENDIF         
 @ENDWHILE
@TTYECHO
@END
:ENDOFCODE
