# EXGC — EX716 Graphics Card

**Hardware and emulator design specification**
**Status:** Draft v0.1 — architecture agreed; register-level details proposed for implementation review
**Date:** 2026-11-03
**Target:** EX716 / CPU24 emulator, including compiled C `-f` fast mode

## 1. Purpose and design principles

EXGC is a hypothetical early-1980s graphics expansion card for the EX716/CPU24 architecture. It is inspired by contemporary framebuffer, character-generator, and sprite-controller hardware rather than reproducing any particular device.

The guest accesses EXGC through a **fixed, memory-mapped 64 KiB data segment, DS 252 (`0xFC`)**. The segment is reserved for video hardware and must not be allocated by lcc for ordinary code or data. Video memory and registers have identical guest-visible behavior regardless of the emulator's execution backend.

The first host display backend is **SIXEL**, implemented in C for the fast emulator. SIXEL is an output transport, **not** part of the guest hardware interface. Alternative backends may be added without changing EXGC programs.

Goals:

- Native 240×192 graphics with 16 simultaneously displayed, programmable RGB555 colors.
- Two fixed-location framebuffer pages with synchronized page flipping.
- Lower-resolution modes using the same framebuffer base addresses.
- Character-generator text display and text-over-graphics overlay.
- 32 hardware sprites using shared pattern storage and attribute records.
- Readable video timing, frame counting, and optional future interrupts.
- Historically plausible software interface, deterministic behavior, and straightforward portable C implementation.

**Conventions:** All offsets are **byte offsets** within DS `0xFC`; 16-bit registers and words are at even offsets. This document does not change CPU24's existing word-addressing or endianness rules. Undefined/reserved register bits read as zero and ignore writes unless otherwise stated. Addresses shown are inclusive.

## 2. Address map

| Offset range | Size (bytes) | Purpose |
|---|---:|---|
| `0000–59FF` | 23,040 | Framebuffer A |
| `5A00–B3FF` | 23,040 | Framebuffer B |
| `B400–DFFF` | 11,264 | Sprite pattern RAM |
| `E000–E3FF` | 1,024 | Sprite attribute RAM |
| `E400–EBFF` | 2,048 | Programmable character generator RAM |
| `EC00–F3FF` | 2,048 | Text cell RAM |
| `F400–F7FF` | 1,024 | Reserved RAM / future expansion |
| `F800–FFFF` | 2,048 | Control, status, palette, and reserved registers |

Total: **65,536 bytes**. Framebuffer B begins at `0x5A00` (not an arbitrary 32 KiB boundary). The second buffer ends at `0xB3FF`.

The region `F800–FFFF` is **MMIO**, not ordinary writable RAM. Register reads/writes must pass through the device interface, including in C fast mode. Other regions behave as RAM unless otherwise specified. Phase 2 requires even-aligned 16-bit accesses to this region; byte and unaligned-word accesses are rejected. This is intentionally stricter than direct video RAM access.

### 2.1 Framebuffer pixel packing

In native graphics mode each pixel is a 4-bit palette index, stored in row-major order without scanline padding:

- Pixel `(x,y)` has linear index `p = y*240 + x`.
- Byte address = framebuffer base + `(p >> 1)`.
- **Proposed packing:** even `x` in high nibble; odd `x` in low nibble.
- `0 ≤ x < 240`, `0 ≤ y < 192`.

Native framebuffer size: `240*192/2 = 23,040 bytes = 0x5A00`.

The selected display page is independent of where software chooses to draw; software may write either framebuffer directly. EXGC does not need a separate hardware draw-page register.

### 2.2 Low-resolution mode

Proposed optional 120×96×4bpp mode uses **only the beginning** of each existing page (`5,760 bytes = 0x1680` per page). Pixel packing is unchanged except for the 120-pixel row stride. Each low-resolution pixel expands to a 2×2 block in the card's 240×192 logical output. **Framebuffer A and B base addresses never move.** Remaining bytes in each page are unaffected and retain their contents.

