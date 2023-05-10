# Test the random libary
I common.mc
L random.ld
:Seed 0
:High 0
:Result 0
:Low 0x4000
:Index 0
:Main . Main
@PRT "Set Random Seed: "
@READI Seed
@PUSHI Seed
@CALL rndsetseed
@PRT "Random: "
@ForIA2B Index 0 1000
  @PUSH 1000
  @CALL rndint
  @POPI Result
  @PUSHI Result
  @PUSHI High
  @IF_GT_S
     @MM2M Result High
  @ENDIF
  @POPNULL @POPNULL
  @PUSHI Result
  @PUSHI Low
  @IF_LT_S
     @MM2M Result Low
  @ENDIF
  @POPNULL @POPNULL
  @PRTI Result @PRT ","
@Next Index
@PRTNL
@PRT "Range High: " @PRTI High @PRT " Low:" @PRTI Low
@PRTNL
@END


	
