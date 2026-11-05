# EXGC Phase 2: CPU24 memory-mapped framebuffer integration

Phase 2 connected the standalone SIXEL encoder to CPU24's DS `0xFC` segment.
Subsequent work added instruction-clocked video timing, VBlank page flips,
an opt-in automatic host refresh, and initial sprite composition. Text,
interrupts, sprite collision/status, and EXGC CPU opcodes remain unimplemented. The register details below describe current
behavior; the benchmarks and Phase 2 fixture describe their original scope.

## Memory and MMIO

The entire 64 KiB EXGC segment is ordinary shared CPU24 memory below `F800`.
Framebuffer A is `0000–59FF`; framebuffer B is `5A00–B3FF`. Both the Python
and C executors operate on the same 16 MiB memory array.

`F800–FFFF` is routed through the shared EXGC device implementation. Phase 2
allows only even-aligned 16-bit access there; byte and odd-word accesses are
rejected. Implemented words are:

- `F800 VIDEO_TIMING`: read-only scanline and VBlank status.
- `F802 VIDEO_PAGE`: write bit 1 to select A/B immediately, or set bit 2 to
  request that selection at the next VBlank. Reads report the displayed page,
  requested page, and pending state.
- `F804 VIDEO_MODE`: bit 4 enables sprites; other bits are reserved.
- `F808 SPRITE_CONTROL`: sprite engine enable, size, magnification, and count.
- `F814 VIDEO_FRAME`: read-only, wrapping frame counter.
- `F840–F85E PALETTE[0..15]`: writable little-endian RGB555+T words. The
  renderer ignores T (bit 15), as required for final framebuffer composition.

Other current MMIO words read zero and ignore writes. This reserves their ABI
without falsely exposing future sprite status or text behavior.

## Reset and rendering

Cold reset clears all 64 KiB, restores the renderer's default palette, selects
framebuffer A, resets scanline and frame counters, and leaves no page flip
pending. `VIDEO_MODE` currently implements only sprite enable, so reset does
not provide an operational display-enable control. Python callers can use `CPU.reset_exgc()`; native callers can use
`cpuCfunc.EXGCReset(memory)`.

Explicit rendering reads the currently selected page independently of video timing:

```python
# Writes a SIXEL stream through vm_console's VIDEO channel; returns byte count.
CPU.render_exgc(3, 2)
# Equivalent native extension call:
cpuCfunc.EXGCRender(CPU.memspace, 3, 2)
```

`EXGCRender` reads whichever page is currently selected. It does not switch
pages, wait for VBlank, update a frame counter, or schedule events.

### Explicit in-place terminal presentation

For a host-managed normal-screen display session, use:

```python
CPU.start_exgc_display()
try:
    CPU.render_exgc(3, 2)
    # Modify the selected framebuffer, then render later frames.
    CPU.render_exgc(3, 2)
finally:
    CPU.stop_exgc_display()
```

Start saves the normal cursor then establishes terminal home as a stable
display origin. Every render after the first explicitly returns to home before
emitting its SIXEL frame, so it does not rely on SIXEL's post-image cursor
position. Stop restores the saved cursor; it uses neither alternate-screen
mode nor a full-terminal clear. `EXGCRender` flushes once after a complete
frame, never once per encoder callback.

While the session is active, native guest `CAST` output uses the existing
bounded 8 KiB guest-text buffer rather than overwriting the display. On stop,
that text is released at the restored normal cursor and direct guest output is
restored. Host diagnostics remain on stderr throughout. If the terminal
reports pixel viewport dimensions and a requested rendered frame is too large,
rendering fails before emission rather than scrolling; terminals that do not
report pixel dimensions are allowed, because a safe pixel-to-cell estimate is
not available. Resizing is checked before every frame.

## Video timing and automatic refresh

Video timing advances every 256 retired CPU24 instructions per scanline, with
192 visible lines and 262 total lines. `VIDEO_TIMING` exposes the current
visible line and VBlank flag; `VIDEO_FRAME` increments when the scanline wraps.
A deferred `VIDEO_PAGE` request takes effect at the transition from visible
line 191 to VBlank. Immediate page selection remains available. See
[EXGC.md](../EXGC.md) for the exact register bits and boundary behavior.

With `--exgc-render`, the native event service schedules presentation every
1,000,000 retired instructions. This is a provisional instruction-count
cadence, not a guaranteed wall-clock frame rate or a VBlank trigger. Explicit
host rendering does not advance the guest video clock or apply pending flips.
The automatic path currently emits frames without dirty-frame suppression;
terminal output can consume host time. An optional `EXGCHostRefresher` also
provides a caller-polled wall-clock presentation policy for host integrations.

`tests/test_exgc_timing.py` covers the native scanline/frame clock, immediate
and deferred page selection, VBlank boundary, reset, and the fact that an
explicit render does not alter timing or page state.

## Guest program exercise

[`tests/exgc-phase2.asm`](../tests/exgc-phase2.asm) preloads framebuffer A
with palette index 1, enters Ring 1, selects DS `FC`, changes that palette
entry to red, and demonstrates that writing `VIDEO_PAGE` bit 1 switches page
immediately. For a visual SIXEL smoke test, run it in a SIXEL-capable terminal:

```sh
CPUPATH=lib python3 cpu24.py -q -f --exgc-render tests/exgc-phase2.asm
```

The host `--exgc-render` option starts an in-place display session, enables
instruction-clocked automatic refresh during execution, and renders once more
on exit. The fixture produces a 720x384 solid bright-red SIXEL image (3x2
scale). Omit the option for a normal non-video run. Rendering is a host
presentation action, independent of the guest's VBlank and page-flip clock.

For repeated in-place Windows Terminal verification, use the dedicated host
harness (not a guest instruction):

```sh
CPUPATH=lib python3 tests/test_exgc_phase2_validation.py --emit --in-place --scale 3x2 --frames 6
CPUPATH=lib python3 tests/test_exgc_phase2_validation.py --emit --in-place --scale 6x3 --frames 6
```

## Validation and performance

`tests/test_exgc_device.c` validates reset, palettes, immediate page changes,
invalid MMIO accesses, and selected-page render output. `tests/test_exgc_cpu24.py`
executes a native CPU24 aligned word store with DS `FC` and confirms Python
observes the same memory-backed MMIO state.

On the optimized event-clock NOP benchmark, this integration measured 165.9M
no-event instructions/s versus the previously recorded 173.9M/s. NOPs do not
access data/MMIO and host variance is visible across runs, so this is an
observed comparison rather than a proven EXGC access penalty. Renderer output
performance remains the standalone encoder benchmark; integration copies only
the 16 palette words before rendering.
