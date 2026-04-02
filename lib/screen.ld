! SCREEN_DONE
M SCREEN_DONE 1
I common.mc
L softstack.ld
# DEBUGSCREEN option:
# If defined, ANSI escape codes are replaced by "<ESC>["
# so debugging output shows literally instead of altering terminal.
#M DEBUGSCREEN

# -----------------------------
# Exported Symbols
# -----------------------------

# Screen management
G WinClear G WinResize G WinWidth G WinHeight

# Cursor control
G WinCursor G WinHideCursor G WinShowCursor
G WinNorth G WinSouth G WinEast G WinWest

# Colors
G ColorReset G ColorFGSet G ColorBGSet

# Drawing
G WinPlot G WinBox

# Scrolling
G WinScrollRegion G WinResetScrollRegion
G WinScrollUp G WinScrollDown

# Text Effects
G WinUnderLineOn G WinUnderLineOff
G WinBoldOn G WinBoldOff

# Misc
G CSICODE

# -----------------------------
# Defaults
# -----------------------------
:WinWidth 80     # default until WinResize called
:WinHeight 24    # default until WinResize called

# CSICODE: start of ANSI escape sequences
:CSICODE
! DEBUGSCREEN
   $$27 "[" $$0
ENDBLOCK
? DEBUGSCREEN
   "<ESC>[" $$0
ENDBLOCK


# ----------------------------------------------------------------------
# Function: WinClear
# Purpose : Reset terminal state and clear the screen.
# Inputs  : (none)
# Outputs : (none)
# SideFX  : Resets colors, moves cursor to (0,0), clears screen,
#           ensures cursor is visible.
# ----------------------------------------------------------------------
:WinClear
@PRTS CSICODE @PRT "0m"
@PRTS CSICODE @PRT "0;0H"
@PRTS CSICODE @PRT "2J"
@CALL WinShowCursor
@RET

# ----------------------------------------------------------------------
# Function: WinCursor
# Purpose : Move cursor to (X, Y) on the screen.
# Inputs  : Stack → [X, Y] (X = column, Y = row)
# Outputs : (none)
# SideFX  : Emits ANSI cursor positioning code: CSI Y;XH
# ----------------------------------------------------------------------
:WinCursor
@SWP
@PRTS CSICODE @PRTTOP @POPNULL
@PRT ";"
@SWP
@PRTTOP @POPNULL
@PRT "H"
@RET

# ----------------------------------------------------------------------
# Function: WinHideCursor
# Purpose : Hide the cursor.
# Inputs  : (none)
# Outputs : (none)
# SideFX  : Emits ANSI CSI ?25l (cursor hidden)
# ----------------------------------------------------------------------
:WinHideCursor
@PRTS CSICODE @PRT "?25l"
@RET

# ----------------------------------------------------------------------
# Function: WinShowCursor
# Purpose : Show the cursor.
# Inputs  : (none)
# Outputs : (none)
# SideFX  : Emits ANSI CSI ?25h (cursor visible)
# ----------------------------------------------------------------------
:WinShowCursor
@PRTS CSICODE @PRT "?25h"
@RET

# ----------------------------------------------------------------------
# Function : WinPlot
# Purpose  : Draw a line between two points on the terminal, printing
#            the given string at each intermediate point.
# Inputs   : Stack → [X0, Y0, X1, Y1, StrPtr]
#            - X0, Y0 : starting coordinates
#            - X1, Y1 : ending coordinates
#            - StrPtr : pointer to string to print at each plotted point
# Outputs  : (none)
# SideFX   : 
#   - Uses WinCursor to move cursor at each step
#   - Emits StrPtr at every coordinate along the line
#   - Line drawing uses integer-only Bresenham algorithm
# Notes    :
#   - Handles all octants (any slope, any direction).
#   - Terminates when both X0=X1 and Y0=Y1 (end point reached).
#   - Uses local vars (DX, DY, SX, SY, ERR, E2, Direct) to track slope
#     and accumulated error.
#   - Main loop limited by hard cap (@PUSH 0x200 … @WHILE_NOTZERO)
#     to avoid infinite loops on degenerate cases.
# Algorithm basis:
#   DX = abs(X1-X0), DY = -abs(Y1-Y0)
#   ERR = DX + DY
#   while not at end:
#       plot(X0,Y0)
#       E2 = 2*ERR
#       if E2 >= DY: ERR += DY; X0 += SX
#       if E2 <= DX: ERR += DX; Y0 += SY
# ----------------------------------------------------------------------
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
@PUSH 0x200  # Hard cap on iterations (0x200 = 512) prevents infinite loops
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
   @ELSE
      @POPNULL
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

