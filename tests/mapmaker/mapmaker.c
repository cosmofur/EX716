#include "mapmaker.h"

/* Compile-time checks: this program cannot safely target another ABI. */
typedef char mapmaker_assert_short_is_16[(sizeof(unsigned short) == 2) ? 1 : -1];
typedef char mapmaker_assert_long_is_at_least_32[(sizeof(unsigned long) >= 4) ? 1 : -1];

/* Explicit masks make the checksum 32-bit even on LP64 hosts. */
#define MAP_U32(value) ((value) & 0xffffffffUL)

/* This full-map buffer keeps smoothing independent of traversal direction. */
#ifdef __EX716__
/* Bank 2 is a manually reserved far-scratch bank in the CPU24 harness. */
static ex716_far_ptr mapmaker_smooth_buffer = EX716_FAR_PTR(2U, 0x0200U);
static MapCell mapmaker_smooth_row[MAP_WIDTH];
#else
static MapCell mapmaker_smooth_buffer[MAP_CELLS];
#endif

/* The host keeps the entire destination map near.  CPU24 writes one computed
 * row at a time, then transfers that row to the far scratch segment. */
#ifndef __EX716__
static void mapmaker_smooth_store(unsigned int index, MapCell cell)
{
    mapmaker_smooth_buffer[index] = cell;
}

static MapCell mapmaker_smooth_load(unsigned int index)
{
    return mapmaker_smooth_buffer[index];
}
#endif

static int mapmaker_clamp_coordinate(int value, int maximum)
{
    if (value < 0)
        return 0;
    if (value > maximum)
        return maximum;
    return value;
}

static void mapmaker_stamp_peak(Map *map, int center_x, int center_y,
                                unsigned int height)
{
    int x;
    int y;
    int distance;
    unsigned int candidate;
    MapCell cell;
    unsigned int terrain;

    for (y = center_y - 7; y <= center_y + 7; ++y) {
        if (y < 0 || y >= MAP_HEIGHT)
            continue;
        for (x = center_x - 7; x <= center_x + 7; ++x) {
            if (x < 0 || x >= MAP_WIDTH)
                continue;
            distance = x - center_x;
            if (distance < 0)
                distance = -distance;
            if (y - center_y < 0)
                distance += center_y - y;
            else
                distance += y - center_y;
            if (height <= (unsigned int)(distance * 16))
                continue;
            candidate = height - (unsigned int)(distance * 16);
            cell = map->cells[y * MAP_WIDTH + x];
            if (candidate > CELL_HEIGHT(cell)) {
                terrain = (CELL_TERRAIN(cell) & ~TERRAIN_GROUND_MASK) |
                          TERRAIN_ROCK;
                map->cells[y * MAP_WIDTH + x] = MAKE_CELL(candidate, terrain);
            }
        }
    }
}

static void mapmaker_draw_ridge(Map *map, int x0, int y0, unsigned int h0,
                                int x1, int y1, unsigned int h1)
{
    int delta_x;
    int delta_y;
    int step_x;
    int step_y;
    int error;
    int twice_error;
    int steps;
    int step;
    long height;

    delta_x = x1 - x0;
    if (delta_x < 0) delta_x = -delta_x;
    delta_y = y1 - y0;
    if (delta_y < 0) delta_y = -delta_y;
    step_x = x0 < x1 ? 1 : -1;
    step_y = y0 < y1 ? 1 : -1;
    error = delta_x - delta_y;
    steps = delta_x > delta_y ? delta_x : delta_y;
    if (steps == 0) {
        mapmaker_stamp_peak(map, x0, y0, h0);
        return;
    }
    step = 0;
    for (;;) {
        height = (long)h0 + ((long)((int)h1 - (int)h0) * step) / steps;
        mapmaker_stamp_peak(map, x0, y0, (unsigned int)height);
        if (x0 == x1 && y0 == y1)
            break;
        twice_error = error * 2;
        if (twice_error > -delta_y) {
            error -= delta_y;
            x0 += step_x;
        }
        if (twice_error < delta_x) {
            error += delta_x;
            y0 += step_y;
        }
        ++step;
    }
}

