################
# lmath.asm libary
# Provide procedures to do basic math on 32 bit numbers
#
# Functions come in two flavors
# 3 pointer functions on HW stack in order:
#  A-PTR, B-PTR, Result-PTR
# 2 pointer functons
#  A_PTR Result_PTR
#
# The PTR's point to 4 bytes of memory, Little-Endian
#
# 3 Pointer functions are:
#   ADD32, SUB32, CMP32, AND32, OR32
# 2 Pointer functions are:
#   RTR32, RTL32, INV32
#
# Helpfull 32bit math macros
# COPY32VV   Label   Label
# MOVE32AV   Number  Label
# 
# Copy is for copying the 4 bytes of a 32b word from one pointer to another
# Passed in parameters are the lables/pointers to the first word of the 32b numbers
M COPY32VV @PUSHI %1 @POPI %2 @PUSHI %1+2 @POPI %2+2
M COPY32VIV @PUSHII %1 @POPI %2 @PUSHI %1 @ADD 2 @PUSHS @POPI %2+2
# Save a 16b value as a 32bit value stored at pointer (16b# ptr)
# This is the easiet way to quick load a 32b number, but is limited to enterable 16b numbers
# If you want a 32b constant in your program, use the '$$$' notation but that will save
# the 32b number at a spot in memory, so you need to define a label and treat the label as ptr to value
M MOVE32AV @PUSH %1 @PUSH %2 @POPS @PUSH 0 @PUSH %2+2 @POPS
M MOVE32AVI @PUSH %1 @PUSHI %2 @POPS @PUSH 0 @PUSH %2 @ADD 2 @POPS
#
I common.mc
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
@INC2I C_PTR      # Move C_PTR to High Part oc C
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
  @INC2I C_PTR            # C was'nt inc2 because we still needed it for the POP
  @SUBS
  @POPII C_PTR
  @JMP SPastNoBorrow
:SNoBorrow
  @PUSHII A_PTR @PUSHII B_PTR
  @INC2I C_PTR            # C was'nt inc2 because we still needed it for the POP
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
# Rather than mixxing the math with ptr increments, store the High Part as seperate PTR
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
@CALL SUB32   # We are Using SUB32 to Subtrace B - A > Temp Result
#  Test if High Workd Hights Bit is set, if so, it's negative.
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
@JMP C32NotZeroOrNeg  # If it's not zero (and not neg) then report Possitive
:C32MaybeZero        # High word was not zero, so test the lower word
@PUSHI C32Result
@CMP 0 @POPNULL
@JMPZ C32IsZero
:C32NotZeroOrNeg     #Having failed both zero and negative, must be possitive
@PUSH 1
@JMP C32End
:C32IsZero
@PUSH 0
@JMP C32End
:C32IsNeg
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
@PUSHS @INV @PUSHI IV32Aval @POPS
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
:isBase 0
:isInvalPtr 0
:isStrPtr 0
:isWorkBuff "000000000000"
:isNegFlag 0
:isRevIndex 0
# Following are 32bit buffers that act as variables, but we have to deail with both high and low words
:isWorkValPtr 0 0
:IsLocalR1 0 0
:IsLocalR2 0 0
# Start of procedure
:i32tos
@POPI isReturn1
@POPI isBase
@POPI isInvalPtr
@MC2M 0x3000 isWorkBuff   # We need 11 characters to have sufficent space for 32bit decimal numbers
@MC2M 0 isWorkBuff+2      # +/- -2,147,483,648 to 2,147,483,647
@MC2M 0 isWorkBuff+4
@MC2M 0 isWorkBuff+6
@MC2M 0 isWorkBuff+8
@MC2M 0 isWorkBuff+10
#
# Save working copy of number
#
@PUSHII isInvalPtr
@PUSHI isInvalPtr
@ADD 2
@PUSHS
@POPI isWorkValPtr+2
@POPI isWorkValPtr
#
# Test for Negative
@MC2M 0 isNegFlag
@PUSH 0 @CMPI isWorkValPtr+2 @POPNULL
@JGE isNotNeg      # JGE means was Not 'N' and Not 'Z'
  @MC2M 1 isNegFlag
  # Need to call Subtraction.
  @MC2M 0 IsLocalR1+2        # Set Local register to '1'
  @MC2M 1 IsLocalR1
  @PUSH IsLocalR1
  @PUSH isWorkValPtr
  @PUSH IsLocalR2
  @CALL SUB32                # Result will be saved to R2, move to working space
  @MM2M IsLocalR2+2 isWorkValPtr+2
  @MM2M IsLocalR2 isWorkValPtr