A possible 240×192×2bpp mode is reserved, not part of the initial implementation. It would need a separate explicit packing specification.

## 3. Palette

There are 16 palette entries, each a 16-bit word:

```text
15       14       10 9         5 4         0
+----------+----------+-----------+----------+
| Sprite T | Red[4:0] | Green[4:0]| Blue[4:0]|
+----------+----------+-----------+----------+
```

- RGB components are unsigned 0–31, scaled to host color values by the display backend.
- Bit 15 (`T`) makes pixels using that palette index **transparent in sprites**. It does **not** make framebuffer pixels transparent.
- Transparency is shared by all sprites because it is a property of the palette entry.
- Palette changes affect subsequently composed frames; no framebuffer rewrite is needed.
- **Phase 2 reset decision:** a cold reset clears the entire 64 KiB EXGC
  segment, then initializes the palette registers from the renderer's default
  16-color palette. This is now the reset palette software may rely on.

## 4. Display modes and text

The principal display types are:

1. **Graphics:** show the selected framebuffer, optionally compositing sprites.
2. **Text:** show the character-cell screen, without requiring the framebuffer to be initialized.
3. **Overlay:** show graphics with a character-cell text layer above it; sprite/text ordering must be specified (see §7).

Proposed text cell formats:

| Text mode | Cell size | Columns × rows | Cells |
|---|---|---|---:|
| Wide text | 6×8 | 40×24 | 960 |
| Standard text | 8×8 | 30×24 | 720 |

The card has 256 programmable glyphs of eight bytes each (`E400–EBFF`). Each byte represents one glyph scanline; for 8×8 use eight bits, for 6×8 use six defined bits (exact bit alignment to be frozen before implementation).

A built-in 8×8 ROM font is available after reset. `TEXT_CONTROL` selects ROM or RAM glyphs. The ROM font is an emulator asset, not stored in the 64 KiB guest segment.

Text RAM (`EC00–F3FF`) contains 16-bit cells: low byte = character code, high byte = attribute. A proposed initial attribute format is foreground palette index in bits 11–8 and background palette index in bits 15–12 (viewed as a 16-bit cell). This uses all eight attribute bits; blinking, underline, and inverse-video need alternate modes or additional controls. For text overlay, a defined background index can mean transparent background, independent of the sprite palette T bit; **exact overlay transparency rule TBD**.

A hardware cursor is optional but its position/control registers are reserved. Text rendering should be done by the video controller, not by guest code painting glyphs into the framebuffer.

## 5. Sprite subsystem

EXGC supports **32 active sprite descriptors** and a shared pattern table. Sprites are composited by the card; they are not permanently drawn into framebuffer RAM.

### 5.1 Sprite patterns

Initial implementation proposal:

- Global sprite size selectable between **8×8** and **16×16**.
- Global magnification selectable between **1×** and **2×**.
- Each sprite uses the same 16-color palette as graphics.
- Patterns use the same packed 4bpp format as framebuffer pixels.
- Pattern slots are packed according to the global sprite size: **32 bytes**
  for 8×8 (two 16-bit words per row), or **128 bytes** for 16×16 (four
  words per row). Rows are contiguous and even-X pixels use the high nibble.
- The 11,264-byte table holds **352** 8×8 slots (`0–351`) or **88** 16×16
  slots (`0–87`). Slot `n` begins at `B400 + n * slot_size`.
- Changing the global sprite size changes the slot-to-memory mapping. Programs
  must arrange or reload pattern data for the selected size.
- Out-of-range pattern references render transparently without reading into
  attribute memory. An error/status flag remains future work.

The pattern table is shared: multiple sprite descriptors can reference the same pattern. 2× magnification duplicates pixels during composition, without increasing pattern RAM usage.

### 5.2 Sprite attributes

