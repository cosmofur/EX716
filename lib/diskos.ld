! DISKOS_SEEN
M DISKOS_SEEN 1
I common.mc
L heapmgr.ld
L string.ld

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
#   DirClearArgTable(*ArgTable)
#          Clears ArgTable to default values, void function
#   DirReadEntry(FileNum, *ArgTable, *SectorBuffer):(0|1)
#          For given FileNum Reads DIR's Sector into provided Buffer and fills ArgTable
#   DirWriteEntry(FileNum, *ArgTable, *SectorBuffer):(0|1)
#          For given FileNum insert FileNum into DIR entry, use SectorBuffer as scratch space.
#   DirNewArgTable():( *ArgTable |0) 0=failure.
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
#   DiskFileName(FilePtr, StrPtr)
#        Writes StrPtr string into Filename part of FilePtr, void function
#   DiskFileSetLineCount(FilePtr, LineCount)
#        Writes LineCount into Meta Data of FilePtr, void function
#   DiskGetLineCount(FilePtr):Line_Count
#        Gets number of lines in Meta data of FilePtr
#   DiskFileSetType(FilePtr, TypeWord)
#        Writes File Type Code into Meta Data of FilePtr, void function
#   DiskFileGetType(FilePtr):FileType
#        Gets File Type Code from Meta Data of FilePtr
#
# Allocation / FS helpers:
#   FSReadHeader(DISK_NUMBER):(0|1) 1=success
#   FSWriteHeader():(0|1) 1=success
#   FSIsFileUsed(FileNum):(0|1)  boolean
#   FSSetFileUsed(FileNum):(0|1) 1=success 0=invalid filenum
#   FSClearFileUsed(FileNum):(0|1) 1=success 0=invalid filenum
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
G DirClearArgTable
G DirReadEntry
G DirWriteEntry
G DirNewArgTable
G DirFindFile
G DirFindFree
G WildCardMatch
#====================================================
#Public API — File-Level Operations
#====================================================
G DiskOpen
G DiskClose
G DiskFileRead
G DiskFileWrite
G file_open

G DiskFileName
G DiskFileSetLineCount
G DiskGetLineCount
G DiskFileSetType
G DiskFileGetType
G DiskWithDirEntry
G DiskFileReadLine

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

=FP_OPEN_READ    0b0001
=FP_OPEN_WRITE   0b0010
=FP_OPEN_APPEND  0b0100
=FP_OPEN_CREATE  0b1000

#====================================================
#File Pointer Structure (in memory)
#====================================================
G FPTR_FILENUM
G FPTR_FIRST_SECTOR
G FPTR_FILESIZE
G FPTR_CURSOR
G FPTR_MODE
G FPTR_RESERVE
G FILEPTR_SIZE

=FPTR_FILENUM        0
=FPTR_FIRST_SECTOR   2
=FPTR_FILESIZE       4   # 32-bit
=FPTR_CURSOR         8   # 32-bit
=FPTR_MODE           12
=FPTR_RESERVE        14

=FILEPTR_SIZE        16

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
#ArgTable Helper Macros
#====================================================
# %1[%2] = %3   (%1 = ArgTablePtr, %2 = offset, %3 = value)
M FILL_AT_A @PUSH %3  @PUSHI %1 @ADD %2 @POPS
M FILL_AT_V @PUSHI %3 @PUSHI %1 @ADD %2 @POPS


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

# Only one buffer supported (non-reentrant)
:DiskHeap            -1
:FSDiskNumStore      -1
:FSDiskIDStore       0
:FSCreateTimeStore   0 0   # 32-bit
:FSActiveFilesStore  0
:FSHeaderFlagStore   0
:FSHeadValidStore    0
:FSFileBitMapStore
. FSFileBitMapStore+128
#####################################################################################
#--------------------------------------------------
# SetDiskHeap(HeapID)
# Required function, Heap Space must be allocated and ID'ed
#--------------------------------------------------
:SetDiskHeap
@PUSHRETURN
   @POPI DiskHeap
@POPRETURN
@RET

#
#
# Low Level Disk IO
#--------------------------------------------------
# DiskReadSector(Sector, *Buffer)
#--------------------------------------------------
:DiskReadSector
@PUSHRETURN
    @LocalVar Sector 01
    @LocalVar BufPtr 02
    @POPI BufPtr
    @POPI Sector
    @DISKSEEKI Sector
    @DISKREADI BufPtr
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#--------------------------------------------------
# DiskWriteSector(Sector, *Buffer)
#--------------------------------------------------
:DiskWriteSector
@PUSHRETURN
    @LocalVar Sector 01
    @LocalVar BufPtr 02
    @POPI BufPtr
    @POPI Sector

    @DISKSEEKI Sector
    @DISKWRITEI BufPtr
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#---------------------------------------------
# DataBlockFirstSector(FileNum):(Sector)
#---------------------------------------------
:DataBlockFirstSector
@PUSHRETURN
    @LocalVar FileNum 01
    @IF_ULT_A 512
       @POPI FileNum
       @PUSHI FileNum
       @SHLN 7         # <<7 == *128
    @ELSE
       # Error Invalid FileNum
       @PRT "Invalid FileNum: " @PRTTOP @PRTNL
       @POPNULL
       @PUSH -1       # -1 as error code
    @ENDIF
    @RestoreVar 01
@POPRETURN
@RET
#---------------------------------------------
# DirLocate(FileNum):(Sector, Offset)
# Finds the DIR sector and its offset within that sector.
#---------------------------------------------
:DirLocate
@PUSHRETURN
   @LocalVar FileNum 01
   @LocalVar ByteOffset 02
   @LocalVar Sector 03
   @LocalVar OffSet 04

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
       @PRT "Invalid FileNum: " @PRTTOP @PRTNL
       @POPNULL
       @PUSH -1       # -1 as error code
       @PUSH -1       # -1 as error code
   @ENDIF
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#
#------------------------------------------
# DirEntryPtr(*Buffer, Offset):(*EntryPtr)
# Set Ptr to spot in Buffer where FileNum's DirEntry starts.
#------------------------------------------
:DirEntryPtr
@PUSHRETURN
   @LocalVar BuffPtr 01
   @LocalVar OffSet 02

   @POPI OffSet
   @POPI BuffPtr

   @PUSHI BuffPtr @ADDI OffSet
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

#
#------------------------------------------
# DirEntryToArgTable(*DirEntry, *ArgTable):
# Reads DIR from disk into ArgTable, which must be at least 128 bytes long
#------------------------------------------
:DirEntryToArgTable
@PUSHRETURN
   @LocalVar DirEntry 01
   @LocalVar ArgTable 02
   @LocalVar _I 03

   @POPI ArgTable
   @POPI DirEntry

   @ForIA2B _I 0 DIR_AT_SIZE
      @PUSHII DirEntry
      @POPII ArgTable
      @INC2I DirEntry
      @INC2I ArgTable
   @NextBy _I 2

   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#------------------------------------------------
