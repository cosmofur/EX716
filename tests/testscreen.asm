I common.mc
L screen2.asm
@CALL WinInit
@CALL WinClear
@PUSH 10 @PUSH 5     # Spot is down 5 lines, and over 10 characters
@PUSH String
@CALL WinWrite
@CALL WinRefresh
@PUSH 10 @PUSH 6
@PUSH String
@CALL WinWrite
@CALL WinRefresh
@PUSH 10 @PUSH 7
@PUSH String
@CALL WinWrite
@CALL WinRefresh
@PUSH 10 @PUSH 8
@PUSH String
@CALL WinWrite
@CALL WinRefresh
@PUSH 10 @PUSH 5
@PUSH String2
@CALL WinWrite
@CALL WinRefresh

@END
:String "Hello World" b0
:String2 "GoodBye Now" b0
