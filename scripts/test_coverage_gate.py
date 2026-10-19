import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import coverage_gate as cg  # noqa: E402


class GateTest(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        os.makedirs(os.path.join(self.root, "lib/game"))
        for name, body in {"a.dart": "int f() {\n  return 1;\n}\n", "b.dart": "int g() {\n  return 2;\n}\n"}.items():
            with open(os.path.join(self.root, "lib/game", name), "w") as f:
                f.write(body)

    def run_gate(self, files, spec):
        disk = ["lib/game/a.dart", "lib/game/b.dart"]
        return cg.gate(files, disk, [spec], self.root)

    def test_file_missing_from_lcov_lowers_percentage(self):
        ok, out = self.run_gate({"lib/game/a.dart": [2, 2]}, "lib/game=90")
        self.assertFalse(ok)
        self.assertIn("50.0%", out[0])

    def test_fully_listed_passes(self):
        ok, _ = self.run_gate({"lib/game/a.dart": [2, 2], "lib/game/b.dart": [2, 2]}, "lib/game=90")
        self.assertTrue(ok)

    def test_unknown_prefix_fails(self):
        ok, out = self.run_gate({}, "lib/nope=70")
        self.assertFalse(ok)
        self.assertIn("no files match", out[0])

    def test_comment_and_import_lines_are_not_counted(self):
        path = os.path.join(self.root, "lib/game/c.dart")
        with open(path, "w") as f:
            f.write("// c\nimport 'x.dart';\n\nint h() {\n  return 3;\n}\n")
        self.assertEqual(cg.count_lines(path), 2)

    def test_ignore_file_marker_counts_zero_lines(self):
        path = os.path.join(self.root, "lib/game/d.dart")
        with open(path, "w") as f:
            f.write("// coverage:ignore-file\nabstract class X {\n  void a();\n}\n")
        self.assertEqual(cg.count_lines(path), 0)


if __name__ == "__main__":
    unittest.main()
