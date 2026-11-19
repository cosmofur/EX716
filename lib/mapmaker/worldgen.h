#ifndef WORLDGEN_H
#define WORLDGEN_H

/*
 * Replacement MapMaker foundation.  This API is intentionally independent
 * from the older 127 by 127 Map/WorldGlobe pipeline while it is evaluated.
 * It uses C89 types and caller-owned storage.
 */

typedef unsigned short WorldGenCell;

#define WORLDGEN_MAP_WIDTH 128U
#define WORLDGEN_MAP_HEIGHT 128U
#define WORLDGEN_MAP_CELLS (WORLDGEN_MAP_WIDTH * WORLDGEN_MAP_HEIGHT)

#define WORLDGEN_GLOBE_ROWS 64U
#define WORLDGEN_GLOBE_EQUATOR_WIDTH 128U
#define WORLDGEN_GLOBE_POLAR_WIDTH 32U
/* Enough words for a rectangular 128 by 64 caller buffer.  Active rows use
 * fewer cells and `cell_count` states exactly how many are used. */
#define WORLDGEN_GLOBE_MAX_CELLS \
    (WORLDGEN_GLOBE_ROWS * WORLDGEN_GLOBE_EQUATOR_WIDTH)
#define WORLDGEN_GLOBE_MIN_STORAGE_CELLS 5960U

#define WORLDGEN_CELL_VALUE_MASK 0x00ffU
#define WORLDGEN_CELL_SURFACE_MASK 0x0f00U
#define WORLDGEN_SURFACE_NONE 0x0000U
#define WORLDGEN_SURFACE_OCEAN 0x0100U
#define WORLDGEN_SURFACE_LAND 0x0200U
#define WORLDGEN_SURFACE_HIGHLAND 0x0300U
#define WORLDGEN_SURFACE_MOUNTAIN 0x0400U
#define WORLDGEN_FEATURE_RIVER  0x1000U
#define WORLDGEN_FEATURE_LAKE   0x2000U
#define WORLDGEN_FEATURE_SWAMP  0x4000U
#define WORLDGEN_FEATURE_FOREST 0x4000U
#define WORLDGEN_FEATURE_SITE   0x8000U

#define WORLDGEN_RIVER_END_SEA  1U
#define WORLDGEN_RIVER_END_POND 2U
#define WORLDGEN_RIVER_END_LIMIT 3U
#define WORLDGEN_RIVER_END_TRIBUTARY 4U

#define WORLDGEN_PROFILE_EARTHLIKE 1U
#define WORLDGEN_PROFILE_DEAD      2U

/* Level describes intended content; location and metres-per-cell determine
 * the actual zoom, so programs may add compatible intermediate scales. */
#define WORLDGEN_LEVEL_REGION     1U
#define WORLDGEN_LEVEL_WORLD_TILE 2U
#define WORLDGEN_LEVEL_SITE       3U
#define WORLDGEN_LEVEL_LOCAL      4U

#define WORLDGEN_REGION_METERS_PER_CELL 5000U
#define WORLDGEN_WORLD_METERS_PER_CELL 1000U
#define WORLDGEN_SITE_METERS_PER_CELL 10U
#define WORLDGEN_LOCAL_METERS_PER_CELL 1U

typedef struct WorldGenMap {
    unsigned long seed;
    unsigned short profile;
    unsigned short level;
    unsigned short meters_per_cell;
    unsigned int cell_size_half_meters;
    long origin_x_meters;
    long origin_y_meters;
    long origin_x_half_meters;
    long origin_y_half_meters;
    WorldGenCell cells[WORLDGEN_MAP_CELLS];
} WorldGenMap;

typedef struct WorldGenGlobe {
    unsigned long seed;
    unsigned short profile;
    int sea_level;
    unsigned char continent_count;
    unsigned char row_width[WORLDGEN_GLOBE_ROWS];
    unsigned short row_start[WORLDGEN_GLOBE_ROWS + 1U];
    unsigned short cell_count;
    unsigned short cell_capacity;
    WorldGenCell *cells;
} WorldGenGlobe;

