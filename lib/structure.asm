# These for structured program flow
#
# This set of Macros bellow define a set of 'IF/ELSE/ENDIF' block structures.
# Keep in mind the actual 'logic' of the IF condition is code you need to write yourself
# THAT code leaves values on the stack that have to be fairly simple
# Conditions supported by the IF blocks are:
# ZERO, NOTZERO,
# NEG. ZFLAG.NOTZF,POS,OVERFLOW,NOTOVER,NOTCARRY
# EQ_S, EQ_A, EQ_V, EQ_VV, EQ_VA, EQ_AV
# LT_S, LT_A, LT_V, LT_VV
# LE_S, LE_A, LE_V, LE_VV
# ULT_S, ULT_A, ULT_V, ULT_VV
# ULE_S, ULE_A, ULE_V, ULE_VV
# GT_S, GT_A, GT_V, GT_VV,
# GE_S, GE_A, GE_V, GE_VV,
# UGT_S, UGT_A, UGT_V, UGT_VV,
# UGE_S, UGE_A, UGE_V, UGE_VV,
# INRANGE_AB, INRANGE_AV,INRANGE_VA
#
# Not there are no 'NEQ or few 'Not' prebuilt IF conditions, this is because the ELSE logic
# does that already. There is no forced requirment that the positive IF block has to have any
# content, and you can have an IF ELSE ENDIF block that only has content in the ELSE block.
#
# While loops also have a number of tests available (not as exaustive as IF but a good number)
# NOTZERO,EQ_A,NEQ_A,NEQ_V,EQ_AV,NEQ_AV,GT_A,GT_V,LT_A,LT_V,UGT_A,UGT_V,ULT_A,ULT_V
#
# WHEN/DO_?/ENDWHEN loops are basicly simplified while loops but with the conditional part
# being a multi line WHEN function. This allows more complex conditions that what the
# built in ones allow, while keeping it a readable structure.
# Only condition the DO part cares about are ZERO or NOTZERO but WHEN part of the block
# can be as complex as it needs to be, just has to exit with a zero/notzero on the stack.
#
# LOOP/UNTIL
# Loop Until is basicly a WHEN block but with the condtional tested at the bottom rather
# than the top of the loop. This will mean that the loop will run at least once. Where
# normal WHEN loops many not run at all, if the initial condition has already been met.
# Like WHEN/DO loops the conditional at the bottom is only tested for ZERO/NOTZERO but
# you can use as many lines as you want at the end of the loop to prepare that test.
#
# WHILEBREAK/FORBREAK
# This is a somewhat limited, 'break out of current loop' command.
# It has a MAJOR limitation, it has to be decided at a top level IF/ENDIF block.
# You can't break out of FOR or WHILE loop from more than 1 level deep of an IF block.
#
# FORCONTINUE is like FORBREAK, it shortcuts the loop to the NEXT line, but like
# FORBREAK it has to be at a top level IF block within the loop.
# 





# 
#    Stack is not poped so what ever values you are testing, will remain on stack.
# EQ_V means cmping stack vs variable, EQ_VV means cmping two Variables for equality.
# EQ_VV,EQ_VA are really the only ones that takes two parameters.
# When 'reading' the GT and LT macros, think A is GT/LT B, with B being the second value given.

# IF_ZERO will start an IF[ELSE]ENDIF block if the value on the stack is zero
# It does not pop the value off, so remove the zero when it's no longer needed
M IF_ZERO \
    @PUSH 0 @CMPS @POPNULL \
    @JMPZ _%0_True \
    %S @JMP _%V_ENDIF \
    :_%0_True
# IF_NOTZERO is the reverse logic of the IF_ZERO, works with the same 'ending' blocks
# and can be nested.
M IF_NOTZERO \
    @PUSH 0 @CMPS @POPNULL \
    @JNZ _%0_True \
    %S @JMP _%V_ENDIF \
    :_%0_True
# IF_EQ_S (A,B)=True if value at TOS is == value at TOS-1
M IF_EQ_S \
  @CMPS \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
# IF_EQ_A (A) = True if A == TOS
M IF_EQ_A \
  @PUSH %1 \
  @CMPS @POPNULL \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
# IF_EQ_V (V) = True if [V] == TOS
M IF_EQ_V \
  @PUSHI %1 \
  @CMPS @POPNULL \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
