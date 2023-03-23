################
# lmath.ld library
# Provide procedures to do basic math on 32 bit numbers
#
# Functions come in two flavors
# 3 pointer functions on HW stack in order:
#  A-PTR, B-PTR, Result-PTR
# 2 pointer functions
#  A_PTR Result_PTR
#
# The PTR's point to 4 bytes of memory, Little-Endian
#
# 3 Pointer functions are:
#   ADD32, SUB32, CMP32, AND32, OR32
# 2 Pointer functions are:
#   RTR32, RTL32, INV32
#
# Helpful 32bit math macros (Note some of these 'macros' take up 25 to 30 bytes of memory, each
# time they are assembled. So if you need to call them in many diffrent places in your code. It
# might be more effient to use a function call)
# COPY32VV   Label32    Label32
# COPY32VIV  [Label]    Label
# MOVE32AV   $$$Number  Label
# MOVE32AVI  $$$Number  [Label32]
# INT2LONG   Label16    Label32
# INT2LONGI  Label16    [label32]
# INT2ILONG  [Label16]  label32
# LONG2INT   Label32    Label16
# 
# Copy is for copying the 4 bytes of a 32b word from one pointer to another
# Passed in parameters are the labels/pointers to the first word of the 32b numbers
M COPY32VV \
     @PUSHI %1 @POPI %2 @PUSHI %1+2 @POPI %2+2
# Most of the 32Bit match functions assume you are passing a simple pointer to the
# 32bit structure, sometimes you need to pass a double indirect pointer. The following
# Macro coverts a double indirect to a single indirect.
#
M COPY32VIV \
      @PUSHII %1 @PUSHI %1 @ADD 2 @PUSHS @POPI %2+2 @POPI %2
# 
#  MOVE32AV is the ruff 32bit equivalent of @MC2M
#M MOVE32AV @PUSH %1 @PUSH %2 @POPS @PUSH 0 @PUSH %2+2 @POPS
#M MOVE32AVI @PUSH %1 @PUSHI %2 @POPS @PUSH 0 @PUSH %2 @ADD 2 @POPS
M MOVE32AV @JMP %0SkipOver :%0C1 $$$%1 \
           :%0SkipOver @PUSHI %0C1 @PUSH %2 @POPS \
	   @PUSHI %0C1+2 @PUSH %2+2 @POPS


M MOVE32AVI @JMP %0SkipF :%0C1 $$$%1 \
           :%0SkipF @PUSHI %0C1 @PUSHI %2 @POPS \
	   @PUSHI %0C1+2 @PUSHI %2 @ADD 2 @POPS
# The INT2LONG macro takes a Label to 16b data and saves it as a 32b (zeroed high word) Label
#  %1 is ptr to 16b data, %2 is ptr to 32b data
# Started life as a macro, now its a function, with macro like calling.
M INT2LONG \
    @PUSH %1 @PUSH %2 @CALL INT2LONG
# This is for when the src value is a pointer to a 16b number
M INTI2LONG \
    @PUSHI %1 @PUSH %2 @CALL INT2LONG
# Started life as a macro, now its a function, with macro like calling.
M INT2LONGI \
    @PUSH %1 @PUSHI %2 @CALL INT2LONG
# Lastly we have the case where both the src and dst are pointers
M INTI2LONGI \
    @PUSHI %1 @PUSHI %2 @CALL INT2LONG
    

# LONG2INT is trucates the lower word in 32b data to 16b.But conider possibity of negative values
# %1 is ptr to 32b data and %2 is ptr to 16b data (Does effect flags)
# It started life as a macro, now its a function.

M LONG2INT @PUSH %1 @PUSH %2 @CALL LONG2INT

#
! MATH32DEFINE
M MATH32DEFINE 1
# Define the globals
G ADD32
G SUB32
G CMP32
G AND32
G OR32
G RTR32
G RTL32
G INV32
G DIV32
G MUL32
G i32tos
G INT2LONG
G LONG2INT

