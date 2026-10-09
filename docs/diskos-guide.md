# DiskOS Guide

DiskOS (`lib/diskos.ld`) is EX716's small native filesystem library. It builds
named, sequential files over the emulator's 512-byte sector device. It is not
FAT16: `fat16lib.ld` is a separate library.

DiskOS favors a fixed, inspectable layout over space efficiency. Data is
allocated in contiguous 64 KiB blocks. Directory entries identify data blocks
separately from file numbers; a root entry can link continuation entries to
represent a larger file.

## 1. Heap dependency, initialization, and ownership

DiskOS depends heavily on `heapmgr.ld`. It has no permanent static sector
buffer: it allocates sector buffers, directory argument tables, open-file
objects, and several search/metadata temporaries from a caller-owned heap. A
program must initialize the heap, give its ID to DiskOS, and load the
filesystem header before opening by name.

At minimum, a successful open keeps a 20-byte file-pointer object and a
128-byte directory argument table alive until close. Normal operations also
need transient 512-byte sector buffers, while name searches and metadata work
may overlap additional allocations. Leave comfortable headroom beyond the
requested application buffer; do not size the heap for only the two persistent
objects.

```assembly
I common.mc
L softstack.ld
L heapmgr.ld
L string.ld
L diskos.ld

:MainHeap 0

:Main . Main
    @PUSH _END_
    @PUSH 0xff00 @SUB _END_
    @CALL HeapDefineMemory
    @POPI MainHeap

    @Call(V) SetDiskHeap MainHeap
    @Call(A) FSReadHeader 0       # select and validate DISK00.disk
    @IF_ZERO
        @POPNULL
        @PRTLN "DiskOS header is invalid"
        @END
    @ENDIF
    @POPNULL
```

`FSReadHeader(DiskNum)` selects the virtual disk, verifies magic word `0x3044`
(`D0` in little-endian bytes), and caches its allocation bitmap. Call it once
per disk context. `FSFormat(DiskID, DiskNum)` creates a DiskOS header and should
only be used when intentionally formatting a disk.

Objects returned by DiskOS belong to the configured heap. `DiskClose` frees an
open file pointer and its directory table; the pointer is invalid afterward.
The heap and the memory range backing it must outlive every open file.

| Heap-backed item | Lifetime/owner |
| --- | --- |
| Open-file pointer (`FILEPTR_SIZE`, 20 bytes) | Returned by `DiskOpen`/`file_open`; released by `DiskClose`. |
| Directory argument table (`ARGTABLE_SIZE`, 128 bytes) | Retained inside the open-file pointer; released by `DiskClose`. |
| Sector buffer (`SECTOR_SIZE`, 512 bytes) | Allocated transiently by header, directory, read, and write operations, then released internally. |
| Name/search and metadata results | Ownership follows the individual API; notably, a string returned by `DiskGetFileName` is a new heap object the caller must release. |

Heap allocation failures commonly surface as zero/error returns plus
`ERR:MEM`. `DiskNewBuffer` and `DirNewArgTable` normalize heap-manager error
IDs below 100 to zero, so their callers can branch safely on a null result.
Other direct heap allocations still require checking their documented error
range.

## 2. Physical disk organization

| Region | Sector/block location | Purpose |
| --- | --- | --- |
| Filesystem header | first 128 bytes of sector 0 | Magic, disk identity, creation time, active count, flags, and the 512-bit file-allocation bitmap. |
| Directory | block 0: sectors 0-127 | 512 fixed 128-byte entries; four entries fit in each 512-byte sector. Entry 0 overlaps the filesystem header. |
| Reserved objects | directory entry 0; data blocks 1-3 | Entry 0 stores filesystem metadata. Physical data blocks 1-3 are reserved; directory entries 1-511 remain valid file slots. |
| File data | blocks 4-511 | Contiguous 64 KiB blocks (128 sectors each), identified by each extent entry's `DIR_FIRSTBLOCK`. |

The directory occupies one complete 64 KiB block. Directory index and file
number are the same, so `DirLocate` computes the directory sector and offset.
File data starts at the block named by `DIR_FIRSTBLOCK`; it is not necessarily
the same number as the root directory entry.

The 32-bit file size and cursor describe the whole logical file. Both
`DiskFileRead` and `DiskFileWrite` follow linked extent entries and can span
their boundaries. Writes allocate a one-block continuation when the cursor
reaches the end of the current chain. The runtime currently supports files
whose total allocation fits in the available 64 KiB data blocks.

## 3. Filesystem header table

The header begins at byte 0 of directory entry 0.

| Offset | Symbol | Size | Meaning |
| ---: | --- | ---: | --- |
| `0x00` | `FSMagicID` | 2 | Format signature, word `0x3044`. |
| `0x02` | `FSDiskID` | 2 | Caller-selected disk identity. |
| `0x04` | `FSCreateTimeID` | 4 | Creation time recorded by `FSFormat`. |
| `0x08` | `FSActiveFilesID` | 2 | Number of visible root files; continuation slots are excluded. |
| `0x0A` | `FSHeaderFlagsID` | 2 | Filesystem-level flags. |
| `0x0C` | `FSFileBitMapID` | 64 | 512 allocation bits, one per file number. |
| `0x4C` | `FSReservedID` | 52 | Reserved portion through the 128-byte entry boundary. |

