############################################################
# flightsim.asm
#
# Event-driven demo for the paintui2-generated flightsim.inc
# panel. The lower-half controls handle thrust, stick/rudder,
# and flaps. Background clicks are ignored.
############################################################

I common.mc
L softstack.ld
L mul.ld
L heapmgr.ld
L screen.ld
L event.ld
L display.ld

############################################################
# Event IDs
############################################################

=EV_EXIT       1
=EV_BG_CLICK   2
=EV_THRUST     10
=EV_STICK      11
=EV_FLAPS      12
=EV_AILERON    13
=EV_NOOP       14
=EV_SIMTICK    15

############################################################
# Program globals
############################################################

:Columns         0
:Rows            0
:EventID         0
:EventTable      0
:Running         0
:ObjectSize      0
:HEAP_ID         0
:SoftStackStart  0
:SoftStackEnd    0

# Display backing values used by flightsim.inc.
:Altitude        1000
:Heading         0
:Speed           120
:Roll            0
:Bank            0
:TurnRate        0
:VertVel         0
:Engine          1
:Fuel            100
:PanelText       "\0"
:Pitch           0

:RegType         0
:RegX1           0
:RegY1           0
:RegX2           0
:RegY2           0
:RegEventID      0
:RegIndex        0
:RegSpot         0
:RegTableBytes   0
:DirtyFieldPtr   0
:DirtyFlags      0
:ThrustY        15
:RudderX        68
:FlapY          18
:AileronX       68
:StickX         39
:StickY         18
:OldStickX      39
:OldStickY      18
:ControlScratch 0
:TimerOneSec    1
:TimerRepeat    1
:ThrustValue    96
:RudderValue    0
:AileronValue   0
:PitchValue     0
:PosX           0
:PosY           0
:ClickX         0
:ClickY         0
:SimSeconds     0
:MoveStep       0
:MoveStepSpeed  -1
:SpeedDelta     0
:SpeedDrag      0
:FlightLift      0
:FlightFlaps     0
:FlightAbs       0
:MoveAngle      0
:MoveDX         0
:MoveDY         0
:MoveProduct    0
:MoveComponent  0
:MoveRemX       0
:MoveRemY       0
:MoveTableValue 0
:MoveIndex      0
:ScaleInput      0
:ScaleQuotient   0
:HorizonIndex    0
:HorizonBest     0
:HorizonBestIndex 0
:HorizonDelta    0
:HorizonBlockPtr 0
:HorizonRowPtr   0
:HorizonRowIndex 0
:HorizonY        0
:HorizonDrawValid 0
:HorizonLastBlockPtr 0
:HorizonLastRowIndex 0
:LandmarkIndex   0
:LandmarkDX      0
:LandmarkDY      0
:LandmarkSin     0
:LandmarkCos     0
:LandmarkForward 0
:LandmarkRight   0
:LandmarkWidth   0
:LandmarkAbs     0
:LandmarkScreenX 0
:LandmarkScreenY 0
:LandmarkRowPtr  0
:LandmarkChar    0
:LandmarkDivisor 0
:LandmarkLetter  0
:LandmarkMulA    0
:LandmarkMulB    0
:LandmarkMulSign 0
:LandmarkMulIndex 0
:LandmarkMulResult 0
:LandmarkOldX
   0 0 0 0 0
:LandmarkOldY
   0 0 0 0 0
# Ridge vertices: local map X/Y and elevation in feet.
:RidgeX
   -120 -85 -50 -20 10 40 75 110
:RidgeY
   -230 -245 -250 -270 -265 -250 -240 -230
:RidgeZ
   1450 1750 2100 1850 2400 1950 1650 1400
:RidgeIndex 0
:RidgeForward 0
:RidgeRight 0
:RidgeSX 0
:RidgeSY 0
:RidgePrevX 0
:RidgePrevY 0
:RidgePrevValid 0
:RidgeValid 0
:RidgeShift 0
:RidgeAbs 0
:RidgeDeltaZ 0
:RidgeGlyph "*\0"
:LandmarkLetters
   65 66 67 68 69
:LandmarkMapX
   0 -60 95 0 240
:LandmarkMapY
   -160 -260 -360 -560 -420

:FlightSinTable
   0 4 9 13 18 22 27 31 36 40 44 49 53
   58 62 66 71 75 79 83 88 92 96 100 104 108
   112 116 120 124 128 132 136 139 143 147 150 154 158
   161 165 168 171 175 178 181 184 187 190 193 196 199
   202 204 207 210 212 215 217 219 222 224 226 228 230
   232 234 236 237 239 241 242 243 245 246 247 248 249
   250 251 252 253 254 254 255 255 255 255 255 255 255

L flightsim.inc
I horizon_pointer_blocks.inc

############################################################
# Helpers
############################################################




:GrowEventTable
   # EventRecordSize is 12, so 16 records is a fixed 192 bytes.
   # Avoid MUL here because this runs during startup before events are active.
   @PUSH 192
   @ADD EventTableHeaderSize
   @POPI RegTableBytes

   @PUSHI HEAP_ID
   @PUSHI EventTable
   @PUSHI RegTableBytes
   @CALL HeapResizeObject
   @IF_ULT_A 100
      @PRT "ERR:MEM"
      @END
   @ENDIF
   @POPI EventTable
   @MV2V EventTable ActiveEventTable
   @Call(V) EventSetActive EventTable
   @FILL_AT_A ActiveEventTable EventMaxUsedHeadOff 16
@RET

:AddEventFromVars
   @GET_FROM ActiveEventTable EventUsedHeadOff
   @POPI RegIndex

   # Offset = RegIndex * 12 = (RegIndex << 3) + (RegIndex << 2).
   # This keeps event registration out of the general MUL routine.
   @PUSHI RegIndex
   @SHL
   @SHL
   @POPI RegSpot
   @PUSHI RegIndex
   @SHL
   @SHL
   @SHL
   @ADDI RegSpot
   @ADDI ActiveEventTable
   @ADD EventTableHeaderSize
   @POPI RegSpot

   @INCI RegIndex
   @FILL_AT_V ActiveEventTable EventUsedHeadOff RegIndex

   @PUSHI RegType
   @SWITCH
   @CASE_RANGE 1 MouseEvent
      @POPNULL
      @QuickMinI RegX1 RegX2
      @QuickMinI RegY1 RegY2
      @EncodeLoc RegX1 RegY1
      @FILL_AT_S RegSpot MouseMinLocOff
      @EncodeLoc RegX2 RegY2
      @FILL_AT_S RegSpot MouseMaxLocOff
      @FILL_AT_V RegSpot EventIDOff RegEventID
      @FILL_AT_V RegSpot EventTypeOff RegType
      @CBREAK
   @CASE KeyRangeEvent
      @POPNULL
      @QuickMinI RegX1 RegY1
      @FILL_AT_V RegSpot EventTypeOff RegType
      @FILL_AT_V RegSpot KeyASCIIStartOff RegX1
      @FILL_AT_V RegSpot KeyASCIIEndOff RegY1
      @FILL_AT_V RegSpot EventIDOff RegEventID
      @CBREAK
   @CASE TimerEvent
      @POPNULL
      @FILL_AT_V RegSpot EventTypeOff RegType
      @GETTIME
      @POPNULL
      @FILL_AT_S RegSpot TimerStartOff
      @FILL_AT_V RegSpot TimerDurOff RegX1
      @FILL_AT_V RegSpot TimerRepOff RegY1
      @FILL_AT_V RegSpot EventIDOff RegEventID
      @CBREAK
   @CDEFAULT
      @POPNULL
      @PRT "ERR:ETY"
      @END
      @CBREAK
   @ENDCASE
