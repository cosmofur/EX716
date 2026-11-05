! __LIB_HEAPMGR_DS_LOADED
M __LIB_HEAPMGR_DS_LOADED 1
P Loading heapmgrDS.ld
I heapmgrDS.ref
L softstackDS.ld

# DS-local heap manager.  Heap and object IDs are near offsets in the active
# DS and are invalid after DS changes.  A heap never crosses a 64 KiB bank.

G HeapDSDefineMemory G HeapDSNewObject G HeapDSDeleteObject
G HeapDSObjectSize G HeapDSAvailable

=HDS_FIRST_OBJECT 0
=HDS_LIMIT          2
=HDS_HEADER_SIZE     4
=HDS_FLAG_OFFSET     3
=HDS_NEXT_OFFSET     2
=HDS_OBJECT_HEADER   3
=HDS_MIN_OBJECT      2
=HDS_SPLIT_MIN       HDS_OBJECT_HEADER+HDS_MIN_OBJECT

# Lightweight bootstrap: reserve the DS stack at the top of the selected
# range, then turn the preceding range into one near heap.  No call occurs
# before DSSInitAB has made the DS stack usable.
# HeapDSInit(HeapIdVar, HeapBottom, HeapTopExclusive, StackBytes)
M HeapDSInit `\
  @DSSInitAB %3 %3-%4 ; \
  @PUSH %2 ; \
  @PUSH %3-%4-%2 ; \
  @CALL HeapDSDefineMemory ; \
  @POPI %1 \
`
M HeapDSInitS `\
  @DSSInitABS %5 %3 %3-%4 ; \
  @PUSH %2 ; \
  @PUSH %3-%4-%2 ; \
  @CALL HeapDSDefineMemory ; \
  @POPI %1 \
`

@JMP __HDS_SKIP

@FUNCTION HeapDSDefineMemory
:HeapDSDefineMemory
@DSSPushReturn
@DSSLocals
   @DSSLocal HeapID
   @DSSLocal SizeBytes
   @DSSLocal Limit
   @DSSLocal First
   @POPI SizeBytes
   @POPI HeapID
   @PUSHI HeapID
   @IF_ULT_A 0x0100
      @POPNULL
      @PUSH 0
      @JMP HDSD_Exit
   @ENDIF
   @POPNULL
   @PUSHI SizeBytes
   @IF_ULT_A HDS_HEADER_SIZE+HDS_OBJECT_HEADER+HDS_MIN_OBJECT
      @POPNULL
      @PUSH 0
      @JMP HDSD_Exit
   @ENDIF
   @POPNULL
   @PUSHI HeapID
   @ADDI SizeBytes
   @IF_ULT_V HeapID
      @POPNULL
      @PUSH 0
      @JMP HDSD_Exit
   @ENDIF
   @POPI Limit
   @PUSHI Limit
   @PUSHI HeapID @ADD HDS_LIMIT
   @POPS
   @PUSHI HeapID @ADD HDS_HEADER_SIZE+HDS_OBJECT_HEADER
   @POPI First
   @PUSHI First
   @PUSHI HeapID
   @POPS
   @PUSH 0
   @PUSHI First @SUB HDS_FLAG_OFFSET
   @POPS
   @PUSH 0
   @PUSHI First @SUB HDS_NEXT_OFFSET
   @POPS
   @PUSHI HeapID
:HDSD_Exit
@DSSEndLocals
@DSSPopReturn
@RET
@ENDFUNCTION

@FUNCTION HeapDSObjectSize
:HeapDSObjectSize
@DSSPushReturn
@DSSLocals
   @DSSLocal HeapID
   @DSSLocal ObjectID
   @DSSLocal Next
   @DSSLocal Limit
   @POPI ObjectID
   @POPI HeapID
   @PUSHI ObjectID @SUB HDS_NEXT_OFFSET @PUSHS
   @POPI Next
   @PUSHI Next
   @IF_ZERO
      @POPNULL
      @PUSHI HeapID @ADD HDS_LIMIT @PUSHS
      @POPI Limit
      @PUSHI Limit
      @SUBI ObjectID
   @ELSE
      @POPNULL
      @PUSHI Next
      @SUB HDS_OBJECT_HEADER
      @SUBI ObjectID
   @ENDIF
@DSSEndLocals
@DSSPopReturn
@RET
@ENDFUNCTION

