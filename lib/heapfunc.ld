! HeapFuncSeen
M HeapFuncSeen 1
L heapdefs.ld
L heapcore.ld

# Public functions:


G HeapDefineMemory
G HeapNewObject
G HeapResizeObject
G HeapDeleteObject
G HeapListMap
G GetObjectRealSize
G HeapAppend


# ----------------------------------------------------------------------
# Function: HeapDefineMemory
#
# Purpose:
#   Initializes a new heap in memory. Creates the heap header and the
#   first empty object header at the given base address.
#
# Inputs:
#   Stack:  ( Address  SizeInBytes )
#       Address      = Start address of the heap region (>100)
#       SizeInBytes  = Total size of the heap region
#
# Outputs:
#   Stack:  ( HeapID )
#       HeapID >= 100 = pointer to the heap base (success)
#       HeapID < 100  = error code (failure)
#
# Heap Layout after call:
#   HeapID[0] = pointer to first object
#   HeapID[2] = total heap size (bytes)
#   First object header (Obj[-1..-3]) is zeroed and marked free
#
# Errors:
#   0 = invalid heap (overflow / too small)
#
# Notes:
#   - The caller must provide a valid memory block that does not overlap
#     other data.
#   - SizeInBytes is reduced internally by SizeHeapHead before storing
#     into HeapID[2].
# ----------------------------------------------------------------------
:HeapDefineMemory
@PUSHRETURN
@LocalVar HeapID 01
@LocalVar SizeInBytes 02
@LocalVar Index1 03

@POPI SizeInBytes
@POPI HeapID      # HeapID is start address of heap memory

# Test for overflow: if HeapID + SizeInBytes wraps below HeapID, fail
@PUSHI HeapID
@ADDI SizeInBytes
@IF_ULT_V HeapID
   @PRTLN "HeapID + Size Overflowed"
   @POPNULL
   @PUSH 0             # Returning zero means invalid heap
@ELSE
   @POPNULL

   # Save pointer to first object (HeapID + SizeFirstHead) at HeapID[0]
   @PUSHI HeapID
   @ADD SizeFirstHead
   @Heap_FirstObject HeapID @POPS

   # Save total heap size (SizeInBytes - SizeHeapHead) at HeapID[2]
   @PUSHI SizeInBytes
   @SUB SizeHeapHead
   @Heap_Size HeapID @POPS

   # Initialize first object’s header to zero
   @PUSHII HeapID
   @Heap_SetObjSizeI(%TOP,0)     # Obj[-1] = 0
   @Heap_SetObjNext(%TOP,0)      # Obj[-2] = 0
   @Heap_SetFlag(%TOP,0)         # Obj[-3] = 0 (free)

   @PUSHI HeapID                 # Return HeapID on success
@ENDIF

@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET



#
# ----------------------------------------------------------------------
# Function: HeapNewObject
#
# Purpose:
#   Allocate a new object of a given size from the heap.
#   Searches for a free block large enough; if none found, may extend
#   the chain at the end of the heap.
#
# Inputs:
#   Stack: ( HeapID  SizeInBytes )
#       HeapID      = pointer to heap base
#       SizeInBytes = requested object size (bytes)
#
# Outputs:
#   Stack: ( ObjectID )
#       ObjectID >= 100 = pointer to allocated object (success)
#       ObjectID < 100  = error code:
#           2 = request larger than heap size
#           3 = no room at heap tail
#
# Notes:
#   - Each object header contains:
#       Obj[-1] = size word
#       Obj[-2] = next object pointer
#       Obj[-3] = flag byte (0=free, 1=in use)
#   - Allocation may split a free block, creating a new object header.
#   - If extending the chain, a new object header is created at the tail.
# ----------------------------------------------------------------------
# NOTE ON IF-### / WHILE-### TAGS
#
#   In this lesson, all IF/ELSE/ENDIF and WHILE/ENDWHILE blocks
#   are annotated with labels like "IF-001" or "WHILE-001".
#
#   These labels are *not part of the assembler syntax*. They are
#   debugging markers to make it clear which ENDIF matches
#   which IF, and which ENDWHILE matches which WHILE.
#
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------


:HeapNewObject
@PUSHRETURN
@LocalVar HeapID 01
@LocalVar SizeInBytes 02
@LocalVar IndexX 03
@LocalVar NewNextObject 04
@LocalVar ContinueLoop 05
@LocalVar OldNextObject 06

# ----------------------------------------------------------------------
# (1) Setup and validation
# ----------------------------------------------------------------------

