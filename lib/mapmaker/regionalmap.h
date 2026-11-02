#ifndef REGIONALMAP_H
#define REGIONALMAP_H

#include "mapmaker.h"
#include "worldglobe.h"

#define MAP_REGIONAL_METERS_PER_CELL 5000U
#define MAP_REGIONAL_HEIGHT_METERS_PER_UNIT 25U

/* Generates one 635 km square regional tile.  tile_y increases southward.
 * Adjacent tiles query the same global raw field outside their own borders,
 * so the one-pass smoothing kernel does not clamp or introduce edge seams. */
int MapGenerateRegionalTile(Map *map, const WorldGlobe *globe,
                            long tile_x, long tile_y);

/* Samples the continuous regional field at global kilometre coordinates.
 * The returned height uses the regional map's 25 m height unit. */
unsigned int MapSampleRegionalHeight(const WorldGlobe *globe,
                                     long world_x_km, long world_y_km,
                                     unsigned char *world_cell);

#endif
