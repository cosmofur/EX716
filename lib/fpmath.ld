! __LIB_FPMATH_LOADED
M __LIB_FPMATH_LOADED 1
L lmath.ld
########################
# Published functions
G FP32_UNPACK
G FP32_PACK
G SHIFT_RIGHT_JAM32
G FP32_NORMALIZE
G FP_ADD
G FP_SUB
G FP_MUL

G MUL24X24U
G FP32_EXTRACT_PRODUCT
G FP_CMP

= FP_INVALID     0x0001
= FP_DIVZERO     0x0002
= FP_OVERFLOW    0x0004
= FP_UNDERFLOW   0x0008
= FP_INEXACT     0x0010

:FP_Status 0
G FP_Status

# ===========================================================
# Function : FP32_UNPACK
# Purpose  : Separate IEEE binary32 into sign, exponent,
#            and 24-bit significand.
# Inputs   : [ ... FP_Low FP_High ]
# Outputs  : [ ... Sign Exponent MantLow MantHigh ]
# ===========================================================
##############################
@FUNCTION FP32_UNPACK
# FPRE_UNPACK(LowWord,HighWord):(Sign, Exponent, MantLow, MantHigh)
:FP32_UNPACK
@PUSHRETURN
@Locals
   @Local LowWord
   @Local HighWord
   @Local Sign
   @Local Exponent
   @Local MantHigh

   @POPI2 HighWord LowWord

   @MA2V 0 Sign
   @MA2V 0 Exponent
   @MA2V 0 MantHigh

   @PUSHI HighWord
   @AND 0x8000
   @IF_NOTZERO
      @MA2V 1 Sign
   @ENDIF
   @POPNULL

   @PUSHI HighWord
   @AND 0x7f80        # Mask 8 bits from bits 0x6 to 0xe
   @SHRN 7
   @POPI Exponent

   @PUSHI HighWord
   @AND 0x7f
   @POPI MantHigh

   # Handle zero/subnormal exponent and reserved exponent
   @PUSHI Exponent
   @IF_NOTZERO
      @SUB 0xff
      @IF_NOTZERO
         @PUSHI MantHigh
         @OR 0x80        # normalize high bit to be always 1
         @POPI MantHigh
      @ENDIF
   @ENDIF
   @POPNULL

   @PUSHI4 Sign Exponent LowWord MantHigh
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ===========================================================
# Function : FP32_PACK
# Purpose  : Assemble IEEE binary32 from sign, exponent,
#            and 24-bit significand.
# Inputs   : [ ... Sign Exponent MantLow MantHigh ]
# Outputs  : [ ... FP_Low FP_High ]
# ===========================================================
@FUNCTION FP32_PACK
# FP32_PACK(Sign, Exponent, MantLow, MantHigh):(FP_Low,FP_High)
:FP32_PACK
@PUSHRETURN
@Locals
   @Local Sign
   @Local Exponent
   @Local MantLow
   @Local MantHigh
   @Local FP_High

   @POPI4 MantHigh MantLow Exponent Sign

   @MA2V 0 FP_High

   @IF_NEQ_AV 0 Sign
      @MA2V 0x8000 FP_High
   @ENDIF

   @PUSHI Exponent
   @AND 0xff
   @SHLN 7
   @ORI FP_High
   @POPI FP_High

   @PUSHI MantHigh
   @AND 0x7f
   @ORI FP_High
   @POPI FP_High

   @PUSHI2 MantLow FP_High
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ====================================================
# Function : FP32_NORMALIZE(Sign, Exponent, MantLow, MantHigh)
# Purpose: : Normalize the Floating point data to following
#            Exponent is signed and unbiased
#            MainLow/High contains 24 signficant bits plus GRS
#            Normal leading bit at position 26
#            Carry bit at posiiton 27
#            Minimum normal exponent -126
#            Maximum normal exponent +127
# Result:    Sign BiasedExponent Result Result+2
@FUNCTION FP32_NORMALIZE
:FP32_NORMALIZE
@PUSHRETURN
@Locals
   @Local Sign
   @Local Exponent
   @Local MantLow
   @Local MantHigh
   @Local BiasedExponent
   @Local32 Result
   @Local32 Fraction
   @Local Guard
   @Local Round
   @Local Sticky
   @Local TempJump
   @Local Shift

   @POPI4 MantHigh MantLow Exponent Sign

   @IF_EQ_AV 0 MantLow
      @IF_EQ_AV 0 MantHigh
         @MA2V 0 BiasedExponent
         @MA2V 0 MantLow
         @MA2V 0 MantHigh
         @JMP FP32_NORMALIZE_EXIT
      @ENDIF
   @ENDIF
   :Break2
   @WHEN
      @Call32(VA) CMP32U MantLow $$$0x8000000   # Mant32 >= ( 1<<27)
      @IF32_UGE
         @PUSH 1    # Continue Loop
      @ELSE
         @PUSH 0    # Break Loop
      @ENDIF
   @DO_NOTZERO
      @POPNULL
      @Call32(VA16) SHIFT_RIGHT_JAM32 MantLow 1
      @POP32I(V) MantLow
      @INCI Exponent
   @ENDWHEN
   @POPNULL   
   #
   @WHEN
      @Call32(VA) CMP32U MantLow $$$0x4000000  # Main32 < ( 1<<26)
      @IF32_ULT
         @PUSH 1
      @ELSE
         @PUSH 0
      @ENDIF
      @PUSHI Exponent
      @IF_LE_A -126
         @POPNULL    # Full test is AND Exponent > -126, so break if it is <= to it.
         @POPNULL
         @PUSH 0
      @ELSE
         @POPNULL
      @ENDIF
   @DO_NOTZERO
      @POPNULL   
      @Call32(V) SHL32_1 MantLow
      @POP32I(V) MantLow
      @DECI Exponent
   @ENDWHEN
   @POPNULL
   # Handle exponent overflow
   @PUSHI Exponent
   @IF_GT_A 127
      @POPNULL
      @MA2V 255 BiasedExponent
      @M32A2V $$$0 Result
      @JMP FP32_NORMALIZE_EXIT
   @ENDIF
   @POPNULL
   # Handle values below subnormal range
   @PUSHI Exponent
   @IF_LT_A -126
      @PUSH -126
      @SUBI Exponent
      @POPI Shift
      @Call32(VV16) SHIFT_RIGHT_JAM32 MantLow Shift 
      @POP32I(V) MantLow
      @MA2V -126 Exponent
   @ENDIF
   @POPNULL
   #
   # Round to nearest, ties on even

   # Fraction = Mant >> 3
   @Call32(VA16) SHR32 MantLow 3
   @POP32I(V) Fraction
   #
   # Guard = bit 2
   @PUSHI MantLow
   @AND 0x0004
   @SHRN 2
   @POPI Guard

   # Round = bit 1
   @PUSHI MantLow
   @AND 0x0002
   @SHRN 1
   @POPI Round

   # Sticky = bit 0
   @PUSHI MantLow
   @AND 0x0001
   @POPI Sticky

   # Compound IF
   # IF Guard == 1 and ( Round == 1 or Sticky == 1 or (Fraction32 & 1 ) == 1 )
   # Guard is bit 2.
   @PUSHI MantLow
   @AND 0x0004
   @IF_NOTZERO
      @POPNULL

      # Round, sticky, or retained LSB:
      # bits 1, 0, and 3.
      @PUSHI MantLow
      @AND 0x000B
      @IF_NOTZERO
         @Call32(VA) ADD32U Fraction $$$1
         @POP32I(V) Fraction
      @ENDIF
      @POPNULL
   @ELSE
      @POPNULL
   @ENDIF
   #
   # Rounding may overflow the significand
   @Call32(VA) CMP32U Fraction $$$0x01000000
   @IF32_UGE
      @Call32(V) SHR32_1 Fraction
      @POP32I(V) Fraction
      @INCI Exponent
      @PUSHI Exponent
      @IF_GT_A 127
          @POPNULL
          @MA2V 255 BiasedExponent                
          @M32A2V $$$0 Result
          @JMP FP32_NORMALIZE_EXIT
      @ENDIF
      @POPNULL
   @ENDIF
   #
   # Normal or sub-normal
   @Call32(VA) CMP32U Fraction $$$0
   @IF32_EQ
      @MA2V 0 BiasedExponent
      @M32A2V $$$0 Result
      @JMP FP32_NORMALIZE_EXIT      
   @ENDIF
   @Call32(VA) CMP32U Fraction $$$0x800000
   @IF32_ULT
      @MA2V 0 BiasedExponent
  @ELSE
      @PUSHI Exponent
      @ADD 127
      @POPI BiasedExponent
  @ENDIF
  #
  # Return Results
  @M32V2V Fraction Result
