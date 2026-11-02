#ifndef WORLDMAP_H
#define WORLDMAP_H

#include "mapmaker.h"
#include "worldglobe.h"

#define MAP_WORLD_METERS_PER_CELL 1000U
#define MAP_WORLD_HEIGHT_METERS_PER_UNIT 5U

/* Generates one 127 km square at 1 km per cell.  Tile coordinates use this
 * 127 km grid and tile_y increases southward.  Features may be null. */
int MapGenerateWorldTile(Map *map, const WorldGlobe *globe,
                         long tile_x, long tile_y, MapFeatureList *features);

#endif