@RET

:MarkAllFieldsDirty
   @Call(V) DisplayMarkFormDirty DisplayRoot
   @GET_FROM DisplayRoot FORM_FIRST_FIELD
   @POPI DirtyFieldPtr
   @PUSHI DirtyFieldPtr
   @WHILE_NOTZERO
      @POPNULL
      @GET_FROM DirtyFieldPtr FIELD_FLAGS
      @OR FIELD_FLAG_DIRTY
      @POPI DirtyFlags
      @FILL_AT_V DirtyFieldPtr FIELD_FLAGS DirtyFlags
      @GET_FROM DirtyFieldPtr FIELD_NEXT
      @POPI DirtyFieldPtr
      @PUSHI DirtyFieldPtr
   @ENDWHILE
   @POPNULL
@RET


:RefreshDisplay
   @CALL DisplayUpdate
@RET

:DrawHorizon
   # Select the nearest precomputed bank block, including negative banks.
   @MA2V 32767 HorizonBest
   @MA2V 0 HorizonBestIndex
   @ForIA2B HorizonIndex 0 29
      @PUSHI HorizonIndex
      @SHL
      @ADD HorizonAngles
      @PUSHS
      @SUBI Bank
      @POPI HorizonDelta
      @PUSHI HorizonDelta
      @IF_LT_A 0
         @POPNULL
         @PUSH 0
         @SUBI HorizonDelta
         @POPI HorizonDelta
      @ELSE
         @POPNULL
      @ENDIF
      @PUSHI HorizonDelta
      @IF_ULT_V HorizonBest
         @POPNULL
         @MV2V HorizonDelta HorizonBest
         @MV2V HorizonIndex HorizonBestIndex
      @ELSE
         @POPNULL
      @ENDIF
   @Next HorizonIndex

   @PUSHI HorizonBestIndex
   @SHL
   @ADD HorizonBankPointers
   @PUSHS
   @POPI HorizonBlockPtr

   # The centered 11-row slice begins at template row 4 for pitch 0.
   @PUSH 4
   @SUBI PitchValue
   @POPI HorizonRowIndex

   # Both values identify the 11 visible rows. Skip terminal output when
   # the same bank template and pitch slice were drawn last time.
   @PUSHI HorizonDrawValid
   @IF_NOTZERO
      @POPNULL
      @IF_EQ_VV HorizonBlockPtr HorizonLastBlockPtr
         @IF_EQ_VV HorizonRowIndex HorizonLastRowIndex
            @RET
         @ENDIF
      @ENDIF
   @ELSE
      @POPNULL
   @ENDIF
   @MV2V HorizonBlockPtr HorizonLastBlockPtr
   @MV2V HorizonRowIndex HorizonLastRowIndex
   @MA2V 1 HorizonDrawValid

   @ForIA2B HorizonY 2 13
      @PUSHI HorizonRowIndex
      @SHL
      @ADDI HorizonBlockPtr
      @PUSHS
      @POPI HorizonRowPtr
      @Call(AV) WinCursor 22 HorizonY
      @PRTSI HorizonRowPtr
      @INCI HorizonRowIndex
   @Next HorizonY
@RET

############################################################
# Fixed ground landmarks in the horizon viewport
############################################################

:LandmarkScaleTrig
   # Convert a 0..255 sine-table entry to a rounded 0..16 component.
   # Preserve the return address because the result stays on the stack.
   @PUSHRETURN
   @PUSHI MoveTableValue
   @ADD 8
   @SHR @SHR @SHR @SHR
   @POPRETURN
@RET

:LandmarkHeadingBasis
   # Forward=(sin heading,-cos heading), right=(cos heading,sin heading).
   # Components are signed and scaled by 16.
   @PUSHI Heading
   @IF_ULT_A 90
      @POPNULL
      @MV2V Heading MoveAngle
      @CALL FlightLookupSin
      @CALL LandmarkScaleTrig
      @POPI LandmarkSin
      @CALL FlightLookupCos
      @CALL LandmarkScaleTrig
      @POPI LandmarkCos
   @ELSE
      @POPNULL
      @PUSHI Heading
      @IF_ULT_A 180
         @POPNULL
         @PUSHI Heading @SUB 90 @POPI MoveAngle
         @CALL FlightLookupCos
         @CALL LandmarkScaleTrig
         @POPI LandmarkSin
         @CALL FlightLookupSin
         @CALL LandmarkScaleTrig
         @POPI LandmarkCos
         @PUSH 0 @SUBI LandmarkCos @POPI LandmarkCos
      @ELSE
         @POPNULL
         @PUSHI Heading
         @IF_ULT_A 270
            @POPNULL
            @PUSHI Heading @SUB 180 @POPI MoveAngle
            @CALL FlightLookupSin
            @CALL LandmarkScaleTrig
            @POPI LandmarkSin
            @PUSH 0 @SUBI LandmarkSin @POPI LandmarkSin
            @CALL FlightLookupCos
            @CALL LandmarkScaleTrig
            @POPI LandmarkCos
            @PUSH 0 @SUBI LandmarkCos @POPI LandmarkCos
         @ELSE
            @POPNULL
            @PUSHI Heading @SUB 270 @POPI MoveAngle
            @CALL FlightLookupCos
            @CALL LandmarkScaleTrig
            @POPI LandmarkSin
            @PUSH 0 @SUBI LandmarkSin @POPI LandmarkSin
            @CALL FlightLookupSin
            @CALL LandmarkScaleTrig
            @POPI LandmarkCos
         @ENDIF
      @ENDIF
   @ENDIF
@RET

# Multiply a signed map delta by a signed heading factor (-16..16).
:LandmarkMultiply
   @MA2V 0 LandmarkMulResult
   @MA2V 0 LandmarkMulSign
   @PUSHI LandmarkMulB
   @IF_LT_A 0
      @POPNULL
      @MA2V 1 LandmarkMulSign
      @PUSH 0 @SUBI LandmarkMulB @POPI LandmarkMulB
   @ELSE
      @POPNULL
   @ENDIF
   @ForIA2V LandmarkMulIndex 0 LandmarkMulB
      @PUSHI LandmarkMulResult
      @ADDI LandmarkMulA
      @POPI LandmarkMulResult
   @Next LandmarkMulIndex
   @PUSHI LandmarkMulSign
   @IF_NOTZERO
      @POPNULL
      @PUSH 0 @SUBI LandmarkMulResult @POPI LandmarkMulResult
   @ELSE
      @POPNULL
   @ENDIF
@RET