:FP32_NORMALIZE_EXIT
  @PUSHI4 Sign BiasedExponent Result Result+2

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# 
#


# ========================
# Function: SHIFT_RIGHT_JAM32(ValueLow, ValueHigh, Count):Value32
@FUNCTION SHIFT_RIGHT_JAM32
:SHIFT_RIGHT_JAM32
@PUSHRETURN
@Locals
   @Local Count
   @Local ValueLow
   @Local ValueHigh
   @Local Index
   @Local32 Mask
   @Local32 LostBits
   @Local32 Result


   @POPI3 Count ValueHigh ValueLow
   @M32V2V ValueLow Result

   @IF_NEQ_AV 0 Count
      @PUSHI Count
      @IF_GE_A 32
          @IF_NEQ_AV 0 ValueLow             
             @M32A2V $$$1 Result
          @ELSE
              @IF_NEQ_AV 0 ValueHigh
                 @M32A2V $$$1 Result
              @ENDIF
          @ENDIF
      @ELSE
          # Count has to be between 1 and 31
          # Effect Mask=(1 << Count) -1
          @M32A2V $$$2 Mask
          @ForIA2V Index 1 Count     # By starting at 1 loop will go for Count-1 steps
              @Call32(V) SHL32_1 Mask
              @POP32I(V) Mask
          @Next Index
          @Call32(VA) SUB32U Mask $$$1
          @POP32I(V) Mask
          #
          @Call32(VV) AND32 ValueLow Mask
          @POP32I(V) LostBits
          #
          @Call32(VV16) SHR32 ValueLow Count
          @POP32I(V) Result
          #
          @Call32(VA) CMP32U LostBits $$$0
          @IF32_NE
              @Call32(VA) OR32 Result $$$1
              @POP32I(V) Result
          @ENDIF
       @ENDIF
       @POPNULL
   @ENDIF
   @PUSH32I(V) Result
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ==================================================
# Function: FP_ADD
# Purpose : IEEE binary32 addition, round-to-nearest-even
# Inputs  : [ ... FP1_Low FP1_High FP2_Low FP2_High ]
# Outputs : [ ... Result_Low Result_High ]
# Notes   : FP32_NORMALIZE expects unbiased exponent and
#           27-bit significand (24 significand bits + 3 GRS bits).
#           Current provisional policy for NaN/Inf input:
#           set FP_INVALID and return +0.
# ==================================================
@FUNCTION FP_ADD
:FP_ADD
@PUSHRETURN
@Locals
    @Local32 FP1
    @Local32 FP2
    @Local Sign1
    @Local Sign2
    @Local Exp1
    @Local Exp2
    @Local32 Mant1
    @Local32 Mant2
    @Local32 Result
    @Local ResultSign
    @Local ResultExp
    @Local Shift

    # Consume the four input words. No operands remain on
    # the evaluation stack after these two pops.
    @POP32I(V) FP2
    @POP32I(V) FP1

    # Define a safe result for all early-exit paths.
    @M32A2V $$$0 Result
    @MA2V 0 ResultSign
    @MA2V 0 ResultExp

    # Unpack: Sign, biased exponent, 24-bit significand.
    @Call32(V) FP32_UNPACK FP1
    @POPI4 Mant1+2 Mant1 Exp1 Sign1
    @Call32(V) FP32_UNPACK FP2
    @POPI4 Mant2+2 Mant2 Exp2 Sign2

    # Provisional special-value handling: exponent 255.
    # @IF_EQ_AV tests locals directly; no evaluation-stack
    # Boolean is introduced.
    @IF_EQ_AV 255 Exp1
        @MA2V FP_INVALID FP_Status
        @JMP FP_ADD_QEXIT
    @ENDIF
    @IF_EQ_AV 255 Exp2
        @MA2V FP_INVALID FP_Status
        @JMP FP_ADD_QEXIT
    @ENDIF

    # Both zero: retain common sign, otherwise return +0
    # (round-to-nearest-even convention).
    @IF_EQ_AV 0 Mant1
        @IF_EQ_AV 0 Mant1+2
            @IF_EQ_AV 0 Mant2
                @IF_EQ_AV 0 Mant2+2
                    @IF_EQ_VV Sign1 Sign2
                        @MV2V Sign1 ResultSign
                    @ENDIF
                    @JMP FP_ADD_QEXIT
                @ENDIF
            @ENDIF
        @ENDIF
    @ENDIF

    # One zero: return the other operand without GRS
    # extension or normalization. FP32_PACK masks the
    # implicit leading significand bit for normal numbers.
    @IF_EQ_AV 0 Mant1
        @IF_EQ_AV 0 Mant1+2
            @M32V2V Mant2 Result
            @MV2V Sign2 ResultSign
            @MV2V Exp2 ResultExp
            @JMP FP_ADD_QEXIT
        @ENDIF
    @ENDIF
    @IF_EQ_AV 0 Mant2
        @IF_EQ_AV 0 Mant2+2
            @M32V2V Mant1 Result
            @MV2V Sign1 ResultSign
            @MV2V Exp1 ResultExp
            @JMP FP_ADD_QEXIT
        @ENDIF
    @ENDIF

    # Convert biased exponent to signed unbiased exponent.
    # For subnormals the effective exponent is -126.
    @IF_EQ_AV 0 Exp1
        @MA2V -126 Exp1
    @ELSE
        @PUSHI Exp1
        @SUB 127
        @POPI Exp1
    @ENDIF
    @IF_EQ_AV 0 Exp2
        @MA2V -126 Exp2
    @ELSE
        @PUSHI Exp2
        @SUB 127
        @POPI Exp2
    @ENDIF

    # Extend significands by 3 GRS positions BEFORE alignment.
    @Call32(VA16) SHL32 Mant1 3
    @POP32I(V) Mant1
    @Call32(VA16) SHL32 Mant2 3
    @POP32I(V) Mant2

    # Signed exponent difference. Shift > 0 means FP1 has
    # the larger exponent; Shift < 0 means FP2 does.
    @PUSHI Exp1
    @SUBI Exp2
    @POPI Shift

    # Result exponent starts at Exp1; change it only when
    # Exp2 is greater.
    @MV2V Exp1 ResultExp

    @PUSHI Shift
    @IF_GT_A 0
        # Exp1 > Exp2: align FP2 downward.
        @Call32(VV16) SHIFT_RIGHT_JAM32 Mant2 Shift
        @POP32I(V) Mant2
    @ELSE
        @IF_LT_A 0
            # Exp2 > Exp1: shift FP1 by -Shift.
            @PUSH 0
            @SUBI Shift
            @POPI Shift
            @Call32(VV16) SHIFT_RIGHT_JAM32 Mant1 Shift
            @POP32I(V) Mant1
            @MV2V Exp2 ResultExp
        @ENDIF
    @ENDIF
    @POPNULL               # Remove saved signed difference.

    # Equal signs: add magnitudes. Different signs: subtract
    # smaller aligned magnitude from larger aligned magnitude.
    @IF_EQ_VV Sign1 Sign2
        @Call32(VV) ADD32U Mant1 Mant2
        @POP32I(V) Result
        @MV2V Sign1 ResultSign
    @ELSE
        @Call32(VV) CMP32U Mant1 Mant2
        @IF32_UGT
            @Call32(VV) SUB32U Mant1 Mant2
            @POP32I(V) Result
            @MV2V Sign1 ResultSign
        @ELSE
            @IF32_ULT
                @Call32(VV) SUB32U Mant2 Mant1
                @POP32I(V) Result
                @MV2V Sign2 ResultSign
            @ELSE
                # Exact cancellation, round-to-nearest-even: +0.
                @M32A2V $$$0 Result
                @MA2V 0 ResultSign
                @MA2V 0 ResultExp
                @JMP FP_ADD_QEXIT
            @ENDIF
        @ENDIF
    @ENDIF

    # Normalize/round returns Sign, biased exponent,
    # significand low word, significand high word.
    @PUSHI4 ResultSign ResultExp Result Result+2
    @CALL FP32_NORMALIZE
    @POPI4 Result+2 Result ResultExp ResultSign

