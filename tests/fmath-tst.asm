I commmon.mc
L lmath.ld
L strings.ld
#
# Test to try some basic 32 bit floating point logic
#
# Float will be defined as a 32 bit structure
# Sign Bit, 8 bits, Exponent
# 23 bits, Mantissa or Fraction
#
#
#
# First function is to convert a string in format [-+][0-9]*[.[0-9+]] into a Floating point number
#
# function str2float(string,ptrfloat)
:str2float
@POPI ReturnSF
@POPI FloatPtrSF
@POPI StrPtrSF
# Skip WhiteSpace
@PUSHII StrPtrSF @AND 0xff
@WHILE_EQ_A " \0"
   @POPNULL
   @INCI StrPtrSF
   @PUSHII StrPtrSF @AND 0xff
   @IF_ZERO
      @POPNULL
      @PRT "String was blank"
      @PUSHI ReturnSF
      @RET
   @ENDIF
@ENDWHILE
@POPNULL
#
# Set NegFlag and skip past andy + or - characters.
@MA2V 0 IsNegFlagSF
@PUSHII StrPtrSF @AND 0xff #Look at first character
@IF_EQ_A "-\0"
   @POPNULL
   @MA2V 1 IsNegFlagSF
   @INCI StrPtrSF
@ELSE
   @IF_EQ_A "+\0"
      @POPNULL
      @INCI StrPtrSF
   @ELSE
      @POPNULL
@ENDIF
@PUSHII StrPtrSF @AND 0xff #Should be first digit character.
#
#
# Split the string in to a whole part and a fractional part
@MA2V 0 WholeBuffSF        # init to Null the partial strings
@MA2V 0 FractBuffSF
@MA2V WholeBuffSF WholePtrSF   # Prepare pointers to index the strings
@MA2V FractBuffSF FractPtrSF 
@MA2V 1 InWholePart            # Our loop will be in two stages, whole then fract
#
@WHILE_NOTZERO
   @SWITCH
   @CASE ".\0"
      @MA2V 0 InWhilePart
      @CBREAK
   @CASE_RANGE "0\0" "0\9"   # Is digit
      @PUSHI InWhilePart
      @IF_EQ_A 1             # in the whole part
         @POPII WholePtrSF
	 @INCI WholePtrSF
      @ELSE
         @POPII FractPtrSF   # Other wise its the fractional part
	 @INCI FractPtrSF
      @ENDIF
      @CBREAK
   @DEFAULTCASE
      @PRT "Error, invalid character in string."
      @POPNULL
      @PUSH ReturnSF
      @RET
      @CBREAK
   @ENDCASE
   @POPNULL
   @INCI StrPtrSF
   @PUSHII StrPtrSF
@ENDWHILE
#
@PUSHI WholeInt32SF
@PUSH WholeBuffSF          # Notice we're sending ref not val
@CALL i32tos
#
@PUSH WholeBuffSF
@CALL strlen
@POPI ExponentInt
#




   # Combine the whole and fractional parts into a single integer
    if len(fractional_part) > 0:
        fractional_integer = int(fractional_part)
        value_integer = whole_integer * (10 ** len(fractional_part)) + fractional_integer
    else:
        value_integer = whole_integer

    # Adjust the exponent if the value is less than 1
    while value_integer < (1 << 23):
        value_integer *= 2
        exponent -= 1

    # Create the 32-bit floating-point structure
    sign_bit = 1 if is_negative else 0
    exponent_bits = (exponent + 127) & 0xFF  # Bias by 127 and limit to 8 bits
    fraction_bits = (value_integer - (1 << 23)) & 0x7FFFFF  # Remove the implied 1

    # Combine the parts into a 32-bit integer
    float32_bits = (sign_bit << 31) | (exponent_bits << 23) | fraction_bits

    return float32_bits





@PUSH FractBuffSF
@CALL strlen








@IF_NOZERO
   @POPNULL
   @PUSH FractBuffSF
   @CALL A2I
   @PUSH 1
   @ForIA2V Index1S 0 
   
