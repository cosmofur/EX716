#!/usr/bin/env python3
"""
mkdisk.py — EX716 Disk Image Initializer
=======================================

This script creates a minimal EX716 disk image using the canonical
ABIs defined in:

  - disk.py     (raw disk access)
  - boot.py     (sector 0 boot ABI)
  - dir.py      (directory sector ABI)
  - fileent.py  (FILE entry ABI)

This file contains NO on-disk format definitions.
It is glue / orchestration only.
"""

from disk import (
    SECTOR_SIZE,
    create_blank_disk,
    write_sector,
    save_disk_image,
    load_disk_image,
    read_sector,
)

from boot import (
    make_boot_sector,
    parse_boot_sector,
)

from dir import (
    make_empty_dir_sector,
    parse_dir_sector,
    file_entry_offset,
)

from fileent import (
    make_file_entry,
    parse_file_entry,
)

# -------------------------------------------------------
# Local constants / policy
# -------------------------------------------------------

DISK_FILENAME = "DISK00.disk"

# Simple FILE flags (kept local on purpose)
FLAG_ACTIVE = 0x01
FLAG_SYSTEM = 0x04

# -------------------------------------------------------
# Disk creation
# -------------------------------------------------------

def create_disk():
    print("Creating EX716 disk image:", DISK_FILENAME)

    # ---- Disk geometry ----
    total_sectors = (32 * 1024 * 1024) // SECTOR_SIZE  # 32 MiB

    # ---- Kernel placement (placeholder) ----
    kernel_start_sector = 2
    kernel_sector_count = 0   # no kernel yet

    # ---- Create blank disk ----
    disk = create_blank_disk(total_sectors)

    # ---- Sector 0: boot sector ----
    boot_sector = make_boot_sector(
        total_sectors=total_sectors,
        kernel_start_sector=kernel_start_sector,
        kernel_sector_count=kernel_sector_count,
        boot_stub_bytes=None
    )
    write_sector(disk, 0, boot_sector)

    # ---- Sector 1: root DIR ----
    dir_sector_number = 1
    dir_sector = make_empty_dir_sector(dir_sector_number)

    # ---- FILE entries ----

    # Entry 0: DIR itself
    add_file_to_dir(
        dir_sector,
        index=0,
        filename="DIR",
        flags=FLAG_ACTIVE | FLAG_SYSTEM,
        size=SECTOR_SIZE,
        extents=[(0, dir_sector_number, dir_sector_number)]
    )

    # Entry 1: KERNEL (placeholder)
    kernel_start = 2
    kernel_sectors = 8
    kernel_size = kernel_sectors * SECTOR_SIZE

    add_file_to_dir(
        dir_sector,
        index=1,
        filename="KERNEL",
        flags=FLAG_ACTIVE | FLAG_SYSTEM,
        size=kernel_size,
        extents=[(0, kernel_start, kernel_start + kernel_sectors - 1)]
    )

    fill_file_sectors(
    disk,
    kernel_start,
    kernel_sectors,
    "KERNEL"
    )


    # Entry 2: FATMAP, This will both create the DIR entry and create the FATMAP bitmap
    # with existing used sectors for BOOT DIR and KERNEL set as in use.
    used_sectors = set()

    # Boot
    used_sectors.add(0)

    # DIR
    used_sectors.add(1)

    # Kernel
    for s in range(kernel_start, kernel_start + kernel_sectors):
        used_sectors.add(s)

    fatmap_data = build_fatmap(total_sectors, used_sectors)

    fatmap_size_bytes = len(fatmap_data)
    fatmap_sectors = (fatmap_size_bytes + SECTOR_SIZE - 1) // SECTOR_SIZE
    fatmap_start = kernel_start + kernel_sectors
        

    for i in range(fatmap_sectors):
       secbuf = bytearray(SECTOR_SIZE)
       chunk = fatmap_data[i * SECTOR_SIZE:(i + 1) * SECTOR_SIZE]
       secbuf[:len(chunk)] = chunk
       write_sector(disk, fatmap_start + i, secbuf)
       used_sectors.add(fatmap_start + i)

    add_file_to_dir(
        dir_sector,
        index=2,
        filename="FATMAP",
        flags=FLAG_ACTIVE | FLAG_SYSTEM,
        size=fatmap_size_bytes,
        extents=[(0, fatmap_start, fatmap_start + fatmap_sectors - 1)]
    )

    # Entry 3: META (placeholder)
    add_file_to_dir(
        dir_sector,
        index=3,
        filename="META",
        flags=FLAG_ACTIVE | FLAG_SYSTEM,
        size=0,
        extents=[]
    )

    write_sector(disk, dir_sector_number, dir_sector)


    # ---- Save disk image ----
    save_disk_image(DISK_FILENAME, disk)

    print("Disk image written successfully.")
    print("  Total sectors :", total_sectors)
    print("  Root DIR sector:", dir_sector_number)

# -------------------------------------------------------
# Verification / sanity check
# -------------------------------------------------------

def verify_disk():
    print("\nVerifying disk image...")

    disk = load_disk_image(DISK_FILENAME)

    # ---- Verify boot sector ----
    boot_sector = read_sector(disk, 0)
    boot_info = parse_boot_sector(boot_sector)

    print("Boot sector:")
    for k, v in boot_info.items():
        print(f"  {k}: {v}")

    # ---- Verify DIR sector ----
    dir_sector = read_sector(disk, 1)
    dir_info = parse_dir_sector(dir_sector)

    print("\nDIR sector:")
    for k, v in dir_info.items():
        print(f"  {k}: {v}")

    # ---- Verify DIR FILE entry ----
    off = file_entry_offset(0)
    entry_buf = dir_sector[off:off + 56]
    entry_info = parse_file_entry(entry_buf)

    print("\nDIR FILE entry:")
    for k, v in entry_info.items():
        print(f"  {k}: {v}")

    assert entry_info["filename"] == "DIR"
    assert entry_info["extents"] == [(0, 1, 1)]

    print("\nVerification PASSED.")

def add_file_to_dir(dir_sector, index, *,
                    filename,
                    flags,
                    size,
                    extents,
                    group=0,
                    chain=0,
                    meta=0):
    """
    Create a FILE entry and insert it into a DIR sector slot.
    """

    entry = make_file_entry(
        filename=filename,
        flags=flags,
        group=group,
        size=size,
        extents=extents,
        chain=chain,
        meta=meta
    )

    off = file_entry_offset(index)
    dir_sector[off:off + len(entry)] = entry
    
def build_fatmap(total_sectors, used_sectors):
    """
    Build a FATMAP bitmap.

    Args:
        total_sectors (int)
        used_sectors (set[int])

    Returns:
        bytearray: raw FATMAP bytes (length = ceil(total_sectors / 8))
    """
    size_bytes = (total_sectors + 7) // 8
    buf = bytearray(size_bytes)

    for sec in used_sectors:
        byte = sec // 8
        bit  = sec % 8
        buf[byte] |= (1 << bit)

    return buf


def fill_file_sectors(disk, start_sector, sector_count, label):
    for i in range(sector_count):
        sec = start_sector + i
        buf = bytearray(512)
        text = f"{label} sector {sec:04d}\n".encode("ascii")
        while len(text) < 512:
            text += text
        buf[:512] = text[:512]
        write_sector(disk, sec, buf)


# -------------------------------------------------------
# Entry point
# -------------------------------------------------------

def main():
    create_disk()
    verify_disk()

if __name__ == "__main__":
    main()
