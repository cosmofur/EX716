#  32 bit math functions
#
! LMATH_DONE
M LMATH_DONE 1
M INC2I @PUSHI %1 @ADD 2 @POPI %1
M DEC2I @PUSHI %1 @SUB 2 @POPI %1
M PRT32I @JMP %0SKIP :%0STORE 0 :%0SKIP @PUSHI %1 @POPI %0STORE @PUSH 32 $$CAST %0STORE @POPNULL
M PRT32S @PUSH 33 $$CAST %1 @POPNULL
@JMP SKIP_lmath
G SPInit32
G SPPush32
G SPPop32
G SPGet32


# set32, sets a 16 bit number to be stored as a 32 number.
# get32low: Gets the lower 16 bit from a 32 number
# get32high: Gets the higher 16 bits from a 32 number
# Add32, Adds two 32 bit numbers and returns a new 32 number
# Sub32, Subtracts two 32 bit umbers and returns a new 32 number
# Neg32, inverts the sign of a 32 bit number.
# itos32, converts a 32 bit number into a base 10 string.
# stoi32, converts a string into a base 10 string into a 32 bit number.
#
#
# SPInit32(%r)      Initilizat Software SP by setting it to new address.
# SPPush32(%r)      Push 32 bit value to Soft Stack
# SPPop32()         Pop to HW stack 32 bit from Soft Stack
# SPGet32(%r)    Copy (not pop) offset from S_SP to HW stack from Soft Stack
#
:SPInit32         # Set the S_SP to a new 'top' address, SP will 'grow up' from that address.
@SWP
@POPI S_SP
@RET
:S_SP 1
:S_T1 2 0
:S_T2 3 0
:S_T2 4 0
#
:SPPush32
@SWP            # Using swp to preserve return address
#   @PRT "Value Pushed :"
   @DUP
   @POPI S_T2
#   @PRTII S_T2
@POPI S_T1      # T1 is pointer to lower 16b word of 32b word
@PUSHII S_T1    # put on HW stack Value T1 is pointing to.
#   @PRT " Save to:L:"
#   @PRTII S_SP
@POPII S_SP     # Save that to SP
@INC2I S_T1
@INC2I S_SP
@PUSHII S_T1    # put on HW stack Value T1 is pointing to.
    @DUP
    @POPI S_T2
#    @PRT " 2nd word value:"
#    @PRTII S_T2
@POPII S_SP     # Save that to S_SP
#    @PRT " 2nd word src: "
#    @PRTII S_SP
 #   @PRTNL
@INC2I S_SP     # Leave with S_SP poiting at next 'available'
@RET
#
:SPPop32
@POPI S_T1     # T1 will preserve return address.
@DEC2I S_SP     # Order push first high 16b word, then push low 16b word. 
@PUSHII S_SP   # So the low 16b will be the first to 'pop' off the HW stack later
@DEC2I S_SP     
@PUSHII S_SP
@PUSHI S_T1
@RET
#
:SPGet32
@POPI S_T1     # T1 will preserver return address
#  @PRT "Calculating SP Address: "
#  @PRTTOP
@PUSH 1        # Rememberng that S_SP points to 'next available' space and not the 'TOP'
@ADDS          # so idx 0 mean S_SP - 4, idx 1 means S_SP - 8, idx 5 means SP_SP - 24
@RTL           # Value at TOS is offset, multiply by 4 to make it point to 32b words
@RTL
#
# S_SP should be pointer to block spot for next push.
@PUSHI S_SP
@SUBS
# Here Value at TOS should be pointer to wished for result
#
@ADD 2         # We want to HW_Push the Higher 16b part first, so start at +2
@POPI S_T2     # Copy the 2 16 bit words to HW Stack,
#
# Move Value at [S_T2] to stack (should be High order word)
@PUSHII S_T2
@DEC2I S_T2
# Move value at [S_T2] to stack (should be lower order word)
@PUSHII S_T2
@SWP
@PUSHI S_T1
@RET


#
# set32(%r,%v)
:set32 0
#



:SKIP_lmath
ENDBLOCK
