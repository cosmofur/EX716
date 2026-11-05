#include "worldgen.h"
#include "mapmath.h"

#define WORLDGEN_CONTOUR_DOMAIN 0x434f4e54UL

static unsigned long worldgen_hash(unsigned long seed, unsigned long domain,
                                   long x, long y)
{
    unsigned long value;

    value = seed ^ domain;
    value ^= (unsigned long)x * 2246822519UL;
    value ^= (unsigned long)y * 3266489917UL;
    value ^= value >> 13;
    value *= 1274126177UL;
    return value ^ (value >> 16);
}

static int worldgen_abs(int value)
{
    return value < 0 ? -value : value;
}

static int worldgen_clamp(int value, int low, int high)
{
    if (value < low) return low;
    if (value > high) return high;
    return value;
}

static long worldgen_floor_divide(long value, long divisor)
{
    if (value >= 0L) return value / divisor;
    return -(((-value) + divisor - 1L) / divisor);
}

static int worldgen_octile(long first_x, long first_y, long second_x,
                           long second_y)
{
    int x_distance;
    int y_distance;
    int smaller;

    x_distance = worldgen_abs((int)(first_x - second_x));
    y_distance = worldgen_abs((int)(first_y - second_y));
    smaller = x_distance < y_distance ? x_distance : y_distance;
    return (x_distance > y_distance ? x_distance : y_distance) + smaller / 2;
}

static int worldgen_noise(unsigned long seed, unsigned long domain,
                          long x, long y)
{
    return (int)((worldgen_hash(seed, domain, x, y) >> 24) & 255UL) - 128;
}

static int worldgen_smooth_noise(unsigned long seed, unsigned long domain,
                                 long x, long y, unsigned int period)
{
    long cell_x;
    long cell_y;
    unsigned int fraction_x;
    unsigned int fraction_y;
    int top;
    int bottom;
    int first;
    int second;

    cell_x = x / (long)period;
    cell_y = y / (long)period;
    if (x < 0 && x % (long)period != 0) --cell_x;
    if (y < 0 && y % (long)period != 0) --cell_y;
    fraction_x = (unsigned int)(x - cell_x * (long)period);
    fraction_y = (unsigned int)(y - cell_y * (long)period);
    first = worldgen_noise(seed, domain, cell_x, cell_y);
    second = worldgen_noise(seed, domain, cell_x + 1L, cell_y);
    top = (first * (int)(period - fraction_x) + second * (int)fraction_x) /
          (int)period;
    first = worldgen_noise(seed, domain, cell_x, cell_y + 1L);
    second = worldgen_noise(seed, domain, cell_x + 1L, cell_y + 1L);
    bottom = (first * (int)(period - fraction_x) + second * (int)fraction_x) /
             (int)period;
    return (top * (int)(period - fraction_y) + bottom * (int)fraction_y) /
           (int)period;
}

int WorldGenIrregularField(unsigned long seed, unsigned long domain,
                           long x, long y, long center_x, long center_y,
                           unsigned int radius, unsigned int aspect_percent)
{
    long adjusted_x;
    int distance;
    int edge;

    if (radius == 0U || aspect_percent == 0U)
        return -32767;
    adjusted_x = ((x - center_x) * 100L) / (long)aspect_percent + center_x;
    distance = worldgen_octile(adjusted_x, y, center_x, center_y);
    edge = worldgen_smooth_noise(seed, domain, x, y, radius / 3U + 3U) / 8;
    edge += worldgen_smooth_noise(seed, domain + 1UL, x, y,
                                  radius / 7U + 2U) / 20;
    return (int)radius - distance + edge;
}

static unsigned int worldgen_index(const WorldGenGlobe *globe,
                                   unsigned int row, unsigned int column)
{
    return (unsigned int)(globe->row_start[row] +
                          column % globe->row_width[row]);
}

static int worldgen_longitude_delta(unsigned int first, unsigned int second)
{
    int difference;

    difference = (int)first - (int)second;
    if (difference > 127) difference -= 256;
    if (difference < -128) difference += 256;
    return difference;
}

