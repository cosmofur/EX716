I common.mc
L softstack.ld
L random.ld
L screen.ld
L heapmgr.ld
L string.ld
L mul.ld
L div.ld
#### Local Storage
:MainHeapID 0
#
# We are using a range of 0 to 64 for our map values, but as 16 bit data.
# So 6 bits will be the number and 10 bits for the deciamal Positive numbers only.
#
#
#####################################
# Function: init(Width,Height)
:init
#
# Defined memory between endofcode and 0xf000 as available
@PUSH ENDOFCODE @PUSH 0xf000 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeapID
#
# Expands the Soft Stack so we can use deeper recursion, about 1K should do for now.
@PUSHI MainHeapID @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF   # Error code 1  #0
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
#
#
# Now that stack is setup, we can use the local variables
@PUSHRETURN
=Height Var01
=Width Var02
=Size Var03
=Index1 Var04
=SeedCount Var05
=UserKey Var06
=MapObject Var07

@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@POPI Height
@POPI Width
# Setup Random seed
@PRTLN "Start...(hit any key)"
@TTYNOECHO
@WHEN   # First When 'drains' the keybuffer so human reaction time matters.
   @READCNW UserKey
   @PUSHI UserKey
   @DO_NOTZERO
      @POPNULL
@ENDWHEN
@POPNULL
@WHEN
   @READCNW UserKey
   @PUSHI UserKey
   @IF_EQ_AV 0 UserKey
   @ELSE
       @PRTSTR UserKey
   @ENDIF
   @DO_ZERO
      @POPNULL
      @INCI SeedCount  # Never Initilied SeedCount, but that just makes it more random.
@ENDWHEN
@POPNULL
@TTYECHO
@PUSHI SeedCount @ADDI UserKey @AND 0x7fff
@CALL rndsetseed
#

#
@PUSHI Width
@PUSHI Height
@CALL MULU
@POPI Size
#
# Create the map object.
@PUSHI MainHeapID
@PUSHI Size @ADD 6 @SHL
@CALL HeapNewObject
@POPI MapObject
@PUSHI Size @POPII MapObject
@PUSHI Width @PUSHI MapObject @ADD 2 @POPS
@PUSHI Height @PUSHI MapObject @ADD 4 @POPS

@ForIA2V Index1 0 Size
#   @CALL rnd16
#   @PUSHII Index1
   @PUSH 0
   @PUSHI Index1 @ADD 6 @ADDI MapObject
   @POPS
   @PUSHI Index1
   @AND 0x3f
   @IF_EQ_A 0x3f
      @PRT "."
   @ENDIF
   @POPNULL
@Next Index1
@PRTNL
@PUSHI MapObject
:ErrorExit
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET



:Main . Main

=MapObject Var01
=Index1 Var02
=Size Var03
=CharVal Var04
@PUSH 80 @PUSH 24
@CALL init
@POPI MapObject
@PUSHI MapObject
@CALL DrawMap
@PRTNL
#
#@PUSH 10 @PUSH 10 @PUSH 5 @PUSH 20 @PUSHI MapObject
#@CALL DrawCircle
#
#@PUSH 20 @PUSH 13 @PUSH 6 @PUSH 24 @PUSHI MapObject
#@CALL FilledCircle
#@PUSHI MapObject
#@PRTLN "Calling DrawMap"
#@CALL DrawMap
#
@PRTLN "Draw Ellipse"
@PUSH 10 @PUSH 15 @PUSH 4 @PUSH 6 @PUSH 20 @PUSHI MapObject
@CALL DrawEllipse
#
#

@PUSHI MapObject
@PRTLN "Calling DrawMap"
@CALL DrawMap
#
@PRTS CISCODE @PRT "-1;1H"

@END

#####################################
# Function DrawMap(map)
:DrawMap
@PUSHRETURN
=MapObject Var01
=Index1 Var02
=Size Var03
=PreColor Var04
=CharVal Var05
=YPOS Var06
=XPOS Var07
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@POPI MapObject

