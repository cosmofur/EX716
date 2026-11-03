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

static long landscape_abs(long value)
{
    return value < 0L ? -value : value;
}

void WorldLandscapeInitialize(WorldLandscape *landscape, unsigned long seed)
{
    unsigned int index;
    if (landscape == 0) return;
    landscape->seed = seed & 0xffffffffUL;
    landscape->range_count = 0U;
    for (index = 0U; index < WORLD_LANDSCAPE_MAX_RANGES; ++index)
        landscape->ranges[index].active = 0U;
}

int WorldLandscapeGenerate(WorldLandscape *landscape)
{
    unsigned int index;
    unsigned long first;
    unsigned long second;
    WorldMountainRange *range;
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
    }
    return 1;
}

unsigned int WorldLandscapeUplift(const WorldLandscape *landscape,
                                  long world_x_km, long world_y_km)
{
    unsigned int index;
    long dx;
    long dy;
    long length;
    long progress;
    long near_x;
    long near_y;
    long distance;
    long width;
    unsigned int uplift;
    unsigned int total;
    const WorldMountainRange *range;

    if (landscape == 0) return 0U;
    total = 0U;
    for (index = 0U; index < landscape->range_count; ++index) {
        range = &landscape->ranges[index];
        if (!range->active) continue;
        dx = range->end_x - range->start_x;
        dy = range->end_y - range->start_y;
        length = landscape_abs(dx) + landscape_abs(dy);
        if (length == 0L) continue;
        progress = ((world_x_km - range->start_x) * dx +
                    (world_y_km - range->start_y) * dy) / length;
        if (progress < 0L) progress = 0L;
        if (progress > length) progress = length;
        near_x = range->start_x + dx * progress / length;
        near_y = range->start_y + dy * progress / length;
        distance = landscape_abs(world_x_km - near_x) +
                   landscape_abs(world_y_km - near_y);
        width = 70L + (long)range->erosion_passes * 24L;
        if (distance >= width) continue;
        uplift = (unsigned int)((long)range->peak_meters *
                 (width - distance) / width);
        total += uplift;
    }
    return total;
}
