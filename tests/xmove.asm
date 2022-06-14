I common.mc
L screen2.asm


@CALL WinInit
@CALL WinClear
@MC2M 0 KeyIn
@MC2M 20 Limit
@MC2M 40 XSpot
@MC2M 12 YSpot
M READC @PUSH PollReadCharI @POLL %1 @POPNULL
:MainLoop
  @READC KeyIn
  @PRTIC KeyIn
  @PUSHI KeyIn
  @CMP "Q" b0
  @JMPZ ExitLoop
  @CMP "l" b0
  @JMPZ MoveRight
  @CMP "k" b0
  @JMPZ MoveUp
  @CMP "j" b0
  @JMPZ MoveDown
  @CMP "h" b0
  @JMPZ MoveLeft
  @POPNULL
  @JMP MainLoop
:ExitLoop
@END
:Limit 0
:KeyIn 0 0 0
:XSpot 0
:YSpot 0
:MoveRight
@PUSHI XSpot @PUSHI YSpot @PUSH SpaceOut @CALL WinWrite
@INCI XSpot @PUSH 2 @PUSH WinWidth @SUBS
@CMPI XSpot @POPNULL
@JMPZ MRLimit
:MRLimitReturn
@PUSHI XSpot @PUSHI YSpot @PUSH PlusMark @CALL WinWrite
@RET
:MRLimit
@DECI XSpot
@JMP MRLimitReturn
:MoveLeft
@PUSHI XSpot @PUSHI YSpot @PUSH SpaceOut @CALL WinWrite
@DECI XSpot @PUSH 2
@CMPI XSpot @POPNULL
@JMPZ MLLimit
:MRLimitReturn
@PUSHI XSpot @PUSHI YSpot @PUSH PlusMark @CALL WinWrite
@RET
:MLLimit
@INCI XSpot
@JMP MLimitReturn
:MoveUp
@PUSHI XSpot @PUSHI YSpot @PUSH SpaceOut @CALL WinWrite
@DECI YSpot @PUSH 1 @PUSHI YSpot @ADDS
@CMPI YSpot @POPNULL
@JMPZ MULimit
:MULimitReturn
@PUSHI XSpot @PUSHI YSpot @PUSH PlusMark @CALL WinWrite
@RET
:MULimit
@INCI YSpot
@JMP MULimitReturn
:MoveDown
@PUSHI XSpot @PUSHI YSpot @PUSH SpaceOut @CALL WinWrite
@DECI YSpot @PUSH 1 @PUSHI YSpot @ADDS
@CMPI YSpot @POPNULL
@JMPZ MDLimit
:MDLimitReturn
@PUSHI XSpot @PUSHI YSpot @PUSH PlusMark @CALL WinWrite
@RET
:MDLimit
@INCI YSpot
@JMP MDLimitReturn

:SpaceOut " " b0
:PlusMark "+" b0