# ----------------------------------------------------------------------
# Function : WinResize
# Purpose  : Detect the current terminal window size (rows × columns).
# Inputs   : (none)
# Outputs  : Sets globals:
#              WinWidth  = detected column count (capped 5–80)
#              WinHeight = detected row count (capped 5–50)
# SideFX   :
#   - Uses ANSI “Device Status Report” (DSR, CSI 6n) to query cursor
#     position after moving to a far bottom-right coordinate.
#   - Requires TTY raw mode to read characters directly.
#   - Prompts user "<Hit Enter>" in DEBUGSCREEN mode.
# Notes    :
#   - Caps results to a safe maximum of 80×50 (minimum 5×5).
#   - Restores cursor with CSI "u".
#   - Uses TermInfoBuffer/TIBIndex to temporarily hold input chars.
#   - Skips normal logic in DEBUGSCREEN, returning dummy output.
# ----------------------------------------------------------------------

:WinResize
#
# Windows Resize queries Terminal for it's size
! DEBUGSCREEN
@LocalVar TIBChar 01
@LocalVar CurVal 02
@TTYRAW
@PRTLN "------------Initilizing....<Hit Enter>"
@PRTS CSICODE @PRT "s"
@PRTS CSICODE @PRT "999;999H"    # Move cursor to far bottom right.
@PRTS CSICODE @PRT "6n"          # Termanil will clamp that to real max size.
@MA2V TermInfoBuffer TIBIndex
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
@TTYRAWOFF
? DEBUGSCREEN
  @PRT "DEBUG MODE:"
  @RET
ENDBLOCK