@POPI SizeInBytes
@POPI HeapID

# Start at the first object in this heap
@Heap_FirstObject HeapID
@POPI IndexX

# Fetch total size of heap
@Heap_Size HeapID

# If request > total heap size → fail immediately
@IF_ULT_V SizeInBytes                               # IF-001
   # Error code 2: request larger than heap
   @MA2V 2 ContinueLoop
@ELSE                                               # IF-001
   @POPNULL
   # ContinueLoop variable doubles as “state”:
   #   0 = keep searching
   #   1 = found / allocated
   #   2..4 = error codes
   @MA2V 0 ContinueLoop
   @PUSHI ContinueLoop
   @WHILE_ZERO                                      # WHILE-001
      @POPNULL

      # ------------------------------------------------------------------
      # (2) Search the object chain
      # ------------------------------------------------------------------

      # Test allocation flag
      @Heap_ObjFlag IndexX
      @IF_ZERO                                      # IF-002
         # ------------------------------------------------------------------
         # (2A) Current object is FREE
         # ------------------------------------------------------------------
         @POPNULL
         @PUSHI HeapID
         @PUSHI IndexX
         @CALL GetObjectRealSize   # returns size of this block
         @IF_UGE_V SizeInBytes                      # IF-003
            # This block is large enough → mark ContinueLoop=1 to stop search
            @MA2V 1 ContinueLoop

            # Get pointer to next object in chain (may be 0 if none)
            @Heap_ObjNext IndexX
            @POPI OldNextObject

            # Compute address of where new object would begin if split
            @PUSHI IndexX
            @ADDI SizeInBytes
            @ADD SizeObjectHead
            @POPI NewNextObject

            # Calculate leftover size if we split off this block
            @SUBI SizeInBytes
            @SUB SizeObjectHead
            @POPI Remaining

            # Only split if leftover is large enough for a full object
            @PUSHI Remaining
            @IF_UGE_V MinSplitSize                  # IF-004
               # --- Split case ---
               # Zero out new object’s header
               @Heap_SetObjSizeI NewNextObject 0
               @Heap_SetObjNext NewNextObject 0
               @Heap_SetFlag   NewNextObject 0

               # Link current object → NewNextObject → OldNextObject
               @Heap_SetObjNext IndexX NewNextObject
               @Heap_SetObjNext NewNextObject OldNextObject
            @ELSE                                   # IF-004
               # Not enough space for a real object → don’t split off
               @POPNULL
            @ENDIF                                  # ENDIF-004

            # Finally, mark current object as in use
            @Heap_SetFlag IndexX 1
         @ELSE                                      # IF-003
            # ------------------------------------------------------------------
            # (2B) Current object is FREE but TOO SMALL
            # ------------------------------------------------------------------
            @POPNULL
            @Heap_ObjNext IndexX
            @IF_ZERO                                # IF-005
               # No "next" object → end of chain
               @POPNULL
               @PUSHI IndexX   # Leave IndexX for Section 3 (tail extend)
            @ELSE                                   # IF-005
               # There *is* a next object → continue search
               @POPI IndexX
               @POPNULL
            @ENDIF                                  # ENDIF-005
         @ENDIF                                     # ENDIF-003
      @ELSE                                         # IF-002
         # ------------------------------------------------------------------
         # (2C) Current object is IN USE
         # ------------------------------------------------------------------
         @POPNULL
         @Heap_ObjNext IndexX
         @POPI IndexX
         @PUSHI IndexX
         @IF_ZERO                                   # IF-006
            # End of chain reached with no suitable block
            @POPNULL
            # Error code 4: walked chain but found nothing
            @MA2V 4 ContinueLoop
         @ELSE                                      # IF-006
            # Continue search with next object
            @POPNULL
         @ENDIF                                     # ENDIF-006
      @ENDIF                                        # ENDIF-002

      # ------------------------------------------------------------------
      # (3) Tail extension
      #
      # - If we reached the end of the chain (no next object),
      #   and there is still space in the heap, we can append a new object.
      # - This creates a header at the tail and links it into the chain.
      # - If not enough space remains, allocation fails with error code 3.
      # ------------------------------------------------------------------

      @Heap_ObjNext IndexX
      @IF_ZERO                                        # IF-007
         @POPNULL

         # How much space remains from IndexX to end of heap?
         # Remaining = (HeapSize - (IndexX - HeapID)) - SizeObjectHead
         @PUSHI IndexX
         @SUBI HeapID
         # Subtract heap header and object header to ensure space covers both metadata and payload          
         @SUB SizeHeapHead
         @SUB SizeObjectHead

         @IF_UGT_V SizeInBytes                       # IF-008
            # There is sufficient space → create new object
            @POPNULL

            # Mark ContinueLoop=IndexX to break out of loop with result
            @MV2V IndexX ContinueLoop

            # Compute address of new object’s header
            @PUSHI IndexX
            @ADDI SizeInBytes
            @SUB SizeObjectHead
            @POPI NewNextObject

            # Mark IndexX as active (in use)
            @Heap_SetFlag IndexX 1

            # Save pointer to future NewNextObject
            @Heap_SetObjNext IndexX NewNextObject

            # Zero out header of NewNextObject
            @Heap_SetObjSizeI NewNextObject 0
            @Heap_SetObjNext NewNextObject 0
            @Heap_SetFlag   NewNextObject 0
         @ELSE                                       # IF-008
            # Not enough space left in heap → fail
            # 3 = no room at heap tail (end-of-chain allocation failure)
            @MA2V 3 ContinueLoop
         @ENDIF                                      # ENDIF-008
      @ENDIF                                         # ENDIF-007
   @ENDWHILE                                        # ENDWHILE-001
