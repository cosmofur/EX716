# Provides and Alternative small software stack

# Used mostly so some simple low depth recursion can avoid reusing fixed storage
#
# This provides a Software stack which can be larger than the built in hardware stack.
# The default is 'only' 240 bytes long and suttbale for 120 2 byte words, but you can
# redefine any block of memory to be a new software stack.
#
# Main public  Macros are:
#
#  PUSHHW        - POP's HW stack and Pushes it to Software stack
#  PUSHRETURN    - Same, but syntaticily clear is meant to store the Return Address of functions
#  PUSHLOCAL     - PUSH's the value constant to Software Stack
#  PUSHLOCALI    - PUSH's the value of a [variable] to Software Stack
#  PUSHLOCALII   - PUSH the value of a [[variable]] to software state (usefull if trying to push an item in array)
#  PUSHLOCAL     - PUSH's a constant (or lable address) to software stack
#
#  POPHW         - POP's SoftwareStack and PUSHS it onto the HW stack
#  POPRETURN     - Same, but syntaticly clear is meant to recover the Return address of functions
#  POPLOCAL      - POP's Software stack to variable
#                This is really POPLOCALI because in pure form POPLOCAL would make no sense as you can't
#                pop a value to a 'constant'
#  POPLOCALII    - POP's SW stack to [variable] for arrays
#  TOPLOCAL      - Puts on HW stack value at top of SW stack, without pop'ing it.
#
# For basic usage,
#   The goal of the these tools is to allow 'local' variables to work in a semi-natural way.
#   PUSHRETURN saves the previous passed in return address in a non-unique storage
#   PUSHLOCALI VARNAME, saves the current values of the var name so it can be used in recursion.
#   POPLOCAL VARNAME, restores the previous value of the Variable from the stack (make sure order is reversed)
#   POPRETURN Restores the Return Addres to the HW stack so the next @RET will work.
#

#
# There are also some public Functions, which the Macro's above use.
# __MOVE_SS_HW    - Soft Stack to Hardware stack
# __MOVE_HW_SS   - Hardware Stack to Soft Stack
#
# The global variables __SS_TOP __SS_SP __SS_BOTTOM can be queried but should be treated as read only
# To change them use the SaveSSStack and RestoreSSStack functions.
#
# The three SSS function SetSSStack, SaveSSStack and RestoreSSStack are for managing whre
# stacks are stored in memory, and offers a way to manage multiple stacks. 
#
#  SetSSStack(TopAddress,BottomAddress)
! SOFTSTACK_DONE
M SOFTSTACK_DONE 1
@JMP SkipSoftStack
#
# Global key Soft Stack Values
G __SS_TOP
G __SS_BOTTOM
G __SS_SP
G __MOVE_HW_SS
G __MOVE_SS_HW
G SetSSStack
G __SS_StackError
G SaveSSStack
G RestoreSSStack


:__SS_TOP 0xfff0   # Default stack is top of mem 0xff00 to 0xfff0 about 240 bytes
:__SS_SP 0xfff2    # The First time we push, we dec SP to TOP
:__SS_BOTTOM 0xff00

#
# Define PUSHRETURN
M PUSHRETURN @CALL __MOVE_HW_SS
M PUSHHW @CALL __MOVE_HW_SS
M PUSHLOCALI @PUSHI %1 @CALL __MOVE_HW_SS
M PUSHLOCALII @PUSHII %1 @CALL __MOVE_HW_SS
M PUSHLOCAL @PUSH %1 @CALL __MOVE_HW_SS
# Function __MOVE_HW_SS
#  Pushes top of HW Stack to SoftStack
:__MOVE_HW_SS
@PRTHEXTOP @PRTSP
@PUSHI __SS_SP
@IF_ULT_V __SS_BOTTOM
   @POPNULL
   @PRT "PUSH:"
   @StackDump   
   @JMP __SS_StackError
@ENDIF
@POPNULL
@SWP
@DEC2I __SS_SP      # After a PUSH mem[__SS_SP] is value of TOP
#@PRT "Soft PUSH Mem[" @PRTHEXI __SS_BOTTOM @PRT "/" @PRTHEXI __SS_SP @PRT "/" @PRTHEXI __SS_TOP @PRT "]:"
#@PRTHEXTOP  @PRTNL
@POPII __SS_SP

