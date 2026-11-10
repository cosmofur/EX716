# DiskOSDS interface and execution contract

This is the application-facing v1 contract for DiskOSDS. The current assembly
implements the calls marked in `DiskOSDS-Checklist.md`; remaining calls are
still in progress. Applications use only the `DiskOS*` calls below;
DiskOS near pointers, heap IDs, directory buffers, and file-pointer layouts
remain private to DDS.

## Required application API

All external entries are far calls into DDS. Every near pointer argument is an
offset in the caller's UDS, captured at entry. A file handle is an opaque word
owned by DiskOSDS and remains valid across calls until closed. Calls are
sequential: an attempted nested/concurrent operation returns `DISKOS_E_BUSY`
without changing the active call. Several handles may remain open at once.

| Service | Signature (arguments pushed left to right) | Result |
|---|---|---|
| Initialize | `DiskOSInit(disk_number)` | `1` on success; idempotent for the already selected disk |
| Open | `DiskOSOpen(filename_offset, open_flags)` | opaque handle, or `0` |
| Close | `DiskOSClose(handle)` | `1` on success, `0` on error |
| Read | `DiskOSRead(handle, buffer_offset, byte_count)` | bytes read; short read and zero at EOF are normal |
| Write | `DiskOSWrite(handle, buffer_offset, byte_count)` | bytes written; inspect last error if short |
| Seek | `DiskOSSeek(handle, offset_low, offset_high, origin)` | `1` on success; `origin` is SET/CUR/END |
| Tell | `DiskOSTell(handle, result_offset)` | `1`; writes 32-bit cursor low word then high word to UDS |
| Size | `DiskOSSize(handle, result_size)` | `1`; writes 32-bit size low word then high word to UDS |
| Truncate | `DiskOSTruncate(handle, size_low, size_high)` | `1` on success; shrinks to the requested 32-bit size |
| Find | `DiskOSFind(pattern_offset, start_file_number)` | next matching file number, or `0` |
| Info | `DiskOSGetInfo(file_number, info_offset)` | `1`; copies the fixed `DiskOSFileInfo` record to UDS |
| Delete | `DiskOSDelete(filename_offset)` | `1` on success; fails if the file is open |
| Last error | `DiskOSLastError()` | most recent `DISKOS_E_*` value; query does not clear it |

`DiskOSInit` owns the DDS heap and loads the selected disk's filesystem header.
The library chooses its private heap range from linker-reserved DDS ranges; an
application never supplies or receives a DiskOS heap ID. Calls before a
successful init fail with `DISKOS_E_NOT_INITIALIZED`. Init on a different disk
after success fails with `DISKOS_E_ALREADY_INITIALIZED`; applications must
close all handles before shutdown/reinitialization. Disk switching is not a
v1 operation. `DISKOS_MAX_OPEN_FILES` is 16; opening a seventeenth live handle
returns `DISKOS_E_TOO_MANY_OPEN`.

Open uses flags so create, truncate, and append behavior stays explicit:
`DISKOS_OPEN_READ=0x0001`, `DISKOS_OPEN_WRITE=0x0002`,
`DISKOS_OPEN_CREATE=0x0004`, `DISKOS_OPEN_TRUNCATE=0x0008`, and
`DISKOS_OPEN_APPEND=0x0010`. At least READ or WRITE is required. CREATE,
TRUNCATE, and APPEND require WRITE; TRUNCATE also requires CREATE. Existing
files are preserved unless TRUNCATE is set. APPEND moves the cursor to EOF
before each write, even after a seek.
CREATE permits a missing file to be created. Unknown or invalid combinations
fail with `DISKOS_E_ARGUMENT`. Filenames are NUL-terminated in UDS, limited
to 31 bytes, and copied into DDS before any DiskOS call. A missing name
without CREATE returns `DISKOS_E_NOT_FOUND`.

Buffer operations take an explicit byte count. A zero-byte request succeeds
without touching the buffer. A nonzero UDS range must not wrap the 16-bit
offset space; because transfers use word memory operations, its final byte
must be at most `0xfffe`. Invalid ranges fail with `DISKOS_E_RANGE` before
advancing the file cursor. Reads stop at EOF and return the actual count.
Writes may be partial; the returned count is authoritative and last-error
distinguishes a short transfer caused by storage failure.

Seek origins are `DISKOS_SEEK_SET`, `DISKOS_SEEK_CUR`, and `DISKOS_SEEK_END`.
The offset is a signed 32-bit two-word value (low then high); negative or
greater-than-32-bit resulting positions fail. `Tell` and `Size` write words in
little-endian word order. Truncate accepts an absolute unsigned 32-bit size,
only shrinks the current file, clamps the cursor to the new end, and persists
the new size when the handle is closed. Extending by truncate is rejected;
applications can extend by writing bytes.

`DISKOS_SEEK_SET=0`, `DISKOS_SEEK_CUR=1`, and `DISKOS_SEEK_END=2`.
`DiskOSFind` uses the existing wildcard matching rules and scans from the
provided file number inclusively; callers pass 1 for the first lookup and
previous-result+1 for the next. `DiskOSGetInfo` copies this fixed record to
UDS. Offsets and sizes use CPU24 word-address units; each filename byte
is stored using the normal CPU24 string convention: one character in the low
byte of each successive word, followed by a NUL character. This is the same
format consumed by the existing `strlen`, `strcmp`, and other string routines:

