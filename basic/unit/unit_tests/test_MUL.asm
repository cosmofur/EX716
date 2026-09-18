M USE_ONLY 1
I common.mc
L heapmgr.ld

@USE MUL
L mul.ld

:AVar 0 0
:BVar 0 0

:Main . Main

@PUSHI 100
@PUSHI 5
@CALL MUL

@StackDump
@END
