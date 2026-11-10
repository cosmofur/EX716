# CPU24 DiskOSDS experimental service core.
# Requires commonDS.mc and a caller-initialized softstackDS stack.
# DDS is reserved at HIGH_BANK+1. This v0 core provides the external
# DiskOSInit, OpenGateway, CloseGateway, ReadGateway, WriteGateway and
# ErrorGateway entry points exercised by the DiskOSDS probes.

MF DiskDDS %EVAL {HIGH_BANK}+1
G DiskOSInit G DiskOSOpen G DiskOSClose G DiskOSRead G DiskOSWrite
G DiskOSTell G DiskOSSize G DiskOSTruncate G DiskOSFind G DiskOSGetInfo G DiskOSLastError
G DISKOS_OPEN_READ G DISKOS_OPEN_WRITE G DISKOS_OPEN_CREATE G DISKOS_OPEN_TRUNCATE G DISKOS_OPEN_APPEND
G DISKOS_E_NONE G DISKOS_E_BUSY G DISKOS_E_NOT_INITIALIZED G DISKOS_E_ARGUMENT
G DISKOS_E_RANGE G DISKOS_E_NOT_FOUND G DISKOS_E_NO_SPACE G DISKOS_E_BAD_HANDLE
G DISKOS_E_IO G DISKOS_E_CORRUPT G DISKOS_E_ALREADY_INITIALIZED G DISKOS_E_TOO_MANY_OPEN
=DISKOS_OPEN_READ     0x0001
=DISKOS_OPEN_WRITE    0x0002
=DISKOS_OPEN_CREATE   0x0004
=DISKOS_OPEN_TRUNCATE 0x0008
=DISKOS_OPEN_APPEND   0x0010
=DISKOS_E_NONE                 0
=DISKOS_E_BUSY                 1
=DISKOS_E_NOT_INITIALIZED      2
=DISKOS_E_ARGUMENT             3
=DISKOS_E_RANGE                4
=DISKOS_E_NOT_FOUND            5
=DISKOS_E_NO_SPACE             6
=DISKOS_E_BAD_HANDLE           7
=DISKOS_E_IO                   8
=DISKOS_E_CORRUPT              9
=DISKOS_E_ALREADY_INITIALIZED 10
=DISKOS_E_TOO_MANY_OPEN       11
.CODE {DiskDDS}
.ORG 0x1000
.DATA {DiskDDS}
::Reserved $$0 * 256
L softstackDS.ld
L heapmgrDS.ld
# DiskOS currently names the legacy heap API; its allocation and deletion
# calls have the same argument order and success conventions as these DS APIs.
=HeapNewObject HeapDSNewObject
=HeapDeleteObject HeapDSDeleteObject
L string.ld
L diskos.ld
::SavedCS 0
::SavedPC 0
::SavedDS 0
::SavedES 0
::Source 0
::Temp 0
::Remaining 0
::FileName $$0 * 32
::FileNameP FileName
::Heap 0
::Result 0
::RequestedDisk 0
::OpenMode MODE_RO
::LegacyMode MODE_RO
::ReadFlag 0
::WriteFlag 0
::CreateFlag 0
::TruncateFlag 0
::AppendFlag 0
::HandleTable $$0 * 64
::HandleIndex 0
::HandleSlot 0
::HandleGen 0
::IOFilePtr 0
::IOOut 0
::IOSizeLow 0
::IOSizeHigh 0
::FindStart 0
::InfoFileNum 0
::InfoOut 0
::InfoArg 0
::InfoBuffer 0
::InfoIndex 0
::InfoSource 0
::InfoTarget 0
::InfoResult 0
::Initialized 0
::IOHandle 0
::IOPtr 0
::IOCount 0
::IOTotal 0
::IOBuffer 0
::DiskDDSBank {DiskDDS}
::DiskBusy 0
::DiskLastError 0

