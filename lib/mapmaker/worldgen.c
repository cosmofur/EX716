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

/* Terrain detail lives in fixed world-space bands.  A band fades in while
 * the map approaches half its wavelength, so zooming adds visible detail
 * without changing the noise that formed the broader land shapes. */
static int worldgen_terrain_detail(unsigned long seed, long world_x,
                                   long world_y,
                                   unsigned int cell_size_half_meters)
{
    static const unsigned int periods[6] = {
        600000U, 60000U, 6000U, 600U, 60U, 6U
    };
    static const int amplitudes[6] = { 20, 16, 12, 8, 5, 3 };
    unsigned int octave;
    unsigned int period;
    unsigned int fade;
    int detail;
    int sample;

    detail = 0;
    for (octave = 0U; octave < 6U; ++octave) {
        period = periods[octave];
        if (cell_size_half_meters >= period) continue;
        if (cell_size_half_meters * 2U <= period)
            fade = 1000U;
        else
            fade = (period - cell_size_half_meters) * 2000U / period;
        sample = worldgen_smooth_noise(seed, 0x54455252UL + octave * 2UL,
                                       world_x, world_y, period);
        detail += sample * amplitudes[octave] * (int)fade / 128000;
    }
    return detail;
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
    map->cell_size_half_meters = (unsigned int)meters_per_cell * 2U;
    map->origin_x_meters = origin_x_meters;
    map->origin_y_meters = origin_y_meters;
    map->origin_x_half_meters = origin_x_meters * 2L;
    map->origin_y_half_meters = origin_y_meters * 2L;
    for (index = 0U; index < WORLDGEN_MAP_CELLS; ++index)
        map->cells[index] = WORLDGEN_SURFACE_NONE;
    return 1;
}

int WorldGenMapInitializeHalfMeter(WorldGenMap *map, unsigned long seed,
                                   unsigned short profile,
                                   unsigned short level,
                                   unsigned int cell_size_half_meters,
                                   long origin_x_half_meters,
                                   long origin_y_half_meters)
{
    unsigned int index;

    if (map == 0 || cell_size_half_meters == 0U ||
        (profile != WORLDGEN_PROFILE_EARTHLIKE &&
         profile != WORLDGEN_PROFILE_DEAD))
        return 0;
    map->seed = seed;
    map->profile = profile;
    map->level = level;
    map->cell_size_half_meters = cell_size_half_meters;
    map->meters_per_cell = (unsigned short)((cell_size_half_meters + 1U) / 2U);
    map->origin_x_half_meters = origin_x_half_meters;
    map->origin_y_half_meters = origin_y_half_meters;
    map->origin_x_meters = origin_x_half_meters / 2L;
    map->origin_y_meters = origin_y_half_meters / 2L;
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

    row = worldgen_floor_divide(world_y, 600000L) + 32L;
    if (row < 0L) row = 0L;
    if (row >= (long)WORLDGEN_GLOBE_ROWS) row = WORLDGEN_GLOBE_ROWS - 1L;
    longitude = worldgen_floor_divide(world_x, 300000L) % 256L;
    if (longitude < 0L) longitude += 256L;
    column = (unsigned int)(longitude * globe->row_width[(unsigned int)row] /
                            256L);
    return WorldGenGlobeGetCell(globe, (unsigned int)row, column, cell);
}

#define WORLDGEN_RIVER_STEP_HALF_METERS 60000L
#define WORLDGEN_RIVER_MAX_STEPS 512U
#define WORLDGEN_WORLD_WIDTH_HALF_METERS 76800000L
#define WORLDGEN_WORLD_HEIGHT_HALF_METERS 19200000L
#define WORLDGEN_RIVER_SOURCE_DOMAIN 0x52495653UL

static long worldgen_abs_long(long value)
{
    return value < 0L ? -value : value;
}

static long worldgen_longitude_distance(long first, long second)
{
    long distance;
    distance = worldgen_abs_long(first - second) %
               WORLDGEN_WORLD_WIDTH_HALF_METERS;
    if (distance > WORLDGEN_WORLD_WIDTH_HALF_METERS / 2L)
        distance = WORLDGEN_WORLD_WIDTH_HALF_METERS - distance;
    return distance;
}

