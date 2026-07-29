! __LIB_DISPLAY_LOADED
M __LIB_DISPLAY_LOADED 1
I common.mc
I display.ref

# display.ld - retained-mode text display/form manager.

G DisplayInit
G DisplayRoot
G DisplayHeap
G DisplayFormNew
G DisplayFieldNew
G DisplayUpdate
G DisplayUpdateForm
G DisplayMarkFormDirty
G DisplayMarkFieldDirty
G DisplayCalcForm
G DisplayDrawField
G DisplayFieldFree
G DisplayFormFree
G DisplayEnsureFieldBuffer
G DisplayFormatInteger
G DisplayFormatLong
G DisplayFitBuffer
G DisplayFormatTextBox
G DisplayTextBoxPutSpace
G DisplayFieldShouldDraw
G DisplayFieldCommitSignature
G DisplayDrawFormFrame

G FORM_PARENT G FORM_REL_X G FORM_REL_Y G FORM_WIDTH G FORM_HEIGHT
G FORM_ABS_X G FORM_ABS_Y G FORM_CLIP_X1 G FORM_CLIP_Y1 G FORM_CLIP_X2 G FORM_CLIP_Y2
G FORM_FIRST_FIELD G FORM_FIRST_CHILD G FORM_NEXT_SIBLING G FORM_FLAGS G FORM_BACKGROUND_FORMAT G FORM_DIRTY G FORM_OBJECT_SIZE
G FIELD_FORM G FIELD_NEXT G FIELD_TYPE G FIELD_REL_X G FIELD_REL_Y G FIELD_WIDTH G FIELD_HEIGHT
G FIELD_VALUE_PTR G FIELD_FORMAT_CODE G FIELD_FLAGS G FIELD_AUX_PTR G FIELD_AUX_VALUE
G FIELD_LAST_VALUE_1 G FIELD_LAST_VALUE_2 G FIELD_LAST_SIGNATURE G FIELD_OBJECT_SIZE
G FORM_FLAG_VISIBLE G FORM_FLAG_ENABLED G FORM_FLAG_DIRTY G FORM_FLAG_CLEAR G FORM_FLAG_BORDER
G FORM_FLAGS_DEFAULT G FORM_FLAGS_BORDERED
G FIELD_FLAG_VISIBLE G FIELD_FLAG_DIRTY G FIELD_FLAGS_DEFAULT
G FIELD_TYPE_INTEGER G FIELD_TYPE_LONG G FIELD_TYPE_STRING G FIELD_TYPE_TEXT G FIELD_TYPE_BOX G FIELD_TYPE_CHARACTER G FIELD_TYPE_TEXTBOX
G DISPLAY_NUMERIC_BUFFER_MIN

=FORM_PARENT             0
=FORM_REL_X              2
=FORM_REL_Y              4
=FORM_WIDTH              6
=FORM_HEIGHT             8
=FORM_ABS_X             10
=FORM_ABS_Y             12
=FORM_CLIP_X1           14
=FORM_CLIP_Y1           16
=FORM_CLIP_X2           18
=FORM_CLIP_Y2           20
=FORM_FIRST_FIELD       22
=FORM_FIRST_CHILD       24
=FORM_NEXT_SIBLING      26
=FORM_FLAGS             28
=FORM_BACKGROUND_FORMAT 30
=FORM_DIRTY             32
=FORM_OBJECT_SIZE       34

=FIELD_FORM             0
=FIELD_NEXT             2
=FIELD_TYPE             4
=FIELD_REL_X            6
=FIELD_REL_Y            8
=FIELD_WIDTH           10
=FIELD_HEIGHT          12
=FIELD_VALUE_PTR       14
=FIELD_FORMAT_CODE     16
=FIELD_FLAGS           18
=FIELD_AUX_PTR         20
=FIELD_AUX_VALUE       22
=FIELD_LAST_VALUE_1    24
=FIELD_LAST_VALUE_2    26
=FIELD_LAST_SIGNATURE  28
=FIELD_OBJECT_SIZE     30

=FORM_FLAG_VISIBLE      0x0001
=FORM_FLAG_ENABLED      0x0002
=FORM_FLAG_DIRTY        0x0004
=FORM_FLAG_CLEAR        0x0008
=FORM_FLAG_BORDER       0x0010
=FORM_FLAGS_DEFAULT     0x0007
=FORM_FLAGS_BORDERED    0x0017
=FIELD_FLAG_VISIBLE     0x0001
=FIELD_FLAG_DIRTY       0x0002
=FIELD_FLAGS_DEFAULT    0x0003
=FIELD_TYPE_INTEGER     1
=FIELD_TYPE_LONG        2
=FIELD_TYPE_STRING      3
=FIELD_TYPE_TEXT        4
=FIELD_TYPE_BOX         5
=FIELD_TYPE_CHARACTER   6
=FIELD_TYPE_TEXTBOX     7
=DISPLAY_NUMERIC_BUFFER_MIN 16

:DisplayHeap 0
:DisplayRoot 0
:DisplayCharBuf 0 0

