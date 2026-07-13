#!/usr/bin/env python3
"""
EX716 DiskOS disk-image utility.

Implements the documented DiskOS layout:

    512-byte sectors
    128 sectors per 64-KiB block
    512 blocks per image
    block 0: 512 x 128-byte directory entries
    blocks 1-3: reserved
    blocks 4-511: file data

Directory entry 0 is the filesystem header. FileNum N maps directly to
directory entry N.

The implementation uses little-endian integer encoding. Change ENDIAN below
if the EX716 on-disk encoding is big-endian.

Large files are represented as an extent chain. The root directory entry owns
the visible filename and total 32-bit file size. The first 16-bit word of
DIR_RESERVE points to the next directory entry, or zero at end of chain.
Continuation entries have no visible filename and describe additional
contiguous block ranges.
"""

from __future__ import annotations

import argparse
import dataclasses
import datetime as dt
import os
import shutil
import struct
import sys
import tempfile
from pathlib import Path
from typing import Iterable, Iterator, Optional


# ---------------------------------------------------------------------------
# Disk geometry
# ---------------------------------------------------------------------------

SECTOR_SIZE = 512
SECTORS_PER_BLOCK = 128
BLOCK_SIZE = SECTOR_SIZE * SECTORS_PER_BLOCK
BLOCK_COUNT = 512
DISK_SIZE = BLOCK_SIZE * BLOCK_COUNT

DIRECTORY_ENTRY_SIZE = 0x80
DIRECTORY_ENTRY_COUNT = 512

FIRST_DATA_BLOCK = 4
LAST_DATA_BLOCK = BLOCK_COUNT - 1

# EX716 integer encoding. The current implementation assumes little endian.
ENDIAN = "<"

VERSION = "0.5.0"


# ---------------------------------------------------------------------------
# Directory entry layout
# ---------------------------------------------------------------------------

DIR_FILENAME = 0x00
DIR_FLAGS = 0x20
DIR_FILENUM = 0x22
DIR_FILESIZE = 0x24
DIR_FIRSTBLOCK = 0x28
DIR_BLOCKCOUNT = 0x2A
DIR_LINECOUNT = 0x2C
DIR_FILETYPE = 0x2E
DIR_TIMESTAMPS = 0x30
DIR_CRC = 0x38
DIR_RESERVE = 0x40
DIR_SIZE = 0x80
DIR_FN_SIZE = 0x1F

FLAG_INUSE = 0x01
FLAG_DELETED = 0x02
FLAG_READONLY = 0x04
FLAG_SYSTEM = 0x08
FLAG_EXEC = 0x10

KNOWN_FLAGS = FLAG_INUSE | FLAG_DELETED | FLAG_READONLY | FLAG_SYSTEM | FLAG_EXEC

# The first word of the reserve area is used as the continuation-entry link.
DIR_NEXT_EXTENT = DIR_RESERVE


# ---------------------------------------------------------------------------
# Filesystem header layout, stored in directory entry 0
# ---------------------------------------------------------------------------

FS_MAGIC = 0
FS_DISK_ID = 2
FS_CREATE_TIME = 4
FS_ACTIVE_FILES = 8
FS_HEADER_FLAGS = 10
FS_FILE_BITMAP = 12
FS_RESERVED = 76

FS_BITMAP_BYTES = FS_RESERVED - FS_FILE_BITMAP  # 64 bytes = 512 bits

# Provisional default. Override with "format --magic" if FSFormat uses another.
DEFAULT_MAGIC = 0x0716


class DiskError(RuntimeError):
    """Base error for malformed images and invalid operations."""


class ImageFormatError(DiskError):
    """The image does not conform to the expected geometry or metadata."""


class AllocationError(DiskError):
    """The image has insufficient directory slots or data blocks."""


def u16(data: bytes | bytearray, offset: int) -> int:
    return struct.unpack_from(ENDIAN + "H", data, offset)[0]


def u32(data: bytes | bytearray, offset: int) -> int:
    return struct.unpack_from(ENDIAN + "I", data, offset)[0]


def put_u16(data: bytearray, offset: int, value: int) -> None:
    struct.pack_into(ENDIAN + "H", data, offset, value & 0xFFFF)


def put_u32(data: bytearray, offset: int, value: int) -> None:
    struct.pack_into(ENDIAN + "I", data, offset, value & 0xFFFFFFFF)