static int worldgen_sample_terrain(const WorldGenGlobe *globe, long x,
                                   long y, int *height,
                                   unsigned int *surface)
{
    WorldGenCell parent;
    int detail;

    if (!worldgen_sample_globe(globe, x, y, &parent)) return 0;
    *surface = parent & WORLDGEN_CELL_SURFACE_MASK;
    if (*surface == WORLDGEN_SURFACE_OCEAN) {
        *height = 0;
        return 1;
    }
    detail = worldgen_terrain_detail(globe->seed, x, y,
                                     (unsigned int)WORLDGEN_RIVER_STEP_HALF_METERS);
    *height = worldgen_clamp((int)(parent & WORLDGEN_CELL_VALUE_MASK) +
                             detail, 0, 255);
    return 1;
}

static int worldgen_river_near_existing(const WorldGenHydrology *hydrology,
                                        unsigned int first_point,
                                        long x, long y)
{
    unsigned int point;
    long dx;
    long dy;

    for (point = 0U; point < first_point; ++point) {
        dx = worldgen_longitude_distance(
            hydrology->points[point].x_half_meters, x);
        dy = worldgen_abs_long(hydrology->points[point].y_half_meters - y);
        if (dx + dy <= WORLDGEN_RIVER_STEP_HALF_METERS / 4L)
            return 1;
    }
    return 0;
}

