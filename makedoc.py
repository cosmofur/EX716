#!/usr/bin/env python3
import re
import sys
import json
from pathlib import Path

# ------------------------------------------------------------
# Command-line handling
# ------------------------------------------------------------
use_color = "--color" in sys.argv
args = [a for a in sys.argv[1:] if a != "--color"]

if len(args) < 2:
    print("Usage: generate_doc.py <pythonfile.py> <infofile> [--color]")
    sys.exit(1)

PYFILE = Path(args[0])
INFOFILE = Path(args[1])

# ANSI colors -------------------------------------------------
def c(text, color):
    if not use_color:
        return text
    colors = {
        "yellow": "\033[33m",
        "cyan": "\033[36m",
        "green": "\033[32m",
        "reset": "\033[0m",
        "magenta": "\033[35m",
    }
    return colors.get(color, "") + text + colors["reset"]

def docstring_extractor(lines, start_index):
    """
    Find a real docstring: it must be the FIRST statement inside the function body.

    Ignore:
    • Strings that appear later in the body
    • Strings inside Windows/Linux branching blocks
    • Accidental inline literals
    """

    n = len(lines)
    i = start_index

    # Skip blank lines and comments
    while i < n and (lines[i].strip() == "" or lines[i].lstrip().startswith("#")):
        i += 1

    if i >= n:
        return None

    stripped = lines[i].strip()

    # Must start with a triple quote AND must not end the same line
    if stripped.startswith('"""') or stripped.startswith("'''"):
        quote = stripped[:3]

        # Case A: one-line docstring
        if stripped.endswith(quote) and len(stripped) > 6:
            return stripped[3:-3].strip()

        # Case B: multi-line docstring
        doc = stripped[3:]
        i += 1
        while i < n:
            line = lines[i]
            if line.strip().endswith(quote):
                doc += "\n" + line.strip()[:-3]
                return doc.strip()
            doc += "\n" + line
            i += 1

        return doc.strip()

    # Otherwise: it is NOT a docstring
    return None



def docstring_extractor_old(lines, start_index):
    """
    Attempt to extract a docstring beginning at start_index.

    Supports:
      - Triple double quoted strings
      - Triple single quoted strings
      - Single-line and multi-line forms
    Returns clean content or "" if no docstring is present.
    """
    if start_index >= len(lines):
        return ""

    line = lines[start_index].lstrip()

    # Docstring must begin with a triple-quote
    if not (line.startswith('"""') or line.startswith("'''")):
        return ""

    quote = line[:3]               # ''' or """
    content = line[3:]             # remainder of the first line
    j = start_index + 1

    # Case: single-line docstring
    if content.strip().endswith(quote):
        return content.rstrip()[:-3].strip()

    # Case: multi-line docstring
    out = [content.rstrip()]
    while j < len(lines):
        stripped = lines[j].rstrip()
        if stripped.endswith(quote):
            # closing quote found — capture last content
            out.append(stripped[:-3])
            break
        else:
            out.append(stripped)
        j += 1

    return "\n".join(out).strip()



# ------------------------------------------------------------
# Load existing .info (if any)
# ------------------------------------------------------------
extra = {}

def _store_info(key, rest):
    desc = ""
    meta = {}

    # quoted description
    qm = re.search(r'"([^"]*)"', rest)
    if qm:
        desc = qm.group(1)
        rest = rest.replace(qm.group(0), "")
    else:
        parts = rest.split(",", 1)
        desc = parts[0].strip()

    # metadata
    for item in rest.split(","):
        if "=" in item:
            k, v = item.split("=", 1)
            meta[k.strip()] = v.strip()

    extra[key] = {"desc": desc, "meta": meta}


def parse_info_file():
    if not INFOFILE.exists():
        return

    txt = INFOFILE.read_text()
    for entry in txt.split(";"):
        entry = entry.strip()
        if not entry:
            continue

        # CLASS entry
        m = re.match(r'^CLASS\s*:\s*([A-Za-z0-9_]+)\s*:\s*([A-Za-z0-9_]+)\s*(.*)$', entry)
        if m:
            cls, func, rest = m.groups()
            _store_info((cls, func), rest)
            continue

        # Top-level function entry
        m = re.match(r'^([A-Za-z0-9_]+)\s*:\s*(.*)$', entry)
        if m:
            func, rest = m.groups()
            _store_info(("", func), rest)
            continue

parse_info_file()

