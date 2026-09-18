#####################################################################
# widget.ld
#
# Common infrastructure for text-mode widgets.
#
# This library does not implement widget-specific drawing or input
# handling. Individual widget libraries embed WIDGET_HeaderSize bytes
# at offset zero of their object.
#
# Dependencies:
#
#     common.mc
#     heapmgr.ld
#     event.ld
#     screen.ld
#
#####################################################################

@FUNCTION WidgetFramework

#####################################################################
# Widget types
#
# Zero is reserved for an invalid or uninitialized widget.
#####################################################################

=WT_NONE          0
=WT_TEXTBOX       1
=WT_SELECTION     2
=WT_SCROLLBAR     3
=WT_MENU          4
=WT_BUTTON        5

#####################################################################
# Runtime state flags
#
# These describe the current state of the widget.
#####################################################################

=WF_VISIBLE       0x0001
=WF_ENABLED       0x0002
=WF_FOCUSED       0x0004
=WF_DIRTY         0x0008
=WF_CAPTURED      0x0010
=WF_DESTROYING    0x0020

#####################################################################
# Capability/behavior flags
#
# These describe what the widget is permitted to do.
#
# They are separate from runtime state so, for example, a widget can
# be focus-capable without currently having focus.
#####################################################################

=WO_FOCUSABLE     0x0001
=WO_MOUSE         0x0002
=WO_KEYBOARD      0x0004
=WO_BORDER        0x0008
=WO_READONLY      0x0010
=WO_TABSTOP       0x0020

#####################################################################
# Common widget header
#
# All widget objects must embed this structure at offset zero.
#
# Coordinates are inclusive:
#
#     Width  = X2 - X1 + 1
#     Height = Y2 - Y1 + 1
#
# EventBase reserves a widget-specific range of event IDs.
#
# ParentPtr is zero for a top-level widget.
#
# UserData is owned by the application. widget.ld never frees or
# interprets it.
#####################################################################

=WIDGET_Type_off          0
=WIDGET_State_off         2
=WIDGET_Options_off       4

=WIDGET_X1_off            6
=WIDGET_Y1_off            8
=WIDGET_X2_off           10
=WIDGET_Y2_off           12

=WIDGET_EventTable_off   14
=WIDGET_EventBase_off    16

=WIDGET_ParentPtr_off    18
=WIDGET_UserData_off     20

=WIDGET_HeaderSize       22

#####################################################################
# Common framework globals
#
# ActiveWidget receives keyboard input.
#
# CapturedWidget receives mouse drag/release events after beginning an
# interaction, even if the mouse moves outside its original rectangle.
#
# HoverWidget is optional bookkeeping. The first implementation does
# not require it, but reserving the global now avoids changing the
# framework interface later.
#####################################################################

:WidgetActivePtr    0
:WidgetCapturedPtr  0
:WidgetHoverPtr     0

#####################################################################
# Common semantic widget results
#
# Widget-specific handlers may return these to the application.
#
# Raw event IDs remain event.ld values. These values describe what a
# widget did after consuming a raw event.
#####################################################################

=WR_NONE               0
=WR_HANDLED             1
=WR_CHANGED             2
=WR_ACTIVATED           3
=WR_SELECTION_CHANGED   4
=WR_FOCUS_CHANGED       5
=WR_SCROLL_CHANGED      6
=WR_TEXT_CHANGED        7
=WR_CLOSE               8

#####################################################################
# WidgetHeaderInit
#
# WidgetHeaderInit(
#     WidgetPtr,
#     WidgetType,
#     State,
#     Options,
#     X1,
#     Y1,
#     X2,
#     Y2,
#     EventTable,
#     EventBase
# )
#
# Initializes only the common widget header.
#
# The caller allocates the complete widget object and initializes all
# widget-specific fields after this call.
#
# Expected initial state will normally be:
#
#     WF_VISIBLE | WF_ENABLED | WF_DIRTY
#
#####################################################################
@ENDFUNCTION

