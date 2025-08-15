! SCREEN_DONE
I common.mc
L heapmgr.ld
L string.ld
L div.ld
M SCREEN_DONE 1
# When DEBUGSCREEN is set the instead of issueing ESC codes it will print <ESC> as text, preventing
# the ANSI codes from messinging up a debuging session.
M DEBUGSCREEN
G WinClear G WinCursor G WinWidth G WinHeight G WinResize G WinPlot
G WinHideCursor G WinShowCursor G ColorReset G ColorFGSet G ColorBGSet
G CSICODE G WinNorth G WinSouth G WinEast G WinWest G WinResetScrollRegion
G WinScrollUp G WinScrollDown G WinScrollRegion
:WinWidth 80
:WinHeight 24
:CSICODE
! DEBUGSCREEN
$$27 "[" $$0
ENDBLOCK
? DEBUGSCREEN
"<ESC>["$$0
ENDBLOCK

# Windows Clear
:WinClear
@PRTS CSICODE @PRT "0m"
@PRTS CSICODE @PRT "0;0H"
@PRTS CSICODE @PRT "2J"
@CALL WinShowCursor
@RET


# Windows Cursor
# Cal WinCursor(X,Y) moves cursor to that location.
:WinCursor
@SWP
@PRTS CSICODE @PRTTOP @POPNULL
@PRT ";"
@SWP
@PRTTOP @POPNULL
@PRT "H"
@RET

#
# Hide Cursor
:WinHideCursor
@PRTS CSICODE @PRT "?25l"
@RET

#
# Show Cursor
:WinShowCursor
@PRTS CSICODE @PRT "?25h"
@RET

# Windows Plot, draws a line for X0,Y0 to X1,Y1 printing String at each point
# Winplot(X0,Y0,X1,Y1,StrPtr
:WinPlot
@PUSHRETURN
@LocalVar StrPtr 01
@LocalVar X0 02
@LocalVar X1 03
@LocalVar Y0 04
@LocalVar Y1 05
@LocalVar DX 06
@LocalVar DY 07
@LocalVar SX 08
@LocalVar SY 09
@LocalVar ERR 10
@LocalVar E2 11
@LocalVar Direct 12
@POPI StrPtr
@POPI Y1 @POPI X1 @POPI Y0 @POPI X0
#@PUSHI X0 @SHL @SHL @SHR @POPI X0
#@PUSHI X1 @SHL @SHL @SHR @POPI X1
@PUSHI X1 @SUBI X0 @POPI DX @ABSI DX @POPI DX

@PUSHI X0
@IF_LT_V X1
   @MA2V 1 SX
@ELSE
   @MA2V -1 SX
@ENDIF
@POPNULL
@PUSHI Y1 @SUBI Y0 @POPI DY @ABSI DY @COMP2 @POPI DY
@PUSHI Y0
@IF_LT_V Y1
   @MA2V 1 SY
@ELSE
   @MA2V -1 SY
@ENDIF
@POPNULL
@PUSHI DX @ADDI DY @POPI ERR
@PUSH 0x200
@WHILE_NOTZERO
   @PUSHI X0 @PUSHI Y0 @CALL WinCursor @PRTSI StrPtr
   @IF_EQ_VV X0 X1
      @IF_EQ_VV Y0 Y1
         @POPNULL @PUSH 0 @JMP WPEndLoop # Break
      @ENDIF
   @ENDIF

   @PUSHI ERR @SHL @POPI E2
   @PUSHI E2
   @IF_GE_V DY
      @POPNULL
      @IF_EQ_VV X0 X1
         @POPNULL @PUSH 0 @JMP WPEndLoop # Break
      @ENDIF
      @PUSHI ERR @ADDI DY @POPI ERR
      @PUSHI X0 @ADDI SX @POPI X0
   @ENDIF
   @PUSHI E2
   @IF_LE_V DX
      @IF_EQ_VV Y0 Y1
         @POPNULL @PUSH 0 @JMP WPEndLoop # Break
      @ENDIF
      @PUSHI ERR @ADDI DX @POPI ERR
      @PUSHI Y0 @ADDI SY @POPI Y0
   @ENDIF
   @POPNULL
   @SUB 1
#   @PRT "4" @StackDump
   :WPEndLoop
@ENDWHILE
@POPNULL
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

:WinResize
#
# Windows Resize queries Terminal for it's size
! DEBUGSCREEN
@LocalVar TIBChar 01
@LocalVar CurVal 02
@PRTLN "------------Initilizing....<Hit Enter>"
@PRTS CSICODE @PRT "s"
@PRTS CSICODE @PRT "999;999H"
@PRTS CSICODE @PRT "6n"
@MA2V TermInfoBuffer TIBIndex
@TTYNOECHO
# Drain until we see 'ESC'
@PUSH 1
@WHILE_NOTZERO
   @READCNW TIBChar
   @IF_EQ_AV "\e\0" TIBChar
      @POPNULL
      @PUSH 0
   @ENDIF
