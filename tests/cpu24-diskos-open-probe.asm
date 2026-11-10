# Experimental open/close. Static gateway state, heap and stack ranges are
# fixed for the test; this is not a reentrant or reusable DiskOSDS interface.
.CODE 0
.ORG 0x0100
.DATA 1
I commonDS.mc
# This isolated executable owns these dependencies; it is not a reusable API.
# Library size diagnostics assume CS0 and are disabled for this probe.
M SIZESINCE
::UserName "EXISTS.TXT\0"
::MissingName "MISSING.TXT\0"
::UserHandle 0
::UserSentinel 0x7777
::InitStatus 0
::FindResult 0
::FileInfo $$0 * 38
L diskosDS.ld
.CODE 0
:Main
.ENTRY Main
@PUSH 1 @ADM @PUSH 1 @SSET SegDS
# The caller owns the fixed software stack. Place a live sentinel on it before
# entering DiskOS; the service must use this stack without resetting its root.
@DSSInitABS 3 0xf000 0xe000
@PUSH 3 @SSET SegES
@PUSH 0xabcd @PUSH 0xeffe @ESO @POPS
@PUSH 0xeffe @PUSH __DSS_SP @ESO @POPS
@PUSH 4 @SSET SegES
@PUSH 0 @FCALL {DiskDDS} DiskOSInit @POPI InitStatus
@PRT "init=" @PUSHI InitStatus @PRTTOP @POPNULL @PRTNL
@PUSH 0 @FCALL {DiskDDS} DiskOSInit @POPI InitStatus
@PRT "initrepeat=" @PUSHI InitStatus @PRTTOP @POPNULL @PRTNL
@PUSH 1 @FCALL {DiskDDS} DiskOSInit @POPI InitStatus
@PRT "initmismatch=" @PUSHI InitStatus @PRTTOP @POPNULL @PRTNL
@FCALL {DiskDDS} DiskOSLastError
@PRT "initerror=" @PRTTOP @POPNULL @PRTNL
@PUSH 0 @FCALL {DiskDDS} DiskOSInit @POPI InitStatus
@PUSH UserName @PUSH 1 @FCALL {DiskDDS} DiskOSFind @POPI FindResult
@PRT "find=" @PUSHI FindResult @PRTTOP @POPNULL @PRTNL
@IF_NEQ_AV 0 FindResult
   @PUSHI FindResult @PUSH FileInfo @FCALL {DiskDDS} DiskOSGetInfo
   @PRT "info=" @PRTTOP @POPNULL
   @PRT " info-file=" @PUSHI FileInfo @PRTTOP @POPNULL
   @PUSH FileInfo+6 @CALL strlen @POPI InitStatus
   @PRT " info-len=" @PUSHI InitStatus @PRTTOP @POPNULL @PRTNL
   @PUSH FileInfo+6 @PUSH UserName @CALL strcmp @POPI InitStatus
   @PRT " info-strcmp=" @PUSHI InitStatus @PRTTOP @POPNULL @PRTNL
@ENDIF
@PUSH MissingName @PUSH 1 @FCALL {DiskDDS} DiskOSFind
@PRT "findmissing=" @PRTTOP @POPNULL @PRTNL
@PUSH UserName @PUSH DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen
@POPI UserHandle
@PRT "result=" @PUSHI UserHandle @PRTTOP @POPNULL
@PRT " DS=" @SGET SegDS @PRTHEXTOP @POPNULL
@PRT " ES=" @SGET SegES @PRTHEXTOP @POPNULL @PRTNL
@IF_NEQ_AV 0 UserHandle
   @PUSHI UserHandle @FCALL {DiskDDS} DiskOSClose
   @PRT "close=" @PRTTOP @POPNULL @PRTNL
   @PUSH UserName @PUSH DISKOS_OPEN_READ @FCALL {DiskDDS} DiskOSOpen @POPI UserHandle
   @PRT "reopen=" @PUSHI UserHandle @PRTTOP @POPNULL @PRTNL
   @PUSHI UserHandle @FCALL {DiskDDS} DiskOSClose
   @PRT "reclose=" @PRTTOP @POPNULL @PRTNL
@ENDIF
@PRT "after DS=" @SGET SegDS @PRTHEXTOP @POPNULL
@PRT " ES=" @SGET SegES @PRTHEXTOP @POPNULL
@PRT " user=" @PUSHI UserSentinel @PRTHEXTOP @POPNULL @PRTNL
@PUSH 3 @SSET SegES
@PRT "stack=" @PUSH __DSS_SP @ESO @PUSHS @PRTHEXTOP @POPNULL
@PRT "/" @PUSH 0xeffe @ESO @PUSHS @PRTHEXTOP @POPNULL @PRTNL
@PUSH 0 @SSET SegES
@PRT "stackbank=" @PUSH __SS_ROOT_STACK_DS @ESO @PUSHS @PRTHEXTOP @POPNULL @PRTNL
@PUSH 0 @ADM @END
