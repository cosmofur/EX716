#ifndef WORLDLANDSCAPE_H
#define WORLDLANDSCAPE_H

/* Persistent, caller-owned macro landforms.  Coordinates are global km in
 * the same system used by MapSampleRegionalHeight. */
#define WORLD_LANDSCAPE_MAX_RANGES 12U

typedef struct WorldMountainRange {
    long start_x;
    long start_y;
    long end_x;
    long end_y;
    unsigned short peak_meters;
    unsigned char erosion_passes;
    unsigned char active;
} WorldMountainRange;

typedef struct WorldLandscape {
    unsigned long seed;
    unsigned char range_count;
    WorldMountainRange ranges[WORLD_LANDSCAPE_MAX_RANGES];
} WorldLandscape;

void WorldLandscapeInitialize(WorldLandscape *landscape, unsigned long seed);
int WorldLandscapeGenerate(WorldLandscape *landscape);
unsigned int WorldLandscapeUplift(const WorldLandscape *landscape,
                                  long world_x_km, long world_y_km);

#endif