# Far entry: save the caller segments, select DDS, and reject re-entry without
# touching the active operation's saved state. The rejection uses the shared
# stack to retain the caller's return pair while discarding its arguments.
M DiskFarEnter `\
 @SGET SegDS ; @SGET SegES ; @PUSH {DiskDDS} ; @SSET SegDS ; \
 @IF_NEQ_AV 0 DiskBusy ; \
    @MA2V 1 DiskLastError ; \
    @SSET SegES ; @SSET SegDS ; \
    @DSSPushHW ; @DSSPushHW ; \
    %REPEAT %1 ; @POPNULL ; %ENDR ; \
    @PUSH 0 ; @DSSPopHW ; @DSSPopHW ; @FJMPS ; \
 @ENDIF ; \
 @MA2V 1 DiskBusy \
`
M ResolveHandle `\
 @PUSHI IOHandle ; @IF_ZERO ; \
   @POPNULL @MA2V DISKOS_E_BAD_HANDLE DiskLastError @JMP %1 ; \
 @ENDIF ; @POPNULL ; \
 @PUSHI IOHandle @AND 0x000f @POPI HandleIndex ; \
 @PUSHI IOHandle @SHRN 4 @POPI HandleGen ; \
 @PUSHI HandleIndex @SHLN 2 @ADD HandleTable @POPI HandleSlot ; \
 @PUSHI HandleSlot @PUSHS @POPI IOFilePtr ; \
 @PUSHI IOFilePtr ; @IF_ZERO ; \
   @POPNULL @MA2V DISKOS_E_BAD_HANDLE DiskLastError @JMP %1 ; \
 @ENDIF ; @POPNULL ; \
 @PUSHI HandleSlot @ADD 2 @PUSHS ; \
 @IF_EQ_V HandleGen ; @POPNULL @JMP _%0_Resolved ; @ENDIF ; @POPNULL ; \
 @MA2V DISKOS_E_BAD_HANDLE DiskLastError @JMP %1 ; \
 :_%0_Resolved \
 @PUSHI IOFilePtr \
`
# DiskOSInit(disk_number): 1/0. Disk selection cannot change after init.
:DiskOSInit
@DiskFarEnter 1
@MA2V 0 DiskLastError
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS @POPI RequestedDisk
@MA2V 0 Result
@IF_NEQ_AV 0 Initialized
   @PUSHI RequestedDisk
   @IF_EQ_V FSDiskNumStore
      @POPNULL @MA2V 1 Result @JMP InitReturn
   @ENDIF
   @POPNULL
   @MA2V 10 DiskLastError
   @JMP InitReturn
@ENDIF
@PUSH 0x9000 @PUSH 0x5000 @CALL HeapDSDefineMemory @POPI Heap
@PUSHI Heap @IF_ULT_A 100
   @POPNULL @MA2V 6 DiskLastError @JMP InitReturn
@ENDIF
@POPNULL
@Call(V) SetDiskHeap Heap
@Call(V) FSReadHeader RequestedDisk
@IF_ZERO
   @POPNULL @MA2V 8 DiskLastError @JMP InitReturn
@ENDIF
@POPNULL
@MA2V 1 Initialized
@MA2V 1 Result
:InitReturn
@MA2V 0 DiskBusy
@PUSHI Result @PUSHI SavedCS @PUSHI SavedPC
@PUSHI SavedES @SSET SegES
@PUSHI SavedDS @SSET SegDS
@FJMPS

:OpenGateway
@DiskFarEnter 1
@MA2V 0 DiskLastError
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS @POPI Source
@MA2V DISKOS_OPEN_READ OpenMode
@JMP OpenFilenameCopy

# DiskOSOpen(UDS filename offset, open flags).
:DiskOSOpen
@DiskFarEnter 2
@MA2V 0 DiskLastError
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS
@POPI OpenMode @POPI Source

:OpenFilenameCopy
@PUSHI SavedDS @SSET SegES
@MA2V FileName Temp
@MA2V 32 Remaining
@MA2V 0 Result
:CopyLoop
@PUSHI Source @IF_EQ_A 0xffff @POPNULL @MA2V DISKOS_E_RANGE DiskLastError @JMP GatewayReturn @ENDIF @POPNULL
@PUSHI Source @ESO @PUSHS @AND 0xff
@PUSHII Temp @AND 0xff00 @ORS @POPII Temp
@PUSHII Temp @AND 0xff
@IF_ZERO @POPNULL @JMP CopyEnd @ENDIF @POPNULL
@INCI Source @INCI Temp @DECI Remaining
@IF_EQ_AV 0 Remaining @MA2V DISKOS_E_ARGUMENT DiskLastError @JMP GatewayReturn @ENDIF
@JMP CopyLoop
:CopyEnd
@IF_EQ_AV 0 Initialized
   @MA2V 2 DiskLastError
   @JMP GatewayReturn