int MapInitialize(Map *map, unsigned long seed, unsigned short type)
{
    unsigned int index;

    if (map == 0)
        return 0;
    map->width = MAP_WIDTH;
    map->height = MAP_HEIGHT;
    map->type = type;
    map->format_version = MAP_FORMAT_VERSION;
    map->seed = MAP_U32(seed);
    /* xorshift has an all-zero absorbing state. */
    map->prng_state = (unsigned short)map->seed;
    if (map->prng_state == 0)
        map->prng_state = 0xace1U;
    for (index = 0; index < MAP_CELLS; ++index)
        map->cells[index] = MAKE_CELL(0, TERRAIN_DIRT);
    return 1;
}

int MapSetCell(Map *map, unsigned int x, unsigned int y, MapCell cell)
{
    if (map == 0 || x >= MAP_WIDTH || y >= MAP_HEIGHT)
        return 0;
    map->cells[y * MAP_WIDTH + x] = cell;
    return 1;
}

int MapGetCell(const Map *map, unsigned int x, unsigned int y, MapCell *cell)
{
    if (map == 0 || cell == 0 || x >= MAP_WIDTH || y >= MAP_HEIGHT)
        return 0;
    *cell = map->cells[y * MAP_WIDTH + x];
    return 1;
}

unsigned long MapRandom(Map *map)
{
    unsigned int value;

    if (map == 0)
        return 0;
    value = map->prng_state;
    value = (value ^ (value << 7)) & 0xffffU;
    value = (value ^ (value >> 9)) & 0xffffU;
    value = (value ^ (value << 8)) & 0xffffU;
    map->prng_state = (unsigned short)value;
    return (unsigned long)value;
}

unsigned int MapRandomBelow(Map *map, unsigned int limit)
{
    if (limit == 0)
        return 0;
    return (unsigned int)(MapRandom(map) % (unsigned long)limit);
}

int MapSmooth(Map *map, int passes)
{
    int pass;
    int x;
    int y;
    unsigned int index;
    unsigned int sum;
    MapCell center;
#ifdef __EX716__
    ex716_far_ptr row_pointer;
#endif

    if (map == 0 || passes < 0)
        return 0;
    for (pass = 0; pass < passes; ++pass) {
        for (y = 0; y < MAP_HEIGHT; ++y) {
            for (x = 0; x < MAP_WIDTH; ++x) {
                index = (unsigned int)(y * MAP_WIDTH + x);
                center = map->cells[index];
                sum = CELL_HEIGHT(center) * 4U;
                sum += CELL_HEIGHT(map->cells[(y ? y - 1 : y) * MAP_WIDTH + x]);
                sum += CELL_HEIGHT(map->cells[(y + 1 < MAP_HEIGHT ? y + 1 : y) * MAP_WIDTH + x]);
                sum += CELL_HEIGHT(map->cells[y * MAP_WIDTH + (x ? x - 1 : x)]);
                sum += CELL_HEIGHT(map->cells[y * MAP_WIDTH + (x + 1 < MAP_WIDTH ? x + 1 : x)]);
#ifdef __EX716__
                mapmaker_smooth_row[x] = MAKE_CELL(sum >> 3,
                                                    CELL_TERRAIN(center));
#else
                mapmaker_smooth_store(index, MAKE_CELL(sum >> 3,
                                                        CELL_TERRAIN(center)));
#endif
            }
#ifdef __EX716__
            row_pointer.offset = (unsigned short)(mapmaker_smooth_buffer.offset +
                                                   (unsigned int)y * MAP_WIDTH * 2U);
            row_pointer.segment = mapmaker_smooth_buffer.segment;
            ex716_far_put16v(&row_pointer, mapmaker_smooth_row, MAP_WIDTH);
#endif
        }
#ifdef __EX716__
        for (y = 0; y < MAP_HEIGHT; ++y) {
            row_pointer.offset = (unsigned short)(mapmaker_smooth_buffer.offset +
                                                   (unsigned int)y * MAP_WIDTH * 2U);
            row_pointer.segment = mapmaker_smooth_buffer.segment;
            ex716_far_get16v(&row_pointer, mapmaker_smooth_row, MAP_WIDTH);
            for (x = 0; x < MAP_WIDTH; ++x)
                map->cells[(unsigned int)y * MAP_WIDTH + x] = mapmaker_smooth_row[x];
        }
#else
        for (index = 0; index < MAP_CELLS; ++index)
            map->cells[index] = mapmaker_smooth_load(index);
#endif
    }
    return 1;
}

