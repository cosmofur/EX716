# Verify :: data labels, inferred initializer widths, and repeated initializers
# in a CPU24 data bank.
.DATA 1
I commonDS.mc

::ByteValue $$0x12
::WordValues 0x3456 * 2
::LongValue $$$0x89abcdef
::TextValue "AB\0"
::MixedValue "XY\0"
::InlineByte $$0xaa ::InlineWord 0xbbbb
::MyCityInfo "New York\0" ::__ "123 -Pie Avenue\0" ::__ "01001\0" ::__ "Two dogs and three cats\0" ::AfterCity $$0

.ORG 0x0100
:Main
@PUSH 1
@SSET SegDS
@PUSH 1
@ADM

@PRT "Layout: "
@PUSH WordValues @SUB ByteValue @PRTHEXTOP @POPNULL
@PRT " "
@PUSH LongValue @SUB WordValues @PRTHEXTOP @POPNULL
@PRT " "
@PUSH TextValue @SUB LongValue @PRTHEXTOP @POPNULL
@PRT " "
@PUSH MixedValue @SUB TextValue @PRTHEXTOP @POPNULL
@PRT " "
@PUSH InlineWord @SUB InlineByte @PRTHEXTOP @POPNULL
@PRT " "
@PUSH AfterCity @SUB MyCityInfo @PRTHEXTOP @POPNULL
@PRTNL

@PRT "Values: "
@PUSHI ByteValue @AND 0xff @PRTHEXTOP @POPNULL
@PRT " "
@PRTHEXI WordValues
@PRT " "
@PRTHEXI WordValues+2
@PRT " "
@PRTHEXI LongValue
@PRT " "
@PRTHEXI LongValue+2
@PRT " "
@PRTHEXI TextValue
@PRT " "
@PUSHI TextValue+2 @AND 0xff @PRTHEXTOP @POPNULL
@PRT " "
@PUSHI InlineByte @AND 0xff @PRTHEXTOP @POPNULL
@PRT " "
@PRTHEXI InlineWord
@PRTNL

@PUSH 0
@ADM
@END
