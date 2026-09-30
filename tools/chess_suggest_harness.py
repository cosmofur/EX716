#!/usr/bin/env python3
"""Drive tests/chess.asm through stdio and check suggested moves.

This is intentionally dependency-free.  It can run simple curated positions now,
and leaves a clean place to add python-chess/Stockfish ranking later.
"""

from __future__ import annotations

import argparse
import json
import re
import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, TextIO


BEST_MOVE_RE = re.compile(r"Best move:\s*([a-h][1-8][a-h][1-8])\s+value\s+(-?\d+)")
NO_MOVE_RE = re.compile(r"No legal move found\.")


@dataclass
class SuggestCase:
    name: str
    board: list[str] | None
    expected_any: set[str]
    moves_before: list[str]
    stdin_extra: list[str]
    suggest_depth: int | None


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def validate_board(name: str, board: list[str] | None) -> None:
    if board is None:
        return
    if len(board) != 8:
        raise ValueError(f"{name}: board must contain 8 rows")
    allowed = set("KQRBNPkqrbnp .")
    for row in board:
        if len(row) != 8:
            raise ValueError(f"{name}: board row must be 8 characters: {row!r}")
        bad = set(row) - allowed
        if bad:
            raise ValueError(f"{name}: invalid board character(s): {sorted(bad)!r}")


def command_script(case: SuggestCase) -> str:
    lines: list[str] = []
    if case.board is not None:
        # B = visual board edit mode, rank 8 down to rank 1.
        lines.append("B")
        lines.extend(case.board)
    lines.extend(case.moves_before)
    lines.extend(case.stdin_extra)
    ask = "?" if case.suggest_depth is None else f"?{case.suggest_depth}"
    lines.append(ask)
    lines.append("q")
    return "\n".join(lines) + "\n"


def run_case(case: SuggestCase, *, cpu: Path, asm: Path, timeout: float) -> tuple[int, str]:
    validate_board(case.name, case.board)
    proc = subprocess.run(
        [sys.executable, str(cpu), str(asm)],
        input=command_script(case),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
        cwd=repo_root(),
        env={"CPUPATH": "lib"},
        check=False,
    )
    return proc.returncode, proc.stdout


def parse_suggestion(output: str) -> tuple[str | None, int | None]:
    matches = BEST_MOVE_RE.findall(output)
    if matches:
        move, score = matches[-1]
        return move, int(score)
    if NO_MOVE_RE.search(output):
        return None, None
    return None, None



