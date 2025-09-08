I common.mc
L lmath.ld
:Var1Ptr Var1
:Var2Ptr Var2
=Var2 Var3
:Var3Ptr Var3
=Var3 Var5
:Var4Ptr Var4
=Var4 Var7
:Var5Ptr Var5
=Var5 Var9
#
:Word1 0
:Word2 0
:Word3 0

:Main . Main

:Init
@MOVE32AV $$$100 Var1
@MOVE32AV $$$1000 Var2
@MOVE32AV $$$200 Var3
@MOVE32AV $$$2000 Var4
@MOVE32AV $$$0 Var5
@JMP SkipForward
:Begin
@CALL PrintVals
@PRT "\n------------------\nADD\n"
@PRT "VVV " @ADD32VVV Var1 Var2 Var5 @CALL PrintVals
@PRT "VVI " @ADD32VVI Var1 Var2 Var5Ptr @CALL PrintVals
@PRT "VIV " @ADD32VIV Var1 Var2Ptr Var5 @CALL PrintVals
@PRT "VII " @ADD32VII Var1 Var2Ptr Var5Ptr @CALL PrintVals
@PRT "IVV " @ADD32IVV Var1Ptr Var2 Var5 @CALL PrintVals
@PRT "IVI " @ADD32IVI Var1Ptr Var2 Var5Ptr @CALL PrintVals
@PRT "IIV " @ADD32IIV Var1Ptr Var2Ptr Var5 @CALL PrintVals
@PRT "III " @ADD32III Var1Ptr Var2Ptr Var5Ptr @CALL PrintVals
@PRT "\n------------------\nSUB\n"
@PRT "VVV " @SUB32VVV Var1 Var2 Var5 @CALL PrintVals
@PRT "VVI " @SUB32VVI Var1 Var2 Var5Ptr @CALL PrintVals
@PRT "VIV " @SUB32VIV Var1 Var2Ptr Var5 @CALL PrintVals
@PRT "VII " @SUB32VII Var1 Var2Ptr Var5Ptr @CALL PrintVals
@PRT "IVV " @SUB32IVV Var1Ptr Var2 Var5 @CALL PrintVals
@PRT "IVI " @SUB32IVI Var1Ptr Var2 Var5Ptr @CALL PrintVals
@PRT "IIV " @SUB32IIV Var1Ptr Var2Ptr Var5 @CALL PrintVals
@PRT "III " @SUB32III Var1Ptr Var2Ptr Var5Ptr @CALL PrintVals
@PRT "\n------------------\nMUL\n"
@PRT "VVV " @MUL32VVV Var1 Var2 Var5 @CALL PrintVals
@PRT "VVI " @MUL32VVI Var1 Var2 Var5Ptr @CALL PrintVals
@PRT "VIV " @MUL32VIV Var1 Var2Ptr Var5 @CALL PrintVals
@PRT "VII " @MUL32VII Var1 Var2Ptr Var5Ptr @CALL PrintVals
@PRT "IVV " @MUL32IVV Var1Ptr Var2 Var5 @CALL PrintVals
@PRT "IVI " @MUL32IVI Var1Ptr Var2 Var5Ptr @CALL PrintVals
@PRT "IIV " @MUL32IIV Var1Ptr Var2Ptr Var5 @CALL PrintVals
@PRT "III " @MUL32III Var1Ptr Var2Ptr Var5Ptr @CALL PrintVals
@PRT "\n------------------\nDIV\n"
@PRT "Divsion works better with diffrent base values\n"
@MOVE32AV $$$100123 Var1
@MOVE32AV $$$25 Var2
@PRT "Division also puts MOD value into Var5\n"
@PRT "VVVV " @DIV32VVVV Var1 Var2 Var4 Var5 @CALL PrintVals
@PRT "VVIV " @DIV32VVIV Var1 Var2 Var4Ptr Var5 @CALL PrintVals
@PRT "VIVV " @DIV32VIVV Var1 Var2Ptr Var4 Var5 @CALL PrintVals
@PRT "VIIV " @DIV32VIIV Var1 Var2Ptr Var4Ptr Var5 @CALL PrintVals
@PRT "IVVV " @DIV32IVVV Var1Ptr Var2 Var4 Var5 @CALL PrintVals
@PRT "IVIV " @DIV32IVIV Var1Ptr Var2 Var4Ptr Var5 @CALL PrintVals
@PRT "IIVV " @DIV32IIVV Var1Ptr Var2Ptr Var4 Var5 @CALL PrintVals
@PRT "IIIV " @DIV32IIIV Var1Ptr Var2Ptr Var4Ptr Var5 @CALL PrintVals


