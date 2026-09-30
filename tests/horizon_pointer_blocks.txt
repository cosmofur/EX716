# Deduplicated ASCII horizon database draft
# 29 bank blocks; 19 row pointers per block;
# 191 unique strings of 39 characters plus terminator.
# Display 11 rows beginning at pointer index 4 - PitchValue.
# Space = sky; dot = ground; /, \, -, | = horizon.
# Single-quoted rows are raw: backslashes are literal characters.

# Label runs: S=sky, G=ground, F=/, B=backslash, H=-, V=|.
# Example: HorizonRow_G19_V1_S19 has 19 dots, |, then 19 spaces.
# Shared row strings
:HorizonRow_G19_V1_S19 '...................|                   ' $$0  # used 19 times
:HorizonRow_G17_B1_S21 '.................\                     ' $$0  # used 7 times
:HorizonRow_G18_B1_S20 '..................\                    ' $$0  # used 12 times
:HorizonRow_G19_B1_S19 '...................\                   ' $$0  # used 13 times
:HorizonRow_G20_B1_S18 '....................\                  ' $$0  # used 12 times
:HorizonRow_G21_B1_S17 '.....................\                 ' $$0  # used 7 times
:HorizonRow_G16_B1_S22 '................\                      ' $$0  # used 7 times
:HorizonRow_G22_B1_S16 '......................\                ' $$0  # used 7 times
:HorizonRow_G14_B1_S24 '..............\                        ' $$0  # used 4 times
:HorizonRow_G15_B1_S23 '...............\                       ' $$0  # used 4 times
:HorizonRow_G18_B2_S19 '..................\\                   ' $$0  # used 1 times
:HorizonRow_G19_B2_S18 '...................\\                  ' $$0  # used 1 times
:HorizonRow_G23_B1_S15 '.......................\               ' $$0  # used 4 times
:HorizonRow_G24_B1_S14 '........................\              ' $$0  # used 4 times
:HorizonRow_G12_B1_S26 '............\                          ' $$0  # used 2 times
:HorizonRow_G13_B1_S25 '.............\                         ' $$0  # used 3 times
:HorizonRow_G14_B2_S23 '..............\\                       ' $$0  # used 2 times
:HorizonRow_G17_B2_S20 '.................\\                    ' $$0  # used 3 times
:HorizonRow_G20_B2_S17 '....................\\                 ' $$0  # used 3 times
:HorizonRow_G23_B2_S14 '.......................\\              ' $$0  # used 2 times
:HorizonRow_G25_B1_S13 '.........................\             ' $$0  # used 3 times
:HorizonRow_G26_B1_S12 '..........................\            ' $$0  # used 2 times
:HorizonRow_G10_B1_S28 '..........\                            ' $$0  # used 1 times
:HorizonRow_G11_B1_S27 '...........\                           ' $$0  # used 2 times
:HorizonRow_G27_B1_S11 '...........................\           ' $$0  # used 2 times
:HorizonRow_G28_B1_S10 '............................\          ' $$0  # used 1 times
:HorizonRow_G8_B1_S30 '........\                              ' $$0  # used 1 times
:HorizonRow_G9_B1_S29 '.........\                             ' $$0  # used 1 times
:HorizonRow_G10_B2_S27 '..........\\                           ' $$0  # used 2 times
:HorizonRow_G11_B2_S26 '...........\\                          ' $$0  # used 1 times
:HorizonRow_G15_B2_S22 '...............\\                      ' $$0  # used 2 times
:HorizonRow_G16_B2_S21 '................\\                     ' $$0  # used 1 times
:HorizonRow_G21_B2_S16 '.....................\\                ' $$0  # used 1 times
:HorizonRow_G22_B2_S15 '......................\\               ' $$0  # used 2 times
:HorizonRow_G26_B2_S11 '..........................\\           ' $$0  # used 1 times
:HorizonRow_G27_B2_S10 '...........................\\          ' $$0  # used 2 times
:HorizonRow_G29_B1_S9 '.............................\         ' $$0  # used 1 times
:HorizonRow_G30_B1_S8 '..............................\        ' $$0  # used 1 times
:HorizonRow_G4_B2_S33 '....\\                                 ' $$0  # used 2 times
:HorizonRow_G6_B2_S31 '......\\                               ' $$0  # used 2 times
:HorizonRow_G7_B2_S30 '.......\\                              ' $$0  # used 1 times
:HorizonRow_G9_B2_S28 '.........\\                            ' $$0  # used 1 times
:HorizonRow_G12_B2_S25 '............\\                         ' $$0  # used 2 times
:HorizonRow_G25_B2_S12 '.........................\\            ' $$0  # used 2 times
:HorizonRow_G28_B2_S9 '............................\\         ' $$0  # used 1 times
:HorizonRow_G30_B2_S7 '..............................\\       ' $$0  # used 1 times
:HorizonRow_G31_B2_S6 '...............................\\      ' $$0  # used 2 times
:HorizonRow_G33_B2_S4 '.................................\\    ' $$0  # used 2 times
:HorizonRow_B2_S37 '\\                                     ' $$0  # used 3 times
:HorizonRow_G2_B2_S35 '..\\                                   ' $$0  # used 2 times
:HorizonRow_G8_B2_S29 '........\\                             ' $$0  # used 1 times
:HorizonRow_G14_B3_S22 '..............\\\                      ' $$0  # used 1 times
:HorizonRow_G16_B3_S20 '................\\\                    ' $$0  # used 1 times
:HorizonRow_G18_B3_S18 '..................\\\                  ' $$0  # used 3 times
:HorizonRow_G20_B3_S16 '....................\\\                ' $$0  # used 1 times
:HorizonRow_G22_B3_S14 '......................\\\              ' $$0  # used 1 times
:HorizonRow_G29_B2_S8 '.............................\\        ' $$0  # used 1 times
:HorizonRow_G35_B2_S2 '...................................\\  ' $$0  # used 2 times
:HorizonRow_G37_B2 '.....................................\\' $$0  # used 3 times
:HorizonRow_S39 '                                       ' $$0  # used 59 times
:HorizonRow_G4_B3_S32 '....\\\                                ' $$0  # used 2 times
:HorizonRow_G7_B3_S29 '.......\\\                             ' $$0  # used 1 times
:HorizonRow_G10_B3_S26 '..........\\\                          ' $$0  # used 1 times
:HorizonRow_G13_B2_S24 '.............\\                        ' $$0  # used 1 times
:HorizonRow_G15_B3_S21 '...............\\\                     ' $$0  # used 1 times
:HorizonRow_G21_B3_S15 '.....................\\\               ' $$0  # used 1 times
:HorizonRow_G24_B2_S13 '........................\\             ' $$0  # used 1 times
:HorizonRow_G26_B3_S10 '..........................\\\          ' $$0  # used 1 times
:HorizonRow_G29_B3_S7 '.............................\\\       ' $$0  # used 1 times
:HorizonRow_G32_B3_S4 '................................\\\    ' $$0  # used 2 times
:HorizonRow_G39 '.......................................' $$0  # used 59 times
:HorizonRow_B4_S35 '\\\\                                   ' $$0  # used 1 times
:HorizonRow_G7_B4_S28 '.......\\\\                            ' $$0  # used 1 times
:HorizonRow_G11_B3_S25 '...........\\\                         ' $$0  # used 1 times
:HorizonRow_G14_B4_S21 '..............\\\\                     ' $$0  # used 1 times
:HorizonRow_G21_B4_S14 '.....................\\\\              ' $$0  # used 1 times
:HorizonRow_G25_B3_S11 '.........................\\\           ' $$0  # used 1 times
:HorizonRow_G28_B4_S7 '............................\\\\       ' $$0  # used 1 times
:HorizonRow_G35_B4 '...................................\\\\' $$0  # used 1 times
:HorizonRow_B3_S36 '\\\                                    ' $$0  # used 1 times
:HorizonRow_G3_B5_S31 '...\\\\\                               ' $$0  # used 1 times
:HorizonRow_G8_B4_S27 '........\\\\                           ' $$0  # used 1 times
:HorizonRow_G12_B5_S22 '............\\\\\                      ' $$0  # used 1 times
:HorizonRow_G17_B5_S17 '.................\\\\\                 ' $$0  # used 1 times
:HorizonRow_G22_B5_S12 '......................\\\\\            ' $$0  # used 1 times
:HorizonRow_G27_B4_S8 '...........................\\\\        ' $$0  # used 1 times
:HorizonRow_G31_B5_S3 '...............................\\\\\   ' $$0  # used 1 times
:HorizonRow_G36_B3 '....................................\\\' $$0  # used 1 times
:HorizonRow_G2_B7_S30 '..\\\\\\\                              ' $$0  # used 1 times
:HorizonRow_G9_B7_S23 '.........\\\\\\\                       ' $$0  # used 1 times
:HorizonRow_G16_B7_S16 '................\\\\\\\                ' $$0  # used 1 times
:HorizonRow_G23_B7_S9 '.......................\\\\\\\         ' $$0  # used 1 times
:HorizonRow_G30_B7_S2 '..............................\\\\\\\  ' $$0  # used 1 times
:HorizonRow_B12_S27 '\\\\\\\\\\\\                           ' $$0  # used 1 times
:HorizonRow_G12_B15_S12 '............\\\\\\\\\\\\\\\            ' $$0  # used 1 times
:HorizonRow_G27_B12 '...........................\\\\\\\\\\\\' $$0  # used 1 times
:HorizonRow_H39 '---------------------------------------' $$0  # used 1 times
:HorizonRow_S27_F12 '                           ////////////' $$0  # used 1 times
:HorizonRow_S12_F15_G12 '            ///////////////............' $$0  # used 1 times
:HorizonRow_F12_G27 '////////////...........................' $$0  # used 1 times
:HorizonRow_S37_F2 '                                     //' $$0  # used 3 times
:HorizonRow_S30_F7_G2 '                              ///////..' $$0  # used 1 times
:HorizonRow_S23_F7_G9 '                       ///////.........' $$0  # used 1 times
:HorizonRow_S16_F7_G16 '                ///////................' $$0  # used 1 times
:HorizonRow_S9_F7_G23 '         ///////.......................' $$0  # used 1 times
:HorizonRow_S2_F7_G30 '  ///////..............................' $$0  # used 1 times
:HorizonRow_F2_G37 '//.....................................' $$0  # used 3 times
:HorizonRow_S36_F3 '                                    ///' $$0  # used 1 times
:HorizonRow_S31_F5_G3 '                               /////...' $$0  # used 1 times
:HorizonRow_S27_F4_G8 '                           ////........' $$0  # used 1 times
:HorizonRow_S22_F5_G12 '                      /////............' $$0  # used 1 times
:HorizonRow_S17_F5_G17 '                 /////.................' $$0  # used 1 times
:HorizonRow_S12_F5_G22 '            /////......................' $$0  # used 1 times
:HorizonRow_S8_F4_G27 '        ////...........................' $$0  # used 1 times
:HorizonRow_S3_F5_G31 '   /////...............................' $$0  # used 1 times
:HorizonRow_F3_G36 '///....................................' $$0  # used 1 times
:HorizonRow_S35_F4 '                                   ////' $$0  # used 1 times
:HorizonRow_S32_F3_G4 '                                ///....' $$0  # used 2 times
:HorizonRow_S28_F4_G7 '                            ////.......' $$0  # used 1 times
:HorizonRow_S25_F3_G11 '                         ///...........' $$0  # used 1 times
:HorizonRow_S21_F4_G14 '                     ////..............' $$0  # used 1 times
:HorizonRow_S18_F3_G18 '                  ///..................' $$0  # used 3 times
:HorizonRow_S14_F4_G21 '              ////.....................' $$0  # used 1 times
:HorizonRow_S11_F3_G25 '           ///.........................' $$0  # used 1 times
:HorizonRow_S7_F4_G28 '       ////............................' $$0  # used 1 times
:HorizonRow_S4_F3_G32 '    ///................................' $$0  # used 2 times
:HorizonRow_F4_G35 '////...................................' $$0  # used 1 times
:HorizonRow_S35_F2_G2 '                                   //..' $$0  # used 2 times
:HorizonRow_S29_F3_G7 '                             ///.......' $$0  # used 1 times
:HorizonRow_S26_F3_G10 '                          ///..........' $$0  # used 1 times
:HorizonRow_S24_F2_G13 '                        //.............' $$0  # used 1 times
:HorizonRow_S21_F3_G15 '                     ///...............' $$0  # used 1 times
:HorizonRow_S15_F3_G21 '               ///.....................' $$0  # used 1 times
:HorizonRow_S13_F2_G24 '             //........................' $$0  # used 1 times
:HorizonRow_S10_F3_G26 '          ///..........................' $$0  # used 1 times
:HorizonRow_S7_F3_G29 '       ///.............................' $$0  # used 1 times
:HorizonRow_S2_F2_G35 '  //...................................' $$0  # used 2 times
:HorizonRow_S33_F2_G4 '                                 //....' $$0  # used 2 times
:HorizonRow_S31_F2_G6 '                               //......' $$0  # used 2 times
:HorizonRow_S29_F2_G8 '                             //........' $$0  # used 1 times
:HorizonRow_S27_F2_G10 '                           //..........' $$0  # used 2 times
:HorizonRow_S25_F2_G12 '                         //............' $$0  # used 2 times
:HorizonRow_S22_F3_G14 '                      ///..............' $$0  # used 1 times
:HorizonRow_S20_F3_G16 '                    ///................' $$0  # used 1 times
:HorizonRow_S16_F3_G20 '                ///....................' $$0  # used 1 times
:HorizonRow_S14_F3_G22 '              ///......................' $$0  # used 1 times
:HorizonRow_S12_F2_G25 '            //.........................' $$0  # used 2 times
:HorizonRow_S10_F2_G27 '          //...........................' $$0  # used 2 times
:HorizonRow_S8_F2_G29 '        //.............................' $$0  # used 1 times
:HorizonRow_S6_F2_G31 '      //...............................' $$0  # used 2 times
:HorizonRow_S4_F2_G33 '    //.................................' $$0  # used 2 times
:HorizonRow_S30_F2_G7 '                              //.......' $$0  # used 1 times
:HorizonRow_S28_F2_G9 '                            //.........' $$0  # used 1 times
:HorizonRow_S27_F1_G11 '                           /...........' $$0  # used 2 times
:HorizonRow_S23_F2_G14 '                       //..............' $$0  # used 2 times
:HorizonRow_S22_F2_G15 '                      //...............' $$0  # used 2 times
:HorizonRow_S20_F2_G17 '                    //.................' $$0  # used 3 times
:HorizonRow_S19_F1_G19 '                   /...................' $$0  # used 13 times
:HorizonRow_S17_F2_G20 '                 //....................' $$0  # used 3 times
:HorizonRow_S15_F2_G22 '               //......................' $$0  # used 2 times
:HorizonRow_S14_F2_G23 '              //.......................' $$0  # used 2 times
:HorizonRow_S11_F1_G27 '           /...........................' $$0  # used 2 times
:HorizonRow_S9_F2_G28 '         //............................' $$0  # used 1 times
:HorizonRow_S7_F2_G30 '       //..............................' $$0  # used 1 times
:HorizonRow_S30_F1_G8 '                              /........' $$0  # used 1 times
:HorizonRow_S29_F1_G9 '                             /.........' $$0  # used 1 times
:HorizonRow_S26_F2_G11 '                          //...........' $$0  # used 1 times
:HorizonRow_S25_F1_G13 '                         /.............' $$0  # used 3 times
:HorizonRow_S24_F1_G14 '                        /..............' $$0  # used 4 times
:HorizonRow_S21_F2_G16 '                     //................' $$0  # used 1 times
:HorizonRow_S16_F2_G21 '                //.....................' $$0  # used 1 times
:HorizonRow_S14_F1_G24 '              /........................' $$0  # used 4 times
:HorizonRow_S13_F1_G25 '             /.........................' $$0  # used 3 times
:HorizonRow_S11_F2_G26 '           //..........................' $$0  # used 1 times
:HorizonRow_S9_F1_G29 '         /.............................' $$0  # used 1 times
:HorizonRow_S8_F1_G30 '        /..............................' $$0  # used 1 times
:HorizonRow_S28_F1_G10 '                            /..........' $$0  # used 1 times
:HorizonRow_S26_F1_G12 '                          /............' $$0  # used 2 times
:HorizonRow_S23_F1_G15 '                       /...............' $$0  # used 4 times
:HorizonRow_S22_F1_G16 '                      /................' $$0  # used 7 times
:HorizonRow_S21_F1_G17 '                     /.................' $$0  # used 7 times
:HorizonRow_S20_F1_G18 '                    /..................' $$0  # used 12 times
:HorizonRow_S18_F1_G20 '                  /....................' $$0  # used 12 times
:HorizonRow_S17_F1_G21 '                 /.....................' $$0  # used 7 times
:HorizonRow_S16_F1_G22 '                /......................' $$0  # used 7 times
:HorizonRow_S15_F1_G23 '               /.......................' $$0  # used 4 times
:HorizonRow_S12_F1_G26 '            /..........................' $$0  # used 2 times
:HorizonRow_S10_F1_G28 '          /............................' $$0  # used 1 times
:HorizonRow_S19_F2_G18 '                   //..................' $$0  # used 1 times
:HorizonRow_S18_F2_G19 '                  //...................' $$0  # used 1 times
:HorizonRow_S19_V1_G19 '                   |...................' $$0  # used 19 times

