############################################################
# Lesson 10 — Structured Programming in EX716
#
# This lesson builds directly on:
#   Lesson 4 — Manual control flow using CMP, flags, and JMP
#   Lesson 7 — The standard library and structure.asm
#
# No new CPU features are introduced here.
# Everything shown expands into ordinary JMP-based assembly.
############################################################

I common.mc

############################################################
# Why Structured Macros Exist
############################################################
#
# In Lesson 4, we wrote loops and conditionals by hand using:
#   CMP
#   hardware flags (Z, N, O, C)
#   explicit JMP instructions
#   many labels
#
# That style is powerful, but it forces the programmer to manage
# multiple concerns at once:
#   - remembering which flags mean what
#   - signed vs unsigned comparisons
#   - creating and tracking labels
#
# Structured macros exist to ORGANIZE this logic,
# not to replace it.
#
# They expand into the same JMP-based code you have already written.
# There is no runtime cost and no hidden behavior.
#
# All structured macros are defined in:
#   lib/structure.asm
#
# This file is included automatically by:
#   I common.mc
#
# You are encouraged to read structure.asm.
#

############################################################
# A Critical Idea: Macro Grammar
############################################################
#
# Structured macros encode their logic in their NAMES.
#
# General form:
#
#   @<STRUCTURE>_<TEST>_<ARGUMENT_PATTERN> arguments...
#
# This grammar is the SAME suffix system introduced in Lesson 4:
#
#   _A   constant
#   _V   variable
#   _AV  constant + variable
#   _VV  variable + variable
#
# Signed vs unsigned tests are still explicit:
#   LT   signed less-than
#   ULT  unsigned less-than
#
# The stack is still real.
# Most tests begin with the Top Of Stack (TOS).
#

############################################################
# Section 1 — IF / ELSE / ENDIF
############################################################
#
# IF blocks replace short JMP-based conditionals.
#
# Manual version (Lesson 4 style):
#

@PUSHI Count
@CMP 10
@POPNULL
@JMPZ EndIf
    @PRTLN "Count is not 10"
:EndIf

#
# Structured version:
#

@PUSHI Count
@IF_NEQ_A 10
    @PRTLN "Count is not 10"
@ENDIF

#
# Notes:
# - The IF macro creates the labels internally
# - The CMP and flag logic still exists after macro expansion
#

############################################################
# Common IF Tests
############################################################
#
# Flag-based tests:
#   IF_ZFLAG, IF_NOTZF
#   IF_NEG, IF_POS
#   IF_OVERFLOW, IF_NOTOVER
#   IF_CARRY, IF_NOTCARRY
#
# Value-based tests (most common):
#   IF_ZERO, IF_NOTZERO
#   IF_EQ_A, IF_NEQ_A
#   IF_LT_V, IF_GE_V
#   IF_ULT_A, IF_UGE_V
#   IF_INRANGE_AV
#
# Example: compare two variables
#

@IF_EQ_VV Avar Bvar
    @PRTLN "Avar equals Bvar"
@ENDIF

############################################################
# Section 2 — WHILE / ENDWHILE
############################################################
#
# WHILE macros follow the SAME grammar as IF,
# but repeat until the condition fails.
#
# Manual loop (Lesson 4 style):
#

@PUSH 0
@POPI Index

:LoopStart
@PUSHI Index
@CMP 5
@POPNULL
@JMPZ LoopEnd
    @PRTI Index
    @PRT " "
    @INCI Index
    @JMP LoopStart
:LoopEnd
@PRTNL

#
# Structured version:
#

@PUSH 0
@POPI Index

@WHILE_LT_A 5
    @PRTI Index
    @PRT " "
    @INCI Index
@ENDWHILE
@PRTNL

#
# WHILE is simply:
#   an IF
#   whose jump target is the top of the block
#

############################################################
# Section 3 — FOR Loops (Convenience Macros)
############################################################
#
# FOR loops are NOT fundamental.
# They are convenience macros built on WHILE and CMP logic.
#
# Use them when the loop pattern is obvious.
#

############################################################
# FOR: exact match exit
############################################################

# Loop Index from 0 to 9 (exit when Index == 10)
@ForIA2B Index 0 10
    @PRTI Index
    @PRT " "
@Next Index
@PRTNL

#
# This expands into:
#   initialization
#   comparison
#   increment
#   conditional jump
#

############################################################
# FOR: >= exit (Up variants)
############################################################
#
# Use these when the index may cross the limit.
#

@ForIupA2B Index 0 10
    @PRTI Index
    @PRT " "
@Next Index
@PRTNL

#
# The only difference is the comparison test.
#

############################################################
# Section 4 — SWITCH / CASE (Advanced)
############################################################
#
# SWITCH replaces cascaded IF / ELSE chains.
# It does not introduce new execution behavior.
#

@PUSHI Mode
@SWITCH
@CASE 0
    @PRTLN "Mode 0"
    @CBREAK
@CASE 1
    @PRTLN "Mode 1"
    @CBREAK
@CDEFAULT
    @PRTLN "Unknown mode"
    @CBREAK
@ENDCASE

#
# Notes:
# - @CDEFAULT is REQUIRED
# - SWITCH expands into comparisons and jumps
#

############################################################
# Final Notes
############################################################
#
# Structured macros:
#   - do NOT remove the stack
#   - do NOT remove flags
#   - do NOT add safety checks
#
# They exist to make intent visible and reduce label clutter.
#
# If you are ever unsure what a structured macro does:
#   open lib/structure.asm and read it.
#
############################################################

@END

:Count 0
:Avar  0
:Bvar  0
:Index 0
:Mode  0
