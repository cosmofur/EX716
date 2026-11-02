/* Interactive host visualizer for the portable MapMaker local-map API. */
#include <stdio.h>
#include <stdlib.h>
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
    case MAP_LOCAL_CELL_HALF_METERS_0_5M: return "0.5 m";
    case MAP_LOCAL_CELL_HALF_METERS_1M: return "1 m";
    case MAP_LOCAL_CELL_HALF_METERS_2M: return "2 m";
    case MAP_LOCAL_CELL_HALF_METERS_5M: return "5 m";
    default: return "10 m";
    }
}

static void explorer_style(MapCell cell, char *glyph, const char **color)
{
    unsigned int terrain;

    terrain = CELL_TERRAIN(cell);
    if (terrain & FEATURE_FOREST) {
        *glyph = 'T';
        *color = "\033[1;32m";
        return;
    }
    if (terrain & FEATURE_ROAD) {
        *glyph = '=';
        *color = "\033[1;33m";
        return;
    }
    switch (terrain & TERRAIN_GROUND_MASK) {
    case TERRAIN_WATER:
        *glyph = '~'; *color = "\033[1;34m"; break;
    case TERRAIN_ROCK:
        *glyph = CELL_HEIGHT(cell) & 1U ? '*' : '.';
        *color = "\033[0;37m"; break;
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
        *glyph = ','; *color = "\033[0;32m"; break;
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

static void explorer_draw(const Map *map, unsigned short scale,
                          long player_x, long player_y)
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
    printf("MapMaker explorer  scale=%s/cell  position=(%ld,%ld) half-metres  ",
           explorer_scale_name(scale), player_x, player_y);
    printf("WASD move  +/- zoom  Q quit\033[K\n");
    printf("green grass ,  trees T  blue water ~  stone ./*  road =  building #\033[K\n");
    for (map_y = first_y; map_y < first_y + visible_height; ++map_y) {
        for (repeat_y = 0U; repeat_y < glyph_height; ++repeat_y) {
            for (map_x = first_x; map_x < first_x + visible_width; ++map_x) {
                explorer_style(map->cells[map_y * MAP_WIDTH + map_x], &glyph,
                               &color);
                is_player = map_x == player_map_x && map_y == player_map_y;
                for (repeat_x = 0U; repeat_x < glyph_width; ++repeat_x) {
                    if (is_player && repeat_x == glyph_width / 2U &&
                        repeat_y == glyph_height / 2U) {
                        if (scale == MAP_LOCAL_CELL_HALF_METERS_10M)
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
    unsigned short scales[5];
    unsigned int scale_index;
    long player_x;
    long player_y;
    unsigned int next_x;
    unsigned int next_y;
    char key;

    scales[0] = MAP_LOCAL_CELL_HALF_METERS_10M;
    scales[1] = MAP_LOCAL_CELL_HALF_METERS_5M;
    scales[2] = MAP_LOCAL_CELL_HALF_METERS_2M;
    scales[3] = MAP_LOCAL_CELL_HALF_METERS_1M;
    scales[4] = MAP_LOCAL_CELL_HALF_METERS_0_5M;
    scale_index = 1U;
    if (!WorldGlobeInitialize(&globe, globe_storage, WORLD_GLOBE_STORAGE_CELLS,
                              424242UL) || !WorldGlobeGenerate(&globe)) {
        fprintf(stderr, "could not initialize MapMaker globe\n");
        return 1;
    }
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
        explorer_draw(&map, scales[scale_index], player_x, player_y);
        if (read(0, &key, 1U) != 1 || key == 'q' || key == 'Q')
            break;
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
        else if (key == '+' && scale_index < 4U) ++scale_index;
        else if (key == '-' && scale_index > 0U) --scale_index;
    }
    return 0;
}
