#!/bin/sh
# Run to see what functions still need to be implimented
grep '"' basic_common.h | grep -v PRT | sed 's/.*"\([^"]*\)".*/\1/' | while read -r id; do
    # The -- ensures that if the ID starts with a dash, it isn't treated as a flag
    if grep -Fq -- "$id" *.asm; then
        echo "$id: In Use"
    else
        echo "$id: Not Implemented"
    fi
done
