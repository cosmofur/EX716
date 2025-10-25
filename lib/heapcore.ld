! HeapMgrCore
M HeapMgrCore
# ----------------------------------------------------------------------
# heapcore.ld
# ----------------------------------------------------------------------
# Internal helpers for EX716 Heap Manager
#
# This file defines the relative offsets of heap and object header fields
# and provides macros that expand into @PUSHI/@POPS code sequences to
# directly read or write those fields. Use these instead of hard-coding
# offsets in the API layer.
#
# Layout summary:
#
#   HeapID[0]   = pointer to first object
#   HeapID[2]   = total heap size in bytes
#
#   ObjectID[-1] = size of object (word)
#   ObjectID[-2] = pointer to next object (or 0 if last)
#   ObjectID[-3] = flag byte (0=free, 1=in use)
#
# Usage examples:
#   @Heap_ObjSize(ObjectID)          ; push size word
#   @Heap_SetObjSizeI(ObjectID,123)  ; write size word
#   @Heap_ObjFlag(ObjectID)          ; push flag byte (0/1)
#   @Heap_SetFlag(ObjectID,1)        ; set flag immediate
#   @Heap_FirstObject(HeapID)        ; push first object pointer
#   @Heap_Size(HeapID)               ; push total heap size
# ----------------------------------------------------------------------

L heapdefs.ld

# ------------------------------
# Offsets relative to HEAP base
# ------------------------------
=HeapOff_FirstObj   0    # word: pointer to first object
=HeapOff_TotalSize  2    # word: total heap size (bytes)

# ------------------------------
# Offsets relative to OBJECT base
# ------------------------------
=ObjOff_Size       -1    # word: object size
=ObjOff_NextPtr    -2    # word: next object pointer
=ObjOff_Flag       -3    # byte: allocation flag

# ------------------------------
# Macros
# ------------------------------

# Heap_FirstObject(HeapID)
# Push the word at HeapID[0] = pointer to first object
M Heap_FirstObject @PUSHI %1 @ADD HeapOff_FirstObj @PUSHS

# Heap_Size(HeapID)
# Push the word at HeapID[2] = total heap size (bytes)
M Heap_Size @PUSHI %1 @ADD HeapOff_TotalSize @PUSHS

# Heap_ObjSize(ObjectID)
# Push the word at ObjectID[-1] = size of object
M Heap_ObjSize @PUSHI %1 @ADD ObjOff_Size @PUSHS

# Heap_SetObjSizeI(ObjectID, Value)
# Store Value into ObjectID[-1]
M Heap_SetObjSizeI \
    @PUSHI %2 \
    @PUSHI %1 @ADD ObjOff_Size @POPS

# Heap_ObjNext(ObjectID)
# Push the word at ObjectID[-2] = next object pointer
M Heap_ObjNext @PUSHI %1 @ADD ObjOff_NextPtr @PUSHS

# Heap_SetObjNext(ObjectID, NextAddr)
# Store NextAddr into ObjectID[-2]
M Heap_SetObjNext \
    @PUSHI %2 \
    @PUSHI %1 @ADD ObjOff_NextPtr @POPS

# Heap_ObjFlag(ObjectID)
# Push the byte at ObjectID[-3] = allocation flag
M Heap_ObjFlag @PUSHI %1 @ADD ObjOff_Flag @PUSHS @AND 0xff

# Heap_SetFlag(ObjectID, Flag)
# Store immediate flag (0 or 1) into ObjectID[-3]
M Heap_SetFlag(Object,Flag) \
    @PUSHI %1 @ADD ObjOff_Flag @PUSHS \
    @AND 0xff00 @PUSH %2 @ORS \
    @PUSHI %1 @ADD ObjOff_Flag @POPS

# Heap_SetFlagI(ObjectID, FlagVar)
# Store flag from variable into ObjectID[-3]
M Heap_SetFlagI(Object,FlagVar) \
    @PUSHI %1 @ADD ObjOff_Flag @PUSHS \
    @AND 0xff00 @PUSHI %2 @ORS \
    @PUSHI %1 @ADD ObjOff_Flag @POPS
ENDBLOCK
