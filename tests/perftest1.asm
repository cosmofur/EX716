I common.mc
:Main . Main
# Stress test: simple loop with math ops
    @PUSH 0xffff        # Loop counter
    @POPI LoopCount

:LoopTop
    @PUSH 1234
    @PUSH 5678
    @ADDS              # 5678+1234
    @PUSH 1111
    @SUBS              # (prev - 1111)
    @PUSH 3333
    @XORS              # scramble
    @POPNULL            # discard

    @PUSHI LoopCount
    @PUSH 1
    @SUBS
    @POPI LoopCount
    @JNZ LoopTop

    @END
:LoopCount 0
