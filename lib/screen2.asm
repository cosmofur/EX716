L string.asm
L mul.ld
L div.ld
! SCREEN_DONE
M SCREEN_DONE 1
M INC2I @PUSHI %1 @ADD 2 @POPI %1
M DEC2I@PUSHI %1 @SUB 2 @POPI %1
@JMP ENDSCREEN
:WinWidth 80
:WinHeight 24
:WinPage1 0xE000
:WinPage2 0xF000
:ActivePage 0
:FixedZero 0
:CSICODE
# "<ESC>["b0
b$27 "[" b0
G CSICODE G WinInit G WinClear G WinRefresh G WinWrite G strlen G WinCursor

:WinInit
# There no other paramters so we already have the Return Address where we need it.
@MC2M 0 ActivePage
@RET

:WinClear
# There no other paramters so we already have the Return Address where we need it.
@PRTS CSICODE
@PRT "0m"
@PRTS CSICODE
@PRT "0;0H"
@PRTS CSICODE
@PRT "2J"
@MM2M WinPage1 WCSrcIndex1
@MM2M WinPage2 WCDstIndex1
@ForIfA2B WCIndex1 0 2000 WCLoop1
   @PUSH 0x2020
   @DUP
   @POPII WCSrcIndex1
   @POPII WCDstIndex1
   @PUSH 2
   @ADDI WCSrcIndex1
   @POPI WCSrcIndex1
   @PUSH 2
   @ADDI WCDstIndex1
   @POPI WCDstIndex1
   @INCI WCIndex1
@NextNamed WCIndex1 WCLoop1 
@RET
:WCIndex1 0
:WCSrcIndex1 0
:WCDstIndex1 0

:WinRefresh
@PUSHI ActivePage
@CMP 0
@POPNULL
@JMPZ WR0ActZero
# Active is 1, so use WinPage2 as src
  @MM2M WinPage2 WRSrcPage
  @MM2M WinPage1 WRDstPage
  @MM2M WinPage2 WREndPageMark
  @JMP WR0SkipElse1
:WR0ActZero
# Active is 0, so use WinPage1 as src
  @MM2M WinPage1 WRSrcPage
  @MM2M WinPage2 WRDstPage
  @MM2M WinPage1 WREndPageMark
:WR0SkipElse1
@MC2M 0 WRWidth
@MC2M 0 WRHeight
@PRTS WR0TOS
@PRTSI WRSrcPage
:WR0MainLoop
  @PUSHII WRSrcPage
  @POPII WRDstPage
  @INC2I WRSrcPage
  @INC2I WRDstPage
  @INC2I WRWidth   # We are copying in word blocks not bytes
  @PUSHI WRWidth
  @CMPI WinWidth @POPNULL
  @JLE WR0SetNextLine    # On chance it is odd number
  @JMP WR0MainLoop
:WR0SetNextLine
#@PRTS WRSrcPage
@INCI WRHeight
@PUSHI WinHeight
@ADD 1
@CMPI WRHeight @POPNULL
@JMPZ WR0ExitWrite
@MC2M 0 WRWidth
@JMP WR0MainLoop
:WR0ExitWrite
@PRTS WR0TOS
@RET
:WR0TOS
b$27 "[0;0H" b0
:WR0YSTR "      "
:WR0XSTR "      "
:WinRefreshSlow
# There no other paramters so we already have the Return Address where we need it.
@PUSHI ActivePage
@CMP 0
@POPNULL
@JMPZ WRActZero
# Active is 1, so use WinPage2 as src
  @MM2M WinPage2 WRSrcPage
  @MM2M WinPage1 WRDstPage
  @MM2M WinPage2 WREndPageMark
  @JMP WRSkipElse1
:WRActZero
# Active is 0, so use WinPage1 as src
  @MM2M WinPage1 WRSrcPage
  @MM2M WinPage2 WRDstPage
  @MM2M WinPage1 WREndPageMark
