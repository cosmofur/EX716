#ifndef LOCALMAP_H
#define LOCALMAP_H

#include "mapmaker.h"
#include "worldglobe.h"

/* One unit is half a metre.  These are the supported local map resolutions. */
#define MAP_LOCAL_CELL_HALF_METERS_5KM 10000U
#define MAP_LOCAL_CELL_HALF_METERS_1KM 2000U
#define MAP_LOCAL_CELL_HALF_METERS_500M 1000U
#define MAP_LOCAL_CELL_HALF_METERS_100M 200U
#define MAP_LOCAL_CELL_HALF_METERS_50M  100U
#define MAP_LOCAL_CELL_HALF_METERS_20M  40U
#define MAP_LOCAL_CELL_HALF_METERS_10M 20U
#define MAP_LOCAL_CELL_HALF_METERS_5M  10U
#define MAP_LOCAL_CELL_HALF_METERS_2M  4U
#define MAP_LOCAL_CELL_HALF_METERS_1M  2U
#define MAP_LOCAL_CELL_HALF_METERS_0_5M 1U

#define MAP_LOCAL_PROFILE_WILDERNESS_SITE 1U
#define MAP_LOCAL_PROFILE_SETTLEMENT       2U
#define MAP_LOCAL_PROFILE_TACTICAL_OUTDOOR 3U
#define MAP_LOCAL_PROFILE_BUILDING_INTERIOR 4U
#define MAP_LOCAL_PROFILE_CAVE             5U
#define MAP_LOCAL_PROFILE_SIMULATION       6U

/* Generates a caller-owned local map whose upper-left corner is the supplied
 * canonical physical position.  The first implementation fully develops the
 * outdoor site profiles; the other profile values reserve stable API meanings
 * for later fine-scale content. */
int MapGenerateLocalMap(Map *map, const WorldGlobe *globe,
                        long origin_x_half_meters,
                        long origin_y_half_meters,
                        unsigned short cell_half_meters,
                        unsigned short profile, MapFeatureList *features);

#endif
