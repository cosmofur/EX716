# EX716 Assembler - Lesson 12: Table Structure Helpers

As programs grow, a single label is not enough to describe the data you care about. You start wanting records: a player with `X`, `Y`, `HP`, and `Score`; a file entry with `Name`, `Size`, and `Flags`; or an event table row with coordinates, type, and ID.

The table-structure helpers in `common.mc` make that style practical. They let you treat memory as **objects with fields** or **lists of fixed-size records** without rewriting pointer arithmetic every time.

---

## Goals

1. Define field offsets for a structured record.
2. Read and write fields with `FILL_AT_*` and `GET_FROM`.
3. Compute field pointers with `PTR_AT`.
4. Use indexed list helpers for arrays of records.
5. Understand when the suffix letters `A`, `V`, and `S` matter.

---

## The Basic Idea

A structured object is just a base pointer plus named offsets.

```asm
=Player_X      0
=Player_Y      2
=Player_HP     4
=Player_Score  6
=Player_Size   8

:Player1
0 0 0 0

:PlayerPtr Player1
```

`PlayerPtr` stores the address of the object. The helpers expect this pattern: the first argument is a variable that contains the base address.

---

## Writing Fields: FILL_AT_A, FILL_AT_V, FILL_AT_S

`FILL_AT_*` writes a 16-bit value into `BasePtr + Offset`.

```text
FILL_AT_A(BasePtrVariable, OffsetConstant, SourceConstant)
FILL_AT_V(BasePtrVariable, OffsetConstant, SourceVariable)
FILL_AT_S(BasePtrVariable, OffsetConstant)
```

The suffix says where the source value comes from:

```text
A = direct/immediate value
V = variable value
S = stack top
```

Examples:

```asm
@FILL_AT_A PlayerPtr Player_X 10       # Player1.X = 10
@FILL_AT_A PlayerPtr Player_Y 5        # Player1.Y = 5
@FILL_AT_V PlayerPtr Player_HP NewHP   # Player1.HP = NewHP

@PUSHI ScoreDelta
@ADDI CurrentScore
@FILL_AT_S PlayerPtr Player_Score      # Player1.Score = stack result
```

Use `FILL_AT_S` when the value is already on the stack. That avoids storing it in a temporary variable first.

---

## Reading Fields: GET_FROM

`GET_FROM(BasePtrVariable, OffsetConstant)` pushes the value stored at `BasePtr + Offset`.

```asm
@GET_FROM PlayerPtr Player_X
@PRTTOP
@POPNULL

@GET_FROM PlayerPtr Player_HP
@IF_LT_A 1
   @PRTLN "Player is down"
@ENDIF
@POPNULL
```

The helper expands to the same idea you would write by hand:

```asm
@PUSHI PlayerPtr
@ADD Player_HP
@PUSHS
```

---

## Getting an Address: PTR_AT

Sometimes you need the address of a field, not the value inside it. `PTR_AT(BasePtrVariable, OffsetConstant)` pushes `BasePtr + Offset`.

```asm
@PTR_AT PlayerPtr Player_Score
@POPI ScoreFieldPtr
```

This is useful when another routine expects a pointer, or when you want to pass a field location to a lower-level macro.

---

## Lists of Records

A list is a sequence of records with the same size.

```asm
=Enemy_X      0
=Enemy_Y      2
=Enemy_HP     4
=Enemy_Size   6

:EnemyTable
0 0 0
0 0 0
0 0 0

:EnemyBase EnemyTable
:EnemyIndex 0
```

The address of a record is:

```text
Base + Index * RecordSize
```

The helpers use `MULU` internally, so `mul.ld` must be loaded before using the list/index helpers.

```asm
L mul.ld
```

---

## Computing Record Pointers

`INDEXA_PTR` and `INDEXV_PTR` push the address of a list record.

```text
INDEXA_PTR(BasePtrVariable, IndexConstant, RecordSizeConstant)
INDEXV_PTR(BasePtrVariable, IndexVariable, RecordSizeConstant)
```

Examples:

```asm
@INDEXA_PTR EnemyBase 2 Enemy_Size   # address of EnemyTable[2]
@POPI EnemyPtr

@INDEXV_PTR EnemyBase EnemyIndex Enemy_Size
@POPI EnemyPtr
```

Once you have `EnemyPtr`, the ordinary object helpers work again:

