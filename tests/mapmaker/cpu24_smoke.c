/* One translation unit makes the initial CPU24 smoke test independent of
   multi-unit linking while still exercising the production core. */
#include "mapmaker.c"

int main(void)
{
    static Map map;
    MapCell cell;
    unsigned long first;

    if (!MapInitialize(&map, 12345UL, 7)) return 1;
    if (!MapSetCell(&map, MAP_WIDTH / 2, MAP_HEIGHT / 2,
                    MAKE_CELL(200, TERRAIN_ROCK))) return 8;
    if (!MapSmooth(&map, 1)) return 9;
    if (!MapSetCell(&map, MAP_WIDTH - 1, MAP_HEIGHT - 1,
                    MAKE_CELL(255, TERRAIN_SNOW))) return 2;
    if (!MapGetCell(&map, MAP_WIDTH - 1, MAP_HEIGHT - 1, &cell)) return 3;
    if (CELL_HEIGHT(cell) != 255U || CELL_TERRAIN(cell) != TERRAIN_SNOW) return 4;
    first = MapRandom(&map);
    if (!MapInitialize(&map, 12345UL, 7)) return 5;
    if (first != MapRandom(&map)) return 6;
    if (MapRandomBelow(&map, 17) >= 17U) return 7;
    return 0;
}
