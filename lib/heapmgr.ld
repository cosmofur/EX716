! __LIB_HEAPMGR_LOADED
M __LIB_HEAPMGR_LOADED 1
I heapmgr.ref
L softstack.ld
P Loading heapmgr.ld


# --- External dependencies (not defined in this file) ---
#  GetObjectRealSize

G OBJ_FLAG_LOC G OBJ_NEXT_LOC G OBJ_HEAD_SIZE G HEAP_SIZE_LOC G HEAP_FIRST_OBJ_LOC G HEAP_HEAD_SIZE
G HeapDefrag

G HeapDefineMemory      # HeapDefineMemory(Address,SizeBytes):HeapID
G HeapNewObject         # HeapNewObject(HeapID,SizeBytes):ObjectID
G HeapResizeObject      # HeapResizeObject(HeapID,ObjectID,NewSizeBytes):ObjectID
G HeapDeleteObject      # HeapDeleteObject(HeapID,ObjectID):0|error
G HeapListMap           # HeapListMap(HeapID)
G GetObjectRealSize     # GetObjectRealSize(HeapID, ObjectID):SizeBytes
G HeapAppend            # HeapAppend(ObjID1,ObjID2,Offset):NewObjectID
G HeapValidate          # HeapValidate(HeapID):0|error(1|2|3)

# Global Variabls
G OBJ_FLAG_LOC G OBJ_NEXT_LOC G HEAP_SIZE_LOC G HEAP_FIRST_OBJ_LOC 

# This is the heap manager module
=OBJ_FLAG_LOC  3
=OBJ_NEXT_LOC  2
=OBJ_HEAD_SIZE 3
=HEAP_SIZE_LOC 2
=HEAP_FIRST_OBJ_LOC 0
=HEAP_HEAD_SIZE 4
=MinObjectSize OBJ_HEAD_SIZE+2
=SizeFirstHead HEAP_SIZE_LOC+HEAP_FIRST_OBJ_LOC+1


