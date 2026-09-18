M USE_ONLY 1
I common.mc
L softstack.ld

@USE SUB32S

L lmath.ld
L heapmgr.ld
:AVar 0 0
:BVar 0 0

:Main . Main

@M32A2V $$$100 AVar
@M32A2V $$$200 BVar
@PUSH32I(V) AVar
@PUSH32I(V) BVar
@CALL SUB32S

@StackDump
@END
