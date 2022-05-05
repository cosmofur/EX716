! SCREEN_DONE
@JMP ENDSCREEN
M SCREEN_DONE 1
# Global for Windows
:WinWidth 80
:WinHeight 24

#
# A very Basic ANSII screen display manager.
G SCRhome G SCRcls G SCRreset G SCRmove G SCRBGColor G SCRFGColor G SCRXY2I
G WinClear G WinWrite G WinRefresh
# SCRXY2I This converts and X,Y index to a delta from origin index
#         (Basicly turn 2d to 1d array)
# In push X, push Y  output is Offset
:SCRXY2I
@POPI SCRReturnAddr
@POPI SCRYVal
@POPI SCRXVal
@PUSHI SCRYVal
@PUSHI WinWidth
@CALL MUL
@ADDI SCRXVal
@PUSHI SCRReturnAddr
@RET
# As this is a utility funciton likely to be called by others, don't reuse local variables
:SCRReturnAddr 0
:SCRYVal 0
:SCRXVal 0
# 
# Cursor Potioning
# Move the cursor to the home position
:SCRhome
@PRTS CSICODE
@PRT "1;1H"
@RET
# Clear to end of screen from Cursor
:SCRcls
@PRTS CSICODE
@PRT "1;1H"
@PRTS CSICODE
@PRT "J"
@PRTS CSICODE
@PRT "0m"
@RET
#
# SCRreset resets with 0m but doesn't move cursor to home
:SCRreset
@PRTS CSICODE
@PRT "0m"
@RET
# Move cursor to x,y location with x,y passed in order of stack (x pushed first, then y)
:SCRmove
@POPI SCRmoveReturnAddr
@PRTS CSICODE
@PRTTOP
@PRT ";"
@POPNULL
@PRTTOP
@PRT "H"
@PUSHI SCRmoveReturnAddr
@RET
:SCRmoveReturnAddr 0
# Set Background Color to 0-15
#0	black
#1	red
#2	green
#3	yellow
#4	blue
#5	magenta
#6	cyan
#7	white
# Over 7 means use val & 7 as bright color
:SCRBGColor
@POPI SCRBGReturnAddr
@POPI GivenColor
@MM2M GivenColor DefaultBG
@PUSH 7
@CMP GivenColor
@POPNULL
@JGT SCRBGLight
@PRTS CSICODE
@PUSH 40
@ADDI GivenColor
@POPI GivenColor
@PRTI GivenColor
@PRT "m"
@PUSHI SCRBGReturnAddr
@RET
:SCRBGLight
@PRTS CSICODE
@PUSH 92
@ADDI GivenColor
@POPI GivenColor
@PRTI GivenColor
@PRT "m"
@PUSHI SCRBGReturnAddr
@RET
:SCRBGReturnAddr 0

:SCRFGColor
@POPI SCRFGReturnAddr
@POPI GivenColor
@MM2M GivenColor DefaultFG
@PUSH 7
@CMP GivenColor
@POPNULL
@JGT SCRFGLight
@PRTS CSICODE
@PUSH 30
@ADDI GivenColor
@POPI GivenColor
@PRTI GivenColor
@PRT "m"
@PUSHI SCRFGReturnAddr
@RET
:SCRFGLight
@PRTS CSICODE
@PUSH 82
@ADDI GivenColor
@POPI GivenColor
@PRTI GivenColor
@PRT "m"
@PUSHI SCRFGReturnAddr
@RET
:SCRFGReturnAddr 0
# Start of 'Window' Functions, a sort of poor mans Curses
#
:WinClear
@POPI WinClearReturnAddr
@CALL SCRcls
@MC2M 0 Scrt1
@MC2M WinAsIs Scrt2
@MC2M WinToBe Scrt3
@ForIfV2V Indx1 Scrt1 WinHeight WCHightLoop1
  @ForIfV2V Indx2 Scrt1 WinWidth WCWidthLoop1
     # Put space with 0 format in both windows.
     @PUSH 0x2000              # 0x2000 == space followed by null
     @DUP
     @POPII Scrt2
     @POPII Scrt3
     @INCI Scrt2
     @INCI Scrt3
  @NextNamed Indx2 WCWidthLoop1
@NextNamed Indx1 WCHightLoop1
@PUSHI WinClearReturnAddr
@RET
:WinClearReturnAddr 0
#
# WinRefresh takes content of 'WinToBe' scans for diffrences with 'WinAsIs' and
# Prints lines that do not match, copying the relevent data to WinAsIs
:WinRefresh
@POPI WinRefreshReturnAddr
@MC2M 0 Scrt1
@MC2M WinAsIs Scrt2
@MC2M WinToBe Scrt3
@PUSHI DefaultBG
@CALL SCRBGColor
@PUSHI DefaultFG
@CALL SCRFGColor
#@PRT "Start of ScreenRefresh"
@ForIfV2V Indx1 Scrt1 WinHeight WRHightLoop1
  @MC2M 0 ChgFlg
  @ForIfV2V Indx2 Scrt1 WinWidth WRWidthLoop1
     @PUSHII Scrt2
     @PUSHII Scrt3
     @CMPS           #Test if there a diffrence
     @POPNULL
     @POPNULL     
     @JMPZ SFSgood   #No diffrence yet.