Sprite attribute RAM begins at `E000`. Each of 32 descriptors occupies four 16-bit words (8 bytes), so the active table occupies 256 bytes (`E000–E0FF`). The remainder is reserved.

| Word offset | Field | Meaning |
|---|---|---|
| +0 | X | Signed 16-bit horizontal position in logical pixels |
| +2 | Y | Signed 16-bit vertical position in logical pixels |
| +4 | Pattern | Pattern slot index (`0–351` in 8×8 mode; `0–87` in 16×16 mode) |
| +6 | Attributes | Visibility, priority, flipping, rotation |

Attribute bits: bit 0 visible; bit 1 reserved for future priority; bit 2
horizontal flip; bit 3 vertical flip; bits 4–5 rotate clockwise by 0, 90, 180,
or 270 degrees (values 0–3). Remaining bits are reserved. Flips apply to the
source pattern before rotation; magnification and screen clipping follow.
Rotation preserves the sprite's top-left position and needs no extra pattern
storage. Sprites may be partially off-screen; clipping is performed by the card.

Sprite ordering defaults to lower sprite index in front of higher sprite index. A future priority mode may use the descriptor's priority bit. There is no initial artificial per-scanline sprite limit; an optional limit/overflow mode can be introduced for period accuracy.

### 5.3 Collision and status

Collision detection, when enabled, tests overlapping **nontransparent** sprite pixels, not just bounding boxes. Collision and overflow flags should be sticky and cleared by writing 1 to their status bits (W1C). Identifying the exact colliding pair is optional future work.

No autonomous sprite animation engine is planned. Software animates sprites by changing positions, pattern indices, or pattern data in video RAM.

## 6. Proposed control register map

**Implementation status:** `VIDEO_TIMING`, `VIDEO_FRAME`, `VIDEO_PAGE`, the
palette, and the sprite enable/size/magnification/count controls described
below are implemented. Other listed register behavior remains proposed or
reserved until its respective device phase.

| Offset | Name | Access | Purpose |
|---|---|---|---|
| `F800` | `VIDEO_TIMING` | RO | Current scanline and vertical blank |
| `F802` | `VIDEO_PAGE` | RW/mixed | Current, requested page, and swap state |
| `F804` | `VIDEO_MODE` | RW | Display type, resolution, enables |
| `F806` | `VIDEO_STATUS` | RO/W1C | Sticky status flags |
| `F808` | `SPRITE_CONTROL` | RW | Sprite size, magnification, count, enables |
| `F80A` | `SPRITE_TABLE` | RW/reserved | Optional sprite table base (fixed initially) |
| `F80C` | `SPRITE_PATTERN` | RW/reserved | Optional pattern base (fixed initially) |
| `F80E` | `TEXT_CONTROL` | RW | Text cell size, ROM/RAM glyph source |
| `F810` | `TEXT_CURSOR` | RW | Cursor position |
| `F812` | `TEXT_COLOR` | RW | Default text colors / options |
| `F814` | `VIDEO_FRAME` | RO | Wrapping 16-bit frame counter |
| `F816` | `IRQ_CONTROL` | RW/reserved | Future video interrupt enable |
| `F818` | `SPRITE_STATUS` | RO/W1C | Collision, overflow, pattern errors |
| `F81A–F83F` | Reserved | — | Future registers |
| `F840–F85F` | `PALETTE[0..15]` | RW | 16 consecutive RGB555+T words |
| `F860–FFFF` | Reserved | — | Future MMIO |

### 6.1 `VIDEO_TIMING` (`F800`)

- Bits 0–7: visible scanline `0–191`; during VBlank, holds at 191.
- Bit 15: vertical blank active.
- Bits 8–14: reserved.

The deterministic initial timing ratio is **256 retired CPU24 instructions per
scanline**. This yields 67,072 instructions/frame and a nominal emulated clock
of 4.02432 MHz at 60 Hz. It is an EXGC emulation constant, not a measurement or
assumption about host MIPS. Each 256-instruction boundary advances one line;
the frame counter increments when line 261 wraps to line 0. Timing persists
across bounded/unlimited native calls and debugger transitions, and resets only
as part of explicit EXGC device reset.

