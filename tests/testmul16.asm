I common.mc
L mul.ld
L softstack.ld
:Main . Main
@PUSH 10
@PUSH 15
@CALL MULU
@PRTTOP
@PRTSP
@PUSH -3
@CALL MUL
@POPI Result
@PRTSGNI Result
@END
:Result 0
