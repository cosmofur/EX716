"""
dir.py — EX716 Directory Sector Format Definition
================================================

This module defines the on-disk ABI for directory sectors
starting at filesystem sector 1.

Design rules:
- Fixed 512-byte sectors
- Linked list of directory sectors
- Flat namespace with grouping handled by FILE entries
- No disk I/O in this module
- No allocation logic
- Little-endian everywhere
- Written to be mechanically portable to EX716 assembly

This module defines ONLY:
- Directory sector header/footer
- FILE entry layout
- Pack / unpack helpers
"""

# -------------------------------------------------------
# Constants
# -------------------------------------------------------

SECTOR_SIZE = 512

DIR_MAGIC   = b"EX716DIR"
DIR_VERSION = 1

# Header / footer sizes
DIR_HEADER_SIZE = 16
DIR_FOOTER_SIZE = 4

# FILE entry size (frozen ABI)
FILE_ENTRY_SIZE = 56

# Derived constant: entries per DIR sector
DIR_ENTRIES_PER_SECTOR = (SECTOR_SIZE - DIR_HEADER_SIZE - DIR_FOOTER_SIZE) // FILE_ENTRY_SIZE

# -------------------------------------------------------
# Offsets (absolute within sector)
# -------------------------------------------------------

DIR_MAGIC_OFFSET   = 0x000   # 8 bytes
DIR_VER_OFFSET     = 0x008   # uint16
DIR_SECTORNO_OFFSET= 0x00A   # uint16
DIR_RSVD_OFFSET    = 0x00C   # 4 bytes

DIR_ENTRIES_OFFSET = DIR_HEADER_SIZE

DIR_NEXT_OFFSET    = SECTOR_SIZE - 4  # uint16 at +0, reserved at +2

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
# Directory sector construction
# -------------------------------------------------------

def make_empty_dir_sector(sector_number, next_sector=0):
    """
    Construct an empty directory sector.

    Args:
        sector_number (int): physical disk sector number
        next_sector (int): next DIR sector or 0

    Returns:
        bytearray: 512-byte DIR sector
    """

    buf = bytearray(SECTOR_SIZE)

    # Magic (8 bytes, null padded)
    buf[DIR_MAGIC_OFFSET:DIR_MAGIC_OFFSET + len(DIR_MAGIC)] = DIR_MAGIC

    # Version
    write_u16_le(buf, DIR_VER_OFFSET, DIR_VERSION)

    # This sector number (physical)
    write_u16_le(buf, DIR_SECTORNO_OFFSET, sector_number)

    # Reserved header bytes left zero

    # Next DIR sector pointer
    write_u16_le(buf, DIR_NEXT_OFFSET, next_sector)

    return buf

# -------------------------------------------------------
# Directory sector parsing
# -------------------------------------------------------

def parse_dir_sector(buf):
    """
    Parse a directory sector header/footer.

    Args:
        buf (bytes or bytearray): 512-byte sector

    Returns:
        dict: parsed metadata
    """

    if len(buf) != SECTOR_SIZE:
        raise ValueError("DIR sector must be exactly 512 bytes")

    raw_magic = buf[DIR_MAGIC_OFFSET:DIR_MAGIC_OFFSET + 8]
    magic = raw_magic.rstrip(b'\x00')

    if magic != DIR_MAGIC:
        raise ValueError("Invalid DIR sector magic")

    version = read_u16_le(buf, DIR_VER_OFFSET)
    if version != DIR_VERSION:
        raise ValueError("Unsupported DIR version")

    return {
        "sector_number": read_u16_le(buf, DIR_SECTORNO_OFFSET),
        "next_sector":   read_u16_le(buf, DIR_NEXT_OFFSET),
        "entries_per_sector": DIR_ENTRIES_PER_SECTOR,
        "file_entry_size": FILE_ENTRY_SIZE,
    }

# -------------------------------------------------------
# FILE entry helpers (structure only)
# -------------------------------------------------------

def file_entry_offset(index):
    """
    Compute byte offset of FILE entry index within a DIR sector.
    """
    if index < 0 or index >= DIR_ENTRIES_PER_SECTOR:
        raise IndexError("FILE entry index out of range")

    return DIR_ENTRIES_OFFSET + index * FILE_ENTRY_SIZE

# -------------------------------------------------------
# ABI self-test (temporary)
# -------------------------------------------------------

if __name__ == "__main__":
    print("DIR sector ABI self-test")

    test_sector = 1
    test_next   = 5

    buf = make_empty_dir_sector(test_sector, test_next)
    info = parse_dir_sector(buf)

    print("Parsed fields:")
    for k, v in info.items():
        print(f"  {k}: {v}")

    assert info["sector_number"] == test_sector
    assert info["next_sector"]   == test_next
    assert info["entries_per_sector"] == DIR_ENTRIES_PER_SECTOR
    assert info["file_entry_size"]    == FILE_ENTRY_SIZE

    # Validate FILE entry offsets don't overlap footer
    last_entry_end = (
        file_entry_offset(DIR_ENTRIES_PER_SECTOR - 1) + FILE_ENTRY_SIZE
    )
    assert last_entry_end <= DIR_NEXT_OFFSET

    print("DIR sector ABI test PASSED")
