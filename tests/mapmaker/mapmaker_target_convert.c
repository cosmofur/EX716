/* Convert a CPU24 MAPMAKER.MAP binary export to normal MapMaker text. */
#include <stdio.h>
#include <string.h>

#include "mapmaker.h"

static int write_map(FILE *stream, const Map *map, const SettlementList *settlements)
{
    unsigned int index;

    if (fprintf(stream, "EX716MAP %u\n", (unsigned int)MAP_FORMAT_VERSION) < 0 ||
        fprintf(stream, "WIDTH=%u\nHEIGHT=%u\nSEED=%lu\nPRNG_STATE=%u\nTYPE=%u\nSETTLEMENTS=%u\n",
                (unsigned int)map->width, (unsigned int)map->height, map->seed,
                (unsigned int)map->prng_state, (unsigned int)map->type,
                (unsigned int)settlements->count) < 0)
        return 0;
    for (index = 0; index < settlements->count; ++index)
        if (fprintf(stream, "SITE=%u,%u,%u,%u\n",
                    (unsigned int)settlements->items[index].cell_index,
                    (unsigned int)settlements->items[index].type,
                    (unsigned int)settlements->items[index].size,
                    (unsigned int)settlements->items[index].tech_level) < 0)
            return 0;
    if (fprintf(stream, "DATA=HEX16\n") < 0)
        return 0;
    for (index = 0; index < MAP_CELLS; ++index)
        if (fprintf(stream, "%04X%s", (unsigned int)map->cells[index],
                    index % 16U == 15U ? "\n" : " ") < 0)
            return 0;
    return ferror(stream) == 0;
}

int main(int argc, char **argv)
{
    static const unsigned char magic[8] = {'E', 'X', '7', '1', '6', 'M', 'B', '1'};
    unsigned char found_magic[8];
    unsigned char header[16];
    Map map;
    Settlement settlements[16];
    SettlementList list;
    unsigned short count;
    FILE *input;
    FILE *output;

    if (argc != 3)
        return 2;
    input = fopen(argv[1], "rb");
    if (input == 0)
        return 3;
    if (fread(found_magic, sizeof found_magic, 1U, input) != 1U ||
        memcmp(found_magic, magic, sizeof magic) != 0 ||
        fread(header, sizeof header, 1U, input) != 1U)
        return 4;
    map.width = (unsigned short)(header[0] | ((unsigned short)header[1] << 8));
    map.height = (unsigned short)(header[2] | ((unsigned short)header[3] << 8));
    map.type = (unsigned short)(header[4] | ((unsigned short)header[5] << 8));
    map.format_version = (unsigned short)(header[6] | ((unsigned short)header[7] << 8));
    map.seed = (unsigned long)header[8] | ((unsigned long)header[9] << 8) |
               ((unsigned long)header[10] << 16) | ((unsigned long)header[11] << 24);
    map.prng_state = (unsigned short)(header[12] | ((unsigned short)header[13] << 8));
    count = (unsigned short)(header[14] | ((unsigned short)header[15] << 8));
    if (count > 16U || fread(settlements, sizeof(Settlement), count, input) != count ||
        fread(map.cells, sizeof(MapCell), MAP_CELLS, input) != MAP_CELLS ||
        fclose(input) != 0)
        return 4;
    if (map.width != MAP_WIDTH || map.height != MAP_HEIGHT ||
        map.format_version != MAP_FORMAT_VERSION)
        return 4;
    SettlementListInitialize(&list, settlements, 16U);
    list.count = count;
    output = fopen(argv[2], "w");
    if (output == 0)
        return 5;
    if (!write_map(output, &map, &list) || fclose(output) != 0)
        return 6;
    return 0;
}
