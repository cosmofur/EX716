#!/bin/sh
if [ -z "$1" ]; then
    echo "Usage $0 filename"
    exit
fi
R=$(basename -- "$1")
E="${R##*.}"
FP="${R%.*}"
cpu.py -c "$1" -l > $FP.lst
fcpu $FP.hex $2 $3 $4