Timing reflects **emulated video time**, never the time taken to emit SIXEL output. A future cycle-based implementation may derive the scanline from CPU24 emulated cycles; a wall-clock-paced implementation must avoid guest-visible dependence on terminal output throughput. The timing source and interaction with unthrottled `-f` execution remain open design decisions.

### 6.2 `VIDEO_PAGE` (`F802`)

- Bit 0: currently displayed page (`0=A`, `1=B`), read-only.
- Bit 1: requested page (`0=A`, `1=B`), read/write.
- Bit 2: write 1 to request applying the selected page at the next VBlank; reads zero (command strobe).
- Bit 3: swap pending, read-only.
- Other bits reserved.

Writing bit 1 without bit 2 immediately selects that page and clears any
pending deferred request. Writing bit 2 requests the page encoded in bit 1:
the displayed page remains unchanged, requested page updates, and pending sets.
At the 191→VBlank boundary, displayed page becomes requested and pending
clears. If multiple deferred requests arrive before VBlank, the latest wins. A
read returns current page, requested page, and pending state; bit 2 always
reads zero.

The existing immediate bit-1 behavior is retained for compatibility. Host
rendering only reads the already displayed page; it never applies a pending
page change, advances timing, or increments `VIDEO_FRAME`.

### 6.3 `VIDEO_MODE` (`F804`)

| Bits | Proposed meaning |
|---|---|
| 0–1 | `0` graphics, `1` text, `2` overlay, `3` reserved |
| 2–3 | `0` 240×192×4bpp; `1` 120×96×4bpp; `2` future 240×192×2bpp; `3` reserved |
| 4 | Enable sprites |
| 5 | Enable hardware text cursor |
| 6 | Enable display |
| 7 | Enable raster interrupts (reserved initially) |
| 8–15 | Reserved |

The initial implementation supports only bit 4 (sprite enable); the other
`VIDEO_MODE` bits read as zero and ignore writes. The native framebuffer remains
visible without a display-enable bit. The initial implementation need only
support resolution code 0. Resolution code 1 is a planned extension whose buffer locations are already fixed by this specification. Unsupported mode selections must have a defined fallback/error behavior before release.

### 6.4 `SPRITE_CONTROL` (`F808`)

| Bits | Proposed meaning |
|---|---|
| 0 | Sprite engine enabled |
| 1 | Size: `0=8×8`, `1=16×16` |
| 2 | Magnification: `0=1×`, `1=2×` |
| 3 | Collision detection enabled |
| 4 | Scanline overflow detection enabled (future) |
| 5 | Priority mode (future; initially fixed index order) |
| 6–7 | Reserved |
| 8–13 | Active sprite count, `0–32` |
| 14–15 | Reserved |

Global sprite enable in `VIDEO_MODE` and engine enable here are both required
to render sprites. In the initial implementation, bits 0–2 and 8–13 are
writable; count values above 32 render the first 32 descriptors. Bits 3–7 and
14–15 read zero and ignore writes. Collision, overflow, status and interrupts
are not implemented. The two enable bits remain provisional pending ABI freeze.

### 6.5 Status and interrupts

`VIDEO_STATUS` is reserved for frame/VBlank and general device status. `SPRITE_STATUS` bit assignments are proposed as: bit 0 collision; bit 1 scanline overflow; bit 2 invalid pattern; bit 3 collision IRQ pending. Sticky bits use write-one-to-clear. Interrupt delivery is **not required in v1**; reserving the control register does not imply CPU24 already supports video IRQs.

`VIDEO_FRAME` increments once per emulated frame and wraps modulo 65,536 (approximately 18.2 minutes at 60 Hz).

## 7. Composition and layer ordering

The host-side composition stage produces a 240×192 **palette-indexed** image before terminal scaling. The intended conceptual pipeline is:

