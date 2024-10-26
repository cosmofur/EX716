######################################
# SSFD  Stupid Simple File System
#
# Disk: A block of addressable storage, multiple disks might be on same hardware, think 'partitions'
# Sectors: 512 byte blocks of disk addressed by a 16 bit address (max 32MB)
# Start Sector: 512 byte, defines disk major variables
# Directory Table: fixed size table structure, 1 to 1 with number of Clusters that will fit on disk
# Clusters:
#
! SSFSDefined
M SSFSDefined
#
# 'root' disk can also be a boot disk. If so, it will load bootstrage (1 512 byte block) at address 0x200 and pass controll
# The Root's of a 'physical' disk will always have a Directory table large enough to map all the possible
# clusters that make up that full disk. For example for 32MB disk with 64K clusters the ROot Directory Table will
# take up about 512 blocks. Still leaving more 64000 sectors for storage
#
# 
# Format of Start Sector  (SS)
#  Byte Offset    Meaning
#   0             1w SSofsTypeCode 0:Unformated,1:Boot Disk, 2: Data Disk, 3: 'extended disk' 4: Marked Bad
#   2             1w SSDTofsFirstSect First Sector of Directory TableDirectory Table First Sector
#   4             1w SSDTofsSize Size in bytes of Directory table entry (32)
#   6             1w SSDTofsLength Length of Directory Table (in entries use >>4 to get Sectors)
#   8             1w SSofsBootSector What Sector to load if SSTypeCode=1 
#   10            null term string up to max of end of first sector.

#
#
# Format of Directory Table  (DT)
#  Byte Offset       Meaning
#  0                 1b (0: Free/Unused 1: Used 2: Reserved 3: Extended Cluster 4: Disabled)
#  1                 1w First Sector of Cluster
#  3                 1w Last accessed Sector of current Cluster
#  5                 1w Next Cluster Sector ( -1 means no extent)
#  7                 2w Size 32 bit number. (try to avoid needing full lmath.ld library)
#  11                1w 16b ID of date as days since Jan 1st 2000
#  13                1w Time of day in minutes.
#  15                Filename 15 bytes null terminated.
# Total Size 32 bytes
#  
#
#
# Format of Open File Table (OFT)
# 
#  Byte Offset       Meaning
#  0                 1b (0: Free Unused Entry, 1: Open File )
#  1                 Disk ID (0-255)
#  2                 1w First Sector of Cluster
#  4                 1w Last accessed Sector of current Cluster
#  6                 1w Next Cluster Sector ( -1 means no extent)
#  8                 2w Size 32 bit number. (try to avoid needing full lmath.ld library)
#  
#
#######
# Global Variables
:MainHeapID 0
:OFTable 0
:WorkBuffer1 0
:ActiveDisk 0
:ActiveFile 0
:ActiveDir 0
####################
I ssfs-ds.asm