static int worldgen_globe_distance(unsigned int row, unsigned int longitude,
                                   unsigned int other_row,
                                   unsigned int other_longitude)
{
    int north_south;
    int east_west;
    int cosine;
    int angle;

    north_south = worldgen_abs((int)row - (int)other_row) * 4;
    east_west = worldgen_abs(worldgen_longitude_delta(longitude,
                                                       other_longitude));
    angle = worldgen_abs((int)row * 2 - 63);
    cosine = MapMathCos((unsigned int)(angle * 64 / 63));
    east_west = east_west * cosine / MAPMATH_TRIG_SCALE;
    return north_south + east_west;
}

static void worldgen_continent_center(const WorldGenGlobe *globe,
                                      unsigned int continent,
                                      unsigned int *row,
                                      unsigned int *longitude)
{
    *row = 8U + (unsigned int)(worldgen_hash(globe->seed,
        WORLDGEN_CONTOUR_DOMAIN, (long)continent, 1L) % 48UL);
    *longitude = (unsigned int)(worldgen_hash(globe->seed,
        WORLDGEN_CONTOUR_DOMAIN, (long)continent, 2L) & 255UL);
}

/* The spine is sampled along two joined, hash-wandered segments.  At globe
 * scale that is both cheaper and more controllable-looking than a simulated
 * tectonic boundary, while never becoming a radial mountain stamp. */
static int worldgen_spine_distance(const WorldGenGlobe *globe,
                                   unsigned int row, unsigned int longitude,
                                   unsigned int continent,
                                   unsigned int range)
{
    unsigned long key;
    unsigned int center_row;
    unsigned int center_longitude;
    int cosine;
    int query_x;
    int query_y;
    int point_x[3];
    int point_y[3];
    int segment;
    int step;
    int x;
    int y;
    int distance;
    int nearest;

    worldgen_continent_center(globe, continent, &center_row, &center_longitude);
    cosine = MapMathCos((unsigned int)(worldgen_abs((int)row * 2 - 63) *
                                       64 / 63));
    query_x = worldgen_longitude_delta(longitude, center_longitude) * cosine /
              MAPMATH_TRIG_SCALE;
    query_y = ((int)row - (int)center_row) * 4;
    key = worldgen_hash(globe->seed, 0x52414e47UL + range,
                        (long)continent, 0L);
    point_x[0] = ((int)(key & 63UL) - 31) * cosine / MAPMATH_TRIG_SCALE;
    point_y[0] = ((int)((key >> 6) & 31UL) - 15) * 4;
    point_x[2] = ((int)((key >> 11) & 63UL) - 31) * cosine /
                 MAPMATH_TRIG_SCALE;
    point_y[2] = ((int)((key >> 17) & 31UL) - 15) * 4;
    point_x[1] = (point_x[0] + point_x[2]) / 2 +
                 ((int)((key >> 22) & 31UL) - 15) * cosine /
                 (MAPMATH_TRIG_SCALE * 2);
    point_y[1] = (point_y[0] + point_y[2]) / 2 +
                 ((int)((key >> 27) & 15UL) - 7) * 2;
    nearest = 32767;
    for (segment = 0; segment < 2; ++segment) {
        for (step = 0; step <= 12; ++step) {
            x = (point_x[segment] * (12 - step) +
                 point_x[segment + 1] * step) / 12;
            y = (point_y[segment] * (12 - step) +
                 point_y[segment + 1] * step) / 12;
            distance = worldgen_octile((long)query_x, (long)query_y,
                                       (long)x, (long)y);
            if (distance < nearest) nearest = distance;
        }
    }
    return nearest;
}

