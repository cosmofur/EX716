.DATA 1
.CODE 0
.ORG 0x0100
M UseSoftStackDS 1
I commonDS.mc
L heapmgrDS.ld

::MainHeap 0
::FirstObject 0
::SecondObject 0
::ReusedObject 0
::AvailableBefore 0
::AvailableAfter 0

.ORG 0x2000
:CommonSyntax
@PUSHRETURN
@Locals
   @Local Value
   @POPI Value
   @PUSHI Value @ADD 1
@EndLocals
@POPRETURN
@RET

:Main
.ENTRY Main
@PUSH 1
@SSET SegDS
@PUSH 1
@ADM

# The macro establishes a 4 KiB DSS stack at d000..e000, then makes
# 0200..d000 an ordinary DS-local heap without touching legacy softstack.
@HeapDSInitS MainHeap 0x0200 0xe000 0x1000 3
@CALL DSSRemaining
@PRT "DSS free=" @PRTTOP @POPNULL @PRTNL
@PUSH 5 @CALL CommonSyntax
@PRT "COMMON=" @PRTTOP @POPNULL @PRTNL

@PUSHI MainHeap @CALL HeapDSAvailable @POPI AvailableBefore
@PUSHI MainHeap @PUSH 32 @CALL HeapDSNewObject @POPI FirstObject
@PUSHI MainHeap @PUSH 64 @CALL HeapDSNewObject @POPI SecondObject
@PUSH 0x1234 @PUSHI FirstObject @POPS
@PUSH 0x5678 @PUSHI SecondObject @POPS
@PUSHI MainHeap @PUSHI FirstObject @CALL HeapDSDeleteObject @POPNULL
@PUSHI MainHeap @PUSH 16 @CALL HeapDSNewObject @POPI ReusedObject
@PUSHI MainHeap @CALL HeapDSAvailable @POPI AvailableAfter

@PRT "HDS first=" @PRTHEXI FirstObject
@PRT " second=" @PRTHEXI SecondObject
@PRT " reused=" @PRTHEXI ReusedObject
@PRT " value=" @PUSHI SecondObject @PUSHS @PRTHEXTOP @POPNULL
@PRT " free=" @PRTI AvailableBefore @PRT "/" @PRTI AvailableAfter @PRTNL

# DS 2 receives a separate near heap, but deliberately does not initialize a
# second stack.  All stack helpers must return to DS 2 after using fixed DS 3.
@PUSH 2 @SSET SegDS
@PUSH 0x0200
@PUSH 0xce00
@CALL HeapDSDefineMemory
@POPI MainHeap
@PUSHI MainHeap @PUSH 16 @CALL HeapDSNewObject @POPI FirstObject
@PUSH 0x2222 @PUSHI FirstObject @POPS
@PRT "DS2=" @PUSHI FirstObject @PUSHS @PRTHEXTOP @POPNULL @PRTNL
@PUSH 7 @CALL CommonSyntax
@PRT "COMMON2=" @PRTTOP @POPNULL @PRTNL
@SGET SegDS @PRT "AFTER DS=" @PRTTOP @POPNULL @PRTNL

@PUSH 1 @SSET SegDS
@PRT "DS1=" @PUSHI SecondObject @PUSHS @PRTHEXTOP @POPNULL @PRTNL
@PUSH 0 @ADM
@END