# Angle lookup: signed degrees, then matching block pointers
:HorizonAngles
   -90
   -80
   -70
   -62
   -53
   -45
   -39
   -32
   -26
   -20
   -16
   -12
   -8
   -4
   0
   4
   8
   12
   16
   20
   26
   32
   39
   45
   53
   62
   70
   80
   90

:HorizonBankPointers
   HorizonBank_M90
   HorizonBank_M80
   HorizonBank_M70
   HorizonBank_M62
   HorizonBank_M53
   HorizonBank_M45
   HorizonBank_M39
   HorizonBank_M32
   HorizonBank_M26
   HorizonBank_M20
   HorizonBank_M16
   HorizonBank_M12
   HorizonBank_M08
   HorizonBank_M04
   HorizonBank_P00
   HorizonBank_P04
   HorizonBank_P08
   HorizonBank_P12
   HorizonBank_P16
   HorizonBank_P20
   HorizonBank_P26
   HorizonBank_P32
   HorizonBank_P39
   HorizonBank_P45
   HorizonBank_P53
   HorizonBank_P62
   HorizonBank_P70
   HorizonBank_P80
   HorizonBank_P90

# Bank -90 degrees
:HorizonBank_M90
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19
   HorizonRow_G19_V1_S19

# Bank -80 degrees
:HorizonBank_M80
   HorizonRow_G17_B1_S21
   HorizonRow_G18_B1_S20
   HorizonRow_G18_B1_S20
   HorizonRow_G18_B1_S20
   HorizonRow_G18_B1_S20
   HorizonRow_G18_B1_S20
   HorizonRow_G18_B1_S20
   HorizonRow_G19_B1_S19
   HorizonRow_G19_B1_S19
   HorizonRow_G19_B1_S19
   HorizonRow_G19_B1_S19
   HorizonRow_G19_B1_S19
   HorizonRow_G20_B1_S18
   HorizonRow_G20_B1_S18
   HorizonRow_G20_B1_S18
   HorizonRow_G20_B1_S18
   HorizonRow_G20_B1_S18
   HorizonRow_G20_B1_S18
   HorizonRow_G21_B1_S17

