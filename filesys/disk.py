"""
disk.py — EX716 Raw Disk Access Layer
====================================

This module provides low-level, filesystem-agnostic disk access
for EX716 disk images.

Design rules:
- No filesystem knowledge (no boot, DIR, FAT, etc.)
- Sector-based access only
- Explicit offsets, no abstractions
- Little-endian handled elsewhere
- Written to be mechanically portable to EX716 assembly

All higher layers (boot, dir, fs) depend on this module.
This module depends on nothing.
"""

SECTOR_SIZE = 512

# -------------------------------------------------------
# Disk creation
# -------------------------------------------------------

def create_blank_disk(total_sectors):
    """
    Create a zero-filled disk image in memory.

    Args:
        total_sectors (int): Number of 512-byte sectors

    Returns:
        bytearray: disk image
    """
    return bytearray(total_sectors * SECTOR_SIZE)

# -------------------------------------------------------
# Sector access helpers
# -------------------------------------------------------

def sector_offset(sector_number):
    """
    Compute byte offset of a sector.

    Args:
        sector_number (int): absolute sector number

    Returns:
        int: byte offset into disk image
    """
    return sector_number * SECTOR_SIZE

def read_sector(disk, sector_number):
    """
    Read a sector from disk.

    Args:
        disk (bytearray): disk image
        sector_number (int): absolute sector number

    Returns:
        bytearray: copy of sector data
    """
    off = sector_offset(sector_number)
    return bytearray(disk[off:off + SECTOR_SIZE])

def write_sector(disk, sector_number, sector_data):
    """
    Write a sector to disk.

    Args:
        disk (bytearray): disk image
        sector_number (int): absolute sector number
        sector_data (bytes or bytearray): must be 512 bytes
    """
    if len(sector_data) != SECTOR_SIZE:
        raise ValueError("sector_data must be exactly 512 bytes")

    off = sector_offset(sector_number)
    disk[off:off + SECTOR_SIZE] = sector_data

# -------------------------------------------------------
# Disk I/O (file-backed images)
# -------------------------------------------------------

def load_disk_image(filename):
    """
    Load a disk image from a file.

    Args:
        filename (str): path to DISK##.disk file

    Returns:
        bytearray: disk image
    """
    with open(filename, "rb") as f:
        return bytearray(f.read())

def save_disk_image(filename, disk):
    """
    Save a disk image to a file.

    Args:
        filename (str): output path
        disk (bytearray): disk image
    """
    with open(filename, "wb") as f:
        f.write(disk)

# -------------------------------------------------------
# Utility helpers
# -------------------------------------------------------

def disk_sector_count(disk):
    """
    Return number of sectors in a disk image.

    Args:
        disk (bytearray)

    Returns:
        int: total sectors
    """
    return len(disk) // SECTOR_SIZE

def clear_sector(disk, sector_number):
    """
    Zero-fill a single sector.

    Args:
        disk (bytearray)
        sector_number (int)
    """
    off = sector_offset(sector_number)
    for i in range(SECTOR_SIZE):
        disk[off + i] = 0