1. Read the selected graphics framebuffer, or generate the text-only background.
2. Composite sprites with palette-based transparency and clipping.
3. Composite text overlay and optional cursor.
4. Map palette indices to output colors for the chosen host renderer.

**Proposed initial layer order:** framebuffer → sprites → text overlay/cursor. Per-sprite behind-background priority is not fully meaningful with an opaque 4bpp framebuffer; it needs a defined background-transparency/priority rule. Until that is specified, implement fixed sprite-above-graphics ordering and reserve priority bits. Text-only mode may disable sprites, as on some historical VDPs; this remains to be decided.

For collision detection, use sprite pixel occupancy before compositing with text; transparent sprite pixels do not collide.

## 8. SIXEL backend

The SIXEL renderer is a **host implementation detail**. It must not change EXGC guest resolution, sprite coordinates, scanline timing, palette semantics, or memory layout.

### 8.1 Output scaling

The guest-visible framebuffer remains 240×192. The initial renderer offers integer nearest-neighbor scales:

| Horizontal × vertical | SIXEL dimensions | Notes |
|---|---|---|
| `1×1` | 240×192 | Debugging; small in modern terminal |
| `2×2` | 480×384 | Compact |
| **`3×2`** | **720×384** | Proposed default |
| `3×3` | 720×576 | Square-pixel scaling |
| `6×3` | 1440×576 | Large-window mode |

SIXEL pixels are **terminal display pixels**, not character cells. Whether an image fits an 80×24 terminal depends on font size, character-cell pixel dimensions, and terminal behavior. Automatic scale selection may query terminal pixel dimensions, with explicit scale overrides and safe fallback.

The logical 240:192 image ratio is 5:4. `3×2` and `6×3` produce 15:8 physical image ratios; they intentionally stretch the image horizontally. A 4:3 CRT-style aspect correction can be added independently.

### 8.2 Encoding strategy

- Compose sprites and text into a **240×192 8-bit palette-indexed host buffer** (46,080 bytes), separate from guest VRAM.
- Encode SIXEL in six-output-row bands and color planes, directly applying integer scaling; **do not allocate a full enlarged RGB framebuffer**.
- Use SIXEL run-length encoding (`!<count><sixel-character>`) and omit redundant empty runs where possible.
- For 3×2, three source rows form one six-row SIXEL band; for 6×3, two source rows form one band.
- Define/update the terminal's 16 SIXEL palette registers as required by the active EXGC palette.
- Suppress output when the visible image is unchanged; initially send complete frames when dirty.
- Throttle terminal updates independently from emulated video frames; initial target approximately 10–20 terminal updates/second, subject to measurement.
- A blocked or slow terminal output stream must not freeze the guest's simulated video clock or distort scanline semantics.

C implementation should measure **bytes/frame**, encode time, write time, and effective frames/second. Changes to hidden framebuffer pages need not force a visible frame until a page flip. Palette, sprite, font, text, and display-control writes may invalidate the composed image.

SIXEL graphics typically render relative to the terminal cursor; the backend must define cursor placement, image replacement, and cleanup to avoid scrolling or leaving successive images on screen. The first version can assume a dedicated terminal display region.

## 9. Integration with CPU24 and lcc

- Reserve DS `0xFC` in CPU24 segment allocation and document it as unavailable to ordinary lcc-generated code/data.
- Route loads/stores targeting DS `0xFC` through EXGC memory/MMIO handling, in both Python execution and C fast mode as applicable.
- Preserve CPU24's existing byte/word alignment and access conventions. Verify the word at `0xFFFF` is never accessed as a valid aligned 16-bit register.
- Do not expose host pointers or SIXEL state to guest software.
- Device reset must initialize control registers, visible page, sprite state, and ROM font selection. Whether framebuffer RAM is cleared or undefined on reset must be specified.
- **Phase 2 reset decision:** framebuffer/video RAM is cleared, framebuffer A
  is selected, graphics mode is disabled, and no page flip is pending.