@PUSHII MapObject @POPI Size
@PUSHI MapObject @ADD 2 @PUSHS @POPI YPOS
@MV2V YPOS XPOS
@INCI Size
@PUSHI MapObject @ADD 6 @ADDI YPOS @PUSHS @AND 0xff
@POPI PreColor
@PRTS CISCODE @PRT "0;0H"
@PRTS CISCODE @PRT "0m|"
@PRTS CISCODE @PRT "48;5;" @PRTI PreColor @PRT "m"
@ForIA2V Index1 1 Size
   @PUSHI Index1
   @ADDI MapObject
   @ADD 6
   @PUSHS @AND 0xff
   @POPI CharVal
   @IF_EQ_VV CharVal PreColor  # saves us from changing color when it's already that color.
      @PRT " "
   @ELSE
      @PRTS CISCODE @PRT "48;5;" @PRTI CharVal @PRT "m*"
      @MV2V CharVal PreColor
   @ENDIF
   # XPOS counts down the width of current line.
   @IF_EQ_AV 1 XPOS
       @PUSHI MapObject @ADD 2 @PUSHS @POPI XPOS
       @PRTS CISCODE @PRT "0m|\n|"
       @PUSHI Index1 @ADDI MapObject @PUSHS @AND 0xff
       @POPI PreColor
       # YPOS is 1st character of next line.
       @PRTS CISCODE @PRT "48;5;" @PRTI PreColor @PRT "m"
   @ELSE
       @DECI XPOS
   @ENDIF
@Next Index1
@PRTS CISCODE @PRTLN "0m"
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET



#####################################
# Function SetPixel(x,y,color,map)
:SetPixel
@PUSHRETURN
=InX Var01
=InY Var02
=InColor Var03
=InMap Var04
=Width Var05
=Height Var06
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@POPI InMap
@POPI InColor
@POPI InY
@DECI InY
@POPI InX
@DECI InX
#
@PUSHI InMap @ADD 2 @PUSHS @POPI Width
@PUSHI InMap @ADD 4 @PUSHS @POPI Height
#
@PUSHI InX
@IF_ULT_V Width
   @PUSHI InY
   @IF_ULT_V Height
      @PUSHI Width
      @CALL MULU
      @ADDS
      @ADD 6      
      @ADDI InMap
      @DUP
      @PUSHS @AND 0xFF00
      @ORI InColor
      @SWP
      @POPS
   @ELSE
      @POPNULL
   @ENDIF
@ELSE
   @POPNULL
@ENDIF
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

#####################################
# Function DrawCircle(InX, InY, InRadius, InColor, InMap)
:DrawCircle
@PUSHRETURN
=InX Var01
=InY Var02
=InRadius Var03
=InColor Var04
=InMap Var05
=TmpX Var06
=TmpY Var07
=ErrRange Var08
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08