:FP_ADD_QEXIT
    # The only evaluation-stack output is the packed FP32.
    @PUSHI4 ResultSign ResultExp Result Result+2
    @CALL FP32_PACK
    @POP32I(V) Mant1
    @PUSH32I(V) Mant1
    @Call32(V) FP_SET_RESULT_FLAGS Mant1
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ============================================================
# FP_SUB - IEEE 754 binary32 subtraction
#
# Input stack:
#    A_Low, A_High, B_Low, B_High
#
# Output stack:
#    Result_Low, Result_High
#
# Computes A - B by calling FP_ADD(A, -B).
# ============================================================

@FUNCTION FP_SUB
:FP_SUB
@PUSHRETURN
@Locals
    @Local32 A
    @Local32 B

    @POP32I(V) B
    @POP32I(V) A

    # Negate B by toggling its sign bit.
    @PUSHI B+2
    @XOR 0x8000
    @POPI B+2

    # Reuse the complete FP_ADD implementation.
    @Call32(VV) FP_ADD A B
    
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ==========================================================
# FP_MUL - IEEE 754 binary32 multiplication
# Input: A_Low A_High B_Low B_High
# Output: Result_Low, Result_High
# Computers A*B
# ==========================================================
@FUNCTION FP_MUL
:FP_MUL
@PUSHRETURN
@Locals
   @Local32 AVal
   @Local32 BVal
   @Local SignA
   @Local ExpA
   @Local32 MantA
   @Local SignB
   @Local ExpB
   @Local32 MantB
   @Local SignR
   @Local ExpR
   @Local32 MantR
   @Local UnbiasedA
   @Local UnbiasedB
   @Local BiasedExpR

   @POP32I(V) BVal
   @POP32I(V) AVal

   @Call32(V) FP32_UNPACK AVal
   @POP32I(V) MantA
   @POPI2 ExpA SignA
   @Call32(V) FP32_UNPACK BVal
   @POP32I(V) MantB
   @POPI2 ExpB SignB

   # Result Sign
   @PUSHI SignA
   @XORI SignB
   @POPI SignR

   # Zero Operands

   @IF_EQ_AV 0 MantA
      @IF_EQ_AV 0 MantA+2
         @JMP FP32_MUL_ZERO
      @ENDIF
   @ENDIF
   @IF_EQ_AV 0 MantB
      @IF_EQ_AV 0 MantB+2
          @JMP FP32_MUL_ZERO
      @ENDIF
   @ENDIF

   # Expondent to unbiaded form.
   @IF_EQ_AV 0 ExpA
      @MA2V -126 UnbiasedA
   @ELSE
      @PUSHI ExpA
      @SUB 127
      @POPI UnbiasedA
   @ENDIF
   @IF_EQ_AV 0 ExpB
      @MA2V -126 UnbiasedB
   @ELSE
      @PUSHI ExpB
      @SUB 127
      @POPI UnbiasedB
   @ENDIF
   
   @PUSHI UnbiasedA
   @ADDI UnbiasedB
   @POPI ExpR

   # Multiple MantA*MantB as 24x24 bit mul
   @Call32(VV) MUL24X24U MantA MantB
   @CALL FP32_EXTRACT_PRODUCT
   
   @ADDI ExpR         # ExpR = ExpR + ExpAdjust
   @POPI ExpR   
   @POP32I(V) MantR

   # Normalize and route to nearest.
   @PUSHI SignR
   @PUSHI ExpR
   @PUSH32I(V) MantR
   @CALL FP32_NORMALIZE
   :FP32_MUL_RETURN
   @CALL FP32_PACK
    @POP32I(V) MantR
    @PUSH32I(V) MantR
    @CALL FP_SET_RESULT_FLAGS
    @PUSH32I(V) MantR