# If V1 == V2 True
M IF_EQ_VV \
  @PUSHI %1 @PUSHI %2 \
  @CMPS @POPNULL @POPNULL \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True  
# If A == V1 True
M IF_EQ_VA \
  @PUSHI %1 @PUSH %2 \
  @CMPS @POPNULL @POPNULL \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
# Reverse for readability
M IF_EQ_AV \
  @PUSH %1 @PUSHI %2 \
  @CMPS @POPNULL @POPNULL \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
# IF_LT_S (A,B)=True if value at SFT(A) < TOS(B)
M IF_LT_S \
   %S \
   @CMPS         \
   @JMPN _%0_True \
   @JMP _%V_ENDIF \
 :_%0_True

# IF_LT_A (A) = True if TOS is < A
M IF_LT_A \
   @CMP %1 \
   @JMPN _%0_True \
    %S @JMP _%V_ENDIF \
   :_%0_True
#
M IF_LT_V \
   @CMPI %1 \
   @JMPN _%0_True \
   %S @JMP _%V_ENDIF \
   :_%0_True
#
# IF_LE_S (A,B)=True if SFT(A) <= TOS(B)
M IF_LE_S \
  %S \
  @CMPS \
  @JMPZ _%0_True \
  @JMPN _%0_True \
  @JMP _%V_ENDIF \
  :_%0_True
# IF_LE_A (A) = True if TOS is <=A
M IF_LE_A \
  %S \
  @CMP %1 \
  @JMPZ _%0_True \
  @JMPN _%0_True \
  @JMP _%V_ENDIF \
  :_%0_True
# IF_LE_V V = True if TOS is <=V
M IF_LE_V \
  @CMPI %1 \
  @JMPZ _%0_True \
  @JMPN _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
# IF_GE_S will A(SFT) >= B(TOS)
M IF_GE_S \
   %S \
   @CMPS \
   @JMPZ _%0_True \
   @JMPN _%V_ENDIF \
   :_%0_True
# True if TOS >= A
M IF_GE_A \
   %S \
   @CMP %1 \
   @JMPZ _%0_True \
   @JMPN _%V_ENDIF \
   :_%0_True
# True if TOS >= V
M IF_GE_V \
   %S \
   @CMPI %1 \
   @JMPZ _%0_True \
   @JMPN _%V_ENDIF \
   :_%0_True
# True if TOS > A
M IF_GT_S \
  %S \
  @CMPS \
  @JMPN _%V_ENDIF \
  @JMPZ _%V_ENDIF \
 :_%0_True
# True if TOP > A
M IF_GT_A \
  %S \
  @CMP %1 \
  @JMPN _%V_ENDIF \
  @JMPZ _%V_ENDIF \
  @JMP _%0_True \
  :_%0_True
# True if TOS > V
M IF_GT_V \
  %S \
  @CMPI %1 \
  @JMPN _%V_ENDIF \
  @JMPZ _%V_ENDIF \
  @JMP _%0_True \
  :_%0_True
M IF_INRANGE_AB \
  %S \
  @PUSH %1 @CMPS @POPNULL \
  @JMPN _%V_ENDIF \
  @PUSH %2 @CMPS @POPNULL \
  @JGT _%V_ENDIF \
  :_%0_True
M IF_INRANGE_AV \
  %S \
  @PUSH %1 @CMPS @POPNULL \
  @JMPN _%V_ENDIF \
  @PUSHI %2 @CMPS @POPNULL \
  @JGT _%V_ENDIF \
  :_%0_True
M IF_INRANGE_VA \
  %S \
  @PUSHI %1 @CMPS @POPNULL \
  @JMPN _%V_ENDIF \
  @PUSH %2 @CMPS @POPNULL \
  @JGT _%V_ENDIF \
  :_%0_True
M IF_INRANGE_VV \
  %S \
  @PUSHI %1 @CMPS @POPNULL \
  @JMPN _%V_ENDIF \
  @PUSHI %2 @CMPS @POPNULL \
  @JGT _%V_ENDIF \
  :_%0_True
#
# Unsigned Logic follows here
#
M IF_UGT_V \
   @CMPI %1 \
   %S \
   @JMPC _%V_ENDIF \
   @JMPZ _%V_ENDIF