@FUNCTION WidgetHeaderInit
:WidgetHeaderInit
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local WidgetType
@Local State
@Local Options
@Local X1
@Local Y1
@Local X2
@Local Y2
@Local EventTable
@Local EventBase

   #
   # Arguments are popped in reverse push order.
   #
   @POPI EventBase
   @POPI EventTable
   @POPI Y2
   @POPI X2
   @POPI Y1
   @POPI X1
   @POPI Options
   @POPI State
   @POPI WidgetType
   @POPI WidgetPtr

   #
   # Replace @FILL_AT_V with the actual common.mc structure-write macro
   # if its spelling differs.
   #
   @FILL_AT_V WidgetPtr WIDGET_Type_off       WidgetType
   @FILL_AT_V WidgetPtr WIDGET_State_off      State
   @FILL_AT_V WidgetPtr WIDGET_Options_off    Options

   @FILL_AT_V WidgetPtr WIDGET_X1_off         X1
   @FILL_AT_V WidgetPtr WIDGET_Y1_off         Y1
   @FILL_AT_V WidgetPtr WIDGET_X2_off         X2
   @FILL_AT_V WidgetPtr WIDGET_Y2_off         Y2

   @FILL_AT_V WidgetPtr WIDGET_EventTable_off EventTable
   @FILL_AT_V WidgetPtr WIDGET_EventBase_off  EventBase

   @FILL_AT_V_A WidgetPtr WIDGET_ParentPtr_off 0
   @FILL_AT_V_A WidgetPtr WIDGET_UserData_off  0

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetGetType(WidgetPtr):(WidgetType)
#####################################################################

@FUNCTION WidgetGetType
:WidgetGetType
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr
   @GET_FROM WidgetPtr WIDGET_Type_off

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetGetState(WidgetPtr):(State)
#####################################################################

@FUNCTION WidgetGetState
:WidgetGetState
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr
   @GET_FROM WidgetPtr WIDGET_State_off

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetGetOptions(WidgetPtr):(Options)
#####################################################################

@FUNCTION WidgetGetOptions
:WidgetGetOptions
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr
   @GET_FROM WidgetPtr WIDGET_Options_off

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetSetStateBits(WidgetPtr, Bits)
#
# State = State | Bits
#####################################################################

@FUNCTION WidgetSetStateBits
:WidgetSetStateBits
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local Bits
@Local State

   @POPI Bits
   @POPI WidgetPtr

   @GET_FROM WidgetPtr WIDGET_State_off
   @POPI State

   @PUSHI State
   @ORI Bits
   @POPI State

   @FILL_AT_V WidgetPtr WIDGET_State_off State

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetClearStateBits(WidgetPtr, Bits)
#
# State = State & ~Bits
#####################################################################

@FUNCTION WidgetClearStateBits
:WidgetClearStateBits
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local Bits
@Local State

   @POPI Bits
   @POPI WidgetPtr

   @GET_FROM WidgetPtr WIDGET_State_off
   @POPI State

   @PUSHI Bits
   @NOT
   @ANDI State
   @POPI State

   @FILL_AT_V WidgetPtr WIDGET_State_off State

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetTestState(WidgetPtr, Bits):(boolean)
#
# Returns nonzero only if all requested bits are set.
#
#     (State & Bits) == Bits
#####################################################################

@FUNCTION WidgetTestState
:WidgetTestState
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local Bits

   @POPI Bits
   @POPI WidgetPtr

   @GET_FROM WidgetPtr WIDGET_State_off
   @ANDI Bits
   @IF_EQ_V Bits
      @POPNULL
      @PUSH 1
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF
   

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetTestOptions(WidgetPtr, Bits):(boolean)
#####################################################################

@FUNCTION WidgetTestOptions
:WidgetTestOptions
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local Bits

   @POPI Bits
   @POPI WidgetPtr

   @GET_FROM WidgetPtr WIDGET_Options_off
   @ANDI Bits
   @IF_EQ_V Bits
      @POPNULL
      @PUSH 1
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetInvalidate(WidgetPtr)
#
# Marks the widget as requiring redraw.
#####################################################################

@FUNCTION WidgetInvalidate
:WidgetInvalidate
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr
   @Call(VA) WidgetSetStateBits WidgetPtr WF_DIRTY

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetValidate(WidgetPtr)
#
# Clears the dirty flag after a successful redraw.
#####################################################################

