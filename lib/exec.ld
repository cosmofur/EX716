! __LIB_EXEC_LOADED
M __LIB_EXEC_LOADED 1

# EXC01 destructive executable loader, first native implementation.
#
# Requirements:
#   * CPU24 segmented mode and commonDS.mc.
#   * diskos.ld initialized with a heap and filesystem header.
#   * This library is loaded after .DATA has selected the caller's data MS.
#   * MS 255 is reserved for the destructive Stage 2 loader in this version.
#
# ExecFile(FileName, ArgCount, ArgVector):error
#   ArgVector contains ArgCount near pointers in the caller's DS. argv[0] is
#   synthesized from FileName. A successful call never returns.

G ExecFile
G ExecBuildArgBlock
G ExecArgWork

=EXEC_OK                 0
=EXEC_NOT_FOUND          1
=EXEC_BAD_FORMAT         2
=EXEC_BAD_EXTENTS        3
=EXEC_ARGUMENTS_TOO_BIG  4
=EXEC_LOADER_MS_USED     5
=EXEC_NO_MEMORY          6
=EXEC_DISK_ERROR         7

=EXEC_LOADER_MS          255
=EXEC_STAGE2_ENTRY       0x0100
=EXEC_HEADER             0x8000
=EXEC_EXTENT_PLAN        0x8200
=EXEC_STAGE2_STATE       0xfb00
=EXEC_SECTOR_BUFFER      0xfc00
=EXEC_ARG_BLOCK          0xfe00
=EXEC_MAX_EXTENTS        512
=EXEC_MAX_CALLER_ARGS    31

# Low-memory Stage 1 workspaces. These are disposable once Stage 2 starts.
::ExecHeaderWork 0 * 512
::ExecExtentWork 0 * 2048
::ExecArgWork 0 * 512
::ExecHeaderCount 0
::ExecHeaderPtr 0
::ExecIndex 0
::ExecSectorCount 0
::ExecPayloadSectors 0
::ExecEntryMS 0
::ExecInitialDS 0
::ExecEntrySeen 0
::ExecDSSeen 0
::ExecAvailableSectors 0
::ExecExpectedLow 0
::ExecExpectedHigh 0

# Copy bytes within the caller DS into the loader MS selected by ES.
@FUNCTION ExecCopyToLoader
:ExecCopyToLoader
@PUSHRETURN
@Locals
    @Local Dst
    @Local Src
    @Local Count
    @POPI Count
    @POPI Src
    @POPI Dst
    @PUSHI Count
    @WHILE_NOTZERO
        @POPNULL
        @PUSHI Dst @ESO @PUSHS @AND 0xff00
        @PUSHI Src @PUSHS @AND 0xff
        @ORS
        @PUSHI Dst @ESO @POPS
        @INCI Dst
        @INCI Src
        @DECI Count
        @PUSHI Count
    @ENDWHILE
    @POPNULL
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ExecBuildArgBlock(FileName, ArgCount, ArgVector):size|0
@FUNCTION ExecBuildArgBlock
:ExecBuildArgBlock
@PUSHRETURN
@Locals
    @Local FileName
    @Local CallerCount
    @Local ArgVector
    @Local TotalCount
    @Local TablePtr
    @Local StringPtr
    @Local Source
    @Local Index
    @Local Ch
    @Local Failed

    @POPI ArgVector
    @POPI CallerCount
    @POPI FileName
    @MA2V 0 Failed
    @PUSHI CallerCount
    @IF_UGT_A EXEC_MAX_CALLER_ARGS
        @POPNULL
        @PUSH 0
        @JMP ExecBuildArgBlockExit
    @ENDIF
    @POPNULL

    @PUSHI CallerCount @ADD 1 @POPI TotalCount
    @MA2V ExecArgWork+16 TablePtr
    @PUSHI TotalCount @ADD 1 @SHLN 1 @ADDI TablePtr @POPI StringPtr

    # ARG1, argc, and table/string offsets. Total size is filled at the end.
    @MA2V 0x5241 ExecArgWork
    @MA2V 0x3147 ExecArgWork+2
    @MA2V 0 ExecArgWork+4
    @MV2V TotalCount ExecArgWork+6
    @MA2V 0 ExecArgWork+8
    @MA2V 16 ExecArgWork+10
    @PUSHI StringPtr @SUB ExecArgWork @POPI ExecArgWork+12
    @MA2V 0 ExecArgWork+14
    @MA2V 0 Index