The cached bitmap is authoritative for slot allocation. Bit 0 is reserved for
the header; file and continuation slots may use directory numbers 1-511.
Formatting initializes the visible-file count to zero. Name-based creation
uses `FSSetFileUsed` and `FSWriteHeader`; extent allocation and trimming update
the continuation bits while keeping them out of the visible-file count.

## 4. Directory entry table

| Offset | Symbol | Size | Meaning |
| ---: | --- | ---: | --- |
| `0x00` | `DIR_FILENAME` | 32 | Optional NUL-terminated name; maximum configured name length is 31 bytes. |
| `0x20` | `DIR_FLAGS` | 2 | `INUSE`, `DELETED`, and reserved read-only/system/executable bits. |
| `0x22` | `DIR_FILENUM` | 2 | File number, normally equal to the directory slot. |
| `0x24` | `DIR_FILESIZE` | 4 | Logical byte length. |
| `0x28` | `DIR_FIRSTBLOCK` | 2 | First physical data block for this extent. |
| `0x2A` | `DIR_BLOCKCOUNT` | 2 | Number of contiguous 64 KiB blocks in this extent. |
| `0x2C` | `DIR_LINECOUNT` | 2 | Optional line-oriented metadata. |
| `0x2E` | `DIR_FILETYPE` | 2 | Application-defined file type. |
| `0x30` | `DIR_TIMESTAMPS` | 8 | Creation/update timestamp area maintained by normal directory writes. |
| `0x38` | `DIR_CRC` | 8 | Reserved checksum area. |
| `0x40` | `DIR_RESERVE` | 64 | Reserved expansion space. |

`DirReadEntry` converts this physical form into a heap-backed argument table.
`DirWriteEntry` applies normal metadata policy; `DirWriteRawEntry` writes the
provided fields verbatim and is intended for low-level tools.

## 5. Open modes and file pointers

The friendly `file_open(Name, Mode)` accepts two-character mode words:

| Mode | Symbol | Behavior |
| --- | --- | --- |
| `ro` | `MODE_RO` | Existing file, read only, cursor at zero. |
| `wo` | `MODE_WO` | Write-only access. The current implementation does not itself imply truncation. |
| `rw` | `MODE_RW` | Existing file, read and write, cursor at zero. |
| `w+` | `MODE_WP` | Create if missing and open for writing/appending at EOF. |
| `a+` | `MODE_AP` | Create if missing, read/write, cursor at EOF. |

`file_open` searches names and maintains header allocation state for new files.
`DiskOpen(FileNum, Flags)` is the lower-level numeric API and accepts
`FP_OPEN_READ`, `FP_OPEN_WRITE`, `FP_OPEN_APPEND`, and `FP_OPEN_CREATE` bits.
`FP_OPEN_CREATE` creates an absent entry; opening an existing entry does not
truncate it. A caller that wants truncation must reset the in-memory file size
and cursor and let `DiskClose` commit the new size.

An open file pointer is a 20-byte heap object:

| Offset | Field | Meaning |
| ---: | --- | --- |
| 0 | `FPTR_FILENUM` | Directory/file number. |
| 2 | `FPTR_FIRST_SECTOR` | First physical data sector. |
| 4 | `FPTR_FILESIZE` | 32-bit logical file size. |
| 8 | `FPTR_CURSOR` | 32-bit next-read/write position. |
| 12 | `FPTR_MODE` | Open permission and create/append flags. |
| 14 | `FPTR_CURRENT_ENTRY` | Reserved/current-entry field. |
| 16 | `FPTR_META_FLAGS` | In-memory metadata state. |
| 18 | `FPTR_ARGTABLE` | Heap pointer to the persistent directory fields. |

`DiskClose` commits size/metadata for writable handles, trims blocks past the
logical end, marks detached continuation entries deleted, clears their file
bitmap bits, and frees both objects. It keeps the root's first data block even
when the logical size is zero. It returns `1` on success and `0` on failure.

## 6. Read a file line by line

`DiskFileReadLine(FilePtr, Buffer, MaxLen)` always reserves space for a NUL.
Its return word packs state in the high nibble and payload length in the low 12
bits:

| State | Meaning |
| --- | --- |
| `LINE_OK | length` | A complete line was read. LF was consumed but is not in the buffer. A final unterminated line also succeeds. |
| `LINE_PARTIAL | length` | The buffer filled before LF. Call again for the next fragment, or reject/skip the overlong physical line. |
| `LINE_EOF` | EOF occurred before this call read any byte. |
| `LINE_NO_ROOM` | `MaxLen` was 0 or 1, leaving no payload space while preserving NUL termination. |

