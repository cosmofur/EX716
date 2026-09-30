M USE_ONLY 1
I common.mc

@USE strncmp

L lmath.ld
L string.ld
L heapmgr.ld
L diskos.ld
L hexdump.ld
:AVar 0 0
:BVar 0 0

:Main . Main

:StrA "123\0"
:StrB "456\0"

@PUSHI StrA
@PUSHI StrB
@CALL strncmp

@StackDump
@END
