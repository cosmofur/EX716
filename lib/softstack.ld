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
= RETSTACKMAX 32     # set to max number of 16b words on stack
. ReturnStack+64     # 2xRETSTACKMAX values is current limit of stack size in bytes
G PushStackError
:PushStackError
@PRTLN "Error. Code Stack Out of Bounds"
@END


# PUSHRETURN Moves the TOS to the local ReturnStack
# Errors if depth grows over RETSTACKMAX
M PUSHRETURN \
   @PUSH RETSTACKMAX @CMPI ReturnStackSP @POPNULL \
   @JMPZ PushStackError \
      @PUSH ReturnStack \
      @ADDI ReturnStackSP \
      @POPS \
      @INC2I ReturnStackSP
      
# PUSHs the Top of ReturnStack to HW Stack
# Errors if Depth is already zero
M POPRETURN \
  @PUSH 0 @CMPI ReturnStackSP @POPNULL \
  @JMPZ PushStackError \
  @DEC2I ReturnStackSP \
  @PUSHI ReturnStackSP @ADD ReturnStack @PUSHS

M PUSHLOCAL \
   @PUSH RETSTACKMAX @CMPI ReturnStackSP @POPNULL \
   @JMPZ PushStackError \
      @PUSHI %1 \
      @PUSH ReturnStack \
      @ADDI ReturnStackSP \
      @POPS \
      @INC2I ReturnStackSP

M POPLOCAL \
  @PUSH 0 @CMPI ReturnStackSP @POPNULL \
  @JMPZ PushStackError \
  @DEC2I ReturnStackSP \
  @PUSHI ReturnStackSP @ADD ReturnStack @PUSHS \
  @POPI %1 
  
:SkipSoftStack
ENDBLOCK
