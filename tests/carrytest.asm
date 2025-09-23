I common.mc
# Carry Flag Test Program
# Each section does an ADD or SUB that should deterministically set or clear CF

:Main . Main
        # ADD tests
        @PUSH 0xFFFF      # TOS = 0xFFFF
        @ADD  0x0001      # 0xFFFF + 1 = 0x10000 → result 0x0000, expect CF=1

        @PUSH 0x0001
        @ADD  0x0001      # 1 + 1 = 2 → result 0x0002, expect CF=0

        # SUB tests
        @PUSH 0x0000
        @SUB  0x0001      # 0 - 1 = -1 (0xFFFF) → result negative, expect CF=1

        @PUSH 0x0001
        @SUB  0x0001      # 1 - 1 = 0 → result 0, expect CF=0

        @END             # end program