@ENDIF
@MA2V 0 ReadFlag @MA2V 0 WriteFlag @MA2V 0 CreateFlag
@MA2V 0 TruncateFlag @MA2V 0 AppendFlag
@PUSHI OpenMode @AND 0xffe0
@IF_NOTZERO
   @POPNULL @MA2V 3 DiskLastError @JMP GatewayReturn
@ENDIF
@POPNULL
@PUSHI OpenMode @AND 3
@IF_ZERO
   @POPNULL @MA2V 3 DiskLastError @JMP GatewayReturn
@ENDIF
@POPNULL
@PUSHI OpenMode @AND DISKOS_OPEN_READ @POPI ReadFlag
@PUSHI OpenMode @AND DISKOS_OPEN_WRITE @POPI WriteFlag
@PUSHI OpenMode @AND DISKOS_OPEN_CREATE @POPI CreateFlag
@PUSHI OpenMode @AND DISKOS_OPEN_TRUNCATE @POPI TruncateFlag
@PUSHI OpenMode @AND DISKOS_OPEN_APPEND @POPI AppendFlag
@PUSHI WriteFlag @IF_ZERO
   @POPNULL
   @PUSHI CreateFlag @PUSHI AppendFlag @ORS @PUSHI TruncateFlag @ORS
   @IF_NOTZERO @POPNULL @MA2V 3 DiskLastError @JMP GatewayReturn @ENDIF
   @POPNULL
@ELSE
   @POPNULL
@ENDIF
@PUSHI AppendFlag @IF_NOTZERO
   @POPNULL
   @PUSHI CreateFlag @IF_ZERO @POPNULL @MA2V 3 DiskLastError @JMP GatewayReturn @ENDIF @POPNULL
@ELSE
   @POPNULL
@ENDIF
@PUSHI TruncateFlag @IF_NOTZERO
   @POPNULL
   @PUSHI CreateFlag @IF_ZERO @POPNULL @MA2V 3 DiskLastError @JMP GatewayReturn @ENDIF @POPNULL
@ELSE
   @POPNULL
@ENDIF

# Select an existing-file mode or a create-capable mode. CREATE opens at zero
# unless APPEND is requested; TRUNCATE clears the in-memory size before close.
   @PUSHI CreateFlag @PUSHI AppendFlag @ORS
@IF_NOTZERO
   @POPNULL
   @PUSHI ReadFlag @IF_NOTZERO
      @POPNULL @MA2V MODE_AP LegacyMode
   @ELSE
      @POPNULL @MA2V MODE_WP LegacyMode
   @ENDIF
@ELSE
   @POPNULL
   @PUSHI ReadFlag @IF_NOTZERO
      @POPNULL
      @PUSHI WriteFlag @IF_NOTZERO
         @POPNULL @MA2V MODE_RW LegacyMode
      @ELSE
         @POPNULL @MA2V MODE_RO LegacyMode
      @ENDIF
   @ELSE
      @POPNULL @MA2V MODE_WO LegacyMode
   @ENDIF
@ENDIF
@Call(AV) file_open FileName LegacyMode @POPI Result
@IF_EQ_AV 0 Result
   @PUSHI CreateFlag @IF_ZERO
      @POPNULL @MA2V DISKOS_E_NOT_FOUND DiskLastError
   @ELSE
      @POPNULL @MA2V DISKOS_E_NO_SPACE DiskLastError
   @ENDIF
@ENDIF
@IF_NEQ_AV 0 Result
   @PUSHI AppendFlag @IF_ZERO
      @POPNULL @FILL_AT_A Result FPTR_CURSOR 0 @FILL_AT_A Result FPTR_CURSOR+2 0
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI TruncateFlag @IF_NOTZERO
      @POPNULL @FILL_AT_A Result FPTR_FILESIZE 0 @FILL_AT_A Result FPTR_FILESIZE+2 0
      @FILL_AT_A Result FPTR_CURSOR 0 @FILL_AT_A Result FPTR_CURSOR+2 0
   @ELSE
      @POPNULL
   @ENDIF
   @MA2V 0 HandleIndex
