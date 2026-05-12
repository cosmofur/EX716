#!/usr/bin/env python3

import os
import re
import sys
from collections import defaultdict

DEBUG = False

FUNC_START_RE = re.compile(
    r'(?<![A-Za-z0-9_])@?FUNCTION\s+([A-Za-z_][A-Za-z0-9_]*)',
    re.IGNORECASE
)

FUNC_END_RE = re.compile(
    r'(?<![A-Za-z0-9_])@?ENDFUNCTION\b',
    re.IGNORECASE
)

CALL_FULL_RE = re.compile(
    r'@call[0-9]*(?:\([^)]*\))?\s+([A-Za-z_][A-Za-z0-9_]*)(.*)',
    re.IGNORECASE
)

MACRO_DEF_RE = re.compile(r'^\s*M\s+([A-Za-z_][A-Za-z0-9_()]*)(?:\s+(.*))?', re.IGNORECASE)
MACRO_USE_RE = re.compile(r'@([A-Za-z_][A-Za-z0-9_]*)')
DEP_HINT_RE = re.compile(r'@DEP:\s*([A-Za-z_][A-Za-z0-9_]*)')

# ------------------------------------------------------------

def dprint(*args):
    if DEBUG:
        print(*args)

def is_valid_ld_file(path):
    name = os.path.basename(path)
    return name.endswith(".ld") and not name.startswith(".#") and not name.startswith(".") and not name.endswith("~")

def strip_comment(line):
    return line.split("#", 1)[0]

def preprocess_lines(raw_lines):
    out = []
    buf = ""

    for raw in raw_lines:
        line = raw.rstrip("\n")
        stripped = line.rstrip()
        continued = stripped.endswith("\\")

        if continued:
            stripped = stripped[:-1]

        buf += stripped + " "

        if not continued:
            clean = strip_comment(buf).strip()
            if clean:
                out.append(clean)
            buf = ""

    if buf.strip():
        clean = strip_comment(buf).strip()
        if clean:
            out.append(clean)

    return out

def read_ld_file(path):
    try:
        with open(path, "r") as f:
            return preprocess_lines(f.readlines())
    except FileNotFoundError:
        return []

# ------------------------------------------------------------

def build_global_function_map(directories):
    func_to_lib = {}

    for directory in directories:
        for name in os.listdir(directory):
            path = os.path.join(directory, name)
            if not is_valid_ld_file(path):
                continue

            libname = os.path.splitext(name)[0]
            lines = read_ld_file(path)

            for line in lines:
                m = FUNC_START_RE.search(line)
                if m:
                    func_to_lib[m.group(1)] = libname

    return func_to_lib

# ------------------------------------------------------------

def extract_macros(lines):
    macros = {}

    for line in lines:
        m = MACRO_DEF_RE.match(line)
        if not m:
            continue

        name = m.group(1).split("(", 1)[0]
        body = m.group(2) or ""

        calls = set()
        for c in re.findall(r'@call[0-9]*(?:\([^)]*\))?\s+([A-Za-z_][A-Za-z0-9_]*)', body, re.IGNORECASE):
            calls.add(c)

        macros[name] = calls

    return macros

# ------------------------------------------------------------

def extract_dependencies(path, global_funcs):
    lines = read_ld_file(path)
    macros = extract_macros(lines)

    deps = defaultdict(set)
    all_funcs = set()          # local only
#    all_funcs = set(global_funcs)
    current_func = None

    for line in lines:

        m = FUNC_START_RE.search(line)
        if m:
            current_func = m.group(1)
            all_funcs.add(current_func)
            continue

        if FUNC_END_RE.search(line):
            current_func = None
            continue

        if not current_func:
            continue

        calls = set()

        m = CALL_FULL_RE.search(line)
        if m:
            func = m.group(1)
            rest = m.group(2)

            calls.add(func)

            for tok in re.findall(r'[A-Za-z_][A-Za-z0-9_]*', rest):
                if tok in global_funcs:
                    calls.add(tok)

        for macro_name in MACRO_USE_RE.findall(line):
            if macro_name in macros:
                calls |= macros[macro_name]

        for hint in DEP_HINT_RE.findall(line):
            calls.add(hint)

        for target in calls:
            if target != current_func:
                deps[current_func].add(target)

    return dict(deps), all_funcs