def normalize_name(name: str) -> str:
    """
    Validate and return a DiskOS filename.

    The physical field is 32 bytes beginning at offset zero, while DIR_FN_SIZE
    is 31. This implementation therefore permits at most 31 encoded bytes and
    stores a trailing NUL.
    """
    if "\x00" in name:
        raise DiskError("filename contains a NUL byte")

    encoded = name.encode("ascii", errors="strict")
    if not encoded:
        raise DiskError("filename must not be empty")
    if len(encoded) > DIR_FN_SIZE:
        raise DiskError(
            f"filename is {len(encoded)} bytes; maximum is {DIR_FN_SIZE}"
        )
    return name


def decode_filename(raw: bytes) -> str:
    raw = raw.split(b"\x00", 1)[0]
    return raw.decode("ascii", errors="replace")


def encode_filename(name: str) -> bytes:
    name = normalize_name(name)
    raw = name.encode("ascii")
    return raw + b"\x00" * (0x20 - len(raw))


@dataclasses.dataclass
class DirectoryEntry:
    file_num: int
    filename: str = ""
    flags: int = 0
    file_size: int = 0
    first_block: int = 0
    block_count: int = 0
    line_count: int = 0
    file_type: int = 0
    timestamp_create: int = 0
    timestamp_update: int = 0
    crc: int = 0
    next_extent: int = 0
    raw_reserve: bytes = b""

    @property
    def in_use(self) -> bool:
        # FLAG_DELETED takes precedence over FLAG_INUSE. Some existing
        # images retain both bits after deletion.
        return bool(self.flags & FLAG_INUSE) and not bool(self.flags & FLAG_DELETED)

    @property
    def deleted(self) -> bool:
        return bool(self.flags & FLAG_DELETED)

    @property
    def is_visible(self) -> bool:
        return self.in_use and bool(self.filename)

    @classmethod
    def from_bytes(cls, file_num: int, raw: bytes) -> "DirectoryEntry":
        if len(raw) != DIRECTORY_ENTRY_SIZE:
            raise ValueError("directory entry must be exactly 128 bytes")
        return cls(
            file_num=file_num,
            filename=decode_filename(raw[DIR_FILENAME:DIR_FLAGS]),
            flags=u16(raw, DIR_FLAGS),
            file_size=u32(raw, DIR_FILESIZE),
            first_block=u16(raw, DIR_FIRSTBLOCK),
            block_count=u16(raw, DIR_BLOCKCOUNT),
            line_count=u16(raw, DIR_LINECOUNT),
            file_type=u16(raw, DIR_FILETYPE),
            timestamp_create=u32(raw, DIR_TIMESTAMPS),
            timestamp_update=u32(raw, DIR_TIMESTAMPS + 4),
            crc=u32(raw, DIR_CRC),
            next_extent=u16(raw, DIR_NEXT_EXTENT),
            raw_reserve=bytes(raw[DIR_RESERVE:DIR_SIZE]),
        )

    def to_bytes(self) -> bytes:
        raw = bytearray(DIRECTORY_ENTRY_SIZE)

        if self.filename:
            raw[DIR_FILENAME:DIR_FLAGS] = encode_filename(self.filename)

        put_u16(raw, DIR_FLAGS, self.flags)
        put_u16(raw, DIR_FILENUM, self.file_num)
        put_u32(raw, DIR_FILESIZE, self.file_size)
        put_u16(raw, DIR_FIRSTBLOCK, self.first_block)
        put_u16(raw, DIR_BLOCKCOUNT, self.block_count)
        put_u16(raw, DIR_LINECOUNT, self.line_count)
        put_u16(raw, DIR_FILETYPE, self.file_type)
        put_u32(raw, DIR_TIMESTAMPS, self.timestamp_create)
        put_u32(raw, DIR_TIMESTAMPS + 4, self.timestamp_update)
        put_u32(raw, DIR_CRC, self.crc)

        if self.raw_reserve:
            reserve = self.raw_reserve[: DIR_SIZE - DIR_RESERVE]
            raw[DIR_RESERVE:DIR_RESERVE + len(reserve)] = reserve

        put_u16(raw, DIR_NEXT_EXTENT, self.next_extent)
        return bytes(raw)