@ENDWHILE
@POPNULL
@MA2V 0 WinHeight
@MA2V 0 WinWidth
@MA2V 0 CurVal
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @READC TIBChar
   @PUSHI TIBChar @AND 0xff
   @IF_INRANGE_AB "0\0" "9\0"
      @SUB "0\0"                           # Ascii to val
      @PUSHI CurVal @SHL @DUP @SHL @SHL @ADDS   # Mul Cur*10
      @ADDS
      @POPI CurVal
      @PUSH 0
   @ELSE
      @IF_EQ_A ";\0"
          @POPNULL
          @MV2V CurVal WinHeight
          @MA2V 0 CurVal
          @PUSH 0
      @ELSE
          @IF_EQ_A "R\0"
             @POPNULL
             @MV2V CurVal WinWidth
             @PUSH 1
          @ELSE
             @POPNULL
             @PUSH 0
          @ENDIF          
      @ENDIF
   @ENDIF
@ENDWHILE
@POPNULL
@TTYECHO
@PRTS CSICODE @PRT "u"
# We need to make sure values are not too big. Our limit is 80x50
@PUSHI WinWidth
@IF_GT_A 80
   @POPNULL
   @PUSH 80
@ENDIF
@IF_LT_A 5
   @POPNULL
   @PUSH 5
@ENDIF
@POPI WinWidth
@PUSHI WinHeight
@IF_GT_A 50
   @POPNULL
   @PUSH 50
@ENDIF
@IF_LT_A 5
   @POPNULL
   @PUSH 5
@ENDIF
@POPI WinHeight
@RestoreVar 02
@RestoreVar 01
@RET
ENDBLOCK
? DEBUGSCREEN
  @PRT "DEBUG MODE:"
  @RET
ENDBLOCK

:TermInfoBuffer "                                                      " $$0
:TIBIndex 0
#
# Function ColorBGSet(Color)
:ColorID 0
:ColorBGSet
@PUSHRETURN
@POPI ColorID
@PRTS CSICODE  @PRT "48;5;" @PRTI ColorID @PRT "m"
@POPRETURN
@RET
# Function ColorFGSet(Color)
:ColorFGSet
@PUSHRETURN
@POPI ColorID
@PRTS CSICODE @PRT "38;5;" @PRTI ColorID @PRT "m"
@POPRETURN
@RET
# Function ColorReset()
:ColorReset
@PRTS CSICODE @PRT "0m"
@RET
########################### Direction
# Function WinNorth()
:WinNorth
@SWP
@PRT CSICODE
@PRTTOP @POPNULL
@PRT "A"
@RET
# Function WinSouth()
:WinSouth
@SWP
@PRT CSICODE
@PRTTOP @POPNULL
@PRT "B"
@RET
# Function WinEast()
:WinEast
@SWP
@PRT CSICODE
@PRTTOP @POPNULL
@PRT "C"
@RET
# Function WinWest()
:WinWest
@SWP
@PRT CSICODE
@PRTTOP @POPNULL
@PRT "D"
@RET
#######################################
# Function WinScrollRegion(TopRow,BottomRow)
:WinScrollRegion
@PUSHRETURN
@LocalVar TopRow 01
@LocalVar BottomRow 02
#
# Setting region CSICODE toprow# ; bottomrow# r
   @POPI BottomRow
   @POPI TopRow
   #
   @PRTS CSICODE
   @PRTI TopRow
   @PRT ";"
   @PRTI BottomRow
   @PRT "r"
   @PUSH TopRow @PUSH 1 @CALL WinCursor
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

########################################
# Function: WinScrollUp(NumLines)
:WinScrollUp
@PUSHRETURN
@LocalVar NumLines 01
    @POPI NumLines
    @PRTS CSICODE
    @PRTI NumLines
    @PRT "S"
@RestoreVar 01
@POPRETURN
@RET

########################################
# Function: WinResetScrollRegion
:WinResetScrollRegion
   @PRTS CSICODE
   @PRT "r"
@RET

########################################
# WinScrollDown(N): Scroll down N lines in current scroll region
:WinScrollDown
@PUSHRETURN
@LocalVar NumLines 01
   @POPI NumLines
   @PRTS CSICODE
   @PRTI NumLines
   @PRT "T"
@RestoreVar 01
@POPRETURN
@RET
      




M SIZESINCECOMMENT screen.ld
@SIZESINCE
:ENDSCREEN
ENDBLOCK