# DirClearArgTable(*ArgTable)
# Clears the ArgTable, does not yet rewrite new entry to Disk
#------------------------------------------------
:DirClearArgTable
@PUSHRETURN
   @LocalVar ArgTable 01
   @LocalVar _I 02

   @POPI ArgTable

# Zero out with 0 words ArgTable from 0 to RESERVE stepping by 2 bytes per word
   @ForIA2B _I 0 DIR_AT_SIZE
      @PUSH 0
      @PUSHI ArgTable
      @ADDI _I
      @POPS
   @NextBy _I 2
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

#--------------------------------------------
# DirArgTableToDirEntry(*DirEntry,*ArgTable)
# Copies the formated ArgTable to the in memory image of DIR sector.
#--------------------------------------------
:DirArgTableToEntry
@PUSHRETURN
   @LocalVar DirEntry 01
   @LocalVar ArgTable 02
   @LocalVar _I 03

   @POPI ArgTable
   @POPI DirEntry


   @ForIA2B _I 0 DIR_AT_SIZE
      @PUSHII ArgTable
      @POPII DirEntry
      @INC2I DirEntry
      @INC2I ArgTable
   @NextBy _I 2

   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

#----------------------------------------
# DirWriteEntry(FileNum, *ArgTable, *DiskBuffer)
# Writes the in memory image of the DIR sector to disk.
#----------------------------------------
:DirWriteEntry
@PUSHRETURN
    @LocalVar FileNum    01
    @LocalVar ArgTable   02
    @LocalVar Sector     03
    @LocalVar Offset     04
    @LocalVar DiskBuffer 05
    @LocalVar EntryPtr   06
    @LocalVar Result     07

    @POPI DiskBuffer
    @POPI ArgTable
    @POPI FileNum
    @MA2V 0 Result
    # Find Sector-Offset where DIR entry is.
    @Call(V) DirLocate FileNum
    @IF_EQ_A -1
       @PRT "Error Writing DIR Entry:" @PRTI FileNum @PRTNL
    @ELSE
       @POPI Offset
       @POPI Sector

       @Call(VV) DiskReadSector Sector DiskBuffer
       

       @Call(VV) DirEntryPtr DiskBuffer Offset
       @POPI EntryPtr

       @PUSHI EntryPtr @ADD DIR_FLAGS @PUSHS
       @AND FLAG_INUSE
       @IF_ZERO
          # File is NEW so set create time, and set as 'inuse'
          @POPNULL
          
          @GETTIME        # Saves 32 bit 'unix' time to stack as two words SFT=Low-word TOS=high-word
          @PUSHI ArgTable @ADD DIR_AT_TIMESTAMPS @POPS  # Created Time is 1st 32 bit word in field.
          @PUSHI ArgTable @ADD DIR_AT_TIMESTAMPS+2 @POPS
          # Now Set INUSE Flag
          @PUSHI ArgTable @ADD DIR_AT_FLAGS @PUSHS
          @OR FLAG_INUSE
          @PUSHI ArgTable @ADD DIR_AT_FLAGS @POPS
       @ELSE
          @POPNULL
          
       @ENDIF
       # Always Change the Modify time to 'now' on writes.
       @GETTIME        # Saves 32 bit 'unix' time to stack as two words SFT=Low-word TOS=high-word
       @PUSHI ArgTable @ADD DIR_AT_TIMESTAMPS+4 @POPS  # Modified Time is 2nd 32 bit word in field.
       @PUSHI ArgTable @ADD DIR_AT_TIMESTAMPS+6 @POPS

       @Call(VV) DirArgTableToEntry EntryPtr ArgTable


       @Call(VV) DiskWriteSector Sector DiskBuffer
       
    @ENDIF
    @MA2V 1 Result
    :DWE_Exit
    
    @PUSHI Result
    @RestoreVar 07    
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#--------------------------------------
# DirReadEntry(FileNum,*ArgTable, *DiskBuff):Error Code
# Test for ArgTable.FLAGS for FLAG_INUSE to check for errors. Will only be set if Entry if valid.
#--------------------------------------
:DirReadEntry
@PUSHRETURN
    @LocalVar FileNum  01
    @LocalVar ArgTable 02
    @LocalVar Offset   03
    @LocalVar Sector   04
    @LocalVar EntryPtr 05
    @LocalVar DiskBuff   06

    @POPI DiskBuff
    @POPI ArgTable
    @POPI FileNum

    # Find Sector-Offset where DIR entry is.
    @Call(V) DirLocate FileNum
    @IF_EQ_A -1
       @PRT "Error Reading DIR Entry:" @PRTI FileNum @PRTNL
       @POPNULL
       @POPNULL
       @PUSH 0       # Error
    @ELSE
       @POPI Offset
       @POPI Sector

       @Call(VV) DiskReadSector Sector DiskBuff


       @Call(VV) DirEntryPtr DiskBuff Offset
       @POPI EntryPtr

       @Call(V) DirClearArgTable ArgTable
       @Call(VV) DirEntryToArgTable EntryPtr ArgTable
       @PUSH 1          # Successs
    @ENDIF
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#-----------------------------------------
# DirNewArgTable
# Returns a new ArgTable pointer.
#-----------------------------------------
:DirNewArgTable
@PUSHRETURN
   @IF_EQ_AV -1 DiskHeap
      # Heap Must be defined before it can be used.
      @PRT "DISK Error, no Heap defined."
      @PUSH 0
   @ELSE
      @Call(VA) HeapNewObject DiskHeap ARGTABLE_SIZE
   @ENDIF
@POPRETURN
@RET

#-----------------------------------------
# DiskNewBuffer():*Buffer
#-----------------------------------------
:DiskNewBuffer
@PUSHRETURN
   @IF_EQ_AV -1 DiskHeap
      # Heap Must be defined before it can be used.
      @PRT "DISK Error, no Heap defined."
      @PUSH -1
   @ELSE
      @Call(VA) HeapNewObject DiskHeap SECTOR_SIZE @IF_ULT_A 100 @PRT "Memory Error" @POPNULL @END @ENDIF
   @ENDIF
