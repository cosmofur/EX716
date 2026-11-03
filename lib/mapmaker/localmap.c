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
    return scale == MAP_LOCAL_CELL_HALF_METERS_5KM ||
           scale == MAP_LOCAL_CELL_HALF_METERS_1KM ||
           scale == MAP_LOCAL_CELL_HALF_METERS_500M ||
           scale == MAP_LOCAL_CELL_HALF_METERS_100M ||
           scale == MAP_LOCAL_CELL_HALF_METERS_50M ||
           scale == MAP_LOCAL_CELL_HALF_METERS_20M ||
           scale == MAP_LOCAL_CELL_HALF_METERS_10M ||
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

/* These fields are evaluated in global coordinates.  Unlike a single stamped
 * circle per macro cell, several overlapping, irregular cores make a feature
 * grow, meet its neighbours and then soften back into the underlying terrain.
 * This keeps local-map borders exact without making the landscape look tiled. */
static int local_feature_strength(const WorldGlobe *globe, unsigned long domain,
                                  long x, long y, long span, int chance,
                                  int base_radius)
{
    long macro_x;
    long macro_y;
    long center_x;
    long center_y;
    unsigned long structure;
    unsigned long core_hash;
    int offset_x;
    int offset_y;
    unsigned int core;
    unsigned int cores;
    int distance;
    int radius;
    int strength;
    int best;

    macro_x = local_floor_divide(x, span);
    macro_y = local_floor_divide(y, span);
    best = 0;
    for (offset_y = -1; offset_y <= 1; ++offset_y) {
        for (offset_x = -1; offset_x <= 1; ++offset_x) {
            structure = local_hash(globe->seed, domain, macro_x + offset_x,
                                   macro_y + offset_y);
            if ((int)(structure & 31UL) >= chance)
                continue;
            cores = 2U + (unsigned int)((structure >> 5) % 3UL);
            for (core = 0U; core < cores; ++core) {
                core_hash = local_hash(globe->seed, domain + 0x31UL + core,
                                       macro_x + offset_x, macro_y + offset_y);
                center_x = (macro_x + offset_x) * span +
                           (long)(core_hash % (unsigned long)span);
                center_y = (macro_y + offset_y) * span +
                           (long)((core_hash >> 12) % (unsigned long)span);
                radius = base_radius + (int)((core_hash >> 20) %
                                              (unsigned long)(base_radius + 1));
                distance = local_distance(x, y, center_x, center_y);
                /* A little high-frequency displacement erodes the otherwise
                 * perfectly round core outline. */
                distance -= (int)(local_hash(globe->seed, domain + 0x71UL,
                                              x / 80L, y / 80L) % 61UL) - 30;
                strength = radius - distance;
                if (strength > best)
                    best = strength;
            }
        }
    }
    return best;
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
    unsigned char world_cell;
    int pond_strength;
    int grove_strength;
    int rock_strength;
    int settlement_strength;
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
                                                   kilometre_y, &world_cell) *
                          MAP_REGIONAL_HEIGHT_METERS_PER_UNIT;
            /* Layer broad relief with two progressively smaller fields.  The
             * latter terms are deliberately weaker: they weather contours
             * without turning a regional slope into visual static. */
            meters = base_height + local_detail(globe, physical_x, physical_y) +
                     local_detail(globe, physical_x / 3L, physical_y / 3L) / 3 +
                     local_detail(globe, physical_x / 9L, physical_y / 9L) / 6;
            if ((long)meters <= map->elevation_datum_meters) height = 0U;
            else height = (unsigned int)((long)meters - map->elevation_datum_meters);
            if (height > 255U) height = 255U;
            /* Sea is a persistent globe landform, not an arbitrary local
             * height threshold.  The latter made low coastal land disappear
             * as a player changed seed or zoom level. */
            if (cell_half_meters >= MAP_LOCAL_CELL_HALF_METERS_500M)
                terrain = base_height <= 750U ? TERRAIN_WATER : TERRAIN_GRASS;
            else
                terrain = (world_cell & WORLD_LANDFORM_MASK) <= WORLD_SHALLOW_SEA ?
                          TERRAIN_WATER : TERRAIN_GRASS;
            if (cell_half_meters < MAP_LOCAL_CELL_HALF_METERS_500M) {
                pond_strength = local_feature_strength(globe, 0x504f4e44UL,
                                                      physical_x, physical_y,
                                                      2800L, 3, 95);
                grove_strength = local_feature_strength(globe, 0x47524f56UL,
                                                       physical_x, physical_y,
                                                       3400L, 4, 110);
                rock_strength = local_feature_strength(globe, 0x524f434bUL,
                                                      physical_x, physical_y,
                                                      3000L, 6, 120);
            } else {
                pond_strength = 0;
                grove_strength = 0;
                rock_strength = 0;
            }
            settlement_strength = local_feature_strength(globe, 0x53495445UL,
                                                        physical_x, physical_y,
                                                        4800L, 32, 450);
            /* Surface features belong to land.  Applying the old stamp
             * fields indiscriminately was what made small "ponds" appear in
             * open sea. */
            pond = pond_strength > 0 && meters >= 850U && meters < 3000U;
            grove = grove_strength > 0 && meters >= 850U && meters < 3000U;
            rocks = meters > 3600U || rock_strength > 0;
            /* The old unconditional horizontal route and 900 m building grid
             * made ordinary wilderness visibly artificial.  Settlements now
             * grow as sparse, irregular clusters around globally stable sites. */
            route = profile == MAP_LOCAL_PROFILE_SETTLEMENT &&
                    local_abs((int)(physical_y - 300L -
                    (long)local_detail(globe, physical_x / 5L, 0L) * 3L)) <
                    (int)cell_half_meters;
            building = profile == MAP_LOCAL_PROFILE_SETTLEMENT &&
                       settlement_strength > 0 &&
                       (local_hash(globe->seed, 0x4255494cUL,
                                   physical_x / 80L, physical_y / 80L) & 7UL) < 3UL;
            if (pond) terrain = TERRAIN_WATER;
            else if (building) terrain = TERRAIN_BUILDING;
            else if (route) terrain = TERRAIN_PAVEMENT | FEATURE_ROAD;
            else if (rocks) terrain = TERRAIN_ROCK;
            else if (grove && terrain == TERRAIN_GRASS) terrain |= FEATURE_FOREST;
            map->cells[index] = MAKE_CELL(height, terrain);
            if (pond) local_add_feature(features, index, MAP_FEATURE_POND, 55U,
                                        local_hash(globe->seed, 0x504f4e44UL,
                                                   physical_x / 2800L,
                                                   physical_y / 2800L));
            if (grove) local_add_feature(features, index, MAP_FEATURE_GROVE, 130U,
                                         local_hash(globe->seed, 0x47524f56UL,
                                                    physical_x / 3400L,
                                                    physical_y / 3400L));
            if (rocks) local_add_feature(features, index, MAP_FEATURE_ROCK_FIELD,
                                         80U, local_hash(globe->seed, 0x524f434bUL,
                                                          physical_x / 3000L,
                                                          physical_y / 3000L));
            if (route) local_add_feature(features, index, MAP_FEATURE_ROUTE, 10U,
                                         local_hash(globe->seed, 0x524f5554UL,
                                                    physical_x / 4800L,
                                                    physical_y / 4800L));
            if (building) local_add_feature(features, index, MAP_FEATURE_BUILDING,
                                            120U, local_hash(globe->seed, 0x4255494cUL,
                                                             physical_x / 4800L,
                                                             physical_y / 4800L));
        }
    }
    return 1;
}
