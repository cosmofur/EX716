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


# Utility function use to keep two values in low to high order.
# Ensures (%1, %2) such that %1 <= %2 Both must be variable lables, not constants.
M QuickMinI @PUSHI %1 @PUSHI %2 @IF_GT_S @SWP @POPI %2 @POPI %1 @ELSE @POPNULL @POPNULL @ENDIF
# Variation that accepts constant as one of the values.
M QuickMinAI @PUSH %1 @PUSHI %2 @IF_GT_S @SWP @POPI %2 @POPI %1 @ELSE @POPNULL @POPNULL @ENDIF

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
M IF_NEQ_S \
  @CMPS \
  %S \
  @JMPZ _%V_ENDIF
# IF_EQ_A (A) = True if A == TOS
M IF_EQ_A \
  %S \
  @CMP %1 \
  @JMPZ _%0_True \
  @JMP _%V_ENDIF \
  :_%0_True
M IF_NEQ_A \
  %S \
  @CMP %1 \
  @JMPZ _%V_ENDIF
# IF_EQ_V (V) = True if [V] == TOS
M IF_EQ_V \
  @PUSHI %1 \
  @CMPS @POPNULL \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
M IF_NEQ_V \
  @PUSHI %1 \
  %S \
  @CMPS @POPNULL \
  @JMPZ _%V_ENDIF
# If V1 == V2 True
M IF_EQ_VV \
  @PUSHI %1 @PUSHI %2 \
  @CMPS @POPNULL @POPNULL \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
M IF_NEQ_VV \
  @PUSHI %1 @PUSHI %2 \
  %S \
  @CMPS @POPNULL @POPNULL \
  @JMPZ _%V_ENDIF

# If A == V1 True
M IF_EQ_VA \
  @PUSHI %1 @PUSH %2 \
  @CMPS @POPNULL @POPNULL \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
M IF_NEQ_VA \
  @PUSHI %1 @PUSH %2 \
  %S \
  @CMPS @POPNULL @POPNULL \
  @JMPZ _%V_ENDIF
# Reverse for readability
M IF_EQ_AV \
  @PUSH %1 @PUSHI %2 \
  @CMPS @POPNULL @POPNULL \
  @JMPZ _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
M IF_NEQ_AV \
  @PUSH %1 @PUSHI %2 \
  %S \
  @CMPS @POPNULL @POPNULL \
  @JMPZ _%V_ENDIF
# Signed Greater Than and Less Than conditions
#
# IF_LT_S (A,B)=True if value at SFT(A) < TOS(B)
M IF_LT_S \
   %S \
   @CMPS \
   @JGE _%V_ENDIF
# IF_LT_A (A) = True if TOS is < A
M IF_LT_A \
   %S \
   @CMP %1 \
   @JGE _%V_ENDIF
#
M IF_LT_V \
   %S \
   @CMPI %1 \
   @JGE _%V_ENDIF
#
# IF_LE_S (A,B)=True if SFT(A) <= TOS(B)
M IF_LE_S \
  %S \
  @CMPS \
  @JGT _%V_ENDIF
# IF_LE_A (A) = True if TOS is <=A
M IF_LE_A \
  %S \
  @CMP %1 \
  @JGT _%V_ENDIF
# IF_LE_V V = True if TOS is <=V
M IF_LE_V \
  %S \
  @CMPI %1 \
  @JGT _%V_ENDIF
# IF_GE_S will A(SFT) >= B(TOS)
M IF_GE_S \
   %S \
   @CMPS \
   @JLT _%V_ENDIF
# True if TOS >= A
M IF_GE_A \
   %S \
   @CMP %1 \
   @JLT _%V_ENDIF
# True if TOS >= V
M IF_GE_V \
   %S \
   @CMPI %1 \
   @JLT _%V_ENDIF
# True if TOS > A
M IF_GT_S \
  %S \
  @CMPS \
  @JLE _%V_ENDIF
# True if TOP > A
M IF_GT_A \
  %S \
  @CMP %1 \
  @JLE _%V_ENDIF
# True if TOS > V
M IF_GT_V \
  %S \
  @CMPI %1 \
  @JLE _%V_ENDIF
#
# Signed Range Conditonals

M IF_INRANGE_AB \
  %S \
  @PUSH %1 @CMPS @POPNULL \
  @JLT _%V_ENDIF \
  @PUSH %2 @CMPS @POPNULL \
  @JGT _%V_ENDIF \
  :_%0_True
