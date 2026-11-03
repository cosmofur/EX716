#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "exgc_device.h"

typedef struct {
    size_t bytes;
    unsigned long hash;
} Capture;

static int capture_write(void *context, const void *data, size_t length)
{
    Capture *capture = context;
    const unsigned char *bytes = data;
    size_t index;
    for (index = 0; index < length; ++index) capture->hash =
        (capture->hash ^ bytes[index]) * 16777619UL;
    capture->bytes += length;
    return 0;
}

int main(void)
{
    uint8_t *memory = malloc(EXGC_SEGMENT_BYTES);
    uint16_t palette[EXGC_SIXEL_PALETTE_SIZE];
    uint16_t value;
    Capture first = {0, 2166136261UL};
    Capture second = {0, 2166136261UL};
    unsigned index;

    assert(memory != 0);
    memset(memory, 0xff, EXGC_SEGMENT_BYTES);
    exgc_device_reset(memory, EXGC_SEGMENT_BYTES);
    exgc_sixel_default_palette(palette);
    assert(memory[EXGC_FRAMEBUFFER_A] == 0 && memory[EXGC_FRAMEBUFFER_B] == 0);
    assert(exgc_device_read_word(memory, EXGC_VIDEO_PAGE, &value) == EXGC_MMIO_HANDLED);
    assert(value == 0);
    for (index = 0; index < EXGC_SIXEL_PALETTE_SIZE; ++index) {
        assert(exgc_device_read_word(memory,
                                     (uint16_t)(EXGC_PALETTE_BASE + index * 2u),
                                     &value) == EXGC_MMIO_HANDLED);
        assert(value == palette[index]);
    }
    assert(exgc_device_write_word(memory, EXGC_VIDEO_PAGE, 2) == EXGC_MMIO_HANDLED);
    assert(exgc_device_read_word(memory, EXGC_VIDEO_PAGE, &value) == EXGC_MMIO_HANDLED);
    assert(value == 3); /* current and requested page B; no pending flip. */
    assert(exgc_device_byte_access(EXGC_VIDEO_PAGE) == EXGC_MMIO_INVALID);
    assert(exgc_device_read_word(memory, EXGC_VIDEO_PAGE + 1u, &value) == EXGC_MMIO_INVALID);
    assert(exgc_device_write_word(memory, EXGC_PALETTE_BASE, 0x801f) == EXGC_MMIO_HANDLED);
    assert(exgc_device_read_word(memory, EXGC_PALETTE_BASE, &value) == EXGC_MMIO_HANDLED);
    assert(value == 0x801f);

    assert(exgc_device_write_word(memory, EXGC_VIDEO_PAGE, 0) == EXGC_MMIO_HANDLED);
    assert(exgc_device_render(memory, 1, 1, capture_write, &first) == EXGC_SIXEL_OK);
    memory[EXGC_FRAMEBUFFER_B] = 0x10; /* first pixel of B uses palette entry 1 */
    assert(exgc_device_write_word(memory, EXGC_VIDEO_PAGE, 2) == EXGC_MMIO_HANDLED);
    assert(exgc_device_render(memory, 1, 1, capture_write, &second) == EXGC_SIXEL_OK);
    assert(first.bytes != 0 && second.bytes != 0 && first.hash != second.hash);
    free(memory);
    return 0;
}