:LandmarkBackgroundChar
   # Return the current horizon character at LandmarkScreenX/Y.
   @PUSHI LandmarkScreenY
   @ADD 2
   @SUBI PitchValue
   @SHL
   @ADDI HorizonBlockPtr
   @PUSHS
   @POPI LandmarkRowPtr
   @PUSHI LandmarkScreenX
   @SUB 22
   @ADDI LandmarkRowPtr
   @PUSHS
   @AND 0xff
   @POPI LandmarkChar
@RET

:LandmarkEraseOld
   # Restore old letter cells from the CURRENT horizon block. This also
   # works when DrawHorizon changed the background earlier this frame.
   @ForIA2B LandmarkIndex 0 5
      @PUSHI LandmarkIndex @SHL @ADD LandmarkOldX @PUSHS
      @POPI LandmarkScreenX
      @PUSHI LandmarkScreenX
      @IF_NOTZERO
         @POPNULL
         @PUSHI LandmarkIndex @SHL @ADD LandmarkOldY @PUSHS
         @POPI LandmarkScreenY
         @CALL LandmarkBackgroundChar
         @Call(VV) WinCursor LandmarkScreenX LandmarkScreenY
         @PRTCHI LandmarkChar
         @PUSH 0
         @PUSHI LandmarkIndex @SHL @ADD LandmarkOldX
         @POPS
      @ELSE
         @POPNULL
      @ENDIF
   @Next LandmarkIndex
@RET

:LandmarkDrawOne
   # Signed 16-bit coordinates are enough for this small local map. Cull
   # deltas before multiplication so the scaled dot products cannot wrap.
   @PUSHI LandmarkIndex @SHL @ADD LandmarkMapX @PUSHS
   @SUBI PosX
   @POPI LandmarkDX
   @PUSHI LandmarkIndex @SHL @ADD LandmarkMapY @PUSHS
   @SUBI PosY
   @POPI LandmarkDY
   @PUSHI LandmarkDX
   @IF_LT_A -640
      @POPNULL
      @RET
   @ENDIF
   @POPNULL
   @PUSHI LandmarkDX
   @IF_GT_A 640
      @POPNULL
      @RET
   @ENDIF
   @POPNULL
   @PUSHI LandmarkDY
   @IF_LT_A -640
      @POPNULL
      @RET
   @ENDIF
   @POPNULL
   @PUSHI LandmarkDY
   @IF_GT_A 640
      @POPNULL
      @RET
   @ENDIF
   @POPNULL

   # Forward = dx*sin - dy*cos; right = dx*cos + dy*sin.
   # Both distances remain scaled by 16.
   @MV2V LandmarkDX LandmarkMulA
   @MV2V LandmarkSin LandmarkMulB
   @CALL LandmarkMultiply
   @MV2V LandmarkMulResult LandmarkForward
   @MV2V LandmarkDY LandmarkMulA
   @MV2V LandmarkCos LandmarkMulB
   @CALL LandmarkMultiply
   @MV2V LandmarkMulResult LandmarkAbs
   @PUSHI LandmarkForward @SUBI LandmarkAbs
   @POPI LandmarkForward
   @MV2V LandmarkDX LandmarkMulA
   @MV2V LandmarkCos LandmarkMulB
   @CALL LandmarkMultiply
   @MV2V LandmarkMulResult LandmarkRight
   @MV2V LandmarkDY LandmarkMulA
   @MV2V LandmarkSin LandmarkMulB
   @CALL LandmarkMultiply
   @PUSHI LandmarkMulResult
   @ADDI LandmarkRight
   @POPI LandmarkRight

   # Five-point footprint: tip (0,0), shoulders (+/-30,60),
   # far corners (+/-165,600). Ignore the first 16 ground units.
   @PUSHI LandmarkForward
   @IF_LT_A 256
      @POPNULL
      @RET
   @ENDIF
   @POPNULL
   @PUSHI LandmarkForward
   @IF_GT_A 9600
      @POPNULL
      @RET
   @ENDIF
   @POPNULL
   @PUSHI LandmarkForward
   @IF_ULT_A 960
      @POPNULL
      @PUSHI LandmarkForward @SHR @POPI LandmarkWidth
   @ELSE
      @POPNULL
      @PUSHI LandmarkForward @SUB 960
      @SHR @SHR @ADD 480
      @POPI LandmarkWidth
   @ENDIF
   @MV2V LandmarkRight LandmarkAbs
   @PUSHI LandmarkAbs
   @IF_LT_A 0
      @POPNULL
      @PUSH 0 @SUBI LandmarkAbs @POPI LandmarkAbs
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI LandmarkAbs
   @IF_UGT_V LandmarkWidth
      @POPNULL
      @RET
   @ENDIF
   @POPNULL

   # Scale sideways position into the 39-column viewport (center X=41).
   @PUSHI LandmarkWidth @SHR @SHR @SHR @SHR
   @POPI LandmarkDivisor
   @PUSHI LandmarkAbs @PUSHI LandmarkDivisor @CALL DIVU
   @POPI LandmarkScreenX
   @POPNULL
   @PUSHI LandmarkRight
   @IF_LT_A 0
      @POPNULL
      @PUSH 41 @SUBI LandmarkScreenX @POPI LandmarkScreenX
   @ELSE
      @POPNULL
      @PUSH 41 @ADDI LandmarkScreenX @POPI LandmarkScreenX
   @ENDIF

   # Coarse distance bands place distant letters close to the horizon.
   @MA2V 12 LandmarkScreenY
   @PUSHI LandmarkForward
   @IF_UGE_A 8000
      @POPNULL
      @MA2V 8 LandmarkScreenY
   @ELSE
      @POPNULL
      @PUSHI LandmarkForward
      @IF_UGE_A 5600
         @POPNULL
         @MA2V 9 LandmarkScreenY
      @ELSE
         @POPNULL
         @PUSHI LandmarkForward
         @IF_UGE_A 3200
            @POPNULL
            @MA2V 10 LandmarkScreenY
         @ELSE
            @POPNULL
            @PUSHI LandmarkForward
            @IF_UGE_A 1600
               @POPNULL
               @MA2V 11 LandmarkScreenY
            @ELSE
               @POPNULL
            @ENDIF
         @ENDIF
      @ENDIF
   @ENDIF

:LandmarkFindGround
   @CALL LandmarkBackgroundChar
   @PUSHI LandmarkChar
   @IF_EQ_A 46
      @POPNULL
      @JMP LandmarkPlace
   @ENDIF
   @POPNULL
   @INCI LandmarkScreenY
   @PUSHI LandmarkScreenY
   @IF_UGT_A 12
      @POPNULL
      @RET
   @ENDIF
   @POPNULL
   @JMP LandmarkFindGround

:LandmarkPlace
   @PUSHI LandmarkIndex @SHL @ADD LandmarkLetters @PUSHS
   @POPI LandmarkLetter
   @Call(VV) WinCursor LandmarkScreenX LandmarkScreenY
   @PRTCHI LandmarkLetter
   @PUSHI LandmarkScreenX
   @PUSHI LandmarkIndex @SHL @ADD LandmarkOldX
   @POPS
   @PUSHI LandmarkScreenY
   @PUSHI LandmarkIndex @SHL @ADD LandmarkOldY
   @POPS
