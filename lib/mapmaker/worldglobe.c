#include "worldglobe.h"
#include "mapmath.h"

#define WORLD_PLATE_COUNT 14U
#define WORLD_CONTINENT_COUNT 5U
#define WORLD_OCEAN_COUNT 6U

static unsigned long worldglobe_u32(unsigned long value)
{
    return value & 0xffffffffUL;
}

static unsigned long worldglobe_hash(unsigned long seed, unsigned long domain,
                                     unsigned long value)
{
    unsigned long result;

    result = worldglobe_u32(seed ^ domain);
    result = worldglobe_u32((result ^ value) * 16777619UL);
    result ^= result >> 13;
    result = worldglobe_u32(result * 0x5bd1e995UL);
    return worldglobe_u32(result ^ (result >> 15));
}

static int worldglobe_range(unsigned long seed, unsigned long domain,
                            unsigned long value, int low, int high)
{
    unsigned long span;

    span = (unsigned long)(high - low + 1);
    return low + (int)(worldglobe_hash(seed, domain, value) % span);
}

static unsigned int worldglobe_longitude(const WorldGlobe *globe,
                                         unsigned int row, unsigned int column)
{
    return (column * 256U) / globe->row_width[row];
}

static int worldglobe_longitude_delta(unsigned int first, unsigned int second)
{
    int delta;

    delta = (int)first - (int)second;
    if (delta > 127)
        delta -= 256;
    if (delta < -128)
        delta += 256;
    return delta;
}

static int worldglobe_abs(int value)
{
    return value < 0 ? -value : value;
}

/* The overview spans roughly +/-75 degrees.  Its 256-angle equivalent is
 * 106 units wide; this returns a signed latitude angle for a ring. */
static int worldglobe_latitude_angle(unsigned int row)
{
    return ((int)(row * 106U) / 63) - 53;
}

static int worldglobe_distance(const WorldGlobe *globe, unsigned int row,
                               unsigned int column, int other_row,
                               unsigned int other_longitude)
{
    int north_south;
    int east_west;
    int cosine;
    unsigned int longitude;

    longitude = worldglobe_longitude(globe, row, column);
    north_south = worldglobe_abs((int)row - other_row) * 4;
    east_west = worldglobe_abs(worldglobe_longitude_delta(longitude,
                                                           other_longitude));
    cosine = MapMathCos((unsigned int)worldglobe_latitude_angle(row));
    east_west = (east_west * cosine) / MAPMATH_TRIG_SCALE;
    return north_south + east_west;
}

static unsigned int worldglobe_index(const WorldGlobe *globe,
                                     unsigned int row, unsigned int column)
{
    return (unsigned int)(globe->row_start[row] +
                          column % globe->row_width[row]);
}

int WorldGlobeInitialize(WorldGlobe *globe, unsigned char *storage,
                         unsigned short capacity, unsigned long seed)
{
    unsigned int row;
    unsigned int distance;
    unsigned int cosine;
    unsigned int width;

    if (globe == 0 || storage == 0)
        return 0;
    globe->seed = worldglobe_u32(seed);
    globe->cells = storage;
    globe->cell_capacity = capacity;
    globe->row_start[0] = 0;
    for (row = 0; row < WORLD_GLOBE_LATITUDE_RINGS; ++row) {
        distance = row < 32U ? 63U - row * 2U : row * 2U - 63U;
        cosine = (unsigned int)MapMathCos((distance * 64U + 31U) / 63U);
        width = WORLD_GLOBE_POLAR_CELLS +
                (95U * cosine + MAPMATH_TRIG_SCALE / 2U) / MAPMATH_TRIG_SCALE;
        globe->row_width[row] = (unsigned char)width;
        globe->row_start[row + 1U] =
            (unsigned short)(globe->row_start[row] + width);
    }
    globe->cell_count = globe->row_start[WORLD_GLOBE_LATITUDE_RINGS];
    return globe->cell_count <= capacity;
}

unsigned int WorldGlobeRowWidth(const WorldGlobe *globe, unsigned int row)
{
    if (globe == 0 || row >= WORLD_GLOBE_LATITUDE_RINGS)
        return 0;
    return globe->row_width[row];
}

int WorldGlobeGetCell(const WorldGlobe *globe, unsigned int row,
                      unsigned int column, unsigned char *cell)
{
    if (globe == 0 || cell == 0 || globe->cells == 0 ||
        row >= WORLD_GLOBE_LATITUDE_RINGS || globe->cell_count == 0)
        return 0;
    *cell = globe->cells[worldglobe_index(globe, row, column)];
    return 1;
}

