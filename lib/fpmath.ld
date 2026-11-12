! __LIB_FPMATH_LOADED
M __LIB_FPMATH_LOADED 1
#L lmath.ld
########################
# Published functions
G FP32_UNPACK
G FP32_PACK

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
