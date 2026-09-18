#!/usr/bin/env python3
"""Preview ASCII artificial horizons and compare nearby bank angles.

The viewport matches the center panel in flightsim.inc: 39 columns by 11 rows.
Positive bank makes the horizon rise to the right; positive pitch moves it down.
This is an exploration tool, not a runtime dependency of the simulator.
"""

import argparse
import math


WIDTH = 39
HEIGHT = 11


def render(bank, pitch=0, width=WIDTH, height=HEIGHT):
    """Return rows of a horizon, with sky blank and ground dotted."""
    radians = math.radians(bank)
    sine = math.sin(radians)
    cosine = math.cos(radians)
    center_x = (width - 1) / 2
    center_y = (height - 1) / 2 + pitch
    line_char = "|" if abs(bank) == 90 else "/" if bank > 0 else "\\" if bank < 0 else "-"
    rows = []
    for y in range(height):
        row = []
        for x in range(width):
            # Signed perpendicular distance also works at +/-90 degrees.
            distance = (y - center_y) * cosine + (x - center_x) * sine
            if abs(distance) <= 0.5:
                row.append(line_char)
            elif distance > 0:
                row.append(".")
            else:
                row.append(" ")
        rows.append("".join(row))
    return rows


def difference(first, second):
    return sum(a != b for row_a, row_b in zip(first, second)
               for a, b in zip(row_a, row_b))


def curved_angles():
    """Keep each range endpoint exact and distribute its rounding."""
    positive = [0, 4, 8, 12, 16, 20,
                26, 32, 39, 45,
                53, 62, 70,
                80, 90]
    return [-angle for angle in reversed(positive[1:])] + positive


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--step", type=int,
                        help="use a uniform bank interval instead of the default curve")
    parser.add_argument("--pitch", type=int, default=0,
                        help="pitch in character rows (default: 0)")
    parser.add_argument("--previews", type=int, nargs="*",
                        default=[0, 4, 8, 20, 26, 45, 53, 70, 80, 90],
                        help="angles to print as full pictures")
    args = parser.parse_args()
    if args.step is not None and args.step <= 0:
        parser.error("step must be positive")
    if not -4 <= args.pitch <= 4:
        parser.error("pitch must be from -4 to 4")

    if args.step is None:
        angles = curved_angles()
        schedule = "curved"
    else:
        angles = sorted(set(range(-90, 91, args.step)) | {-90, 0, 90})
        schedule = f"uniform {args.step} degrees"
    pictures = {angle: render(angle, args.pitch) for angle in angles}
    print(f"Viewport: {WIDTH} x {HEIGHT}; pitch: {args.pitch}; schedule: {schedule}")
    print("Angles: " + ", ".join(str(angle) for angle in angles))
    print("Changed cells between consecutive bank angles:")
    for left, right in zip(angles, angles[1:]):
        changed = difference(pictures[left], pictures[right])
        print(f"{left:>4} to {right:>4}: {changed:>3} / {WIDTH * HEIGHT}")

    for angle in args.previews:
        if not -90 <= angle <= 90:
            parser.error("preview angles must be from -90 to 90")
        print(f"\nBank {angle:+d} degrees, pitch {args.pitch:+d}")
        for row in render(angle, args.pitch):
            print("|" + row + "|")


if __name__ == "__main__":
    main()
