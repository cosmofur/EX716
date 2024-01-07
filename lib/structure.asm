# These for structured program flow
#
# This set of Macros bellow define a set of 'IF/ELSE/ENDIF' block structures.
# Keep in mind the actual 'logic' of the IF condition is code you need to write yourself
# THAT code leaves values on the stack that have to be fairly simple
# Conditions supported by the IF blocks are:
# ZERO, NO_ZERO, EQ_S, EQ_A, EQ_V, EQ_VV, GT_A, GE_A, GT_S, GE_S, LT_A, LE_A, LT_S, LE_S
#    Stack is not poped so what ever values you are testing, will remain on stack.
# EQ_V means cmping stack vs variable, EQ_VV means cmping two Variables for equality.
# EQ_VV,EQ_VA are really the only ones that takes two parameters.
# When 'reading' the GT and LT macros, think A is GT/LT B, with B being the second value given.

# IF_ZERO will start an IF[ELSE]ENDIF block if the value on the stack is zero
# It does not pop the value off, so remove the zero when it's no longer needed
M IF_ZERO \
    @PUSH 0 @CMPS @POPNULL \
    @JMPZ %0_True \
    %S @JMP %V_ENDIF \
    :%0_True
# IF_NOTZERO is the reverse logic of the IF_ZERO, works with the same 'ending' blocks
# and can be nested.
M IF_NOTZERO \
    @PUSH 0 @CMPS @POPNULL \
    @JNZ %0_True \
    %S @JMP %V_ENDIF \
    :%0_True
# IF_EQ_S (A,B)=True if value at TOS is == value at TOS-1
M IF_EQ_S \
  @CMPS \
  @JMPZ %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
# IF_EQ_A (A) = True if A == TOS
M IF_EQ_A \
  @PUSH %1 \
  @CMPS @POPNULL \
  @JMPZ %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
# IF_EQ_V (V) = True if [V] == TOS
M IF_EQ_V \
  @PUSHI %1 \
  @CMPS @POPNULL \
  @JMPZ %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
# If V1 == V2 True
M IF_EQ_VV \
  @PUSHI %1 @PUSHI %2 \
  @CMPS @POPNULL @POPNULL \
  @JMPZ %0_True \
  %S @JMP %V_ENDIF \
  :%0_True  
# If A == V1 True
M IF_EQ_VA \
  @PUSHI %1 @PUSH %2 \
  @CMPS @POPNULL @POPNULL \
  @JMPZ %0_True \
  %S @JMP %V_ENDIF \
  :%0_True  

# IF_LT_S (A,B)=True if value at SFT(A) < TOS(B)
M IF_LT_S \
   @CMPS \
   @JMPN  %0_True \
   %S @JMP %V_ENDIF \
   :%0_True
# IF_LT_A (A) = True if TOS is < A
M IF_LT_A \
   @CMP %1 \
   @JMPN %0_True \
    %S @JMP %V_ENDIF \
   :%0_True
#
M IF_LT_V \
   @CMPI %1 \
   @JMPN %0_True \
   %S @JMP %V_ENDIF \
   :%0_True
#
# IF_LE_S (A,B)=True if SFT(A) <= TOS(B)
M IF_LE_S \
  @CMPS \
  @JMPZ %0_True \
  @JMPN %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
# IF_LE_A (A) = True if TOS is <=A
M IF_LE_A \
  @CMP %1 \
  @JMPZ %0_True \
  @JMPN %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
# IF_LE_V V = True if TOS is <=V
M IF_LE_V \
  @CMPI %1 \
  @JMPZ %0_True \
  @JMPN %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
# IF_GE_S will A(SFT) >= B(TOS)
M IF_GE_S \
   @SWP @CMPS @SWP \
   @JMPN  %0_True \
   @JMPZ %0_True \
   %S @JMP %V_ENDIF \
   :%0_True
# True if TOS >= A
M IF_GE_A \
   @PUSH %1 @SWP @CMPS @SWP @POPNULL \
   @JMPN %0_True \
   @JMPZ %0_True \
    %S @JMP %V_ENDIF \
    :%0_True
# True if TOS >= V
M IF_GE_V \
  @PUSHI %1 @CMPS @POPNULL \
  %S \
  @JMPN %V_ENDIF
# True if (A,B) A>B
M IF_GT_S \
  @SWP @CMPS @SWP \
  @JMPN %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
# True if TOP > A
M IF_GT_A \
  @PUSH %1 @SWP @CMPS @SWP @POPNULL \
  @JMPN %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
