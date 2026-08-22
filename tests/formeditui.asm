#######################
# Form UI Editor
# Paint-style canvas editor scaffold for retained display.ld form overlays.
# TODO: use CanvasCREvent returned SEL_* actions to create DisplayFieldNew overlays.
# TODO: keep editor metadata in one-file form records, then render via DisplayUpdate.
I common.mc
L softstack.ld
L heapmgr.ld
L screen.ld
L lmath.ld
L string.ld
L event.ld
L mul.ld
L div.ld
#USE SetDiskHeap
#USE FSReadHeader
#USE file_open_basic
#USE DiskFileWrite
#USE DiskClose
#USE DiskNewBuffer
#USE DirReadEntry
#USE FSFindFile
D diskos.ld
L display.ld

=StackSizeDefault 0x400

:MainHeap 0
:SoftStackStart 0
:ObjectSize
:SoftStackEnd 0

:CtrlMenuEventTable 0
:CanvasEventTable 0
:FieldEditEventTable 0
:MenuEnabled 0
:MainLoopExit 0

:CanvasData 0         # String Object of Screen Data
:CanvasSize 0
:CanvasCursor 0
:SelectionMode 0
:SelectionX1 -1
:SelectionY1 -1
:SelectionX2 -1
:SelectionY2 -1
:SelectionDimensions 0
:CanvasIgnoreClick 0
:SelectionAction 0
:CanvasCRHandler 0
:SelectionCompleteX1 -1
:SelectionCompleteY1 -1
:SelectionCompleteX2 -1
:SelectionCompleteY2 -1
:FormTable 0
:NextFormID 1
:SelectedFormEntry 0
:ReportActive 0
:FieldEditActive 0
:SaveLineBuffer 0
:SaveNumberBuffer 0
:SaveFilePtr 0
:SaveDiskReady 0
:SaveDiskStatus 0

######################################
# Constants
######################################
=EV_MenuClick 100
=EV_MenuESC 110
=EV_MenuOpenCloseCtrl 115
=EV_CanvasClick 200
=EV_CanvasKey 210
=EV_CanvasESC 220
=EV_CanvasOpenMenuCtrl 225
=EV_CanvasCR 230
=EV_CanvasNL 235
=EV_CanvasDel 240
=EV_CanvasCtrlBox 250
=EV_CanvasCtrlInteger 260
=EV_CanvasCtrlLong 270
=EV_CanvasCtrlString 280
=EV_CanvasCtrlTextBox 290
=EV_CanvasCtrlWords 300
=EV_MenuCtrlBox 350
=EV_MenuCtrlInteger 360
=EV_MenuCtrlLong 370
=EV_MenuCtrlString 380
=EV_MenuCtrlTextBox 390
=EV_MenuCtrlWords 400
=EV_MenuPrint 410
=EV_MenuSaveWork 420
=EV_MenuLoadWork 430
=EV_FieldEditESC 500
=EV_FieldEditOpenMenu 505
=EV_FieldEditDecX 510
=EV_FieldEditIncX 520
=EV_FieldEditDecY 530
=EV_FieldEditIncY 540
=EV_FieldEditDecW 550
=EV_FieldEditIncW 560
=EV_FieldEditDecH 570
=EV_FieldEditIncH 580
=EV_FieldEditCloseClick 590
=EV_FieldEditCloseText 595

=MODE_Default 0
=MODE_SelectFirst 100
=MODE_SelectSecond 200

=SELDIM_None 0
=SELDIM_1D 1
=SELDIM_2D 2

# formeditui.asm design notes:
# - CanvasData remains the editable background buffer.
# - SelectionMode tracks the shared two-corner selection resource.
# - SelectionDimensions distinguishes 1D span selections from 2D rectangle selections.
# - SelectionAction says what ENTER should do after a rectangle is completed.
# - CanvasCRHandler points to the CR_* function for the active edit/function mode.
# - SelectionCompleteX/Y keeps the accepted rectangle after live selection resets.
# - The shared flow is: click first corner, click second corner, ENTER accepts.
# - SEL_DrawBox commits cosmetic boxes into CanvasData.
# - SEL_NewInteger and SEL_NewLong use X1,Y1 plus width only; height is ignored.
# - SEL_NewString uses one-line width; SEL_NewTextBox uses width and height.
# - Form object metadata should remain editor-owned so later property editing can rename IDs,
#   change defaults, delete and replace objects, and prevent overlap.
# - Actual overlay painting should use display.ld forms and fields, with fields marked dirty
#   before repaint because DisplayCanvas clears the terminal each pass.

=SEL_None 0
=SEL_DrawBox 1
=SEL_NewInteger 2
=SEL_NewLong 3
=SEL_NewString 4
=SEL_NewTextBox 5

=FORMTABLE_USED 0
=FORMTABLE_MAX 2
=FORMTABLE_HEAP 4
=FORMTABLE_HEADER_SIZE 6
=FORMTABLE_INITIAL_MAX 8
=FORMTABLE_GROW_BY 8

=FORMOBJ_TYPE 0
=FORMOBJ_FLAGS 2
=FORMOBJ_X 4
=FORMOBJ_Y 6
=FORMOBJ_WIDTH 8
=FORMOBJ_HEIGHT 10
=FORMOBJ_VALUE_PTR 12
=FORMOBJ_FIELD_PTR 14
=FORMOBJ_ID 16
=FORMOBJ_USER1 18
=FORMOBJ_USER2 20
=FORMOBJ_OBJECT_SIZE 22

=FORMOBJ_TYPE_NONE 0
=FORMOBJ_FLAG_ENABLED 0x0001
=FORMOBJ_FLAG_SELECTED 0x0002
=SAVE_LINE_BUFFER_SIZE 160
=SAVE_NUMBER_BUFFER_SIZE 8
:SaveWorkFileName "FORMEDIT.SAV" $$0
######################################
# Stack Setup
######################################
:SetupStack
# Can't use stack while setting it up. So no locals or PUSHRETURN
   @PUSH 0xff00
   @SUB END__
   @POPI ObjectSize
   @Call(AV) HeapDefineMemory END__ ObjectSize
   @POPI MainHeap
   @Call(VA) HeapNewObject MainHeap StackSizeDefault
   @IF_ULT_A 100
      @PRTLN "Error out of memory"
      @END
   @ENDIF
   
   @POPI SoftStackStart  

   @PUSHI SoftStackStart
   @ADD StackSizeDefault
   @POPI SoftStackEnd

   @Call(VV) SetSSStack SoftStackEnd SoftStackStart
@RET

#######################################
# SetupGlobals
#######################################
:SetupGlobals
@PUSHRETURN
@Locals
    @Local Index1
    @Local Index2

    @CALL WinResize   # Setup WinWidth and WinHeight
    @MA2V CR_EDIT CanvasCRHandler
    @Call(V) FormTableNew MainHeap
    @POPI FormTable
    @MA2V 1 NextFormID
    @MA2V 0 SelectedFormEntry
    @MA2V 0 ReportActive
    @Call(VA) HeapNewObject MainHeap SAVE_LINE_BUFFER_SIZE
    @IF_ULT_A 100
       @PRT "ERR:MEM"
       @END
    @ENDIF
    @POPI SaveLineBuffer
    @Call(VA) HeapNewObject MainHeap SAVE_NUMBER_BUFFER_SIZE
    @IF_ULT_A 100
       @PRT "ERR:MEM"
       @END
    @ENDIF
    @POPI SaveNumberBuffer
    @MA2V 0 SaveFilePtr
    @MA2V 0 SaveDiskStatus
    @MA2V 0 SaveDiskReady
    @IF_NEQ_AV 0 CanvasData
       @Call(VV) HeapDeleteObject MainHeap CanvasData
       @POPNULL
    @ENDIF
    @PUSHI WinHeight
    @SUB 1
    @Call(V) MULU WinWidth   # Canvas excludes the status line.
    @POPI CanvasSize
    @PUSHI MainHeap
    @PUSHI CanvasSize
    @ADD 2
    @CALL HeapNewObject
    @IF_ULT_A 100
       @PRT "ERR:CANVAS MEM size="
       @PRTI CanvasSize
       @PRT " avail="
       @Call(V) HeapAvailable MainHeap
       @PRTTOP
       @POPNULL
       @END
    @ENDIF
    @POPI CanvasData
    @MV2V CanvasData Index2
    @ForIA2V Index1 0 CanvasSize
       @PUSH " \0"
       @POPII Index2
       @INCI Index2
    @Next Index1
    @PUSH 0
    @PUSHI CanvasData
    @ADDI CanvasSize
    @POPS
@EndLocals
@POPRETURN
@RET

########################################
# FormTableNew(HeapID):FormTablePtr
########################################
:FormTableNew
@PUSHRETURN
@Locals
   @Local HeapID
   @Local TablePtr
   @Local TableBytes

   @POPI HeapID
   @PUSH FORMTABLE_INITIAL_MAX
   @PUSH FORMOBJ_OBJECT_SIZE
   @CALL MUL
   @ADD FORMTABLE_HEADER_SIZE
   @POPI TableBytes
   @Call(VV) HeapNewObject HeapID TableBytes
   @IF_ULT_A 100
      @PRT "ERR:MEM"
      @END
   @ENDIF
   @POPI TablePtr
   @FILL_AT_A TablePtr FORMTABLE_USED 0
   @FILL_AT_A TablePtr FORMTABLE_MAX FORMTABLE_INITIAL_MAX
   @FILL_AT_V TablePtr FORMTABLE_HEAP HeapID
   @PUSHI TablePtr
@EndLocals
@POPRETURN
@RET

########################################
# FormTableEntryPtr(TablePtr, Index):EntryPtr
########################################
:FormTableEntryPtr
@PUSHRETURN
@Locals
   @Local TablePtr
   @Local Index

   @POPI Index
   @POPI TablePtr
   @PUSHI Index
   @PUSH FORMOBJ_OBJECT_SIZE
   @CALL MUL
   @ADDI TablePtr
   @ADD FORMTABLE_HEADER_SIZE
@EndLocals
@POPRETURN
@RET

########################################
# FormEntryClear(EntryPtr)
########################################
:FormEntryClear
@PUSHRETURN
@Locals
   @Local EntryPtr

   @POPI EntryPtr
   @FILL_AT_A EntryPtr FORMOBJ_TYPE FORMOBJ_TYPE_NONE
   @FILL_AT_A EntryPtr FORMOBJ_FLAGS 0
   @FILL_AT_A EntryPtr FORMOBJ_X 0
   @FILL_AT_A EntryPtr FORMOBJ_Y 0
   @FILL_AT_A EntryPtr FORMOBJ_WIDTH 0
   @FILL_AT_A EntryPtr FORMOBJ_HEIGHT 0
   @FILL_AT_A EntryPtr FORMOBJ_VALUE_PTR 0
   @FILL_AT_A EntryPtr FORMOBJ_FIELD_PTR 0
   @FILL_AT_A EntryPtr FORMOBJ_ID 0
   @FILL_AT_A EntryPtr FORMOBJ_USER1 0
   @FILL_AT_A EntryPtr FORMOBJ_USER2 0      
