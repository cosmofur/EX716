I common.mc


M FPUSH @PUSHI SP @POPS \
        @PUSHI SP @SUB 2 @POPI SP
# FPOP puts on tos value at [SP--2]
M FPOP @PUSHI SP @ADD 2 @DUP \
       @POPI SP \
       @PUSHS
# Swaps the two top values of [SP] and [SP-2]
M FSWP @PUSHI SP @PUSHS \
       @PUSHI SP @ADD 2 @PUSHS \
       @PUSHI SP @POPS \
       @PUSHI SP @ADD 2 @POPS
# BPUSH(tos:x) saves tos:x at [BP] then bp-=2
M BPUSH @PUSHI BP @POPS \
        @PUSHI BP @SUB 2 @POPI BP
# BPOP puts on tos value at [BP--2]
M BPOP @PUSHI BP @ADD 2 @DUP \
       @POPI BP \
       @PUSHS       

# Macro Defines a Dictionary entry, 3 required arguments "String" Lable Flags (must be 0 if not used)
# First create lable named "Word_%2" value is address of previous WORD/LINK
# Second redefind LINK to point to this entry for future entries.
# Next Use special macro funciton %STRLEN to set macro variable %%LEN == length of %1
# Save bytes Length of "String %1" plus value of flags %3
MF LINK 0
M DEFWORD :Word_%2 \
          @LINK \
          MF LINK Word_%2 \
          %STRLEN %1 \
          $$%3+%%LEN \
          %1 \
          :%2


. 0x1000
:Main . Main

@JMP ENDCODE
:Table
@DEFWORD "FooBar" FooBar 0

@DEFWORD "BarFoo" BarFoo 0

:ENDCODE
@END

