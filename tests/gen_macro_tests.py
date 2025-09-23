#!/usr/bin/env python3

# Test macro pattern generator for EX716
# Reads macros.txt and emits test code to stdout

def emit_push(var):
    if var == "A":
        print("    @PUSHI HIGHVAL")
    elif var == "B":
        print("    @PUSHI LOWVAL")
    elif var == "V":
        print("    @PUSH HIGHVAL")
    elif var == "S":
        print("    @PUSHI LOWVAL\n    @PUSH HIGHVAL\n")
    elif var == "ZERO":
        print("    @PUSH 0\n")
    elif var == "NOTZERO":
        print("    @PUSH 1\n")
    elif var == "":
        pass
    else:
        raise ValueError(f"Unknown variant type: {var}")

def emit_test_block(macro, variant, should_succeed):
    print("    # ------------------------------------------")
    label = f"TEST_{macro}_{'PASS' if should_succeed else 'FAIL'}"
    print(f":{label}")
    # Set up test case
    if should_succeed:
        values = {
            "AB": ["B", "A"],
            "AV": ["V", "A"],
            "VA": ["A", "V"],
            "VV": ["V", "V"],
            "S": ["S", "A"],
            "A": ["A"],
            "V": ["V"],
            "ZERO": ["ZERO"],
            "NOTZERO": ["NOTZERO"],
            "": [],
        }
    else:
        values = {
            "AB": ["A", "B"],
            "AV": ["A", "V"],
            "VA": ["V", "A"],
            "VV": ["A", "A"],
            "S": ["A", "S"],
            "A": ["B"],
            "V": ["B"],
            "ZERO": ["NOTZERO"],
            "NOTZERO": ["ZERO"],
            
            "": [],
        }

    for v in values.get(variant, []):
        emit_push(v)

    print(f"    @{macro}")
    print("        @INCI Success" if should_succeed else "        @INCI Fail")
    print("    @ELSE")
    print("        @INCI Fail" if should_succeed else "        @INCI Success")
    print("    @ENDIF")
    print("    @POPNULL\n    @POPNULL")

def detect_variant(name):
    # Suffix after last underscore
    if '_' in name:
        return name.split('_')[-1]
    return ""

def main():
    print("I common.mc")
    print(":Success 0")
    print(":Fail 0")
    print("=LOWVAL 10")
    print("=HIGHVAL 100")
    print(":Main . Main")

    with open("macros.txt") as f:
        for line in f:
            macro = line.strip()
            if not macro or macro.startswith("#"):
                continue
            variant = detect_variant(macro)
            emit_test_block(macro, variant, True)
            emit_test_block(macro, variant, False)

    print("    # Final result")
    print("    @PRT \"Success:\" @PRTI Success")
    print("    @PRT \"Fail:\" @PRTI Fail")
    print("    @END")

if __name__ == "__main__":
    main()
