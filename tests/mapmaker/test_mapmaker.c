#include <stdio.h>

#include "mapmaker.h"
#include "mapmath.h"
#include "worldglobe.h"
#include "regionalmap.h"
#include "worldmap.h"
#include "localmap.h"

static int check(int condition, const char *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message);
        return 0;
    }
    return 1;
}

static char map_symbol(MapCell cell)
{
    unsigned int terrain;

    terrain = CELL_TERRAIN(cell);
    if (terrain & FEATURE_SITE) return '*';
    if (terrain & FEATURE_ROAD) return '+';
    if (terrain & FEATURE_RIVER) return '~';
    if (terrain & FEATURE_FOREST) return 'f';
    switch (terrain & TERRAIN_GROUND_MASK) {
    case TERRAIN_WATER: return '~';
    case TERRAIN_ROCK: return '^';
    case TERRAIN_SNOW: return 'A';
    case TERRAIN_PAVEMENT: return '+';
    case TERRAIN_BUILDING: return '#';
    case TERRAIN_DUNGEON_FLOOR: return '.';
    case TERRAIN_DUNGEON_WALL: return 'X';
    default: return ' ';
    }
}

static void preview(const char *name, const Map *map)
{
    unsigned int x;
    unsigned int y;
    unsigned int sample_width;
    unsigned int sample_height;

    sample_width = MAP_WIDTH < 64 ? MAP_WIDTH : 64;
    sample_height = MAP_HEIGHT < 24 ? MAP_HEIGHT : 24;
    printf("\n%s (%ux%u, checksum=%08lX)\n", name, map->width, map->height,
           MapChecksum(map));
    for (y = 0; y < sample_height; ++y) {
        for (x = 0; x < sample_width; ++x)
            putchar(map_symbol(map->cells[(y * MAP_HEIGHT / sample_height) *
                                      MAP_WIDTH + x * MAP_WIDTH / sample_width]));
        putchar('\n');
    }
}

static char globe_symbol(unsigned char cell)
{
    switch (cell & WORLD_LANDFORM_MASK) {
    case WORLD_DEEP_OCEAN: return '~';
    case WORLD_SHALLOW_SEA: return ',';
    case WORLD_COASTAL_LOWLAND: return '.';
    case WORLD_LOWLAND: return '+';
    case WORLD_UPLAND: return '^';
    case WORLD_PLATEAU: return 'A';
    case WORLD_MOUNTAIN_BELT: return 'M';
    default: return '*';
    }
}

static void globe_preview(const WorldGlobe *globe)
{
    unsigned int row;
    unsigned int column;
    unsigned char cell;

    printf("\nWORLD GLOBE (%u cells; ~300 km at equator)\n",
           (unsigned int)globe->cell_count);
    for (row = 0; row < WORLD_GLOBE_LATITUDE_RINGS; ++row) {
        for (column = 0; column < (WORLD_GLOBE_EQUATOR_CELLS -
             WorldGlobeRowWidth(globe, row)) / 2U; ++column)
            putchar(' ');
        for (column = 0; column < WorldGlobeRowWidth(globe, row); ++column) {
            WorldGlobeGetCell(globe, row, column, &cell);
            putchar(globe_symbol(cell));
        }
        putchar('\n');
    }
}

static void regional_seam_rows(const char *name, const Map *map,
                               unsigned int first_row)
{
    unsigned int x;
    unsigned int y;

    printf("%s\n", name);
    for (y = first_row; y < first_row + 8U; ++y) {
        for (x = 0; x < MAP_WIDTH; ++x) {
            if (CELL_TERRAIN(map->cells[y * MAP_WIDTH + x]) & FEATURE_FOREST) {
                putchar('f');
                continue;
            }
            switch (CELL_TERRAIN(map->cells[y * MAP_WIDTH + x]) &
                    TERRAIN_GROUND_MASK) {
            case TERRAIN_WATER: putchar('~'); break;
            case TERRAIN_ROCK: putchar('^'); break;
            case TERRAIN_SNOW: putchar('A'); break;
            case TERRAIN_DIRT: putchar(':'); break;
            default: putchar('.'); break;
            }
        }
        putchar('\n');
    }
}