@RET

:DrawMapObjects
   @CALL LandmarkEraseOld
   @CALL LandmarkHeadingBasis
   @ForIA2B LandmarkIndex 0 5
      @CALL LandmarkDrawOne
   @Next LandmarkIndex
@RET

# Eight-vertex terrain silhouette. Projection uses coarse depth bands;
# no multiplication or division is done for screen scaling.
:DrawRidge
   @MA2V 0 RidgePrevValid
   @CALL LandmarkHeadingBasis
   @ForIA2B RidgeIndex 0 8
      @MA2V 0 RidgeValid
      @PUSHI RidgeIndex @SHL @ADD RidgeX @PUSHS
      @SUBI PosX @POPI LandmarkDX
      @PUSHI RidgeIndex @SHL @ADD RidgeY @PUSHS
      @SUBI PosY @POPI LandmarkDY
      @PUSHI LandmarkDX
      @IF_LT_A -400
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL
      @PUSHI LandmarkDX
      @IF_GT_A 400
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL
      @PUSHI LandmarkDY
      @IF_LT_A -400
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL
      @PUSHI LandmarkDY
      @IF_GT_A 400
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL

      @MV2V LandmarkDX LandmarkMulA
      @MV2V LandmarkSin LandmarkMulB
      @CALL LandmarkMultiply
      @MV2V LandmarkMulResult RidgeForward
      @MV2V LandmarkDY LandmarkMulA
      @MV2V LandmarkCos LandmarkMulB
      @CALL LandmarkMultiply
      @PUSHI RidgeForward @SUBI LandmarkMulResult @POPI RidgeForward
      @MV2V LandmarkDX LandmarkMulA
      @MV2V LandmarkCos LandmarkMulB
      @CALL LandmarkMultiply
      @MV2V LandmarkMulResult RidgeRight
      @MV2V LandmarkDY LandmarkMulA
      @MV2V LandmarkSin LandmarkMulB
      @CALL LandmarkMultiply
      @PUSHI RidgeRight @ADDI LandmarkMulResult @POPI RidgeRight

      @PUSHI RidgeForward
      @IF_LT_A 256
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL
      @PUSHI RidgeForward
      @IF_GT_A 6400
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL

      # Nearby points spread wider; distant points compress.
      @MA2V 7 RidgeShift
      @PUSHI RidgeForward
      @IF_UGE_A 1600
         @POPNULL @MA2V 8 RidgeShift
      @ELSE
         @POPNULL
      @ENDIF
      @PUSHI RidgeForward
      @IF_UGE_A 3200
         @POPNULL @MA2V 9 RidgeShift
      @ELSE
         @POPNULL
      @ENDIF
      @MV2V RidgeRight RidgeAbs
      @PUSHI RidgeAbs
      @IF_LT_A 0
         @POPNULL @PUSH 0 @SUBI RidgeAbs @POPI RidgeAbs
      @ELSE
         @POPNULL
      @ENDIF
      @PUSHI RidgeAbs
      @PUSHI RidgeShift
      @CALL RidgeShiftRight
      @POPI RidgeSX
      @PUSHI RidgeRight
      @IF_LT_A 0
         @POPNULL @PUSH 41 @SUBI RidgeSX @POPI RidgeSX
      @ELSE
         @POPNULL @PUSH 41 @ADDI RidgeSX @POPI RidgeSX
      @ENDIF

      @PUSHI RidgeIndex @SHL @ADD RidgeZ @PUSHS
      @SUBI Altitude @POPI RidgeDeltaZ
      @MV2V RidgeDeltaZ RidgeAbs
      @PUSHI RidgeAbs
      @IF_LT_A 0
         @POPNULL @PUSH 0 @SUBI RidgeAbs @POPI RidgeAbs
      @ELSE
         @POPNULL
      @ENDIF
      @PUSHI RidgeAbs
      @PUSHI RidgeShift
      @CALL RidgeShiftRight
      @POPI RidgeSY
      @PUSHI RidgeDeltaZ
      @IF_LT_A 0
         @POPNULL @PUSH 7 @ADDI RidgeSY @POPI RidgeSY
      @ELSE
         @POPNULL @PUSH 7 @SUBI RidgeSY @POPI RidgeSY
      @ENDIF
      @PUSHI RidgeSY @SUBI PitchValue @POPI RidgeSY

      # WinPlot does not clip; only fully visible segments are passed in.
      @PUSHI RidgeSX
      @IF_LT_A 22
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL
      @PUSHI RidgeSX
      @IF_GT_A 60
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL
      @PUSHI RidgeSY
      @IF_LT_A 2
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL
      @PUSHI RidgeSY
      @IF_GT_A 12
         @POPNULL @JMP RidgeNext
      @ENDIF
      @POPNULL
      @MA2V 1 RidgeValid
      @PUSHI RidgePrevValid
      @IF_NOTZERO
         @POPNULL
         @PUSHI RidgePrevX @PUSHI RidgePrevY
         @PUSHI RidgeSX @PUSHI RidgeSY
         @PUSH RidgeGlyph @CALL WinPlot
      @ELSE
         @POPNULL
      @ENDIF
      @MV2V RidgeSX RidgePrevX
      @MV2V RidgeSY RidgePrevY
   :RidgeNext
      @MV2V RidgeValid RidgePrevValid
   @Next RidgeIndex
@RET

# Input stack: positive magnitude, shift count (7..9). Output: quotient.
:RidgeShiftRight
   @PUSHRETURN
   @POPI RidgeShift
   @PUSHI RidgeShift
   @IF_EQ_A 7
      @POPNULL @SHRN 7
   @ELSE
      @POPNULL
      @PUSHI RidgeShift
      @IF_EQ_A 8
         @POPNULL @SHRN 8
      @ELSE
         @POPNULL @SHRN 9
      @ENDIF
   @ENDIF
   @POPRETURN
@RET

############################################################
# Interface Scaling Helpers
############################################################

:ScaleInputBy5Over7
   # Input:  positive delta on stack.
   # Output: rounded-down delta * 5 / 7 on stack.
   #
   # Cost note: avoid library DIVU/MUL in mouse handling. Deltas are tiny,
   # so divide by 7 with repeated subtraction after x*5 via shifts/add.
   @PUSHRETURN
   @POPI ScaleInput
   @PUSHI ScaleInput
   @DUP
   @SHL
   @SHL
   @ADDS
   @POPI ScaleInput
   @MA2V 0 ScaleQuotient
   @WHEN
      @PUSHI ScaleInput
      @IF_UGE_A 7
         @POPNULL
         @PUSH 1
      @ELSE
         @POPNULL
         @PUSH 0
      @ENDIF
   @DO_NOTZERO
      @POPNULL
      @PUSHI ScaleInput
      @SUB 7
      @POPI ScaleInput
      @INCI ScaleQuotient
   @ENDWHEN
   @POPNULL
   @PUSHI ScaleQuotient
   @POPRETURN
@RET

############################################################
# Flight Model
#
# All simulation state derivation should live in this section.
# UI handlers update control positions only, then call the control
# sync function below. Timer events call FlightCalculateTick.
############################################################