@FUNCTION DisplayInit
:DisplayInit
@PUSHRETURN
@Locals
@Local HeapID
@Local RootPtr
   @POPI HeapID
   @MV2V HeapID DisplayHeap
   @Call(VA) HeapNewObject HeapID FORM_OBJECT_SIZE
   @POPI RootPtr
   @MV2V RootPtr DisplayRoot
   @FILL_AT_A RootPtr FORM_PARENT 0
   @FILL_AT_A RootPtr FORM_REL_X 1
   @FILL_AT_A RootPtr FORM_REL_Y 1
   @FILL_AT_V RootPtr FORM_WIDTH WinWidth
   @FILL_AT_V RootPtr FORM_HEIGHT WinHeight
   @FILL_AT_A RootPtr FORM_ABS_X 1
   @FILL_AT_A RootPtr FORM_ABS_Y 1
   @FILL_AT_A RootPtr FORM_CLIP_X1 1
   @FILL_AT_A RootPtr FORM_CLIP_Y1 1
   @FILL_AT_V RootPtr FORM_CLIP_X2 WinWidth
   @FILL_AT_V RootPtr FORM_CLIP_Y2 WinHeight
   @FILL_AT_A RootPtr FORM_FIRST_FIELD 0
   @FILL_AT_A RootPtr FORM_FIRST_CHILD 0
   @FILL_AT_A RootPtr FORM_NEXT_SIBLING 0
   @FILL_AT_A RootPtr FORM_FLAGS FORM_FLAGS_DEFAULT
   @FILL_AT_A RootPtr FORM_BACKGROUND_FORMAT 0
   @FILL_AT_A RootPtr FORM_DIRTY 1
   @PUSHI RootPtr
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION DisplayFormNew
:DisplayFormNew
@PUSHRETURN
@Locals
@Local Parent
@Local RelX
@Local RelY
@Local Width
@Local Height
@Local Flags
@Local FormPtr
@Local LinkPtr
   @POPI Flags
   @POPI Height
   @POPI Width
   @POPI RelY
   @POPI RelX
   @POPI Parent
   @Call(VA) HeapNewObject DisplayHeap FORM_OBJECT_SIZE
   @POPI FormPtr
   @FILL_AT_V FormPtr FORM_PARENT Parent
   @FILL_AT_V FormPtr FORM_REL_X RelX
   @FILL_AT_V FormPtr FORM_REL_Y RelY
   @FILL_AT_V FormPtr FORM_WIDTH Width
   @FILL_AT_V FormPtr FORM_HEIGHT Height
   @FILL_AT_A FormPtr FORM_ABS_X 0
   @FILL_AT_A FormPtr FORM_ABS_Y 0
   @FILL_AT_A FormPtr FORM_CLIP_X1 0
   @FILL_AT_A FormPtr FORM_CLIP_Y1 0
   @FILL_AT_A FormPtr FORM_CLIP_X2 0
   @FILL_AT_A FormPtr FORM_CLIP_Y2 0
   @FILL_AT_A FormPtr FORM_FIRST_FIELD 0
   @FILL_AT_A FormPtr FORM_FIRST_CHILD 0
   @FILL_AT_A FormPtr FORM_NEXT_SIBLING 0
   @PUSHI Flags @OR FORM_FLAG_DIRTY @POPI Flags
   @FILL_AT_V FormPtr FORM_FLAGS Flags
   @FILL_AT_A FormPtr FORM_BACKGROUND_FORMAT 0
   @FILL_AT_A FormPtr FORM_DIRTY 1
   @GET_FROM Parent FORM_FIRST_CHILD
   @IF_ZERO
      @POPNULL
      @FILL_AT_V Parent FORM_FIRST_CHILD FormPtr
   @ELSE
      @POPI LinkPtr
      @GET_FROM LinkPtr FORM_NEXT_SIBLING
      @WHILE_NOTZERO
         @POPI LinkPtr
         @GET_FROM LinkPtr FORM_NEXT_SIBLING
      @ENDWHILE
      @POPNULL
      @FILL_AT_V LinkPtr FORM_NEXT_SIBLING FormPtr
   @ENDIF
   @Call(V) DisplayCalcForm FormPtr
   @PUSHI FormPtr
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION DisplayFieldNew
:DisplayFieldNew
@PUSHRETURN
@Locals
@Local FormPtr
@Local FieldType
@Local RelX
@Local RelY
@Local Width
@Local Height
@Local ValuePtr
@Local Format
@Local Flags
@Local FieldPtr
@Local LinkPtr
   @POPI Flags
   @POPI Format
   @POPI ValuePtr
   @POPI Height
   @POPI Width
   @POPI RelY
   @POPI RelX
   @POPI FieldType
   @POPI FormPtr
   @Call(VA) HeapNewObject DisplayHeap FIELD_OBJECT_SIZE
   @POPI FieldPtr
   @FILL_AT_V FieldPtr FIELD_FORM FormPtr
   @FILL_AT_A FieldPtr FIELD_NEXT 0
   @FILL_AT_V FieldPtr FIELD_TYPE FieldType
   @FILL_AT_V FieldPtr FIELD_REL_X RelX
   @FILL_AT_V FieldPtr FIELD_REL_Y RelY
   @FILL_AT_V FieldPtr FIELD_WIDTH Width
   @FILL_AT_V FieldPtr FIELD_HEIGHT Height
   @FILL_AT_V FieldPtr FIELD_VALUE_PTR ValuePtr
   @FILL_AT_V FieldPtr FIELD_FORMAT_CODE Format
   @PUSHI Flags @OR FIELD_FLAG_DIRTY @POPI Flags
   @FILL_AT_V FieldPtr FIELD_FLAGS Flags
   @FILL_AT_A FieldPtr FIELD_AUX_PTR 0
   @FILL_AT_A FieldPtr FIELD_AUX_VALUE 0
   @FILL_AT_A FieldPtr FIELD_LAST_VALUE_1 0
   @FILL_AT_A FieldPtr FIELD_LAST_VALUE_2 0
   @FILL_AT_A FieldPtr FIELD_LAST_SIGNATURE 0
   @GET_FROM FormPtr FORM_FIRST_FIELD
   @IF_ZERO
      @POPNULL
      @FILL_AT_V FormPtr FORM_FIRST_FIELD FieldPtr
   @ELSE
      @POPI LinkPtr
      @GET_FROM LinkPtr FIELD_NEXT
      @WHILE_NOTZERO
         @POPI LinkPtr
         @GET_FROM LinkPtr FIELD_NEXT
      @ENDWHILE
      @POPNULL
      @FILL_AT_V LinkPtr FIELD_NEXT FieldPtr
   @ENDIF
   @Call(V) DisplayMarkFormDirty FormPtr
   @PUSHI FieldPtr
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION DisplayCalcForm
:DisplayCalcForm
@PUSHRETURN
@Locals
@Local FormPtr
@Local Parent
@Local AbsX
@Local AbsY
@Local X2
@Local Y2
   @POPI FormPtr
   @GET_FROM FormPtr FORM_PARENT @POPI Parent
   @IF_EQ_AV 0 Parent
      @GET_FROM FormPtr FORM_REL_X @POPI AbsX
      @GET_FROM FormPtr FORM_REL_Y @POPI AbsY
      @FILL_AT_V FormPtr FORM_ABS_X AbsX
      @FILL_AT_V FormPtr FORM_ABS_Y AbsY
      @GET_FROM FormPtr FORM_WIDTH @ADDI AbsX @SUB 1 @POPI X2
      @GET_FROM FormPtr FORM_HEIGHT @ADDI AbsY @SUB 1 @POPI Y2
      @FILL_AT_V FormPtr FORM_CLIP_X1 AbsX
      @FILL_AT_V FormPtr FORM_CLIP_Y1 AbsY
      @FILL_AT_V FormPtr FORM_CLIP_X2 X2
      @FILL_AT_V FormPtr FORM_CLIP_Y2 Y2
   @ELSE
      @GET_FROM Parent FORM_ABS_X @GET_FROM FormPtr FORM_REL_X @ADDS @POPI AbsX
      @GET_FROM Parent FORM_ABS_Y @GET_FROM FormPtr FORM_REL_Y @ADDS @POPI AbsY
      @FILL_AT_V FormPtr FORM_ABS_X AbsX
      @FILL_AT_V FormPtr FORM_ABS_Y AbsY
      @GET_FROM FormPtr FORM_WIDTH @ADDI AbsX @SUB 1 @POPI X2
      @GET_FROM FormPtr FORM_HEIGHT @ADDI AbsY @SUB 1 @POPI Y2
      @PUSHI AbsX
      @GET_FROM Parent FORM_CLIP_X1
      @IF_LT_S
         @SWP @POPNULL
      @ELSE
         @POPNULL
      @ENDIF
      @FILL_AT_S FormPtr FORM_CLIP_X1
      @PUSHI AbsY
      @GET_FROM Parent FORM_CLIP_Y1
      @IF_LT_S
         @SWP @POPNULL
      @ELSE
         @POPNULL
      @ENDIF
      @FILL_AT_S FormPtr FORM_CLIP_Y1
      @PUSHI X2
      @GET_FROM Parent FORM_CLIP_X2
      @IF_GT_S
         @SWP @POPNULL
      @ELSE
         @POPNULL
      @ENDIF
      @FILL_AT_S FormPtr FORM_CLIP_X2
      @PUSHI Y2
      @GET_FROM Parent FORM_CLIP_Y2
      @IF_GT_S
         @SWP @POPNULL
      @ELSE
         @POPNULL
      @ENDIF
      @FILL_AT_S FormPtr FORM_CLIP_Y2
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION DisplayUpdate
:DisplayUpdate
@PUSHI DisplayRoot
@CALL DisplayUpdateForm
@RET
@ENDFUNCTION

