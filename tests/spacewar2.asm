I common.mc
L screen.ld
L timetool.ld
:ASize1
9 6
#123456789
"   ###   "
" #O##### "
"#####O##>"
"###O#####"
" <####O# "
"   ###   "
:ASize2
4 3
#123456789
" /# "
"#:;#"
" #% "
:ASize3
2 2
#123456
";@"
"*;"
:Bul1
1 1
"+"
:Bul2
1 1
"*"
:Ship1
7 3
#123456789
">_/--\\<"
">-===-<"
"  ^^^  "
:Ship2
5 2
#123456789
"/---\\"
"\\---/"

############ Required Globals
:MainHeapID 0
#############################################################################
# Function Init, setup heap and memory
:Init
# Defined memory between endofcode and 0xf000 as available
@PUSH ENDOFCODE @PUSH 0xf000 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeapID
#
# Expands the Soft Stack so we can use deeper recursion, about 1K should do for now.
@PUSHI MainHeapID @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF   # Error code 1
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
#
# The 'Root' Obejct will always just contain the ID of 0, and one pointer to first available room.
@RET
###########################################################################
# Function ErrorExit
:ErrorExit
@TTYECHO
@PRT "From Location: " @PRTHEXTOP
@POPNULL
@PRT " Error Code: " @PRTTOP
@PRTNL
@POPNULL
@END
############################################################################
# Function Main
:Main . Main
=Xpos Var01
=Ypos Var02
=OXpos Var03
=OYpos Var04
@CALL Init
@CALL WinClear
@MA2V 5 OXpos
@MA2V 10 OYpos
@PUSH 0
@WHILE_ZERO
@ForIA2B Ypos 5 20
  @ForIA2B Xpos 10 65
      @PUSH Glyph1 @PUSHI OXpos @PUSHI OYpos
         @CALL EraseGlyph           
      @PUSH Glyph1 @PUSHI Xpos @PUSHI Ypos
         @CALL DrawGlyph
      @CALL Delay
      @MV2V Xpos OXpos
      @MV2V Ypos OYpos
  @NextBy Xpos 5
@NextBy Ypos 5
@PUSH 0 @PUSH 23
@CALL WinCursor
@ENDWHILE
@END

:Delay
@PUSH 50
@CALL SleepMilli
@RET

###########################################
# Function DrawGlyph(Glyph1, CenterX, CenterY)
:DrawGlyph
=InX Var01
=InY Var02
=InGlyphPtr Var03
=GlyphWidth Var04
=GlyphHeight Var05
=GX Var06
=GY Var07
=Index1 Var08
=Index2 Var09
=CharPtr Var10
=CharVal Var11
@PUSHRETURN
@PUSHLOCALI Var01 @PUSHLOCALI Var02 @PUSHLOCALI Var03 @PUSHLOCALI Var04
@PUSHLOCALI Var05 @PUSHLOCALI Var06 @PUSHLOCALI Var07 @PUSHLOCALI Var08
@PUSHLOCALI Var09 @PUSHLOCALI Var10 @PUSHLOCALI Var11
@POPI InY @POPI InX @POPI InGlyphPtr
#
# Fetch Glyth Width and Height
@PUSHI InGlyphPtr @PUSHS @POPI GlyphWidth
@PUSHI InGlyphPtr @ADD 2 @PUSHS @POPI GlyphHeight
#
# GX = InX - 1/2 GlyphWidth
# GY = InY - 1/2 GlyphHeight
@PUSHI InX @PUSHI GlyphWidth @SHR @SUBS @POPI GX
@PUSHI InY @PUSHI GlyphHeight @SHR @SUBS @POPI GY
@PUSHI WinWidth
@IF_LT_V GX    @MA2V -1 GX @ENDIF
@POPNULL
@PUSHI WinHeight
@IF_LT_V GY    @MA2V -1 GX @ENDIF
@POPNULL
@PUSH 3
@IF_GE_V GX    @MA2V -1 GX @ENDIF
@IF_GE_V GY    @MA2V -1 GX @ENDIF
@POPNULL
@IF_EQ_AV -1 GX
  # Skip this one