@POPRETURN
@RET
#-----------------------------------------
# DiskWriteBlock(Sector, MemPtr, ByteCount, StartOffset, DiskBuffer)
# Writes ByteCount bytes from memory starting at MemPtr into consecutive disk sectors starting at Sector.
# Memory is treated as word-addressable (ByteCount rounded up to even).
# Final sector is zero-filled beyond ByteCount.
# Does not clear sectors beyond the last written sector.
#-----------------------------------------
:DiskWriteBlock
@PUSHRETURN
    @LocalVar Sector 01
    @LocalVar MemPtr 02
    @LocalVar ByteCount 03
    @LocalVar StartOffset 04
    @LocalVar DiskBuffer 05
    @LocalVar InBuffPtr 06
    @LocalVar TotalSectors 07
    @LocalVar _I 08


    @POPI DiskBuffer
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


    # Calculate number of Sectors ByteCount takes up. (Round up by adding 511)
    @PUSHI ByteCount
    @ADDI StartOffset
    @ADD 511
    @SHRN 9
    @POPI TotalSectors

    # Make sure StartOffset is in valid range
    @PUSHI StartOffset
    @IF_UGT_A 511
       #
       @POPNULL
       @PRT "Not valid offset: " @PRTHEXTOP @PRT " must be between 0 and 511\n"
       @JMP DWBExit
    @ENDIF
    @POPNULL
    @IF_NEQ_AV 0 StartOffset
        # If StartOffset != 0, the preload the first sector into DiskBuffer to preserve parts not overwriten
        @Call(VV) DiskReadSector Sector DiskBuffer
    @ENDIF
    @PUSHI ByteCount
    @WHILE_UGT_A 0
        @POPNULL
        @PUSHI DiskBuffer
        @ADDI StartOffset
        @POPI InBuffPtr
        @DECI TotalSectors
        @MV2V StartOffset _I
        @PUSHI _I
        # Replace previous FOR loop with WHILE for more control.
        @WHILE_ULT_A 512
           @POPNULL
           # On last Sector zero out remaining data of sector.
           @IF_EQ_AV 0 ByteCount
              @PUSH 0
           @ELSE
              @PUSHII MemPtr  @AND 0xff     # Doing it byte at a time.
              @DECI ByteCount
           @ENDIF
           @PUSHII InBuffPtr
           @AND 0xff00         # Preserve High Byte
           @ORS                # Or new
           @POPII InBuffPtr
           @INCI MemPtr
           @INCI InBuffPtr
           @INCI _I
           @PUSHI _I
        @ENDWHILE
        @POPNULL
        @MA2V 0 StartOffset
        @Call(VV) DiskWriteSector Sector DiskBuffer
        @INCI Sector
        @PUSHI ByteCount
    @ENDWHILE

:DWBExit
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#---------------------------------------
# DiskReadBlock(Sector, MemPtr, ByteCount, StartOffset, DiskBuffer):Bytes Read
# Reads a sequence of Sectors into a memory.
#---------------------------------------
:DiskReadBlock
@PUSHRETURN
    @LocalVar Sector       01  #
    @LocalVar MemPtr       02  #
    @LocalVar ByteCount    03  #
    @LocalVar StartOffset  04  #
    @LocalVar DiskBuffer   05  #
    @LocalVar InBuffPtr    06  #
    @LocalVar SectRemain   07  #
    @LocalVar OrigCount    08  #

    @POPI DiskBuffer
    @POPI StartOffset
    @POPI ByteCount
    @POPI MemPtr
    @POPI Sector
    # Test if StartOffset is invalud
    @PUSHI StartOffset
    @IF_UGE_A SECTOR_SIZE
       @POPNULL
       @JMP DRBExit
    @ENDIF
    @POPNULL
    # Clamp ByteCount to addressable memory
    @PUSHI ByteCount
    @ADDI MemPtr
    @IF_ULT_V MemPtr
       @PUSH 0xfffe @SUBI MemPtr
       @POPI ByteCount
    @ENDIF
    @POPNULL
    @MV2V ByteCount OrigCount
    @IF_EQ_AV 0 ByteCount
       @JMP DRBExit
    @ENDIF
    @PUSHI ByteCount
    @WHILE_UGT_A 0
       @POPNULL
    :Break02
       @Call(VV) DiskReadSector Sector DiskBuffer
       @PUSHI DiskBuffer @ADDI StartOffset
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
       @PUSHI ByteCount
    @ENDWHILE
    @POPNULL
    @MA2V 0 StartOffset
    @INCI Sector
    @PUSHI OrigCount
    @SUBI ByteCount      # How many bytes were acutually read.
:DRBExit
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#---------------------------------------
# DiskOpen(FileNum,Mode)
# Create a FilePtr structure to refrence a disk file.
#---------------------------------------
:DiskOpen
@PUSHRETURN
    @LocalVar FileNum   01
    @LocalVar Mode      02
    @LocalVar ArgTable  03
    @LocalVar FilePtr   04
    @LocalVar DoCreateFlag 05
    @LocalVar DiskBuffer 06


    @POPI Mode
    @POPI FileNum

#   Validate that APPEND or CREATE is combined with WRITE
    @PUSHI Mode @AND FP_OPEN_CREATE
    @PUSHI Mode @AND FP_OPEN_APPEND
    @ORS
    
    @IF_NOTZERO    
        @POPNULL
        @PUSHI Mode @AND FP_OPEN_WRITE
        @IF_ZERO
            @POPNULL
            @PRT "Error, trying to APPEND or CREATE filenum without WRITE FLAG"
            @JMP Do_Op_EXIT_NH
        @ELSE
            @POPNULL
        @ENDIF
        
    @ELSE
        @POPNULL
        
    @ENDIF
    @CALL DirNewArgTable @IF_ZERO @PRT "Error allocating ArgTable" @END @ENDIF

@POPI ArgTable
   @CALL DiskNewBuffer
    @POPI DiskBuffer

    @Call(VVV) DirReadEntry FileNum ArgTable DiskBuffer
    @IF_ZERO
        @POPNULL
        # Error in DirReadEntry, jump fast exit, skip heap management.
        @JMP Do_Op_EXIT
    @ENDIF
    @POPNULL
    
    @MA2V 0 DoCreateFlag

    @PUSHI ArgTable @ADD DIR_AT_FLAGS @PUSHS
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
           @PRT "Attempted to Open a File that does not exist, without the CREATE option set."
           @JMP Do_Op_EXIT
       @ENDIF
       
    @ENDIF

    @IF_EQ_AV 1 DoCreateFlag
       @FILL_AT_A ArgTable DIR_AT_FLAGS FLAG_INUSE
       @FILL_AT_A ArgTable DIR_AT_FILESIZE 0
       @FILL_AT_V ArgTable DIR_AT_FIRSTBLOCK FileNum
       @FILL_AT_A ArgTable DIR_AT_BLOCKCOUNT 1
       @Call(VVV) DirWriteEntry FileNum ArgTable DiskBuffer @IF_ZERO @PRT "Disk Writer error" @END @ELSE @POPNULL @ENDIF
    @ENDIF
    # Create new File Pointer structure.

    @Call(VA) HeapNewObject DiskHeap FILEPTR_SIZE @IF_ULT_A 100 @PRT "Memory Error" @POPNULL @END  @ENDIF
    @POPI FilePtr

    # Populate FilePtr fields
    @FILL_AT_V FilePtr FPTR_FILENUM FileNum

    @Call(V) DataBlockFirstSector FileNum
    @PUSHI FilePtr @ADD FPTR_FIRST_SECTOR
    @POPS
    @PUSHI ArgTable @ADD DIR_AT_FILESIZE @PUSHS
    @PUSHI FilePtr @ADD FPTR_FILESIZE
    @POPS
    
    # IF MODE flag is OPEN_APPEND set Cursor to EOF
    @PUSHI Mode @AND FP_OPEN_APPEND
    @IF_NOTZERO
       @POPNULL
       @PUSHI ArgTable @ADD DIR_AT_FILESIZE @PUSHS
    # ELSE already zero
    @ENDIF
    
    @PUSHI FilePtr @ADD FPTR_CURSOR @POPS
    @PUSHI Mode
    @PUSHI FilePtr @ADD FPTR_MODE @POPS

    @PUSHI FilePtr
