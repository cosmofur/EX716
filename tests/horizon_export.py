#!/usr/bin/env python3
"""Export the horizon preview pictures as labeled string blocks."""

import argparse
from pathlib import Path

from horizon_preview import WIDTH, curved_angles, render


TEMPLATE_HEIGHT = 19
VIEW_HEIGHT = 11


def format_blocks():
    angles = curved_angles()
    lines = [
        "# ASCII horizon template draft",
        f"# Each block is {WIDTH} columns x {TEMPLATE_HEIGHT} rows.",
        f"# The display uses a {WIDTH} x {VIEW_HEIGHT} row slice of a block.",
        "# At pitch 0, show template rows 4..14 (zero based).",
        "# For positive pitch, move the slice upward by that many rows.",
        "# Space = sky; dot = ground; /, \\, -, | = horizon.",
        "# These are reviewable text strings, not assembler syntax yet.",
        "",
    ]
    for angle in angles:
        lines.append(f"# Bank {angle:+d} degrees")
        lines.extend(f'"{row}"' for row in render(angle, height=TEMPLATE_HEIGHT))
        lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", default="horizon_blocks.txt",
                        help="output file (default: horizon_blocks.txt)")
    args = parser.parse_args()
    destination = Path(args.output)
    destination.write_text(format_blocks(), encoding="ascii")
    print(f"Wrote {len(curved_angles())} horizon blocks to {destination}")


if __name__ == "__main__":
    main()
