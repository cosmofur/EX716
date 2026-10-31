#define MAP_WIDTH 7
#define MAP_HEIGHT 7
#include "mapmaker.c"

static int shared_global = 40;
static Map map;

int shared_global_value(void)
{
    return shared_global;
}

int banked_driver(void)
{
    if (!MapSetCell(&map, 1U, 1U, MAKE_CELL(99U, TERRAIN_ROCK)))
        return 1;
#ifdef BANKED_SMOKE_MAP_SMOOTH
    /* Deliberately exercises the known failing banked far-row-copy path. */
    if (!MapSmooth(&map, 1))
        return 2;
#endif
    return shared_global_value() + 2;
}