@FUNCTION WidgetValidate
:WidgetValidate
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr
   @Call(VA) WidgetClearStateBits WidgetPtr WF_DIRTY

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetIsDirty(WidgetPtr):(boolean)
#####################################################################

@FUNCTION WidgetIsDirty
:WidgetIsDirty
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr
   @Call(VA) WidgetTestState WidgetPtr WF_DIRTY

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetShow(WidgetPtr)
#
# Showing a widget also invalidates it.
#####################################################################

@FUNCTION WidgetShow
:WidgetShow
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr

   @Call(VA) WidgetSetStateBits WidgetPtr WF_VISIBLE
   @Call(V) WidgetInvalidate WidgetPtr

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetHide(WidgetPtr)
#
# Hiding a widget releases focus and mouse capture if it owns either.
#
# The application or parent widget remains responsible for repainting
# whatever was underneath the hidden widget.
#####################################################################

@FUNCTION WidgetHide
:WidgetHide
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr

   @IF_EQ_VV WidgetActivePtr WidgetPtr
      @POPNULL
      @Call(V) WidgetReleaseFocus WidgetPtr
   @ELSE
      @POPNULL
   @ENDIF

   @IF_EQ_VV WidgetCapturedPtr WidgetPtr
      @POPNULL
      @Call(V) WidgetReleaseCapture WidgetPtr
   @ELSE
      @POPNULL
   @ENDIF

   @Call(VA) WidgetClearStateBits WidgetPtr WF_VISIBLE

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetEnable(WidgetPtr)
#####################################################################

@FUNCTION WidgetEnable
:WidgetEnable
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr

   @Call(VA) WidgetSetStateBits WidgetPtr WF_ENABLED
   @Call(V) WidgetInvalidate WidgetPtr

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetDisable(WidgetPtr)
#
# A disabled widget cannot retain focus or mouse capture.
#####################################################################

@FUNCTION WidgetDisable
:WidgetDisable
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr

   @IF_EQ_VV WidgetActivePtr WidgetPtr
      @POPNULL
      @Call(V) WidgetReleaseFocus WidgetPtr
   @ELSE
      @POPNULL
   @ENDIF

   @IF_EQ_VV WidgetCapturedPtr WidgetPtr
      @POPNULL
      @Call(V) WidgetReleaseCapture WidgetPtr
   @ELSE
      @POPNULL
   @ENDIF

   @Call(VA) WidgetClearStateBits WidgetPtr WF_ENABLED
   @Call(V) WidgetInvalidate WidgetPtr

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetCanReceiveInput(WidgetPtr):(boolean)
#
# Returns true when both WF_VISIBLE and WF_ENABLED are set.
#####################################################################

@FUNCTION WidgetCanReceiveInput
:WidgetCanReceiveInput
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr
   @Call(VA) WidgetTestState WidgetPtr WF_VISIBLE|WF_ENABLED

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetCanFocus(WidgetPtr):(boolean)
#
# A widget can receive focus only when:
#
#     - visible
#     - enabled
#     - marked focusable
#####################################################################

@FUNCTION WidgetCanFocus
:WidgetCanFocus
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local StateOK
@Local OptionOK

   @POPI WidgetPtr

   @Call(VA) WidgetTestState WidgetPtr WF_VISIBLE|WF_ENABLED
   @POPI StateOK

   @Call(VA) WidgetTestOptions WidgetPtr WO_FOCUSABLE
   @POPI OptionOK

   @PUSHI StateOK
   @ANDI OptionOK

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetSetFocus(WidgetPtr):(boolean)
#
# Returns:
#
#     1  focus was granted
#     0  widget cannot receive focus
#
# This function changes only common widget state. Widget-specific
# focus decoration is handled when each widget notices WF_DIRTY.
#####################################################################