:FlightControlsToDisplayValues
   # Convert rendered control positions into retained flight controls.
   # RudderX and AileronX center at 68. Their commands are signed
   # around zero so the tick math can use them directly.
   @PUSHI RudderX
   @SUB 68
   @POPI RudderValue

   @PUSHI AileronX
   @SUB 68
   @POPI AileronValue

   # Pitch still follows the stick directly. Roll and Bank are flight state
   # and are updated once per simulation tick.
   @MV2V PitchValue Pitch
@RET

:FlightUpdateRollRate
   # Aileron commands a roll rate (-4..4 degrees/tick). Move the actual
   # rate one degree toward the command each tick, including when centered.
   @PUSHI Roll
   @IF_LT_V AileronValue
      @POPNULL
      @INCI Roll
   @ELSE
      @POPNULL
      @PUSHI Roll
      @IF_GT_V AileronValue
         @POPNULL
         @DECI Roll
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF
@RET

:FlightUpdateBank
   # Bank persists when the aileron is centered; opposite aileron rolls it
   # out. Limit the angle so drag, lift loss, and turn rate remain bounded.
   @PUSHI Bank
   @ADDI Roll
   @POPI Bank
   @PUSHI Bank
   @IF_GT_A 60
      @POPNULL
      @MA2V 60 Bank
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI Bank
   @IF_LT_A -60
      @POPNULL
      @MA2V -60 Bank
   @ELSE
      @POPNULL
   @ENDIF
@RET

:FlightCalcFlaps
   # Convert the flap handle row to 0..8, where higher means more flap.
   # This cheap value feeds both lift and drag.
   @PUSHI FlapY
   @SUB 14
   @POPI FlightFlaps

   @PUSHI FlightFlaps
   @IF_LT_A 0
      @POPNULL
      @MA2V 0 FlightFlaps
   @ELSE
      @POPNULL
   @ENDIF

   @PUSHI FlightFlaps
   @IF_UGT_A 8
      @POPNULL
      @MA2V 8 FlightFlaps
   @ELSE
      @POPNULL
   @ENDIF
@RET

:FlightAbsBank
   # Return abs(Bank) in FlightAbs. Used by both drag and lift loss.
   @MV2V Bank FlightAbs
   @PUSHI FlightAbs
   @IF_LT_A 0
      @POPNULL
      @PUSH 0
      @SUBI FlightAbs
      @POPI FlightAbs
   @ELSE
      @POPNULL
   @ENDIF
@RET

:FlightAbsPitch
   # Return abs(PitchValue) in FlightAbs.
   @MV2V PitchValue FlightAbs
   @PUSHI FlightAbs
   @IF_LT_A 0
      @POPNULL
      @PUSH 0
      @SUBI FlightAbs
      @POPI FlightAbs
   @ELSE
      @POPNULL
   @ENDIF
@RET

:FlightUpdateSpeed
   # Longitudinal energy model. Throttle pulls airspeed toward ThrustValue,
   # then pitch, bank, and flaps add cheap integer energy losses/gains.
   @CALL FlightCalcFlaps

   @PUSHI Speed
   @IF_LT_V ThrustValue
      @POPNULL
      @PUSHI ThrustValue
      @SUBI Speed
      @POPI SpeedDelta
      @PUSHI SpeedDelta
      @IF_UGT_A 4
         @POPNULL
         @MA2V 4 SpeedDelta
      @ELSE
         @POPNULL
      @ENDIF
      @PUSHI Speed
      @ADDI SpeedDelta
      @POPI Speed
   @ELSE
      @POPNULL
      @PUSHI Speed
      @IF_GT_V ThrustValue
         @POPNULL
         @PUSHI Speed
         @SUBI ThrustValue
         @POPI SpeedDelta
         @PUSHI SpeedDelta
         @IF_UGT_A 4
            @POPNULL
            @MA2V 4 SpeedDelta
         @ELSE
            @POPNULL
         @ENDIF
         @PUSHI Speed
         @SUBI SpeedDelta
         @POPI Speed
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF

   # Climbing trades airspeed for altitude; diving feeds a little speed back.
   @PUSHI PitchValue
   @IF_GT_A 0
      @POPNULL
      @PUSHI Speed
      @IF_UGT_V PitchValue
         @POPNULL
         @PUSHI Speed
         @SUBI PitchValue
         @POPI Speed
      @ELSE
         @POPNULL
         @MA2V 0 Speed
      @ENDIF
   @ELSE
      @POPNULL
      @PUSHI PitchValue
      @IF_LT_A 0
         @POPNULL
         @PUSH 0
         @SUBI PitchValue
         @POPI SpeedDelta
         @PUSHI Speed
         @ADDI SpeedDelta
         @POPI Speed
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF

   # Maneuver drag: abs(bank)/4 + abs(pitch)/2 + flaps/2.
   # All divisors are powers of two, so no MUL/DIVU in the hot path.
   @CALL FlightAbsBank
   @PUSHI FlightAbs
   @SHR
   @SHR
   @POPI SpeedDrag

   @CALL FlightAbsPitch
   @PUSHI FlightAbs
   @SHR
   @ADDI SpeedDrag
   @POPI SpeedDrag

   @PUSHI FlightFlaps
   @SHR
   @ADDI SpeedDrag
   @POPI SpeedDrag

   @PUSHI SpeedDrag
   @IF_UGT_A 0
      @POPNULL
      @PUSHI Speed
      @IF_UGT_V SpeedDrag
         @POPNULL
         @PUSHI Speed
         @SUBI SpeedDrag
         @POPI Speed
      @ELSE
         @POPNULL
         @MA2V 0 Speed
      @ENDIF
   @ELSE
      @POPNULL
   @ENDIF

   @PUSHI Speed
   @IF_UGT_A 240
      @POPNULL
      @MA2V 240 Speed
   @ELSE
      @POPNULL
   @ENDIF
@RET

:FlightUpdateAltitude
   # Vertical model. Pitch creates vertical velocity, airspeed supplies lift,
   # flaps add lift, and bank removes vertical lift so turns cost altitude.
   @MV2V PitchValue VertVel

   # Basic lift curve by speed bands. This is intentionally table-like and
   # branch-only; replace with lookup tables once the tuning settles.
   @MA2V 0 FlightLift
   @PUSHI Speed
   @IF_ULT_A 40
      @POPNULL
      @MA2V -3 FlightLift
   @ELSE
      @POPNULL
      @PUSHI Speed
      @IF_ULT_A 80
         @POPNULL
         @MA2V -1 FlightLift
      @ELSE
         @POPNULL
         @PUSHI Speed
         @IF_UGT_A 150
            @POPNULL
            @MA2V 1 FlightLift
         @ELSE
            @POPNULL
         @ENDIF
      @ENDIF
   @ENDIF

   @PUSHI FlightFlaps
   @SHR
   @SHR
   @ADDI FlightLift
   @POPI FlightLift

   @CALL FlightAbsBank
   @PUSHI FlightAbs
   @SHR
   @SHR
   @SUBI FlightLift
   @POPI FlightLift

   @PUSHI VertVel
   @ADDI FlightLift
   @POPI VertVel

   # Stall guard: below flying speed, pitch/flaps may reduce the sink rate
   # but must not create a climb. If the math is still positive, force a
   # modest descent so zero airspeed behaves like a stalled aircraft.
   @PUSHI Speed
   @IF_ULT_A 40
      @POPNULL
      @PUSHI VertVel
      @IF_GT_A -2
         @POPNULL
         @MA2V -2 VertVel
      @ELSE
         @POPNULL
      @ENDIF
   @ELSE
      @POPNULL
   @ENDIF

   @PUSHI Altitude
   @ADDI VertVel
   @POPI Altitude

   @PUSHI Altitude
   @IF_LT_A 0
      @POPNULL
      @MA2V 0 Altitude
      @MA2V 0 VertVel
   @ELSE
      @POPNULL
   @ENDIF
