#!/usr/bin/env python3
import re
import sys
from pathlib import Path

re_pushreturn = re.compile(r'^(\s*)@PUSHRETURN\b(.*)$')
re_localvar   = re.compile(r'^(\s*)@LocalVar\s+(\S+)\s+\S+(.*)$')
re_restorevar = re.compile(r'^(\s*)@RestoreVar\s+\S+\s*(.*)$')

def convert_lines(lines):
    out = []

    pending_pushreturn_indent = None
    in_locals = False
    restore_pending = False

    for line in lines:
        m_push = re_pushreturn.match(line)
        m_local = re_localvar.match(line)
        m_restore = re_restorevar.match(line)

        # New function/prologue marker.
        # If we saw a previous @PUSHRETURN but never saw @LocalVar,
        # then no @Locals is emitted for that function.
        if m_push:
            if restore_pending:
                out.append(f"{m_push.group(1)}@EndLocals\n")
                restore_pending = False
                in_locals = False

            out.append(line)
            pending_pushreturn_indent = m_push.group(1)
            continue

        # First @LocalVar after @PUSHRETURN opens the new locals block.
        if m_local:
            indent, name, trailing = m_local.groups()

            if pending_pushreturn_indent is not None:
                out.append(f"{pending_pushreturn_indent}@Locals\n")
                pending_pushreturn_indent = None
                in_locals = True

            if restore_pending:
                out.append(f"{indent}@EndLocals\n")
                restore_pending = False
                in_locals = False

            out.append(f"{indent}@Local {name}{trailing}\n")
            continue

        # Compress a run of @RestoreVar lines into one @EndLocals.
        if m_restore:
            if in_locals:
                restore_pending = True
            else:
                # Unexpected RestoreVar outside converted locals block.
                out.append(line)
            continue

        # Any ordinary line after RestoreVar closes the locals block.
        if restore_pending:
            indent = re.match(r'^(\s*)', line).group(1)
            out.append(f"{indent}@EndLocals\n")
            restore_pending = False
            in_locals = False

        out.append(line)

    if restore_pending:
        out.append("@EndLocals\n")

    return out


def main():
    if len(sys.argv) < 2:
        print(f"usage: {sys.argv[0]} FILE...", file=sys.stderr)
        sys.exit(2)

    for filename in sys.argv[1:]:
        path = Path(filename)

        original = path.read_text().splitlines(keepends=True)
        converted = convert_lines(original)

        backup = path.with_suffix(path.suffix + ".bak")
        backup.write_text("".join(original))
        path.write_text("".join(converted))

        print(f"converted {path}  backup={backup}")


if __name__ == "__main__":
    main()