:RegisterHandleLoop
   @PUSHI HandleIndex @IF_UGE_A 16
      @POPNULL @Call(V) DiskClose Result @POPNULL
      @MA2V DISKOS_E_TOO_MANY_OPEN DiskLastError
      @MA2V 0 Result @JMP GatewayReturn
   @ENDIF
   @POPNULL
   @PUSHI HandleIndex @SHLN 2 @ADD HandleTable @POPI HandleSlot
   @PUSHI HandleSlot @PUSHS
   @IF_ZERO
      @POPNULL
      @PUSHI Result @PUSHI HandleSlot @POPS
      @PUSHI HandleSlot @ADD 2 @PUSHS @POPI HandleGen
      @INCI HandleGen
      @PUSHI HandleGen @AND 0x0fff @POPI HandleGen
      @IF_EQ_AV 0 HandleGen @MA2V 1 HandleGen @ENDIF
      @PUSHI HandleGen @PUSHI HandleSlot @ADD 2 @POPS
      @PUSHI HandleGen @SHLN 4 @PUSHI HandleIndex @ORS @POPI Result
      @JMP GatewayReturn
   @ENDIF
   @POPNULL
   @INCI HandleIndex
   @JMP RegisterHandleLoop
@ENDIF
:GatewayReturn
@MA2V 0 DiskBusy
@PUSHI Result
@PUSHI SavedCS @PUSHI SavedPC
@PUSHI SavedES @SSET SegES
@PUSHI SavedDS @SSET SegDS
@FJMPS

:DiskOSClose
:CloseGateway
@DiskFarEnter 1
@MA2V 0 DiskLastError
@MA2V 0 Result
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS @POPI IOHandle
@ResolveHandle CloseReturn
@IF_ZERO
   @POPNULL @MA2V 0 Result @JMP CloseReturn
@ENDIF
@POPI IOFilePtr
@Call(V) DiskClose IOFilePtr @POPI Result
@IF_NEQ_AV 0 Result
   @PUSH 0 @PUSHI HandleSlot @POPS
@ENDIF
:CloseReturn
@MA2V 0 DiskBusy
@PUSHI Result
@PUSHI SavedCS @PUSHI SavedPC
@PUSHI SavedES @SSET SegES
@PUSHI SavedDS @SSET SegDS
@FJMPS

# Prototype byte-stream gateways: arguments are DDS handle, UDS offset, count.
# Transfer one byte at a time through DDS storage. Reject any nonempty UDS
# range whose end wraps or exceeds ffff; word-based byte access also requires
# the last byte to be at most fffe. Return the number actually transferred.
:DiskOSRead
:ReadGateway
@DiskFarEnter 3
@MA2V 0 DiskLastError
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS
@POPI IOCount @POPI IOPtr @POPI IOHandle
@MA2V 0 IOTotal
@ResolveHandle IOFinish
@IF_ZERO
   @POPNULL @JMP IOFinish
@ENDIF
@POPI IOFilePtr
@IF_EQ_AV 0 IOCount @JMP IOFinish @ENDIF
@PUSHI IOPtr @ADDI IOCount
@IF_ULT_V IOPtr @POPNULL @MA2V DISKOS_E_RANGE DiskLastError @JMP IOFinish @ENDIF @POPNULL
@PUSHI IOPtr @ADDI IOCount @SUB 1
@IF_UGT_A 0xfffe @POPNULL @MA2V DISKOS_E_RANGE DiskLastError @JMP IOFinish @ENDIF @POPNULL
:ReadNext
@Call(VAA) DiskFileRead IOFilePtr IOBuffer 1
@IF_NEQ_A 1 @POPNULL @JMP IOFinish @ENDIF @POPNULL
@PUSHI SavedDS @SSET SegES
@PUSHI IOPtr @ESO @PUSHS @AND 0xff00
@PUSHI IOBuffer @AND 0xff @ORS
@PUSHI IOPtr @ESO @POPS
@INCI IOPtr @INCI IOTotal @DECI IOCount
@IF_NEQ_AV 0 IOCount @JMP ReadNext @ENDIF
@JMP IOFinish

:DiskOSWrite
:WriteGateway
@DiskFarEnter 3
@MA2V 0 DiskLastError
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS
@POPI IOCount @POPI IOPtr @POPI IOHandle
@MA2V 0 IOTotal
@ResolveHandle IOFinish
@IF_ZERO
   @POPNULL @JMP IOFinish