# It provides the following services
# HeapDefineMemory(LowAddress(>100), SizeInBytes):HeapID Return < 100 is error code
# HeapNewObject(HeapID,Size_in_Bytes):ObjectID Return < 100 is Error code
# HeapResizeObject(HeapID,ObjectID,NewSize_In_Bytes):ObjectID Return < 100 is error code
# HeapDeleteObject(HeapID,ObjectID):StatusCode Success==0 other wise error code
# GetObjectRealSize(HeapID,ObjectID) Calculates the space between ObjectID and next.
# HeapDefrag(HeapID) Walks though heap and tries to merge free objects that are next to each other.
# HeapAppend(ObjectID1,ObjectId2,offset):ObjectID  Appends Object2 to Object1[:offset] 
#
# HeapID is ptr to memory
# HeapID[HEAP_FIRST_OBJ_LOC]=16b Ptr to First Object in Heap
# HeapID[HEAP_SIZE_LOC]=16b total size of heap to help avoid overflow.
#
# ObjectID[- OBJ_NEXT_LOC]=16b Ptr to Next Object Entry or zero if last entry
# ObjectID[- OBJ_FLAG_LOC]=8b flag. (0=Free, 1=In-use)
#
#
#
# Function HeapDefineMemory(Address,SizeInBytes)
# Address should be start of free memory, and size is how much to allocate.
@FUNCTION HeapDefineMemory
:HeapDefineMemory     # ( HeapID, SizeBytes)
@PUSHRETURN
   @LocalVar HeapID 01
   @LocalVar SizeInBytes 02
   @LocalVar Index1 03

   #
   @POPI SizeInBytes
   @POPI HeapID      # At this point the HeapID is same as address where heap memory starts
   #
   # test for overflow
   @PUSHI HeapID
   @ADDI SizeInBytes
   @IF_ULT_V HeapID   # If overflows 0xffff memory, then value will rotate to a number less than HeapID
      @PRTLN "HeapID + Size Overflowed"
      @POPNULL
      @PUSH 0        # Returning zero means the heap request was invalid
   @ELSE
      @POPNULL
      @PUSHI HeapID
      @ADD HEAP_HEAD_SIZE  # address of first object will be after the first headers
      @ADD OBJ_HEAD_SIZE   # Object ID's are at start of data, header is negative from there.
      @POPII HeapID  # Save at HeapID[0] ptr to First object   
      #
      @PUSHI SizeInBytes   # Save at HeapID[HEAP_SIZE_LOC] size in bytes of whole heap
      @SUB HEAP_HEAD_SIZE    # Minus the size of the HeapHeader
      @PUSHI HeapID @ADD HEAP_SIZE_LOC # Ptr to HeapID[2]
      @POPS
      # Fill 0's at the 3 bytes of the first Objects header.
      @PUSH 0
      @PUSHII HeapID @SUB OBJ_HEAD_SIZE
      @POPS
      @PUSH 0 @PUSHII HeapID @SUB OBJ_HEAD_SIZE @ADD 1
      @POPS
      #
      @PUSHI HeapID      # Successfull Heap created return it's ID on stack
   @ENDIF
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
ENDBLOCK
#
# Function HeapNewObject(HeapId, Size)
@FUNCTION HeapNewObject
:HeapNewObject
@PUSHRETURN
   @LocalVar HeapID 01
   @LocalVar SizeInBytes 02
   @LocalVar IndexX 03
   @LocalVar NewNextObject 04
   @LocalVar ContinueLoop 05
   @LocalVar OldNextObject 06

   @POPI SizeInBytes
   @POPI HeapID

   @IF_EQ_AV 0 SizeInBytes
      @PRT "Invalid Empty Heap"
      @JMP HNO_Exit
   @ENDIF

   #
   @PUSHII HeapID      # Ptr to first Object
   @POPI IndexX
   @PUSHI HeapID @ADD 2
   @PUSHS              # Total size in bytes of heap
   @SUB OBJ_HEAD_SIZE  # Make sure we have room for Objet header
   @IF_ULT_V SizeInBytes      #  We can't deal with more SizeInBytes than the whole heap had.
      # We don't have enough memory 
      @MA2V 2 ContinueLoop         # Set ContinueLoop to error code 2
   @ELSE                       #
      @POPNULL
      @MA2V 0 ContinueLoop       # This will both flag when the While Loops done and hold any possible error codes
      @PUSHI ContinueLoop
      @WHILE_ZERO           #
         @POPNULL
         @PUSHI IndexX @SUB OBJ_FLAG_LOC  @PUSHS @AND 0xff # We only care about byte at ObjectID[- OBJ_FLAG_LOC]
         @IF_ZERO     # This means this object is 'free' check it's size .. D2
            @POPNULL            
            # This calculation find the total size of the next block.
            @Call(VV) GetObjectRealSize HeapID IndexX
            @IF_UGE_V SizeInBytes
                #This means that the object was both free and large enough. So we tell While loop to exit.
                @MA2V 1 ContinueLoop
                # Load next pointer into OldNextObject
                @PUSHI IndexX @SUB OBJ_NEXT_LOC @PUSHS # Get the 'old' 'next' object. It might be zero.
                @POPI OldNextObject
                # Calculate remainder
                @SUBI SizeInBytes            # TOS is the size of the old object After we subtract the size we need now
                =SPLITTHRESHOLD OBJ_HEAD_SIZE+MinObjectSize       # Constants so we can get away with Assmbly time Add
                @IF_ULT_A SPLITTHRESHOLD
                   # Remainder is too small, treat like exact fit.
                   @POPNULL
                   @MV2V OldNextObject NewNextObject
                @ELSE
                   @POPNULL
                   @PUSHI IndexX @ADDI SizeInBytes @ADD OBJ_HEAD_SIZE # TOS is Ptr to 'new' objects we're squeezing in.
                   @POPI NewNextObject
                @ENDIF
                #
                @IF_EQ_VV NewNextObject OldNextObject
                   # 'exact fit' new object gets all space of old object.
                @ELSE
                    # These some space left over, split the block.
                    #
                    # Zero out the NewNextObject's default header
                    @PUSH 0 @PUSHI NewNextObject @SUB OBJ_NEXT_LOC @POPS
                    @PUSH 0 @PUSHI NewNextObject @SUB OBJ_HEAD_SIZE @POPS
                    # Now point the current object to point at the NewNextObject
                    @PUSHI NewNextObject
                    @PUSHI IndexX @SUB OBJ_NEXT_LOC @POPS  # IndexX[-2]=Ptr->NewNextObject
                    # Now setup the header of the NewNextObject
                    @PUSHI OldNextObject
                    @PUSHI NewNextObject @SUB OBJ_NEXT_LOC @POPS # NewNextObject[-2]=Ptr->OldNextObject
                @ENDIF
   #
                @PUSHI IndexX @SUB OBJ_HEAD_SIZE @PUSHS
                @AND 0xff00
                @OR 0x1  # Mark Object as 'in use'
                @PUSHI IndexX @SUB OBJ_HEAD_SIZE @POPS
            @ELSE                       #
                # We get here if the current object is free but too small, move onward to next possible object.
                @POPNULL
                @PUSHI IndexX @SUB OBJ_NEXT_LOC @PUSHS
                @IF_ZERO                #
                    @POPNULL
                    # We've hit the end of the HeapChain, so we have to ask if there sufficent space to extend the chain?
                    # We do this by subtracting current Index ptr from HeapID ptr and also remove mininal overhead space for meta data
                    @PUSHI IndexX @SUBI HeapID @SUB HEAP_HEAD_SIZE @SUB OBJ_HEAD_SIZE 
                    @IF_UGT_V SizeInBytes
                        # This means there still remains sufficent space for a new object.
                        @POPNULL
                        @MV2V IndexX ContinueLoop      # Value of new object, and flag to exit while loop.
                        @PUSHI IndexX
                        @ADDI SizeInBytes
                        @ADD OBJ_HEAD_SIZE
                        @POPI NewNextObject
                        @PUSH 1 @PUSHI IndexX @SUB OBJ_HEAD_SIZE @POPS                  # Mark IndexX as now active.
                        @PUSHI NewNextObject @PUSHI IndexX @SUB OBJ_NEXT_LOC @POPS      # Saves ptr to future NewNextObject
                        # Zero out header of 'NewNextObject'
                        @PUSH 0 @PUSHI NewNextObject @SUB OBJ_HEAD_SIZE @POPS
                        @PUSH 0 @PUSHI NewNextObject @SUB OBJ_NEXT_LOC @POPS
                    @ELSE
                        # Here is the error exit for cases where there is not sufficent space to create a new object at the tail.
                        @MA2V 3 ContinueLoop  
                    @ENDIF
                 @ELSE
                    # Here the case when there IS another object to check down the chain.
                    @POPI IndexX
                @ENDIF                 #
             @ENDIF                    #
          @ELSE                        #
             # Here means the current Object is not Free. So we just move on to the next one
                @POPNULL
                @PUSHI IndexX @SUB OBJ_NEXT_LOC @PUSHS
                @POPI IndexX
                @IF_EQ_AV 0 IndexX
                    # This can only be zero if we've hit the end of the heap chain and non space was large enough
                    # We should now call a routine that will find all the free blocks and move the used blocks around
                    # For now we'll just issue an error.
                    @MA2V 4 ContinueLoop         # Set ContinueLoop to error code 4
                @ENDIF                 #
           @ENDIF                      #
           # At this point were back at the main body of the while loop.
           @PUSHI ContinueLoop
       @ENDWHILE                 #
   @ENDIF
   @POPNULL
   # At this point we either have an answer for the ObjectID or an error code.
   @PUSHI ContinueLoop
   @IF_EQ_A 1
     @POPNULL
     # Valide Object found/created.
     @PUSHI IndexX
   # Else the ContinueLoop already on th stack is the error value
   @ENDIF
   :HNO_Exit
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
ENDBLOCK