M IF_INRANGE_AV \
  %S \
  @CMP %1 \
  @JLT _%V_ENDIF \
  @CMPI %2 \
  @JGT _%V_ENDIF \
  :_%0_True
M IF_INRANGE_VA \
  %S \
  @CMPI %1 \
  @JLT _%V_ENDIF \
  @CMP %2 \
  @JGT _%V_ENDIF \
  :_%0_True
M IF_INRANGE_VV \
  %S \
  @CMPI %1 \
  @JLT _%V_ENDIF \
  @CMPI %2  \
  @JGT _%V_ENDIF \
  :_%0_True
#
# Unsigned Range Conditionals
M IF_UINRANGE_AB \
  %S \
  @PUSH %1 @CMPS @POPNULL \
  @JULT _%V_ENDIF \
  @PUSH %2 @CMPS @POPNULL \
  @JUGT _%V_ENDIF \
  :_%0_True
M IF_UINRANGE_AV \
  %S \
  @CMP %1 \
  @JULT _%V_ENDIF \
  @CMPI %2 \
  @JUGT _%V_ENDIF \
  :_%0_True
M IF_UINRANGE_VA \
  %S \
  @CMPI %1 \
  @JULT _%V_ENDIF \
  @CMP %2 \
  @JUGT _%V_ENDIF \
  :_%0_True
M IF_UINRANGE_VV \
  %S \
  @CMPI %1 \
  @JULT _%V_ENDIF \
  @CMPI %2  \
  @JUGT _%V_ENDIF \
  :_%0_True


#
# Unsigned Logic follows here
#
# IF_ULT_S (A,B)=True if value at SFT(A) < TOS(B)
M IF_ULT_S \
   %S \
   @CMPS         \
   @JUGE _%V_ENDIF
# IF_ULT_A (A) = True if TOS is < A
M IF_ULT_A \
   %S \
   @CMP %1 \
   @JUGE _%V_ENDIF
#
M IF_ULT_V \
    %S \
   @CMPI %1 \
   @JUGE _%V_ENDIF
#
# IF_ULE_S (A,B)=True if SFT(A) <= TOS(B)
M IF_ULE_S \
  %S \
  @CMPS \
  @JUGT _%V_ENDIF
# IF_ULE_A (A) = True if TOS is <=A
M IF_ULE_A \
  %S \
  @CMP %1 \
  @JUGT _%V_ENDIF
# IF_ULE_V V = True if TOS is <=V
M IF_ULE_V \
  %S \
  @CMPI %1 \
  @JUGT _%V_ENDIF
# IF_UGE_S will A(SFT) >= B(TOS)
M IF_UGE_S \
   %S \
   @CMPS \
   @JLT _%V_ENDIF
# True if TOS >= A
M IF_UGE_A \
   %S \
   @CMP %1 \
   @JULT _%V_ENDIF
# True if TOS >= V
M IF_UGE_V \
   %S \
   @CMPI %1 \
   @JULT _%V_ENDIF
# True if TOS > A
M IF_UGT_S \
  %S \
  @CMPS \
  @JULE _%V_ENDIF
# True if TOP > A
M IF_UGT_A \
  %S \
  @CMP %1 \
  @JULE _%V_ENDIF
# True if TOS > V
M IF_UGT_V \
  %S \
  @CMPI %1 \
  @JULE _%V_ENDIF
##########################################################
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
  @JMPO _%V_ENDIF
# Jum if Carry set
M IF_CARRY \
  @JMPC _%0_True \
  %S @JMP _%V_ENDIF \
  :_%0_True
#
M IF_NOTCARRY \
  %S \
  @JMPC _%V_ENDIF \
  :_%0_True


 
#
# ELSE is common to all the IF type blocks.
# Note how if we fall into the ELSE block from the code right above.
# It jumps right to the 'JustEnd' label. We do the same thing for ENDIF
# We also set with MF a _%V_E lseFlag so correctly nested ENDIF will know if
# an 'else' was in effect or not.
M ELSE \
  @JMP _%V_JustEnd \
  MF _%V_ELSEUSED 1 \   
  :_%V_ENDIF ;

M ENDIF \
  :_%V_JustEnd \
  IFNDEF _%V_ELSEUSED \
     :_%V_ENDIF \
  ENDBLOCK \
  %P ;
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
  @JLE _%V_ExitLoop \
  :_%0_True

M WHILE_GE_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JLT _%V_ExitLoop \
  :_%0_True

M WHILE_GT_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JLE _%V_ExitLoop \
  :_%0_True

M WHILE_GE_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JLT _%V_ExitLoop \
  :_%0_True

