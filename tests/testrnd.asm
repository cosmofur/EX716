I common.mc
L random.asm
:MainLoop
@PRT "Enter Seed (999 to exit):"
@READI NewSeed
@PUSHI NewSeed @CMP 999 @POPNULL
@JMPZ ExitLoop
@PUSHI NewSeed
@CALL rndsetseed
@PRTLN "------------"
@ForIfA2B RndLoopCnt 1 10 RndLoopID
   @CALL rnd16
   @PRTTOP
   @PRTSP
   @POPNULL
@NextNamed RndLoopCnt RndLoopID
@JMP MainLoop
:ExitLoop
@END
:NewSeed 0
:RndLoopCnt 0

	
