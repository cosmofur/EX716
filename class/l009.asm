# Showing nested loops
I common.mc
#
# Lets do some simple nested loops.
#
# First lets introduce some new convience macros
#   MC2M and MM2M
#
# MC2M should be read as "Move Constant to Memory"
# MM2M should be read as "Move Memory to Memory"
# They are basicly combining the PUSH value POPI label sequence into one macro
#
# Initilize Outerloop index to zero
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
#  Inner Loop Initilize  
  @MC2M 0 InnerIndex
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

