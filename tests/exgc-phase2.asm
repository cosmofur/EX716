# Minimal Phase 2 EXGC guest-side setup.  A host caller must invoke the
# explicit EXGCRender operation after execution to refresh the terminal.
I commonDS.mc

# Preload framebuffer A with palette index 1 in every pixel.  The guest below
# changes that palette entry to red, producing a full 720x384 test image when
# run with cpu24.py --exgc-render.
.DATA 0xfc
::FramebufferA $$0x11 * 23040
.CODE 0

.ORG 0x0100
:Main
.ENTRY Main
@PUSH 0xfc
@SSET SegDS
@PUSH 1
@ADM

# Palette entry 0 is black; entry 1 is bright red (RGB555).
@PUSH 0x0000
@POPI 0xf840
@PUSH 0x7c00
@POPI 0xf842

# Page B then page A: the write to bit 1 applies immediately in Phase 2.
@PUSH 0x0002
@POPI 0xf802
@PUSH 0x0000
@POPI 0xf802

@PUSH 0
@ADM
@END
