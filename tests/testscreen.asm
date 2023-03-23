I common.mc
L mul.ld
L string.ld
L screen2.ld
@CALL WinClear
@PUSH 5
@PUSH 10
@PUSH HelloWorld
@CALL WinWrite
@PRT "Text Written"
#@CALL WinRefresh
@END
:HelloWorld "Hello World" b0

