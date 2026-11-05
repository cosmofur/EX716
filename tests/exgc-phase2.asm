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

# Direct word stores prove that the running CPU24 program, rather than only
# assembler data initialization, can draw to either framebuffer.
@PUSH 0x1234
@POPI 0x0000
@PUSH 0xabcd
@POPI 0x5a00

# Program all RGB555 palette entries through MMIO.  Entry 1 remains red for
# the default solid-frame smoke image; the complete palette supports the
# host-side color-bar/checkerboard/diagonal visual validation harness.
@PUSH 0x0000
@POPI 0xf840
@PUSH 0x7c00
@POPI 0xf842
@PUSH 0x001f
@POPI 0xf844
@PUSH 0x03ff
@POPI 0xf846
@PUSH 0x4210
@POPI 0xf848
@PUSH 0x7c1f
@POPI 0xf84a
@PUSH 0x7fe0
@POPI 0xf84c
@PUSH 0x7fff
@POPI 0xf84e
@PUSH 0x2108
@POPI 0xf850
@PUSH 0x6318
@POPI 0xf852
@PUSH 0x021f
@POPI 0xf854
@PUSH 0x03ff
@POPI 0xf856
@PUSH 0x7c10
@POPI 0xf858
@PUSH 0x7c1f
@POPI 0xf85a
@PUSH 0x7ff0
@POPI 0xf85c
@PUSH 0x7fff
@POPI 0xf85e

# Page B then page A: the write to bit 1 applies immediately in Phase 2.
@PUSH 0x0002
@POPI 0xf802
@PUSH 0x0000
@POPI 0xf802

@PUSH 0
@ADM
@END
