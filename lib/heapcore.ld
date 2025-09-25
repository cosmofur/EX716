# ----------------------------------------------------------------------
# heapcore.ld
# ----------------------------------------------------------------------
# Internal helpers for EX716 Heap Manager
#
# This file defines the relative offsets of heap and object header fields
# and simple macros for calculating addresses relative to a base pointer.
#
# These expand only to "base+offset" constants. No loops, math, or logic.
# The API layer (heapapi.ld) will combine these with @FETCH/@STORE.
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
#   @FETCHW @Heap_ObjSize(%obj)     ; read object size word
#   @STOREB @Heap_ObjFlag(%obj), 1  ; set object flag
#   @FETCHW @Heap_HeapSize(%heap)   ; read total heap size
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
# Macros (expand to base+offset)
# ------------------------------

# Heap fields
@Heap_FirstObj M %1+HeapOff_FirstObj
@Heap_Size     M %1+HeapOff_TotalSize

# Object fields
@Heap_ObjSize  M %1+ObjOff_Size
@Heap_ObjNext  M %1+ObjOff_NextPtr
@Heap_ObjFlag  M %1+ObjOff_Flag
