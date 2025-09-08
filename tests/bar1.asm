G ReturnEnd
G ReturnMain
L bar2.asm
L bar3.asm
=COne 1
=CTwo 2
=CThree 3
M JMP $$39 %1
M PUSH $$1 %1
M CAST $$42 %1
M PUSH $$1 %1
M POPNULL $$6
M NOP $$0
:Main . Main
@NOP
@PUSH Main
@POPNULL
:Location01
@NOP
@PUSH Location01
@POPNULL
:LocUnique01
@NOP
@PUSH LocUnique01
@POPNULL
@JMP InTwo
:ReturnMain
@NOP
@PUSH Location01
@POPNULL
@JMP InThree
:ReturnEnd
@PUSH Location01
@POPNULL
# End code
@PUSH 99 @CAST 0



