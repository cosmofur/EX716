G readstr
	@JMP EndCode
:readstr
	@POPI ReturnAddr
	@POPI ReturnStr
	@MC2M 0 Index
	@PUSH PollReadCharI
	@PUSH 0
	@POPII ReturnStr
:ReadStrLoop1
	@POLL CIn
	# Test for Multi Byte F-Keys
	@PUSH 0xff00
	@CMPI CIn
	@POPNULL
	@JGE SpecialKey
# Test for DEL or backspace (8 or 128)
	@PUSH 8
	@CMPI CIn
	@POPNULL	
	@JMPZ DeleteKey
	@PUSH 128
	@CMPI CIn
	@POPNULL	
	@JMPZ DeleteKey
# Test for ^U
	@PUSH 0x15
	@CMPI CIn
	@POPNULL
	@JMPZ ESCKey
# Test for <ENTER> as end of string.
	@PUSH 13
	@CMPI CIn
	@POPNULL
	@JMPZ EnterKey
# Test if char is >= space
	@PUSH 30
	@CMPI CIn
	@POPNULL	
	# Is any other ctl code under space, just ignore it.
	@JGT ReadStrLoop1
	# Test if char is <= 127
	@PUSH 128
	@CMPI CIn
	@POPNULL
	@JLT ReadStrLoop1
# Should be a valid character, save to buffer and inc buffer index. Note place of lower vs upper bytes.
	@PUSHI CIn
	@POPII ReturnStr
	@PUSH 6
	@CAST CIn
	@POPNULL
	@INCI Index
	@INCI ReturnStr
	@JMP ReadStrLoop1
# Backclear is "^h" space "^h"	
:BackClear b8 b32 b8 b0
:EnterKey
	@POPNULL
	@PUSHI Index
	@PUSHI ReturnAddr
	@RET
# At some future time we may handle arrow keys, not now
	:SpecialKey
	# Test for ESC ESC the python libray readkey doesn't handle single ESC right
	@PUSH 0x1B1B
	@CMPI CIn
	@POPNULL
	@JMPZ ESCKey
	@JMP ReadStrLoop1
# if there are any character in buffer, delete latest.
:DeleteKey
	# make there there something to delete
	@PUSH 0
	@CMPI Index
	@POPNULL
	@JMPZ ReadStrLoop1
	@PRTRAW BackClear	
	@DECI Index
	@JMPZ ReadStrLoop1
# ESC key clears buffer
	:ESCKey
:ESCKey2
	@PUSH 0
	@CMPI Index
	@POPNULL
	@JMPZ ReadStrLoop1
	@PRTRAW BackClear
	@DECI Index
	@DECI ReturnStr
	@JMP ESCKey2
:ReturnAddr 0
:ReturnStr 0
:Index 0
:CIn 0	
:EndCode
#@PRT "Test"
