! HeapMgrSeen
M HeapMgrSeen 1
L common.mc
L softstack.ld
= MinObjectSize 1
= SizeHeapHead 4
= SizeObjectHead 3
= ObjectPtrLocation 2
= SizeFirstHead 7

G HeapDefineMemory
G HeapNewObject
G HeapResizeObject
G HeapDeleteObject
G HeapCopyObject
G HeapListMap
G GetObjectRealSize
# This is the heap manager module

# It provides the following services
# HeapDefineMemory(LowAddress(>100), SizeInBytes):HeapID Return < 100 is error code
# HeapNewObject(HeapID,Size_in_Bytes):ObjectID Return < 100 is Error code
# HeapResizeObject(HeapID,ObjectID,NewSize_In_Bytes):ObjectID Return < 100 is error code
# HeapDeleteObject(HeapID,ObjectID):StatusCode Success==0 other wise error code
# HeapCopyObject(HeapID,ObjectId):ObjectIDReturn < 100 is error code
# GetObjectRealSize(HeapID,ObjectID) Calculates the space between ObjectID and next.
# HeapDefrag(HeapID) Walks though heap and tries to merge free objects that are next to each other.
#
# HeapID is ptr to memory
# HeapID[0]=16b Ptr to First Object in Heap
# HeapID[2]=16b total size of heap to help avoid overflow.
#
# ObjectID[-2]=16b Ptr to Next Object Entry or zero if last entry
# ObjectID[-3]=8b flag. (0=Free, 1=In-use)
#
# Storage
:SizeInBytes 0
:NewSizeInBytes 0
:HeapID 0
:ObjectID 0
:NewObject 0
:IndexX 0
:IndexY 0
:IndexZ 0
:ContinueLoop 0
:NewNextObject 0
:OldNextObject 0
:NewRemainingSize 0
#
#
# Function HeapDefineMemory
:HeapDefineMemory
@PUSHRETURN
@PUSHLOCALI SizeInBytes
@PUSHLOCALI HeapID
#
@POPI SizeInBytes
@POPI HeapID      # At this point the HeapID is same as address where heap memory starts
@PRT "HeadDefineMemory: Start: " @PRTHEXI HeapID @PRT " Size: " @PRTI SizeInBytes @PRTNL
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
   @ADD SizeFirstHead  # address of first object will be after the first headers
   @POPII HeapID  # Save at HeapID[0] ptr to First object   
   #
   @PUSHI SizeInBytes   # Save at HeapID[2] size in bytes of whole heap
   @SUB SizeHeapHead    # Minus the size of the HeapHeader
   @PUSHI HeapID @ADD 2 # Ptr to HeapID[2]
   @POPS
   # Now zero out where the first data object header is.
   @PUSHII HeapID
   @DUP
   @SUB SizeObjectHead @PUSH 0 @SWP @POPS
   @SUB ObjectPtrLocation @PUSH 0 @SWP @POPS
   @PUSHI HeapID      # Successfull Heap created return it's ID on stack
@ENDIF
@POPLOCAL HeapID
@POPLOCAL SizeInBytes
@POPRETURN
@RET
#
# Function HeapNewObject
:HeapNewObject
@PUSHRETURN
@PUSHLOCALI HeapID
@PUSHLOCALI SizeInBytes
@PUSHLOCALI IndexX
@PUSHLOCALI NewNextObject

@POPI SizeInBytes
@POPI HeapID
#
@PUSHII HeapID      # Ptr to first Object
@POPI IndexX
@PUSHI HeapID @ADD 2
@PUSHS              # Total size in bytes of heap
@IF_ULT_V SizeInBytes      #  We can't deal with more SizeInBytes than the whole heap had.
   # We don't have enough memory 
   @MA2V 2 ContinueLoop         # Set ContinueLoop to error code 2
