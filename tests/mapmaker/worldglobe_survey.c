#include <stdio.h>
#include "worldglobe.h"

static unsigned int land_and_continents(const WorldGlobe *globe,
                                        unsigned int *continents)
{
    static unsigned char seen[WORLD_GLOBE_STORAGE_CELLS];
    static unsigned short queue[WORLD_GLOBE_STORAGE_CELLS];
    unsigned int row, column, index, head, tail, land, count, width;
    unsigned int current_row, current_column, current_index;
    unsigned char cell;
    long candidate;
    int dr, dc;

    for (index = 0U; index < globe->cell_count; ++index) seen[index] = 0U;
    land = count = 0U;
    for (row = 0U; row < WORLD_GLOBE_LATITUDE_RINGS; ++row)
        for (column = 0U; column < WorldGlobeRowWidth(globe, row); ++column) {
            index = globe->row_start[row] + column;
            WorldGlobeGetCell(globe, row, column, &cell);
            if ((cell & WORLD_LANDFORM_MASK) > WORLD_SHALLOW_SEA) ++land;
            if (seen[index] || (cell & WORLD_LANDFORM_MASK) <= WORLD_SHALLOW_SEA)
                continue;
            head = tail = 0U; queue[tail++] = (unsigned short)index;
            seen[index] = 1U;
            while (head < tail) {
                current_index = queue[head++];
                for (dr = -1; dr <= 1; ++dr) for (dc = -1; dc <= 1; ++dc) {
                    if (dr == 0 && dc == 0) continue;
                    current_row = 0U;
                    while (current_row + 1U < WORLD_GLOBE_LATITUDE_RINGS &&
                           globe->row_start[current_row + 1U] <= current_index) ++current_row;
                    width = WorldGlobeRowWidth(globe, current_row);
                    current_column = current_index - globe->row_start[current_row];
                    candidate = (long)current_row + dr;
                    if (candidate < 0L || candidate >= (long)WORLD_GLOBE_LATITUDE_RINGS) continue;
                    current_column = (current_column * WorldGlobeRowWidth(globe, (unsigned int)candidate)) / width;
                    current_column = (unsigned int)((long)current_column + dc +
                             WorldGlobeRowWidth(globe, (unsigned int)candidate)) %
                             WorldGlobeRowWidth(globe, (unsigned int)candidate);
                    index = globe->row_start[(unsigned int)candidate] + current_column;
                    WorldGlobeGetCell(globe, (unsigned int)candidate, current_column, &cell);
                    if (!seen[index] && (cell & WORLD_LANDFORM_MASK) > WORLD_SHALLOW_SEA) {
                        seen[index] = 1U; queue[tail++] = (unsigned short)index;
                    }
                }
            }
            /* Small isolated islands do not count as continents. */
            if (tail >= 30U) ++count;
        }
    *continents = count;
    return land;
}

int main(void)
{
    static unsigned char storage[WORLD_GLOBE_STORAGE_CELLS];
    static const unsigned char presets[][4] = {
        { 5U, 6U, 48U, 42U }, { 4U, 6U, 35U, 60U },
        { 5U, 7U, 38U, 60U }, { 4U, 7U, 40U, 58U }
    };
    WorldGlobe globe;
    unsigned int preset, run, land, continents, successes;
    unsigned long total_land, total_continents;
    unsigned long seed;
    for (preset = 0U; preset < 4U; ++preset) {
        successes = 0U;
        total_land = 0UL;
        total_continents = 0UL;
        for (run = 0U; run < 10U; ++run) {
            seed = 1000UL + run * 7919UL;
            WorldGlobeInitializeWithContinents(&globe, storage,
                                               WORLD_GLOBE_STORAGE_CELLS, seed,
                                               presets[preset][0]);
            WorldGlobeSetFormation(&globe, presets[preset][0], presets[preset][1],
                                   presets[preset][2], presets[preset][3]);
            WorldGlobeGenerate(&globe);
            land = land_and_continents(&globe, &continents);
            total_land += land * 100UL / globe.cell_count;
            total_continents += continents;
            if (land * 100U >= globe.cell_count * 40U &&
                land * 100U <= globe.cell_count * 60U &&
                continents >= 3U && continents <= 5U) ++successes;
        }
        printf("continents=%u oceans=%u radii=%u/%u: %u/10 target, avg land=%lu%%, avg components=%lu\n",
               presets[preset][0], presets[preset][1], presets[preset][2],
               presets[preset][3], successes, total_land / 10UL,
               total_continents / 10UL);
    }
    return 0;
}
