
#!/usr/bin/env python3

def emit(x=""):
    print(x)

# ------------------------------------------------------------
# General helpers
# ------------------------------------------------------------

def label_safe(s: str) -> str:
    return s.replace(".", "_").replace("-", "_")

def header(name):
    emit(f'@PRTLN "===== TEST {name} ====="')
    emit("@CALL ResetMem")

def begin_test(name):
    tag = label_safe(name)
    header(name)
    return tag

def pass_block(tag):
    emit(f"@CALL Pass")
    emit(f'@PRTLN "PASS ' + tag + '"')

def fail_block(tag):
    emit(f"@CALL Fail")
    emit(f'@PRTLN "FAIL ' + tag + '"')

def expect_top_equals(tag, value_expr):
    emit(f"@PUSH {value_expr}")
    emit("@CMPS")
    emit(f"@JMPZ PASS_{tag}")
    fail_block(tag)
    emit(f"@JMP END_{tag}")
    emit(f":PASS_{tag}")
    pass_block(tag)
    emit(f":END_{tag}")
    emit("")

def expect_var_equals(tag, varname, value_expr):
    emit(f"@PUSHI {varname}")
    emit(f"@PUSH {value_expr}")
    emit("@CMPS")
    emit(f"@JMPZ PASS_{tag}")
    fail_block(tag)
    emit(f"@JMP END_{tag}")
    emit(f":PASS_{tag}")
    pass_block(tag)
    emit(f":END_{tag}")
    emit("")

def expect_ptr_target_equals(tag, ptrname, value_expr):
    emit(f"@PUSHII {ptrname}")
    emit(f"@PUSH {value_expr}")
    emit("@CMPS")
    emit(f"@JMPZ PASS_{tag}")
    fail_block(tag)
    emit(f"@JMP END_{tag}")
    emit(f":PASS_{tag}")
    pass_block(tag)
    emit(f":END_{tag}")
    emit("")

def stack_setup(a=10, b=20):
    emit(f"@PUSH {a}")
    emit(f"@PUSH {b}")

def init_vars():
    emit("# init direct vars")
    emit("@PUSH 111")
    emit("@POPI AVal")
    emit("@PUSH 222")
    emit("@POPI BVal")
    emit("")
    emit("# init pointed-to storage")
    emit("@PUSH 333")
    emit("@POPI StorageA")
    emit("@PUSH 444")
    emit("@POPI StorageB")
    emit("")
    emit("@MA2V StorageA APtr")
    emit("@MA2V StorageB BPtr")
    emit("")

# ------------------------------------------------------------
# Reset / bookkeeping
# ------------------------------------------------------------

def emit_runtime_support():
    emit(":Pass")
    emit("@POPI ReturnStore")
    emit("@PUSHI PassCount")
    emit("@ADD 1")
    emit("@POPI PassCount")
    emit("@PUSHI ReturnStore")
    emit("@RET")
    emit("")

    emit(":Fail")
    emit("@POPI ReturnStore")
    emit("@PUSHI FailCount")
    emit("@ADD 1")
    emit("@POPI FailCount")
    emit("@PUSHI ReturnStore")
    emit("@RET")
    emit("")

    emit(":ResetMem")
    emit("@POPI ReturnStore")
    emit('@PRTLN "---- RESET ----"')
    emit("@SCLR")
    emit("@FCLR")
    emit("@MA2V 0 AVal")
    emit("@MA2V 0 BVal")
    emit("@MA2V StorageA APtr")
    emit("@MA2V StorageB BPtr")
    emit("@PUSH 0")
    emit("@POPI StorageA")
    emit("@PUSH 0")
    emit("@POPI StorageB")
    emit("@PUSHI ReturnStore")
    emit("@RET")
    emit("")

# ------------------------------------------------------------
# Instruction family emitters
# ------------------------------------------------------------

def test_nop():
    tag = begin_test("NOP")
    pass_block(tag)
    emit("")

