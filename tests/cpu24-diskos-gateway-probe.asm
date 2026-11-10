# Experimental gateway with private DS/CS and a shared fixed software stack.
M UseSoftStackDS 1
.CODE 0
.ORG 0x0100
.DATA 1
I commonDS.mc

::AppValue 0x5678
MF DiskDDS %EVAL {HIGH_BANK}+1

:Main
.ENTRY Main
@PUSH 1 @SSET SegDS @PUSH 1 @ADM
@DSSInitABS 3 0xf000 0xe000
@PUSH 4 @SSET SegES
@CALL DiskGateway
@PRT "result=" @PRTHEXTOP @POPNULL
@PRT " DS=" @SGET SegDS @PRTHEXTOP @POPNULL
@PRT " ES=" @SGET SegES @PRTHEXTOP @POPNULL
@PRT " DDS=" @PUSH {DiskDDS} @PRTHEXTOP @POPNULL
@PRT " app=" @PUSHI AppValue @PRTHEXTOP @POPNULL @PRTNL
@PUSH 0 @ADM @END

:DiskGateway
@DSSPushReturn
@SGET SegDS @DSSPushHW
@SGET SegES @DSSPushHW
@SGET SegDS @SSET SegES
@PUSH {DiskDDS} @SSET SegDS
@PUSH AppValue @FCALL {DiskDDS} DiskProbe
@PUSHI PrivateValue
@DSSPopHW @SSET SegES
@DSSPopHW @SSET SegDS
@DSSPopReturn
@RET

.DATA {DiskDDS}
::PrivateValue 0x1234
::ReturnPC 0
::ReturnCS 0
.CODE {DiskDDS}
.ORG 0x1000
:DiskProbe
@POPI ReturnPC @POPI ReturnCS
@DUP @ESO @PUSHS @POPI PrivateValue
@PUSH 0xbeef @SWP @ESO @POPS
@PUSHI ReturnCS @PUSHI ReturnPC
@FJMPS
