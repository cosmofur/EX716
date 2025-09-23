#!/usr/bin/env python3
import re
import argparse
from pathlib import Path

# Keywords that imply open/close nesting
OPENERS = {
    "@WHILE_ZERO", "@WHILE_NOTZERO", "@WHILE_EQ_A", "@WHILE_EQ_AV", "@WHILE_NEQ_AV", "@WHILE_NEQ_A",
    "@WHILE_EQ_V", "@WHILE_NEQ_V", "@WHILE_GT_A", "@WHILE_GT_V", "@WHILE_LT_A", "@WHILE_LT_V",
    "@WHILE_UGT_A", "@WHILE_UGT_V", "@WHILE_ULT_A", "@WHILE_ULT_V",
    "@IF_ZERO", "@IF_NOTZERO", "@IF_EQ_S", "@IF_EQ_A",
    "@IF_EQ_V", "@IF_EQ_VV", "@IF_EQ_VA", "@IF_EQ_AV", "@IF_LT_S", "@IF_LT_A", "@IF_LT_",
    "@IF_LE_S", "@IF_LE_A", "@IF_LE_V", "@IF_GE_S", "@IF_GE_A", "@IF_GE_V", "@IF_GT_S",
    "@IF_GT_A", "@IF_GT_V", "@IF_INRANGE_AB", "@IF_INRANGE_AV", "@IF_INRANGE_VA",
    "@IF_INRANGE_VV", "@IF_UGT_V", "@IF_UGE_V", "@IF_UGT_A", "@IF_UGE_A", "@IF_UGT_S",
    "@IF_UGE_S", "@IF_ULE_V", "@IF_ULT_V", "@IF_ULE_A", "@IF_ULT_A", "@IF_ULE_S", "@IF_ULT_S",
    "@IF_NEG", "@IF_ZFLAG", "@IF_NOTZF", "@IF_POS", "@IF_OVERFLOW", "@IF_NOTOVER",
    "@IF_CARRY", "@IF_NOTCARRY", "@SWITCH", "@CASE", "@CASE_RANGE", "@CASE_I", "@ForIA2B", "@ForIupA2B",
    "@ForIdownA2B", "@ForIA2V", "@ForIupA2V", "@ForIdownA2V", "@ForIA2S", "@ForIupA2S", "@ForIdownA2S",
    "@ForIV2A", "@ForIupV2A", "@ForIdownV2A", "@ForIV2V", "@ForIupV2V", "@ForIdownV2V", "@WHEN"
}
CLOSERS = {
    "@ENDWHILE", "@ENDIF", "@ENDWHEN", "@ENDCASE", "@Next", "@NextBy", "@NextByI", "@CBREAK", "@CDEFAULT"
}
MIDBLOCKS = {
    "@ELSE", "@CASE", "@CASE_I", "@CASE_RANGE"
}

COLORS = {
    "open": "\033[92m", "mid": "\033[94m", "close": "\033[91m", "reset": "\033[0m"
}

def colorize(text, color, use_color):
    return f"{COLORS[color]}{text}{COLORS['reset']}" if use_color else text

def draw_columns(stack, role, use_color):
    grid = []
    for _ in range(len(stack)):
        grid.append('|   ')
    if role == 'open' or role == 'close':
        grid.append(colorize('---+', role, use_color))
    elif role == 'mid':
        grid.append(colorize('|', role, use_color).ljust(4))
    else:  # continuation
        if stack:
            grid.append('|   ')
    return ''.join(grid)

def parse_control_flow_lines(lines, use_color=False):
    stack = []
    output = []

    for line in lines:
        stripped = line.rstrip()
        match = re.match(r"^\s*(@\S+)\s+(\S+)", stripped)
        keyword, label = (match.groups() if match else (None, None))

        if not match:
            output.append(('', stripped))
            continue
        if stripped.startswith(":") and not stripped.startswith("::"):
            stack.clear()

        if keyword in OPENERS:
            arrow = draw_columns(stack, 'open', use_color)
            stack.append((keyword, label))
        elif keyword in MIDBLOCKS:
            arrow = draw_columns(stack, 'mid', use_color)
        elif keyword in CLOSERS:
            if stack:
                last_keyword, _ = stack[-1]
                if keyword == "@ENDIF" and last_keyword.startswith("@IF"):
                    stack.pop()
                elif keyword == "@ENDWHILE" and last_keyword.startswith("@WHILE"):
                    stack.pop()
                elif keyword == "@ENDCASE" and last_keyword == "@SWITCH":
                    stack.pop()
                elif keyword.startswith("@Next") and last_keyword.startswith("@For"):
                    stack.pop()
            arrow = draw_columns(stack, 'close', use_color)
        else:
            arrow = draw_columns(stack, 'cont', use_color)

        output.append((arrow, stripped))
    return output

def process_ex716_file(filepath, use_color=False, output_path=None):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    parsed = parse_control_flow_lines(lines, use_color)

    if output_path:
        with open(output_path, 'w') as out:
            for arrow, raw in parsed:
                out.write(f"{arrow:<40} {raw}\n")
    else:
        for arrow, raw in parsed:
            print(f"{arrow:<40} {raw}")

def main():
    parser = argparse.ArgumentParser(description="EX716 Assembly Visualizer")
    parser.add_argument("filepath", type=str, help="Input EX716 source file")
    parser.add_argument("--color", action="store_true", help="Enable color output")
    parser.add_argument("--output", type=str, help="Optional output file path")
    args = parser.parse_args()
    process_ex716_file(args.filepath, use_color=args.color, output_path=args.output)

if __name__ == "__main__":
    main()
