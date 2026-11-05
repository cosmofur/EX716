/* Interactive host visualizer for the portable MapMaker local-map API. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <sys/ioctl.h>

#include "localmap.h"
#include "regionalmap.h"

static struct termios explorer_saved_terminal;
static int explorer_terminal_is_raw = 0;

static void explorer_restore_terminal(void)
{
    if (explorer_terminal_is_raw)
        (void)tcsetattr(0, TCSANOW, &explorer_saved_terminal);
    explorer_terminal_is_raw = 0;
    printf("\033[0m\033[?25h\n");
    fflush(stdout);
}

static int explorer_set_raw_terminal(void)
{
    struct termios raw;

    if (tcgetattr(0, &explorer_saved_terminal) != 0)
        return 0;
    raw = explorer_saved_terminal;
    raw.c_lflag &= (tcflag_t)~(ICANON | ECHO);
    raw.c_iflag &= (tcflag_t)~(ICRNL | IXON);
    /* Keep normal output processing: terminals convert the renderer's '\n'
     * into CR/LF.  Raw input does not require disabling OPOST, and doing so
     * makes successive map rows begin at the previous column. */
    raw.c_cc[VMIN] = 1;
    raw.c_cc[VTIME] = 0;
    if (tcsetattr(0, TCSANOW, &raw) != 0)
        return 0;
    explorer_terminal_is_raw = 1;
    return 1;
}

static void explorer_terminal_size(unsigned int *columns, unsigned int *rows)
{
    struct winsize size;

    *columns = 80U;
    *rows = 24U;
    if (ioctl(1, TIOCGWINSZ, &size) == 0) {
        if (size.ws_col >= 20U) *columns = size.ws_col;
        if (size.ws_row >= 8U) *rows = size.ws_row;
    }
}

static void explorer_glyph_size(unsigned short scale, unsigned int *width,
                                unsigned int *height)
{
    if (scale == MAP_LOCAL_CELL_HALF_METERS_0_5M) {
        *width = 6U;
        *height = 3U;
    } else if (scale == MAP_LOCAL_CELL_HALF_METERS_1M) {
        *width = 4U;
        *height = 2U;
    } else if (scale == MAP_LOCAL_CELL_HALF_METERS_2M) {
        *width = 2U;
        *height = 1U;
    } else {
        *width = 1U;
        *height = 1U;
    }
}

static const char *explorer_scale_name(unsigned short scale)
{
    switch (scale) {
    case MAP_LOCAL_CELL_HALF_METERS_5KM: return "5 km";
    case MAP_LOCAL_CELL_HALF_METERS_1KM: return "1 km";
    case MAP_LOCAL_CELL_HALF_METERS_500M: return "500 m";
    case MAP_LOCAL_CELL_HALF_METERS_100M: return "100 m";
    case MAP_LOCAL_CELL_HALF_METERS_50M: return "50 m";
    case MAP_LOCAL_CELL_HALF_METERS_20M: return "20 m";
    case MAP_LOCAL_CELL_HALF_METERS_0_5M: return "0.5 m";
    case MAP_LOCAL_CELL_HALF_METERS_1M: return "1 m";
    case MAP_LOCAL_CELL_HALF_METERS_2M: return "2 m";
    case MAP_LOCAL_CELL_HALF_METERS_5M: return "5 m";
    default: return "10 m";
    }
}

/* ANSI 256-colour relief ramp: damp lowlands through upland grass and dry
 * slopes to stone and snow.  Glyphs remain meaningful when colour is absent. */
static const char *explorer_relief_color(unsigned int height)
{
    if (height >= 224U) return "\033[38;5;255m";
    if (height >= 192U) return "\033[38;5;250m";
    if (height >= 144U) return "\033[38;5;180m";
    if (height >= 96U) return "\033[38;5;107m";
    if (height >= 48U) return "\033[38;5;71m";
    return "\033[38;5;28m";
}

