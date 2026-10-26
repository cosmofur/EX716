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