M IF_UGE_V \
   @CMPI %1 \
   %S \   
   @JMPC _%V_ENDIF
M IF_UGT_A \
   @CMP %1 \
   %S \
   @JMPC _%V_ENDIF \
   @JMPZ _%V_ENDIF
M IF_UGE_A \
   @CMP %1 \
   %S \   
   @JMPC _%V_ENDIF
#   @SWP @CMPS @SWP \
   
M IF_UGT_S \
   %S \
   @CMPS \
   @JMPC _%V_ENDIF \
   @JMPZ _%V_ENDIF
M IF_UGE_S \
   @CMPS \
   %S \
   @JMPC _%V_ENDIF
M IF_ULE_V \
   @CMPI %1 \
   %S \
   @JMPC _%0_True \
   @JMPZ _%0_True \
   @JMP _%V_ENDIF \
   :_%0_True
M IF_ULT_V \
    %S \
    @CMPI %1 \
    @JMPC _%0_True \
    @JMP _%V_ENDIF \
    :_%0_True
M IF_ULE_A \
   %S \
   @CMP %1 \
   @JMPC _%0_True \
   @JMPZ _%0_True \
   @JMP _%V_ENDIF \
   :_%0_True
M IF_ULT_A \
    %S \
    @CMP %1 \
    @JMPC _%0_True \
    @JMP _%V_ENDIF \
    :_%0_True
M IF_ULE_S \
   %S \
   @CMPS  \
   @JMPC _%0_True \
   @JMPZ _%0_True \
   @JMP _%V_ENDIF \
   :_%0_True
M IF_ULT_S \
    %S \
    @CMPS \
    @JMPC _%0_True \
    @JMP _%V_ENDIF \
    :_%0_True
# Here are a few of the IF structures based only on the existing flags
# This way you can use the FLAG based CMP and still use the ease of the IF/ELSE/BLOCKs
M IF_NEG \
  @JMPN _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
#
M IF_ZFLAG \
  @JMPZ _%0_True \  
  %S @JMP _%V_ENDIF \
  :_%0_True
#
M IF_NOTZF \
  %S \
  @JMPZ _%V_ENDIF
#
M IF_POS \
  %S \
  @JMPN _%V_ENDIF
#
M IF_OVERFLOW \
  @JMPO _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
#
M IF_NOTOVER \
  %S \
  @JMPN _%V_ENDIF
#
M IF_CARRY \
  @JMPC _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
#
M IF_NOTCARRY \
  %S \
  @JMPC _%V_ENDIF


 
#
# ELSE is common to all the IF type blocks.
# Note how if we fall into the ELSE block from the code right above.
# It jumps right to the 'JustEnd' label. We do the same thing for ENDIF
# We also set with MF a _%V_ElseFlag so correctly nested ENDIF will know if
# an 'else' was in effect or not.
M ELSE \
  MF _%V_ElseFlag true \
  @JMP _%V_JustEnd \
  :_%V_ENDIF

#
# The Tricky part of ENDIF is determining if we used an ELSE block or not.
# If no ELSE had been used the %V_ElseFlag will not exist.
# We also Define an V_ElseBlock to zero because if there was no ELSE, it would never be
# defined, or used, but would still trigger a warning message during assembly since
# it had been indirectly referenced but not defined.

M ENDIF \
  ? _%V_ElseFlag \
  @JMP _%V_JustEnd \
  ENDBLOCK \
  ! _%V_ElseFlag \
  :_%V_ENDIF \
  ENDBLOCK \
  :_%V_JustEnd \
  %P

#
# Now this section is for simple While loop block structures.
#
M WHILE_ZERO \
  %S \
  :_%V_LoopTop \
  @CMP 0 \
  @JMPZ _%0_True \
  @JMP _%V_ExitLoop \
  :_%0_True

M WHILE_NOTZERO \
  %S \
  :_%V_LoopTop \
  @CMP 0 \
  @JMPZ _%V_ExitLoop \
  :_%0_True

M WHILE_EQ_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JMPZ _%0_True \
  @JMP _%V_ExitLoop \
  :_%0_True

