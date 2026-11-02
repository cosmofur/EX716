#include "localmap.h"
#include "regionalmap.h"

static long local_floor_divide(long value, long divisor)
{
    if (value >= 0L) return value / divisor;
    return -(((-value) + divisor - 1L) / divisor);
}

static unsigned long local_hash(unsigned long seed, unsigned long domain,
                                long x, long y)
{
    unsigned long value;

    value = (seed ^ domain) * 16777619UL;
    value ^= (unsigned long)x * 2246822519UL;
    value ^= (unsigned long)y * 3266489917UL;
    value ^= value >> 13;
    return value & 0xffffffffUL;
}

static int local_abs(int value)
{
    return value < 0 ? -value : value;
}

static int local_distance(long x, long y, long center_x, long center_y)
{
    int dx;
    int dy;
    int minor;

    dx = local_abs((int)(x - center_x));
    dy = local_abs((int)(y - center_y));
    minor = dx < dy ? dx : dy;
    return (dx > dy ? dx : dy) + minor / 2;
}

static int local_valid_scale(unsigned short scale)
{
    return scale == MAP_LOCAL_CELL_HALF_METERS_10M ||
           scale == MAP_LOCAL_CELL_HALF_METERS_5M ||
           scale == MAP_LOCAL_CELL_HALF_METERS_2M ||
           scale == MAP_LOCAL_CELL_HALF_METERS_1M ||
           scale == MAP_LOCAL_CELL_HALF_METERS_0_5M;
}

static void local_add_feature(MapFeatureList *features, unsigned int index,
                              unsigned int type, unsigned int radius,
                              unsigned long id)
{
    MapFeature *feature;
    unsigned int existing;

    if (features == 0 || features->items == 0 ||
        features->count >= features->capacity) return;
    for (existing = 0; existing < features->count; ++existing)
        if (features->items[existing].type == type &&
            features->items[existing].feature_id == id) return;
    feature = &features->items[features->count++];
    feature->cell_index = (unsigned short)index;
    feature->type = (unsigned short)type;
    feature->radius_meters = (unsigned short)radius;
    feature->variant = 0U;
    feature->feature_id = id;
}

/* A globally evaluated detail field gives neighboring local maps identical
 * border samples.  Coordinates are in half metres throughout. */
static int local_detail(const WorldGlobe *globe, long x, long y)
{
    long macro_x;
    long macro_y;
    long fraction_x;
    long fraction_y;
    long inverse_x;
    long inverse_y;
    long lower;
    long upper;
    long value;

    macro_x = local_floor_divide(x, 800L);
    macro_y = local_floor_divide(y, 800L);
    fraction_x = x - macro_x * 800L;
    fraction_y = y - macro_y * 800L;
    inverse_x = 800L - fraction_x;
    inverse_y = 800L - fraction_y;
    lower = (long)(local_hash(globe->seed, 0x4c4f4341UL, macro_x, macro_y) %
                   91UL) * inverse_x +
            (long)(local_hash(globe->seed, 0x4c4f4341UL, macro_x + 1L, macro_y) %
                   91UL) * fraction_x;
    upper = (long)(local_hash(globe->seed, 0x4c4f4341UL, macro_x, macro_y + 1L) %
                   91UL) * inverse_x +
            (long)(local_hash(globe->seed, 0x4c4f4341UL, macro_x + 1L,
                              macro_y + 1L) % 91UL) * fraction_x;
    value = (lower * inverse_y + upper * fraction_y) / 640000L;
    return (int)value - 45;
}

