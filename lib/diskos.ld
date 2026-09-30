! __LIB_DISKOS_LOADED
M __LIB_DISKOS_LOADED 1
I diskos.ref
=REFCOUNT 0
# USE DebugFP
# ================================================================
# diskos.asm
#
# EX716 DiskOS – Slot-Based Disk Storage Library
# ------------------------------------------------
# This module implements a low-level disk storage
# service for the EX716 system.
#
# DiskOS provides:
#   - a fixed on-disk directory
#   - heap-backed I/O buffers
#   - file-oriented read/write operations
#   - deterministic sector-level layout
#
# DiskOS is intentionally simple and predictable.
# It is designed to support BASIC, monitors, loaders,
# and system tools running on constrained hardware.
#
# ------------------------------------------------
# High-Level Model
# ------------------------------------------------
# DiskOS presents a file abstraction built on top of
# a fixed directory and contiguous disk blocks.
#
# Each file is identified by a FileNum (1–511).
# Filenames are optional metadata.
#
# Files are currently stored as one contiguous
# block range on disk. The directory records:
#   - starting block
#   - block count
#   - file size (32-bit)
#
# NOTE:
#   Files larger than 64 KB are not yet supported,
#   but the directory format and I/O APIs are
#   designed to allow future extension via
#   block chaining or extents.
#
# ------------------------------------------------
# Disk Geometry (assumed)
# ------------------------------------------------
# Sector Size     : 512 bytes
# Block Size      : 64 KB (128 sectors)
# Total Blocks    : 512
#
# Block 0         : Directory + FS header
# Block 1-3       : Reserved for 'OS' Kernel/Monitor
# Blocks 4–511    : File data blocks
#
# Sector numbering is linear across the disk.
#
# ------------------------------------------------
# Directory Model
# ------------------------------------------------
# The directory occupies Block 0 and contains
# 512 fixed-size entries (128 bytes each).
#
# Each directory entry records:
#   - filename (optional)
#   - flags (in-use, deleted, etc.)
#   - FileNum (Mapped 1-1 to Dir entry index)
#   - file size (32-bit)
#   - first block
#   - block count
#   - line count / file type metadata
#
# Directory entries are read into heap-allocated
# ArgTables for editing, then written back verbatim.
#
# ------------------------------------------------
# FS Header
# ------------------------------------------------
# Directory entry 0 is reserved as the filesystem
# header (FS block).
#
# The FS header maintains:
#   - magic ID
#   - disk ID
#   - creation timestamp
#   - active file count
#   - bitmap of used FileNum slots
#
# The FS bitmap is authoritative for file allocation.
# NOTE:
#   FSReadHeader must be called during DiskOS initialization.
#   FSWriteHeader must be called whenever file allocation
#   state changes (create/delete).
#   DiskOpen / DiskClose do not modify FS metadata.
#
# ------------------------------------------------
# Memory Management
# ------------------------------------------------
# DiskOS does NOT use static buffers.
#
# All disk sector buffers, directory ArgTables,
# and file pointers are allocated from a
# caller-provided heap.
#
# Callers MUST:
#   - Call SetDiskHeap(HeapID) before use
#   - Ensure destination buffers are large enough
#     for requested reads or writes
#   - Free all returned objects when done
#
# DiskReadBlock and DiskWriteBlock assume the
# caller-provided memory range is valid and large
# enough for ByteCount bytes.
#
# ------------------------------------------------
# I/O Semantics
# ------------------------------------------------
# DiskReadBlock / DiskWriteBlock operate on:
#   - a starting sector
#   - a byte offset within that sector
#   - a byte count
#
# Reads and writes may span multiple sectors.
# Sector boundaries are handled internally.
#
# File-level APIs maintain a 32-bit cursor and
# file size, enabling sequential access.
#
# ------------------------------------------------
# Public API Overview
# ------------------------------------------------
# Heap / setup:
#   SetDiskHeap(HeapID)
#
# Sector-level I/O:
#   DiskReadSector(Sector, *Buffer):Void
#        Low level Disk read, fatal on I/O Failure
#   DiskWriteSector(Sector, *Buffer):Void
#        Low level Disk write, fatal on I/O Failure
#   DiskReadBlock(Sector, MemPtr, ByteCount, StartOffset, *Buffer):Bytes_Read
#   DiskWriteBlock(Sector, MemPtr, ByteCount, StartOffset, *Buffer):Bytes_Written
#
# Directory management:
#   DirLocate(FileNum):(Sector, Offset)
#          Locates directory entry for FileNum
#   DirEntryPtr(*SectorBuffer, Offset):( *DirEntry )
#          Return Pointer to directory entry inside provided buffer
#   DirEntryToArgTable(*DirEntry, *ArgTable)
#          Copies Directrory Entry into provided ArgTable, void function
#   DirArgTableToEntry(*DirEntry, *ArgTable)
#          Copies ArgTable to provided Dir Entry Pointer, void funciton
#   DirReadEntry(FileNum, *ArgTable, *SectorBuffer):(0|1)
#          For given FileNum Reads DIR's Sector into provided Buffer and fills ArgTable
#   DirWriteRawEntry(FileNum, *ArgTable, *SectorBuffer):(0|1)
#     Low-level physical write.
#     Writes ArgTable exactly as supplied into the directory entry slot.
#     Does not alter timestamps, flags, filesize, type, or bitmap state.
#   DirWriteEntry(FileNum, *ArgTable, *SectorBuffer):(0|1)
#     Normal metadata write.
#     Applies filesystem policy: create-time/update-time/status flags.
#     Calls DirWriteRawEntry for the final sector write.
#
# File-level API:
#   DiskOpen(FileNum, Mode):FilePointer|0
#          Given FileNum, open file and return FilePointer
#   DiskClose(FilePtr):(0|1)
#          Close the given File Pointer
#   DiskFileRead(FilePtr, MemPtr, ByteCount):Actual Bytes Read
#          Read upto ByteCount bytes from FilePtr file. Save to MemPtr which must be at least ByteCount large.
#   DiskFileWrite(FilePtr, MemPtr, ByteCount):Acutual Bytes Written
#           Write upto ByteCount Bytes into FilePtr file, data is from MemPtr which must be at least ByteCount large.
#   file_open(FileName, Mode):(FilePtr|0)
#
# Metadata helpers:
#   DiskFileSetLineCount(FilePtr, LineCount)
#        Writes LineCount into Meta Data of FilePtr, void function
#   DiskGetLineCount(FilePtr):Line_Count
#        Gets number of lines in Meta data of FilePtr
#   DiskFileSetType(FilePtr, TypeWord)
#        Writes File Type Code into Meta Data of FilePtr, void function
#   DiskFileGetType(FilePtr):FileType
#        Gets File Type Code from Meta Data of FilePtr
#   DiskSetFileName(FilePtr, StrPtr)
#        Sets copy of StrPtr to be current FileName, written on DiskClose
#   DiskGetFileName(FilePtr):StrPtr (Heap Object)
#        Returns new string copy of the files current set filename.
#
# Allocation / FS helpers:
#   FSReadHeader(DISK_NUMBER):(0|1) 1=success
#   FSWriteHeader():(0|1) 1=success
#   FSIsFileUsed(FileNum):(0|1)  boolean
#   FSSetFileUsed(FileNum):(0|1) 1=success 0=invalid filenum
#   fsclearfileused(FileNum):(0|1) 1=success 0=invalid filenum
#   FSFindFreeFile():FileNum|0  0=failure
#   FSFindFile(StrPattern, StartFileNum): FileNum | 0 0=no more matching files found.
#   FSFormat(DiskID, DiskNum):void   Format DiskNum with DiskID
#
# ------------------------------------------------
# Design Goals
# ------------------------------------------------
# * Deterministic, debuggable on-disk layout
# * Heap-backed, re-entrant friendly
# * Minimal hidden state
# * Suitable for small systems and teaching tools
# * Future-friendly (extents, larger files)
#
# ================================================================
#====================================================
#Storage
#====================================================
G DiskHeap
G SetDiskHeap
G DiskNewBuffer
#====================================================
#Public API — Sector / Block I/O
#====================================================
G DiskReadSector
G DiskWriteSector
G DiskReadBlock
G DiskWriteBlock


G SECTOR_SIZE
=SECTOR_SIZE 512

#====================================================
#Public API — Directory Management
#====================================================
G DirLocate
G DirEntryPtr
G DirEntryToArgTable
G DirArgTableToEntry
G DirReadEntry
G DirWriteRawEntry
G DirWriteEntry
G DirNewArgTable
G WildCardMatch
#====================================================
#Public API — File-Level Operations
#====================================================
G DiskOpen
G DiskClose
G DiskFileRead
G DiskFileWrite
G file_open G file_open_basic

G DiskFileReadLine

G DataBlockFirstSector
G FSNextUsedFile

#=====================================================
# API Fetch/Set File ArgTable fields
#=====================================================
G DiskGetLineCount
G DiskSetLineCount
G DiskGetFileType
G DiskSetFileType
G DiskGetFileName
G DiskSetFileName

#====================================================
#Directory Entry Layout (on disk)
#====================================================
# Offsets within a 128-byte directory entry
G DIR_FILENAME
G DIR_FLAGS
G DIR_FILENUM
G DIR_FILESIZE
G DIR_FIRSTBLOCK
G DIR_BLOCKCOUNT
G DIR_LINECOUNT
G DIR_FILETYPE
G DIR_TIMESTAMPS
G DIR_CRC
G DIR_RESERVE
G DIR_SIZE

=DIR_FILENAME      0x00
=DIR_FLAGS         0x20
=DIR_FILENUM       0x22
=DIR_FILESIZE      0x24
=DIR_FIRSTBLOCK    0x28
=DIR_BLOCKCOUNT    0x2A
=DIR_LINECOUNT     0x2C
=DIR_FILETYPE      0x2E
=DIR_TIMESTAMPS    0x30
=DIR_CRC           0x38
=DIR_RESERVE       0x40
=DIR_SIZE          0x80

=DIREntryCount     512
=DIR_FN_SIZE       0x1f   # Max Filename size
G DIR_FN_SIZE



#====================================================
#ArgTable Aliases (semantic clarity)
#====================================================
G DIR_AT_FILENAME
G DIR_AT_FLAGS
G DIR_AT_FILENUM
G DIR_AT_FILESIZE
G DIR_AT_FIRSTBLOCK
G DIR_AT_BLOCKCOUNT
G DIR_AT_LINECOUNT
G DIR_AT_FILETYPE
G DIR_AT_TIMESTAMPS
G DIR_AT_CRC
G DIR_AT_RESERVE
G DIR_AT_SIZE

