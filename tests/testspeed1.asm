I common.mc
L mul.ld

# Do a tight loop for time tests

@PRTLN "Start Run PUSH POP 100,000 times"
@ForIfA2B Index1 1 4 OuterLoop
  @ForIfA2B Index2 1 25000 InnerLoop
   @PUSH 1
   @POPNULL
  @NextNamed Index2 InnerLoop
@NextNamed Index1 OuterLoop

@PRTLN "End"
@END
:Scratch 0
:Index1 0
:Index2 0


