# Test the MUL function
I common.mc
L mul.ld
@ForIA2B AA -10 11
  @PRTNL @PRT "Multiply " @PRTSGNI AA @PRT " by -10 - +10: "
  @ForIA2B BB -10 11
    @PUSHI AA @PUSHI BB @CALL MUL
    @DUP @POPI DD @PRTSGNI DD @PRT ","
    @ADDI CC @POPI CC
  @Next BB
@Next AA
@PRTNL
@PRT "CheckSum:" @PRTI CC
@END
:AA 0
:BB 0
:CC 0
:DD 0