static void regional_seam_preview(const Map *north, const Map *middle,
                                  const Map *south)
{
    printf("\n5 KM REGIONAL NORTH/SOUTH JOINS (~635 km tiles)\n");
    regional_seam_rows("north tile, southern edge", north, MAP_HEIGHT - 8U);
    regional_seam_rows("middle tile, northern edge", middle, 0U);
    regional_seam_rows("middle tile, southern edge", middle, MAP_HEIGHT - 8U);
    regional_seam_rows("south tile, northern edge", south, 0U);
}

static void regional_seam_columns(const char *name, const Map *map,
                                  unsigned int first_column)
{
    unsigned int x;
    unsigned int y;

    printf("%s\n", name);
    /* This is a 90-degree rotated view: the westernmost selected source
     * column is the first printed line, followed by columns eastward. */
    for (x = first_column; x < first_column + 8U; ++x) {
        for (y = 0; y < MAP_HEIGHT; ++y) {
            switch (CELL_TERRAIN(map->cells[y * MAP_WIDTH + x]) &
                    TERRAIN_GROUND_MASK) {
            case TERRAIN_WATER: putchar('~'); break;
            case TERRAIN_ROCK: putchar('^'); break;
            case TERRAIN_SNOW: putchar('A'); break;
            case TERRAIN_DIRT: putchar(':'); break;
            default: putchar('.'); break;
            }
        }
        putchar('\n');
    }
}

static void regional_west_east_preview(const Map *west, const Map *middle,
                                       const Map *east)
{
    printf("\n5 KM REGIONAL WEST/EAST JOINS (rotated 90 degrees)\n");
    regional_seam_columns("west tile, eastern edge", west, MAP_WIDTH - 8U);
    regional_seam_columns("middle tile, western edge", middle, 0U);
    regional_seam_columns("middle tile, eastern edge", middle, MAP_WIDTH - 8U);
    regional_seam_columns("east tile, western edge", east, 0U);
}

