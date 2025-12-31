"""
fs_ops.py — EX716 filesystem operations

High-level filesystem behaviors built on top of
on-disk structures.

This module:
- locates files by name/group
- creates file handles
- performs sequential and random reads

No disk formats are defined here.
"""

from disk import read_sector, load_disk_image
from dir import parse_dir_sector, DIR_HEADER_SIZE
from fileent import parse_file_entry, FLAG_ACTIVE

import sys

def open_file(disk, filename, group_id=0):
    """
    Locate a file in the directory chain and return a FileHandle.

    CHAIN files not yet resolved.
    """

    # Root directory always starts at sector 1 (for now)
    dir_sector_num = 1

    while dir_sector_num != 0:
        # Read DIR sector
        dir_sector = read_sector(disk, dir_sector_num)

        # Parse DIR header
        dir_info = parse_dir_sector(dir_sector)

        entries_per_sector = dir_info["entries_per_sector"]
        entry_size = dir_info["file_entry_size"]

        # FILE entries start after DIR header
        base = DIR_HEADER_SIZE

        for i in range(entries_per_sector):
            off = base + i * entry_size
            raw = dir_sector[off:off + entry_size]

            entry = parse_file_entry(raw)

            # Skip inactive entries
            if not (entry["flags"] & FLAG_ACTIVE):
                continue

            if entry["filename"] != filename:
                continue

            if entry["group"] != group_id:
                continue

            # FOUND
            size = entry["size"]
            extents = entry["extents"]

            if size == 0 or not extents:
                return {
                    "filename": filename,
                    "group": group_id,
                    "size": 0,
                    "extents": [],
                    "extent_index": 0,
                    "current_sector": 0,
                    "byte_offset": 0,
                    "bytes_remaining": 0,
                }

            disk_id, start, end = extents[0]

            return {
                "filename": filename,
                "group": group_id,
                "size": size,
                "extents": extents,
                "extent_index": 0,
                "current_sector": start,
                "byte_offset": 0,
                "bytes_remaining": size,
            }

        # Follow DIR chain
        dir_sector_num = dir_info["next_sector"]

    # Not found
    return None


SECTOR_SIZE = 512


def next_sector(fh):
    """
    Advance to the next sector in the file.
    Sets current_sector to 0 on EOF.
    """

    # Still inside current extent
    if fh["current_sector"] < fh["current_extent_end"]:
        fh["current_sector"] += 1
        return fh["current_sector"]

    # Move to next extent
    fh["extent_index"] += 1

    if fh["extent_index"] >= len(fh["extents"]):
        fh["current_sector"] = 0   # EOF
        return 0

    # Load next extent
    disk, start, end = fh["extents"][fh["extent_index"]]
    fh["current_sector"] = start
    fh["current_extent_end"] = end

    return fh["current_sector"]

SECTOR_SIZE = 512

def read_block(disk, fh, buffer):
    """
    Read one sector from file into buffer.

    Returns:
        512 if data read
        0   if EOF
    """

    # EOF check BEFORE read
    if fh["bytes_remaining"] == 0:
        return 0

    # Safety: buffer must be at least 512 bytes
    if len(buffer) < SECTOR_SIZE:
        raise ValueError("Buffer too small for read_block")

    # Read current sector
    sector = fh["current_sector"]
    start = sector * SECTOR_SIZE
    end   = start + SECTOR_SIZE

    buffer[0:SECTOR_SIZE] = disk[start:end]

    # Account bytes read
    if fh["bytes_remaining"] >= SECTOR_SIZE:
        fh["bytes_remaining"] -= SECTOR_SIZE
    else:
        fh["bytes_remaining"] = 0

    # Advance to next sector (may hit EOF)
    next_sector(fh)

    return SECTOR_SIZE


def select_sector(fh, rel_sector):
    """
    Position file cursor to a relative sector number.

    Args:
        fh (dict): file handle
        rel_sector (int): 0-based sector index within file

    Returns:
        int: absolute sector number, or 0 on failure
    """

    if rel_sector < 0:
        fh["current_sector"] = 0
        return 0

    extents = fh["extents"]
    sector_index = rel_sector

    for idx, (disk, start, end) in enumerate(extents):
        extent_len = end - start + 1

        if sector_index < extent_len:
            # Found the extent containing the sector
            abs_sector = start + sector_index
            fh["extent_index"] = idx
            fh["current_sector"] = abs_sector
            fh["current_extent_end"] = end
            return abs_sector

        sector_index -= extent_len

    # Out of range → EOF
    fh["current_sector"] = 0
    return 0


