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

The first target smoke uses a 7x7 map and checks initialization, cell access,
smoothing, and deterministic PRNG behavior. The separate WorldGen smoke uses
a full 128x128 map, initializes and accesses cells, draws them through EXGC,
and reads back pixels on CPU24. The host suite exercises complete generators;
full procedural WorldGen generation on CPU24 remains to be verified.


The replacement WorldGen globe and 1 km tiles can also be displayed with the
EXGC framebuffer and SIXEL renderer. Build the native host viewer from this
directory and run it in a SIXEL-capable terminal:

```sh
make worldgen-exgc
./worldgen-exgc                       # globe, default seed
./worldgen-exgc --seed 12345          # globe, selected seed
./worldgen-exgc --tile                # 128x128 world tile
./worldgen-exgc --tile --origin 6000000 -1200000 --seed 12345
```

The output is a 240x192 EXGC framebuffer scaled to 720x384 by the existing
SIXEL renderer. Ocean, land, highland and mountain relief use palette colors;
no rivers, forests or cities are implied by those colors. The `--origin`
values are the tile's upper-left world coordinates in metres. The native viewer
generates the map on the host and uses the shared EXGC device renderer.

Build and launch the interactive world explorer in a SIXEL-capable terminal:

```sh
make worldgen-explorer
./worldgen-explorer --seed 12345
```

Use `W`, `A`, `S`, and `D` to pan, `+`/`=` to zoom in, `-` to zoom out,
and `Q` to quit. Zoom changes by about 1.5x per key. The globe remains visible
through the intermediate zooms; at roughly 30 km per cell, the explorer
switches to a newly generated 128x128 tile centered on the same location.
Further zooms regenerate that tile at finer scales, passing through about
3 km, 300 m, 30 m, 1 m, and 0.5 m per cell. The status labels the current band
from geography through region, city, street, building, and sprite scale; those
labels describe resolution, not generated content. Longitude wraps and
latitude stops at the poles. This establishes the location and scale handoff
for later regional, city, and dungeon map generation.

The interactive explorer builds a deterministic, world-coordinate river
network once per session from selected mountain and highland cells. Paths favor
downhill neighbors, keep their heading over flat ground with seeded meanders,
and terminate at the sea, another river, or a pond at a closed lowland sink.
Low, nearly flat stretches are tagged as wetland. The map status reports the
network totals, and the same river paths are drawn over generated tiles at each
zoom level.

At 0.5 m per cell, the explorer keeps generating a 128x128 map (64x64 m) and
shows a centered 32x32-cell viewport (16x16 m). Placeholder sprites occupy
4x4 cells, or 2x2 m, so the view shows eight sprite widths across and movement
advances by half a sprite. The current demo uses a tiled floor, two door tiles,
and two character sprites from the CC0 Kenney Tiny Dungeon set in
`sprites/Tiles`; this is a scale preview, not generated city content. The
individual tile PNGs are converted to a compact C header during the build.
Whole-map tile views and the globe keep their previous rendering path.

To display the exact same generated framebuffer through the CPU24 graphics
card, generate a guest assembly image and run it from the repository root:

```sh
./tests/mapmaker/worldgen-exgc --asm > /tmp/worldgen-exgc.asm
CPUPATH=lib python3 cpu24.py -f --exgc-render /tmp/worldgen-exgc.asm
```

`--seed`, `--tile`, and `--origin` work with `--asm` too. Map generation is
currently performed on the host; the generated guest image preloads framebuffer
A and programs its palette. This is a display integration test, not yet a
CPU24 build of the WorldGen generator or an interactive map explorer.


The renderer uses `lib/exgc/exgc_canvas.c`, a C89 framebuffer interface
shared by both compilers. GCC supplies a host EXGC segment buffer; lcc uses
CPU24 far-memory calls to segment `FC`. The standalone `exgc_sixel.c` remains
the host presentation backend: guest C programs write EXGC memory and do not
need to encode SIXEL themselves. `make test-lcc` includes a CPU24 pixel,
packing, bounds, and palette smoke test for the shared canvas.

The EX716 lcc compiler accepts the 128x128 word map plus metadata. The ECC
smoke test compiles `worldgen_cpu24.c`, `worldgen.c`, `worldgen_exgc.c`,
`exgc_canvas.c`, and `mapmath.c` together, then runs them with CPU24. It
initializes a full-size map, draws it into EXGC, and checks pixels at both
edges. Full procedural globe/tile generation has not yet been exercised
end-to-end on CPU24. A large near map must fit alongside the target program's
other data and runtime allocations in the same 64 KiB segment.

`make test-lcc` invokes `../../bin/ECC` directly for each C test and then runs
the resulting assembly with `python3 ../../cpu24.py -q -f`. For example:

```sh
../../bin/ECC -I ../../lib/mapmaker -I ../../lib/exgc \
  -o /tmp/ex716-worldgen.asm worldgen_cpu24.c worldgen_exgc.c \
  ../../lib/exgc/exgc_canvas.c ../../lib/mapmaker/worldgen.c \
  ../../lib/mapmaker/mapmath.c
CPUPATH=../../lib python3 ../../cpu24.py -q -f /tmp/ex716-worldgen.asm
```