#
# Function HeapResizeObject(HeapID,ObjectID,NewSize)
#
@FUNCTION HeapResizeObject
:HeapResizeObject
@PUSHRETURN
   @LocalVar HeapID 01
   @LocalVar ObjectID 02
   @LocalVar NewSizeInBytes 03
   @LocalVar IndexX 04
   @LocalVar IndexY 05
   @LocalVar NewObject 06

   #
   @POPI NewSizeInBytes
   @POPI ObjectID
   @POPI HeapID
   #
   # Make sure ObjectID is valid
   @PUSHI ObjectID
   @IF_ULT_A 100
      @JMP HRO_Err_Exit
   @ENDIF
   @POPNULL
   #
   # Find a 'new object' of the NewSize
   # Yes this means that we can't expand 'inplace'
   @Call(VV)  HeapNewObject HeapID NewSizeInBytes
   @IF_ULT_A 100 JMP HRO_Err_Exit @ENDIF
   @POPI NewObject
   #
   # Copy 'just' the OldSize data from Old Object to New
   @Call(VV) GetObjectRealSize HeapID ObjectID
   @POPI IndexY    # Size of old Object
   # Test to see if the new size is smaller than the old size.
   @PUSHI IndexY
   # If the NewObject is smaller than the Old one we only want to copy NewSize bytes
   # otherwise if NewObject is larger, then we can safely copy the full length of OldSize
   @IF_UGT_V NewSizeInBytes
      # If NewSizeInBytes < OldSize, then we just copy NewSize number of bytes
      @MV2V NewSizeInBytes IndexY
      @POPNULL
   @ELSE
      # Otherwise OldSize has enough space, so copy it all.
      @POPNULL
   @ENDIF

   # Consider Optimizing this loop to use NextBy words rather than bytes.
   @ForIA2V IndexX 0 IndexY
      @PUSHI ObjectID @ADDI IndexX @PUSHS @AND 0xff
      @PUSHI NewObject @ADDI IndexX @DUP @SWP @PUSHS @AND 0xff00 @ORS @POPS
   @Next IndexX
   #
   @Call(VV) HeapDeleteObject HeapID ObjectID
   #
   # Return the NewObject
   @PUSHI NewObject
   # If we have error, error code will already be on stack.
   :HRO_Err_Exit
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
ENDBLOCK
#
#
# Function HeapDeleteObject(HeapID,ObjectID)
@FUNCTION HeapDeleteObject
:HeapDeleteObject
@PUSHRETURN
   @LocalVar HeapID 01
   @LocalVar ObjectID 02

   #
   @POPI ObjectID
   @POPI HeapID
   #
   # The simplists delete mode is to just mark the current ObjectID as free
   @PUSHI ObjectID @SUB OBJ_HEAD_SIZE @PUSHS @AND 0xff00   # Zero it out.
   @PUSHI ObjectID @SUB OBJ_HEAD_SIZE @POPS                # Put it back
   #
   @PUSHI HeapID
   @CALL HeapDefrag
   #
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
ENDBLOCK
#
#
# Function HeapDefrag(HeapID)
# Walk the Heap find any free nodes and check if they are adjacent. Combine them if possible.
=MARK_ENDOFCHAIN 2
=MARK_BREAKWHILE 1
@FUNCTION HeapDefrag
:HeapDefrag
@PUSHRETURN
   @LocalVar HeapID 01
   @LocalVar IndexX 02
   @LocalVar IndexY 03
   #
   @POPI HeapID
   #
   @PUSHII HeapID @POPI IndexX
   #
   # Outer While loop terminats when IndexX is zero, which means end of chain.
   @PUSHI IndexX
   @WHILE_NOTZERO
       @SUB OBJ_HEAD_SIZE @PUSHS @AND 0xff
       @IF_NOTZERO
          # This Object still in use, just move down the chain.
          @POPNULL
          @PUSHI IndexX @SUB OBJ_NEXT_LOC @PUSHS @POPI IndexX
          @PUSHI IndexX   # Push next outer-loop condition.
       @ELSE
          # Object is free, our main question, is it a 'chain' of free objects. Merge them if we can.
          @POPNULL
          # Get the ptr to the next object, while keeping IndexX pointing at the current one.
          @PUSHI IndexX @SUB OBJ_NEXT_LOC @PUSHS @POPI IndexY
          @IF_EQ_AV 0 IndexY
             @PUSH MARK_ENDOFCHAIN  # Skip Merge
          @ELSE
              @PUSHI IndexY @SUB OBJ_HEAD_SIZE @PUSHS @AND 0xff
          @ENDIF
          # If IndexY is not free, we just never do this loop.
          @WHILE_ZERO
             # IndexY is another free node. Swap IndexX's PTR but also continue seeing what the next item in the chain is.
             @POPNULL
             @PUSHI IndexY @SUB OBJ_NEXT_LOC @PUSHS # Get where IndexY pointed too
             @DUP
             @PUSHI IndexX @SUB OBJ_NEXT_LOC @POPS  # Make it so original IndexX now skips IndexY and goes directly to next in chain
             @IF_ZERO
                # This would be true if 'Next after IndexY' is also the end of the heap.
                @POPNULL
                @PUSH MARK_ENDOFCHAIN  #To break the Inner While Loop
             @ELSE
                #IndexY points to another obeject, now test that one.
                @POPI IndexY
                @PUSHI IndexY @SUB OBJ_HEAD_SIZE @PUSHS @AND 0xff  # Test that next one for in use flag
             @ENDIF
           @ENDWHILE
           # We get to this spot in a few ways.
           #  1) Loop never ran, because IndexY was not free from the start TOS=1
           #  2) Loop ran and IndexY eventually pointed to an in use object. TOS=1
           #  3) Loop ran, and IndexY eventually reached the end of the chain. TOS=2
           @IF_EQ_A MARK_ENDOFCHAIN
              # We had run into end of chain rather than an inuse IndexY           
              @POPNULL
              @PUSH 0   # This will end the outter while loop.
           @ELSE
              @POPNULL
              @PUSHI IndexY @SUB OBJ_NEXT_LOC @PUSHS @POPI IndexX  # Set up for next outer while test
              @PUSHI IndexY
           @ENDIF        
        @ENDIF
   @ENDWHILE
   @POPNULL
   @PUSH 0   # Will be the return value.
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
ENDBLOCK

