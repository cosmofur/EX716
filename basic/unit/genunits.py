#!/usr/bin/env python3

import os

OUTDIR = "unit_tests"

FUNCTIONS = [
    "ADD32S","AND32","CMP32S","CMP32U","COMP232","DIV","DIV32S",
    "DiskClose","DiskFileReadLine","DiskFileWrite","DiskOpen","FSReadHeader","file_open",
    "HeapDefineMemory","HeapDeleteObject","HeapListMap","HeapNewObject","HeapResizeObject",
    "HexDump","ISAlphaNum","ISNumeric","MUL","MULU","MUL32S",
    "OR32","SUB32S","SetDiskHeap","SetSSStack",
    "itos","memcpy","stoi32","stoifirst","strcpy","strlen","strncmp","strncpy"
]

# --- classification -------------------------------------------------

CAT_32 = {
    "ADD32S","AND32","CMP32S","CMP32U","COMP232","DIV32S",
    "MUL32S","OR32","SUB32S"
}

CAT_16 = {
    "DIV","MUL","MULU"
}

CAT_HEAP = {
    "HeapDefineMemory","HeapDeleteObject","HeapListMap","HeapNewObject","HeapResizeObject"
}

CAT_DISK = {
    "DiskClose","DiskFileReadLine","DiskFileWrite","DiskOpen",
    "FSReadHeader","file_open","SetDiskHeap"
}

CAT_STRING = {
    "itos","memcpy","stoi32","stoifirst","strcpy","strlen","strncmp","strncpy","ISAlphaNum","ISNumeric"
}

# --- templates ------------------------------------------------------

HEADER = """M USE_ONLY 1
I common.mc

@USE {func}

L lmath.ld
L string.ld
L heapmgr.ld
L diskos.ld
L hexdump.ld
:AVar 0 0
:BVar 0 0

:Main . Main
"""

FOOTER = """
@StackDump
@END
"""

BODY_32 = """
@M32A2V $$$100 AVar
@M32A2V $$$200 BVar
@PUSH32I(V) AVar
@PUSH32I(V) BVar
@CALL {func}
"""

BODY_16 = """
@PUSHI 100
@PUSHI 5
@CALL {func}
"""

BODY_HEAP = """
# minimal heap init for symbol resolution
@PUSHI HeapBase
@PUSHI HeapSize
@CALL HeapDefineMemory

@PUSHI 16
@CALL {func}

:HeapBase 0
:HeapSize 1024
"""

BODY_DISK = """
# disk functions depend on heap symbols
@PUSHI HeapBase
@PUSHI HeapSize
@CALL HeapDefineMemory

# dummy call (arguments not meaningful)
@CALL {func}

:HeapBase 0
:HeapSize 1024
"""

BODY_STRING = """
:StrA "123\\0"
:StrB "456\\0"

@PUSHI StrA
@PUSHI StrB
@CALL {func}
"""

BODY_DEFAULT = """
# generic fallback
@CALL {func}
"""

# --- generator ------------------------------------------------------

def pick_body(func):
    if func in CAT_32:
        return BODY_32
    if func in CAT_16:
        return BODY_16
    if func in CAT_HEAP:
        return BODY_HEAP
    if func in CAT_DISK:
        return BODY_DISK
    if func in CAT_STRING:
        return BODY_STRING
    return BODY_DEFAULT

def main():
    os.makedirs(OUTDIR, exist_ok=True)

    for func in FUNCTIONS:
        path = os.path.join(OUTDIR, f"test_{func}.asm")

        with open(path, "w") as f:
            f.write(HEADER.format(func=func))
            f.write(pick_body(func).format(func=func))
            f.write(FOOTER)

        print(f"Generated {path}")

if __name__ == "__main__":
    main()
    