@EndLocals
@POPRETURN
@RET

########################################
# FormTableAllocEntry(TablePtr):EntryPtr
# Reuses disabled slots before growing the dynamic table.
########################################
:FormTableAllocEntry
@PUSHRETURN
@Locals
   @Local TablePtr
   @Local UsedCount
   @Local MaxCount
   @Local HeapID
   @Local Index
   @Local EntryPtr
   @Local NewMax
   @Local NewBytes

   @POPI TablePtr
   @GET_FROM TablePtr FORMTABLE_USED @POPI UsedCount
   @GET_FROM TablePtr FORMTABLE_MAX @POPI MaxCount
   @MA2V 0 EntryPtr

   @ForIA2V Index 0 UsedCount
      @Call(VV) FormTableEntryPtr TablePtr Index
      @POPI EntryPtr
      @GET_FROM EntryPtr FORMOBJ_TYPE
      @IF_EQ_A FORMOBJ_TYPE_NONE
         @POPNULL
         @FORBREAK
      @ELSE
         @POPNULL
         @MA2V 0 EntryPtr
      @ENDIF
   @Next Index

   @IF_EQ_AV 0 EntryPtr
      @IF_EQ_VV UsedCount MaxCount
         @GET_FROM TablePtr FORMTABLE_HEAP @POPI HeapID
         @PUSHI MaxCount
         @ADD FORMTABLE_GROW_BY
         @POPI NewMax
         @PUSHI NewMax
         @PUSH FORMOBJ_OBJECT_SIZE
         @CALL MUL
         @ADD FORMTABLE_HEADER_SIZE
         @POPI NewBytes

         # HeapResizeObject may move the table. so invalidate current pointer.
         @Call(A) FormSelectEntry 0
         
         @PUSHI HeapID
         @PUSHI TablePtr
         @PUSHI NewBytes
         @CALL HeapResizeObject
         @IF_ULT_A 100
            @PRT "ERR:MEM"
            @END
         @ENDIF
         @POPI TablePtr
         @FILL_AT_V TablePtr FORMTABLE_MAX NewMax
         @MV2V TablePtr FormTable
      @ENDIF
      @Call(VV) FormTableEntryPtr TablePtr UsedCount
      @POPI EntryPtr
      @INCI UsedCount
      @FILL_AT_V TablePtr FORMTABLE_USED UsedCount
   @ENDIF

   # Clear form
   @Call(V) FormEntryClear EntryPtr
   @PUSHI EntryPtr

@EndLocals
@POPRETURN
@RET

########################################
# AddFormEntry(Type,X,Y,Width,Height,ValuePtr,FieldPtr):EntryPtr
# Convenience macro for the common editor form metadata call.
########################################
M AddFormEntry \
   @PUSHI %1 \
   @PUSHI %2 \
   @PUSHI %3 \
   @PUSHI %4 \
   @PUSHI %5 \
   @PUSH %6 \
   @PUSH %7 \
   @CALL FormEntryCreate

########################################
# FormEntryCreate(Type,X,Y,Width,Height,ValuePtr,FieldPtr):EntryPtr
########################################
:FormEntryCreate
@PUSHRETURN
@Locals
   @Local ObjType
   @Local X
   @Local Y
   @Local Width
   @Local Height
   @Local ValuePtr
   @Local FieldPtr
   @Local EntryPtr


   @POPI FieldPtr
   @POPI ValuePtr
   @POPI Height
   @POPI Width
   @POPI Y
   @POPI X
   @POPI ObjType
   @Call(V) FormTableAllocEntry FormTable
   @POPI EntryPtr
   @FILL_AT_V EntryPtr FORMOBJ_TYPE ObjType
   @FILL_AT_A EntryPtr FORMOBJ_FLAGS FORMOBJ_FLAG_ENABLED
   @FILL_AT_V EntryPtr FORMOBJ_X X
   @FILL_AT_V EntryPtr FORMOBJ_Y Y
   @FILL_AT_V EntryPtr FORMOBJ_WIDTH Width
   @FILL_AT_V EntryPtr FORMOBJ_HEIGHT Height
   @FILL_AT_V EntryPtr FORMOBJ_VALUE_PTR ValuePtr
   @FILL_AT_V EntryPtr FORMOBJ_FIELD_PTR FieldPtr
   @FILL_AT_V EntryPtr FORMOBJ_ID NextFormID
   @INCI NextFormID
   @Call(V) FormEntryNormalizeGeometry EntryPtr
   @PUSHI EntryPtr
@EndLocals
@POPRETURN
@RET

########################################
# FormTypeFromSelection(Action):FieldType
########################################
:FormTypeFromSelection
@PUSHRETURN
@Locals
   @Local Action
   @Local FieldType

   @POPI Action
   @MA2V FORMOBJ_TYPE_NONE FieldType
   @PUSHI Action
   @SWITCH
   @CASE SEL_DrawBox
      # Decrative boxes commit directly to CancasData and do not represent a dynamic form.
      @CBREAK
   @CASE SEL_NewInteger
      @MA2V FIELD_TYPE_INTEGER FieldType
      @CBREAK
   @CASE SEL_NewLong
      @MA2V FIELD_TYPE_LONG FieldType
      @CBREAK
   @CASE SEL_NewString
      @MA2V FIELD_TYPE_STRING FieldType
      @CBREAK
   @CASE SEL_NewTextBox
      @MA2V FIELD_TYPE_TEXTBOX FieldType
      @CBREAK
   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL
   @PUSHI FieldType
@EndLocals
@POPRETURN
@RET

########################################
# FormEntryCreateFromSelection(Action):EntryPtr
########################################
:FormEntryCreateFromSelection
@PUSHRETURN
@Locals
   @Local Action
   @Local FieldType
   @Local Width
   @Local Height
   @Local EntryPtr

   @POPI Action
   @MA2V 0 EntryPtr
   @Call(V) FormTypeFromSelection Action
   @POPI FieldType
   @IF_NEQ_AV FORMOBJ_TYPE_NONE FieldType
      @PUSHI SelectionCompleteX2
      @SUBI SelectionCompleteX1
      @ADD 1
      @POPI Width
      @MA2V 1 Height
      
      @PUSHI FieldType
      @SWITCH
      @CASE FIELD_TYPE_TEXTBOX
         @PUSHI SelectionCompleteY2
         @SUBI SelectionCompleteY1
         @ADD 1
         @POPI Height
         @CBREAK
      @CDEFAULT
         @CBREAK
      @ENDCASE
      @POPNULL
      
      @AddFormEntry FieldType SelectionCompleteX1 SelectionCompleteY1 Width Height 0 0
      @POPI EntryPtr

   @ENDIF
   @PUSHI EntryPtr
@EndLocals
@POPRETURN
@RET

########################################
# FormPrintType(Type)
########################################
:FormPrintType
@PUSHRETURN
@Locals
   @Local ObjType

   @POPI ObjType
   @PUSHI ObjType
   @SWITCH
   @CASE FIELD_TYPE_BOX
      @PRT "BOX    "
      @CBREAK
   @CASE FIELD_TYPE_INTEGER
      @PRT "INT    "
      @CBREAK
   @CASE FIELD_TYPE_LONG
      @PRT "LONG   "
      @CBREAK
   @CASE FIELD_TYPE_STRING
      @PRT "STRING "
      @CBREAK
   @CASE FIELD_TYPE_TEXTBOX
      @PRT "TEXTBOX"
      @CBREAK
   @CDEFAULT
      @PRT "?      "
      @CBREAK
   @ENDCASE
   @POPNULL
@EndLocals
@POPRETURN
@RET

########################################
# FormPrintGlyph(Type)
########################################
:FormPrintGlyph
@PUSHRETURN
@Locals
   @Local ObjType

   @POPI ObjType
   @PUSHI ObjType
   @SWITCH
   @CASE FIELD_TYPE_INTEGER
      @PRT "%\0"
      @CBREAK
   @CASE FIELD_TYPE_LONG
      @PRT "&\0"
      @CBREAK
   @CASE FIELD_TYPE_STRING
      @PRT "$\0"
      @CBREAK
   @CASE FIELD_TYPE_TEXTBOX
      @PRT "_\0"
      @CBREAK
   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL
@EndLocals
@POPRETURN
@RET

########################################
# FormEntryContainsPoint(EntryPtr,X,Y):Status
########################################
:FormEntryContainsPoint
@PUSHRETURN
@Locals
   @Local EntryPtr
   @Local X
   @Local Y
   @Local X2
   @Local Y2
   @Local Status

   @POPI Y
   @POPI X
   @POPI EntryPtr
   @MA2V 0 Status
   @IF_NEQ_AV 0 EntryPtr
      @GET_FROM EntryPtr FORMOBJ_X
      @IF_LE_V X
         @POPNULL
         @GET_FROM EntryPtr FORMOBJ_Y
         @IF_LE_V Y
            @POPNULL
            @GET_FROM EntryPtr FORMOBJ_X @POPI X2
            @GET_FROM EntryPtr FORMOBJ_WIDTH @ADDI X2 @SUB 1 @POPI X2
            @GET_FROM EntryPtr FORMOBJ_Y @POPI Y2
            @GET_FROM EntryPtr FORMOBJ_HEIGHT @ADDI Y2 @SUB 1 @POPI Y2
            @PUSHI X
            @IF_LE_V X2
               @POPNULL
               @PUSHI Y
               @IF_LE_V Y2
                  @POPNULL
                  @MA2V 1 Status
               @ELSE
                  @POPNULL
               @ENDIF
            @ELSE
               @POPNULL
            @ENDIF
         @ELSE
            @POPNULL
         @ENDIF
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
   @PUSHI Status
@EndLocals
@POPRETURN
@RET


########################################
# FormEntryFindAtPoint(X,Y):EntryPtr
# Entries are stored and painted in creation order.
# Continue scanning after a hit so the last matching entry wins,
# matching the visible topmost overlay.
########################################
:FormEntryFindAtPoint
@PUSHRETURN
@Locals
   @Local X
   @Local Y
   @Local UsedCount
   @Local Index
   @Local EntryPtr
   @Local HitPtr

   @POPI Y
   @POPI X
   @MA2V 0 HitPtr
   @GET_FROM FormTable FORMTABLE_USED @POPI UsedCount
   @ForIA2V Index 0 UsedCount
      @Call(VV) FormTableEntryPtr FormTable Index
      @POPI EntryPtr
      @GET_FROM EntryPtr FORMOBJ_TYPE
      @IF_NEQ_A FORMOBJ_TYPE_NONE
         @POPNULL
         @GET_FROM EntryPtr FORMOBJ_TYPE
         @IF_EQ_A FIELD_TYPE_BOX
            @POPNULL
         @ELSE
            @POPNULL
            @GET_FROM EntryPtr FORMOBJ_FLAGS
            @AND FORMOBJ_FLAG_ENABLED
            @IF_NOTZERO
               @POPNULL
               @Call(VVV) FormEntryContainsPoint EntryPtr X Y
               @IF_NOTZERO
                  @POPNULL
                  @MV2V EntryPtr HitPtr
               @ELSE
                  @POPNULL
               @ENDIF
            @ELSE
               @POPNULL
            @ENDIF
         @ENDIF
      @ELSE
         @POPNULL
      @ENDIF
   @Next Index
   @PUSHI HitPtr