# Function HeapListMap(HeapID)
@FUNCTION HeapListMap
:HeapListMap
@PUSHRETURN
   @LocalVar HeapID 01
   @LocalVar ObjectID 02

   #
   @POPI HeapID
   @PUSHII HeapID
   @POPI ObjectID
   #
   # Test for empty Heap
   @PUSHI ObjectID @SUB 2
   @PUSHS
   @IF_ZERO
      @POPNULL
      @PRTLN "Empty Heap"
   @ELSE
       @POPNULL
       @PUSHI ObjectID
       @WHILE_NOTZERO
          @POPI ObjectID
          @PRT "Object: " @PRTHEXI ObjectID
          @PUSHI ObjectID @SUB OBJ_HEAD_SIZE @PUSHS @AND 0xff
          @IF_ZERO
             @PRT "( )"
          @ELSE
             @PRT "(X)"
          @ENDIF
          @POPNULL
          @PUSHI HeapID
          @PUSHI ObjectID
          @CALL GetObjectRealSize
          @PRT " Size(0x"
          @PRTHEXTOP
          @PRT ") Next ID->"
          @POPNULL
          @PUSHI ObjectID @SUB OBJ_NEXT_LOC @PUSHS
          @PRTHEXTOP
          @PUSHII ObjectID @AND 0xff
          @IF_GE_A "0\0"
             @IF_LE_A "z\0"
                @PRT " " @PRTSI ObjectID
             @ENDIF
          @ENDIF
          @POPNULL
          @PRTNL
       @ENDWHILE      
       @POPNULL
   @ENDIF
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
ENDBLOCK   
   