static unsigned int explorer_matching_neighbours(const Map *map,
                                                 unsigned int x, unsigned int y,
                                                 unsigned int feature)
{
    unsigned int count;
    unsigned int nx;
    unsigned int ny;
    int dx;
    int dy;

    count = 0U;
    for (dy = -1; dy <= 1; ++dy) {
        for (dx = -1; dx <= 1; ++dx) {
            if (dx == 0 && dy == 0) continue;
            if ((int)x + dx < 0 || (int)y + dy < 0) continue;
            nx = (unsigned int)((int)x + dx);
            ny = (unsigned int)((int)y + dy);
            if (nx >= MAP_WIDTH || ny >= MAP_HEIGHT) continue;
            if (feature == TERRAIN_WATER) {
                if ((CELL_TERRAIN(map->cells[ny * MAP_WIDTH + nx]) &
                     TERRAIN_GROUND_MASK) == TERRAIN_WATER) ++count;
            } else if (CELL_TERRAIN(map->cells[ny * MAP_WIDTH + nx]) & feature)
                ++count;
        }
    }
    return count;
}

static void explorer_style(const Map *map, unsigned int x, unsigned int y,
                           int show_relief, char *glyph, const char **color)
{
    unsigned int terrain;
    unsigned int neighbours;
    unsigned int height;
    long elevation;
    MapCell cell;

    cell = map->cells[y * MAP_WIDTH + x];
    terrain = CELL_TERRAIN(cell);
    height = CELL_HEIGHT(cell);
    elevation = map->elevation_datum_meters + (long)height;
    if (show_relief && (terrain & TERRAIN_GROUND_MASK) != TERRAIN_WATER) {
        if (height >= 192U) {
            *glyph = '^'; *color = explorer_relief_color(height);
        } else if (height >= 144U) {
            *glyph = 'A'; *color = explorer_relief_color(height);
        } else if (height >= 96U) {
            *glyph = ','; *color = explorer_relief_color(height);
        } else if (height >= 48U) {
            *glyph = ':'; *color = explorer_relief_color(height);
        } else {
            *glyph = '.'; *color = explorer_relief_color(height);
        }
        return;
    }
    if (terrain & FEATURE_RIVER) {
        *glyph = '~';
        *color = "\033[1;34m";
        return;
    }
    if (terrain & FEATURE_FOREST) {
        neighbours = explorer_matching_neighbours(map, x, y, FEATURE_FOREST);
        *glyph = neighbours >= 6U ? 'T' : 't';
        if (elevation >= 3000L)
            *color = "\033[1;33m";
        else if (elevation >= 1900L)
            *color = "\033[1;32m";
        else
            *color = "\033[0;32m";
        return;
    }
    if (terrain & FEATURE_ROAD) {
        *glyph = '=';
        *color = "\033[1;33m";
        return;
    }
    switch (terrain & TERRAIN_GROUND_MASK) {
    case TERRAIN_WATER:
        neighbours = explorer_matching_neighbours(map, x, y, TERRAIN_WATER);
        *glyph = neighbours >= 7U ? '~' : '.';
        *color = neighbours >= 7U ? "\033[0;34m" : "\033[1;36m"; break;
    case TERRAIN_ROCK:
        if (height >= 192U) {
            *glyph = '^'; *color = "\033[1;37m";
        } else if (height >= 112U) {
            *glyph = '*'; *color = "\033[1;37m";
        } else {
            *glyph = '.'; *color = "\033[0;37m";
        }
        break;
    case TERRAIN_SNOW:
        *glyph = '^'; *color = "\033[1;37m"; break;
    case TERRAIN_DIRT:
    case TERRAIN_SAND:
        *glyph = ':'; *color = "\033[0;33m"; break;
    case TERRAIN_PAVEMENT:
        *glyph = '='; *color = "\033[1;33m"; break;
    case TERRAIN_BUILDING:
        *glyph = '#'; *color = "\033[1;35m"; break;
    default:
        *glyph = height >= 144U ? ',' :
                 (height >= 96U ? ':' : '"');
        *color = explorer_relief_color(height);
        break;
    }
}