:ExecBuildArgNext
    @PUSHI Index
    @IF_UGE_V TotalCount
        @POPNULL
        @JMP ExecBuildArgDone
    @ENDIF
    @POPNULL
    @IF_EQ_AV 0 Index
        @MV2V FileName Source
    @ELSE
        @PUSHI Index @SUB 1 @SHLN 1 @ADDI ArgVector @PUSHS @POPI Source
    @ENDIF
    @PUSHI StringPtr @SUB ExecArgWork
    @PUSHI TablePtr @POPS

:ExecBuildArgCopy
    @PUSHI StringPtr
    @IF_UGE_A ExecArgWork+512
        @POPNULL
        @MA2V 1 Failed
        @JMP ExecBuildArgDone
    @ENDIF
    @POPNULL
    @PUSHI Source @PUSHS @AND 0xff @POPI Ch
    @PUSHI StringPtr @PUSHS @AND 0xff00
    @PUSHI Ch @ORS
    @PUSHI StringPtr @POPS
    @INCI Source
    @INCI StringPtr
    @IF_NEQ_AV 0 Ch
        @JMP ExecBuildArgCopy
    @ENDIF
    @INC2I TablePtr
    @INCI Index
    @JMP ExecBuildArgNext

:ExecBuildArgDone
    @PUSH 0 @PUSHI TablePtr @POPS
    @IF_NEQ_AV 0 Failed
        @PUSH 0
    @ELSE
        @PUSHI StringPtr @SUB ExecArgWork @POPI ExecArgWork+4
        @PUSHI StringPtr @SUB ExecArgWork
    @ENDIF
:ExecBuildArgBlockExit
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ExecFile(FileName, ArgCount, ArgVector):error. Success does not return.
@FUNCTION ExecFile
:ExecFile
@PUSHRETURN
@Locals
#USE file_open,DiskFileRead,DiskClose,DiskNewBuffer,DirNewArgTable,DirReadEntry,HeapDeleteObject
    @Local FileName
    @Local ArgCount
    @Local ArgVector
    @Local FilePtr
    @Local DiskBuffer
    @Local WorkArg
    @Local EntryNum
    @Local NextEntry
    @Local ExtentCount
    @Local PlanPtr
    @Local BlockCount
    @Local FirstBlock
    @Local ArgSize
    @Local Result

    @POPI ArgVector
    @POPI ArgCount
    @POPI FileName
    @MA2V EXEC_BAD_FORMAT Result
    @MA2V 0 FilePtr
    @MA2V 0 DiskBuffer
    @MA2V 0 WorkArg

    @Call(VVV) ExecBuildArgBlock FileName ArgCount ArgVector
    @POPI ArgSize
    @IF_EQ_AV 0 ArgSize
        @MA2V EXEC_ARGUMENTS_TOO_BIG Result
        @JMP ExecFileCleanup
    @ENDIF

    @Call(VA) file_open FileName MODE_RO
    @POPI FilePtr
    @IF_EQ_AV 0 FilePtr
        @MA2V EXEC_NOT_FOUND Result
        @JMP ExecFileCleanup
    @ENDIF
    # Read logical file sector zero directly. DiskOpen has already translated
    # the root extent's first block into FPTR_FIRST_SECTOR.
    @PUSHI FilePtr @ADD FPTR_FIRST_SECTOR @PUSHS @POPI FirstBlock
    @Call(VA) DiskReadSector FirstBlock ExecHeaderWork

    # EXC01 magic.
    @PUSHI ExecHeaderWork
    @IF_NEQ_A 0x5845
        @POPNULL
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL
    @PUSHI ExecHeaderWork+2
    @IF_NEQ_A 0x3043
        @POPNULL
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL
    @PUSHI ExecHeaderWork+4 @AND 0xff
    @IF_NEQ_A 0x31
        @POPNULL
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL

    @PUSHI ExecHeaderWork+5 @AND 0xff @POPI ExecEntryMS
    @PUSHI ExecHeaderWork+8 @AND 0xff @POPI ExecInitialDS
    @PUSHI ExecHeaderWork+9 @AND 0xff @POPI ExecHeaderCount
    @PUSHI ExecHeaderCount
    @IF_UGT_A 125
        @POPNULL
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL
    @MA2V 0 ExecPayloadSectors
    @MA2V 0 ExecEntrySeen
    @MA2V 0 ExecDSSeen
    @MA2V ExecHeaderWork+10 ExecHeaderPtr
    @MA2V 0 ExecIndex

