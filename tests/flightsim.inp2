#PAINTUI VER 1.0
# WIDTH: 80
# HEIGHT: 24
# CANVAS_SIZE: 1920
# NEXT_FORM_ID: 11
# COUNT: 10
# 1 1 1 13 2 6 1 0
# 2 1 1 13 3 6 1 0
# 3 1 1 13 4 6 1 0
# 4 1 1 13 5 6 1 0
# 5 1 1 13 6 6 1 0
# 6 1 1 13 7 6 1 0
# 7 1 1 13 8 6 1 0
# 8 1 1 13 9 6 1 0
# 9 1 3 70 2 6 1 0
# 10 1 1 70 3 6 1 0
# FIELD 1 VALUE Altitude
# FIELD 2 VALUE Heading
# FIELD 3 VALUE Speed
# FIELD 4 VALUE Roll
# FIELD 5 VALUE Bank
# FIELD 6 VALUE Pitch
# FIELD 7 VALUE TurnRate
# FIELD 8 VALUE VertVel
# FIELD 9 VALUE Engine
# FIELD 10 VALUE Fuel
# CANVAS:
# "+------------------+---------------------------------------+-------------------+"
# "|Altitude:         |                                       | Engine:           |"
# "|Heading:          |                                       | Fuel:             |"
# "|Speed:            |                                       |                   |"
# "|Roll:             |                                       |                   |"
# "|Bank:             |                                       |                   |"
# "|Pitch:            |                                       |                   |"
# "|Turn Rate:        |                                       |                   |"
# "|Vert Vel.:        |                                       |                   |"
# "|                  |                                       |                   |"
# "|                  |                                       |                   |"
# "|                  |                                       |                   |"
# "+------------------+---------------------------------------+-------------------+"
# "|                                     F                ^                       |"
# "|    | | |                     +-------------+         |                       |"
# "|    | | |                     |      |      |         |                       |"
# "|    | | |                     |      |      |         |                       |"
# "|    | | |                   L |------+------| R       |      <--------->      |"
# "|    | | |                     |      |      |         |                       |"
# "|    | | |                     |      |      |         |        Rudder         |"
# "|    | | |                     +-------------+         |                       |"
# "|    Thrust                           B                v                       |"
# "|              <Break>              Stick            Flaps                     |"
# "+------------------------------------------------------------------------------+"
# END CANVAS
######################################################
# Start of Code
:DrawBackGround
   @Call(AA) WinCursor 1 1
   @PRT "+------------------+---------------------------------------+-------------------+"
   @Call(AA) WinCursor 1 2
   @PRT "|Altitude:         |                                       | Engine:           |"
   @Call(AA) WinCursor 1 3
   @PRT "|Heading:          |                                       | Fuel:             |"
   @Call(AA) WinCursor 1 4
   @PRT "|Speed:            |                                       |                   |"
   @Call(AA) WinCursor 1 5
   @PRT "|Roll:             |                                       |                   |"
   @Call(AA) WinCursor 1 6
   @PRT "|Bank:             |                                       |                   |"
   @Call(AA) WinCursor 1 7
   @PRT "|Pitch:            |                                       |                   |"
   @Call(AA) WinCursor 1 8
   @PRT "|Turn Rate:        |                                       |                   |"
   @Call(AA) WinCursor 1 9
   @PRT "|Vert Vel.:        |                                       |                   |"
   @Call(AA) WinCursor 1 10
   @PRT "|                  |                                       |                   |"
   @Call(AA) WinCursor 1 11
   @PRT "|                  |                                       |                   |"
   @Call(AA) WinCursor 1 12
   @PRT "|                  |                                       |                   |"
   @Call(AA) WinCursor 1 13
   @PRT "+------------------+---------------------------------------+-------------------+"
   @Call(AA) WinCursor 1 14
   @PRT "|                                     F                ^                       |"
   @Call(AA) WinCursor 1 15
   @PRT "|    | | |                     +-------------+         |                       |"
   @Call(AA) WinCursor 1 16
   @PRT "|    | | |                     |      |      |         |                       |"
   @Call(AA) WinCursor 1 17
   @PRT "|    | | |                     |      |      |         |                       |"
   @Call(AA) WinCursor 1 18
   @PRT "|    | | |                   L |------+------| R       |      <--------->      |"
   @Call(AA) WinCursor 1 19
   @PRT "|    | | |                     |      |      |         |                       |"
   @Call(AA) WinCursor 1 20
   @PRT "|    | | |                     |      |      |         |        Rudder         |"
   @Call(AA) WinCursor 1 21
   @PRT "|    | | |                     +-------------+         |                       |"
   @Call(AA) WinCursor 1 22
   @PRT "|    Thrust                           B                v                       |"
   @Call(AA) WinCursor 1 23
   @PRT "|              <Break>              Stick            Flaps                     |"
   @Call(AA) WinCursor 1 24
   @PRT "+------------------------------------------------------------------------------+"
@RET
:PaintUIScreenInit
@PUSHRETURN
@Locals
   @Local FormPtr
   @POPI FormPtr
   # id: 1, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 13           # RelX
   @PUSH 2           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH Altitude           # ValuePtr
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 2, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 13           # RelX
   @PUSH 3           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH Heading           # ValuePtr
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 3, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 13           # RelX
   @PUSH 4           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH Speed           # ValuePtr
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 4, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 13           # RelX
   @PUSH 5           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH Roll           # ValuePtr
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 5, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 13           # RelX
   @PUSH 6           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH Bank           # ValuePtr
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 6, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 13           # RelX
   @PUSH 7           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH Pitch           # ValuePtr: replace with app variable/buffer
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 7, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 13           # RelX
   @PUSH 8           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH TurnRate           # ValuePtr
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 8, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 13           # RelX
   @PUSH 9           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH VertVel           # ValuePtr
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 9, type: 1, flags: 3, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 70           # RelX
   @PUSH 2           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH Engine           # ValuePtr
   @PUSH 0           # Format Code
   @PUSH FIELD_FLAGS_DEFAULT
   @CALL DisplayFieldNew
   @POPNULL
   # id: 10, type: 1, flags: 1, depth: 0
   @PUSHI FormPtr
   @PUSH 1           # FieldType
   @PUSH 70           # RelX
   @PUSH 3           # RelY
   @PUSH 6           # Width
   @PUSH 1           # Height
   @PUSH Fuel           # ValuePtr
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
