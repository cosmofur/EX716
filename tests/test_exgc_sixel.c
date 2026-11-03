#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "exgc_sixel.h"

typedef struct {
    unsigned char *data;
    size_t length;
    size_t capacity;
    size_t fail_after;
} Capture;

typedef struct {
    unsigned width;
    unsigned height;
    unsigned char *pixels;
    unsigned palette_seen;
} Decoded;

static int capture_write(void *context, const void *data, size_t length)
{
    Capture *capture = context;
    unsigned char *new_data;
    if (capture->fail_after != 0 && capture->length + length > capture->fail_after) return 1;
    if (capture->length + length > capture->capacity) {
        size_t capacity = capture->capacity == 0 ? 256u : capture->capacity;
        while (capacity < capture->length + length) capacity *= 2u;
        new_data = realloc(capture->data, capacity);
        if (new_data == 0) return 1;
        capture->data = new_data;
        capture->capacity = capacity;
    }
    memcpy(capture->data + capture->length, data, length);
    capture->length += length;
    return 0;
}

static void capture_free(Capture *capture)
{
    free(capture->data);
    memset(capture, 0, sizeof(*capture));
}

static int capture_contains(const Capture *capture, const char *needle, size_t needle_length)
{
    size_t index;
    if (needle_length > capture->length) return 0;
    for (index = 0; index + needle_length <= capture->length; ++index) {
        if (memcmp(capture->data + index, needle, needle_length) == 0) return 1;
    }
    return 0;
}

static unsigned read_number(const unsigned char *data, size_t length, size_t *position)
{
    unsigned value = 0;
    assert(*position < length && data[*position] >= '0' && data[*position] <= '9');
    while (*position < length && data[*position] >= '0' && data[*position] <= '9') {
        value = value * 10u + (unsigned)(data[*position] - '0');
        ++*position;
    }
    return value;
}

static void require_char(const unsigned char *data, size_t length, size_t *position,
                         unsigned char value)
{
    assert(*position < length && data[*position] == value);
    ++*position;
}

static void decoder_draw(Decoded *decoded, unsigned color, unsigned y, unsigned *x,
                         unsigned char sixel, unsigned repeat)
{
    unsigned count;
    unsigned bit;
    for (count = 0; count < repeat; ++count, ++*x) {
        assert(*x < decoded->width);
        for (bit = 0; bit < 6u; ++bit) {
            if ((sixel & (1u << bit)) != 0 && y + bit < decoded->height) {
                decoded->pixels[(size_t)(y + bit) * decoded->width + *x] =
                    (unsigned char)color;
            }
        }
    }
}

/* Supports precisely the compact SIXEL subset emitted by exgc_sixel.c. */
static Decoded decode(const Capture *capture)
{
    const unsigned char *data = capture->data;
    size_t length = capture->length;
    size_t position = 3;
    unsigned current_color = 0;
    unsigned x = 0;
    unsigned y = 0;
    Decoded decoded;
    assert(length >= 5 && data[0] == 27 && data[1] == 'P' && data[2] == 'q');
    require_char(data, length, &position, '"');
    assert(read_number(data, length, &position) == 1u);
    require_char(data, length, &position, ';');
    assert(read_number(data, length, &position) == 1u);
    require_char(data, length, &position, ';');
    decoded.width = read_number(data, length, &position);
    require_char(data, length, &position, ';');
    decoded.height = read_number(data, length, &position);
    decoded.pixels = malloc((size_t)decoded.width * decoded.height);
    assert(decoded.pixels != 0);
    memset(decoded.pixels, 255, (size_t)decoded.width * decoded.height);
    decoded.palette_seen = 0;
    while (position < length - 2u) {
        unsigned char c = data[position++];
        if (c == '#') {
            current_color = read_number(data, length, &position);
            assert(current_color < EXGC_SIXEL_PALETTE_SIZE);
            if (position < length && data[position] == ';') {
                require_char(data, length, &position, ';');
                assert(read_number(data, length, &position) == 2u);
                require_char(data, length, &position, ';');
                (void)read_number(data, length, &position);
                require_char(data, length, &position, ';');
                (void)read_number(data, length, &position);
                require_char(data, length, &position, ';');
                (void)read_number(data, length, &position);
                decoded.palette_seen |= 1u << current_color;
            }
        } else if (c == '$') {
            x = 0;
        } else if (c == '-') {
            x = 0;
            y += 6u;
        } else if (c == '!') {
            unsigned repeat = read_number(data, length, &position);
            assert(position < length && data[position] >= '?' && data[position] <= '~');
            decoder_draw(&decoded, current_color, y, &x,
                         (unsigned char)(data[position++] - '?'), repeat);
        } else {
            assert(c >= '?' && c <= '~');
            decoder_draw(&decoded, current_color, y, &x, (unsigned char)(c - '?'), 1u);
        }
    }
    assert(data[length - 2u] == 27 && data[length - 1u] == '\\');
    return decoded;
}

static void decoded_free(Decoded *decoded)
{
    free(decoded->pixels);
    decoded->pixels = 0;
}

