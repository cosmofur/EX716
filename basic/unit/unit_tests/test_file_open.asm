M USE_ONLY 1
I common.mc

@USE file_open
@USE HeapDefineMemory

L softstack.ld
L diskos.ld
L string.ld
L heapmgr.ld
:AVar 0 0
:BVar 0 0

:Main . Main

# disk functions depend on heap symbols
@PUSHI HeapBase
@PUSHI HeapSize
@CALL HeapDefineMemory

# dummy call (arguments not meaningful)
@CALL file_open

:HeapBase 0
:HeapSize 1024

@StackDump
@END
