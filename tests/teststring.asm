I common.mc
I string.asm

@ForIfA2B Index 0x7fff 0x8001 MainForLoop
  @PUSH StringInfo
  @PUSHI Index
  @PUSH 10  
  @CALL itos
  @PRT "From: "
  @PRTS StringInfo
  @PUSH StringInfo
  @CALL stoi
  @PRT " To: "
  @PRTTOP
  @PRTNL
  @POPNULL
@NextStep Index 1 MainForLoop
@END
:Index 0
:StringInfo
0 0 0 0 0 0 0 0 0 0