:TermInfoBuffer "                                                      " $$0
:TIBIndex 0
#
# ----------------------------------------------------------------------
# Function : ColorBGSet
# Purpose  : Set terminal background color (8-bit ANSI palette).
# Inputs   : Stack → [ColorID]
#            - ColorID: integer (0–255) selects background color.
# Outputs  : (none)
# SideFX   : Emits CSI "48;5;<ColorID>m" sequence.
# Notes    :
#   - Uses "48;5;" selector = background, 256-color mode.
#   - Requires terminal that supports xterm-256color or compatible.
#   - See table of color IDs below.
# ----------------------------------------------------------------------
:ColorID 0
:ColorBGSet
@PUSHRETURN
@POPI ColorID
@PRTS CSICODE  @PRT "48;5;" @PRTI ColorID @PRT "m"
@POPRETURN
@RET
# ---------------------------------------------------------------------
#    ANSI Color 'table'
#  The “256-color” ANSI palette splits into ranges:
#
#  0–7: Standard colors
# 0=black, 1=red, 2=green, 3=yellow, 4=blue, 5=magenta, 6=cyan, 7=white
#
# 8–15: Bright versions of the above
#
# 16–231: 6×6×6 color cube (216 colors)
#
# Formula: 16 + 36*r + 6*g + b where r,g,b ∈ [0–5]
#
# Example: 196 = pure red (r=5,g=0,b=0), 46 = bright green (r=0,g=5,b=0)
# 
# 232–255: Grayscale ramp (24 levels, black→white)
# ----------------------------------------------------------------------
# Function : ColorFGSet
# Purpose  : Set terminal foreground (text) color (8-bit ANSI palette).
# Inputs   : Stack → [ColorID]
#            - ColorID: integer (0–255) selects foreground color.
# Outputs  : (none)
# SideFX   : Emits CSI "38;5;<ColorID>m" sequence.
# Notes    :
#   - Uses "38;5;" selector = foreground, 256-color mode.
#   - Same color ID mapping as background.
# ----------------------------------------------------------------------
:ColorFGSet
@PUSHRETURN
@POPI ColorID
@PRTS CSICODE @PRT "38;5;" @PRTI ColorID @PRT "m"
@POPRETURN
@RET
# ----------------------------------------------------------------------
# Function : ColorReset
# Purpose  : Reset all text attributes to default.
# Inputs   : (none)
# Outputs  : (none)
# SideFX   : Emits CSI "0m" (clears colors, bold, underline, etc.)
# ----------------------------------------------------------------------
:ColorReset
@PRTS CSICODE @PRT "0m"
@RET
########################### Direction
# ----------------------------------------------------------------------
# Function : WinNorth
# Purpose  : Move the cursor up (north) by N cells.
# Inputs   : Stack → [N]
#            - N = number of rows to move upward
# Outputs  : (none)
# SideFX   : Emits CSI <N>A
# Example  : PUSH 5 CALL WinNorth   ; move up 5 rows
# ----------------------------------------------------------------------
# Function WinNorth()
:WinNorth
@SWP
@PRT CSICODE
@PRTTOP @POPNULL
@PRT "A"
@RET
# ----------------------------------------------------------------------
# Function : WinSouth
# Purpose  : Move the cursor down (south) by N cells.
# Inputs   : Stack → [N]
#            - N = number of rows to move downward
# Outputs  : (none)
# SideFX   : Emits CSI <N>B
# Example  : PUSH 2 CALL WinSouth   ; move down 2 rows
# ----------------------------------------------------------------------
# Function WinSouth()
:WinSouth
@SWP
@PRT CSICODE
@PRTTOP @POPNULL
@PRT "B"
@RET
# ----------------------------------------------------------------------
# Function : WinEast
# Purpose  : Move the cursor right (east) by N cells.
# Inputs   : Stack → [N]
#            - N = number of columns to move right
# Outputs  : (none)
# SideFX   : Emits CSI <N>C
# Example  : PUSH 10 CALL WinEast   ; move right 10 columns
# ----------------------------------------------------------------------
# Function WinEast()
:WinEast
@SWP
@PRT CSICODE
@PRTTOP @POPNULL
@PRT "C"
@RET
# ----------------------------------------------------------------------
# Function : WinWest
# Purpose  : Move the cursor left (west) by N cells.
# Inputs   : Stack → [N]
#            - N = number of columns to move left
# Outputs  : (none)
# SideFX   : Emits CSI <N>D
# Example  : PUSH 3 CALL WinWest    ; move left 3 columns
# ----------------------------------------------------------------------
# Function WinWest()
:WinWest
@SWP
@PRT CSICODE
@PRTTOP @POPNULL
@PRT "D"
@RET
# ----------------------------------------------------------------------
# Function : WinScrollRegion
# Purpose  : Define a scrolling region within the screen.
# Inputs   : Stack → [TopRow, BottomRow]
#            - TopRow    : first row of region (1-based)
#            - BottomRow : last row of region
# Outputs  : (none)
# SideFX   :
#   - Emits CSI <TopRow>;<BottomRow>r
#   - Constrains subsequent scrolling/up/down to this region only.
#   - Moves cursor to column 1 of TopRow after setting region.
# Notes    :
#   - Useful for status bars, split windows, or animation zones.
#   - Reset with WinResetScrollRegion.
# Example  : PUSH 5 PUSH 20 CALL WinScrollRegion
#            (restricts scrollable area to rows 5–20)
# ----------------------------------------------------------------------
#######################################
# Function WinScrollRegion(TopRow,BottomRow)
:WinScrollRegion
@PUSHRETURN
@LocalVar TopRow 01
@LocalVar BottomRot 02
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
   @PUSHI TopRow @PUSH 1 @CALL WinCursor
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
# Save for future use in scroll right / letf
:TopRow 0
:BottomRow 0