@FUNCTION HeapDSNewObject
:HeapDSNewObject
@DSSPushReturn
@DSSLocals
   @DSSLocal HeapID
   @DSSLocal SizeBytes
   @DSSLocal Current
   @DSSLocal Next
   @DSSLocal BlockSize
   @DSSLocal Remainder
   @DSSLocal NewObject
   @DSSLocal Result
   @POPI SizeBytes
   @POPI HeapID
   @MA2V 0 Result
   @PUSHI SizeBytes
   @IF_ZERO
      @POPNULL
      @JMP HDSN_Done
   @ENDIF
   @POPNULL
   @PUSHII HeapID
   @POPI Current
   @PUSHI Current
   @WHILE_NOTZERO
      @POPNULL
      @PUSHI Current @SUB HDS_FLAG_OFFSET @PUSHS @AND 0xff
      @IF_ZERO
         @POPNULL
         @PUSHI HeapID
         @PUSHI Current
         @CALL HeapDSObjectSize
         @POPI BlockSize
         @PUSHI BlockSize
         @IF_UGE_V SizeBytes
            @POPNULL
            @PUSHI BlockSize @SUBI SizeBytes @POPI Remainder
            @PUSHI Current @SUB HDS_NEXT_OFFSET @PUSHS @POPI Next
            @PUSHI Remainder
            @IF_UGE_A HDS_SPLIT_MIN
               @POPNULL
               @PUSHI Current @ADDI SizeBytes @ADD HDS_OBJECT_HEADER
               @POPI NewObject
               @PUSH 0
               @PUSHI NewObject @SUB HDS_FLAG_OFFSET
               @POPS
               @PUSHI Next
               @PUSHI NewObject @SUB HDS_NEXT_OFFSET
               @POPS
               @PUSHI NewObject
               @PUSHI Current @SUB HDS_NEXT_OFFSET
               @POPS
            @ELSE
               @POPNULL
            @ENDIF
            @PUSHI Current @SUB HDS_FLAG_OFFSET @PUSHS @AND 0xff00 @OR 1
            @PUSHI Current @SUB HDS_FLAG_OFFSET @POPS
            @MV2V Current Result
            @MA2V 0 Current
         @ELSE
            @POPNULL
            @PUSHI Current @SUB HDS_NEXT_OFFSET @PUSHS @POPI Current
         @ENDIF
      @ELSE
         @POPNULL
         @PUSHI Current @SUB HDS_NEXT_OFFSET @PUSHS @POPI Current
      @ENDIF
      @PUSHI Current
   @ENDWHILE
   @POPNULL
:HDSN_Done
   @PUSHI Result
@DSSEndLocals
@DSSPopReturn
@RET
@ENDFUNCTION

@FUNCTION HeapDSDeleteObject
:HeapDSDeleteObject
@DSSPushReturn
@DSSLocals
   @DSSLocal HeapID
   @DSSLocal ObjectID
   @POPI ObjectID
   @POPI HeapID
   @PUSHI ObjectID
   @IF_ULT_A 0x0100
      @POPNULL
      @PUSH 1
      @JMP HDSX_Done
   @ENDIF
   @POPNULL
   @PUSHI ObjectID @SUB HDS_FLAG_OFFSET @PUSHS @AND 0xff00
   @PUSHI ObjectID @SUB HDS_FLAG_OFFSET @POPS
   @PUSH 0
:HDSX_Done
@DSSEndLocals
@DSSPopReturn
@RET
@ENDFUNCTION

@FUNCTION HeapDSAvailable
:HeapDSAvailable
@DSSPushReturn
@DSSLocals
   @DSSLocal HeapID
   @DSSLocal Current
   @DSSLocal Total
   @DSSLocal BlockSize
   @POPI HeapID
   @MA2V 0 Total
   @PUSHII HeapID @POPI Current
   @PUSHI Current
   @WHILE_NOTZERO
      @POPNULL
      @PUSHI Current @SUB HDS_FLAG_OFFSET @PUSHS @AND 0xff
      @IF_ZERO
         @POPNULL
         @PUSHI HeapID @PUSHI Current @CALL HeapDSObjectSize
         @ADDI Total
         @POPI Total
      @ELSE
         @POPNULL
      @ENDIF
      @PUSHI Current @SUB HDS_NEXT_OFFSET @PUSHS @POPI Current
      @PUSHI Current
   @ENDWHILE
   @POPNULL
   @PUSHI Total
@DSSEndLocals
@DSSPopReturn
@RET
@ENDFUNCTION

:__HDS_SKIP
ENDBLOCK
