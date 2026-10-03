.DATA 1
I commonDS.mc
L clocals.ld

@FUNCTION SetThroughPointer
:SetThroughPointer
@PUSHRETURN
@CLocals 4
@CLocal Value
@CLocal Pointer
   @CPOPI Pointer
   @CPOPI Value
   @CPUSHI Value
   @CPUSHI Pointer
   @POPS
@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION RecursiveSum
:RecursiveSum
@PUSHRETURN
@CLocals 4
@CLocal N
@CLocal Saved
   @CPOPI N
   @CPUSHI N
   @CPOPI Saved
   @CPUSHI N
   @IF_LE_A 1
      @POPNULL
      @PUSH 1
      @JMP RecursiveSumDone
   @ENDIF
   @POPNULL
   @CPUSHI N
   @SUB 1
   @CALL RecursiveSum
   @CPUSHI Saved
   @ADDS
:RecursiveSumDone
@EndCLocals
@POPRETURN
@RET
@ENDFUNCTION

.ORG 0x2000
:Main
@PUSH 1
@SSET SegDS
@PUSH 1
@ADM

@CLocals 6
@CLocal Value
@CLocal32 Wide
   @PUSH 1234
   @CPUSHADDR Value
   @CALL SetThroughPointer
   @CPUSHI Value
   @PRTTOP
   @POPNULL
   @PRTNL

   @PUSH 0x5678
   @PUSH 0x1234
   @CPOP32I Wide
   @CPUSH32I Wide
   @PRTHEXTOP
   @SWP
   @PRTHEXTOP
   @POPNULL
   @POPNULL
   @PRTNL
@EndCLocals

@PUSH 5
@CALL RecursiveSum
@PRTTOP
@POPNULL
@PRTNL

@PUSH 0
@ADM
@END
