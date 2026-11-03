# MapMaker library tests

The production library is [`lib/mapmaker`](../../lib/mapmaker), not this
directory. It is portable C89, uses caller-owned map and settlement storage,
and does not allocate dynamically.

The library supplies deterministic utility functions for cells, random values,
terrain shaping, rivers, forests, and settlement placement. Its complete map
generators currently cover wilderness islands, towns/cities, and
room-and-corridor dungeons. `worldglobe.c` supplies the persistent planetary
overview used before local tiles: 64 wrapping latitude rings, 32--127 cells
per ring, continent/ocean influences, plate-boundary relief, and broad
latitude moisture bands. It needs 5,860 caller-owned bytes for active cells.
`regionalmap.c` is the first consumer: it generates 127×127 regional maps at
5 km per cell (635 km square), sampling and smoothing a one-cell global halo
so adjacent regional maps join without clamped-edge seams. Five 1 km world
maps fit exactly across a regional map.
`worldmap.c` refines that field into a 127 km, 1 km/cell world tile. It uses a
tile-local elevation datum with 5 m height units, preserves regional terrain
continuity with a global smoothing halo, and returns caller-owned pond, grove,
and hill records through `MapFeatureList`. Each of those structures is formed
from two to four deterministic cores, then blended with a 3×3 global smoothing
kernel, avoiding repeated diamond-shaped terrain stamps.

`localmap.c` is the generic site-map layer. Its location and resolution are
stored in canonical half-metre units, so a 127×127 local map can be generated
at 10 m, 5 m, 2 m, 1 m, or 0.5 m per cell without floating point or
scale-specific tile coordinates. `MapGenerateLocalMap` currently develops the
wilderness-site and settlement profiles from the globe-backed regional field:
it adds seam-safe local relief, water, groves, rock fields, route corridors,
and settlement building footprints, returning feature records in caller-owned
storage. The tactical, interior, cave, and simulation profile identifiers are
stable API reservations for their later fine-scale generators.

`test_mapmaker.c` is deliberately a test harness rather than an application.
It asserts API behavior and prints sampled ASCII previews so generated maps
remain easy to inspect in ordinary test output. Legend: `~` water, `^` rock,
`f` forest, `+` road, `#` building, `X` dungeon wall, and `.` dungeon floor.
The final preview is the globe: `~` ocean, `,` shallow sea, `.` coast, `+`
lowland, `^` upland, `A` plateau, `M` mountain belt, and `*` polar ice.
The final regional previews print north/south and west/east boundary strips
from three adjacent 5 km tiles; the west/east output is rotated 90 degrees
with the western source column printed first. `.` is grassland and `:` is dry
ground.
The last preview is three north/south adjacent 1 km tiles; `f` marks grove
cover and its feature summary reports deterministic ponds, groves, and hills.

Run the complete host suite with:

```sh
make test
```

Run the CPU24/lcc smoke separately with:

```sh
make test-lcc
```

Build and run the host ANSI explorer with:

```sh
make explorer
./mapmaker-explorer
```

It uses raw terminal input: `W`, `A`, `S`, and `D` move one cell at the
active scale; `+` zooms in and `-` zooms out; `Q` exits. The player remains
at the screen center while a local map is regenerated around its canonical
physical position. It supports 0.5 m, 1 m, 2 m, 5 m, 10 m, 20 m, 50 m, and
100 m cells; the 100 m overview displays a 12.7 km square. Cell glyph blocks
are 6×3 at 0.5 m, 4×2 at 1 m, 2×1 at 2 m, and 1×1 at coarser scales. Forest
edges use dim `t` and interiors bright `T`; cyan `.` is shallow/shore water
and dark-blue `~` is deeper water or a river.
The player starts on the first land cell found near canonical world center and
cannot step into water. Terrain glyph/color choices are centralized in
`explorer_style` in `mapmaker_explorer.c` for quick visual experimentation.

The target smoke is intentionally small (7x7) and verifies initialization,
cell access, smoothing, and deterministic PRNG behavior through the lcc/CPU24
pipeline. The host suite exercises every full generator; its new complete-map
entry points are omitted from the compact target image.
