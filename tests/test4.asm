I common.mc
:Loop
@PRTLN "Subtraction Tests:"
@PRT " B:"
@PRTI BVAL
@PRT " - "
@PRT "A:"
@PRTI AVAL
@PRT " = "
@PRTI CVAL
@PRTNL
@MA2V 0 CMDCODE
@PRTLN "1:Change A. 2: Change B: 3: Quit,  else: Calc "
@PROMPT "CMD> " CMDCODE
@PUSHI CMDCODE
@CMP 1
@JMPZ ChangeA
@CMP 2
@JMPZ ChangeB
@CMP 3
@JMPZ Quit
@POPNULL
@PUSHI AVAL
@PUSHI BVAL
@DEBUGTOGGLE
@SUBS
@DEBUGTOGGLE
@POPI CVAL
@JMPO OverFlow
:Oreturn
@JMPC Carry
@JMP Loop
:OverFlow
@PRTLN "OverFlow Flag"
@JMP Oreturn
:Carry
@PRTLN "Carry Flag"
@JMP Loop
:ChangeA
@POPNULL
@PROMPT "New A:" AVAL
@JMP Loop
:ChangeB
@POPNULL
@PROMPT "New B:" BVAL
@JMP Loop
:Quit
@END


:CMDCODE
0
:AVAL
0
:BVAL
0
:CVAL
0