@ELSE                       # 
   @POPNULL
   @MA2V 0 ContinueLoop       # This will both flag when the While Loops done and hold any possible error codes
   @PUSHI ContinueLoop
   @WHILE_ZERO           #
      @POPNULL
      @PUSHI IndexX @SUB SizeObjectHead  @PUSHS @AND 0xff # We only care about byte at ObjectID[-3]
      @IF_ZERO     # This means this object is 'free' check it's size .. D2
         @POPNULL
         # This calculation find the total size of the next block.
         @PUSHI HeapID
         @PUSHI IndexX
         @CALL GetObjectRealSize
         @DUP @POPI NewRemainingSize
         @IF_UGT_V SizeInBytes          #
             #This means that the object was both free and large enough. So we tell While loop to exit.
             @MA2V 1 ContinueLoop
             # Next question Will the new object take up all the space, or leave some for a new empty object?
             @SUBI SizeInBytes            # TOS is the size of the old object After we subtract the size we need now.
             @SUB SizeObjectHead
             @IF_UGT_A MinObjectSize       # We don't want to leave tiny objects arround that will never be used. D4
                 @POPNULL
                 # OK its big enough for reasonable objects
                 @PUSHI IndexX @SUB ObjectPtrLocation @PUSHS # Get the 'old' 'next' object. It might be zero.
                 @POPI OldNextObject
                 #
                 @PUSHI IndexX @ADDI SizeInBytes @ADD SizeObjectHead # TOS is Ptr to 'new' objects we're squeezing in.
                 @POPI NewNextObject
                 #
                 # Zero out the NewNextObject's default header
                 @PUSH 0 @PUSHI NewNextObject @SUB ObjectPtrLocation @POPS
                 @PUSH 0 @PUSHI NewNextObject @SUB SizeObjectHead @POPS
                 # Now point the current object to point at the NewNextObject
                 @PUSHI NewNextObject
                 @PUSHI IndexX @SUB ObjectPtrLocation @POPS  # IndexX[-2]=Ptr->NewNextObject
                 # Now setup the header of the NewNextObject
                 @PUSHI OldNextObject
                 @PUSHI NewNextObject @SUB ObjectPtrLocation @POPS # NewNextObject[-2]=Ptr->OldNextObject
             @ELSE                    # 
                 # The space we are reclaiming was not large enough to divide but large enough for our one time use
                 # The NextObject therefore remains the same. We just need to Mark current one as used
                 @POPNULL
             @ENDIF                   # 
             @PUSHI IndexX @SUB SizeObjectHead @PUSHS
             @AND 0xff00
             @OR 0x1  # Mark Object as 'in use'
             @PUSHI IndexX @SUB SizeObjectHead @POPS
         @ELSE                       #
             # We get here if the current object is free but too small, move onward to next possible object.
             @POPNULL
             @PUSHI IndexX @SUB ObjectPtrLocation @PUSHS
             @IF_ZERO                #
                 @POPNULL
                 # We've hit the end of the HeapChain, so we have to ask if there sufficent space to extend the chain?
                 # We do this by subtracting current Index ptr from HeapID ptr and also remove mininal overhead space for meta data
                 @PUSHI IndexX @SUBI HeapID @SUB SizeHeapHead @SUB SizeObjectHead 
                 @IF_UGT_V SizeInBytes
                     # This means there still remains sufficent space for a new object.
                     @MV2V IndexX ContinueLoop      # Value of new object, and flag to exit while loop.
                     @PUSHI IndexX @ADDI SizeInBytes @SUB SizeObjectHead @POPI NewNextObject
                     @PUSH 1 @PUSHI IndexX @SUB SizeObjectHead @POPS                  # Mark IndexX as now active.
                     @PUSHI NewNextObject @PUSHI IndexX @SUB ObjectPtrLocation @POPS      # Saves ptr to future NewNextObject
                     # Zero out header of 'NewNextObject'
                     @PUSH 0 @PUSHI NewNextObject @SUB SizeObjectHead @POPS
                     @PUSH 0 @PUSHI NewNextObject @SUB ObjectPtrLocation @POPS
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
             @PUSHI IndexX @SUB ObjectPtrLocation @PUSHS
             @POPI IndexX
             @PUSHI IndexX
             @IF_ZERO                #
                 @POPNULL
                 # This can only be zero if we've hit the end of the heap chain and non space was large enough
                 # We should now call a routine that will find all the free blocks and move the used blocks around
                 # For now we'll just issue an error.
                 @MA2V 4 ContinueLoop         # Set ContinueLoop to error code 4
             @ELSE
                 @POPNULL
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
@POPLOCAL NewNextObject
@POPLOCAL IndexX
@POPLOCAL SizeInBytes
@POPLOCAL HeapID
@POPRETURN
@RET

