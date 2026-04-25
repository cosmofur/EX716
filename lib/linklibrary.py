#!/usr/bin/env python3

import re
import sys
import os


# --------------------------------------------------
# Regex patterns
# --------------------------------------------------

CALL_RE = re.compile(r'@call(?:\([^)]*\))?\s+([A-Za-z0-9_]+)', re.IGNORECASE)
MACRO_DEF_RE = re.compile(r'^M\s+([A-Za-z0-9_]+)\s+(.*)', re.IGNORECASE)
MACRO_USE_RE = re.compile(r'@([A-Za-z0-9_]+)')


# --------------------------------------------------
# Preprocessing: handle "\" continuation and comments
# --------------------------------------------------

def strip_comment(line):
    if "#" in line:
        return line.split("#", 1)[0]
    return line


def preprocess_lines(raw_lines):
    logical_lines = []
    buffer = ""

    for line in raw_lines:
        line = line.rstrip("\n")

        # detect continuation BEFORE stripping comments
        stripped = line.rstrip()
        has_cont = stripped.endswith("\\")

        if has_cont:
            stripped = stripped[:-1]  # remove trailing '\'

        # accumulate
        buffer += stripped.strip() + " "

        if not has_cont:
            # now strip comments
            clean = strip_comment(buffer).strip()
            if clean:
                logical_lines.append(clean)
            buffer = ""

    # catch any trailing buffer
    if buffer.strip():
        logical_lines.append(strip_comment(buffer).strip())

    return logical_lines


# --------------------------------------------------
# Extract macro definitions and their direct CALL deps
# --------------------------------------------------

def extract_macros(lines):
    macros = {}

    for line in lines:
        m = MACRO_DEF_RE.match(line)
        if m:
            name, body = m.groups()
            deps = set(CALL_RE.findall(body))
            if deps:
                macros[name] = deps

    return macros


# --------------------------------------------------
# Extract functions and their dependencies
# --------------------------------------------------

def extract_functions(lines, macros):
    functions = {}
    current_func = None

    for line in lines:
        tokens = line.split()

        if not tokens:
            continue

        keyword = tokens[0].upper()

        # FUNCTION start
        if keyword == "FUNCTION":
            if len(tokens) < 2:
                continue
            current_func = tokens[1]
            functions[current_func] = set()
            continue

        # FUNCTION end
        if keyword == "ENDFUNCTION":
            current_func = None
            continue

        # Inside function body
        if current_func:
            deps = set()

            # direct @CALL
            deps |= set(CALL_RE.findall(line))

            # macro usage
            macro_tokens = MACRO_USE_RE.findall(line)
            for mname in macro_tokens:
                if mname in macros:
                    deps |= macros[mname]

            functions[current_func] |= deps

    return functions


# --------------------------------------------------
# Filter dependencies to known functions only
# --------------------------------------------------

def filter_dependencies(functions):
    known = set(functions.keys())

    for f in functions:
        functions[f] = {
            d for d in functions[f]
            if d in known and d != f
        }


# --------------------------------------------------
# Write .ref file
# --------------------------------------------------

def write_ref_file(functions, output_path):
    with open(output_path, "w") as f:
        for func in sorted(functions):
            deps = sorted(functions[func])

            f.write(f"FUNC {func}\n")
            for d in deps:
                f.write(f"    NEED {d}\n")

            f.write("\n")


# --------------------------------------------------
# Main
# --------------------------------------------------

def main():
    if len(sys.argv) != 2:
        print("Usage: gen_ref.py <library.ld>")
        sys.exit(1)

    input_file = sys.argv[1]

    if not os.path.isfile(input_file):
        print(f"Error: file not found: {input_file}")
        sys.exit(1)

    base, _ = os.path.splitext(input_file)
    output_file = base + ".ref"

    with open(input_file, "r") as f:
        raw_lines = f.readlines()

    lines = preprocess_lines(raw_lines)

    macros = extract_macros(lines)
    functions = extract_functions(lines, macros)

    filter_dependencies(functions)

    write_ref_file(functions, output_file)

    print(f"Generated: {output_file}")


if __name__ == "__main__":
    main()
    
