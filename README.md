EX716: A Toy Stack-Based CPU Emulator

EX716 is an experimental emulator for a fictional CPU architecture inspired by 1970s microcomputers. Its purpose is not practical performance, but to serve as a training and exploration platform for low-level programming in a clean and consistent assembly environment.

The EX716 is not based on any specific historical CPU. It draws design ideas from the 8085, RCA 1802, and custom hardware like the Apple I. It features a minimalistic, idealized instruction set with consistent behavior and stack-based execution.

System Overview:

* Architecture: Hybrid 8/16-bit
* Internal Data Path: 16-bit
* Registers:

  * Hidden Program Counter and Flags
  * 64K addressable memory
  * Hardware stack: 127 16-bit words (255 bytes)
  * Only accessible user register is the Top Of Stack (TOS)
* Endianess: Little-endian
* No floating point or BCD
* Minimal or no soft interrupts

Conceptual External Interface:

* 48 to 64 pin package
* 16-bit address bus
* 24-bit data bus (may be serialized or fetched in 3 cycles)
* Optional page register for external memory access
* Flags for ready, memory/data distinction, and DMA control

Addressing Modes:

* Direct: Parameter (PRM) is the literal value used
* Indirect: PRM points to the memory address containing the value
* Double Indirect: PRM points to a pointer that points to the value
* Stack: Operands come from the top of the hardware stack

Instruction Encoding:

* Most instructions: 1-byte opcode followed by 2-byte PRM
* Stack-type instructions use only 1-byte opcode

Instruction Families:

Naming conventions:

* OP     = Direct
* OPI    = Indirect
* OPII   = Double Indirect
* OPS    = Stack

Core Groups:

* Stack Ops: PUSH, PUSHI, PUSHII, PUSHS / POPI, POPII, POPS
* Arithmetic: ADD, ADDI, ADDII, ADDS / SUB, SUBI, SUBII, SUBS
* Compare: CMP, CMPI, CMPII, CMPS
* Bitwise: AND, ANDI, ANDII, ANDS / OR, ORI, ORII, ORS / XOR, XORI, XORII, XORS
* Branching: JMP, JMPZ, JMPN, JMPO / JMPI, JMPS
* Control: DUP, SWP, NOP
* IO: CAST, POLL
* Shifts/Rotates: SHR, SHL, RRTC, RLTC
* Unary: INV, COMP2, FCLR, FSAV, FLOD

Macro Assembler:

The assembler is integrated and macro-based. It does not follow MASM syntax.

* Use of @NAME for inline macros
* M and MF define macros
* Labels: \:LABEL or ;LABEL
* Use .DATA to declare separate data segment
* Directives: ., .ORG, .DATA, I (include), L (library), G (global), = (assign value)
* Conditional logic using !, ?, ENDBLOCK
* Supports decimal, 0x hex, 0o octal, 0b binary, \$, \$\$, \$\$\$ for value sizes
* Text in quotes is stored as bytes, optionally null-terminated

Built-in Macros (from common.mc):

Flow Control:
@CALL, @RET, @JMPNZ, @JMPZI, @JMPNZI, @JMPNC, @JMPNO
@JLT, @JLE, @JGE, @JGT

Output Macros:
@PRT, @PRTLN, @PRTI, @PRTIC, @PRTS, @PRTSI, @PRTSS
@PRT