:Do_Op_EXIT
    # If we get here then DiskBuffer needs to be destroyed.
    @Call(VV) HeapDeleteObject DiskHeap DiskBuffer @IF_NOTZERO  @PRT "Memory Error:" @END @ELSE @POPNULL @ENDIF
    # If we get here then ArgTable needs to be destroyed.
    @Call(VV) HeapDeleteObject DiskHeap ArgTable  @IF_NOTZERO  @PRT "Memory Error:" @END @ELSE @POPNULL @ENDIF
:Do_Op_EXIT_NH

    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


#-----------------------------------------
# DiskFileWrite(FilePtr, MemPtr, ByteCount)
# Writes data to file at current cursor.
#-----------------------------------------
:DiskFileWrite
@PUSHRETURN
    @LocalVar FilePtr     01
    @LocalVar MemPtr      02
    @LocalVar ByteCount   03
    @LocalVar Mode        04
    @LocalVar Cursor      05
    @LocalVar CursorHW    06    # 32-but uses 05-06
    @LocalVar FileSize    07    # 32-bit (uses 07,08)
    @LocalVar FileSizeHW  08    # Need to name 08 but don't have to use the name.
    @LocalVar SectorBase  09
    @LocalVar Sector      10
    @LocalVar StartOffset 11
    @LocalVar DiskBuffer  12
    @LocalVar MaxWrite    13

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
        @PRT "DiskFileWrite: file not opened for WRITE"
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
    @POPI DiskBuffer

    #-------------------------------------------------
    # Perform write
    #-------------------------------------------------
    @PUSHI Sector       # Do to limit of Macros, have to manually push arguments > 4
    @Call(VVVV) DiskWriteBlock MemPtr ByteCount StartOffset DiskBuffer
    @POPNULL


    #-------------------------------------------------
    # Free disk buffer
    #-------------------------------------------------
    @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
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
    @RestoreVar 13
    @RestoreVar 12
    @RestoreVar 11
    @RestoreVar 10
    @RestoreVar 09
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#
#-----------------------------------------------------
# DiskClose(FilePtr):(0|1)
# Commits meta data to DIR and closes open file.
#-----------------------------------------------------
:DiskClose
@PUSHRETURN
    @LocalVar FilePtr    01
    @LocalVar Mode       02
    @LocalVar FileNum    03
    @LocalVar ArgTable   04
    @LocalVar DiskBuffer 05

    @POPI FilePtr

# Get Mode Flags
    @PUSHI FilePtr @ADD FPTR_MODE @PUSHS
    @POPI Mode
# Commit metadata only if WRITE flag set.
    @PUSHI Mode @AND FP_OPEN_WRITE
    @IF_NOTZERO
       @POPNULL
       # Get an ArgTable an DiskBuffer for DIR Sectors
       @CALL DirNewArgTable  @IF_ZERO @PRT "Error Allocating ArgTable" @END @ENDIF
       @POPI ArgTable
       @IF_EQ_AV -1 ArgTable
           @PRT "DiskClose: Argtable Alloc Failed.\n"
           @JMP DC_ERROR
       @ENDIF
       @CALL DiskNewBuffer
       @POPI DiskBuffer
       @IF_EQ_AV -1 DiskBuffer
           @PRT "DiskClose: DiskBuffer Alloc Failed.\n"
           @JMP DC_ERROR
       @ENDIF
       # Recover Filenum
       @PUSHI FilePtr @ADD FPTR_FILENUM @PUSHS
       @POPI FileNum
       # Read DIR entry
       @Call(VVV) DirReadEntry FileNum ArgTable DiskBuffer
       @IF_ZERO
          @POPNULL
          @PRT "DiskClose: DirReadEntry Failed\n"
          @JMP DC_ERROR
       @ENDIF
       @POPNULL
       # Update FileSize from FilePtr data
       @PUSHI FilePtr @ADD FPTR_FILESIZE @PUSHS
       @PUSHI ArgTable @ADD DIR_AT_FILESIZE
       @POPS
       @PUSHI FilePtr @ADD FPTR_FILESIZE+2 @PUSHS   # (possible 32 bit files in future
       @PUSHI ArgTable @ADD DIR_AT_FILESIZE+2
       @POPS
       # Write DIR Entry
       @Call(VVV) DirWriteEntry FileNum ArgTable DiskBuffer @IF_ZERO @PRT "Disk Write Error" @END @ELSE @POPNULL @ENDIF
       #
       # Clean up new temp objects
       #
       @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
       @POPNULL
       @Call(VV) HeapDeleteObject DiskHeap ArgTable
       @POPNULL
       @PUSH 1
    @ELSE
       @POPNULL
       @PUSH 1
    @ENDIF
    # Get here, then safe to delete the FilePtr object
    @Call(VV) HeapDeleteObject DiskHeap FilePtr
    @POPNULL
    @JMP DC_EXIT
:DC_ERROR
    @IF_NEQ_AV 0 DiskBuffer
        @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
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
    @PUSH 0
:DC_EXIT
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
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
:DiskFileRead
@PUSHRETURN
    @LocalVar FilePtr     01
    @LocalVar MemPtr      02
    @LocalVar ByteCount   03
    @LocalVar Mode        04
    @LocalVar Cursor      05
    @LocalVar CursorHW    06
    @LocalVar FileSize    07        # 32-bit (07,08)
    @LocalVar FileSizeHW  08
    @LocalVar BytesLeft   09
    @LocalVar SectorBase  10
    @LocalVar SectorOff   11
    @LocalVar Sector      12
    @LocalVar StartOffset 13
    @LocalVar DiskBuffer  14

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
        @PRT "DiskFileRead: file not opened for READ\n"
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
    @POPI DiskBuffer
    #-------------------------------------------------
    # Read data block
    #-------------------------------------------------
    @PUSHI Sector              # Have to push Sector first as we don't have VVVVV Call
    :Break01
    @Call(VVVV) DiskReadBlock MemPtr ByteCount StartOffset DiskBuffer
    @POPNULL
    #-------------------------------------------------
    # Free disk buffer
    #-------------------------------------------------
    @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
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
    @RestoreVar 14
    @RestoreVar 13
    @RestoreVar 12
    @RestoreVar 11
    @RestoreVar 10
    @RestoreVar 09
    @RestoreVar 08
    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#-------------------------------------------------