@PRT "For Boolen Math resetting AVar and BVar to \n0xCCCCCCCC and 0x77777777 which partly overlap\n"
@MOVE32AV $$$0xcccccccc Var1
@MOVE32AV $$$0x77777777 Var2
@PRT "\n------------------\nAND\n"
@PRT "VVV " @AND32VVV Var1 Var2 Var5 @CALL PrintHexVals
@PRT "VVI " @AND32VVI Var1 Var2 Var5Ptr @CALL PrintHexVals
@PRT "VIV " @AND32VIV Var1 Var2Ptr Var5 @CALL PrintHexVals
@PRT "VII " @AND32VII Var1 Var2Ptr Var5Ptr @CALL PrintHexVals
@PRT "IVV " @AND32IVV Var1Ptr Var2 Var5 @CALL PrintHexVals
@PRT "IVI " @AND32IVI Var1Ptr Var2 Var5Ptr @CALL PrintHexVals
@PRT "IIV " @AND32IIV Var1Ptr Var2Ptr Var5 @CALL PrintHexVals
@PRT "III " @AND32III Var1Ptr Var2Ptr Var5Ptr @CALL PrintHexVals
@PRT "\n------------------\nOR\n"
@PRT "VVV " @OR32VVV Var1 Var2 Var5 @CALL PrintHexVals
@PRT "VVI " @OR32VVI Var1 Var2 Var5Ptr @CALL PrintHexVals
@PRT "VIV " @OR32VIV Var1 Var2Ptr Var5 @CALL PrintHexVals
@PRT "VII " @OR32VII Var1 Var2Ptr Var5Ptr @CALL PrintHexVals
@PRT "IVV " @OR32IVV Var1Ptr Var2 Var5 @CALL PrintHexVals
@PRT "IVI " @OR32IVI Var1Ptr Var2 Var5Ptr @CALL PrintHexVals
@PRT "IIV " @OR32IIV Var1Ptr Var2Ptr Var5 @CALL PrintHexVals
@PRT "III " @OR32III Var1Ptr Var2Ptr Var5Ptr @CALL PrintHexVals
#
@PRT "\n------------------Functions 16 with 32 (WL) family\nADDWL\n"
@MA2V 1 Word1
@MA2V 30000 Word2
@MA2V -1 Word3
@MOVE32AV $$$1 Var1
@MOVE32AV $$$1000 Var2
@MOVE32AV $$$0 Var3
@PRT "Initial: "
@CALL PrintMixZVals
@PRT "\n-------------------\nADDWL\n"
@PRT "ADDWLAV 1 Var1 " @ADDWLAV 1 Var1 @CALL PrintMixZVals
@PRT "ADDWLIV Word2 Var1 " @ADDWLIV Word2 Var1 @CALL PrintMixZVals
@PRT "ADDWLAI 200 Var1Ptr " @ADDWLAI 200 Var1Ptr @CALL PrintMixZVals
@PRT "ADDWLII Word2 Var1Ptr " @ADDWLII Word2 Var1Ptr @CALL PrintMixZVals
@PRT "\n-------------------\nSUBWL\n"
@MA2V 1 Word1
@MA2V 30000 Word2
@MA2V -1 Word3
@MOVE32AV $$$1 Var1
@MOVE32AV $$$1000 Var2
@MOVE32AV $$$0 Var3
@PRT "Initial: "
@CALL PrintMixZVals
@PRT "SUBWLAV 1 Var1 " @SUBWLAV 1 Var1 @CALL PrintMixZVals
@PRT "SUBWLIV Word2 Var1 " @SUBWLIV Word2 Var1 @CALL PrintMixZVals
@PRT "SUBWLAI 200 Var1Ptr " @SUBWLAI 200 Var1Ptr @CALL PrintMixZVals
@PRT "SUBWLII  Word2 Var1Ptr " @SUBWLII Word2 Var1Ptr @CALL PrintMixZVals
@PRT "\n-------------------\nMULWL\n"
@MA2V 1 Word1
@MA2V 30000 Word2
@MA2V -1 Word3
@MOVE32AV $$$1 Var1
@MOVE32AV $$$1000 Var2
@MOVE32AV $$$0 Var3
@PRT "Initial: "
@CALL PrintMixZVals
@PRT "MULWLAV 4 Var1 " @MULWLAV 4 Var1 @CALL PrintMixZVals
@PRT "MULWLIV Word1 Var1 " @MULWLIV Word1 Var1 @CALL PrintMixZVals
@PRT "MULWLAI 25 Var1Ptr " @MULWLAI 25 Var1Ptr @CALL PrintMixZVals
@PRT "MULWLII Word2 Var1Ptr " @MULWLII Word2 Var1Ptr @CALL PrintMixZVals
:SkipForward
@PRT "\n-------------------\nDIVWL\n"
@MA2V 5 Word1
@MA2V 300 Word2
@MA2V 10 Word3
@MOVE32AV $$$150 Var1
@MOVE32AV $$$400 Var2
@MOVE32AV $$$101 Var3
@PRT "Initial: "
@CALL PrintMixZVals
:Break1
@PRT "DIVWLAV 650 Var1 " @DIVWLAV 4 Var1 Var2 @CALL PrintMixZVals
@PRT "DIVWLIV Word1 Var1 " @DIVWLIV Word1 Var1 Var2 @CALL PrintMixZVals
@PRT "DIVWLAI 25 Var1Ptr " @DIVWLAI 25 Var1Ptr Var2 @CALL PrintMixZVals
@PRT "DIVWLII Word2 Var1Ptr " @DIVWLII Word2 Var1Ptr Var2 @CALL PrintMixZVals

@END








:PrintVals
@PRT "\nVar1: " @PRT32 Var1
@PRT " Var2: " @PRT32 Var2
@PRT " Var3: " @PRT32 Var3
@PRT " Var4: " @PRT32 Var4
@PRT " Var5: " @PRT32 Var5
@PRTNL
@RET
:PrintHexVals
@PRT "\nVar1: " @PRTHEXI Var1 @PRTHEXI Var1+2
@PRT " Var2: " @PRTHEXI Var2 @PRTHEXI Var2+2
@PRT " Var3: " @PRTHEXI Var3 @PRTHEXI Var3+2
@PRT " Var4: " @PRTHEXI Var4 @PRTHEXI Var4+2
@PRT " Var5: " @PRTHEXI Var5 @PRTHEXI Var5+2
@PRTNL
@RET
:PrintMixZVals
@PRT "\nVar1: " @PRT32 Var1
@PRT " Var2: " @PRT32 Var2
@PRT " Var3: " @PRT32 Var3
@PRT " Word1: " @PRTI Word1
@PRT " Word2: " @PRTI Word2
@PRT " Word3: " @PRTI Word3
@PRTNL
@RET



