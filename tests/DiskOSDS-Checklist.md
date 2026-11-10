# DiskOSDS implementation checklist

DDS is the DiskOS segment, used for both DiskOS code and its private data and
heap. UDS is the calling application's active data segment. Callers pass near
pointers into UDS; DiskOS records UDS at each entry and transfers bytes across
the segment boundary. Existing `diskos.ld` remains available to legacy users.
The application API is specified in `DiskOSDS-Interface.md`: init, open,
close, read, write, seek, tell, size, truncate, find, get-info, delete, and
last-error. Use explicit open flags; do not expose DiskOS heap IDs, near
pointers, raw sectors, or directory ArgTables to applications.

The application initializes one fixed-segment `softstackDS` stack and DiskOSDS
shares it. DiskOSDS must never reinitialize that stack or replace its root.
The gateway captures the caller's UDS and ES before selecting DDS, stays in
DDS for DiskOS routines and their near pointers, and restores UDS and ES on
every return path. Soft-stack helpers may temporarily select the fixed stack
segment, but must restore DDS before DiskOS resumes. The existing probe uses
static return storage and is not reentrant; production entry/return must
preserve each call's state safely.

- [x] Establish a CS/DS gateway probe that preserves caller DS and ES and copies
  data in both directions. This is not a production gateway.
- [x] Demonstrate capturing `HIGH_BANK+1` once and using the captured value as
  both CS and DS after different prior code-bank selections.
- [x] Demonstrate copying a bounded, NUL-terminated filename from UDS to DDS,
  including rejection of a 32-character filename in the 32-byte buffer.
- [x] Demonstrate initialization, open, close and reopen of an existing file
  through DiskOS using a DDS-local heap and a copied UDS filename, on both
  CPU24 engines. This probe still has static gateway state and fixed ranges.
- [x] Run that probe with `softstackDS.ld` and `heapmgrDS.ld`; map DiskOS's
  legacy allocation names to the corresponding DS heap calls in the probe.
- [x] Have the caller initialize the shared DS stack and verify its selected
  segment, stack pointer and a live sentinel survive open and close calls.
  This is a probe, not yet a test with real nested application frames.
- [x] Exercise prototype DDS read/write gateways against a real disk image,
  including binary bytes, short read/EOF, zero counts, rejected UDS range
  wrapping, caller register/stack preservation, and both CPU24 engines.
  The gateways are byte-at-a-time and share the probe's static state.
- [x] Exercise repeated writes across the 64 KiB file boundary on both CPU24
  engines and verify the exported file and filesystem image.
- [x] Probe non-reentrant far-entry rejection, restoration of caller segments
  and shared stack, preservation of active call state, and querying the busy
  error. Probe two simultaneous handles with independent close operations.
  See `DiskOSDS-Interface.md` for the target contract and unresolved details.
- [ ] Select DDS from `HIGH_BANK+1` at assembly time, capture that value once,
  reserve the selected bank, reject unavailable/reserved banks and overflow,
  and test varying existing code and data bank layouts.
- [x] Export far-call entries and public constants for the current v1 services
  documented in `DiskOSDS-Interface.md`. Legacy gateway aliases remain for old
  probes and should be removed after those probes migrate.
- [ ] Establish non-overlapping DDS ranges for code, static data, heap and any
  segment-local stack, with build-time bounds checks.
- [ ] Implement far entry and return conventions that preserve UDS, ES, caller
  state, and stack frames on every return path; remove probe-only static return
  storage and establish whether nested calls are supported.
- [ ] Put DiskOS state and its required allocator/string dependencies in DDS;
  initialize an isolated DDS heap and the filesystem once, without changing UDS.
- [x] Implement `DiskOSInit` and `DiskOSOpen`: initialize the DDS-local heap
  and filesystem once; validate flags and copy the bounded UDS filename into
  DDS before calling DiskOS, then
  return an opaque file handle whose storage and resources belong to DDS.
- [x] Test open of existing/missing files and creation/truncation/append,
  invalid flags/name,
  allocation failure, repeated calls, pointer and segment boundaries, caller
  DS/ES preservation, and both execution engines on disposable disk images.
- [x] Add close, read, write, tell, size, truncate, find, get-info and
  last-error services; transfer user buffers and records through captured UDS
  with explicit lengths and safe boundary handling.
- [ ] Implement seek and delete, then test both against disposable disk images.
- [ ] Add FuncCalc SAVE, LOAD, TYPE, DIR and DELETE against the completed API.
