"""
boot.py — EX716 Boot Sector ABI Definition
==========================================

This module defines the on-disk ABI for sector 0 of an EX716 disk.

SECTOR 0 (512 bytes total) — EXECUTABLE FIRST
---------------------------------------------

Sector 0 is executable code starting at offset 0. The EX716 boot ROM
(or emulator) is expected to:

  - Read sector 0 of disk 0 into memory
  - Begin execution at offset 0
  - The boot stub then loads the filesystem kernel using absolute
    sector numbers stored in the metadata area

BOOT SECTOR LAYOUT
------------------

Offset   Size    Description
-------------------------------------------------------
0x000    200     Boot stub executable code
                - Raw machine code
                - No filesystem parsing
                - Typically ~31 bytes, but up to 200 allowed

0x0C8      8     Magic ASCII string: "EX716FS" (null padded)
0x0D0      2     Sector size (uint16, little-endian)
0x0D2      2     Reserved (must be zero)
0x0D4      4     Total sectors on disk (uint32 LE)
0x0D8      4     Filesystem start sector (uint32 LE, always 1)
0x0DC      4     Kernel start sector (uint32 LE)
0x0E0      4     Kernel sector count (uint32 LE)
0x0E4      4     Filesystem version (uint32 LE)
0x0E8    rest    Reserved / zero-filled

NOTES
-----
- All numeric fields are little-endian
- Sector size is fixed at 512 bytes
- Sector 1 is the first filesystem sector (DIR)
- The boot stub MUST NOT assume any filesystem structures
- Metadata offsets are fixed and absolute

This module contains NO disk I/O.
It is the canonical specification of the boot-sector ABI.
"""

# -------------------------------------------------------
# Constants
# -------------------------------------------------------

SECTOR_SIZE = 512
BOOT_STUB_SIZE = 200

BOOT_MAGIC = b"EX716FS"
BOOT_VERSION = 1

# -------------------------------------------------------
# Metadata offsets (absolute, frozen ABI)
# -------------------------------------------------------

BOOT_META_BASE      = BOOT_STUB_SIZE

BOOT_MAGIC_OFFSET   = BOOT_META_BASE + 0x00   # 8 bytes
BOOT_SECSIZE_OFFSET = BOOT_META_BASE + 0x08   # uint16
BOOT_RSVD_OFFSET    = BOOT_META_BASE + 0x0A   # uint16
BOOT_TOTSEC_OFFSET  = BOOT_META_BASE + 0x0C   # uint32
BOOT_FSSTART_OFFSET = BOOT_META_BASE + 0x10   # uint32
BOOT_KSTART_OFFSET  = BOOT_META_BASE + 0x14   # uint32
BOOT_KCOUNT_OFFSET  = BOOT_META_BASE + 0x18   # uint32
BOOT_VER_OFFSET     = BOOT_META_BASE + 0x1C   # uint32

# -------------------------------------------------------
# Little-endian helpers (local, explicit)
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
# Boot sector construction
# -------------------------------------------------------

def make_boot_sector(total_sectors,
                     kernel_start_sector,
                     kernel_sector_count,
                     boot_stub_bytes=None):
    """
    Construct a complete 512-byte boot sector.
    """

    buf = bytearray(SECTOR_SIZE)

    # Insert boot stub executable
    if boot_stub_bytes is not None:
        if len(boot_stub_bytes) > BOOT_STUB_SIZE:
            raise ValueError("Boot stub exceeds BOOT_STUB_SIZE")
        buf[0:len(boot_stub_bytes)] = boot_stub_bytes

    # Magic (null padded)
    buf[BOOT_MAGIC_OFFSET:BOOT_MAGIC_OFFSET + len(BOOT_MAGIC)] = BOOT_MAGIC

    # Fixed sector size
    write_u16_le(buf, BOOT_SECSIZE_OFFSET, SECTOR_SIZE)

    # Geometry / kernel info
    write_u32_le(buf, BOOT_TOTSEC_OFFSET,  total_sectors)
    write_u32_le(buf, BOOT_FSSTART_OFFSET, 1)
    write_u32_le(buf, BOOT_KSTART_OFFSET,  kernel_start_sector)
    write_u32_le(buf, BOOT_KCOUNT_OFFSET,  kernel_sector_count)
    write_u32_le(buf, BOOT_VER_OFFSET,     BOOT_VERSION)

    return buf

# -------------------------------------------------------
# Boot sector parsing (validation / tools)
# -------------------------------------------------------

def parse_boot_sector(buf):
    """
    Parse metadata fields from a boot sector.
    """

    if len(buf) != SECTOR_SIZE:
        raise ValueError("Boot sector must be exactly 512 bytes")

    raw_magic = buf[BOOT_MAGIC_OFFSET:BOOT_MAGIC_OFFSET + 8]
    magic = raw_magic.rstrip(b'\x00')

    if magic != BOOT_MAGIC:
        raise ValueError("Invalid boot sector magic")

    return {
        "sector_size":       read_u16_le(buf, BOOT_SECSIZE_OFFSET),
        "total_sectors":     read_u32_le(buf, BOOT_TOTSEC_OFFSET),
        "fs_start_sector":   read_u32_le(buf, BOOT_FSSTART_OFFSET),
        "kernel_start":      read_u32_le(buf, BOOT_KSTART_OFFSET),
        "kernel_sectors":    read_u32_le(buf, BOOT_KCOUNT_OFFSET),
        "fs_version":        read_u32_le(buf, BOOT_VER_OFFSET),
    }

# -------------------------------------------------------
# ABI self-test (optional)
# -------------------------------------------------------

if __name__ == "__main__":
    print("Boot sector ABI self-test")

    buf = make_boot_sector(
        total_sectors=65536,
        kernel_start_sector=2,
        kernel_sector_count=16
    )

    info = parse_boot_sector(buf)
    for k, v in info.items():
        print(f"{k}: {v}")

    assert info["sector_size"] == 512
    assert info["fs_start_sector"] == 1
    assert info["fs_version"] == BOOT_VERSION

    print("Boot sector ABI test PASSED")
