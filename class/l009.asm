# Showing nested loops
I common.mc
#
# Lets do some simple nested loops.
#
# First lets introduce some new convience macros
#   MA2V and MV2V
#
# MA2V should be read as "Move Constant to Variable"
# MV2V should be read as "Move Variable to Variable"
# These macros exist to hide the stack, but not eliminate it.
# They still compile into a PUSH value POPI variable sequence internally.
#
# Initilize Outerloop index to zero
@MA2V 0 OuterIndex
#
# While the outerloop is less than 20 continue
:OuterLoopBody
@PUSHI OuterIndex
@CMP 20
@POPNULL
@JMPZ ExitOuterLoop
@PRTI OuterIndex
@PRT "> "
#  Inner Loop Initilize  
  @MA2V 0 InnerIndex
  # While InnerIndex is less than 30 continue
  :InnerLoopBody
  @PUSHI InnerIndex
  @CMP 30
  @POPNULL
  @JMPZ ExitInnerLoop
      @PRTI InnerIndex
      @PRT " "
      # Incriment the innerLoop index
      @INCI InnerIndex
      @JMP InnerLoopBody
  :ExitInnerLoop
  @PRTNL
  @INCI OuterIndex
  @JMP OuterLoopBody
:ExitOuterLoop
@PRTNL
@PRTLN "End of First Nested Loops"
@END
:InnerIndex 0
:OuterIndex 0