@ENDIF
@POPI IOFilePtr
@IF_EQ_AV 0 IOCount @JMP IOFinish @ENDIF
@PUSHI IOPtr @ADDI IOCount
@IF_ULT_V IOPtr @POPNULL @MA2V DISKOS_E_RANGE DiskLastError @JMP IOFinish @ENDIF @POPNULL
@PUSHI IOPtr @ADDI IOCount @SUB 1
@IF_UGT_A 0xfffe @POPNULL @MA2V DISKOS_E_RANGE DiskLastError @JMP IOFinish @ENDIF @POPNULL
:WriteNext
@PUSHI SavedDS @SSET SegES
@PUSHI IOPtr @ESO @PUSHS @AND 0xff @POPI IOBuffer
@Call(VAA) DiskFileWrite IOFilePtr IOBuffer 1
@IF_NEQ_A 1 @POPNULL @JMP IOFinish @ENDIF @POPNULL
@INCI IOPtr @INCI IOTotal @DECI IOCount
@IF_NEQ_AV 0 IOCount @JMP WriteNext @ENDIF
:IOFinish
@MA2V 0 DiskBusy
@PUSHI IOTotal @PUSHI SavedCS @PUSHI SavedPC
@PUSHI SavedES @SSET SegES
@PUSHI SavedDS @SSET SegDS
@FJMPS

# Tell/Size copy a 32-bit little-endian pair into a caller-owned UDS buffer.
:DiskOSTell
@DiskFarEnter 2
@MA2V 0 DiskLastError @MA2V 0 Result
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS
@POPI IOOut @POPI IOHandle
@ResolveHandle TellReturn
@IF_ZERO @POPNULL @JMP TellReturn @ENDIF
@POPI IOFilePtr
@PUSHI IOOut @IF_UGT_A 0xfffc
   @POPNULL @MA2V DISKOS_E_RANGE DiskLastError @JMP TellReturn
@ENDIF
@POPNULL
@PUSHI SavedDS @SSET SegES
@PUSHI IOFilePtr @ADD FPTR_CURSOR @PUSHS @PUSHI IOOut @ESO @POPS
@PUSHI IOFilePtr @ADD FPTR_CURSOR+2 @PUSHS @PUSHI IOOut @ADD 2 @ESO @POPS
@MA2V 1 Result
:TellReturn
@MA2V 0 DiskBusy
@PUSHI Result @PUSHI SavedCS @PUSHI SavedPC
@PUSHI SavedES @SSET SegES @PUSHI SavedDS @SSET SegDS @FJMPS

:DiskOSSize
@DiskFarEnter 2
@MA2V 0 DiskLastError @MA2V 0 Result
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS
@POPI IOOut @POPI IOHandle
@ResolveHandle SizeReturn
@IF_ZERO @POPNULL @JMP SizeReturn @ENDIF
@POPI IOFilePtr
@PUSHI IOOut @IF_UGT_A 0xfffc
   @POPNULL @MA2V DISKOS_E_RANGE DiskLastError @JMP SizeReturn
@ENDIF
@POPNULL
@PUSHI SavedDS @SSET SegES
@PUSHI IOFilePtr @ADD FPTR_FILESIZE @PUSHS @PUSHI IOOut @ESO @POPS
@PUSHI IOFilePtr @ADD FPTR_FILESIZE+2 @PUSHS @PUSHI IOOut @ADD 2 @ESO @POPS
@MA2V 1 Result
:SizeReturn
@MA2V 0 DiskBusy
@PUSHI Result @PUSHI SavedCS @PUSHI SavedPC
@PUSHI SavedES @SSET SegES @PUSHI SavedDS @SSET SegDS @FJMPS

# Truncate only shrinks; the next DiskOSClose commits the new directory size.
:DiskOSTruncate
@DiskFarEnter 3
@MA2V 0 DiskLastError @MA2V 0 Result
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS
@POPI IOSizeHigh @POPI IOSizeLow @POPI IOHandle
@ResolveHandle TruncateReturn
@IF_ZERO @POPNULL @JMP TruncateReturn @ENDIF
@POPI IOFilePtr
@PUSHI IOFilePtr @ADD FPTR_MODE @PUSHS @AND FP_OPEN_WRITE
@IF_ZERO
   @POPNULL @MA2V DISKOS_E_ARGUMENT DiskLastError @JMP TruncateReturn
