#
# here we show how Macros can be stacked together and pass diffrent parameters
#
M Aval %1 %2 %3
M Bval %2 %3 %1
M Cval %3 %1 %2
@Cval 0x10 0x20 0x30 @Bval 0x11 0x21 0x31 @Aval 0x12 0x22 0x32