@ENDIF                                              # ENDIF-001

@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

# ----------------------------------------------------------------------
# Function: HeapResizeObject
#
# Purpose:
#   Resize an existing object to a new size.
#   - Always allocates a *new* object of the requested size.
#   - Copies the old contents into the new object.
#   - Marks the old object as free.
#
# Inputs:
#   Stack: ( HeapID  ObjectID  NewSizeInBytes )
#
# Outputs:
#   Stack: ( NewObjectID )
#       >= 100 = pointer to resized object (success)
#       <  100 = error code from HeapNewObject
#
# Notes:
#   - This is a "copy and free" strategy, not in-place reallocation.
#   - If new size < old size, only NewSize bytes are copied.
#   - If new size >= old size, the entire old contents are copied.
# ----------------------------------------------------------------------

:HeapResizeObject
@PUSHRETURN
@LocalVar HeapID 01
@LocalVar ObjectID 02
@LocalVar NewSizeInBytes 03
@LocalVar IndexX 04
@LocalVar IndexY 05
@LocalVar NewObject 06

# ----------------------------------------------------------------------
# (1) Setup
# ----------------------------------------------------------------------
@POPI NewSizeInBytes
@POPI ObjectID
@POPI HeapID

# ----------------------------------------------------------------------
# (2) Try to allocate a new object of NewSize
# ----------------------------------------------------------------------
@PUSHI HeapID
@PUSHI NewSizeInBytes
@CALL HeapNewObject
@POPI NewObject

# ----------------------------------------------------------------------
# (3) Did allocation succeed?
# ----------------------------------------------------------------------
@PUSHI NewObject
@IF_UGE_A 100                                # IF-001
   @POPNULL

   # -------------------------------------------------------------------
   # (3a) Copy old object data into the new one
   # -------------------------------------------------------------------

   # Copy next pointer link
   @Heap_ObjNext ObjectID
   @PUSHS
   @Heap_SetObjNext NewObject OldNextObject

   # Mark new object as in use
   @Heap_SetFlag NewObject 1

   # Get size of old object
   @PUSHI HeapID
   @PUSHI ObjectID
   @CALL GetObjectRealSize
   @POPI IndexY    # Size of old Object

   # If NewSize < OldSize, shrink copy length
   @PUSHI IndexY
   @IF_UGT_V NewSizeInBytes                  # IF-002
      @MV2V NewSizeInBytes IndexY
      @POPNULL
   @ELSE                                     # IF-002
      @POPNULL
   @ENDIF                                    # ENDIF-002

   # Copy byte-by-byte
   @ForIA2V IndexX 0 IndexY
      @PUSHI ObjectID @ADDI IndexX @PUSHS @AND 0xff
      @PUSHI NewObject @ADDI IndexX @DUP @SWP @PUSHS @AND 0xff00 @ORS @POPS
   @Next IndexX

   # -------------------------------------------------------------------
   # (3b) Free the old object
   # -------------------------------------------------------------------
   @Heap_SetFlag ObjectID 0

   # Return new object ID
   @PUSHI NewObject
@ELSE                                         # IF-001
   # Allocation failed — NewObject already holds error code
   @POPNULL
@ENDIF                                        # ENDIF-001

