#include "exgc_sixel.h"

#include <limits.h>
#include <stdio.h>

static int emit(EXGCWriteCallback writer, void *context, const void *data,
                size_t length)
{
    return writer(context, data, length) == 0 ? EXGC_SIXEL_OK : EXGC_SIXEL_WRITE_ERROR;
}

static int emit_char(EXGCWriteCallback writer, void *context, unsigned char value)
{
    return emit(writer, context, &value, 1);
}

static int emit_number(EXGCWriteCallback writer, void *context, unsigned value)
{
    char text[16];
    int length = snprintf(text, sizeof(text), "%u", value);
    if (length < 0 || (size_t)length >= sizeof(text)) return EXGC_SIXEL_INVALID_ARGUMENT;
    return emit(writer, context, text, (size_t)length);
}

static int emit_repeat(EXGCWriteCallback writer, void *context, unsigned count,
                       unsigned char value)
{
    int result;
    if (count == 1) return emit_char(writer, context, value);
    if (count == 2) {
        result = emit_char(writer, context, value);
        return result == EXGC_SIXEL_OK ? emit_char(writer, context, value) : result;
    }
    result = emit_char(writer, context, '!');
    if (result != EXGC_SIXEL_OK) return result;
    result = emit_number(writer, context, count);
    return result == EXGC_SIXEL_OK ? emit_char(writer, context, value) : result;
}

static int frame_is_valid(const EXGCFrame *frame)
{
    size_t last_row;
    size_t row_bytes;
    if (frame == 0 || frame->pixels == 0 || frame->palette == 0 ||
        frame->width == 0 || frame->height == 0 || frame->scale_x == 0 ||
        frame->scale_y == 0) return 0;
    row_bytes = ((size_t)frame->width + 1u) / 2u;
    if (frame->stride < row_bytes) return 0;
    if (frame->width > UINT_MAX / frame->scale_x ||
        frame->height > UINT_MAX / frame->scale_y) return 0;
    if ((size_t)(frame->height - 1u) > SIZE_MAX / frame->stride) return 0;
    last_row = ((size_t)frame->height - 1u) * frame->stride;
    return last_row <= frame->buffer_size && row_bytes <= frame->buffer_size - last_row;
}

uint8_t exgc_sixel_pixel_at(const EXGCFrame *frame, unsigned x, unsigned y)
{
    uint8_t packed = frame->pixels[(size_t)y * frame->stride + x / 2u];
    return (uint8_t)((x & 1u) == 0 ? packed >> 4 : packed & 15u);
}

void exgc_sixel_rgb555_to_percent(uint16_t rgb555, unsigned *red,
                                  unsigned *green, unsigned *blue)
{
    if (red != 0) *red = (((rgb555 >> 10) & 31u) * 100u + 15u) / 31u;
    if (green != 0) *green = (((rgb555 >> 5) & 31u) * 100u + 15u) / 31u;
    if (blue != 0) *blue = ((rgb555 & 31u) * 100u + 15u) / 31u;
}

void exgc_sixel_default_palette(uint16_t palette[EXGC_SIXEL_PALETTE_SIZE])
{
    static const uint16_t defaults[EXGC_SIXEL_PALETTE_SIZE] = {
        0x0000u, 0x4210u, 0x001fu, 0x03ffu,
        0x7c00u, 0x7c1fu, 0x7fe0u, 0x7fffu,
        0x2108u, 0x6318u, 0x021fu, 0x03ffu,
        0x7c10u, 0x7c1fu, 0x7ff0u, 0x7fffu
    };
    unsigned index;
    for (index = 0; index < EXGC_SIXEL_PALETTE_SIZE; ++index) palette[index] = defaults[index];
}