int MapAddMountainRange(Map *map, int low_height, int high_height, int age)
{
    int x[12];
    int y[12];
    unsigned int height[12];
    int intermediate;
    int point_count;
    int index;
    int attempt;
    int delta_x;
    int delta_y;
    int jitter;

    if (map == 0 || low_height < 0 || high_height > 255 ||
        low_height > high_height || age < 0)
        return 0;
    for (attempt = 0; attempt < 64; ++attempt) {
        x[0] = (int)MapRandomBelow(map, MAP_WIDTH);
        y[0] = (int)MapRandomBelow(map, MAP_HEIGHT);
        x[11] = (int)MapRandomBelow(map, MAP_WIDTH);
        y[11] = (int)MapRandomBelow(map, MAP_HEIGHT);
        delta_x = x[11] - x[0];
        delta_y = y[11] - y[0];
        if (delta_x * delta_x + delta_y * delta_y >= 900)
            break;
    }
    if (attempt == 64)
        return 0;
    intermediate = 5 + (int)MapRandomBelow(map, 6);
    point_count = intermediate + 2;
    x[point_count - 1] = x[11];
    y[point_count - 1] = y[11];
    for (index = 0; index < point_count; ++index)
        height[index] = (unsigned int)low_height +
            MapRandomBelow(map, (unsigned int)(high_height - low_height + 1));
    for (index = 1; index < point_count - 1; ++index) {
        x[index] = (x[0] * (point_count - 1 - index) +
                    x[point_count - 1] * index) / (point_count - 1);
        y[index] = (y[0] * (point_count - 1 - index) +
                    y[point_count - 1] * index) / (point_count - 1);
        /* Keep control points close to the endpoint line: +/- 5% drift. */
        jitter = (int)MapRandomBelow(map, 11) - 5;
        x[index] = mapmaker_clamp_coordinate(x[index] -
                    ((y[point_count - 1] - y[0]) * jitter) / 16,
                    MAP_WIDTH - 1);
        y[index] = mapmaker_clamp_coordinate(y[index] +
                    ((x[point_count - 1] - x[0]) * jitter) / 16,
                    MAP_HEIGHT - 1);
    }
    for (index = 0; index < point_count - 1; ++index)
        mapmaker_draw_ridge(map, x[index], y[index], height[index],
                            x[index + 1], y[index + 1], height[index + 1]);
    return MapSmooth(map, age);
}

int MapClassifyTerrain(Map *map, unsigned int sea_level)
{
    unsigned int index;
    unsigned int height;
    unsigned int terrain;

    if (map == 0 || sea_level > 255U)
        return 0;
    for (index = 0; index < MAP_CELLS; ++index) {
        height = CELL_HEIGHT(map->cells[index]);
        terrain = CELL_TERRAIN(map->cells[index]) & ~TERRAIN_GROUND_MASK;
        if (height <= sea_level)
            terrain |= TERRAIN_WATER;
        else if (height >= 192U)
            terrain |= TERRAIN_SNOW;
        else if (height >= 80U)
            terrain |= TERRAIN_ROCK;
        else
            terrain |= TERRAIN_GRASS;
        map->cells[index] = MAKE_CELL(height, terrain);
    }
    return 1;
}

static void mapmaker_mark_river(Map *map, int x, int y)
{
    unsigned int index;
    MapCell cell;

    index = (unsigned int)(y * MAP_WIDTH + x);
    cell = map->cells[index];
    map->cells[index] = MAKE_CELL(CELL_HEIGHT(cell),
                                  CELL_TERRAIN(cell) | FEATURE_RIVER);
}