static int worldgen_trace_river(WorldGenHydrology *hydrology,
                                const WorldGenGlobe *globe,
                                unsigned int source_row,
                                unsigned int source_column)
{
    static const int direction_x[8] = { 0, 1, 1, 1, 0, -1, -1, -1 };
    static const int direction_y[8] = { -1, -1, 0, 1, 1, 1, 0, -1 };
    long x, y, next_x, next_y, step_x, step_y, cell_width;
    long dx, dy, latitude_row;
    unsigned long key;
    unsigned int first_point, step, direction, preferred, candidate;
    unsigned int selected, surface, next_surface;
    unsigned int row_angle, cosine, point_index;
    int height, next_height, previous_height, drop, best_score, score;
    int maximum_drop, minimum_height, found, repeated;
    unsigned int terminal;
    WorldGenRiver *river;

    if (hydrology->river_count >= hydrology->river_capacity ||
        hydrology->point_count >= hydrology->point_capacity)
        return 0;
    first_point = hydrology->point_count;
    key = worldgen_hash(globe->seed, WORLDGEN_RIVER_SOURCE_DOMAIN,
                        (long)source_row, (long)source_column);
    cell_width = WORLDGEN_WORLD_WIDTH_HALF_METERS /
                 WorldGenGlobeRowWidth(globe, source_row);
    x = (long)source_column * cell_width + cell_width / 2L;
    y = ((long)source_row - 32L) * 600000L + 300000L;
    direction = (unsigned int)(key & 7UL);
    previous_height = -1;
    selected = 0U;
    terminal = WORLDGEN_RIVER_END_LIMIT;
    step_y = WORLDGEN_RIVER_STEP_HALF_METERS;

    for (step = 0U; step < WORLDGEN_RIVER_MAX_STEPS; ++step) {
        if (!worldgen_sample_terrain(globe, x, y, &height, &surface))
            return 0;
        if (hydrology->point_count >= hydrology->point_capacity) break;
        point_index = hydrology->point_count++;
        hydrology->points[point_index].x_half_meters = x;
        hydrology->points[point_index].y_half_meters = y;
        hydrology->points[point_index].flags = WORLDGEN_FEATURE_RIVER;
        if (height <= 55 && previous_height >= 0 &&
            worldgen_abs(height - previous_height) <= 2)
            hydrology->points[point_index].flags |= WORLDGEN_FEATURE_SWAMP;
        if (surface == WORLDGEN_SURFACE_OCEAN) {
            terminal = WORLDGEN_RIVER_END_SEA;
            break;
        }
        if (step != 0U && worldgen_river_near_existing(hydrology,
                                                       first_point, x, y)) {
            terminal = WORLDGEN_RIVER_END_TRIBUTARY;
            break;
        }

        latitude_row = worldgen_floor_divide(y, 600000L) + 32L;
        row_angle = (unsigned int)(worldgen_abs((int)latitude_row * 2 -
                                                63) * 64 / 63);
        if (row_angle > 64U) row_angle = 64U;
        cosine = (unsigned int)MapMathCos(row_angle);
        if (cosine < (MAPMATH_TRIG_SCALE / 3U))
            step_x = step_y * 3L;
        else
            step_x = step_y * MAPMATH_TRIG_SCALE / (long)cosine;

        maximum_drop = -32768;
        minimum_height = 32767;
        selected = 0U;
        best_score = -32768;
        found = 0;
        for (candidate = 0U; candidate < 8U; ++candidate) {
            next_x = x + (long)direction_x[candidate] * step_x;
            next_y = y + (long)direction_y[candidate] * step_y;
            if (next_y < -WORLDGEN_WORLD_HEIGHT_HALF_METERS ||
                next_y > WORLDGEN_WORLD_HEIGHT_HALF_METERS)
                continue;
            if (!worldgen_sample_terrain(globe, next_x, next_y,
                                         &next_height, &next_surface))
                continue;
            if (next_height < minimum_height) minimum_height = next_height;
            drop = height - next_height;
            if (drop > maximum_drop) maximum_drop = drop;
            if (drop > 1 || next_surface == WORLDGEN_SURFACE_OCEAN) {
                score = drop * 8 + (candidate == direction ? 20 :
                        (candidate + 1U) % 8U == direction ||
                        (direction + 1U) % 8U == candidate ? 8 : 0) +
                        (int)(worldgen_hash(globe->seed, key,
                                            (long)step, (long)candidate) & 7UL);
                repeated = 0;
                for (point_index = first_point;
                     point_index < hydrology->point_count; ++point_index) {
                    dx = worldgen_longitude_distance(
                        hydrology->points[point_index].x_half_meters, next_x);
                    dy = worldgen_abs_long(hydrology->points[point_index].y_half_meters -
                                           next_y);
                    if (dx + dy < WORLDGEN_RIVER_STEP_HALF_METERS / 3L) {
                        repeated = 1;
                        break;
                    }
                }
                if (!repeated && score > best_score) {
                    best_score = score;
                    selected = candidate;
                    found = 1;
                }
            }
        }
        if (!found) {
            if (minimum_height > height + 2 || maximum_drop < 0) {
                terminal = WORLDGEN_RIVER_END_POND;
                break;
            }
            preferred = direction;
            key = worldgen_hash(globe->seed, key, (long)step, 0x464c4154L);
            if (key % 100UL < 15UL)
                preferred = (direction + ((key & 0x100UL) ? 1U : 7U)) & 7U;
            best_score = -32768;
            found = 0;
            for (candidate = 0U; candidate < 8U; ++candidate) {
                next_x = x + (long)direction_x[candidate] * step_x;
                next_y = y + (long)direction_y[candidate] * step_y;
                if (next_y < -WORLDGEN_WORLD_HEIGHT_HALF_METERS ||
                    next_y > WORLDGEN_WORLD_HEIGHT_HALF_METERS ||
                    !worldgen_sample_terrain(globe, next_x, next_y,
                                             &next_height, &next_surface) ||
                    next_height > height + 1)
                    continue;
                score = (candidate == preferred ? 100 : 0) -
                        (int)worldgen_abs_long((long)height - next_height) * 4 +
                        (int)(worldgen_hash(globe->seed, key,
                                            (long)step, (long)candidate) & 3UL);
                repeated = 0;
                for (point_index = first_point;
                     point_index < hydrology->point_count; ++point_index) {
                    dx = worldgen_longitude_distance(
                        hydrology->points[point_index].x_half_meters, next_x);
                    dy = worldgen_abs_long(hydrology->points[point_index].y_half_meters -
                                           next_y);
                    if (dx + dy < WORLDGEN_RIVER_STEP_HALF_METERS / 3L) {
                        repeated = 1;
                        break;
                    }
                }
                if (!repeated && score > best_score) {
                    best_score = score;
                    selected = candidate;
                    found = 1;
                }
            }
            if (!found) {
                terminal = WORLDGEN_RIVER_END_POND;
                break;
            }
        }
        previous_height = height;
        direction = selected;
        x += (long)direction_x[direction] * step_x;
        y += (long)direction_y[direction] * step_y;
    }

    if (hydrology->point_count == first_point) return 0;
    river = &hydrology->rivers[hydrology->river_count++];
    river->id = worldgen_hash(globe->seed, WORLDGEN_RIVER_SOURCE_DOMAIN,
                              (long)source_row, (long)source_column);
    river->first_point = first_point;
    river->point_count = hydrology->point_count - first_point;
    river->terminal = terminal;
    river->mouth_x_half_meters = hydrology->points[hydrology->point_count - 1U].x_half_meters;
    river->mouth_y_half_meters = hydrology->points[hydrology->point_count - 1U].y_half_meters;
    river->width_half_meters = 2U + river->point_count / 32U;
    if (river->width_half_meters > 12U) river->width_half_meters = 12U;
    river->pond_radius_half_meters = terminal == WORLDGEN_RIVER_END_POND ?
        100U + (unsigned int)(key % 900UL) : 0U;
    return 1;
}