@JMP ENDLMATH
# Global Variables
:A_PTR 0
:AH_PTR 0
:B_PTR 0
:BH_PTR 0
:C_PTR 0
:CH_PTR 0
:ReturnAdr 0
:AltReturn 0
:Aval
:Aval_Low 0
:Aval_High 0
:Bval
:Bval_Low 0
:Bval_High 0
:Cval
:Cval_Low 0
:Cval_High 0
:Scr
:Scr_Low 0
:Scr_High 0
# Constants 32b 1 and 0
:One_Val 1 0
:Zero_Val 0 0
#
#
:ADD32         # Note that 32 bit math does NOT set any flags so we can't directly use it for 64 bit math.
@POPI ReturnAdr
@POPI C_PTR
@POPI B_PTR    
@POPI A_PTR
@PUSHII A_PTR     # Fetch low part of A from ptr
@POPI Aval_Low
@PUSHI A_PTR
@ADD 2
@PUSHS            # Fetch high part of A from ptr
@POPI Aval_High
@PUSHII B_PTR     # Fetch low part of B from ptr
@POPI Bval_Low
@PUSHI B_PTR
@ADD 2
@PUSHS            # Fetch high part of B from ptr
@POPI Bval_High
@PUSHI Aval_Low    # Start the Math A on stack
@PUSHI Bval_Low
@ADDS
@POPII C_PTR       # Save the Low results to Low C
@PUSHI Aval_High   # Whether or not there was carry, push High A on stack
@JMPNC ADD32NoCarry
@PUSH 1     # There was a Carry, so add one
@ADDS
:ADD32NoCarry
@PUSHI Bval_High
@ADDS       # High part results on stack.
@INC2I C_PTR      # Move C_PTR to High Part of C
@POPII C_PTR     # Save A+B High to C High
@PUSHI ReturnAdr
@RET
#
#
:SUB32
@POPI ReturnAdr
@POPI C_PTR
@POPI B_PTR
@POPI A_PTR
@PUSHII A_PTR @PUSHII B_PTR
@INC2I B_PTR @INC2I A_PTR # We do the inc2 here to avoid messing up flags
@SUBS
@POPII C_PTR
@JMPNC SNoBorrow 
# Case for Borrow
  @PUSHII A_PTR
  @PUSH 1 @PUSHII B_PTR @SUBS     # Barrow bit from High A
  @INC2I C_PTR            # C wasn't inc2 because we still needed it for the POP
  @SUBS
  @POPII C_PTR
  @JMP SPastNoBorrow
:SNoBorrow
  @PUSHII A_PTR @PUSHII B_PTR
  @INC2I C_PTR            # C wasn't inc2 because we still needed it for the POP
  @SUBS
  @POPII C_PTR
:SPastNoBorrow
@PUSHI ReturnAdr
@RET

@POPII C_PTR
@INC2I A_PTR @INC2I B_PTR @INC2I C_PTR