int WorldGenMapInitialize(WorldGenMap *map, unsigned long seed,
                          unsigned short profile, unsigned short level,
                          unsigned short meters_per_cell,
                          long origin_x_meters, long origin_y_meters)
{
    unsigned int index;

    if (map == 0 || meters_per_cell == 0U ||
        (profile != WORLDGEN_PROFILE_EARTHLIKE &&
         profile != WORLDGEN_PROFILE_DEAD))
        return 0;
    map->seed = seed;
    map->profile = profile;
    map->level = level;
    map->meters_per_cell = meters_per_cell;
    map->origin_x_meters = origin_x_meters;
    map->origin_y_meters = origin_y_meters;
    for (index = 0U; index < WORLDGEN_MAP_CELLS; ++index)
        map->cells[index] = WORLDGEN_SURFACE_NONE;
    return 1;
}

/* Globe x coordinates wrap every 38,400 km.  A longitude unit is 150 km;
 * active cells are two units wide at the equator and grow narrower in count
 * towards the poles.  World y=0 is the equator. */
static int worldgen_sample_globe(const WorldGenGlobe *globe, long world_x,
                                 long world_y, WorldGenCell *cell)
{
    long row;
    long longitude;
    unsigned int column;

    row = worldgen_floor_divide(world_y, 300000L) + 32L;
    if (row < 0L) row = 0L;
    if (row >= (long)WORLDGEN_GLOBE_ROWS) row = WORLDGEN_GLOBE_ROWS - 1L;
    longitude = worldgen_floor_divide(world_x, 150000L) % 256L;
    if (longitude < 0L) longitude += 256L;
    column = (unsigned int)(longitude * globe->row_width[(unsigned int)row] /
                            256L);
    return WorldGenGlobeGetCell(globe, (unsigned int)row, column, cell);
}

int WorldGenGenerateTile(WorldGenMap *map, const WorldGenGlobe *globe)
{
    unsigned int x;
    unsigned int y;
    unsigned int index;
    long world_x;
    long world_y;
    int parent_height;
    int detail;
    int height;
    unsigned int detail_period;
    WorldGenCell parent;
    WorldGenCell surface;

    if (map == 0 || globe == 0 || globe->cells == 0 ||
        map->seed != globe->seed || map->profile != globe->profile ||
        map->meters_per_cell == 0U)
        return 0;
    detail_period = (unsigned int)((unsigned long)map->meters_per_cell * 9UL +
                                   37UL);
    if (detail_period > 65535U) detail_period = 65535U;
    for (y = 0U; y < WORLDGEN_MAP_HEIGHT; ++y) {
        world_y = map->origin_y_meters +
                  (long)y * (long)map->meters_per_cell;
        for (x = 0U; x < WORLDGEN_MAP_WIDTH; ++x) {
            world_x = map->origin_x_meters +
                      (long)x * (long)map->meters_per_cell;
            if (!worldgen_sample_globe(globe, world_x, world_y, &parent))
                return 0;
            index = y * WORLDGEN_MAP_WIDTH + x;
            surface = parent & WORLDGEN_CELL_SURFACE_MASK;
            parent_height = (int)(parent & WORLDGEN_CELL_VALUE_MASK);
            if (surface == WORLDGEN_SURFACE_OCEAN) {
                map->cells[index] = WORLDGEN_SURFACE_OCEAN;
                continue;
            }
            /* Detail is evaluated from physical coordinates.  It therefore
             * agrees on a shared edge even when adjacent tiles are generated
             * at different times or held by different programs. */
            detail = worldgen_smooth_noise(map->seed, 0x54494c45UL,
                world_x, world_y, detail_period) / 5;
            height = worldgen_clamp(parent_height + detail, 0, 255);
            if (surface == WORLDGEN_SURFACE_MOUNTAIN || height >= 102)
                surface = WORLDGEN_SURFACE_MOUNTAIN;
            else if (surface == WORLDGEN_SURFACE_HIGHLAND || height >= 66)
                surface = WORLDGEN_SURFACE_HIGHLAND;
            else
                surface = WORLDGEN_SURFACE_LAND;
            map->cells[index] = (WorldGenCell)(surface | (unsigned int)height);
        }
    }
    return 1;
}