static int explorer_generate_centered(Map *map, const WorldGlobe *globe,
                                      long player_x, long player_y,
                                      unsigned short scale)
{
    return MapGenerateLocalMap(map, globe,
                               player_x - (long)(MAP_WIDTH / 2U) * scale,
                               player_y - (long)(MAP_HEIGHT / 2U) * scale,
                               scale, MAP_LOCAL_PROFILE_WILDERNESS_SITE, 0);
}

static int explorer_is_water(const Map *map, unsigned int x, unsigned int y)
{
    return (CELL_TERRAIN(map->cells[y * MAP_WIDTH + x]) &
            TERRAIN_GROUND_MASK) == TERRAIN_WATER;
}

static int explorer_try_land_start(Map *map, const WorldGlobe *globe,
                                   unsigned short scale, long candidate_x,
                                   long candidate_y, long *player_x,
                                   long *player_y)
{
    if (MapSampleRegionalHeight(globe, candidate_x / 2000L,
                                candidate_y / 2000L, 0) <= 31U ||
        !explorer_generate_centered(map, globe, candidate_x, candidate_y,
                                   scale) ||
        explorer_is_water(map, MAP_WIDTH / 2U, MAP_HEIGHT / 2U))
        return 0;
    *player_x = candidate_x;
    *player_y = candidate_y;
    return 1;
}

/* Search a compact square spiral around canonical world centre.  The cheap
 * regional-height check avoids constructing full local maps for ocean. */
static int explorer_find_land_start(Map *map, const WorldGlobe *globe,
                                    unsigned short scale, long *player_x,
                                    long *player_y)
{
    int radius;
    int offset;
    long candidate_x;
    long candidate_y;

    if (explorer_try_land_start(map, globe, scale, 0L, 0L,
                                 player_x, player_y))
        return 1;
    for (radius = 1; radius <= 32; ++radius) {
        for (offset = -radius; offset <= radius; ++offset) {
            candidate_x = (long)offset * 10000L;
            candidate_y = (long)-radius * 10000L;
            if (explorer_try_land_start(map, globe, scale, candidate_x,
                                         candidate_y, player_x, player_y))
                return 1;
            candidate_y = (long)radius * 10000L;
            if (explorer_try_land_start(map, globe, scale, candidate_x,
                                         candidate_y, player_x, player_y))
                return 1;
        }
        for (offset = -radius + 1; offset < radius; ++offset) {
            candidate_x = (long)-radius * 10000L;
            candidate_y = (long)offset * 10000L;
            if (explorer_try_land_start(map, globe, scale, candidate_x,
                                         candidate_y, player_x, player_y))
                return 1;
            candidate_x = (long)radius * 10000L;
            if (explorer_try_land_start(map, globe, scale, candidate_x,
                                         candidate_y, player_x, player_y))
                return 1;
        }
    }
    return 0;
}

static int explorer_find_range_land(const WorldGlobe *globe, long center_x,
                                    long center_y, long *player_x,
                                    long *player_y)
{
    int radius;
    int dx;
    int dy;
    long candidate_x;
    long candidate_y;
    unsigned char cell;

    for (radius = 0; radius <= 16; ++radius)
        for (dy = -radius; dy <= radius; ++dy)
            for (dx = -radius; dx <= radius; ++dx) {
                if (radius != 0 && dx != -radius && dx != radius &&
                    dy != -radius && dy != radius) continue;
                candidate_x = center_x + (long)dx * 10000L;
                candidate_y = center_y + (long)dy * 10000L;
                if (MapSampleRegionalHeight(globe, candidate_x / 2000L,
                    candidate_y / 2000L, &cell) > 31U &&
                    (cell & WORLD_LANDFORM_MASK) > WORLD_SHALLOW_SEA) {
                    *player_x = candidate_x;
                    *player_y = candidate_y;
                    return 1;
                }
            }
    return 0;
}

