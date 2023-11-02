I common.mc
# In the 1970's your small computer was more likely to have either no disk, a tape drive, or if you were
# lucky a floppy disk. These sorts of disks were so limited that they didn't need a lot of complex
# concepts to manage how files where organized or stored on them.
#
# Now while the EX716 is inspired by the more 'down to earth' and 'human scale' of the 1970s CPU's
# I don't see why we also need to embrace such simple file systems when we know better now.
#
# So I want a 'realistic' but functional file system that can work with the limited sort of hardware
# that would have been possible in those days.
#
# So we are going to approach building up the 'ideas' of a filesystem in stages, and approach it more like
# developing a specialized database application, that happens to be able to be generalized into a filesystem.
#
# First, our simulated hardware provides an elementary disk IO the Cast an Poll functions.
#       All of these are pretty similar to the sort of hardware interface a disk controller would provide.
#       While our simulation uses a file (DISK#) to simulate disks, these low level IO calls do not understand
#       concepts like files or directories, these are just hardware addresses and unformatted Sectors of data.
#
#       We use a 16b number to identify the sector number, with a little math 16b-index*256bye sectors means
#       our largest 'disk' is 16Megabyte. In the 1970's this would have been a respectable disk size. Much
#       larger than Floppy disks where typically at the time. 
#           SelectDisk      Opens the disk and identifies the active disk device
#           SeekDisk        Move disk head to a given sector for read/write
#           WriteSector      Copies a 256byte Sector memory to the current disk sector.
#                           it also moves disk head to the next sector.
#           SyncDisk        Flushes and HW buffers the Disk controller may have. Returns when disk is ready.
#           PollReadSector   Reverse of WriteSector, copies 256byte data from current sector to Sector of memory.
#                           it also moves disk head to the next sector.
#
# Disk LayOut
# Sector 0:        Boot sector, also points to 'N' which is first Inode sector.
# Sector 1-(N-1)   Usage BitMap, each bit maps to a 256 sector. Set means in-use, blank means free.
# Sector N:        Inode 0, see Inode Structure below
# ..
# Sector M:        An 'extent' directory see bellow
# Sectors D-END    End User Data
#
# Inode Structure (Basic)
# NodeType: (Basic,Extent,Inactive,Deleted, ... )                              : 1 Byte
# ID#                                                                          : 1 Word
# Permissions_Flags: RWX,Link,                                                 : 1 Byte
# DateInfo: TimeDateInfo                                                       : 5 Bytes (32b second 8b epic)
# Comment: Fixed Length String                                                 : 16 Bytes
# ObjectSize: Bytes                                                            : 4 Byte, 32b number
# NodeList(Sector,Count): Count:(Zero=EndOfList, 0xFFFF=Sector is Extent Node) : Sector:2 Bytes, Count: 2 Bytes
# NodeList...NodeList... Max of 57                                             : Byte 26-254
#
# Extent Inodes are for when we need more than 57 entries in the NodeList.
# NoteType:                                                                    : 1 Byte
# Parent Node:                                                                 : 2 Byte
# NodeList... Max of 63
#
# There can be multiple 'Extents' for large split up files.
#
#
# Now Inode's can point to a group of sectors that make up a 'file'
# Directories are a special file that maps 1 or more filenames to other Inodes.
#
# So Inode 0, would map to the 'root' directory file, which in turn would be a list of additional files or other
# directory inodes.
#
