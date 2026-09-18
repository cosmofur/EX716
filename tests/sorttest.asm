I common.mc
L softstack.ld

:Main . Main

# GETARRAY( ARRAY_NAME, INDEX)
M GETARRAY @PUSHI %2 @SHL @ADDI %1 @PUSHS
# PUTARRAY( ARRAY_NAME, INDEX, VALUE)
M PUTARRAY @PUSHI %3 @PUSHI %2 @SHL @ADDI %1 @POPS
M PUTARRAYS @PUSHI %2 @SHL @ADDI %1 @POPS

@PRTLN "Start"
@Call(A) PrintTable Table
@Call(A) SortTable Table
@PRTLN "After Sort"
@Call(A) PrintTable Table
@END

:PrintTable
@PUSHRETURN
@Locals
   @Local Index
   @Local TablePtr
   @Local Limit

   @POPI TablePtr

   @PUSHII TablePtr
   @POPI Limit
   @INC2I TablePtr

   @ForIA2V Index 0 Limit
      @GETARRAY TablePtr Index
      @PRTI Index @PRT "> "
      @PRTTOP @PRTNL
      @POPNULL
   @Next Index

@EndLocals
@POPRETURN
@RET

:SortTable
@PUSHRETURN
@Locals
   @Local Left
   @Local Right
   @Local TablePtr

   @POPI TablePtr

   @MA2V 0 Left
   @PUSHII TablePtr
   @SUB 1
   @POPI Right
   
   @INC2I TablePtr     # First element is size, so move to data part

   @Call(VVV) QuickSort TablePtr Left Right
@EndLocals
@POPRETURN
@RET

:QuickSort
@PUSHRETURN
@Locals
   @Local Array
   @Local Left
   @Local Right
   @Local PivotIndex
   @Local TempRight
   @Local TempLeft

   @POPI3 Right Left Array

   @PUSHI Left
   @IF_LT_V Right
      @POPNULL

      @PRT "QS left=" @PRTI Left @PRT " Right=" @PRTI Right @PRTNL

      @Call(VVV) Partition Array Left Right
      @POPI PivotIndex

      @PRT "PivotIndex=" @PRTI PivotIndex @PRT " CallerLeft=" @PRTI Left @PRT " CallerRight=" @PRTI Right @PRTNL

      # QuickSort(Array, Left, PivotIndex - 1)
      @PUSHI PivotIndex
      @SUB 1
      @POPI TempRight
      @Call(VVV) QuickSort Array Left TempRight

      # QuickSort(Array, PivotIndex + 1, Right)
      @PUSHI PivotIndex
      @ADD 1
      @POPI TempLeft
      @Call(VVV) QuickSort Array TempLeft Right

   @ELSE
      @POPNULL
   @ENDIF

@EndLocals
@POPRETURN
@RET

:Partition
@PUSHRETURN
@Locals
   @Local Array
   @Local Left
   @Local Right
   @Local Pivot
   @Local Index
   @Local Jndex
   @POPI3 Right Left Array

   @GETARRAY Array Right
   @POPI Pivot

   
   @PUSHI Left @SUB 1
   @POPI Index

   @ForIV2V Jndex Left Right
      @GETARRAY Array Jndex
      @IF_LE_V Pivot
         @INCI Index
         @GETARRAY Array Index
         @GETARRAY Array Jndex
         @PUTARRAYS Array Index
         @PUTARRAYS Array Jndex
      @ENDIF
   @Next Jndex
   @INCI Index
   @GETARRAY Array Index
   @GETARRAY Array Right
   @PUTARRAYS Array Index
   @PUTARRAYS Array Right

   @PUSHI Index
@EndLocals
@POPRETURN
@RET

   
:Table
6      # Size
101
120
105
130
115
105

