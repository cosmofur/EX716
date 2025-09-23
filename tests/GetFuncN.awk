#!/usr/bin/awk -f
# Usage: GetFunction N file.asm
# Extracts the Nth function that starts with `:Label` and ends before the next `:Label`.

BEGIN {
    if (ARGC < 3) {
        print "Usage: GetFunction N file.asm" > "/dev/stderr"
        exit 1
    }
    target = ARGV[1]
    ARGV[1] = ""  # Remove so it's not interpreted as a file
    funcIndex = 0
    collecting = 0
}

/^:/ {
    if (collecting) {
        exit
    }
    funcIndex++
    if (funcIndex == target) {
        collecting = 1
    }
}

collecting {
    print
}