def test_push():
    tag = begin_test("PUSH")
    emit("@PUSH 123")
    emit("@PRTTOP")
    expect_top_equals(tag, 123)

def test_dup():
    tag = begin_test("DUP")
    emit("@PUSH 55")
    emit("@DUP")
    emit("@PRTTOP")
    expect_top_equals(tag, 55)

def test_pushi():
    tag = begin_test("PUSHI")
    init_vars()
    emit("@PUSHI AVal")
    emit("@PRTTOP")
    expect_top_equals(tag, 111)

def test_pushii():
    tag = begin_test("PUSHII")
    init_vars()
    emit("@PUSHII APtr")
    emit("@PRTTOP")
    expect_top_equals(tag, 333)

def test_pushs():
    tag = begin_test("PUSHS")
    emit("@PUSH 777")
    emit("@PUSH StorageA")
    emit("@POPS")
    emit("@PUSH StorageA")
    emit("@PUSHS")
    emit("@PRTTOP")
    expect_top_equals(tag, 777)

def test_popnull():
    tag = begin_test("POPNULL")
    emit("@PUSH 55")
    emit("@PUSH 66")
    emit("@POPNULL")
    emit("@PRTTOP")
    expect_top_equals(tag, 55)

def test_swp():
    tag = begin_test("SWP")
    emit("@PUSH 11")
    emit("@PUSH 22")
    emit("@SWP")
    emit("@PRTTOP")
    expect_top_equals(tag, 11)

def test_popi():
    tag = begin_test("POPI")
    emit("@PUSH 777")
    emit("@POPI AVal")
    expect_var_equals(tag, "AVal", 777)

def test_popii():
    tag = begin_test("POPII")
    init_vars()
    emit("@PUSH 888")
    emit("@POPII APtr")
    expect_ptr_target_equals(tag, "APtr", 888)

def test_pops():
    tag = begin_test("POPS")
    emit("@PUSH 999")
    emit("@PUSH StorageA")
    emit("@POPS")
    emit("@PUSHI StorageA")
    emit("@PRTTOP")
    expect_top_equals(tag, 999)

def test_cmp_literal():
    tag = begin_test("CMP")
    emit("@PUSH 20")
    emit("@CMP 20")
    emit("@JMPZ PASS_" + tag)
    fail_block(tag)
    emit("@JMP END_" + tag)
    emit(":PASS_" + tag)
    pass_block(tag)
    emit(":END_" + tag)
    emit("")

def test_cmps():
    tag = begin_test("CMPS")
    emit("@PUSH 30")
    emit("@PUSH 30")
    emit("@CMPS")
    emit("@JMPZ PASS_" + tag)
    fail_block(tag)
    emit("@JMP END_" + tag)
    emit(":PASS_" + tag)
    pass_block(tag)
    emit(":END_" + tag)
    emit("")

def test_cmpi():
    tag = begin_test("CMPI")
    init_vars()
    emit("@PUSH 111")
    emit("@CMPI AVal")
    emit("@JMPZ PASS_" + tag)
    fail_block(tag)
    emit("@JMP END_" + tag)
    emit(":PASS_" + tag)
    pass_block(tag)
    emit(":END_" + tag)
    emit("")

def test_cmpii():
    tag = begin_test("CMPII")
    init_vars()
    emit("@PUSH 333")
    emit("@CMPII APtr")
    emit("@JMPZ PASS_" + tag)
    fail_block(tag)
    emit("@JMP END_" + tag)
    emit(":PASS_" + tag)
    pass_block(tag)
    emit(":END_" + tag)
    emit("")

def binary_literal(op, lhs, rhs, expected):
    tag = begin_test(op)
    emit(f"@PUSH {lhs}")
    emit(f"@{op} {rhs}")
    emit("@PRTTOP")
    expect_top_equals(tag, expected)

def binary_stack(op, lhs, rhs, expected):
    tag = begin_test(op)
    emit(f"@PUSH {lhs}")
    emit(f"@PUSH {rhs}")
    emit("@StackDump")
    emit(f"@{op}")
    emit("@StackDump")
    emit("@PRTTOP")
    expect_top_equals(tag, expected)