@EndLocals
@POPRETURN
@RET
# Utility block to handle special case zero return.
:FP32_MUL_ZERO
   @PUSHI SignR
   @PUSH 0 @PUSH 0 @PUSH 0
   @JMP FP32_MUL_RETURN

   




############# Notes on logic of using Parital sums to manage a required 48 bit multiply, require these extra bits to properly handle overflow.



   # We need to multiple as if we had 48 bit math, but we only have 32 bit math
   # So build up the higher words with partial products. so non is biggefr than 32 bits
   #  A = ( AHigh << 16) | ALow
   #  B = ( BHigh << 16) | BLow
   #  T0 = AL * BL    16x16=32 bits
   #  T1 = AH * BL    8x16=24 bits
   #  T2 = AL * BL    16x8=24 bits
   #  T3 = AH * BH    8x8 =16 bits
   #  P0 = low16(T0)
   #  Sum1 = high16(T0) + low16(T1) + low16(T2)
   #  P1 = low16(Sum1)
   #  Sum2 = high16(T1) + high16(T2) + T3 + high16(Sum1)
   #  P2 = low16(Sum2)
   # 48 bit result is P0:bits(0-15) P1:bits(16-31) P2:bits(32-47)
   #
   # TO support this will built two helper functions MUL24x24U and PROD48TO32