static void mapmaker_make_lake(Map *map, int center_x, int center_y)
{
    int x;
    int y;
    unsigned int index;
    MapCell cell;

    for (y = center_y - 1; y <= center_y + 1; ++y) {
        if (y < 0 || y >= MAP_HEIGHT)
            continue;
        for (x = center_x - 1; x <= center_x + 1; ++x) {
            if (x < 0 || x >= MAP_WIDTH)
                continue;
            index = (unsigned int)(y * MAP_WIDTH + x);
            cell = map->cells[index];
            map->cells[index] = MAKE_CELL(CELL_HEIGHT(cell),
                                          (CELL_TERRAIN(cell) & ~TERRAIN_GROUND_MASK) |
                                          TERRAIN_WATER | FEATURE_RIVER);
        }
    }
}

int MapAddRivers(Map *map, int start_height, int count)
{
    int river;
    int attempts;
    int x;
    int y;
    int next_x;
    int next_y;
    int direction;
    int steps;
    int created;
    int options;
    unsigned int current_height;
    unsigned int next_height;
    unsigned int terrain;
    static const int delta_x[4] = { 0, 1, 0, -1 };
    static const int delta_y[4] = { -1, 0, 1, 0 };

    if (map == 0 || start_height < 0 || start_height > 255 || count < 0)
        return -1;
    created = 0;
    for (river = 0; river < count; ++river) {
        for (attempts = 0; attempts < 256; ++attempts) {
            x = (int)MapRandomBelow(map, MAP_WIDTH);
            y = (int)MapRandomBelow(map, MAP_HEIGHT);
            terrain = CELL_TERRAIN(map->cells[y * MAP_WIDTH + x]);
            if (CELL_HEIGHT(map->cells[y * MAP_WIDTH + x]) >=
                (unsigned int)start_height &&
                (terrain & TERRAIN_GROUND_MASK) != TERRAIN_WATER)
                break;
        }
        if (attempts == 256)
            continue;
        ++created;
        for (steps = 0; steps < MAP_CELLS; ++steps) {
            current_height = CELL_HEIGHT(map->cells[y * MAP_WIDTH + x]);
            mapmaker_mark_river(map, x, y);
            if ((CELL_TERRAIN(map->cells[y * MAP_WIDTH + x]) &
                 TERRAIN_GROUND_MASK) == TERRAIN_WATER)
                break;
            next_x = x;
            next_y = y;
            next_height = current_height;
            for (direction = 0; direction < 4; ++direction) {
                int candidate_x = x + delta_x[direction];
                int candidate_y = y + delta_y[direction];
                unsigned int candidate_height;

                if (candidate_x < 0 || candidate_x >= MAP_WIDTH ||
                    candidate_y < 0 || candidate_y >= MAP_HEIGHT)
                    continue;
                candidate_height = CELL_HEIGHT(
                    map->cells[candidate_y * MAP_WIDTH + candidate_x]);
                if (candidate_height < next_height) {
                    next_height = candidate_height;
                    next_x = candidate_x;
                    next_y = candidate_y;
                }
            }
            if (next_x == x && next_y == y) {
                mapmaker_make_lake(map, x, y);
                break;
            }
            /* On gentle slopes, choose among near-steepest lower neighbors.
               Reservoir selection is deterministic because it uses the map's
               PRNG, while strict descent still prevents cycles. */
            options = 0;
            for (direction = 0; direction < 4; ++direction) {
                int candidate_x = x + delta_x[direction];
                int candidate_y = y + delta_y[direction];
                unsigned int candidate_height;

                if (candidate_x < 0 || candidate_x >= MAP_WIDTH ||
                    candidate_y < 0 || candidate_y >= MAP_HEIGHT)
                    continue;
                candidate_height = CELL_HEIGHT(
                    map->cells[candidate_y * MAP_WIDTH + candidate_x]);
                if (candidate_height < current_height &&
                    candidate_height <= next_height + 2U) {
                    ++options;
                    if (MapRandomBelow(map, (unsigned int)options) == 0U) {
                        next_x = candidate_x;
                        next_y = candidate_y;
                    }
                }
            }
            x = next_x;
            y = next_y;
        }
    }
    return created;
}