/* River geometry is stored in stable half-metre world coordinates.  Callers
 * own both arrays so the host viewer can build a network once and reuse it
 * while regenerating map tiles at different scales. */
typedef struct WorldGenRiverPoint {
    long x_half_meters;
    long y_half_meters;
    unsigned short flags;
} WorldGenRiverPoint;

typedef struct WorldGenRiver {
    unsigned long id;
    unsigned int first_point;
    unsigned int point_count;
    unsigned int terminal;
    long mouth_x_half_meters;
    long mouth_y_half_meters;
    unsigned int width_half_meters;
    unsigned int pond_radius_half_meters;
} WorldGenRiver;

typedef struct WorldGenHydrology {
    WorldGenRiver *rivers;
    unsigned int river_capacity;
    unsigned int river_count;
    WorldGenRiverPoint *points;
    unsigned int point_capacity;
    unsigned int point_count;
} WorldGenHydrology;

/* Set up a normal working tile.  Generation phases populate its cells later. */
int WorldGenMapInitialize(WorldGenMap *map, unsigned long seed,
                          unsigned short profile, unsigned short level,
                          unsigned short meters_per_cell,
                          long origin_x_meters, long origin_y_meters);

/* Initialize at half-metre coordinate precision.  Cell size and origins are
 * expressed in 0.5 m units (1 unit = 0.5 m); this supports sprite-scale maps
 * without floating point. */
int WorldGenMapInitializeHalfMeter(WorldGenMap *map, unsigned long seed,
                                   unsigned short profile,
                                   unsigned short level,
                                   unsigned int cell_size_half_meters,
                                   long origin_x_half_meters,
                                   long origin_y_half_meters);

/* Set up a 64-row globe.  `storage` is caller-owned and must have room for
 * WORLDGEN_GLOBE_MIN_STORAGE_CELLS active cells. */
int WorldGenGlobeInitialize(WorldGenGlobe *globe, WorldGenCell *storage,
                            unsigned short capacity, unsigned long seed,
                            unsigned short profile);

/* Phase 1.  `sea_level` is a signed contour adjustment (-32 to 32). */
int WorldGenGlobeEstablishSeaLevel(WorldGenGlobe *globe, int sea_level);

/* Phase 2.  Form 1..8 continent silhouettes from stable irregular fields.
 * It resets the coarse surface classification but preserves the sea level. */
int WorldGenGlobeGenerateContinents(WorldGenGlobe *globe,
                                    unsigned char continent_count);

/* Phase 3.  Lay one or two seeded, wandering mountain spines across each
 * continent and spread their uplift through irregular weathered foothills. */
int WorldGenGlobeGenerateRelief(WorldGenGlobe *globe);

int WorldGenHydrologyInitialize(WorldGenHydrology *hydrology,
                                WorldGenRiver *rivers,
                                unsigned int river_capacity,
                                WorldGenRiverPoint *points,
                                unsigned int point_capacity);
int WorldGenGenerateHydrology(WorldGenHydrology *hydrology,
                              const WorldGenGlobe *globe);

/* Generate a 128 by 128 view at the map's physical origin and scale.  The
 * same seed/globe/profile/origin/scale always recreates the same tile.  The
 * initial implementation refines globe land and relief; later water, biome,
 * settlement, city, and dungeon passes attach to this stable entry point. */
int WorldGenGenerateTile(WorldGenMap *map, const WorldGenGlobe *globe);

int WorldGenMapGetCell(const WorldGenMap *map, unsigned int x,
                       unsigned int y, WorldGenCell *cell);

unsigned int WorldGenGlobeRowWidth(const WorldGenGlobe *globe,
                                   unsigned int row);
int WorldGenGlobeGetCell(const WorldGenGlobe *globe, unsigned int row,
                         unsigned int column, WorldGenCell *cell);

/* A reusable signed irregular field.  Positive means inside.  The caller
 * controls scale and aspect; the seed/domain make its edge stable across
 * zoom levels. */
int WorldGenIrregularField(unsigned long seed, unsigned long domain,
                           long x, long y, long center_x, long center_y,
                           unsigned int radius, unsigned int aspect_percent);

#endif
