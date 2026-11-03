# EXGC standalone SIXEL renderer

`exgc_sixel.c` is a host-side, standalone encoder. It has no Python, CPU24,
MMIO, event, or terminal dependency. It turns caller-owned packed indexed
framebuffer memory into a SIXEL byte stream through a callback.

## API and ownership

```c
typedef int (*EXGCWriteCallback)(void *context, const void *data, size_t length);

typedef struct {
    const uint8_t *pixels;
    size_t buffer_size;
    unsigned width, height, stride;
    unsigned scale_x, scale_y;
    const uint16_t *palette;
} EXGCFrame;

int exgc_sixel_render(const EXGCFrame *, EXGCWriteCallback, void *);
```

The caller retains ownership of the framebuffer and its 16-entry palette for
the complete call. The renderer never modifies either. `stride` is bytes per
logical source row and can exceed the packed row size; `buffer_size` must cover
the final logical row. Width, height, strides, scale values, callback, and
overflowed scaled dimensions are validated before any output.

Pixels are 4-bit high-nibble-first: even X is bits 7–4 and odd X is bits 3–0.
The palette is RGB555; bit 15 is ignored. Each five-bit component converts to
SIXEL's 0–100 range with integer nearest-value rounding.

## Encoding

The encoder emits `ESC P q`, raster attributes (`"1;1;width;height`), 16
palette definitions, SIXEL color planes, and `ESC \\`. It processes output in
six-row bands. For each present palette index, a SIXEL character packs the
six vertically replicated nearest-neighbour source pixels; `$` returns to the
left edge between color planes and `-` advances to the next band. Repeated
characters use `!count<char>`; runs of one or two remain literal to avoid a
larger representation. Partial final bands mask nonexistent rows.

No RGB framebuffer or scaled framebuffer is created. The source is sampled
directly with integer division for independent X/Y scaling.

## Commands

```sh
make exgc-sixel
./exgc_sixel_test --pattern bars --scale 3x2 > image.six
./exgc_sixel_test --pattern checker --scale 6x3 --output image.six
make test-exgc-sixel
make benchmark-exgc-sixel
```

Patterns are `bars`, `checker`, `diagonal`, `solid`, `all16`, and `noise`.
The generator writes only SIXEL bytes to stdout; its diagnostics go to stderr.
`--benchmark` uses a counting callback, so it measures encoding rather than
terminal throughput.

## Baseline encoder benchmark

Recorded with `make -B DEBUG=0` (`cc` Ubuntu 13.3.0, `-O2 -DNDEBUG`) on
Linux 6.18.54 x86_64 under WSL. Each case encoded five frames to a null counting
callback; times exclude terminal writes. The one-pass band occupancy change
preserves the prior encoder's byte count in every case. `60 FPS` is the
corresponding encoded stream bandwidth, so it indicates why terminal transport
is likely to dominate high-detail output.

| Pattern | Scale | Bytes/frame | ms/frame | Encoder FPS | 60 FPS stream |
| --- | --- | ---: | ---: | ---: | ---: |
| solid | 1×1 | 494 | 0.15 | 6,468.3 | 28.9 KiB/s |
| solid | 3×2 | 750 | 0.91 | 1,099.6 | 43.9 KiB/s |
| solid | 6×3 | 1,103 | 2.74 | 365.2 | 64.6 KiB/s |
| bars | 1×1 | 8,430 | 1.41 | 708.5 | 493.9 KiB/s |
| bars | 3×2 | 17,134 | 8.19 | 122.0 | 1,003.9 KiB/s |
| bars | 6×3 | 26,543 | 24.56 | 40.7 | 1,555.3 KiB/s |
| checker | 1×1 | 12,874 | 1.50 | 667.1 | 754.3 KiB/s |
| checker | 3×2 | 27,346 | 8.37 | 119.4 | 1,602.3 KiB/s |
| checker | 6×3 | 37,679 | 24.90 | 40.2 | 2,207.8 KiB/s |
| noise | 1×1 | 99,630 | 2.30 | 434.2 | 5,837.7 KiB/s |
| noise | 3×2 | 255,864 | 10.72 | 93.2 | 14,992.0 KiB/s |
| noise | 6×3 | 295,801 | 26.83 | 37.3 | 17,332.1 KiB/s |

The benchmark calls the renderer directly and does not model a blocked terminal
or SIXEL decode/render cost. At high-detail 6×3, transport bandwidth should be
treated as the primary integration risk; the measured encoder itself remains
near 20 FPS before terminal I/O.

## Test coverage

`tests/test_exgc_sixel.c` includes a minimal decoder for this encoder's SIXEL
subset. It validates nibble order, RGB555 conversion, palette definitions,
native scaling, six-row bit placement, color-plane positioning, RLE, partial
bands, source immutability, input bounds, and callback-error propagation.

## Compatibility and future integration

The stream uses standard seven-bit SIXEL DCS syntax and should be accepted by
SIXEL-enabled terminals, including Windows Terminal builds with SIXEL support.
This repository's non-graphical test environment does not visually verify a
Windows Terminal rendering; that remains a manual smoke test. The renderer
does not query terminal capability, clear a screen, hide a cursor, or choose
image placement.

A future EXGC device can pass a composed visible framebuffer to this renderer
and implement `EXGCWriteCallback` through `vm_console`'s `VIDEO` channel. That
integration is intentionally outside this standalone phase.
