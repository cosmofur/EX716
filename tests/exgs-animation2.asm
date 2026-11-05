# Fixed-point parabola with distance bands and a cycling RGB555 palette.
# Run: CPUPATH=lib python3 cpu24.py -f --exgc-render tests/exgs-animation2.asm

.CODE 0
.ORG 0x100
.DATA 1
M UseSoftStackDS 1
I commonDS.mc
L heapmgrDS.ld
L timetool.ld

=GraphDS 0xfc
=RingOne 1
=Black 0x0
=PaletteAddress 0xf840
=FrameBufferA 0x0
=FrameBufferB 0x5a00
=FBRegVideoPage 0xf802
=BackgroundColor 0

::MainHeap 0
::ActiveFrameBuffer FrameBufferA
M MUL120I @PUSHI %1 @SHLN 3 @DUP @SHLN 4 @SWP @SUBS
# Setup Stack and Heap
:InitMemory
   @HeapDSInitS MainHeap 0x200 0xff00 1000 3
@RET



# ClearWindow(Color)
# Clears both frame buffers to a single background color
:ClearWindow
@PUSHRETURN
@Locals
   @Local NewColor
   @Local Index
   @Local FrameB1
   @Local FrameB2
   
   @POPI NewColor

   # Turn NewColor into 4 Nibbles of same color
   @PUSHI NewColor
   @DUP @SHLN 4
   @ORS
   @DUP
   @SHLN 8
   @ORS
   @POPI NewColor

   # Set start index for both frame buffers
   @MA2V FrameBufferA FrameB1
   @MA2V FrameBufferB FrameB2

   @ForIA2B Index 0 0x2d00
      @PUSHI NewColor
      @PUSHI FrameB1
      @ESO @POPS
      @PUSHI NewColor
      @PUSHI FrameB2
      @ESO @POPS
      @INC2I FrameB1
      @INC2I FrameB2
   @Next Index
@EndLocals
@POPRETURN
@RET      
   

# SetPallet(Index, ColorCode)
:SetPalette
@PUSHRETURN
@Locals
  @Local ColorCode
  @Local Index
  
  @POPI2 ColorCode Index
  
  @PUSHI ColorCode
  @PUSH PaletteAddress
  @ADDI Index
  @ADDI Index  
   @ESO @POPS
  
@EndLocals
@POPRETURN
@RET

# SetPixel(X,Y,Color)
:SetPixel
@PUSHRETURN
@Locals
   @Local InX1
   @Local InY1
   @Local InColor
   @Local PixelByteAddress
   @Local WordValue
   
   @POPI3 InColor InY1 InX1

   # Calculate offset from base page
   @MUL120I InY1
   @PUSHI InX1 @SHRN 1
   @ADDS
   @ADDI ActiveFrameBuffer
   @POPI PixelByteAddress

   @PUSHI PixelByteAddress
   @ESO @PUSHS
   @POPI WordValue

   @PUSHI InX1 @AND 0x1
   @IF_ZERO
      # Value wanted is nibble 2
      @POPNULL
      @PUSH 0xff0f      # Mask to save other 3 nibbles
      @ANDI WordValue
      @PUSHI InColor
      @AND 0xf
      @SHLN 4
      @ORS
   @ELSE
      @POPNULL
      @PUSH 0xfff0      # Mask to save other 3 nibbles
      @ANDI WordValue
      @PUSHI InColor
      @AND 0xf
      @ORS
   @ENDIF
   @PUSHI PixelByteAddress
   @ESO @POPS
@EndLocals
@POPRETURN
@RET


      

      
   
   

   
  

# A closed rainbow in RGB555. Index 0 remains the black background.
::Rainbow 0x7c00
::__ 0x7d40
::__ 0x7ea0
::__ 0x7fe0
::__ 0x5fe0
::__ 0x2fe0
::__ 0x03e0
::__ 0x03ea
::__ 0x03f5
::__ 0x03ff
::__ 0x029f
::__ 0x015f
::__ 0x001f
::__ 0x3c1f
::__ 0x781f

# Draw y = 165 - (x - 120)^2 / 128. The numerator is an integer
# fixed-point value with seven fractional bits; its maximum is 14161.
# Color bands measure horizontal distance from the curve's vertex (120,165).
:DrawCurve
@PUSHRETURN
@Locals
   @Local CurveX
   @Local Distance
   @Local CurveY
   @Local Band

   @ForIA2B CurveX 1 240
      @PUSHI CurveX
      @IF_LT_A 120
         @POPNULL
         @PUSH 120 @SUBI CurveX @POPI Distance
      @ELSE
         @POPNULL
         @PUSHI CurveX @SUB 120 @POPI Distance
      @ENDIF

      @Call(VV) MULU Distance Distance
      @SHRN 7
      @PUSH 165 @SWP @SUBS @POPI CurveY
      @PUSHI Distance @SHRN 3 @ADD 1 @POPI Band

      # Three pixels thick so the curve remains easy to see.
      @Call(VVV) SetPixel CurveX CurveY Band
      @DECI CurveY
      @Call(VVV) SetPixel CurveX CurveY Band
      @INC2I CurveY
      @Call(VVV) SetPixel CurveX CurveY Band
   @Next CurveX
@EndLocals
@POPRETURN
@RET

# Shift the colors through palette entries 1..15 without redrawing pixels.
# The phase is in the range 0..14.
:CyclePalette
@PUSHRETURN
@Locals
   @Local Phase
   @Local PaletteIndex
   @Local ColorIndex
   @Local ColorValue
   @POPI Phase

   @ForIA2B PaletteIndex 1 16
      @PUSHI PaletteIndex @SUB 1 @ADDI Phase
      @IF_GE_A 15
         @SUB 15
      @ENDIF
      @POPI ColorIndex
      @PUSHI ColorIndex @SHL @ADD Rainbow @PUSHS @POPI ColorValue
      @Call(VV) SetPalette PaletteIndex ColorValue
   @Next PaletteIndex
@EndLocals
@POPRETURN
@RET

:Main .ENTRY Main
@PUSH 1
@SSET SegDS
@PUSH RingOne
@ADM
@CALL InitMemory

@Locals
   @Local Phase
   @Local Frame

   @PUSH GraphDS
   @SSET SegES
   @Call(AA) SetPalette BackgroundColor Black
   @Call(A) ClearWindow BackgroundColor
   @MA2V 0 Phase
   @Call(V) CyclePalette Phase
   @CALL DrawCurve

   # Two complete cycles, one palette change per second.
   @ForIA2B Frame 0 30
      @Call(A) Sleep 1
      @INCI Phase
      @IF_EQ_AV 15 Phase
         @MA2V 0 Phase
      @ENDIF
      @Call(V) CyclePalette Phase
   @Next Frame
@EndLocals
@END
