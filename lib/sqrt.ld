# Square Root Function, Integer only.
# Require common.mc
! DEFINESQRT
L softstack.ld
L mul.ld
L lmath.ld
M SIZESINCECOMMENT sqrt.ld
M DEFINESQRT 0
:Hold1 0
:LongA 0 0
:LongB 0 0
:LongC 0 0
G SQRT
#
# Function SQRT(number)
:SQRT
=number Var01
=Bit Var02
=root Var03
@PUSHRETURN
@POPI number
@PUSHI number
@IF_LT_A 0
   @PRT "Error, SQRT of Negative number."
   @POPRETURN
   @RET
@ENDIF
@POPNULL
@MA2V 0x8000 Bit
@MA2V 0 root
@PUSHI Bit
@WHILE_NOTZERO
   @POPNULL
   # (root+Bit)**2
   @PUSHI root @ADDI Bit   
   # To allow for reasonable accuracy we use 32 bit math here.
   @POPI Hold1 @INT2LONG Hold1 LongA   # Convert 16b to 32b
   @MUL32VVV LongA LongA LongA         # do the **2
   @INT2LONG number LongB              # use 32bit CMP
   @CMP32VV LongB LongA                # We want LONGA <= LONGB or same as LONGB > LONGA
   @IF_EQ_A 1
      # root=root+Bit
      @PUSHI root @ADDI Bit @POPI root
   @ENDIF
   @POPNULL
   @PUSHI Bit @SHR @POPI Bit
   @PUSHI Bit
@ENDWHILE
@POPNULL
#
@PUSHI number
@WHILE_NOTZERO
   @POPNULL
   # number -= root**2
   @PUSHI number
   @PUSHI root @DUP @CALL MULU
   @SUBS @POPI number
   @PUSHI number
   @IF_GE_V root
      @SUBI root @POPI number
      @INCI root
      @PUSHI number
   @ENDIF
   @IF_LE_A 0
      @POPNULL
      @PUSH 0
   @ENDIF
@ENDWHILE
@PUSHI root
@POPRETURN
@SIZESINCE
@RET

