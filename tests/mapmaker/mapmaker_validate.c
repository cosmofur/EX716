#include <stdio.h>
#include "mapmaker.h"

int main(int argc, char **argv)
{
    Map map;
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
    FILE *input;
    Settlement sites[256];
    SettlementList site_list;

    if (argc != 2) {
        fprintf(stderr, "usage: %s MAP.map\n", argv[0]);
        return 2;
    }
    input = fopen(argv[1], "r");
    if (input == 0) {
        perror(argv[1]);
        return 1;
    }
    if (fscanf(input, "EX716MAP %u\nWIDTH=%u\nHEIGHT=%u\nSEED=%lu\nPRNG_STATE=%u\nTYPE=%u\nSETTLEMENTS=%u\n",
               &version, &width, &height, &seed, &state, &type,
               &settlement_count) != 7 ||
        version != MAP_FORMAT_VERSION || width != MAP_WIDTH || height != MAP_HEIGHT ||
        settlement_count > 256U || !MapInitialize(&map, seed, (unsigned short)type)) {
        fprintf(stderr, "%s: invalid MapMaker version or metadata\n", argv[1]);
        fclose(input);
        return 1;
    }
    map.prng_state = (unsigned short)state;
    SettlementListInitialize(&site_list, sites, 256);
    for (index = 0; index < settlement_count; ++index) {
        if (fscanf(input, "SITE=%u,%u,%u,%u\n", &site_index, &site_type,
                   &site_size, &site_tech) != 4 || site_index >= MAP_CELLS ||
            site_type > 0xffffU || site_size > 0xffffU || site_tech > 0xffffU ||
            MapFindSettlement(&site_list, (unsigned short)site_index) != 0) {
            fprintf(stderr, "%s: invalid settlement %u\n", argv[1], index);
            fclose(input);
            return 1;
        }
        sites[site_list.count].cell_index = (unsigned short)site_index;
        sites[site_list.count].type = (unsigned short)site_type;
        sites[site_list.count].size = (unsigned short)site_size;
        sites[site_list.count].tech_level = (unsigned short)site_tech;
        ++site_list.count;
    }
    if (fscanf(input, "DATA=HEX16\n") != 0) {
        fclose(input);
        return 1;
    }
    for (index = 0; index < MAP_CELLS; ++index) {
        if (fscanf(input, "%x", &value) != 1 || value > 0xffffU) {
            fprintf(stderr, "%s: invalid cell %u\n", argv[1], index);
            fclose(input);
            return 1;
        }
        map.cells[index] = (MapCell)value;
    }
    for (index = 0; index < site_list.count; ++index)
        if (!(CELL_TERRAIN(map.cells[sites[index].cell_index]) & FEATURE_SITE)) {
            fprintf(stderr, "%s: settlement %u lacks FEATURE_SITE\n", argv[1], index);
            fclose(input);
            return 1;
        }
    if (fclose(input) != 0)
        return 1;
    printf("valid width=%u height=%u settlements=%u checksum=%08lX\n", width,
           height, (unsigned int)site_list.count, MapChecksum(&map));
    return 0;
}
