# MapMaker replacement design

## Purpose

MapMaker produces deterministic, visually plausible game maps.  It is an
appearance-first generator, not a climate, plate-tectonics, or hydrology
simulation.  A seed and a location always produce the same result, allowing a
program to discard a map and recreate it on demand.

The same foundation supports living worlds, dry/dead mining worlds, cities,
and dungeons.  A world profile chooses which phases are enabled; it does not
change coordinates, storage, or the zoom contract.

## Storage and coordinates

`Map` is a caller-owned 128 by 128 array of 16-bit words, indexed from 0
through 127 in each axis.  It is the only normal working buffer.  A program
may retain a small cache of maps and regenerate any other tile from its seed,
profile, level, and tile location.

The overview is the one exception.  It is a 64-row globe with an equatorial
maximum of 128 cells.  Each row records its active length; rows shorten
towards the poles, and longitude wraps.  At this level one cell is about
300 km and holds only broad water/land identity and a coarse elevation class.
It deliberately does not store rivers, forests, roads, settlements, or local
noise.

Every generated map has a canonical world-space origin and an integer cell
size.  A child map samples its parent using world coordinates rather than
copying/rescaling pixels.  Thus a coast or mountain mass stays in the same
place at every level even while the child adds detail.  Features are evaluated
from stable hashed seeds plus their world-space region, never from the order
in which neighboring maps happened to be requested.

Suggested first levels are:

| Level | Cell scale | Main content |
| --- | ---: | --- |
| Globe | ~300 km | ocean, continent outline, coarse relief |
| Region | 5 km | mountain systems, broad drainage and biome zones |
| World tile | 1 km | rivers, lakes, forests, deserts, settlement sites |
| Site | 10-100 m | terrain, roads, fields, districts, building plots |
| Local | 0.5-5 m | paths, walls, rooms, props, tactical terrain |

The exact intermediate scales can change without breaking the contract:
location is physical world space, not a level-specific tile number.

## Current replacement API

`WorldGenMapInitialize` establishes a normal map with seed, profile, intended
level, metres per cell, and physical upper-left origin.  `WorldGenGenerateTile`
then recreates the terrain at that location from a generated `WorldGenGlobe`.
It already supports region (5 km), world-tile (1 km), site (10 m), local
(1 m), and caller-chosen compatible scales through the same entry point.
The seed and profile must match the globe; generated detail is evaluated from
physical coordinates, so independently generated adjacent tiles agree at
their common edge.

The current implementation carries ocean/plains/highlands/mountains from the
globe into a 128 by 128 tile and adds stable fine relief.  Surface water,
biomes, settlement records, city layouts, and dungeon interiors remain later
phases, but will be additions to `WorldGenGenerateTile` and profile-specific
helpers—not a replacement for this API.

## Earth-like phases

Each phase consumes only earlier phase output and persistent feature records.
It may add detail but must not move a parent coastline or a parent mountain
system.

1. **Sea level.** Choose a world profile, a sea level, polar treatment, and a
   target land fraction.  Dead worlds may set no liquid sea and use the same
   landform machinery for basins, regolith, ice, or lava.
2. **Continental silhouettes.** Lay down several large, irregular island
   fields and combine them with union/subtraction.  Classify the resulting
   signed land value against sea level.  This phase is responsible for the
   attractive outline; no tectonic simulation participates.
3. **Relief.** Place one or two directed range spines per sufficiently large
   continent.  Uplift is strongest beside a wandering spine, interrupted by
   passes, and spread through anisotropic weathering/erosion.  The resulting
   altitude field descends through foothills, valleys, and plains rather than
   radial cones around point peaks.
4. **Surface water and biomes.** At 1 km or finer, use the downhill relief
   field to trace selected headwaters.  A river joins a lake when it reaches a
   local basin and otherwise continues to the sea; add an explicit escape
   channel when a filled lake overflows.  Distance to water, latitude,
   rain-shadow side of ranges, and deterministic variation choose grassland,
   desert, and forest.  This is stylized drainage, not a global fluid model.
5. **Settlements.** Score stable candidate sites: river mouths first, lake
   shores next, then river crossings, sheltered coasts, and usable inland
   ground.  Place towns/cities at the highest scoring, well-separated sites;
   later city maps refine those records instead of independently rolling a
   city somewhere else.

## Reusable irregular-shape primitive

The core shape is a deterministic signed field rather than a stamped circle.
For a feature with centre, orientation, base radius, and seed:

1. Convert the query point to feature-local coordinates and measure an
   elliptical base distance.
2. Perturb the boundary by a small number of smooth, seeded angular lobes.
3. Add two or three lower-amplitude, higher-frequency lobes only when a child
   level has enough resolution to show them.
4. Optionally blend overlapping sibling fields and apply a narrow, stable
   domain warp.

The sign of the field says inside/outside; its magnitude says how far from the
edge.  At a low zoom only the broad lobes are sampled.  At a high zoom the
same lobes remain, with bounded extra detail near the boundary.  This creates
recognizable coastlines and non-circular forests without requiring a giant
stored raster or fractal subdivision.  The same primitive can form continent
pieces, islands, lakes, forest stands, dry basins, mountain-footprint masks,
and dungeon caverns; its parameters control the character.

## Profiles and scope

`EARTHLIKE` runs all five phases.  `DEAD` runs continental silhouettes and
relief but swaps water/biome/settlement phases for profile-selected crater,
regolith, mineral, ice, lava, or ruin passes.  `CITY` and `DUNGEON` consume a
site/entrance record and use their own layout algorithms; they share the cell
format, random stream discipline, coordinate metadata, and zoom contract,
not Earth-like terrain rules.

## Migration rule

The current 127-cell, plate/influence-based globe and its descendants are not
to be evolved into this design.  Build the replacement behind a new API and
visual test harness; compare fixed seeds as ASCII/ANSI images; only then
retire the old stack and migrate callers.

The first harness is `tests/mapmaker/worldgen-explorer`.  Build it with
`make -C tests/mapmaker worldgen-explorer` and run it with an optional numeric
seed.  It displays the latitude-shortened globe directly, using blue ocean,
green plains, yellow highlands, and bright-white mountain chains.  It is
deliberately a replacement viewer, not an adaptation of the old local-map
explorer, because it should only visualize fields produced by this API.
