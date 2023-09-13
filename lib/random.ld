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
@JMP Skip2End
! RANDOM_SEEN
M RANDOM_SEEN 1
#
# We will make public the function rnd16 and rndsetseed(N)
G rnd16 G rndsetseed G rndint G rndgetseed

# Our main routen is rnd16 which just returns a random number betwen 0 and 32K
:rnd16
@POPI RDReturn
@PUSHI Seed
@PUSH 22673
@CALL MULU
@ADD 1
@DUP
@POPI Seed
# To avoid an issue with the lower 5 bites cause even/odd flipping
# We shift right 5 times.
@RTR @RTR @RTR @RTR @RTR
@PUSHI RDReturn
@RET
#
# rndint allows you defind a random range 0 -> value (max 2047)
# rndint( range )
:rndint
@POPI RIReturn
@POPI RIRange
@CALL rnd16
@PUSHI RIRange
@CALL DIVU   # Divsion returns both the Division and the Mod, keep Mod only
@POPNULL
@PUSHI RIReturn
@RET
:RIReturn 0
:Seed 0
:RDReturn 0
:RIRange 0
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
ENDBLOCK
:Skip2End
