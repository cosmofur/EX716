import contextlib
import io
import tempfile
import unittest
from pathlib import Path

import numpy as np

import cpu24


class Exc01Tests(unittest.TestCase):
    def make_image(self, path):
        context = cpu24.AssemblerContext()
        context.EntryBank = 3
        context.Entry = 0x0234
        context.EntryExplicit = True
        context.InitialDS = 7
        context.SegmentHighWater = {3: 0x0600, 7: 1}
        context.CodeSegments = {3}
        context.DataSegments = {7}
        machine = cpu24.microcpu(0, cpu24.MAXPHYSMEM)
        machine.memspace[(3 << 16):(3 << 16) + 0x0600] = np.arange(
            0x0600, dtype=np.uint16
        ).astype(np.uint8)
        machine.memspace[7 << 16] = 0x5a
        cpu24.write_exc01(path, "round trip", machine, context)
        return machine

    def test_round_trip(self):
        with tempfile.TemporaryDirectory() as tempdir:
            path = Path(tempdir) / "program.exc"
            original = self.make_image(path)
            raw = path.read_bytes()

            self.assertEqual(raw[:5], b"EXC01")
            self.assertEqual(raw[5:10], bytes((3, 0x34, 0x02, 7, 2)))
            self.assertEqual(len(raw), 512 + (3 + 1) * 512)

            restored = cpu24.microcpu(0, cpu24.MAXPHYSMEM)
            restored_context = cpu24.AssemblerContext()
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                descriptors = cpu24.load_exc01(path, restored, restored_context)

            self.assertEqual(descriptors, [(0, 3, 3), (1, 7, 1)])
            self.assertIn("round trip", output.getvalue())
            self.assertEqual(restored.CS, 3)
            self.assertEqual(restored.pc, 0x0234)
            self.assertEqual(restored.DS, 7)
            self.assertEqual(restored.ES, 7)
            self.assertEqual(restored.SegmentMode, 1)
            np.testing.assert_array_equal(
                restored.memspace[3 << 16:(3 << 16) + 0x0600],
                original.memspace[3 << 16:(3 << 16) + 0x0600],
            )
            self.assertEqual(restored.memspace[7 << 16], 0x5a)

    def test_duplicate_memory_segment_is_rejected(self):
        with tempfile.TemporaryDirectory() as tempdir:
            path = Path(tempdir) / "program.exc"
            self.make_image(path)
            raw = bytearray(path.read_bytes())
            raw[15] = raw[11]
            path.write_bytes(raw)

            with self.assertRaisesRegex(ValueError, "described twice"):
                cpu24.load_exc01(
                    path,
                    cpu24.microcpu(0, cpu24.MAXPHYSMEM),
                    cpu24.AssemblerContext(),
                )


if __name__ == "__main__":
    unittest.main()