| Word offset | Field | Words |
|---:|---|---:|
| 0 | `file_number` | 1 |
| 1 | `flags` | 1 |
| 2 | `size_low` | 1 |
| 3 | `size_high` | 1 |
| 4 | `line_count` | 1 |
| 5 | `file_type` | 1 |
| 6 | NUL-terminated filename, zero-padded | 32 |

The record occupies 38 words; `file_number` and `size` are low-word-first.
File transfer counts are bytes, with one low-byte value in each UDS word slot.
This matches CPU24's word-addressed memory model. This is enough for DIR and
TYPE callers without exposing raw directory sectors or ArgTables.
Delete removes the exact name from the directory and frees its allocation; it
must reject a file with an open handle.

Soft errors use stable values: `DISKOS_E_NONE=0`, `DISKOS_E_BUSY=1`,
`DISKOS_E_NOT_INITIALIZED=2`, `DISKOS_E_ARGUMENT=3`, `DISKOS_E_RANGE=4`,
`DISKOS_E_NOT_FOUND=5`, `DISKOS_E_NO_SPACE=6`, `DISKOS_E_BAD_HANDLE=7`,
`DISKOS_E_IO=8`, `DISKOS_E_CORRUPT=9`, `DISKOS_E_ALREADY_INITIALIZED=10`, and
`DISKOS_E_TOO_MANY_OPEN=11`. Value-returning calls return zero on failure;
count-returning calls return the transferred count. `DiskOSLastError` provides
the corresponding detail and is reset to `DISKOS_E_NONE` when an ordinary
operation starts. Hardware/emulator faults remain fatal and are outside this
soft-error contract.

`DiskOSFormat(disk_number, disk_id)` is intentionally not part of the normal
application API because it destroys all files. A separate installer or disk
utility may expose it explicitly.

### FuncCalc and standard-I/O coverage

This surface supports `SAVE`, `LOAD`, and `TYPE` with Open/Read/Write/Seek/
Truncate/Close; `DIR` with Find/GetInfo; and `DELETE` with Delete. C standard
I/O uses Open/Close/Read/Write/Seek/Tell/Size/Truncate. Flush is not a separate
DiskOS service because writes are synchronous at the file API boundary. The
old same-segment `diskos.ld` entry points remain available to legacy callers.

## Segment and memory ownership

DDS denotes the segment reserved for DiskOSDS code, fixed service state,
temporary storage, and its local heap. UDS is the calling program's active DS
at entry. The assembler selects DDS once from `HIGH_BANK+1`; the library must
reject an unavailable/reserved bank and ensure code, state, heap and any
reserved ranges do not overlap. Merely selecting a high bank is not sufficient
if a program later claims it or reserves hardware there.

DDS fixed state records its own bank, the active operation's caller segment and
return state, a busy indicator, and the most recent soft error code. Temporary
filename and transfer buffers belong to DDS. A caller passes a normal UDS
pointer plus any required length; the gateway captures UDS before selecting
DDS and uses that captured segment for data transfers. Returned handles are
opaque references to DDS-owned open-file state, not UDS pointers. Multiple
handles must remain valid simultaneously and independently until closed.

## Calls and re-entry

Every operation has a far entry/exit usable by application code and a local
entry/exit for calls made inside DDS. Internal calls do not claim a second
external operation. An entire external file operation is non-reentrant: a
second operation attempted while one is active must fail cleanly without
altering the active operation's saved call state, heap, or file state. More
than one handle may nevertheless remain open across sequential operations.

The caller initializes the shared fixed-segment DS software stack. DiskOSDS
must not reinitialize it or change its root. A far call captures and restores
caller DS and ES on all exits, and FJMPS returns to the caller's CS and PC;
the stack pointer and all live caller frames must survive. Internal utility
calls use DDS as DS; helpers that temporarily select another segment restore
DDS before continuing. Segment preservation must be tested with real live
caller frames, not just a sentinel. The current root scratch fields and
`FENTER`/`FRET` still need a re-entry and fixed-stack audit.

## Error reporting

The fixed DDS last-error field records soft errors. A query operation retrieves
it without clearing it; the next ordinary operation starts a new error status.
A busy/re-entry failure records a busy error while leaving the active call
state intact. The current implementation reports initialization, argument,
range, allocation, handle, busy, and I/O errors through the stable codes above.
Corrupt-filesystem reporting and recovery behavior still need verification.
Existing fatal `@END` paths and hardware/emulator I/O faults cannot be assumed
to be recoverable soft errors.

An optional error-handler registration is a separate setup function: it would
store a user far callback in DDS. Callback arguments, stack/segment context,
lifetime, clear/unregister operation and timing, including whether the busy
flag is held and what happens if the callback calls DiskOSDS, must be specified
and tested before callbacks can be invoked safely. No callback is implemented
in the prototype.