# Bank -70 degrees
:HorizonBank_M70
   HorizonRow_G16_B1_S22
   HorizonRow_G16_B1_S22
   HorizonRow_G16_B1_S22
   HorizonRow_G17_B1_S21
   HorizonRow_G17_B1_S21
   HorizonRow_G18_B1_S20
   HorizonRow_G18_B1_S20
   HorizonRow_G18_B1_S20
   HorizonRow_G19_B1_S19
   HorizonRow_G19_B1_S19
   HorizonRow_G19_B1_S19
   HorizonRow_G20_B1_S18
   HorizonRow_G20_B1_S18
   HorizonRow_G20_B1_S18
   HorizonRow_G21_B1_S17
   HorizonRow_G21_B1_S17
   HorizonRow_G22_B1_S16
   HorizonRow_G22_B1_S16
   HorizonRow_G22_B1_S16

# Bank -62 degrees
:HorizonBank_M62
   HorizonRow_G14_B1_S24
   HorizonRow_G15_B1_S23
   HorizonRow_G15_B1_S23
   HorizonRow_G16_B1_S22
   HorizonRow_G16_B1_S22
   HorizonRow_G17_B1_S21
   HorizonRow_G17_B1_S21
   HorizonRow_G18_B1_S20
   HorizonRow_G18_B2_S19
   HorizonRow_G19_B1_S19
   HorizonRow_G19_B2_S18
   HorizonRow_G20_B1_S18
   HorizonRow_G21_B1_S17
   HorizonRow_G21_B1_S17
   HorizonRow_G22_B1_S16
   HorizonRow_G22_B1_S16
   HorizonRow_G23_B1_S15
   HorizonRow_G23_B1_S15
   HorizonRow_G24_B1_S14

