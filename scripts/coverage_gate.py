#!/usr/bin/env python3
"""Per-prefix lcov coverage gate.

Usage: coverage_gate.py LCOV_FILE PREFIX=MIN_PERCENT [PREFIX=MIN_PERCENT ...]
A prefix with files but 0 instrumented lines prints "n/a" and passes; a prefix
matching no file at all fails. Files under the prefix that no test imports
(absent from lcov) count as 0 covered of N lines,
unless they carry a `// coverage:ignore-file` comment.
The bare prefix `lib` excludes lib/l10n/generated.
"""
import os
import re
import sys

EXCLUDED = ("lib/l10n/generated",)


def parse(path):
    files, cur = {}, None
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line.startswith("SF:"):
            cur = line[3:].replace("\\", "/")
            files[cur] = [0, 0]
        elif line.startswith("LF:") and cur:
            files[cur][0] = int(line[3:])
        elif line.startswith("LH:") and cur:
            files[cur][1] = int(line[3:])
    return files


_NOISE = re.compile(r"^(//.*|import\b.*|export\b.*|part\b.*|[\s{}()\[\];,]*)$")


def count_lines(path):
    """Rough count of code lines: skips blanks, comments, imports, brace-only lines."""
    with open(path, encoding="utf-8") as f:
        lines = f.read().splitlines()
    if any("coverage:ignore-file" in line for line in lines):
        return 0  # declarations only (interfaces, const data): nothing executable
    return sum(1 for line in lines if not _NOISE.match(line.strip()))


def disk_files(root):
    found = []
    for base, _, names in os.walk(os.path.join(root, "lib")):
        for n in names:
            if n.endswith(".dart"):
                found.append(os.path.relpath(os.path.join(base, n), root).replace("\\", "/"))
    return found


def in_prefix(path, prefix):
    if not (path == prefix or path.startswith(prefix + "/")):
        return False
    return not (prefix == "lib" and path.startswith(EXCLUDED))


def gate(files, disk, specs, root="."):
    """files: lcov map path -> [LF, LH]. Returns (ok, report lines)."""
    ok, out = True, []
    for spec in specs:
        prefix, _, minimum = spec.partition("=")
        total = hit = 0
        matched = False
        for path, (lf, lh) in files.items():
            if in_prefix(path, prefix):
                matched = True
                total += lf
                hit += lh
        for path in disk:
            if in_prefix(path, prefix) and path not in files:
                matched = True
                total += count_lines(os.path.join(root, path))
        if not matched:
            ok = False
            out.append(f"{prefix}: FAIL (no files match this prefix)")
        elif total == 0:
            out.append(f"{prefix}: n/a (no instrumented lines)")
        else:
            pct = 100.0 * hit / total
            passed = pct >= float(minimum)
            ok &= passed
            out.append(f"{prefix}: {pct:.1f}% (min {minimum}) {'OK' if passed else 'FAIL'}")
    return ok, out


def main(argv):
    if len(argv) < 3 or argv[1] in ("-h", "--help"):
        print(__doc__)
        return 0 if argv[1:2] in (["-h"], ["--help"]) else 2
    ok, out = gate(parse(argv[1]), disk_files("."), argv[2:])
    print("\n".join(out))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
