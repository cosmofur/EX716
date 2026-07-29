#!/usr/bin/env bash

pattern="$1"
shift

awk -v PATTERN="$pattern" '
  function strip_comment(s) {
    out = ""
    esc = 0
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (c == "#" && !esc) break
      if (c == "\\" && !esc) {
        esc = 1
        out = out c
        continue
      }
      esc = 0
      out = out c
    }
    return out
  }

  {
    raw = $0
    phys[phys_count++] = raw

    line = strip_comment(raw)

    # Detect continuation using match() with a string regex
    cont = match(line, "\\\\[[:space:]]*$")
    if (cont) {
      line = substr(line, 1, RSTART - 1)
    }

    logical = logical line

    if (cont) next

    if (logical ~ PATTERN) {
      for (i = 0; i < phys_count; i++)
        print phys[i]
      print ""
    }

    logical = ""
    delete phys
    phys_count = 0
  }
' "$@"
