I common.mc
@MC2M 0 StartA
@MC2M 30000 StartB
@MC2M 30000 StopA
@MC2M 40000 StopB
@MC2M 1000 StepA
@MC2M 2000 StepB

@PUSHI StartA @POPI VarA
@PUSHI StartB @POPI VarB
:LOOP

@PUSHI VarA @CMPI StopA @POPNULL
@JMPZ EndALoop
@PUSHI VarB @CMPI StopB @POPNULL
@JMPZ EndBLoop


@PRT "Compair A:" @PRTHEXI VarA @PRTSP @PRTBIN VarA
@PRT " To B:" @PRTHEXI VarB @PRTSP @PRTBIN VarB @PRT " Flags: "
@PUSHI VarA @PUSHI VarB @CMPS @POPNULL @POPNULL
@JMPZ ZSet
  @PRT "-"
  @JMP Skip1
:ZSet
  @PRT "Z"
:Skip1
@JMPN NSet
  @PRT "-"
  @JMP Skip2
:NSet
  @PRT "N"
:Skip2
@JMPO OSet
  @PRT "-"
  @JMP Skip3
:OSet
  @PRT "O"
:Skip3
@JMPC CSet
  @PRT "-"
  @JMP Skip4
:CSet
  @PRT "C"
:Skip4
@PRTNL
@PUSHI VarA @PUSHI StepA @ADDS @POPI VarA
@JMP LOOP
:EndALoop
@PUSHI StartA @POPI VarA
@PRT "Resetting A"
@PUSHI VarB @PUSHI StepB @ADDS @POPI VarB
@JMP LOOP
:EndBLoop
@PRT "Final"
@END

:VarA 0
:VarB 0
:StartA 0
:StartB 0
:StepA 0
:StepB 0
:StopA 0
:StopB 0
