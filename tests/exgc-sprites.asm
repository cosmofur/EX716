# EXGC transparency and quarter-turn rotation demo.
# Run from repository root with --exgc-render; requires SIXEL.
.CODE 0
.ORG 0x100
.DATA 1
I commonDS.mc
L softstackDS.ld
L timetool.ld
::Frame 0
::Position 0
::Row 0
::Column 0
::Address 0

:Main .ENTRY Main
@DSSInitQuick
@PUSH 0xfc @SSET SegES

# Palette index zero is transparent to sprites but remains black on the framebuffer.
@PUSH 0x8000 @PUSH 0xf840 @ESO @POPS
@PUSH 0x7c00 @PUSH 0xf842 @ESO @POPS
@PUSH 0x7fe0 @PUSH 0xf844 @ESO @POPS
@PUSH 0x7fff @PUSH 0xf846 @ESO @POPS
@PUSH 0x0848 @PUSH 0xf848 @ESO @POPS  # dark blue
@PUSH 0x1144 @PUSH 0xf84a @ESO @POPS  # dark teal
@PUSH 0x2d6b @PUSH 0xf84c @ESO @POPS  # grid lines

# Checkerboard and grid are framebuffer pixels; transparent parts of each
# sprite reveal these colors as the sprite travels over the pattern.
@MA2V 0 Address
@ForIA2B Row 0 192
   @ForIA2B Column 0 60
      @PUSHI Row @AND 31
      @IF_ZERO
         @POPNULL
         @PUSH 0x6666
      @ELSE
         @POPNULL
         @PUSHI Column @AND 7
         @IF_ZERO
            @POPNULL
            @PUSH 0x6666
         @ELSE
            @POPNULL
            @PUSHI Row @SHRN 4 @PUSHI Column @SHRN 2 @XORS @AND 1
            @IF_ZERO
               @POPNULL @PUSH 0x4444
            @ELSE
               @POPNULL @PUSH 0x5555
            @ENDIF
         @ENDIF
      @ENDIF
      @PUSHI Address @ESO @POPS
      @INC2I Address
   @Next Column
@Next Row

# Asymmetric arrow: its transparent corners show the background.
@PUSH 0x0100 @PUSH 0xb400 @ESO @POPS
@PUSH 0x0000 @PUSH 0xb402 @ESO @POPS
@PUSH 0x1200 @PUSH 0xb404 @ESO @POPS
@PUSH 0x0010 @PUSH 0xb406 @ESO @POPS
@PUSH 0x2301 @PUSH 0xb408 @ESO @POPS
@PUSH 0x0021 @PUSH 0xb40a @ESO @POPS
@PUSH 0x3312 @PUSH 0xb40c @ESO @POPS
@PUSH 0x1032 @PUSH 0xb40e @ESO @POPS
@PUSH 0x1200 @PUSH 0xb410 @ESO @POPS
@PUSH 0x0010 @PUSH 0xb412 @ESO @POPS
@PUSH 0x1200 @PUSH 0xb414 @ESO @POPS
@PUSH 0x0010 @PUSH 0xb416 @ESO @POPS
@PUSH 0x1200 @PUSH 0xb418 @ESO @POPS
@PUSH 0x0010 @PUSH 0xb41a @ESO @POPS
@PUSH 0x0000 @PUSH 0xb41c @ESO @POPS
@PUSH 0x0000 @PUSH 0xb41e @ESO @POPS

# Two descriptors: both use pattern 0; second is flipped horizontally.
@PUSH 0 @PUSH 0xe000 @ESO @POPS
@PUSH 70 @PUSH 0xe002 @ESO @POPS
@PUSH 0 @PUSH 0xe004 @ESO @POPS
@PUSH 1 @PUSH 0xe006 @ESO @POPS
@PUSH 200 @PUSH 0xe008 @ESO @POPS
@PUSH 110 @PUSH 0xe00a @ESO @POPS
@PUSH 0 @PUSH 0xe00c @ESO @POPS
@PUSH 5 @PUSH 0xe00e @ESO @POPS
@PUSH 0x10 @PUSH 0xf804 @ESO @POPS
@PUSH 0x0205 @PUSH 0xf808 @ESO @POPS

# Move in opposite directions and rotate by 90 degrees each frame.
@ForIA2B Frame 0 30
   @PUSHI Frame @DUP @SHL @ADDS @SHL @POPI Position
   @PUSHI Position @PUSH 0xe000 @ESO @POPS
   @PUSH 200 @SUBI Position @PUSH 0xe008 @ESO @POPS
   @PUSHI Frame @AND 3 @SHLN 4 @OR 1 @PUSH 0xe006 @ESO @POPS
   @PUSHI Frame @AND 3 @SHLN 4 @OR 5 @PUSH 0xe00e @ESO @POPS
   @Call(A) Sleep 1
@Next Frame
@END
