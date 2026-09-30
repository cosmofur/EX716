M USE_ONLY 1
I common.mc

@USE HexDump

L lmath.ld
L string.ld
L heapmgr.ld
L diskos.ld
L hexdump.ld
:AVar 0 0
:BVar 0 0

:Main . Main

# generic fallback
@CALL HexDump

@StackDump
@END