```asm
@FILL_AT_A EnemyPtr Enemy_HP 10
@GET_FROM EnemyPtr Enemy_X
```

---

## Reading From Lists

The list read helpers combine indexing and field access in one line.

```text
LISTA_GET_FROM(BasePtrVariable, IndexConstant, RecordSizeConstant, FieldOffsetConstant)
LISTV_GET_FROM(BasePtrVariable, IndexVariable, RecordSizeConstant, FieldOffsetConstant)
```

Examples:

```asm
@LISTA_GET_FROM EnemyBase 0 Enemy_Size Enemy_HP
@POPI FirstEnemyHP

@LISTV_GET_FROM EnemyBase EnemyIndex Enemy_Size Enemy_X
@POPI CurrentEnemyX
```

Use `LISTA_...` when the index is a direct number. Use `LISTV_...` when the index lives in a variable.

---

## Writing To Lists

The list fill helpers write a field inside an indexed record.

```text
LISTA_FILL_AT_A(BasePtrVariable, IndexConstant, RecordSizeConstant, FieldOffsetConstant, SourceConstant)
LISTA_FILL_AT_V(BasePtrVariable, IndexConstant, RecordSizeConstant, FieldOffsetConstant, SourceVariable)
LISTA_FILL_AT_S(BasePtrVariable, IndexConstant, RecordSizeConstant, FieldOffsetConstant)

LISTV_FILL_AT_A(BasePtrVariable, IndexVariable, RecordSizeConstant, FieldOffsetConstant, SourceConstant)
LISTV_FILL_AT_V(BasePtrVariable, IndexVariable, RecordSizeConstant, FieldOffsetConstant, SourceVariable)
LISTV_FILL_AT_S(BasePtrVariable, IndexVariable, RecordSizeConstant, FieldOffsetConstant)
```

Examples:

```asm
@LISTA_FILL_AT_A EnemyBase 0 Enemy_Size Enemy_HP 25
@LISTA_FILL_AT_V EnemyBase 1 Enemy_Size Enemy_HP NewHP

@PUSHI CurrentX
@ADD 1
@LISTV_FILL_AT_S EnemyBase EnemyIndex Enemy_Size Enemy_X
```

The final suffix still describes the source value: `A` for direct, `V` for variable, `S` for stack.

---

## Mini Example: Updating Enemy HP

```asm
I common.mc
L mul.ld

=Enemy_X      0
=Enemy_Y      2
=Enemy_HP     4
=Enemy_Size   6

:EnemyTable
0 0 0
0 0 0
0 0 0

:EnemyBase EnemyTable
:EnemyIndex 1
:Damage 3
:HP 0

# Initialize enemy 1.
@LISTV_FILL_AT_A EnemyBase EnemyIndex Enemy_Size Enemy_X 20
@LISTV_FILL_AT_A EnemyBase EnemyIndex Enemy_Size Enemy_Y 8
@LISTV_FILL_AT_A EnemyBase EnemyIndex Enemy_Size Enemy_HP 12

# HP = HP - Damage.
@LISTV_GET_FROM EnemyBase EnemyIndex Enemy_Size Enemy_HP
@SUBI Damage
@LISTV_FILL_AT_S EnemyBase EnemyIndex Enemy_Size Enemy_HP

# Read it back for display.
@LISTV_GET_FROM EnemyBase EnemyIndex Enemy_Size Enemy_HP
@POPI HP
@PRT "Enemy HP: "
@PRTI HP
@PRTNL
@END
```

---

## Why This Matters

These helpers are the foundation for larger EX716 systems:

- Object-like records: one base pointer, many named fields.
- Arrays/lists: one base pointer, one index, one fixed record size.
- Heap objects: allocate a block, store its address, then access fields by offsets.
- Event tables: each row is a structured record with type, ID, coordinates, and extra data.

Lesson 13 uses these ideas to make `event.ld` easier to understand.

---

## Summary

- `FILL_AT_A`, `FILL_AT_V`, and `FILL_AT_S` write fields inside one object.
- `GET_FROM` reads a field value.
- `PTR_AT` computes a field address.
- `INDEXA_PTR` and `INDEXV_PTR` compute record addresses inside fixed-size lists.
- `LISTA_GET_FROM`, `LISTV_GET_FROM`, and the `LIST*_FILL_AT_*` macros combine indexing with field access.