@ENDIF
@POPNULL
@PUSHI IOSizeHigh
@PUSHI IOFilePtr @ADD FPTR_FILESIZE+2 @PUSHS
@IF_UGT_S
   @POPNULL @POPNULL @MA2V DISKOS_E_ARGUMENT DiskLastError @JMP TruncateReturn
@ENDIF
@IF_EQ_S
   @POPNULL @POPNULL
   @PUSHI IOSizeLow
   @PUSHI IOFilePtr @ADD FPTR_FILESIZE @PUSHS
   @IF_UGT_S
      @POPNULL @POPNULL @MA2V DISKOS_E_ARGUMENT DiskLastError @JMP TruncateReturn
   @ENDIF
   @POPNULL @POPNULL
@ELSE
   @POPNULL @POPNULL
@ENDIF
@PUSHI IOSizeLow @PUSHI IOFilePtr @ADD FPTR_FILESIZE @POPS
@PUSHI IOSizeHigh @PUSHI IOFilePtr @ADD FPTR_FILESIZE+2 @POPS
@PUSHI IOFilePtr @ADD FPTR_CURSOR+2 @PUSHS
@PUSHI IOSizeHigh
@IF_UGT_S
   @POPNULL @POPNULL @JMP TruncateClamp
@ENDIF
@IF_EQ_S
   @POPNULL @POPNULL
   @PUSHI IOFilePtr @ADD FPTR_CURSOR @PUSHS
   @PUSHI IOSizeLow
   @IF_UGT_S
      @POPNULL @POPNULL @JMP TruncateClamp
   @ENDIF
   @POPNULL @POPNULL
@ELSE
   @POPNULL @POPNULL
@ENDIF
@JMP TruncateDone
:TruncateClamp
@PUSHI IOSizeLow @PUSHI IOFilePtr @ADD FPTR_CURSOR @POPS
@PUSHI IOSizeHigh @PUSHI IOFilePtr @ADD FPTR_CURSOR+2 @POPS
:TruncateDone
@MA2V 1 Result
:TruncateReturn
@MA2V 0 DiskBusy
@PUSHI Result @PUSHI SavedCS @PUSHI SavedPC
@PUSHI SavedES @SSET SegES @PUSHI SavedDS @SSET SegDS @FJMPS

# Find matching names from an inclusive starting file number. Pattern bytes
# are copied from UDS to the bounded DDS filename buffer before FSFindFile.
:DiskOSFind
@DiskFarEnter 2
@MA2V 0 DiskLastError @MA2V 0 Result
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS
@POPI FindStart @POPI Source
@PUSHI Initialized @IF_ZERO
   @POPNULL @MA2V DISKOS_E_NOT_INITIALIZED DiskLastError @JMP FindReturn
@ENDIF
@POPNULL
@PUSHI SavedDS @SSET SegES
@MA2V FileName Temp @MA2V 32 Remaining
:FindCopyLoop
@PUSHI Source @IF_EQ_A 0xffff
   @POPNULL @MA2V DISKOS_E_RANGE DiskLastError @JMP FindReturn
@ENDIF
@POPNULL
@PUSHI Source @ESO @PUSHS @AND 0xff
@PUSHII Temp @AND 0xff00 @ORS @POPII Temp
@PUSHII Temp @AND 0xff
@IF_ZERO @POPNULL @JMP FindCopied @ENDIF
@POPNULL
@INCI Source @INCI Temp @DECI Remaining
@IF_EQ_AV 0 Remaining
   @MA2V DISKOS_E_ARGUMENT DiskLastError @JMP FindReturn
@ENDIF
@JMP FindCopyLoop
:FindCopied
@Call(AV) FSFindFile FileName FindStart @POPI Result
:FindReturn
@MA2V 0 DiskBusy
@PUSHI Result @PUSHI SavedCS @PUSHI SavedPC
@PUSHI SavedES @SSET SegES @PUSHI SavedDS @SSET SegDS @FJMPS

