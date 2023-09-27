I common.mc
L lmath.ld
L string.ld
#
# Test to try some basic 32 bit floating point logic
#
# Float will be defined as a 32 bit structure
# Sign Bit, 8 bits, Exponent
# 23 bits, Mantissa or Fraction
#
#
#
# First function is to convert a string in format [-+][0-9]*[.[0-9+]][E+127/-128] into a Floating point number
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
# Set NegFlag and skip past any + or - characters.
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
#
#
# Split the string in to a whole part and a fractional part
@MA2V 0 WholeBuffSF        # init to Null the partial strings
@MA2V 0 FractBuffSF
@MA2V WholeBuffSF WholePtrSF   # Prepare pointers to index the strings
@MA2V FractBuffSF FractPtrSF 
@MA2V 1 InWholePart            # Our loop will be in two stages, whole then fract
#
@PUSHII StrPtrSF @AND 0xff #Should be first digit character.

#
@WHILE_NOTZERO
   @SWITCH
   @CASE ".\0"
      @MA2V 0 InWholePart
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
   @CDEFAULT
      @PRT "Error, invalid character in string."
      @POPNULL
      @PUSH ReturnSF
      @RET
      @CBREAK
   @ENDCASE
   @POPNULL
   @INCI StrPtrSF
   @PUSHII StrPtrSF @AND 0xff
@ENDWHILE
@POPNULL
# Reset pointers back to the begining of strings.
@MA2V WholeBuffSF WholePtrSF   # Prepare pointers to index the strings
@MA2V FractBuffSF FractPtrSF 
@PUSHI WholePtrSF
@PUSH Value32IntSF   # Save as 32b Integer Whole part
@CALL stoi32
@PUSHI FractPtrSF @CALL strlen

@IF_NOTZERO         # If len(fractpart) > 0, set Fract32Int to value
   @POPI FractPartLen  # Will need this for the power loop
   @PUSHI FractPtrSF
   @PUSH Fract32IntSF   # Save as 32b Integer Fractional part
   @CALL stoi32
   @MOVE32AV 1 Power32IntSF
   @MOVE32AV 10 Ten32IntSF
   @ForIA2V PowerLoop 0 FractPartLen  # Loop to generate power of 10^len(FractPart)
       @PUSH Power32IntSF
       @PUSH Ten32IntSF
       @PUSH Power32IntSF       
       @CALL MUL32
   @Next PowerLoop
   @PUSH Value32IntSF
   @PUSH Power32IntSF
   @PUSH Value32IntSF
   @CALL MUL32           # ValueInt=Whole*10^(len(fractpart))
   @PUSH Value32IntSF
   @PUSH Fract32IntSF
   @PUSH Value32IntSF
   @CALL ADD32           # ValueInt=ValueInt+FractInt
@ELSE
   @POPNULL
   @MOVE32AV 0 Fract32IntSF
@ENDIF
@MA2V 0 ExponentSF
#            321098765432109876543210  # 1<<23
@MOVE32AV 0b0100000000000000000000000 Mask23SF 
@PUSH Value32IntSF
@PUSH Mask32SF
@CALL CMP32
@IF_NEG
  @PUSH 1
@ELSE
  @PUSH 0
@ENDIF
@WHILE_NOTZERO
   @POPNULL
   @PUSH Value32InfSF
   @PUSH Value32InfSF
   @PUSH Value32InfSF
   @ADD32        # Value_integer *= 2
   @DECI ExponentSF
   # Do the While Condition
   @PUSH Value32IntSF
   @PUSH Mask32SF
   @CALL CMP32
   @IF_NEG
     @PUSH 1
   @ELSE
     @PUSH 0
   @ENDIF
@ENDWHILE
@POPNULL
# Now format the bit fields
@MOVE32A2IV 0 FloatPtrSF   #Zero out result structure

@PUSHI IsNegFlagSF
@IF_NOTZERO
  @PUSH 0x8000
  @POPII
   
   




    # Adjust the exponent if the value is less than 1
    while value_integer < (1 << 23):
        value_integer *= 2
i        exponent -= 1

    # Create the 32-bit floating-point structure
    sign_bit = 1 if is_negative else 0
    exponent_bits = (exponent + 127) & 0xFF  # Bias by 127 and limit to 8 bits
    fraction_bits = (value_integer - (1 << 23)) & 0x7FFFFF  # Remove the implied 1

    # Combine the parts into a 32-bit integer
    float32_bits = (sign_bit << 31) | (exponent_bits << 23) | fraction_bits

    return float32_bits




#format of 32 bit number in memory


Byte 0: Sign bit, exponent bits 7-4
Byte 1: Exponent bits 3-0, fraction bits 15-11
Byte 2: Fraction bits 10-6
Byte 3: Fraction bits 5-0

# Example for number 123.45
Byte 0: 0x40 (Sign bit: 0, exponent bits 7-4: 1000)
Byte 1: 0x1E (Exponent bits 3-0: 1110, fraction bits 15-11: 000)
Byte 2: 0x2C (Fraction bits 10-6: 001011)
Byte 3: 0x59 (Fraction bits 5-0: 1011001)

# Sign = 0, expoent = 10001110, Fraction 0000010111011001
