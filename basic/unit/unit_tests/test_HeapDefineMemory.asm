M USE_ONLY 1
I common.mc

@USE HeapDefineMemory

L lmath.ld
L string.ld
L heapmgr.ld
L diskos.ld
L hexdump.ld
:AVar 0 0
:BVar 0 0

:Main . Main

# minimal heap init for symbol resolution
@PUSHI HeapBase
@PUSHI HeapSize
@CALL HeapDefineMemory

@PUSHI 16
@CALL HeapDefineMemory

:HeapBase 0
:HeapSize 1024

@StackDump
@END
