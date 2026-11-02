#include "worldmap.h"
#include "regionalmap.h"

static long worldmap_floor_divide(long value, long divisor)
{
    if (value >= 0)
        return value / divisor;
    return -(((-value) + divisor - 1) / divisor);
}

static unsigned long worldmap_hash(unsigned long seed, unsigned long domain,
                                   long x, long y)
{
    unsigned long value;

    value = (seed ^ domain) * 16777619UL;
    value ^= (unsigned long)x * 2246822519UL;
    value ^= (unsigned long)y * 3266489917UL;
    value ^= value >> 13;
    return value & 0xffffffffUL;
}

static int worldmap_abs(int value)
{
    return value < 0 ? -value : value;
}

/* A cheap rounded distance avoids the conspicuous diamond outlines produced
 * by Manhattan distance while staying in the integer-only C89 subset. */
static int worldmap_distance(long first_x, long first_y,
                             long second_x, long second_y)
{
    int x_distance;
    int y_distance;
    int minor;

    x_distance = worldmap_abs((int)(first_x - second_x));
    y_distance = worldmap_abs((int)(first_y - second_y));
    minor = x_distance < y_distance ? x_distance : y_distance;
    return (x_distance > y_distance ? x_distance : y_distance) + minor / 2;
}

static unsigned int worldmap_hill_detail(const WorldGlobe *globe,
                                         long world_x, long world_y)
{
    long macro_x;
    long macro_y;
    long candidate_x;
    long candidate_y;
    int x_offset;
    int y_offset;
    int distance;
    int radius;
    int height;
    int detail;
    unsigned int core;
    unsigned int core_count;
    unsigned long structure_hash;
    unsigned long core_hash;

    macro_x = worldmap_floor_divide(world_x, 16L);
    macro_y = worldmap_floor_divide(world_y, 16L);
    detail = 0;
    for (y_offset = -1; y_offset <= 1; ++y_offset) {
        for (x_offset = -1; x_offset <= 1; ++x_offset) {
            structure_hash = worldmap_hash(globe->seed, 0x48494c4cUL,
                                           macro_x + x_offset, macro_y + y_offset);
            core_count = 2U + (unsigned int)(structure_hash % 3UL);
            for (core = 0; core < core_count; ++core) {
                core_hash = worldmap_hash(globe->seed, 0x48494c50UL + core,
                                          macro_x + x_offset, macro_y + y_offset);
                candidate_x = (macro_x + x_offset) * 16L +
                              (long)(core_hash & 15UL);
                candidate_y = (macro_y + y_offset) * 16L +
                              (long)((core_hash >> 4) & 15UL);
                radius = 3 + (int)((core_hash >> 8) % 5UL);
                height = 16 + (int)((core_hash >> 12) % 49UL);
                distance = worldmap_distance(world_x, world_y,
                                             candidate_x, candidate_y);
                if (distance < radius)
                    detail += height * (radius - distance) / radius;
            }
        }
    }
    return (unsigned int)detail;
}

static unsigned int worldmap_hill_center(const WorldGlobe *globe,
                                         long world_x, long world_y,
                                         unsigned long *feature_id)
{
    long macro_x;
    long macro_y;
    unsigned long hash;
    unsigned long core_hash;
    long center_x;
    long center_y;
    unsigned int core;
    unsigned int core_count;

    macro_x = worldmap_floor_divide(world_x, 16L);
    macro_y = worldmap_floor_divide(world_y, 16L);
    hash = worldmap_hash(globe->seed, 0x48494c4cUL, macro_x, macro_y);
    core_count = 2U + (unsigned int)(hash % 3UL);
    for (core = 0; core < core_count; ++core) {
        core_hash = worldmap_hash(globe->seed, 0x48494c50UL + core,
                                  macro_x, macro_y);
        center_x = macro_x * 16L + (long)(core_hash & 15UL);
        center_y = macro_y * 16L + (long)((core_hash >> 4) & 15UL);
        if (world_x == center_x && world_y == center_y) {
            if (feature_id != 0)
                *feature_id = hash;
            return 3U + (unsigned int)((core_hash >> 8) % 5UL);
        }
    }
    return 0;
}