@POPI InMap
@POPI InColor
@POPI InRadius
@POPI InY
@POPI InX
#
# Draw the initial points at the top and bottom
@PUSHI InX @PUSHI InY @ADDI InRadius @PUSHI InColor @PUSHI InMap
@CALL SetPixel    # xo, yo+radius
@PUSHI InX @PUSHI InY @SUBI InRadius @PUSHI InColor @PUSHI InMap
@CALL SetPixel    # xo, yo-radius
#
@MV2V InRadius TmpX
@MA2V 0 TmpY
@MA2V 0 ErrRange
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @PUSHI InX @ADDI TmpX   @PUSHI InY @ADDI TmpY @PUSHI InColor @PUSHI InMap
   @CALL SetPixel    # xo+x,yo+y
   @PUSHI InX @SUBI TmpX   @PUSHI InY @ADDI TmpY @PUSHI InColor @PUSHI InMap
   @CALL SetPixel    # xo-x, yo+y
   @PUSHI InX @ADDI TmpX   @PUSHI InY @SUBI TmpY @PUSHI InColor @PUSHI InMap
   @CALL SetPixel    # xo+x, yo-y
   @PUSHI InX @SUBI TmpX   @PUSHI InY @SUBI TmpY @PUSHI InColor @PUSHI InMap
   @CALL SetPixel    # xo-x,yo-y
   @PUSHI InX @ADDI TmpY   @PUSHI InY @ADDI TmpX @PUSHI InColor @PUSHI InMap
   @CALL SetPixel    # xo+y,yo+x
   @PUSHI InX @SUBI TmpY   @PUSHI InY @ADDI TmpX @PUSHI InColor @PUSHI InMap
   @CALL SetPixel    # xo-y,yi_x
   @PUSHI InX @ADDI TmpY   @PUSHI InY @SUBI TmpX @PUSHI InColor @PUSHI InMap
   @CALL SetPixel    # xo+y,yo-x
   @PUSHI InX @SUBI TmpY   @PUSHI InY @SUBI TmpX @PUSHI InColor @PUSHI InMap
   @CALL SetPixel    # xo-y, yo-x
   # handle case them TmpX == 0
   @IF_EQ_AV 0 TmpX
      @PUSHI InX @PUSHI InY @ADDI TmpY @PUSH InColor @PUSHI InMap
      @CALL SetPixel  # xo, yo+y
      @PUSHI InX @PUSHI InY @SUBI TmpY @PUSH InColor @PUSHI InMap      
      @CALL SetPixel  # xo, yo-y
   @ENDIF
   @INCI TmpY
   @PUSHI ErrRange
   @IF_LE_A 0
      @PUSHI TmpY @SHL @ADD 1
      @ADDI ErrRange @POPI ErrRange
   @ELSE
      @DECI TmpX
      @PUSHI TmpY @SUBI TmpX @SHL @ADD 1
      @ADDI ErrRange @POPI ErrRange
   @ENDIF
   @POPNULL   
   @PUSHI TmpX
   @IF_GT_V TmpY
      @POPNULL
      @PUSH 0
   @ELSE
      @POPNULL
      @PUSH 1
   @ENDIF
@ENDWHILE
@POPNULL

@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

#######################################
# Function FilledCircle(InX, InY, InRadius, InColor, InMap)
# Draw a filled circle of a given color.
:FilledCircle
@PUSHRETURN
=InX Var01
=InY Var02
=InRadius Var03
=InColor Var04
=InMap Var05
=TmpX Var06
=TmpY Var07
=NegRadius Var08
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08

@POPI InMap
@POPI InColor
@POPI InRadius
@POPI InY
@POPI InX
#
@PUSHI InRadius
@COMP2
@POPI NegRadius
@INCI InRadius # To make For loops to include last value.
@ForIV2V TmpY NegRadius InRadius 
    @ForIV2V TmpX NegRadius InRadius
        @PUSHI TmpX @DUP @CALL MUL     # X*X
        @PUSHI TmpY @DUP @CALL MUL     # Y*Y
        @ADDS                          # X^2+Y^2
        @PUSHI NegRadius @DUP @CALL MUL  # Radius^2
        @IF_LE_S
            @PUSHI InX @ADDI TmpX
            @PUSHI InY @ADDI TmpY
            @PUSHI InColor
            @PUSHI InMap
            @CALL SetPixel
        @ENDIF
        @POPNULL
        @POPNULL
    @Next TmpX
