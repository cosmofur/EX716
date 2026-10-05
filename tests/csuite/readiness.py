#!/usr/bin/env python3
"""Persistent EX716 C capability audit; failures are backlog, never expected passes."""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SUITE = Path(__file__).resolve().parent
BAD_BACKEND = re.compile(r"EX716: (?:unsupported|unhandled|malformed)")
RESULT = re.compile(r"(?m)^EX716_AUDIT_RESULT=(-?\d+)\s*$")


def invoke(command, cwd, timeout, env=None, stdin=""):
    try:
        p = subprocess.run(command, cwd=cwd, env=env, input=stdin,
                           capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as e:
        def decode(s):
            return s.decode(errors="replace") if isinstance(s, bytes) else (s or "")
        return None, decode(e.stdout), decode(e.stderr) + "\nTIMEOUT"


def audit(feature, mode, args, artifact_root):
    identity = feature["id"] + "/" + mode
    row = {"id": feature["id"], "mode": mode, "priority": feature["priority"],
           "title": feature["title"], "status": "NOT_TESTED", "stage": "coverage",
           "detail": feature.get("reason", ""), "acceptance": feature["acceptance"]}
    if feature.get("kind") == "planned":
        return row
    if mode == "segmented" and args.cpu.name != "cpu24.py":
        row.update(status="ERROR", detail="segmented mode requires cpu24.py")
        return row
    with tempfile.TemporaryDirectory(prefix="ex716-readiness-") as td:
        work = Path(td)
        evidence = {}

        def finish(status, stage, detail):
            row.update(status=status, stage=stage, detail=detail)
            if artifact_root:
                target = artifact_root / feature["id"] / mode
                target.mkdir(parents=True, exist_ok=True)
                for name, content in evidence.items():
                    (target / name).write_text(content, encoding="utf-8")
                row["artifacts"] = str(target)
            return row

        assembly = []
        units = feature.get("units")
        if units is None:
            if "file" in feature:
                units = [(SUITE / feature["file"]).read_text()]
            else:
                units = [feature["source"]]
        for i, source in enumerate(units):
            c = work / f"unit{i}.c"
            c.write_text(source + "\n", encoding="utf-8")
            evidence[c.name] = source + "\n"
            command = [str(args.cpp), "-N", "-D__EX716__=1", "-I" + str(args.include), str(c)]
            rc, out, err = invoke(command, work, args.timeout)
            evidence[f"unit{i}.cpp.stderr"] = err
            if rc is None:
                return finish("TIMEOUT", "preprocess", err[-1200:])
            if rc != 0:
                return finish("MISSING", "preprocess", err[-1200:])
            preprocessed = work / f"unit{i}.i"
            preprocessed.write_text(out, encoding="utf-8")
            evidence[preprocessed.name] = out
            rc, out, err = invoke([str(args.compiler), "-target=ex716", str(preprocessed)],
                                  args.compiler.parent.parent, args.timeout)
            evidence[f"unit{i}.compiler.stderr"] = err
            evidence[f"unit{i}.asm"] = out
            if rc is None:
                return finish("TIMEOUT", "compile", err[-1200:])
            if feature.get("kind") == "backend-reject":
                pattern = feature.get("diagnostic", "EX716:")
                if rc != 0 and re.search(pattern, err):
                    return finish("PASS", "diagnostic", "unsupported valid C produced a backend diagnostic and nonzero compiler exit")
                if rc == 0:
                    return finish("FAIL", "diagnostic", "unsupported valid C was accepted; expected nonzero exit and " + pattern)
                return finish("FAIL", "diagnostic", "compiler failed without expected backend diagnostic " + pattern + ": " + err[-1000:])
            if feature.get("kind") == "reject":
                return finish("PASS" if rc else "FAIL", "diagnostic",
                              "compiler rejected invalid C" if rc else "invalid C accepted")
            if rc != 0:
                backend_errors = [line.strip() for line in err.splitlines()
                                  if BAD_BACKEND.search(line)]
                errors = [line for line in err.splitlines()
                          if "storage exceeds" in line or ": error" in line]
                detail = backend_errors or errors
                return finish("FAIL", "compile",
                              "\n".join(detail) if detail else err[-1200:])
            bad = BAD_BACKEND.search(err)
            if bad:
                diagnostic = err[bad.start():].splitlines()[0]
                return finish("FAIL", "codegen", "compiler exited 0: " + diagnostic)
            assembly.append(out)
        if len(assembly) > 1:
            names = set()
            for unit in assembly:
                definitions = set(re.findall(r"(?m)^@FUNCTION (\S+)", unit))
                collision = names & definitions
                if collision:
                    return finish("FAIL", "codegen", "translation-unit function names collide: " + ", ".join(sorted(collision)))
                names.update(definitions)
        if feature.get("kind") == "header":
            return finish("PASS", "compile", "public header compiles; runtime not assessed")
        prefix = [".DATA 1", "I commonDS.mc"] if mode == "segmented" else ["I common.mc"]
        harness = prefix + ["@JMP __audit_entry", "L clocals.ld", "L lmath.ld"]
        for runtime in args.runtime:
            harness.append("L " + str(runtime))
        harness += assembly + [".ORG 0x7000", ":__audit_entry"]
        if mode != "classic":
            harness += [".ENTRY __audit_entry"]
        if mode == "segmented":
            harness += ["@PUSH 1", "@SSET SegDS", "@PUSH 1", "@ADM"]
        harness += ['@PRT "EX716_AUDIT_OUTPUT_BEGIN\\n"', "@CALL main",
                    '@PRT "\\nEX716_AUDIT_OUTPUT_END\\n"',
                    '@PRT "EX716_AUDIT_RESULT="', "@PRTTOP", "@POPNULL", "@PRTNL",
                    # C frames must restore both software stack and frame pointer.
                    "@PUSHI __SS_SP", "@PRT \"EX716_AUDIT_SP=\"", "@PRTHEXTOP", "@POPNULL", "@PRTNL",
                    "@PUSHI __C_FP", "@PRT \"EX716_AUDIT_FP=\"", "@PRTHEXTOP", "@POPNULL", "@PRTNL",
                    "@StackDump"]
        if mode == "segmented":
            harness += ["@PUSH 0", "@ADM"]
        harness += ["@END", ""]
        asm = "\n".join(harness)
        (work / "harness.asm").write_text(asm, encoding="utf-8")
        evidence["harness.asm"] = asm
        env = dict(os.environ, CPUPATH=str(ROOT / "lib") + os.pathsep + str(work))
        cpu = ROOT / "cpu.py" if mode == "classic" else args.cpu
        rc, out, err = invoke([sys.executable, str(cpu), str(work / "harness.asm")],
                              work, args.timeout, env, feature.get("stdin", ""))
        evidence["cpu.stdout"] = out
        evidence["cpu.stderr"] = err
        if rc is None:
            return finish("TIMEOUT", "execute", "emulator exceeded per-stage timeout")
        if "Unresolved symbols: 0" not in out:
            missing = out.split("=== Missing Symbols ===", 1)
            detail = missing[1].split("=== Summary ===", 1)[0].strip() if len(missing) == 2 else (out + err)[-1600:]
            return finish("FAIL", "assemble", detail)
        if rc:
            return finish("FAIL", "execute", (out + err)[-1600:])
        matches = RESULT.findall(out)
        if len(matches) != 1:
            return finish("FAIL", "execute", "missing/duplicate result marker: " + (out + err)[-1200:])
        if int(matches[0]) != 0:
            return finish("FAIL", "result", "main returned " + matches[0])
        if "ex716_audit_sp=fff2" not in out.lower():
            return finish("FAIL", "abi", "software stack not restored")
        if "EX716_AUDIT_FP=0000" not in out:
            return finish("FAIL", "abi", "C frame pointer not restored")
        if not re.search(r"Stack:\(empty\)", out + err):
            return finish("FAIL", "abi", "hardware stack not empty after result pop")
        output = out.split("EX716_AUDIT_OUTPUT_BEGIN\n", 1)[-1].split("\nEX716_AUDIT_OUTPUT_END", 1)[0]
        if "stdout" in feature and output != feature["stdout"]:
            return finish("FAIL", "output", f"expected {feature['stdout']!r}; got {output!r}")
        if "stderr_pattern" in feature and not re.search(feature["stderr_pattern"], err, re.MULTILINE):
            return finish("FAIL", "output", "stderr did not match " + feature["stderr_pattern"])
        return finish("PASS", "execute", "result, frame restoration, and stack balance passed")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--compiler", type=Path, default=ROOT.parent / "lcc/build/rcc")
    p.add_argument("--cpp", type=Path, default=ROOT.parent / "lcc/build/cpp")
    p.add_argument("--include", type=Path, default=ROOT.parent / "lcc/include/ex716")
    p.add_argument("--cpu", type=Path, default=ROOT / "cpu24.py")
    p.add_argument("--runtime", type=Path, action="append", default=[], help="C ABI adapter .ld; repeatable")
    p.add_argument("--manifest", type=Path, default=SUITE / "features.json")
    p.add_argument("--modes", default="segmented", help="comma-separated classic,cpu24,segmented")
    p.add_argument("--filter", action="append", default=[],
                   help="substring of feature ID; repeat to select several IDs")
    p.add_argument("--timeout", type=float, default=60)
    p.add_argument("--jobs", type=int, default=4)
    p.add_argument("--json", type=Path, help="machine-readable results")
    p.add_argument("--compare", type=Path, help="report status changes from an earlier JSON run")
    p.add_argument("--artifacts", type=Path, help="save sources, assembly and logs for every executable probe")
    args = p.parse_args()
    for key in ("compiler", "cpp", "cpu", "include"):
        setattr(args, key, getattr(args, key).resolve())
    args.runtime = [x.resolve() for x in args.runtime]
    for path in [args.compiler, args.cpp, args.cpu] + args.runtime:
        if not path.is_file():
            p.error(f"missing tool/runtime: {path}; build with make -C ../lcc BUILDDIR=build rcc cpp")
    modes = args.modes.split(",")
    if set(modes) - {"classic", "cpu24", "segmented"} or args.jobs < 1 or args.timeout <= 0:
        p.error("invalid modes, jobs or timeout")
    manifest = json.loads(args.manifest.read_text())
    features = manifest["features"]
    ids = [f["id"] for f in features]
    if len(set(ids)) != len(ids):
        p.error("duplicate feature IDs")
    features = [f for f in features
                if not args.filter or any(token in f["id"] for token in args.filter)]
    if not features:
        p.error("no matching features")
    artifact_root = args.artifacts.resolve() if args.artifacts else None
    tasks = [(f, m) for f in features for m in modes]
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = [pool.submit(audit, f, m, args, artifact_root) for f, m in tasks]
        rows = []
        for (f, m), future in zip(tasks, futures):
            try:
                row = future.result()
            except Exception as e:
                row = {"id": f["id"], "mode": m, "priority": f["priority"],
                       "title": f["title"], "status": "ERROR", "stage": "runner", "detail": str(e)}
            rows.append(row)
            print(f"{row['status']:10} {row['priority']} {row['id']}/{m} [{row['stage']}]", flush=True)
            if row["status"] not in ("PASS", "NOT_TESTED"):
                detail = row.get("detail") or "(no diagnostic detail)"
                print("  " + detail.splitlines()[0][:240], flush=True)
    counts = dict(Counter(r["status"] for r in rows))
    changes = []
    if args.compare:
        previous = {(r["id"], r["mode"]): r["status"] for r in json.loads(args.compare.read_text())["results"]}
        for row in rows:
            before = previous.get((row["id"], row["mode"]), "NEW")
            if before != row["status"]:
                changes.append({"id": row["id"], "mode": row["mode"], "before": before, "after": row["status"]})
                print(f"CHANGE {row['id']}/{row['mode']}: {before} -> {row['status']}")
    report = {"schema": 1, "scope": manifest["scope"], "counts": counts,
              "tools": {str(x): hashlib.sha256(x.read_bytes()).hexdigest()
                        for x in [args.compiler, args.cpp, args.cpu] + args.runtime},
              "manifest_sha256": hashlib.sha256(args.manifest.read_bytes()).hexdigest(),
              "source_sha256": {str(x.relative_to(ROOT.parent)): hashlib.sha256(x.read_bytes()).hexdigest()
                                for x in [ROOT.parent / "lcc/src/ex716.c", ROOT / "cpu.py", ROOT / "cpu24.py"]
                                + sorted((ROOT / "lib").glob("*.ld"))
                                + sorted((ROOT / "lib").glob("*.mc"))
                                + sorted((SUITE / "cases").rglob("*.c"))
                                + sorted((SUITE / "probes").glob("*.c"))},
              "results": rows, "changes": changes}
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(report, indent=2) + "\n")
    print("\n" + ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))
    return int(any(r["status"] != "PASS" for r in rows))


if __name__ == "__main__":
    raise SystemExit(main())