=DIR_AT_FILENAME      DIR_FILENAME
=DIR_AT_FLAGS         DIR_FLAGS
=DIR_AT_FILENUM       DIR_FILENUM
=DIR_AT_FILESIZE      DIR_FILESIZE
=DIR_AT_FIRSTBLOCK    DIR_FIRSTBLOCK
=DIR_AT_BLOCKCOUNT    DIR_BLOCKCOUNT
=DIR_AT_LINECOUNT     DIR_LINECOUNT
=DIR_AT_FILETYPE      DIR_FILETYPE
=DIR_AT_TIMESTAMPS    DIR_TIMESTAMPS
=DIR_AT_CRC           DIR_CRC
=DIR_AT_RESERVE       DIR_RESERVE
=DIR_AT_SIZE          DIR_SIZE

G ARGTABLE_SIZE
=ARGTABLE_SIZE DIR_AT_SIZE

#====================================================
#Directory Flags
#====================================================
G FLAG_INUSE
G FLAG_DELETED
G FLAG_READONLY
G FLAG_SYSTEM
G FLAG_EXEC

=FLAG_INUSE     0b00001  # Entry exists
=FLAG_DELETED   0b00010  # Previously used, now free
=FLAG_READONLY  0b00100  # FUTURE
=FLAG_SYSTEM    0b01000  # FUTURE
=FLAG_EXEC      0b10000  # Executable vs data
#====================================================
#File Pointer Modes
#====================================================
G FP_OPEN_READ
G FP_OPEN_WRITE
G FP_OPEN_APPEND
G FP_OPEN_CREATE

G MODE_RO        # Read Only
G MODE_WO        # Write Only
G MODE_RW        # Read Write
G MODE_WP        # Write Append
G MODE_AP        # Open RW Append


=MODE_RO 0x6f72 # "ro"
=MODE_WO 0x6f77 # "wo"
=MODE_RW 0x7772 # "rw"
=MODE_WP 0x2b77 # "w+"
=MODE_AP 0x2b61 # "a+"

=FP_OPEN_READ    0b0001
=FP_OPEN_WRITE   0b0010
=FP_OPEN_APPEND  0b0100
=FP_OPEN_CREATE  0b1000

#===================================================
# Meta Flags used for tracking valid DIR lifetime
#===================================================
=FPTR_META_DIRTY 0x1

#====================================================
#File Pointer Structure (in memory)
#====================================================
G FPTR_FILENUM
G FPTR_FIRST_SECTOR
G FPTR_FILESIZE
G FPTR_CURSOR
G FPTR_MODE
G FPTR_RESERVE
G FPTR_CURRENT_ENTRY
G FPTR_META_FLAGS
G FPTR_ARGTABLE
G FILEPTR_SIZE

=FPTR_FILENUM        0
=FPTR_FIRST_SECTOR   2
=FPTR_FILESIZE       4   # 32-bit
=FPTR_CURSOR         8   # 32-bit
=FPTR_MODE           12
=FPTR_RESERVE        14
=FPTR_CURRENT_ENTRY  14      # Future meaning of RESERVE
=FPTR_META_FLAGS     16
=FPTR_ARGTABLE       18
=FILEPTR_SIZE        20

#====================================================
#File System (FS) Header API
#====================================================
G FSReadHeader
G FSWriteHeader
G FSIsFileUsed
G FSSetFileUsed
G FSClearFileUsed
G FSFindFreeFile
G FSFindFile
G FSFormat

#====================================================
#FS Header Layout (on disk)
#====================================================
G FSMagicID
G FSDiskID
G FSCreateTimeID
G FSActiveFilesID
G FSHeaderFlagsID
G FSFileBitMapID
G FSReservedID

=FSMagicID          0
=FSDiskID           2
=FSCreateTimeID     4
=FSActiveFilesID    8
=FSHeaderFlagsID    10
=FSFileBitMapID     12
=FSReservedID       76

#====================================================
#Structure Helper Macros
#====================================================
# %1[%2] = %3   (%1 = StructurePtr, %2 = offset, %3 = value)
M FILL_AT_A @PUSH %3  @PUSHI %1 @ADD %2 @POPS
M FILL_AT_V @PUSHI %3 @PUSHI %1 @ADD %2 @POPS
M FILL_AT_S @PUSHI %1 @ADD %2 @POPS
M GET_FROM @PUSHI %1 @ADD %2 @PUSHS


#====================================================
#Internal Storage (DiskOS state)
#====================================================
G FSDiskNumStore
G FSDiskIDStore
G FSCreateTimeStore
G FSActiveFilesStore
G FSHeaderFlagStore
G FSHeadValidStore
G FSFileBitMapStore

#====================================================
# DiskFileReadLine return status format:
#   high nibble = status
#   low 12 bits = length/detail
#
# 0x0nnn = complete line, nnn = payload length
# 0x8nnn = partial line, nnn = payload length, LF not yet seen
# 0xf000 = EOF before any byte read
#
# Max payload length is 0x0fff.
G LINE_LEN_MASK
G LINE_STATE_MASK
G LINE_OK
G LINE_NO_ROOM
G LINE_PARTIAL
G LINE_EOF

= LINE_LEN_MASK      0x0fff
= LINE_STATE_MASK    0xf000

= LINE_OK            0x0000
= LINE_NO_ROOM       0x1000
= LINE_PARTIAL       0x8000
= LINE_EOF           0xf000


# Only one buffer supported (non-reentrant)
:DiskHeap            -1
:DiskIOSector         0
:DiskIOBuffer         0
:FSDiskNumStore      -1
:FSDiskIDStore       0
:FSCreateTimeStore   0 0   # 32-bit
:FSActiveFilesStore  0
:FSHeaderFlagStore   0
:FSHeadValidStore    0
:FSFileBitMapStore
. FSFileBitMapStore+128



# --- External dependencies (not defined in this file) ---
#  DataBlockFirstSector
#  DirArgTableToEntry
#  DirEntryPtr
#  DirEntryToArgTable
#  DirLocate
#  DiskReadSector
#  DiskWriteSector
#  FSIsFileUsed
#  FSSetFileUsed
#  HeapDeleteObject
#  HeapNewObject
#  strcmp
#  strfndc
#  strlen
#  strncmp
#  strncpy

#####################################################################################
#--------------------------------------------------
# SetDiskHeap(HeapID)
# Required function, Heap Space must be allocated and ID'ed
#--------------------------------------------------
@FUNCTION SetDiskHeap
:SetDiskHeap
@PUSHRETURN
   @POPI DiskHeap
@POPRETURN
@RET
@ENDFUNCTION
#
#
# Low Level Disk IO
#--------------------------------------------------
# DiskReadSector(Sector, *Buffer)
#--------------------------------------------------
@FUNCTION DiskReadSector
:DiskReadSector
@PUSHRETURN
    @POPI DiskIOBuffer
    @POPI DiskIOSector
    @DISKSEEKI DiskIOSector
    @DISKREADI DiskIOBuffer
@POPRETURN
@RET
@ENDFUNCTION
#--------------------------------------------------
# DiskWriteSector(Sector, *Buffer)
#--------------------------------------------------
@FUNCTION DiskWriteSector
:DiskWriteSector
@PUSHRETURN
    @POPI DiskIOBuffer
    @POPI DiskIOSector
    @DISKSEEKI DiskIOSector
    @DISKWRITEI DiskIOBuffer
@POPRETURN
@RET
@ENDFUNCTION
#---------------------------------------------
@FUNCTION  DataBlockFirstSector
# DataBlockFirstSector(FileNum):(Sector)
#---------------------------------------------
:DataBlockFirstSector
@PUSHRETURN
@Locals
    @Local FileNum
    @IF_ULT_A 512
       @POPI FileNum
       @PUSHI FileNum
       @SHLN 7         # <<7 == *128
    @ELSE
       # Error Invalid FileNum
       @PRT "ERR:IVFN:" @PRTTOP
       @POPNULL
       @PUSH -1       # -1 as error code
    @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#---------------------------------------------
@FUNCTION  DirLocate
# DirLocate(FileNum):(Sector, Offset)
# Finds the DIR sector and its offset within that sector.
#---------------------------------------------
:DirLocate
@PUSHRETURN
@Locals
   @Local FileNum
   @Local ByteOffset
   @Local Sector
   @Local OffSet

   # Directory Entry N always corresponds to data in Block N where block is 64K sequentual blocks on the disk.
    @IF_ULT_A 512
      @POPI FileNum

      # Directory entries are fixed 128 bytes.
      # Math below is based on fixed size so to use shifts rather than MOD or DIV

      @PUSHI FileNum @SHLN 7    # * 128
      @POPI ByteOffset

      @PUSHI ByteOffset @SHRN 9  # / 512
      @POPI Sector

      @PUSHI ByteOffset @AND 0x1ff # Mask 512
      @POPI OffSet

      @PUSHI Sector
      @PUSHI OffSet
   @ELSE
      # Invalid FileNum
       @PRT "ERR:IVFN:" @PRTTOP
       @POPNULL
       @PUSH -1       # -1 as error code
       @PUSH -1       # -1 as error code
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#
#------------------------------------------
@FUNCTION  DirEntryPtr
# DirEntryPtr(*Buffer, Offset):(*EntryPtr)
# Set Ptr to spot in Buffer where FileNum's DirEntry starts.
#------------------------------------------
:DirEntryPtr
@PUSHRETURN
@Locals
   @Local BuffPtr
   @Local OffSet

   @POPI OffSet
   @POPI BuffPtr

   @PUSHI BuffPtr @ADDI OffSet
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#
#------------------------------------------
@FUNCTION  DirEntryToArgTable
# DirEntryToArgTable(*DirEntry, *ArgTable):
# Reads DIR from disk into ArgTable, which must be at least 128 bytes long
#------------------------------------------
:DirEntryToArgTable
@PUSHRETURN
@Locals
   @Local DirEntry
   @Local ArgTable   

   @POPI ArgTable
   @POPI DirEntry

   @Call(VVA) memcpy ArgTable DirEntry DIR_AT_SIZE

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#--------------------------------------------
# DirArgTableToEntry(*DirEntry,*ArgTable)
# Copies the formated ArgTable to the in memory image of DIR sector.
#--------------------------------------------
@FUNCTION DirArgTableToEntry
:DirArgTableToEntry
@PUSHRETURN
@Locals
   @Local DirEntry
   @Local ArgTable

   @POPI ArgTable
   @POPI DirEntry

   @Call(VVA) memcpy DirEntry ArgTable DIR_AT_SIZE

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#----------------------------------------
# DirWriteRawEntry(FileNum, *ArgTable, *Diskbuff)
#----------------------------------------
@FUNCTION DirWriteRawEntry
:DirWriteRawEntry
@PUSHRETURN
@Locals
#USE DirEntryPtr,DirLocate,DirArgTableToEntry
    @Local FileNum
    @Local ArgTable
    @Local Diskbuff
    @Local Result
    @Local Offset
    @Local Sector
    @Local EntryPtr
    
    @POPI Diskbuff
    @POPI ArgTable
    @POPI FileNum
    @MA2V 0 Result
    # Find Sector-Offset where Dir entry is.
    @Call(V) DirLocate FileNum
    @IF_EQ_A -1
       @PRT "ERR:WDIR"
    @ELSE
       @POPI Offset
       @POPI Sector
       @Call(VV) DiskReadSector Sector Diskbuff
       @Call(VV) DirEntryPtr Offset Diskbuff
       @POPI EntryPtr
       @Call(VV) DirArgTableToEntry EntryPtr ArgTable
       @Call(VV) DiskWriteSector Sector Diskbuff
       @MA2V 1 Result
    @ENDIF
    @PUSHI Result
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#--------------------------------------
@FUNCTION  DirReadEntry
# DirReadEntry(FileNum,*ArgTable, *Diskbuff):Error Code
# Test for ArgTable.FLAGS for FLAG_INUSE to check for errors. Will only be set if Entry if valid.
#--------------------------------------
:DirReadEntry
@PUSHRETURN
@Locals
#USE DirEntryToArgTable,DirLocate
    @Local FileNum
    @Local ArgTable
    @Local Offset
    @Local Sector
    @Local EntryPtr
    @Local Diskbuff

    @POPI Diskbuff
    @POPI ArgTable
    @POPI FileNum

    # Find Sector-Offset where DIR entry is.
    @Call(V) DirLocate FileNum
    @IF_EQ_A -1
       @PRT "ERR:RDIR"
       @POPNULL
       @POPNULL
       @PUSH 0       # Error
    @ELSE
       @POPI Offset
       @POPI Sector

       @Call(VV) DiskReadSector Sector Diskbuff


       @Call(VV) DirEntryPtr Diskbuff Offset
       @POPI EntryPtr

       @Call(VV) DirEntryToArgTable EntryPtr ArgTable
       @PUSH 1
    @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#-----------------------------------------
