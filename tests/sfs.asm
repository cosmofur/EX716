#
# Simple File System
#
# Very Basic File System
#
# Sector 0, Boot Sector
#   Byte: Length | Symbol | Value
#   0   : W :  ID : "FS"
#   2   : W : VERSION : 0x0000
#   4   : W : Load Address: 0xfe20
#   6   : W : Entry Address: 0xfE1f
#   8   : 4W : String : 8 Byte Vol ID
#  0x20 : Code Start

! SFSLoaded
M SFSLoadded 1
I common.mc

#
#
# Following Code entered at 0x1000 by hand would be
# the hex of 33 bytes. Which Loads first sector to
# temp storage, then reads from the disk the acutual address
# to needs to be loaded to, then after loading it there,
# jumps to the start of boot program. 
# 01 14 00 2a 00 00 01 15 00 2a 00 00 01 16 00 2b 21 10 01 15 00 2a 00 00 01 1a 00 2b 25 10 28 27 10
#

. 0x1000
:BootStrap
@DISKSEL 0             # 01 14 00 2a 00 00   Code 14=DiskSel
@DISKSEEK 0            # 01 15 00 2a 00 00   Code 15=DiskSeek
@DISKREAD BSDiskB      # 01 16 00 2b 21 10   Code 16=DiskRead
@DISKSEEK 0            # 01 15 00 2a 00 00   Code 15=DiskSeek
@DISKREADI BSLoadAddr  # 01 1a 00 2b 25 10   Code 1a=DiskReadI
@JMPI BSEntry          # 28 27 10            JMPI 0x1027
# The following space can be recovered later.
:BSDiskB
:BSDiskID 0
:BSVersion 0
:BSLoadAddr 0
:BSEntry 0
:BSVolName "01234567"
:BSData
. BSData+0xe0
:EndBSData

