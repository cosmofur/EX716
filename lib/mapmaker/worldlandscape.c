#include "worldlandscape.h"

static unsigned long landscape_hash(unsigned long seed, unsigned long domain,
                                    unsigned long value)
{
    unsigned long result;
    result = (seed ^ domain) * 16777619UL;
    result ^= value * 2246822519UL;
    result ^= result >> 13;
    return result & 0xffffffffUL;
}

static unsigned int landscape_index(unsigned int row, unsigned int column)
{
    return row * WORLD_LANDSCAPE_COLUMNS +
           column % WORLD_LANDSCAPE_COLUMNS;
}

static long landscape_abs(long value)
{
    return value < 0L ? -value : value;
}

static unsigned int landscape_column(long world_x_km)
{
    long column;
    column = (world_x_km + 19050L) / 300L;
    column %= (long)WORLD_LANDSCAPE_COLUMNS;
    if (column < 0L) column += WORLD_LANDSCAPE_COLUMNS;
    return (unsigned int)column;
}

static unsigned int landscape_row(long world_y_km)
{
    long row;
    row = (world_y_km + 9600L) / 300L;
    if (row < 0L) row = 0L;
    if (row >= WORLD_LANDSCAPE_ROWS) row = WORLD_LANDSCAPE_ROWS - 1U;
    return (unsigned int)row;
}

void WorldLandscapeInitialize(WorldLandscape *landscape, unsigned long seed)
{
    unsigned int index;
    if (landscape == 0) return;
    landscape->seed = seed & 0xffffffffUL;
    landscape->range_count = 0U;
    for (index = 0U; index < WORLD_LANDSCAPE_MAX_RANGES; ++index)
        landscape->ranges[index].active = 0U;
    for (index = 0U; index < WORLD_LANDSCAPE_CELLS; ++index)
        landscape->heights[index] = landscape->scratch[index] = 0U;
}

int WorldLandscapeGenerate(WorldLandscape *landscape)
{
    unsigned int index;
    unsigned long first;
    unsigned long second;
    WorldMountainRange *range;
    unsigned int row;
    unsigned int column;
    unsigned int pass;
    unsigned int step;
    unsigned int neighbour_sum;
    unsigned int peak;
    long x;
    long y;
    if (landscape == 0) return 0;
    landscape->range_count = 6U;
    for (index = 0U; index < landscape->range_count; ++index) {
        range = &landscape->ranges[index];
        first = landscape_hash(landscape->seed, 0x52414e47UL, index);
        second = landscape_hash(landscape->seed, 0x5350494eUL, index);
        range->start_x = (long)(first % 15000UL) - 7500L;
        range->start_y = (long)((first >> 12) % 7000UL) - 3500L;
        range->end_x = range->start_x + (long)(second % 3000UL) - 1500L;
        range->end_y = range->start_y + (long)((second >> 12) % 3000UL) - 1500L;
        range->peak_meters = (unsigned short)(700U + (second >> 24) % 1300UL);
        range->erosion_passes = (unsigned char)(2U + (first >> 24) % 5UL);
        range->active = 1U;
        /* Several unequal peaks make a chain, rather than one radial hill. */
        for (step = 0U; step <= 16U; ++step) {
            x = range->start_x + (range->end_x - range->start_x) * step / 16L;
            y = range->start_y + (range->end_y - range->start_y) * step / 16L;
            x += (long)((int)((first >> (step & 15U)) & 15UL) - 7) * 35L;
            y += (long)((int)((second >> (step & 15U)) & 15UL) - 7) * 35L;
            row = landscape_row(y);
            column = landscape_column(x);
            peak = 36U + (unsigned int)((first >> ((step + 4U) & 15U)) & 31UL);
            if (peak > landscape->heights[landscape_index(row, column)])
                landscape->heights[landscape_index(row, column)] = (unsigned char)peak;
        }
    }
    /* Erosion spreads high cells outward.  The retained centre contribution
     * prevents the peaks from vanishing while each pass broadens slopes. */
    for (pass = 0U; pass < 10U; ++pass) {
        for (row = 0U; row < WORLD_LANDSCAPE_ROWS; ++row)
            for (column = 0U; column < WORLD_LANDSCAPE_COLUMNS; ++column) {
                neighbour_sum = landscape->heights[landscape_index(row, column)] * 4U;
                neighbour_sum += landscape->heights[landscape_index(row,
                    column == 0U ? WORLD_LANDSCAPE_COLUMNS - 1U : column - 1U)];
                neighbour_sum += landscape->heights[landscape_index(row, column + 1U)];
                neighbour_sum += landscape->heights[landscape_index(row == 0U ? 0U : row - 1U, column)];
                neighbour_sum += landscape->heights[landscape_index(
                    row + 1U >= WORLD_LANDSCAPE_ROWS ? WORLD_LANDSCAPE_ROWS - 1U : row + 1U,
                    column)];
                landscape->scratch[landscape_index(row, column)] =
                    (unsigned char)(neighbour_sum / 8U);
            }
        for (row = 0U; row < WORLD_LANDSCAPE_ROWS; ++row)
            for (column = 0U; column < WORLD_LANDSCAPE_COLUMNS; ++column)
                landscape->heights[landscape_index(row, column)] =
                    landscape->scratch[landscape_index(row, column)];
    }
    return 1;
}

