I common.mc
@PRTLN "Try to add 32bit numbers"
@MC2M 0xff00 LowPartA
@MC2M 0 HighPartA
@MC2M 0x99 LowPartB
@MC2M 0 HighPartB
@MC2M 500 Idx
:LOOP
@PRT "A:"
@PRTHEXI HighPartA
@PRTHEXI LowPartA
@PRT " B:"
@PRTHEXI HighPartB
@PRTHEXI LowPartB
@PRTNL
@PUSHI LowPartA
@PUSHI LowPartB
@ADDS
@PUSHI HighPartA
@JMPNC NoCarryBit
@PUSH 1
@ADDS
:NoCarryBit
@PUSHI HighPartA
@ADDS
@POPI ResultHigh
@POPI ResultLow
@PRT "Result:"
@PRTHEXI ResultHigh
@PRTHEXI ResultLow
@PRTNL
@INCI LowPartB
@DECI Idx
@JNZ LOOP
@END
:LowPartA 0
:HighPartA 0
:LowPartB 0
:HighPartB 0
:ResultLow 0
:ResultHigh 0
:Idx 0