# Bank -53 degrees
:HorizonBank_M53
   HorizonRow_G12_B1_S26
   HorizonRow_G13_B1_S25
   HorizonRow_G14_B1_S24
   HorizonRow_G14_B2_S23
   HorizonRow_G15_B1_S23
   HorizonRow_G16_B1_S22
   HorizonRow_G17_B1_S21
   HorizonRow_G17_B2_S20
   HorizonRow_G18_B1_S20
   HorizonRow_G19_B1_S19
   HorizonRow_G20_B1_S18
   HorizonRow_G20_B2_S17
   HorizonRow_G21_B1_S17
   HorizonRow_G22_B1_S16
   HorizonRow_G23_B1_S15
   HorizonRow_G23_B2_S14
   HorizonRow_G24_B1_S14
   HorizonRow_G25_B1_S13
   HorizonRow_G26_B1_S12

# Bank -45 degrees
:HorizonBank_M45
   HorizonRow_G10_B1_S28
   HorizonRow_G11_B1_S27
   HorizonRow_G12_B1_S26
   HorizonRow_G13_B1_S25
   HorizonRow_G14_B1_S24
   HorizonRow_G15_B1_S23
   HorizonRow_G16_B1_S22
   HorizonRow_G17_B1_S21
   HorizonRow_G18_B1_S20
   HorizonRow_G19_B1_S19
   HorizonRow_G20_B1_S18
   HorizonRow_G21_B1_S17
   HorizonRow_G22_B1_S16
   HorizonRow_G23_B1_S15
   HorizonRow_G24_B1_S14
   HorizonRow_G25_B1_S13
   HorizonRow_G26_B1_S12
   HorizonRow_G27_B1_S11
   HorizonRow_G28_B1_S10

