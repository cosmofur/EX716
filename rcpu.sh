#!/bin/sh
if [ "X$1" == "X" ]; then
    echo Usage $0 filename
    exit
fi
R=$(basename -- "$1")
E="${R##*.}"
FP="${R%.*}"
cpu.py -c "$1"
fcpu $FP.a.o $2 $3 $4