#
# Function HeapResizeObject(HeapID,ObjectID,NewSize)
#
:HeapResizeObject
@PUSHRETURN
@PUSHLOCALI HeapID
@PUSHLOCALI ObjectID
@PUSHLOCALI NewSizeInBytes
@PUSHLOCALI IndexX
@PUSHLOCALI IndexY
@PUSHLOCALI NewObject
@POPI NewSizeInBytes
@POPI ObjectID
@POPI HeapID
#
# Find a 'new object' of the NewSize
# Yes this means that we can't expand 'inplace'
@PUSHI HeapID
@PUSHI NewSizeInBytes
@CALL HeapNewObject
@POPI NewObject
@PUSHI NewObject
:Break3
@IF_UGT_A 100       # Any Number Less than 100 is an error code.
    @POPNULL
    #
    # Now copy the old Object's data to the New Object
    @PUSHI ObjectID @SUB 4 @PUSHS
    @PUSHI NewObject @SUB 4 @POPS
    @PUSHI NewObject @SUB 5 @PUSHS @AND 0xff00 @OR 1  # Mark New Obejct as 'in use'
    @PUSHI NewObject @SUB 5 @POPS
    #
    # Copy 'just' the OldSize data from Old Object to New
    @PUSHI HeapID
    @PUSHI ObjectID
    @CALL GetObjectRealSize
    @POPI IndexY    # Size of old Object
    # Test to see if the new size is smaller than the old size.
    @PUSHI IndexY
    # If the NewObject is smaller than the Old one we only want to copy NewSize bytes
    # otherwise if NewObject is larger, then we can safely copy the full length of OldSize
    @IF_ULT_V NewSizeInBytes
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
    # Now mark the Old Object as 'free'
    # Replace this with DeleteObject once it's written
    @PUSHI ObjectID @SUB 5 @PUSHS @AND 0xff00
    @PUSHI ObjectID @SUB 5 @POPS
    #
    # Return the NewObject
    @PUSHI NewObject
@ELSE
    # Call to HeapNewObject result in an error, which will already be in NewObject, just let it be returned.
    @POPNULL