@RET

:FlightUpdateTurnRate
   # Approximate a coordinated turn: one degree/tick per eight degrees of
   # bank at medium speed. Slow flight turns twice as fast; fast flight turns
   # half as fast. Rudder adds a small direct yaw term.
   @CALL FlightAbsBank
   @PUSHI FlightAbs
   @SHR
   @SHR
   @SHR
   @POPI TurnRate

   @PUSHI Speed
   @IF_ULT_A 80
      @POPNULL
      @PUSHI TurnRate
      @SHL
      @POPI TurnRate
   @ELSE
      @POPNULL
      @PUSHI Speed
      @IF_UGE_A 160
         @POPNULL
         @PUSHI TurnRate
         @SHR
         @POPI TurnRate
      @ELSE
         @POPNULL
      @ENDIF
   @ENDIF

   # Preserve a visible one-degree turn for a small nonzero bank. Integer
   # shifts otherwise make the first seven degrees appear to fly straight.
   @PUSHI Bank
   @IF_NEQ_A 0
      @POPNULL
      @PUSHI TurnRate
      @IF_EQ_A 0
         @POPNULL
         @MA2V 1 TurnRate
      @ELSE
         @POPNULL
      @ENDIF
   @ELSE
      @POPNULL
   @ENDIF

   @PUSHI Bank
   @IF_LT_A 0
      @POPNULL
      @PUSH 0
      @SUBI TurnRate
      @POPI TurnRate
   @ELSE
      @POPNULL
   @ENDIF

   # Divide signed rudder input toward zero before adding it.
   @PUSHI RudderValue
   @IF_LT_A 0
      @POPNULL
      @PUSH 0
      @SUBI RudderValue
      @SHR
      @POPI FlightAbs
      @PUSHI TurnRate
      @SUBI FlightAbs
      @POPI TurnRate
   @ELSE
      @POPNULL
      @PUSHI RudderValue
      @SHR
      @ADDI TurnRate
      @POPI TurnRate
   @ENDIF
@RET

:FlightAdvanceHeading
   # Integrate the computed turn rate. Its bounded range needs one wrap.
   @PUSHI Heading
   @ADDI TurnRate
   @POPI Heading

   @PUSHI Heading
   @IF_LT_A 0
      @POPNULL
      @PUSHI Heading
      @ADD 360
      @POPI Heading
   @ELSE
      @POPNULL
   @ENDIF

   @PUSHI Heading
   @IF_UGT_A 359
      @POPNULL
      @PUSHI Heading
      @SUB 360
      @POPI Heading
   @ELSE
      @POPNULL
   @ENDIF
@RET

:FlightSpeedToStep
   # Convert speed into grid movement per tick.
   #
   # Cost note: DIVU by 10 is high cost, so cache the result. Speed changes
   # only when the flight model adjusts thrust/drag, while this function runs
   # every timer tick.
   # If this still becomes hot, replace DIVU with a reciprocal approximation
   # or a small lookup table.
   @IF_EQ_VV Speed MoveStepSpeed
      @JMP FlightSpeedToStepDone
   @ENDIF

   @MV2V Speed MoveStepSpeed
   @PUSHI Speed
   @PUSH 10
   @CALL DIVU
   @POPI MoveStep
   @POPNULL

:FlightSpeedToStepDone
@RET

:FlightLookupSin
   # MoveAngle is 0..90. Return sin(angle) scaled by 256 in MoveTableValue.
   @PUSHI MoveAngle
   @SHL
   @ADD FlightSinTable
   @PUSHS
   @POPI MoveTableValue
@RET

:FlightLookupCos
   # MoveAngle is 0..90. Return cos(angle), i.e. sin(90-angle), scaled by 256.
   @PUSH 90
   @SUBI MoveAngle
   @SHL
   @ADD FlightSinTable
   @PUSHS
   @POPI MoveTableValue
@RET

:FlightScaleTableX
   # Scale MoveStep by MoveTableValue/256 for X, preserving fractional carry.
   @MV2V MoveRemX MoveProduct
   @ForIA2V MoveIndex 0 MoveStep
      @PUSHI MoveProduct
      @ADDI MoveTableValue
      @POPI MoveProduct
   @Next MoveIndex

   @PUSHI MoveProduct
   @AND 0xff
   @POPI MoveRemX

   @PUSHI MoveProduct
   @SHR @SHR @SHR @SHR
   @SHR @SHR @SHR @SHR
   @POPI MoveComponent
@RET

:FlightScaleTableY
   # Scale MoveStep by MoveTableValue/256 for Y, preserving fractional carry.
   @MV2V MoveRemY MoveProduct
   @ForIA2V MoveIndex 0 MoveStep
      @PUSHI MoveProduct
      @ADDI MoveTableValue
      @POPI MoveProduct
   @Next MoveIndex

   @PUSHI MoveProduct
   @AND 0xff
   @POPI MoveRemY

   @PUSHI MoveProduct
   @SHR @SHR @SHR @SHR
   @SHR @SHR @SHR @SHR
   @POPI MoveComponent
@RET

:FlightComputeMoveVector
   # Heading uses compass convention: 0=N, 90=E, 180=S, 270=W.
   # Screen Y grows downward, so north is negative Y and south is positive Y.
   @MA2V 0 MoveDX
   @MA2V 0 MoveDY

   @PUSHI Heading
   @IF_ULT_A 90
      # NE: X = sin(angle), Y = -cos(angle)
      @POPNULL
      @MV2V Heading MoveAngle
      @CALL FlightLookupSin
      @CALL FlightScaleTableX
      @MV2V MoveComponent MoveDX
      @CALL FlightLookupCos
      @CALL FlightScaleTableY
      @PUSH 0
      @SUBI MoveComponent
      @POPI MoveDY
   @ELSE
      @POPNULL
      @PUSHI Heading
      @IF_ULT_A 180
         # SE: X = cos(angle-90), Y = sin(angle-90)
         @POPNULL
         @PUSHI Heading
         @SUB 90
         @POPI MoveAngle
         @CALL FlightLookupCos
         @CALL FlightScaleTableX
         @MV2V MoveComponent MoveDX
         @CALL FlightLookupSin
         @CALL FlightScaleTableY
         @MV2V MoveComponent MoveDY
      @ELSE
         @POPNULL
         @PUSHI Heading
         @IF_ULT_A 270
            # SW: X = -sin(angle-180), Y = cos(angle-180)
            @POPNULL
            @PUSHI Heading
            @SUB 180
            @POPI MoveAngle
            @CALL FlightLookupSin
            @CALL FlightScaleTableX
            @PUSH 0
            @SUBI MoveComponent
            @POPI MoveDX
            @CALL FlightLookupCos
            @CALL FlightScaleTableY
            @MV2V MoveComponent MoveDY
         @ELSE
            # NW: X = -cos(angle-270), Y = -sin(angle-270)
            @POPNULL
            @PUSHI Heading
            @SUB 270
            @POPI MoveAngle
            @CALL FlightLookupCos
            @CALL FlightScaleTableX
            @PUSH 0
            @SUBI MoveComponent
            @POPI MoveDX
            @CALL FlightLookupSin
            @CALL FlightScaleTableY
            @PUSH 0
            @SUBI MoveComponent
            @POPI MoveDY
         @ENDIF
      @ENDIF
   @ENDIF