:WRSkipElse1
@PUSH 2000         # Sometime we should change this to a WinWidth * WinHeight but for now...
@ADDI WREndPageMark
@POPI WREndPageMark
@PUSHI WRSrcPage
@ADD 2000
@POPI WREndSrcIdx
@MC2M 0 WRWidth
@MC2M 0 WRHeight
:WRMainLoop
  @PUSHII WRSrcPage       # Get Src word
  @AND 0x00ff             # Mask Low Byte
  @PUSHII WRDstPage       # Get Dest word
  @AND 0x00ff             # Mask low byte of Dest word
  @CMPS
  @POPNULL       # Get rid of old Dest word
  @POPNULL
  @JMPZ WRByteNoDiff
     # the the character is diffrent.
     # Move Cursor to location.
     @PRTS CSICODE
     @PRTI WRHeight
     @PRT ";"
     @PRTI WRWidth
     @PRT "H"
     #
     # Now we are going to loop forward until either the end or until we find a matching byte.
     #
     @MM2M WRSrcPage WRBeginSrcDiff      # Save so we know where to 'start' later
     @MM2M WRDstPage WRBeginDstDiff
     :WRFindDiffRangeLoop
     @INCI WRSrcPage
     @INCI WRDstPage
     @INCI WRWidth
     @PUSHI WRWidth
     @CMPI WinWidth                       # Testing for end of Line
     @POPNULL
     @JMPZ WRRollNextLineInDA             # Jumping to do this logic elsewhere, but will return here.
     :WRReturnInDANextLine                # There is an efficently reason to do this rather than JNZ
     @PUSHI WRSrcPage
     @CMPI WREndPageMark                  # Testinf for end of Page
     @POPNULL
     @JMPZ WRReachEndPage
     # So we belive WRSrc and WRDst are both valid here.
        @PUSHII WRSrcPage                 # This is basicly the same test we did before in the main loop
	@AND 0x00ff
	@PUSHII WRDstPage
	@AND 0x00ff
	@CMPS
	@POPNULL
	@POPNULL
	@JMPZ WRInDaFoundSame             # This means that we have discovered a new spot where matches begin.
	@JMP WRFindDiffRangeLoop
#
# We had an 'if' jumps that need to be handled that seemed 'cleaner' to pull it out of the loop
#
# The first is to know that we've rolled to the next line and need to CR cursor
:WRRollNextLineInDA
@INCI WRHeight
@MC2M 0 WRWidth
@JMP WRReturnInDANextLine
#
# We have two type of exits from the 'DiffRangeLoop'
# One was when we found another matching character
# And the other was when we reached the end of the page.
#
# In both cases we are basicly going to do the same thing.
# Write SRC characters on screen, and overwrite them in the DST storeage.
#
:WRInDaFoundSame
:WRReachEndPage
# We can take advantage of the PRTS to print the block of text from
#  WRBeginSrcDiff to WRSrcPage, by just putting a null or zero at the WRSPage +1 spot.
#
@PUSHII WRSrcPage   #This should be pointing to either 1+ last character or 1+ the last 'diffrent' character.
@PUSH 0             #It will be preserved on the stack.
@POPII WRSrcPage
#Now Print the block of text (or a single character) that's from WRBeginSrcDiff to here.
@PRTSI WRBeginSrcDiff
@POPII WRSrcPage    # Put the preserved old word that was at the end, back.
#
@ForIfV2V WRCpIndex WRBeginSrcDiff WRSrcPage WRNamedLoop1
  @PUSHII WRCpIndex
  @AND 0xff
  @PUSHII WRBeginDstDiff        # We will be only copying the 'low bytes' so preserve the High one.
  @AND 0xff00
  @ADDS
  @POPII WRBeginDstDiff
  @INCI WRBeginDstDiff