@EndLocals
@POPRETURN
@RET

########################################
# FormSelectEntry(EntryPtr)
########################################
:FormSelectEntry
@PUSHRETURN
@Locals
   @Local EntryPtr
   @Local Flags

   @POPI EntryPtr
   @IF_NEQ_AV 0 SelectedFormEntry
      @GET_FROM SelectedFormEntry FORMOBJ_FLAGS
      @AND 0xfffd
      @POPI Flags
      @FILL_AT_V SelectedFormEntry FORMOBJ_FLAGS Flags
   @ENDIF
   @MV2V EntryPtr SelectedFormEntry
   @IF_NEQ_AV 0 SelectedFormEntry
      @GET_FROM SelectedFormEntry FORMOBJ_FLAGS
      @OR FORMOBJ_FLAG_SELECTED
      @POPI Flags
      @FILL_AT_V SelectedFormEntry FORMOBJ_FLAGS Flags
   @ENDIF
@EndLocals
@POPRETURN
@RET

########################################
# DisplayFormEntryOverlay(EntryPtr)
########################################
:DisplayFormEntryOverlay
@PUSHRETURN
@Locals
   @Local EntryPtr
   @Local ObjType
   @Local Flags
   @Local X
   @Local Y
   @Local Width
   @Local Height
   @Local X2
   @Local Y2
   @Local MaxXEnd
   @Local Row
   @Local Col

   @POPI EntryPtr
   @GET_FROM EntryPtr FORMOBJ_TYPE @POPI ObjType
   @IF_NEQ_AV FORMOBJ_TYPE_NONE ObjType
      @IF_NEQ_AV FIELD_TYPE_BOX ObjType
      @GET_FROM EntryPtr FORMOBJ_FLAGS @POPI Flags
      @PUSHI Flags
      @AND FORMOBJ_FLAG_ENABLED
      @IF_NOTZERO
         @POPNULL
         @GET_FROM EntryPtr FORMOBJ_X @POPI X
         @GET_FROM EntryPtr FORMOBJ_Y @POPI Y
         @GET_FROM EntryPtr FORMOBJ_WIDTH @POPI Width
         @GET_FROM EntryPtr FORMOBJ_HEIGHT @POPI Height
         @PUSHI WinWidth @ADD 1 @POPI MaxXEnd
         @PUSHI X @ADDI Width @POPI X2
         @PUSHI X2
         @IF_GT_V MaxXEnd
            @POPNULL
            @MV2V MaxXEnd X2
         @ELSE
            @POPNULL
         @ENDIF
         @PUSHI Y @ADDI Height @POPI Y2
         @PUSHI Y2
         @IF_GT_V WinHeight
            @POPNULL
            @MV2V WinHeight Y2
         @ELSE
            @POPNULL
         @ENDIF
         @PUSHI Flags
         @AND FORMOBJ_FLAG_SELECTED
         @IF_NOTZERO
            @POPNULL
            @Call(A) ColorFGSet 11
         @ELSE
            @POPNULL
            @Call(A) ColorFGSet 4
         @ENDIF
         @ForIV2V Row Y Y2
            @PUSHI Row
            @IF_LT_V WinHeight
               @POPNULL
               @ForIV2V Col X X2
                  @Call(VV) WinCursor Col Row
                  @Call(V) FormPrintGlyph ObjType
               @Next Col
            @ELSE
               @POPNULL
            @ENDIF
         @Next Row
         @CALL ColorReset
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
   @ENDIF
@EndLocals
@POPRETURN
@RET

########################################
# DisplayFormOverlays
########################################
:DisplayFormOverlays
@PUSHRETURN
@Locals
   @Local UsedCount
   @Local Index
   @Local EntryPtr

   @GET_FROM FormTable FORMTABLE_USED @POPI UsedCount
   @ForIA2V Index 0 UsedCount
      @Call(VV) FormTableEntryPtr FormTable Index
      @POPI EntryPtr
      @Call(V) DisplayFormEntryOverlay EntryPtr
   @Next Index
@EndLocals
@POPRETURN
@RET

########################################
# PrintFormTable
########################################
:PrintFormTable
@PUSHRETURN
@Locals
   @Local UsedCount
   @Local Index
   @Local EntryPtr
   @Local Row
   @Local PrintID
   @Local PrintType
   @Local PrintX
   @Local PrintY
   @Local PrintWidth
   @Local PrintHeight
   @Local PrintValuePtr
   @Local PrintFieldPtr

   @CALL WinClear
   @Call(AA) WinCursor 1 1
   @PRT "ID   TYPE    X   Y   W   H   VALUE  FIELD"
   @Call(AA) WinCursor 1 2
   @PRT "----------------------------------------"
   @GET_FROM FormTable FORMTABLE_USED @POPI UsedCount
   @MA2V 3 Row
   @ForIA2V Index 0 UsedCount
      @Call(VV) FormTableEntryPtr FormTable Index
      @POPI EntryPtr
      @GET_FROM EntryPtr FORMOBJ_TYPE
      @IF_NEQ_A FORMOBJ_TYPE_NONE
         @POPNULL
         @PUSHI Row
         @IF_LT_V WinHeight
            @POPNULL
            @GET_FROM EntryPtr FORMOBJ_ID @POPI PrintID
            @GET_FROM EntryPtr FORMOBJ_TYPE @POPI PrintType
            @GET_FROM EntryPtr FORMOBJ_X @POPI PrintX
            @GET_FROM EntryPtr FORMOBJ_Y @POPI PrintY
            @GET_FROM EntryPtr FORMOBJ_WIDTH @POPI PrintWidth
            @GET_FROM EntryPtr FORMOBJ_HEIGHT @POPI PrintHeight
            @GET_FROM EntryPtr FORMOBJ_VALUE_PTR @POPI PrintValuePtr
            @GET_FROM EntryPtr FORMOBJ_FIELD_PTR @POPI PrintFieldPtr
            @Call(AV) WinCursor 1 Row
            @PRTI PrintID
            @PRT "    "
            @Call(V) FormPrintType PrintType
            @PRT " "
            @PRTI PrintX
            @PRT "   "
            @PRTI PrintY
            @PRT "   "
            @PRTI PrintWidth
            @PRT "   "
            @PRTI PrintHeight
            @PRT "   "
            @PRTI PrintValuePtr
            @PRT "   "
            @PRTI PrintFieldPtr
            @INCI Row
         @ELSE
            @POPNULL
         @ENDIF
      @ELSE
         @POPNULL
      @ENDIF
   @Next Index
   @Call(AV) WinCursor 1 WinHeight
   @PRT "Click or ESC returns to editor"
   @MA2V 1 ReportActive
   @Call(V) EventSetActive CanvasEventTable
@EndLocals
@POPRETURN
@RET



########################################
# SaveEnsureDiskReady():Status
# DiskOS is initialized lazily so normal editing does not touch the disk.
########################################
:SaveEnsureDiskReady
@PUSHRETURN
   @IF_EQ_AV 0 SaveDiskReady
      @Call(V) SetDiskHeap MainHeap
      @Call(A) FSReadHeader 0
      @IF_ZERO
         @POPNULL
         @MA2V 0 SaveDiskReady
      @ELSE
         @POPNULL
         @MA2V 1 SaveDiskReady
      @ENDIF
   @ENDIF
   @PUSHI SaveDiskReady
@POPRETURN
@RET

########################################
# SaveLineClear()
########################################
:SaveLineClear
@PUSHRETURN
   @PUSH 0
   @POPII SaveLineBuffer
@POPRETURN
@RET

########################################
# SaveLineAppend(StrPtr)
# Local append that always writes the trailing null.
########################################
:SaveLineAppend
@PUSHRETURN
@Locals
   @Local StrPtr
   @Local OutPtr
   @Local Ch

   @POPI StrPtr
   @MV2V SaveLineBuffer OutPtr
   @PUSHII OutPtr
   @AND 0xff
   @WHILE_NOTZERO
      @POPNULL
      @INCI OutPtr
      @PUSHII OutPtr
      @AND 0xff
   @ENDWHILE
   @POPNULL

   @PUSHII StrPtr
   @AND 0xff
   @POPI Ch
   @PUSHI Ch
   @WHILE_NOTZERO
      @POPNULL
      @PUSHI Ch
      @POPII OutPtr
      @INCI OutPtr
      @INCI StrPtr
      @PUSHII StrPtr
      @AND 0xff
      @POPI Ch
      @PUSHI Ch
   @ENDWHILE
   @POPNULL
   @PUSH 0
   @POPII OutPtr
@EndLocals
@POPRETURN
@RET

########################################
# SaveLineAppendInt(Value)
########################################
:SaveLineAppendInt
@PUSHRETURN
@Locals
   @Local Value
   @POPI Value
   @Call(VVA) itos SaveNumberBuffer Value 10
   @Call(V) SaveLineAppend SaveNumberBuffer
@EndLocals
@POPRETURN
@RET

########################################
# SaveLineEmit()
# Writes to SaveFilePtr when open, otherwise previews via @PRTSI.
########################################
:SaveLineEmit
@PUSHRETURN
@Locals
   @Local OutLen
   @Local WriteLen

   @IF_NEQ_AV 0 SaveFilePtr
      @STRSTACK "\n"
      @CALL SaveLineAppend
      @Call(V) strlen SaveLineBuffer
      @POPI OutLen
      @Call(VVV) DiskFileWrite SaveFilePtr SaveLineBuffer OutLen
      @POPI WriteLen
      @PUSHI WriteLen
      @IF_ULT_V OutLen
         @POPNULL
         @MA2V 0 SaveDiskStatus
      @ELSE
         @POPNULL
      @ENDIF
   @ELSE
      @STRSTACK "\r\n"
      @CALL SaveLineAppend
      @PRTSI SaveLineBuffer
   @ENDIF
@EndLocals
@POPRETURN
@RET


