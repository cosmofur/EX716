#include <stdio.h>
#include <stdlib.h>

#include "mapmaker.h"

static int write_map(FILE *stream, const Map *map, const SettlementList *settlements)
{
    unsigned int index;

    if (fprintf(stream, "EX716MAP %u\n", (unsigned int)MAP_FORMAT_VERSION) < 0 ||
        fprintf(stream, "WIDTH=%u\nHEIGHT=%u\nSEED=%lu\nPRNG_STATE=%u\nTYPE=%u\nSETTLEMENTS=%u\n",
                (unsigned int)map->width, (unsigned int)map->height, map->seed,
                (unsigned int)map->prng_state, (unsigned int)map->type,
                settlements ? (unsigned int)settlements->count : 0U) < 0)
        return 0;
    if (settlements) {
        for (index = 0; index < settlements->count; ++index)
            if (fprintf(stream, "SITE=%u,%u,%u,%u\n",
                        (unsigned int)settlements->items[index].cell_index,
                        (unsigned int)settlements->items[index].type,
                        (unsigned int)settlements->items[index].size,
                        (unsigned int)settlements->items[index].tech_level) < 0)
                return 0;
    }
    if (fprintf(stream, "DATA=HEX16\n") < 0)
        return 0;
    for (index = 0; index < MAP_CELLS; ++index) {
        if (fprintf(stream, "%04X%s", (unsigned int)map->cells[index],
                    (index % 16U == 15U) ? "\n" : " ") < 0)
            return 0;
    }
    return ferror(stream) == 0;
}

static int write_u16(FILE *stream, unsigned int value)
{
    return fputc((int)(value & 0xffU), stream) != EOF &&
           fputc((int)((value >> 8) & 0xffU), stream) != EOF;
}

static int write_u32(FILE *stream, unsigned long value)
{
    return write_u16(stream, (unsigned int)(value & 0xffffUL)) &&
           write_u16(stream, (unsigned int)((value >> 16) & 0xffffUL));
}

static unsigned int color_component(unsigned int base, unsigned int height,
                                    unsigned int divisor)
{
    unsigned int value;

    value = base + height / divisor;
    return value > 255U ? 255U : value;
}

static void cell_rgb(MapCell cell, unsigned int *red, unsigned int *green,
                     unsigned int *blue)
{
    unsigned int height;

    height = CELL_HEIGHT(cell);
    if (CELL_TERRAIN(cell) & FEATURE_RIVER) {
        *red = color_component(0U, height, 16U);
        *green = color_component(40U, height, 5U);
        *blue = color_component(130U, height, 3U);
        return;
    }
    if (CELL_TERRAIN(cell) & FEATURE_SITE) {
        *red = 255U;
        *green = 210U;
        *blue = 30U;
        return;
    }
    if (CELL_TERRAIN(cell) & FEATURE_FOREST) {
        *red = color_component(0U, height, 12U);
        *green = color_component(25U, height, 3U);
        *blue = color_component(0U, height, 16U);
        return;
    }
    switch (CELL_TERRAIN(cell) & TERRAIN_GROUND_MASK) {
    case TERRAIN_GRASS:
        *red = color_component(12U, height, 6U);
        *green = color_component(55U, height, 2U);
        *blue = color_component(8U, height, 8U);
        break;
    case TERRAIN_SAND:
        *red = color_component(100U, height, 2U);
        *green = color_component(80U, height, 3U);
        *blue = color_component(20U, height, 12U);
        break;
    case TERRAIN_WATER:
        *red = color_component(0U, height, 12U);
        *green = color_component(20U, height, 5U);
        *blue = color_component(80U, height, 2U);
        break;
    case TERRAIN_ROCK:
        *red = height;
        *green = height;
        *blue = height;
        break;
    case TERRAIN_SNOW:
        *red = color_component(155U, height, 3U);
        *green = color_component(155U, height, 3U);
        *blue = color_component(170U, height, 3U);
        break;
    case TERRAIN_DIRT:
    default:
        *red = color_component(65U, height, 2U);
        *green = color_component(32U, height, 4U);
        *blue = color_component(12U, height, 12U);
        break;
    }
}

