I common.mc
L string.asm
L screen2.asm
@CALL WinInit
@CALL WinClear
@PUSH 0 @PUSH 1
@PUSH TopBar
@CALL WinWrite
@MC2M 40 CURX
@MC2M 12 CURY
@PUSHI CURX @PUSHI CURY @PUSH STRVAL	
@CALL WinWrite
@CALL WinRefresh
@PUSH STRVAL

	
:TopLoop
  @PUSH STRVAL   @PUSHI CURX   @PUSH 10   @CALL itos  # CURX to String
  @PUSH 1 @PUSH 2 @PUSH STRVAL  @CALL WinWrite        # Write at 1,2
  @PUSH STRVAL   @PUSHI CURY  @PUSH 10    @CALL itos  # CURY to String
  @PUSH 5 @PUSH 2 @PUSH STRVAL  @CALL WinWrite        # Write at 5,2
  @PUSHI CURX @PUSHI CURY @PUSH SPACESTR @CALL WinWrite
  @READC CHRIN
  @PUSHI CHRIN
  @CMP 0 @JNZ KeyWasRead
  @POPNULL
  @JMP TopLoop
:KeyWasRead
  @CMP "l" b0  # Using hjkl vi like directions
  @JNZ NotRight
    @INCI CURX
    @CALL CheckRange
  :NotRight
  @CMP b12 b0	# Ctrl L
  @JNZ NotCtrlL
    @CALL 
  @CMP "h" b0
  @JNZ NotLeft
    @DECI CURX
    @CALL CheckRange
  :NotLeft
  @CMP "k" b0
  @JNZ NotUp
     @DECI CURY
     @CALL CheckRange
  :NotUp
  @CMP "j" b0
  @JNZ NotDown
     @INCI CURY
     @CALL CheckRange
  :NotDown
  @CMP "q" b0
     @JMPZ EndLoop
  @POPNULL
  @PUSHI CURX @PUSHI CURY @PUSH XSTR @CALL WinWrite
  @CALL WinRefresh
  @JMP TopLoop
:EndLoop
@PUSH 1 @PUSH 20
@PUSH STRVAL
@CALL WinWrite
@CALL WinRefresh
@END
:CheckRange
# Function that checks if CURX and CURY are in valid ranges.
# No paramerters so we can just leave return on stack
#
@PUSHI CURX @CMP 80 @POPNULL
@JGT NotXOver
  @MC2M 80 CURX
  @JMP Ytests
:NotXOver
@PUSHI CURX @CMP 0 @POPNULL
@JNZ Ytests
  @MC2M 1 CURX
:Ytests
@PUSHI CURY @CMP 24 @POPNULL
@JGT NotYOver
  @MC2M 24 CURY
  @JMP EndTests
:NotYOver
@PUSHI CURY @CMP 1 @POPNULL # Top Line is Ruler Bar
@JNZ EndTests
  @MC2M 2 CURY
:EndTests
@RET


:TestStr "Test" b0
:TopBar "0----5----1----5----2----5----3----5----4----5----5----5----6----5----7----5" b0
:STRVAL "Start Test" b0
:COUNT1 0
:COUNT2 0
:CHRIN 0
:XSTR "X" b0
:SPACESTR " " b0

:CURX 0
:CURY 0
