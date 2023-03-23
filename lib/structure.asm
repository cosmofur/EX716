# These for structured program flow
#
# This set of Macros bellow define a set of 'IF/ELSE/ENDIF' block structures.
# Keep in mind the actual 'logic' of the IF condition is code you need to write yourself
# THAT code leaves values on the stack that have to be fairly simple
# Conditions supported by the IF blocks are:
#    TOS == ZERO,  TOS != ZERO, Immediate < TOS, Immediate >= TOS, TOS < [TOS-1] and TOS >= [TOS-1]
#    Stack is not poped so what ever values you are testing, will remain on stack.
#    We are not providing a <= or simple > logic so use stack swaps if needed or code around it.


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
M IF_EQ_VV \
  @PUSHI %1 @PUSHI %2 \
  @CMPS @POPNULL @POPNULL \
  @JMPZ %0_True \
  %S @JMP %V_ENDIF \
  :%0_True  
# IF_LT_S (A,B)=True if value at TOS is < value at TOS-1
M IF_LT_S \
   @CMPS \
   @JMPN  %0_True \
   %S @JMP %V_ENDIF \
   :%0_True
# IF_LT_A (A) = True if value A is < TOS
M IF_LT_A \
   @PUSH %1 \
   @CMPS @POPNULL \
   @JMPN %0_True \
    %S @JMP %V_ENDIF \
    :%0_True
# IF_GE_S will compare TOS with [TOS-1] and do block if [TOS] >= [TOS-1] ;
M IF_GE_S \
   @SWP @CMPS @SWP \
   @JMPN  %0_True \
   @JMPZ %0_True \
   %S @JMP %V_ENDIF \
   :%0_True
# Like IF_LT_S but compares TOS to immediate value (testing if immediate value is < TOS
M IF_GE_A \  
   @PUSH %1 @SWP @CMPS @SWP @POPNULL \
   @JMPN %0_True \
   @JMPZ %0_True \
    %S @JMP %V_ENDIF \
    :%0_True
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
# We also Define an V_ElseBlock to zero because if there was not else, it would never be
# defined, or used, but would still trigger a warning message during assembly since
# it had been indirectly referenced but not defined.
##  :%V_ElseBlock \

M ENDIF \
  @JMP %V_JustEnd \
  :%V_ENDIF \
  ! %V_ElseFlag \
     @JMP %V_JustEnd \
     =%V_ElseBlock 0 \
  ENDBLOCK \
  @JMP %V_ElseBlock \
  :%V_JustEnd \
  %P
#
# Now this section is for simple While loop block structures.
# For simplicity we're only supporting the zero/not-zero test.
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
  @JNZ %0_True \
  @JMP %V_ExitLoop \
  :%0_True

M CONTINUE \
  @JMP %V_LoopTop

M BREAK \
  @JMP %V_ExitLoop

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

M UNTIL_ZERO \
  @CMP 0 \
  @JMPZ %V_TopLoop \
  %P

M UNTIL_NOTZERO \
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
  @JMPZ %0_DoCase \
  @JMP %V_NextCase \
  :%0_DoCase

# Takes two constant params (low value then high value, can't be swaped)
M CASE_RANGE \
  %S \
  @CMP %1 \
  @JMPN %0_LowGood \
     @JMP %V_NextCase \
  :%0_LowGood \
     @CMP %2 \
     @JMPN %V_NextCase

# Compares TOS with value at [%1] which 'maybe' dynamic.
M CASE_REF \
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
  @MC2M %2 %1 \
  :%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPZ %V_NextEnd

# for Index from constant to variable
M ForIA2V \
  %S \
  @MC2M %2 %1 \
  :%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPZ %V_NextEnd

# for Index from variable to constant
M ForIV2A \
  %S \
  @MM2M %2 %1 \
  :%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPZ %V_NextEnd

#for Index from variable to variable
M ForIV2V \
  %S \
  @MM2M %2 %1 \
  :%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPZ %V_NextEnd
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
