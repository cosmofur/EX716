#!/usr/bin/env python3
"""Export a deduplicated horizon row pool and per-angle pointer tables."""

import argparse
from collections import Counter
from itertools import groupby
from pathlib import Path

from horizon_preview import WIDTH, curved_angles, render


TEMPLATE_HEIGHT = 19
VIEW_HEIGHT = 11


def bank_label(angle):
    return f"HorizonBank_{'M' if angle < 0 else 'P'}{abs(angle):02d}"


def row_label(row):
    """Describe each left-to-right run in the row label."""
    codes = {" ": "S", ".": "G", "/": "F", "\\": "B", "-": "H", "|": "V"}
    runs = [f"{codes[character]}{sum(1 for _ in group)}"
            for character, group in groupby(row)]
    return "HorizonRow_" + "_".join(runs)


def build_database():
    angles = curved_angles()
    blocks = {angle: render(angle, height=TEMPLATE_HEIGHT) for angle in angles}
    unique_rows = list(dict.fromkeys(row for rows in blocks.values() for row in rows))
    names = {row: row_label(row) for row in unique_rows}
    uses = Counter(row for rows in blocks.values() for row in rows)

    lines = [
        "# Deduplicated ASCII horizon database draft",
        f"# {len(angles)} bank blocks; {TEMPLATE_HEIGHT} row pointers per block;",
        f"# {len(unique_rows)} unique strings of {WIDTH} characters plus terminator.",
        f"# Display {VIEW_HEIGHT} rows beginning at pointer index 4 - PitchValue.",
        "# Space = sky; dot = ground; /, \\, -, | = horizon.",
        "# Single-quoted rows are raw: backslashes are literal characters.",
        "",
        "# Label runs: S=sky, G=ground, F=/, B=backslash, H=-, V=|.",
        "# Example: HorizonRow_G19_V1_S19 has 19 dots, |, then 19 spaces.",
        "# Shared row strings",
    ]
    for row in unique_rows:
        lines.append(f":{names[row]} '{row}' $$0  # used {uses[row]} times")

    lines.extend(["", "# Angle lookup: signed degrees, then matching block pointers", ":HorizonAngles"])
    lines.extend(f"   {angle}" for angle in angles)
    lines.extend(["", ":HorizonBankPointers"])
    lines.extend(f"   {bank_label(angle)}" for angle in angles)
    lines.append("")

    for angle, rows in blocks.items():
        lines.append(f"# Bank {angle:+d} degrees")
        lines.append(f":{bank_label(angle)}")
        lines.extend(f"   {names[row]}" for row in rows)
        lines.append("")
    return "\n".join(lines), len(angles), len(unique_rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", default="horizon_pointer_blocks.inc",
                        help="output file (default: horizon_pointer_blocks.inc)")
    args = parser.parse_args()
    content, angle_count, row_count = build_database()
    Path(args.output).write_text(content, encoding="ascii")
    plain_words = angle_count * TEMPLATE_HEIGHT * (WIDTH + 1)
    shared_words = row_count * (WIDTH + 1) + angle_count * TEMPLATE_HEIGHT
    print(f"Wrote {angle_count} bank blocks and {row_count} shared strings to {args.output}")
    print(f"Estimated row storage: {plain_words} -> {shared_words} words "
          f"({plain_words - shared_words} saved; excludes angle lookup)")


if __name__ == "__main__":
    main()
