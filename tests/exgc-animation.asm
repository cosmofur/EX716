# EXGC timing/page-flip demonstration.  Each phase changes only the
# non-displayed framebuffer, requests a bit-2 VBlank flip, then polls bit 3.
I commonDS.mc

.CODE 0
.ORG 0x0100
:Main
.ENTRY Main
@PUSH 0xfc
@SSET SegDS
@PUSH 1
@ADM

# Palette index 1 is bright red; framebuffer reset state is black.
@PUSH 0x7c00
@POPI 0xf842

:Bounce
# B: erase its previous ball at x=160 and draw at x=40, y=96.
@PUSH 0
@POPI 0x8750
@PUSH 0x1111
@POPI 0x8714
@PUSH 0x0006                 # requested B + deferred-flip command
@POPI 0xf802
:WaitBLeft
@PUSH 0xf802
@PUSHS
@AND 0x0008
@POPNULL
@JMPZ WaitBLeft

# A: erase its previous ball at x=140 and draw at x=80.
@PUSH 0
@POPI 0x2d46
@PUSH 0x1111
@POPI 0x2d28
@PUSH 0x0004                 # requested A + deferred-flip command
@POPI 0xf802
:WaitALeft
@PUSH 0xf802
@PUSHS
@AND 0x0008
@POPNULL
@JMPZ WaitALeft

# B moves to the right while A is displayed.
@PUSH 0
@POPI 0x8714
@PUSH 0x1111
@POPI 0x8750
@PUSH 0x0006
@POPI 0xf802
:WaitBRight
@PUSH 0xf802
@PUSHS
@AND 0x0008
@POPNULL
@JMPZ WaitBRight

# A moves to the right while B is displayed, then repeat the bounce.
@PUSH 0
@POPI 0x2d28
@PUSH 0x1111
@POPI 0x2d46
@PUSH 0x0004
@POPI 0xf802
:WaitARight
@PUSH 0xf802
@PUSHS
@AND 0x0008
@POPNULL
@JMPZ WaitARight
@JMP Bounce
