I common.mc
:Main . Main
# ---- Carry + Overflow Flag Test ----

# ---- ADD cases for CF ----
@PUSH 0xFFFF
@ADD  0x0001       # expect CF=1, OF=0

@PUSH 0x0001
@ADD  0x0001       # expect CF=0, OF=0

# ---- SUB cases for CF ----
@PUSH 0x0000
@SUB  0x0001       # expect CF=1, OF=0

@PUSH 0x0001
@SUB  0x0001       # expect CF=0, OF=0

# ---- ADD cases for OF ----
@PUSH 0x4000
@ADD  0x4000       # 16384 + 16384 = 0x8000 (-32768), expect OF=1

@PUSH 0x7FFF
@ADD  0x0001       # 32767 + 1 = -32768, expect OF=1

# ---- SUB cases for OF ----
@PUSH 0x8000
@SUB  0x0001       # -32768 - 1 wraps, expect OF=1

@PUSH 0x7FFF
@SUB  0xFFFF       # 32767 - (-1) = 32768, expect OF=1

# ---- End ----
@END