M WHILE_EQ_AV \
  %S \
  :_%V_LoopTop \
  @PUSH %1 \
  @PUSHI %2 \
  @CMPS \
  @POPNULL @POPNULL \
  @JMPZ _%0_True \
  @JMP _%V_ExitLoop \
  :_%0_True  

M WHILE_NEQ_AV \
  %S \
  :_%V_LoopTop \
  @PUSH %1 \
  @PUSHI %2 \
  @CMPS \
  @POPNULL @POPNULL \  
  @JMPZ _%V_ExitLoop \
  :_%0_True


M WHILE_NEQ_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JMPZ _%V_ExitLoop \
  :_%0_True

M WHILE_EQ_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JMPZ _%0_True \
  @JMP _%V_ExitLoop \
  :_%0_True

M WHILE_NEQ_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JMPZ _%V_ExitLoop \
  :_%0_True

M WHILE_GT_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JMPN _%V_ExitLoop \
  :_%0_True

M WHILE_GT_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JMPN _%V_ExitLoop \
  @JMPZ _%V_ExitLoop \
  :_%0_True

M WHILE_LT_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JMPN _%0_True \
  @JMP _%V_ExitLoop \
  :_%0_True

M WHILE_LT_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JMPN _%0_True \
  @JMP _%V_ExitLoop \
  :_%0_True

M WHILE_UGT_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JMPC _%V_ExitLoop \
  @JMPZ _%V_ExitLoop \  
  :_%0_True

M WHILE_UGT_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JMPC _%V_ExitLoop \
  @JMPZ _%V_ExitLoop \  
  :_%0_True

M WHILE_ULT_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JMPC _%0_True \
  @JMP _%V_ExitLoop \
  :_%0_True
  
M WHILE_ULT_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JMPC _%0_True \
  @JMP _%V_ExitLoop \
  :_%0_True
#
# When Do Loop are very much like While Loops but have a fixed place for a multi
# line conditional logic. WHEN Code DO_ZERO or DO_NOTZERO ENDWHEN
# Code can be multiple lines, just it leaves a 0 or a non-zero to contol
# execution between Do and ENDWHEN
# WHEN is good for cases where there no existing WHILE condition prewired.
# Its important to remember the condition block will leave a condition value
# on the stack, that will need to be POPNULL'ed to keep the stack from growing.
#
M WHEN \
  %S \
  :_%V_LoopTop
#
M DO_ZERO \
  @CMP 0 \
  @JMPZ _%V_True \
  @JMP _%V_ENDWHEN \
  :_%V_True
#
M DO_NOTZERO \
  @CMP 0 \
  @JMPZ _%V_ENDWHEN
#
M ENDWHEN \
  @JMP _%V_LoopTop \
  :_%V_ENDWHEN \
  %P


# Note the %P in both the Continue and Break Macros
# is there because we expect (demand) that the Break/Continue
# be part of an IF Block and we need to pop out of the Block first.
# This is Less flexable than full languages support as it supports only
# one level of enbeding (So it can't be a 2nd or deeper IF block)
M WHILECONTINUE \
  %P \
  @JMP _%V_LoopTop

M WHILEBREAK \
  @JMP _%W_ExitLoop

M FORBREAK \
  @JMP _%W_NextEnd

M FORCONTINUE \
  @JMP _%W_

M ENDWHILE \
  @JMP _%V_LoopTop \
  :_%V_ExitLoop \
  %P
#
# LOOP/UNTIL is basicly a while loop that does the test at the end of the loop
# which guarantees at least one iteration of the loop each time.

M LOOP \
  %S \
  :_%V_TopLoop
# UNTIL only handles the TOS zero or notzero cases.
# If you need a more complex test, manually do the test before UNTIL...
# and leave either 0 or 1 on the stack.

M UNTIL_NOTZERO \
  @CMP 0 \
  @JMPZ _%V_TopLoop \
  %P

M UNTIL_ZERO \
  @CMP 0 \
  @JMPNZ _%V_TopLoop \
  %P

#
# Switch/case.... is this possible?
# Sort of but with some limits.
# Unlike a 'C' switch case, each Case needs to be a block that ends with CBREAK
# So the 'case' match can't 'fall though' to the cases bellow and will always jump to the ENDCASE line
# So the SWITCH part is just a push of the test value and is always 16b numeric.
# The CASE types include CASE, CASE_RANGE A B, CASE_I V, CDEFAULT
#
# Main reason for switch is to prep the Macro Stack so ENDCASE has something to 'pop'
# You need that so the ENDCASE will work.
M SWITCH \
  %S
