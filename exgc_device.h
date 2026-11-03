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
#define EXGC_MMIO_START 0xf800u
#define EXGC_VIDEO_TIMING 0xf800u
#define EXGC_VIDEO_PAGE 0xf802u
#define EXGC_PALETTE_BASE 0xf840u

typedef enum {
    EXGC_MMIO_NOT_HANDLED = 0,
    EXGC_MMIO_HANDLED = 1,
    EXGC_MMIO_INVALID = -1
} EXGCMMIOResult;

void exgc_device_reset(uint8_t *segment_memory, size_t size);
EXGCMMIOResult exgc_device_read_word(const uint8_t *segment_memory,
                                     uint16_t offset, uint16_t *value);
EXGCMMIOResult exgc_device_write_word(uint8_t *segment_memory,
                                      uint16_t offset, uint16_t value);
EXGCMMIOResult exgc_device_byte_access(uint16_t offset);
int exgc_device_render(const uint8_t *segment_memory, unsigned scale_x,
                       unsigned scale_y, EXGCWriteCallback writer,
                       void *writer_context);

#endif