# DirNewArgTable
# Returns a new ArgTable pointer.
#-----------------------------------------
@FUNCTION DirNewArgTable
:DirNewArgTable
@PUSHRETURN
@Locals
   @Local I1
   @Local Limit
   @Local ArgTable
   @IF_EQ_AV -1 DiskHeap
      # Heap Must be defined before it can be used.
      @PRTS MEMERRMSG
      @PUSH 0
   @ELSE
      @Call(VA) HeapNewObject DiskHeap ARGTABLE_SIZE
      @POPI ArgTable
      @PUSHI ArgTable @ADD ARGTABLE_SIZE @SUB 1 @POPI Limit
      @ForIV2V I1 ArgTable Limit
         @PUSH 0 @POPII I1
      @Next I1
      @PUSHI ArgTable
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#-----------------------------------------
@FUNCTION  DiskNewBuffer
# DiskNewBuffer():*Buffer
#-----------------------------------------
:DiskNewBuffer
@PUSHRETURN
   @IF_EQ_AV -1 DiskHeap
      # Heap Must be defined before it can be used.
      @PRTS MEMERRMSG
      @PUSH -1
   @ELSE
      @Call(VA) HeapNewObject DiskHeap SECTOR_SIZE @IF_ULT_A 100 @PRTS MEMERRMSG @POPNULL @END @ENDIF
   @ENDIF
@POPRETURN
@RET
@ENDFUNCTION

#-----------------------------------------
# DiskWriteBlock(Sector, MemPtr, ByteCount, StartOffset, Diskbuff)
# Writes exactly ByteCount bytes from memory beginning at MemPtr
# into consecutive disk sectors beginning at Sector and StartOffset.
# Existing bytes outside the written range in partial sectors are preserved.
# Sectors beyond the written range are not modified.
#-----------------------------------------
@FUNCTION DiskWriteBlock
:DiskWriteBlock
@PUSHRETURN
@Locals
    @Local Sector
    @Local MemPtr
    @Local ByteCount
    @Local StartOffset
    @Local Diskbuff
    @Local InBuffPtr
    @Local _I


    @POPI Diskbuff
    @POPI StartOffset
    @POPI ByteCount
    @POPI MemPtr
    @POPI Sector



    # Now test to make sure ByteCount does not overflow the address
    @PUSHI ByteCount
    @ADDI MemPtr
    @IF_ULT_V MemPtr
      # Over Flow, so set ByteCount to something that will fit
       @PUSH 0xfffe @SUBI MemPtr
       @POPI ByteCount
    @ENDIF
    @POPNULL

# Fast exit if we are trying to write 0 bytes.
    @IF_EQ_AV 0 ByteCount
       @JMP DWBExit
    @ENDIF


    # Make sure StartOffset is in valid range
    @PUSHI StartOffset
    @IF_UGT_A 511
       #
       @POPNULL
       @PRT "ERR:NVOF"
       @JMP DWBExit
    @ENDIF
    @POPNULL

    @PUSHI ByteCount
    @WHILE_UGT_A 0
        @POPNULL

        # A sector must be preloaded when either:
        #
        # 1. StartOffset is nonzero, because bytes before the write
        #    must be preserved.
        #
        # 2. StartOffset is zero and ByteCount is less than one
        #    complete sector, because bytes after the write must
        #    be preserved.

        @IF_NEQ_AV 0 StartOffset
            @Call(VV) DiskReadSector Sector Diskbuff
        @ELSE

            @PUSH 512
            @IF_UGT_V ByteCount
                @POPNULL
                @Call(VV) DiskReadSector Sector Diskbuff
            @ELSE
                @POPNULL
            @ENDIF
        @ENDIF

        @PUSHI Diskbuff
        @ADDI StartOffset
        @POPI InBuffPtr

        @MV2V StartOffset _I
        @PUSHI _I

        @WHILE_ULT_A 512
            @POPNULL

            @IF_EQ_AV 0 ByteCount
                @WHILEBREAK
            @ENDIF

            @PUSHII MemPtr
            @AND 0xff

            @PUSHII InBuffPtr
            @AND 0xff00
            @ORS
            @POPII InBuffPtr

            @INCI MemPtr
            @INCI InBuffPtr
            @DECI ByteCount
            @INCI _I

            @PUSHI _I
        @ENDWHILE
        @POPNULL

        @Call(VV) DiskWriteSector Sector Diskbuff
        @INCI Sector
        @MA2V 0 StartOffset

        @PUSHI ByteCount
    @ENDWHILE
:DWBExit
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION  DiskReadBlock
#---------------------------------------
# DiskReadBlock(Sector, MemPtr, ByteCount, StartOffset, Diskbuff):Bytes Read
# Reads a sequence of Sectors into a memory.
#---------------------------------------
:DiskReadBlock
@PUSHRETURN
@Locals
    @Local Sector  #
    @Local MemPtr  #
    @Local ByteCount  #
    @Local StartOffset  #
    @Local Diskbuff  #
    @Local InBuffPtr  #
    @Local SectRemain  #
    @Local OrigCount  #

    @POPI Diskbuff
    @POPI StartOffset
    @POPI ByteCount
    @POPI MemPtr
    @POPI Sector
    # Test if StartOffset is invalud
    @PUSHI StartOffset
    @IF_UGE_A SECTOR_SIZE
       @POPNULL
       @PUSH 0        # Return zero on this error
       @JMP DRBExit
    @ENDIF
    @POPNULL
    # Clamp ByteCount to addressable memory
    @PUSHI ByteCount
    @ADDI MemPtr
    @IF_ULT_V MemPtr
       @PUSH 0xfffe
       @SUBI MemPtr
       @POPI ByteCount
    @ENDIF
    @POPNULL
    @MV2V ByteCount OrigCount
    @IF_EQ_AV 0 ByteCount
       @PUSH 0      # Return zero if no bytecount
       @JMP DRBExit
    @ENDIF
    @PUSHI ByteCount
    @WHILE_UGT_A 0
       @POPNULL
       @Call(VV) DiskReadSector Sector Diskbuff
       @PUSHI Diskbuff @ADDI StartOffset
       @POPI InBuffPtr
       @PUSH SECTOR_SIZE @SUBI StartOffset
       @POPI SectRemain
       @MA2V 0 StartOffset
       # WHEN is used here to emulate:
       # while (SectRemain > 0 && ByteCount > 0)
       @WHEN
          # True is SectRemain > 0 && ByteCount > 0
          @PUSH 1
          @IF_EQ_AV 0 SectRemain 
             @POPNULL @PUSH 0   # Always Break WHEN SectRemain==0
          @ENDIF
          @IF_EQ_AV 0 ByteCount
             @POPNULL @PUSH 0   # Always Break WHEN ByteCount==0
          @ENDIF
       @DO_NOTZERO
          @POPNULL
          @PUSHII MemPtr @AND 0xff00   # Get High Byte Preserve it.
          @PUSHII InBuffPtr @AND 0xff  # Low Byte
          @ORS
          @POPII MemPtr                # Save
          @INCI InBuffPtr
          @INCI MemPtr
          @DECI SectRemain
          @DECI ByteCount
       @ENDWHEN
       @POPNULL
       @INCI Sector       
       @PUSHI ByteCount
    @ENDWHILE
    @POPNULL
    @PUSHI OrigCount
    @SUBI ByteCount      # How many bytes were acutually read.
:DRBExit
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#---------------------------------------
# DiskOpen(FileNum,Mode)
# Create a FilePtr structure to refrence a disk file.
#---------------------------------------
@FUNCTION DiskOpen
:DiskOpen
@PUSHRETURN
@Locals
#USE DirNewArgTable,DirWriteEntry,DataBlockFirstSector
    @Local FileNum
    @Local Mode
    @Local ArgTable
    @Local FilePtr
    @Local DoCreateFlag
    @Local Diskbuff


    @POPI Mode
    @POPI FileNum

    @MA2V 0 ArgTable   # Set defaults for Error cases.
    @MA2V 0 Diskbuff
    @MA2V 0 FilePtr