int WorldGenGlobeInitialize(WorldGenGlobe *globe, WorldGenCell *storage,
                            unsigned short capacity, unsigned long seed,
                            unsigned short profile)
{
    unsigned int row;
    unsigned int polar_angle;
    unsigned int width;

    if (globe == 0 || storage == 0 ||
        (profile != WORLDGEN_PROFILE_EARTHLIKE &&
         profile != WORLDGEN_PROFILE_DEAD))
        return 0;
    globe->row_start[0] = 0U;
    for (row = 0U; row < WORLDGEN_GLOBE_ROWS; ++row) {
        polar_angle = (unsigned int)(worldgen_abs((int)row * 2 - 63) * 64 / 63);
        width = WORLDGEN_GLOBE_POLAR_WIDTH +
                (unsigned int)((96L * MapMathCos(polar_angle) +
                                MAPMATH_TRIG_SCALE / 2) / MAPMATH_TRIG_SCALE);
        if (row == 31U || row == 32U)
            width = WORLDGEN_GLOBE_EQUATOR_WIDTH;
        globe->row_width[row] = (unsigned char)width;
        globe->row_start[row + 1U] =
            (unsigned short)(globe->row_start[row] + width);
    }
    globe->cell_count = globe->row_start[WORLDGEN_GLOBE_ROWS];
    if (capacity < globe->cell_count)
        return 0;
    globe->seed = seed;
    globe->profile = profile;
    globe->sea_level = 0;
    globe->continent_count = 0U;
    globe->cell_capacity = capacity;
    globe->cells = storage;
    return WorldGenGlobeEstablishSeaLevel(globe, 0);
}

int WorldGenGlobeEstablishSeaLevel(WorldGenGlobe *globe, int sea_level)
{
    unsigned int index;

    if (globe == 0 || globe->cells == 0 || globe->cell_count == 0U ||
        globe->cell_count > globe->cell_capacity || sea_level < -32 ||
        sea_level > 32)
        return 0;
    globe->sea_level = sea_level;
    for (index = 0U; index < globe->cell_count; ++index)
        globe->cells[index] = (WorldGenCell)(WORLDGEN_SURFACE_OCEAN | 128U);
    return 1;
}

int WorldGenGlobeGenerateContinents(WorldGenGlobe *globe,
                                    unsigned char continent_count)
{
    unsigned int row;
    unsigned int column;
    unsigned int continent;
    unsigned int longitude;
    unsigned int center_row;
    unsigned int center_longitude;
    unsigned int radius;
    int distance;
    int score;
    int best;
    int value;
    WorldGenCell surface;

    if (globe == 0 || globe->cells == 0 || continent_count == 0U ||
        continent_count > 8U)
        return 0;
    for (row = 0U; row < WORLDGEN_GLOBE_ROWS; ++row) {
        for (column = 0U; column < globe->row_width[row]; ++column) {
            longitude = column * 256U / globe->row_width[row];
            best = -32767;
            for (continent = 0U; continent < continent_count; ++continent) {
                worldgen_continent_center(globe, continent, &center_row,
                                          &center_longitude);
                radius = 26U + (unsigned int)(worldgen_hash(globe->seed,
                    WORLDGEN_CONTOUR_DOMAIN, (long)continent, 3L) % 19UL);
                distance = worldgen_globe_distance(row, longitude, center_row,
                                                   center_longitude);
                score = (int)radius - distance;
                score += worldgen_smooth_noise(globe->seed,
                    WORLDGEN_CONTOUR_DOMAIN + continent * 17UL,
                    (long)longitude, (long)row * 4L, 19U) / 5;
                score += worldgen_smooth_noise(globe->seed,
                    WORLDGEN_CONTOUR_DOMAIN + continent * 17UL + 1UL,
                    (long)longitude, (long)row * 4L, 7U) / 14;
                if (score > best) best = score;
            }
            value = worldgen_clamp(128 + best * 3, 0, 255);
            surface = best >= globe->sea_level ? WORLDGEN_SURFACE_LAND :
                                                 WORLDGEN_SURFACE_OCEAN;
            globe->cells[worldgen_index(globe, row, column)] =
                (WorldGenCell)(surface | (unsigned int)value);
        }
    }
    globe->continent_count = continent_count;
    return 1;
}

