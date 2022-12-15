# Basic Screen Library to drive ANSI terminal
! SCREEN_DONE
M SCREEN_DONE 1
L io.ld
L string.ld
@JMP ENDSCREEN
G ScrInit G ScrClear G ScrMove G ScrWidth G ScrHeight G CSICODE
:ScrWidth 80
:ScrHeight 24
:CSICODE
"<ESC>[" b0
# b$27 "[" b0
:ScrInit
# There no other paramters so we already have the Return Address where we need it.
@PRTLN "-----INITILIZING....<Hit Enter>"
@PRTS CSICODE @PRT "s"
@PRTS CSICODE @PRT "999;999H"
@PRTS CSICODE @PRT "6n"
@READS TermInfoBuffer
@MC2M TermInfoBuffer TIBIndex
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
@POPI ScrHeight
# Search for 'R'
@INCI TIBIndex	   # Skip past the previously inserted null
@PUSH 0x52 @PUSHI TIBIndex @CALL strfndc
@PUSHI TIBIndex   # Save the old Index or start of second number spot
@SWP
@POPI TIBIndex
@PUSHII TIBIndex
@AND 0xff00      # Turn 'R' into a null
@POPII TIBIndex
@CALL stoi
@POPI ScrWidth
# We need to make sure values are not too big. Our limit is 80x50
@PUSHI ScrWidth @CMP 80 @POPNULL
@JLE NotTooWide
   @MC2M 80 ScrWidth
:NotTooWide
@PUSHI ScrHeight @CMP 50 @POPNULL
@JLE NotTooTall
  @MC2M 50 ScrHeight
:NotTooTall
@RET
# We put an initial 24x80 responce code for a reasonable default if screen size fails to report properly
:TermInfoBuffer "[24;80R                                                  " b0
:TIBIndex 0
#
# 
:ScrClear
@PRTS CSICODE
@PRT "0m"
@PRT CSICODE
@PRT "0;0H"
@PRTS CSICODE
@PRT "2J"
@RET
#
#
:ScrMove
@PRTS CSICODE
@SWP
@PRTTOP @POPNULL
@PRT ";"
@SWP
@PRTTOP @POPNULL
@PRT "H"
@RET
#
#



:ENDSCREEN
ENDBLOCK