# WildCardMatch(pattern,text):1|0
# Returns 1 if pattern matches test
# Allows only 0 or 1 wildcard '*' in pattern.
#-------------------------------------------------
:WildCardMatch
@PUSHRETURN
    @LocalVar pattern 01
    @LocalVar text 02
    @LocalVar star 03
    @LocalVar Result 04
    @LocalVar head_len 05
    @LocalVar tail_len 06
    @LocalVar text_len 07


    @POPI text
    @POPI pattern

    @MA2V 0 Result

    # star will be 0 or have index of wildcard
    @PUSHI pattern @PUSH "*\0" @CALL strfndc
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

    @RestoreVar 07
    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#--------------------------------------------
# DirFindFile(Pattern, StartPoint):FileNum | 0
# Searches DIR, starting at StartPoint for filenames that match Pattern
# StartPoint is in terms of FileNum so by calling repeatily you can find
# all files that match a pattern.
#--------------------------------------------
:DirFindFile
@PUSHRETURN
    @LocalVar Pattern 01
    @LocalVar Result 02
    @LocalVar StartPoint 03
    @LocalVar DiskBuffer 04
    @LocalVar CurFileNum 05
    @LocalVar ArgTable 06

    @POPI StartPoint
    @POPI Pattern

    @MA2V 0 Result       # Default result is 'not found'

    @CALL DiskNewBuffer
    @POPI DiskBuffer

    @CALL DirNewArgTable  @IF_ZERO @PRT "Error Allocating ArgTable" @END @ENDIF
    @POPI ArgTable

    # We reserve the first 4 Files (0-3) for 'os' and support. So start the search at 4
    @PUSHI StartPoint
    @IF_ULT_A 4
       @POPNULL
       @PUSH 4
    @ENDIF
    @POPI StartPoint

    # Search loop continues until we find a match or reach end of DIR
    @PUSHI StartPoint
    @WHILE_LT_A DIREntryCount     # in practice 512
       @POPI CurFileNum
       @Call(VVV) DirReadEntry CurFileNum ArgTable DiskBuffer
       @IF_ZERO
          @POPNULL
          @PRT "Error Reading Filename"
          @JMP WCMExit
       @ENDIF
       @POPNULL
       # Skip DIR entries that are not active.
       @PUSHI ArgTable @ADD DIR_AT_FLAGS @PUSHS
       @AND FLAG_INUSE
       @IF_NOTZERO
          # FileNum is tagged as INUSE
          @POPNULL
          @PUSHI Pattern
          @PUSHI ArgTable @ADD DIR_AT_FILENAME   # We waisting a few cycles here, DIR_AT_FILENAME=0
          @CALL WildCardMatch

          @IF_NOTZERO
             # Pattern Matched, return current FileNum
             @POPNULL
             @MV2V CurFileNum Result
             @JMP WCMExit
          @ELSE
             @POPNULL
          @ENDIF
       @ELSE
          @POPNULL
       @ENDIF
       @INCI CurFileNum
       @PUSHI CurFileNum
    @ENDWHILE
    @POPNULL
:WCMExit
    @PUSHI Result
    # Free Space
    @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
    @POPNULL
    @Call(VV) HeapDeleteObject DiskHeap ArgTable
    @POPNULL

    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#-------------------------------------------
# DirFindFree():FileNum | 0
# Searches for a free Director entry, 0 if none found.
#-------------------------------------------
:DirFindFree
@PUSHRETURN
   @LocalVar DiskBuffer 01
   @LocalVar ArgTable   02
   @LocalVar CurFileNum 03
   @LocalVar Result     04

   @MA2V 0 Result
   @CALL DiskNewBuffer
   @POPI DiskBuffer

   @CALL DirNewArgTable @IF_ZERO @PRT "Error Allocating Argtable" @END @ENDIF
   @POPI ArgTable

   # We start search as 4 as 0-3 are reserved for OS
   @MA2V 4 CurFileNum

   @PUSHI CurFileNum
   @WHILE_LT_A DIREntryCount
      @POPNULL
      @Call(VVV) DirReadEntry CurFileNum ArgTable DiskBuffer
      @IF_ZERO
         @POPNULL
         @PRT "Error Failed to read directory."
         @MA2V 0 Result
         @JMP DFF_Exit
      @ENDIF
      @POPNULL
      # Skip DIR entries that are not active.
      @PUSHI ArgTable @ADD DIR_AT_FLAGS @PUSHS
      @AND FLAG_INUSE
      @IF_ZERO
         @POPNULL
         # FileNum is not marked as INUSE, select this one and return.
         @MV2V CurFileNum Result
         @JMP DFF_Exit
      @ENDIF
      @POPNULL
      @INCI CurFileNum
      @PUSHI CurFileNum
   @ENDWHILE
   # If we fall though here Result will still be zero
:DFF_Exit
   @PUSHI Result
   # Free Space
   @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
   @POPNULL
   @Call(VV) HeapDeleteObject DiskHeap ArgTable
   @POPNULL

   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
 @POPRETURN
 @RET




#--------------------------------------------
# file_open(FileName, Mode): FilePointer | 0
#--------------------------------------------
:file_open
@PUSHRETURN
    @LocalVar FileName   01
    @LocalVar Mode       02
    @LocalVar FileNum    03
    @LocalVar NewFlag    04
    @LocalVar FileSize   05
    @LocalVar FilePointer 06

    @POPI Mode
    @POPI FileName
    @MA2V 0 NewFlag
    @MA2V 0 FilePointer    # For Safe return on error.

    # Validate mode
    # We only use these Mode tests here, so putting the definition local
    =MODE_RO 0x6f72 # "ro"
    =MODE_WO 0x6f77 # "wo"
    =MODE_RW 0x7772 # "rw"
    =MODE_WP 0x2b77 # "w+"
    =MODE_AP 0x2b61 # "a+"

    @PUSHI Mode
    @SWITCH
    @CASE MODE_RO
        @MA2V FP_OPEN_READ NewFlag
        @CBREAK
    @CASE MODE_WO
        @MA2V FP_OPEN_WRITE NewFlag
        @CBREAK
    @CASE  MODE_RW
        @PUSH FP_OPEN_READ @PUSH FP_OPEN_WRITE
        @ORS
        @POPI NewFlag
        @CBREAK
    @CASE MODE_WP
        @PUSH FP_OPEN_WRITE @PUSH FP_OPEN_APPEND
        @ORS
        @POPI NewFlag
        @CBREAK
    @CASE MODE_AP
        @PUSH FP_OPEN_WRITE @PUSH FP_OPEN_APPEND
        @ORS
        @POPI NewFlag
        @CBREAK
    @CDEFAULT
        # invalid mode
        @POPNULL
        @MA2V 0 FilePointer
        @JMP FO_Exit
        @CBREAK
    @ENDCASE
    @POPNULL

    # Locate file
    @PUSHI FileName
    @PUSH 0
    @CALL FSFindFile
    @POPI FileNum
    @IF_EQ_AV 0 FileNum
       # We only can create a new File if the FP_OPEN_WRITE is set, otherwise its a 'not found' error
       @PUSHI NewFlag
       @AND FP_OPEN_WRITE
       @IF_ZERO
          # File doesn't exist and not open for writing.
          @POPNULL
          @MA2V 0 FilePointer
          @JMP FO_Exit
       @ENDIF
       # Get here it is a new file need to setup defaults.# NOTE:
#   FSReadHeader must be called during DiskOS initialization.
#   FSWriteHeader must be called whenever file allocation
#   state changes (create/delete).
#   DiskOpen / DiskClose do not modify FS metadata.
       @POPNULL
       @CALL DirFindFree       # Searches Disk for free DIR entry.
       @IF_NOTZERO
          # Create New Disk entry, give it filename and then reclose it to prepare FS
          @POPI FileNum
          @Call(V) FSSetFileUsed FileNum
          @IF_ZERO
             @PRT "Error setting FS Bitmap\n"
             @MA2V 0 FilePointer
             @POPNULL
             @JMP FO_Exit
          @ENDIF
          @POPNULL
          @PUSHI NewFlag @OR FP_OPEN_CREATE @POPI NewFlag
          @Call(VV) DiskOpen FileNum NewFlag @IF_ZERO @PRT "Failed to Open File" @END @ENDIF
          @POPI FilePointer
          @Call(VV) DiskFileName FilePointer FileName

          
          @CALL FSWriteHeader  @IF_ZERO @PRT "Failed to write FS data to disk" @POPNULL @END @ELSE @POPNULL @ENDIF
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
          @PRT "Error Disk could not allocate space for File.\n"
          @MA2V 0 FilePointer
          @JMP FO_Exit
       @ENDIF
    @ENDIF
    # Open File and return FilePointer to caller
    
    @Call(VV) DiskOpen FileNum NewFlag @IF_ZERO @PRT "Failed to open file" @END @ENDIF
    
    @POPI FilePointer
    
    # Now set cursor based on if in an APPEND mode or not.
    @PUSHI NewFlag @AND FP_OPEN_APPEND
    @IF_NOTZERO
       @POPNULL
       @PUSHI FilePointer @ADD FPTR_FILESIZE @PUSHS   # Get Current FileSize low word
       @PUSHI FilePointer @ADD FPTR_CURSOR @POPS      # Save Low Word as Cursor
       @PUSHI FilePointer @ADD FPTR_FILESIZE+2 @PUSHS # Get Current FileSize High word
       @PUSHI FilePointer @ADD FPTR_CURSOR+2 @POPS    # Save High Word as Cursor
    @ELSE
       @POPNULL
       @PUSH 0 @PUSHI FilePointer @ADD FPTR_CURSOR @POPS   # Low word Cursor
       @PUSH 0 @PUSHI FilePointer @ADD FPTR_CURSOR+2 @POPS # High word Cursor
    @ENDIF

:FO_Exit
    @PUSHI FilePointer

    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#---------------------------------------------------------
# Series of API to modify/access DIR header data.
#---------------------------------------------------------
#
#
#-----------------------------------
# DiskFileSetLineCount(FilePtr, LineCount)
#-----------------------------------
:DiskFileSetLineCount
@PUSHRETURN
    @LocalVar FilePtr 01
    @LocalVar LineCount    02

    @POPI LineCount
    @POPI FilePtr

    @PUSHI LineCount     # Push lowest in stack for argument to SetLine_Mod
    @Call(VA) DiskWithDirEntry FilePtr _DF_SetLine_Mod

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#----------------------------------
# _DF_SetLine_Mod
# Modifies ArgTable LineNumer Field
#----------------------------------
:_DF_SetLine_Mod
@PUSHRETURN
    @LocalVar ArgTable 01
    @LocalVar LineCount     02

    @POPI ArgTable
    @POPI LineCount

    @PUSHI LineCount
    @PUSHI ArgTable
    @ADD DIR_AT_LINECOUNT
    @POPS

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#-----------------------------------
# DiskGetLineCount(FilePtr):LineCount
#-----------------------------------
:DiskGetLineCount
@PUSHRETURN
    @LocalVar FilePtr 01
    @LocalVar LineCount    02

    @POPI FilePtr

    @Call(VA) DiskWithDirEntry FilePtr _DF_GetLine_Mod

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#----------------------------------
# _DF_GetLine_Mod
# Modifies ArgTable LineNumer Field
#----------------------------------
:_DF_GetLine_Mod
@PUSHRETURN
    @LocalVar ArgTable 01

    @POPI ArgTable

    @PUSHI ArgTable
    @ADD DIR_AT_LINECOUNT
    @PUSHS

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#-----------------------------------
# DiskSetFileType(FilePtr, TypeWord)
#-----------------------------------
:DiskFileSetType
@PUSHRETURN
    @LocalVar FilePtr 01
    @LocalVar Type    02

    @POPI Type
    @POPI FilePtr

    @PUSHI Type       # Push lowest in stack argument to SetType_Mod funciton
    @Call(VA)  DiskWithDirEntry FilePtr _DF_SetType_Mod

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#----------------------------------
# _DF_SetType_Mod
# Modifies ArgTable SetType Field
#----------------------------------
:_DF_SetType_Mod
@PUSHRETURN
    @LocalVar ArgTable 01
    @LocalVar Type     02

    @POPI ArgTable
    @POPI Type

    @PUSHI Type
    @PUSHI ArgTable
    @ADD DIR_AT_FILETYPE
    @POPS

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#-----------------------------------
# DiskGetFileType(FilePtr):TypeWord
#-----------------------------------
:DiskFileGetType
@PUSHRETURN
    @LocalVar FilePtr 01
    @LocalVar Type    02

    @POPI FilePtr

    @Call(VA) DiskWithDirEntry FilePtr _DF_GetType_Mod

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#----------------------------------
# _DF_GetType_Mod
# Modifies ArgTable SetType Field
#----------------------------------
:_DF_GetType_Mod
@PUSHRETURN
    @LocalVar ArgTable 01
    @LocalVar Type     02

    @POPI ArgTable

    @PUSHI ArgTable
    @ADD DIR_AT_FILETYPE
    @PUSHS

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#------------------------------------
# DiskFileName
#------------------------------------
:DiskFileName
@PUSHRETURN
    @LocalVar FilePtr 01
    @LocalVar StrPtr  02

    @POPI StrPtr
    @POPI FilePtr
    @PUSHI StrPtr
    @Call(VA) DiskWithDirEntry FilePtr _DFN_Mod

    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#------------------------------