@POPI C_PTR    # These are local copies of the original PTR's passed in.
@MM2M C_PTR CH_PTR
@POPI B_PTR
@MM2M B_PTR BH_PTR
@POPI A_PTR
@MM2M A_PTR AH_PTR
# Rather than mixing the math with ptr increments, store the High Part as separate PTR
@INC2I CH_PTR
@INC2I AH_PTR
@INC2I BH_PTR
# Make copies of values the A and B points to local A and B storage.
@PUSHII A_PTR     # Fetch low part of A from ptr
@POPI Aval_Low
@PUSHII AH_PTR     # Fetch high part of A from ptr
@POPI Aval_High
@PUSHII B_PTR     # Fetch low part of B from ptr
@POPI Bval_Low
@PUSHII BH_PTR     # Fetch high part of B from ptr
@POPI Bval_High
# Main math function.
@PUSHI Aval_Low    # Start the Math A on stack
@PUSHI Bval_Low
@SUBS
@POPII C_PTR       # Save the Low results to Low C
@JMPNC SUB32NoCarry
@PUSH 1     # There was a Carry, so remove 1 from B High block
@PUSHI Bval_High
@SUBS
@POPI Bval_High
:SUB32NoCarry
@PUSHI Aval_High
@PUSHI Bval_High
@SUBS       # High part results on stack.
@POPII CH_PTR     # Save High part to C High
@PUSHI ReturnAdr
@RET
#
:CMP32
@POPI C32Return
@PUSH C32Result
@CALL SUB32   # We are Using SUB32 to Subtract B - A > Temp Result
#  Test if High Worked Highest Bit is set, if so, it's negative.
@PUSHI C32Result+2
@AND 0x8000
@CMP 0 @POPNULL
@JMPZ C32NotNeg
@JMP C32IsNeg
:C32NotNeg
# Failed the NEG test, so now look for Zero
@PUSHI C32Result+2    # Test the High Word first
@CMP 0 @POPNULL
@JMPZ C32MaybeZero
@JMP C32NotZeroOrNeg  # If it's not zero (and not neg) then report Positive
:C32MaybeZero        # High word was not zero, so test the lower word
@PUSHI C32Result
@CMP 0 @POPNULL
@JMPZ C32IsZero
:C32NotZeroOrNeg     #Having failed both zero and negative, must be positive
@PUSH 1 @CMP 2 @POPNULL   # For flags to be 'reset' for simpler testing.
@PUSH 1
@JMP C32End
:C32IsZero
@PUSH 0
@CMP 0               # Force the Z Flag to be set, so we avoid testing again
@JMP C32End
:C32IsNeg
@PUSH 1 @CMP 0 @POPNULL   # Force the N flag to be set.
@PUSH -1
:C32End
@PUSHI C32Return
@RET
:C32Return 0
:C32Result 0 0
#
# RRT32 Rotate Right 32 bit version 2 Parms ptr to A and Return to C
:RTR32
@POPI ReturnAdr
# Setup Individual pointers to the Low and High parts of the Src(A) and Dst(C) numbers
@DUP 	
@POPI C_PTR @ADD 2 @POPI CH_PTR
@DUP
@POPI A_PTR @ADD 2 @POPI AH_PTR
# Fetch low part of A from ptr
@PUSHII A_PTR  @POPI Aval_Low
# Fetch high part of A from ptr
@PUSHII AH_PTR @POPI Aval_High
# Clear Carry
@PUSH 1 @CMP 0 @POPNULL
# Since We are rotating 'right' we do the High Part First
@PUSHI Aval_High
@RRTC
# Then We rotate the Low part with what ever carry there was left over
@PUSHI Aval_Low
@RRTC
# Move results to C
@POPII C_PTR
@POPII CH_PTR
@PUSHI ReturnAdr
@RET
#
# Invert Bits
#
:INV32
@POPI IVReturnAdr
@POPI IV32Aval
@PUSHI IV32Aval
@PUSHS @INV @PUSHI IV32Aval @POPS  # Note modification is to where Aval points to, not Aval itself.
@PUSHI IV32Aval @ADD 2
@PUSHS @INV @PUSHI IV32Aval @ADD 2 @POPS
@PUSHI IVReturnAdr
@RET
:IVReturnAdr 0
:IV32Aval 0
#
# RTL32 Rotate Left 32 bit version 2 Parms ptr to A and Return to C
:RTL32
@POPI RL32ReturnAdr
@POPI RL32CVAL
@POPI RL32AVAL
@PUSHI RL32AVAL
@PUSHS         # Lower A-Val to Stack
@PUSHI RL32AVAL
@ADD 2
@PUSHS         # upper A-Val to stack
@RTL
@POPI RL32UpperHold     #save upper part for later.
@RTL                    # Now rotate the Lower Part
@JMPNC RL32NoCarry
   @PUSHI RL32UpperHold
   @OR 0x1              # If Lower part HAD a carry, set bit one of already RTL upper part
   @POPI RL32UpperHold