# ------------------------------------------------------------
# Docstring extractor — SAFE against Windows/POSIX blocks
# ------------------------------------------------------------
def extract_docstring(lines, start_line):
    """
    Extract a real Python docstring from immediately after a def.
    Only accepts triple-quoted strings (\"\"\" or \'\'\') that are properly indented.
    """

    if start_line + 1 >= len(lines):
        return ""

    nextline = lines[start_line + 1]
    stripped = nextline.lstrip()
    indent = len(nextline) - len(stripped)

    # Triple-quote tokens expressed safely so they don't break the file
    TQ1 = "\"\"\""   # double-quote docstring
    TQ2 = "'''"      # single-quote docstring

    # Not a docstring?
    if not (stripped.startswith(TQ1) or stripped.startswith(TQ2)):
        return ""

    # Determine which marker we found
    quote = TQ1 if stripped.startswith(TQ1) else TQ2
    content = stripped[len(quote):].rstrip()
    line_idx = start_line + 2

    # Single-line docstring
    if stripped.endswith(quote) and len(stripped) > len(quote)*2:
        return stripped[len(quote):-len(quote)].strip()

    collected = [content]

    # Multi-line docstring: scan until matching close
    while line_idx < len(lines):
        L = lines[line_idx]
        S = L.strip()

        # If indentation drops, abort (avoids mis-detecting OS-specific branches)
        if len(L) - len(L.lstrip()) < indent:
            break

        if S.endswith(quote):
            collected.append(S[:-len(quote)])
            break

        collected.append(S)
        line_idx += 1

    return "\n".join(collected).strip()


# ------------------------------------------------------------
# Parse Python source file (with multi-line defs + docstrings)
# ------------------------------------------------------------
source = PYFILE.read_text().splitlines()

class_methods = {}
top_functions = []
current_class = None

def_pattern = re.compile(r'^\s*def\s+([A-Za-z0-9_]+)\s*\(')
class_pattern = re.compile(r'^\s*class\s+([A-Za-z0-9_]+)\s*')

i = 0
N = len(source)

while i < N:
    line = source[i]

    # ---------------- CLASS DETECTION ----------------
    class_m = class_pattern.match(line)
    if class_m:
        current_class = class_m.group(1)
        class_methods.setdefault(current_class, [])
        i += 1
        continue

    # ---------------- DEF DETECTION -------------------
    m = def_pattern.match(line)
    if m:
        name = m.group(1)
        lineno = i + 1

        # --- accumulate multiline signature ---
        sig_lines = [line.strip()]
        i += 1

        while i < N:
            stripped = source[i].strip()
            sig_lines.append(stripped)
            if stripped.endswith(":"):
                break
            i += 1

        # NOTE: NO "i += 1" here — we fall through
        sig = " ".join(sig_lines)

        # parse signature
        m2 = re.match(r'def\s+([A-Za-z0-9_]+)\s*\((.*?)\)\s*:', sig)
        if m2:
            args = m2.group(2)
        else:
            args = "(parse_error)"

        # extract docstring
        doc = docstring_extractor(source, i + 1)

        # save
        if current_class:
            class_methods[current_class].append((name, args, lineno, doc))
        else:
            top_functions.append((name, args, lineno, doc))

        # *** CRITICAL ***
        # break out of def block and let outer loop increment i
        continue

    # ---------------- NORMAL LINES -------------------
    i += 1




# ------------------------------------------------------------
# Output Markdown
# ------------------------------------------------------------
print(f"# Function Index for `{PYFILE.name}`\n")
print("Auto-generated from source + `.info`.\n")

# Helper -------------------------------------------------------
def print_entry(cls, name, args, lineno, doc):
    key = (cls if cls else "", name)
    info = extra.get(key, {})
    desc = info.get("desc", "")
    meta = info.get("meta", {})

    print(f"### `{name}({args})`  \n*Line {lineno}*")

    if desc:
        print(f"- **Description:** {desc}")

    if doc:
        print(f"- **Docstring:**\n```\n{doc}\n```")

    if meta:
        print(f"- **Metadata:**")
        for k, v in meta.items():
            print(f"  - {k}: {v}")

    print()

# Classes ------------------------------------------------------
for cls in sorted(class_methods.keys()):
    print(f"## Class: **{cls}**\n")
    for (name, args, lineno, doc) in class_methods[cls]:
        print_entry(cls, name, args, lineno, doc)

# Top-level functions -----------------------------------------
if top_functions:
    print("## Top-Level Functions\n")
    for (name, args, lineno, doc) in top_functions:
        print_entry("", name, args, lineno, doc)


# ------------------------------------------------------------
# Append stub entries for missing items
# ------------------------------------------------------------
missing = []

# class methods
for cls, funcs in class_methods.items():
    for (name, args, lineno, doc) in funcs:
        key = (cls, name)
        if key not in extra:
            missing.append(f'CLASS:{cls}:{name} "TODO: describe {name}"')

# top-level
for (name, args, lineno, doc) in top_functions:
    key = ("", name)
    if key not in extra:
        missing.append(f'{name}: "TODO: describe {name}"')

if missing:
    with INFOFILE.open("a") as f:
        f.write("\n\n# Automatically added stub entries:\n")
        for m in missing:
            f.write(m + ";\n")

    print(c(f"\nAdded {len(missing)} stub entries to {INFOFILE}", "green"), file=sys.stderr)
else:
    print(c("\nNo missing entries. .info file is complete.", "cyan"), file=sys.stderr)