@NextNamed WRCpIndex WRNamedLoop1
#
# Ok were at the exit point of the inner loop for cases were there Was a diffrence.
# But now we need to handle the no diffrence parts
# But first...when we get here normaly
# WRSrc and WRDst are pointing at matching data, or we've reached the end of page.
# So first test if we've reached end of page.
:WRByteNoDiff
@PUSHI WRSrcPage
@CMPI WREndPageMark
@POPNULL
@JMPZ WRRealEndPage       # This is a 'real' exit of the main loop.
# Now is the time to incremnt the main pointers and width counter.
@INCI WRSrcPage
@INCI WRDstPage
@INCI WRWidth
# Now test if WRWidth is ready to roll to a new line
@PUSHI WRWidth
@CMPI WinWidth
@POPNULL
@JMPZ WROutLoopEndLine
# We get here if we not at either end of page or end of line.
# So jump back to the begining of the main loop
@JMP WRMainLoop
#
# This is the case for reaching end of linem but not end of page.
:WROutLoopEndLine
@INCI WRHeight
@MC2M 0 WRWidth
@JMP WRMainLoop
#
# OK this is the Real end of the module.
:WRRealEndPage
@RET
# Here are all the local variables used.
:WRSrcPage 0
:WRDstPage 0
:WREndPageMark 0
:WREndSrcIdx 0
:WRWidth 0
:WRHeight 0
:WRBeginSrcDiff 0
:WRBeginDstDiff 0
:WRCpIndex 0
#
#
# WinCursor moves the active cursor to a location
#
:WinCursor
@POPI WCReturnAddr
@POPI WCYLoc
@POPI WCXLoc
@PRS CSICODE @PRTI WCYLoc @PRT ";" @PRTI WCXLoc @PRT "H"
@PUSH WCReturnAddr
@RET
:WCXLoc 0
:WCYLoc 0
:WCReturnAddr

#
# WinWrite takes three paramters
# Pushed in order, WinX, WinY, StringPtr
:WinWrite
# Unlike most of the other functions (so far) we ARE using paramters here so reserve the return address
@POPI WWReturnAddr
@POPI WWStrPtr
@POPI WWYLoc
@POPI WWXLoc
# Lets find the 'active' page.
@PUSHI ActivePage
@CMP 0
@POPNULL
@JMPZ WWActZero
   @MM2M WinPage2 WWSrcPage
   @MM2M WinPage1 WWDstPage
   @MM2M WinPage2 WWEndPageMark
   @JMP WWSkipElse1
:WWActZero
   @MM2M WinPage1 WWSrcPage
   @MM2M WinPage2 WWDstPage
   @MM2M WinPage1 WWEndPageMark
:WWSkipElse1
@PUSH 2000       # Still need to change this to a calculated length sometime.
@ADDI WWEndPageMark 
@POPI WWEndPageMark
# Now we need to 'calculate' the offset (in both src and dest) where Y*Width+X will be
@PUSHI WWYLoc
@PUSHI WinWidth
@CALL MUL
@ADDI WWXLoc
@POPI WWOffset
# Lets get the string's length
@PUSHI WWStrPtr
@CALL strlen      # On the stack will be the string length
@PUSHI WWSrcPage   # We're looking to find where our loop ends
@ADDS             # So that's WWSRC + Len + Offset
@ADDI WWOffset
# Now we want to make sure the EndSpot is not 'off' the page. (too large a string for remaining space)
@CMPI WWEndPageMark          # As reminder CMP is flags based on EndPage - (Src + Offset + len) if N then bad
@JMPN WWDoBadMark   # So N is EndPage is < offset+len
  @POPI WWEndSpot
  @JMP WWSkipElseGoodMark
:WWDoBadMark
# So we get here when string it 'too' large. Set EndSpot to be same as EndPage
  @POPNULL
  @MM2M WWEndPageMark WWEndSpot
:WWSkipElseGoodMark
@PUSHI WWSrcPage
@ADDI WWOffset
@POPI WWStartSpot
# By the time we get here, this loop handles the main job.
# WWStartStop to EndSpot is where the strptr going to be copied.
@ForIfV2V WWCpIndex WWStartSpot WWEndSpot WWForCopyLoop
  @PUSHII WWCpIndex
  @AND 0xff00     # We need to preserve the upperbyte.
  @PUSHII WWStrPtr
  @AND 0xff       # In the string we only care about lower byte
  @ADDS
  @POPII WWCpIndex
  @INCI WWStrPtr
@NextNamed WWCpIndex WWForCopyLoop
@PUSHI WWReturnAddr
@RET
# Local storage
:WWReturnAddr 0
:WWStrPtr 0
:WWXLoc 0
:WWYLoc 0
:WWSrcPage 0
:WWDstPage 0
:WWEndPageMark 0
:WWOffset 0
:WWEndSpot 0
:WWStartSpot 0
:WWCpIndex 0

  


   


  	




   










ENDBLOCK
:ENDSCREEN
L mul.ld
