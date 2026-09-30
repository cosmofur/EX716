I common.mc
L display.ld
G TestValue


L generated_screen.inc

:ObjectSize 0
:HEAP_ID 0
:SoftStackStart 0
:SoftStackEnd 0
:UserKey 0
:Running 0

# Backing values used by generated_screen.inc while testing display.ld.
:TestValue 1234

:DrawHelp
   @Call(AA) WinCursor 1 25
   @PRT "+/- changes TestValue, q quits"
@RET

:MarkAllDirty
   @Call(V) DisplayMarkFormDirty DisplayRoot
@RET

:Main .ORG Main
   @PUSH 0xff00
   @SUB END__
   @POPI ObjectSize

   @Call(AV) HeapDefineMemory END__ ObjectSize
   @POPI HEAP_ID

   @Call(VA) HeapNewObject HEAP_ID 0x400
   @POPI SoftStackStart

   @PUSHI SoftStackStart
   @ADD 0x400
   @POPI SoftStackEnd

   @Call(VV) SetSSStack SoftStackEnd SoftStackStart

   @CALL WinClear
   @Call(V) DisplayInit HEAP_ID
   @POPNULL

   @Call(V) PaintUIScreenInit DisplayRoot
   @CALL PaintUIScreenDraw
   @CALL DrawHelp

   @MA2V 1 Running
   @TTYNOECHO
   @PUSHI Running
   @WHILE_NOTZERO
      @POPNULL
      @READC UserKey
      @PUSHI UserKey
      @AND 0xff
      @POPI UserKey
      @PUSHI UserKey
      @SWITCH
      @CASE "+\0"
         @INCI TestValue
         @CALL MarkAllDirty
         @CALL PaintUIScreenDraw
         @CALL DrawHelp
         @CBREAK
      @CASE "-\0"
         @DECI TestValue
         @CALL MarkAllDirty
         @CALL PaintUIScreenDraw
         @CALL DrawHelp
         @CBREAK
      @CASE "q\0"
         @MA2V 0 Running
         @CBREAK
      @CASE "Q\0"
         @MA2V 0 Running
         @CBREAK
      @CDEFAULT
         @CBREAK
      @ENDCASE
      @POPNULL
      @PUSHI Running
   @ENDWHILE
   @POPNULL
   @TTYECHO
   @CALL WinClear
   @END