@Next TmpY
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
####################################################
# Function DrawEllipse(x1,y1,a,b, color,InMap)
# a and b are the horizontal and vertical radius
:DrawEllipse
@PUSHRETURN
=InX0 Var01
=InB Var02
=InY0 Var03
=InA Var04
=InColor Var06
=A2 Var07
=B2 Var08
=Sigma Var09
=TmpX Var10
=TmpY Var11
=FA2 Var12
=FB2 Var13
=InMap Var14
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08
@PUSHLOCALI Var08
@PUSHLOCALI Var10
@PUSHLOCALI Var11
@PUSHLOCALI Var12
@PUSHLOCALI Var13
@PUSHLOCALI Var14
#
@POPI InMap
@POPI InColor
@POPI InB
@POPI InA
@POPI InY0
@POPI InX0
#
@PUSHI InA @DUP @CALL MUL @POPI A2
@PUSHI InB @DUP @CALL MUL @POPI B2
@PUSHI A2 @SHL @SHL @POPI FA2    # a2*4
@PUSHI B2 @SHL @SHL @POPI FB2    # b2*4
#
@MA2V 0 TmpX      # X=0
@MV2V InB TmpY    # Y=B
#
# sigma = 2*B2+A2*(1-2*B)
@PUSHI B2 @SHL    # b2*2
@PUSH 1           # (1 - 2*B)
@PUSHI InB @SHL
@SUBS
@PUSHI A2         # A2 * (1-2*B)
@CALL MUL
@ADDS             # () + ()
@POPI Sigma
#
@CALL EllipseCondition1  # true if ( b2*x <= a2*y)
@WHILE_NOTZERO
@  @PRT "A:For X=" @PRTI TmpX @PRT ", Y=" @PRTI TmpY @PRT ", sigma:" @PRTI Sigma @PRT " = ( B2:" @PRTI B2
@  @PRT " * X:" @PRTI TmpX @PRT " A2:" @PRTI A2 @PRT " <= A2 * Y:" @PRTI InY @PRT " == " @PRTTOP
@  @PRTNL
  @POPNULL
  # SetPixel(X0+X, Y0+Y,color)
     @PUSHI InX0 @ADDI TmpX
     @PUSHI InY0 @ADDI TmpY
     @PUSHI InColor
     @PUSHI InMap
     @CALL SetPixel
  # SetPixel(X0-X, Y0+Y,color)
     @PUSHI InX0 @SUBI TmpX
     @PUSHI InY0 @ADDI TmpY
     @PUSHI InColor
     @PUSHI InMap
     @CALL SetPixel     
  # SetPixel(X0+X, Y0-Y,color)
     @PUSHI InX0 @ADDI TmpX
     @PUSHI InY0 @SUBI TmpY
     @PUSHI InColor
     @PUSHI InMap
     @CALL SetPixel
  # SetPixel(X0-X, Y0-Y,color)
     @PUSHI InX0 @SUBI TmpX
     @PUSHI InY0 @SUBI TmpY
     @PUSHI InColor
     @PUSHI InMap
     @CALL SetPixel
  @PUSHI Sigma @PUSH 0
  @IF_GE_S
     # sigma += FA2 * ( 1 - Y)
     @PUSH 1 @SUBI TmpY
     @PUSHI FA2
     @CALL MUL
     @ADDI Sigma
     @POPI Sigma
     @DECI TmpY
  @ENDIF
  @POPNULL @POPNULL
  # sigma += b2 * ((4*x) + 6)
  @PUSHI TmpX @SHL @SHL @ADD 6 # 4*x + 6
  @PUSHI B2
  @CALL MUL      # B2 * ()
  @ADDI Sigma
  @POPI Sigma    # Sigma += ()
  @INCI TmpX
  @CALL EllipseCondition1
