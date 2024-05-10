# Input: Stack RET, N, MM
# Output: ANS, CNT
! MUL_SEEN
M MUL_SEEN 1
G MUL
G MULU

# Define local storage (Registers)
:Var01 0
:Var02 0
:Var03 0
I common.mc
L softstack.ld
:MULU
=MM Var01
=NN Var02
=ANS Var03
@PUSHRETURN
@PUSHLOCALI MM
@PUSHLOCALI NN
@PUSHLOCALI ANS
@POPI MM
@POPI NN
@MA2V 0 ANS
@PUSHI NN
@IF_ZERO      # If either NN or MM is zero, answer is zero
    @JMP MULUEXIT
@ENDIF
@POPNULL
@PUSHI MM     # No Need to test MM for zero, while loop just will not run.
@WHILE_NOTZERO
# if m & 1 ; then m >> 1  
  @AND 1
  @IF_NOTZERO  # If MM[0]==1: ANS+=NN
     @PUSHI ANS @ADDI NN @POPI ANS 
  @ENDIF
  @POPNULL
  @PUSHI NN  @RTL  @POPI NN   # NN << 1
  @PUSHI MM  @RTR  @POPI MM   # MM >> 1
  @PUSHI MM
@ENDWHILE
@POPNULL
@PUSHI ANS
:MULUEXIT
@POPLOCAL ANS
@POPLOCAL NN
@POPLOCAL MM
@POPRETURN
@RET
#
# Now for the Signed version of MUL
:MUL
=SIGN Var01
@PUSHRETURN
@PUSHLOCALI SIGN

@MA2V 0 SIGN
@IF_LT_A 0          # IF NN or MM < 0 Invert SIGN
   @PUSHI SIGN
   @INV @POPI SIGN
@ENDIF
@SWP
@IF_LT_A 0
   @PUSHI SIGN
   @INV @POPI SIGN
@ENDIF
@SWP
@CALL MULU
@PUSHI SIGN
@IF_GT_A 0         # If SING==-1 Invert Answer
  @POPNULL
  @COMP2
@ELSE
  @POPNULL
@ENDIF
@POPLOCAL SIGN
@POPRETURN
@RET
ENDBLOCK