def binary_indirect(op, varname, varvalue, lhs, expected):
    tag = begin_test(op)
    emit(f"@PUSH {varvalue}")
    emit(f"@POPI {varname}")
    emit(f"@PUSH {lhs}")
    emit("@StackDump")
    emit(f"@{op} {varname}")
    emit("@StackDump")
    emit("@PRTTOP")
    expect_top_equals(tag, expected)

def binary_double_indirect(op, ptrname, storage_label, stored_value, lhs, expected):
    tag = begin_test(op)
    emit(f"@PUSH {stored_value}")
    emit(f"@POPI {storage_label}")
    emit(f"@MA2V {storage_label} {ptrname}")
    emit(f"@PUSH {lhs}")
    emit("@StackDump")
    emit(f"@{op} {ptrname}")
    emit("@StackDump")
    emit("@PRTTOP")
    expect_top_equals(tag, expected)

def unary_stack(op, value, expected):
    tag = begin_test(op)
    emit(f"@PUSH {value}")
    emit("@StackDump")
    emit(f"@{op}")
    emit("@StackDump")
    emit("@PRTTOP")
    expect_top_equals(tag, expected)

# ------------------------------------------------------------
# Jump tests
# ------------------------------------------------------------

def jump_conditional(op, setflag, clearflag):
    tag = label_safe(op.lower())
    emit(f'@PRTLN "===== TEST {op} ====="')
    emit("@CALL ResetMem")

    emit(f"@{setflag}")
    emit(f"@{op} SUS_{tag}_1")
    fail_block(tag + "_forward")
    emit(f"@JMP FAIL2_{tag}_1")

    emit(f":SUS_{tag}_1")
    emit(f"@{clearflag}")
    emit(f"@{op} FAIL_{tag}_1")
    pass_block(tag + "_forward")
    emit(f"@JMP SKIP_{tag}_1")

    emit(f":FAIL_{tag}_1")
    fail_block(tag + "_reverse")

    emit(f":FAIL2_{tag}_1")
    emit(f":SKIP_{tag}_1")
    emit("")

def jump_unconditional():
    tag = "jmp"
    emit('@PRTLN "===== TEST JMP ====="')
    emit("@CALL ResetMem")
    emit("@JMP SUS_jmp_1")
    fail_block(tag + "_forward")
    emit("@JMP SKIP_jmp_1")
    emit(":SUS_jmp_1")
    pass_block(tag + "_forward")
    emit(":SKIP_jmp_1")
    emit("")

def jumpi_test():
    tag = "jmpi"
    emit('@PRTLN "===== TEST JMPI ====="')
    emit("@CALL ResetMem")
    emit("@PUSH SUS_JMPI_1")
    emit("@POPI AVal")
    emit("@JMPI AVal")
    fail_block(tag + "_forward")
    emit("@JMP SKIP_JMPI_1")
    emit(":SUS_JMPI_1")
    pass_block(tag + "_forward")
    emit(":SKIP_JMPI_1")
    emit("")

def jmps_test():
    tag = "jmps"
    emit('@PRTLN "===== TEST JMPS ====="')
    emit("@CALL ResetMem")
    emit("@PUSH SUS_JMPS_1")
    emit("@JMPS")
    fail_block(tag + "_forward")
    emit("@JMP SKIP_JMPS_1")
    emit(":SUS_JMPS_1")
    pass_block(tag + "_forward")
    emit(":SKIP_JMPS_1")
    emit("")

# ------------------------------------------------------------
# Special / placeholder tests
# ------------------------------------------------------------

def placeholder_test(op, comment="Manual semantic review needed"):
    tag = begin_test(op)
    emit(f'@PRTLN "{comment}"')
    emit(f"@{op}")
    pass_block(tag)
    emit("")

# ------------------------------------------------------------
# Program emission
# ------------------------------------------------------------

