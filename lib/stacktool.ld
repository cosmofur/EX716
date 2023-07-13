# Stacktool provides basic Stack like operations when the HW stack is too small.
! StackToolDef
M StackToolDef 1
#
#
# ST_INIT(size,storageptr): initilzied a stack of size*words at location starting at storageptr
#          returns a prt to the stack definition or SD
# ST_PUSH(SD,value)
# ST_POP(SD)
# ST_TOP(SD)
# ST_SWP(SD)
# ST_NTH(SD,Depth) Fetches the Nth Deep item from stack. Depth=0 same as TOP, Depth=1 == second from top
# ST_SIZEOF(SD)      Returns how many items in stack 0 == empty stack
G ST_INIT G ST_PUSH G ST_POP G ST_TOP G ST_SWP G ST_NTH G ST_SIZEOF
#
#
:ST_STORE 0
:ST_SIZE 0
:ST_VALUE 0
:ST_RETURN 0
:ST_SD 0
:ST_SDMAX 0
:ST_SDSP 0
#
#
# ST_INIT(size, ptr to storage)
# First two words store current stack size and max stack size
# Returns a pointer to 3rd word which is used as Stack defintion
:ST_INIT
@POPI ST_RETURN
@POPI ST_STORE
@POPI ST_SIZE
@PUSH 0 @POPII ST_STORE # [SD-4]=SP
@PUSHI ST_SIZE @INC2I ST_STORE @POPII ST_STORE # [SD-2] = SIZE
@INC2I ST_STORE  # SD=Storage+4 
@PUSHI ST_STORE
@PUSHI ST_RETURN
@RET
#
# ST_PUSH(SD,Value) will insert Value into SD Stack. Errors is overflow.
:ST_PUSH
@POPI ST_RETURN
@POPI ST_VALUE
@POPI ST_SD
# This will be common in most of the ST functions, get the meta data stored before the SD data
@PUSHI ST_SD @SUB 2 @PUSHS  # [SD-2] = SIZE
@POPI ST_SIZE
@PUSHI ST_SD @SUB 4 @PUSHS   # [SD-4] = SP
@POPI ST_SDSP
# 
@PUSHI ST_SDSP
@IF_GE_V ST_SIZE
   @POPNULL
   @PRT "Error: SD Library Stack Overflow.\n"
   @PUSHI ST_RETURN
   @RET
@ENDIF
@ADDI ST_SD
@PUSHI ST_VALUE
@SWP        # POPS uses value,address so swap them
@POPS 
@INC2I ST_SDSP             # We're using words so Inc and Dec by two
@PUSHI ST_SDSP @PUSHI ST_SD @SUB 4 @POPS  # Put updated SP back into meta data
@PUSHI ST_RETURN
@RET
#
#
# ST_POP(SD) returns top of stack, and removes it, errors if empty
#
:ST_POP
@POPI ST_RETURN
@POPI ST_SD
# This will be common in most of the ST functions, get the meta data stored before the SD data
@PUSHI ST_SD @SUB 2 @PUSHS  # [SD-2] = SIZE
@POPI ST_SIZE
@PUSHI ST_SD @SUB 4 @PUSHS   # [SD-4] = SP
@POPI ST_SDSP
# 
@PUSHI ST_SDSP
@IF_ZERO
   @POPNULL
   @PRT "Error: SD Library Stack Underflow.\n"
   @PUSH 0
   @PUSHI ST_RETURN
   @RET
@ENDIF
@SUB 2
@DUP
@ADDI ST_SD
@PUSHS               # Push [SD+SP]
@SWP                 # We want to save the new SP, which is behind the top value on the stack
@PUSHI ST_SD @SUB 4 @POPS  # Put updated SP back into meta data
@PUSHI ST_RETURN
@RET
#
#
# ST_TOP, is basicly same as ST_POP except we don't save the change to SP
:ST_TOP
@POPI ST_RETURN
@POPI ST_SD
# This will be common in most of the ST functions, get the meta data stored before the SD data
@PUSHI ST_SD @SUB 2 @PUSHS  # [SD-2] = SIZE
@POPI ST_SIZE
@PUSHI ST_SD @SUB 4 @PUSHS   # [SD-4] = SP
@POPI ST_SDSP
# 
@PUSHI ST_SDSP
@IF_ZERO
   @POPNULL
   @PRT "Error: SD Library Stack Underflow.\n"
   @PUSH 0
   @PUSHI ST_RETURN
   @RET
@ENDIF
@SUB 2
@ADDI ST_SD
@PUSHS               # Push [SD+SP]
@PUSHI ST_RETURN
@RET
#
#
# ST_SWP reverse the TOP and Second From TOP, errors if there not at least two items in stack
:ST_SWP
@POPI ST_RETURN
@POPI ST_SD
# This will be common in most of the ST functions, get the meta data stored before the SD data
@PUSHI ST_SD @SUB 2 @PUSHS  # [SD-2] = SIZE
@POPI ST_SIZE
@PUSHI ST_SD @SUB 4 @PUSHS   # [SD-4] = SP
@POPI ST_SDSP
# 
@PUSHI ST_SDSP
@IF_LT_A 4                  # testing for 4 means lt 2 words on stack is an error.
   @POPNULL
   @PRT "Error: SD Library Stack Underflow.\n"
   @PUSH 0
   @PUSHI ST_RETURN
   @RET
@ENDIF
@SUB 2
@ADDI ST_SD
@PUSHS               # gets TOP
@PUSHI ST_SDSP
@SUB 4
@ADDI ST_SD
@PUSHS               # gets Second From Top. ST_SDSP still pointing here.
@PUSHI ST_SDSP
@SUB 2
@ADDI ST_SD
@POPS                # Puts old top where SFT was
@PUSHI ST_SDSP
@SUB 4
@ADDI ST_SD
@POPS
#
@PUSHI ST_RETURN
@RET
#
#
# ST_NTH(SD,Depth) Will fetch without modifying value at SD[Top-Depth]
:ST_NTH
@POPI ST_RETURN
@RTL               # We'll be using words so *2
@POPI ST_VALUE
@POPI ST_SD
@PUSHI ST_SD @SUB 2 @PUSHS  # [SD-2] = SIZE
@POPI ST_SIZE
@PUSHI ST_SD @SUB 4 @PUSHS   # [SD-4] = SP
@POPI ST_SDSP
#
@PUSHI ST_VALUE
@IF_GT_V ST_SDSP        # If SP < Depth, then invalied depth requested.
   @POPNULL
   @PRT "Error: SD Libaray Stack Underflow.\n"
   @PUSH 0
   @PUSHI ST_RETURN
   @RET
@ENDIF
@ADDI ST_SD
@PUSHS
# Not saving any changes to stack, so just return
@PUSHI ST_RETURN
@RET
#
#
# ST_SIZEOF(SP) returns size of stack....0 if empty
:ST_SIZEOF
@POPI ST_RETURN
@POPI ST_SD
# This will be common in most of the ST functions, get the meta data stored before the SD data
@PUSHI ST_SD @SUB 2 @PUSHS  # [SD-2] = SIZE
@POPI ST_SIZE
@PUSHI ST_SD @SUB 4 @PUSHS   # [SD-4] = SP
@POPI ST_SDSP
# 
@PUSHI ST_SDSP @RTR     # Size is in bytes, turn into words
@PUSHI ST_RETURN
@RET
ENDBLOCK
