L common.mc
L screen.ld
L mul.ld
@CALL WinClear
@PUSH 25
@PUSH 5
@PUSH Message1
@CALL WinWrite
@END
:Message1 "Hello World"