static void world_seam_preview(const Map *north, const Map *middle,
                               const Map *south)
{
    printf("\n1 KM WORLD-TILE NORTH/SOUTH JOINS (~127 km tiles)\n");
    regional_seam_rows("north tile, southern edge", north, MAP_HEIGHT - 8U);
    regional_seam_rows("middle tile, northern edge", middle, 0U);
    regional_seam_rows("middle tile, southern edge", middle, MAP_HEIGHT - 8U);
    regional_seam_rows("south tile, northern edge", south, 0U);
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
    Map town;
    Map town_repeat;
    Map city;
    Map dungeon;
    Map wilderness;
    Settlement wilderness_items[16];
    SettlementList wilderness_settlements;
    unsigned int buildings;
    unsigned int roads;
    unsigned int floors;
    static unsigned char globe_storage[WORLD_GLOBE_STORAGE_CELLS];
    static unsigned char globe_repeat_storage[WORLD_GLOBE_STORAGE_CELLS];
    WorldGlobe globe;
    WorldGlobe globe_repeat;
    unsigned int globe_index;
    unsigned int globe_land;
    unsigned int globe_mountains;
    unsigned char globe_cell;
    unsigned char globe_first;
    static Map regional_north;
    static Map regional_middle;
    static Map regional_south;
    static Map regional_west;
    static Map regional_east;
    static Map regional_repeat;
    static Map world_north;
    static Map world_middle;
    static Map world_south;
    static Map world_repeat;
    static MapFeature world_feature_items[128];
    static MapFeature world_repeat_feature_items[128];
    MapFeatureList world_features;
    MapFeatureList world_repeat_features;
    unsigned int pond_features;
    unsigned int grove_features;
    unsigned int hill_features;
    static Map local_first;
    static Map local_repeat;
    static Map local_east;
    static Map local_settlement;
    static Map local_half_metre;
    static MapFeature local_feature_items[128];
    static MapFeature local_repeat_feature_items[128];
    MapFeatureList local_features;
    MapFeatureList local_repeat_features;
    unsigned int local_routes;
    unsigned int local_buildings;

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
    if (!check(MapChecksum(&second) == 0x56CBA03EUL, "initial checksum")) return 1;
    if (!check(MapInitialize(&mountain, 2468UL, 0) &&
               MapInitialize(&repeat, 2468UL, 0), "mountain setup")) return 1;
    if (!check(MapAddMountainRange(&mountain, 96, 224, 3) &&
               MapAddMountainRange(&repeat, 96, 224, 3), "mountain generation")) return 1;
    if (!check(MapChecksum(&mountain) == 0x7700BD7EUL &&
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
    SettlementListInitialize(&wilderness_settlements, wilderness_items, 16U);
    if (!check(MapInitialize(&wilderness, 9876UL, MAP_TYPE_WILDERNESS) &&
               MapGenerateWilderness(&wilderness, 2, 3, &wilderness_settlements) &&
               wilderness.type == MAP_TYPE_WILDERNESS &&
               wilderness_settlements.count > 0U,
               "complete wilderness generator")) return 1;
    if (!check(MapInitialize(&town, 1001UL, MAP_TYPE_TOWN) &&
               MapInitialize(&town_repeat, 1001UL, MAP_TYPE_TOWN) &&
               MapGenerateTown(&town, 0) && MapGenerateTown(&town_repeat, 0) &&
               town.type == MAP_TYPE_TOWN &&
               MapChecksum(&town) == MapChecksum(&town_repeat),
               "deterministic town generation")) return 1;
    buildings = 0;
    roads = 0;
    for (index = 0; index < MAP_CELLS; ++index) {
        if ((CELL_TERRAIN(town.cells[index]) & TERRAIN_GROUND_MASK) == TERRAIN_BUILDING)
            ++buildings;
        if (CELL_TERRAIN(town.cells[index]) & FEATURE_ROAD)
            ++roads;
    }
    if (!check(buildings > 0U && roads > 0U, "town buildings and roads")) return 1;
    if (!check(MapInitialize(&city, 1002UL, MAP_TYPE_CITY) &&
               MapGenerateTown(&city, 1) && city.type == MAP_TYPE_CITY,
               "city generation")) return 1;
    if (!check(MapInitialize(&dungeon, 1003UL, MAP_TYPE_DUNGEON) &&
               MapGenerateDungeon(&dungeon, 12) && dungeon.type == MAP_TYPE_DUNGEON,
               "dungeon generation")) return 1;
    floors = 0;
    for (index = 0; index < MAP_CELLS; ++index)
        if ((CELL_TERRAIN(dungeon.cells[index]) & TERRAIN_GROUND_MASK) ==
            TERRAIN_DUNGEON_FLOOR)
            ++floors;
    if (!check(floors > 12U && !MapGenerateDungeon(&dungeon, 0),
               "dungeon rooms and validation")) return 1;
    if (!check(MapMathSin(0U) == 0 && MapMathSin(64U) == MAPMATH_TRIG_SCALE &&
               MapMathSin(128U) == 0 && MapMathSin(192U) == -MAPMATH_TRIG_SCALE &&
               MapMathCos(0U) == MAPMATH_TRIG_SCALE && MapMathCos(64U) == 0,
               "quarter-wave trigonometry")) return 1;
    if (!check(WorldGlobeInitialize(&globe, globe_storage,
                                    WORLD_GLOBE_STORAGE_CELLS, 424242UL) &&
               WorldGlobeInitialize(&globe_repeat, globe_repeat_storage,
                                    WORLD_GLOBE_STORAGE_CELLS, 424242UL) &&
               globe.cell_count == WORLD_GLOBE_STORAGE_CELLS &&
               WorldGlobeRowWidth(&globe, 0U) == WORLD_GLOBE_POLAR_CELLS &&
               WorldGlobeRowWidth(&globe, 31U) == WORLD_GLOBE_EQUATOR_CELLS &&
               WorldGlobeRowWidth(&globe, 63U) == WORLD_GLOBE_POLAR_CELLS &&
               WorldGlobeGenerate(&globe) && WorldGlobeGenerate(&globe_repeat),
               "globe geometry and generation")) return 1;
    globe_land = 0;
    globe_mountains = 0;
    for (globe_index = 0; globe_index < globe.cell_count; ++globe_index) {
        if (globe_storage[globe_index] != globe_repeat_storage[globe_index])
            return 1;
        if ((globe_storage[globe_index] & WORLD_LANDFORM_MASK) >= WORLD_COASTAL_LOWLAND)
            ++globe_land;
        if ((globe_storage[globe_index] & WORLD_LANDFORM_MASK) == WORLD_MOUNTAIN_BELT)
            ++globe_mountains;
    }
    if (!check(globe_land > 0U && globe_land < globe.cell_count &&
               globe_mountains > 0U &&
               WorldGlobeGetCell(&globe, 20U, WorldGlobeRowWidth(&globe, 20U),
                                  &globe_cell) &&
               WorldGlobeGetCell(&globe, 20U, 0U, &globe_first) &&
               globe_cell == globe_first,
               "globe determinism, landforms, and longitude wrap")) return 1;
    if (!check(MapGenerateRegionalTile(&regional_north, &globe, 0L, -1L) &&
               MapGenerateRegionalTile(&regional_middle, &globe, 0L, 0L) &&
               MapGenerateRegionalTile(&regional_south, &globe, 0L, 1L) &&
               MapGenerateRegionalTile(&regional_west, &globe, -1L, 0L) &&
               MapGenerateRegionalTile(&regional_east, &globe, 1L, 0L) &&
               MapGenerateRegionalTile(&regional_repeat, &globe, 0L, 0L) &&
               regional_middle.type == MAP_TYPE_REGIONAL &&
               regional_middle.meters_per_cell == MAP_REGIONAL_METERS_PER_CELL &&
               regional_middle.meters_per_height_unit ==
                   MAP_REGIONAL_HEIGHT_METERS_PER_UNIT &&
               regional_north.tile_y == -1L && regional_south.tile_y == 1L &&
               regional_west.tile_x == -1L && regional_east.tile_x == 1L &&
               MapChecksum(&regional_middle) == MapChecksum(&regional_repeat),
               "five-kilometre regional tiles")) return 1;
    MapFeatureListInitialize(&world_features, world_feature_items, 128U);
    MapFeatureListInitialize(&world_repeat_features, world_repeat_feature_items, 128U);
    if (!check(MapGenerateWorldTile(&world_north, &globe, 0L, -1L, 0) &&
               MapGenerateWorldTile(&world_middle, &globe, 0L, 0L,
                                    &world_features) &&
               MapGenerateWorldTile(&world_south, &globe, 0L, 1L, 0) &&
               MapGenerateWorldTile(&world_repeat, &globe, 0L, 0L,
                                    &world_repeat_features) &&
               world_middle.type == MAP_TYPE_WORLD_TILE &&
               world_middle.meters_per_cell == MAP_WORLD_METERS_PER_CELL &&
               world_middle.meters_per_height_unit ==
                   MAP_WORLD_HEIGHT_METERS_PER_UNIT &&
               world_middle.elevation_datum_meters != 0L &&
               MapChecksum(&world_middle) == MapChecksum(&world_repeat) &&
               world_features.count == world_repeat_features.count,
               "one-kilometre world tiles")) return 1;
    pond_features = 0;
    grove_features = 0;
    hill_features = 0;
    for (index = 0; index < world_features.count; ++index) {
        if (world_features.items[index].type == MAP_FEATURE_POND)
            ++pond_features;
        if (world_features.items[index].type == MAP_FEATURE_GROVE)
            ++grove_features;
        if (world_features.items[index].type == MAP_FEATURE_HILL)
            ++hill_features;
    }
    if (!check(pond_features > 0U && grove_features > 0U && hill_features > 0U,
               "world ponds, groves, and hills")) return 1;
    MapFeatureListInitialize(&local_features, local_feature_items, 128U);
    MapFeatureListInitialize(&local_repeat_features, local_repeat_feature_items,
                             128U);
    if (!check(MapGenerateLocalMap(&local_first, &globe, -2540L, 5080L,
                                   MAP_LOCAL_CELL_HALF_METERS_10M,
                                   MAP_LOCAL_PROFILE_WILDERNESS_SITE,
                                   &local_features) &&
               MapGenerateLocalMap(&local_repeat, &globe, -2540L, 5080L,
                                   MAP_LOCAL_CELL_HALF_METERS_10M,
                                   MAP_LOCAL_PROFILE_WILDERNESS_SITE,
                                   &local_repeat_features) &&
               MapGenerateLocalMap(&local_east, &globe, 0L, 5080L,
                                   MAP_LOCAL_CELL_HALF_METERS_10M,
                                   MAP_LOCAL_PROFILE_WILDERNESS_SITE, 0) &&
               local_first.type == MAP_TYPE_LOCAL &&
               local_first.half_meters_per_cell ==
                   MAP_LOCAL_CELL_HALF_METERS_10M &&
               local_first.origin_x_half_meters == -2540L &&
               MapChecksum(&local_first) == MapChecksum(&local_repeat) &&
               local_features.count == local_repeat_features.count &&
               !MapGenerateLocalMap(&local_first, &globe, 0L, 0L, 3U,
                                    MAP_LOCAL_PROFILE_WILDERNESS_SITE, 0),
               "generic local site maps")) return 1;
    if (!check(local_east.origin_x_half_meters ==
                   local_first.origin_x_half_meters +
                   (long)MAP_WIDTH * MAP_LOCAL_CELL_HALF_METERS_10M &&
               local_east.origin_y_half_meters == local_first.origin_y_half_meters,
               "local-map canonical adjacent locations")) return 1;
    if (!check(MapGenerateLocalMap(&local_settlement, &globe, 0L, 0L,
                                   MAP_LOCAL_CELL_HALF_METERS_5M,
                                   MAP_LOCAL_PROFILE_SETTLEMENT, 0),
               "settlement local profile")) return 1;
    if (!check(MapGenerateLocalMap(&local_half_metre, &globe, 41L, -17L,
                                   MAP_LOCAL_CELL_HALF_METERS_0_5M,
                                   MAP_LOCAL_PROFILE_TACTICAL_OUTDOOR, 0) &&
               local_half_metre.half_meters_per_cell == 1U &&
               local_half_metre.meters_per_cell == 0U &&
               local_half_metre.origin_x_half_meters == 41L,
               "half-metre local resolution")) return 1;
    local_routes = 0U;
    local_buildings = 0U;
    for (index = 0U; index < MAP_CELLS; ++index) {
        if (CELL_TERRAIN(local_settlement.cells[index]) & FEATURE_ROAD)
            ++local_routes;
        if ((CELL_TERRAIN(local_settlement.cells[index]) & TERRAIN_GROUND_MASK) ==
            TERRAIN_BUILDING) ++local_buildings;
    }
    if (!check(local_routes > 0U && local_buildings > 0U,
               "local routes and building footprints")) return 1;
    preview("WILDERNESS", &repeat);
    preview("TOWN", &town);
    preview("CITY", &city);
    preview("DUNGEON", &dungeon);
    globe_preview(&globe);
    regional_seam_preview(&regional_north, &regional_middle, &regional_south);
    regional_west_east_preview(&regional_west, &regional_middle, &regional_east);
    printf("1 KM FEATURES ponds=%u groves=%u hills=%u\n", pond_features,
           grove_features, hill_features);
    world_seam_preview(&world_north, &world_middle, &world_south);
    printf("PASS checksum=%08lX sizeof(Map)=%lu\n", MapChecksum(&first), (unsigned long)sizeof(Map));
    return 0;
}
