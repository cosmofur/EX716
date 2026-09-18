#!/usr/bin/env python3
"""
FUNCTION dependency extractor for EX716-style assembler

Purpose:
--------
Scan a library file, extract @FUNCTION blocks, detect @CALL dependencies,
and generate correctly ordered @FUNCTIONNEEDS / @USE blocks.

Key behavior:
-------------
- Only scans inside @FUNCTION ... @ENDFUNCTION
- Only treats '@CALL ...' as dependency (NOT Call(...))
- Handles '@CALL(AV) foo' variants
- Includes ALL functions in graph (even with no dependencies)  <-- FIXED
- Does NOT error on missing functions (external libraries)
- Outputs external dependencies as comments using '#'
"""

import re
import sys

# ------------------------------------------------------------
# Regex patterns
# ------------------------------------------------------------

# Match: @FUNCTION foo
FUNC_START = re.compile(r'@FUNCTION\s+([A-Za-z_][A-Za-z0-9_]*)')

# Match: @ENDFUNCTION
FUNC_END = re.compile(r'@ENDFUNCTION')

# Match ONLY dependency calls:
#   @CALL foo
#   @CALL(AV) foo
CALL_RE = re.compile(
    r'@C[Aa][Ll][Ll]\s*(?:\([A-Za-z]*\))?\s+([A-Za-z_][A-Za-z0-9_]*)'
)

# Optional: ignore known primitives if needed
IGNORE = {
    # "PUSH", "JMP", etc.
}


# ------------------------------------------------------------
# Step 1: Extract all @FUNCTION blocks
# ------------------------------------------------------------

def extract_functions(lines):
    """
    Returns:
        dict: { function_name: [list of lines in body] }
    """
    functions = {}
    current_name = None
    body = []

    for line in lines:
        m = FUNC_START.search(line)
        if m:
            current_name = m.group(1)
            body = []
            continue

        if current_name:
            if FUNC_END.search(line):
                functions[current_name] = body[:]
                current_name = None
            else:
                body.append(line)

    return functions


# ------------------------------------------------------------
# Step 2: Extract dependencies (FIXED: include ALL functions)
# ------------------------------------------------------------

def extract_dependencies(functions):
    """
    Build dependency graph:
        function -> set(dependent functions)

    IMPORTANT:
        Every function is included, even if it has zero dependencies.
    """
    deps = {}

    # Initialize ALL functions (fix for your bug)
    for fname in functions:
        deps[fname] = set()

    # Now populate dependencies
    for fname, body in functions.items():
        for line in body:
            for m in CALL_RE.finditer(line):
                target = m.group(1)

                if target != fname and target not in IGNORE:
                    deps[fname].add(target)

    return deps


# ------------------------------------------------------------
# Step 3: Topological sort
# ------------------------------------------------------------

def topo_sort(graph):
    """
    Returns:
        order: list of functions in safe dependency order
        external_refs: set of functions not defined in this file
    """
    visited = {}
    order = []
    external_refs = set()

    def visit(node):
        if node in visited:
            if visited[node] == 1:
                raise RuntimeError(f"Cycle detected involving: {node}")
            return

        visited[node] = 1  # visiting

        for dep in graph.get(node, []):
            if dep in graph:
                visit(dep)
            else:
                external_refs.add(dep)

        visited[node] = 2  # done
        order.append(node)

    # Sorted for stable output
    for fn in sorted(graph):
        visit(fn)

    return order, external_refs


# ------------------------------------------------------------
# Step 4: Emit FUNCTIONNEEDS blocks
# ------------------------------------------------------------

def emit(deps, order):
    """
    Generate @FUNCTIONNEEDS output text
    """
    out = []

    for fname in order:
        if not deps[fname]:
            continue

        out.append(f"@FUNCTIONNEEDS {fname}")

        for dep in sorted(deps[fname]):
            out.append(f"   @USE {dep}")

        out.append("ENDBLOCK\n")

    return "\n".join(out)


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

def main():
    if len(sys.argv) != 2:
        print("Usage: python gen_functionneeds.py <input.asm>")
        sys.exit(1)

    filename = sys.argv[1]

    with open(filename) as f:
        lines = f.readlines()

    # Step 1
    functions = extract_functions(lines)

    # Step 2
    deps = extract_dependencies(functions)

    # Step 3
    order, external_refs = topo_sort(deps)

    # Step 4
    output = emit(deps, order)
    print(output)

    # External dependency report (using '#')
    if external_refs:
        print("# --- External dependencies (not defined in this file) ---")
        for ref in sorted(external_refs):
            print(f"#  {ref}")


if __name__ == "__main__":
    main()
    