int MapGenerateLocalMap(Map *map, const WorldGlobe *globe,
                        long origin_x_half_meters,
                        long origin_y_half_meters,
                        unsigned short cell_half_meters,
                        unsigned short profile, MapFeatureList *features)
{
    unsigned int x;
    unsigned int y;
    unsigned int index;
    long physical_x;
    long physical_y;
    long kilometre_x;
    long kilometre_y;
    unsigned int base_height;
    unsigned int meters;
    unsigned int height;
    unsigned int terrain;
    unsigned long marker;
    long macro_x;
    long macro_y;
    long center_x;
    long center_y;
    int distance;
    int pond;
    int grove;
    int rocks;
    int route;
    int building;

    if (map == 0 || globe == 0 || globe->cells == 0 ||
        !local_valid_scale(cell_half_meters) ||
        profile < MAP_LOCAL_PROFILE_WILDERNESS_SITE ||
        profile > MAP_LOCAL_PROFILE_SIMULATION ||
        (features != 0 && features->capacity != 0U && features->items == 0))
        return 0;
    if (!MapInitialize(map, globe->seed, MAP_TYPE_LOCAL)) return 0;
    map->half_meters_per_cell = cell_half_meters;
    map->meters_per_cell = cell_half_meters / 2U;
    map->meters_per_height_unit = 1U;
    map->origin_x_half_meters = origin_x_half_meters;
    map->origin_y_half_meters = origin_y_half_meters;
    map->tile_x = local_floor_divide(origin_x_half_meters,
                                     (long)cell_half_meters * MAP_WIDTH);
    map->tile_y = local_floor_divide(origin_y_half_meters,
                                     (long)cell_half_meters * MAP_HEIGHT);
    kilometre_x = local_floor_divide(origin_x_half_meters +
                                     (long)cell_half_meters * (MAP_WIDTH / 2U),
                                     2000L);
    kilometre_y = local_floor_divide(origin_y_half_meters +
                                     (long)cell_half_meters * (MAP_HEIGHT / 2U),
                                     2000L);
    base_height = MapSampleRegionalHeight(globe, kilometre_x, kilometre_y, 0) *
                  MAP_REGIONAL_HEIGHT_METERS_PER_UNIT;
    map->elevation_datum_meters = (long)base_height - 127L;
    if (features != 0) features->count = 0U;
    for (y = 0U; y < MAP_HEIGHT; ++y) {
        physical_y = origin_y_half_meters + (long)y * cell_half_meters;
        for (x = 0U; x < MAP_WIDTH; ++x) {
            physical_x = origin_x_half_meters + (long)x * cell_half_meters;
            index = y * MAP_WIDTH + x;
            kilometre_x = local_floor_divide(physical_x, 2000L);
            kilometre_y = local_floor_divide(physical_y, 2000L);
            base_height = MapSampleRegionalHeight(globe, kilometre_x,
                                                   kilometre_y, 0) *
                          MAP_REGIONAL_HEIGHT_METERS_PER_UNIT;
            meters = base_height + local_detail(globe, physical_x, physical_y);
            if ((long)meters <= map->elevation_datum_meters) height = 0U;
            else height = (unsigned int)((long)meters - map->elevation_datum_meters);
            if (height > 255U) height = 255U;
            terrain = meters < 780U ? TERRAIN_WATER : TERRAIN_GRASS;
            macro_x = local_floor_divide(physical_x, 1400L);
            macro_y = local_floor_divide(physical_y, 1400L);
            marker = local_hash(globe->seed, 0x504f4e44UL, macro_x, macro_y);
            center_x = macro_x * 1400L + (long)(marker % 1400UL);
            center_y = macro_y * 1400L + (long)((marker >> 12) % 1400UL);
            distance = local_distance(physical_x, physical_y, center_x, center_y);
            pond = (marker & 15UL) == 0UL && distance < 110;
            marker = local_hash(globe->seed, 0x47524f56UL, macro_x, macro_y);
            center_x = macro_x * 1400L + (long)(marker % 1400UL);
            center_y = macro_y * 1400L + (long)((marker >> 12) % 1400UL);
            distance = local_distance(physical_x, physical_y, center_x, center_y);
            grove = (marker & 7UL) < 3UL && distance < 260;
            rocks = meters > 3600U || ((marker >> 24) & 31UL) == 0UL;
            route = local_abs((int)(physical_y - (macro_y * 1400L + 700L))) <
                    (int)cell_half_meters;
            building = profile == MAP_LOCAL_PROFILE_SETTLEMENT &&
                       physical_x % 900L > 150L && physical_x % 900L < 650L &&
                       physical_y % 900L > 150L && physical_y % 900L < 650L;
            if (pond) terrain = TERRAIN_WATER;
            else if (building) terrain = TERRAIN_BUILDING;
            else if (route) terrain = TERRAIN_PAVEMENT | FEATURE_ROAD;
            else if (rocks) terrain = TERRAIN_ROCK;
            else if (grove && terrain == TERRAIN_GRASS) terrain |= FEATURE_FOREST;
            map->cells[index] = MAKE_CELL(height, terrain);
            if (pond) local_add_feature(features, index, MAP_FEATURE_POND, 55U,
                                        local_hash(globe->seed, 0x504f4e44UL,
                                                   macro_x, macro_y));
            if (grove) local_add_feature(features, index, MAP_FEATURE_GROVE, 130U,
                                         local_hash(globe->seed, 0x47524f56UL,
                                                    macro_x, macro_y));
            if (rocks) local_add_feature(features, index, MAP_FEATURE_ROCK_FIELD,
                                         80U, local_hash(globe->seed, 0x524f434bUL,
                                                          macro_x, macro_y));
            if (route) local_add_feature(features, index, MAP_FEATURE_ROUTE, 10U,
                                         local_hash(globe->seed, 0x524f5554UL,
                                                    macro_x, macro_y));
            if (building) local_add_feature(features, index, MAP_FEATURE_BUILDING,
                                            120U, local_hash(globe->seed, 0x4255494cUL,
                                                             macro_x, macro_y));
        }
    }
    return 1;
}