static void set_pixel(unsigned char *pixels, unsigned stride, unsigned x, unsigned y,
                      unsigned value)
{
    unsigned char *packed = &pixels[(size_t)y * stride + x / 2u];
    if ((x & 1u) == 0) *packed = (unsigned char)((*packed & 15u) | (value << 4));
    else *packed = (unsigned char)((*packed & 0xf0u) | value);
}

static void expect_frame(const EXGCFrame *frame, const unsigned char *expected)
{
    Capture capture = {0};
    Decoded decoded;
    unsigned x, y;
    assert(exgc_sixel_render(frame, capture_write, &capture) == EXGC_SIXEL_OK);
    decoded = decode(&capture);
    assert(decoded.width == frame->width * frame->scale_x);
    assert(decoded.height == frame->height * frame->scale_y);
    assert(decoded.palette_seen == 0xffffu);
    for (y = 0; y < decoded.height; ++y) {
        for (x = 0; x < decoded.width; ++x) {
            assert(decoded.pixels[(size_t)y * decoded.width + x] ==
                   expected[(size_t)y * decoded.width + x]);
        }
    }
    decoded_free(&decoded);
    capture_free(&capture);
}

static void test_pixels_scaling_and_immutability(void)
{
    unsigned char pixels[4] = {0};
    unsigned char original_pixels[4];
    uint16_t palette[16];
    uint16_t original_palette[16];
    unsigned char expected[6 * 8];
    EXGCFrame frame;
    unsigned x, y;
    exgc_sixel_default_palette(palette);
    set_pixel(pixels, 2, 0, 0, 1); set_pixel(pixels, 2, 1, 0, 2); set_pixel(pixels, 2, 2, 0, 3);
    set_pixel(pixels, 2, 0, 1, 4); set_pixel(pixels, 2, 1, 1, 5); set_pixel(pixels, 2, 2, 1, 6);
    memcpy(original_pixels, pixels, sizeof(pixels));
    memcpy(original_palette, palette, sizeof(palette));
    frame = (EXGCFrame){pixels, sizeof(pixels), 3, 2, 2, 2, 3, palette};
    for (y = 0; y < 6; ++y) for (x = 0; x < 6; ++x)
        expected[(size_t)y * 6 + x] = (unsigned char)((y / 3u) * 3u + x / 2u + 1u);
    expect_frame(&frame, expected);
    assert(memcmp(pixels, original_pixels, sizeof(pixels)) == 0);
    assert(memcmp(palette, original_palette, sizeof(palette)) == 0);
}

static void test_partial_band_and_all_colors(void)
{
    unsigned char pixels[16 * 7 / 2] = {0};
    uint16_t palette[16];
    unsigned char expected[16 * 7];
    EXGCFrame frame;
    unsigned x, y;
    exgc_sixel_default_palette(palette);
    for (y = 0; y < 7; ++y) for (x = 0; x < 16; ++x) {
        set_pixel(pixels, 8, x, y, x);
        expected[(size_t)y * 16 + x] = (unsigned char)x;
    }
    frame = (EXGCFrame){pixels, sizeof(pixels), 16, 7, 8, 1, 1, palette};
    expect_frame(&frame, expected);
}

static void test_rgb_rle_validation_and_errors(void)
{
    unsigned char pixels[8] = {0};
    uint16_t palette[16];
    EXGCFrame frame;
    Capture capture = {0};
    unsigned red, green, blue;
    exgc_sixel_default_palette(palette);
    exgc_sixel_rgb555_to_percent(0x8000u | (16u << 10) | (8u << 5) | 31u,
                                 &red, &green, &blue);
    assert(red == 52u && green == 26u && blue == 100u);
    frame = (EXGCFrame){pixels, sizeof(pixels), 16, 1, 8, 1, 1, palette};
    assert(exgc_sixel_pixel_at(&frame, 0, 0) == 0u);
    set_pixel(pixels, 8, 0, 0, 10); set_pixel(pixels, 8, 1, 0, 11);
    assert(exgc_sixel_pixel_at(&frame, 0, 0) == 10u);
    assert(exgc_sixel_pixel_at(&frame, 1, 0) == 11u);
    memset(pixels, 0, sizeof(pixels));
    assert(exgc_sixel_render(&frame, capture_write, &capture) == EXGC_SIXEL_OK);
    assert(capture_contains(&capture, "!16@", 4));
    capture_free(&capture);
    assert(exgc_sixel_render(&frame, 0, 0) == EXGC_SIXEL_INVALID_ARGUMENT);
    frame.stride = 7;
    assert(exgc_sixel_render(&frame, capture_write, &capture) == EXGC_SIXEL_INVALID_ARGUMENT);
    frame.stride = 8;
    frame.buffer_size = 7;
    assert(exgc_sixel_render(&frame, capture_write, &capture) == EXGC_SIXEL_INVALID_ARGUMENT);
    frame.buffer_size = sizeof(pixels);
    capture.fail_after = 1;
    assert(exgc_sixel_render(&frame, capture_write, &capture) == EXGC_SIXEL_WRITE_ERROR);
    capture_free(&capture);
}

int main(void)
{
    test_pixels_scaling_and_immutability();
    test_partial_band_and_all_colors();
    test_rgb_rle_validation_and_errors();
    puts("EXGC SIXEL tests passed");
    return 0;
}
