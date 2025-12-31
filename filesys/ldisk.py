#!/usr/bin/env python3
"""
lsdisk.py — EX716 Directory Dumper
=================================

Minimal inspection tool for EX716 disk images.

Reads the root DIR sector (sector 1) and dumps FILE entries
using the canonical ABIs.

This tool performs NO disk modifications.
"""

import sys

from disk import (
    load_disk_image,
    read_sector,
)

from dir import (
    parse_dir_sector,
    file_entry_offset,
    DIR_ENTRIES_PER_SECTOR,
)

from fileent import (
    parse_file_entry,
    FILE_ENTRY_SIZE,
)

# -------------------------------------------------------
# Flags (local knowledge only for display)
# -------------------------------------------------------

FLAG_ACTIVE    = 0x01
FLAG_DELETED   = 0x02
FLAG_SYSTEM    = 0x04
FLAG_PROTECTED = 0x08
FLAG_CHAIN     = 0x10

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------

def flags_to_string(flags):
    out = []
    if flags & FLAG_ACTIVE:    out.append("A")
    if flags & FLAG_DELETED:   out.append("D")
    if flags & FLAG_SYSTEM:    out.append("S")
    if flags & FLAG_PROTECTED: out.append("P")
    if flags & FLAG_CHAIN:     out.append("C")
    return "".join(out) if out else "-"

# -------------------------------------------------------
# Main logic
# -------------------------------------------------------

def dump_dir(disk_filename):
    print("Inspecting disk image:", disk_filename)

    disk = load_disk_image(disk_filename)

    # ---- Read root DIR sector ----
    dir_sector = read_sector(disk, 1)
    dir_info = parse_dir_sector(dir_sector)

    print("\nRoot DIR sector:")
    for k, v in dir_info.items():
        print(f"  {k}: {v}")

    print("\nDirectory entries:")
    print("Idx  Flags  Size     Name         Extents")
    print("---- ------ -------- ------------ ----------------------")

    for idx in range(DIR_ENTRIES_PER_SECTOR):
        off = file_entry_offset(idx)
        entry_buf = dir_sector[off:off + FILE_ENTRY_SIZE]

        entry = parse_file_entry(entry_buf)

        # Empty slot heuristic:
        # inactive + empty name + no extents
        raw_name = entry["filename"]
        if entry["flags"] == 0 and not raw_name.strip('\x00 ').strip():
            continue

        flags = flags_to_string(entry["flags"])
        size  = entry["size"]
        name  = entry["filename"]

        ext_str = ", ".join(
            f"D{d}:{s}-{e}" for (d, s, e) in entry["extents"]
        ) if entry["extents"] else "-"

        print(f"{idx:>3}  {flags:<6} {size:>8}  {name:<12} {ext_str}")

# -------------------------------------------------------
# Entry point
# -------------------------------------------------------

def main():
    if len(sys.argv) != 2:
        print("Usage: lsdisk.py <diskimage>")
        sys.exit(1)

    dump_dir(sys.argv[1])

if __name__ == "__main__":
    main()
