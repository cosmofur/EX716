! SCREEN_DONE
L heapmgr.ld
L string.ld
M SCREEN_DONE 1
G WinClear G WinCursor G WinWidth G WinHeight G WinResize G WinPlot
G WinHideCursor G WinShowCursor G ColorReset G ColorFGSet G ColorBGSet
G CSICODE G WinNorth G WinSouth G WinEast G WinWest
:WinWidth 80
:WinHeight 24
:CSICODE
#"<ESC>["$$0
$$27 "[" $$0
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
@PUSHLOCALI StrPtr
@PUSHLOCALI X0
@PUSHLOCALI X1
@PUSHLOCALI Y0
@PUSHLOCALI Y1
@PUSHLOCALI DX
@PUSHLOCALI DY
@PUSHLOCALI SX
@PUSHLOCALI SY
@PUSHLOCALI ERR
@PUSHLOCALI E2
@PUSHLOCALI Direct
@POPI StrPtr
@POPI Y1 @POPI X1 @POPI Y0 @POPI X0
#@PUSHI X0 @RTL @RTL @RTR @POPI X0
#@PUSHI X1 @RTL @RTL @RTR @POPI X1
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
   
   @PUSHI ERR @RTL @POPI E2
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
@PUSHLOCALI Direct
@PUSHLOCALI E2
@PUSHLOCALI ERR
@PUSHLOCALI SY
@PUSHLOCALI SX
@PUSHLOCALI DY
@PUSHLOCALI DX
@PUSHLOCALI Y1
@PUSHLOCALI Y0
@PUSHLOCALI X1
@PUSHLOCALI X0
@PUSHLOCALI StrPtr
@POPRETURN
@RET
:WPReturn 0
:StrPtr 0
:X0 0 :X1 0
:Y0 0 :Y1 0
:DX 0 :DY 0
:SX 0 :SY 0
:ERR 0 :E2 0
:Direct 0



:WinResize
#
# Windows Resize queries Terminal for it's size
@PRTLN "------------Initilizing....<Hit Enter>"
@PRTS CSICODE @PRT "s"
@PRTS CSICODE @PRT "999;999H"
@PRTS CSICODE @PRT "6n"
@READS TermInfoBuffer
@MA2V TermInfoBuffer TIBIndex
@PRTS CSICODE @PRT "u"
# At this point TermInfoBuffer should be "[[HH;WWR"
# Search for ';'
@PUSH 0x3b @PUSH TermInfoBuffer @CALL strfndc
@POPI TIBIndex
@PUSHII TIBIndex
@AND 0xff00       #Turn ';' into a null
@POPII TIBIndex
@PUSH TermInfoBuffer     # Start string where '[' was
@ADD 1                   # Move one over.	
@CALL stoi
@POPI WinHeight
# Search for 'R'
@INCI TIBIndex	   # Skip past the previously inserted null
@PUSH 0x52 @PUSHI TIBIndex @CALL strfndc
@PUSHI TIBIndex   # Save the old Index or start of second number spot
#@ADD 1
@SWP
@POPI TIBIndex
@PUSHII TIBIndex
@AND 0xff00      # Turn 'R' into a null
@POPII TIBIndex
# the old index should be at TOS
@CALL stoi
@POPI WinWidth
# We need to make sure values are not too big. Our limit is 80x50
@PUSHI WinWidth @CMP 80 @POPNULL
@JLE NotTooWide
   @MA2V 80 WinWidth
:NotTooWide
@PUSHI WinHeight @CMP 50 @POPNULL
@JLE NotTooTall
  @MA2V 50 WinHeight
:NotTooTall
@RET
:TermInfoBuffer "                                                      " $$0
:TIBIndex 0
#
# Function ColorBGSet(Color)
:ANSICSI $$27 "[" $$0
:ColorID 0
:ColorBGSet
@PUSHRETURN
@POPI ColorID
#@PRTS ANSICSI @PRT "48;5;" @PRTI ColorID @PRT "m"
@PRTS CSICODE  @PRT "48;5;" @PRTI ColorID @PRT "m"
@POPRETURN
@RET
# Function ColorFGSet(Color)
:ColorFGSet
@PUSHRETURN
@POPI ColorID
#@PRTS ANSICSI @PRT "38;5;" @PRTI ColorID @PRT "m"
@PRTS CSICODE @PRT "38;5;" @PRTI ColorID @PRT "m"
@POPRETURN
@RET
# Function ColorReset()
:ColorReset
@PRTS ANSICSI @PRT "0m"
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



ENDBLOCK
:ENDSCREEN
