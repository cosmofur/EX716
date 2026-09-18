M USE_ONLY 1
I common.mc
L softstack.ld

@USE itos
L string.ld
L div.ld


L string.ld
L heapmgr.ld
:AVar 0 0
:BVar 0 0

:Main . Main

:StrA "123\0"
:StrB "456\0"

@PUSHI StrA
@PUSHI StrB
@CALL itos

@StackDump
@END