########################################
# SaveEmitHeader()
########################################
:SaveEmitHeader
@PUSHRETURN
@Locals
   @Local CanvasRows

   @PUSHI WinHeight
   @SUB 1
   @POPI CanvasRows

   @CALL SaveLineClear
   @STRSTACK "VERSION: 1.0"
   @CALL SaveLineAppend
   @CALL SaveLineEmit

   @CALL SaveLineClear
   @STRSTACK "WIDTH: "
   @CALL SaveLineAppend
   @Call(V) SaveLineAppendInt WinWidth
   @CALL SaveLineEmit

   @CALL SaveLineClear
   @STRSTACK "HEIGHT: "
   @CALL SaveLineAppend
   @Call(V) SaveLineAppendInt CanvasRows
   @CALL SaveLineEmit

   @CALL SaveLineClear
   @STRSTACK "canvas_size: "
   @CALL SaveLineAppend
   @Call(V) SaveLineAppendInt CanvasSize
   @CALL SaveLineEmit

   @CALL SaveLineClear
   @STRSTACK "next_form_id: "
   @CALL SaveLineAppend
   @Call(V) SaveLineAppendInt NextFormID
   @CALL SaveLineEmit
@EndLocals
@POPRETURN
@RET

########################################
# SaveEmitFormEntry(EntryPtr)
########################################
:SaveEmitFormEntry
@PUSHRETURN
@Locals
   @Local EntryPtr
   @Local Value

   @POPI EntryPtr

   @CALL SaveLineClear
   @STRSTACK "  { id: "
   @CALL SaveLineAppend
   @GET_FROM EntryPtr FORMOBJ_ID @POPI Value
   @Call(V) SaveLineAppendInt Value
   @STRSTACK ", type: "
   @CALL SaveLineAppend
   @GET_FROM EntryPtr FORMOBJ_TYPE @POPI Value
   @Call(V) SaveLineAppendInt Value
   @STRSTACK ", flags: "
   @CALL SaveLineAppend
   @GET_FROM EntryPtr FORMOBJ_FLAGS @POPI Value
   @Call(V) SaveLineAppendInt Value
   @STRSTACK ", x: "
   @CALL SaveLineAppend
   @GET_FROM EntryPtr FORMOBJ_X @POPI Value
   @Call(V) SaveLineAppendInt Value
   @STRSTACK ", y: "
   @CALL SaveLineAppend
   @GET_FROM EntryPtr FORMOBJ_Y @POPI Value
   @Call(V) SaveLineAppendInt Value
   @STRSTACK ", w: "
   @CALL SaveLineAppend
   @GET_FROM EntryPtr FORMOBJ_WIDTH @POPI Value
   @Call(V) SaveLineAppendInt Value
   @STRSTACK ", h: "
   @CALL SaveLineAppend
   @GET_FROM EntryPtr FORMOBJ_HEIGHT @POPI Value
   @Call(V) SaveLineAppendInt Value
   @STRSTACK " }"
   @CALL SaveLineAppend
   @CALL SaveLineEmit
@EndLocals
@POPRETURN
@RET

########################################
# SaveEmitForms()
########################################
:SaveEmitForms
@PUSHRETURN
@Locals
   @Local UsedCount
   @Local Index
   @Local EntryPtr

   @CALL SaveLineClear
   @STRSTACK "forms: ["
   @CALL SaveLineAppend
   @CALL SaveLineEmit

   @GET_FROM FormTable FORMTABLE_USED @POPI UsedCount
   @ForIA2V Index 0 UsedCount
      @Call(VV) FormTableEntryPtr FormTable Index
      @POPI EntryPtr
      @GET_FROM EntryPtr FORMOBJ_TYPE
      @IF_NEQ_A FORMOBJ_TYPE_NONE
         @POPNULL
         @Call(V) SaveEmitFormEntry EntryPtr
      @ELSE
         @POPNULL
      @ENDIF
   @Next Index

   @CALL SaveLineClear
   @STRSTACK "]"
   @CALL SaveLineAppend
   @CALL SaveLineEmit
@EndLocals
@POPRETURN
@RET

########################################
# SaveEmitCanvasLine(DataPtr)
########################################
:SaveEmitCanvasLine
@PUSHRETURN
@Locals
   @Local DataPtr
   @Local EndPtr
   @Local KeepIt

   @POPI DataPtr
   @PUSHI DataPtr
   @ADDI WinWidth
   @POPI EndPtr
   @PUSHII EndPtr
   @POPI KeepIt
   @PUSH 0
   @POPII EndPtr

   @CALL SaveLineClear
   @Call(V) SaveLineAppend DataPtr
   @CALL SaveLineEmit

   @PUSHI KeepIt
   @POPII EndPtr
@EndLocals
@POPRETURN
@RET

########################################
# SaveEmitCanvas()
########################################
:SaveEmitCanvas
@PUSHRETURN
@Locals
   @Local Row
   @Local CanvasRows
   @Local DataPtr

   @CALL SaveLineClear
   @STRSTACK "canvas: ["
   @CALL SaveLineAppend
   @CALL SaveLineEmit

   @PUSHI WinHeight
   @SUB 1
   @POPI CanvasRows
   @MV2V CanvasData DataPtr

   @ForIA2V Row 0 CanvasRows
      @Call(V) SaveEmitCanvasLine DataPtr
      @PUSHI DataPtr
      @ADDI WinWidth
      @POPI DataPtr
   @Next Row

   @CALL SaveLineClear
   @STRSTACK "]"
   @CALL SaveLineAppend
   @CALL SaveLineEmit
@EndLocals
@POPRETURN
@RET

########################################
# SaveWorkFile
# Placeholder report view for the editable work-file output path.
########################################
:SaveWorkFile
@PUSHRETURN
@Locals
   @CALL TermMouseDisable
   @CALL WinClear
   @Call(V) HeapAvailable MainHeap
   @IF_ULT_A 1400
      @POPNULL
      @CALL SaveLineClear
      @STRSTACK "NOT ENOUGH HEAP FOR DISK SAVE"
      @CALL SaveLineAppend
      @CALL SaveLineEmit
      @JMP SaveWorkFileFinish
   @ENDIF
   @POPNULL
   @MA2V 1 SaveDiskStatus
   @CALL SaveEnsureDiskReady
   @POPNULL
   @IF_EQ_AV 0 SaveDiskReady
      @CALL SaveLineClear
      @STRSTACK "DISK NOT READY"
      @CALL SaveLineAppend
      @CALL SaveLineEmit
   @ELSE
      @Call(VA) file_open_basic SaveWorkFileName MODE_WP
      @POPI SaveFilePtr
      @IF_EQ_AV 0 SaveFilePtr
         @CALL SaveLineClear
         @STRSTACK "SAVE OPEN FAILED: FORMEDIT.SAV"
         @CALL SaveLineAppend
         @CALL SaveLineEmit
      @ELSE
         @CALL SaveEmitHeader
         @CALL SaveEmitForms
         @CALL SaveEmitCanvas
         @CALL SaveLineClear
         @STRSTACK "END"
         @CALL SaveLineAppend
         @CALL SaveLineEmit
         @Call(V) DiskClose SaveFilePtr
         @IF_ZERO
            @POPNULL
            @MA2V 0 SaveDiskStatus
         @ELSE
            @POPNULL
         @ENDIF
         @MA2V 0 SaveFilePtr
         @CALL SaveLineClear
         @IF_EQ_AV 1 SaveDiskStatus
            @STRSTACK "SAVED FORMEDIT.SAV"
         @ELSE
            @STRSTACK "SAVE FAILED: FORMEDIT.SAV"
         @ENDIF
         @CALL SaveLineAppend
         @CALL SaveLineEmit
      @ENDIF
   @ENDIF

:SaveWorkFileFinish
   @CALL SaveLineClear
   @STRSTACK "Click or ESC returns to editor"
   @CALL SaveLineAppend
   @CALL SaveLineEmit
   @CALL TermMouseEnable
   @MA2V 1 ReportActive
   @Call(V) EventSetActive CanvasEventTable
@EndLocals
@POPRETURN
@RET


########################################
# LoadWorkFile
# Placeholder report view for the editable work-file input path.
########################################
:LoadWorkFile
@PUSHRETURN
@Locals
   @CALL TermMouseDisable
   @CALL WinClear
   @CALL SaveLineClear
   @STRSTACK "LOAD WORK: disk parser pending"
   @CALL SaveLineAppend
   @CALL SaveLineEmit
   @CALL SaveLineClear
   @STRSTACK "SAVE WORK currently writes FORMEDIT.SAV"
   @CALL SaveLineAppend
   @CALL SaveLineEmit
   @CALL SaveLineClear
   @STRSTACK "Click or ESC returns to editor"
   @CALL SaveLineAppend
   @CALL SaveLineEmit
   @CALL TermMouseEnable
   @MA2V 1 ReportActive
   @Call(V) EventSetActive CanvasEventTable
@EndLocals
@POPRETURN
@RET

########################################
# DisplaySelectedFieldEditor
########################################
:DisplaySelectedFieldEditor
@PUSHRETURN
@Locals
   @Local EditX
   @Local EditY
   @Local EditW
   @Local EditH
   @Local PrintID
   @Local PrintType
   @Local PrintX
   @Local PrintY
   @Local PrintWidth
   @Local PrintHeight
   @Local PrintValuePtr
   @Local PrintFieldPtr

   @IF_NEQ_AV 0 SelectedFormEntry
      @MA2V 24 EditX
      @MA2V 6 EditY
      @MA2V 62 EditW
      @MA2V 20 EditH
      @CALL DisplayCanvas
      @Call(VVVV) WinClearRect EditX EditY EditW EditH
      @MA2V 0 BOXMODE
      @Call(VVVV) WinBox EditX EditY EditW EditH
      @Call(AA) WinCursor 61 6
      @PRT "X"
      @GET_FROM SelectedFormEntry FORMOBJ_ID @POPI PrintID
      @GET_FROM SelectedFormEntry FORMOBJ_TYPE @POPI PrintType
      @GET_FROM SelectedFormEntry FORMOBJ_X @POPI PrintX
      @GET_FROM SelectedFormEntry FORMOBJ_Y @POPI PrintY
      @GET_FROM SelectedFormEntry FORMOBJ_WIDTH @POPI PrintWidth
      @GET_FROM SelectedFormEntry FORMOBJ_HEIGHT @POPI PrintHeight
      @GET_FROM SelectedFormEntry FORMOBJ_VALUE_PTR @POPI PrintValuePtr
      @GET_FROM SelectedFormEntry FORMOBJ_FIELD_PTR @POPI PrintFieldPtr

      @Call(AA) WinCursor 26 7
      @PRT "EDIT SELECTED FIELD"
      @Call(AA) WinCursor 26 9
      @PRT "ID: " @PRTI PrintID
      @Call(AA) WinCursor 26 10
      @PRT "TYPE: " @Call(V) FormPrintType PrintType
      @Call(AA) WinCursor 26 11
      @PRT "- X " @PRTI PrintX
      @Call(AA) WinCursor 42 11
      @PRT "+"
      @Call(AA) WinCursor 26 12
      @PRT "- Y " @PRTI PrintY
      @Call(AA) WinCursor 42 12
      @PRT "+"
      @Call(AA) WinCursor 26 13
      @PRT "- W " @PRTI PrintWidth
      @Call(AA) WinCursor 42 13
      @PRT "+"
      @Call(AA) WinCursor 26 14
      @IF_EQ_AV FIELD_TYPE_TEXTBOX PrintType
         @PRT "- H " @PRTI PrintHeight
         @Call(AA) WinCursor 42 14
         @PRT "+"
      @ELSE
         @PRT "  H " @PRTI PrintHeight @PRT " fixed"
      @ENDIF
      @Call(AA) WinCursor 26 16
      @PRT "VALUE PTR: " @PRTI PrintValuePtr
      @Call(AA) WinCursor 26 17
      @PRT "FIELD PTR: " @PRTI PrintFieldPtr
      @Call(AA) WinCursor 26 19
      @PRT "ESC/^O close"
      @MA2V 0 ReportActive
      @MA2V 1 FieldEditActive
      @Call(V) EventSetActive FieldEditEventTable
      @CALL StatusLine
   @ELSE
      @Call(V) EventSetActive CanvasEventTable
      @CALL DisplayCanvas
   @ENDIF
