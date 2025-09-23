EX716 IF_ Predicate Macros — One-Page Cheat Sheet
Core semantics

Compare order: all relational macros evaluate SFT − TOS (Second-from-Top minus Top-of-Stack).

Signed vs Unsigned:

LT, LE, GE, GT → signed compare (CMPS).

ULT, ULE, UGE, UGT → unsigned compare (CMPU).

Suffix letters (operand sourcing):

_S — stack form: both operands already on stack (SFT vs TOS).

_A — direct/immediate literal (the macro uses the literal you supply).

_V — variable deref (literal is a label/pointer; macro loads [label]).

_VV, _AV, _VA — two-operand forms (var vs var, imm vs var, var vs imm).

Zero tests check TOS directly (no compare).

Zero / Non-Zero (tests TOS)
Macro	Meaning
IF_ZERO	TOS == 0
IF_NOTZERO	TOS != 0

Equality / Inequality (order agnostic)
Macro	Compares
IF_EQ_S	SFT == TOS
IF_NEQ_S	SFT != TOS
IF_EQ_A	(immediate) == TOS
IF_NEQ_A	(immediate) != TOS
IF_EQ_V	[var] == TOS
IF_NEQ_V	[var] != TOS
IF_EQ_VV	[var1] == [var2]
IF_NEQ_VV	[var1] != [var2]
IF_EQ_VA	[var] == (immediate)
IF_NEQ_VA	[var] != (immediate)
IF_EQ_AV	(immediate) == [var]
IF_NEQ_AV	(immediate) != [var]

Signed relational (CMPS on SFT−TOS)
Macro	True when…
IF_LT_S	SFT < TOS
IF_LE_S	SFT ≤ TOS
IF_GE_S	SFT ≥ TOS
IF_GT_S	SFT > TOS
IF_LT_A	(imm) < TOS
IF_LE_A	(imm) ≤ TOS
IF_GE_A	(imm) ≥ TOS
IF_GT_A	(imm) > TOS
IF_LT_V	[var] < TOS
IF_LE_V	[var] ≤ TOS
IF_GE_V	[var] ≥ TOS
IF_GT_V	[var] > TOS

Unsigned relational (CMPU on SFT−TOS)
Macro	True when…
IF_ULT_S	SFT < TOS (unsigned)
IF_ULE_S	SFT ≤ TOS (unsigned)
IF_UGE_S	SFT ≥ TOS (unsigned)
IF_UGT_S	SFT > TOS (unsigned)
IF_ULT_A	(imm) < TOS (u)
IF_ULE_A	(imm) ≤ TOS (u)
IF_UGE_A	(imm) ≥ TOS (u)
IF_UGT_A	(imm) > TOS (u)
IF_ULT_V	[var] < TOS (u)
IF_ULE_V	[var] ≤ TOS (u)
IF_UGE_V	[var] ≥ TOS (u)
IF_UGT_V	[var] > TOS (u)

Range helpers (inclusive)
Macro	Meaning
IF_INRANGE_AB	TOS ∈ [ [A] .. (imm B) ]
IF_INRANGE_AV	TOS ∈ [ [A] .. [V] ]
IF_INRANGE_VA	TOS ∈ [ [V] .. (imm A) ]
IF_INRANGE_VV	TOS ∈ [ [V1] .. [V2] ]

Flag tests (no compare; inspect CPU flags)
Macro	Flag condition
IF_NEG	Negative set
IF_POS	Negative clear
IF_ZFLAG	Zero set
IF_NOTZF	Zero clear
IF_OVERFLOW	Overflow set
IF_NOTOVER	Overflow clear
IF_CARRY	Carry set
IF_NOTCARRY	Carry clear

Quick examples.
Immediate vs TOS (stack form, signed):

@PUSH Limit
@PUSH X              ; TOS = X
@IF_LT_S             ; true if Limit < X
  ...
@ENDIF

@IF_EQ_AV 42 SomeVar   ; true if 42 == [SomeVar]
  ...
@ENDIF
