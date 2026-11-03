#ifndef EXGC_SIXEL_H
#define EXGC_SIXEL_H

#include <stddef.h>
#include <stdint.h>

#define EXGC_SIXEL_PALETTE_SIZE 16u
#define EXGC_SIXEL_NATIVE_WIDTH 240u
#define EXGC_SIXEL_NATIVE_HEIGHT 192u
#define EXGC_SIXEL_NATIVE_STRIDE 120u

typedef int (*EXGCWriteCallback)(void *context, const void *data, size_t length);

typedef struct {
    const uint8_t *pixels;
    size_t buffer_size;
    unsigned width;
    unsigned height;
    unsigned stride;
    unsigned scale_x;
    unsigned scale_y;
    const uint16_t *palette;
} EXGCFrame;

enum {
    EXGC_SIXEL_OK = 0,
    EXGC_SIXEL_INVALID_ARGUMENT = -1,
    EXGC_SIXEL_WRITE_ERROR = -2
};

/* Pixels use high-nibble-first packing: even x is bits 7..4, odd x 3..0. */
uint8_t exgc_sixel_pixel_at(const EXGCFrame *frame, unsigned x, unsigned y);
void exgc_sixel_rgb555_to_percent(uint16_t rgb555, unsigned *red,
                                  unsigned *green, unsigned *blue);
void exgc_sixel_default_palette(uint16_t palette[EXGC_SIXEL_PALETTE_SIZE]);
int exgc_sixel_render(const EXGCFrame *frame, EXGCWriteCallback writer,
                      void *writer_context);

#endif
