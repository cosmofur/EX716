# A startup call must be relocated when its target is moved to another code
# bank.  Its return value must survive the far veneer too.
I commonDS.mc
L softstack.ld
.DATA 1

:Main
.ENTRY Main
@PUSH 1
@ADM
@PUSH 1
@SSET SegDS
@PUSH 0xfff0
@PUSH 0xf000
@CALL SetSSStack
@CALL Relocated
@IF_EQ_A 42
   @PRTLN "CPU24 auto-bank entry PASS"
@ELSE
   @PRTLN "CPU24 auto-bank entry FAIL"
@ENDIF
@POPNULL
@PUSH 0
@ADM
@END

# Force the next captured function to be placed in a new CS bank.
.ORG 0xfc00
@FUNCTION Relocated
:Relocated
@PUSH 42
@SWP
@RET
@ENDFUNCTION