@EndLocals
@POPRETURN
@RET

########################################
# FormEntryDelete(EntryPtr):Status
########################################
:FormEntryDelete
@PUSHRETURN
@Locals
   @Local EntryPtr
   @Local Status

   @POPI EntryPtr
   @MA2V 0 Status
   @IF_NEQ_AV 0 EntryPtr
      @IF_EQ_VV EntryPtr SelectedFormEntry
         @MA2V 0 SelectedFormEntry
      @ENDIF
      @Call(V) FormEntryClear EntryPtr
      @MA2V 1 Status
   @ENDIF
   @PUSHI Status
@EndLocals
@POPRETURN
@RET

########################################
# FormEntryFindByID(FormID):EntryPtr
########################################
:FormEntryFindByID
@PUSHRETURN
@Locals
   @Local FormID
   @Local UsedCount
   @Local Index
   @Local EntryPtr

   @POPI FormID
   @GET_FROM FormTable FORMTABLE_USED @POPI UsedCount
   @MA2V 0 EntryPtr
   @ForIA2V Index 0 UsedCount
      @Call(VV) FormTableEntryPtr FormTable Index
      @POPI EntryPtr
      @GET_FROM EntryPtr FORMOBJ_TYPE
      @IF_NEQ_A FORMOBJ_TYPE_NONE
         @POPNULL
         @GET_FROM EntryPtr FORMOBJ_ID
         @IF_EQ_V FormID
            @POPNULL
            @FORBREAK
         @ELSE
            @POPNULL
            @MA2V 0 EntryPtr
         @ENDIF
      @ELSE
         @POPNULL
         @MA2V 0 EntryPtr
      @ENDIF
   @Next Index
   @PUSHI EntryPtr
@EndLocals
@POPRETURN
@RET

############################################
# FormEntryNormalizeGeometry(EntryPtr)
############################################
:FormEntryNormalizeGeometry
@PUSHRETURN
@Locals
   @Local EntryPtr
   @Local ObjType
   @Local X1
   @Local Y1
   @Local Width
   @Local Height
   @Local MaxWidth
   @Local MaxHeight

   @POPI EntryPtr

   @IF_NEQ_AV 0 EntryPtr
      @GET_FROM EntryPtr FORMOBJ_TYPE @POPI ObjType
      @GET_FROM EntryPtr FORMOBJ_X @POPI X1
      @GET_FROM EntryPtr FORMOBJ_Y @POPI Y1
      @GET_FROM EntryPtr FORMOBJ_WIDTH @POPI Width
      @GET_FROM EntryPtr FORMOBJ_HEIGHT @POPI Height

      # Clamp origin to the editable canvas.
      @PUSHI X1
      @IF_LT_A 1
         @POPNULL
         @MA2V 1 X1
      @ELSE
         @POPNULL
      @ENDIF

      @PUSHI X1
      @IF_GT_V WinWidth
         @POPNULL
         @MV2V WinWidth X1
      @ELSE
         @POPNULL
      @ENDIF

      @PUSHI Y1
      @IF_LT_A 1
         @POPNULL
         @MA2V 1 Y1
      @ELSE
         @POPNULL
      @ENDIF

      @PUSHI WinHeight
      @SUB 1
      @IF_LT_V Y1
         @POPNULL
         @PUSHI WinHeight
         @SUB 1
         @POPI Y1
      @ELSE
         @POPNULL
      @ENDIF

      # Width may occupy the remainder of the row.
      @PUSHI WinWidth
      @SUBI X1
      @ADD 1
      @POPI MaxWidth

      @PUSHI Width
      @IF_LT_A 1
         @POPNULL
         @MA2V 1 Width
      @ELSE
         @POPNULL
      @ENDIF

      @PUSHI Width
      @IF_GT_V MaxWidth
         @POPNULL
         @MV2V MaxWidth Width
      @ELSE
         @POPNULL
      @ENDIF

      # All fields are one line unless explicitly multi-line.
      @MA2V 1 Height

      @PUSHI ObjType
      @SWITCH
      @CASE FIELD_TYPE_TEXTBOX
         @PUSHI WinHeight
         @SUB 1
         @SUBI Y1
         @ADD 1
         @POPI MaxHeight

         @GET_FROM EntryPtr FORMOBJ_HEIGHT @POPI Height

         @PUSHI Height
         @IF_LT_A 1
            @POPNULL
            @MA2V 1 Height
         @ELSE
            @POPNULL
         @ENDIF

         @PUSHI Height
         @IF_GT_V MaxHeight
            @POPNULL
            @MV2V MaxHeight Height
         @ELSE
            @POPNULL
         @ENDIF
         @CBREAK

      @CDEFAULT
         @CBREAK
      @ENDCASE
      @POPNULL

      @FILL_AT_V EntryPtr FORMOBJ_X X1
      @FILL_AT_V EntryPtr FORMOBJ_Y Y1
      @FILL_AT_V EntryPtr FORMOBJ_WIDTH Width
      @FILL_AT_V EntryPtr FORMOBJ_HEIGHT Height
   @ENDIF
@EndLocals
@POPRETURN
@RET

########################################
# FormEntryDeleteByID(FormID):Status
########################################
:FormEntryDeleteByID
@PUSHRETURN
@Locals
   @Local FormID
   @Local EntryPtr

   @POPI FormID
   @Call(V) FormEntryFindByID FormID
   @POPI EntryPtr
   @Call(V) FormEntryDelete EntryPtr
@EndLocals
@POPRETURN
@RET

   
########################################
# SetupEvents
# Initilizes Event Tables
########################################
:SetupEvents
@PUSHRETURN
@Locals
   @Local Zero

# Most common Event Add is AVVVVA so create custom macro for most common form.
M AddCommonEvent \
   @PUSH %1 \     # EventType Mouse  Key     KeyRange  Timer
   @PUSHI %2 \    #           X1     StrPtr  ASCII     Secs
   @PUSHI %3 \    #           Y1     0       ASCII     Repeat
   @PUSHI %4 \    #           X2     0       0         0
   @PUSHI %5 \    #           Y2     0       0         0
   @PUSH %6 \     # EventID
   @CALL EventAdd
# Second most common is AAAAAA 
M AddConstantEvent \
   @PUSH %1 \     # EventType Mouse  Key     KeyRange  Timer
   @PUSH %2 \     #           X1     StrPtr  ASCII     Secs
   @PUSH %3 \     #           Y1     0       ASCII     Repeat
   @PUSH %4 \     #           X2     0       0         0
   @PUSH %5 \     #           Y2     0       0         0
   @PUSH %6 \     # EventID
   @CALL EventAdd

   @MA2V 0 Zero

   @Call(V) EventTableNew MainHeap
   @POPI CtrlMenuEventTable
   @Call(V) EventSetActive CtrlMenuEventTable

   @AddCommonEvent MouseEventClick Zero Zero WinWidth WinHeight EV_MenuClick
   @AddConstantEvent KeyRangeEvent 27 27 0 0 EV_MenuESC
   @AddConstantEvent KeyRangeEvent 15 15 0 0 EV_MenuOpenCloseCtrl # ^O close menu
   @AddConstantEvent KeyRangeEvent 2 2 0 0 EV_MenuCtrlBox       # ^B
   @AddConstantEvent KeyRangeEvent 9 9 0 0 EV_MenuCtrlInteger   # ^I / TAB
   @AddConstantEvent KeyRangeEvent 12 12 0 0 EV_MenuCtrlLong    # ^L
   @AddConstantEvent KeyRangeEvent 19 19 0 0 EV_MenuCtrlString  # ^S
   @AddConstantEvent KeyRangeEvent 23 23 0 0 EV_MenuCtrlWords   # ^W
   @AddConstantEvent KeyRangeEvent 20 20 0 0 EV_MenuCtrlTextBox # ^T
   @AddConstantEvent KeyRangeEvent 16 16 0 0 EV_MenuPrint       # ^P
   @CALL EventGetActive
   @POPI CtrlMenuEventTable

   @Call(V) EventTableNew MainHeap
   @POPI CanvasEventTable
   @Call(V) EventSetActive CanvasEventTable

   @AddCommonEvent MouseEventClick Zero Zero WinWidth WinHeight EV_CanvasClick
   @AddConstantEvent KeyRangeEvent 2 2 0 0 EV_CanvasCtrlBox       # ^B
   @AddConstantEvent KeyRangeEvent 9 9 0 0 EV_CanvasCtrlInteger   # ^I / TAB
   @AddConstantEvent KeyRangeEvent 12 12 0 0 EV_CanvasCtrlLong    # ^L
   @AddConstantEvent KeyRangeEvent 19 19 0 0 EV_CanvasCtrlString  # ^S
   @AddConstantEvent KeyRangeEvent 23 23 0 0 EV_CanvasCtrlWords   # ^W
   @AddConstantEvent KeyRangeEvent 20 20 0 0 EV_CanvasCtrlTextBox # ^T
   @AddConstantEvent KeyRangeEvent " \0" 126 0 0 EV_CanvasKey
   @AddConstantEvent KeyRangeEvent 127 127 0 0 EV_CanvasDel   
   @AddConstantEvent KeyRangeEvent 27 27 0 0 EV_CanvasESC
   @AddConstantEvent KeyRangeEvent 15 15 0 0 EV_CanvasOpenMenuCtrl # ^O Open menu
   @AddConstantEvent KeyRangeEvent 10 10 0 0 EV_CanvasNL
   @AddConstantEvent KeyRangeEvent 13 13 0 0 EV_CanvasCR
   @CALL EventGetActive
   @POPI CanvasEventTable

   @Call(V) EventTableNew MainHeap
   @POPI FieldEditEventTable
   @Call(V) EventSetActive FieldEditEventTable

   @AddConstantEvent KeyRangeEvent 27 27 0 0 EV_FieldEditESC
   @AddConstantEvent KeyRangeEvent 15 15 0 0 EV_FieldEditOpenMenu
   @AddConstantEvent MouseEventClick 26 11 26 11 EV_FieldEditDecX
   @AddConstantEvent MouseEventClick 42 11 42 11 EV_FieldEditIncX
   @AddConstantEvent MouseEventClick 26 12 26 12 EV_FieldEditDecY
   @AddConstantEvent MouseEventClick 42 12 42 12 EV_FieldEditIncY
   @AddConstantEvent MouseEventClick 26 13 26 13 EV_FieldEditDecW
   @AddConstantEvent MouseEventClick 42 13 42 13 EV_FieldEditIncW
   @AddConstantEvent MouseEventClick 26 14 26 14 EV_FieldEditDecH
   @AddConstantEvent MouseEventClick 42 14 42 14 EV_FieldEditIncH
   @AddConstantEvent MouseEventClick 61 6 61 6 EV_FieldEditCloseClick
   @AddConstantEvent MouseEventClick 26 19 36 19 EV_FieldEditCloseText
   @CALL EventGetActive
   @POPI FieldEditEventTable
   @Call(V) EventSetActive CanvasEventTable