@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
# ----------------------------------------------------------------------
# Notes on Resize Strategy
#
# This version of HeapResizeObject always uses the "copy + free" model:
#   1. Allocate a new object of the requested size.
#   2. Copy the contents of the old object.
#   3. Mark the old object as free.
#
# Advantages:
#   - Simple and predictable.
#   - Old data is never lost until the new object is safely allocated.
#
# Disadvantage:
#   - Requires enough memory for *both* old and new objects at once,
#     which can temporarily double the space requirement.
#
# In theory, we could free the old object *before* allocating the new one
# to reduce pressure, or even try to "expand in place" by merging with
# adjacent free blocks. This would be more memory-efficient but risky:
#   - If the new allocation fails after freeing, the old data is lost.
#
# Advanced heap managers often attempt in-place growth/shrink first,
# then fall back to the copy+free approach if that fails. For now we
# keep the safer, simpler model for clarity.
# ----------------------------------------------------------------------



#
# ----------------------------------------------------------------------
# Function: HeapDeleteObject
#
# Purpose:
#   Free an allocated object, making its space available for reuse.
#   This is a "non-destructive" delete: it only marks the object as free
#   and then calls HeapDefrag to merge adjacent free blocks.
#
# Inputs:
#   Stack: ( HeapID  ObjectID )
#
# Outputs:
#   Stack: ( Status )
#       0 = success
#       other codes = from HeapDefrag (future expansion)
#
# Notes:
#   - Does not wipe object contents, only clears the "in use" flag.
#   - Adjacent free blocks may be merged during defragmentation.
# ----------------------------------------------------------------------

:HeapDeleteObject
@PUSHRETURN
@LocalVar HeapID 01
@LocalVar ObjectID 02

# ----------------------------------------------------------------------
# (1) Pop inputs
# ----------------------------------------------------------------------
@POPI ObjectID
@POPI HeapID

# ----------------------------------------------------------------------
# (2) Mark object as free
# ----------------------------------------------------------------------
@Heap_SetFlag ObjectID 0

# ----------------------------------------------------------------------
# (3) Defragment heap to merge adjacent free objects
# ----------------------------------------------------------------------
@PUSHI HeapID
@CALL HeapDefrag

# ----------------------------------------------------------------------
# (4) Return
# ----------------------------------------------------------------------
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
# ----------------------------------------------------------------------
# Notes on Delete Strategy
#
# This implementation of HeapDeleteObject is a *non-destructive delete*:
#   - It only clears the "in use" flag in the object header.
#   - The data payload of the object is left untouched in memory.
#   - HeapDefrag is then called to merge adjacent free blocks.
#
# Advantages:
#   - Fast and simple.
#   - Old data can still be inspected for debugging or copied later.
#
# Disadvantages:
#   - Sensitive information remains in memory until overwritten.
#   - A program that assumes freed memory is cleared may be surprised.
#
# Possible alternatives:
#   - *Destructive delete*: zero out or overwrite the object's payload
#     at the time of deletion (more secure, slower).
#   - *Lazy defrag*: skip the immediate call to HeapDefrag and merge
#     free blocks only on demand, trading memory fragmentation for speed.
#
# ----------------------------------------------------------------------
#
#
# ----------------------------------------------------------------------
# Function: HeapDefrag
#
# Purpose:
#   Walk the heap and merge adjacent free objects into a single block.
#
# Inputs:
#   Stack: ( HeapID )
#
# Outputs:
#   Stack: ( Status )
#       0 = success
#
# Notes:
#   - Only combines consecutive free nodes.
#   - Does not move or copy data; just rewires the "next" pointers.
#   - Called automatically after HeapDeleteObject, but can also be
#     invoked manually to reduce fragmentation.
# ----------------------------------------------------------------------

:HeapDefrag
@PUSHRETURN
@LocalVar HeapID 01
@LocalVar IndexX 02
@LocalVar IndexY 03

# ----------------------------------------------------------------------
# (1) Pop input heap ID
# ----------------------------------------------------------------------
@POPI HeapID

# Start at the first object
@PUSHII HeapID
@POPI IndexX