# ----------------------------------------------------------------------
# Function : WinScrollUp
# Purpose  : Scroll text upward within the current scroll region.
# Inputs   : Stack → [NumLines]
#            - NumLines : number of rows to scroll up
# Outputs  : (none)
# SideFX   : 
#   - Emits CSI <NumLines>S
#   - Lines scrolled off top are discarded.
#   - Blank lines inserted at bottom of region.
# Example  : PUSH 3 CALL WinScrollUp   ; scroll up 3 rows
# ----------------------------------------------------------------------
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
# ----------------------------------------------------------------------
# Function : WinResetScrollRegion
# Purpose  : Restore full-screen scrolling region.
# Inputs   : (none)
# Outputs  : (none)
# SideFX   : Emits CSI r
# Notes    :
#   - Resets scroll region to entire screen.
#   - Must be called when done with partial scroll areas.
# Example  : CALL WinResetScrollRegion
# ----------------------------------------------------------------------
########################################
# Function: WinResetScrollRegion
:WinResetScrollRegion
   @PRTS CSICODE
   @PRT "r"
@RET

# ----------------------------------------------------------------------
# Function : WinScrollDown
# Purpose  : Scroll text downward within the current scroll region.
# Inputs   : Stack → [NumLines]
#            - NumLines : number of rows to scroll down
# Outputs  : (none)
# SideFX   :
#   - Emits CSI <NumLines>T
#   - Lines scrolled off bottom are discarded.
#   - Blank lines inserted at top of region.
# Example  : PUSH 2 CALL WinScrollDown ; scroll down 2 rows
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# Function : WinScrollRight
# Purpose  : Scroll text right within the current scroll region.
# Inputs   : Stack → [NunComlums]
#            - NumLines : number of Columns to scroll Right
# Outputs  : (none)
# SideFX   :
#   - Emits CSI <NumLines>P
#   - Lines scrolled off right side are discard
# Example  : PUSH 2 CALL WinScrollRight ; scroll Right 2 columns
# ----------------------------------------------------------------------
########################################
:WinScrollRight
@PUSHRETURN
@LocalVar NumLines 01
@LocalVar Index 02
   @POPI NumLines
   @ForIV2V Index TopRow BottomRow
      @PUSHI WinWidth
      @PUSHI Index
      @CALL WinCursor
      @PRTS CSICODE
      @PRTI NumLines
      @PRT "@"
   @Next Index
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
# ----------------------------------------------------------------------
# Function : WinScrollLeft
# Purpose  : Scroll text right within the current scroll region.
# Inputs   : Stack → [NunComlums]
#            - NumLines : number of Columns to scroll Left
# Outputs  : (none)
# SideFX   :
#   - Emits CSI <NumLines>P
#   - Lines scrolled off right side are discard
# Example  : PUSH 2 CALL WinScrollLeft ; scroll Left 2 columns
# ----------------------------------------------------------------------
########################################
:WinScrollRight
@PUSHRETURN
@LocalVar NumLines 01
@LocalVar Index 02
   @POPI NumLines
   @ForIV2V Index TopRow BottomRow
      @PUSH 1
      @PUSHI Index
      @CALL WinCursor
      @PRTS CSICODE
      @PRTI NumLines
      @PRT "P"
   @Next Index
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
# ----------------------------------------------------------------------
# Function : WinUnderLineOn
# Purpose  : Enable underlining for subsequent printed text.
# Inputs   : (none)
# Outputs  : (none)
# SideFX   :
#   - Emits CSI 4m
#   - All following text will appear underlined until disabled.
# Example  : CALL WinUnderLineOn ; begin underlined output
# ----------------------------------------------------------------------
:WinUnderLineOn
   @PRTS CSICODE
   @PRT "4m"