unsigned int WorldLandscapeUplift(const WorldLandscape *landscape,
                                  long world_x_km, long world_y_km)
{
    long local_x;
    long local_y;
    unsigned int row;
    unsigned int column;
    unsigned int next_row;
    unsigned int first;
    unsigned int second;
    unsigned int range_index;
    unsigned int peak_index;
    unsigned int fine;
    unsigned int total;
    long peak_x;
    long peak_y;
    long distance;
    long radius;
    const WorldMountainRange *range;

    if (landscape == 0) return 0U;
    row = landscape_row(world_y_km);
    column = landscape_column(world_x_km);
    next_row = row + 1U >= WORLD_LANDSCAPE_ROWS ? row : row + 1U;
    local_x = (world_x_km + 19050L) % 300L;
    if (local_x < 0L) local_x += 300L;
    local_y = (world_y_km + 9600L) % 300L;
    if (local_y < 0L) local_y += 300L;
    first = ((unsigned int)landscape->heights[landscape_index(row, column)] *
             (unsigned int)(300L - local_x) +
             (unsigned int)landscape->heights[landscape_index(row, column + 1U)] *
             (unsigned int)local_x) / 300U;
    second = ((unsigned int)landscape->heights[landscape_index(next_row, column)] *
              (unsigned int)(300L - local_x) +
              (unsigned int)landscape->heights[landscape_index(next_row, column + 1U)] *
              (unsigned int)local_x) / 300U;
    total = (first * (unsigned int)(300L - local_y) + second *
             (unsigned int)local_y) / 12U;
    /* The persistent raster establishes continental relief.  These globally
     * addressed 5--100 km peak kernels are its finer erosion layer: peaks
     * lie along the range spine and overlap into varied foothills instead of
     * one 300 km linear plane. */
    for (range_index = 0U; range_index < landscape->range_count; ++range_index) {
        range = &landscape->ranges[range_index];
        if (!range->active) continue;
        for (peak_index = 0U; peak_index <= 16U; ++peak_index) {
            peak_x = range->start_x + (range->end_x - range->start_x) *
                     (long)peak_index / 16L;
            peak_y = range->start_y + (range->end_y - range->start_y) *
                     (long)peak_index / 16L;
            peak_x += (long)((int)(landscape_hash(landscape->seed,
                0x5045414bUL + range_index, peak_index) & 15UL) - 7) * 9L;
            peak_y += (long)((int)(landscape_hash(landscape->seed,
                0x50454159UL + range_index, peak_index) & 15UL) - 7) * 9L;
            radius = 35L + (long)range->erosion_passes * 11L +
                     (long)(peak_index & 3U) * 7L;
            distance = landscape_abs(world_x_km - peak_x) +
                       landscape_abs(world_y_km - peak_y);
            if (distance >= radius) continue;
            fine = (unsigned int)((long)range->peak_meters *
                   (radius - distance) / radius);
            total += fine;
        }
    }
    return total;
}
