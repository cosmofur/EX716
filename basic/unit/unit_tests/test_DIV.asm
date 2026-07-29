M USE_ONLY 1
I common.mc

@USE DIV

L heapmgr.ld
L div.ld

:AVar 0 0
:BVar 0 0

:Main . Main

@PUSHI 100
@PUSHI 5
@CALL DIV

@StackDump
@END
