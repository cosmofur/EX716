# Input: Stack RET, N, MM
# Output: ANS, CNT
# Requites common
! MUL_SEEN
M MUL_SEEN 1
@JMP MULINIT
G MUL
G MULU
:MULU
@POPI RETURN
@POPI MM
@POPI NN
@MA2V 0 ANS
@PUSHI NN
@IF_ZERO      # If either NN or MM is zero, answer is zero
   @PUSHI RETURN
   @RET
@ENDIF
@POPNULL
@PUSHI MM     # A additional MM is zero test would be redundent.
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
@PUSHI RETURN
@RET
:RETURN
0
:RETURN2
0
:NN
0
:MM
0
:ANS
0
:SIGN
0
:ONEMASK
1
#
# Now for the Signed version of MUL
:MUL
@POPI RETURN2
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
@PUSHI RETURN2
@RET
:MULINIT
ENDBLOCK