@RET

:FlightApplyPosition
   # Integrate the movement vector into the map position.
   @PUSHI PosX
   @ADDI MoveDX
   @POPI PosX

   @PUSHI PosY
   @ADDI MoveDY
   @POPI PosY
@RET

:FlightCalculateTick
   # One simulation tick. Keep this as the top-level flight calculation
   # orchestration so the model remains easy to audit.
   @CALL FlightControlsToDisplayValues
   @CALL FlightUpdateRollRate
   @CALL FlightUpdateBank
   @CALL FlightUpdateSpeed
   @CALL FlightUpdateTurnRate
   @CALL FlightUpdateAltitude
   @CALL FlightAdvanceHeading
   @CALL FlightSpeedToStep
   @CALL FlightComputeMoveVector
   @CALL FlightApplyPosition
@RET

:DrawThrust
   @ForIA2B ControlScratch 15 22
      @Call(AV) WinCursor 7 ControlScratch
      @PRT " | "
   @Next ControlScratch
   @Call(AV) WinCursor 7 ThrustY
   @PRT "###"
@RET

:HandleThrustClick
   @MV2V LastMouseY ThrustY
   # Interface mapping: lower thrust handle means more thrust.
   # Low cost multiply by 16: four shifts avoid calling MUL.
   @PUSH 21
   @SUBI ThrustY
   @SHL
   @SHL
   @SHL
   @SHL
   @POPI ThrustValue
   @CALL FlightControlsToDisplayValues
   @CALL DrawThrust
   @CALL RefreshDisplay
@RET

:DrawRudder
   @Call(AA) WinCursor 63 19
   @PRT "           "
   @Call(VA) WinCursor RudderX 19
   @PRT "^"
@RET

:DrawStick
   # Redraw just the stick panel before plotting the marker, so moving the
   # marker does not erase the box, labels, or center lines.
   @Call(AA) WinCursor 28 14
   @PRT "           F           "
   @Call(AA) WinCursor 28 15
   @PRT "    +-------------+    "
   @Call(AA) WinCursor 28 16
   @PRT "    |      |      |    "
   @Call(AA) WinCursor 28 17
   @PRT "    |      |      |    "
   @Call(AA) WinCursor 28 18
   @PRT "  L |------+------| R  "
   @Call(AA) WinCursor 28 19
   @PRT "    |      |      |    "
   @Call(AA) WinCursor 28 20
   @PRT "    |      |      |    "
   @Call(AA) WinCursor 28 21
   @PRT "    +-------------+    "
   @Call(AA) WinCursor 28 22
   @PRT "           B           "

   @Call(VV) WinCursor StickX StickY
   @PRT "o"
   @MV2V StickX OldStickX
   @MV2V StickY OldStickY
@RET


:HandleStickClick
   @MV2V LastMouseX StickX
   @MV2V LastMouseY StickY

   # Scale stick deltas by 5/7, equivalent to about 1.4 input cells
   # per displayed indicator cell. Keep DIVU inputs positive.
   @PUSHI LastMouseX
   @IF_ULT_A 39
      @POPNULL
      @PUSH 39
      @SUBI LastMouseX
      @CALL ScaleInputBy5Over7
      @POPI ControlScratch
      @PUSH 68
      @SUBI ControlScratch
      @POPI RudderX
   @ELSE
      @POPNULL
      @PUSHI LastMouseX
      @SUB 39
      @CALL ScaleInputBy5Over7
      @POPI ControlScratch
      @PUSHI ControlScratch
      @ADD 68
      @POPI RudderX
   @ENDIF
   @PUSHI RudderX
   @IF_ULT_A 63
      @POPNULL
      @MA2V 63 RudderX
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI RudderX
   @IF_UGT_A 73
      @POPNULL
      @MA2V 73 RudderX
   @ELSE
      @POPNULL
   @ENDIF

   # Vertical stick controls pitch. The stick area is rows 14..22 with
   # center at 18, so direct row delta gives the full -4..+4 range.
   # Forward/up is nose down; pulling back/down is nose up.
   @PUSHI LastMouseY
   @SUB 18
   @POPI PitchValue
   @PUSHI PitchValue
   @IF_GT_A 4
      @POPNULL
      @MA2V 4 PitchValue
   @ELSE
      @POPNULL
   @ENDIF
   @PUSHI PitchValue
   @IF_LT_A -4
      @POPNULL
      @MA2V -4 PitchValue
   @ELSE
      @POPNULL
   @ENDIF
   @CALL FlightControlsToDisplayValues
   @CALL DrawRudder
   @CALL DrawStick
   @CALL DrawAileron
   @CALL DrawFlaps
@RET

:DrawAileron
   # Horizontal aileron slider above the rudder indicator. The command
   # spans -4..4, with the marker one row below its nine-cell track.
   @Call(AA) WinCursor 64 15
   @PRT "Aileron"
   @Call(AA) WinCursor 64 16
   @PRT "----+----"
   @Call(AA) WinCursor 64 17
   @PRT "         "
   @Call(VA) WinCursor AileronX 17
   @PRT "^"
@RET

:DrawFlaps
   @ForIA2B ControlScratch 14 22
      @Call(AV) WinCursor 57 ControlScratch
      @PRT " "
   @Next ControlScratch
   @Call(AV) WinCursor 57 FlapY
   @PRT "<"
@RET

:HandleAileronClick
   @MV2V LastMouseX AileronX
   @CALL FlightControlsToDisplayValues
   @CALL DrawAileron
@RET

:HandleFlapsClick
   @MV2V LastMouseY FlapY
   @CALL DrawFlaps
@RET


:DrawMouseClick
   # The middle of the instrument panel is free on row 2. Capture only
   # dispatched mouse clicks so timer and keyboard events cannot erase it.
   @MV2V LastMouseX ClickX
   @MV2V LastMouseY ClickY
   @Call(AA) WinCursor 40 2
   @PRT "Click X:            "
   @Call(AA) WinCursor 40 2
   @PRT "Click X: "
   @PRTI ClickX
   @PRT " Y: "
   @PRTI ClickY
@RET

