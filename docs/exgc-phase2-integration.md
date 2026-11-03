# EXGC Phase 2: CPU24 memory-mapped framebuffer integration

Phase 2 connects the standalone SIXEL encoder to CPU24's DS `0xFC` segment.
It implements only direct video RAM, the `VIDEO_PAGE` register, palette words,
cold reset, and an explicit host render. It does not add video timing, VBlank,
automatic refresh, sprites, text, interrupts, or EXGC CPU opcodes.

## Memory and MMIO

The entire 64 KiB EXGC segment is ordinary shared CPU24 memory below `F800`.
Framebuffer A is `0000–59FF`; framebuffer B is `5A00–B3FF`. Both the Python
and C executors operate on the same 16 MiB memory array.

`F800–FFFF` is routed through the shared EXGC device implementation. Phase 2
allows only even-aligned 16-bit access there; byte and odd-word accesses are
rejected. Implemented words are:

- `F802 VIDEO_PAGE`: write bit 1 as page A/B. The change takes effect
  immediately. Reads return matching current/requested bits, with VBlank
  command and pending bits zero.
- `F840–F85E PALETTE[0..15]`: writable little-endian RGB555+T words. The
  renderer ignores T (bit 15), as required for final framebuffer composition.

Other current MMIO words read zero and ignore writes. This reserves their ABI
without falsely exposing future timing/sprite/text behavior.

## Reset and rendering

Cold reset clears all 64 KiB, restores the renderer's default palette, selects
framebuffer A, disables graphics mode, and leaves no page flip pending. Python
callers can use `CPU.reset_exgc()`; native callers can use
`cpuCfunc.EXGCReset(memory)`.

Rendering is explicit and independent of page selection/timing:

```python
# Writes a SIXEL stream through vm_console's VIDEO channel; returns byte count.
CPU.render_exgc(3, 2)
# Equivalent native extension call:
cpuCfunc.EXGCRender(CPU.memspace, 3, 2)
```

`EXGCRender` reads whichever page is currently selected. It does not switch
pages, wait for VBlank, update a frame counter, or schedule events.

## Guest program exercise

[`tests/exgc-phase2.asm`](../tests/exgc-phase2.asm) preloads framebuffer A
with palette index 1, enters Ring 1, selects DS `FC`, changes that palette
entry to red, and demonstrates that writing `VIDEO_PAGE` bit 1 switches page
immediately. For a visual SIXEL smoke test, run it in a SIXEL-capable terminal:

```sh
CPUPATH=lib python3 cpu24.py -q -f --exgc-render tests/exgc-phase2.asm
```

After the normal CPU24 status text, the explicit host `--exgc-render` request
emits a 720x384 solid bright-red SIXEL image (3x2 scale). It is deliberately a
host option rather than a guest instruction: ordinary execution does not
automatically refresh video, and rendering remains independent of VBlank or
page selection timing. Omit `--exgc-render` for the normal non-video run.

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
