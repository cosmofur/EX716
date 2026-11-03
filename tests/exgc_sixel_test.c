#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "exgc_sixel.h"

#define FRAME_BYTES (EXGC_SIXEL_NATIVE_STRIDE * EXGC_SIXEL_NATIVE_HEIGHT)

typedef struct {
    size_t bytes;
} CountSink;

static int file_write(void *context, const void *data, size_t length)
{
    FILE *stream = context;
    return fwrite(data, 1, length, stream) == length ? 0 : 1;
}

static int count_write(void *context, const void *data, size_t length)
{
    CountSink *sink = context;
    (void)data;
    sink->bytes += length;
    return 0;
}

static void set_pixel(unsigned char *pixels, unsigned x, unsigned y, unsigned value)
{
    unsigned char *packed = &pixels[(size_t)y * EXGC_SIXEL_NATIVE_STRIDE + x / 2u];
    if ((x & 1u) == 0) *packed = (unsigned char)((*packed & 15u) | (value << 4));
    else *packed = (unsigned char)((*packed & 0xf0u) | value);
}

static void make_pattern(unsigned char *pixels, const char *name)
{
    unsigned x, y;
    unsigned long noise = 0x13579bdfUL;
    memset(pixels, 0, FRAME_BYTES);
    for (y = 0; y < EXGC_SIXEL_NATIVE_HEIGHT; ++y) {
        for (x = 0; x < EXGC_SIXEL_NATIVE_WIDTH; ++x) {
            unsigned color;
            if (strcmp(name, "bars") == 0) color = x * 16u / EXGC_SIXEL_NATIVE_WIDTH;
            else if (strcmp(name, "checker") == 0) color = ((x / 8u) ^ (y / 8u)) & 15u;
            else if (strcmp(name, "diagonal") == 0)
                color = ((x + y) % 24u < 3u || (x + EXGC_SIXEL_NATIVE_HEIGHT - y) % 24u < 3u) ?
                        (x / 15u) & 15u : 0u;
            else if (strcmp(name, "solid") == 0) color = 9u;
            else if (strcmp(name, "all16") == 0) color = (x % 4u) + (y % 4u) * 4u;
            else if (strcmp(name, "noise") == 0) {
                noise = noise * 1103515245UL + 12345UL;
                color = (unsigned)((noise >> 16) & 15u);
            } else color = 0u;
            set_pixel(pixels, x, y, color);
        }
    }
}

static int parse_scale(const char *text, unsigned *scale_x, unsigned *scale_y)
{
    unsigned x, y;
    char tail;
    if (sscanf(text, "%ux%u%c", &x, &y, &tail) != 2 || x == 0 || y == 0) return 0;
    *scale_x = x;
    *scale_y = y;
    return 1;
}

static int benchmark_pattern(const char *name, unsigned scale_x, unsigned scale_y,
                             unsigned char *pixels, const uint16_t *palette)
{
    EXGCFrame frame;
    CountSink sink;
    clock_t start;
    clock_t elapsed;
    unsigned iteration;
    make_pattern(pixels, name);
    frame = (EXGCFrame){pixels, FRAME_BYTES, EXGC_SIXEL_NATIVE_WIDTH,
                        EXGC_SIXEL_NATIVE_HEIGHT, EXGC_SIXEL_NATIVE_STRIDE,
                        scale_x, scale_y, palette};
    sink.bytes = 0;
    if (exgc_sixel_render(&frame, count_write, &sink) != EXGC_SIXEL_OK) return 1;
    start = clock();
    for (iteration = 0; iteration < 5u; ++iteration) {
        CountSink null_sink = {0};
        if (exgc_sixel_render(&frame, count_write, &null_sink) != EXGC_SIXEL_OK) return 1;
    }
    elapsed = clock() - start;
    fprintf(stderr, "%-7s %ux%u: %zu bytes/frame, %.2f ms/frame, %.1f fps; "
            "bandwidth 10/15/30/60 fps: %.1f/%.1f/%.1f/%.1f KiB/s\n",
            name, scale_x, scale_y, sink.bytes,
            1000.0 * (double)elapsed / (double)CLOCKS_PER_SEC / 5.0,
            elapsed == 0 ? 0.0 : 5.0 * (double)CLOCKS_PER_SEC / (double)elapsed,
            sink.bytes * 10.0 / 1024.0, sink.bytes * 15.0 / 1024.0,
            sink.bytes * 30.0 / 1024.0, sink.bytes * 60.0 / 1024.0);
    return 0;
}

static int benchmark(unsigned char *pixels, const uint16_t *palette)
{
    static const char *patterns[] = {"solid", "bars", "checker", "noise"};
    static const unsigned scales[][2] = {{1, 1}, {3, 2}, {6, 3}};
    unsigned pattern, scale;
    fprintf(stderr, "EXGC SIXEL benchmark: CPU time only; null counting callback; 5 frames/case\n");
    for (pattern = 0; pattern < sizeof(patterns) / sizeof(patterns[0]); ++pattern) {
        for (scale = 0; scale < sizeof(scales) / sizeof(scales[0]); ++scale) {
            if (benchmark_pattern(patterns[pattern], scales[scale][0], scales[scale][1],
                                  pixels, palette) != 0) return 1;
        }
    }
    return 0;
}

int main(int argc, char **argv)
{
    unsigned char pixels[FRAME_BYTES];
    uint16_t palette[EXGC_SIXEL_PALETTE_SIZE];
    EXGCFrame frame;
    const char *pattern = "bars";
    const char *output_name = 0;
    unsigned scale_x = 3;
    unsigned scale_y = 2;
    int do_benchmark = 0;
    int index;
    FILE *output = stdout;

    for (index = 1; index < argc; ++index) {
        if (strcmp(argv[index], "--pattern") == 0 && index + 1 < argc) pattern = argv[++index];
        else if (strcmp(argv[index], "--scale") == 0 && index + 1 < argc) {
            if (!parse_scale(argv[++index], &scale_x, &scale_y)) {
                fprintf(stderr, "invalid scale; use XxY\n"); return 2;
            }
        } else if (strcmp(argv[index], "--output") == 0 && index + 1 < argc) output_name = argv[++index];
        else if (strcmp(argv[index], "--benchmark") == 0) do_benchmark = 1;
        else {
            fprintf(stderr, "usage: %s [--pattern bars|checker|diagonal|solid|all16|noise] "
                    "[--scale XxY] [--output FILE] [--benchmark]\n", argv[0]);
            return 2;
        }
    }
    exgc_sixel_default_palette(palette);
    if (do_benchmark) return benchmark(pixels, palette);
    if (output_name != 0) {
        output = fopen(output_name, "wb");
        if (output == 0) { perror(output_name); return 1; }
    }
    make_pattern(pixels, pattern);
    frame = (EXGCFrame){pixels, FRAME_BYTES, EXGC_SIXEL_NATIVE_WIDTH,
                        EXGC_SIXEL_NATIVE_HEIGHT, EXGC_SIXEL_NATIVE_STRIDE,
                        scale_x, scale_y, palette};
    fprintf(stderr, "EXGC SIXEL: %s at %ux%u -> %ux%u\n", pattern, scale_x, scale_y,
            frame.width * scale_x, frame.height * scale_y);
    if (exgc_sixel_render(&frame, file_write, output) != EXGC_SIXEL_OK) {
        fprintf(stderr, "SIXEL output write failed\n");
        if (output != stdout) fclose(output);
        return 1;
    }
    if (output != stdout && fclose(output) != 0) { perror(output_name); return 1; }
    return 0;
}
