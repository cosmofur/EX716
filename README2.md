This is thinking about future plans rather than a description of this version of the EX716
The follow up process might be the EX816 and would have the following additional features

16x16 bit vector map register for 16 hardware interrupts.
Address bus would be expanded to 24 bits and be configured, allowing up to 16MB of address space.
This will be done by pretending 8 bit page register (PR) allowing 256 64K pages.
These pages will be numbered based on the value of the PR.

PR zero is special. It is the 'admin mode' page and the majority of the new instructions will only function
if called from a process running on page zero. All other pages are User Space memory and are more restrictive on what they can do.

In practice, Page 0, will be where the main device drivers and library functions will be be stored. So any 'OS' will run its
kernel code in Page 0 .

New Instructions

ENBINT             - Enables the Interrupt system, by default its not enabled.
DSBINT             - Disabled the Interrupt system.
SETINT #           - Sets Interrupt # (0-15) to TOS address in Page 0
INT #              - Pushs PR and PC onto Stack and jumps to Page 0 interrupt PAGE[CUR] Disable Interrupts.
INTI #             - 

In the following instructions TOS will hold the page value, and # will be target address

In the JMP instructions the new PR will be continue as the active PR as control will move to the new Page.
The existing Stack TOS (and SFT in LJUMPS case) are popped off.
LJMP  #            - PR=TOS and PC set #
LJMPI #            - PR=TOS and PC set to Page 0 [#]
LJMPII #           - PR=TOS and PC set to Page 0 [Page 0[#]]
LJMPS              - PR=TOS and PC set to SFT


The Following the PR will take on the TOS value, only for the duration of this instruction.
The existing TOS (and SFT in case of S version) are popped off, replaced by new value
LPUSH #            - Temp(PR=TOS) PUSH to stack Page[TOS][#]
LPUSHI #           - Temp(PR=TOS) PUSH to stack Page[TOS][Page[0][#]]
LPUSHII #          - Temp(PR=TOS) PUSH to stack Page[TOS][Page[0][Page[0][#]]]
LPUSHS             - Temp(PR=TOS) PUSH to Stack Page[TOS][SFT]

LPOPI #            - Temp(PR=TOS) POP SFT to Page[TOS][Page[0][#]]
LPOPII #           - Temp(PR=TOS) POP SFT to Page[TOS][Page[0][Page[0][#]]]
# THere no 'LPOPS' as that would require a 'Third from Top' and not enough instructions require that to justify HW version.

# The following are Stack Dump/Restore meant to allow process issolation when task swapping.
# Its a very costly operation, so avoid it when Task Issolcation not a critical requirement
STKSIZE            - PUSHS onto stack current depth (if two items on stack, will put 2 into 3rd position)
STKDUMP #          - # is an address in Page 0 buffer of 129 bytes in length. Byte 0 will be the current Stack Size
                   - The current HW stack will be nulled
STKDUMPI #         - Page 0[#] is an address in Page 0 buffer of 129 bytes in length. Byte 0 will be the current Stack Size
STKREST #          - Restore stack previously dumped with STKDUMP #
STKRESTI #         - Restore stack previous dumped with STKDUMPI #

#
The Majority of the above instructions are only available if the current process is running in Page 0.
The following are also available to user level

INT #
INTI #
STKSIZE

Notice how the User level processes can't access or even see memory outside its own page. All 'Push/Pops' of long addresses have to managed by processes running on Page 0

Interupts

There are a total of 16 Interupts, the lower 8 are available as hardware interupts, and the upper 8 are for just Software Interuppts.

Some have predefined/prefered uses. They can also all be used as Soft Interupts.

Interupt

0        Clock - When enabled gets called once a second.
1        Error - Gets called when HW stack underflows or overflows or CPU 
2        Eternal - Triggers when Sys Console HW device triggers (Keyboard)
3        Mem Error - Attept to access a Page which is not mapped to memory.
4        Timer Interupt - external timer like clock but adjustable by HW Cast operatoin.
5        Disk device triggered interuppts.
6        Video Hardware Interupts
7        Memory Manager Interupts.
8-f      soft interupts.
8        Primary OS IO Service call, Read Write etc
9        OS Exec control Interupt, exec, kill etc. Childern.
a        OS message passing interupt. For sending singals to other processes
b        OS Memory operations, Alloc, LFetch, LSend


In principle a multi process OS can be created with the main instruciton set and these additions.

Page 0 would act as the OS kernel and handle all device services as well as task swapping.

Library calls would be made to allow processes to use other 'process blocks' as extended memory for larger arrays and data structures.

