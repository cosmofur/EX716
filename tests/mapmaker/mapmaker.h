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
#define MAP_FORMAT_VERSION 2

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

/* Stable, target-independent checksum over metadata and cells. */
unsigned long MapChecksum(const Map *map);

#endif