@FUNCTION DisplayUpdateForm
:DisplayUpdateForm
@PUSHRETURN
@Locals
@Local FormPtr
@Local FieldPtr
@Local ChildPtr
   @POPI FormPtr
   @IF_EQ_AV 0 FormPtr
   @ELSE
      @GET_FROM FormPtr FORM_FLAGS
      @AND FORM_FLAG_VISIBLE
      @IF_NOTZERO
         @POPNULL
         @Call(V) DisplayCalcForm FormPtr
         @GET_FROM FormPtr FORM_DIRTY
         @IF_NOTZERO
            @POPNULL
            @Call(V) DisplayDrawFormFrame FormPtr
         @ELSE
            @POPNULL
         @ENDIF
         @GET_FROM FormPtr FORM_FIRST_FIELD @POPI FieldPtr
         @PUSHI FieldPtr
         @WHILE_NOTZERO
            @POPNULL
            @Call(V) DisplayDrawField FieldPtr
            @GET_FROM FieldPtr FIELD_NEXT @POPI FieldPtr
            @PUSHI FieldPtr
         @ENDWHILE
         @POPNULL
         @GET_FROM FormPtr FORM_FIRST_CHILD @POPI ChildPtr
         @PUSHI ChildPtr
         @WHILE_NOTZERO
            @POPNULL
            @Call(V) DisplayUpdateForm ChildPtr
            @GET_FROM ChildPtr FORM_NEXT_SIBLING @POPI ChildPtr
            @PUSHI ChildPtr
         @ENDWHILE
         @POPNULL
         @FILL_AT_A FormPtr FORM_DIRTY 0
      @ENDIF
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION DisplayMarkFormDirty
:DisplayMarkFormDirty
@PUSHRETURN
@Locals
@Local FormPtr
@Local Flags
   @POPI FormPtr
   @FILL_AT_A FormPtr FORM_DIRTY 1
   @GET_FROM FormPtr FORM_FLAGS @OR FORM_FLAG_DIRTY @POPI Flags
   @FILL_AT_V FormPtr FORM_FLAGS Flags
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION DisplayMarkFieldDirty
:DisplayMarkFieldDirty
@PUSHRETURN
@Locals
@Local FieldPtr
@Local FormPtr
@Local Flags
   @POPI FieldPtr
   @GET_FROM FieldPtr FIELD_FLAGS @OR FIELD_FLAG_DIRTY @POPI Flags
   @FILL_AT_V FieldPtr FIELD_FLAGS Flags
   @GET_FROM FieldPtr FIELD_FORM @POPI FormPtr
   @Call(V) DisplayMarkFormDirty FormPtr
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayFieldFree(FieldPtr)
#
# Frees a field and any field-owned heap buffer in FIELD_AUX_PTR.
# If the field is linked into its parent form, it is unlinked first.
#####################################################################
@FUNCTION DisplayFieldFree
:DisplayFieldFree
@PUSHRETURN
@Locals
@Local FieldPtr
@Local FormPtr
@Local AuxPtr
@Local CurPtr
@Local PrevPtr
@Local NextPtr
   @POPI FieldPtr
   @IF_EQ_AV 0 FieldPtr
      @JMP DFF_Done
   @ENDIF

   @GET_FROM FieldPtr FIELD_FORM @POPI FormPtr
   @IF_EQ_AV 0 FormPtr
   @ELSE
      @MA2V 0 PrevPtr
      @GET_FROM FormPtr FORM_FIRST_FIELD @POPI CurPtr
      @PUSHI CurPtr
      @WHILE_NOTZERO
         @POPNULL
         @IF_EQ_VV CurPtr FieldPtr
            @GET_FROM CurPtr FIELD_NEXT @POPI NextPtr
            @IF_EQ_AV 0 PrevPtr
               @FILL_AT_V FormPtr FORM_FIRST_FIELD NextPtr
            @ELSE
               @FILL_AT_V PrevPtr FIELD_NEXT NextPtr
            @ENDIF
            @MA2V 0 CurPtr
            @JMP DFF_Unlinked
         @ENDIF
         @MV2V CurPtr PrevPtr
         @GET_FROM CurPtr FIELD_NEXT @POPI CurPtr
         @PUSHI CurPtr
      @ENDWHILE
      @POPNULL
   @ENDIF
   :DFF_Unlinked

   @GET_FROM FieldPtr FIELD_AUX_PTR @POPI AuxPtr
   @IF_EQ_AV 0 AuxPtr
   @ELSE
      @Call(VV) HeapDeleteObject DisplayHeap AuxPtr
      @POPNULL
   @ENDIF

   @Call(VV) HeapDeleteObject DisplayHeap FieldPtr
   @POPNULL

   :DFF_Done
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayFormFree(FormPtr)
#
# Recursively frees all fields and child forms, then frees FormPtr.
# The form is unlinked from its parent sibling list when possible.
#####################################################################
@FUNCTION DisplayFormFree
:DisplayFormFree
@PUSHRETURN
@Locals
@Local FormPtr
@Local Parent
@Local CurPtr
@Local PrevPtr
@Local NextPtr
@Local FieldPtr
@Local ChildPtr
   @POPI FormPtr
   @IF_EQ_AV 0 FormPtr
      @JMP DFO_Done
   @ENDIF

   # Free fields first. DisplayFieldFree unlinks each field.
   @GET_FROM FormPtr FORM_FIRST_FIELD @POPI FieldPtr
   @PUSHI FieldPtr
   @WHILE_NOTZERO
      @POPNULL
      @GET_FROM FieldPtr FIELD_NEXT @POPI NextPtr
      @Call(V) DisplayFieldFree FieldPtr
      @MV2V NextPtr FieldPtr
      @PUSHI FieldPtr
   @ENDWHILE
   @POPNULL

   # Free child forms depth-first.
   @GET_FROM FormPtr FORM_FIRST_CHILD @POPI ChildPtr
   @PUSHI ChildPtr
   @WHILE_NOTZERO
      @POPNULL
      @GET_FROM ChildPtr FORM_NEXT_SIBLING @POPI NextPtr
      @Call(V) DisplayFormFree ChildPtr
      @MV2V NextPtr ChildPtr
      @PUSHI ChildPtr
   @ENDWHILE
   @POPNULL

   # Unlink from parent child list.
   @GET_FROM FormPtr FORM_PARENT @POPI Parent
   @IF_EQ_AV 0 Parent
   @ELSE
      @MA2V 0 PrevPtr
      @GET_FROM Parent FORM_FIRST_CHILD @POPI CurPtr
      @PUSHI CurPtr
      @WHILE_NOTZERO
         @POPNULL
         @IF_EQ_VV CurPtr FormPtr
            @GET_FROM CurPtr FORM_NEXT_SIBLING @POPI NextPtr
            @IF_EQ_AV 0 PrevPtr
               @FILL_AT_V Parent FORM_FIRST_CHILD NextPtr
            @ELSE
               @FILL_AT_V PrevPtr FORM_NEXT_SIBLING NextPtr
            @ENDIF
            @MA2V 0 CurPtr
            @JMP DFO_Unlinked
         @ENDIF
         @MV2V CurPtr PrevPtr
         @GET_FROM CurPtr FORM_NEXT_SIBLING @POPI CurPtr
         @PUSHI CurPtr
      @ENDWHILE
      @POPNULL
   @ENDIF
   :DFO_Unlinked

   @IF_EQ_VV DisplayRoot FormPtr
      @MA2V 0 DisplayRoot
   @ENDIF

   @Call(VV) HeapDeleteObject DisplayHeap FormPtr
   @POPNULL

   :DFO_Done
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayEnsureFieldBuffer(FieldPtr,MinSize):(BufferPtr)
#
# Numeric fields own one reusable heap buffer in FIELD_AUX_PTR.
#####################################################################
@FUNCTION DisplayEnsureFieldBuffer
:DisplayEnsureFieldBuffer
@PUSHRETURN
@Locals
@Local FieldPtr
@Local MinSize
@Local BufPtr
   @POPI MinSize
   @POPI FieldPtr
   @GET_FROM FieldPtr FIELD_AUX_PTR @POPI BufPtr
   @IF_EQ_AV 0 BufPtr
      @Call(VV) HeapNewObject DisplayHeap MinSize
      @POPI BufPtr
      @FILL_AT_V FieldPtr FIELD_AUX_PTR BufPtr
   @ENDIF
   @PUSHI BufPtr
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayFitBuffer(BufPtr,Width):(BufPtr)
#
# Fits a numeric string to field width in-place. If the string is too
# long, keep the rightmost Width characters. If it is short, pad with
# spaces. The buffer is always null terminated.
#####################################################################
@FUNCTION DisplayFitBuffer
:DisplayFitBuffer
@PUSHRETURN
@Locals
@Local BufPtr
@Local Width
@Local StrLen
@Local SrcPtr
@Local DstPtr
@Local Index
   @POPI Width
   @POPI BufPtr
   @Call(V) strlen BufPtr
   @POPI StrLen

   @PUSHI StrLen
   @IF_GT_V Width
      @POPNULL
      @PUSHI BufPtr @ADDI StrLen @SUBI Width @POPI SrcPtr
      @MV2V BufPtr DstPtr
      @ForIA2V Index 0 Width
         @PUSHII SrcPtr @AND 0xff
         @POPII DstPtr
         @INCI SrcPtr
         @INCI DstPtr
      @Next Index
      @PUSH 0
      @POPII DstPtr
      @JMP DFB_Done
   @ENDIF
   @POPNULL

   @PUSHI BufPtr @ADDI StrLen @POPI DstPtr
   @PUSHI StrLen
   @IF_LT_V Width
      @POPNULL
      @ForIV2V Index StrLen Width
         @PUSH " \0"
         @POPII DstPtr
         @INCI DstPtr
      @Next Index
   @ELSE
      @POPNULL
   @ENDIF
   @PUSH 0
   @POPII DstPtr

   :DFB_Done
   @PUSHI BufPtr
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayFormatInteger(FieldPtr):(BufferPtr)
#
# Converts the retained integer into a field-owned buffer, pads the
# field width with spaces, null terminates, and returns BufferPtr.
#####################################################################
@FUNCTION DisplayFormatInteger
:DisplayFormatInteger
@PUSHRETURN
@Locals
@Local FieldPtr
@Local ValuePtr
@Local BufPtr
@Local Width
@Local BufSize
   @POPI FieldPtr
   @GET_FROM FieldPtr FIELD_WIDTH @POPI Width
   @PUSHI Width @ADD 1 @POPI BufSize
   @PUSHI BufSize
   @IF_LT_A DISPLAY_NUMERIC_BUFFER_MIN
      @POPNULL
      @MA2V DISPLAY_NUMERIC_BUFFER_MIN BufSize
   @ELSE
      @POPNULL
   @ENDIF

   @Call(VV) DisplayEnsureFieldBuffer FieldPtr BufSize
   @POPI BufPtr
   @GET_FROM FieldPtr FIELD_VALUE_PTR @POPI ValuePtr

   @PUSHI BufPtr
   @PUSHII ValuePtr
   @PUSH 10
   @CALL itos

   @Call(VV) DisplayFitBuffer BufPtr Width
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayFormatLong(FieldPtr):(BufferPtr)
#
# Converts the retained 32-bit integer into a field-owned buffer, pads
# the field width with spaces, null terminates, and returns BufferPtr.
#####################################################################
@FUNCTION DisplayFormatLong
:DisplayFormatLong
@PUSHRETURN
@Locals
@Local FieldPtr
@Local ValuePtr
@Local BufPtr
@Local Width
@Local BufSize
   @POPI FieldPtr
   @GET_FROM FieldPtr FIELD_WIDTH @POPI Width
   @PUSHI Width @ADD 1 @POPI BufSize
   @PUSHI BufSize
   @IF_LT_A DISPLAY_NUMERIC_BUFFER_MIN
      @POPNULL
      @MA2V DISPLAY_NUMERIC_BUFFER_MIN BufSize
   @ELSE
      @POPNULL
   @ENDIF

   @Call(VV) DisplayEnsureFieldBuffer FieldPtr BufSize
   @POPI BufPtr
   @GET_FROM FieldPtr FIELD_VALUE_PTR @POPI ValuePtr

   @PUSHI BufPtr
   @PUSHII ValuePtr
   @PUSHI ValuePtr @ADD 2 @PUSHS
   @PUSH 10
   @CALL i32tos

   @Call(VV) DisplayFitBuffer BufPtr Width
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayDrawFormFrame(FormPtr)
#
# Handles form-level clear/border drawing. Border style remains owned
# by screen.ld through WinBox. FORM_FLAG_BORDER simply requests it.
#####################################################################
@FUNCTION DisplayDrawFormFrame
:DisplayDrawFormFrame
@PUSHRETURN
@Locals
@Local FormPtr
@Local Flags
@Local X1
@Local Y1
@Local X2
@Local Y2
   @POPI FormPtr
   @GET_FROM FormPtr FORM_FLAGS @POPI Flags
   @PUSHI Flags @AND FORM_FLAG_BORDER
   @IF_NOTZERO
      @POPNULL
      @GET_FROM FormPtr FORM_ABS_X @POPI X1
      @GET_FROM FormPtr FORM_ABS_Y @POPI Y1
      @GET_FROM FormPtr FORM_WIDTH @ADDI X1 @SUB 1 @POPI X2
      @GET_FROM FormPtr FORM_HEIGHT @ADDI Y1 @SUB 1 @POPI Y2
      @PUSHI X1 @PUSHI Y1 @PUSHI X2 @PUSHI Y2 @CALL WinBox
   @ELSE
      @POPNULL
   @ENDIF
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayFieldShouldDraw(FieldPtr):(0|1)
#
# Returns 1 when a field is dirty or its retained value signature has
# changed since the last draw. The first pass uses cheap signatures:
# integer/character low word, long low/high words, and pointer plus
# textbox left offset for text-oriented fields.
#####################################################################
@FUNCTION DisplayFieldShouldDraw
:DisplayFieldShouldDraw
@PUSHRETURN
@Locals
@Local FieldPtr
@Local FieldType
@Local ValuePtr
@Local Flags
@Local Cur1
@Local Cur2
   @POPI FieldPtr
   @GET_FROM FieldPtr FIELD_FLAGS @POPI Flags
   @PUSHI Flags @AND FIELD_FLAG_DIRTY
   @IF_NOTZERO
      @POPNULL
      @PUSH 1
      @JMP DFS_Done
   @ENDIF
   @POPNULL

   @GET_FROM FieldPtr FIELD_TYPE @POPI FieldType
   @GET_FROM FieldPtr FIELD_VALUE_PTR @POPI ValuePtr
   @MA2V 0 Cur2

   @PUSHI FieldType
   @SWITCH
   @CASE FIELD_TYPE_INTEGER
      @POPNULL
      @PUSHII ValuePtr @POPI Cur1
   @CBREAK
   @CASE FIELD_TYPE_CHARACTER
      @POPNULL
      @PUSHII ValuePtr @POPI Cur1
   @CBREAK
   @CASE FIELD_TYPE_LONG
      @POPNULL
      @PUSHII ValuePtr @POPI Cur1
      @PUSHI ValuePtr @ADD 2 @PUSHS @POPI Cur2
   @CBREAK
   @CASE FIELD_TYPE_TEXTBOX
      @POPNULL
      @MV2V ValuePtr Cur1
      @GET_FROM FieldPtr FIELD_AUX_VALUE @POPI Cur2
   @CBREAK
   @CDEFAULT
      @POPNULL
      @MV2V ValuePtr Cur1
   @CBREAK
   @ENDCASE

   @GET_FROM FieldPtr FIELD_LAST_VALUE_1
   @PUSHI Cur1
   @IF_EQ_S
      @POPNULL @POPNULL
      @GET_FROM FieldPtr FIELD_LAST_VALUE_2
      @PUSHI Cur2
      @IF_EQ_S
         @POPNULL @POPNULL
         @PUSH 0
         @JMP DFS_Done
      @ENDIF
      @POPNULL @POPNULL
   @ELSE
      @POPNULL @POPNULL
   @ENDIF
   @PUSH 1

   :DFS_Done
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayFieldCommitSignature(FieldPtr)
#
# Stores the current field signature and clears FIELD_FLAG_DIRTY.
#####################################################################
@FUNCTION DisplayFieldCommitSignature
:DisplayFieldCommitSignature
@PUSHRETURN
@Locals
@Local FieldPtr
@Local FieldType
@Local ValuePtr
@Local Flags
@Local Cur1
@Local Cur2
   @POPI FieldPtr
   @GET_FROM FieldPtr FIELD_TYPE @POPI FieldType
   @GET_FROM FieldPtr FIELD_VALUE_PTR @POPI ValuePtr
   @MA2V 0 Cur2

   @PUSHI FieldType
   @SWITCH
   @CASE FIELD_TYPE_INTEGER
      @POPNULL
      @PUSHII ValuePtr @POPI Cur1
   @CBREAK
   @CASE FIELD_TYPE_CHARACTER
      @POPNULL
      @PUSHII ValuePtr @POPI Cur1
   @CBREAK
   @CASE FIELD_TYPE_LONG
      @POPNULL
      @PUSHII ValuePtr @POPI Cur1
      @PUSHI ValuePtr @ADD 2 @PUSHS @POPI Cur2
   @CBREAK
   @CASE FIELD_TYPE_TEXTBOX
      @POPNULL
      @MV2V ValuePtr Cur1
      @GET_FROM FieldPtr FIELD_AUX_VALUE @POPI Cur2
   @CBREAK
   @CDEFAULT
      @POPNULL
      @MV2V ValuePtr Cur1
   @CBREAK
   @ENDCASE

   @FILL_AT_V FieldPtr FIELD_LAST_VALUE_1 Cur1
   @FILL_AT_V FieldPtr FIELD_LAST_VALUE_2 Cur2
   @GET_FROM FieldPtr FIELD_FLAGS @AND 0xfffd @POPI Flags
   @FILL_AT_V FieldPtr FIELD_FLAGS Flags
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayTextBoxPutSpace(DstPtr,Col,DstCol,LeftOffset,Width):(DstPtr,DstCol)
#
# Emits one visual space into the textbox buffer when it falls inside
# the horizontal window. Always advances Col in caller-owned logic.
#####################################################################
@FUNCTION DisplayTextBoxPutSpace
:DisplayTextBoxPutSpace
@PUSHRETURN
@Locals
@Local DstPtr
@Local Col
@Local DstCol
@Local LeftOffset
@Local Width
   @POPI Width
   @POPI LeftOffset
   @POPI DstCol
   @POPI Col
   @POPI DstPtr
   @PUSHI Col
   @IF_GE_V LeftOffset
      @POPNULL
      @PUSHI DstCol
      @IF_LT_V Width
         @POPNULL
         @PUSH " \0"
         @POPII DstPtr
         @INCI DstPtr
         @INCI DstCol
      @ELSE
         @POPNULL
      @ENDIF
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI DstPtr
   @PUSHI DstCol
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# DisplayFormatTextBox(FieldPtr):(BufferPtr)
#
# Formats a multiline textbox into a field-owned render buffer.
# Newlines split logical lines. Tabs expand to four-column stops.
# Lines clip on the right, FIELD_AUX_VALUE is horizontal left offset,
# and the bottom-most FIELD_HEIGHT logical lines are displayed.
#####################################################################
@FUNCTION DisplayFormatTextBox
:DisplayFormatTextBox
@PUSHRETURN
@Locals
@Local FieldPtr
@Local SrcPtr
@Local BufPtr
@Local Width
@Local Height
@Local LeftOffset
@Local LineStride
@Local BufSize
@Local Row
@Local Col
@Local DstCol
@Local DstPtr
@Local Lines
@Local StartLine
@Local CurLine
@Local Ch
@Local TabTarget
@Local Index
   @POPI FieldPtr
   @GET_FROM FieldPtr FIELD_WIDTH @POPI Width
   @GET_FROM FieldPtr FIELD_HEIGHT @POPI Height
   @GET_FROM FieldPtr FIELD_AUX_VALUE @POPI LeftOffset
   @PUSHI Width @ADD 1 @POPI LineStride
   @PUSHI LineStride @PUSHI Height @CALL MULU @ADD 1 @POPI BufSize

   @Call(VV) DisplayEnsureFieldBuffer FieldPtr BufSize
   @POPI BufPtr

   # Clear buffer to space-filled, null-terminated display lines.
   @MV2V BufPtr DstPtr
   @ForIA2V Row 0 Height
      @ForIA2V Col 0 Width
         @PUSH " \0"
         @POPII DstPtr
         @INCI DstPtr
      @Next Col
      @PUSH 0
      @POPII DstPtr
      @INCI DstPtr
   @Next Row
   @PUSH 0
   @POPII DstPtr

   # Count logical source lines.
   @GET_FROM FieldPtr FIELD_VALUE_PTR @POPI SrcPtr
   @MA2V 1 Lines
   @PUSHII SrcPtr @AND 0xff @POPI Ch
   @PUSHI Ch
   @WHILE_NOTZERO
      @POPNULL
      @IF_EQ_AV 10 Ch
         @INCI Lines
      @ENDIF
      @INCI SrcPtr
      @PUSHII SrcPtr @AND 0xff @POPI Ch
      @PUSHI Ch
   @ENDWHILE
   @POPNULL

   @PUSHI Lines @SUBI Height @POPI StartLine
   @PUSHI StartLine
   @IF_LT_A 0
      @POPNULL
      @MA2V 0 StartLine
   @ELSE
      @POPNULL
   @ENDIF

   # Render from StartLine through the bottom into the cleared buffer.
   @GET_FROM FieldPtr FIELD_VALUE_PTR @POPI SrcPtr
   @MA2V 0 CurLine
   @MA2V 0 Row
   @MA2V 0 Col
   @MA2V 0 DstCol
   @MV2V BufPtr DstPtr
   @PUSHII SrcPtr @AND 0xff @POPI Ch
   @PUSHI Ch
   @WHILE_NOTZERO
      @POPNULL
      @PUSHI Row
      @IF_GE_V Height
         @POPNULL
         @JMP DFTB_DoneLoop
      @ENDIF
      @POPNULL

      @IF_EQ_AV 10 Ch
         @PUSHI CurLine
         @IF_GE_V StartLine
            @POPNULL
            @INCI Row
            @PUSHI BufPtr
            @PUSHI Row
            @PUSHI LineStride
            @CALL MULU
            @ADDS
            @POPI DstPtr
            @MA2V 0 DstCol
         @ELSE
            @POPNULL
         @ENDIF
         @INCI CurLine
         @MA2V 0 Col
         @JMP DFTB_NextChar
      @ENDIF

      @IF_EQ_AV 9 Ch
         @PUSHI Col @ADD 1 @POPI TabTarget
         @PUSHI TabTarget @AND 3
         @WHILE_NOTZERO
            @POPNULL
            @INCI TabTarget
            @PUSHI TabTarget @AND 3
         @ENDWHILE
         @POPNULL
         @PUSHI Col
         @WHILE_LT_V TabTarget
            @POPNULL
            @PUSHI CurLine
            @IF_GE_V StartLine
               @POPNULL
               @PUSHI DstPtr
               @PUSHI Col
               @PUSHI DstCol
               @PUSHI LeftOffset
               @PUSHI Width
               @CALL DisplayTextBoxPutSpace
               @POPI DstCol
               @POPI DstPtr
            @ELSE
               @POPNULL
            @ENDIF
            @INCI Col
            @PUSHI Col
         @ENDWHILE
         @POPNULL
         @JMP DFTB_NextChar
      @ENDIF

      @PUSHI CurLine
      @IF_GE_V StartLine
         @POPNULL
         @PUSHI Col
         @IF_GE_V LeftOffset
            @POPNULL
            @PUSHI DstCol
            @IF_LT_V Width
               @POPNULL
               @PUSHI Ch
               @POPII DstPtr
               @INCI DstPtr
               @INCI DstCol
            @ELSE
               @POPNULL
            @ENDIF
         @ELSE
            @POPNULL
         @ENDIF
      @ELSE
         @POPNULL
      @ENDIF
      @INCI Col

      :DFTB_NextChar
      @INCI SrcPtr
      @PUSHII SrcPtr @AND 0xff @POPI Ch
      @PUSHI Ch
   @ENDWHILE
   @POPNULL
   :DFTB_DoneLoop
   @PUSHI BufPtr
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION DisplayDrawField
:DisplayDrawField
@PUSHRETURN
@Locals
@Local FieldPtr
@Local FormPtr
@Local FieldType
@Local ValuePtr
@Local X
@Local Y
@Local X2
@Local Y2
@Local Height
@Local Flags
@Local DstLinePtr
   @POPI FieldPtr
   @GET_FROM FieldPtr FIELD_FLAGS
   @AND FIELD_FLAG_VISIBLE
   @IF_ZERO
      @POPNULL
      @JMP DDF_Exit
   @ENDIF
   @POPNULL
   @GET_FROM FieldPtr FIELD_FORM @POPI FormPtr
   @GET_FROM FormPtr FORM_ABS_X @GET_FROM FieldPtr FIELD_REL_X @ADDS @POPI X
   @GET_FROM FormPtr FORM_ABS_Y @GET_FROM FieldPtr FIELD_REL_Y @ADDS @POPI Y
   @GET_FROM FieldPtr FIELD_WIDTH @ADDI X @SUB 1 @POPI X2
   @GET_FROM FieldPtr FIELD_HEIGHT @POPI Height
   @PUSHI Height @ADDI Y @SUB 1 @POPI Y2
   @PUSHI X
   @GET_FROM FormPtr FORM_CLIP_X1
   @IF_LT_S
      @POPNULL @POPNULL
      @JMP DDF_Exit
   @ENDIF
   @POPNULL @POPNULL
   @PUSHI Y
   @GET_FROM FormPtr FORM_CLIP_Y1
   @IF_LT_S
      @POPNULL @POPNULL
      @JMP DDF_Exit
   @ENDIF
   @POPNULL @POPNULL
   @PUSHI X
   @GET_FROM FormPtr FORM_CLIP_X2
   @IF_GT_S
      @POPNULL @POPNULL
      @JMP DDF_Exit
   @ENDIF
   @POPNULL @POPNULL
   @PUSHI Y
   @GET_FROM FormPtr FORM_CLIP_Y2
   @IF_GT_S
      @POPNULL @POPNULL
      @JMP DDF_Exit
   @ENDIF
   @POPNULL @POPNULL
   @Call(V) DisplayFieldShouldDraw FieldPtr
   @IF_ZERO
      @POPNULL
      @JMP DDF_Exit
   @ENDIF
   @POPNULL
   @GET_FROM FieldPtr FIELD_TYPE @POPI FieldType
   @GET_FROM FieldPtr FIELD_VALUE_PTR @POPI ValuePtr
   @PUSHI X @PUSHI Y @CALL WinCursor
   @PUSHI FieldType
   @SWITCH
   @CASE FIELD_TYPE_INTEGER
      @POPNULL
      @Call(V) DisplayFormatInteger FieldPtr
      @POPI ValuePtr
      @PRTSI ValuePtr
      @JMP DDF_AfterDraw
   @CBREAK
   @CASE FIELD_TYPE_LONG
      @POPNULL
      @Call(V) DisplayFormatLong FieldPtr
      @POPI ValuePtr
      @PRTSI ValuePtr
      @JMP DDF_AfterDraw
   @CBREAK
   @CASE FIELD_TYPE_STRING
      @POPNULL
      @PRTSI ValuePtr
      @JMP DDF_AfterDraw
   @CBREAK
   @CASE FIELD_TYPE_TEXT
      @POPNULL
      @PRTSI ValuePtr
      @JMP DDF_AfterDraw
   @CBREAK
   @CASE FIELD_TYPE_CHARACTER
      @POPNULL
      @PUSHII ValuePtr @AND 0xff @POPI DisplayCharBuf
      @PRTS DisplayCharBuf
      @JMP DDF_AfterDraw
   @CBREAK
   @CASE FIELD_TYPE_TEXTBOX
      @POPNULL
      @Call(V) DisplayFormatTextBox FieldPtr
      @POPI ValuePtr
      @MA2V 0 Flags
      @PUSHI ValuePtr @POPI DstLinePtr
      @ForIA2V Flags 0 Height
         @PUSHI X
         @PUSHI Y @ADDI Flags
         @CALL WinCursor
         @PRTSI DstLinePtr
         @PUSHI DstLinePtr @GET_FROM FieldPtr FIELD_WIDTH @ADD 1 @ADDS @POPI DstLinePtr
      @Next Flags
      @JMP DDF_AfterDraw
   @CBREAK
   @CASE FIELD_TYPE_BOX
      @POPNULL
      @PUSHI X @PUSHI Y @PUSHI X2 @PUSHI Y2 @CALL WinBox
      @JMP DDF_AfterDraw
   @CBREAK
   @CDEFAULT
      @POPNULL
   @CBREAK
   @ENDCASE

   :DDF_AfterDraw
   @Call(V) DisplayFieldCommitSignature FieldPtr
   :DDF_Exit
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION
