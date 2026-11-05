/* EXGC sprite composition and register contract. */
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "exgc_device.h"

static void word(uint8_t *m, unsigned a, unsigned value) {
    m[a] = (uint8_t)value; m[a + 1] = (uint8_t)(value >> 8);
}
static void descriptor(uint8_t *m, unsigned n, int x, int y, unsigned pattern, unsigned attr) {
    unsigned a = EXGC_SPRITE_ATTRIBUTES + n * 8;
    word(m, a, (uint16_t)x); word(m, a + 2, (uint16_t)y);
    word(m, a + 4, pattern); word(m, a + 6, attr);
}
static unsigned pixel(uint8_t *frame, unsigned x, unsigned y) {
    unsigned p = frame[y * 120 + x / 2]; return x % 2 ? p & 15 : p >> 4;
}
int main(void) {
    uint8_t *m = calloc(1, EXGC_SEGMENT_BYTES), *out = malloc(EXGC_FRAMEBUFFER_BYTES);
    uint16_t v;
    assert(m && out);
    exgc_device_reset(m, EXGC_SEGMENT_BYTES);
    word(m, EXGC_PALETTE_BASE, 0x8000); /* color zero transparent */
    memset(m + EXGC_SPRITE_PATTERNS, 0x12, 32);
    memset(m + EXGC_SPRITE_PATTERNS + 351 * 32, 0x30, 32);
    descriptor(m, 0, 10, 10, 0, 1);
    descriptor(m, 1, 10, 10, 351, 1);
    descriptor(m, 2, -1, -1, 0, 1);
    descriptor(m, 3, 20, 20, 352, 1);
    assert(exgc_device_write_word(m, EXGC_VIDEO_MODE, 0xffff) == EXGC_MMIO_HANDLED);
    assert(exgc_device_read_word(m, EXGC_VIDEO_MODE, &v) == EXGC_MMIO_HANDLED && v == 0x10);
    assert(exgc_device_write_word(m, EXGC_SPRITE_CONTROL, 0xffff) == EXGC_MMIO_HANDLED);
    assert(exgc_device_read_word(m, EXGC_SPRITE_CONTROL, &v) == EXGC_MMIO_HANDLED && v == 0x3f07);
    exgc_device_write_word(m, EXGC_SPRITE_CONTROL, 0x0401);
    exgc_device_compose(m, out);
    assert(pixel(out, 10, 10) == 1 && pixel(out, 11, 10) == 2); /* priority */
    assert(pixel(out, 0, 0) == 2); /* negative clipping */
    assert(pixel(out, 20, 20) == 0); /* invalid pattern */
    descriptor(m, 0, 10, 10, 0, 0); /* shared slot behind a transparent pixel */
    exgc_device_compose(m, out);
    assert(pixel(out, 10, 10) == 3 && pixel(out, 11, 10) == 0);
    descriptor(m, 0, 10, 10, 0, 5); /* horizontal flip */
    exgc_device_compose(m, out);
    assert(pixel(out, 10, 10) == 2 && pixel(out, 11, 10) == 1);
    exgc_device_write_word(m, EXGC_SPRITE_CONTROL, 0x0105); /* magnify 2x */
    exgc_device_compose(m, out);
    assert(pixel(out, 10, 10) == 2 && pixel(out, 11, 10) == 2 && pixel(out, 12, 10) == 1);
    memset(m + EXGC_SPRITE_PATTERNS + 87 * 128, 0x40, 128);
    descriptor(m, 0, 239, 191, 87, 1);
    exgc_device_write_word(m, EXGC_SPRITE_CONTROL, 0x0103); /* 16x16 last slot */
    exgc_device_compose(m, out);
    assert(pixel(out, 239, 191) == 4);
    /* Vertical flip reads the last source row first. */
    memset(m + EXGC_SPRITE_PATTERNS + 87 * 128 + 15 * 8, 0x50, 8);
    descriptor(m, 0, 30, 30, 87, 9);
    exgc_device_compose(m, out);
    assert(pixel(out, 30, 30) == 5);
    descriptor(m, 0, 239, 191, 88, 1);
    exgc_device_compose(m, out);
    assert(pixel(out, 239, 191) == 0);
    /* Asymmetric corners expose every rotation and flip ordering. */
    memset(m + EXGC_SPRITE_PATTERNS, 0, 32);
    m[EXGC_SPRITE_PATTERNS] = 0x10;       /* top left 1 */
    m[EXGC_SPRITE_PATTERNS + 3] = 0x02;   /* top right 2 */
    m[EXGC_SPRITE_PATTERNS + 28] = 0x30;  /* bottom left 3 */
    m[EXGC_SPRITE_PATTERNS + 31] = 0x04;  /* bottom right 4 */
    memset(m + EXGC_FRAMEBUFFER_A, 0x66, EXGC_FRAMEBUFFER_BYTES);
    exgc_device_write_word(m, EXGC_SPRITE_CONTROL, 0x0101);
    for (unsigned rotation = 0; rotation < 4; ++rotation) {
        static const unsigned corners[4][4] = {
            {1, 2, 3, 4}, {3, 1, 4, 2}, {4, 3, 2, 1}, {2, 4, 1, 3}
        };
        descriptor(m, 0, 20, 20, 0, 1 | (rotation << 4));
        exgc_device_compose(m, out);
        assert(pixel(out, 20, 20) == corners[rotation][0]);
        assert(pixel(out, 27, 20) == corners[rotation][1]);
        assert(pixel(out, 20, 27) == corners[rotation][2]);
        assert(pixel(out, 27, 27) == corners[rotation][3]);
        assert(pixel(out, 21, 20) == 6); /* background through transparent pixel */
    }
    descriptor(m, 0, 20, 20, 0, 0x15); /* flip first, then rotate */
    exgc_device_compose(m, out);
    assert(pixel(out, 20, 20) == 4 && pixel(out, 27, 20) == 2);
    descriptor(m, 0, -7, -7, 0, 0x11);
    exgc_device_compose(m, out);
    assert(pixel(out, 0, 0) == 2); /* rotated and clipped bottom-right */
    exgc_device_write_word(m, EXGC_VIDEO_MODE, 0);
    exgc_device_compose(m, out);
    assert(pixel(out, 10, 10) == 6);
    free(out); free(m); return 0;
}
