M USE_ONLY 1
I common.mc

@USE FSReadHeader
@USE HeapDefineMemory
L softstack.ld

L heapmgr.ld
L diskos.ld

:AVar 0 0
:BVar 0 0

:Main . Main

# disk functions depend on heap symbols
@PUSHI HeapBase
@PUSHI HeapSize
@CALL HeapDefineMemory

# dummy call (arguments not meaningful)
@CALL FSReadHeader

:HeapBase 0
:HeapSize 1024

@StackDump
@END