@ENDWHILE
:Break01
@POPNULL
#
# Second For loop
@MV2V InA TmpX
@MA2V 0 TmpY
# sigma = 2*B2 + A2 * (1-2*B)
@PUSH 1
@PUSHI InB @SHL   # 2*b
@SUBS             # 1 - ()
@PUSHI A2
@CALL MUL         # A2 * ()
@PUSHI B2 @SHL    # B2 * 2
@ADDS             # Sigma = () + ()
@POPI Sigma
@CALL EllipseCondition2  # a2*y <= b2*x
@WHILE_NOTZERO
#  @PRT "B:For X=" @PRTI TmpX @PRT ", Y=" @PRTI TmpY @PRT ", sigma:" @PRTI Sigma @PRT " = ( B2:" @PRTI B2
#  @PRT " * X:" @PRTI TmpX @PRT " A2:" @PRTI A2 @PRT " <= A2 * Y:" @PRTI InY @PRT " == " @PRTTOP
  @PRTTOP @PRTNL
  @POPNULL
  # SetPixel(X0+X, Y0+Y,color)
     @PUSHI InX0 @ADDI TmpX
     @PUSHI InY0 @ADDI TmpY
     @PUSHI InColor
     @PUSHI InMap
     @CALL SetPixel
  # SetPixel(X0-X, Y0+Y,color)
     @PUSHI InX0 @SUBI TmpX
     @PUSHI InY0 @ADDI TmpY
     @PUSHI InColor
     @PUSHI InMap
     @CALL SetPixel
  # SetPixel(X0+X, Y0-Y,color)
     @PUSHI InX0 @ADDI TmpX
     @PUSHI InY0 @SUBI TmpY
     @PUSHI InColor
     @PUSHI InMap
     @CALL SetPixel
  # SetPixel(X0-X, Y0-Y,color)
     @PUSHI InX0 @SUBI TmpX
     @PUSHI InY0 @SUBI TmpY
     @PUSHI InColor
     @PUSHI InMap
     @CALL SetPixel
  @PUSHI Sigma @PUSH 0
  @IF_GE_S
     # sigma += FB2*(1-X)
     @POPNULL @POPNULL
     @PUSH 1
     @SUBI TmpX   # (1-X)
     @PUSHI FB2
     @CALL MUL    # FB2*()
     @ADDI Sigma
     @POPI Sigma  # Sigma += ()
     @DECI TmpX
   @ELSE
     @POPNULL @POPNULL
   @ENDIF
   # sigma += A2 * ((4*Y)+6)
    @PUSHI TmpY
    @SHL @SHL     # 4*Y
    @ADD 6        # ()+6
    @PUSHI A2
    @CALL MUL     # A2*()
    @ADDI Sigma
    @POPI Sigma   # Sigma += ()
    @INCI TmpY
   @CALL EllipseCondition2
#  @PRT "B:(" @PRTI TmpX @PRT "," @PRTI TmpY @PRT "):" @StackDump
@ENDWHILE

@PUSHI InX0
@PUSHI InY0
@PUSHI InColor
@PUSHI InMap
@CALL SetPixel


@PUSHI InX0
@PUSHI InY0 @SUBI InA
@PUSHI InColor
@PUSHI InMap
@CALL SetPixel
@JMP Skip1
@PUSHI InX0 
@PUSHI InY0 @ADDI InA
@PUSHI InColor
@PUSHI InMap
@CALL SetPixel

@PUSHI InX0 @SUBI InB
@PUSHI InY0  
@PUSHI InColor
@PUSHI InMap
@CALL SetPixel

@PUSHI InX0  @ADDI InB
@PUSHI InY0
@PUSHI InColor
@PUSHI InMap
@CALL SetPixel

:Skip1

@POPLOCAL Var14
@POPLOCAL Var13
@POPLOCAL Var12
@POPLOCAL Var11
@POPLOCAL Var10
@POPLOCAL Var09
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


# These mini functions just uses the local variable os DrawEllipse and returns just true(1)or false(0)
     
:EllipseCondition1
# Condtion true if B2*X <= A2*Y
@PUSHI B2 @PUSHI TmpX @CALL MUL
@PUSHI A2 @PUSHI TmpY @CALL MUL
@IF_LE_S
   @POPNULL @POPNULL
   @PUSH 1
@ELSE
   @POPNULL @POPNULL
   @PUSH 0
@ENDIF
@SWP
@RET
#
:EllipseCondition2
# Condition true if A2*Y <= B2*X

@PUSHI A2 @PUSHI TmpY @CALL MUL
@PUSHI B2 @PUSHI TmpX @CALL MUL
@IF_LE_S
   @POPNULL @POPNULL
   @PUSH 1
   @PRT "+"
@ELSE
   @POPNULL @POPNULL
   @PUSH 0
   @PRT "-"
@ENDIF

@SWP
@RET



@PUSHI B2 @SHL
@PUSH 1 @PUSHI InRadius @SHL @SUBS
@CALL MUL
@POPI Sigma
#
@PUSHI B2 @PUSHI TmpX @CALL MUL
@PUSHI A2 @PUSHI TmpY @CALL MUL
@IF_LE_S
   @POPNULL @POPNULL
   @PUSH 1
@ELSE
   @POPNULL @POPNULL
   @PUSH 0
@ENDIF
@SWP
@RET






:ENDOFCODE