@dataclasses.dataclass
class FSHeader:
    magic: int
    disk_id: int
    create_time: int
    active_files: int
    flags: int
    bitmap: bytearray

    @classmethod
    def from_bytes(cls, raw: bytes) -> "FSHeader":
        if len(raw) != DIRECTORY_ENTRY_SIZE:
            raise ValueError("filesystem header must be 128 bytes")
        return cls(
            magic=u16(raw, FS_MAGIC),
            disk_id=u16(raw, FS_DISK_ID),
            create_time=u32(raw, FS_CREATE_TIME),
            active_files=u16(raw, FS_ACTIVE_FILES),
            flags=u16(raw, FS_HEADER_FLAGS),
            bitmap=bytearray(raw[FS_FILE_BITMAP:FS_RESERVED]),
        )

    def to_bytes(self) -> bytes:
        if len(self.bitmap) != FS_BITMAP_BYTES:
            raise ValueError("filesystem bitmap must be exactly 64 bytes")

        raw = bytearray(DIRECTORY_ENTRY_SIZE)
        put_u16(raw, FS_MAGIC, self.magic)
        put_u16(raw, FS_DISK_ID, self.disk_id)
        put_u32(raw, FS_CREATE_TIME, self.create_time)
        put_u16(raw, FS_ACTIVE_FILES, self.active_files)
        put_u16(raw, FS_HEADER_FLAGS, self.flags)
        raw[FS_FILE_BITMAP:FS_RESERVED] = self.bitmap
        return bytes(raw)

    def is_used(self, file_num: int) -> bool:
        if not 0 <= file_num < DIRECTORY_ENTRY_COUNT:
            raise IndexError(file_num)
        return bool(self.bitmap[file_num // 8] & (1 << (file_num % 8)))

    def set_used(self, file_num: int, used: bool) -> None:
        if not 0 <= file_num < DIRECTORY_ENTRY_COUNT:
            raise IndexError(file_num)

        byte_index = file_num // 8
        mask = 1 << (file_num % 8)

        if used:
            self.bitmap[byte_index] |= mask
        else:
            self.bitmap[byte_index] &= ~mask


class DiskImage:
    def __init__(self, path: Path):
        self.path = path
        self.data = bytearray(path.read_bytes())
        if len(self.data) != DISK_SIZE:
            raise ImageFormatError(
                f"{path}: image size is {len(self.data):,} bytes; "
                f"expected {DISK_SIZE:,}"
            )
        self.header = FSHeader.from_bytes(self.read_entry_raw(0))

    @classmethod
    def create(
        cls,
        path: Path,
        disk_id: int,
        magic: int = DEFAULT_MAGIC,
        create_time: Optional[int] = None,
        overwrite: bool = False,
    ) -> "DiskImage":
        if path.exists() and not overwrite:
            raise DiskError(f"{path} already exists; use --force to replace it")

        if not 0 <= disk_id <= 0xFFFF:
            raise DiskError("disk ID must fit in 16 bits")
        if not 0 <= magic <= 0xFFFF:
            raise DiskError("magic ID must fit in 16 bits")

        image = bytearray(DISK_SIZE)
        timestamp = int(dt.datetime.now(dt.timezone.utc).timestamp())
        if create_time is not None:
            timestamp = create_time

        bitmap = bytearray(FS_BITMAP_BYTES)
        header = FSHeader(
            magic=magic,
            disk_id=disk_id,
            create_time=timestamp,
            active_files=0,
            flags=0,
            bitmap=bitmap,
        )
        # Entry zero is permanently reserved as the filesystem header.
        header.set_used(0, True)
        image[0:DIRECTORY_ENTRY_SIZE] = header.to_bytes()

        atomic_write(path, image, backup=False)
        return cls(path)

    def read_entry_raw(self, file_num: int) -> bytes:
        self._validate_file_num(file_num, allow_zero=True)
        start = file_num * DIRECTORY_ENTRY_SIZE
        return bytes(self.data[start:start + DIRECTORY_ENTRY_SIZE])

    def read_entry(self, file_num: int) -> DirectoryEntry:
        return DirectoryEntry.from_bytes(file_num, self.read_entry_raw(file_num))

    def write_entry(self, entry: DirectoryEntry) -> None:
        self._validate_file_num(entry.file_num, allow_zero=False)
        start = entry.file_num * DIRECTORY_ENTRY_SIZE
        self.data[start:start + DIRECTORY_ENTRY_SIZE] = entry.to_bytes()

    def write_header(self) -> None:
        self.data[0:DIRECTORY_ENTRY_SIZE] = self.header.to_bytes()

    def save(self, backup: bool = True) -> None:
        self.write_header()
        atomic_write(self.path, self.data, backup=backup)

    @staticmethod
    def _validate_file_num(file_num: int, allow_zero: bool = False) -> None:
        minimum = 0 if allow_zero else 1
        if not minimum <= file_num < DIRECTORY_ENTRY_COUNT:
            raise DiskError(
                f"FileNum {file_num} outside valid range "
                f"{minimum}-{DIRECTORY_ENTRY_COUNT - 1}"
            )

    def entries(self) -> Iterator[DirectoryEntry]:
        for file_num in range(1, DIRECTORY_ENTRY_COUNT):
            yield self.read_entry(file_num)

    def visible_entries(self, include_deleted: bool = False) -> Iterator[DirectoryEntry]:
        for entry in self.entries():
            if entry.filename and (entry.in_use or (include_deleted and entry.deleted)):
                yield entry

    def find(self, name: str, include_deleted: bool = False) -> DirectoryEntry:
        wanted = normalize_name(name).casefold()
        matches = [
            entry for entry in self.visible_entries(include_deleted=include_deleted)
            if entry.filename.casefold() == wanted
        ]

        if not matches:
            raise DiskError(f"file not found: {name}")
        if len(matches) > 1:
            nums = ", ".join(str(entry.file_num) for entry in matches)
            raise DiskError(f"ambiguous duplicate filename {name!r}: FileNums {nums}")
        return matches[0]

    def chain(self, root: DirectoryEntry) -> list[DirectoryEntry]:
        result: list[DirectoryEntry] = []
        seen: set[int] = set()
        current = root

        while True:
            if current.file_num in seen:
                raise ImageFormatError(
                    f"extent chain for FileNum {root.file_num} contains a cycle"
                )

            seen.add(current.file_num)
            result.append(current)

            if current.next_extent == 0:
                break

            self._validate_file_num(current.next_extent, allow_zero=False)
            current = self.read_entry(current.next_extent)

        return result

    def allocated_blocks(self) -> dict[int, int]:
        """Return block -> FileNum for every block referenced by an in-use entry."""
        allocated: dict[int, int] = {}

        for entry in self.entries():
            if not entry.in_use or entry.block_count == 0:
                continue

            end = entry.first_block + entry.block_count
            for block in range(entry.first_block, end):
                if FIRST_DATA_BLOCK <= block <= LAST_DATA_BLOCK:
                    allocated.setdefault(block, entry.file_num)

        return allocated

    def free_blocks(self) -> list[int]:
        used = self.allocated_blocks()
        return [
            block for block in range(FIRST_DATA_BLOCK, BLOCK_COUNT)
            if block not in used
        ]

    def free_file_nums(self) -> list[int]:
        return [
            file_num
            for file_num in range(1, DIRECTORY_ENTRY_COUNT)
            if not self.header.is_used(file_num)
        ]

    def allocate_file_nums(self, count: int) -> list[int]:
        free = self.free_file_nums()
        if len(free) < count:
            raise AllocationError(
                f"need {count} directory entries, but only {len(free)} are free"
            )
        return free[:count]

    def allocate_blocks(self, count: int) -> list[int]:
        free = self.free_blocks()
        if len(free) < count:
            raise AllocationError(
                f"need {count} data blocks, but only {len(free)} are free"
            )
        return free[:count]

    def import_file(
        self,
        source: Path,
        disk_name: str,
        file_type: int = 0,
        line_count: int = 0,
        flags: int = 0,
        replace: bool = False,
    ) -> DirectoryEntry:
        disk_name = normalize_name(disk_name)
        payload = source.read_bytes()

        try:
            existing = self.find(disk_name)
        except DiskError:
            existing = None

        if existing is not None:
            if not replace:
                raise DiskError(
                    f"{disk_name} already exists; use --replace to overwrite it"
                )
            self.delete_entry(existing, preserve_deleted_name=False)

        extent_count = max(1, (len(payload) + BLOCK_SIZE - 1) // BLOCK_SIZE)
        file_nums = self.allocate_file_nums(extent_count)
        blocks = self.allocate_blocks(extent_count)
        timestamp = int(dt.datetime.now(dt.timezone.utc).timestamp())

        entries: list[DirectoryEntry] = []

        for index, (file_num, block) in enumerate(zip(file_nums, blocks)):
            start = index * BLOCK_SIZE
            chunk = payload[start:start + BLOCK_SIZE]

            block_offset = block * BLOCK_SIZE
            self.data[block_offset:block_offset + BLOCK_SIZE] = (
                chunk + b"\x00" * (BLOCK_SIZE - len(chunk))
            )

            entry = DirectoryEntry(
                file_num=file_num,
                filename=disk_name if index == 0 else "",
                flags=FLAG_INUSE | (flags & (FLAG_READONLY | FLAG_SYSTEM | FLAG_EXEC)),
                file_size=len(payload) if index == 0 else len(chunk),
                first_block=block,
                block_count=1,
                line_count=line_count if index == 0 else 0,
                file_type=file_type if index == 0 else 0,
                timestamp_create=timestamp,
                timestamp_update=timestamp,
                crc=0,
                next_extent=file_nums[index + 1] if index + 1 < len(file_nums) else 0,
            )
            entries.append(entry)

        for entry in entries:
            self.write_entry(entry)
            self.header.set_used(entry.file_num, True)

        self.header.active_files += 1
        return entries[0]

    def export_file(self, entry: DirectoryEntry, destination: Path, force: bool = False) -> None:
        if destination.exists() and not force:
            raise DiskError(f"{destination} already exists; use --force to replace it")

        remaining = entry.file_size
        output = bytearray()

        for extent in self.chain(entry):
            if not extent.in_use:
                raise ImageFormatError(
                    f"extent FileNum {extent.file_num} is not marked in use"
                )

            byte_count = extent.block_count * BLOCK_SIZE
            start = extent.first_block * BLOCK_SIZE
            output.extend(self.data[start:start + min(remaining, byte_count)])
            remaining -= min(remaining, byte_count)

            if remaining == 0:
                break

        if remaining != 0:
            raise ImageFormatError(
                f"{entry.filename}: extent chain is {remaining} bytes short"
            )

        destination.parent.mkdir(parents=True, exist_ok=True)
        atomic_write(destination, output, backup=False)

    def rename(self, entry: DirectoryEntry, new_name: str) -> None:
        new_name = normalize_name(new_name)
        try:
            collision = self.find(new_name)
        except DiskError:
            collision = None

        if collision is not None and collision.file_num != entry.file_num:
            raise DiskError(f"filename already exists: {new_name}")

        entry.filename = new_name
        entry.timestamp_update = int(dt.datetime.now(dt.timezone.utc).timestamp())
        self.write_entry(entry)

    def delete_entry(
        self,
        root: DirectoryEntry,
        preserve_deleted_name: bool = True,
    ) -> None:
        chain = self.chain(root)

        for index, entry in enumerate(chain):
            entry.flags &= ~FLAG_INUSE
            entry.flags |= FLAG_DELETED
            if index != 0 or not preserve_deleted_name:
                entry.filename = ""
            entry.timestamp_update = int(dt.datetime.now(dt.timezone.utc).timestamp())
            self.write_entry(entry)
            self.header.set_used(entry.file_num, False)

        if self.header.active_files:
            self.header.active_files -= 1

    def undelete(self, root: DirectoryEntry) -> None:
        chain = self.chain(root)

        # Ensure the directory slots have not been reallocated.
        for entry in chain:
            if self.header.is_used(entry.file_num):
                raise DiskError(
                    f"cannot undelete: FileNum {entry.file_num} is already allocated"
                )

        # Ensure the referenced blocks are not now owned by another live entry.
        live_blocks = self.allocated_blocks()
        for entry in chain:
            for block in range(entry.first_block, entry.first_block + entry.block_count):
                owner = live_blocks.get(block)
                if owner is not None:
                    raise DiskError(
                        f"cannot undelete: block {block} is now owned by FileNum {owner}"
                    )

        for entry in chain:
            entry.flags &= ~FLAG_DELETED
            entry.flags |= FLAG_INUSE
            self.write_entry(entry)
            self.header.set_used(entry.file_num, True)

        self.header.active_files += 1

    def check(self) -> list[str]:
        issues: list[str] = []
        counted_visible = 0
        block_owners: dict[int, int] = {}

        if len(self.header.bitmap) != FS_BITMAP_BYTES:
            issues.append("filesystem bitmap is not 64 bytes")

        if not self.header.is_used(0):
            issues.append("bitmap does not reserve FileNum 0 for the FS header")

        for entry in self.entries():
            bit_used = self.header.is_used(entry.file_num)

            if entry.in_use and not bit_used:
                issues.append(
                    f"FileNum {entry.file_num}: entry is INUSE but bitmap bit is clear"
                )
            if bit_used and not entry.in_use:
                issues.append(
                    f"FileNum {entry.file_num}: bitmap bit is set but entry is not INUSE"
                )
            if entry.flags & ~KNOWN_FLAGS:
                issues.append(
                    f"FileNum {entry.file_num}: unknown flag bits "
                    f"0x{entry.flags & ~KNOWN_FLAGS:04x}"
                )
            if entry.in_use and entry.filename:
                counted_visible += 1

            if entry.in_use and entry.block_count:
                if entry.first_block < FIRST_DATA_BLOCK:
                    issues.append(
                        f"FileNum {entry.file_num}: first block "
                        f"{entry.first_block} is reserved"
                    )
                if entry.first_block + entry.block_count > BLOCK_COUNT:
                    issues.append(
                        f"FileNum {entry.file_num}: block range extends past image"
                    )

                for block in range(
                    entry.first_block,
                    min(entry.first_block + entry.block_count, BLOCK_COUNT),
                ):
                    previous = block_owners.get(block)
                    if previous is not None:
                        issues.append(
                            f"block {block} is shared by FileNums "
                            f"{previous} and {entry.file_num}"
                        )
                    else:
                        block_owners[block] = entry.file_num

            if entry.next_extent:
                try:
                    next_entry = self.read_entry(entry.next_extent)
                except DiskError as exc:
                    issues.append(f"FileNum {entry.file_num}: {exc}")
                else:
                    if next_entry.filename:
                        issues.append(
                            f"FileNum {entry.file_num}: continuation "
                            f"FileNum {entry.next_extent} has visible filename "
                            f"{next_entry.filename!r}"
                        )

        if counted_visible != self.header.active_files:
            issues.append(
                f"active-file count is {self.header.active_files}, "
                f"but {counted_visible} visible INUSE entries were found"
            )

        # Validate every visible chain independently.
        for entry in self.visible_entries():
            try:
                chain = self.chain(entry)
            except ImageFormatError as exc:
                issues.append(str(exc))
                continue

            capacity = sum(extent.block_count * BLOCK_SIZE for extent in chain)
            if capacity < entry.file_size:
                issues.append(
                    f"FileNum {entry.file_num} ({entry.filename}): "
                    f"size {entry.file_size} exceeds chain capacity {capacity}"
                )

        return issues


def atomic_write(path: Path, payload: bytes | bytearray, backup: bool) -> None:
    path = path.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)

    if backup and path.exists():
        backup_path = path.with_name(path.name + ".bak")
        shutil.copy2(path, backup_path)

    fd, temp_name = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp_name, path)
    except Exception:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise


def flag_text(flags: int) -> str:
    names: list[str] = []
    if flags & FLAG_INUSE:
        names.append("INUSE")
    if flags & FLAG_DELETED:
        names.append("DELETED")
    if flags & FLAG_READONLY:
        names.append("READONLY")
    if flags & FLAG_SYSTEM:
        names.append("SYSTEM")
    if flags & FLAG_EXEC:
        names.append("EXEC")
    unknown = flags & ~KNOWN_FLAGS
    if unknown:
        names.append(f"0x{unknown:04x}")
    return ",".join(names) if names else "-"


def format_timestamp(value: int) -> str:
    if value == 0:
        return "-"
    try:
        return dt.datetime.fromtimestamp(value, dt.timezone.utc).isoformat()
    except (OverflowError, OSError, ValueError):
        return f"0x{value:08x}"


def parse_int(text: str) -> int:
    return int(text, 0)


def open_image(path: str) -> DiskImage:
    return DiskImage(Path(path))


def looks_like_disk_image(value: str) -> bool:
    return value.lower().endswith(".disk")


def find_default_disk_image() -> str:
    """Return the sole *.disk image in the current directory."""
    images = sorted(
        path.name
        for path in Path.cwd().iterdir()
        if path.is_file() and path.name.lower().endswith(".disk")
    )

    if len(images) == 1:
        return images[0]
    if not images:
        raise DiskError(
            "no .disk image was specified and none exists in the current directory"
        )

    listing = "\n".join(f"  {name}" for name in images)
    raise DiskError(
        "no .disk image was specified and multiple images exist:\n" + listing
    )


def resolve_image_and_names(values: list[str], name_count: int) -> tuple[str, list[str]]:
    """
    Accept image-first, image-last, or an omitted image when exactly one
    *.disk file exists in the current directory.
    """
    if len(values) == name_count:
        return find_default_disk_image(), values

    if len(values) != name_count + 1:
        raise DiskError(
            f"expected {name_count} filename argument(s), with an optional "
            f".disk image when exactly one image exists"
        )

    image_indexes = [
        index for index, value in enumerate(values) if looks_like_disk_image(value)
    ]

    if len(image_indexes) == 1:
        image_index = image_indexes[0]
    elif len(image_indexes) == 0:
        image_index = 0
    else:
        raise DiskError("more than one positional argument looks like a .disk image")

    image = values[image_index]
    names = values[:image_index] + values[image_index + 1:]
    return image, names


def cmd_format(args: argparse.Namespace) -> int:
    image = DiskImage.create(
        Path(args.image),
        disk_id=args.disk_id,
        magic=args.magic,
        create_time=args.create_time,
        overwrite=args.force,
    )
    print(
        f"Formatted {image.path}: {DISK_SIZE:,} bytes, "
        f"disk ID 0x{image.header.disk_id:04x}, "
        f"magic 0x{image.header.magic:04x}"
    )
    return 0


def cmd_info(args: argparse.Namespace) -> int:
    image = open_image(args.image or find_default_disk_image())
    print(f"Image:         {image.path}")
    print(f"Size:          {len(image.data):,} bytes")
    print(f"Magic:         0x{image.header.magic:04x}")
    print(f"Disk ID:       0x{image.header.disk_id:04x}")
    print(f"Created:       {format_timestamp(image.header.create_time)}")
    print(f"Active files:  {image.header.active_files}")
    print(f"Header flags:  0x{image.header.flags:04x}")
    print(f"Free slots:    {len(image.free_file_nums())}")
    print(f"Free blocks:   {len(image.free_blocks())}")
    print(f"Free bytes:    {len(image.free_blocks()) * BLOCK_SIZE:,}")
    return 0


def cmd_dir(args: argparse.Namespace) -> int:
    image = open_image(args.image or find_default_disk_image())
    entries = list(image.visible_entries(include_deleted=args.all))

    print(
        f"{'FILE':>4}  {'NAME':<31}  {'SIZE':>10}  "
        f"{'FIRST':>5}  {'BLOCKS':>6}  {'NEXT':>4}  FLAGS"
    )
    print("-" * 92)

    for entry in entries:
        print(
            f"{entry.file_num:4d}  {entry.filename:<31}  "
            f"{entry.file_size:10d}  {entry.first_block:5d}  "
            f"{entry.block_count:6d}  {entry.next_extent:4d}  "
            f"{flag_text(entry.flags)}"
        )

    print()
    print(
        f"{sum(1 for e in entries if e.in_use)} active entries shown; "
        f"{image.header.active_files} active files recorded in header"
    )
    return 0


def cmd_rename(args: argparse.Namespace) -> int:
    image_name, names = resolve_image_and_names(args.items, 2)
    old_name, new_name = names
    image = open_image(image_name)
    entry = image.find(old_name)
    image.rename(entry, new_name)
    image.save(backup=not args.no_backup)
    print(f"Renamed {old_name} to {new_name}")
    return 0


def cmd_delete(args: argparse.Namespace) -> int:
    image_name, names = resolve_image_and_names(args.items, 1)
    name = names[0]
    image = open_image(image_name)
    entry = image.find(name)
    image.delete_entry(entry, preserve_deleted_name=True)
    image.save(backup=not args.no_backup)
    print(f"Deleted {name} (FileNum {entry.file_num})")
    return 0


def cmd_undelete(args: argparse.Namespace) -> int:
    image_name, names = resolve_image_and_names(args.items, 1)
    name = names[0]
    image = open_image(image_name)
    entry = image.find(name, include_deleted=True)
    if not entry.deleted:
        raise DiskError(f"{name} is not marked deleted")
    image.undelete(entry)
    image.save(backup=not args.no_backup)
    print(f"Undeleted {name} (FileNum {entry.file_num})")
    return 0


def cmd_import(args: argparse.Namespace) -> int:
    image_name, names = resolve_image_and_names(args.items, 1)
    image = open_image(image_name)
    source = Path(names[0])
    disk_name = args.name or source.name

    flags = 0
    if args.readonly:
        flags |= FLAG_READONLY
    if args.system:
        flags |= FLAG_SYSTEM
    if args.exec:
        flags |= FLAG_EXEC

    entry = image.import_file(
        source,
        disk_name,
        file_type=args.file_type,
        line_count=args.line_count,
        flags=flags,
        replace=args.replace,
    )
    image.save(backup=not args.no_backup)
    print(
        f"Imported {source} as {entry.filename} "
        f"(FileNum {entry.file_num}, {entry.file_size:,} bytes)"
    )
    return 0


def cmd_export(args: argparse.Namespace) -> int:
    image_name, names = resolve_image_and_names(args.items, 1)
    name = names[0]
    image = open_image(image_name)
    entry = image.find(name)
    destination = Path(args.output or entry.filename)
    image.export_file(entry, destination, force=args.force)
    print(
        f"Exported {entry.filename} to {destination} "
        f"({entry.file_size:,} bytes)"
    )
    return 0


def cmd_check(args: argparse.Namespace) -> int:
    image = open_image(args.image or find_default_disk_image())
    issues = image.check()

    if not issues:
        print(f"{image.path}: no structural problems found")
        return 0

    print(f"{image.path}: {len(issues)} problem(s) found:")
    for issue in issues:
        print(f"  - {issue}")
    return 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Manage EX716 DiskOS .disk images"
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {VERSION}")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("format", help="create and format a new disk image")
    p.add_argument("image")
    p.add_argument(
        "--disk-id",
        type=parse_int,
        required=True,
        help="16-bit disk ID; decimal or 0x-prefixed",
    )
    p.add_argument(
        "--magic",
        type=parse_int,
        default=DEFAULT_MAGIC,
        help=f"16-bit magic ID; default 0x{DEFAULT_MAGIC:04x}",
    )
    p.add_argument(
        "--create-time",
        type=parse_int,
        help="explicit 32-bit timestamp; default current Unix time",
    )
    p.add_argument("-f", "--force", action="store_true")
    p.set_defaults(func=cmd_format)

    p = sub.add_parser("info", help="show filesystem header and free space")
    p.add_argument("image", nargs="?")
    p.set_defaults(func=cmd_info)

    p = sub.add_parser("dir", aliases=["list", "ls"], help="list directory")
    p.add_argument("image", nargs="?")
    p.add_argument("-a", "--all", action="store_true", help="include deleted entries")
    p.set_defaults(func=cmd_dir)

    p = sub.add_parser(
        "rename",
        help="rename a visible file; accepts IMAGE OLD NEW or OLD NEW IMAGE",
    )
    p.add_argument("items", nargs="+", metavar="ARG")
    p.add_argument("--no-backup", action="store_true")
    p.set_defaults(func=cmd_rename)

    p = sub.add_parser(
        "delete", aliases=["rm"],
        help="mark a file deleted; accepts IMAGE NAME or NAME IMAGE",
    )
    p.add_argument("items", nargs="+", metavar="ARG")
    p.add_argument("--no-backup", action="store_true")
    p.set_defaults(func=cmd_delete)

    p = sub.add_parser(
        "undelete",
        help="restore a deleted file; accepts IMAGE NAME or NAME IMAGE",
    )
    p.add_argument("items", nargs="+", metavar="ARG")
    p.add_argument("--no-backup", action="store_true")
    p.set_defaults(func=cmd_undelete)

    p = sub.add_parser(
        "import",
        help="copy a host file; accepts IMAGE SOURCE, SOURCE IMAGE, "
             "or SOURCE when exactly one *.disk exists",
    )
    p.add_argument("items", nargs="+", metavar="ARG")
    p.add_argument("--name", help="DiskOS filename; default host basename")
    p.add_argument("--replace", action="store_true")
    p.add_argument("--file-type", type=parse_int, default=0)
    p.add_argument("--line-count", type=parse_int, default=0)
    p.add_argument("--readonly", action="store_true")
    p.add_argument("--system", action="store_true")
    p.add_argument("--exec", action="store_true")
    p.add_argument("--no-backup", action="store_true")
    p.set_defaults(func=cmd_import)

    p = sub.add_parser(
        "export",
        help="copy a DiskOS file to the host; accepts IMAGE NAME or NAME IMAGE",
    )
    p.add_argument("items", nargs="+", metavar="ARG")
    p.add_argument("-o", "--output")
    p.add_argument("-f", "--force", action="store_true")
    p.set_defaults(func=cmd_export)

    p = sub.add_parser("check", help="check structural consistency")
    p.add_argument("image", nargs="?")
    p.set_defaults(func=cmd_check)

    return parser


def main(argv: Optional[list[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        return args.func(args)
    except (DiskError, OSError, UnicodeError, ValueError) as exc:
        parser.exit(2, f"error: {exc}\n")


if __name__ == "__main__":
    raise SystemExit(main())