# ----------------------------------------------------------------------
# (2) Walk chain, stop when IndexX=0 (end of chain)
# ----------------------------------------------------------------------
@PUSHI IndexX
@WHILE_NOTZERO                             # WHILE-001
   # Check flag of current object
   @Heap_ObjFlag IndexX
   @IF_NOTZERO                             # IF-001
      # Current object is in use → advance to next
      @POPNULL
      @Heap_ObjNext IndexX
      @POPI IndexX
      @PUSHI IndexX                        # prepare for next WHILE test
   @ELSE                                   # IF-001
      # Current object is free
      @POPNULL

      # Get pointer to next object, keep IndexX pointing here
      @Heap_ObjNext IndexX
      @POPI IndexY

      # Check flag of IndexY
      @Heap_ObjFlag IndexY
      @WHILE_ZERO                          # WHILE-002
         # IndexY is also free → merge it into IndexX
         @POPNULL

         # Fetch "next" pointer of IndexY
         @Heap_ObjNext IndexY
         @DUP

         # Make IndexX skip IndexY → point directly to IndexY’s next
         @Heap_SetObjNext IndexX %TOP

         @IF_ZERO                          # IF-002
            # End of chain reached
            @POPNULL
            @PUSH 2   # break signal for inner WHILE
         @ELSE                             # IF-002
            # IndexY points further down chain → keep testing
            @POPI IndexY
            @Heap_ObjFlag IndexY
         @ENDIF                            # ENDIF-002
      @ENDWHILE                            # ENDWHILE-002

      # Inner loop finished. TOS could be:
      #  1 → stopped because next was in-use
      #  2 → stopped because we reached end-of-chain

      @IF_EQ_A 2                           # IF-003
         # Reached end of chain while merging → terminate outer loop
         @POPNULL
         @PUSH 0
      @ELSE                                # IF-003
         @POPNULL
         # Advance IndexX for next outer loop check
         @Heap_ObjNext IndexY
         @POPI IndexX
         @PUSHI IndexY
      @ENDIF                               # ENDIF-003
   @ENDIF                                  # ENDIF-001
@ENDWHILE                                  # ENDWHILE-001

# ----------------------------------------------------------------------
# (3) Return status
# ----------------------------------------------------------------------
@POPNULL
@PUSH 0   # success

@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

# ----------------------------------------------------------------------
# Notes on Defrag Strategy
#
# - This implementation only merges *adjacent* free blocks.
# - It does not shift object data; pointers to allocated objects
#   remain valid, so defrag is safe to call at any time.
# - Future enhancement: add "lazy defrag" (only when needed) vs
#   "eager defrag" (on every delete).
# ----------------------------------------------------------------------


# ----------------------------------------------------------------------
# Function: HeapListMap
#
# Purpose:
#   Diagnostic function to print a map of all objects in a heap.
#
# Inputs:
#   Stack: ( HeapID )
#
# Outputs:
#   Prints one line per object:
#     ObjAddr  Status  Size  NextObj
# ----------------------------------------------------------------------

:HeapListMap
@PUSHRETURN
@LocalVar HeapID 01
@LocalVar ObjectID 02

# ----------------------------------------------------------------------
# (1) Pop input and fetch first object
# ----------------------------------------------------------------------
@POPI HeapID
@PUSHII HeapID
@POPI ObjectID

# Header
@PRT "Heap Map for HeapID="
@PRTHEXI HeapID
@PRTNL
@PRT "-----------------------------------------------"
@PRTNL
@PRT "ObjAddr   Status  Size(bytes)  NextObj"
@PRTNL
@PRT "-----------------------------------------------"
@PRTNL

# ----------------------------------------------------------------------
# (2) Walk chain and print one line per object
# ----------------------------------------------------------------------
@PUSHI ObjectID
@WHILE_NOTZERO                           # WHILE-001
   @POPI ObjectID

   # Address
   @PRTHEXI ObjectID
   @PRT "   "

   # Status
   @Heap_ObjFlag ObjectID
   @IF_ZERO                              # IF-001
      @PRT "FREE "
   @ELSE                                 # IF-001
      @PRT "USED "
   @ENDIF                                # ENDIF-001

   @PRT "  "

   # Size
   @PUSHI HeapID
   @PUSHI ObjectID
   @CALL GetObjectRealSize
   @PRTHEXTOP
   @POPNULL
   @PRT "       "

   # Next object pointer
   @Heap_ObjNext ObjectID
   @PUSHS
   @PRTHEXTOP
   @POPNULL

   @PRTNL

   # Advance to next
   @Heap_ObjNext ObjectID
   @POPI ObjectID
   @PUSHI ObjectID
@ENDWHILE                                # ENDWHILE-001