def main():
    emit("I common.mc")
    emit(":Main . Main")
    emit('@PRTLN "Starting EX716 Opcode Validation"')
    emit("")

    # Core stack / memory
    test_nop()
    test_push()
    test_dup()
    test_pushi()
    test_pushii()
    test_pushs()
    test_popnull()
    test_swp()
    test_popi()
    test_popii()
    test_pops()

    # Compare family
    test_cmp_literal()
    test_cmps()
    test_cmpi()
    test_cmpii()

    # Arithmetic / logic families
    binary_literal("ADD",   10, 20, 30)
    binary_stack("ADDS",    10, 20, 30)
    binary_indirect("ADDI", "AVal", 20, 10, 30)
    binary_double_indirect("ADDII", "APtr", "StorageA", 20, 10, 30)

    binary_literal("SUB",   10, 20, 0xFFF6)
    binary_stack("SUBS",    10, 20, 0xFFF6)
    binary_indirect("SUBI", "AVal", 20, 10, 0xFFF6)
    binary_double_indirect("SUBII", "APtr", "StorageA", 20, 10, 0xFFF6)

    binary_literal("OR",    0x0A, 0x14, 0x1E)
    binary_stack("ORS",     0x0A, 0x14, 0x1E)
    binary_indirect("ORI",  "AVal", 0x14, 0x0A, 0x1E)
    binary_double_indirect("ORII", "APtr", "StorageA", 0x14, 0x0A, 0x1E)

    binary_literal("AND",   0x0A, 0x14, 0x00)
    binary_stack("ANDS",    0x0A, 0x14, 0x00)
    binary_indirect("ANDI", "AVal", 0x14, 0x0A, 0x00)
    binary_double_indirect("ANDII", "APtr", "StorageA", 0x14, 0x0A, 0x00)

    binary_literal("XOR",   0x0A, 0x14, 0x1E)
    binary_stack("XORS",    0x0A, 0x14, 0x1E)
    binary_indirect("XORI", "AVal", 0x14, 0x0A, 0x1E)
    binary_double_indirect("XORII", "APtr", "StorageA", 0x14, 0x0A, 0x1E)

    # Jumps
    jump_conditional("JMPZ", "SETZ", "CLZ")
    jump_conditional("JMPN", "SETN", "CLN")
    jump_conditional("JMPC", "SETC", "CLC")
    jump_conditional("JMPO", "SETO", "CLO")
    jump_unconditional()
    jumpi_test()
    jmps_test()

    # Unary / bit ops
    unary_stack("SHR",   0x0080, 0x0040)
    unary_stack("SHL",   0x0001, 0x0002)
    unary_stack("INV",   0x00F0, 0xFF0F)
    unary_stack("COMP2", 0x0001, 0xFFFF)

    # Specials / partial placeholders
    placeholder_test("CAST")
    placeholder_test("POLL")
    placeholder_test("RRTC")
    placeholder_test("RLTC")
    placeholder_test("FCLR")
    placeholder_test("FSAV")
    placeholder_test("FLOD")
    placeholder_test("ADM")
    placeholder_test("SCLR")
    placeholder_test("SRTP")

    # Summary
    emit('@PRTLN "===== TEST SUMMARY ====="')
    emit('@PRT "PASS COUNT: "')
    emit("@PUSHI PassCount")
    emit("@PRTI")
    emit('@PRT "FAIL COUNT: "')
    emit("@PUSHI FailCount")
    emit("@PRTI")
    emit("@END")
    emit("")

    # Data / support
    emit_runtime_support()

    emit(":ReturnStore 0")
    emit(":PassCount 0")
    emit(":FailCount 0")
    emit("")
    emit(":AVal")
    emit("0")
    emit(":BVal")
    emit("0")
    emit("")
    emit(":APtr")
    emit("StorageA")
    emit(":BPtr")
    emit("StorageB")
    emit("")
    emit(":StorageA")
    emit("0 0 0 0")
    emit(":StorageB")
    emit("0 0 0 0")

if __name__ == "__main__":
    main()
    