static int write_bmp(FILE *stream, const Map *map)
{
    unsigned long row_bytes;
    unsigned long image_bytes;
    int x;
    int y;
    unsigned int red;
    unsigned int green;
    unsigned int blue;
    unsigned long padding;

    row_bytes = ((unsigned long)map->width * 3UL + 3UL) & ~3UL;
    image_bytes = row_bytes * (unsigned long)map->height;
    if (fputc('B', stream) == EOF || fputc('M', stream) == EOF ||
        !write_u32(stream, 54UL + image_bytes) || !write_u32(stream, 0UL) ||
        !write_u32(stream, 54UL) || !write_u32(stream, 40UL) ||
        !write_u32(stream, (unsigned long)map->width) ||
        !write_u32(stream, (unsigned long)map->height) || !write_u16(stream, 1U) ||
        !write_u16(stream, 24U) || !write_u32(stream, 0UL) ||
        !write_u32(stream, image_bytes) || !write_u32(stream, 0UL) ||
        !write_u32(stream, 0UL) || !write_u32(stream, 0UL) || !write_u32(stream, 0UL))
        return 0;
    padding = row_bytes - (unsigned long)map->width * 3UL;
    for (y = MAP_HEIGHT - 1; y >= 0; --y) {
        for (x = 0; x < MAP_WIDTH; ++x) {
            cell_rgb(map->cells[y * MAP_WIDTH + x], &red, &green, &blue);
            if (fputc((int)blue, stream) == EOF || fputc((int)green, stream) == EOF ||
                fputc((int)red, stream) == EOF)
                return 0;
        }
        while (padding-- != 0)
            if (fputc(0, stream) == EOF)
                return 0;
        padding = row_bytes - (unsigned long)map->width * 3UL;
    }
    return ferror(stream) == 0;
}

int main(int argc, char **argv)
{
    Map map;
    unsigned long seed;
    long age;
    long ranges;
    long range;
    int forests;
    int settlements_added;
    Settlement settlements[16];
    SettlementList settlement_list;
    FILE *output;
    FILE *image;

    if (argc < 4 || argc > 6) {
        fprintf(stderr, "usage: %s SEED OUTPUT.map OUTPUT.bmp [AGE [RANGES]]\n", argv[0]);
        return 2;
    }
    seed = strtoul(argv[1], 0, 0);
    age = argc >= 5 ? strtol(argv[4], 0, 0) : 10;
    ranges = argc == 6 ? strtol(argv[5], 0, 0) : 4;
    if (age < 0 || age > 100 || ranges < 1 || ranges > 16 ||
        !MapInitialize(&map, seed, 0))
        return 1;
    for (range = 0; range < ranges; ++range)
        if (!MapAddMountainRange(&map, 100, 120, (int)age))
            return 1;
    SettlementListInitialize(&settlement_list, settlements, 16);
    if (!MapClassifyTerrain(&map, 24U) || MapAddRivers(&map, 80, 8) < 0 ||
        (forests = MapAddForests(&map, 30)) < 0 ||
        (settlements_added = MapAddSettlements(&map, &settlement_list, 12)) < 0)
        return 1;
    output = fopen(argv[2], "w");
    if (output == 0) {
        perror(argv[2]);
        return 1;
    }
    image = fopen(argv[3], "wb");
    if (image == 0) {
        perror(argv[3]);
        return 1;
    }
    if (!write_bmp(image, &map) || fclose(image) != 0) {
        fprintf(stderr, "could not write %s\n", argv[3]);
        return 1;
    }
    if (!write_map(output, &map, &settlement_list) || fclose(output) != 0) {
        fprintf(stderr, "could not write %s\n", argv[2]);
        return 1;
    }
    printf("seed=%lu age=%ld ranges=%ld forests=%d settlements=%d checksum=%08lX\n",
           seed, age, ranges, forests, settlements_added, MapChecksum(&map));
    return 0;
}