@ELSE
   #
   # CharPtr = InGlyphPtr + 2 words
   @PUSHI InGlyphPtr @ADD 4 @POPI CharPtr
   #
#   @PRT "GlyphWidth: " @PRTI GlyphWidth @PRT " GlyphHeight: " @PRTI GlyphHeight
   @ForIA2V Index1 0 GlyphHeight
      @PUSHI GX @PUSHI GY @CALL WinCursor
      @ForIA2V Index2 0 GlyphWidth
#          @PRT "."
          @PUSHII CharPtr @AND 0xff
          # If space, skip to next character
          @IF_EQ_AV " \0" CharVal
             @POPNULL
             @PUSH 1 @CALL WinEast
          @ELSE
             @PRTCHS
             @POPNULL
          @ENDIF
          @INCI CharPtr
      @Next Index2
      @INCI GY
   @Next Index1
@ENDIF
@POPLOCAL Var11 @POPLOCAL Var10 @POPLOCAL Var09 @POPLOCAL Var08 @POPLOCAL Var07
@POPLOCAL Var06 @POPLOCAL Var05 @POPLOCAL Var04 @POPLOCAL Var03 @POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

###########################################
# Function EraseGlyph(Glyph1, CenterX, CenterY)
:EraseGlyph
=InX Var01
=InY Var02
=InGlyphPtr Var03
=GlyphWidth Var04
=GlyphHeight Var05
=GX Var06
=GY Var07
=Index1 Var08
=Index2 Var09
=CharPtr Var10
@PUSHRETURN
@PUSHLOCALI Var01 @PUSHLOCALI Var02 @PUSHLOCALI Var03 @PUSHLOCALI Var04
@PUSHLOCALI Var05 @PUSHLOCALI Var06 @PUSHLOCALI Var07 @PUSHLOCALI Var08
@PUSHLOCALI Var09 @PUSHLOCALI Var10
@POPI InY @POPI InX @POPI InGlyphPtr
#
# Fetch Glyth Width and Height
@PUSHI InGlyphPtr @PUSHS @POPI GlyphWidth
@PUSHI InGlyphPtr @ADD 2 @PUSHS @POPI GlyphHeight
#
# GX = InX - 1/2 GlyphWidth
# GY = InY - 1/2 GlyphHeight

@PUSHI InX @PUSHI GlyphWidth @SHR @SUBS @POPI GX
@PUSHI InY @PUSHI GlyphHeight @SHR @SUBS @POPI GY
@PUSHI WinWidth
@IF_LT_V GX    @MA2V -1 GX   @ENDIF
@POPNULL
@PUSHI WinHeight
@IF_LT_V GY    @MA2V -1 GX   @ENDIF
@POPNULL
@PUSH 3
@IF_GE_V GX    @MA2V -1 GX   @ENDIF
@IF_GE_V GY    @MA2V -1 GX   @ENDIF
@POPNULL

@IF_EQ_AV -1 GX
  # Skip this one.
@ELSE
  #
  # CharPtr = InGlyphPtr + 2 words
  @PUSHI InGlyphPtr @ADD 4 @POPI CharPtr
  #
  @ForIA2V Index1 0 GlyphHeight
     @PUSHI GX @PUSHI GY @CALL WinCursor
     @ForIA2V Index2 0 GlyphWidth
         @PRTSP
         @INCI CharPtr
     @Next Index2
     @INCI GY
  @Next Index1
@ENDIF
@POPLOCAL Var10 @POPLOCAL Var09 @POPLOCAL Var08 @POPLOCAL Var07 @POPLOCAL Var06
@POPLOCAL Var05 @POPLOCAL Var04 @POPLOCAL Var03 @POPLOCAL Var02 @POPLOCAL Var01
@POPRETURN
@RET

       







:ENDOFCODE