:ExecValidateDescriptor
    @PUSHI ExecIndex
    @IF_UGE_V ExecHeaderCount
        @POPNULL
        @JMP ExecDescriptorsDone
    @ENDIF
    @POPNULL
    @PUSHI ExecHeaderPtr @PUSHS @AND 0xff
    @IF_UGT_A 1
        @POPNULL
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL
    @PUSHI ExecHeaderPtr @ADD 1 @PUSHS @AND 0xff @POPI NextEntry
    @IF_EQ_AV EXEC_LOADER_MS NextEntry
        @MA2V EXEC_LOADER_MS_USED Result
        @JMP ExecFileCleanup
    @ENDIF
    @PUSHI ExecHeaderPtr @ADD 2 @PUSHS @POPI ExecSectorCount
    @IF_EQ_AV 0 ExecSectorCount
        @JMP ExecFileCleanup
    @ENDIF
    @PUSHI ExecSectorCount
    @IF_UGT_A 128
        @POPNULL
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL
    @PUSHI ExecPayloadSectors @ADDI ExecSectorCount @POPI ExecPayloadSectors
    @IF_EQ_VV NextEntry ExecEntryMS
        @MA2V 1 ExecEntrySeen
    @ENDIF
    @IF_EQ_VV NextEntry ExecInitialDS
        @MA2V 1 ExecDSSeen
    @ENDIF
    @PUSHI ExecHeaderPtr @ADD 4 @POPI ExecHeaderPtr
    @INCI ExecIndex
    @JMP ExecValidateDescriptor

:ExecDescriptorsDone
    @IF_EQ_AV 0 ExecEntrySeen
        @JMP ExecFileCleanup
    @ENDIF
    @IF_EQ_AV 0 ExecDSSeen
        @JMP ExecFileCleanup
    @ENDIF

    # EXC01 payload is sector-exact: one header DS plus the declared CS data.
    @PUSHI ExecPayloadSectors @ADD 1 @POPI ExecSectorCount
    @PUSHI ExecSectorCount @SHLN 9 @POPI ExecExpectedLow
    @PUSHI ExecSectorCount @SHRN 7 @POPI ExecExpectedHigh
    @PUSHI FilePtr @ADD FPTR_FILESIZE @PUSHS
    @IF_NEQ_V ExecExpectedLow
        @POPNULL
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL
    @PUSHI FilePtr @ADD FPTR_FILESIZE+2 @PUSHS
    @IF_NEQ_V ExecExpectedHigh
        @POPNULL
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL

    @CALL DiskNewBuffer
    @IF_ZERO
        @POPNULL
        @MA2V EXEC_NO_MEMORY Result
        @JMP ExecFileCleanup
    @ENDIF
    @POPI DiskBuffer
    @CALL DirNewArgTable
    @IF_ZERO
        @POPNULL
        @MA2V EXEC_NO_MEMORY Result
        @JMP ExecFileCleanup
    @ENDIF
    @POPI WorkArg
    @PUSHI FilePtr @ADD FPTR_FILENUM @PUSHS @POPI EntryNum
    @MA2V 0 ExtentCount
    @MA2V 0 ExecAvailableSectors
    @MA2V ExecExtentWork PlanPtr

