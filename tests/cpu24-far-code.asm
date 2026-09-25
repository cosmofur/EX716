# Focused CPU24 code-bank regression. Exercises explicit entry selection,
# nested far calls, local calls, WHILE, IF/ELSE, and return values.
.DATA 1
I commonDS.mc
L softstack.ld

::LoopCount 0
::BankOneLocalValue 0x1111
::BankTwoLocalValue 0x2222

.CODE 0
.ORG 0x0100
:Main
.ENTRY Main
@PUSH 1
@ADM
@FCALL 1 FarLoop
@IF_EQ_A 42
   @PRTLN "CPU24 far-code PASS"
@ELSE
   @PRTLN "CPU24 far-code FAIL"
@ENDIF
@POPNULL
@PUSH 0
@ADM
@END

.CODE 1
.ORG 0x0200
=ReusedLocal BankOneLocalValue
@FUNCTION(F) FarLoop
@MA2V 0 LoopCount
@PUSHI LoopCount
@WHILE_LT_A 3
   @POPNULL
   @INCI LoopCount
   @PUSHI LoopCount
@ENDWHILE
@POPNULL
@FCALL 2 FarValue
@SWP @RET
@ENDFUNCTION

.CODE 2
.ORG 0x0300
=ReusedLocal BankTwoLocalValue
@FUNCTION(F) FarValue
@CALL LocalValue
@SWP @RET
@ENDFUNCTION

:LocalValue
@PUSHI LoopCount
@IF_EQ_A 3
   @POPNULL
   @PUSH 42
@ELSE
   @POPNULL
   @PUSH 0
@ENDIF
@SWP @RET
