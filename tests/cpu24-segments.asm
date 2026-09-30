# cpu24.py interprets .DATA as an 8-bit bank number. Data labels remain
# 16-bit offsets while their bytes are emitted into that physical bank.
.DATA 1
I commonDS.mc
::BankValue 0x1234

.ORG 0x0100
:Main
@PUSH 1
@ADM

@PRT "DS value: "
@PUSHI BankValue
@PRTHEXTOP
@POPNULL
@PRTNL
@PRT "DS direct: "
@PRTHEXI BankValue
@PRTNL

@PUSH 2
@SSET SegES
@PUSH 0xbeef
@ESO @POPI 0x0200

@PRT "ES value: "
@ESO @PUSHI 0x0200
@PRTHEXTOP
@POPNULL
@PRTNL

@PRT "DS bank: "
@SGET SegDS
@PRTHEXTOP
@POPNULL
@PRTNL

@PUSH 0
@ADM
@END
