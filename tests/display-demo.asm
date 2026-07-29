############################################################
# display-demo.asm
#
# Small retained-mode display.ld demo.
#
# It builds a simple instrument panel, binds fields to variables,
# renders once, changes the variables, and renders again.
############################################################

I common.mc
L display.ld

:ObjectSize 0
:HEAP_ID 0
:SoftStackStart 0
:SoftStackEnd 0

:PanelForm 0
:StatusForm 0
:StatusTextBox 0

:Altitude 1200
:Heading 90
:VerticalSpeed 300
:LongValue 0 0
:ModeChar "C\0"

:TitleText "EX716 DISPLAY DEMO\0"
:AltLabel "ALT \0"
:HdgLabel "HDG \0"
:VsLabel "VS  \0"
:ModeLabel "MODE \0"
:LongLabel "LONG \0"
:StatusLog "LINE 1: display manager initialized.\nLINE 2: retained values are live.\nLINE 3: this line is deliberately wider than the box and clips to the right.\nLINE 4:\tbottom line with a tab stop.\0"

:Main .Org Main

   @PUSH 0xff00
   @SUB ENDOFCODE
   @POPI ObjectSize

   @Call(AV) HeapDefineMemory ENDOFCODE ObjectSize
   @POPI HEAP_ID

   @Call(VA) HeapNewObject HEAP_ID 0x400
   @POPI SoftStackStart

   @PUSHI SoftStackStart
   @ADD 0x400
   @POPI SoftStackEnd

   @Call(VV) SetSSStack SoftStackEnd SoftStackStart

   # 123456 decimal = 0x0001e240. A width-4 long field should show 3456.
   @PUSH 0xe240 @POPI LongValue
   @PUSH 0x0001 @POPI LongValue+2

   @CALL WinClear
   @Call(V) DisplayInit HEAP_ID
   @POPNULL

   #########################################################
   # Root title field.
   #########################################################

   @PUSHI DisplayRoot
   @PUSH FIELD_TYPE_TEXT
   @PUSH 28
   @PUSH 1
   @PUSH 20
   @PUSH 1
   @PUSH TitleText
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   #########################################################
   # Main bordered panel form.
   #########################################################

   @PUSHI DisplayRoot
   @PUSH 4
   @PUSH 3
   @PUSH 36
   @PUSH 10
   @PUSH FORM_FLAGS_BORDERED
   @CALL DisplayFormNew
   @POPI PanelForm


   @PUSHI PanelForm
   @PUSH FIELD_TYPE_TEXT
   @PUSH 3
   @PUSH 2
   @PUSH 4
   @PUSH 1
   @PUSH AltLabel
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   @PUSHI PanelForm
   @PUSH FIELD_TYPE_INTEGER
   @PUSH 10
   @PUSH 2
   @PUSH 8
   @PUSH 1
   @PUSH Altitude
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL


   @PUSHI PanelForm
   @PUSH FIELD_TYPE_TEXT
   @PUSH 20
   @PUSH 2
   @PUSH 5
   @PUSH 1
   @PUSH LongLabel
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   @PUSHI PanelForm
   @PUSH FIELD_TYPE_LONG
   @PUSH 27
   @PUSH 2
   @PUSH 4
   @PUSH 1
   @PUSH LongValue
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   @PUSHI PanelForm
   @PUSH FIELD_TYPE_TEXT
   @PUSH 3
   @PUSH 4
   @PUSH 4
   @PUSH 1
   @PUSH HdgLabel
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   @PUSHI PanelForm
   @PUSH FIELD_TYPE_INTEGER
   @PUSH 10
   @PUSH 4
   @PUSH 8
   @PUSH 1
   @PUSH Heading
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   @PUSHI PanelForm
   @PUSH FIELD_TYPE_TEXT
   @PUSH 3
   @PUSH 6
   @PUSH 4
   @PUSH 1
   @PUSH VsLabel
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   @PUSHI PanelForm
   @PUSH FIELD_TYPE_INTEGER
   @PUSH 10
   @PUSH 6
   @PUSH 8
   @PUSH 1
   @PUSH VerticalSpeed
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   @PUSHI PanelForm
   @PUSH FIELD_TYPE_TEXT
   @PUSH 3
   @PUSH 8
   @PUSH 5
   @PUSH 1
   @PUSH ModeLabel
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   @PUSHI PanelForm
   @PUSH FIELD_TYPE_CHARACTER
   @PUSH 10
   @PUSH 8
   @PUSH 1
   @PUSH 1
   @PUSH ModeChar
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPNULL

   #########################################################
   # Status child form.
   #########################################################

   @PUSHI DisplayRoot
   @PUSH 4
   @PUSH 15
   @PUSH 64
   @PUSH 4
   @PUSH FORM_FLAGS_BORDERED
   @CALL DisplayFormNew
   @POPI StatusForm


   @PUSHI StatusForm
   @PUSH FIELD_TYPE_TEXTBOX
   @PUSH 2
   @PUSH 1
   @PUSH 58
   @PUSH 2
   @PUSH StatusLog
   @PUSH 0
   @PUSH FIELD_FLAG_VISIBLE
   @CALL DisplayFieldNew
   @POPI StatusTextBox

   @CALL DisplayUpdate

   #########################################################
   # Change application variables and repaint from retained fields.
   #########################################################

   @PUSH 2450 @POPI Altitude
   @PUSH 135 @POPI Heading
   @PUSH -80 @POPI VerticalSpeed
   # 987654 decimal = 0x000f1206. Width-4 should show 7654.
   @PUSH 0x1206 @POPI LongValue
   @PUSH 0x000f @POPI LongValue+2
   @PUSH "D\0" @POPI ModeChar

   # Move the textbox window right six columns for the second paint.
   @FILL_AT_A StatusTextBox FIELD_AUX_VALUE 6

   @CALL DisplayUpdate

   @Call(V) DisplayFormFree DisplayRoot

   @PUSH 1
   @PUSH 22
   @CALL WinCursor
   @PRTLN ""
   @END

:ENDOFCODE