# Bank -39 degrees
:HorizonBank_M39
   HorizonRow_G8_B1_S30
   HorizonRow_G9_B1_S29
   HorizonRow_G10_B2_S27
   HorizonRow_G11_B2_S26
   HorizonRow_G13_B1_S25
   HorizonRow_G14_B1_S24
   HorizonRow_G15_B2_S22
   HorizonRow_G16_B2_S21
   HorizonRow_G17_B2_S20
   HorizonRow_G19_B1_S19
   HorizonRow_G20_B2_S17
   HorizonRow_G21_B2_S16
   HorizonRow_G22_B2_S15
   HorizonRow_G24_B1_S14
   HorizonRow_G25_B1_S13
   HorizonRow_G26_B2_S11
   HorizonRow_G27_B2_S10
   HorizonRow_G29_B1_S9
   HorizonRow_G30_B1_S8

# Bank -32 degrees
:HorizonBank_M32
   HorizonRow_G4_B2_S33
   HorizonRow_G6_B2_S31
   HorizonRow_G7_B2_S30
   HorizonRow_G9_B2_S28
   HorizonRow_G11_B1_S27
   HorizonRow_G12_B2_S25
   HorizonRow_G14_B2_S23
   HorizonRow_G15_B2_S22
   HorizonRow_G17_B2_S20
   HorizonRow_G19_B1_S19
   HorizonRow_G20_B2_S17
   HorizonRow_G22_B2_S15
   HorizonRow_G23_B2_S14
   HorizonRow_G25_B2_S12
   HorizonRow_G27_B1_S11
   HorizonRow_G28_B2_S9
   HorizonRow_G30_B2_S7
   HorizonRow_G31_B2_S6
   HorizonRow_G33_B2_S4