```assembly
=INPUT_SIZE 128
:FileName "NOTES.TXT\0"
:InputBuffer
. InputBuffer+INPUT_SIZE
:FilePtr 0
:LineState 0
:LineLength 0

    @Call(AA) file_open FileName MODE_RO
    @POPI FilePtr
    @IF_EQ_AV 0 FilePtr
        @PRTLN "Open failed"
        @JMP ReadDone
    @ENDIF

:ReadNext
    @Call(VAA) DiskFileReadLine FilePtr InputBuffer INPUT_SIZE
    @DUP @AND LINE_STATE_MASK @POPI LineState
    @AND LINE_LEN_MASK @POPI LineLength

    @IF_EQ_AV LINE_EOF LineState
        @JMP ReadClose
    @ENDIF
    @IF_EQ_AV LINE_NO_ROOM LineState
        @PRTLN "Input buffer is too small"
        @JMP ReadClose
    @ENDIF
    @IF_EQ_AV LINE_PARTIAL LineState
        @PRTLN "Line is longer than the input buffer"
        # This fragment is valid NUL-terminated text. A real parser can append
        # it, or keep reading fragments until LineState is no longer PARTIAL.
    @ENDIF

    @PRTSI InputBuffer @PRTNL
    @JMP ReadNext

:ReadClose
    @Call(V) DiskClose FilePtr
    @POPNULL
:ReadDone
```

The loop decodes state before length because `LINE_EOF` (`0xf000`) otherwise
looks like a zero-length result. Empty lines are valid `LINE_OK | 0` results.

## 7. Write a file line by line

DiskOS exposes byte writes, so line-oriented output is a byte write whose
buffer includes `\n`. Check the returned count for short writes.

```assembly
:FileName "REPORT.TXT\0"
:LineOne "first line\n\0"
:LineTwo "second line\n\0"
:FilePtr 0
:Expected 0

    @Call(AA) file_open FileName MODE_WP
    @POPI FilePtr
    @IF_EQ_AV 0 FilePtr
        @PRTLN "Open failed"
        @JMP WriteDone
    @ENDIF

    @Call(A) strlen LineOne
    @POPI Expected
    @Call(VAV) DiskFileWrite FilePtr LineOne Expected
    @IF_NEQ_V Expected
        @POPNULL
        @PRTLN "Short write"
        @JMP WriteClose
    @ENDIF
    @POPNULL

    @Call(A) strlen LineTwo
    @POPI Expected
    @Call(VAV) DiskFileWrite FilePtr LineTwo Expected
    @IF_NEQ_V Expected
        @POPNULL
        @PRTLN "Short write"
        @JMP WriteClose
    @ENDIF
    @POPNULL

:WriteClose
    @Call(V) DiskClose FilePtr
    @IF_ZERO
        @POPNULL
        @PRTLN "Close/metadata commit failed"
    @ELSE
        @POPNULL
    @ENDIF
:WriteDone
```

`MODE_WP` means create-if-needed plus append positioning. It does not itself
truncate an existing file. C stdio implements C `w` modes by explicitly
setting the open pointer's file size and cursor to zero before close commits
the updated metadata.

## 8. Raw reads, writes, and close discipline

`DiskFileRead(FilePtr, MemPtr, ByteCount)` and
`DiskFileWrite(FilePtr, MemPtr, ByteCount)` advance the cursor and return the
actual byte count. `DiskFileRead` accepts a 16-bit count, so a single call can
read at most 65535 bytes, though it can cross any number of extent boundaries.
A positive request at EOF returns zero; a request that reaches EOF returns the
bytes read before EOF. A count of `-1` requests 65535 bytes. Buffers must be
large enough for the requested data.

`DiskWriteBlock(Sector, MemPtr, ByteCount, StartOffset, Buffer)` also returns
the number of bytes copied, after clamping a request that would wrap the
16-bit memory address space. Assembly callers must consume that result or use
`@POPNULL` when they do not need it. `DiskFileWrite` consumes the count to
advance its cursor only by bytes actually written.

Always close every nonzero file pointer, including after parse errors or short
I/O. Do not separately free a file pointer or its `FPTR_ARGTABLE`; `DiskClose`
owns that cleanup. Conversely, if open returns zero, there is nothing to close.
Do not destroy or reinitialize the configured heap while a file remains open.

## 9. Host-side image utility

`filesys/ex716disk.py` manages DiskOS images without running the emulator:

```sh
python3 filesys/ex716disk.py info filesys/DISK00.disk
python3 filesys/ex716disk.py dir filesys/DISK00.disk
python3 filesys/ex716disk.py import filesys/DISK00.disk local.txt --name NOTES.TXT
python3 filesys/ex716disk.py export filesys/DISK00.disk NOTES.TXT -o local-copy.txt
python3 filesys/ex716disk.py check filesys/DISK00.disk
```

Mutating utility commands create a `.bak` image unless `--no-backup` is given.
When creating an image for the current runtime, explicitly use
`format ... --magic 0x3044`: the Python utility's current provisional default
is `0x0716`, but `diskos.ld` rejects any signature other than `0x3044`.

The image utility implements linked extents for files larger than 64 KiB.
`DiskFileRead` and `DiskFileWrite` consume those chains; runtime writes add
one-block continuations as needed. Keep total files within available disk
capacity; multi-extent files beyond that capacity are not supported.