#   Validate that APPEND or CREATE is combined with WRITE
    @PUSHI Mode @AND FP_OPEN_CREATE
    @PUSHI Mode @AND FP_OPEN_APPEND
    @ORS
    
    @IF_NOTZERO    
        @POPNULL
        @PUSHI Mode @AND FP_OPEN_WRITE
        @IF_ZERO
            @POPNULL
            @PRT "ERR:!W"
            @JMP Do_Op_EXIT_NH
        @ELSE
            @POPNULL
        @ENDIF
        
    @ELSE
        @POPNULL
        
    @ENDIF
    @CALL DirNewArgTable @IF_ZERO
                   @PRTS MEMERRMSG
                   @POPNULL
                   @JMP Do_Op_EXIT
                   @ENDIF

    @POPI ArgTable
    @CALL DiskNewBuffer
    @POPI Diskbuff
    @Call(VVV) DirReadEntry FileNum ArgTable Diskbuff
    @IF_ZERO
        @POPNULL
        # Error in DirReadEntry, jump fast exit, skip heap management.
        @JMP Do_Op_EXIT
    @ENDIF
    @POPNULL
    @MA2V 0 DoCreateFlag

    @GET_FROM ArgTable DIR_AT_FLAGS
    #
    @AND FLAG_INUSE
    
    @IF_NOTZERO
       # File exists
       @POPNULL
       @PUSHI Mode @AND FP_OPEN_CREATE
       @IF_NOTZERO
           @POPNULL
           @MA2V 1 DoCreateFlag
       @ELSE
           @POPNULL
       @ENDIF
       
    @ELSE
       @POPNULL
       @PUSHI Mode @AND FP_OPEN_CREATE
       @IF_NOTZERO
           @POPNULL
           @MA2V 1 DoCreateFlag
       @ELSE
           @POPNULL
           @PRT "ERR:!Found"
           @JMP Do_Op_EXIT
       @ENDIF
       
    @ENDIF

    @IF_EQ_AV 1 DoCreateFlag
       @FILL_AT_A ArgTable DIR_AT_FLAGS FLAG_INUSE
       @FILL_AT_A ArgTable DIR_AT_FILESIZE 0
       @FILL_AT_A ArgTable DIR_AT_FILESIZE+2 0       
       @FILL_AT_V ArgTable DIR_AT_FIRSTBLOCK FileNum
       @FILL_AT_A ArgTable DIR_AT_BLOCKCOUNT 1
       @Call(VVV) DirWriteEntry FileNum ArgTable Diskbuff
       @IF_ZERO
          @PRT "ERR:DW"
          @POPNULL
          @JMP Do_Op_EXIT
       @ENDIF
       @POPNULL
    @ENDIF
    # Create new File Pointer structure.

    @Call(VA) HeapNewObject DiskHeap FILEPTR_SIZE
    @IF_ULT_A 100
          @PRTS MEMERRMSG
          @POPNULL
          @JMP Do_Op_EXIT
    @ENDIF
    @POPI FilePtr

    # Populate FilePtr fields
    @FILL_AT_V FilePtr FPTR_FILENUM FileNum

    @Call(V) DataBlockFirstSector FileNum
    @FILL_AT_S FilePtr FPTR_FIRST_SECTOR

    @PUSHI ArgTable @ADD DIR_AT_FILESIZE @PUSHS
    @FILL_AT_S FilePtr FPTR_FILESIZE 

    @PUSHI ArgTable @ADD DIR_AT_FILESIZE+2 @PUSHS
    @FILL_AT_S FilePtr FPTR_FILESIZE+2

    @FILL_AT_V FilePtr FPTR_ARGTABLE ArgTable
    @MA2V 0 ArgTable                  # To make sure ArgTable not erassed like on error.

    @FILL_AT_A FilePtr FPTR_META_FLAGS 0

    @FILL_AT_V FilePtr FPTR_RESERVE FileNum

    # IF MODE flag is OPEN_APPEND set Cursor to EOF
    @PUSHI Mode @AND FP_OPEN_APPEND
    @IF_NOTZERO
        @POPNULL

        # Cursor low = FileSize low
        @GET_FROM FilePtr FPTR_FILESIZE
        @FILL_AT_S FilePtr FPTR_CURSOR

        # Cursor high = FileSize high
        @GET_FROM FilePtr FPTR_FILESIZE+2
        @FILL_AT_S FilePtr FPTR_CURSOR+2        

    @ELSE
        @POPNULL

        # Cursor low = 0
        @FILL_AT_A FilePtr FPTR_CURSOR 0
        @FILL_AT_A FilePtr FPTR_CURSOR+2 0        

    @ENDIF

    @FILL_AT_V FilePtr FPTR_MODE Mode

    @PUSHI FilePtr
:Do_Op_EXIT
    # If we get here then Diskbuff needs to be destroyed.
    @IF_NEQ_AV 0 Diskbuff    
       @Call(VV) HeapDeleteObject DiskHeap Diskbuff
       @IF_NOTZERO
          @PRTS MEMERRMSG
       @ENDIF
       @POPNULL
    @ENDIF
    @IF_NEQ_AV 0 ArgTable
       @Call(VV) HeapDeleteObject DiskHeap ArgTable
       @IF_NOTZERO
          @PRTS MEMERRMSG
       @ENDIF
       @POPNULL
    @ENDIF
:Do_Op_EXIT_NH

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION


#-----------------------------------------
# DiskFileWrite(FilePtr, MemPtr, ByteCount)
# Writes data to file at current cursor.
#-----------------------------------------
@FUNCTION DiskFileWrite
:DiskFileWrite
@PUSHRETURN
@Locals
#USE DiskWriteBlock
    @Local FilePtr
    @Local MemPtr
    @Local ByteCount
    @Local Mode
    @Local Cursor
    @Local CursorHW    # 32-but uses 05-06
    @Local FileSize    # 32-bit (uses 07,08)
    @Local FileSizeHW    # Need to name 08 but don't have to use the name.
    @Local SectorBase
    @Local Sector
    @Local StartOffset
    @Local Diskbuff
    @Local MaxWrite
    @POPI ByteCount
    @POPI MemPtr
    @POPI FilePtr

    #-------------------------------------------------
    # Validate WRITE permission
    #-------------------------------------------------
    @PUSHI FilePtr @ADD FPTR_MODE @PUSHS
    @AND FP_OPEN_WRITE
    @IF_ZERO
        @POPNULL
        @PRT "ERR:!W"
        @PUSH 0
        @JMP DFW_EXIT
    @ENDIF
    @POPNULL

    #-------------------------------------------------
    # Load cursor and filesize
    #-------------------------------------------------
    @PUSHI FilePtr @ADD FPTR_CURSOR @PUSHS
    @POPI Cursor

    @PUSHI FilePtr @ADD FPTR_FILESIZE @PUSHS
    @POPI FileSize
    @PUSHI FilePtr @ADD FPTR_FILESIZE+2 @PUSHS
    @POPI FileSize+2

    #-------------------------------------------------
    # Enforce 64KB single-block limit
    #-------------------------------------------------
    @PUSH 0xffff
    @SUBI Cursor
    @POPI MaxWrite

    @PUSHI ByteCount
    @IF_UGT_V MaxWrite
        @POPNULL
        @MA2V MaxWrite ByteCount
    @ENDIF
    @POPNULL

    @IF_EQ_AV 0 ByteCount
        @PUSH 0
        @JMP DFW_EXIT
    @ENDIF

    #-------------------------------------------------
    # Compute sector and offset
    #-------------------------------------------------
    @PUSHI Cursor
    @SHRN 9
    @POPI Sector

    @PUSHI Cursor
    @AND 0x1FF
    @POPI StartOffset

    @PUSHI FilePtr @ADD FPTR_FIRST_SECTOR @PUSHS
    @ADDI Sector
    @POPI Sector

    #-------------------------------------------------
    # Allocate disk buffer
    #-------------------------------------------------
    @CALL DiskNewBuffer
    @IF_ZERO
       @POPNULL
       @PRTS MEMERRMSG
       @JMP DFW_EXIT       
    @ENDIF
    @POPI Diskbuff

    #-------------------------------------------------
    # Perform write
    #-------------------------------------------------
    @PUSHI Sector       # Do to limit of Macros, have to manually push arguments > 4
    @Call(VVVV) DiskWriteBlock MemPtr ByteCount StartOffset Diskbuff
    @POPNULL


    #-------------------------------------------------
    # Free disk buffer
    #-------------------------------------------------
    @Call(VV) HeapDeleteObject DiskHeap Diskbuff
    @POPNULL
    #-------------------------------------------------
    # Update cursor
    #-------------------------------------------------
    @PUSHI Cursor
    @ADDI ByteCount
    @POPI Cursor

    @PUSHI Cursor
    @PUSHI FilePtr @ADD FPTR_CURSOR
    @POPS
    #-------------------------------------------------
    # Update filesize if extended
    #-------------------------------------------------
    @PUSHI Cursor
    @IF_UGT_V FileSize
        @POPNULL
        @PUSHI Cursor
        @PUSHI FilePtr @ADD FPTR_FILESIZE
        @POPS
    @ELSE
        @POPNULL
    @ENDIF
    @PUSHI ByteCount

:DFW_EXIT
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#-----------------------------------------------------
@FUNCTION DiskClose
# DiskClose(FilePtr):(0|1)
# Commits metadata to DIR and closes open file.
#-----------------------------------------------------
:DiskClose
@PUSHRETURN
@Locals
#USE DirWriteEntry
    @Local FilePtr
    @Local Mode
    @Local FileNum
    @Local ArgTable
    @Local Diskbuff
    @Local Result

    @POPI FilePtr

    @MA2V 0 ArgTable
    @MA2V 0 Diskbuff
    @MA2V 0 Result

    @IF_EQ_AV 0 FilePtr
        @JMP DC_CLEANUP
    @ENDIF

    @GET_FROM FilePtr FPTR_ARGTABLE
    @POPI ArgTable

    @IF_EQ_AV 0 ArgTable
        @PRT "ERR:!AT"
        @JMP DC_CLEANUP
    @ENDIF

    @GET_FROM FilePtr FPTR_MODE
    @POPI Mode

    # Commit metadata only if WRITE flag is set.
    @PUSHI Mode
    @AND FP_OPEN_WRITE
    @IF_NOTZERO
        @POPNULL

        @CALL DiskNewBuffer
        @IF_ZERO
            @PRTS MEMERRMSG
            @POPNULL
            @JMP DC_CLEANUP
        @ENDIF
        @POPI Diskbuff

        # Recover FileNum.
        @GET_FROM FilePtr FPTR_FILENUM
        @POPI FileNum

        # Update FileSize in persistent ArgTable.
        @GET_FROM FilePtr FPTR_FILESIZE
        @FILL_AT_S ArgTable DIR_AT_FILESIZE

        @GET_FROM FilePtr FPTR_FILESIZE+2
        @FILL_AT_S ArgTable DIR_AT_FILESIZE+2

        # Commit persistent directory entry.
        @Call(VVV) DirWriteEntry FileNum ArgTable Diskbuff
        @IF_ZERO
            @PRT "ERR:!DW"
            @POPNULL
            @JMP DC_CLEANUP
        @ENDIF
        @POPNULL
    @ELSE
        # Read-only file: no directory write.
        @POPNULL
    @ENDIF

    @MA2V 1 Result