:FP32_MUL_EXIT


@ENDFUNCTION


# ================================
# Support: FP32_EXTRACT_PRODUCT
# Input: 48 bit product P0 P1 P2
# Output: MantLow MantHigh ExpAdjust
# Convert 48 bit unsigned significand product into a 27 bit extended mantissa
# ================================
# ==========================================
# Support: FP32_EXTRACT_PRODUCT
#
# Input:  P0 P1 P2 (48-bit product)
# Output: MantLow MantHigh ExpAdjust
#
# Converts a normalized 48-bit product into
# a 27-bit extended mantissa with sticky bit.
# ==========================================

@FUNCTION FP32_EXTRACT_PRODUCT
:FP32_EXTRACT_PRODUCT
@PUSHRETURN
@Locals
   @Local P0
   @Local P1
   @Local P2
   @Local ExpAdjust
   @Local Sticky
   @Local ShiftCount
   @Local StickyMask

   @POPI3 P2 P1 P0

   # Default: bit 46 set, bit 47 clear.
   # Total shift = 20 bits (16 + 4).
   @MA2V 0 ExpAdjust
   @MA2V 4 ShiftCount
   @MA2V 0x000F StickyMask

   # If bit 47 is set, shift 21 instead.
   @PUSHI P2
   @AND 0x8000

   @IF_NOTZERO
      @MA2V 1 ExpAdjust
      @MA2V 5 ShiftCount
      @MA2V 0x001F StickyMask
   @ENDIF
   @POPNULL

   # Calculate sticky from discarded bits.
   #
   # Original P0: all 16 bits discarded.
   # Original P1: lowest 4 or 5 bits discarded.

   @PUSHI P1
   @ANDI StickyMask
   @ORI P0

   @IF_NOTZERO
      @MA2V 1 Sticky
   @ELSE
      @MA2V 0 Sticky
   @ENDIF
   @POPNULL

   # Shift the upper 32 bits down by 16.
   @MV2V P1 P0
   @MV2V P2 P1

   # Shift remaining 4 or 5 bits.
   @Call32(VV16) SHR32 P0 ShiftCount
   @POP32I(V) P0

   # Jam discarded bits into bit 0.
   @PUSHI P0
   @ORI Sticky
   @POPI P0

   # Return 27-bit mantissa and adjustment.
   @PUSH32I(V) P0
   @PUSHI ExpAdjust