# Bank -26 degrees
:HorizonBank_M26
   HorizonRow_B2_S37
   HorizonRow_G2_B2_S35
   HorizonRow_G4_B2_S33
   HorizonRow_G6_B2_S31
   HorizonRow_G8_B2_S29
   HorizonRow_G10_B2_S27
   HorizonRow_G12_B2_S25
   HorizonRow_G14_B3_S22
   HorizonRow_G16_B3_S20
   HorizonRow_G18_B3_S18
   HorizonRow_G20_B3_S16
   HorizonRow_G22_B3_S14
   HorizonRow_G25_B2_S12
   HorizonRow_G27_B2_S10
   HorizonRow_G29_B2_S8
   HorizonRow_G31_B2_S6
   HorizonRow_G33_B2_S4
   HorizonRow_G35_B2_S2
   HorizonRow_G37_B2

# Bank -20 degrees
:HorizonBank_M20
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_B2_S37
   HorizonRow_G2_B2_S35
   HorizonRow_G4_B3_S32
   HorizonRow_G7_B3_S29
   HorizonRow_G10_B3_S26
   HorizonRow_G13_B2_S24
   HorizonRow_G15_B3_S21
   HorizonRow_G18_B3_S18
   HorizonRow_G21_B3_S15
   HorizonRow_G24_B2_S13
   HorizonRow_G26_B3_S10
   HorizonRow_G29_B3_S7
   HorizonRow_G32_B3_S4
   HorizonRow_G35_B2_S2
   HorizonRow_G37_B2
   HorizonRow_G39
   HorizonRow_G39

# Bank -16 degrees
:HorizonBank_M16
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_B4_S35
   HorizonRow_G4_B3_S32
   HorizonRow_G7_B4_S28
   HorizonRow_G11_B3_S25
   HorizonRow_G14_B4_S21
   HorizonRow_G18_B3_S18
   HorizonRow_G21_B4_S14
   HorizonRow_G25_B3_S11
   HorizonRow_G28_B4_S7
   HorizonRow_G32_B3_S4
   HorizonRow_G35_B4
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39

# Bank -12 degrees
:HorizonBank_M12
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_B3_S36
   HorizonRow_G3_B5_S31
   HorizonRow_G8_B4_S27
   HorizonRow_G12_B5_S22
   HorizonRow_G17_B5_S17
   HorizonRow_G22_B5_S12
   HorizonRow_G27_B4_S8
   HorizonRow_G31_B5_S3
   HorizonRow_G36_B3
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39

# Bank -8 degrees
:HorizonBank_M08
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_B2_S37
   HorizonRow_G2_B7_S30
   HorizonRow_G9_B7_S23
   HorizonRow_G16_B7_S16
   HorizonRow_G23_B7_S9
   HorizonRow_G30_B7_S2
   HorizonRow_G37_B2
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39

# Bank -4 degrees
:HorizonBank_M04
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_B12_S27
   HorizonRow_G12_B15_S12
   HorizonRow_G27_B12
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39