# DiskFileName Modifier function.
#------------------------------
:_DFN_Mod
@PUSHRETURN
    @LocalVar ArgTable 01
    @LocalVar StrPtr   02
    @LocalVar Len      03

    @POPI ArgTable
    @POPI StrPtr
    @Call(V) strlen StrPtr
    @IF_GT_A 31
        @PUSH 0
        @PUSHI StrPtr @ADD 31
        @POPS
        @POPNULL
        @CALL strlen StrPtr
    @ENDIF
    @POPI Len

    @Call(VVV) strncpy ArgTable StrPtr Len
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET


#-----------------------------------------
# DiskWithDirEntry(FilePtr, ModifierFn)
#
# This is a generic functon, that when called is passed a pointer to a
# modifier funciton that modifies the ArgTable, which is then written back
#-----------------------------------------
:DiskWithDirEntry
@PUSHRETURN
    @LocalVar FilePtr     01
    @LocalVar ModFn       02
    @LocalVar ArgTable    03
    @LocalVar DiskBuffer  04
    @LocalVar FileNum     05

    @POPI ModFn
    @POPI FilePtr

    # Allocate ArgTable
    @CALL DirNewArgTable @IF_ZERO @PRT "Error Allocating ArgTable" @END @ENDIF
    @POPI ArgTable
    @IF_EQ_AV -1 ArgTable
        @PRT "DiskWithDirEntry: ArgTable alloc failed\n"
        @JMP DWDE_EXIT
    @ENDIF

    # Allocate DiskBuffer
    @CALL DiskNewBuffer
    @POPI DiskBuffer
    @IF_EQ_AV -1 DiskBuffer
        @PRT "DiskWithDirEntry: DiskBuffer alloc failed\n"
        @JMP DWDE_EXIT
    @ENDIF

    # FileNum = FilePtr->FileNum
    @PUSHI FilePtr
    @ADD FPTR_FILENUM
    @PUSHS
    @POPI FileNum

    # Read DIR entry
    @Call(VVV) DirReadEntry FileNum ArgTable DiskBuffer
    @IF_ZERO
        @POPNULL
        @PRT "DiskWithDirEntry: DirReadEntry failed\n"
        @JMP DWDE_EXIT
    @ENDIF
    @POPNULL

    # Call modifier: ModFn(ArgTable)
    @PUSHI ArgTable
    @CALLI ModFn

    # Write DIR entry
    @Call(VVV) DirWriteEntry FileNum ArgTable DiskBuffer @IF_ZERO @PRT "Disk Writer Error" @END @ELSE @POPNULL @ENDIF

:DWDE_EXIT
    @IF_NEQ_AV -1 DiskBuffer
        @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
        @POPNULL
    @ENDIF

    @IF_NEQ_AV -1 ArgTable
        @Call(VV) HeapDeleteObject DiskHeap ArgTable
        @POPNULL
    @ENDIF

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#--------------------------------
# FSReadHeader(DISK_NUMBER):1|0 # Reads filesystem superblock (FS header) and establishes FS context
#--------------------------------
:FSReadHeader
@PUSHRETURN
    @LocalVar DiskBuffer 01
    @LocalVar _I 02
    @LocalVar DISKNUM 03

    @POPI DISKNUM
    @MV2V DISKNUM FSDiskNumStore      # We keep this so WriteHeader does not require param.

    @Call(VA) HeapNewObject DiskHeap SECTOR_SIZE
    @POPI DiskBuffer

    @DISKSELI DISKNUM                 # Reading Disk Header is really the only time to select DISKID
    @Call(AV) DiskReadSector 0 DiskBuffer


    @PUSHII DiskBuffer
    @IF_NEQ_A 0x3044
       # FSMagicID = 'D0' (0x44,0x30) little-endian word 0x3044
       @POPNULL
       @PRT "DISK " @PRTHEXI DISKNUM @PRT " is not formated."
       @MA2V 0 FSHeadValidStore    # Mark the disk data as bad
       @MA2V -1 FSDiskNumStore     # Make sure other functions know this is invalid.
       @PUSH 0
       @JMP FSRH_Exit
    @ELSE
       @POPNULL
       @PUSHI DiskBuffer @ADD FSDiskID @PUSHS @POPI FSDiskIDStore
       @PUSHI DiskBuffer @ADD FSCreateTimeID
       @DUP
       @PUSHS @POPI FSCreateTimeStore
       @ADD 2 @PUSHS @POPI FSCreateTimeStore+2
       @PUSHI DiskBuffer @ADD FSActiveFilesID @PUSHS @POPI FSActiveFilesStore
       @PUSHI DiskBuffer @ADD FSHeaderFlagsID @PUSHS @POPI FSHeaderFlagStore
       @PUSHI DiskBuffer @ADD FSFileBitMapID
       @ForIA2B _I 0 64
          @DUP                       # Copy of DiskBuffer start address
          @ADDI _I
          @PUSHS                     # Get Value of at offset
          @PUSH FSFileBitMapStore @ADDI _I  # Location to put it.
          @POPS
       @NextBy _I 2
       @POPNULL                      # Get rid of base DiskBuffer offset
       @MA2V 1 FSHeadValidStore    # Mark disk data as valid
   @ENDIF
   @PUSHI FSHeadValidStore
   # Always delete DiskBuffer
   @Call(VV) HeapDeleteObject DiskHeap DiskBuffer @IF_NOTZERO @POPNULL  @PRT "Memory Error:" @END @ELSE @POPNULL @ENDIF
   :FSRH_Exit
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