:DC_CLEANUP
    @IF_NEQ_AV 0 Diskbuff
        @Call(VV) HeapDeleteObject DiskHeap Diskbuff
        @POPNULL
    @ENDIF

    @IF_NEQ_AV 0 ArgTable
        @Call(VV) HeapDeleteObject DiskHeap ArgTable
        @POPNULL
    @ENDIF

    @IF_NEQ_AV 0 FilePtr
        @Call(VV) HeapDeleteObject DiskHeap FilePtr
        @POPNULL
    @ENDIF

    @PUSHI Result

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#---------------------------------------------------------
# DiskFileRead(FilePtr, MemPtr, ByteCount)
#
# Reads data from an open file starting at the current
# file cursor.
#
# ByteCount semantics:
#   ByteCount > 0  : read up to ByteCount bytes
#   ByteCount == -1: read until EOF (subject to limits)
#   ByteCount == 0 : read nothing
#
# The number of bytes actually read is returned.
#
# Notes:
# * The file cursor is advanced by the number of bytes read.
# * The file size is taken from the FilePtr, not the directory.
# * A single call will never read more than 64KB.
# * Callers must loop to read larger files.
# * The file must be opened with FP_OPEN_READ.
#
# This interface is forward-compatible with multi-block
# and extent-based files.
# DiskFileRead(FilePtr, MemPtr, ByteCount)
#---------------------------------------------------------
@FUNCTION DiskFileRead
:DiskFileRead
@PUSHRETURN
@Locals
#USE DiskReadBlock
    @Local FilePtr
    @Local MemPtr
    @Local ByteCount
    @Local Mode
    @Local Cursor
    @Local CursorHW
    @Local FileSize        # 32-bit (07,08)
    @Local FileSizeHW
    @Local BytesLeft
    @Local SectorBase
    @Local SectorOff
    @Local Sector
    @Local StartOffset
    @Local Diskbuff
    @POPI ByteCount
    @POPI MemPtr
    @POPI FilePtr

    #-------------------------------------------------
    # Validate READ permission
    #-------------------------------------------------
    @PUSHI FilePtr @ADD FPTR_MODE @PUSHS
    @AND FP_OPEN_READ
    @IF_ZERO
        @POPNULL
        @PRT "ERR:!RD"
        @PUSH 0
        @JMP DFR_EXIT
    @ENDIF
    @POPNULL

    #-------------------------------------------------
    # Load cursor
    #-------------------------------------------------
    @PUSHI FilePtr @ADD FPTR_CURSOR @PUSHS
    @POPI Cursor

    #-------------------------------------------------
    # Load file size (32-bit)
    #-------------------------------------------------
    @PUSHI FilePtr @ADD FPTR_FILESIZE @PUSHS
    @POPI FileSize
    @PUSHI FilePtr @ADD FPTR_FILESIZE+2 @PUSHS
    @POPI FileSizeHW

    #-------------------------------------------------
    # EOF check
    #-------------------------------------------------
    @PUSHI Cursor
    @IF_UGE_V FileSize
        @POPNULL
        @PUSH 0
        @JMP DFR_EXIT
    @ENDIF
    @POPNULL

    #-------------------------------------------------
    # BytesLeft = FileSize - Cursor
    #-------------------------------------------------
    @PUSHI FileSize
    @SUBI Cursor
    @POPI BytesLeft

    #-------------------------------------------------
    # Handle ByteCount == -1 (read to EOF)
    #-------------------------------------------------
    @IF_EQ_AV -1 ByteCount
        @MV2V BytesLeft ByteCount
    @ENDIF

    #-------------------------------------------------
    # Clamp ByteCount to BytesLeft
    #-------------------------------------------------
    @PUSHI ByteCount
    @IF_UGT_V BytesLeft
        @POPNULL
        @MA2V BytesLeft ByteCount
    @ENDIF
    @POPNULL

    #-------------------------------------------------
    # Fast exit if nothing to read
    #-------------------------------------------------
    @IF_EQ_AV 0 ByteCount
        @PUSH 0
        @JMP DFR_EXIT
    @ENDIF

    #-------------------------------------------------
    # Compute sector offset and start offset
    #-------------------------------------------------
    @PUSHI Cursor
    @SHRN 9
    @POPI SectorOff

    @PUSHI Cursor
    @AND 0x1FF
    @POPI StartOffset

    @PUSHI FilePtr @ADD FPTR_FIRST_SECTOR @PUSHS
    @ADDI SectorOff
    @POPI Sector

    #-------------------------------------------------
    # Allocate disk buffer
    #-------------------------------------------------
    @CALL DiskNewBuffer
    @POPI Diskbuff
    #-------------------------------------------------
    # Read data block
    #-------------------------------------------------
    @PUSHI Sector              # Have to push Sector first as we don't have VVVVV Call
    :Break01
    @Call(VVVV) DiskReadBlock MemPtr ByteCount StartOffset Diskbuff
    @POPNULL
    #-------------------------------------------------
    # Free disk buffer
    #-------------------------------------------------
    @Call(VV) HeapDeleteObject DiskHeap Diskbuff
    @POPNULL

    #-------------------------------------------------
    # Advance cursor
    #-------------------------------------------------
    @PUSHI Cursor
    @ADDI ByteCount
    @POPI Cursor

    @PUSHI Cursor
    @PUSHI FilePtr @ADD FPTR_CURSOR
    @POPS

    #-------------------------------------------------
    # Return bytes read
    #-------------------------------------------------
    @PUSHI ByteCount

:DFR_EXIT
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#-------------------------------------------------
@FUNCTION  WildCardMatch
# WildCardMatch(pattern,text):1|0
# Returns 1 if pattern matches test
# Allows only 0 or 1 wildcard '*' in pattern.
#-------------------------------------------------
:WildCardMatch
@PUSHRETURN
@Locals
#USE strcmp,strfndc,strncmp
    @Local pattern
    @Local text
    @Local star
    @Local Result
    @Local head_len
    @Local tail_len
    @Local text_len

    @POPI text
    @POPI pattern

    @MA2V 0 Result

    # star will be 0 or have index of wildcard
    @Call(VA) strfndc pattern "*\0"
    @POPI star               # Star is pointer to where in string wildcard is.

    @IF_EQ_AV 0 star
       # No Wildcard, just do exact match.
       @Call(VV) strcmp pattern text
       @IF_ZERO
          @POPNULL
          @MA2V 1 Result
       @ELSE
          @POPNULL
          @MA2V 0 Result
       @ENDIF
       @JMP WCM_Exit
    @ENDIF

    # Get the length of the diffrent parts of pattern dependingon where wildcard was.

    @PUSHI star @SUBI pattern
    @POPI head_len

    @INCI star    # All future use of star is really star+1 as we want to skip the star
    @Call(V) strlen star
    @POPI tail_len

    @Call(V) strlen text
    @POPI text_len

    @PUSHI text_len @SUBI head_len
    @IF_LT_V tail_len
        # String too short to match
        @POPNULL
        @MA2V 0 Result
        @JMP WCM_Exit
    @ENDIF
    @POPNULL


    # Match head
    @IF_NEQ_AV 0 head_len
       @Call(VVV) strncmp pattern text head_len
       @IF_ZERO
          @POPI Result
          @JMP WCM_Exit
       @ENDIF
       @POPNULL
    @ENDIF

    # Match Tail
    @IF_NEQ_AV 0 tail_len
       # Do strcmp(text+text_len-tail_len, star)
       @PUSHI text
       @ADDI text_len
       @SUBI tail_len
       @PUSHI star
       @CALL strcmp
       @IF_ZERO
          @POPI Result
          @JMP WCM_Exit
       @ENDIF
       @POPNULL
    @ENDIF

    # Drop here, then its was true.
    @MA2V 1 Result

:WCM_Exit
    @PUSHI Result

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#--------------------------------------------
@FUNCTION  file_open
# file_open(FileName, Mode): FilePointer | 0
#--------------------------------------------
:file_open
@PUSHRETURN
@Locals
#USE FSFindFreeFile,DiskSetFileName,DiskOpen,DiskClose,FSSetFileUsed,FSWriteHeader
    @Local FileName
    @Local Mode
    @Local FileNum
    @Local NewFlag
    @Local FileSize
    @Local FilePointer
    @POPI Mode
    @POPI FileName
    @MA2V 0 NewFlag
    @MA2V 0 FilePointer    # For Safe return on error.

    # Validate mode

    @PUSHI Mode
    @SWITCH
    @CASE MODE_RO
        @POPNULL
        @MA2V FP_OPEN_READ NewFlag
        @CBREAK
    @CASE MODE_WO
        @POPNULL
        @MA2V FP_OPEN_WRITE NewFlag
        @CBREAK
    @CASE  MODE_RW
        @POPNULL
        @PUSH FP_OPEN_READ
        @PUSH FP_OPEN_WRITE
        @ORS
        @POPI NewFlag
        @CBREAK
    @CASE MODE_WP
        @POPNULL
        @PUSH FP_OPEN_WRITE
        @PUSH FP_OPEN_CREATE
        @ORS
        @PUSH FP_OPEN_APPEND
        @ORS
        @POPI NewFlag
        @CBREAK
    @CASE MODE_AP
        @POPNULL
        @PUSH FP_OPEN_READ
        @PUSH FP_OPEN_WRITE
        @ORS
        @PUSH FP_OPEN_CREATE
        @ORS
        @PUSH FP_OPEN_APPEND
        @ORS
        @POPI NewFlag
        @CBREAK
    @CDEFAULT
        # invalid mode
        @POPNULL
        @MA2V 0 FilePointer
        @PUSH 0
        @JMP FO_Exit
        @CBREAK
    @ENDCASE
    # Locate file
    @Call(VA) FSFindFile FileName 0
    @POPI FileNum
    @IF_EQ_AV 0 FileNum
       # We only can create a new File if the FP_OPEN_WRITE is set, otherwise its a 'not found' error
       @PUSHI NewFlag
       @AND FP_OPEN_WRITE
       @IF_ZERO
          # File doesn't exist and not open for writing.
          @POPNULL
          @MA2V 0 FilePointer
          @PUSH 0
          @JMP FO_Exit
       @ENDIF
       # Get here it is a new file need to setup defaults.# NOTE:
#   FSReadHeader must be called during DiskOS initialization.
#   FSWriteHeader must be called whenever file allocation
#   state changes (create/delete).
#   DiskOpen / DiskClose do not modify FS metadata.
       @POPNULL

       @CALL FSFindFreeFile
       @IF_NOTZERO
          # Create New Disk entry, give it filename and then reclose it to prepare FS
          @POPI FileNum
          @Call(V) FSSetFileUsed FileNum
          @IF_ZERO
             @MA2V 0 FilePointer
             @POPNULL
             @JMP FO_Exit
          @ENDIF
          @POPNULL
          
          @PUSHI NewFlag @OR FP_OPEN_CREATE @POPI NewFlag
          @Call(VV) DiskOpen FileNum NewFlag @IF_ZERO @PRT "ERR:!O" @END @ENDIF
          @POPI FilePointer
          @Call(VV) DiskSetFileName FilePointer FileName
          
          @CALL FSWriteHeader  @IF_ZERO @PRT "ERR:!W" @POPNULL @END @ELSE @POPNULL @ENDIF
          @Call(V) DiskClose FilePointer
          @IF_ZERO
             # Erorr File failed to close propelr return 0 for error
             @POPI FilePointer
             @JMP FO_Exit
          @ELSE
             @POPNULL
          @ENDIF
       @ELSE
          # Handle case where there was no remaining DIR slots available.
          @PRTS MEMERRMSG
          @MA2V 0 FilePointer
          @JMP FO_Exit
       @ENDIF
    @ENDIF
    # Open File and return FilePointer to caller
    @Call(VV) DiskOpen FileNum NewFlag @IF_ZERO @PRT "ERR:!FO" @END @ENDIF
    @POPI FilePointer

:FO_Exit
    @PUSHI FilePointer

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#--------------------------------------------
@FUNCTION  file_open_basic
# file_open_basic(FileName, Mode): FilePointer | 0
# BASIC only uses MODE_RO and MODE_WP.
#--------------------------------------------
:file_open_basic
@PUSHRETURN
@Locals
#USE FSFindFreeFile,DiskSetFileName,DiskOpen,DiskClose,FSSetFileUsed,FSWriteHeader
    @Local FileName
    @Local Mode
    @Local FileNum
    @Local NewFlag
    @Local FilePointer

    @POPI Mode
    @POPI FileName
    @MA2V 0 FilePointer

    @PUSHI Mode
    @IF_EQ_A MODE_RO
       @POPNULL
       @MA2V FP_OPEN_READ NewFlag
    @ELSE
       @IF_EQ_A MODE_WP
          @POPNULL
          @PUSH FP_OPEN_WRITE
          @PUSH FP_OPEN_CREATE
          @ORS
          @PUSH FP_OPEN_APPEND
          @ORS
          @POPI NewFlag
       @ELSE
          @POPNULL
          @JMP FOB_Exit
       @ENDIF
    @ENDIF

    @Call(VA) FSFindFile FileName 0
    @POPI FileNum
    @IF_EQ_AV 0 FileNum
       @PUSHI NewFlag
       @AND FP_OPEN_WRITE
       @IF_ZERO
          @POPNULL
          @JMP FOB_Exit
       @ENDIF
       @POPNULL

       @CALL FSFindFreeFile
       @IF_NOTZERO
          @POPI FileNum
          @Call(V) FSSetFileUsed FileNum
          @IF_ZERO
             @POPNULL
             @JMP FOB_Exit
          @ENDIF
          @POPNULL

          @PUSHI NewFlag @OR FP_OPEN_CREATE @POPI NewFlag
          @Call(VV) DiskOpen FileNum NewFlag @IF_ZERO @PRT "ERR:!O" @END @ENDIF
          @POPI FilePointer
          @Call(VV) DiskSetFileName FilePointer FileName

          @CALL FSWriteHeader  @IF_ZERO @PRT "ERR:!W" @POPNULL @END @ELSE @POPNULL @ENDIF
          @Call(V) DiskClose FilePointer
          @IF_ZERO
             @POPI FilePointer
             @JMP FOB_Exit
          @ELSE
             @POPNULL
          @ENDIF
       @ELSE
          @PRTS MEMERRMSG
          @JMP FOB_Exit
       @ENDIF
    @ENDIF

    @Call(VV) DiskOpen FileNum NewFlag @IF_ZERO @PRT "ERR:!FO" @END @ENDIF
    @POPI FilePointer

:FOB_Exit
    @PUSHI FilePointer

@EndLocals
@POPRETURN
@RET

#---------------------------------------------------------
# Series of API to modify/access DIR header data.
#---------------------------------------------------------
#
#---------------------------------------------
# DiskGetLineCount(FilePtr)
#---------------------------------------------
@FUNCTION DiskGetLineCount
:DiskGetLineCount
@PUSHRETURN
   # One argument which we just need to do immediate math..no need for variables
   @ADD FPTR_ARGTABLE
   @PUSHS
   @ADD DIR_AT_LINECOUNT
   @PUSHS
@POPRETURN
@RET
@ENDFUNCTION

#---------------------------------------------
# DiskSetLineCount(FilePtr, LineCount)
#---------------------------------------------
@FUNCTION DiskSetLineCount
:DiskSetLineCount
@PUSHRETURN
    # Again we can save some opcodes by doing all the math on the stack
    # Stack is current [ NewLineCount FilePtr ]
    @ADD FPTR_ARGTABLE
    @PUSHS
    @ADD DIR_AT_LINECOUNT
    @POPS
@POPRETURN
@RET
@ENDFUNCTION
#--------------------------------------
# DiskGetFileType(FilePtr)
#--------------------------------------
@FUNCTION DiskGetFileType
:DiskGetFileType
@PUSHRETURN
   @ADD FPTR_ARGTABLE
   @PUSHS
   @ADD DIR_AT_FILETYPE
   @PUSHS
@POPRETURN
@RET
@ENDFUNCTION
#--------------------------------------
# DiskSetFileType(FilePtr, FileType)
#--------------------------------------
@FUNCTION DiskSetFileType
:DiskSetFileType
@PUSHRETURN
   @ADD FPTR_ARGTABLE
   @PUSHS
   @ADD DIR_AT_FILETYPE
   @POPS
@POPRETURN
@RET
@ENDFUNCTION

#--------------------------------------
# DiskSetFileName(FilePtr, StrPtr)
# Copies at most DIR_FN_SIZE characters.
# Does not modify the caller's string.
#--------------------------------------
@FUNCTION DiskSetFileName
:DiskSetFileName
@PUSHRETURN
@Locals
    @Local FilePtr
    @Local StrPtr
    @Local Len
    @Local DestPtr

    @POPI2 StrPtr FilePtr

    @IF_EQ_AV 0 FilePtr
        @JMP DSFN_EXIT
    @ENDIF

    @IF_EQ_AV 0 StrPtr
        @JMP DSFN_EXIT
    @ENDIF

    @Call(V) strlen StrPtr

    # Clamp strings longer than the 31-character field.
    @IF_UGT_A DIR_FN_SIZE
        @POPNULL
        @PUSH DIR_FN_SIZE
    @ENDIF
    @POPI Len

    @GET_FROM FilePtr FPTR_ARGTABLE
    @ADD DIR_AT_FILENAME
    @POPI DestPtr

    # Copy filename characters, not the terminator.
    @Call(VVV) memcpy DestPtr StrPtr Len

    # Always terminate, including Len == 0.
    @PUSHI DestPtr
    @ADDI Len
    @POPI DestPtr
    @PUSHII DestPtr
    @AND 0xff00    
    @POPII DestPtr

:DSFN_EXIT
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#--------------------------------------
# DiskGetFileName(FilePtr):(new heap object string ptr)
#--------------------------------------
@FUNCTION DiskGetFileName
:DiskGetFileName
@PUSHRETURN
@Locals
    @Local FilePtr
    @Local FPString
    @Local MaxLen
    @Local OutString
    @Local Len
    @Local NullPtr

    @POPI FilePtr
    @MA2V 0 OutString
    @IF_EQ_AV 0 FilePtr
       @PRT "ERR:!NF"
       @JMP DGFN_EXIT
    @ENDIF
    @GET_FROM FilePtr FPTR_ARGTABLE
    @ADD DIR_AT_FILENAME
    @POPI FPString

    @GET_FROM FilePtr FPTR_ARGTABLE  # Make sure filename in ArgTable terminates
    @ADD DIR_AT_FILENAME
    @ADD DIR_FN_SIZE
    @POPI NullPtr
    @PUSHII NullPtr
    @AND 0xff00
    @POPII NullPtr
    
    @Call(V) strlen FPString

    @POPI Len
    
    @PUSHI Len
    @ADD 1      # For null space
    @POPI MaxLen
    
    @Call(VV) HeapNewObject DiskHeap MaxLen
    @IF_ULT_A 100
       @PRTS MEMERRMSG
       @POPNULL
       @JMP DGFN_EXIT
    @ENDIF
    @POPI OutString
    @Call(VVV) memcpy OutString FPString MaxLen                    
    @PUSHI OutString
    @ADDI Len
    @POPI NullPtr
    @PUSHII NullPtr
    @AND 0xff00
    @POPII NullPtr

:DGFN_EXIT
    @PUSHI OutString
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#----------------------------------------
# DirWriteEntry(FileNum, *ArgTable, *Diskbuff)
#
# Writes a complete ArgTable to a directory entry.
# Initializes creation time for a previously unused
# entry and always updates modification time.
#----------------------------------------
@FUNCTION DirWriteEntry
:DirWriteEntry
@PUSHRETURN
@Locals
#USE DirEntryPtr,DirLocate,DirArgTableToEntry

    @Local FileNum
    @Local ArgTable
    @Local Diskbuff
    @Local Result
    @Local Offset
    @Local Sector
    @Local EntryPtr

    @POPI3 Diskbuff ArgTable FileNum

    @MA2V 0 Result

    @Call(V) DirLocate FileNum
    @IF_EQ_A -1
        @PRT "ERR:!WD"
    @ELSE
        @POPI Offset
        @POPI Sector

        @Call(VV) DiskReadSector Sector Diskbuff

        @Call(VV) DirEntryPtr Offset Diskbuff
        @POPI EntryPtr

        # A previously unused entry is being created.
        @PUSHI EntryPtr
        @ADD DIR_AT_FLAGS
        @PUSHS
        @AND FLAG_INUSE
        @IF_ZERO
            @POPNULL

            # Set creation time.
            @GETTIME
            @PUSHI ArgTable
            @ADD DIR_AT_TIMESTAMPS
            @POPS
            @PUSHI ArgTable
            @ADD DIR_AT_TIMESTAMPS+2
            @POPS

            # Mark the new entry in use.
            @PUSHI ArgTable
            @ADD DIR_AT_FLAGS
            @PUSHS
            @OR FLAG_INUSE
            @PUSHI ArgTable
            @ADD DIR_AT_FLAGS
            @POPS
        @ELSE
            @POPNULL
        @ENDIF

        # Every logical write changes modification time.
        # This version of DirWriteEntry uses two GETTIME's but future hardware may have significent delays reading HW
        # In that case a version which uses one GETTIME and saves it in local storage maybe more efficet.
        @GETTIME
        @PUSHI ArgTable
        @ADD DIR_AT_TIMESTAMPS+4
        @POPS
        @PUSHI ArgTable
        @ADD DIR_AT_TIMESTAMPS+6
        @POPS

        @Call(VV) DirArgTableToEntry EntryPtr ArgTable
        @Call(VV) DiskWriteSector Sector Diskbuff

        @MA2V 1 Result
    @ENDIF

    @PUSHI Result

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION


