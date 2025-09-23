I common.mc
L softstack.ld
L random.ld
L heapmgr.ld
L mul.ld
L screen.ld

# THis is just psudo code, need to be rewored into real code.

= MAPSIZE 64
= GRIDSTEP 8
= GRIDPTS 9

:FadeTable
   $$0 $$5 $$19 $$38 $$57 $$70 $$78 $$84

# Temporary using fixe memory, rather replace with Heap defined tables

:GradientGrid
  # 9x9 bytes
. GradientGrid+81
  

:Map
  # 64x64 bytes
  . Map+4096

######################################
# Function GenerateTerainMap()
:GenerateTerrainMap
  @PUSHRETURN
  @LocalVar X1 01
  @LocalVar Y1 02
  @LocalVar V1 03
  @LocalVar DX 04
  @LocalVar GY 05
  @LocalVar DY 06
  @LocalVar FX 07
  @LocalVar FY 08
  @LocalVar TL 09
  @LocalVar TR 10
  @LocalVar BL 11
  @LocalVar BR 12


  @MA2V 0 Y1
  
  @PUSHI Y1
  @WHILE_LT_A MAPSIZE      # In the future MAPSIZE maybe a variable rather than constant
    @POPNULL
    @MA2V 0 X1
    @PUSHI X1
    @WHILE_LT_A MAPSIZE
      @PUSHI X1 @SHR @SHR @SHR @POPI GX  #      = GX X >> 3
      @PUSHI X1 @AND 0x7 @POPI DX        #      = DX X & 7
      @PUSHI Y1 @SHR @SHR @SHR @POPI GY  #      = GY Y >> 3
      @PUSHI Y1 @AND 0x7 @POPI DY        #      = DY Y & 7

      @PUSH FadeTable @ADDI DX @PUSHS @AND 0xff  
      @POPI FX                           #      = FX FadeTable[DX]
      @PUSH FadeTable @ADDI DY @PUSHS @AND 0xff
      @POPI FY                           #      = FY FadeTable[DY]

      # Get 4 corner values from coarse gradient grid
      
      #   = TL GradientGrid[GY * GRIDPTS + GX]
         @PUSH GradientGrid
         @PUSHI GY @SHL @SHL @SHL @ADDI GY   # GY * 8 + GY GRIDPTS == 9
         @ADDI GX
         @PUSHS @AND 0xff
         @POPI TL
      #   = TR GradientGrid[GY * GRIDPTS + GX + 1]
         @PUSH GradientGrid
         @PUSHI GY @SHL @SHL @SHL @ADD GY    # GY*9
         @ADDI GX @ADD 1
         @PUSHS @AND 0xff
         @POPI TR
      #   = BL GradientGrid[(GY + 1) * GRIDPTS + GX]
         @PUSH GradientGrid
         @PUSHI GY @ADD 1 @SHL @SHL @SHL @ADD GY @ADD 1   # (GY+1)*9
         @ADDI GX
         @PUSHS @AND 0xff
         @POPI BL
      #   = BR GradientGrid[(GY + 1) * GRIDPTS + GX + 1]
         @PUSH GradientGrid
         @PUSHI GY @ADD 1 @SHL @SHL @SHL @ADD GY @ADD 1   # (GY+1)*9
         @ADDI GX @ADD 1
         @PUSHS @AND 0xff
         @POPI BR
      #      ; A = lerp(TL, TR, FX)
         @PUSHI TL @PUSHI TR @PUSHI FX
         @CALL Lerp
         @POPI A1

      #      ; B = lerp(BL, BR, FX)
         @PUSHI BL @PUSHI BR @PUSHI FX
         @CALL Lerp
         @POPI B1

      #      ; V1 = lerp(A, B, FY)
         @PUSHI A1 @PUSHI B1 @PUSHI FY
         @CALL Lerp
         @POPI V1
      #      ; Store value into map[Y * 64 + X]
      @PUSHI Y1 @LSH @LSH @LSH @LSH @LSH @LSH @ADDI X1
      @DUP
      @PUSHS @AND 0xff00         # Get High Byte that's there.
      @PUSHI V1
      @ORS                       # Or in into lowbyte the V1 Value
      @SWP                       
      @POPS
      @INCI X1
    @ENDWHILE
    @INCI Y1
  @ENDWHILE
  @RestoreVar 12
  @RestoreVar 11
  @RestoreVar 10
  @RestoreVar 09
  @RestoreVar 08
  @RestoreVar 07
  @RestoreVar 06
  @RestoreVar 05
  @RestoreVar 04
  @RestoreVar 03
  @RestoreVar 02
  @RestoreVar 01
  @POPRETURN
  @RET


:Lerp
  @PUSHRETURN
  ; Inputs: A B T on stack
  POP T
  POP B
  POP A

  = OneMinusT 128 - T

  PUSH A
  PUSH OneMinusT
  CALL MUL
  POP LeftPart

  PUSH B
  PUSH T
  CALL MUL
  POP RightPart

  = Sum LeftPart + RightPart
  = Result Sum >> 7

  PUSH Result
  @POPRETURN
  @RET


:SeedGradientGrid
  = I 0
  WHILE I < 81 DO
    CALL frnd16
    POP R
    = GradientGrid[I] R & 0xFF
    = I I + 1
  ENDWHILE
  @RET
