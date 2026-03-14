import itertools

# Operand type → assembler instruction
push_map = {
    "A": "@PUSH",
    "v": "@PUSHI",
    "P": "@PUSHII",
}

for n in [5]:
    for combo in itertools.product(["A","v","P"], repeat=n):
        sig = "".join(combo)
        pushes = [f"    {push_map[c]} %{i+2}" for i,c in enumerate(combo)]
        body = " ".join(pushes + ["    @CALL %1"])
        print(f"M Call({sig}) {body}")
        
