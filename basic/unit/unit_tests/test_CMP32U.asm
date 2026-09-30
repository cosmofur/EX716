M USE_ONLY 1
I common.mc

@USE CMP32U

L lmath.ld
L string.ld
L heapmgr.ld
L diskos.ld
L hexdump.ld
:AVar 0 0
:BVar 0 0

:Main . Main

@M32A2V $$$100 AVar
@M32A2V $$$200 BVar
@PUSH32I(V) AVar
@PUSH32I(V) BVar
@CALL CMP32U

@StackDump
@END