#
# Basic CASE takes 16b constant as test value against stack
#    Worth Noting that we're using a mix of _%0 and _%V which a simple case like this
#    are the same value, but for notation sense, use _%V when you mean the lable you
#    are preserving on the stack, and plan to use again, and _%0 for lables that only
#    have value inside this same macro.
M CASE \
  %S \
  @CMP %1 \
  @JMPZ _%V_DoCase1 \
  @JMP _%V_NextCase \
  :_%V_DoCase1

# Takes two constant params (low value then high value, can't be swaped)
# So some of the complexity is to make sure we can use IF_GE for both the low and high
# range tests in the CASE. Other wise we could miss the edge cases.
M CASE_RANGE \
  %S \
  @CMP %1 \
  @JMPN _%V_NextCase \
  @CMP %2 \
  @JGT _%V_NextCase \
  @JMP _%V_InRange \
  :_%V_InRange

# Compares TOS with value at [%1] 
M CASE_I \
   %S \
  @CMPI %1 \
  @JMPNZ _%V_NextCase

# You Always need CDEFAULT is to balance the Macro Stack, which would underflow without.
# So always include a CDEFAULT even if you alreay had CASE's for all the valid values.
M CDEFAULT \
  :_%V_NextCase \
  %S
  
# Call the CASES need a matching CBREAK main things it does is pop the MacroStack
#    There seems to be some odd jumping here. Just to keep track CBreak provides
#    Two entry points. One is the 'fall through' from the previous CASE which means
#    we want to jump to the ENDCASE BUT we don't have the right _%V on the stack for that.
#    We first have to deal with the top of stack _%V which is the entry point for the next
#    CASE statement, so we first 'jump over' the entry for the next CASE and then we can
#    POP the _%V stack, get the right _%V for the endcase and jmp there, lastly we prepare
#    for the next CASE 
M CBREAK \
  @JMP _%0_SkipHeadNextCase \
     :_%V_NextCase \
     @JMP _%0_RealHeadNextCase \
     %P \     
  :_%0_SkipHeadNextCase \
     @JMP _%V_EndCASE \
  :_%0_RealHeadNextCase


# End Case provides a target for, the %P is there to pop the %S from SWITCH

M ENDCASE \
  :_%V_EndCASE \
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
# For cases where there may not be an exact match for the stop value, you can use the ForIup## variant
# But this version can not work with negative 'NextBy' only possitive the test is valid only from
# A Up To B, not B down to A
#
# 
# The For Loops come in the following types
#  ForIA2B Index    : 3 Args For from constant A to Constant B
#  ForIA2V Index    : 3 Args For from constant A to Variable
#  ForIV2A Index    : 3 Args For from Variable to Constant A
#  ForIV2V Index    : 3 Args For From Variable to Variable
#  ForIA2S Index    : 2 Args For from Constant to value on TOS
#  Next Index       : 1 Args must match Index name from For Loop (Inc var is default +1)
#  NextBy Index A   : 2 Args Index name and Increment value, which can be negative
#  NextByI Index V  : 2 Args Index name and variable for increment
#                       Just make sure that Index will eventually equal the stop value.
#             For cases when your lookint to stop loop when index is >= stop value.
#  ForIupA2B Index  : 3 Args For from constant A until >= Constant B
#  ForIupA2V Index  : 3 Args For from constant A until >= Variable B
#  ForIupA2V Index  : 3 Args For from Varable A until >= Constant B
#  ForIupV2V Index  : 3 Args For from Varable A until >= Varable B
#  ForIupA2S Index  : 2 Args For from constant A until >= TOS value
#  ForIdownA2B Index  : 3 Args For from constant A until <= Constant B
#  ForIdownA2V Index  : 3 Args For from constant A until <= Variable B
#  ForIdownA2V Index  : 3 Args For from Varable A until <= Constant B
#  ForIdownV2V Index  : 3 Args For from Varable A until <= Varable B
#  ForIdownA2S Index  : 2 Args For from constant A until <= TOS value

#
#
# for Index from constant to constant

