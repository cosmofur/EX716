# EX716 DiskOS image tool

`ex716disk.py` manages EX716 `Disk##.disk` images.

## Commands

```sh
chmod +x ex716disk.py

./ex716disk.py format Disk01.disk --disk-id 1
./ex716disk.py info Disk01.disk
./ex716disk.py dir Disk01.disk
./ex716disk.py import Disk01.disk local.bin --name PROGRAM.BIN
./ex716disk.py export Disk01.disk PROGRAM.BIN -o local-copy.bin
./ex716disk.py rename Disk01.disk PROGRAM.BIN NEWNAME.BIN
./ex716disk.py delete Disk01.disk NEWNAME.BIN
./ex716disk.py dir Disk01.disk --all
./ex716disk.py undelete Disk01.disk NEWNAME.BIN
./ex716disk.py check Disk01.disk
```

Mutating operations create `Disk01.disk.bak` unless `--no-backup` is used.

## Current assumptions that should be checked against `FSFormat`

1. Multi-byte integers are little-endian.
2. The default magic value is `0x0716`.
3. Timestamps are 32-bit Unix UTC timestamps.
4. The first 16-bit word of `DIR_RESERVE` is the next-extent FileNum.
5. Bitmap bit numbering is least-significant-bit first.
6. FileNum 0 is marked allocated in the filesystem bitmap.
7. The filesystem active-file count counts visible root files, not continuation
   extent entries.

All except the physical geometry and documented field offsets are isolated
constants or small methods near the top of the program.

## Extent handling

The visible root entry contains:

- filename
- total 32-bit file size
- first data block
- first extent block count
- next-extent FileNum in `DIR_RESERVE[0:2]`

Continuation entries contain:

- `FLAG_INUSE`
- their own FileNum
- first block
- block count
- next-extent FileNum
- no visible filename

Imports allocate one 64-KiB block and one directory entry per extent. The
reader and checker permit an extent to describe more than one contiguous block,
so the format can later use larger contiguous runs without changing the chain
logic.
