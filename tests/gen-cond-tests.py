#!/usr/bin/env python3
# EX716 IF condition test generator (fixed _V argument syntax)

from textwrap import dedent

VARS = dedent("""
:Var_Neg1   -1
:Var_Zero    0
:Var_One     1
:Var_Two     2
:Var_Five    5
:Var_HighBit 0x8000
:Var_Large   0x7FFF
""").strip()

HEADER = dedent("""
# Auto-generated IF test suite (16-bit)
I common.mc
:Main . Main
@PRTNL
@PRT "BEGIN IF TESTS" @PRTNL
""").strip()

FOOTER = dedent("""
@PRT "END IF TESTS" @PRTNL
@PRTNL
""").strip()

# === Flag-based tests (single-stack behavior) ===
FLAG_TESTS = [
    ("IF_NEG",      "@PUSH 0 @SUB 1", "@PUSH 1 @SUB 0"),
    ("IF_POS",      "@PUSH 1 @SUB 0", "@PUSH 0 @SUB 1"),
    ("IF_OVERFLOW", "@PUSH 0x7FFF @ADD 1", "@PUSH 1 @ADD 1"),
    ("IF_NOTOVER",  "@PUSH 1 @ADD 1", "@PUSH 0x7FFF @ADD 1"),
    ("IF_CARRY",    "@PUSH 0xFFFF @ADD 1", "@PUSH 1 @ADD 1"),
    ("IF_NOTCARRY", "@PUSH 1 @ADD 1", "@PUSH 0xFFFF @ADD 1"),
    ("IF_ZFLAG",    "@PUSH 1 @SUB 1", "@PUSH 2 @SUB 1"),
    ("IF_NOTZF",    "@PUSH 2 @SUB 1", "@PUSH 1 @SUB 1"),
    ("IF_ZERO",     "@PUSH 1 @SUB 1", "@PUSH 2 @SUB 1"),
    ("IF_NOTZERO",  "@PUSH 2 @SUB 1", "@PUSH 1 @SUB 1"),
]

# === Signed compare patterns (two-stack)
COMPARES = [
    ("EQ",  "@PUSH 1 @PUSH 1", "@PUSH 1 @PUSH 2"),
    ("NEQ", "@PUSH 1 @PUSH 2", "@PUSH 1 @PUSH 1"),
    ("LT",  "@PUSH 1 @PUSH 2", "@PUSH 2 @PUSH 1"),
    ("LE",  "@PUSH 1 @PUSH 2", "@PUSH 2 @PUSH 1"),
    ("GE",  "@PUSH 2 @PUSH 1", "@PUSH 1 @PUSH 2"),
    ("GT",  "@PUSH 2 @PUSH 1", "@PUSH 1 @PUSH 2"),
]

UCOMPARES = ["ULT", "ULE", "UGE", "UGT"]

RANGE_CASES = [
    ("IF_INRANGE_AB", "@PUSH 5", "2", "10"),
    ("IF_INRANGE_AV", "@PUSH 5", "2", "Var_Large"),
    ("IF_INRANGE_VA", "@PUSHI Var_Five", "Var_One", "10"),
    ("IF_INRANGE_VV", "@PUSHI Var_Five", "Var_One", "Var_Large"),
]

# === Emitters ===
def test_block(name, expr_true, expr_false, popcount=2):
    """Generic IF test block"""
    pops = " ".join("@POPNULL" for _ in range(popcount))
    return dedent(f"""
        # === TEST {name} ===
        {expr_true}
        @{name}
          @PRT "PASS {name} true" @PRTNL
        @ELSE
          @PRT "FAIL {name} true" @PRTNL
        @ENDIF
        {pops}

        {expr_false}
        @{name}
          @PRT "FAIL {name} false" @PRTNL
        @ELSE
          @PRT "PASS {name} false" @PRTNL
        @ENDIF
        {pops}
    """)