@RET
#
#
M POPRETURN @CALL __MOVE_SS_HW
M POPHW @CALL __MOVE_SS_HW
M POPLOCAL @CALL __MOVE_SS_HW @POPI %1
M POPLOCALII @CALL __MOVE_SS_HW @POPII %1
M TOPLOCAL @PUSHII __SS_SP
# Function __MOVE_SS_HW
# POPS top of Softstack onto HW Stack
:__MOVE_SS_HW
@PUSHI __SS_SP
@IF_UGT_V __SS_TOP
   @POPNULL
   @PRT "POP:"
   @StackDump
   @JMP __SS_StackError
@ENDIF
@POPNULL
#@PRT "Soft Pop Mem[" @PRTHEXI __SS_BOTTOM @PRT "/" @PRTHEXI __SS_SP @PRT "/" @PRTHEXI __SS_TOP @PRT "]:"
@PUSHII __SS_SP
#@PRTHEXTOP @PRTNL
@INC2I __SS_SP
@SWP
@RET
#
# Function
# Sets the Stack storage to a new range of memory.
# This initilizes the stack, save/set the global __SS_SP if you need to preserve data
# SetSSStack(TopAddress,BottomAddress)
:SetSSStack
@SWP
@POPI __SS_BOTTOM
@SWP
@SUB 2     # We need a one word buffer for the empty case
@POPI __SS_TOP
@MV2V __SS_TOP __SS_SP
@INC2I __SS_SP
@RET
#
# Function
# SaveSSStack(IDStore)
# With an eye on managing multiple stacks, this function will save
# the TOP,BOTTOM and SP to a 6 byte strutucture pointed to by IDStore.
:SaveStack
@SWP       # It would be self defeating if SaveStack used the stack for temp storage.
# Top of Stack holds address of IDStore, we'll need it three times.
@DUP @DUP
# [return, IDStore,IDStore,IDStore]
@PUSHI __SS_TOP
@SWP      # Poiunt to where we store 'TOP'
@POPS
# [return, IDStore, IDStore]
@ADD 2    # Point to where we store 'Bottom'
@PUSHI __SS_BOTTOM
@SWP
@POPS
# [ return, IDStore]
@ADD 4   # Point to where we store 'SP'
@PUSHI __SS_SP
@SWP
@POPS
# [return]
@RET
#
# Function
# RestoreSSStack(IDStore)
# With an eye on managing multiple stacks, this funciton will restore from
# previous 'SAVE' TOP, BOTTOM and SP from a 6 byte structure pointed to by IDSTORE
:RestoreStack
@SWP
# We'll need IDStore 3 times.
@DUP @DUP
# [return, IDStore IDStore, IDStore]
@PUSHS
@POPI __SS_TOP
# [return, IDStore IDStore]
@ADD 2
@PUSHS
@POPI __SS_BOTTOM
# [return, IDStore ]
@ADD 4
@PUSHS
@POPI __SS_SP
# [return]
@RET
# The Following macros are to make the Stack manipulation functions follow I and A rules.
#
# 1) @SetSStackAB Lable1(Highval) Label2(LowVal)
M SetSSStackAB @PUSH %1 @PUSH %2 @CALL SetSSStack
# 2) @SetSStackAS Label1 INT_SIZE_In_Bytes
M SetSSStackAS @PUSH %1+%2 @PUSH %1 @CALL SetSSStack
# 3) @SetSStackIS Label-Pointer INT_SIZE_IN_Bytes
M SetSSStackIS @PUSHI %1 @ADD %2 @PUSHI %1 @CALL SetSSStack
# 3) @SaveSSStackA Label(6 bytes storage)
M SaveSSStackA @PUSH %1 @CALL SaveSSStack
# 4) @SaveSSStackI Lable-Pointer (ptr to 6 bytes storage)
M SaveSSStackI @PUSHI %1 @CALL SaveSSStack
# 5) @RestoreSSStackA Label (6 bytes storage)
M RestoreSSStackA @PUSH %1 @CALL RestoreSSStack
# 6) @RestoreSSStackI Label-Pointer (6 bytes storage)
M RestoreSSStackI @PUSHI %1 @CALL RestoreSSStack


#
# Standard Stack Error handler, exits on any error
# 
:__SS_StackError
@PRTLN "Error. Code Stack Out of Bounds"
@END


:SkipSoftStack
ENDBLOCK