@EndLocals
@POPRETURN
@RET
#############################################
# DisplayMenu
#############################################
:DisplayMenu
@PUSHRETURN
@Locals
   @Local MenuWidth
   @Local MenuHeight

   @MA2V 22 MenuWidth
   @MA2V 12 MenuHeight

   @Call(AAVV) WinClearRect 0 0 MenuWidth MenuHeight
   @MA2V 0 BOXMODE
   @Call(AAVV) WinBox 1 1 MenuWidth MenuHeight   
   @Call(AA) WinCursor 21 1
   @PRT "X"

   @Call(AA) WinCursor 2 2
   @PRT "^B BOX"
   @Call(AA) WinCursor 2 3
   @PRT "^I INTEGER"
   @Call(AA) WinCursor 2 4
   @PRT "^L LONG"   
   @Call(AA) WinCursor 2 5
   @PRT "^S/^W STRING"
   @Call(AA) WinCursor 2 6
   @PRT "^T TEXTBOX"
   @Call(AA) WinCursor 2 7
   @PRT "PRINT"
   @Call(AA) WinCursor 2 8
   @PRT "SAVE WORK"
   @Call(AA) WinCursor 2 9
   @PRT "LOAD WORK"
   @Call(AA) WinCursor 2 10
   @IF_NEQ_AV 0 SelectedFormEntry
      @PRT "EDIT SEL."
   @ELSE
      @PRT "SELECT"
   @ENDIF
   @Call(AA) WinCursor 2 11
   @PRT "Exit"
@EndLocals
@POPRETURN
@RET

###########################################
# Status Line
###########################################
:StatusLine
@PUSHRETURN
@Locals
    @Call(AV) WinCursor 10 WinHeight
    @IF_NEQ_AV 0 FieldEditActive
       @PRT "FIELD EDIT                       "
       @JMP StatusLineDone
    @ENDIF
    @PUSHI SelectionMode
    @SWITCH
    @CASE MODE_Default
       @PRT "EDIT                             "
       @CBREAK
    @CASE MODE_SelectSecond
       @IF_EQ_AV SELDIM_1D SelectionDimensions
          @PRT "SELECT: End ESC=Cancel           "
       @ELSE
          @PRT "SELECT: 2nd Corner ESC=Cancel    "
       @ENDIF
       @CBREAK
    @CASE MODE_SelectFirst
       @IF_EQ_AV -1 SelectionX2
          @PRT "SELECT: 1st Corner ESC=Cancel "
       @ELSE
          @PRT "SELECT: ENTER=Accept ESC=Cancel"
       @ENDIF
       @CBREAK
    @CDEFAULT
       @CBREAK
    @ENDCASE
    @POPNULL
    # Status rendering moves the hardware cursor; return it to the edit point.
    @CALL CanvasCursorMove
:StatusLineDone
@EndLocals
@POPRETURN
@RET


###########################################
# DisplayCanvas
###########################################
:DisplayCanvas
@PUSHRETURN
@Locals
   @Local Row
   @Local DataPtr
   @Local EndPtr
   @Local KeepIt
   @Local ScreenY
   @Local PrintWidth
   @Local CanvasRows

   @CALL WinClear
   @MV2V CanvasData DataPtr
   @PUSHI WinHeight
   @SUB 1
   @POPI CanvasRows

   @ForIA2V Row 0 CanvasRows
      @PUSHI Row
      @ADD 1
      @POPI ScreenY

      @MV2V WinWidth PrintWidth

      @Call(AV) WinCursor 1 ScreenY

      @PUSHI DataPtr
      @ADDI PrintWidth
      @POPI EndPtr

      @PUSHII EndPtr
      @POPI KeepIt

      @PUSH 0
      @POPII EndPtr

      @PRTSI DataPtr

      @PUSHI KeepIt
      @POPII EndPtr

      @PUSHI DataPtr
      @ADDI WinWidth
      @POPI DataPtr
   @Next Row

   @CALL DisplayFormOverlays

   # Put the hardware cursor back at the logical edit position.
   @CALL CanvasCursorMove

@EndLocals
@POPRETURN
@RET

##########################################
# FillBetween(X1,Y1,X2,Y2)
##########################################
:FillBetween
@PUSHRETURN
@Locals
    @Local I1
    @Local J1
    @Local KeepIt
    @Local X1
    @Local X2
    @Local Y1
    @Local Y2
    @Local StrPtr
    @Local FillWidth

    @POPI4 Y2 X2 Y1 X1
    @INCI X1
    @INCI Y1
    @DECI X2
    @DECI Y2
    @QuickMinI X1 X2
    @QuickMinI Y1 Y2
    

    @PUSHI Y1
    @SUB 1
    @PUSHI WinWidth
    @CALL MULU
    @PUSHI X1
    @SUB 1
    @ADDS
    @ADDI CanvasData
    @POPI StrPtr
    @PUSHI X2
    @SUBI X1
    @POPI FillWidth
    
    @ForIV2V I1 Y1 Y2
        @Call(VV) WinCursor X1 I1
        @PUSHI StrPtr
        @ADDI FillWidth
        @PUSHS
        @POPI KeepIt
        @PUSH 0
        @PUSHI StrPtr
        @ADDI FillWidth
        @POPS
        @PRTSI StrPtr
        @PUSHI KeepIt
        @PUSHI StrPtr
        @ADDI FillWidth
        @POPS
        @PUSHI StrPtr
        @ADDI WinWidth
        @POPI StrPtr
    @Next I1
@EndLocals
@POPRETURN
@RET
        
        
############################################
# CanvasClickEvent
############################################
:CanvasClickEvent
@PUSHRETURN
@Locals
    # Ignore Clicks on Status line
    @PUSHI LastMouseY
    @IF_GE_V WinHeight
       @POPNULL
       @JMP CanvasClickDone
    @ELSE
       @POPNULL
    @ENDIF

    @IF_NEQ_AV MODE_Default SelectionMode
        @IF_EQ_AV MODE_SelectFirst SelectionMode
           # Next selection click chooses the first point. Erase any uncommitted preview first.
           @IF_NEQ_AV -1 SelectionX2
               # Preview not accepted, start a new selection.
               @CALL DisplayCanvas
           @ENDIF
           @MV2V LastMouseX SelectionX1
           @MV2V LastMouseY SelectionY1
           @MA2V -1 SelectionX2
           @MA2V -1 SelectionY2
           @MA2V MODE_SelectSecond SelectionMode
           # Transient first-corner marker for selection modes.
           @Call(VV) WinCursor SelectionX1 SelectionY1
           @PRT "+"
        @ELSE
           # Second point completes the preview, then the next click starts a new first point.
           @MV2V LastMouseX SelectionX2
           @IF_EQ_AV SELDIM_1D SelectionDimensions
              @MV2V SelectionY1 SelectionY2
           @ELSE
              @MV2V LastMouseY SelectionY2
           @ENDIF
           @QuickMinI SelectionX1 SelectionX2
           @IF_EQ_AV SELDIM_2D SelectionDimensions
              @QuickMinI SelectionY1 SelectionY2
           @ENDIF
           @MA2V 1 BOXMODE
           @Call(VVVV) WinBox SelectionX1 SelectionY1 SelectionX2 SelectionY2
           @MA2V MODE_SelectFirst SelectionMode
        @ENDIF
    @ELSE
        # Normal Click just moves the cursor insert point
        @PUSHI LastMouseY
        @IF_LT_V WinHeight
           @POPNULL
           @PUSHI LastMouseY
           @SUB 1
           @PUSHI WinWidth
           @CALL MULU
           @PUSHI LastMouseX
           @SUB 1
           @ADDS
           @POPI CanvasCursor
           @Call(VV) WinCursor LastMouseX LastMouseY
           @Call(VV) FormEntryFindAtPoint LastMouseX LastMouseY
           @CALL FormSelectEntry
           @CALL DisplayCanvas
        @ELSE
           @POPNULL
        @ENDIF
    @ENDIF

    :CanvasClickDone
@EndLocals
@POPRETURN
@RET
##########################################
# CanvasCursorMove
##########################################
:CanvasCursorMove
@PUSHRETURN
@Locals
   @Local CursorX
   @Local CursorY

   @PUSHI CanvasCursor
   @IF_ULT_V CanvasSize
      @POPNULL
      @Call(VV) DIVU CanvasCursor WinWidth
      @POPI CursorY
      @POPI CursorX
      @INCI CursorX
      @INCI CursorY
      @Call(VV) WinCursor CursorX CursorY
   @ELSE
      @POPNULL
   @ENDIF
@EndLocals
@POPRETURN
@RET

##########################################
# CanvasKeyEvent
##########################################
:CanvasKeyEvent
@PUSHRETURN
@Locals
   @Local CharPtr

   # Printable keys have no editing means while selecting a shared region.
   @IF_NEQ_AV MODE_Default SelectionMode
   @ELSE
      @PUSHI CanvasData
      @ADDI CanvasCursor
      @POPI CharPtr

      @PUSHI CanvasCursor
      @IF_ULT_V CanvasSize
         @POPNULL
         @CALL CanvasCursorMove
         @PUSHI LastKeyChar
         @STOREBII CharPtr
         @INCI CanvasCursor
         @CALL DisplayCanvas
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
@EndLocals
@POPRETURN
@RET

