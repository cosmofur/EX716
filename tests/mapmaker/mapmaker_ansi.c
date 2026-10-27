#include <stdio.h>

#include "mapmaker.h"

/* The xterm 256-color cube is six values per component.  MapMaker uses this
   four-value subset (0, 2, 4, 5), yielding a predictable 64-color RGB table. */
static const unsigned char ansi_component[4] = { 0, 2, 4, 5 };

static int read_map(FILE *input, Map *map)
{
    unsigned int version;
    unsigned int width;
    unsigned int height;
    unsigned int type;
    unsigned int state;
    unsigned int value;
    unsigned int index;
    unsigned int settlement_count;
    unsigned int site_index;
    unsigned int site_type;
    unsigned int site_size;
    unsigned int site_tech;
    unsigned long seed;

    if (fscanf(input, "EX716MAP %u\nWIDTH=%u\nHEIGHT=%u\nSEED=%lu\nPRNG_STATE=%u\nTYPE=%u\nSETTLEMENTS=%u\n",
               &version, &width, &height, &seed, &state, &type,
               &settlement_count) != 7 ||
        version != MAP_FORMAT_VERSION || width != MAP_WIDTH || height != MAP_HEIGHT ||
        settlement_count > MAP_CELLS || !MapInitialize(map, seed, (unsigned short)type))
        return 0;
    map->prng_state = (unsigned short)state;
    for (index = 0; index < settlement_count; ++index)
        if (fscanf(input, "SITE=%u,%u,%u,%u\n", &site_index, &site_type,
                   &site_size, &site_tech) != 4 || site_index >= MAP_CELLS)
            return 0;
    if (fscanf(input, "DATA=HEX16\n") != 0)
        return 0;
    for (index = 0; index < MAP_CELLS; ++index) {
        if (fscanf(input, "%x", &value) != 1 || value > 0xffffU)
            return 0;
        map->cells[index] = (MapCell)value;
    }
    return 1;
}

static unsigned int shade_from_height(unsigned int height)
{
    if (height < 64U) return 0;
    if (height < 128U) return 1;
    if (height < 192U) return 2;
    return 3;
}

static unsigned int ansi_color(MapCell cell)
{
    unsigned int shade;
    unsigned int ground;
    unsigned int red;
    unsigned int green;
    unsigned int blue;

    shade = shade_from_height(CELL_HEIGHT(cell));
    ground = CELL_TERRAIN(cell) & TERRAIN_GROUND_MASK;
    if (CELL_TERRAIN(cell) & FEATURE_RIVER)
        return shade >= 2 ? 51U : 45U;
    if (CELL_TERRAIN(cell) & FEATURE_SITE)
        return 226U;
    if (CELL_TERRAIN(cell) & FEATURE_FOREST)
        return 22U + 6U * shade;
    /* xterm provides a separate 24-step neutral grayscale ramp.  Mountains
       need finer elevation feedback than the four neutral entries in the
       4x4x4 terrain palette can provide. */
    if (ground == TERRAIN_ROCK || ground == TERRAIN_SNOW)
        return 232U + (CELL_HEIGHT(cell) * 23U) / 255U;
    red = 0;
    green = 0;
    blue = 0;
    switch (ground) {
    case TERRAIN_GRASS:
        red = shade == 3 ? 1 : 0;
        green = shade < 3 ? shade + 1 : 3;
        blue = shade == 3 ? 1 : 0;
        break;
    case TERRAIN_SAND:
        red = shade;
        green = shade > 0 ? shade - 1 : 0;
        blue = 0;
        break;
    case TERRAIN_WATER:
        red = shade == 3 ? 1 : 0;
        green = shade;
        blue = shade < 3 ? shade + 1 : 3;
        break;
    case TERRAIN_DIRT:
    default:
        red = shade;
        green = shade > 1 ? shade - 2 : 0;
        blue = 0;
        break;
    }
    return 16U + 36U * ansi_component[red] +
           6U * ansi_component[green] + ansi_component[blue];
}

int main(int argc, char **argv)
{
    Map map;
    FILE *input;
    unsigned int x;
    unsigned int y;

    if (argc != 2) {
        fprintf(stderr, "usage: %s MAP.map\n", argv[0]);
        return 2;
    }
    input = fopen(argv[1], "r");
    if (input == 0) {
        perror(argv[1]);
        return 1;
    }
    if (!read_map(input, &map) || fclose(input) != 0) {
        fprintf(stderr, "%s: invalid MapMaker map\n", argv[1]);
        return 1;
    }
    for (y = 0; y < MAP_HEIGHT; ++y) {
        for (x = 0; x < MAP_WIDTH; ++x)
            printf("\033[48;5;%um ", ansi_color(map.cells[y * MAP_WIDTH + x]));
        printf("\033[0m\n");
    }
    return 0;
}
