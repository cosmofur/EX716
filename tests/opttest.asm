
# Exercise all the opcodes
#
# Main use is to compare the debug output of cpu.py and fcpu.
# With the exception of some comments and formatting, the output should be identical.
# Run cpu.py opttest.asm -d 2> file1
#     fcpu opttestt.hex -d 256 > file2
#  Then after removing comments, both files should be effectivly identical.
#
# Purposely written with out loading common.mc so all opcodes are in their numeric form.
# Start run at 256 to help detect errors that might overwrite 0-255
. 0x100

:Main . Main
# First push (optcode 1) a few buffer items on the stack.
$$1 0 $$1 1 $$1 2 $$1 3
    $$0				# "NOP",1],
    $$1 :here here+2		# "PUSH",3],
    $$2				# "DUP",1],
    $$3 :here here+2		# "PUSHI",3],
    $$4 :here here+2		# "PUSHII",3],
    $$1 Scratch                 # Put address for PUSHS on stack
    $$5				# "PUSHS",1],
    $$6				# "POPNULL",1],
    $$7				# "SWP",1],
    $$8 Scratch			# "POPI",3],
    $$9 Scratch			# "POPII",3],
    $$1 100 $$1 Scratch         # Put on Stack 100, Scratch for value and destination
    $$10			# "POPS",1],
    $$11 :here here+2		# "CMP",3],
    $$1  100  $$1 100           # Put some values on stack for CMP ops
    $$12			# "CMPS",1],
    $$13 :here here+2		# "CMPI",3],
    $$14 Scratch		# "CMPII",3],
    $$15 :here here+2		# "ADD",3],
    $$1 1 $$1 2                 # Put 1 and 2 on Stack for ADDS
    $$16			# "ADDS",1],
    $$17 :here here+2		# "ADDI",3],
    $$18 Scratch		# "ADDII",3],
    $$19 :here here+2		# "SUB",3],
    $$1 1 $$1 2                 # Put 1 and 2 on Stack for SUBS    
    $$20			# "SUBS",1],
    $$21 :here here+2		# "SUBI",3],
    $$22 Scratch		# "SUBII",3],
    $$23 :here here+2		# "OR",3],
    $$1 0xff $$1 42             # Put some values for ORS
    $$24			# "ORS",1],
    $$25 :here here+2		# "ORI",3],
    $$26 Scratch		# "ORII",3],
    $$27 :here here+2		# "AND",3],
    $$1 0xff $$1 42             # Put some values for ANDS
    $$28		 	# "ANDS",1],
    $$29 :here here+2		# "ANDI",3],
    $$30 Scratch		# "ANDII",3],
    $$31 :here here+2		# "JMPZ",3],
    $$32 :here here+2		# "JMPN",3],
    $$33 :here here+2		# "JMPC",3],
    $$34 :here here+2		# "JMPO",3],
    $$35 :here here+2		# "JMP",3],
    $$36 TargetRef		# "JMPI",3], TargetRef will have value of next instruction addressn
:Target
    $$1 2
    $$37 :here here+2		# "CAST",3],
    $$1 6                       # Setup a no wait read
    $$38 Scratch		# "POLL",3],
    $$39       			# "RRTC",1],
    $$40			# "RLTC",1],
    $$41			# "RTR",1],
    $$42			# "RTL",1],
    $$43			# "INV",1],
    $$44			# "COMP2",1],
    $$45			# "FCLR",1],
    $$46			# "FSAV",1],
    $$47			# "FLOD",1]
    $$1 99       # Do exit call
    $$37 99
:TargetRef Target
:Scratch 0