#     @PRT " Found Diff "
     # Here be a diffrence.
     # Need to loop from Scrt3[Index2] to Scrt3[WinWidth]
     @PUSHI Indx2   # Move the cursor to the Indx1 down and Indx2 over.
     @PUSH Indx1
     @CALL SCRmove
     @ForIfV2V Indx3 Indx2 WinWidth WRChangeLoop1
#        @PRT " Doing "
#	@PRTI Indx3
#	@PRT " "
        @PUSHII Scrt3 # Get 16b color/char at (Indx1,Indx2+Indx3) on stack
	@POPII ScrCellStruct0   # Character part will be at byte starting at SCS0
	@PUSHI ScrCellStruct1   # Color Part will be in byte starting at SCS1
	@AND 0x00ff             # Mask out any junk
	@DUP
	@AND 0x0f     # Color bytes are 4bit FG 4bit BG 
	@POPI BGColor1
	@AND 0xf0
	@RTR @RTR @RTR @RTR     #shift if down from 0x00 - 0xf0 to 0x0 - 0xf
	@DUP
	@POPI FGColor1
	# Now test if we need to change FG color.
	@CMPI DefaultFG
	@POPNULL
	@JMPZ NextColorTest     # If same go on to check BG color
	#Else
	@MM2M FGColor1 DefaultFG
	@CALL SCRFGColor
	:NextColorTest
	CMPI DefaultBG
	@POPNULL
	@JMPZ WriteTextPart
	#Else
	@MM2M BGColor1 DefaultBG
	@PUSHI BGColor1
	@CALL SCRBGColor
	:WriteTextPart
	@PUSHI ScrCellStruct0
	@AND 0x00ff
	@POPI ScrCellStruct0       # Write character back with high byte now null
	@PRTS ScrCellStruct0
     @NextNamed Indx3 WRChangeLoop1
  :SFSgood # Jumps here if no diffrences found
  @NextNamed Indx2 WRWidthLoop1
@NextNamed Indx1 WRHightLoop1
@PUSH 0
@PUSH 0
@CALL SCRmove
@PUSHI WinRefreshReturnAddr
@RET
:WinRefreshReturnAddr 0
0
#
# WinWrite will write a string at a given location x,y strptr (push x first)
:WinWrite
@POPI WinWriteReturnAddr
@POPI StrPtr
@POPI WinWYVal
@POPI WinWXVal
@PUSHI WinWXVal
@PUSHI WinWYVal
#@PRT " Start of Write at offset: "
@CALL SCRXY2I
#@PRTTOP
@DUP
@ADD WinAsIs
@POPI Scrt1   # Scrt1 is index of WinAsIs
@ADD WinToBe
@POPI Scrt2   # Scrt2 is index of WinToBe
@PUSHI WinWXVal
#@PRT "Calculated X: "
#@PRTTOP
@PUSHI WinWYVal
#@PRT "Calculate Y: "
#@PRTTOP
#
#INsert here code to save X and Y and calculate offset from WinAsIs and WinToBe
# Stack now has X,Y
@CALL SCRmove  #Move cursor to that location.
@PUSHI DefaultFG
@AND 0x0f      # Just to make sure its in valid range.
@RTL @RTL @RTL @RTL   #shift left 4 times so FG field is top nibble of byte
@ADDI DefaultBG       # Add the lower BG nibble
@MC2M 0 ScrCellStruct2   # Zero out the storage, then save as byte in the High Byte of the word.
@POPI ScrCellstruct3     #save color to 'high' part of ScrCellStruct2/3
@MC2M 0 Indx1
@PUSHI StrPtr
@CALL strlen
@POPI Indx2
#@PRT "Calcualted String Length:"
#@PRTTOP
@ForIfV2V Indx3 Indx1 Indx2 StrLoop1
   @PUSHII StrPtr
   @AND 0xff
#   @PRT "Ch("
#   @PRTTOP
#   @PRT ") "
   @ADDI ScrCellStruct2   #add the color part to the character Part
   @PUSHII Scrt1          # Insert New colored text at location.
   @PUSHI Scrt1
   @ADD 2
   @POPI Scrt1
   @INCI StrPtr
@NextNamed Indx3 StrLoop1

@PUSHI WinWriteReturnAddr
@RET
	
:WinWriteReturnAddr 0	



:ScrCellStruct0
b0
:ScrCellStruct1
b0
:ScrCellStruct2
b0
:ScrCellstruct3
0              # extra byte is to buffer from ReturnAddr
:ReturnAddr
0
:GivenColor 0
:DefaultFG 0
:DefaultBG 0
:FGColor1 0
:BGColor1 0
:Indx1 0
:Indx2 0
:Indx3 0
:Scrt1 0
:Scrt2 0
:Scrt3 0
:ChgFlg 0
:WinWYVal 0
:WinWXVal 0
:StrPtr 0
:CSICODE
"<ESC>["b0
#b$27
"["
b0
:WinAsIs
#123456789A123456789B123456789C123456789D123456789E123456789F123456789G123456789H
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
:WinToBe
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
"                                                                                "
:ENDSCREEN
ENDBLOCK