:DrawControlState
   # Keep current command positions visible for screenshot comparisons.
   @Call(AA) WinCursor 23 4
   @PRT "                                    "
   @Call(AA) WinCursor 23 4
   @PRT "Aileron X: "
   @PRTI AileronX
   @PRT "  Flaps row: "
   @PRTI FlapY
   @Call(AA) WinCursor 23 5
   @PRT "                                    "
   @Call(AA) WinCursor 23 5
   @PRT "Rudder: "
   @PRTSGNI RudderValue
   @PRT "  Pitch cmd: "
   @PRTSGNI PitchValue
@RET

:DrawClock
   @Call(AA) WinCursor 62 4
   @PRT "Time:             "
   @Call(AA) WinCursor 62 4
   @PRT "Time: "
   @PRTI SimSeconds
@RET

:DrawPosition
   @Call(AA) WinCursor 2 10
   @PRT "X:               "
   @Call(AA) WinCursor 5 10
   @PRTI PosX
   @Call(AA) WinCursor 2 11
   @PRT "Y:               "
   @Call(AA) WinCursor 5 11
   @PRTI PosY
@RET

:DrawControls
   @CALL DrawThrust
   @CALL DrawRudder
   @CALL DrawStick
   @CALL DrawAileron
   @CALL DrawFlaps
@RET

:IgnoreClick
@RET


:SimTick
   @CALL FlightCalculateTick
   @INCI SimSeconds
   @CALL RefreshDisplay
   @MA2V 0 HorizonDrawValid
   @CALL DrawHorizon
   @CALL DrawRidge
   @CALL DrawMapObjects
   @CALL DrawPosition
   @CALL DrawClock
@RET

############################################################
# Main
############################################################

:Main .ORG Main

   @MA2V 1 Running

   @PUSH 0xff00
   @SUB ENDOFCODE
   @POPI ObjectSize

   @Call(AV) HeapDefineMemory ENDOFCODE ObjectSize
   @POPI HEAP_ID

   @Call(VA) HeapNewObject HEAP_ID 0x800
   @POPI SoftStackStart

   @PUSHI SoftStackStart
   @ADD 0x800
   @POPI SoftStackEnd

   @Call(VV) SetSSStack SoftStackEnd SoftStackStart

   @Call(V) EventTableNew HEAP_ID
   @POPI EventTable
   @Call(V) EventSetActive EventTable

   @CALL WinResize
   @MV2V WinWidth Columns
   @MV2V WinHeight Rows
   @CALL WinClear

   @Call(V) DisplayInit HEAP_ID
   @POPNULL
   @Call(V) PaintUIScreenInit DisplayRoot
   @CALL MarkAllFieldsDirty
   @CALL PaintUIScreenDraw
   @CALL DrawHorizon
   @CALL DrawRidge
   @CALL DrawMapObjects
   @CALL DrawControls
   @CALL DrawPosition
   @CALL DrawClock

   @CALL GrowEventTable

   # q/Q exit keys. Avoid ESC because terminal resize/mouse sequences start with ESC.
   @MA2V KeyRangeEvent RegType
   @MA2V "q\0" RegX1
   @MA2V "q\0" RegY1
   @MA2V 0 RegX2
   @MA2V 0 RegY2
   @MA2V EV_EXIT RegEventID
   @CALL AddEventFromVars

   @MA2V KeyRangeEvent RegType
   @MA2V "Q\0" RegX1
   @MA2V "Q\0" RegY1
   @MA2V 0 RegX2
   @MA2V 0 RegY2
   @MA2V EV_EXIT RegEventID
   @CALL AddEventFromVars

   # Repeating one-second simulation timer.
   @MA2V TimerEvent RegType
   @MV2V TimerOneSec RegX1
   @MV2V TimerRepeat RegY1
   @MA2V 0 RegX2
   @MA2V 0 RegY2
   @MA2V EV_SIMTICK RegEventID
   @CALL AddEventFromVars

   # Add the broad fallback first; KeySearchMouse checks newest records first.
   @MA2V MouseEventClick RegType
   @MA2V 1 RegX1
   @MA2V 1 RegY1
   @MA2V 80 RegX2
   @MA2V 24 RegY2
   @MA2V EV_BG_CLICK RegEventID
   @CALL AddEventFromVars


   # Top instrument/readout panel is display-only.
   @MA2V MouseEventClick RegType
   @MA2V 1 RegX1
   @MA2V 1 RegY1
   @MA2V 80 RegX2
   @MA2V 13 RegY2
   @MA2V EV_NOOP RegEventID
   @CALL AddEventFromVars

   # Thrust bars: click between the two outer vertical lines.
   @MA2V MouseEventClick RegType
   @MA2V 6 RegX1
   @MA2V 15 RegY1
   @MA2V 10 RegX2
   @MA2V 21 RegY2
   @MA2V EV_THRUST RegEventID
   @CALL AddEventFromVars

   # Stick/circle area. Horizontal movement drives rudder position.
   @MA2V MouseEventClick RegType
   @MA2V 28 RegX1
   @MA2V 14 RegY1
   @MA2V 50 RegX2
   @MA2V 22 RegY2
   @MA2V EV_STICK RegEventID
   @CALL AddEventFromVars

   # Horizontal aileron track and marker above the rudder indicator.
   @MA2V MouseEventClick RegType
   @MA2V 64 RegX1
   @MA2V 16 RegY1
   @MA2V 72 RegX2
   @MA2V 17 RegY2
   @MA2V EV_AILERON RegEventID
   @CALL AddEventFromVars

   # Flaps use the right side of the vertical guide.
   @MA2V MouseEventClick RegType
   @MA2V 57 RegX1
   @MA2V 14 RegY1
   @MA2V 58 RegX2
   @MA2V 22 RegY2
   @MA2V EV_FLAPS RegEventID
   @CALL AddEventFromVars
   @CALL TermMouseEnable

   @PUSHI Running
   @WHILE_NOTZERO
      @POPNULL

      @CALL EventPoll
      @POPI EventID

      @IF_NEQ_AV 0 EventID
         @PUSHI EventID
         @SWITCH
         @CASE EV_EXIT
         @POPNULL
         @MA2V 0 Running
         @CBREAK
      @CASE EV_THRUST
         @POPNULL
         @CALL HandleThrustClick
         @CBREAK
      @CASE EV_STICK
         @POPNULL
         @CALL HandleStickClick
         @CBREAK
      @CASE EV_FLAPS
         @POPNULL
         @CALL HandleFlapsClick
         @CBREAK
      @CASE EV_AILERON
         @POPNULL
         @CALL HandleAileronClick
         @CBREAK
      @CASE EV_SIMTICK
         @POPNULL
         @CALL SimTick
         @CBREAK
      @CASE EV_BG_CLICK
         @POPNULL
         @CALL IgnoreClick
         @CBREAK
      @CASE EV_NOOP
         @POPNULL
         @CBREAK
      @CDEFAULT
         @POPNULL
         @CBREAK
         @ENDCASE
      @ENDIF

      @PUSHI Running
   @ENDWHILE
   @POPNULL

   @CALL TermMouseDisable
   @TTYECHO
   @TTYRAWOFF
   @Call(V) EventTableFree EventTable

   @Call(VV) WinCursor 1 Rows
   @PRTNL

@END

:ENDOFCODE
