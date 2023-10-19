# Provides and Alternative small software stack
# Used mostly so some simple low depth recursion can avoid reusing fixed storage
#
# @PUSHRETURN at the top of a function saves the passed return address
# @POPRETURN restores it, and should be the last macro call before @RET
# @PUSHLOCAL VarName, does same for a named variable. Allowing 'local' use.
# @POPLOCAL restore it at end of function....
# IF YOU HAVE MULTIPLE LOCAL VARIABLES, PUSH and POP in REVERSE Order!
#   ie) PUSHLOCAL A, PUSHLOCAL B ...... POPLOCAL B, POPLOCAL A
#
# You can also consider PUSHRETURN and POPRETURN as a way to save the top of HW stack
# and restore it later.
#
! SOFTSTACK_DONE
M SOFTSTACK_DONE 1
@JMP SkipSoftStack
G PUSHRETURN  G POPRETURN G RETSTACKMAX G ReturnStackSP G ReturnStack
:ReturnStackSP 0
:ReturnStack
= RETSTACKMAX 32
. ReturnStack+64     # 32 16b values is current limit of stack size.

# PUSHRETURN Moves the TOS to the local ReturnStack
# Errors if depth grows over RETSTACKMAX
M PUSHRETURN \
   @PUSH RETSTACKMAX @CMPI ReturnStackSP @POPNULL \
   @JMPZ StackFull%0 \
      @PUSH ReturnStack \
      @ADDI ReturnStackSP \
      @POPS \
      @INC2I ReturnStackSP \
   @JMP NextCmd%0 \
      :StackFull%0 @PRTLN "ERROR: Code Stack Full"  @END \
   :NextCmd%0

# PUSHs the Top of ReturnStack to HW Stack
# Errors if Depth is already zero
M POPRETURN \
  @PUSH 0 @CMPI ReturnStackSP @POPNULL \
  @JMPZ StackEmpty%0 \
  @DEC2I ReturnStackSP \
  @PUSHI ReturnStackSP @ADD ReturnStack @PUSHS \
  @JMP NextCmd%0 \
  :StackEmpty%0 @PRTLN "ERROR: Code Stack Empty" @END \
  :NextCmd%0
M PUSHLOCAL \
   @PUSH RETSTACKMAX @CMPI ReturnStackSP @POPNULL \
   @JMPZ StackFull%0 \
      @PUSHI %1 \
      @PUSH ReturnStack \
      @ADDI ReturnStackSP \
      @POPS \
      @INC2I ReturnStackSP \
   @JMP NextCmd%0 \
      :StackFull%0 @PRTLN "ERROR: Code Stack Full"  @END \
   :NextCmd%0
M POPLOCAL \
  @PUSH 0 @CMPI ReturnStackSP @POPNULL \
  @JMPZ StackEmpty%0 \
  @DEC2I ReturnStackSP \
  @PUSHI ReturnStackSP @ADD ReturnStack @PUSHS \
  @POPI %1 \
  @JMP NextCmd%0 \
  :StackEmpty%0 @PRTLN "ERROR: Code Stack Empty" @END \
  :NextCmd%0  
  
:SkipSoftStack
ENDBLOCK
