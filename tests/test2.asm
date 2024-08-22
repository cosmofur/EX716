I common.mc
@PUSH 0x7ffe
@PUSH 2
@ADDS
@PRT "0xffff + 0x2 = " @PRTHEXTOP @CALL PrtFlags
@POPNULL
@PUSH 0xffff
@PUSH 0xffff
@ADDS     # Expect Overflow
@PRT "0xffff + 0xffff = " @PRTHEXTOP @CALL PrtFlags
@POPNULL
@PUSH 0xffff
@PUSH 0x7fff
@ADDS     # No further overflows expected.
@PRT "0xffff + 0x7fff= " @PRTHEXTOP @CALL PrtFlags
@POPNULL
@PUSH 0x7fff
@PUSH 0xffff
@ADDS
@PRT "0x7fff + 0xffff= " @PRTHEXTOP @CALL PrtFlags
@POPNULL
@PUSH 0x7ffe
@PUSH 0xfffe
@PRT "0x7ffe + 0xfffe= " @PRTHEXTOP @CALL PrtFlags
@ADDS
@POPNULL
@END
:PrtFlags
@JMPZ IsZero
@PRT " -"
:BackZero
@JMPN IsNeg
@PRT "-"
:BackNeg
@JMPO IsOver
@PRT "-"
:BackOver
@JMPC IsCarry
@PRT "-\n"
:BackCarry
@RET


:IsZero
@PRT " Z"
@JMP BackZero
:IsNeg
@PRT "N"
@JMP BackNeg
:IsOver
@PRT "O"
@JMP BackOver
:IsCarry
@PRT "C\n"
@JMP BackCarry
