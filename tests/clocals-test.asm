I common.mc
. 0x0100
@JMP Main
L clocals.ld

# SetThroughPointer(value, pointer)
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

# RecursiveSum(n): verifies that each recursive invocation owns its frame.
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

:Main
# Taking the address of a C local remains valid in a nested call.
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

# Confirm 32-bit frame access and word ordering.
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

# 1+2+3+4+5 = 15, with five simultaneous C frames.
@PUSH 5
@CALL RecursiveSum
@PRTTOP
@POPNULL
@PRTNL
@END