:RL32NoCarry
# Put result into CVAL
@PUSHI RL32CVAL
@POPS                   #Copy lower part of answer to CVAL
@PUSHI RL32UpperHold
@PUSHI RL32CVAL
@ADD 2
@POPS                   #Save Upper Part to CVAL
@PUSHI RL32ReturnAdr
@RET
:RL32ReturnAdr  0
:RL32CVAL 0
:RL32AVAL 0
:RL32OutCarry 0
:RL32UpperHold 0
@DUP
@POPI C_PTR
@POPI CH_PTR
@INC2I CH_PTR
@DUP
@POPI A_PTR
@POPI AH_PTR
@INC2I AH_PTR
@PUSHII A_PTR     # Fetch low part of A from ptr
@POPI Aval_Low
@PUSHII AH_PTR     # Fetch high part of A from ptr
@POPI Aval_High
@PUSHI Aval_Low
# Clear Carry
@PUSH 1
@CMP 0
@POPNULL
# Since We are rotating 'left' we do Low Part first
@RTL
# Then We rotate the High part with what ever carry there was left over
@PUSHI Aval_High
@RTL
# Move results to C
@POPII CH_PTR
@POPII C_PTR
@PUSHI ReturnAdr
@RET
# We need some basic string functions that work with 32b numbers
# So we need to create i32tos
# Locals
:isReturn1 0
:isBase 0 0
:isA32Ptr 0         # Pointer in mem where the original A32 was stored.
:isResultPtr 0
:isStrPtr 0         # Used as pointer/index of isWorkBuff
:isWorkBuff "000000000000"
:isNegFlag 0
:isRevIndex 0
:isZero 0 0
:isOne 0 0
# Following are 32bit buffers that act as variables, but we have to deal with both high and low words
:isA32 0 0
:IsLocalR1 0 0
# Start of procedure
:i32tos
@POPI isReturn1
@POPI isStrPtr
@POPI isBase              # Pointer to Base(8,10,16)
@POPI isA32Ptr          # Address of input A32
# Put a '0' glph in first slot of WorkBuff
@MC2M 0x3000 isWorkBuff   # WorkBuff is empty string (11 bytes) for max 32b size
@MC2M 0 isWorkBuff+2      # +/- -2,147,483,648 to 2,147,483,647
@MC2M 0 isWorkBuff+4
@MC2M 0 isWorkBuff+6
@MC2M 0 isWorkBuff+8
@MC2M 0 isWorkBuff+10
@MOVE32AV $$$0 isZero     # Constants we need for inverting 2scompt
@MOVE32AV $$$1 isOne#
# Save working copy of number
#
@COPY32VIV isA32Ptr isA32
#@MC2M isWorkBuff isStrPtr    # Set string ptr to WorkBuff[0]
#
# Test for Negative
@MC2M 0 isNegFlag

@PUSH isZero @PUSH isA32 @CALL CMP32 @POPNULL
@JMPNZ isNotNeg
  @MC2M 1 isNegFlag
  # Need invert with addtion for 2s comp
  @PUSH isA32 @CALL INV32   # Invert Bits
  @PUSH isOne @PUSH isA32 @PUSH isA32 @CALL ADD32  # Add 1 for 2comp
:isNotNeg
@MC2M isWorkBuff isRevIndex   #First Left to right, then reverse later.
                              #Helpfull because this way highbyte in words
			      #naturually add null to end of string