static unsigned int worldmap_pond_radius(const WorldGlobe *globe,
                                         long world_x, long world_y,
                                         unsigned char world_cell,
                                         unsigned long *feature_id)
{
    long macro_x;
    long macro_y;
    long candidate_x;
    long candidate_y;
    int x_offset;
    int y_offset;
    int distance;
    int radius;
    unsigned int core;
    unsigned int core_count;
    unsigned long structure_hash;
    unsigned long core_hash;

    if (((world_cell & WORLD_MOISTURE_MASK) >> WORLD_MOISTURE_SHIFT) < 2U)
        return 0;
    macro_x = worldmap_floor_divide(world_x, 12L);
    macro_y = worldmap_floor_divide(world_y, 12L);
    for (y_offset = -1; y_offset <= 1; ++y_offset) {
        for (x_offset = -1; x_offset <= 1; ++x_offset) {
            structure_hash = worldmap_hash(globe->seed, 0x504f4e44UL,
                                           macro_x + x_offset, macro_y + y_offset);
            if ((structure_hash & 7UL) != 0UL)
                continue;
            core_count = 2U + (unsigned int)((structure_hash >> 3) % 3UL);
            for (core = 0; core < core_count; ++core) {
                core_hash = worldmap_hash(globe->seed, 0x504f4e50UL + core,
                                          macro_x + x_offset, macro_y + y_offset);
                candidate_x = (macro_x + x_offset) * 12L +
                              (long)(core_hash % 12UL);
                candidate_y = (macro_y + y_offset) * 12L +
                              (long)((core_hash >> 4) % 12UL);
                radius = 1 + (int)((core_hash >> 8) % 3UL);
                distance = worldmap_distance(world_x, world_y,
                                             candidate_x, candidate_y);
                if (distance <= radius) {
                    if (feature_id != 0)
                        *feature_id = structure_hash;
                    return (unsigned int)radius;
                }
            }
        }
    }
    return 0;
}

static unsigned int worldmap_grove_radius(const WorldGlobe *globe,
                                          long world_x, long world_y,
                                          unsigned char world_cell,
                                          unsigned long *feature_id)
{
    long macro_x;
    long macro_y;
    long candidate_x;
    long candidate_y;
    int x_offset;
    int y_offset;
    int distance;
    int radius;
    unsigned int core;
    unsigned int core_count;
    unsigned long structure_hash;
    unsigned long core_hash;

    if (((world_cell & WORLD_MOISTURE_MASK) >> WORLD_MOISTURE_SHIFT) < 1U)
        return 0;
    macro_x = worldmap_floor_divide(world_x, 10L);
    macro_y = worldmap_floor_divide(world_y, 10L);
    for (y_offset = -1; y_offset <= 1; ++y_offset) {
        for (x_offset = -1; x_offset <= 1; ++x_offset) {
            structure_hash = worldmap_hash(globe->seed, 0x47524f56UL,
                                           macro_x + x_offset, macro_y + y_offset);
            if ((structure_hash & 7UL) != 0UL)
                continue;
            core_count = 2U + (unsigned int)((structure_hash >> 3) % 3UL);
            for (core = 0; core < core_count; ++core) {
                core_hash = worldmap_hash(globe->seed, 0x47524f50UL + core,
                                          macro_x + x_offset, macro_y + y_offset);
                candidate_x = (macro_x + x_offset) * 10L +
                              (long)(core_hash % 10UL);
                candidate_y = (macro_y + y_offset) * 10L +
                              (long)((core_hash >> 4) % 10UL);
                radius = 2 + (int)((core_hash >> 8) % 4UL);
                distance = worldmap_distance(world_x, world_y,
                                             candidate_x, candidate_y);
                if (distance <= radius) {
                    if (feature_id != 0)
                        *feature_id = structure_hash;
                    return (unsigned int)radius;
                }
            }
        }
    }
    return 0;
}

static void worldmap_add_feature(MapFeatureList *features, unsigned int index,
                                 unsigned int type, unsigned int radius,
                                 unsigned long id)
{
    MapFeature *feature;
    unsigned int existing;

    if (features == 0 || features->items == 0 ||
        features->count >= features->capacity)
        return;
    for (existing = 0; existing < features->count; ++existing)
        if (features->items[existing].type == type &&
            features->items[existing].feature_id == id)
            return;
    feature = &features->items[features->count++];
    feature->cell_index = (unsigned short)index;
    feature->type = (unsigned short)type;
    feature->radius_meters = (unsigned short)(radius * 1000U);
    feature->variant = 0;
    feature->feature_id = id;
}

static unsigned int worldmap_raw_height(const WorldGlobe *globe,
                                        long world_x, long world_y,
                                        unsigned char *world_cell,
                                        unsigned int *pond_radius)
{
    unsigned int regional_height;
    unsigned int height;
    unsigned int pond;
    unsigned char cell;

    regional_height = MapSampleRegionalHeight(globe, world_x, world_y, &cell);
    height = regional_height * MAP_REGIONAL_HEIGHT_METERS_PER_UNIT;
    height += worldmap_hill_detail(globe, world_x, world_y);
    pond = worldmap_pond_radius(globe, world_x, world_y, cell, 0);
    if (pond != 0U && height > pond * 25U)
        height -= pond * 25U;
    if (world_cell != 0)
        *world_cell = cell;
    if (pond_radius != 0)
        *pond_radius = pond;
    return height;
}

