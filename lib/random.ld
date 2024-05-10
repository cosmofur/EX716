! RANDOM_SEEN
I common.mc
L softstack.ld
L lmath.ld
L mul.ld
M RANDOM_SEEN 1
G rnd16 G rndint G rndsetseed G frnd16 G frndint G xorshift16

:Seed
:Seed32A 0 0
:Modulus32 $$$1103515245   # ISO Plauger's book
:MOffset32 $$$12345
:Scratch32A 0 0
:Bval
:Scratch32B 0 0
:Cval
:Scratch32C 0 0
:Product 0
:RIRange 0


#Function rnd16()
# 
:rnd16
@PUSH Seed32A
@PUSH Modulus32
@PUSH Scratch32A
@CALL MUL32
#
#
@PUSH Scratch32A
@PUSH MOffset32
@PUSH Scratch32B
@CALL ADD32
#
@COPY32VV Scratch32B Seed32A

#
# We only use the top 16 bits of the result seed for return.
@PUSHI Seed32A+2
@SWP
@RET

# Function rndsetseed(N)
# Sets the seed value (only can set the lower 16 bits)
:rndsetseed
@PUSHRETURN
@POPI Seed32A
@PUSH 0 @POPI Seed32A+2
@POPRETURN
@RET
#
:Range1 0
# Function rndint(N) returns intger rand between 0 and N
:rndint
@PUSHRETURN
@POPI Range1
@CALL rnd16
# Before we call the expensive DIV function, check for some common simpler cases
@IF_EQ_VA Range1 2
   @AND 0x1
@ELSE
   @IF_EQ_VA Range1 4
      @AND 0x3
   @ELSE
      @IF_EQ_VA Range1 8
         @AND 0x7
      @ELSE
         @PUSHI Range1
         @CALL DIVU
         @POPNULL
      @ENDIF
   @ENDIF
@ENDIF
@POPRETURN
@RET
#
# frndint allows you defind a random range 0 -> value (max 2047)
# function rndint( range )
:frndint
@PUSHRETURN
@POPI RIRange
@CALL xorshift16
@PUSHI RIRange
@CALL DIVU   # Divsion returns both the Division and the Mod, keep Mod only
@POPNULL
@POPRETURN
@RET

# xorshift version of fast random
:frnd16
:xorshift16
@PUSHRETURN
@INCI Cval
@MV2V Seed S1Seed
@MV2V Seed SModified
@MV2V Seed Bval
# << 7
@PUSHI SModified
@RTL @RTL @RTL @RTL @RTL @RTL @RTL
@POPI S1Seed
#
# Now XOR it with original Seed
@PUSHI S1Seed
@PUSHI SModified
@XORS
@POPI SModified
# S2 is SModified >> 9
@PUSHI SModified
@RTR @RTR @RTR @RTR @RTR @RTR @RTR @RTR @RTR
@POPI S1Seed
# Xor results
@PUSHI S1Seed
@PUSHI SModified
@XORS
@POPI SModified
#
# S3 is SModified << 8 Thats just making the Low Bits the High Bits
@PUSHI SModified
@RTL @RTL @RTL @RTL @RTL @RTL @RTL @RTL
@POPI S1Seed
@PUSHI S1Seed
@PUSHI SModified
@XORS
@IF_EQ_V Seed
   @POPNULL
   @MV2V Cval Seed
@ELSE
   @POPI Seed
@ENDIF
@PUSHI Seed
@POPRETURN
@RET
:S1Seed 0
:SModified 0
