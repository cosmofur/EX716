I common.mc
L div.ld
@ForIfA2B TopVal -100 100 Outer1
  @ForIfA2B BotVal 1 25 Inner1
    @PUSHI TopVal
    @PUSHI BotVal
    @CALL DIV
    @POPI Result
    @POPI Remainder
#    @PRTSGN TopVal @PRT " / " @PRTSGN BotVal @PRT " = "
#    @PRTSGN Result    @PRT " With "    @PRTSGN Remainder
#    @PRTLN " Left over"
@NextNamed BotVal Inner1
@NextNamed TopVal Outer1
@END
:TopVal 0
:BotVal 0
:Result 0
:Remainder 0




