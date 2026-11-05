#ifndef WORLDLANDSCAPE_H
#define WORLDLANDSCAPE_H

/* Persistent, caller-owned macro landforms.  Coordinates are global km in
 * the same system used by MapSampleRegionalHeight. */
#define WORLD_LANDSCAPE_MAX_RANGES 12U
#define WORLD_LANDSCAPE_ROWS 64U
#define WORLD_LANDSCAPE_COLUMNS 127U
#define WORLD_LANDSCAPE_CELLS (WORLD_LANDSCAPE_ROWS * WORLD_LANDSCAPE_COLUMNS)

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
    /* Persistent 300 km elevation raster plus caller-owned erosion scratch. */
    unsigned char heights[WORLD_LANDSCAPE_CELLS];
    unsigned char scratch[WORLD_LANDSCAPE_CELLS];
} WorldLandscape;

void WorldLandscapeInitialize(WorldLandscape *landscape, unsigned long seed);
int WorldLandscapeGenerate(WorldLandscape *landscape);
unsigned int WorldLandscapeUplift(const WorldLandscape *landscape,
                                  long world_x_km, long world_y_km);

#endif