@FUNCTION WidgetSetFocus
:WidgetSetFocus
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local OldWidget

   @POPI WidgetPtr

   @Call(V) WidgetCanFocus WidgetPtr

   @IF_ZERO
      @POPNULL
      @PUSH 0
   @ELSE
      @POPNULL

      @MV2V WidgetActivePtr OldWidget

      #
      # Already focused.
      #
      @IF_NEQ_VV OldWidget WidgetPtr
         #
         # Remove focus from the previous widget.
         #
         @IF_NEQ_AV 0 OldWidget
            @Call(VA) WidgetClearStateBits OldWidget WF_FOCUSED
            @Call(V) WidgetInvalidate OldWidget
         @ELSE
            @POPNULL
         @ENDIF

         #
         # Focus the new widget.
         #
         @MV2V WidgetPtr WidgetActivePtr
         @Call(VA) WidgetSetStateBits WidgetPtr WF_FOCUSED
         @Call(V) WidgetInvalidate WidgetPtr
      @ENDIF

      @PUSH 1
   @ENDIF

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetReleaseFocus(WidgetPtr)
#
# Releases focus only if WidgetPtr currently owns it.
#####################################################################

@FUNCTION WidgetReleaseFocus
:WidgetReleaseFocus
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr

   @IF_EQ_VV WidgetActivePtr WidgetPtr
      @MA2V 0 WidgetActivePtr
      @Call(VA) WidgetClearStateBits WidgetPtr WF_FOCUSED
      @Call(V) WidgetInvalidate WidgetPtr
   @ELSE
      @POPNULL
   @ENDIF

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetClearFocus()
#####################################################################

@FUNCTION WidgetClearFocus
:WidgetClearFocus
@PUSHRETURN
@Locals

@Local OldWidget

   @MV2V WidgetActivePtr OldWidget

   @IF_NEQ_AV 0 OldWidget
      @Call(V) WidgetReleaseFocus OldWidget
   @ENDIF

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetCaptureMouse(WidgetPtr):(boolean)
#
# Only visible and enabled widgets may capture the mouse.
#
# The first implementation permits only one captured widget.
#####################################################################

@FUNCTION WidgetCaptureMouse
:WidgetCaptureMouse
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local OldWidget

   @POPI WidgetPtr

   @Call(V) WidgetCanReceiveInput WidgetPtr

   @IF_ZERO
      @POPNULL
      @PUSH 0
   @ELSE
      @POPNULL

      @MV2V WidgetCapturedPtr OldWidget

      @IF_NEQ_AV 0 OldWidget
         @Call(VA) WidgetClearStateBits OldWidget WF_CAPTURED
      @ENDIF

      @MV2V WidgetPtr WidgetCapturedPtr
      @Call(VA) WidgetSetStateBits WidgetPtr WF_CAPTURED

      @PUSH 1
   @ENDIF

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetReleaseCapture(WidgetPtr)
#
# Releases capture only if WidgetPtr currently owns it.
#####################################################################

@FUNCTION WidgetReleaseCapture
:WidgetReleaseCapture
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr

   @IF_EQ_VV WidgetCapturedPtr WidgetPtr
      @MA2V 0 WidgetCapturedPtr
      @Call(VA) WidgetClearStateBits WidgetPtr WF_CAPTURED
   @ENDIF

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetGetWidth(WidgetPtr):(Width)
#
# Coordinates are inclusive.
#####################################################################

@FUNCTION WidgetGetWidth
:WidgetGetWidth
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local X1

   @POPI WidgetPtr

   @GET_FROM WidgetPtr WIDGET_X1_off
   @POPI X1

   @GET_FROM WidgetPtr WIDGET_X2_off
   @SUBI X1
   @ADD 1

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetGetHeight(WidgetPtr):(Height)
#####################################################################

@FUNCTION WidgetGetHeight
:WidgetGetHeight
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local Y1

   @POPI WidgetPtr

   @GET_FROM WidgetPtr WIDGET_Y1_off
   @POPI Y1

   @GET_FROM WidgetPtr WIDGET_Y2_off
   @SUBI Y1
   @ADD 1

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetContainsXY(WidgetPtr, X, Y):(boolean)
#
# Boundary coordinates are included.
#####################################################################