int WorldGlobeGenerate(WorldGlobe *globe)
{
    unsigned int row;
    unsigned int column;
    unsigned int plate;
    unsigned int continent;
    unsigned int ocean;
    unsigned int longitude;
    unsigned int nearest_plate;
    int nearest_distance;
    int second_distance;
    int distance;
    int continent_score;
    int elevation;
    int base_height;
    int boundary;
    int interaction;
    int influence;
    int moisture;
    int roughness;
    unsigned int landform;
    unsigned char cell;

    if (globe == 0 || globe->cells == 0 || globe->cell_count == 0 ||
        globe->cell_count > globe->cell_capacity)
        return 0;
    for (row = 0; row < WORLD_GLOBE_LATITUDE_RINGS; ++row) {
        for (column = 0; column < globe->row_width[row]; ++column) {
            longitude = worldglobe_longitude(globe, row, column);
            continent_score = 0;
            for (continent = 0; continent < WORLD_CONTINENT_COUNT; ++continent) {
                distance = worldglobe_distance(globe, row, column,
                    worldglobe_range(globe->seed, 0x434f4e54UL, continent, 8, 55),
                    (unsigned int)worldglobe_range(globe->seed, 0x434f4e4cUL,
                                                   continent, 0, 255));
                influence = 48 - distance;
                if (influence > 0)
                    continent_score += influence;
            }
            for (ocean = 0; ocean < WORLD_OCEAN_COUNT; ++ocean) {
                distance = worldglobe_distance(globe, row, column,
                    worldglobe_range(globe->seed, 0x4f434541UL, ocean, 2, 61),
                    (unsigned int)worldglobe_range(globe->seed, 0x4f43454cUL,
                                                   ocean, 0, 255));
                influence = 42 - distance;
                if (influence > 0)
                    continent_score -= influence;
            }
            continent_score += worldglobe_range(globe->seed, 0x434f4153UL,
                                                (unsigned long)row * 257UL + longitude,
                                                -6, 6);
            nearest_plate = 0;
            nearest_distance = 32767;
            second_distance = 32767;
            for (plate = 0; plate < WORLD_PLATE_COUNT; ++plate) {
                distance = worldglobe_distance(globe, row, column,
                    worldglobe_range(globe->seed, 0x504c4154UL, plate, 1, 62),
                    (unsigned int)worldglobe_range(globe->seed, 0x504c4f4eUL,
                                                   plate, 0, 255));
                if (distance < nearest_distance) {
                    second_distance = nearest_distance;
                    nearest_distance = distance;
                    nearest_plate = plate;
                } else if (distance < second_distance) {
                    second_distance = distance;
                }
            }
            base_height = worldglobe_range(globe->seed, 0x504c4847UL,
                                            nearest_plate, -8, 8);
            elevation = continent_score / 3 + base_height;
            boundary = second_distance - nearest_distance;
            roughness = 0;
            if (boundary <= 5) {
                interaction = worldglobe_range(globe->seed, 0x494e5445UL,
                                                nearest_plate, 0, 2);
                if (interaction == 0) {
                    elevation += 22 - boundary * 2;
                    roughness = 3;
                } else if (interaction == 1) {
                    elevation -= 12 - boundary;
                    roughness = 1;
                } else {
                    elevation += 6;
                    roughness = 2;
                }
            }
            if (row < 3U || row > 60U)
                landform = WORLD_POLAR_ICE;
            else if (elevation < -18)
                landform = WORLD_DEEP_OCEAN;
            else if (elevation < -5)
                landform = WORLD_SHALLOW_SEA;
            else if (elevation < 3)
                landform = WORLD_COASTAL_LOWLAND;
            else if (elevation < 12)
                landform = WORLD_LOWLAND;
            else if (elevation < 24)
                landform = WORLD_UPLAND;
            else if (elevation < 38)
                landform = WORLD_PLATEAU;
            else
                landform = WORLD_MOUNTAIN_BELT;
            moisture = 3 - (worldglobe_abs((int)row - 31) * 3) / 32;
            if (landform <= WORLD_SHALLOW_SEA)
                moisture = 3;
            if (roughness == 3 && moisture > 0)
                --moisture;
            if (moisture < 0)
                moisture = 0;
            cell = (unsigned char)(landform | ((unsigned int)moisture <<
                                                WORLD_MOISTURE_SHIFT) |
                                 ((unsigned int)roughness <<
                                                WORLD_ROUGHNESS_SHIFT));
            if (landform == WORLD_COASTAL_LOWLAND || boundary <= 2)
                cell |= WORLD_FEATURE_COAST;
            globe->cells[worldglobe_index(globe, row, column)] = cell;
        }
    }
    return 1;
}
