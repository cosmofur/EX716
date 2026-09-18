#PAINTUI VER 1.0
# WIDTH: 80
# HEIGHT: 24
# CANVAS_SIZE: 1920
# NEXT_FORM_ID: 8
# COUNT: 7
# 1 1 1 11 2 10 1 0
# 2 3 1 30 2 24 1 0
# 3 1 1 64 2 10 1 0
# 4 7 1 5 6 38 6 0
# 5 7 1 48 5 14 15 0
# 6 2 1 17 17 25 1 0
# 7 3 1 17 19 25 1 0
# CANVAS:
# "+-----------------------------------------------------------------------------+ "
# "|Form001:              Name:                             Page:              X | "
# "|                                                                             | "
# "|  MAP                                        Status Bars                     | "
# "|  +--------------------------------------+                                   | "
# "|  |                                      |                                   | "
# "|  |                                      |                                   | "
# "|  |                                      |                                   | "
# "|  |                                      |                                   | "
# "|  |                                      |                                   | "
# "|  |                                      |                                   | "
# "|  +--------------------------------------+                                   | "
# "|    +-----------+    +--------------+                                        | "
# "|    | Button 1  |    | Button 2     |                                        | "
# "|    +-----------+    +--------------+                                        | "
# "|                                                                             | "
# "|   Long Value:                                                               | "
# "|                                                                             | "
# "|   World Code:                                                               | "
# "|                                                                             | "
# "|                                                                             | "
# "+-----------------------------------------------------------------------------+ "
# "                                                                                "
# "                                                                                "
######################################################
# Start of Code
:DrawBackGround
   @Call(AA) WinCursor 1 1
   @PRTLN "+-----------------------------------------------------------------------------+ "
   @PRTLN "|Form001:              Name:                             Page:              X | "
   @PRTLN "|                                                                             | "
   @PRTLN "|  MAP                                        Status Bars                     | "
   @PRTLN "|  +--------------------------------------+                                   | "
   @PRTLN "|  |                                      |                                   | "
   @PRTLN "|  |                                      |                                   | "
   @PRTLN "|  |                                      |                                   | "
   @PRTLN "|  |                                      |                                   | "
   @PRTLN "|  |                                      |                                   | "
   @PRTLN "|  |                                      |                                   | "
   @PRTLN "|  +--------------------------------------+                                   | "
   @PRTLN "|    +-----------+    +--------------+                                        | "
   @PRTLN "|    | Button 1  |    | Button 2     |                                        | "
   @PRTLN "|    +-----------+    +--------------+                                        | "
   @PRTLN "|                                                                             | "
   @PRTLN "|   Long Value:                                                               | "
   @PRTLN "|                                                                             | "
   @PRTLN "|   World Code:                                                               | "
   @PRTLN "|                                                                             | "
   @PRTLN "|                                                                             | "
   @PRTLN "+-----------------------------------------------------------------------------+ "
   @PRTLN "                                                                                "
   @PRT "                                                                                "
@RET
:PaintUIScreenInit
@PUSHRETURN
@Locals
   @Local FormPtr
   @POPI FormPtr
   # id: 1, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 11           # RelX
   @PUSH 2           # RelY
   @PUSH 10           # Width
   @PUSH 1           # Height
   @PUSH 0           # ValuePtr: replace with app variable/buffer
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 2, type: 3, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 3           # FieldType
   @PUSH 30           # RelX
   @PUSH 2           # RelY
   @PUSH 24           # Width
   @PUSH 1           # Height
   @PUSH 0           # ValuePtr: replace with app variable/buffer
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 3, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 64           # RelX
   @PUSH 2           # RelY
   @PUSH 10           # Width
   @PUSH 1           # Height
   @PUSH 0           # ValuePtr: replace with app variable/buffer
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 4, type: 7, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 7           # FieldType
   @PUSH 5           # RelX
   @PUSH 6           # RelY
   @PUSH 38           # Width
   @PUSH 6           # Height
   @PUSH 0           # ValuePtr: replace with app variable/buffer
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 5, type: 7, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 7           # FieldType
   @PUSH 48           # RelX
   @PUSH 5           # RelY
   @PUSH 14           # Width
   @PUSH 15           # Height
   @PUSH 0           # ValuePtr: replace with app variable/buffer
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 6, type: 2, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 2           # FieldType
   @PUSH 17           # RelX
   @PUSH 17           # RelY
   @PUSH 25           # Width
   @PUSH 1           # Height
   @PUSH 0           # ValuePtr: replace with app variable/buffer
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 7, type: 3, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 3           # FieldType
   @PUSH 17           # RelX
   @PUSH 19           # RelY
   @PUSH EDIT
   @PUSH 1           # Height
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

