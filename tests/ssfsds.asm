# For readability the offsets of the main tabes data structures are defined here.

#
#
#      Start Sector (SS)
# These constants are the offset values from beging of the structure.
#
=SSofsTypeCode 0                   # 0:Unformated,1:Boot Disk, 2: Data Disk, 3: 'extended disk' 4: Marked Bad
=SSDTofsFirstSect SSofsTypeCode+2     # First Sector of Directory Table
=SSDTofsSize SSDTofsFirstSect+2      # Size in bytes of Directory table entry (32)
=SSDTofsLength SSDTofsSize+2          # Length of Directory Table (in entries use >>4 to get Sectors)
=SSofsBootSector SSDTofsLength+2      # What Sector to load if SSTypeCode=1 (1 sector read to 0x200 which is also entry point)
=SSofsDiskID SSofsBootSector+2     # 32b ID of Disk based on time stamp of when it was created.
=SSofsBootLabel SSofsDiskID+4      # Boot Lable, remaining sector, can also possile space for extra data for boot info.
#
#
# Directory Table (DT)
#
=DTofsState 0                          # Byte 0:Free/Unused 1: Used 2: Reserved 3: Extended 4: Disabled/Bad
=DTofsFirstSect DTofsState+1           # First Sector of Cluster
=DTofsLastAccessed DTofsFirstSect+2     # Last accessed Sector
=DTofsNextSector DTofsLastAccessed+2   # First Sector of Next Cluster, -1 means file ends in this Cluster
=DTofsLongSize DTofsNextSector+2       # Size as 32 bit number (Can be treated as two words, count of sectors + offset)
=DTofsDateInfo DTofsLongSize+4         # Date info
=DTofsTimeInfo DTofsDateInfo+2         # Create Time info
=DTofsFileName DTofsTimeInfo+2         # Start of filename null padded string 0-15 long
=DTSizeItem 32                         # DT record size
#
#
# OpenFileTable (OFT)
#
=OFTofsState 0                         # Byte State 0: Free/Unused 1: Currently Open/inuse
=OFTofsDiskID OFTofsState+1            # Points to ADT entry.
=OFTofs1stClust OFTofsDiskID+1         # Start Sector of First cluster
=OFTofsCurClust OFTofs1stClust+2       # Current, most recently used cluster. -1 means cluster not read/written yet.
=OFTofsNextClust OFTofsCurClust+2      # Start Sector of Next Cluster ( -1 if file ends in curret cluster)
=OFTofsFileSize OFTofsNextClust+2      # 32 bit file size
=OFTSizeItem OFTofsFileSize+2          # OFT record size
#
#
# Attach Disk Table (ADT)
#
#
=ADTofsState 0                         # State Flags bits BRVU   (0000 - 1111)
                                       #    B=Boot Sector
                                       #    R=RO Flag Set=Read Old
                                       #    V=Virtaul Flag, Set=Virtual Disk
                                       #    U=Used Flag, 0=Unused.
=ADTofsDiskID ADTofsState+2            # 32 bit Disk ID, used to help detect removeable media
=ADTofsBuffer ADTofsDiskID+4           # Points to 512 byte bype 'last read/modified' buffer
=ADTofsDTstart ADTofsBuffer+2          # Points to Sector where Directory Table Starts
=ADTofsHWDiskID ADTofsStaleFlag+2      # Disk ID/Hardware ID
=ADTofsStartSect ADTofsHWDiskID+2      # Points to Sector on disk where start sector is.
=ADTofsDTstop ADTofsStartSect+2        # Points to Sector where DT ends.
=ADTofsVirtDisk ADTofsIsBoot+2         # If not zero, then is the ADT entry for parent disk.
=ADTSizeItem  ADTofsVirtDisk+2         # Size of object
#
#
#
# Basic Concepts
#
# File System depeneds on several tables
#
#  ADT stores information about each mounted/mountable disk
#     Key info stored is
#        A Disk ID (timestamp?) that in unique to a given HW
#        A reusable 512 byte buffer for latest read/written sector.
#        A flag to indicate if sector has been modifed.

#
#  OFT stores the Open File Table, File Pointers are the index in this table.
#     Key info, stored is
#        What ADT entry the file is stored on.
#        What sector it starts at.
#        What sector (if any) of 'next' cluster. if Next==-1 then file ends in current cluster.
#        How large is the file size.
# 
#
#  SS stores the Start Sector of current disk. It mainly used when building the DT
#     Key info
#          Is this a boot disk?
#          First sector of the Directory Table
#          Size in bytes of a Directory Table entry (normally 32)
#          Length of Directory tables (max files in this disk, not counting archives)
#          Sector to load and entry address if disk is a boot disk.
#          Boot Label 1st 4 bytes are boot ID (ASCII code)

