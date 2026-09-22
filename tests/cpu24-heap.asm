.DATA 1
I commonDS.mc
L softstack.ld
L heapmgr.ld

;MainHeapID 2 0
;ObjectID 2 0

.ORG 0x2000
:Main
# SSET is available before Ring 1 so ADM immediately enters with the desired DS.
@PUSH 1
@SSET SegDS
@PUSH 1
@ADM

# commonDS.mc's Var01..Var20 labels are logical offsets. Their active storage
# must be in DS, and LocalVar/RestoreVar must preserve the caller's values.
@MA2V 0x1111 Var01
@MA2V 0x2020 Var20

# Keep fixed DS storage below the heap and reserve f000..ffff for the
# software stack. Heap IDs below 100 are reserved as error returns, so start
# this small test's heap at 0x0100 (comfortably above __DEND).
@PUSH 0x0100
@PUSH 0xe000
@SUB 0x0100
@CALL HeapDefineMemory
@POPI MainHeapID

@PUSHI MainHeapID
@IF_ULT_A 100
   @PRTLN "HeapDefineMemory failed"
   @END
@ENDIF
@POPNULL

@PUSHI MainHeapID
@PUSH 32
@CALL HeapNewObject
@POPI ObjectID

@PUSHI ObjectID
@IF_ULT_A 100
   @PRTLN "HeapNewObject failed"
   @END
@ENDIF
@POPNULL

@PUSH 0x716
@PUSHI ObjectID
@POPS

@PRT "Heap bank: "
@SGET SegDS
@PRTHEXTOP
@POPNULL
@PRT " object: "
@PRTHEXI ObjectID
@PRT " value: "
@PUSHI ObjectID
@PUSHS
@PRTHEXTOP
@POPNULL
@PRTNL

@PUSHI MainHeapID
@PUSHI ObjectID
@CALL HeapDeleteObject
@PRT "Delete status: "
@PRTTOP
@POPNULL
@PRTNL

@PRT "DS locals: "
@PRTHEXI Var01
@PRT " "
@PRTHEXI Var20
@PRTNL

@PUSH 0
@ADM
@END
