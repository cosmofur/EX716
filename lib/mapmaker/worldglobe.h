#ifndef WORLDGLOBE_H
#define WORLDGLOBE_H

#define WORLD_GLOBE_LATITUDE_RINGS 64U
#define WORLD_GLOBE_EQUATOR_CELLS 127U
#define WORLD_GLOBE_POLAR_CELLS 32U
#define WORLD_GLOBE_STORAGE_CELLS 5860U

/* Packed WorldGlobe cell: three-bit landform, two-bit moisture, two-bit
 * tectonic roughness, and a coast/boundary hint. */
#define WORLD_LANDFORM_MASK       0x07U
#define WORLD_MOISTURE_MASK       0x18U
#define WORLD_MOISTURE_SHIFT      3U
#define WORLD_ROUGHNESS_MASK      0x60U
#define WORLD_ROUGHNESS_SHIFT     5U
#define WORLD_FEATURE_COAST       0x80U

#define WORLD_DEEP_OCEAN          0U
#define WORLD_SHALLOW_SEA         1U
#define WORLD_COASTAL_LOWLAND     2U
#define WORLD_LOWLAND             3U
#define WORLD_UPLAND              4U
#define WORLD_PLATEAU             5U
#define WORLD_MOUNTAIN_BELT       6U
#define WORLD_POLAR_ICE           7U

typedef struct WorldGlobe {
    unsigned long seed;
    unsigned short cell_count;
    unsigned char row_width[WORLD_GLOBE_LATITUDE_RINGS];
    unsigned short row_start[WORLD_GLOBE_LATITUDE_RINGS + 1U];
    unsigned char *cells;
    unsigned short cell_capacity;
} WorldGlobe;

/* The caller owns the compact backing storage; no dynamic allocation occurs. */
int WorldGlobeInitialize(WorldGlobe *globe, unsigned char *storage,
                         unsigned short capacity, unsigned long seed);
int WorldGlobeGenerate(WorldGlobe *globe);
unsigned int WorldGlobeRowWidth(const WorldGlobe *globe, unsigned int row);
int WorldGlobeGetCell(const WorldGlobe *globe, unsigned int row,
                      unsigned int column, unsigned char *cell);

#endif
