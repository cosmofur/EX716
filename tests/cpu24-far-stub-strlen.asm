# Focused label-rebinding / far-stub regression.
# Run with --no_auto_bank: explicit CS placement isolates the stub protocol.
.DATA 1
I commonDS.mc
L softstack.ld
L string.ld

::StubString "stub!\0"

.CODE 0
:Main
.ENTRY Main
@PUSH 1
@ADM
@PUSH 1
@SSET SegDS
@PUSH 0xfff0
@PUSH 0xf000
@CALL SetSSStack
@FCALL 3 RunCS3
@IF_EQ_A 5
   @PRTLN "CPU24 far strlen stub PASS"
@ELSE
   @PRTLN "CPU24 far strlen stub FAIL"
@ENDIF
@POPNULL
@PUSH 0
@ADM
@END

# Preserve the original CS0 binding and expose it through a far entry.
=strlen_original strlen
@FUNCTION(F) strlen_far
@CALL strlen_original
@SWP @RET
@ENDFUNCTION

.CODE 3
:strlen_stub
@FCALL 0 strlen_far
@SWP @RET

# This binding is active only for the CS3 code below.
=strlen strlen_stub

@FUNCTION(F) RunCS3
@PUSH StubString
@CALL strlen
@SWP @RET
@ENDFUNCTION

.CODE 0
# Restore the original binding for following CS0 code.
=strlen strlen_original