#--------------------------------
@FUNCTION  FSReadHeader
# FSReadHeader(DISK_NUMBER):1|0 # Reads filesystem superblock (FS header) and establishes FS context
#--------------------------------
:FSReadHeader
@PUSHRETURN
@Locals
#USE DiskReadSector
    @Local Diskbuff
    @Local _I
    @Local DISKNUM
    @POPI DISKNUM
    @MV2V DISKNUM FSDiskNumStore      # We keep this so WriteHeader does not require param.

    @Call(VA) HeapNewObject DiskHeap SECTOR_SIZE
    @POPI Diskbuff

    @DISKSELI DISKNUM                 # Reading Disk Header is really the only time to select DISKID
    @Call(AV) DiskReadSector 0 Diskbuff


    @PUSHII Diskbuff
    @IF_NEQ_A 0x3044
       # FSMagicID = 'D0' (0x44,0x30) little-endian word 0x3044
       @POPNULL
       @PRT "ERR:!FMT"
       @MA2V 0 FSHeadValidStore    # Mark the disk data as bad
       @MA2V -1 FSDiskNumStore     # Make sure other functions know this is invalid.
       @PUSH 0
       @JMP FSRH_Exit
    @ELSE
       @POPNULL
       @PUSHI Diskbuff @ADD FSDiskID @PUSHS @POPI FSDiskIDStore
       @PUSHI Diskbuff @ADD FSCreateTimeID
       @DUP
       @PUSHS @POPI FSCreateTimeStore
       @ADD 2 @PUSHS @POPI FSCreateTimeStore+2
       @PUSHI Diskbuff @ADD FSActiveFilesID @PUSHS @POPI FSActiveFilesStore
       @PUSHI Diskbuff @ADD FSHeaderFlagsID @PUSHS @POPI FSHeaderFlagStore
       @PUSHI Diskbuff @ADD FSFileBitMapID
       @ForIA2B _I 0 64
          @DUP                       # Copy of Diskbuff start address
          @ADDI _I
          @PUSHS                     # Get Value of at offset
          @PUSH FSFileBitMapStore @ADDI _I  # Location to put it.
          @POPS
       @NextBy _I 2
       @POPNULL                      # Get rid of base Diskbuff offset
       @MA2V 1 FSHeadValidStore    # Mark disk data as valid
   @ENDIF
   @PUSHI FSHeadValidStore
   # Always delete Diskbuff
   @Call(VV) HeapDeleteObject DiskHeap Diskbuff @IF_NOTZERO @POPNULL  @PRTS MEMERRMSG @END @ELSE @POPNULL @ENDIF
   :FSRH_Exit
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#----------------------------------------
# FSWriteHeader() Stores current FS Disk meta data back to disk.
#----------------------------------------
@FUNCTION FSWriteHeader
:FSWriteHeader
@PUSHRETURN
@Locals
#USE DiskReadSector,DiskWriteSector
    @Local Diskbuff
    @Local _I
    @Local TestVal
    # First do some test for valid disks

    @MA2V 1 TestVal       # All tests must pass anyone sets val to 0 fails

    @IF_EQ_AV -1 FSDiskNumStore
       # Tried to call Write before Read
       @MA2V 0 TestVal
    @ENDIF
    @IF_EQ_AV 0 FSHeadValidStore
       # Last Read Header failed, can't use that to write
       @MA2V 0 TestVal
    @ENDIF
    # Now test to make sure Disk wasn't swapped.
    @DISKSELI FSDiskNumStore
    @Call(VA) HeapNewObject DiskHeap SECTOR_SIZE
    @POPI Diskbuff
    @Call(AV) DiskReadSector 0 Diskbuff
    #
    @PUSHI Diskbuff @ADD FSDiskID @PUSHS
    @IF_NEQ_V FSDiskIDStore
       # Disk does not have matching ID
       @MA2V 0 TestVal
    @ENDIF
    @POPNULL
    @PUSHII Diskbuff
    @IF_NEQ_A 0x3044
       @MA2V 0 TestVal       # Is magic number fails, disk is swapped.
    @ENDIF
    @POPNULL

    @IF_EQ_AV 1 TestVal
      # Only continue is all it right.
      # While we grab all the fields, we do not allow this functio to rewrite fixed value fields
      # like DISKID or Magic Number or create time. A format command would do all that.
      @PUSHI FSActiveFilesStore
      @PUSHI Diskbuff @ADD FSActiveFilesID  @POPS
      #
      @PUSH FSFileBitMapStore
      @ForIA2B _I 0 64
         @DUP
         @ADDI _I
         @PUSHS
         @PUSHI Diskbuff @ADD FSFileBitMapID
         @ADDI _I
         @POPS
      @NextBy _I 2
      @POPNULL # Drop Original FSFileBitMapID offset.
      #
      # Save results to Disk
      @Call(AV) DiskWriteSector 0 Diskbuff
      @PUSH 1   # Success
    @ELSE
      @PUSH 0   # Failed tests
    @ENDIF
    # Always delete Diskbuff
    @Call(VV) HeapDeleteObject DiskHeap Diskbuff @IF_NOTZERO  @POPNULL @PRTS MEMERRMSG @END @ELSE @POPNULL @ENDIF

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#---------------------------------
@FUNCTION  FSIsFileUsed
# FSIsFileUsed(FileNum):0|1  tests if bitmap says file in use
#---------------------------------
:FSIsFileUsed
@PUSHRETURN
@Locals
   @Local FileNum
   @Local _I
   @Local ByteOffset
   @Local BitIndex
   @Local Mask

   @AND 0x1ff       # Make sure FileNum in valid range.
   @IF_UGE_A 4
      @POPI FileNum


      @PUSHI FileNum @SHRN 4 @SHLN 1  # We need both do align with words
      @POPI ByteOffset
      @PUSHI FileNum @AND 0xf
      @POPI BitIndex

      @PUSH 1
      @ForIA2V _I 0 BitIndex
         @SHL
      @Next _I
      @POPI Mask

      @PUSH FSFileBitMapStore @ADDI ByteOffset
      @PUSHS
      @ANDI Mask
      @IF_NOTZERO
         @POPNULL
         @PUSH 1
      # Else is already zero
      @ENDIF
   @ELSE
      @PUSH 0             # send if FileNum <4
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#---------------------------------
# FSSetFileUsed(FileNum) Sets BitMap At FileNum spot
#---------------------------------
@FUNCTION FSSetFileUsed
:FSSetFileUsed
@PUSHRETURN
@Locals
   @Local FileNum
   @Local _I
   @Local ByteOffset
   @Local BitIndex
   @Local Mask

   @AND 0x1ff       # Make sure FileNum in valid range.
   @IF_UGE_A 4
      @POPI FileNum

      @PUSHI FileNum @SHRN 4 @SHLN 1  # We need both do align with words
      @POPI ByteOffset
      @PUSHI FileNum @AND 0xf
      @POPI BitIndex

      @PUSH 1
      @ForIA2V _I 0 BitIndex
         @SHL
      @Next _I
      @POPI Mask
      # Test if there is change in this bit
      @PUSH FSFileBitMapStore @ADDI ByteOffset
      @PUSHS
      @ANDI Mask
      @IF_ZERO
         # Bit had not been set, so INC Active Files
         @INCI FSActiveFilesStore
         @POPNULL
         # Now set it.
         @PUSH FSFileBitMapStore @ADDI ByteOffset
         @PUSHS
         @ORI Mask
         @PUSH FSFileBitMapStore @ADDI ByteOffset
         @POPS
      @ELSE
         @POPNULL
      @ENDIF
      @PUSH 1   # Success
   @ELSE
      @PUSH 0   # Invalid range
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#---------------------------------
# FSClearFileUsed(FileNum) Cleats BitMap at FileNum spot
#---------------------------------
@FUNCTION FSClearFileUsed
:FSClearFileUsed
@PUSHRETURN
@Locals
   @Local FileNum
   @Local _I
   @Local ByteOffset
   @Local BitIndex
   @Local Mask

   @AND 0x1ff       # Make sure FileNum in valid range.
   @IF_UGE_A 4
      @POPI FileNum

      @PUSHI FileNum @SHRN 4 @SHLN 1  # We need both do align with words
      @POPI ByteOffset
      @PUSHI FileNum @AND 0xf
      @POPI BitIndex

      @PUSH 1
      @ForIA2V _I 0 BitIndex
         @SHL
      @Next _I
      @POPI Mask
      @PUSH FSFileBitMapStore @ADDI ByteOffset
      @PUSHS
      @ANDI Mask
      @IF_NOTZERO
         # Bit was previously set, so DEC Active Files
         @DECI FSActiveFilesStore
         @POPNULL
         @PUSHI Mask
         @INV          # Invert the mask so all bits but Index are 1
         @POPI Mask

         @PUSH FSFileBitMapStore @ADDI ByteOffset
         @PUSHS
         @ANDI Mask
         @PUSH FSFileBitMapStore @ADDI ByteOffset
         @POPS
      @ELSE
         @POPNULL
      @ENDIF
      @PUSH 1   # Success
   @ELSE
      @PUSH 0   # Not valid range
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#--------------------------------------
@FUNCTION  FSFindFreeFile
# FSFindFreeFile():FileNum|0
#--------------------------------------
:FSFindFreeFile
@PUSHRETURN
@Locals
#USE FSIsFileUsed
    @Local _I

    @MA2V 4 _I
    @PUSHI _I
    @WHILE_ULT_A 512
       @POPNULL
       # Fast track, skip full bitmaps 16 at a time.
       @PUSHI _I
       @SHRN 4               # Get Word where _I will be.
       @SHLN 1               # Turn Word into Byte Address
       @ADD FSFileBitMapStore
       @PUSHS
       @IF_EQ_A 0xffff       # If all are used, then skip it.
           @POPNULL
           # Advance to next word boundry.
           @PUSHI _I
           @AND 0xfff0
           @ADD 16
           @POPI _I
           @PUSHI _I
       @ELSE
           # At least one bit in word was still unused, find it.
           @POPNULL
           @Call(V) FSIsFileUsed _I
           @IF_ZERO
              @POPNULL
              @PUSHI _I
              @JMP FSFFF_EXIT
           @ENDIF
           @POPNULL
           @INCI _I
           @PUSHI _I
       @ENDIF
    @ENDWHILE
    @POPNULL
    @PUSH 0