int WorldGenHydrologyInitialize(WorldGenHydrology *hydrology,
                                WorldGenRiver *rivers,
                                unsigned int river_capacity,
                                WorldGenRiverPoint *points,
                                unsigned int point_capacity)
{
    if (hydrology == 0 || rivers == 0 || points == 0 ||
        river_capacity == 0U || point_capacity == 0U)
        return 0;
    hydrology->rivers = rivers;
    hydrology->river_capacity = river_capacity;
    hydrology->river_count = 0U;
    hydrology->points = points;
    hydrology->point_capacity = point_capacity;
    hydrology->point_count = 0U;
    return 1;
}

int WorldGenGenerateHydrology(WorldGenHydrology *hydrology,
                              const WorldGenGlobe *globe)
{
    unsigned int row, column;
    unsigned long key;
    WorldGenCell cell;

    if (hydrology == 0 || globe == 0 || globe->cells == 0 ||
        hydrology->rivers == 0 || hydrology->points == 0)
        return 0;
    hydrology->river_count = 0U;
    hydrology->point_count = 0U;
    for (row = 8U; row + 8U < WORLDGEN_GLOBE_ROWS; ++row) {
        for (column = 0U; column < WorldGenGlobeRowWidth(globe, row);
             ++column) {
            if (!WorldGenGlobeGetCell(globe, row, column, &cell)) return 0;
            key = worldgen_hash(globe->seed, WORLDGEN_RIVER_SOURCE_DOMAIN,
                                (long)row, (long)column);
            if ((cell & WORLDGEN_CELL_SURFACE_MASK) == WORLDGEN_SURFACE_MOUNTAIN) {
                if (key % 5UL != 0UL) continue;
            } else if ((cell & WORLDGEN_CELL_SURFACE_MASK) ==
                       WORLDGEN_SURFACE_HIGHLAND) {
                if (key % 47UL != 0UL) continue;
            } else continue;
            if (!worldgen_trace_river(hydrology, globe, row, column) &&
                (hydrology->river_count >= hydrology->river_capacity ||
                 hydrology->point_count >= hydrology->point_capacity))
                return 1;
        }
    }
    return 1;
}

int WorldGenGenerateTile(WorldGenMap *map, const WorldGenGlobe *globe)
{
    unsigned int x;
    unsigned int y;
    unsigned int index;
    long world_x_half;
    long world_y_half;
    int parent_height;
    int detail;
    int height;
    WorldGenCell parent;
    WorldGenCell surface;

    if (map == 0 || globe == 0 || globe->cells == 0 ||
        map->seed != globe->seed || map->profile != globe->profile ||
        map->cell_size_half_meters == 0U)
        return 0;
    for (y = 0U; y < WORLDGEN_MAP_HEIGHT; ++y) {
        world_y_half = map->origin_y_half_meters +
                  (long)y * (long)map->cell_size_half_meters;
        for (x = 0U; x < WORLDGEN_MAP_WIDTH; ++x) {
            world_x_half = map->origin_x_half_meters +
                      (long)x * (long)map->cell_size_half_meters;
            if (!worldgen_sample_globe(globe, world_x_half,
                                       world_y_half, &parent))
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
            detail = worldgen_terrain_detail(map->seed, world_x_half,
                                             world_y_half,
                                             map->cell_size_half_meters);
            height = worldgen_clamp(parent_height + detail, 0, 255);
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