# Function GetObjectRealSize(HeapID,ObjectID)
# Utility given ObjectID will look forward to the next object and calculate the size of ObjectID
# minus the 5 byte header of the next object, if it exists.
@FUNCTION GetObjectRealSize
:GetObjectRealSize
@PUSHRETURN
   @LocalVar ObjectID 01
   @LocalVar HeapID 02
   @POPI ObjectID
   @POPI HeapID
   @PUSHI ObjectID
   #
   @SUB OBJ_NEXT_LOC @PUSHS  # Get Address of Next Object. It Might be zero for end of chain
   @IF_NOTZERO
      @POPNULL
      # TOS will be address of next object
      @PUSHI ObjectID
      @SUB OBJ_NEXT_LOC
      @PUSHS    # Ptr to next Object is at ObjectID[-2]
   @ELSE
      # If Next Object is 'zero' means that no next object yet defined.
      # We have 'all' the space from ObjectID to end of the Heap.
      @POPNULL
      @PUSHI HeapID @ADD 2 @PUSHS  @ADDI HeapID # Get Address of Heap End
   @ENDIF
   # At TOS should be address of start of Next object, or address of end of heap.
   # subtract the current ObjectID's address to get available size
   @SUBI ObjectID
   @SUB OBJ_HEAD_SIZE   # we don't count the Object's header as part of its size.
   #
   @RestoreVar 02
   @RestoreVar 01   