static int mapmaker_can_forest(const Map *map, int x, int y)
{
    int direction;
    unsigned int terrain;
    static const int delta_x[4] = { 0, 1, 0, -1 };
    static const int delta_y[4] = { -1, 0, 1, 0 };

    if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT)
        return 0;
    terrain = CELL_TERRAIN(map->cells[y * MAP_WIDTH + x]);
    if ((terrain & TERRAIN_GROUND_MASK) != TERRAIN_GRASS ||
        (terrain & FEATURE_RIVER))
        return 0;
    for (direction = 0; direction < 4; ++direction) {
        int near_x = x + delta_x[direction];
        int near_y = y + delta_y[direction];

        if (near_x < 0 || near_x >= MAP_WIDTH ||
            near_y < 0 || near_y >= MAP_HEIGHT)
            continue;
        terrain = CELL_TERRAIN(map->cells[near_y * MAP_WIDTH + near_x]);
        if ((terrain & TERRAIN_GROUND_MASK) == TERRAIN_WATER)
            return 0;
    }
    return 1;
}

int MapAddForests(Map *map, int density)
{
    unsigned int index;
    unsigned int grass_cells;
    unsigned long target;
    unsigned long placed;
    unsigned long cluster;
    unsigned long clusters;
    int x;
    int y;
    int seed_x;
    int seed_y;
    int attempts;
    int steps;
    int direction;
    MapCell cell;
    static const int delta_x[4] = { 0, 1, 0, -1 };
    static const int delta_y[4] = { -1, 0, 1, 0 };

    if (map == 0 || density < 0 || density > 100)
        return -1;
    grass_cells = 0;
    for (index = 0; index < MAP_CELLS; ++index)
        if ((CELL_TERRAIN(map->cells[index]) & TERRAIN_GROUND_MASK) ==
            TERRAIN_GRASS)
            ++grass_cells;
    target = ((unsigned long)grass_cells * (unsigned long)density) / 100UL;
    if (target == 0)
        return 0;
    clusters = target / 64UL + 1UL;
    placed = 0;
    for (cluster = 0; cluster < clusters && placed < target; ++cluster) {
        for (attempts = 0; attempts < 256; ++attempts) {
            seed_x = (int)MapRandomBelow(map, MAP_WIDTH);
            seed_y = (int)MapRandomBelow(map, MAP_HEIGHT);
            if (mapmaker_can_forest(map, seed_x, seed_y))
                break;
        }
        if (attempts == 256)
            continue;
        x = seed_x;
        y = seed_y;
        for (steps = 0; steps < 96 && placed < target; ++steps) {
            if (mapmaker_can_forest(map, x, y)) {
                cell = map->cells[y * MAP_WIDTH + x];
                if (!(CELL_TERRAIN(cell) & FEATURE_FOREST)) {
                    map->cells[y * MAP_WIDTH + x] = MAKE_CELL(CELL_HEIGHT(cell),
                                                CELL_TERRAIN(cell) | FEATURE_FOREST);
                    ++placed;
                }
            }
            direction = (int)MapRandomBelow(map, 4);
            x += delta_x[direction];
            y += delta_y[direction];
            if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT ||
                !mapmaker_can_forest(map, x, y)) {
                x = seed_x;
                y = seed_y;
            }
        }
    }
    return (int)placed;
}

void SettlementListInitialize(SettlementList *list, Settlement *items,
                              unsigned short capacity)
{
    if (list == 0)
        return;
    list->items = items;
    list->count = 0;
    list->capacity = capacity;
}

Settlement *MapFindSettlement(SettlementList *list, unsigned short cell_index)
{
    unsigned int index;

    if (list == 0 || list->items == 0)
        return 0;
    for (index = 0; index < list->count; ++index)
        if (list->items[index].cell_index == cell_index)
            return &list->items[index];
    return 0;
}