@FUNCTION WidgetContainsXY
:WidgetContainsXY
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local X
@Local Y
@Local X1
@Local Y1
@Local X2
@Local Y2

   @POPI Y
   @POPI X
   @POPI WidgetPtr

   @GET_FROM WidgetPtr WIDGET_X1_off
   @POPI X1

   @GET_FROM WidgetPtr WIDGET_Y1_off
   @POPI Y1

   @GET_FROM WidgetPtr WIDGET_X2_off
   @POPI X2

   @GET_FROM WidgetPtr WIDGET_Y2_off
   @POPI Y2

   #
   # Default result is false. Each failed range test exits with zero.
   #
   @PUSHI X
   @PUSHI X1
   @IF_LT
      @POPNULL
      @PUSH 0
   @ELSE
      @POPNULL

      @PUSHI X
      @PUSHI X2
      @IF_GT
         @POPNULL
         @PUSH 0
      @ELSE
         @POPNULL

         @PUSHI Y
         @PUSHI Y1
         @IF_LT
            @POPNULL
            @PUSH 0
         @ELSE
            @POPNULL

            @PUSHI Y
            @PUSHI Y2
            @IF_GT
               @POPNULL
               @PUSH 0
            @ELSE
               @POPNULL
               @PUSH 1
            @ENDIF
         @ENDIF
      @ENDIF
   @ENDIF

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetSetRect(WidgetPtr, X1, Y1, X2, Y2)
#
# Changes geometry and marks the widget dirty.
#
# Validation such as minimum widget-specific dimensions belongs in
# the widget-specific library.
#####################################################################

@FUNCTION WidgetSetRect
:WidgetSetRect
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local X1
@Local Y1
@Local X2
@Local Y2

   @POPI Y2
   @POPI X2
   @POPI Y1
   @POPI X1
   @POPI WidgetPtr

   @FILL_AT_V WidgetPtr WIDGET_X1_off X1
   @FILL_AT_V WidgetPtr WIDGET_Y1_off Y1
   @FILL_AT_V WidgetPtr WIDGET_X2_off X2
   @FILL_AT_V WidgetPtr WIDGET_Y2_off Y2

   @Call(V) WidgetInvalidate WidgetPtr

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetSetParent(WidgetPtr, ParentPtr)
#####################################################################

@FUNCTION WidgetSetParent
:WidgetSetParent
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local ParentPtr

   @POPI ParentPtr
   @POPI WidgetPtr

   @FILL_AT_V WidgetPtr WIDGET_ParentPtr_off ParentPtr

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetSetUserData(WidgetPtr, UserData)
#####################################################################

@FUNCTION WidgetSetUserData
:WidgetSetUserData
@PUSHRETURN
@Locals

@Local WidgetPtr
@Local UserData

   @POPI UserData
   @POPI WidgetPtr

   @FILL_AT_V WidgetPtr WIDGET_UserData_off UserData

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetGetUserData(WidgetPtr):(UserData)
#####################################################################

@FUNCTION WidgetGetUserData
:WidgetGetUserData
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr
   @GET_FROM WidgetPtr WIDGET_UserData_off

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

#####################################################################
# WidgetPrepareDestroy(WidgetPtr)
#
# Common first stage of widget destruction.
#
# Widget-specific destructors should:
#
#     1. Call WidgetPrepareDestroy.
#     2. Remove their registered event entries.
#     3. Free widget-owned subordinate allocations.
#     4. Free the widget object itself.
#
# ParentPtr and UserData are not owned by the widget and are not freed.
#####################################################################

@FUNCTION WidgetPrepareDestroy
:WidgetPrepareDestroy
@PUSHRETURN
@Locals

@Local WidgetPtr

   @POPI WidgetPtr

   @Call(VA) WidgetSetStateBits WidgetPtr WF_DESTROYING

   @PUSHI WidgetActivePtr
   @PUSHI WidgetPtr
   @IF_EQ
      @POPNULL
      @Call(V) WidgetReleaseFocus WidgetPtr
   @ELSE
      @POPNULL
   @ENDIF

   @PUSHI WidgetCapturedPtr
   @PUSHI WidgetPtr
   @IF_EQ
      @POPNULL
      @Call(V) WidgetReleaseCapture WidgetPtr
   @ELSE
      @POPNULL
   @ENDIF

   @PUSHI WidgetHoverPtr
   @PUSHI WidgetPtr
   @IF_EQ
      @POPNULL
      @MA2V 0 WidgetHoverPtr
   @ELSE
      @POPNULL
   @ENDIF

@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

