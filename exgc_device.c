#include "exgc_device.h"

#include <string.h>

static uint16_t read_le16(const uint8_t *data, uint16_t offset)
{
    return (uint16_t)(data[offset] | ((uint16_t)data[offset + 1u] << 8));
}

static void write_le16(uint8_t *data, uint16_t offset, uint16_t value)
{
    data[offset] = (uint8_t)value;
    data[offset + 1u] = (uint8_t)(value >> 8);
}

void exgc_device_reset(uint8_t *segment_memory, size_t size)
{
    uint16_t palette[EXGC_SIXEL_PALETTE_SIZE];
    unsigned index;
    if (segment_memory == 0 || size < EXGC_SEGMENT_BYTES) return;
    memset(segment_memory, 0, EXGC_SEGMENT_BYTES);
    exgc_sixel_default_palette(palette);
    for (index = 0; index < EXGC_SIXEL_PALETTE_SIZE; ++index) {
        write_le16(segment_memory, (uint16_t)(EXGC_PALETTE_BASE + index * 2u),
                   palette[index]);
    }
}

EXGCMMIOResult exgc_device_byte_access(uint16_t offset)
{
    return offset >= EXGC_MMIO_START ? EXGC_MMIO_INVALID : EXGC_MMIO_NOT_HANDLED;
}

EXGCMMIOResult exgc_device_read_word(const uint8_t *segment_memory,
                                     uint16_t offset, uint16_t *value)
{
    if (offset < EXGC_MMIO_START) return EXGC_MMIO_NOT_HANDLED;
    if ((offset & 1u) != 0 || offset == 0xffffu || value == 0)
        return EXGC_MMIO_INVALID;
    if (offset == EXGC_VIDEO_PAGE) {
        uint16_t page = (uint16_t)(segment_memory[offset] & 1u);
        *value = (uint16_t)(page | (page << 1));
    } else if (offset >= EXGC_PALETTE_BASE && offset < EXGC_PALETTE_BASE + 32u) {
        *value = read_le16(segment_memory, offset);
    } else {
        *value = 0;
    }
    return EXGC_MMIO_HANDLED;
}

EXGCMMIOResult exgc_device_write_word(uint8_t *segment_memory,
                                      uint16_t offset, uint16_t value)
{
    if (offset < EXGC_MMIO_START) return EXGC_MMIO_NOT_HANDLED;
    if ((offset & 1u) != 0 || offset == 0xffffu) return EXGC_MMIO_INVALID;
    if (offset == EXGC_VIDEO_PAGE) {
        uint16_t page = (uint16_t)((value >> 1) & 1u);
        /* Phase 2 decision: requested page applies immediately; no VBlank
         * request or pending state exists until timing is implemented. */
        write_le16(segment_memory, offset, (uint16_t)(page | (page << 1)));
    } else if (offset >= EXGC_PALETTE_BASE && offset < EXGC_PALETTE_BASE + 32u) {
        write_le16(segment_memory, offset, value);
    }
    return EXGC_MMIO_HANDLED;
}

int exgc_device_render(const uint8_t *segment_memory, unsigned scale_x,
                       unsigned scale_y, EXGCWriteCallback writer,
                       void *writer_context)
{
    EXGCFrame frame;
    uint16_t palette[EXGC_SIXEL_PALETTE_SIZE];
    uint16_t page;
    unsigned index;
    if (segment_memory == 0) return EXGC_SIXEL_INVALID_ARGUMENT;
    page = (uint16_t)(segment_memory[EXGC_VIDEO_PAGE] & 1u);
    for (index = 0; index < EXGC_SIXEL_PALETTE_SIZE; ++index) {
        palette[index] = read_le16(segment_memory,
                                   (uint16_t)(EXGC_PALETTE_BASE + index * 2u));
    }
    frame.pixels = segment_memory + (page ? EXGC_FRAMEBUFFER_B : EXGC_FRAMEBUFFER_A);
    frame.buffer_size = EXGC_FRAMEBUFFER_BYTES;
    frame.width = EXGC_SIXEL_NATIVE_WIDTH;
    frame.height = EXGC_SIXEL_NATIVE_HEIGHT;
    frame.stride = EXGC_SIXEL_NATIVE_STRIDE;
    frame.scale_x = scale_x;
    frame.scale_y = scale_y;
    frame.palette = palette;
    return exgc_sixel_render(&frame, writer, writer_context);
}