:FSFFF_EXIT
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#--------------------------------------
# FSFormat(DiskID, DiskNum)
# Format DiskNum and applies DiskID
#--------------------------------------
@FUNCTION FSFormat
:FSFormat
@PUSHRETURN
@Locals
#USE DiskReadSector,DiskWriteSector
    @Local Diskbuff
    @Local _I
    @Local DiskID
    @Local DiskNum
    @POPI DiskNum
    @POPI DiskID

    @DISKSELI DiskNum
    # Setup Storage
    @Call(VA) HeapNewObject DiskHeap SECTOR_SIZE
    @POPI Diskbuff
    #
    @Call(AV) DiskReadSector 0 Diskbuff
    #
    # First zero whole sector out to remove old data.
    @ForIA2B _I 0 510
       @PUSH 0
       @PUSHI Diskbuff
       @ADDI _I
       @POPS
    @NextBy _I 2
    #
    # Now Fill in fixed fields
    #
    @PUSH 0x3044
    @PUSHI Diskbuff @ADD FSMagicID
    @POPS
    #
    @PUSHI DiskID
    @PUSHI Diskbuff @ADD FSDiskID
    @POPS
    #
    @GETTIME     # 32 value
    @PUSHI Diskbuff @ADD FSCreateTimeID
    @POPS
    @PUSHI Diskbuff @ADD FSCreateTimeID+2
    @POPS
    #
    @PUSH 4             # 4 covers the 4 reserved files.
    @PUSHI Diskbuff @ADD FSActiveFilesID
    @POPS
    #
    # First 4 blocks are reserved mark them as in use
    @PUSH 0b1111
    @PUSHI Diskbuff @ADD FSFileBitMapID
    @POPS
    #
    # Now save the Diskbuff Back
    @Call(AV) DiskWriteSector 0 Diskbuff
    # Always cleanup Diskbuff
    @Call(VV) HeapDeleteObject DiskHeap Diskbuff @IF_NOTZERO  @PRTS MEMERRMSG @END @ELSE @POPNULL @ENDIF
    #
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#-----------------------------------
@FUNCTION  FSNextUsedFile
# FSNextUsedFile(Index):FileNum
# Utility to find next used file, skipping blocks of unused files.
#-----------------------------------
:FSNextUsedFile
@PUSHRETURN
@Locals
#USE FSIsFileUsed
    @Local _I
    @Local Word
    @IF_ULT_A 4
        @POPNULL
        @MA2V 4 _I
    @ELSE
        @POPI _I
    @ENDIF

    @PUSHI _I
    @WHILE_ULT_A 512
        @POPNULL

        # Load bitmap word
        @PUSHI _I
        @SHRN 4          # word index
        @SHLN 1          # byte offset
        @ADD FSFileBitMapStore
        @PUSHS
        @POPI Word

        @IF_EQ_AV 0x0000 Word
            # No used files in this word, skip 16
            @PUSHI _I
            @AND 0xfff0
            @ADD 16
            @POPI _I
            @PUSHI _I
        @ELSE
            # At least one bit is set
            @Call(V) FSIsFileUsed _I
            @IF_NOTZERO
                @POPNULL
                @PUSHI _I
                @JMP FSNUF_Exit
            @ENDIF
            @POPNULL
            @INCI _I
            @PUSHI _I
        @ENDIF
    @ENDWHILE

    @POPNULL
    @PUSH 0

:FSNUF_Exit
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
#--------------------------------------------
@FUNCTION  FSFindFile
# FSFindFile(Pattern, StartPoint): FileNum | 0
# Bitmap-driven filename search using FSNextUsedFile
#--------------------------------------------
:FSFindFile
@PUSHRETURN
@Locals
#USE DirNewArgTable,FSNextUsedFile,WildCardMatch
    @Local Pattern
    @Local StartPoint
    @Local FileNum
    @Local Diskbuff
    @Local ArgTable

    @POPI StartPoint
    @POPI Pattern

    # Allocate working buffers
    @CALL DiskNewBuffer
    @POPI Diskbuff

    @CALL DirNewArgTable @IF_ZERO @PRTS MEMERRMSG @END @ENDIF
    @POPI ArgTable

    # Start at max(StartPoint, 4)
    @PUSHI StartPoint
    @IF_ULT_A 4
        @POPNULL
        @PUSH 4
    @ENDIF
    @POPI FileNum

:FSFF_Loop
    # Get next used file from bitmap
    @Call(V) FSNextUsedFile FileNum
    @POPI FileNum

    # No more used files
    @IF_EQ_AV 0 FileNum
        @PUSH 0
        @JMP FSFF_Exit
    @ENDIF

    # Read directory entry
    @Call(VVV) DirReadEntry FileNum ArgTable Diskbuff
    @IF_ZERO
        # DIR read failure — skip but continue search
        @POPNULL
        @INCI FileNum
        @JMP FSFF_Loop
    @ENDIF
    @POPNULL

    # Match filename
    @PUSHI Pattern
    @PUSHI ArgTable @ADD DIR_AT_FILENAME
    @CALL WildCardMatch
    @IF_NOTZERO
        @POPNULL
        @PUSHI FileNum
        @JMP FSFF_Exit
    @ENDIF
    @POPNULL

    # Advance past this file and continue
    @INCI FileNum
    @JMP FSFF_Loop

:FSFF_Exit
    # Cleanup
    @Call(VV) HeapDeleteObject DiskHeap Diskbuff
    @POPNULL
    @Call(VV) HeapDeleteObject DiskHeap ArgTable
    @POPNULL

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#--------------------------------------------
@FUNCTION  DiskFileReadLine
# DiskFileReadLine(FilePtr, MemPtr, MaxLen):StatusLen
#
# MaxLen is total buffer capacity including final NUL.
#
# Reads at most:
#     min(MaxLen-1, LINE_LEN_MASK)
#
# LF is consumed but not stored.
# NUL is stored but not counted.
#
# Return:
#   LINE_OK | N          Complete line, N payload bytes.
#                        N may be 0 for empty line.
#
#   LINE_PARTIAL | N     Buffer filled before LF was seen.
#                        N payload bytes were stored.
#                        Caller may call again to get the next fragment.
#
#   LINE_EOF            EOF before any byte was read.
#
#   LINE_NO_ROOM        MaxLen was 0 or 1, so no payload could be read
#                        while preserving NUL termination.
#--------------------------------------------
:DiskFileReadLine
@PUSHRETURN
@Locals
#USE DiskFileRead
    @Local FilePtr
    @Local MemPtr
    @Local Consumed
    @Local MaxLen
    @Local PayloadLimit
    @Local StatusLen
    @Local Continue
    
    @POPI MaxLen
    @POPI MemPtr
    @POPI FilePtr

    @MA2V 0 Consumed
    @MA2V 0 StatusLen
    @MA2V 0 Continue

    # Need room for at least one payload byte plus final NUL.
    @IF_EQ_AV 0 MaxLen
        @MA2V LINE_NO_ROOM StatusLen

    @ELSE
        @IF_EQ_AV 1 MaxLen
            # MaxLen == 1: preserve a valid empty string if possible.
            @PUSHII MemPtr
            @AND 0xff00
            @POPII MemPtr

            @MA2V LINE_NO_ROOM StatusLen

        @ELSE
            # PayloadLimit = MaxLen - 1, reserving room for final NUL.
            @MV2V MaxLen PayloadLimit
            @DECI PayloadLimit

            # if PayloadLimit > LINE_LEN_MASK, cap it to prevent overflow into status bits
            @PUSHI PayloadLimit
            @IF_GT_A LINE_LEN_MASK
                @MA2V LINE_LEN_MASK PayloadLimit
            @ENDIF
            @POPNULL

            @MA2V 1 Continue

            @WHILE_NEQ_AV 0 Continue

                # If payload capacity is exhausted before LF, return partial.
                @IF_EQ_AV 0 PayloadLimit
                    @PUSHII MemPtr
                    @AND 0xff00
                    @POPII MemPtr

                    @PUSHI Consumed
                    @AND LINE_LEN_MASK
                    @OR LINE_PARTIAL
                    @POPI StatusLen

                    @MA2V 0 Continue

                @ELSE
                    # Read one byte into current MemPtr.
                    @Call(VVA) DiskFileRead FilePtr MemPtr 1

                    # DiskFileRead returns 0 on EOF/no byte read.
                    @IF_ZERO
                        @POPNULL

                        # EOF before any byte was read by this call.
                        @IF_EQ_AV 0 Consumed
                            @PUSHII MemPtr
                            @AND 0xff00
                            @POPII MemPtr

                            @MA2V LINE_EOF StatusLen

                        @ELSE
                            # EOF after a partial final line.
                            # Treat as a complete line even without trailing LF.
                            @PUSHII MemPtr
                            @AND 0xff00
                            @POPII MemPtr

                            @PUSHI Consumed
                            @AND LINE_LEN_MASK
                            @POPI StatusLen
                        @ENDIF

                        @MA2V 0 Continue

                    @ELSE
                        @POPNULL

                        # Check byte just read.
                        @PUSHII MemPtr
                        @AND 0xff

                        @IF_EQ_A 10       # LF '\n'
                            @POPNULL

                            # Replace LF with NUL terminator.
                            @PUSHII MemPtr
                            @AND 0xff00
                            @POPII MemPtr

                            @PUSHI Consumed
                            @AND LINE_LEN_MASK
                            @POPI StatusLen

                            @MA2V 0 Continue

                        @ELSE
                            @POPNULL

                            # Normal payload byte.
                            @INCI Consumed
                            @INCI MemPtr
                            @DECI PayloadLimit
                        @ENDIF
                    @ENDIF
                @ENDIF

            @ENDWHILE
        @ENDIF
    @ENDIF

    @PUSHI StatusLen

@EndLocals
@POPRETURN
@RET

@ENDFUNCTION
:MEMERRMSG "ERR:MEM"

M SIZESINCECOMMENT diskos.ld
@SIZESINCE
ENDBLOCK
