# EXGC Phase 2 post-integration validation

Validation was run after checkpoint `2872892` on 2026-11-03 with an optimized
native extension (`make -B DEBUG=0`, GCC, `-O2 -DNDEBUG`) under WSL. This is a
validation report, not a hardware-behavior change.

## Automated coverage

`tests/test_exgc_phase2_validation.py` uses the existing
`tests/exgc-phase2.asm` fixture and runs it through the normal assembler and
native fast executor. The fixture enters DS `FC`, writes words directly to
both framebuffer A and B (`1234` and `ABCD` respectively), programs all
sixteen RGB555 palette words by MMIO, and selects pages via `VIDEO_PAGE`.

The validator then fills deterministic bars, checkerboard, and diagonal
patterns in the two direct framebuffer regions, selects each page using the
normal device register path, and invokes `CPU.render_exgc()` at 3x2 and 6x3.
It captures each stream to a temporary file and verifies the DCS introducer,
terminator, raster dimensions, byte count reported by the extension, and a
distinct stream hash per pattern. There are 12 selected-page/pattern/scale
render cases.

It also verifies:

- Python DS/segment-override word access and native `ESO` one-instruction
  prefix both route register operations to DS `FC`.
- An ordinary native DS access to `F800` remains ordinary memory rather than
  EXGC MMIO.
- Native palette write/readback (`PUSH`, `POPI`, `PUSHS`) agrees with Python
  readback and with little-endian NumPy backing bytes.
- Unimplemented aligned words read zero and ignore writes.
- Python device byte and odd-word operations reject with `ValueError`; native
  odd-word access returns `RC_DEVICE_GENERAL_FAIL` (`-10`).

The full regression command passed:

```sh
make -B DEBUG=0 test
```

The expected `Unknown OptCode 255` line is from the pre-existing fast-console
negative test. The new validator passed all 12 renders; a representative run
measured 3x2 temporary-file render calls at 2.79–15.33 ms and 16,048–35,072
bytes, and 6x3 at 7.23–41.00 ms and 23,953–42,065 bytes. These figures include
encoding, C stdio output, and an explicit flush to a local temporary file;
they do **not** measure Windows Terminal's rasterization/presentation time.

The existing encoder-only null-sink benchmark measured 3x2 bars/checker at
8.14/8.55 ms and 6x3 at 24.14/24.33 ms. Output bandwidth, especially for
high-detail images, remains more likely than encoder CPU time to limit refresh
rate.

## Manual Windows Terminal visual and cursor probes

Run these from the repository root in a Windows Terminal profile with SIXEL
enabled:

```sh
CPUPATH=lib python3 tests/test_exgc_phase2_validation.py --emit --scale 3x2 --frames 3
CPUPATH=lib python3 tests/test_exgc_phase2_validation.py --emit --scale 6x3 --frames 3
```

Each sequence alternates framebuffer A/B and emits bars, checkerboard, and
diagonal frames. The harness prints page/pattern/timing metadata to stderr so
it does not contaminate the SIXEL stream. Confirm the palette, high-nibble
first checkerboard ordering, diagonal continuity, page switch, and whether
successive images accumulate or move/scroll the cursor.

For an explicit in-place-placement experiment that does not use the alternate
screen or change a terminal mode, run:

```sh
CPUPATH=lib python3 tests/test_exgc_phase2_validation.py --emit --in-place --scale 3x2 --frames 6
CPUPATH=lib python3 tests/test_exgc_phase2_validation.py --emit --in-place --scale 6x3 --frames 6
```

The host display session saves the normal cursor, uses `CSI H` before every
frame after the first, flushes after each complete frame, then restores the
saved cursor on stop. It neither enables alternate-screen mode nor adds an
automatic refresh loop. Confirm that all six frames replace at the display
origin and that ordinary terminal output resumes at the original cursor when
the harness exits.

**Windows Terminal visual result before this mode (confirmed):** ordinary consecutive SIXEL
frames advance/scroll the terminal, while the `--cursor-home` probe replaces
the image in place. Therefore future host presentation should position the
cursor explicitly before each refresh. This is a terminal presentation policy,
not an EXGC register, page-flip, VBlank, or timing behavior.

## MMIO and backing-memory observations

There is deliberately no separate EXGC register-state allocation in Phase 2.
`VIDEO_PAGE` state and palette values are represented by their bytes in the
shared DS `FC` NumPy array. Consequently, direct NumPy inspection of palette
bytes is meaningful (`0x801f` appears as `1f 80`), and selected-page backing
is `00 00` or `03 00`.

That also means raw host mutation of MMIO backing bytes bypasses the guest
device access rules; it is a test/debugger escape hatch, not a guest-visible
CPU memory-access path. Unsupported-register backing bytes are not state:
guest MMIO reads still return zero and guest writes are ignored. CPU24 byte
instructions are not currently exposed by the native instruction table, so
byte rejection is covered at the shared device/Python memory-access layer;
native unaligned word rejection is covered through actual CPU instructions.

Python's `EXGCDevice` reports invalid MMIO as `ValueError`; native execution
reports the corresponding condition as `RC_DEVICE_GENERAL_FAIL`. The public
CPU execution error framework then handles Python faults using its existing
fatal-error/debugger route. Thus the failure *policy* is consistent (reject),
while the transport differs by backend as it does for other emulator faults.

## VIDEO flush finding and next-step recommendation

Before the in-place session implementation, `vm_console_write(...,
VM_CONSOLE_VIDEO, ...)` used `fwrite()` but did not flush. A child-process pipe
probe rendered a 3x2 solid frame and found no bytes available after 200 ms
while the child remained alive; all 764 bytes appeared only at process exit.
The explicit renderer now flushes after a completed frame.

For the requested
presentation policy, debugger single-step should flush pending VIDEO output at
each completed step, while long running execution should use an
instruction-count presentation cadence derived from a configurable emulated
instruction rate and roughly 24–30 Hz. It must remain independent of EXGC
VBlank timing and must not itself cause a render unless a later frontend policy
explicitly requests one. The exact `N` is therefore `instruction_rate / target
presentation_hz`, not a fixed universal instruction count.

Other than this flush issue, the validation found no CPU/MMIO bypass in the
normal Python/native execution paths and no measurable ordinary NOP-path cost
attributable specifically to EXGC interception. The current 50M-NOP benchmark
was 172.0M instructions/s without events and 174.1M/s with its periodic test
event (the 1.19% difference is run-to-run noise, not a speedup claim); NOPs do
not access EXGC memory.