##########################################
# CanvasDelEvent
##########################################
:CanvasDelEvent
@PUSHRETURN
@Locals
   @Local CharPtr
  # Printable keys have no editing means while selecting a shared region.
   @IF_NEQ_AV MODE_Default SelectionMode
   @ELSE
      @PUSHI CanvasCursor
      @IF_UGT_A 0
         @POPNULL
         @DECI CanvasCursor
         @PUSHI CanvasData
         @ADDI CanvasCursor
         @POPI CharPtr
         
         @PUSH 32
         @STOREBII CharPtr

         @CALL DisplayCanvas
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
@EndLocals
@POPRETURN
@RET

##########################################
# CanvasCREvent
# Validates the current CR state, then dispatches to CanvasCRHandler.
# Returns SEL_None or the completed SEL_* action from the CR_* handler.
##########################################
:CanvasCREvent
@PUSHRETURN
@Locals
   @Local CompletedAction

   @MA2V SEL_None CompletedAction

   @IF_NEQ_AV MODE_Default SelectionMode
       @IF_EQ_AV -1 SelectionX1
          @PUSHI CompletedAction
          @JMP CCRE_Done
       @ENDIF
       @IF_EQ_AV -1 SelectionX2
          @PUSHI CompletedAction
          @JMP CCRE_Done
       @ENDIF
       @IF_EQ_AV -1 SelectionY2
          @PUSHI CompletedAction
          @JMP CCRE_Done
       @ENDIF
   @ENDIF

   @CALLI CanvasCRHandler
   @POPI CompletedAction
   @PUSHI CompletedAction

:CCRE_Done
@EndLocals
@POPRETURN
@RET

##########################################
# SelectionCompleteAndReset(Action):Action
# Captures the accepted rectangle for the CR_* handler, resets live
# selection state, then returns the completed action.
##########################################
:SelectionCompleteAndReset
@PUSHRETURN
@Locals
   @Local CompletedAction

   @POPI CompletedAction
   @MV2V SelectionX1 SelectionCompleteX1
   @MV2V SelectionY1 SelectionCompleteY1
   @MV2V SelectionX2 SelectionCompleteX2
   @MV2V SelectionY2 SelectionCompleteY2
   @MA2V -1 SelectionX1
   @MA2V -1 SelectionY1
   @MA2V -1 SelectionX2
   @MA2V -1 SelectionY2
   @MA2V SELDIM_None SelectionDimensions
   @MA2V SEL_None SelectionAction
   @MA2V MODE_Default SelectionMode
   @MA2V CR_EDIT CanvasCRHandler
   @PUSHI CompletedAction
@EndLocals
@POPRETURN
@RET

##########################################
# CR_EDIT
# Default ENTER behavior: move to the beginning of the next line.
##########################################
:CR_EDIT
@PUSHRETURN
@Locals
   @Local CursorX
   @Local CursorY

   @Call(VV) DIVU CanvasCursor WinWidth
   @POPI CursorY
   @POPI CursorX
   @INCI CursorY
   @PUSHI CursorY
   @IF_LT_V WinHeight
      @POPNULL
      @Call(VV) MULU CursorY WinWidth
      @POPI CanvasCursor
   @ELSE
      @POPNULL
   @ENDIF
   @PUSH SEL_None
@EndLocals
@POPRETURN
@RET

##########################################
# CR_BOX
# Completes draw-box mode by committing the selected rectangle to CanvasData.
##########################################
:CR_BOX
@PUSHRETURN
@Locals
   @Local BoxXI
   @Local BoxYI
   @Local DataPtr1
   @Local DataPtr2

   @PUSHI SelectionY1
   @SUB 1
   @PUSHI WinWidth
   @CALL MULU
   @PUSHI SelectionX1
   @SUB 1
   @ADDS
   @ADDI CanvasData
   @POPI DataPtr1
   @PUSHI SelectionY2
   @SUB 1
   @PUSHI WinWidth
   @CALL MULU
   @PUSHI SelectionX1
   @SUB 1
   @ADDS
   @ADDI CanvasData
   @POPI DataPtr2
   @ForIV2V BoxXI SelectionX1 SelectionX2
      @PUSH "-\0"
      @STOREBII DataPtr1
      @PUSH "-\0"
      @STOREBII DataPtr2
      @INCI DataPtr1
      @INCI DataPtr2
   @Next BoxXI
   @PUSHI SelectionY1
   @SUB 1
   @PUSHI WinWidth
   @CALL MULU
   @PUSHI SelectionX1
   @SUB 1
   @ADDS
   @ADDI CanvasData
   @POPI DataPtr1
   @PUSHI DataPtr1
   @ADDI SelectionX2
   @SUBI SelectionX1
   @POPI DataPtr2
   @ForIV2V BoxYI SelectionY1 SelectionY2
      @PUSH "|\0"
      @STOREBII DataPtr1
      @PUSH "|\0"
      @STOREBII DataPtr2
      @PUSHI DataPtr1
      @ADDI WinWidth
      @POPI DataPtr1
      @PUSHI DataPtr2
      @ADDI WinWidth
      @POPI DataPtr2
   @Next BoxYI
   @PUSHI SelectionY1
   @SUB 1
   @PUSHI WinWidth
   @CALL MULU
   @PUSHI SelectionX1
   @SUB 1
   @ADDS
   @ADDI CanvasData
   @POPI DataPtr1
   @PUSH "+\0"
   @STOREBII DataPtr1
   @PUSHI SelectionY2
   @SUB 1
   @PUSHI WinWidth
   @CALL MULU
   @PUSHI SelectionX1
   @SUB 1
   @ADDS
   @ADDI CanvasData
   @POPI DataPtr2
   @PUSH "+\0"
   @STOREBII DataPtr2
   @PUSHI DataPtr1 @ADDI SelectionX2 @SUBI SelectionX1
   @POPI DataPtr1
   @PUSH "+\0"
   @STOREBII DataPtr1
   @PUSHI DataPtr2 @ADDI SelectionX2 @SUBI SelectionX1
   @POPI DataPtr2
   @PUSH "+\0"
   @STOREBII DataPtr2

   @Call(A) SelectionCompleteAndReset SEL_DrawBox
@EndLocals
@POPRETURN
@RET

:CR_INTEGER
@PUSHRETURN
   @Call(A) SelectionCompleteAndReset SEL_NewInteger
@POPRETURN
@RET

:CR_LONG
@PUSHRETURN
   @Call(A) SelectionCompleteAndReset SEL_NewLong
@POPRETURN
@RET

:CR_STRING
@PUSHRETURN
   @Call(A) SelectionCompleteAndReset SEL_NewString
@POPRETURN
@RET

:CR_TEXTBOX
@PUSHRETURN
   @Call(A) SelectionCompleteAndReset SEL_NewTextBox
@POPRETURN
@RET

############################################
# StartSelection(Action)
# Shared by menu items and control-key shortcuts.  The ENTER handler
# returns the completed SelectionAction.  SEL_DrawBox still commits
# to CanvasData; form creation actions use the returned status as their hook.
############################################
:StartSelection
@PUSHRETURN
@Locals
   @POPI SelectionAction
   @MA2V -1 SelectionX1
   @MA2V -1 SelectionY1
   @MA2V -1 SelectionX2
   @MA2V -1 SelectionY2
   @MA2V -1 SelectionCompleteX1
   @MA2V -1 SelectionCompleteY1
   @MA2V -1 SelectionCompleteX2
   @MA2V -1 SelectionCompleteY2
   @PUSHI SelectionAction
   @SWITCH
   @CASE SEL_DrawBox
      @MA2V SELDIM_2D SelectionDimensions
      @MA2V CR_BOX CanvasCRHandler
      @CBREAK
   @CASE SEL_NewInteger
      @MA2V SELDIM_1D SelectionDimensions
      @MA2V CR_INTEGER CanvasCRHandler
      @CBREAK
   @CASE SEL_NewLong
      @MA2V SELDIM_1D SelectionDimensions
      @MA2V CR_LONG CanvasCRHandler
      @CBREAK
   @CASE SEL_NewString
      @MA2V SELDIM_1D SelectionDimensions
      @MA2V CR_STRING CanvasCRHandler
      @CBREAK
   @CASE SEL_NewTextBox
      @MA2V SELDIM_2D SelectionDimensions
      @MA2V CR_TEXTBOX CanvasCRHandler
      @CBREAK
   @CDEFAULT
      @MA2V SELDIM_None SelectionDimensions
      @MA2V CR_EDIT CanvasCRHandler
      @CBREAK
   @ENDCASE
   @POPNULL
   @MA2V MODE_SelectFirst SelectionMode
   @MA2V 0 FieldEditActive
   @Call(V) EventSetActive CanvasEventTable
   @CALL DisplayCanvas
@EndLocals
@POPRETURN
@RET

############################################
# CancelSelection
# Abort any active two-point mode and return to plain edit handling.
############################################
:CancelSelection
@PUSHRETURN
   @MA2V -1 SelectionX1
   @MA2V -1 SelectionY1
   @MA2V -1 SelectionX2
   @MA2V -1 SelectionY2
   @MA2V SELDIM_None SelectionDimensions
   @MA2V SEL_None SelectionAction
   @MA2V MODE_Default SelectionMode
   @MA2V CR_EDIT CanvasCRHandler
@POPRETURN
@RET

############################################
# FieldEditAdjust(Offset,Delta)
############################################
:FieldEditAdjust
@PUSHRETURN
@Locals
   @Local Offset
   @Local Delta
   @Local Value
   @Local ValuePtr

   @POPI Delta
   @POPI Offset
   @IF_NEQ_AV 0 SelectedFormEntry
      @PUSHI SelectedFormEntry
      @ADDI Offset
      @POPI ValuePtr
      @PUSHII ValuePtr
      @ADDI Delta
      @POPI Value
      @PUSHI Value
      @IF_LT_A 1
         @POPNULL
         @MA2V 1 Value
      @ELSE
         @POPNULL
      @ENDIF
      @PUSHI Value
      @POPII ValuePtr
      @Call(V) FormEntryNormalizeGeometry SelectedFormEntry
      @CALL DisplaySelectedFieldEditor
   @ENDIF
@EndLocals
@POPRETURN
@RET

############################################
# FieldEditExit
############################################
:FieldEditExit
@PUSHRETURN
   @MA2V 0 FieldEditActive
   @Call(V) EventSetActive CanvasEventTable
   @CALL DisplayCanvas
@POPRETURN
@RET