def select_byte(fh, byte_offset):
    """
    Position file cursor to an absolute byte offset.

    Args:
        fh (dict): file handle
        byte_offset (int): 0-based byte offset in file

    Returns:
        int: 1 on success, 0 on failure
    """

    if byte_offset < 0:
        fh["current_sector"] = 0
        return 0

    # Optional safety check (can be relaxed later)
    if byte_offset >= fh["size"]:
        fh["current_sector"] = 0
        return 0

    sector_index = byte_offset // SECTOR_SIZE
    offset_in_sector = byte_offset % SECTOR_SIZE

  # For Assembly later notice that we can use shifts and masks rather than DIV and MOD
  #     sector_index        = byte_offset >> 9
  #     offset_in_sector    = byte_offset & 0x01FF

    
    abs_sector = select_sector(fh, sector_index)
    if abs_sector == 0:
        fh["current_sector"] = 0
        return 0

    fh["byte_offset_in_sector"] = offset_in_sector
    return 1

def read_buffer(disk, fh, buf, size):
    """
    Read up to `size` bytes from file into buf.

    Returns:
        int: number of bytes actually read
    """

    if size <= 0:
        return 0

    total_read = 0
    buf_pos = 0

    temp = bytearray(SECTOR_SIZE)

    while size > 0 and fh["current_sector"] != 0 and fh["bytes_remaining"] > 0:

        # Read current sector into temp buffer
        rc = read_block(disk, fh, temp)
        if rc == 0:
            break

        # Determine how many bytes to copy from this sector
        start = fh.get("byte_offset_in_sector", 0)
        avail = SECTOR_SIZE - start

        to_copy = min(avail, size, fh["bytes_remaining"] + avail)

        buf[buf_pos:buf_pos + to_copy] = temp[start:start + to_copy]

        # Update counters
        buf_pos += to_copy
        total_read += to_copy
        size -= to_copy

        # After first read, subsequent reads are sector-aligned
        fh["byte_offset_in_sector"] = 0

    return total_read

def test_read_buffer():
    print("Testing read_buffer()")

    total_sectors = 32
    disk = bytearray(total_sectors * SECTOR_SIZE)

    # Populate sectors 2–4 with test data
    for s in range(2, 5):
        msg = f"SECTOR{s}".encode("ascii")
        base = s * SECTOR_SIZE
        disk[base:base + len(msg)] = msg

    fh = {
        "size": 3 * SECTOR_SIZE,
        "extents": [(0, 2, 4)],
        "extent_index": 0,
        "current_sector": 2,
        "current_extent_end": 4,
        "bytes_remaining": 3 * SECTOR_SIZE,
        "byte_offset_in_sector": 3,
    }

    buf = bytearray(100)
    n = read_buffer(disk, fh, buf, 20)

    print("Read bytes:", n)
    print("Data:", buf[:n])

    assert n == 20
    assert buf[:n].startswith(b"TOR2")

    print("read_buffer() test PASSED")


def test_select_sector():
    print("Testing select_sector()")

    fh = {
        "extents": [(0, 2, 4), (0, 10, 12)],
        "extent_index": 0,
        "current_sector": 2,
        "current_extent_end": 4,
    }

    # rel_sector → absolute sector
    cases = [
        (0, 2),
        (1, 3),
        (2, 4),
        (3, 10),
        (4, 11),
        (5, 12),
    ]

    for rel, abs_expected in cases:
        abs_sector = select_sector(fh, rel)
        print(f"rel {rel} → abs {abs_sector}")
        assert abs_sector == abs_expected

    # Out of range
    assert select_sector(fh, 6) == 0
    assert fh["current_sector"] == 0

    print("select_sector() test PASSED")


def test_read_block():
    print("Testing read_block()")

    SECTOR_SIZE = 512
    total_sectors = 32

    # ---- Create fake disk ----
    disk = bytearray(total_sectors * SECTOR_SIZE)

    # Fill sectors 2–9 with identifiable data
    for s in range(2, 10):
        msg = f"KERNEL sector {s:04d}\n".encode("ascii")
        base = s * SECTOR_SIZE
        disk[base:base + len(msg)] = msg

    # ---- Fake FILE handle (what open_file would return) ----
    fh = {
        "filename": "KERNEL",
        "size": 8 * SECTOR_SIZE,
        "extents": [(0, 2, 9)],
        "extent_index": 0,
        "current_sector": 2,
        "current_extent_end": 9,
        "bytes_remaining": 8 * SECTOR_SIZE,
    }

    buf = bytearray(SECTOR_SIZE)

    sectors_seen = []

    while True:
        rc = read_block(disk, fh, buf)
        if rc == 0:
            print("EOF reached")
            break

        # Extract sector number from content
        line = buf.split(b"\n", 1)[0]
        sectors_seen.append(line.decode("ascii"))

        print(buf[:32])

    # ---- Assertions ----
    expected = [f"KERNEL sector {s:04d}" for s in range(2, 10)]
    assert sectors_seen == expected, "Sector sequence mismatch"

    assert fh["bytes_remaining"] == 0
    assert fh["current_sector"] == 10 or fh["current_sector"] == 0
    assert fh["extent_index"] == 1
    assert fh["current_extent_end"] == 12

    print("read_block() test PASSED")


def main():
#    test_select_sector()
#    test_read_block()
    test_read_buffer()

    print("EOF reached")
    

if __name__ == "__main__":
    main()
    