:ExecExtentLoop
    @PUSHI ExtentCount
    @IF_UGE_A EXEC_MAX_EXTENTS
        @POPNULL
        @MA2V EXEC_BAD_EXTENTS Result
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL
    @Call(VVV) DirReadEntry EntryNum WorkArg DiskBuffer
    @IF_ZERO
        @POPNULL
        @MA2V EXEC_BAD_EXTENTS Result
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL
    @GET_FROM WorkArg DIR_AT_FLAGS @AND FLAG_INUSE
    @IF_ZERO
        @POPNULL
        @MA2V EXEC_BAD_EXTENTS Result
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL
    @GET_FROM WorkArg DIR_AT_FIRSTBLOCK @POPI FirstBlock
    @GET_FROM WorkArg DIR_AT_BLOCKCOUNT @POPI BlockCount
    @IF_EQ_AV 0 BlockCount
        @MA2V EXEC_BAD_EXTENTS Result
        @JMP ExecFileCleanup
    @ENDIF
    @PUSHI FirstBlock @SHLN 7 @PUSHI PlanPtr @POPS
    @PUSHI BlockCount @SHLN 7 @PUSHI PlanPtr @ADD 2 @POPS
    @PUSHI ExecAvailableSectors
    @PUSHI BlockCount @SHLN 7 @ADDS
    @POPI ExecAvailableSectors
    @PUSHI PlanPtr @ADD 4 @POPI PlanPtr
    @INCI ExtentCount
    @GET_FROM WorkArg DIR_AT_RESERVE @POPI NextEntry
    @IF_EQ_AV 0 NextEntry
        @JMP ExecExtentsDone
    @ENDIF
    @MV2V NextEntry EntryNum
    @JMP ExecExtentLoop

:ExecExtentsDone
    # The physical extent chain must cover the header plus every payload CS
    # before Stage 2 is allowed to destroy the caller.
    @PUSHI ExecPayloadSectors @ADD 1
    @IF_UGT_V ExecAvailableSectors
        @POPNULL
        @MA2V EXEC_BAD_EXTENTS Result
        @JMP ExecFileCleanup
    @ENDIF
    @POPNULL

    # Copy all information Stage 2 needs into its reserved MS.
    @PUSH EXEC_LOADER_MS @SSET SegES
    @Call(AAA) ExecCopyToLoader EXEC_HEADER ExecHeaderWork 512
    @PUSHI ExtentCount @SHLN 2 @POPI ExecSectorCount
    @Call(AAV) ExecCopyToLoader EXEC_EXTENT_PLAN ExecExtentWork ExecSectorCount
    @Call(AAV) ExecCopyToLoader EXEC_ARG_BLOCK ExecArgWork ArgSize
    @PUSHI ExtentCount
    @PUSH EXEC_STAGE2_STATE @ESO @POPS

    # Close and free every DiskOS object before abandoning the old image.
    @Call(V) DiskClose FilePtr
    @POPNULL
    @MA2V 0 FilePtr
    @Call(VV) HeapDeleteObject DiskHeap WorkArg
    @POPNULL
    @MA2V 0 WorkArg
    @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
    @POPNULL
    @MA2V 0 DiskBuffer

    @PUSH EXEC_LOADER_MS @SSET SegDS
    @PUSH EXEC_LOADER_MS @SSET SegES
    @FJMP EXEC_LOADER_MS EXEC_STAGE2_ENTRY

:ExecFileCleanup
    @IF_NEQ_AV 0 FilePtr
        @Call(V) DiskClose FilePtr
        @POPNULL
    @ENDIF
    @IF_NEQ_AV 0 WorkArg
        @Call(VV) HeapDeleteObject DiskHeap WorkArg
        @POPNULL
    @ENDIF
    @IF_NEQ_AV 0 DiskBuffer
        @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
        @POPNULL
    @ENDIF
    @PUSHI Result
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

# ---------------------------------------------------------------------------
# Stage 2. It runs entirely from MS 255 and never calls Stage 1 or DiskOS.
# ---------------------------------------------------------------------------
.CODE 255
.ORG EXEC_STAGE2_ENTRY
:ExecStage2
@PUSH 1 @ADM
@PUSH EXEC_LOADER_MS @SSET SegDS
@PUSH EXEC_LOADER_MS @SSET SegES

