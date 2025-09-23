I common.mc
# -------------------------------
# Simple nested loop stress test
# -------------------------------
# OuterCount × InnerCount ≈ total iterations

    @PUSH 0x0100        # OuterCount (256)
    @POPI  OUTER

:OuterLoop
    @PUSH 0xFFFF        # InnerCount (65535)
    @POPI  INNER

:InnerLoop
    # --- hot loop body ---
    NOP
    NOP
    # put a couple of simple ops here
    # ----------------------

    @PUSHI INNER
    @SUB 1
    @POPI INNER
    @JNZ  InnerLoop

    @PUSHI OUTER
    @SUB 1
    @POPI OUTER
    @JNZ  OuterLoop

    @END

# -------------------------------
# Vars
:OUTER 0
:INNER 0