:isMainLoop
   # Cmp work value to 0
   @PUSH isA32
   @PUSH isZero        #  CMP's are B-A or tos - sftos for flags
   @CALL CMP32            # This will return 0, -1 or 1 as result
   @POPNULL
   @JMPZ EndMainLoop
   @PUSH isA32
   @PUSH isBase
   @PUSH IsLocalR1           # Remander
   @PUSH isA32           # Result
   @CALL DIV32
   @PUSHI IsLocalR1         # We only allow remainders that are <=16 so lower word of R1 should work.
   @AND 0x0f                # Just to make sure, we mask out any artifacts with lower nibble
   @ADD 0x30                # Turn Remainder to ASCII
   @CMP 0x40
   @JGT isNotHex            # only hex number require jump to A-F
       @ADD 0x07
   :isNotHex
   @POPII isRevIndex        # save the ASCII code
   @INCI isRevIndex
   @JMP isMainLoop
:EndMainLoop
# At this point isWorkBuff will have in reverse order the ASCII number, max 11 digits.
#
@PUSH 0 @CMPI isNegFlag @POPNULL
@JMPZ isGoReverseDigits
   # Else NEG flag set, so insert '-'
   @PUSH 0x2d    # Ascii for '-'
   @POPII isStrPtr       # isStrPtr was passed in as needs to be pointer to suffient sized buffer.
   @INCI isStrPtr

:isGoReverseDigits
@DECI isRevIndex         # Last insert put RevIndex one past end of string.
:isGoReverseLoop
  # while isRevIndex > isWorkBuff
  @PUSHI isRevIndex
  @CMP isWorkBuff @POPNULL
  @JGT isExitReverseLoop
  @PUSHII isRevIndex
  @POPII isStrPtr
  @PUSH 0
  @POPII isRevIndex      # After copying to stack we zero out, so next loop lowers byte will be blanked
  @INCI isStrPtr
  @DECI isRevIndex
  @JMP isGoReverseLoop
:isExitReverseLoop
  @PUSHI isReturn1
  @RET

# AND function AND bits in A and B and returns result to C. A&B not modified.
:AND32
@POPI ReturnAdr
@POPI ADC_PTR       # Return Result
@INC2I ADC_PTR       # Set C to the High part of itself
@POPI ADB_PTR    
@POPI ADA_PTR
@PUSHII ADA_PTR     #Put on Stack low works of A and B
@PUSHII ADB_PTR
@PUSHI ADA_PTR @ADD 2 @PUSHS  # Put On Stack High A
@PUSHI ADB_PTR @ADD 2 @PUSHS  # Put On Stack High B
@ANDS @POPII ADC_PTR          # Save High Parts ANDed to High C
@DEC2I ADC_PTR
@ANDS @POPII ADC_PTR          # Save Low Parts ANDed to Low C
@PUSHI ReturnAdr
@RET
:ADA_PTR 0 0
:ADB_PTR 0 0
:ADC_PTR 0 0

# OR function ORs bits in A and B and returns result to C. A&B not modified.
:OR32
@POPI ReturnAdr
@POPI ORC_PTR       # Return Result
@INC2I ORC_PTR       # Set C to the High part of itself
@POPI ORB_PTR    
@POPI ORA_PTR
@PUSHII ORA_PTR     #Put on Stack low works of A and B
@PUSHII ORB_PTR
@PUSHI ORA_PTR @ADD 2 @PUSHS  # Put On Stack High A
@PUSHI ORB_PTR @ADD 2 @PUSHS  # Put On Stack High B
@ORS @POPII ORC_PTR          # Save High Parts ORed to High C
@DEC2I ORC_PTR
@ORS @POPII ORC_PTR          # Save Low Parts ORed to Low C
@PUSHI ReturnAdr
@RET
:ORA_PTR 0 0
:ORB_PTR 0 0
:ORC_PTR 0 0

# End of i32tos 

