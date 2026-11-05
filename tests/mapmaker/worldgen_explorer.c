#include <stdio.h>
#include <stdlib.h>

#include "worldgen.h"

static void draw_cell(WorldGenCell cell)
{
    switch (cell & WORLDGEN_CELL_SURFACE_MASK) {
    case WORLDGEN_SURFACE_OCEAN:
        fputs("\033[34m~", stdout);
        break;
    case WORLDGEN_SURFACE_LAND:
        fputs("\033[32m.", stdout);
        break;
    case WORLDGEN_SURFACE_HIGHLAND:
        fputs("\033[33m^", stdout);
        break;
    case WORLDGEN_SURFACE_MOUNTAIN:
        fputs("\033[37;1mM", stdout);
        break;
    default:
        fputc('?', stdout);
        break;
    }
}

int main(int argc, char **argv)
{
    static WorldGenCell storage[WORLDGEN_GLOBE_MAX_CELLS];
    WorldGenGlobe globe;
    unsigned long seed;
    unsigned int row;
    unsigned int column;
    unsigned int padding;
    WorldGenCell cell;

    seed = 0x12345678UL;
    if (argc > 1)
        seed = strtoul(argv[1], 0, 0);
    if (argc > 2) {
        fprintf(stderr, "usage: %s [seed]\n", argv[0]);
        return 2;
    }
    if (!WorldGenGlobeInitialize(&globe, storage, WORLDGEN_GLOBE_MAX_CELLS,
                                 seed, WORLDGEN_PROFILE_EARTHLIKE) ||
        !WorldGenGlobeEstablishSeaLevel(&globe, -2) ||
        !WorldGenGlobeGenerateContinents(&globe, 4U) ||
        !WorldGenGlobeGenerateRelief(&globe)) {
        fputs("worldgen explorer: generation failed\n", stderr);
        return 1;
    }
    printf("\033[0mWorldGen globe seed=%08lX  (%u active cells)\n",
           seed, globe.cell_count);
    fputs("\033[34m~ ocean  \033[32m. plains  \033[33m^ highland  "
          "\033[37;1mM mountain\033[0m\n\n", stdout);
    for (row = 0U; row < WORLDGEN_GLOBE_ROWS; ++row) {
        padding = (WORLDGEN_GLOBE_EQUATOR_WIDTH -
                   WorldGenGlobeRowWidth(&globe, row)) / 2U;
        for (column = 0U; column < padding; ++column) fputc(' ', stdout);
        for (column = 0U; column < WorldGenGlobeRowWidth(&globe, row);
             ++column) {
            WorldGenGlobeGetCell(&globe, row, column, &cell);
            draw_cell(cell);
        }
        fputs("\033[0m\n", stdout);
    }
    return 0;
}