# Bank +0 degrees
:HorizonBank_P00
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_H39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39

# Bank +4 degrees
:HorizonBank_P04
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S27_F12
   HorizonRow_S12_F15_G12
   HorizonRow_F12_G27
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39

# Bank +8 degrees
:HorizonBank_P08
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S37_F2
   HorizonRow_S30_F7_G2
   HorizonRow_S23_F7_G9
   HorizonRow_S16_F7_G16
   HorizonRow_S9_F7_G23
   HorizonRow_S2_F7_G30
   HorizonRow_F2_G37
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39

# Bank +12 degrees
:HorizonBank_P12
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S36_F3
   HorizonRow_S31_F5_G3
   HorizonRow_S27_F4_G8
   HorizonRow_S22_F5_G12
   HorizonRow_S17_F5_G17
   HorizonRow_S12_F5_G22
   HorizonRow_S8_F4_G27
   HorizonRow_S3_F5_G31
   HorizonRow_F3_G36
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39

# Bank +16 degrees
:HorizonBank_P16
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S35_F4
   HorizonRow_S32_F3_G4
   HorizonRow_S28_F4_G7
   HorizonRow_S25_F3_G11
   HorizonRow_S21_F4_G14
   HorizonRow_S18_F3_G18
   HorizonRow_S14_F4_G21
   HorizonRow_S11_F3_G25
   HorizonRow_S7_F4_G28
   HorizonRow_S4_F3_G32
   HorizonRow_F4_G35
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39
   HorizonRow_G39

# Bank +20 degrees
:HorizonBank_P20
   HorizonRow_S39
   HorizonRow_S39
   HorizonRow_S37_F2
   HorizonRow_S35_F2_G2
   HorizonRow_S32_F3_G4
   HorizonRow_S29_F3_G7
   HorizonRow_S26_F3_G10
   HorizonRow_S24_F2_G13
   HorizonRow_S21_F3_G15
   HorizonRow_S18_F3_G18
   HorizonRow_S15_F3_G21
   HorizonRow_S13_F2_G24
   HorizonRow_S10_F3_G26
   HorizonRow_S7_F3_G29
   HorizonRow_S4_F3_G32
   HorizonRow_S2_F2_G35
   HorizonRow_F2_G37
   HorizonRow_G39
   HorizonRow_G39

# Bank +26 degrees
:HorizonBank_P26
   HorizonRow_S37_F2
   HorizonRow_S35_F2_G2
   HorizonRow_S33_F2_G4
   HorizonRow_S31_F2_G6
   HorizonRow_S29_F2_G8
   HorizonRow_S27_F2_G10
   HorizonRow_S25_F2_G12
   HorizonRow_S22_F3_G14
   HorizonRow_S20_F3_G16
   HorizonRow_S18_F3_G18
   HorizonRow_S16_F3_G20
   HorizonRow_S14_F3_G22
   HorizonRow_S12_F2_G25
   HorizonRow_S10_F2_G27
   HorizonRow_S8_F2_G29
   HorizonRow_S6_F2_G31
   HorizonRow_S4_F2_G33
   HorizonRow_S2_F2_G35
   HorizonRow_F2_G37

# Bank +32 degrees
:HorizonBank_P32
   HorizonRow_S33_F2_G4
   HorizonRow_S31_F2_G6
   HorizonRow_S30_F2_G7
   HorizonRow_S28_F2_G9
   HorizonRow_S27_F1_G11
   HorizonRow_S25_F2_G12
   HorizonRow_S23_F2_G14
   HorizonRow_S22_F2_G15
   HorizonRow_S20_F2_G17
   HorizonRow_S19_F1_G19
   HorizonRow_S17_F2_G20
   HorizonRow_S15_F2_G22
   HorizonRow_S14_F2_G23
   HorizonRow_S12_F2_G25
   HorizonRow_S11_F1_G27
   HorizonRow_S9_F2_G28
   HorizonRow_S7_F2_G30
   HorizonRow_S6_F2_G31
   HorizonRow_S4_F2_G33

# Bank +39 degrees
:HorizonBank_P39
   HorizonRow_S30_F1_G8
   HorizonRow_S29_F1_G9
   HorizonRow_S27_F2_G10
   HorizonRow_S26_F2_G11
   HorizonRow_S25_F1_G13
   HorizonRow_S24_F1_G14
   HorizonRow_S22_F2_G15
   HorizonRow_S21_F2_G16
   HorizonRow_S20_F2_G17
   HorizonRow_S19_F1_G19
   HorizonRow_S17_F2_G20
   HorizonRow_S16_F2_G21
   HorizonRow_S15_F2_G22
   HorizonRow_S14_F1_G24
   HorizonRow_S13_F1_G25
   HorizonRow_S11_F2_G26
   HorizonRow_S10_F2_G27
   HorizonRow_S9_F1_G29
   HorizonRow_S8_F1_G30