# Mutable state lives in the reserved high part of this MS.
@MA2V 0 EXEC_STAGE2_STATE+2      # extent index
@MA2V 0 EXEC_STAGE2_STATE+4      # descriptor index
@MA2V EXEC_EXTENT_PLAN EXEC_STAGE2_STATE+6
@MA2V EXEC_HEADER+10 EXEC_STAGE2_STATE+8

# Load first physical extent and skip the EXC01 header Disk Sector.
@PUSHI EXEC_EXTENT_PLAN @ADD 1 @POPI EXEC_STAGE2_STATE+10
@PUSHI EXEC_EXTENT_PLAN+2 @SUB 1 @POPI EXEC_STAGE2_STATE+12

:ExecStage2DescriptorLoop
@PUSHI EXEC_STAGE2_STATE+4
@PUSHI EXEC_HEADER+9 @AND 0xff
@IF_UGE_S
    @POPNULL @POPNULL
    @JMP ExecStage2StartProgram
@ENDIF
@POPNULL @POPNULL

@PUSHI EXEC_STAGE2_STATE+8 @ADD 1 @PUSHS @AND 0xff @POPI EXEC_STAGE2_STATE+14
@PUSHI EXEC_STAGE2_STATE+8 @ADD 2 @PUSHS @POPI EXEC_STAGE2_STATE+16
@MA2V 0 EXEC_STAGE2_STATE+18

:ExecStage2SectorLoop
@IF_EQ_AV 0 EXEC_STAGE2_STATE+16
    @PUSHI EXEC_STAGE2_STATE+8 @ADD 4 @POPI EXEC_STAGE2_STATE+8
    @INCI EXEC_STAGE2_STATE+4
    @JMP ExecStage2DescriptorLoop
@ENDIF

@IF_EQ_AV 0 EXEC_STAGE2_STATE+12
    @INCI EXEC_STAGE2_STATE+2
    @PUSHI EXEC_STAGE2_STATE+2 @SHLN 2 @ADD EXEC_EXTENT_PLAN @POPI EXEC_STAGE2_STATE+6
    @PUSHII EXEC_STAGE2_STATE+6 @POPI EXEC_STAGE2_STATE+10
    @PUSHI EXEC_STAGE2_STATE+6 @ADD 2 @PUSHS @POPI EXEC_STAGE2_STATE+12
@ENDIF

@DISKSEEKI EXEC_STAGE2_STATE+10
@DISKREAD EXEC_SECTOR_BUFFER
@PUSHI EXEC_STAGE2_STATE+14 @SSET SegES
@MA2V 0 EXEC_STAGE2_STATE+20

:ExecStage2CopySector
@PUSHI EXEC_STAGE2_STATE+20
@IF_UGE_A 512
    @POPNULL
    @JMP ExecStage2SectorCopied
@ENDIF
@POPNULL
@PUSH EXEC_SECTOR_BUFFER @ADDI EXEC_STAGE2_STATE+20 @PUSHS @AND 0xff
@PUSHI EXEC_STAGE2_STATE+18 @ADDI EXEC_STAGE2_STATE+20 @ESO @PUSHS @AND 0xff00
@ORS
@PUSHI EXEC_STAGE2_STATE+18 @ADDI EXEC_STAGE2_STATE+20 @ESO @POPS
@INCI EXEC_STAGE2_STATE+20
@JMP ExecStage2CopySector

:ExecStage2SectorCopied
@INCI EXEC_STAGE2_STATE+10
@DECI EXEC_STAGE2_STATE+12
@DECI EXEC_STAGE2_STATE+16
@PUSHI EXEC_STAGE2_STATE+18 @ADD 512 @POPI EXEC_STAGE2_STATE+18
@JMP ExecStage2SectorLoop

:ExecStage2StartProgram
@PUSHI EXEC_HEADER+5 @AND 0xff
@PUSHI EXEC_HEADER+6
@PUSHI EXEC_HEADER+8 @AND 0xff @SSET SegDS
@PUSH EXEC_LOADER_MS @SSET SegES
@FJMPS

# Keep subsequent source assembly in the conventional code MS.
.CODE 0
