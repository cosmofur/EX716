#!/bin/bash
ARGC=$#
LAST_ARG="${!ARGC}"

if [ -d "$LAST_ARG" ]; then
    ARGS=$(printf "%s\n" "$@" | sed '$d')
    cd "$LAST_ARG"
else
    cd /home/backs1/github/personal/EX716/tests
    ARGS="$@"
fi
echo "Working directory: $(pwd)"
python3 -m pdb /home/backs1/github/personal/EX716/cpu.py $ARGS
