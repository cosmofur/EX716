I common.mc
L lmath.ld
@JMP TestStart
:IDX 0
:ODX 0
:InPut
b1 b0 b0 b0
b2 b0 b0 b0
b3 b0 b0 b0
b4 b0 b0 b0
b5 b0 b0 b0
b6 b0 b0 b0
:OutPut 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
:StackSpace 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
:IDX 0
:IDX2 0
:PrtBuff 0
:Return1 0
:TestStart
@PUSH StackSpace
@CALL SPInit32
@MA2V InPut IDX
@MA2V 0 ODX
:LoadLoop1
@PUSHI IDX
@PRT32I IDX
@PRT ","
@CALL SPPush32
@PUSHI IDX
@PRT " "
@CMP OutPut
@JGE EndLoop
@ADD 4
@POPI IDX
@JMP LoadLoop1
:EndLoop
@PUSH 5
@CMPI ODX
@POPNULL
@JMPZ lastpart
@PUSHI ODX
@CALL SPGet32
@PRT32S 0
@PRT "-"
@INCI ODX
@JMP EndLoop
:lastpart
@PRTLN "End of loop"

@END
