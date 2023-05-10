# Test the DIV functions
I common.mc
:Main . Main	
L div.ld
@ForIA2B AA -10 10
  @PRTNL @PRT "Testing AA:" @PRTSGNI AA @PRTLN " Divided by 1 - 10" 
  @ForIA2B BB 1 10
    @PUSHI AA @PUSHI BB @CALL DIV
    @DUP @POPI DD @PRTSGNI DD  @PRT ","	
    @ADDI CC @POPI CC
    @POPNULL
  @Next BB
@Next AA
@PRTNL
@PRT "CheckSum:" @PRTI CC
@END
:AA 0
:BB 0
:CC 0
:DD 0
