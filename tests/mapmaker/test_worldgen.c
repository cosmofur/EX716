#include <stdio.h>

#include "worldgen.h"

static int check(int condition, const char *message)
{
    if (condition) return 1;
    fprintf(stderr, "worldgen test failed: %s\n", message);
    return 0;
}

int main(void)
{
    static WorldGenCell storage[WORLDGEN_GLOBE_MAX_CELLS];
    static WorldGenCell repeated_storage[WORLDGEN_GLOBE_MAX_CELLS];
    WorldGenGlobe globe;
    WorldGenGlobe repeated;
    WorldGenMap map;
    WorldGenMap tile;
    WorldGenMap tile_repeat;
    unsigned int row;
    unsigned int column;
    unsigned int land;
    unsigned int ocean;
    unsigned int mountains;
    unsigned int highlands;
    WorldGenCell cell;

    if (!check(WorldGenMapInitialize(&map, 1234UL, WORLDGEN_PROFILE_EARTHLIKE,
                                     0U, 1000U, -64000L, -64000L),
               "128 by 128 working map setup")) return 1;
    if (!check(map.cells[0] == WORLDGEN_SURFACE_NONE &&
               map.cells[WORLDGEN_MAP_CELLS - 1U] == WORLDGEN_SURFACE_NONE,
               "working map clears every cell")) return 1;
    if (!check(WorldGenGlobeInitialize(&globe, storage,
                                       WORLDGEN_GLOBE_MAX_CELLS, 0x12345678UL,
                                       WORLDGEN_PROFILE_EARTHLIKE) &&
               WorldGenGlobeInitialize(&repeated, repeated_storage,
                                       WORLDGEN_GLOBE_MAX_CELLS, 0x12345678UL,
                                       WORLDGEN_PROFILE_EARTHLIKE),
               "globe setup")) return 1;
    if (!check(WorldGenGlobeRowWidth(&globe, 0U) == WORLDGEN_GLOBE_POLAR_WIDTH &&
               WorldGenGlobeRowWidth(&globe, 31U) == WORLDGEN_GLOBE_EQUATOR_WIDTH &&
               WorldGenGlobeRowWidth(&globe, 63U) == WORLDGEN_GLOBE_POLAR_WIDTH &&
               globe.cell_count == WORLDGEN_GLOBE_MIN_STORAGE_CELLS,
               "latitude-aware globe geometry")) return 1;
    if (!check(WorldGenGlobeEstablishSeaLevel(&globe, -2) &&
               WorldGenGlobeGenerateContinents(&globe, 4U) &&
               WorldGenGlobeEstablishSeaLevel(&repeated, -2) &&
               WorldGenGlobeGenerateContinents(&repeated, 4U),
               "sea and continent phases")) return 1;
    if (!check(WorldGenGlobeGenerateRelief(&globe) &&
               WorldGenGlobeGenerateRelief(&repeated), "relief phase")) return 1;
    land = 0U;
    ocean = 0U;
    mountains = 0U;
    highlands = 0U;
    for (row = 0U; row < WORLDGEN_GLOBE_ROWS; ++row) {
        for (column = 0U; column < WorldGenGlobeRowWidth(&globe, row); ++column) {
            if (!WorldGenGlobeGetCell(&globe, row, column, &cell)) return 1;
            if ((cell & WORLDGEN_CELL_SURFACE_MASK) == WORLDGEN_SURFACE_LAND)
                ++land;
            else if ((cell & WORLDGEN_CELL_SURFACE_MASK) == WORLDGEN_SURFACE_OCEAN)
                ++ocean;
            else if ((cell & WORLDGEN_CELL_SURFACE_MASK) == WORLDGEN_SURFACE_HIGHLAND)
                ++highlands;
            else if ((cell & WORLDGEN_CELL_SURFACE_MASK) == WORLDGEN_SURFACE_MOUNTAIN)
                ++mountains;
            if (!check(cell == repeated.cells[repeated.row_start[row] + column],
                       "deterministic outline")) return 1;
        }
    }
    if (!check(land + highlands + mountains > 300U && ocean > 300U,
               "mixed land and sea")) return 1;
    if (!check(highlands > 20U && mountains > 10U,
               "weathered mountain-chain relief")) return 1;
    if (!check(WorldGenIrregularField(1UL, 2UL, 0L, 0L, 0L, 0L, 30U, 100U) > 0 &&
               WorldGenIrregularField(1UL, 2UL, 100L, 100L, 0L, 0L, 30U, 100U) < 0,
               "irregular field sign")) return 1;
    if (!check(WorldGenMapInitialize(&tile, 0x12345678UL,
                                     WORLDGEN_PROFILE_EARTHLIKE,
                                     WORLDGEN_LEVEL_WORLD_TILE,
                                     WORLDGEN_WORLD_METERS_PER_CELL,
                                     6000000L, -1200000L) &&
               WorldGenMapInitialize(&tile_repeat, 0x12345678UL,
                                     WORLDGEN_PROFILE_EARTHLIKE,
                                     WORLDGEN_LEVEL_SITE,
                                     WORLDGEN_SITE_METERS_PER_CELL,
                                     6000000L, -1200000L) &&
               WorldGenGenerateTile(&tile, &globe) &&
               WorldGenGenerateTile(&tile_repeat, &globe),
               "world and site tile generation")) return 1;
    if (!check(WorldGenMapGetCell(&tile, 0U, 0U, &cell) &&
               !WorldGenMapGetCell(&tile, WORLDGEN_MAP_WIDTH, 0U, &cell) &&
               tile.cells[0] == tile_repeat.cells[0],
               "coordinate-stable tile sampling")) return 1;
    puts("worldgen phase 1/2/3 tests passed");
    return 0;
}