class StockfishUCI:
    def __init__(self, path: str, *, movetime_ms: int = 200):
        self.movetime_ms = movetime_ms
        self.proc = subprocess.Popen(
            [path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        assert self.proc.stdin is not None
        assert self.proc.stdout is not None
        self.stdin: TextIO = self.proc.stdin
        self.stdout: TextIO = self.proc.stdout
        self._send("uci")
        self._read_until("uciok")
        self._send("isready")
        self._read_until("readyok")

    def close(self) -> None:
        if self.proc.poll() is None:
            try:
                self._send("quit")
            except BrokenPipeError:
                pass
            try:
                self.proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.proc.kill()

    def _send(self, line: str) -> None:
        self.stdin.write(line + "\n")
        self.stdin.flush()

    def _read_until(self, token: str) -> list[str]:
        lines: list[str] = []
        while True:
            line = self.stdout.readline()
            if line == "":
                raise RuntimeError("stockfish exited unexpectedly")
            line = line.rstrip("\n")
            lines.append(line)
            if line == token or line.startswith(token + " "):
                return lines

    def bestmove(self, moves: list[str]) -> str:
        suffix = "" if not moves else " moves " + " ".join(moves)
        self._send("position startpos" + suffix)
        self._send(f"go movetime {self.movetime_ms}")
        for line in self._read_until("bestmove"):
            if line.startswith("bestmove "):
                move = line.split()[1]
                if move == "(none)":
                    raise RuntimeError("stockfish reported no legal move")
                return move
        raise RuntimeError("stockfish did not report bestmove")


def ex716_suggest(
    moves_before: list[str], *, timeout: float, suggest_depth: int | None
) -> tuple[str | None, int | None, str]:
    case = SuggestCase(
        name="stockfish game position",
        board=None,
        expected_any=set(),
        moves_before=moves_before,
        stdin_extra=[],
        suggest_depth=suggest_depth,
    )
    code, output = run_case(
        case,
        cpu=repo_root() / "cpu.py",
        asm=repo_root() / "tests" / "chess.asm",
        timeout=timeout,
    )
    move, score = parse_suggestion(output)
    if code != 0:
        raise RuntimeError(summarize_output(output))
    return move, score, output


def run_stockfish_game(
    *,
    engine_path: str,
    plies: int,
    movetime_ms: int,
    timeout: float,
    ex716_depth: int | None,
) -> int:
    moves: list[str] = []
    engine = StockfishUCI(engine_path, movetime_ms=movetime_ms)
    try:
        for ply in range(1, plies + 1):
            side = "white" if ply % 2 else "black"
            if side == "white":
                move, score, _output = ex716_suggest(
                    moves, timeout=timeout, suggest_depth=ex716_depth
                )
                if move is None:
                    print(f"{ply:02d}. EX716 has no suggested move; game stops")
                    return 0
                moves.append(move)
                score_text = "" if score is None else f" score={score}"
                depth_text = "" if ex716_depth is None else f" depth={ex716_depth}"
                print(f"{ply:02d}. EX716 {move}{score_text}{depth_text}")
            else:
                move = engine.bestmove(moves)
                moves.append(move)
                print(f"{ply:02d}. Stockfish {move}")
        print("moves:", " ".join(moves))
        return 0
    finally:
        engine.close()

def load_cases(path: Path | None) -> list[SuggestCase]:
    if path is None:
        return builtin_cases()
    raw = json.loads(path.read_text())
    cases = raw["cases"] if isinstance(raw, dict) and "cases" in raw else raw
    result: list[SuggestCase] = []
    for item in cases:
        result.append(
            SuggestCase(
                name=item["name"],
                board=item.get("board"),
                expected_any=set(item.get("expected_any", [])),
                moves_before=item.get("moves_before", []),
                stdin_extra=item.get("stdin_extra", []),
                suggest_depth=item.get("suggest_depth"),
            )
        )
    return result


def builtin_cases() -> list[SuggestCase]:
    return [
        SuggestCase(
            name="starting position returns a legal-looking knight move",
            board=None,
            expected_any={"b1c3", "g1f3"},
            moves_before=[],
            stdin_extra=[],
            suggest_depth=None,
        ),
        SuggestCase(
            name="white queen can capture exposed black queen",
            board=[
                "....k...",
                "........",
                "........",
                "...q....",
                "........",
                "........",
                "........",
                "....K..Q",
            ],
            expected_any={"h1d5"},
            moves_before=[],
            stdin_extra=[],
            suggest_depth=None,
        ),
    ]


def summarize_output(output: str, max_lines: int = 18) -> str:
    interesting: list[str] = []
    for line in output.splitlines():
        if (
            "Best move:" in line
            or "No legal move" in line
            or "Error" in line
            or "unresolved" in line.lower()
            or "Internal error" in line
        ):
            interesting.append(line)
    if not interesting:
        interesting = output.splitlines()[-max_lines:]
    return "\n".join(interesting[-max_lines:])


def run_all(cases: Iterable[SuggestCase], *, timeout: float, verbose: bool) -> int:
    root = repo_root()
    cpu = root / "cpu.py"
    asm = root / "tests" / "chess.asm"
    failures = 0
    for case in cases:
        try:
            code, output = run_case(case, cpu=cpu, asm=asm, timeout=timeout)
            move, score = parse_suggestion(output)
        except subprocess.TimeoutExpired:
            failures += 1
            print(f"FAIL {case.name}: timed out after {timeout:g}s")
            continue
        except Exception as exc:  # keep test runner useful while iterating cases
            failures += 1
            print(f"FAIL {case.name}: {exc}")
            continue

        ok = code == 0 and (not case.expected_any or move in case.expected_any)
        status = "PASS" if ok else "FAIL"
        score_text = "" if score is None else f" value={score}"
        print(f"{status} {case.name}: move={move or 'none'}{score_text}")
        if not ok:
            failures += 1
            if case.expected_any:
                print(f"  expected one of: {', '.join(sorted(case.expected_any))}")
            print("  output:")
            print("  " + summarize_output(output).replace("\n", "\n  "))
        elif verbose:
            print("  " + summarize_output(output).replace("\n", "\n  "))
    return 1 if failures else 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cases", type=Path, help="JSON case file; defaults to built-in smoke cases")
    parser.add_argument("--timeout", type=float, default=20.0, help="seconds per EX716 run")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--engine", default=os.environ.get("STOCKFISH", "/usr/games/stockfish"))
    parser.add_argument("--engine-movetime", type=int, default=200, help="Stockfish think time in ms")
    parser.add_argument("--ex716-depth", type=int, choices=range(1, 10), metavar="1-9")
    parser.add_argument("--stockfish-game", type=int, metavar="PLIES", help="play EX716 as white against Stockfish")
    args = parser.parse_args(argv)
    if args.stockfish_game is not None:
        return run_stockfish_game(
            engine_path=args.engine,
            plies=args.stockfish_game,
            movetime_ms=args.engine_movetime,
            timeout=args.timeout,
            ex716_depth=args.ex716_depth,
        )
    return run_all(load_cases(args.cases), timeout=args.timeout, verbose=args.verbose)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
