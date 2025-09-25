# ----------------------------------------------------------------------
# heapdefs.ld
# ----------------------------------------------------------------------
# Definitions and constants for the EX716 Heap Manager
#
# This file contains all symbolic constants related to heap management.
# It is included by both heapcore.ld and heapapi.ld.
#
# Lesson 11 Note:
#   The heap is a region of memory set aside for dynamic allocation.
#   Each object allocated on the heap has a small *header* stored just
#   before the user data. These constants define the sizes and offsets
#   of those headers, as well as common error codes.
# ----------------------------------------------------------------------

# ------------------------------
# Heap Manager internal constants
# ------------------------------

=MinObjectSize   1      # Smallest allocatable object (bytes)
=SizeHeapHead    4      # Words used by the heap header (per heap)
=SizeObjectHead  3      # Words used by object header (per object)
=ObjectPtrOffset 2      # Offset (negative) from object base to pointer
=SizeFirstHead   7      # Combined size of first object + heap header

# Offsets relative to HeapID
=HeapOff_FirstObj 0
=HeapOff_TotalSize 2

# Offsets relative to ObjectID
=ObjOff_NextPtr -2
=ObjOff_Flag    -3
=ObjOff_Size    -1   # if we want to expose it explicitly


# ------------------------------
# Error Codes
#   (< 100 means failure)
# ------------------------------
=HeapErr_InvalidHeap    1   # Heap ID not recognized
=HeapErr_NoSpace        2   # Not enough room to allocate object
=HeapErr_BadObject      3   # Object ID invalid or corrupted
=HeapErr_ResizeFailed   4   # Resize could not be performed
=HeapErr_NotDeleted     5   # Object could not be deleted

# ------------------------------
# Return conventions
# ------------------------------
# On success, functions return:
#   HeapID   (>= 100) from HeapDefineMemory
#   ObjectID (>= 100) from HeapNewObject / HeapResizeObject
#
# On failure, functions return one of the error codes above (< 100).
# ------------------------------