M ForIA2B \
  %S \
  @MA2V %2 %1 \
  :_%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPZ _%V_NextEnd

# For UP variation test for > end condition
M ForIupA2B \
  %S \
  @MA2V %2 %1 \
  :_%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPC _%V_NextEnd \
  @JMPZ _%V_NextEnd

M ForIdownA2B \
  %S \
  @MA2V %2 %1 \
  :_%V_ForTop \
  @PUSHI %1 \
  @CMP %3 @POPNULL \
  @JMPN _%V_NextEnd \
  @JMPZ _%V_NextEnd



# for Index from constant to variable
M ForIA2V \
  %S \
  @MA2V %2 %1 \
  :_%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPZ _%V_NextEnd

# For Up variation to for > end condition
M ForIupA2V \
  %S \
  @MA2V %2 %1 \
  :_%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPC _%V_NextEnd \
  @JMPZ _%V_NextEnd

M ForIdownA2V \
  %S \
  @MA2V %2 %1 \
  :_%V_ForTop \
  @PUSHI %1 \
  @CMPI %3 @POPNULL \
  @JMPN _%V_NextEnd \
  @JMPZ _%V_NextEnd


# For Index from constant to current TOS
M ForIA2S \
  %S \
  @POPI _%V_EndVal \
  @MA2V %2 %1 \  
  @JMP _%V_ForTop \
  :_%V_EndVal 0 \
  :_%V_ForTop \
  @PUSHI _%V_EndVal \
  @CMPI %1 @POPNULL \
  @JMPZ _%V_NextEnd

# Forup Up variation test for > end condition
M ForIupA2S \
  %S \
  @POPI _%V_EndVal \
  @MA2V %2 %1 \
  @JMP _%V_ForTop \
  :_%V_EndVal 0 \
  :_%V_ForTop \
  @PUSHI _%V_EndVal \
  @CMPI %1 @POPNULL \
  @JMPC _%V_NextEnd \
  @JMPZ _%V_NextEnd

M ForIdownA2S \
  %S \
  @POPI _%V_EndVal \
  @MA2V %2 %1 \
  @JMP _%V_ForTop \
  :_%V_EndVal 0 \
  :_%V_ForTop \
  @PUSHI %1 \
  @CMPI _%V_EndVal @POPNULL \
  @JMPN _%V_NextEnd \
  @JMPZ _%V_NextEnd
  


# for Index from variable to constant
M ForIV2A \
  %S \
  @MV2V %2 %1 \
  :_%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPZ _%V_NextEnd

# For Up variation to for > end condition
M ForIupV2A \
  %S \
  @MV2V %2 %1 \
  :_%V_ForTop \
  @PUSH %3 \
  @CMPI %1 @POPNULL \
  @JMPC _%V_NextEnd \
  @JMPZ _%V_NextEnd

M ForIdownV2A \
  %S \
  @MV2V %2 %1 \
  :_%V_ForTop \
  @PUSHI %1 \
  @CMP %3 @POPNULL \
  @JMPN _%V_NextEnd \
  @JMPZ _%V_NextEnd

  
#for Index from variable to variable
M ForIV2V \
  %S \
  @MV2V %2 %1 \
  :_%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPZ _%V_NextEnd

M ForIupV2V \
  %S \
  @MV2V %2 %1 \
  :_%V_ForTop \
  @PUSHI %3 \
  @CMPI %1 @POPNULL \
  @JMPC _%V_NextEnd \
  @JMPZ _%V_NextEnd


M ForIdownV2V \
  %S \
  @MV2V %2 %1 \
  :_%V_ForTop \
  @PUSHI %1 \
  @CMPI %3 @POPNULL \
  @JMPN _%V_NextEnd \
  @JMPZ _%V_NextEnd


M Next \
  @INCI %1 \
  @JMP _%V_ForTop \
  :_%V_NextEnd \
  %P
M NextBy \
  @PUSH %2 \
  @ADDI %1 \
  @POPI %1 \
  @JMP _%V_ForTop \
  :_%V_NextEnd \
  %P
M NextByI \
  @PUSHI %2 \
  @ADDI %1 \
  @POPI %1 \
  @JMP _%V_ForTop \
  :_%V_NextEnd \
  %P

  

  