M IF_GE_A \
  @PUSH %1 @CMPS @POPNULL \
  %S \
  @JMPN %V_ENDIF
# True if TOP > V
M IF_GT_V \
  @PUSHI %1 @SWP @CMPS @SWP @POPNULL \
  @JMPN %0_True \
  %S @JMP %V_ENDIF \
  :%0_True



#
# Unsigned Logic follows here
#
M IF_UGT_V \
   @CMPI %1 \
   %S \
   @JMPC %V_ENDIF \
   @JMPZ %V_ENDIF
M IF_UGE_V \
   @CMPI %1 \
   %S \   
   @JMPC %V_ENDIF
M IF_ULE_V \
   @CMPI %1 \
   %S \
   @JMPC %0_True \
   @JMPZ %0_True \
   @JMP %V_ENDIF \
   :%0_True
M IF_ULT_V \
    @CMPI %1 \
    @JMPC %0_True \
    %S @JMP %V_ENDIF \
    :%0_True
M IF_UGT_A \
   @CMP %1 \
   %S \
   @JMPC %V_ENDIF \
   @JMPZ %V_ENDIF
M IF_UGE_A \
   @CMP %1 \
   %S \   
   @JMPC %V_ENDIF
M IF_ULE_A \
   @CMP %1 \
   @JMPC %0_True \
   @JMPZ %0_True \
   %S @JMP %V_ENDIF \
   :%0_True
M IF_ULT_A \
    @CMP %1 \
    @JMPC %0_True \
    %S @JMP %V_ENDIF \
    :%0_True
M IF_UGT_S \
   @CMPS \
   %S \
   @JMPC %V_ENDIF \
   @JMPZ %V_ENDIF
M IF_UGE_S \
   @CMPS \
   %S \   
   @JMPC %V_ENDIF
M IF_ULE_S \
   @CMPS  \
   %S \   
   @JMPC %0_True \
   @JMPZ %0_True \
   @JMP %V_ENDIF \
   :%0_True
M IF_ULT_S \
    @CMPS \
    %S \    
    @JMPC %0_True \
    @JMP %V_ENDIF \
    :%0_True
# Here are a few of the IF structures based only on the existing flags
# This way you can use the FLAG based CMP and still use the ease of the IF/ELSE/BLOCKs
M IF_NEG \
  @JMPN %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
#
M IF_ZFLAG \
  @JMPZ %0_True \  
  %S @JMP %V_ENDIF \
  :%0_True
#
M IF_NOTZF \
  %S \
  @JMPZ %V_ENDIF
#
M IF_POS \
  %S \
  @JMPN %V_ENDIF
#
M IF_OVERFLOW \
  @JMPO %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
#
M IF_NOTOVER \
  %S \
  @JMPN %V_ENDIF
#
M IF_CARRY \
  @JMPC %0_True \
  %S @JMP %V_ENDIF \
  :%0_True
#
M IF_NOTCARRY \
  %S \
  @JMPC %V_ENDIF


 
#
# ELSE is common to all the IF type blocks.
# Note how if we fall into the ELSE block from the code right above.
# It jumps right to the 'JustEnd' label. We do the same thing for ENDIF 
M ELSE \
  @JMP %V_JustEnd \
  :%V_ElseBlock \
  M %V_ElseFlag true
#
# The Tricky part of ENDIF is determining if we used an ELSE block or not.
# If no ELSE had been used the %V_ElseFlag will not exist.
# We also Define an V_ElseBlock to zero because if there was no ELSE, it would never be
# defined, or used, but would still trigger a warning message during assembly since
# it had been indirectly referenced but not defined.

# M ENDIF \
#   @JMP %V_JustEnd \
#   :%V_ENDIF \
#   ! %V_ElseFlag \
#      @JMP %V_JustEnd \
#      =%V_ElseBlock 00 \
#   ENDBLOCK \
#   @JMP %V_ElseBlock \
#   :%V_JustEnd \
#   %P
 M ENDIF \
   @JMP %V_JustEnd \
   :%V_ENDIF \
   ? %V_ElseFlag \
     @JMP %V_ElseBlock \
   ENDBLOCK \
   :%V_JustEnd \
   %P

#
# Now this section is for simple While loop block structures.
#
M WHILE_ZERO \
  %S \
  :%V_LoopTop \
  @CMP 0 \
  @JMPZ %0_True \
  @JMP %V_ExitLoop \
  :%0_True

M WHILE_NOTZERO \
  %S \
  :%V_LoopTop \
  @CMP 0 \
  @JMPZ %V_ExitLoop \
  :%0_True