int MapGenerateWorldTile(Map *map, const WorldGlobe *globe,
                         long tile_x, long tile_y, MapFeatureList *features)
{
    unsigned int x;
    unsigned int y;
    unsigned int index;
    long global_x;
    long global_y;
    long center_x;
    long center_y;
    unsigned int datum_height;
    unsigned int sum;
    unsigned int meters;
    unsigned int height;
    unsigned int pond;
    unsigned int grove;
    unsigned char world_cell;
    unsigned long feature_id;
    unsigned int terrain;

    if (map == 0 || globe == 0 || globe->cells == 0 || globe->cell_count == 0 ||
        (features != 0 && features->capacity != 0 && features->items == 0))
        return 0;
    if (!MapInitialize(map, globe->seed, MAP_TYPE_WORLD_TILE))
        return 0;
    map->meters_per_cell = MAP_WORLD_METERS_PER_CELL;
    map->meters_per_height_unit = MAP_WORLD_HEIGHT_METERS_PER_UNIT;
    map->tile_x = tile_x;
    map->tile_y = tile_y;
    if (features != 0)
        features->count = 0;
    center_x = tile_x * (long)MAP_WIDTH + (long)(MAP_WIDTH / 2U);
    center_y = tile_y * (long)MAP_HEIGHT + (long)(MAP_HEIGHT / 2U);
    datum_height = worldmap_raw_height(globe, center_x, center_y, 0, 0);
    map->elevation_datum_meters = (long)datum_height - 640L;
    for (y = 0; y < MAP_HEIGHT; ++y) {
        global_y = tile_y * (long)MAP_HEIGHT + (long)y;
        for (x = 0; x < MAP_WIDTH; ++x) {
            global_x = tile_x * (long)MAP_WIDTH + (long)x;
            index = y * MAP_WIDTH + x;
            sum = worldmap_raw_height(globe, global_x, global_y, &world_cell,
                                      &pond) * 4U;
            sum += worldmap_raw_height(globe, global_x - 1L, global_y, 0, 0) * 2U;
            sum += worldmap_raw_height(globe, global_x + 1L, global_y, 0, 0) * 2U;
            sum += worldmap_raw_height(globe, global_x, global_y - 1L, 0, 0) * 2U;
            sum += worldmap_raw_height(globe, global_x, global_y + 1L, 0, 0) * 2U;
            sum += worldmap_raw_height(globe, global_x - 1L, global_y - 1L, 0, 0);
            sum += worldmap_raw_height(globe, global_x + 1L, global_y - 1L, 0, 0);
            sum += worldmap_raw_height(globe, global_x - 1L, global_y + 1L, 0, 0);
            sum += worldmap_raw_height(globe, global_x + 1L, global_y + 1L, 0, 0);
            meters = sum >> 4;
            if ((long)meters <= map->elevation_datum_meters)
                height = 0;
            else
                height = (unsigned int)(((long)meters -
                         map->elevation_datum_meters) /
                         MAP_WORLD_HEIGHT_METERS_PER_UNIT);
            if (height > 255U)
                height = 255U;
            /* Terrain class must use the globally sampled elevation, never
             * this tile's local byte/datum.  Adjacent tiles may legitimately
             * choose different display datums, but their coast/rock/snow
             * boundary must still be the same physical boundary. */
            terrain = TERRAIN_GRASS;
            if (pond != 0U || meters <= 750U)
                terrain = TERRAIN_WATER;
            else if (meters >= 5600U)
                terrain = TERRAIN_SNOW;
            else if (meters >= 4000U)
                terrain = TERRAIN_ROCK;
            else if (((world_cell & WORLD_MOISTURE_MASK) >>
                      WORLD_MOISTURE_SHIFT) == 0U)
                terrain = TERRAIN_DIRT;
            feature_id = 0;
            grove = worldmap_grove_radius(globe, global_x, global_y,
                                          world_cell, &feature_id);
            if (grove != 0U && terrain == TERRAIN_GRASS)
                terrain |= FEATURE_FOREST;
            map->cells[index] = MAKE_CELL(height, terrain);
            if (pond != 0U && worldmap_pond_radius(globe, global_x, global_y,
                                                    world_cell, &feature_id) != 0U)
                worldmap_add_feature(features, index, MAP_FEATURE_POND, pond,
                                     feature_id);
            if (grove != 0U)
                worldmap_add_feature(features, index, MAP_FEATURE_GROVE, grove,
                                     feature_id);
            grove = worldmap_hill_center(globe, global_x, global_y, &feature_id);
            if (grove != 0U)
                worldmap_add_feature(features, index, MAP_FEATURE_HILL, grove,
                                     feature_id);
        }
    }
    return 1;
}
