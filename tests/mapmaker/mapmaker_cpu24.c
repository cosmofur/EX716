/* Fixed-configuration CPU24 front end. The loader will supply arguments
 * later; this intentionally needs none so it can run directly in cpu24.py. */
#include <stdio.h>

#include "mapmaker.h"

#define MAPMAKER_CPU24_SEED 12345UL
#ifdef MAPMAKER_CPU24_SMOKE
#define MAPMAKER_CPU24_AGE 1
#define MAPMAKER_CPU24_RANGES 1
#else
#define MAPMAKER_CPU24_AGE 10
#define MAPMAKER_CPU24_RANGES 4
#endif

static Map mapmaker_cpu24_map;
static Settlement mapmaker_cpu24_settlements[16];
static SettlementList mapmaker_cpu24_settlement_list;
static const unsigned char mapmaker_cpu24_magic[8] = {
    'E', 'X', '7', '1', '6', 'M', 'B', '1'
};

static int mapmaker_cpu24_write(FILE *stream)
{
    unsigned short settlement_count;

    settlement_count = mapmaker_cpu24_settlement_list.count;
    if (fwrite(mapmaker_cpu24_magic, sizeof mapmaker_cpu24_magic, 1U, stream) != 1U ||
        fwrite(&mapmaker_cpu24_map.width, 2U, 1U, stream) != 1U ||
        fwrite(&mapmaker_cpu24_map.height, 2U, 1U, stream) != 1U ||
        fwrite(&mapmaker_cpu24_map.type, 2U, 1U, stream) != 1U ||
        fwrite(&mapmaker_cpu24_map.format_version, 2U, 1U, stream) != 1U ||
        fwrite(&mapmaker_cpu24_map.seed, 4U, 1U, stream) != 1U ||
        fwrite(&mapmaker_cpu24_map.prng_state, 2U, 1U, stream) != 1U ||
        fwrite(&settlement_count, 2U, 1U, stream) != 1U ||
        (settlement_count != 0U &&
         fwrite(mapmaker_cpu24_settlement_list.items, sizeof(Settlement),
                settlement_count, stream) != settlement_count) ||
        fwrite(mapmaker_cpu24_map.cells, sizeof(MapCell), MAP_CELLS, stream) != MAP_CELLS)
        return 0;
    return 1;
}

int main(void)
{
    FILE *output;
    int range;

    if (!MapInitialize(&mapmaker_cpu24_map, MAPMAKER_CPU24_SEED, 0))
        return 1;
#ifndef MAPMAKER_CPU24_SMOKE
    for (range = 0; range < MAPMAKER_CPU24_RANGES; ++range)
        if (!MapAddMountainRange(&mapmaker_cpu24_map, 100, 120, MAPMAKER_CPU24_AGE))
            return 2;
#endif
    SettlementListInitialize(&mapmaker_cpu24_settlement_list,
                             mapmaker_cpu24_settlements, 16U);
#ifndef MAPMAKER_CPU24_SMOKE
    if (!MapClassifyTerrain(&mapmaker_cpu24_map, 24U) ||
        MapAddRivers(&mapmaker_cpu24_map, 80, 8) < 0 ||
        MapAddForests(&mapmaker_cpu24_map, 30) < 0 ||
        MapAddSettlements(&mapmaker_cpu24_map,
                          &mapmaker_cpu24_settlement_list, 12) < 0)
        return 3;
#endif
    output = fopen("MAPMAKER.MAP", "wb");
    if (output == 0)
        return 4;
    if (!mapmaker_cpu24_write(output)) {
        fclose(output);
        return 5;
    }
    return fclose(output) == 0 ? 0 : 6;
}
