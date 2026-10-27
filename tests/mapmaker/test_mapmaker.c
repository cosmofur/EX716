#include <stdio.h>

#include "mapmaker.h"

static int check(int condition, const char *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message);
        return 0;
    }
    return 1;
}

int main(void)
{
    Map first;
    Map second;
    Map mountain;
    Map repeat;
    MapCell cell;
    unsigned long first_random;
    unsigned int index;
    unsigned int highest;
    unsigned int rock_cells;
    unsigned int water_cells;
    unsigned int land_cells;
    unsigned int river_cells;
    unsigned int forest_cells;
    int rivers;
    int forests;
    int settlements;
    Settlement settlement_items[8];
    SettlementList settlement_list;
    Settlement *settlement;

    if (!check(MapInitialize(&first, 12345UL, 7), "initialization")) return 1;
    if (!check(first.width == MAP_WIDTH && first.height == MAP_HEIGHT, "dimensions")) return 1;
    if (!check(first.seed == 12345UL && first.prng_state == 12345UL, "metadata")) return 1;
    if (!check(MapGetCell(&first, 0, 0, &cell) && cell == MAKE_CELL(0, TERRAIN_DIRT), "first cell")) return 1;
    if (!check(MapGetCell(&first, MAP_WIDTH - 1, MAP_HEIGHT - 1, &cell) && cell == MAKE_CELL(0, TERRAIN_DIRT), "last cell")) return 1;
    if (!check(MapSetCell(&first, 0, 0, MAKE_CELL(255, TERRAIN_SNOW | FEATURE_FOREST)), "set corner")) return 1;
    if (!check(MapGetCell(&first, 0, 0, &cell) && CELL_HEIGHT(cell) == 255U && CELL_TERRAIN(cell) == (TERRAIN_SNOW | FEATURE_FOREST), "cell encoding")) return 1;
    if (!check(!MapSetCell(&first, MAP_WIDTH, 0, 0) && !MapGetCell(&first, 0, MAP_HEIGHT, &cell), "bounds")) return 1;
    if (!check(MapInitialize(&second, 12345UL, 7), "second initialization")) return 1;
    first_random = MapRandom(&first);
    if (!check(first_random == MapRandom(&second), "PRNG repeatability")) return 1;
    for (index = 0; index < 100; ++index)
        if (!check(MapRandomBelow(&first, 17) < 17U, "bounded PRNG")) return 1;
    if (!check(MapChecksum(&second) == 0xEA85C076UL, "initial checksum")) return 1;
    if (!check(MapInitialize(&mountain, 2468UL, 0) &&
               MapInitialize(&repeat, 2468UL, 0), "mountain setup")) return 1;
    if (!check(MapAddMountainRange(&mountain, 96, 224, 3) &&
               MapAddMountainRange(&repeat, 96, 224, 3), "mountain generation")) return 1;
    if (!check(MapChecksum(&mountain) == 0x50C0069AUL &&
               MapChecksum(&mountain) == MapChecksum(&repeat), "mountain repeatability")) return 1;
    highest = 0;
    rock_cells = 0;
    for (index = 0; index < MAP_CELLS; ++index) {
        if (CELL_HEIGHT(mountain.cells[index]) > highest)
            highest = CELL_HEIGHT(mountain.cells[index]);
        if ((CELL_TERRAIN(mountain.cells[index]) & TERRAIN_GROUND_MASK) == TERRAIN_ROCK)
            ++rock_cells;
    }
    if (!check(highest > 96U && rock_cells > 30U, "mountain elevations and terrain")) return 1;
    if (!check(!MapAddMountainRange(&mountain, 224, 96, 1) &&
               !MapSmooth(&mountain, -1), "terrain argument validation")) return 1;
    if (!check(MapSetCell(&mountain, 0, 0, MAKE_CELL(100, TERRAIN_GRASS | FEATURE_FOREST)) &&
               MapSmooth(&mountain, 1) &&
               MapGetCell(&mountain, 0, 0, &cell) &&
               CELL_TERRAIN(cell) == (TERRAIN_GRASS | FEATURE_FOREST),
               "smoothing preserves terrain flags")) return 1;
    if (!check(MapClassifyTerrain(&repeat, 24U), "terrain classification")) return 1;
    water_cells = 0;
    land_cells = 0;
    for (index = 0; index < MAP_CELLS; ++index) {
        if ((CELL_TERRAIN(repeat.cells[index]) & TERRAIN_GROUND_MASK) == TERRAIN_WATER)
            ++water_cells;
        else
            ++land_cells;
    }
    if (!check(water_cells > 0U && land_cells > 0U, "island coastline")) return 1;
    rivers = MapAddRivers(&repeat, 80, 4);
    river_cells = 0;
    for (index = 0; index < MAP_CELLS; ++index)
        if (CELL_TERRAIN(repeat.cells[index]) & FEATURE_RIVER)
            ++river_cells;
    if (!check(rivers == 4 && river_cells >= 4U, "river generation")) return 1;
    if (!check(MapAddRivers(0, 80, 1) == -1, "river argument validation")) return 1;
    forests = MapAddForests(&repeat, 30);
    forest_cells = 0;
    for (index = 0; index < MAP_CELLS; ++index)
        if (CELL_TERRAIN(repeat.cells[index]) & FEATURE_FOREST)
            ++forest_cells;
    if (!check(forests > 0 && forest_cells == (unsigned int)forests,
               "clustered forest generation")) return 1;
    if (!check(MapAddForests(0, 30) == -1 && MapAddForests(&repeat, 101) == -1,
               "forest argument validation")) return 1;
    SettlementListInitialize(&settlement_list, settlement_items, 8);
    settlements = MapAddSettlements(&repeat, &settlement_list, 4);
    settlement = MapFindSettlement(&settlement_list, settlement_items[0].cell_index);
    if (!check(settlements > 0 && settlement_list.count == (unsigned int)settlements &&
               settlement != 0 && settlement->type >= SETTLEMENT_PORT &&
               (CELL_TERRAIN(repeat.cells[settlement->cell_index]) & FEATURE_SITE),
               "settlement placement and lookup")) return 1;
    if (!check(MapAddSettlements(0, &settlement_list, 1) == -1 &&
               MapFindSettlement(0, 0) == 0, "settlement argument validation")) return 1;
    if (!check(!MapClassifyTerrain(&repeat, 256U), "sea level validation")) return 1;
    printf("PASS checksum=%08lX sizeof(Map)=%lu\n", MapChecksum(&first), (unsigned long)sizeof(Map));
    return 0;
}
