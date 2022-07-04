# Showing nested loops
I common.mc
#
# Lets do some simple nested loops.
#
# First lets introduce some new convince macros
#   MC2M and MM2M
#
# MC2M should be read as "Move Constant to Memory"
# MM2M should be read as "Move Memory to Memory"
# They are basically combining the PUSH value POPI label sequence into one macro
#
# Initialize Outerloop index to zero
@MC2M 0 OuterIndex
#
# While the outerloop is less than 20 continue
:OuterLoopBody
@PUSHI OuterIndex
@CMP 20
@POPNULL
@JMPZ ExitOuterLoop
@PRTI OuterIndex
@PRT "> "
#  Inner Loop Initialize  
  @MC2M 0 InnerIndex
  # While InnerIndex is less than 30 continue
  :InnerLoopBody
  @PUSHI InnerIndex
  @CMP 30
  @POPNULL
  @JMPZ ExitInnerLoop
      @PRTI InnerIndex
      @PRT " "
      # Increment the innerLoop index
      @INCI InnerIndex
      @JMP InnerLoopBody
  :ExitInnerLoop
  @PRTNL
  @INCI OuterIndex
  @JMP OuterLoopBody
:ExitOuterLoop
@PRTNL
@PRTLN "End of First Nested Loops"
#
# Now this is such a common type of loop, that we have provided some Macros to simplify it.
# We have two macros
#    ForIfA2B which can be read as:
#          For Index from Constant A to Constant B
#  There is also a version where A and B are variables named:
#    ForIfV2V
#
# Both these macros are paired with another set of macros which marks the END of the for loop
#    NextNamed        < This is the basic Increment index by one each loop.
#    NextStep         < This allows you to change the step size of the increment, even negative steps.
#
# The parameters for the ForIfA2B are:
#   @ForIfA2B Index Start##  Stop## Symbol
#       Index is a label with storage for a 16 bit integer
#       the Start## and Stop## are just constant numbers
#       The tricky one is 'Symbol' its like a Label but has no value.
#        And MUST be unique to that given loop in the current file. Do not reused elsewhere in src.
#        It just has to match the same Symbol passed the NextNamed macro.
#        This 'ties' the two macros together as beginning and end of loop, while allowing nesting.
# The ForIfV2V is nearly identical except the Stop and Stop ##'s are labels that point to where
#     the start and stop values are stored.
#
# The NamedNext Macro parameters are:
#     @NamedNext Index Symbol
# Both the Index label and the Symbol must match the ones used in the original For macro
#
#  Here how we can do the same output as the first nested loop example above:
@ForIfA2B OuterIndex 0 20 OuterForLoop
   @PRTI OuterIndex @PRT "> "
   @ForIfA2B InnerIndex 0 30 InnerForLoop
      @PRTI InnerIndex @PRT " "
   @NextNamed InnerIndex InnerForLoop
   @PRTNL
@NextNamed OuterIndex OuterForLoop
#
# A common thing is to have an index which must increment by 2 rather than 1
# This is useful when we are using an index to point to a list of words rather
# than bytes. As each word takes up two bytes, we need to increment by 2 rather than 1
# Note how we also are introducing the concept of adding a simple constant (+100) to
# a label. Our For loop here is going to go from start of SrcMemory to SrcMemory+100
@MC2M DstMemory DstPointer
# By using a step of '2' this loop will only go 50 rather than 100 times.
@ForIfV2V SrcPointer SrcMemory SrcMemory+100 BlockCopyLoop
  @PUSHII SrcPointer
  @POPII DstPointer
  @INC2I DstPointer        # INC2I is just like INCI but adds 2 each time.
@NextStep SrcPointer 2 BlockCopyLoop

@END
:InnerIndex 0
:OuterIndex 0
:SrcMemory
# Here are 100 bytes of data
"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
:DstMemory
# Here are just 100 blank spaces to reserve the space
"                                                                                                    "
