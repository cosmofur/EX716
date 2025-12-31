"""
fileent.py — EX716 FILE Entry Format Definition
==============================================

Defines the on-disk ABI for FILE entries stored in directory sectors.

Design rules:
- Fixed-size entries (56 bytes)
- No disk I/O
- No directory logic
- Little-endian everywhere
- Mechanically portable to EX716 assembly
"""

FILE_ENTRY_SIZE = 56

# -------------------------------------------------------
# FILE entry field offsets
# -------------------------------------------------------

FE_NAME_OFFSET   = 0x00  # 12 bytes
FE_FLAGS_OFFSET  = 0x0C  # uint8
FE_GROUP_OFFSET  = 0x0D  # uint8
FE_RSVD_OFFSET   = 0x0E  # uint16

FE_SIZE_OFFSET   = 0x10  # uint32

FE_EXT1_OFFSET   = 0x14
FE_EXT2_OFFSET   = 0x19
FE_EXT3_OFFSET   = 0x1E

FE_CHAIN_OFFSET  = 0x23  # uint16
FE_META_OFFSET   = 0x25  # uint16

# -------------------------------------------------------
# FILE entry flags (bitmask)
# -------------------------------------------------------

FLAG_ACTIVE    = 0x01  # Entry is valid
FLAG_DELETED   = 0x02  # Entry deleted (available for reuse)
FLAG_SYSTEM    = 0x04  # System file (DIR, KERNEL, FATMAP, META)
FLAG_PROTECTED = 0x08  # Read-only
FLAG_CHAIN     = 0x10  # Chain continuation entry


# -------------------------------------------------------
# Little-endian helpers
# -------------------------------------------------------

def write_u16_le(buf, off, val):
    buf[off]     = val & 0xFF
    buf[off + 1] = (val >> 8) & 0xFF

def write_u32_le(buf, off, val):
    buf[off]     = val & 0xFF
    buf[off + 1] = (val >> 8) & 0xFF
    buf[off + 2] = (val >> 16) & 0xFF
    buf[off + 3] = (val >> 24) & 0xFF

def read_u16_le(buf, off):
    return buf[off] | (buf[off + 1] << 8)

def read_u32_le(buf, off):
    return (buf[off] |
           (buf[off + 1] << 8) |
           (buf[off + 2] << 16) |
           (buf[off + 3] << 24))

# -------------------------------------------------------
# FILE entry construction
# -------------------------------------------------------

def make_file_entry(
    filename,
    flags=0,
    group=0,
    size=0,
    extents=None,
    chain=0,
    meta=0
):
    """
    Construct a single FILE entry.

    Args:
        filename (str): ASCII name (max 12 chars)
        flags (int): flag bitfield
        group (int): group / namespace ID
        size (int): file size in bytes
        extents (list): up to 3 (disk, start, end) tuples
        chain (int): chain sector pointer or 0
        meta (int): META index

    Returns:
        bytearray: 56-byte FILE entry
    """

    buf = bytearray(FILE_ENTRY_SIZE)

    # Filename (space-padded)
    name_bytes = filename.encode("ascii")
    if len(name_bytes) > 12:
        raise ValueError("Filename too long")

    buf[FE_NAME_OFFSET:FE_NAME_OFFSET + len(name_bytes)] = name_bytes
    for i in range(len(name_bytes), 12):
        buf[FE_NAME_OFFSET + i] = ord(' ')

    # Flags and group
    buf[FE_FLAGS_OFFSET] = flags & 0xFF
    buf[FE_GROUP_OFFSET] = group & 0xFF

    # File size
    write_u32_le(buf, FE_SIZE_OFFSET, size)

    # Extents
    if extents is None:
        extents = []

    for idx, ext in enumerate(extents[:3]):
        disk, start, end = ext
        base = [FE_EXT1_OFFSET, FE_EXT2_OFFSET, FE_EXT3_OFFSET][idx]
        buf[base] = disk & 0xFF
        write_u16_le(buf, base + 1, start)
        write_u16_le(buf, base + 3, end)

    # Chain and META
    write_u16_le(buf, FE_CHAIN_OFFSET, chain)
    write_u16_le(buf, FE_META_OFFSET, meta)

    return buf

# -------------------------------------------------------
# FILE entry parsing
# -------------------------------------------------------

def parse_file_entry(buf):
    """
    Parse a FILE entry.

    Args:
        buf (bytes or bytearray): 56-byte FILE entry

    Returns:
        dict: parsed FILE entry fields
    """

    if len(buf) != FILE_ENTRY_SIZE:
        raise ValueError("Invalid FILE entry size")

    name = buf[FE_NAME_OFFSET:FE_NAME_OFFSET + 12].rstrip(b' ').decode("ascii")

    extents = []
    for base in (FE_EXT1_OFFSET, FE_EXT2_OFFSET, FE_EXT3_OFFSET):
        disk = buf[base]
        start = read_u16_le(buf, base + 1)
        end = read_u16_le(buf, base + 3)
        if start != 0 or end != 0:
            extents.append((disk, start, end))

    return {
        "filename": name,
        "flags": buf[FE_FLAGS_OFFSET],
        "group": buf[FE_GROUP_OFFSET],
        "size": read_u32_le(buf, FE_SIZE_OFFSET),
        "extents": extents,
        "chain": read_u16_le(buf, FE_CHAIN_OFFSET),
        "meta": read_u16_le(buf, FE_META_OFFSET),
    }

# -------------------------------------------------------
# ABI self-test
# -------------------------------------------------------

if __name__ == "__main__":
    print("FILE entry ABI self-test")

    entry = make_file_entry(
        filename="TEST",
        flags=0x05,
        group=2,
        size=12345,
        extents=[(0, 10, 12)],
        chain=0,
        meta=7
    )

    info = parse_file_entry(entry)

    for k, v in info.items():
        print(f"{k}: {v}")

    assert info["filename"] == "TEST"
    assert info["flags"] == 0x05
    assert info["group"] == 2
    assert info["size"] == 12345
    assert info["extents"] == [(0, 10, 12)]
    assert info["meta"] == 7

    print("FILE entry ABI test PASSED")
