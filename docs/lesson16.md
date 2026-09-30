# EX716 Assembler - Lesson 16: Retained Text Displays with display.ld

`display.ld` provides a retained-mode text display manager for terminal applications.

Instead of repainting every value manually, an application creates forms and fields once. Each field stores a pointer to an application value. The application changes its variables, then calls `DisplayUpdate` to repaint only fields that are dirty or whose retained value changed.

The current demo is:

```text
tests/display-demo.asm
```

## Loading the Library

A normal program can load only `display.ld`; it brings in its display dependencies.

```asm
I common.mc
L display.ld
```

`display.ld` currently loads:

```text
softstack.ld
heapmgr.ld
screen.ld
lmath.ld
string.ld
```

The long math and string libraries are used for integer and long-to-string formatting.

## Required Runtime Setup

Before calling display functions, define heap memory and initialize the software stack.

```asm
:ObjectSize 0
:HEAP_ID 0
:SoftStackStart 0
:SoftStackEnd 0

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
```

Then clear the screen and create root form 0.

```asm
@CALL WinClear
@Call(V) DisplayInit HEAP_ID
@POPNULL
```

`DisplayRoot` now points to form 0, representing the physical terminal screen.

## Forms

Forms are rectangular regions. Child form coordinates are relative to the parent form.

```asm
:PanelForm 0

@PUSHI DisplayRoot
@PUSH 4                  # Relative X
@PUSH 3                  # Relative Y
@PUSH 36                 # Width
@PUSH 10                 # Height
@PUSH FORM_FLAGS_BORDERED
@CALL DisplayFormNew
@POPI PanelForm
```

Useful form flags today:

```asm
FORM_FLAG_VISIBLE
FORM_FLAG_ENABLED
FORM_FLAG_DIRTY
FORM_FLAG_CLEAR      # reserved for later
FORM_FLAG_BORDER
FORM_FLAGS_DEFAULT   # visible | enabled | dirty
FORM_FLAGS_BORDERED  # visible | enabled | dirty | border
```

`FORM_FLAG_BORDER` uses `screen.ld`'s `WinBox`, so box style belongs to the screen library.

## Fields

A field belongs to a form and retains a pointer to application data.

```asm
:Altitude 1200

@PUSHI PanelForm
@PUSH FIELD_TYPE_INTEGER
@PUSH 10                 # Relative X
@PUSH 2                  # Relative Y
@PUSH 8                  # Width
@PUSH 1                  # Height
@PUSH Altitude           # Retained value pointer
@PUSH 0                  # Format code, reserved for future formatting
@PUSH FIELD_FLAG_VISIBLE
@CALL DisplayFieldNew
@POPNULL
```

Initial field types:

```asm
FIELD_TYPE_INTEGER
FIELD_TYPE_LONG
FIELD_TYPE_STRING
FIELD_TYPE_TEXT
FIELD_TYPE_BOX
FIELD_TYPE_CHARACTER
FIELD_TYPE_TEXTBOX
```

The pointer passed in `FIELD_VALUE_PTR` must remain valid for the lifetime of the field.

## Updating Values

The application changes variables directly. The display manager reads the new values on update.

```asm
@PUSH 2450 @POPI Altitude
@CALL DisplayUpdate
```

`DisplayUpdate` walks the form tree recursively. Fields are drawn only when dirty or when their retained value signature changed.

Current signatures are simple and cheap:

```text
INTEGER   current word
LONG      current low/high words
CHARACTER current word
TEXT      retained pointer
STRING    retained pointer
BOX       retained pointer
TEXTBOX   retained pointer plus FIELD_AUX_VALUE
```

If string contents change in place without changing the pointer, call `DisplayMarkFieldDirty` for that field.

## Numeric Formatting

Integer and long fields are formatted into field-owned heap buffers, then printed as strings. This allows values to be padded or clipped before printing.

If a numeric string is shorter than the field width, it is padded with spaces.

If it is longer than the field width, the rightmost characters are kept.

Example:

```text
Value: 123456
Width: 4
Shown: 3456
```

The field-owned buffer is stored in `FIELD_AUX_PTR` and reused across updates. It is freed by `DisplayFieldFree` or recursive `DisplayFormFree`.

## Textbox Fields

`FIELD_TYPE_TEXTBOX` is for rectangular multiline text. It is useful for status boxes, logs, and future map windows.

Current behavior:

```text
- FIELD_VALUE_PTR points to source text
- FIELD_WIDTH and FIELD_HEIGHT define the visible box
- FIELD_AUX_PTR owns the render buffer
- FIELD_AUX_VALUE is horizontal left offset
- newline splits logical lines
- tab expands to 4-column stops
- long lines clip on the right
- bottom FIELD_HEIGHT lines are displayed
```

Example source text:

```asm
:StatusLog "LINE 1: ready.\nLINE 2: values live.\nLINE 3: this line is wider than the box.\nLINE 4:\tbottom line.\0"
```

Create a two-line textbox inside a form:

```asm
:StatusTextBox 0

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
```

Scroll horizontally by changing `FIELD_AUX_VALUE`.

```asm
@FILL_AT_A StatusTextBox FIELD_AUX_VALUE 6
@CALL DisplayUpdate
```

The textbox will repaint because its signature includes the left offset.

## Cleanup

Use `DisplayFormFree` to recursively free a form, its fields, its child forms, and field-owned buffers.

```asm
@Call(V) DisplayFormFree DisplayRoot
```

`DisplayFieldFree` can free one field and unlink it from its parent form.

## Complete Example

See:

```text
tests/display-demo.asm
```

Run it with:

```sh
python3 cpu.py tests/display-demo.asm
```

The demo shows:

```text
- bordered forms
- retained text labels
- integer fields
- long fields with right-side clipping
- character fields
- multiline textbox bottom-scroll
- horizontal textbox offset
- dirty/change detection
- recursive cleanup
```

## Current Limitations

`display.ld` is still young. Current known limits:

```text
- Text and string fields use pointer signatures, not content checksums.
- TEXTBOX supports bottom-scroll mode, not fixed map/window mode yet.
- Textbox lines clip; they do not wrap.
- FORM_FLAG_CLEAR is reserved but not implemented.
- Full parent-edge clipping is still incomplete for simple text/string fields.
- Numeric FIELD_FORMAT_CODE patterns such as ###,###.## are not implemented yet.
```