# Bank +45 degrees
:HorizonBank_P45
   HorizonRow_S28_F1_G10
   HorizonRow_S27_F1_G11
   HorizonRow_S26_F1_G12
   HorizonRow_S25_F1_G13
   HorizonRow_S24_F1_G14
   HorizonRow_S23_F1_G15
   HorizonRow_S22_F1_G16
   HorizonRow_S21_F1_G17
   HorizonRow_S20_F1_G18
   HorizonRow_S19_F1_G19
   HorizonRow_S18_F1_G20
   HorizonRow_S17_F1_G21
   HorizonRow_S16_F1_G22
   HorizonRow_S15_F1_G23
   HorizonRow_S14_F1_G24
   HorizonRow_S13_F1_G25
   HorizonRow_S12_F1_G26
   HorizonRow_S11_F1_G27
   HorizonRow_S10_F1_G28

# Bank +53 degrees
:HorizonBank_P53
   HorizonRow_S26_F1_G12
   HorizonRow_S25_F1_G13
   HorizonRow_S24_F1_G14
   HorizonRow_S23_F2_G14
   HorizonRow_S23_F1_G15
   HorizonRow_S22_F1_G16
   HorizonRow_S21_F1_G17
   HorizonRow_S20_F2_G17
   HorizonRow_S20_F1_G18
   HorizonRow_S19_F1_G19
   HorizonRow_S18_F1_G20
   HorizonRow_S17_F2_G20
   HorizonRow_S17_F1_G21
   HorizonRow_S16_F1_G22
   HorizonRow_S15_F1_G23
   HorizonRow_S14_F2_G23
   HorizonRow_S14_F1_G24
   HorizonRow_S13_F1_G25
   HorizonRow_S12_F1_G26

# Bank +62 degrees
:HorizonBank_P62
   HorizonRow_S24_F1_G14
   HorizonRow_S23_F1_G15
   HorizonRow_S23_F1_G15
   HorizonRow_S22_F1_G16
   HorizonRow_S22_F1_G16
   HorizonRow_S21_F1_G17
   HorizonRow_S21_F1_G17
   HorizonRow_S20_F1_G18
   HorizonRow_S19_F2_G18
   HorizonRow_S19_F1_G19
   HorizonRow_S18_F2_G19
   HorizonRow_S18_F1_G20
   HorizonRow_S17_F1_G21
   HorizonRow_S17_F1_G21
   HorizonRow_S16_F1_G22
   HorizonRow_S16_F1_G22
   HorizonRow_S15_F1_G23
   HorizonRow_S15_F1_G23
   HorizonRow_S14_F1_G24

# Bank +70 degrees
:HorizonBank_P70
   HorizonRow_S22_F1_G16
   HorizonRow_S22_F1_G16
   HorizonRow_S22_F1_G16
   HorizonRow_S21_F1_G17
   HorizonRow_S21_F1_G17
   HorizonRow_S20_F1_G18
   HorizonRow_S20_F1_G18
   HorizonRow_S20_F1_G18
   HorizonRow_S19_F1_G19
   HorizonRow_S19_F1_G19
   HorizonRow_S19_F1_G19
   HorizonRow_S18_F1_G20
   HorizonRow_S18_F1_G20
   HorizonRow_S18_F1_G20
   HorizonRow_S17_F1_G21
   HorizonRow_S17_F1_G21
   HorizonRow_S16_F1_G22
   HorizonRow_S16_F1_G22
   HorizonRow_S16_F1_G22

# Bank +80 degrees
:HorizonBank_P80
   HorizonRow_S21_F1_G17
   HorizonRow_S20_F1_G18
   HorizonRow_S20_F1_G18
   HorizonRow_S20_F1_G18
   HorizonRow_S20_F1_G18
   HorizonRow_S20_F1_G18
   HorizonRow_S20_F1_G18
   HorizonRow_S19_F1_G19
   HorizonRow_S19_F1_G19
   HorizonRow_S19_F1_G19
   HorizonRow_S19_F1_G19
   HorizonRow_S19_F1_G19
   HorizonRow_S18_F1_G20
   HorizonRow_S18_F1_G20
   HorizonRow_S18_F1_G20
   HorizonRow_S18_F1_G20
   HorizonRow_S18_F1_G20
   HorizonRow_S18_F1_G20
   HorizonRow_S17_F1_G21

# Bank +90 degrees
:HorizonBank_P90
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
   HorizonRow_S19_V1_G19