:isNotNeg
@MC2M isWorkBuff isRevIndex   #First Left to right, then reverse later.
:isMainLoop
   # Cmp work value to 0
   @MC2M 0 IsLocalR1
   @MC2M 2 IsLocalR1+2    # Zero out R1
   @PUSH isWorkValPtr
   @PUSH IsLocalR1        #  CMP's are B-A or tos - sftos for flags
   @CALL CMP32            # This will return 0, -1 or 1 as result
   @CMP 0 @POPNULL
   @JMPZ EndMainLoop
   @MC2M 0 IsLocalR2+2
   @MM2M isBase IsLocalR2   # Copy base to 32 int.
   @PUSH IsLocalR2          #pust A B and C ptrs to stack
   @PUSH isWorkValPtr
   @PUSH IsLocalR1   
   @CALL DIV32
   @POPI IsLocalR1          # result
   @POPI IsLocalR2          # Remainder
   @MM2M IsLocalR1+2 isWorkBuff+2  # Copy result to IsWork
   @MM2M IsLocalR1 isWorkBuff
   @PUSHII IsLocalR2        # We only care about remainder which will always be 16 or less.
   @AND 0x0f
   @ADD 0x30                # Turn Remainder to ASCII
   @CMP 0x40
   @JGT isNotHex            # only hex number requrie jump to A-F
       @ADD 0x07
   :isNotHex
   @POPII isRevIndex        # save the Ascii code
   @INCI isRevIndex
   @JMP isMainLoop
:EndMainLoop
# At this point isWorkBuff will have in reverse order the ASCII number, max 11 digits.
#
@PUSH 0 @CMPI isNegFlag @POPNULL
@JMPZ isGoReverseDigits
   # Else NEG flag set, so inser '-'
   @PUSH 0x2d
   @POPII isStrPtr
   @INCI isStrPtr
:isGoReverseDigits
  # while isRevIndex > isWorkBuff
  @PUSHI isRevIndex
  @CMP isWorkBuff @POPNULL
  @JGT isExitReverseLoop
  @PUSHII isStrPtr
  @PUSH 0
  @POPII isRevIndex      # After copying to stack we zero out, so next loop lowers byte will be blanked
  @INCI isStrPtr
  @DECI isRevIndex
  @JMP isGoReverseDigits
:isExitReverseLoop
  @PUSHI isReturn1
  @RET

# AND function AND bits in A and B and returns result to C. A&B not modified.
:AND32
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
@ANDI Bval_Low     # AND Low parts together.
@POPII C_PTR       # Save the Low results to Low C
@PUSHI Aval_High   
@ANDI Bval_High    # AND High Parts
@INC2I C_PTR      # Move C_PTR to High Part oc C
@POPII C_PTR      # Save A and B High to C High
@PUSHI ReturnAdr
@RET

# OR function ORs bits in A and B and returns result to C. A&B not modified.
:OR32
@POPI ReturnAdr
@POPI C_PTR
@POPI B_PTR    
@POPI A_PTR
@PUSHII A_PTR     # Fetch low part of A from ptr
@POPI Aval_Low @PUSHI A_PTR @ADD 2
@PUSHS            # Fetch high part of A from ptr
@POPI Aval_High
@PUSHII B_PTR     # Fetch low part of B from ptr
@POPI Bval_Low @PUSHI B_PTR @ADD 2
@PUSHS            # Fetch high part of B from ptr
@POPI Bval_High
@PUSHI Aval_Low    # Start the Math A on stack
@ORI Bval_Low      # OR Low parts together.
@POPII C_PTR       # Save the Low results to Low C
@PUSHI Aval_High   
@ORI Bval_High    # OR High Parts
@INC2I C_PTR      # Move C_PTR to High Part oc C
@POPII C_PTR      # Save A and B High to C High
@PUSHI ReturnAdr
@RET

# End of i32tos 

:DIV32
# The return of DIV is two pointers to internal 32b numbers, tos will be result, tos-1 will be remainder
# It imporatant to clear these out of the stack and COPY them to local memory, or results will be
# overwritten in later calls to DIV32
#
@POPI DReturn
@POPI DDenomPtr
@POPI DNumerPtr
# Copy local versions of Denominator and Numerator
@PUSHII DDenomPtr @POPI DDenomLow
@PUSHI DDenomPtr @ADD 2 @PUSHS @POPI DDenomHigh
@PUSHII DNumerPtr @POPI DNumerLow
@PUSHI DNumerPtr @ADD 2 @PUSHS @POPI DNumerHigh
@MOVE32AV 0 DZero32      # Zero Out the Zero variable
@PUSH DZero32 @PUSH DDenomLow @CALL CMP32              # Test if Denominator is zero
@CMP 0 @POPNULL
@JMPZ DDivideByZero
@PUSH DNumerLow
@MC2M 0 DNEGFLAG         # Now test for Negative Number
@PUSH DZero32
@CALL CMP32              # Flags based on Zero - DNumer (so >0 or 1 if DNum is negative)
@CMP 1 @POPNULL
@JMPZ DIsNeg             # We have to prepare for negative math
@PUSH DDenomLow
@PUSH DZero32
@CALL CMP32
@CMP 1 @POPNULL
@JMPZ DIsNeg
@JMP DNotNeg
@JMP DNotNeg             # So skip over the negative math prep
:DIsNeg
   @PUSHI DNEGFLAG @INV @POPI DNEGFLAG  #Invert Neg Flag
   @MOVE32AV 1 DOne32                   # We need to inver then add one to Numerator
   @PUSHI DNumerLow @INV @POPI DNumerLow
   @PUSHI DNumerHigh @INV @POPI DNumerHigh
   @PUSH DOne32    @PUSH DNumerLow    @PUSH DNumerLow  # Add one to DNumerator
   @CALL ADD32           # Inverting the 2s complement of Numerator
