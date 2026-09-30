#PAINTUI VER 1.0
# WIDTH: 80
# HEIGHT: 24
# CANVAS_SIZE: 1920
# NEXT_FORM_ID: 3
# COUNT: 2
# 1 7 1 39 14 35 9 0
# 2 7 1 3 2 35 14 0
# CANVAS:
# "+------------------------------------+------------------------------------+     "
# "|                                    |          . X         X .           |     "
# "|                                    |             X       X              |     "
# "|                                    |          \   X     X   /           |     "
# "|                                    |            \  X   X  /             |     "
# "|                                    |         .    \ X X /    .          |     "
# "|                                    |       ----------X----------        |     "
# "|                                    |         .    / X X \    .          |     "
# "|                                    |            /  X   X  \             |     "
# "|                                    |          /   X     X   \           |     "
# "|                                    |          .  X       X  .           |     "
# "|                                    |            X         X             |     "
# "|                                    +------------------------------------+     "
# "|                                    |                                    |     "
# "|                                    |                                    |     "
# "+-----------------+------------------+                                    |     "
# "| F1 F2 F3 F4 F5  | G1 G2 G3 G4 G5   |                                    |     "
# "|                 |                  |                                    |     "
# "+-----------------|------------------+                                    |     "
# "+-----------------|------------------+                                    |     "
# "|     V           |         V        |                                    |     "
# "| <-------------> | <--------------> |                                    |     "
# "+-----------------+------------------+------------------------------------+     "
# "                                                                                "
# END CANVAS
######################################################
# Start of Code
:DrawBackGround
   @Call(AA) WinCursor 1 1
   @PRTLN "+------------------------------------+------------------------------------+     "
   @PRTLN "|                                    |          . X         X .           |     "
   @PRTLN "|                                    |             X       X              |     "
   @PRTLN "|                                    |          \   X     X   /           |     "
   @PRTLN "|                                    |            \  X   X  /             |     "
   @PRTLN "|                                    |         .    \ X X /    .          |     "
   @PRTLN "|                                    |       ----------X----------        |     "
   @PRTLN "|                                    |         .    / X X \    .          |     "
   @PRTLN "|                                    |            /  X   X  \             |     "
   @PRTLN "|                                    |          /   X     X   \           |     "
   @PRTLN "|                                    |          .  X       X  .           |     "
   @PRTLN "|                                    |            X         X             |     "
   @PRTLN "|                                    +------------------------------------+     "
   @PRTLN "|                                    |                                    |     "
   @PRTLN "|                                    |                                    |     "
   @PRTLN "+-----------------+------------------+                                    |     "
   @PRTLN "| F1 F2 F3 F4 F5  | G1 G2 G3 G4 G5   |                                    |     "
   @PRTLN "|                 |                  |                                    |     "
   @PRTLN "+-----------------|------------------+                                    |     "
   @PRTLN "+-----------------|------------------+                                    |     "
   @PRTLN "|     V           |         V        |                                    |     "
   @PRTLN "| <-------------> | <--------------> |                                    |     "
   @PRTLN "+-----------------+------------------+------------------------------------+     "
   @PRT "                                                                                "
@RET
:PaintUIScreenInit
@PUSHRETURN
@Locals
   @Local FormPtr
   @POPI FormPtr
   # id: 1, type: 7, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 7           # FieldType
   @PUSH 39           # RelX
   @PUSH 14           # RelY
   @PUSH 35           # Width
   @PUSH 9           # Height
   @PUSH 0           # ValuePtr: replace with app variable/buffer
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 2, type: 7, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 7           # FieldType
   @PUSH 3           # RelX
   @PUSH 2           # RelY
   @PUSH EDIT
   @PUSH 14           # Height
   @PUSH 0           # ValuePtr: replace with app variable/buffer
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
@EndLocals
@POPRETURN
@RET
:PaintUIScreenDraw
   @CALL DrawBackGround
   @CALL DisplayUpdate
@RET
# END PAINTUI
