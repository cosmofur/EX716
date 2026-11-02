#include "regionalmap.h"

static long regional_floor_divide(long value, long divisor)
{
    if (value >= 0)
        return value / divisor;
    return -(((-value) + divisor - 1) / divisor);
}

static long regional_modulo(long value, long divisor)
{
    return value - regional_floor_divide(value, divisor) * divisor;
}

static unsigned long regional_hash(unsigned long seed, long x, long y)
{
    unsigned long value;

    value = (seed ^ (unsigned long)x) * 16777619UL;
    value ^= (unsigned long)y * 2246822519UL;
    value ^= value >> 13;
    return value & 0xffffffffUL;
}

static unsigned int regional_base_height(unsigned int landform)
{
    switch (landform) {
    case WORLD_DEEP_OCEAN: return 4U;
    case WORLD_SHALLOW_SEA: return 20U;
    case WORLD_COASTAL_LOWLAND: return 42U;
    case WORLD_LOWLAND: return 82U;
    case WORLD_UPLAND: return 132U;
    case WORLD_PLATEAU: return 180U;
    case WORLD_MOUNTAIN_BELT: return 225U;
    default: return 32U;
    }
}

static unsigned int regional_world_height(unsigned char cell)
{
    return regional_base_height(cell & WORLD_LANDFORM_MASK) +
           ((cell & WORLD_ROUGHNESS_MASK) >> WORLD_ROUGHNESS_SHIFT) * 7U;
}

static unsigned int regional_row_height(const WorldGlobe *globe, long row,
                                        long global_x, unsigned char *world_cell)
{
    long period;
    long local_x;
    long column;
    long fraction;
    unsigned char first;
    unsigned char second;
    unsigned int first_height;
    unsigned int second_height;

    if (row < 0)
        row = 0;
    if (row >= (long)WORLD_GLOBE_LATITUDE_RINGS)
        row = (long)WORLD_GLOBE_LATITUDE_RINGS - 1L;
    period = (long)WorldGlobeRowWidth(globe, (unsigned int)row) * 60L;
    local_x = regional_modulo(global_x, period);
    column = local_x / 60L;
    fraction = local_x % 60L;
    if (!WorldGlobeGetCell(globe, (unsigned int)row, (unsigned int)column, &first) ||
        !WorldGlobeGetCell(globe, (unsigned int)row, (unsigned int)(column + 1L),
                           &second))
        return 0;
    first_height = regional_world_height(first);
    second_height = regional_world_height(second);
    if (world_cell != 0)
        *world_cell = fraction < 30L ? first : second;
    return (first_height * (unsigned int)(60L - fraction) +
            second_height * (unsigned int)fraction + 30U) / 60U;
}

static unsigned int regional_raw_height(const WorldGlobe *globe,
                                        long global_x, long global_y,
                                        unsigned char *world_cell)
{
    long globe_row;
    long row_fraction;
    unsigned int height;
    unsigned int next_height;
    int noise;
    unsigned char cell;
    unsigned char next_cell;

    /* One 300 km globe cell contains sixty 5 km regional cells.  Blend both
     * axes before adding detail, so a regional tile never exposes a blocky
     * globe-cell boundary or clamps its neighbour-facing edge. */
    globe_row = 32L + regional_floor_divide(global_y, 60L);
    row_fraction = regional_modulo(global_y, 60L);
    height = regional_row_height(globe, globe_row, global_x, &cell);
    next_height = regional_row_height(globe, globe_row + 1L, global_x,
                                      &next_cell);
    height = (height * (unsigned int)(60L - row_fraction) +
              next_height * (unsigned int)row_fraction + 30U) / 60U;
    if (row_fraction >= 30L)
        cell = next_cell;
    noise = (int)(regional_hash(globe->seed, global_x / 4L, global_y / 4L) % 25UL) - 12;
    if (noise < 0 && height < (unsigned int)(-noise))
        height = 0;
    else
        height = (unsigned int)((int)height + noise);
    if (height > 255U)
        height = 255U;
    if (world_cell != 0)
        *world_cell = cell;
    return height;
}