# ------------------------------------------------------------

def compute_use_distance(deps, funcs):
    dist = {f: 0 for f in funcs}

    changed = True
    while changed:
        changed = False
        for f in funcs:
            for d in deps.get(f, []):
                if d in dist:
                    if dist[d] <= dist[f]:
                        dist[d] = dist[f] + 1
                        changed = True
    return dist

def parent_before_dependency_order(deps, all_funcs):
    """
    Topological order:
    parent -> child (A uses B means A -> B)

    We return standard topo order (children first),
    caller will reverse it to get parent-first.
    """

    local = set(all_funcs)

    # Build graph
    graph = {f: set() for f in local}
    indegree = {f: 0 for f in local}

    for parent, uses in deps.items():
        for child in uses:
            if child in local:
                if child not in graph[parent]:
                    graph[parent].add(child)
                    indegree[child] += 1

    # Kahn's algorithm
    queue = [f for f in local if indegree[f] == 0]
    queue.sort()  # deterministic

    result = []

    while queue:
        n = queue.pop(0)
        result.append(n)

        for child in sorted(graph[n]):
            indegree[child] -= 1
            if indegree[child] == 0:
                queue.append(child)

    # cycle detection
    if len(result) != len(local):
        print("ERROR: dependency cycle detected")
        for f in local:
            if indegree[f] > 0:
                print("  cycle involving:", f, "->", graph[f])
        sys.exit(2)

    return result

# ------------------------------------------------------------

def generate_ref(lib_path, func_to_lib):
    libname = os.path.splitext(os.path.basename(lib_path))[0]
    ref_path = os.path.splitext(lib_path)[0] + ".ref"

    deps, all_funcs = extract_dependencies(lib_path, set(func_to_lib.keys()))

#    dist = compute_use_distance(deps, all_funcs)
#    ordered = sorted(all_funcs, key=lambda f: (-dist[f], f))
#    ordered.reverse()

    ordered = parent_before_dependency_order(deps, all_funcs)


    print(f"Generating {ref_path}")

    with open(ref_path, "w") as out:
        out.write("# Auto-generated dependency file\n\n")

        # --- external library guards ---
        external_libs = set()

        for uses in deps.values():
            for t in uses:
                provider = func_to_lib.get(t)
                if provider and provider != libname:
                    external_libs.add(provider)

        for lib in sorted(external_libs):
            out.write(f"IFNDEF __LIB_{lib.upper()}_LOADED\n")
            out.write(f'    P "Require {lib}.ld needs to be included."\n')
            out.write("ENDBLOCK\n\n")

        # --- function rules ---
        for func in ordered:
            if func not in deps:
                continue
            uses = deps.get(func, set())

            out.write(f"@FUNCTIONNEEDS {func}\n")

            for target in sorted(uses):
                provider = func_to_lib.get(target)

                # 🔥 NEW: cross-library ordering warning
                if provider and provider != libname:
                    out.write(f"   IFNDEF __LIB_{provider.upper()}_LOADED\n")
                    out.write(f'        P "ERROR: {func} requires {provider}.ld to be loaded AFTER {libname}.ld"\n')
                    out.write("    ENDBLOCK\n")

                out.write(f"    @USE {target}\n")

            out.write("ENDBLOCK\n\n")

    print(f"Generated {ref_path}")

# ------------------------------------------------------------

def collect_ld_files(inputs):
    files = []

    for arg in inputs:
        if os.path.isdir(arg):
            for name in os.listdir(arg):
                path = os.path.join(arg, name)
                if is_valid_ld_file(path):
                    files.append(path)
        elif os.path.isfile(arg):
            if is_valid_ld_file(arg):
                files.append(arg)

    return sorted(set(files))

# ------------------------------------------------------------

def main():
    global DEBUG

    args = sys.argv[1:]

    if "--debug" in args:
        DEBUG = True
        args.remove("--debug")

    if not args:
        print("Usage: linklibrary.py <dir>")
        sys.exit(1)

    ld_files = collect_ld_files(args)

    directories = {os.path.dirname(p) or "." for p in ld_files}
    func_to_lib = build_global_function_map(directories)

    for path in ld_files:
        generate_ref(path, func_to_lib)

# ------------------------------------------------------------

if __name__ == "__main__":
    main()
    
