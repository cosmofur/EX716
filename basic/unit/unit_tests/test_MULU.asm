M USE_ONLY 1
I common.mc

@USE MULU

L softstack.ld
L mul.ld
L heapmgr.ld
:AVar 0 0
:BVar 0 0

:Main . Main

@PUSHI 100
@PUSHI 5
@CALL MULU

@StackDump
@END