:DIV32
# Call with 4 parameters DIV(Numerator, Denominator, Remainder, Quotent)
# All are direct pointers to 32 bit numbers. If you need indirect, build a support function.
#
@POPI DReturn
@POPI DQValReturnPtr
@POPI DRemReturnPtr
@POPI DDenomPtr
@POPI DNumerPtr
@PUSHII DDenomPtr @POPI DLocalDenom
@PUSHI DDenomPtr @ADD 2 @PUSHS @POPI DLocalDenom+2
@PUSHII DNumerPtr @POPI DLocalNumer
@PUSHI DNumerPtr @ADD 2 @PUSHS @POPI DLocalNumer+2
@MOVE32AV $$$0 DZero32      # Zero Out the Zero variable
@PUSH DZero32 @PUSH DLocalDenom @CALL CMP32              # Test if Denominator is zero
@POPNULL
@JMPZ DDivideByZero
@MC2M 0 DNEGFLAG         # Now test for Negative Number
@MOVE32AV 1 DOne32       # We need a 32b One for possible 32b 2Compliment calc
@PUSH DZero32 @PUSH DLocalDenom @CALL CMP32 @POPNULL  # Compare Denom to zero
@JGE DDenomNotNeg          # Denom - 0 >= 0
   # Denum is Neg. Flip flag
   @PUSHI DNEGFLAG @INV @AND 1 @POPI DNEGFLAG
   @PUSH DLocalDenom @CALL INV32   # Invert High and Low words
   @PUSH DOne32 @PUSH DLocalDenom @PUSH DLocalDenom @CALL ADD32  # Then Add one for 2Comp   
:DDenomNotNeg
@PUSH DZero32 @PUSH DLocalNumer @CALL CMP32 @POPNULL  # Compare Numerator to zero
@JGE DNumerNotNeg              # Numer - 0 >= 0
   # Numer is Neg, Flip Flag
   @PUSHI DNEGFLAG @INV @AND 1 @POPI DNEGFLAG
   @PUSHI DLocalNumer @INV @POPI DLocalNumer
   @PUSHI DLocalNumer+2 @INV @POPI DLocalNumer+2    # Invert both high an low words
   @PUSH DOne32 @PUSH DLocalNumer @PUSH DLocalNumer @CALL ADD32  # Then Add one for 2Comp      
:DNumerNotNeg
@MOVE32AV 0 DQval
@MOVE32AV 0 DRemainder
@PUSH 0x0000 @POPI DReverseBit
@PUSH 0x8000 @POPI DReverseBit+2       # Start the Reverse bit at 32'nd bit
@MC2M 32 DIndex
:DMainLoop
@PUSHI DIndex @CMP 0 @POPNULL
# Explanation of loop
# We are doing a For loop though the 32 bits.
# Going from the highest bit to the lowest bit of the Numerator
# Regardless of that bit is set, we rotate the current Remainder left (*2)
# When the Numerator bit is set, we add a bit to the Remainder
# Then we take the remainder and compare to Denominator
# If that Remainder is >= Denominator we set that bit(index) to one in QVal
# 
@JMPZ DExitMainLoop
      # Left shift the Remainder by 1
      @PUSH DRemainder @PUSH DRemainder @CALL RTL32 # Remainder << 1
      @PUSH DLocalNumer @PUSH DReverseBit @PUSH DResultHold
      @CALL AND32   # Result= Numerator & Reversebit
      @PUSH DResultHold @PUSH DZero32 @CALL CMP32    # CMP Result and 32b zero, results in TOS
      @POPNULL
      @JMPZ DBitNotSet
         # Bit IS set.
	 @PUSH DOne32 @PUSH DRemainder @PUSH DRemainder @CALL OR32   # OR 1 to DRemainder
      :DBitNotSet
      @PUSH DLocalDenom @PUSH DRemainder @CALL CMP32
      @POPNULL
      @JMPN DSkipQSet
          @PUSH DLocalDenom @PUSH DRemainder @PUSH DRemainder @CALL SUB32  # Remain = Remain - Demonin
	  # Now modify just the Ith bit of Qval to be 1
	  # Fill DResultHold with all 'F'
	  @PUSH 0xFFFF @POPI DResultHold
	  @PUSH 0xFFFF @POPI DResultHold+2
	  @PUSH DReverseBit @PUSH DResultHold @PUSH DResultHold @CALL AND32  # Result = Reverse & FFF...
	  @PUSH DQval @PUSH DResultHold @PUSH DQval @CALL ADD32  # Qval = Qval + Result
      :DSkipQSet
      # Shift Right ReverseBit
      @PUSH DReverseBit @PUSH DReverseBit @CALL RTR32   # ReverseBit >> 1
      @DECI DIndex
      @JMP DMainLoop
