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
@MOVE32AV $$$0x800000 Mask32SF  # Equal to 1<<23
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
   @CALL ADD32        # Value_integer *= 2
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
@MOVE32AV 0 FloatStoreSF   #Zero out result structure

@PUSHI IsNegFlagSF
@IF_NOTZERO
  @PUSH 0x8000
  @POPII FloatStoreSF  # First operation, we don't have to save old data
@ENDIF
@POPNULL
#
# Put the 8 bit Exponent in bits 0-6 of byte 0 split over to bit 7 of byte 1
@PUSHI ExponentSF
@ADD 127 @AND 0xff
@FCLR       # Not frequently used, but clears all flags so we can be sure Carry is zero
@RRTC
@IF_CARRY    # Carry flag will have the old '1'st bit
   @MA2V 0x80 PartInfoSF   # Save low bit on Exponent into high but of next byte
@ELSE
   @MA2V 0 PartInfoSF
@ENDIF
@AND 0x7f      # On stack should be the 0-7 of the Exponent, mask it so not to confict with NF
@PUSHII FloatStoreSF
@ORS
@POPII FloatStoreSF
@PUSHI PartInfoSF
@POPII FloatStoreSF+1     # Put the extra bit at top of 2nd byte of 32b struct
#
# Now do     fraction_bits = (value_integer - (1 << 23)) & 0x7FFFFF  # Remove the implied 1
@MOVE32AV 0 Fraction32BitsSF    # Zero it out to start
@PUSH Value32IntSF
@MOVE32AV $$$0x800000 Mask32SF      # We may already have this value here. eq 1<<23
@PUSH Mask32SF
@PUSH Fraction32BitsSF
@CALL SUB32
@MOVE32AV $$$0x7fffff Mask32SF      # Change Mask from 1<<23 to 0x7fffff
@PUSH Fraction32BitsSF
@PUSH Mask32SF
@PUSH Fraction32BitsSF
@CALL AND32                         # Fraction bits should now be lower 23 bits of 32 bit structure.
#
#
@PUSH Fraction32BitsSF
@PUSH FloatStoreSF
@PUSH FloatStoreSF
@CALL OR32                          # This should combine all the fields into one structure.
#
# Now copy the result into the Float storage passed in the call as FloatPtrSF
@COPY32VIV FloatStoreSF FloatPtrSF
@PUSHI ReturnSF
@RET
# Storage
:ReturnSF 0
:FloatPtrSF 0
:InWhilePart 0
:PowerLoop 0
:StrPtrSF 0
:IsNegFlagSF 0
:WholeBuffSF 0
:FractBuffSF 0
:WholePtrSF 0
:FractPtrSF 0
:InWholePart 0
:ExponentSF 0
:PartInfoSF 0
# Here is start of the 32 bit structures needed
:Value32IntSF $$$0
:Fract32IntSF $$$0
:Ten32IntSF $$$0
:Power32IntSF $$$0
:Mask32SF $$$0
:FloatStoreSF $$$0
:Value32InfSF $$$0
:Fraction32BitsSF $$$0

#format of 32 bit number in memory


#Byte 0: Sign bit, exponent bits 7-4
#Byte 1: Exponent bits 3-0, fraction bits 15-11
#Byte 2: Fraction bits 10-6
#Byte 3: Fraction bits 5-0

# Example for number 123.45
#Byte 0: 0x40 (Sign bit: 0, exponent bits 7-4: 1000)
#Byte 1: 0x1E (Exponent bits 3-0: 1110, fraction bits 15-11: 000)
#Byte 2: 0x2C (Fraction bits 10-6: 001011)
#Byte 3: 0x59 (Fraction bits 5-0: 1011001)

# Sign = 0, expoent = 10001110, Fraction 0000010111011001
