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

void exgc_timing_reset(EXGCTimingState *timing, uint8_t *segment_memory,
                       size_t size)
{
    if (timing == 0 || segment_memory == 0 || size < EXGC_SEGMENT_BYTES) return;
    timing->scanline = 0;
    timing->frame = 0;
    write_le16(segment_memory, EXGC_VIDEO_TIMING, 0);
    write_le16(segment_memory, EXGC_VIDEO_FRAME, 0);
}

void exgc_timing_advance_scanline(EXGCTimingState *timing,
                                  uint8_t *segment_memory, size_t size)
{
    uint16_t page;
    if (timing == 0 || segment_memory == 0 || size < EXGC_SEGMENT_BYTES) return;
    ++timing->scanline;
    if (timing->scanline == EXGC_VISIBLE_SCANLINES) {
        /* VBlank begins immediately after visible scanline 191. A requested
         * swap becomes visible at this boundary, never during visible draw. */
        page = read_le16(segment_memory, EXGC_VIDEO_PAGE);
        if ((page & 0x0008u) != 0) {
            page = (uint16_t)(((page >> 1) & 1u) | (page & 0x0002u));
            write_le16(segment_memory, EXGC_VIDEO_PAGE, page);
        }
    }
    if (timing->scanline >= EXGC_TOTAL_SCANLINES) {
        timing->scanline = 0;
        ++timing->frame;
        write_le16(segment_memory, EXGC_VIDEO_FRAME, timing->frame);
    }
    /* Keep backing bytes useful to host inspection, but guest reads remain
     * routed below so they cannot bypass timing state. */
    write_le16(segment_memory, EXGC_VIDEO_TIMING,
               (uint16_t)((timing->scanline >= EXGC_VISIBLE_SCANLINES ? 0x8000u : 0u) |
                          (timing->scanline >= EXGC_VISIBLE_SCANLINES ?
                           EXGC_VISIBLE_SCANLINES - 1u : timing->scanline)));
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
    if (offset == EXGC_VIDEO_TIMING || offset == EXGC_VIDEO_FRAME) {
        *value = read_le16(segment_memory, offset);
    } else if (offset == EXGC_VIDEO_MODE || offset == EXGC_SPRITE_CONTROL) {
        *value = read_le16(segment_memory, offset);
    } else if (offset == EXGC_VIDEO_PAGE) {
        *value = (uint16_t)(read_le16(segment_memory, offset) & 0x000bu);
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
        if ((value & 0x0004u) != 0) {
            uint16_t displayed = (uint16_t)(read_le16(segment_memory, offset) & 1u);
            write_le16(segment_memory, offset,
                       (uint16_t)(displayed | (page << 1) | 0x0008u));
        } else {
            /* Preserve the Phase 2 immediate selection ABI. An immediate
             * select also supersedes any deferred request. */
            write_le16(segment_memory, offset, (uint16_t)(page | (page << 1)));
        }
    } else if (offset == EXGC_VIDEO_MODE) {
        /* Only the sprite enable is implemented; framebuffer remains visible. */
        write_le16(segment_memory, offset, (uint16_t)(value & 0x0010u));
    } else if (offset == EXGC_SPRITE_CONTROL) {
        /* Enable, size, magnification and active descriptor count. */
        write_le16(segment_memory, offset, (uint16_t)(value & 0x3f07u));
    } else if (offset >= EXGC_PALETTE_BASE && offset < EXGC_PALETTE_BASE + 32u) {
        write_le16(segment_memory, offset, value);
    }
    return EXGC_MMIO_HANDLED;
}