# ----------------------------------------------------------------------
# (3) Done
# ----------------------------------------------------------------------
@POPNULL
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
   
   
# ----------------------------------------------------------------------
# Function: GetObjectRealSize
#
# Purpose:
#   Compute the usable size of an object by looking at the distance
#   between this object and the next one in the chain. If there is
#   no next object (NextPtr=0), the size extends to the end of the heap.
#
# Inputs:
#   Stack: ( HeapID  ObjectID )
#
# Outputs:
#   Stack: ( SizeInBytes )
#
# Notes:
#   - Subtracts the object header size, so result is just payload bytes.
#   - Does not check whether the object is marked free/used.
# ----------------------------------------------------------------------

:GetObjectRealSize
@PUSHRETURN
@PUSHLOCALI ObjectID
@PUSHLOCALI HeapID
@POPI ObjectID
@POPI HeapID

# ----------------------------------------------------------------------
# (1) Find address of "next" object, or heap end if none
# ----------------------------------------------------------------------
@Heap_ObjNext ObjectID
@IF_NOTZERO                             # IF-001
   @POPNULL
   # Next object exists → get its address
   @Heap_ObjNext ObjectID
   @PUSHS
@ELSE                                   # IF-001
   @POPNULL
   # No next object → extend to end of heap
   @Heap_Size HeapID
   @ADDI HeapID
@ENDIF                                  # ENDIF-001

# ----------------------------------------------------------------------
# (2) Subtract this object’s base to get size
# ----------------------------------------------------------------------
@SUBI ObjectID
@SUB SizeObjectHead    # exclude header bytes

# ----------------------------------------------------------------------
# (3) Return result
# ----------------------------------------------------------------------
@POPLOCAL HeapID
@POPLOCAL ObjectID
@POPRETURN
@RET



# ----------------------------------------------------------------------
# Function: HeapAppend
#
# Purpose:
#   Append the contents of Object2 onto Object1, starting at Object1+Offset.
#   If Object1 is too small to hold Object2’s data, it is resized first.
#
# Inputs:
#   Stack: ( HeapID  Object1  Object2  Offset )
#       HeapID   = heap base
#       Object1  = destination object
#       Object2  = source object
#       Offset   = byte offset into Object1 where append begins
#
# Outputs:
#   Stack: ( Object1ID )
#       >= 100 = pointer to (possibly resized) Object1 containing appended data
#       <  100 = error code (e.g. from HeapResizeObject)
#
# Notes:
#   - Copy is always raw byte-for-byte.
#   - Resizing is done via HeapResizeObject if needed.
#   - If resize fails, error code is returned and copy is skipped.
# ----------------------------------------------------------------------

:HeapAppend
@PUSHRETURN
@LocalVar HeapID 01
@LocalVar Object1 02
@LocalVar Index1 03
@LocalVar Offset 04
@LocalVar NewObject 05
@LocalVar Object1Size 06
@LocalVar Object2Size 07
@LocalVar Object2 08

# ----------------------------------------------------------------------
# (1) Pop inputs
# ----------------------------------------------------------------------
@POPI Offset
@POPI Object2
@POPI Object1
@POPI HeapID

# ----------------------------------------------------------------------
# (2) Calculate sizes of Object1 and Object2
# ----------------------------------------------------------------------
@PUSHI Object1
@PUSHI HeapID
@CALL GetObjectRealSize
@POPI Object1Size

@PUSHI Object2
@PUSHI HeapID
@CALL GetObjectRealSize
@POPI Object2Size

# ----------------------------------------------------------------------
# (3) Ensure Object1 is large enough to hold Object2+Offset
# ----------------------------------------------------------------------
@PUSHI Object1Size
@SUBI Offset
@IF_LT_V Object2Size                      # IF-001
   # Object1 too small → expand
   @POPNULL
   @PUSHI Object1Size
   @SUBI Offset
   @ADDI Object2Size
   @PUSHI Object1
   @PUSHI HeapID
   @CALL HeapResizeObject
   @POPI Object1   # May now be new address, or error code
@ENDIF                                      # ENDIF-001

# ----------------------------------------------------------------------
# (4) If resize succeeded (Object1 >= 100), append Object2
# ----------------------------------------------------------------------
@PUSHI Object1
@IF_UGE_A 100                              # IF-002
   @POPNULL
   @ForIA2V Index1 0 Object2Size
      @PUSHI Object2 @ADDI Index1 @PUSHS
      @PUSHI Object1 @ADDI Offset @ADDI Index1 @POPS
   @Next Index1
@ELSE                                      # IF-002
   # Resize failed — Object1 is error code, do nothing
   @POPNULL
@ENDIF                                     # ENDIF-002

# ----------------------------------------------------------------------
# (5) Return Object1 (new or error code)
# ----------------------------------------------------------------------
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