@RET
# ----------------------------------------------------------------------
# Function : WinUnderLineOff
# Purpose  : Disable underlining previously enabled by WinUnderLineOn.
# Inputs   : (none)
# Outputs  : (none)
# SideFX   :
#   - Emits CSI 24m
#   - Stops underlining without resetting other attributes.
# Example  : CALL WinUnderLineOff ; end underlined output
# ----------------------------------------------------------------------
:WinUnderLineOff
   @PRTS CSICODE
   @PRT "24m"
@RET
# ----------------------------------------------------------------------
# Function : WinBoldOn
# Purpose  : Enable bold or high-intensity text output.
# Inputs   : (none)
# Outputs  : (none)
# SideFX   :
#   - Emits CSI 1m
# Example  : CALL WinBoldOn
# ----------------------------------------------------------------------
:WinBoldOn
   @PRTS CSICODE
   @PRT "1m"
@RET

# ----------------------------------------------------------------------
# Function : WinBoldOff
# Purpose  : Disanable bold or high-intensity text output.
# Inputs   : (none)
# Outputs  : (none)
# SideFX   :
#   - Emits CSI 1m
# Example  : CALL WinBoldOn
# ----------------------------------------------------------------------
:WinBoldOff
   @PRTS CSICODE
   @PRT "22m"
@RET


# ----------------------------------------------------------------------
# Function : WinBox
# Purpose  : Draw an ASCII box on the screen.
# Inputs   : Stack → [X1, Y1, X2, Y2]
#            - X1, Y1 : top-left corner (col, row)
#            - X2, Y2 : bottom-right corner (col, row)
# Outputs  : (none)
# SideFX   :
#   - Prints characters directly on screen:
#       '-' for top/bottom edges
#       '|' for side edges
#       '+' for corners
#   - Uses WinCursor for positioning each character.
# Notes    :
#   - Coordinates are inclusive; box spans full rectangle.
#   - Works well if given coordinates just outside a WinScrollRegion,
#     creating a “frame” effect around the region.
# Example  :
#   PUSH 5 PUSH 3 PUSH 40 PUSH 10 CALL WinBox
#   (draws box from (5,3) to (40,10))
# ----------------------------------------------------------------------
#######################################
# WinBox(x1,y1,x2,y2)
# Draw in ANSI a 'box' on the screen.
:WinBox
@PUSHRETURN
@LocalVar X1 01 @LocalVar Y1 02 @LocalVar X2 03 @LocalVar Y2 04
@LocalVar Index 05
@POPI Y2 @POPI X2 @POPI Y1 @POPI X1

@PUSHI X1 @PUSHI Y1 @CALL WinCursor
@ForIV2V Index X1 X2
  @PRT "-"
@Next Index
@PUSHI X1 @PUSHI Y2 @CALL WinCursor
@ForIV2V Index X1 X2
  @PRT "-"
@Next Index
@PUSHI X1 @PUSHI Y1 @CALL WinCursor
@ForIV2V Index Y1 Y2
   @PUSHI X1 @PUSHI Index @CALL WinCursor @PRT "|"
   @PUSHI X2 @PUSHI Index @CALL WinCursor @PRT "|"
@Next Index
@PUSHI X1 @PUSHI Y1 @CALL WinCursor @PRT "+"
@PUSHI X2 @PUSHI Y1 @CALL WinCursor @PRT "+"
@PUSHI X1 @PUSHI Y2 @CALL WinCursor @PRT "+"
@PUSHI X2 @PUSHI Y2 @CALL WinCursor @PRT "+"
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET






M SIZESINCECOMMENT screen.ld
@SIZESINCE
:ENDSCREEN
ENDBLOCK