#----------------------------------------
# FSWriteHeader() Stores current FS Disk meta data back to disk.
#----------------------------------------
:FSWriteHeader
@PUSHRETURN
    @LocalVar DiskBuffer 01
    @LocalVar _I 02
    @LocalVar TestVal 03

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
    @POPI DiskBuffer
    @Call(AV) DiskReadSector 0 DiskBuffer
    #
    @PUSHI DiskBuffer @ADD FSDiskID @PUSHS
    @IF_NEQ_V FSDiskIDStore
       # Disk does not have matching ID
       @MA2V 0 TestVal
    @ENDIF
    @POPNULL
    @PUSHII DiskBuffer
    @IF_NEQ_A 0x3044
       @MA2V 0 TestVal       # Is magic number fails, disk is swapped.
    @ENDIF
    @POPNULL

    @IF_EQ_AV 1 TestVal
      # Only continue is all it right.
      # While we grab all the fields, we do not allow this functio to rewrite fixed value fields
      # like DISKID or Magic Number or create time. A format command would do all that.
      @PUSHI FSActiveFilesStore
      @PUSHI DiskBuffer @ADD FSActiveFilesID  @POPS
      #
      @PUSH FSFileBitMapStore
      @ForIA2B _I 0 64
         @DUP
         @ADDI _I
         @PUSHS
         @PUSHI DiskBuffer @ADD FSFileBitMapID
         @ADDI _I
         @POPS
      @NextBy _I 2
      @POPNULL # Drop Original FSFileBitMapID offset.
      #
      # Save results to Disk
      @Call(AV) DiskWriteSector 0 DiskBuffer
      @PUSH 1   # Success
    @ELSE
      @PUSH 0   # Failed tests
    @ENDIF
    # Always delete DiskBuffer
    @Call(VV) HeapDeleteObject DiskHeap DiskBuffer @IF_NOTZERO  @POPNULL @PRT "Memory Error:" @END @ELSE @POPNULL @ENDIF

    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#---------------------------------
# FSIsFileUsed(FileNum):0|1  tests if bitmap says file in use
#---------------------------------
:FSIsFileUsed
@PUSHRETURN
   @LocalVar FileNum 01
   @LocalVar _I 02
   @LocalVar ByteOffset 03
   @LocalVar BitIndex 04
   @LocalVar Mask 05

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
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#---------------------------------
# FSSetFileUsed(FileNum) Sets BitMap At FileNum spot
#---------------------------------
:FSSetFileUsed
@PUSHRETURN
   @LocalVar FileNum 01
   @LocalVar _I 02
   @LocalVar ByteOffset 03
   @LocalVar BitIndex 04
   @LocalVar Mask 05

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
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#---------------------------------
# FSClearFileUsed(FileNum) Cleats BitMap at FileNum spot
#---------------------------------
:FSClearFileUsed
@PUSHRETURN
   @LocalVar FileNum 01
   @LocalVar _I 02
   @LocalVar ByteOffset 03
   @LocalVar BitIndex 04
   @LocalVar Mask 05

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
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#--------------------------------------
# FSFindFreeFile():FileNum|0
#--------------------------------------
:FSFindFreeFile
@PUSHRETURN
    @LocalVar _I       01

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
    @RestoreVar 01
@POPRETURN
@RET
#--------------------------------------
# FSFormat(DiskID, DiskNum)
# Format DiskNum and applies DiskID
#--------------------------------------
:FSFormat
@PUSHRETURN
    @LocalVar DiskBuffer 01
    @LocalVar _I 02
    @LocalVar DiskID 03
    @LocalVar DiskNum 04

    @POPI DiskNum
    @POPI DiskID

    @DISKSELI DiskNum
    # Setup Storage
    @Call(VA) HeapNewObject DiskHeap SECTOR_SIZE
    @POPI DiskBuffer
    #
    @Call(AV) DiskReadSector 0 DiskBuffer
    #
    # First zero whole sector out to remove old data.
    @ForIA2B _I 0 510
       @PUSH 0
       @PUSHI DiskBuffer
       @ADDI _I
       @POPS
    @NextBy _I 2
    #
    # Now Fill in fixed fields
    #
    @PUSH 0x3044
    @PUSHI DiskBuffer @ADD FSMagicID
    @POPS
    #
    @PUSHI DiskID
    @PUSHI DiskBuffer @ADD FSDiskID
    @POPS
    #
    @GETTIME     # 32 value
    @PUSHI DiskBuffer @ADD FSCreateTimeID
    @POPS
    @PUSHI DiskBuffer @ADD FSCreateTimeID+2
    @POPS
    #
    @PUSH 4             # 4 covers the 4 reserved files.
    @PUSHI DiskBuffer @ADD FSActiveFilesID
    @POPS
    #
    # First 4 blocks are reserved mark them as in use
    @PUSH 0b1111
    @PUSHI DiskBuffer @ADD FSFileBitMapID
    @POPS
    #
    # Now save the DiskBuffer Back
    @Call(AV) DiskWriteSector 0 DiskBuffer
    # Always cleanup DiskBuffer
    @Call(VV) HeapDeleteObject DiskHeap DiskBuffer @IF_NOTZERO  @PRT "Memory Error:" @END @ELSE @POPNULL @ENDIF
    #
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#-----------------------------------
# FSNextUsedFile(Index):FileNum
# Utility to find next used file, skipping blocks of unused files.
#-----------------------------------
:FSNextUsedFile
@PUSHRETURN
    @LocalVar _I 01
    @LocalVar Word 02

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
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET

#--------------------------------------------
# FSFindFile(Pattern, StartPoint): FileNum | 0
# Bitmap-driven filename search using FSNextUsedFile
#--------------------------------------------
:FSFindFile
@PUSHRETURN
    @LocalVar Pattern     01
    @LocalVar StartPoint  02
    @LocalVar FileNum     03
    @LocalVar DiskBuffer  04
    @LocalVar ArgTable    05

    @POPI StartPoint
    @POPI Pattern

    # Allocate working buffers
    @CALL DiskNewBuffer
    @POPI DiskBuffer

    @CALL DirNewArgTable @IF_ZERO @PRT "Error Allocating ArgTable" @END @ENDIF
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
    @Call(VVV) DirReadEntry FileNum ArgTable DiskBuffer
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
    @Call(VV) HeapDeleteObject DiskHeap DiskBuffer
    @POPNULL
    @Call(VV) HeapDeleteObject DiskHeap ArgTable
    @POPNULL

    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#--------------------------------------------
# DiskFileReadLine(FilePtr, MemPtr):Bytes_Read
# Read file as stream, looking for LF ('\n')
# Needs to handle EOF as both EOF and EOL
#--------------------------------------------
:DiskFileReadLine
@PUSHRETURN
    @LocalVar FilePtr   01
    @LocalVar MemPtr    02
    @LocalVar Consumed  03

    @POPI MemPtr
    @POPI FilePtr

    @MA2V 0 Consumed
    @WHEN
       @Call(VVA) DiskFileRead FilePtr MemPtr 1
    @DO_NOTZERO
       @POPNULL
       @PUSHII MemPtr
       @AND 0xff
       @IF_EQ_A 10     # New Line
          # END of Line detected, turn into terminator.
          @POPNULL
          @PUSHII MemPtr
          @AND 0xff00      # Zero low byte
          @POPII MemPtr
          @JMP DFRL_ENDLINE
       @ELSE
          @POPNULL
       @ENDIF
       @INCI Consumed
       @INCI MemPtr
    @ENDWHEN
    @POPNULL 
    :DFRL_ENDLINE
    @PUSHI Consumed

    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET






M SIZESINCECOMMENT diskos.ld
@SIZESINCE
ENDBLOCK