M WHILE_LT_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JGE _%V_ExitLoop \
  :_%0_True

M WHILE_LE_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JGT _%V_ExitLoop \
  :_%0_True

M WHILE_LT_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JGE _%V_ExitLoop \
  :_%0_True

M WHILE_LE_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JGT _%V_ExitLoop \
  :_%0_True

M WHILE_UGT_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JULE _%V_ExitLoop \
  :_%0_True

M WHILE_UGT_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JULE _%V_ExitLoop \
  :_%0_True

M WHILE_ULT_A \
  %S \
  :_%V_LoopTop \
  @CMP %1 \
  @JUGE _%V_ExitLoop \
  :_%0_True
  
M WHILE_ULT_V \
  %S \
  :_%V_LoopTop \
  @CMPI %1 \
  @JUGE _%V_ExitLoop \
  :_%0_True
#
# When Do Loop are very much like While Loops but have a fixed place for a multi
# line conditional logic. WHEN Code DO_ZERO or DO_NOTZERO ENDWHEN
# Code can be multiple lines, just it leaves a 0 or a non-zero to contol
# execution between Do and ENDWHEN
# WHEN is good for cases where there no existing WHILE condition prewired.
# Its important to remember the condition block will leave a condition value
# on the stack, that will need to be POPNULL 'ed to keep the stack from growing.
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
  @JMP _%W_LoopTop

M WHILEBREAK \
@JMP _%W_ExitLoop


M FORBREAK \
  @JMP _%W_NextEnd

M FORCONTINUE \
  @JMP _%W_NextEnd

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
# SWITCH / CASE structured macro set
#
# This implements a simple 16-bit numeric switch/case construct.
#
# Usage pattern:
#
#   @PUSH value
#   @SWITCH
#      @CASE SOME_CONSTANT
#         ... case body ...
#         @CBREAK
#
#      @CASE_RANGE LOW HIGH
#         ... case body ...
#         @CBREAK
#
#      @CDEFAULT
#         ... default body ...
#         @CBREAK
#   @ENDCASE
#
# Important rules:
#
#   1. The switch test value must already be on TOS before @SWITCH.
#
#   2. Each @CASE compares against that TOS value.
#      The compare consumes/reuses the stack according to the CMP macro behavior,
#      so each CASE macro uses %S to preserve the switch frame while testing.
#
#   3. CASE bodies do not intentionally fall through like C.
#      A matching CASE body should end with @CBREAK, which jumps to @ENDCASE.
#
#   4. CASE_RANGE and CASE_URANGE test inclusive ranges.
#      If the value is outside the range, they jump to the shared NextCase label.
#      If the value is inside the range, execution falls through into the case body.
#
#   5. @CDEFAULT is required to provide the final NextCase label and to keep the
#      macro stack balanced. Use it even when all values appear to be covered.
#
#   6. @ENDCASE closes the switch macro frame opened by @SWITCH.
#
# Label conventions:
#
#   %V refers to the current preserved switch/case macro frame.
#   %W refers to the base switch frame used by @CBREAK to jump to EndCase.
#   %0 is unique to the current macro invocation and should be used for labels
#      local to a single CASE expansion.
#
# The normal CASE macro uses a unique %0-based DoCase label so multiple CASE
# macros in the same SWITCH do not collide.
#
M SWITCH \
  =_%0_CaseCount 0 \
  =_%0_BreakCount 0 \
  %S

M CASE \
  =_%V_CaseCount  {_%V_CaseCount}+1 \
  %S \
  @CMP %1 \  
  @JMPZ _%0_DoCase1 \
  @JMP _%V_NextCase \
  :_%0_DoCase1


M CASE_RANGE_AA \
  =_%V_CaseCount {_%V_CaseCount}+1 \  
  @CMP %1 \
  %S \
  @JLT _%V_NextCase \
  @CMP %2 \
  @JGT _%V_NextCase
  # Fall Through True Case

M CASE_RANGE @CASE_RANGE_AA %1 %2
M CASE_RANGE_AV \
  =_%V_CaseCount {_%V_CaseCount}+1 \  
  @CMP %1 \
  %S \
  @JLT _%V_NextCase \
  @CMPI %2 \
  @JGT _%V_NextCase
  # Fall Through True Case
M CASE_RANGE_VA \
  =_%V_CaseCount {_%V_CaseCount}+1 \  
  @CMPI %1 \
  %S \
  @JLT _%V_NextCase \
  @CMP %2 \
  @JGT _%V_NextCase
  # Fall Through True Case