@POPRETURN
@RET
ENDBLOCK
##################################################################
# Function HeapAppend(HeapID,Object1,Object2,Offset):Object1_(new?)
# Appends Object2 to Object1 and growns
@FUNCTION HeapAppend
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
   #
   @POPI Offset
   @POPI Object2
   @POPI Object1
   @POPI HeapID
   #
   # Calculate Object sizes
   @PUSHI Object1
   @PUSHI HeapID
   @CALL GetObjectRealSize
   @POPI Object1Size
   @PUSHI Object2
   @PUSHI HeapID
   @CALL GetObjectRealSize
   @POPI Object2Size
   #
   @PUSHI Object1Size @SUBI Offset
   @IF_LT_V Object2Size
      # Object1 too Small, expand it.
      @POPNULL
      @PUSHI Object1Size @SUBI Offset
      @ADDI Object2Size     # New size is Oldsize-Offset+Object2Size
      @PUSHI Object1
      @PUSHI HeapID
      @CALL HeapResizeObject
      @POPI Object1   # Object1 might as be just an error code.
   @ENDIF
   #
   # There is a chance that the resizing of Object1 failed with an error.
   # If so we don't bother copying Object2 and just pass the Object1 error to the calling process
   @PUSHI Object1
   @IF_GT_A 100       # Object1's ID will be < 100 if there is an error.
      @ForIA2V Index1 0 Object2Size
          @PUSHI Object2 @ADDI Index1 @PUSHS
          @PUSHI Object1 @ADDI Offset @ADDI Index1 @POPS
      @Next Index1
   @ENDIF
   # Object1's id or error code is on the stack.
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
ENDBLOCK


# Function HeapValidate(HeapID)
# Walks heap chain and verifies pointer integrity.
# Returns:
#   0 = heap is valid
#   1 = pointer outside heap
#   2 = next pointer not increasing
#   3 = next pointer beyond heap end

@FUNCTION HeapValidate
:HeapValidate
@PUSHRETURN
   @LocalVar HeapID 01
   @LocalVar IndexX 02
   @LocalVar NextPtr 03
   @LocalVar HeapEnd 04

   @POPI HeapID

   # Compute heap end = HeapID + heap_size
   @PUSHI HeapID
   @PUSHI HeapID @ADD HEAP_SIZE_LOC @PUSHS
   @ADD
   @POPI HeapEnd

   # Load first object
   @PUSHI HeapID @ADD HEAP_FIRST_OBJ_LOC @PUSHS
   @POPI IndexX

   @PUSHI IndexX
   @WHILE_NOTZERO

       # Check object pointer inside heap
       @IF_ULT_V HeapID
          @PUSH 1
          JMP HV_EXIT
       @ENDIF

       @IF_UGE_V HeapEnd
          @PUSH 1
          JMP HV_EXIT
       @ENDIF

       # Load next pointer
       @PUSHI IndexX @SUB OBJ_NEXT_LOC @PUSHS
       @POPI NextPtr

       # If next == 0 we are done
       @IF_EQ_AV 0 NextPtr
          @POPNULL
          @PUSH 0
          JMP HV_EXIT
       @ENDIF

       # next must be greater than current object
       @PUSHI NextPtr
       @IF_ULT_V IndexX
          @PUSH 2
          JMP HV_EXIT
       @ENDIF

       # next must stay inside heap
       @PUSHI NextPtr
       @IF_UGE_V HeapEnd
          @PUSH 3
          JMP HV_EXIT
       @ENDIF

       # advance
       @MV2V NextPtr IndexX
       @PUSHI IndexX

   @ENDWHILE

   # if loop exited normally
   @POPNULL
   @PUSH 0

:HV_EXIT
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
ENDBLOCK
M SIZESINCECOMMENT heapmgr.ld
@SIZESINCE
ENDBLOCK
