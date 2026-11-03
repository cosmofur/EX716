# EXGC SIXEL solid-colour profile

Profile date: 2026-11-03. The initial investigation made no change; the
one-pass occupancy optimization described below was subsequently implemented
at the user's direction.

## Method

The standalone pattern generator was compiled outside the repository with
`cc -std=c99 -O2 -g -pg -I. tests/exgc_sixel_test.c exgc_sixel.c` and run with
`--benchmark`. The benchmark uses its existing counting callback, not stdout
or a terminal, so its timing excludes terminal transmission, SIXEL decoding,
and terminal drawing. A second `-O0 -pg` run retained individual helper calls
to identify the hot operation.

The optimized `gprof` run assigned 97.9% of sampled time to
`exgc_sixel_render`; the counting callback and RLE emission helpers together
were below 2%. In the unoptimized call-count profile,
`exgc_sixel_pixel_at` accounted for 47.0% of time and was called 781,056,000
times over the 72 benchmark renders. At `-O2` that helper is inlined, so its
cost appears inside `exgc_sixel_render`.

## Why a 1 KiB solid 6×3 frame takes about 24 ms

The 6×3 output is 1,440×576: 96 SIXEL bands of six rows. For each band, the
current renderer scans every output column and six output rows for **each of
16 palette indices** before deciding whether that plane has any pixels. A solid
frame therefore performs this empty-plane discovery work:

```text
96 bands × 16 colors × 1,440 columns × 6 rows = 13,271,040 pixel fetches
```

The one nonempty color plane is then scanned again to emit it:

```text
96 × 1 × 1,440 × 6 = 829,440 further pixel fetches
```

That is approximately **14.1 million packed-pixel fetches**, each involving
runtime scale division and source address calculation, to produce a stream of
only 1,103 bytes. The measured normal optimized benchmark was 23.93 ms/frame
(41.8 FPS); the `-pg` build measured 26.4 ms/frame, consistent with profiling
instrumentation overhead.

Therefore the cost is not inherent to SIXEL RLE: a solid frame naturally has
very little encoded output. It is an avoidable implementation cost from
discovering that 15 planes are empty once per band.

## Implemented occupancy optimization

The renderer now scans each output band once to build 16 `present[color]`
flags, then generates only present planes. It requires no allocation and keeps
the callback/API/stream format and emitted byte counts unchanged.

- Solid 6×3 would drop from about 14.1M fetches to about 1.66M (one presence
  scan plus the single emitted plane), roughly an 8.5× reduction in this hot
  work.
- A fully populated/noisy band would drop from about 26.5M to about 14.1M
  fetches, because the existing implementation currently scans every plane
  twice.

The follow-up optimized null-sink benchmark measured solid 6×3 at 2.74 ms
(365.2 FPS) rather than 23.93 ms (41.8 FPS), an approximately 8.7× improvement.
Noisy 6×3 improved from 49.92 ms to 26.83 ms (about 1.9×). The existing
benchmark still makes many small callback calls for detailed images; that was
insignificant with the null sink, but a future `VIDEO` integration should
measure buffered stream writes separately.