static void explorer_draw(const Map *map, unsigned short scale,
                          unsigned int scale_index, int show_relief)
{
    unsigned int columns;
    unsigned int rows;
    unsigned int glyph_width;
    unsigned int glyph_height;
    unsigned int visible_width;
    unsigned int visible_height;
    unsigned int first_x;
    unsigned int first_y;
    unsigned int map_x;
    unsigned int map_y;
    unsigned int repeat_x;
    unsigned int repeat_y;
    unsigned int player_map_x;
    unsigned int player_map_y;
    char glyph;
    const char *color;
    int is_player;

    explorer_terminal_size(&columns, &rows);
    explorer_glyph_size(scale, &glyph_width, &glyph_height);
    visible_width = columns / glyph_width;
    visible_height = (rows - 2U) / glyph_height;
    if (visible_width > MAP_WIDTH) visible_width = MAP_WIDTH;
    if (visible_height > MAP_HEIGHT) visible_height = MAP_HEIGHT;
    player_map_x = MAP_WIDTH / 2U;
    player_map_y = MAP_HEIGHT / 2U;
    first_x = player_map_x > visible_width / 2U ?
              player_map_x - visible_width / 2U : 0U;
    first_y = player_map_y > visible_height / 2U ?
              player_map_y - visible_height / 2U : 0U;
    if (first_x + visible_width > MAP_WIDTH) first_x = MAP_WIDTH - visible_width;
    if (first_y + visible_height > MAP_HEIGHT) first_y = MAP_HEIGHT - visible_height;

    printf("\033[H\033[2J\033[?25l");
    printf("MapMaker z%u/11 %s %lukm seed=%08lX\033[K\n",
           scale_index + 1U, explorer_scale_name(scale),
           ((unsigned long)MAP_WIDTH * scale) / 2000UL, map->seed);
    printf("WASD +/-  R=new  M=range  H=%s  Q=quit\033[K\n",
           show_relief ? "relief" : "biome");
    for (map_y = first_y; map_y < first_y + visible_height; ++map_y) {
        for (repeat_y = 0U; repeat_y < glyph_height; ++repeat_y) {
            for (map_x = first_x; map_x < first_x + visible_width; ++map_x) {
                explorer_style(map, map_x, map_y, show_relief, &glyph, &color);
                is_player = map_x == player_map_x && map_y == player_map_y;
                for (repeat_x = 0U; repeat_x < glyph_width; ++repeat_x) {
                    if (is_player && repeat_x == glyph_width / 2U &&
                        repeat_y == glyph_height / 2U) {
                        if (scale >= MAP_LOCAL_CELL_HALF_METERS_10M)
                            printf("\033[1;97m+");
                        else
                            printf("\033[1;97m@");
                    } else
                        printf("%s%c", color, glyph);
                }
            }
            printf("\033[0m\033[K\n");
        }
    }
    fflush(stdout);
}