M WHILE_EQ_A \
  %S \
  :%V_LoopTop \
  @CMP %1 \
  @JMPZ %0_True \
  @JMP %V_ExitLoop \
  :%0_True

M WHILE_NEQ_A \
  %S \
  :%V_LoopTop \
  @CMP %1 \
  @JMPZ %V_ExitLoop \
  :%0_True

M WHILE_EQ_V \
  %S \
  :%V_LoopTop \
  @CMPI %1 \
  @JMPZ %0_True \
  @JMP %V_ExitLoop \
  :%0_True

M WHILE_NEQ_V \
  %S \
  :%V_LoopTop \
  @CMPI %1 \
  @JMPZ %V_ExitLoop \
  :%0_True

M WHILE_GT_A \
  %S \
  :%V_LoopTop \
  @CMP %1 \
  @JMPN %V_ExitLoop \
  :%0_True

M WHILE_GT_V \
  %S \
  :%V_LoopTop \
  @CMPI %1 \
  @JMPN %V_ExitLoop \
  :%0_True

M WHILE_LT_A \
  %S \
  :%V_LoopTop \
  @CMP %1 \
  @JMPN %0_True \
  @JMP %V_ExitLoop \
  :%0_True

M WHILE_LT_V \
  %S \
  :%V_LoopTop \
  @CMPI %1 \
  @JMPN %0_True \
  @JMP %V_ExitLoop \
  :%0_True

M WHILE_UGT_A \
  %S \
  :%V_LoopTop \
  @CMP %1 \
  @JMPC %V_ExitLoop \
  @JMPZ %V_ExitLoop \  
  :%0_True

M WHILE_UGT_V \
  %S \
  :%V_LoopTop \
  @CMPI %1 \
  @JMPC %V_ExitLoop \
  @JMPZ %V_ExitLoop \  
  :%0_True

M WHILE_ULT_A \
  %S \
  :%V_LoopTop \
  @CMP %1 \
  @JMPC %0_True \
  @JMP %V_ExitLoop \
  :%0_True
  
M WHILE_ULT_V \
  %S \
  :%V_LoopTop \
  @CMPI %1 \
  @JMPC %0_True \
  @JMP %V_ExitLoop \
  :%0_True


# Note the %P in both the Continue and Break Macros
# is there because we expect (demand) that the Break/Continue
# be part of an IF Block and we need to pop out of the Block first.
# This is Less flexable than full languages support.
M WHILECONTINUE \
  %P \
  @JMP %V_LoopTop

M WHILEBREAK \
  @JMP %W_ExitLoop

M FORBREAK \
  @JMP %W_NextEnd

M FORCONTINUE \
  @JMP %W_

M ENDWHILE \
  @JMP %V_LoopTop \
  :%V_ExitLoop \
  %P
#
# LOOP/UNTIL is basicly a while loop that does the test at the end of the loop
# which guarantees at least one iteration of the loop each time.

M LOOP \
  %S \
  :%V_TopLoop
# Like for 'while' we'll only handle the TOS zero or notzero cases.
# If you need a more complex test, manually do the test before UNTIL...
# and leave either 0 or 1 on the stack.

M UNTIL_NOTZERO \
  @CMP 0 \
  @JMPZ %V_TopLoop \
  %P

M UNTIL_ZERO \
  @CMP 0 \
  @JMPNZ %V_TopLoop \
  %P

#
# Switch/case.... is this possible?
# Sort of but with some limits.
# Unlike a 'C' switch case, each Case needs to be a block that ends with CBREAK
# So the 'case' match can't 'fall though' to the cases bellow and will always jump to the ENDCASE line
# So the SWITCH part is just a push of the test value and is always 16b numeric.
# The CASE types include CASE, CASE_RANGE A B, CASE_REF V, CDEFAULT
#
# Main reason for switch is to prep the Macro Stack so ENDCASE has something to 'pop'
# You need that so the V_ENDCASE will work.
M SWITCH \
  %S
#
# Basic CASE takes 16b constant as test value against stack
#    Worth Noting that we're using a mix of %0 and %V which a simple case like this
#    are the same value, but for notation sense, use %V when you mean the lable you
#    are preserving on the stack, and plan to use again, and %0 for lables that only
#    have value inside this same macro.
M CASE \
  %S \
  @CMP %1 \
  @JMPZ %V_DoCase1 \
  @JMP %V_NextCase \
  :%V_DoCase1