def compare_block(base, expr_true, expr_false):
    """Emit S/A/V variants (stack, immediate, variable) with consistent logic."""
    parts = []

    # --- Stack (S) form ---
    parts.append(test_block(f"IF_{base}_S", expr_true, expr_false))

    # --- Define operand patterns for A/V forms ---
    # Each entry defines (true_push, true_arg, false_push, false_arg)
    if base in ("LT", "ULT", "NEQ"):
        # Strict less-than or not-equal
        true_push, true_arg = "1", "2"   # true: 1 < 2
        false_push, false_arg = "1", "1" # false: 1 < 1
    elif base in ("GT", "UGT"):
        # Strict greater-than
        true_push, true_arg = "2", "1"   # true: 2 > 1
        false_push, false_arg = "1", "1" # false: 1 > 1
    elif base in ("LE", "ULE"):
        # Less or equal
        true_push, true_arg = "1", "2"   # true: 1 <= 2
        false_push, false_arg = "2", "1" # false: 2 <= 1
    elif base in ("GE", "UGE"):
        # Greater or equal
        true_push, true_arg = "2", "1"   # true: 2 >= 1
        false_push, false_arg = "1", "2" # false: 1 >= 2
    elif base == "EQ":
        true_push, true_arg = "1", "1"
        false_push, false_arg = "1", "2"
    else:
        # Default fallback (acts like equality)
        true_push, true_arg = "1", "1"
        false_push, false_arg = "1", "2"

    # --- Immediate (A) form ---
    parts.append(dedent(f"""
        # === TEST IF_{base}_A ===
        @PUSH {true_push}
        @IF_{base}_A {true_arg}
          @PRT "PASS IF_{base}_A true" @PRTNL
        @ELSE
          @PRT "FAIL IF_{base}_A true" @PRTNL
        @ENDIF
        @POPNULL

        @PUSH {false_push}
        @IF_{base}_A {false_arg}
          @PRT "FAIL IF_{base}_A false" @PRTNL
        @ELSE
          @PRT "PASS IF_{base}_A false" @PRTNL
        @ENDIF
        @POPNULL
    """))

    # --- Variable (V) form ---
    # Use same operand logic as A form (mapping 1→Var_One, 2→Var_Two)
    parts.append(dedent(f"""
        # === TEST IF_{base}_V ===
        @PUSH {true_push}
        @IF_{base}_V Var_{'One' if true_arg == '1' else 'Two'}
          @PRT "PASS IF_{base}_V true" @PRTNL
        @ELSE
          @PRT "FAIL IF_{base}_V true" @PRTNL
        @ENDIF
        @POPNULL

        @PUSH {false_push}
        @IF_{base}_V Var_{'One' if false_arg == '1' else 'Two'}
          @PRT "FAIL IF_{base}_V false" @PRTNL
        @ELSE
          @PRT "PASS IF_{base}_V false" @PRTNL
        @ENDIF
        @POPNULL
    """))

    return "\n".join(parts)


def unsigned_block(base):
    """Unsigned variant (S, A, V) with correct operand direction"""
    if base in ("ULT", "ULE"):
        expr_true  = "@PUSH 1 @PUSH 2"   # 1 < 2
        expr_false = "@PUSH 2 @PUSH 1"
    elif base in ("UGE", "UGT"):
        expr_true  = "@PUSH 2 @PUSH 1"   # 2 > 1
        expr_false = "@PUSH 1 @PUSH 2"
    else:
        expr_true  = "@PUSH 1 @PUSH 1"
        expr_false = "@PUSH 1 @PUSH 2"

    return compare_block(base, expr_true, expr_false)

def range_block(name, push_expr, low, high):
    """Range test (non-inclusive bounds)"""
    return dedent(f"""
        # === TEST {name} ===
        @PUSHI Var_Five
        @{name} {low} {high}
          @PRT "PASS {name} true" @PRTNL
        @ELSE
          @PRT "FAIL {name} true" @PRTNL
        @ENDIF
        @POPNULL

        @PUSHI 15
        @{name} {low} {high}
          @PRT "FAIL {name} false (above)" @PRTNL
        @ELSE
          @PRT "PASS {name} false (above)" @PRTNL
        @ENDIF
        @POPNULL
    """)


# === Main ===
def main():
    lines = [VARS, "", HEADER]

    # Flag-based tests
    for name, expr_true, expr_false in FLAG_TESTS:
        lines.append(test_block(name, expr_true, expr_false, popcount=1))

    # Signed compares
    for base, expr_true, expr_false in COMPARES:
        lines.append(compare_block(base, expr_true, expr_false))

    # Unsigned compares
    for base in UCOMPARES:
        lines.append(unsigned_block(base))

    # Ranges
    for name, expr, low, high in RANGE_CASES:
        lines.append(range_block(name, expr, low, high))

    lines.append(FOOTER)
    print("\n".join(lines))
    print("\n@END\n")

if __name__ == "__main__":
    main()
