# Provides and Alternative small software stack
# Used mostly so some simple recursion can avoid reusing fixed storage
#
! SOFTSTACK_DONE
M SOFTSTACK_DONE 1
@JMP SkipSoftStack
G PUSHRETURN  G POPRETURN G RETSTACKMAX G ReturnStackSP G ReturnStack
:ReturnStackSP 0
:ReturnStack 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
= RETSTACKMAX 15

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
:SkipSoftStack
ENDBLOCK