- A guest C header may eventually define `EXGC_SEGMENT`, register offsets, bit masks, sprite descriptors, and helper functions. Its memory access strategy must follow CPU24/lcc's actual segmented-memory ABI, not assume conventional flat C pointers.
- The first standalone implementation should test the C SIXEL encoder independently of the CPU24 emulator, then integrate VRAM and MMIO, then sprites and text.

## 10. Suggested implementation sequence

1. **Freeze ABI:** finalize offsets, bit semantics, pixel packing, defaults, and text cell format.
2. **Standalone C renderer:** fixed test image, 16 colors, 3×2 and 6×3 scaling, SIXEL RLE, performance measurements.
3. **Segment mapping:** reserve DS `0xFC`; verify byte/word reads and writes; implement MMIO interception.
4. **Basic graphics:** 240×192×4bpp, palette, page A/B, visible-page selection.
5. **Timing:** scanline, VBlank, frame counter, synchronized page swap, independent terminal refresh.
6. **Text:** ROM glyphs, RAM glyphs, text-only and overlay, cursor.
7. **Sprites:** patterns, 32 descriptors, transparency, clipping, global size/magnification, flips and quarter-turn rotation implemented; collisions remain.
8. **Extensions:** 120×96 mode, interrupts, additional priority rules, auto terminal sizing, other host backends.

## 11. Open design decisions before coding

These are intentionally **not** silently treated as settled hardware behavior:

1. **CPU24 access semantics:** exact guest instructions/API for selecting DS `0xFC` and reading/writing 8-bit packed pixels; byte ordering and word access behavior.
2. **Timing source:** CPU-cycle-based versus wall-clock-paced video, especially when `-f` runs unthrottled; VBlank/scanline behavior when the emulator is paused.
3. **Page control:** whether writes without the VBlank strobe select a page immediately, and precise reset values.
4. **Pixel packing:** high-nibble-first proposal; confirm against CPU24's practical byte operations.
5. **Text attributes:** exact foreground/background layout, overlay transparent-background selection, glyph bit order, cursor encoding.
6. **Sprite priority:** interaction with opaque framebuffer and text overlay; whether text-only mode supports sprites.
7. **Sprite size:** mode-dependent packed 32-byte and 128-byte slots are implemented; per-sprite sizes remain a possible extension.
8. **Register minimalism:** whether fixed sprite tables need writable base-pointer registers at all; whether to consolidate redundant sprite enable bits.
9. **Reset state:** default palette, mode, page, font source, RAM initialization, sprite count, and display enable.
10. **Interrupts and unsupported modes:** whether to reserve only or implement; defined behavior for invalid mode values.
11. **Terminal placement:** SIXEL image origin, replacement, resizing, and avoiding terminal scrolling.

## 12. Acceptance tests

- DS `0xFC` is reserved and accessible without disturbing existing lcc allocations.
- A known pixel pattern produces identical logical images in Python and C execution paths.
- Palette updates change displayed colors without changing framebuffer bytes.
- A hidden-page update is not displayed until selected; VBlank swaps are atomic at the emulated frame boundary.
- Scanline and frame counters progress according to the selected emulated clock, independently of SIXEL throughput.
- ROM text works immediately after reset; RAM glyph edits affect the correct cells.
- Multiple sprites share patterns, clip correctly, and honor palette transparency.
- Sprite collision ignores transparent pixels and sets/clears sticky flags correctly.
- 3×2 SIXEL produces 720×384 output; 6×3 produces 1440×576; no guest-visible coordinate changes.
- Renderer does not emit repeated identical frames unnecessarily and behaves sensibly when terminal SIXEL is unavailable.

---

**Document policy:** Treat this file as the source of truth for EXGC once the proposed ABI is reviewed and frozen. Until then, preserve explicit **TBD/proposed** labels rather than assuming unresolved details are final.
