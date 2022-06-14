I common.mc
L mul.ld
L div.ld
L string.asm
@MC2M 1000 NumVal
@MC2M 2 Base
@PUSH StrPtr
@PUSHI NumVal
@PUSHI Base
@CALL itos
@PRT "Result: "
@PRTS StrPtr
@PRTNL
@END
:NumVal 0
:Base 0
:StrPtr 0 0 0 0 0 0 0 0