int WorldGenGlobeGenerateRelief(WorldGenGlobe *globe)
{
    unsigned int row;
    unsigned int column;
    unsigned int continent;
    unsigned int range;
    unsigned int longitude;
    unsigned int range_count;
    unsigned int width;
    int nearest;
    int uplift;
    int local_uplift;
    int height;
    int base;
    int weathering;
    WorldGenCell cell;
    WorldGenCell surface;

    if (globe == 0 || globe->cells == 0 || globe->continent_count == 0U)
        return 0;
    for (row = 0U; row < WORLDGEN_GLOBE_ROWS; ++row) {
        for (column = 0U; column < globe->row_width[row]; ++column) {
            cell = globe->cells[worldgen_index(globe, row, column)];
            if ((cell & WORLDGEN_CELL_SURFACE_MASK) != WORLDGEN_SURFACE_LAND)
                continue;
            longitude = column * 256U / globe->row_width[row];
            /* The continent-outline value is only a rough distance from the
             * coast.  It becomes a gentle plain before range uplift is added. */
            base = 40 + ((int)(cell & WORLDGEN_CELL_VALUE_MASK) - 128) / 6;
            base = worldgen_clamp(base, 28, 62);
            uplift = 0;
            for (continent = 0U; continent < globe->continent_count;
                 ++continent) {
                range_count = 1U + (unsigned int)(worldgen_hash(globe->seed,
                    0x52414e47UL, (long)continent, 4L) & 1UL);
                for (range = 0U; range < range_count; ++range) {
                    width = 4U + (unsigned int)(worldgen_hash(globe->seed,
                        0x52414e47UL + range, (long)continent, 5L) % 4UL);
                    nearest = worldgen_spine_distance(globe, row, longitude,
                                                       continent, range);
                    if (nearest < (int)(width * 3U)) {
                        local_uplift = ((int)(width * 3U) - nearest) * 3;
                        weathering = worldgen_smooth_noise(globe->seed,
                            0x45524f44UL + range, (long)longitude,
                            (long)row * 4L, 9U) / 5;
                        local_uplift += weathering;
                        if (local_uplift > uplift) uplift = local_uplift;
                    }
                }
            }
            height = worldgen_clamp(base + uplift, 0, 255);
            if (height >= 102)
                surface = WORLDGEN_SURFACE_MOUNTAIN;
            else if (height >= 66)
                surface = WORLDGEN_SURFACE_HIGHLAND;
            else
                surface = WORLDGEN_SURFACE_LAND;
            globe->cells[worldgen_index(globe, row, column)] =
                (WorldGenCell)(surface | (unsigned int)height);
        }
    }
    return 1;
}

unsigned int WorldGenGlobeRowWidth(const WorldGenGlobe *globe,
                                   unsigned int row)
{
    if (globe == 0 || row >= WORLDGEN_GLOBE_ROWS) return 0U;
    return globe->row_width[row];
}

int WorldGenGlobeGetCell(const WorldGenGlobe *globe, unsigned int row,
                         unsigned int column, WorldGenCell *cell)
{
    if (globe == 0 || cell == 0 || globe->cells == 0 ||
        row >= WORLDGEN_GLOBE_ROWS || globe->row_width[row] == 0U)
        return 0;
    *cell = globe->cells[worldgen_index(globe, row, column)];
    return 1;
}

int WorldGenMapGetCell(const WorldGenMap *map, unsigned int x,
                       unsigned int y, WorldGenCell *cell)
{
    if (map == 0 || cell == 0 || x >= WORLDGEN_MAP_WIDTH ||
        y >= WORLDGEN_MAP_HEIGHT)
        return 0;
    *cell = map->cells[y * WORLDGEN_MAP_WIDTH + x];
    return 1;
}