@ENDIF
@POPLOCAL NewObject
@POPLOCAL IndexY
@POPLOCAL IndexX
@POPLOCAL NewSizeInBytes
@POPLOCAL ObjectID
@POPLOCAL HeapID
@POPRETURN
@RET
#
#
# Function HeapDeleteObject(HeapID,ObjectID)
:HeapDeleteObject
@PUSHRETURN
@PUSHLOCALI ObjectID
@PUSHLOCALI HeapID
#
@POPI ObjectID
@POPI HeapID
#
# The simplists delete mode is to just mark the current ObjectID as free
@PUSHI ObjectID @SUB SizeObjectHead @PUSHS @AND 0xff00   # Zero it out.
@PUSHI ObjectID @SUB SizeObjectHead @POPS                # Put it back
#
@PUSHI HeapID
@CALL HeapDefrag
#
@POPLOCAL HeapID
@POPLOCAL ObjectID
@POPRETURN
@RET
#
#
# Function HeapDefrag(HeapID)
# Walk the Heap find any free nodes and check if they are adjacent. Combine them if possible.
:HeapDefrag
@PUSHRETURN
@PUSHLOCALI HeapID
@PUSHLOCALI IndexX
@PUSHLOCALI IndexY
#
@POPI HeapID
#
@PUSHII HeapID @POPI IndexX
#
# Outer While loop terminats when IndexX is zero, which means end of chain.
@PUSHI IndexX
@WHILE_NOTZERO
    @SUB SizeObjectHead @PUSHS @AND 0xff
    @IF_NOTZERO
       # This Object still in use, just move down the chain.
       @POPNULL
       @PUSHI IndexX @SUB ObjectPtrLocation @PUSHS @POPI IndexX
       @PUSHI IndexX      # This will make the outter WHile exit, if we reached end of chain.
    @ELSE
       # Object is free, our main question, is it a 'chain' of free objects. Merge them if we can.
       @POPNULL
       # Get the ptr to the next object, while keeping IndexX pointing at the current one.
       @PUSHI IndexX @SUB ObjectPtrLocation @PUSHS @POPI IndexY
       @PUSHI IndexY @SUB SizeObjectHead @PUSHS @AND 0xff
       # If IndexY is not free, we just never do this loop.
       @WHILE_ZERO
          # IndexY is another free node. Swap IndexX's PTR but also continue seeing what the next item in the chain is.
          @POPNULL
          @PUSHI IndexY @SUB 2 @PUSHS # Get where IndexY pointed too
          @DUP
          @PUSHI IndexX @SUB 2 @POPS  # Make it so original IndexX now skips IndexY and goes directly to next in chain
          @IF_ZERO
             # This would be true if 'Next after IndexY' is also the end of the heap.
             @POPNULL
             @PUSH 2  #To break the Inner While Loop
          @ELSE
             #IndexY points to another obeject, now test that one.
             @POPI IndexY
             @PUSHI IndexY @SUB SizeObjectHead @PUSHS @AND 0xff  # Test that next one for in use flag
          @ENDIF
        @ENDWHILE
        # We get to this spot in a few ways.
        #  1) Loop never ran, because IndexY was not free from the start TOS=1
        #  2) Loop ran and IndexY eventually pointed to an in use object. TOS=1
        #  3) Loop ran, and IndexY eventually reached the end of the chain. TOS=2
        @IF_EQ_A 2
           # We had run into end of chain rather than an inuse IndexY           
           @POPNULL
           @PUSH 0   # This will end the outter while loop.
        @ELSE
           @PUSHI IndexY @SUB ObjectPtrLocation @PUSHS @POPI IndexX  # Set up for next outer while test
           @PUSHI IndexY
        @ENDIF        
     @ENDIF
@ENDWHILE
@POPLOCAL IndexY
@POPLOCAL IndexX
@POPLOCAL HeapID
@POPRETURN
@RET

# Function HeapListMap(HeapID)
:HeapListMap
@PUSHRETURN
@PUSHLOCALI ObjectID
@PUSHLOCALI HeapID
@POPI HeapID
@PUSHII HeapID
@POPI ObjectID
#
@PUSHI ObjectID
@WHILE_NOTZERO
   @POPI ObjectID
   @PRT "Object: " @PRTHEXI ObjectID
   @PUSHI ObjectID @SUB SizeObjectHead @PUSHS @AND 0xff
   @IF_ZERO
      @PRT "( )"
   @ELSE
      @PRT "(X)"
   @ENDIF
   @POPNULL
   @PUSHI HeapID
   @PUSHI ObjectID
   @CALL GetObjectRealSize
   @PRT " Size("
   @PRTTOP
   @PRT ") Next ID->"
   @POPNULL
   @PUSHI ObjectID @SUB ObjectPtrLocation @PUSHS
   @PRTHEXTOP
   @PRTNL
@ENDWHILE
@POPNULL
@POPLOCAL HeapID
@POPLOCAL ObjectID
@POPRETURN
@RET
   
   


# Function GetObjectRealSize(HeapID,ObjectID)
# Utility given ObjectID will look forward to the next object and calculate the size of ObjectID
# minus the 5 byte header of the next object, if it exists.
:GetObjectRealSize
@PUSHRETURN
@PUSHLOCALI ObjectID
@PUSHLOCALI HeapID
@POPI ObjectID
@POPI HeapID
@PUSHI ObjectID
#
@SUB ObjectPtrLocation @PUSHS  # Get Address of Next Object. It Might be zero for end of chain
@IF_NOTZERO
   @POPNULL
   # TOS will be address of next object
   @PUSHI ObjectID
   @SUB ObjectPtrLocation
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
@SUB SizeObjectHead   # we don't count the Object's header as part of its size.
#
@POPLOCAL HeapID
@POPLOCAL ObjectID
@POPRETURN
@RET