int exgc_sixel_render(const EXGCFrame *frame, EXGCWriteCallback writer,
                      void *writer_context)
{
    unsigned output_width;
    unsigned output_height;
    unsigned band;
    unsigned color;
    int result;
    if (!frame_is_valid(frame) || writer == 0) return EXGC_SIXEL_INVALID_ARGUMENT;
    output_width = frame->width * frame->scale_x;
    output_height = frame->height * frame->scale_y;

    result = emit(writer, writer_context, "\033Pq\"1;1;", 8);
    if (result != EXGC_SIXEL_OK) return result;
    result = emit_number(writer, writer_context, output_width);
    if (result != EXGC_SIXEL_OK) return result;
    result = emit_char(writer, writer_context, ';');
    if (result != EXGC_SIXEL_OK) return result;
    result = emit_number(writer, writer_context, output_height);
    if (result != EXGC_SIXEL_OK) return result;

    for (color = 0; color < EXGC_SIXEL_PALETTE_SIZE; ++color) {
        unsigned red, green, blue;
        exgc_sixel_rgb555_to_percent(frame->palette[color], &red, &green, &blue);
        result = emit_char(writer, writer_context, '#');
        if (result != EXGC_SIXEL_OK) return result;
        result = emit_number(writer, writer_context, color);
        if (result != EXGC_SIXEL_OK) return result;
        result = emit(writer, writer_context, ";2;", 3);
        if (result != EXGC_SIXEL_OK) return result;
        result = emit_number(writer, writer_context, red);
        if (result != EXGC_SIXEL_OK) return result;
        result = emit_char(writer, writer_context, ';');
        if (result != EXGC_SIXEL_OK) return result;
        result = emit_number(writer, writer_context, green);
        if (result != EXGC_SIXEL_OK) return result;
        result = emit_char(writer, writer_context, ';');
        if (result != EXGC_SIXEL_OK) return result;
        result = emit_number(writer, writer_context, blue);
        if (result != EXGC_SIXEL_OK) return result;
    }

    for (band = 0; band < output_height; band += 6u) {
        int first_plane = 1;
        uint32_t present = 0;
        unsigned x;
        /* Determine all occupied color planes in one pass.  This avoids
         * rescanning an otherwise solid band fifteen times just to find empty
         * planes.  The subsequent pass still evaluates only planes that will
         * be emitted, keeping the output format unchanged. */
        for (x = 0; x < output_width; ++x) {
            unsigned bit;
            for (bit = 0; bit < 6u && band + bit < output_height; ++bit) {
                unsigned source_x = x / frame->scale_x;
                unsigned source_y = (band + bit) / frame->scale_y;
                present |= 1u << exgc_sixel_pixel_at(frame, source_x, source_y);
            }
        }
        for (color = 0; color < EXGC_SIXEL_PALETTE_SIZE; ++color) {
            unsigned run_count = 0;
            unsigned char run_value = 0;
            if ((present & (1u << color)) == 0) continue;
            if (!first_plane) {
                result = emit_char(writer, writer_context, '$');
                if (result != EXGC_SIXEL_OK) return result;
            }
            first_plane = 0;
            result = emit_char(writer, writer_context, '#');
            if (result != EXGC_SIXEL_OK) return result;
            result = emit_number(writer, writer_context, color);
            if (result != EXGC_SIXEL_OK) return result;
            for (x = 0; x < output_width; ++x) {
                unsigned bit;
                unsigned char bits = 0;
                unsigned char value;
                for (bit = 0; bit < 6u && band + bit < output_height; ++bit) {
                    unsigned source_x = x / frame->scale_x;
                    unsigned source_y = (band + bit) / frame->scale_y;
                    if (exgc_sixel_pixel_at(frame, source_x, source_y) == color) {
                        bits = (unsigned char)(bits | (1u << bit));
                    }
                }
                value = (unsigned char)('?' + bits);
                if (run_count != 0 && value != run_value) {
                    result = emit_repeat(writer, writer_context, run_count, run_value);
                    if (result != EXGC_SIXEL_OK) return result;
                    run_count = 0;
                }
                run_value = value;
                ++run_count;
            }
            result = emit_repeat(writer, writer_context, run_count, run_value);
            if (result != EXGC_SIXEL_OK) return result;
        }
        if (band + 6u < output_height) {
            result = emit_char(writer, writer_context, '-');
            if (result != EXGC_SIXEL_OK) return result;
        }
    }
    return emit(writer, writer_context, "\033\\", 2);
}
