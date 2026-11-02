#ifndef MAPMAKER_H
#define MAPMAKER_H

/* Portable C89 core.  CPU24 requires unsigned short to be 16 bits. */
#ifndef MAP_WIDTH
#define MAP_WIDTH 127
#endif
#ifndef MAP_HEIGHT
#define MAP_HEIGHT 127
#endif
#define MAP_CELLS (MAP_WIDTH * MAP_HEIGHT)
#define MAP_FORMAT_VERSION 4

typedef unsigned short MapCell;

#ifdef __EX716__
#include <farptr.h>
#endif

#define CELL_HEIGHT(cell) ((unsigned int)((cell) & 0x00ffU))
#define CELL_TERRAIN(cell) ((unsigned int)(((cell) >> 8) & 0x00ffU))
#define MAKE_CELL(height, terrain) \
    ((MapCell)((((unsigned int)(terrain) & 0x00ffU) << 8) | \
               ((unsigned int)(height) & 0x00ffU)))

/* Low nibble is ground; high nibble contains independent feature flags. */
#define TERRAIN_GROUND_MASK 0x0fU
#define TERRAIN_DIRT        0x00U
#define TERRAIN_GRASS       0x01U
#define TERRAIN_SAND        0x02U
#define TERRAIN_ROCK        0x03U
#define TERRAIN_WATER       0x04U
#define TERRAIN_SNOW        0x05U
#define TERRAIN_PAVEMENT    0x06U
#define TERRAIN_BUILDING    0x07U
#define TERRAIN_DUNGEON_FLOOR 0x08U
#define TERRAIN_DUNGEON_WALL  0x09U
#define FEATURE_FOREST      0x10U
#define FEATURE_RIVER       0x20U
#define FEATURE_ROAD        0x40U
#define FEATURE_SITE        0x80U

typedef struct Map {
    unsigned short width;
    unsigned short height;
    unsigned short type;
    unsigned short format_version;
    unsigned long seed;
    unsigned short prng_state;
    /* Physical scale and stable position in the map's own tile grid. */
    unsigned short meters_per_cell;
    unsigned short meters_per_height_unit;
    long elevation_datum_meters;
    long tile_x;
    long tile_y;
    /* Canonical physical location/scale.  A unit is half a metre, allowing
     * local maps down to 0.5 m per cell without floating point. */
    unsigned short half_meters_per_cell;
    long origin_x_half_meters;
    long origin_y_half_meters;
    MapCell cells[MAP_CELLS];
} Map;

typedef struct Settlement {
    unsigned short cell_index;
    unsigned short type;
    unsigned short size;
    unsigned short tech_level;
} Settlement;

typedef struct SettlementList {
    Settlement *items;
    unsigned short count;
    unsigned short capacity;
} SettlementList;

#define SETTLEMENT_PORT    1U
#define SETTLEMENT_INLAND  2U

/* Map types are deliberately descriptive rather than format-specific. */
#define MAP_TYPE_WILDERNESS 0U
#define MAP_TYPE_TOWN       1U
#define MAP_TYPE_CITY       2U
#define MAP_TYPE_DUNGEON    3U
#define MAP_TYPE_REGIONAL   4U
#define MAP_TYPE_WORLD_TILE 5U
#define MAP_TYPE_LOCAL      6U

typedef struct MapFeature {
    unsigned short cell_index;
    unsigned short type;
    unsigned short radius_meters;
    unsigned short variant;
    unsigned long feature_id;
} MapFeature;

typedef struct MapFeatureList {
    MapFeature *items;
    unsigned short count;
    unsigned short capacity;
} MapFeatureList;

#define MAP_FEATURE_POND  1U
#define MAP_FEATURE_GROVE 2U
#define MAP_FEATURE_HILL  3U
#define MAP_FEATURE_ROCK_FIELD 4U
#define MAP_FEATURE_ROUTE      5U
#define MAP_FEATURE_BUILDING   6U

/* Returns 1 for success, 0 for invalid input. */
int MapInitialize(Map *map, unsigned long seed, unsigned short type);
int MapSetCell(Map *map, unsigned int x, unsigned int y, MapCell cell);
int MapGetCell(const Map *map, unsigned int x, unsigned int y, MapCell *cell);

/* Per-map xorshift16 PRNG.  MapRandomBelow uses modulo in this first core. */
unsigned long MapRandom(Map *map);
unsigned int MapRandomBelow(Map *map, unsigned int limit);

/* Host-reference terrain operations.  Mountain age is the smoothing-pass count. */
int MapAddMountainRange(Map *map, int low_height, int high_height, int age);
int MapSmooth(Map *map, int passes);
int MapClassifyTerrain(Map *map, unsigned int sea_level);
/* Returns the number of rivers started; each follows cardinal steepest descent. */
int MapAddRivers(Map *map, int start_height, int count);
/* Returns the number of grass cells marked as clustered forest. */
int MapAddForests(Map *map, int density);
void SettlementListInitialize(SettlementList *list, Settlement *items,
                              unsigned short capacity);
Settlement *MapFindSettlement(SettlementList *list, unsigned short cell_index);
int MapAddSettlements(Map *map, SettlementList *list, int count);
void MapFeatureListInitialize(MapFeatureList *list, MapFeature *items,
                              unsigned short capacity);

/* Complete deterministic generators.  They use only the map's embedded PRNG
 * and caller-owned storage, so the same seed and arguments always agree. */
int MapGenerateWilderness(Map *map, int ranges, int age,
                          SettlementList *settlements);
int MapGenerateTown(Map *map, int city);
int MapGenerateDungeon(Map *map, int rooms);

/* Stable, target-independent checksum over metadata and cells. */
unsigned long MapChecksum(const Map *map);

#endif