:DExitMainLoop
@PUSHI DNEGFLAG  @CMP 0 @POPNULL   # Was it Negative?
@JMPZ DNotNeg2
   # IS Negative.
:DInvertAnswer
   @PUSHI DQval @INV @POPI DQval
   @PUSHI DQval+2 @INV @POPI DQval+2
   @PUSH DOne32 @PUSH DQval @PUSH DQval @CALL ADD32   # 2's comp, invert and add one.
:DNotNeg2
# Put the Address of the two result points on stack.
# As a matter of technique it important to understand that what was passed and is stored in the local Return vars
# are the pointers TO where the result is going to be saved.
#
@PUSHI DQval @POPII DQValReturnPtr                   # Copy Qval lower to RemQvalReturnPtr   
@PUSHI DQval+2 @PUSHI DQValReturnPtr @ADD 2 @POPS     # Copy Qval upper to RemQvalReturnPtr+2

@PUSHI DRemainder @POPII DRemReturnPtr                # Copy Remainder lower word to RemReturnPtr
@PUSHI DRemainder+2 @PUSHI DRemReturnPtr @ADD 2 @POPS # Copy Remainder upper word to RemReturnPtr+2
@PUSHI DReturn
@RET
#
# INT2LONG function(A,B)
#   A=Ptr to 16b data, B=Ptr to 32b destination
:INT2LONG
  @POPI I2LReturn
  @POPI I2LB
  @POPI I2LA
  @PUSHI I2LA @AND 0x8000 @POPNULL # Test if 16b was Negative
  @JMPZ I2LNotNeg
     @PUSHI I2LA
     @POPII I2LB
     @INC2I I2LB
     @PUSH 0xffff @POPII I2LB
     @JMP I2LEnd
  :I2LNotNeg
     @PUSHI I2LA
     @POPII I2LB
     @INC2I I2LB
     @PUSH 0 @POPII I2LB
  :I2LEnd
     @PUSHI I2LReturn
     @RET
:I2LA 0
:I2LB 0
:I2LReturn 0

# MUL32(multiplierA, multiplierB, Result) pointers to 32b data
:MUL32
@POPI MReturn
@POPI MResultPtr
@POPI MMPtr
@POPI NNPtr
@PUSHII MMPtr @POPI MMLocal
@PUSHI MMPtr @ADD 2 @PUSHS @POPI MMLocal+2
@PUSHII NNPtr @POPI NNLocal
@PUSHI NNPtr @ADD 2 @PUSHS @POPI NNLocal+2
@MOVE32AV $$$0 M_ANS
@MC2M 0 M_NEGFLAG
@MOVE32AVI $$$0 M_ZERO
@MOVE32AVI $$$1 M_ONE
@PUSH M_ZERO @PUSH MMLocal @CALL CMP32 @POPNULL
@JGE M1NotNeg
@PUSHI M_NEGFLAG @INV @POPI M_NEGFLAG  # Flip NEGFlag
# Invert and add 1 to convert negative to possitive value for calculation
@PUSHI MMLocal @INV @POPI MMLocal
@PUSHI MMLocal+2 @INV @POPI MMLocal+2
@PUSH MMLocal @PUSH M_ONE @PUSH MMLocal @CALL ADD32
:M1NotNeg
@PUSH M_ZERO @PUSH NNLocal @CALL CMP32 @POPNULL
@JGE M2NotNeg
@PUSHI M_NEGFLAG @INV @POPI M_NEGFLAG  # Flip NEGFlag
# Invert and add 1 to convert negative to possitive value for calculation
@PUSHI NNLocal @INV @POPI NNLocal
@PUSHI NNLocal+2 @INV @POPI NNLocal+2
@PUSH NNLocal @PUSH M_ONE @PUSH NNLocal @CALL ADD32
:M2NotNeg
:M_WHILE1
   @PUSH M_ZERO @PUSH MMLocal @CALL CMP32 @POPNULL
   @JMPZ M_ENDWHILE
   # if M & 0x1; then ANS=ANS+NN
   @PUSH MMLocal @PUSH M_ONE @PUSH M_TEMP @CALL AND32
   @PUSH M_TEMP @PUSH M_ONE @CALL CMP32 @POPNULL
   @JMPNZ M_ENDIF1
      # ANS = ANS + N
      @PUSH M_ANS @PUSH NNLocal @PUSH M_ANS @CALL ADD32