/* Compose into a packed framebuffer without modifying guest VRAM. */
void exgc_device_compose(const uint8_t *memory, uint8_t *framebuffer)
{
    uint16_t mode = read_le16(memory, EXGC_VIDEO_MODE);
    uint16_t control = read_le16(memory, EXGC_SPRITE_CONTROL);
    unsigned size = (control & 2u) ? 16u : 8u;
    unsigned scale = (control & 4u) ? 2u : 1u;
    unsigned count = (control >> 8) & 63u;
    unsigned slot_bytes = size * size / 2u;
    unsigned slots = EXGC_SPRITE_PATTERN_BYTES / slot_bytes;
    int sprite;

    memcpy(framebuffer, memory + ((memory[EXGC_VIDEO_PAGE] & 1u) ?
           EXGC_FRAMEBUFFER_B : EXGC_FRAMEBUFFER_A), EXGC_FRAMEBUFFER_BYTES);
    if (!(mode & 0x10u) || !(control & 1u)) return;
    if (count > EXGC_SPRITE_COUNT) count = EXGC_SPRITE_COUNT;
    /* Draw back to front so a lower descriptor number wins overlaps. */
    for (sprite = (int)count - 1; sprite >= 0; --sprite) {
        uint16_t descriptor = (uint16_t)(EXGC_SPRITE_ATTRIBUTES + sprite * 8u);
        uint16_t raw_x = read_le16(memory, descriptor);
        uint16_t raw_y = read_le16(memory, (uint16_t)(descriptor + 2u));
        int x = raw_x < 0x8000u ? (int)raw_x : (int)raw_x - 65536;
        int y = raw_y < 0x8000u ? (int)raw_y : (int)raw_y - 65536;
        unsigned pattern = read_le16(memory, (uint16_t)(descriptor + 4u));
        unsigned attr = read_le16(memory, (uint16_t)(descriptor + 6u));
        unsigned dy, dx;
        if (!(attr & 1u) || pattern >= slots) continue;
        for (dy = 0; dy < size * scale; ++dy) {
            int screen_y = y + (int)dy;
            unsigned py = dy / scale;
            if (screen_y < 0 || screen_y >= (int)EXGC_SIXEL_NATIVE_HEIGHT) continue;
            for (dx = 0; dx < size * scale; ++dx) {
                int screen_x = x + (int)dx;
                unsigned px = dx / scale;
                unsigned color, offset;
                uint8_t packed;
                if (screen_x < 0 || screen_x >= (int)EXGC_SIXEL_NATIVE_WIDTH) continue;
                /* Invert a clockwise quarter-turn, then invert the source
                 * flips: flips happen first, followed by rotation. */
                {
                    unsigned sy = py;
                    unsigned sx = px;
                    switch ((attr >> 4) & 3u) {
                    case 1: px = sy; py = size - 1u - sx; break;
                    case 2: px = size - 1u - sx; py = size - 1u - sy; break;
                    case 3: px = size - 1u - sy; py = sx; break;
                    default: break;
                    }
                    if (attr & 4u) px = size - 1u - px;
                    if (attr & 8u) py = size - 1u - py;
                    packed = memory[EXGC_SPRITE_PATTERNS + pattern * slot_bytes +
                                    py * (size / 2u) + px / 2u];
                    py = sy;
                }
                color = (px & 1u) ? packed & 15u : packed >> 4;
                if (read_le16(memory, (uint16_t)(EXGC_PALETTE_BASE + color * 2u)) & 0x8000u)
                    continue;
                offset = (unsigned)screen_y * EXGC_SIXEL_NATIVE_STRIDE + (unsigned)screen_x / 2u;
                if (screen_x & 1) framebuffer[offset] = (uint8_t)((framebuffer[offset] & 0xf0u) | color);
                else framebuffer[offset] = (uint8_t)((framebuffer[offset] & 0x0fu) | (color << 4));
            }
        }
    }
}

int exgc_device_render(const uint8_t *segment_memory, unsigned scale_x,
                       unsigned scale_y, EXGCWriteCallback writer,
                       void *writer_context)
{
    EXGCFrame frame;
    uint16_t palette[EXGC_SIXEL_PALETTE_SIZE];
    uint8_t composed[EXGC_FRAMEBUFFER_BYTES];
    unsigned index;
    if (segment_memory == 0) return EXGC_SIXEL_INVALID_ARGUMENT;
    exgc_device_compose(segment_memory, composed);
    for (index = 0; index < EXGC_SIXEL_PALETTE_SIZE; ++index) {
        palette[index] = read_le16(segment_memory,
                                   (uint16_t)(EXGC_PALETTE_BASE + index * 2u));
    }
    frame.pixels = composed;
    frame.buffer_size = EXGC_FRAMEBUFFER_BYTES;
    frame.width = EXGC_SIXEL_NATIVE_WIDTH;
    frame.height = EXGC_SIXEL_NATIVE_HEIGHT;
    frame.stride = EXGC_SIXEL_NATIVE_STRIDE;
    frame.scale_x = scale_x;
    frame.scale_y = scale_y;
    frame.palette = palette;
    return exgc_sixel_render(&frame, writer, writer_context);
}