static unsigned int regional_ground(unsigned int height, unsigned char world_cell)
{
    if (height <= 30U)
        return TERRAIN_WATER;
    if (height >= 224U)
        return TERRAIN_SNOW;
    if (height >= 170U)
        return TERRAIN_ROCK;
    if ((world_cell & WORLD_MOISTURE_MASK) >> WORLD_MOISTURE_SHIFT == 0U)
        return TERRAIN_DIRT;
    return TERRAIN_GRASS;
}

int MapGenerateRegionalTile(Map *map, const WorldGlobe *globe,
                            long tile_x, long tile_y)
{
    unsigned int x;
    unsigned int y;
    long global_x;
    long global_y;
    unsigned int sum;
    unsigned int height;
    unsigned char world_cell;

    if (map == 0 || globe == 0 || globe->cells == 0 || globe->cell_count == 0)
        return 0;
    if (!MapInitialize(map, globe->seed, MAP_TYPE_REGIONAL))
        return 0;
    map->meters_per_cell = MAP_REGIONAL_METERS_PER_CELL;
    map->meters_per_height_unit = MAP_REGIONAL_HEIGHT_METERS_PER_UNIT;
    map->tile_x = tile_x;
    map->tile_y = tile_y;
    for (y = 0; y < MAP_HEIGHT; ++y) {
        global_y = tile_y * (long)MAP_HEIGHT + (long)y;
        for (x = 0; x < MAP_WIDTH; ++x) {
            global_x = tile_x * (long)MAP_WIDTH + (long)x;
            /* This samples one-cell north/south/east/west halos from global
             * coordinates, including the adjacent regional tiles. */
            sum = regional_raw_height(globe, global_x, global_y, &world_cell) * 4U;
            sum += regional_raw_height(globe, global_x - 1L, global_y, 0);
            sum += regional_raw_height(globe, global_x + 1L, global_y, 0);
            sum += regional_raw_height(globe, global_x, global_y - 1L, 0);
            sum += regional_raw_height(globe, global_x, global_y + 1L, 0);
            height = sum >> 3;
            map->cells[y * MAP_WIDTH + x] =
                MAKE_CELL(height, regional_ground(height, world_cell));
        }
    }
    return 1;
}

unsigned int MapSampleRegionalHeight(const WorldGlobe *globe,
                                     long world_x_km, long world_y_km,
                                     unsigned char *world_cell)
{
    long base_x;
    long base_y;
    long fraction_x;
    long fraction_y;
    unsigned int northwest;
    unsigned int northeast;
    unsigned int southwest;
    unsigned int southeast;
    unsigned int north;
    unsigned int south;
    unsigned char cell;

    if (globe == 0)
        return 0;
    base_x = regional_floor_divide(world_x_km, 5L);
    base_y = regional_floor_divide(world_y_km, 5L);
    fraction_x = regional_modulo(world_x_km, 5L);
    fraction_y = regional_modulo(world_y_km, 5L);
    northwest = regional_raw_height(globe, base_x, base_y, &cell);
    northeast = regional_raw_height(globe, base_x + 1L, base_y, 0);
    southwest = regional_raw_height(globe, base_x, base_y + 1L, 0);
    southeast = regional_raw_height(globe, base_x + 1L, base_y + 1L, 0);
    north = (northwest * (unsigned int)(5L - fraction_x) +
             northeast * (unsigned int)fraction_x + 2U) / 5U;
    south = (southwest * (unsigned int)(5L - fraction_x) +
             southeast * (unsigned int)fraction_x + 2U) / 5U;
    if (world_cell != 0)
        *world_cell = cell;
    return (north * (unsigned int)(5L - fraction_y) +
            south * (unsigned int)fraction_y + 2U) / 5U;
}
