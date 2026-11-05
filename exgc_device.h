#ifndef EXGC_DEVICE_H
#define EXGC_DEVICE_H

#include <stddef.h>
#include <stdint.h>

#include "exgc_sixel.h"

#define EXGC_SEGMENT 0xfcu
#define EXGC_SEGMENT_BYTES 0x10000u
#define EXGC_FRAMEBUFFER_BYTES 0x5a00u
#define EXGC_FRAMEBUFFER_A 0x0000u
#define EXGC_FRAMEBUFFER_B 0x5a00u
#define EXGC_SPRITE_PATTERNS 0xb400u
#define EXGC_SPRITE_PATTERN_BYTES 0x2c00u
#define EXGC_SPRITE_ATTRIBUTES 0xe000u
#define EXGC_SPRITE_COUNT 32u
#define EXGC_VIDEO_MODE 0xf804u
#define EXGC_SPRITE_CONTROL 0xf808u
#define EXGC_MMIO_START 0xf800u
#define EXGC_VIDEO_TIMING 0xf800u
#define EXGC_VIDEO_PAGE 0xf802u
#define EXGC_VIDEO_FRAME 0xf814u
#define EXGC_PALETTE_BASE 0xf840u
#define EXGC_VISIBLE_SCANLINES 192u
#define EXGC_TOTAL_SCANLINES 262u
#define EXGC_INSTRUCTIONS_PER_SCANLINE 256u

typedef struct {
    uint16_t scanline;
    uint16_t frame;
} EXGCTimingState;

typedef enum {
    EXGC_MMIO_NOT_HANDLED = 0,
    EXGC_MMIO_HANDLED = 1,
    EXGC_MMIO_INVALID = -1
} EXGCMMIOResult;

void exgc_device_reset(uint8_t *segment_memory, size_t size);
void exgc_timing_reset(EXGCTimingState *timing, uint8_t *segment_memory,
                       size_t size);
void exgc_timing_advance_scanline(EXGCTimingState *timing,
                                  uint8_t *segment_memory, size_t size);
EXGCMMIOResult exgc_device_read_word(const uint8_t *segment_memory,
                                     uint16_t offset, uint16_t *value);
EXGCMMIOResult exgc_device_write_word(uint8_t *segment_memory,
                                      uint16_t offset, uint16_t value);
EXGCMMIOResult exgc_device_byte_access(uint16_t offset);
void exgc_device_compose(const uint8_t *segment_memory, uint8_t *framebuffer);
int exgc_device_render(const uint8_t *segment_memory, unsigned scale_x,
                       unsigned scale_y, EXGCWriteCallback writer,
                       void *writer_context);

#endif
