# EXC01 executable format

EXC01 stores a finalized CPU24 memory image as a 512-byte header followed by
contiguous 512-byte payload sectors. Multibyte fields are little-endian.

## Header

| Offset | Size | Meaning |
|---:|---:|---|
| 0 | 5 | ASCII magic `EXC01` |
| 5 | 1 | Entry Memory Segment (initial `CS`) |
| 6 | 2 | Entry address |
| 8 | 1 | Initial `DS` (`ES` is initialized to the same MS) |
| 9 | 1 | Descriptor count, at most 125 |
| 10 | 4 × count | Descriptor table |
| following | variable | NUL-terminated ASCII loading message |
| remainder | variable | Zero padding through byte 511 |

Each descriptor contains a one-byte type, one-byte destination Memory Segment,
and a two-byte count of 512-byte sectors. Type 0 is a normal mixed code/data
image and type 1 marks a data-oriented image. Both load identically. Counts are
1 through 128, so every descriptor loads at offset zero and occupies at most
one 64 KiB Memory Segment. A Memory Segment may appear only once.

Payload sectors occur in descriptor order beginning at file offset 512. The
file has no trailing data: its size must be 512 plus 512 times the sum of all
descriptor sector counts.

## CPU24 usage

Assemble and write an executable beside the source:

```text
python3 cpu24.py --exe --exe-message "Loading program" program.asm
```

This creates `program.exc`. CPU24 recognizes EXC01 by its magic and executes it
without running the assembler:

```text
python3 cpu24.py program.exc
```

An EXC01 file contains no source map or symbols, so source-level debugger
features are available only when running the assembly source.

## Native DiskOS exec

`lib/exec.ld` provides a destructive native loader and a launcher-oriented
call/reload path:

```text
ExecFile(FileName, ArgCount, ArgVector):error
ExecCall(FileName, ArgCount, ArgVector, ReturnFileName):error
```

The supplied argument vector contains `ArgCount` near string pointers and does
not include `argv[0]`; the loader prepends `FileName`. Failure returns one of
the `EXEC_*` status constants. Success replaces the caller and never returns.

`ExecFile` succeeds by replacing the caller and never returns. `ExecCall`
prepares both its target and `ReturnFileName`, loads the target from reserved
MS 255, and reloads `ReturnFileName` when the target exits through the loader
gateway. It therefore also does not return directly to its original caller.

Stage 1 uses DiskOS to open each file, validate its EXC01 header and exact
file size, follow the complete extent chain, and construct a physical-sector
plan. Stage 2 runs from reserved MS 255, reads payload sectors through raw
disk operations, copies them into their destination Memory Segments, and
far-jumps to the entry point. MS 255 holds the active Stage 2
loader. A launcher that links `exec.ld` also carries that segment in its EXC01
payload; the loader consumes its payload sectors but deliberately does not
copy them over the active loader.

An `ExecCall` target is a callable program, not an `@END`-terminated image.
Include `exec.mc` and use `@ExecExit status` to exit. It pushes the 16-bit
status and far-jumps to the fixed resident-loader gateway at `255:0x0e00`.
The gateway stores the status, marks the continuation ARG1 block as returned,
and reloads the continuation image; it never returns to the child.

### ARG1 launch block

On entry to the replacement program, `ES` is 255 and `ES:0xfe00` contains one
512-byte launch area. Only the serialized portion is written; remaining bytes
are reserved. The executable starts with `CS:PC` and `DS` from EXC01.

| Offset | Size | Meaning |
|---:|---:|---|
| 0 | 4 | ASCII `ARG1` |
| 4 | 2 | Serialized size |
| 6 | 2 | `argc`, including synthesized `argv[0]` |
| 8 | 2 | Flags; bit 0 is set after an `ExecCall` child returns |
| 10 | 2 | Argument-offset table offset, currently 16 |
| 12 | 2 | String-area offset |
| 14 | 2 | Child exit status when flag bit 0 is set; otherwise zero |
| 16 | variable | `(argc + 1)` relative offsets; final entry is zero |
| following | variable | NUL-terminated argument strings |

At most 31 caller arguments are accepted, producing at most 32 entries after
`argv[0]` is added. The complete header, table, and strings must fit in 512
bytes. A C startup shim can copy these strings from ES into normal DS-relative
storage and then call `main(argc, argv)`.