############################################
# DoMenuAction
############################################
:DoMenuAction
@PUSHRETURN
@Locals
   @Local YValue
   @Local LoopExit
   @POPI YValue
   @MA2V 0 LoopExit

   @PUSHI YValue
   @SWITCH
   @CASE 1    # Draw box selection
      @Call(A) StartSelection SEL_DrawBox
      @CBREAK
   @CASE 2
      @Call(A) StartSelection SEL_NewInteger
      @CBREAK
   @CASE 3
      @Call(A) StartSelection SEL_NewLong
      @CBREAK
   @CASE 4
      @Call(A) StartSelection SEL_NewString
      @CBREAK
   @CASE 5
      @Call(A) StartSelection SEL_NewTextBox
      @CBREAK      
   @CASE 6
      @CALL PrintFormTable
      @CBREAK
   @CASE 7
      @CALL SaveWorkFile
      @CBREAK
   @CASE 8
      @CALL LoadWorkFile
      @CBREAK
   @CASE 9
      @IF_NEQ_AV 0 SelectedFormEntry
         @CALL DisplaySelectedFieldEditor
      @ELSE
         @Call(V) EventSetActive CanvasEventTable
         @CALL DisplayCanvas
      @ENDIF
      @CBREAK
   @CASE 10
      @MA2V 1 LoopExit
      @CBREAK
   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL
   @PUSHI LoopExit
@EndLocals
@POPRETURN
@RET

   
               

   
############################################
# MainEventLoop
############################################
:MainEventLoop
@PUSHRETURN
@Locals
    @Local EventID
    @Local CompletedAction

    @MA2V 0 MainLoopExit

    @PUSHI MainLoopExit
    @WHILE_ZERO    
       @CALL EventPoll
       @POPI EventID
       @IF_NEQ_AV 0 EventID
          @PUSHI EventID
          @SWITCH
          @CASE EV_MenuClick
             # Menu Select, or top-right X close.
             @POPNULL
             @IF_EQ_AV 1 LastMouseY
                @IF_EQ_AV 21 LastMouseX
                   @Call(V) EventSetActive CanvasEventTable
                   @CALL DisplayCanvas
                @ENDIF
             @ELSE
                @PUSHI LastMouseY
                @SUB 1
                @CALL DoMenuAction
                @POPI MainLoopExit
                @IF_NEQ_AV 0 MainLoopExit
                   @POPNULL
                   @PUSHI MainLoopExit
                @ENDIF
             @ENDIF
             @CBREAK
          @CASE EV_MenuOpenCloseCtrl
             @POPNULL
             @PUSH EV_MenuESC
             @CASE_FALLTHRU
          @CASE EV_MenuESC
             @POPNULL
             @Call(V) EventSetActive CanvasEventTable
             @CALL DisplayCanvas
             @CBREAK
          @CASE EV_MenuCtrlBox
             @POPNULL
             @Call(A) StartSelection SEL_DrawBox
             @CBREAK
          @CASE EV_MenuCtrlInteger
             @POPNULL
             @Call(A) StartSelection SEL_NewInteger
             @CBREAK
          @CASE EV_MenuCtrlLong
             @POPNULL
             @Call(A) StartSelection SEL_NewLong
             @CBREAK
          @CASE EV_MenuCtrlWords
             @POPNULL
             @PUSH EV_MenuCtrlString      # Treat as alias
             @CASE_FALLTHRU             
          @CASE EV_MenuCtrlString
             @POPNULL
             @Call(A) StartSelection SEL_NewString
             @CBREAK
          @CASE EV_MenuCtrlTextBox
             @POPNULL
             @Call(A) StartSelection SEL_NewTextBox
             @CBREAK
          @CASE EV_MenuPrint
             @POPNULL
             @CALL PrintFormTable
             @CBREAK
          @CASE EV_MenuSaveWork
             @POPNULL
             @CALL SaveWorkFile
             @CBREAK
          @CASE EV_MenuLoadWork
             @POPNULL
             @CALL LoadWorkFile
             @CBREAK
          @CASE EV_CanvasCtrlBox
             @POPNULL
             @Call(A) StartSelection SEL_DrawBox
             @CBREAK
          @CASE EV_CanvasCtrlInteger
             @POPNULL
             @Call(A) StartSelection SEL_NewInteger
             @CBREAK
          @CASE EV_CanvasCtrlLong
             @POPNULL
             @Call(A) StartSelection SEL_NewLong
             @CBREAK
          @CASE EV_CanvasCtrlWords
             @POPNULL
             @PUSH EV_CanvasCtrlString
             @CASE_FALLTHRU
          @CASE EV_CanvasCtrlString
             @POPNULL
             @Call(A) StartSelection SEL_NewString
             @CBREAK
          @CASE EV_CanvasCtrlTextBox
             @POPNULL
             @Call(A) StartSelection SEL_NewTextBox
             @CBREAK
          @CASE EV_FieldEditOpenMenu
             @POPNULL
             @PUSH EV_FieldEditESC
             @CASE_FALLTHRU
          @CASE EV_FieldEditCloseClick
             @POPNULL
             @PUSH EV_FieldEditESC
             @CASE_FALLTHRU
          @CASE EV_FieldEditCloseText
             @POPNULL
             @PUSH EV_FieldEditESC
             @CASE_FALLTHRU
          @CASE EV_FieldEditESC
             @POPNULL
             @CALL FieldEditExit
             @CBREAK
          @CASE EV_FieldEditDecX
             @POPNULL
             @Call(AA) FieldEditAdjust FORMOBJ_X -1
             @CBREAK
          @CASE EV_FieldEditIncX
             @POPNULL
             @Call(AA) FieldEditAdjust FORMOBJ_X 1
             @CBREAK
          @CASE EV_FieldEditDecY
             @POPNULL
             @Call(AA) FieldEditAdjust FORMOBJ_Y -1
             @CBREAK
          @CASE EV_FieldEditIncY
             @POPNULL
             @Call(AA) FieldEditAdjust FORMOBJ_Y 1
             @CBREAK
          @CASE EV_FieldEditDecW
             @POPNULL
             @Call(AA) FieldEditAdjust FORMOBJ_WIDTH -1
             @CBREAK
          @CASE EV_FieldEditIncW
             @POPNULL
             @Call(AA) FieldEditAdjust FORMOBJ_WIDTH 1
             @CBREAK
          @CASE EV_FieldEditDecH
             @POPNULL
             @IF_NEQ_AV 0 SelectedFormEntry
                @GET_FROM SelectedFormEntry FORMOBJ_TYPE
                @IF_EQ_A FIELD_TYPE_TEXTBOX
                   @POPNULL
                   @Call(AA) FieldEditAdjust FORMOBJ_HEIGHT -1
                @ELSE
                   @POPNULL
                @ENDIF
             @ENDIF
             @CBREAK
          @CASE EV_FieldEditIncH
             @POPNULL
             @IF_NEQ_AV 0 SelectedFormEntry
                @GET_FROM SelectedFormEntry FORMOBJ_TYPE
                @IF_EQ_A FIELD_TYPE_TEXTBOX
                   @POPNULL
                   @Call(AA) FieldEditAdjust FORMOBJ_HEIGHT 1
                @ELSE
                   @POPNULL
                @ENDIF
             @ENDIF
             @CBREAK
          @CASE EV_CanvasClick
             @POPNULL
             @IF_NEQ_AV 0 ReportActive
                @MA2V 0 ReportActive
                @MA2V MODE_Default SelectionMode
                @MA2V SELDIM_None SelectionDimensions
                @MA2V SEL_None SelectionAction
                @MA2V CR_EDIT CanvasCRHandler
                @Call(V) EventSetActive CanvasEventTable
                @CALL DisplayCanvas
             @ELSE
                @CALL CanvasClickEvent
             @ENDIF
             @CBREAK
          @CASE EV_CanvasKey
             @POPNULL
             @CALL CanvasKeyEvent
             @CBREAK
          @CASE EV_CanvasOpenMenuCtrl
             @POPNULL
             @PUSH EV_CanvasESC
             @CASE_FALLTHRU             
          @CASE EV_CanvasESC
             @POPNULL
             @IF_NEQ_AV 0 ReportActive
                @MA2V 0 ReportActive
                @CALL DisplayCanvas
             @ELSE
                @IF_NEQ_AV MODE_Default SelectionMode
                   @CALL CancelSelection
                   @CALL DisplayCanvas
                @ELSE
                   @Call(V) EventSetActive CtrlMenuEventTable
                   @CALL DisplayCanvas
                   @CALL DisplayMenu
                @ENDIF
             @ENDIF
             @CBREAK
          @CASE EV_CanvasDel
             @POPNULL
             @CALL CanvasDelEvent
             @CBREAK
          @CASE EV_CanvasNL
             @POPNULL
             @CALL CanvasCREvent
             @POPI CompletedAction
             @IF_NEQ_AV SEL_None CompletedAction
                @PUSHI CompletedAction
                @SWITCH
                @CASE SEL_DrawBox
                   @CBREAK
                @CASE SEL_NewInteger
                   @Call(V) FormEntryCreateFromSelection CompletedAction
                   @POPNULL
                   @CBREAK
                @CASE SEL_NewLong
                   @Call(V) FormEntryCreateFromSelection CompletedAction
                   @POPNULL
                   @CBREAK
                @CASE SEL_NewString
                   @Call(V) FormEntryCreateFromSelection CompletedAction
                   @POPNULL
                   @CBREAK
                @CASE SEL_NewTextBox
                   @Call(V) FormEntryCreateFromSelection CompletedAction
                   @POPNULL
                   @CBREAK
                @CDEFAULT
                   @CBREAK
                @ENDCASE
                @POPNULL
             @ENDIF
             @CALL DisplayCanvas
          @CBREAK
          @CASE EV_CanvasCR
             @POPNULL
             @CALL CanvasCREvent
             @POPI CompletedAction
             @IF_NEQ_AV SEL_None CompletedAction
                @PUSHI CompletedAction
                @SWITCH
                @CASE SEL_DrawBox
                   @CBREAK
                @CASE SEL_NewInteger
                   @Call(V) FormEntryCreateFromSelection CompletedAction
                   @POPNULL
                   @CBREAK
                @CASE SEL_NewLong
                   @Call(V) FormEntryCreateFromSelection CompletedAction
                   @POPNULL
                   @CBREAK
                @CASE SEL_NewString
                   @Call(V) FormEntryCreateFromSelection CompletedAction
                   @POPNULL
                   @CBREAK
                @CASE SEL_NewTextBox
                   @Call(V) FormEntryCreateFromSelection CompletedAction
                   @POPNULL
                   @CBREAK
                @CDEFAULT
                   @CBREAK
                @ENDCASE
                @POPNULL
             @ENDIF
             @CALL DisplayCanvas
          @CBREAK             
          @CDEFAULT
             @POPNULL
             @CBREAK          
          @ENDCASE
          @CALL StatusLine
       @ENDIF
   @ENDWHILE
   @CALL WinClear
@EndLocals
@POPRETURN
@RET

:Main .Org Main
   @CALL SetupStack
   @CALL SetupGlobals
   @CALL SetupEvents
   @CALL DisplayCanvas
   @CALL TermMouseEnable
   @CALL MainEventLoop
   @CALL TermMouseDisable
   @END


   
       

