#include "mapmaker.c"

int far_target(void);
static Map map;

int far_target_impl(void)
{
    return 42;
}

int main(void)
{
    map.width = MAP_WIDTH;
    return 0;
}
