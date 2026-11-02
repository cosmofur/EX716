#include "mapmath.h"

/* One quarter-wave table is sufficient: reflection and sign cover every
 * quadrant, while cosine is sine advanced by one quarter turn. */
static const unsigned short mapmath_sine_quarter[64] = {
    0, 804, 1608, 2410, 3212, 4011, 4808, 5602,
    6393, 7179, 7962, 8739, 9512, 10278, 11039, 11793,
    12539, 13279, 14010, 14732, 15446, 16151, 16846, 17530,
    18204, 18868, 19519, 20159, 20787, 21403, 22005, 22594,
    23170, 23731, 24279, 24811, 25329, 25832, 26319, 26790,
    27245, 27683, 28105, 28510, 28898, 29268, 29621, 29956,
    30273, 30571, 30852, 31113, 31356, 31580, 31785, 31971,
    32137, 32285, 32412, 32521, 32609, 32678, 32728, 32757
};

static int mapmath_quarter_value(unsigned int index)
{
    if (index >= 64U)
        return MAPMATH_TRIG_SCALE;
    return (int)mapmath_sine_quarter[index];
}

int MapMathSin(unsigned int angle)
{
    unsigned int quadrant;
    unsigned int index;
    int value;

    angle &= 255U;
    quadrant = angle >> 6;
    index = angle & 63U;
    if (quadrant == 0U)
        return mapmath_quarter_value(index);
    if (quadrant == 1U)
        return mapmath_quarter_value(64U - index);
    if (quadrant == 2U)
        return -mapmath_quarter_value(index);
    value = mapmath_quarter_value(64U - index);
    return -value;
}

int MapMathCos(unsigned int angle)
{
    return MapMathSin(angle + 64U);
}