M CASE_RANGE_VV \
  =_%V_CaseCount {_%V_CaseCount}+1 \  
  @CMPI %1 \
  %S \
  @JLT _%V_NextCase \
  @CMPI %2 \
  @JGT _%V_NextCase 
  # Fall Through True Case


# range tests in the Unsigned CASE. Other wise we could miss the edge cases.
M CASE_URANGE_AA \
  =_%V_CaseCount {_%V_CaseCount}+1 \  
  @CMP %1 \
  %S \
  @JULT _%V_NextCase \
  @CMP %2 \
  @JUGT _%V_NextCase
  # Fall Through True Case
M CASE_URANGE @CASE_URANGE_AA %1 %2
M CASE_URANGE_AV \
  =_%V_CaseCount {_%V_CaseCount}+1 \  
  @CMP %1 \
  %S \
  @JULT _%V_NextCase \
  @CMPI %2 \
  @JUGT _%V_NextCase
  # Fall Through True Case

M CASE_URANGE_VA \
  =_%V_CaseCount {_%V_CaseCount}+1 \  
  @CMPI %1 \
  %S \
  @JULT _%V_NextCase \
  @CMP %2 \
  @JUGT _%V_NextCase
  # Fall Through True Case
  
M CASE_URANGE_VV \
  =_%V_CaseCount {_%V_CaseCount}+1 \  
  @CMPI %1 \
  %S \
  @JULT _%V_NextCase \
  @CMPI %2 \
  @JUGT _%V_NextCase
  # Fall Through True Case  

# Compares TOS with value at [%1] 
M CASE_V \
  =_%V_CaseCount {_%V_CaseCount}+1 \
  %S \
  @CMPI %1 \
  @JMPNZ _%V_NextCase
  # Fall Through True Case  
#
# @CDEFAULT starts the default body.
#
# It defines the shared NextCase label used by the final failed CASE test.
# Since there is no comparison, execution reaches CDEFAULT only when no earlier
# CASE matched, or when control explicitly falls through to the final default.
#
# @CDEFAULT also preserves the switch frame with %S so @CBREAK and @ENDCASE
# can continue using the same stack convention as normal CASE bodies.
#
M CDEFAULT \
  :_%V_NextCase \
  =_%V_CaseCount {_%V_CaseCount}+1 \
  %S
 

#
# @CBREAK ends the current CASE body.
#
# It emits two things:
#
#   1. A jump to the switch-level EndCase label, so a matched CASE does not
#      continue into later CASE bodies.
#
#   2. The shared NextCase label for the previous failed CASE test.
#
# After defining NextCase, %P restores the macro stack back to the switch frame
# so the next CASE/CDEFAULT/ENDCASE sees the correct %V/%W context.
#
# Every non-empty CASE body should normally end with @CBREAK.
#

M CBREAK \
  @JMP _%W_EndCase \                 # Jump the BASE frame's END_CASE
  :_%V_NextCase \
  %P \                               # Back to BASE frame
  =_%V_BreakCount {_%V_BreakCount}+1
#
# @CASE_FALLTHRU is an alternative to CBREAK
# finish this case block, but resume testing/executing at the next case boundary instead of exiting the switch
M CASE_FALLTHRU \
  :_%V_NextCase \
  %P \
  =_%V_BreakCount {_%V_BreakCount}+1

# End Case provides a target for, the %P is there to pop the %S from SWITCH

M ENDCASE \
  :_%V_EndCase \
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
#
#  ForIA2B Index    : 3 Args For from constant A to Constant B
#  ForIA2V Index    : 3 Args For from constant A to Variable
#  ForIV2A Index    : 3 Args For from Variable to Constant A
#  ForIV2V Index    : 3 Args For From Variable to Variable
#  ForIA2S Index    : 2 Args For from Constant to value on TOS
#  Next Index       : 1 Args must match Index name from For Loop (Inc var is default +1)
#  NextBy Index A   : 2 Args Index name and Increment value, which can be negative
#  NextByI Index V  : 2 Args Index name and variable for increment
#  NextByV Index V  : 2 Args Index name and variable for increment ( both I and V are legal here)
#                       Just make sure that Index will eventually equal the stop value.
#             For cases when your lookint to stop loop when index is >= stop value.
# All For Termination tests are Unsigned, so not sutitble if range includes negative numbers.
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
  @JMPNC _%V_NextEnd \
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
  @JMPNC _%V_NextEnd \
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
  @JMPNC _%V_NextEnd \
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
  @JMPNC _%V_NextEnd \
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
  @JMPNC _%V_NextEnd \
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
M NextByV @NextByI %1 %2
  

  