:DNotNeg
@MOVE32AV 0 DQval
@MOVE32AV 0 DRemainder
@PUSH 0x0000 @POPI DReverseBit
@PUSH 0x8000 @POPI DReverseBit+2       # Start the Reverse bit at 32'nd bit
@MC2M 32 DIndex
:DMainLoop
@PUSHI DIndex @CMP 0 @POPNULL
# Explantion of loop
# We are doing a For loop though the 32 bits.
# Going from the highest bit to the lowest bit of the Numerator
# Regardless of that bit is set, we rotate the current Remainder left (*2)
# When the Numerator bit is set, we add a bit to the Remainder
# Then we take the remainder and compair to Denominator
# If that Remainder is >= Denominator we set that bit(index) to one in QVal
# 
@JMPZ DExitMainLoop
      # Left shift the Remainder by 1
      @PUSH DRemainder @PUSH DRemainder @CALL RTL32 # Remainder << 1
      @PUSH DNumerLow @PUSH DReverseBit @PUSH DResultHold @CALL AND32   # Result= Numerator & Reversebit
      @PUSH DResultHold @PUSH DZero32 @CALL CMP32    # CMP Result and 32b zero, results in TOS
      @CMP 0 @POPNULL                                # If TOS ==0 then bit is not set.
      @JMPZ DBitNotSet
         # Bit IS set.
#	 @PRTLN "Before OR"
	 @PUSH DOne32 @PUSH DRemainder @PUSH DRemainder @CALL OR32   # OR 1 to DRemainder
#	 @PRT "DRemainder being updated: " @PRT32I DRemainder @PRTNL
      :DBitNotSet
      @PUSH DDenomLow @PUSH DRemainder @CALL CMP32
#      @PRT " CMPing DDenom(" @PRT32I DDenomLow @PRT ") to DRemainder(" @PRT32I DRemainder
      @CMP 0
#      @PRT ") results in:" @PRTTOP @PRTNL
      @POPNULL  # TOS will be -1 if result was negative.      
      @JGT DSkipQSet                     # if negative, we skip setting Q value
#          @PRT "For " @PRTI DIndex @PRT " Bit is set Q:" @PRT32I DQval @PRTNL
          @PUSH DDenomLow @PUSH DRemainder @PUSH DRemainder @CALL SUB32  # Remain = Remain - Demonin
	  # Now modify just the Ith bit of Qval to be 1
	  # Fill DResultHold with all 'F'
	  @PUSH 0xFFFF @POPI DResultHold
	  @PUSH 0xFFFF @POPI DResultHold+2
	  @PUSH DReverseBit @PUSH DResultHold @PUSH DResultHold @CALL AND32  # Result = Reverse & FFF...
	  @PUSH DQval @PUSH DResultHold @PUSH DQval @CALL ADD32  # Qval = Qval + Result
      :DSkipQSet
      # Shift Right ReverseBit
      @PUSH DReverseBit @PUSH DReverseBit @CALL RTR32   # ReversBit >> 1
      @DECI DIndex
      @JMP DMainLoop
:DExitMainLoop
@PUSHI DNEGFLAG  @CMP 0 @POPNULL   # Was it Negative?
@JMPZ DNotNeg2
   # IS Negative.
   @PUSH DQval @PUSH DQval @CALL INV32      # Invert answer
   @PUSH DQval @PUSH DOne32 @PUSH DQval @CALL ADD32   # 2's comp, invert and add one.
:DNotNeg2
# Put the Address of the two result points on stack.
@PUSH DRemainder
@PUSH DQval
@PUSHI DReturn
@RET
:DDivideByZero
@PRT "ERROR DIV by Zero"
@PUSHI DReturn          # Attempt to return, but really should exit
@RET
:DReturn 0
:DIndex 0
:DDenomPtr 0
:DDenomLow 0
:DDenomHigh 0
:DNumerPtr 0
:DNumerLow 0
:DNumerHigh 0
:DZero32 0 0
:DOne32 $$$01
:DNEGFLAG 0
:DQval 0 0
:DRemainder 0 0
:DReverseBit 0 0
:DResultHold 0 0
:ENDLMATH
ENDBLOCK

