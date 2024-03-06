# Random Number Library
# The main purpose of this is to create an effective random number generator
# Our CPU does not have a real time clock or any hardware to aid in Random Numbers
# Or limit word size means the Random number will be only good for 0 - 2047
#
# So we will need to provide a seed function
# We are also going to use the psudo random function of Linear Congruential Generator
#    seed * 25173 + 13849 && FFFF
#    update seed with each call.
#
L mul.ld
L div.ld
L softstack.ld
! RANDOM_SEEN
M RANDOM_SEEN 1
#
# We will make public the function rnd16 and rndsetseed(N)
G rnd16 G rndsetseed G rndint G rndgetseed G frnd16 G frndint

# Our main routen is rnd16 which just returns a random number betwen 0 and 32K
:rnd16
@PUSHRETURN
@PUSHLOCALI Aval
@PUSHLOCALI Bval
@PUSHI Seed
@MV2V Seed Bval
@PUSH 48271
@CALL MULU
# Xor Result and Seed
@DUP
@DUP              # s[r,r,r]
@ORI Seed         # s[r,r,(r|s)]
@SWP              # s[r,(r|s),r]
@ANDI Seed        # s[r,(r|s),(r&s)]
@SUBS             # s[r,(r|s)-r(&s)]
#
@ADD 1
@IF_EQ_V Bval     # Every time we call this Cval changes so should kick us out of local loops
   @ForIA2V Bval 0 Cval
      @ADD 1
   @Next Bval
@ENDIF
@POPI Seed        # s[r]
#
# To avoid an issue with the lower 5 bites cause even/odd flipping
# We shift right 5 times.
@RRTC @RRTC @RRTC #@RRTC @RRTC
@INCI Cval
@IF_EQ_VA Cval 29
   @MA2V 0 Cval
@ENDIF
@POPLOCAL Bval
@POPLOCAL Aval
@POPRETURN
@RET
#
# rndint allows you defind a random range 0 -> value (max 2047)
# function rndint( range )
:rndint
@PUSHRETURN
@POPI RIRange
@CALL rnd16
@PUSHI RIRange
@CALL DIVU   # Divsion returns both the Division and the Mod, keep Mod only
@POPNULL
@POPRETURN
@RET
:RIReturn 0
:Seed 0
:Aval 0
:Bval 0
:Cval 0
:RIRange 0
:Product 0
#
# Set seed is just a way to set the initial seed value for a bit better randomization
:rndsetseed
@SWP    # As there is only one parameter, a swap is sufficent to preserve return addr.
@POPI Seed
@RET
#
# Returns the Current Seed for presevation and later re-runs
:rndgetseed
@PUSHI Seed
@SWP
@RET
#
# Function frnd16() a 'faster' frnd avaoiding 32 bit math
:frnd16
@PUSHRETURN
@PUSHLOCALI Product
@PUSHLOCALI Bval
# Rather than calling the MUL function for Seed * 31973 (prime # < 0x7fff)
# We'll using RTL's and Adds
# Binary 31973 is binary 1111111000010011
# Reading right to left, do a RTL and add for each on bit.
# 
@MV2V Seed Product
@PUSHI Seed
@RTL               # X << 1
@DUP @ADDI Product @POPI Product
@RTL @RTL @RTL     # X << 4
@DUP @ADDI Product @POPI Product
@RTL @RTL @RTL @RTL @RTL  # X << 9
@DUP @ADDI Product @POPI Product
@RTL               # X << 10
@DUP @ADDI Product @POPI Product
@RTL               # X << 11
@DUP @ADDI Product @POPI Product
@RTL               # X << 12
@DUP @ADDI Product @POPI Product
@RTL               # X << 13
@DUP @ADDI Product @POPI Product
@RTL               # X << 14
@DUP @ADDI Product @POPI Product
@RTL               # X << 15
@DUP @ADDI Product @POPI Product
# XOR result with seed.
@PUSHI Seed
@XORI Product
@ADD 1
@IF_EQ_V Bval
   @ForIA2V Bval 0 Cval
      @ADD 1
   @Next Bval
@ENDIF
@POPI Seed
@INCI Cval
@IF_EQ_VA Cval 29
   @MA2V 0 Cval
@ENDIF
@POPLOCAL Bval
@POPLOCAL Product
@POPRETURN
@RET
# frndint allows you defind a random range 0 -> value (max 2047)
# function rndint( range )
:frndint
@PUSHRETURN
@POPI RIRange
@CALL frnd16
@PUSHI RIRange
@CALL DIVU   # Divsion returns both the Division and the Mod, keep Mod only
@POPNULL
@POPRETURN
@RET


ENDBLOCK
