#ifndef MAPMATH_H
#define MAPMATH_H

/* Angles use 256 units per revolution.  Results are signed Q15 values. */
#define MAPMATH_ANGLE_FULL 256U
#define MAPMATH_TRIG_SCALE 32767

int MapMathSin(unsigned int angle);
int MapMathCos(unsigned int angle);

#endif