# Copy one live directory entry into the caller's 38-word DiskOSFileInfo.
:DiskOSGetInfo
@DiskFarEnter 2
@MA2V 0 DiskLastError @MA2V 0 Result
@MA2V 0 InfoArg @MA2V 0 InfoBuffer
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS
@POPI InfoOut @POPI InfoFileNum
@PUSHI Initialized @IF_ZERO
   @POPNULL @MA2V DISKOS_E_NOT_INITIALIZED DiskLastError @JMP InfoReturn
@ENDIF
@POPNULL
@PUSHI InfoFileNum @IF_ULT_A 1
   @POPNULL @MA2V DISKOS_E_ARGUMENT DiskLastError @JMP InfoReturn
@ENDIF
@POPNULL
@PUSHI InfoFileNum @IF_UGE_A 512
   @POPNULL @MA2V DISKOS_E_ARGUMENT DiskLastError @JMP InfoReturn
@ENDIF
@POPNULL
@PUSHI InfoOut @IF_UGT_A 0xffd9
   @POPNULL @MA2V DISKOS_E_RANGE DiskLastError @JMP InfoReturn
@ENDIF
@POPNULL
@CALL DirNewArgTable
@IF_ZERO
   @POPNULL @MA2V DISKOS_E_NO_SPACE DiskLastError @JMP InfoCleanup
@ENDIF
@POPI InfoArg
@CALL DiskNewBuffer
@IF_ZERO
   @POPNULL @MA2V DISKOS_E_NO_SPACE DiskLastError @JMP InfoCleanup
@ENDIF
@POPI InfoBuffer
@Call(VVV) DirReadEntry InfoFileNum InfoArg InfoBuffer
@IF_ZERO
   @POPNULL @MA2V DISKOS_E_IO DiskLastError @JMP InfoCleanup
@ENDIF
@POPNULL
@PUSHI InfoArg @ADD DIR_AT_FLAGS @PUSHS @AND FLAG_INUSE
@IF_ZERO
   @POPNULL @MA2V DISKOS_E_NOT_FOUND DiskLastError @JMP InfoCleanup
@ENDIF
@POPNULL
@PUSHI SavedDS @SSET SegES
@PUSHI InfoArg @ADD DIR_AT_FILENUM @PUSHS @PUSHI InfoOut @ESO @POPS
@PUSHI InfoArg @ADD DIR_AT_FLAGS @PUSHS @PUSHI InfoOut @ADD 1 @ESO @POPS
@PUSHI InfoArg @ADD DIR_AT_FILESIZE @PUSHS @PUSHI InfoOut @ADD 2 @ESO @POPS
@PUSHI InfoArg @ADD DIR_AT_FILESIZE+2 @PUSHS @PUSHI InfoOut @ADD 3 @ESO @POPS
@PUSHI InfoArg @ADD DIR_AT_LINECOUNT @PUSHS @PUSHI InfoOut @ADD 4 @ESO @POPS
@PUSHI InfoArg @ADD DIR_AT_FILETYPE @PUSHS @PUSHI InfoOut @ADD 5 @ESO @POPS
@MA2V 0 InfoIndex
:InfoCopyName
@PUSHI InfoIndex @IF_UGE_A 32
   @POPNULL @JMP InfoNameDone
@ENDIF
@POPNULL
@PUSHI InfoArg @ADD DIR_AT_FILENAME @ADDI InfoIndex @PUSHS
@PUSHI InfoOut @ADD 6 @ADDI InfoIndex @ESO @POPS
@INCI InfoIndex
@JMP InfoCopyName
:InfoNameDone
@MA2V 1 Result
:InfoCleanup
@IF_NEQ_AV 0 InfoBuffer
   @Call(VV) HeapDSDeleteObject Heap InfoBuffer @POPNULL
@ENDIF
@IF_NEQ_AV 0 InfoArg
   @Call(VV) HeapDSDeleteObject Heap InfoArg @POPNULL
@ENDIF
:InfoReturn
@MA2V 0 DiskBusy
@PUSHI Result @PUSHI SavedCS @PUSHI SavedPC
@PUSHI SavedES @SSET SegES @PUSHI SavedDS @SSET SegDS @FJMPS

# A query preserves the last error until the next ordinary operation.
:DiskOSLastError
:ErrorGateway
@DiskFarEnter 0
@POPI SavedES @POPI SavedDS @POPI SavedPC @POPI SavedCS
@MV2V DiskLastError Result
@JMP GatewayReturn
