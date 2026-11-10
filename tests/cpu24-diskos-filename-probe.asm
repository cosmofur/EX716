# Prototype copying a UDS filename to DDS. No DiskOS file is opened here.
M UseSoftStackDS 1
.CODE 0
.ORG 0x0100
.DATA 1
I commonDS.mc
::UserFilename "TEST.TXT\0"
MF DiskDDS %EVAL {HIGH_BANK}+1

:Main
.ENTRY Main
@PUSH 1 @SSET SegDS @PUSH 1 @ADM
@DSSInitABS 3 0xf000 0xe000
@PUSH 4 @SSET SegES
@CALL FilenameGateway
@PRT " DS=" @SGET SegDS @PRTHEXTOP @POPNULL
@PRT " ES=" @SGET SegES @PRTHEXTOP @POPNULL @PRTNL
@PUSH 0 @ADM @END

:FilenameGateway
@DSSPushReturn
@SGET SegDS @DSSPushHW
@SGET SegES @DSSPushHW
@SGET SegDS @SSET SegES
@PUSH {DiskDDS} @SSET SegDS
@PUSH UserFilename @FCALL {DiskDDS} CopyFilename
@PRT "filename="
@IF_EQ_AV 1 Status @PRTSI NamePtr @ELSE @PRT "<invalid>" @ENDIF
@PRT " status=" @PUSHI Status @PRTTOP @POPNULL
@DSSPopHW @SSET SegES
@DSSPopHW @SSET SegDS
@DSSPopReturn @RET

.DATA {DiskDDS}
::NameBuffer $$0 * 32
::NamePtr NameBuffer
::Source 0
::Destination 0
::Remaining 0
::Status 0
::ReturnPC 0
::ReturnCS 0
.CODE {DiskDDS}
.ORG 0x1000
:CopyFilename
@POPI ReturnPC @POPI ReturnCS @POPI Source
@MA2V NameBuffer Destination
@MA2V 32 Remaining
@MA2V 0 Status
:CopyNext
@PUSHI Source @IF_EQ_A 0xffff @POPNULL @JMP CopyDone @ENDIF @POPNULL
@PUSHI Source @ESO @PUSHS @AND 0xff
@PUSHII Destination @AND 0xff00 @ORS @POPII Destination
@PUSHII Destination @AND 0xff
@IF_ZERO
   @POPNULL @MA2V 1 Status @JMP CopyDone
@ENDIF
@POPNULL
@INCI Source @INCI Destination @DECI Remaining
@IF_EQ_AV 0 Remaining @JMP CopyDone @ENDIF
@JMP CopyNext
:CopyDone
@PUSHI ReturnCS @PUSHI ReturnPC @FJMPS
