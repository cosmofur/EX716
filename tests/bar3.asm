=COne 301
=CTwo 302
=CThree 303
M JMP $$39 %1
M PUSH $$1 %1
M CAST $$42 %1
M PUSH $$1 %1
M POPNULL $$6
M NOP $$0

G InThree
:InThree
@NOP
:Location01
@PUSH Location01
@POPNULL
$$0
:LocUnique03
@NOP
@PUSH LocUnique03
@POPNULL
@JMP ReturnEnd
