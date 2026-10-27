# EX716 MapMaker (Milestone 2 — host reference)

This directory contains the portable MapMaker core and its Linux reference
program.  The core uses a caller-supplied `Map`; its 16,129 packed 16-bit cells
consume 32,258 bytes, while metadata holds dimensions, type, format version,
original seed, and current 16-bit PRNG state.  It never allocates dynamically.

`MapCell` stores elevation in its low byte.  Its high byte uses the low nibble
for ground type and the upper nibble for feature flags. `mapmaker_host` writes
the deterministic `EX716MAP 2` text format. It records the PRNG state and a
settlement section before the HEX16 cells:

```text
SETTLEMENTS=12
SITE=15177,1,1,0
DATA=HEX16
```

Each `SITE` is `cell_index,type,size,tech_level`. `mapmaker-validate` rebuilds
the settlement list, rejects duplicate/out-of-range records, and verifies that
every record has a matching `FEATURE_SITE` cell. The checksum is FNV-1a over
metadata and cells.

The current host pipeline creates one deterministic mountain ridge (five to ten
intermediate control points), stamps integer foothills, then performs the
requested number of full-buffer smoothing passes. It classifies elevations at
or below sea level 24 as water, producing mountain islands; exposed elevations
become grass, rock, or snow. It then starts eight rivers at elevation 80 or
higher; each follows cardinal steepest descent to ocean water or a small lake
at a local minimum. Finally, clustered forest covers 30% of eligible inland
grassland. Twelve settlements are then placed, preferring river mouths and
other coastlines; their map cells are marked as sites and their extra metadata
lives in a caller-owned settlement list keyed by cell index. Smoothing preserves
terrain and feature bits and avoids in-place traversal bias. `mapmaker-host` writes
both the map file and a 24-bit color BMP. BMP is directly viewable in Windows
11 Photos; terrain chooses the base color and elevation lightens it.

Build and test on Linux:

```sh
make test
make
./mapmaker-host 12345 example.map example.bmp 10 4
./mapmaker-validate example.map
./mapmaker-ansi example.map
```

`mapmaker-ansi` renders each map cell as one terminal background-color space,
so its 127-cell rows fit terminals at least 127 columns wide.
It uses ANSI SGR `48;5;N` colors from a 64-color subset of the 256-color xterm
palette: a 4×4×4 RGB table with component levels 0, 2, 4, and 5. Elevation
chooses dark through light shades; dirt is brown, grass green, and water blue.
Rock and snow use the terminal's 24-step ANSI grayscale ramp so mountain
erosion remains visible. The optional `AGE` argument is the smoothing-pass
count (default 10); `RANGES` is the number of layered mountain ranges (default
4). Use a terminal with ANSI 256-color support.

Milestone 2 is intentionally GCC-only while far data pointers and multi-bank
allocation are absent from lcc. The next step is visual inspection and tuning
of the ridge/erosion parameters, followed by a far-pointer compiler milestone
before restoring CPU24 parity.