# Takes two constant params (low value then high value, can't be swaped)
# What going on here, might seem complex, the key is we have and IF_GE but no IF_LE
# So some of the complexity is to make sure we can use IF_GE for both the low and high
# range tests in the CASE. Other wise we could miss the edge cases.
M CASE_RANGE \
  %S \
  @CMP %1 \
  @JMPN %V_NextCase \
  @CMP %2 \
  @JMPN %V_InRange \
  @JMPZ %V_InRange \
  @JMP %V_NextCase \
  :%V_InRange

# Compares TOS with value at [%1] 
M CASE_I \
   %S \
  @CMPI %1 \
  @JMPNZ %V_NextCase

# The only reason we need CDEFAULT is to balance the Macro Stack, which would underflow without.
M CDEFAULT \
  :%V_NextCase \
  %S
  
# Call the CASES need a matching CBREAK main things it does is pop the MacroStack
#    There seems to be some odd jumping here. Just to keep track CBreak provides
#    Two entry points. One is the 'fall through' from the previous CASE which means
#    we want to jump to the ENDCASE BUT we don't have the right %V on the stack for that.
#    We first have to deal with the top of stack %V which is the entry point for the next
#    CASE statement, so we first 'jump over' the entry for the next CASE and then we can
#    POP the %V stack, get the right %V for the endcase and jmp there, lastly we prepare
#    for the next CASE 
M CBREAK \
  @JMP %0_SkipHeadNextCase \
     :%V_NextCase \
     @JMP %0_RealHeadNextCase \
     %P \     
  :%0_SkipHeadNextCase \
     @JMP %V_EndCASE \
  :%0_RealHeadNextCase


# End Case provides a target for, the %P is there to pop the %S from SWITCH

M ENDCASE \
  :%V_EndCASE \
  %P
#
#
# For Loops, We will continue to use notion A,B means constants and V means a variable
# 'I' is the 'index' variable and required for all loops.
#
# One issue with this type of for loop is that it will exit from the top of the loop if the index
# variable equals the termination value. Not termination+1, which means a For 1 to 10, would NOT do
# the body of the loop when the index equals 10, but would 'stop' at 9 iterations.
#
# This is a natural limitation of this type of FOR loop as we cant loop until index > stop as we don't
# know if the index is being incremented, or decremented until the NEXT macro is encountered. If we are
# using NEXTBY with a negative increment, then a '>' would have to be switched to a '<' one and we have
# no method to go back and do that.
#
#  The Test logic requires that the Index will increment from start to stop and must Exactly
#  equal the stop value to end the loop. If index increments by larger than 1 steps, it might
#  miss the Stop value and loop forever.
# 
# The For Loops come in the following types
#  ForIA2B     : 3 Args For from constant A to Constant B
#  ForIA2V     : 3 Args For from constant A to Variable
#  ForIV2A     : 3 Args For from constant Variable to Constant A
#  ForIV2V     : 3 Args For From Variable to Variable
#  Next I      : 1 Args must match Index name from For Loop (Inc var is default +1)
#  NextBy I A  : 2 Args Index name and Increment value, which can be negative
#  NextByI I V : 2 Args Index name and variable for increment
#                       Just make sure that Index will eventually equal the stop value.
#
#
#
# for Index from constant to constant

M ForIA2B \
  %S \
  @MA2V %2 %1 \
  :%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPZ %V_NextEnd

# For UP variation test for > end condition
M ForIupA2B \
  %S \
  @MA2V %2 %1 \
  :%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPN %V_NextEnd

# for Index from constant to variable
M ForIA2V \
  %S \
  @MA2V %2 %1 \
  :%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPZ %V_NextEnd

# For Up variation to for > end condition
M ForIupA2V \
  %S \
  @MA2V %2 %1 \
  :%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPN %V_NextEnd

# for Index from variable to constant
M ForIV2A \
  %S \
  @MV2V %2 %1 \
  :%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPZ %V_NextEnd

# For Up variation to for > end condition
M ForIupV2A \
  %S \
  @MV2V %2 %1 \
  :%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPN %V_NextEnd

#for Index from variable to variable
M ForIV2V \
  %S \
  @MV2V %2 %1 \
  :%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPZ %V_NextEnd

M ForIupV2V \
  %S \
  @MV2V %2 %1 \
  :%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPN %V_NextEnd

M Next \
  @INCI %1 \
  @JMP %V_ForTop \
  :%V_NextEnd \
  %P
M NextBy \
  @PUSH %2 \
  @ADDI %1 \
  @POPI %1 \
  @JMP %V_ForTop \
  :%V_NextEnd \
  %P
M NextByI \
  @PUSHI %2 \
  @ADDI %1 \
  @POPI %1 \
  @JMP %V_ForTop \
  :%V_NextEnd \
  %P

  

  
