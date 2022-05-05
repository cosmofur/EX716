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
#   SET32, ZERO32, INV32, RTR32, RTL32
#
! JMP
I common.mc
ENDBLOCK
M INC2I @PUSHI %1 @ADD 2 @POPI %1
M DEC2I @PUSHI %1 @SUB 2 @POPI %1
G ADD32
G SUB32
G CMP32
G RTR32
G RTL32
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
@INC2I A_PTR
@PUSHII A_PTR     # Fetch high part of A from ptr
@POPI Aval_High
@PUSHII B_PTR     # Fetch low part of B from ptr
@POPI Bval_Low
@INC2I B_PTR
@PUSHII B_PTR     # Fetch high part of B from ptr
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
@POPI C_PTR    # These are local copies of the original PTR's passed in.
@MM2M C_PTR CH_PTR
@POPI A_PTR
@MM2M A_PTR AH_PTR
@POPI B_PTR
@MM2M B_PTR BH_PTR
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
@POPI ReturnAdr
# There is no return C value.
@POPI A_PTR
@MM2M A_PTR AH_PTR
@POPI B_PTR
@MM2M B_PTR BH_PTR
# Rather than mixxing the math with ptr increments, store the High Part as seperate PTR
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
@MC2M 1 Scr	   # It takes a both high/low zero test to get real zero, so 1 is default
@CMPS
@JNZ CMP32NotLowZero
@MC2M 0 Scr
:CMP32NotLowZero
@JGE CMP32NotLowNegative
@MC2M -1 Scr
:CMP32NotLowNegative
@JMPNC CMP32NoCarry
@PUSH 1     # There was a Carry, so remove 1 from B High block
@PUSHI Bval_High
@SUBS
@POPI Bval_High
:CMP32NoCarry
@PUSHI Aval_High
@PUSHI Bval_High
@CMPS       # High part
#
#  We have several possible states
# Low   High    Result
# <0    <0      <0      -1
# <0     0      <0      -1
# <0    >0      >0      +1
#  0    <0      <0      -1
#  0     0       0       0
#  0    >0      >0      +1
# >0    <0      <0      -1
# >0     0      >0      +1
# >0    >0      >0      +1
# 
@JMPZ CMP32HighZero
# If High is 0, then we only care about Low which we already did
@JMPN CMP32HighNeg
# Here is if High is !0 and and >0
@MC2M 1 Scr
@JMP CMP32HighZero
:CMP32HighNeg
@MC2M -1 Scr
:CMP32HighZero
@PUSHI Scr
@PUSHI ReturnAdr
@RET
#
# RRT32 Rotate Right 32 bit version 2 Parms ptr to A and Return to C
:RTR32
@POPI ReturnAdr
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
@DUP
@POPI Aval_High
# Clear Carry
@PUSH 1
@CMP 0
@POPNULL
# Since We are rotating 'right' we do the High Part First
@RTR
# Then We rotate the Low part with what ever carry there was left over
@PUSHI Aval_Low
@RTR
# Move results to C
@POPII C_PTR
@POPII CH_PTR
@PUSHI ReturnAdr
@RET

#
# RTL32 Rotate Left 32 bit version 2 Parms ptr to A and Return to C
:RTL32
@POPI ReturnAdr
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


:ENDLMATH