@EndLocals
@POPRETURN
@RET   


# =================================
# Support: MUL24X24U
# Input: A_LOW, A_HIGH, B_LOW, B_HIGH
# Output: ProdLow, ProdMid, ProdHigh
# =================================
@FUNCTION MUL24X24U
:MUL24X24U
@PUSHRETURN
@Locals
   @Local32 AIn
   @Local32 BIn
   @Local32 T0
   @Local32 T1
   @Local32 T2
   @Local32 T3
   @Local32 Reg1
   @Local32 Reg2
   @Local P0
   @Local P1
   @Local P2

   @POP32I(V) BIn
   @POP32I(V) AIn

   # Before doing math make sure top word is zeroed in temp registers
   @MA2V 0 Reg1+2
   @MA2V 0 Reg2+2

   # T0 = AL * BL
   @MV2V AIn Reg1
   @MV2V BIn Reg2
   @Call32(VV) MUL32U Reg1 Reg2
   @POP32I(V) T0
   # T1 = AH*BL
   @MA2V 0 Reg1+2
   @MA2V 0 Reg2+2
   @MV2V AIn+2 Reg1
   @MV2V BIn Reg2
   @Call32(VV) MUL32U Reg1 Reg2
   @POP32I(V) T1
   # T2 = AL*BH
   @MA2V 0 Reg1+2
   @MA2V 0 Reg2+2
   @MV2V AIn Reg1
   @MV2V BIn+2 Reg2
   @Call32(VV) MUL32U Reg1 Reg2
   @POP32I(V) T2
   # T3 = AH*BH
   @MA2V 0 Reg1+2
   @MA2V 0 Reg2+2
   @MV2V AIn+2 Reg1
   @MV2V BIn+2 Reg2
   @Call32(VV) MUL32U Reg1 Reg2
   @POP32I(V) T3   
   #
   # We'll reused Reg1 and Reg2 to sum up the products
   #
   # P0=low16(T0)
   @MV2V T0 P0
   # Sum1 = High16(T0) + low16(T1) + Low16(T2)
   @MA2V 0 Reg1+2
   @MV2V T0+2 Reg1
   @MA2V 0 Reg2+2
   @MV2V T1 Reg2
   @Call32(VV) ADD32U Reg1 Reg2
   @POP32I(V) Reg1
   @MA2V 0 Reg2+2
   @MV2V T2 Reg2
   @Call32(VV) ADD32U Reg1 Reg2
   @POP32I(V) Reg1
   @MV2V Reg1 P1
   #
   # Sum2 = high16(T1)+high16(T2)+T3+high16(Sum1)
   @MV2V Reg1+2 Reg1     # Reg1==Sum1 we only need high word once now
   @MA2V 0 Reg1+2
   @Call32(VV) ADD32U Reg1 T3   # high16(sum1)+T3
   @POP32I(V) Reg1
   @MA2V 0 Reg2+2
   @MV2V T2+2 Reg2
   @Call32(VV) ADD32U Reg1 Reg2   # + high(T2)
   @POP32I(V) Reg1
   @MA2V 0 Reg2+2
   @MV2V T1+2 Reg2
   @Call32(VV) ADD32U Reg1 Reg2   # + high(T1)
   @POP32I(V) Reg1            
   @MV2V Reg1 P2           # P2=Low(Sum2)

   @PUSHI3 P0 P1 P2
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ===================================
# Support function: FP_SET_RESULT_FLAGS(ResultLow,ResultHigh)
# Sets the Flags32 soft register with the status of the most recent function
# ===================================
@FUNCTION FP_SET_RESULT_FLAGS
:FP_SET_RESULT_FLAGS
@PUSHRETURN
@Locals
   @Local32 Result

   @POP32I(V) Result

   @MA2V 0 Flags32
   # Flags32.Z
   @PUSHI Result+2
   @AND 0x7fff
   @ORI Result
   @IF_ZERO
      @PUSHI Flags32
      @OR Z32Flag
      @POPI Flags32
   @ENDIF
   @POPNULL
   #
   # Flags32.N
   @PUSHI Result+2
   @AND 0x8000
   @IF_NOTZERO
      @PUSHI Flags32
      @AND Z32Flag
      @IF_ZERO
         @PUSHI Flags32
         @OR N32Flag
         @POPI Flags32
      @ENDIF
      @POPNULL
   @ENDIF
   @POPNULL
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
# ==========================================
# FP_CMP: Compare floating point values
# Input: (a_low, a_high, b_low, b_high)
# output: ( --- ) Flags32 set
# ==========================================
@FUNCTION FP_CMP
:FP_CMP
@PUSHRETURN
@Locals
   @Local32 AVal
   @Local32 BVal
   @Local Neg_A
   @Local Neg_B

   @POP32I(V) BVal
   @POP32I(V) AVal

   # Capture old Sign flags
   @PUSHI AVal+2
   @AND 0x8000
   @POPI Neg_A
   @PUSHI BVal+2
   @AND 0x8000
   @POPI Neg_B
   #
   # Clear signs
   @PUSHI AVal+2
   @AND 0x7fff
   @POPI AVal+2
   @PUSHI BVal+2
   @AND 0x7fff
   @POPI BVal+2
@PRT " SignA="
@PRTHEXI Neg_A
@PRT " SignB="
@PRTHEXI Neg_B
@PRTNL

   #
   @IF_NEQ_VV Neg_A Neg_B
      # Opposite signs.
      # handle +0 vs -0
      @PUSHI AVal
      @ORI AVal+2
      @ORI BVal
      @ORI BVal+2
      @IF_ZERO
         @MA2V Z32Flag Flags32
      @ELSE
         # Negative so A < B
         @IF_NEQ_AV 0 Neg_A
            @PUSH N32Flag
            @OR C32Flag
            @POPI Flags32
         @ELSE
            # Else A > B 
            @MA2V 0 Flags32
         @ENDIF
      @ENDIF
      @POPNULL
   @ELSE
      # Same sign cases
      @IF_NEQ_AV 0 Neg_A
          # Both Negative
          @Call32(VV) CMP32U BVal AVal
      @ELSE
          @Call32(VV) CMP32U AVal BVal
      @ENDIF
      # Convert unsigned borrow into signed negative
      @IF32_CARRY
         @PUSHI Flags32
         @OR N32Flag
         @POPI Flags32
      @ENDIF
  @ENDIF
            
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

ENDBLOCK