int main(void)
{
    static unsigned char globe_storage[WORLD_GLOBE_STORAGE_CELLS];
    static Map map;
    WorldGlobe globe;
    WorldLandscape landscape;
    unsigned short scales[11];
    unsigned int scale_index;
    long player_x;
    long player_y;
    unsigned int next_x;
    unsigned int next_y;
    unsigned long seed;
    unsigned int mountain_index;
    int show_relief;
    char key;

    scales[0] = MAP_LOCAL_CELL_HALF_METERS_5KM;
    scales[1] = MAP_LOCAL_CELL_HALF_METERS_1KM;
    scales[2] = MAP_LOCAL_CELL_HALF_METERS_500M;
    scales[3] = MAP_LOCAL_CELL_HALF_METERS_100M;
    scales[4] = MAP_LOCAL_CELL_HALF_METERS_50M;
    scales[5] = MAP_LOCAL_CELL_HALF_METERS_20M;
    scales[6] = MAP_LOCAL_CELL_HALF_METERS_10M;
    scales[7] = MAP_LOCAL_CELL_HALF_METERS_5M;
    scales[8] = MAP_LOCAL_CELL_HALF_METERS_2M;
    scales[9] = MAP_LOCAL_CELL_HALF_METERS_1M;
    scales[10] = MAP_LOCAL_CELL_HALF_METERS_0_5M;
    scale_index = 7U;
    show_relief = 0;
    mountain_index = 0U;
    seed = 424242UL;
    if (!WorldGlobeInitializeWithContinents(&globe, globe_storage,
                              WORLD_GLOBE_STORAGE_CELLS, seed, 4U) ||
        !WorldGlobeGenerate(&globe)) {
        fprintf(stderr, "could not initialize MapMaker globe\n");
        return 1;
    }
    WorldLandscapeInitialize(&landscape, seed);
    if (!WorldLandscapeGenerate(&landscape)) {
        fprintf(stderr, "could not generate MapMaker landscape\n");
        return 1;
    }
    WorldGlobeSetLandscape(&globe, &landscape);
    if (!explorer_find_land_start(&map, &globe, scales[scale_index],
                                  &player_x, &player_y)) {
        fprintf(stderr, "could not find land near world centre\n");
        return 1;
    }
    if (!explorer_set_raw_terminal()) {
        fprintf(stderr, "mapmaker-explorer requires an interactive tty\n");
        return 1;
    }
    (void)atexit(explorer_restore_terminal);
    for (;;) {
        if (!explorer_generate_centered(&map, &globe, player_x, player_y,
                                        scales[scale_index]))
            break;
        explorer_draw(&map, scales[scale_index], scale_index, show_relief);
        if (read(0, &key, 1U) != 1 || key == 'q' || key == 'Q')
            break;
        if (key == 'r' || key == 'R') {
            seed = seed * 1664525UL + 1013904223UL;
            printf("\033[H\033[2J\033[?25lGenerating world seed=%08lX...\033[K\n",
                   seed);
            fflush(stdout);
            /* Generation is entirely fresh, but clearing the caller-owned
             * backing store makes that guarantee explicit and prevents any
             * future partial generator from inheriting stale cell data. */
            memset(globe_storage, 0, sizeof(globe_storage));
            if (!WorldGlobeInitializeWithContinents(&globe, globe_storage,
                                      WORLD_GLOBE_STORAGE_CELLS, seed, 4U) ||
                !WorldGlobeGenerate(&globe)) break;
            WorldLandscapeInitialize(&landscape, seed);
            if (!WorldLandscapeGenerate(&landscape)) break;
            WorldGlobeSetLandscape(&globe, &landscape);
            if (!explorer_find_land_start(&map, &globe, scales[scale_index],
                                          &player_x, &player_y)) break;
            continue;
        }
        if (key == 'h' || key == 'H') {
            show_relief = !show_relief;
            continue;
        }
        if (key == 'm' || key == 'M') {
            if (landscape.range_count != 0U) {
                (void)explorer_find_range_land(&globe,
                    (landscape.ranges[mountain_index].start_x +
                     landscape.ranges[mountain_index].end_x) * 1000L,
                    (landscape.ranges[mountain_index].start_y +
                     landscape.ranges[mountain_index].end_y) * 1000L,
                    &player_x, &player_y);
                mountain_index = (mountain_index + 1U) % landscape.range_count;
            }
            continue;
        }
        next_x = MAP_WIDTH / 2U;
        next_y = MAP_HEIGHT / 2U;
        if (key == 'w' || key == 'W') --next_y;
        else if (key == 'a' || key == 'A') --next_x;
        else if (key == 's' || key == 'S') ++next_y;
        else if (key == 'd' || key == 'D') ++next_x;
        if ((key == 'w' || key == 'W' || key == 'a' || key == 'A' ||
             key == 's' || key == 'S' || key == 'd' || key == 'D') &&
            !explorer_is_water(&map, next_x, next_y)) {
            if (key == 'w' || key == 'W') player_y -= scales[scale_index];
            else if (key == 'a' || key == 'A') player_x -= scales[scale_index];
            else if (key == 's' || key == 'S') player_y += scales[scale_index];
            else player_x += scales[scale_index];
        }
        else if (key == '+' && scale_index < 10U) ++scale_index;
        else if (key == '-' && scale_index > 0U) --scale_index;
    }
    return 0;
}