static int mapmaker_settlement_class(const Map *map, int x, int y)
{
    int direction;
    unsigned int terrain;
    static const int delta_x[4] = { 0, 1, 0, -1 };
    static const int delta_y[4] = { -1, 0, 1, 0 };

    terrain = CELL_TERRAIN(map->cells[y * MAP_WIDTH + x]);
    if ((terrain & TERRAIN_GROUND_MASK) == TERRAIN_WATER ||
        (terrain & FEATURE_SITE))
        return -1;
    for (direction = 0; direction < 4; ++direction) {
        int near_x = x + delta_x[direction];
        int near_y = y + delta_y[direction];

        if (near_x < 0 || near_x >= MAP_WIDTH ||
            near_y < 0 || near_y >= MAP_HEIGHT)
            continue;
        terrain = CELL_TERRAIN(map->cells[near_y * MAP_WIDTH + near_x]);
        if ((terrain & TERRAIN_GROUND_MASK) == TERRAIN_WATER) {
            if (terrain & FEATURE_RIVER)
                return 2;
            return 1;
        }
    }
    return (CELL_TERRAIN(map->cells[y * MAP_WIDTH + x]) &
            TERRAIN_GROUND_MASK) == TERRAIN_GRASS ? 0 : -1;
}

static int mapmaker_site_has_space(const SettlementList *list, int x, int y)
{
    unsigned int index;
    int other_x;
    int other_y;
    int distance;

    for (index = 0; index < list->count; ++index) {
        other_x = list->items[index].cell_index % MAP_WIDTH;
        other_y = list->items[index].cell_index / MAP_WIDTH;
        distance = x - other_x;
        if (distance < 0) distance = -distance;
        other_y = y - other_y;
        if (other_y < 0) other_y = -other_y;
        distance += other_y;
        if (distance < 8)
            return 0;
    }
    return 1;
}

int MapAddSettlements(Map *map, SettlementList *list, int count)
{
    int wanted_class;
    int candidate_class;
    int fallback_class;
    int attempts;
    int x;
    int y;
    int placed;
    unsigned int index;
    MapCell cell;
    Settlement *settlement;

    if (map == 0 || list == 0 || count < 0 ||
        (list->capacity != 0 && list->items == 0) || list->count > list->capacity)
        return -1;
    placed = 0;
    while (placed < count && list->count < list->capacity) {
        /* 70% river mouths, 20% other coast, 10% inland grassland. */
        if (placed * 10 < count * 7)
            wanted_class = 2;
        else if (placed * 10 < count * 9)
            wanted_class = 1;
        else
            wanted_class = 0;
        candidate_class = -1;
        for (fallback_class = wanted_class; fallback_class >= 0 &&
             candidate_class < 0; --fallback_class) {
            for (attempts = 0; attempts < 512; ++attempts) {
                x = (int)MapRandomBelow(map, MAP_WIDTH);
                y = (int)MapRandomBelow(map, MAP_HEIGHT);
                if (mapmaker_settlement_class(map, x, y) == fallback_class &&
                    mapmaker_site_has_space(list, x, y)) {
                    candidate_class = fallback_class;
                    break;
                }
            }
        }
        if (candidate_class < 0)
            break;
        index = (unsigned int)(y * MAP_WIDTH + x);
        cell = map->cells[index];
        map->cells[index] = MAKE_CELL(CELL_HEIGHT(cell),
                                      CELL_TERRAIN(cell) | FEATURE_SITE);
        settlement = &list->items[list->count++];
        settlement->cell_index = (unsigned short)index;
        settlement->type = candidate_class > 0 ? SETTLEMENT_PORT :
                                                 SETTLEMENT_INLAND;
        settlement->size = 1;
        settlement->tech_level = 0;
        ++placed;
    }
    return placed;
}

unsigned long MapChecksum(const Map *map)
{
    unsigned int index;
    unsigned long sum;

    if (map == 0)
        return 0;
    sum = 2166136261UL;
    sum = MAP_U32((sum ^ map->width) * 16777619UL);
    sum = MAP_U32((sum ^ map->height) * 16777619UL);
    sum = MAP_U32((sum ^ map->type) * 16777619UL);
    sum = MAP_U32((sum ^ map->format_version) * 16777619UL);
    sum = MAP_U32((sum ^ map->seed) * 16777619UL);
    sum = MAP_U32((sum ^ map->prng_state) * 16777619UL);
    for (index = 0; index < MAP_CELLS; ++index)
        sum = MAP_U32((sum ^ map->cells[index]) * 16777619UL);
    return sum;
}