:M_ENDIF1
   # N = N << 1
   @PUSH NNLocal @PUSH NNLocal @CALL RTL32
   # MM / 2 | MM >> 1
   @PUSH MMLocal @PUSH MMLocal @CALL RTR32
@JMP M_WHILE1
:M_ENDWHILE
@PUSH 0 @CMPI M_NEGFLAG @POPNULL
@JMPZ M_NOTNEG
# Or Is Negative
@PUSHI M_ANS @INV @POPI M_ANS
@PUSHI M_ANS+2 @INV @POPI M_ANS+2
@PUSH M_ONE @PUSH M_ANS @PUSH M_ANS @CALL ADD32
:M_NOTNEG
# Put M_ANS into return location
@PUSHI M_ANS @POPII MResultPtr
@PUSHI M_ANS+2 @PUSHI MResultPtr @ADD 2 @POPS
@PUSHI MReturn
@RET
:MReturn 0
:MResultPtr 0
:M_NEGFLAG 0
:MMPtr 0
:NNPtr 0
:MMLocal 0 0
:NNLocal 0 0
:M_TEMP 0 0
:M_ANS 0 0
:M_ZERO $$$0
:M_ONE $$$1

   


# LONG2INT funciton(A,B) a 32b(A) into a 16b(B) with some for negative values
:LONG2INT
   @POPI L2IReturn
   @POPI L2IB
   @POPI L2IA
   @PUSHII L2IA
   @POPII L2IB     # Copy the lower word from A to B
   @INC2I L2IA     # Point to high word of A
   @PUSHII L2IA
   @AND 0x8000 @POPNULL
   @JMPZ L2INotNeg
      # If negative 2's comp the value.
      @PUSHII L2IA
      @PUSHI L2IA @ADD 2
      @PUSHS
      @POPI L2IM1+2  # Fetch 'local' copy of the 32b A value
      @POPI L2IM1
      @PUSH L2IM1    # Invert value of A
      @CALL INV32
      @PUSH L2IM1
      @PUSH L2IOne
      @PUSH L2IM1
      @CALL ADD32    # Add one to invert (long version of COMP2)
      @PUSHI L2IM1   # Get lower word of 2cmp'ed A
      @COMP2         # Convert just this 16v to negative
      @POPI  L2IB
   :L2INotNeg
   @PUSHI L2IReturn
   @RET
:L2IReturn 0
:L2IA 0
:L2IB 0
:L2IOne $$$01
:L2IM1 0 0





:DDivideByZero
@PRT "ERROR DIV by Zero"
@PUSHI DReturn          # Attempt to return, but really should exit
@RET
:DReturn 0
:DIndex 0
:DDenomPtr 0
:DNumerPtr 0
:DLocalDenom 0 0
:DLocalNumer 0 0
:DZero32 0 0
:DOne32 $$$01
:DNEGFLAG 0
:DQval 0 0
:DRemainder 0 0
:DReverseBit 0 0
:DResultHold 0 0
:DRemReturnPtr 0
:DQValReturnPtr 0
:ENDLMATH
ENDBLOCK
