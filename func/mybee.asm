# A very simple function evaluation program
I common.mc
I mybee_tolkens.inc
#
:Main
. Main
@CALL MYB_Init
#
:MainLoop
@PRTS PromptString
@READS CmdBuffer1

@PUSH CmdBuffer1
@CALL Tolkenize

# Here is the 'main' loop
# We Tolkinize the command line 'in place' so same buffer should be tolkenized.
# the first word should be one of the valid commands, else error
@MC2M NotKnown CmdState
@PUSHI CmdBuffer1
@CMP LineNumberTolk
@CALLZ InsertLine
@CMP RunTolk
@CALLZ RunCommand
@CMP ListTolk
@CALLZ ListCommand
@CMP PrintTolk
@CALLZ EvalPrintLine
@CMP LetTolk
@CALLZ EvalAssignLine
@POPNULL
@PUSHI CmdState
@CMP NotKnown
@JMPNZ DidSomething
@PRT "Not Recognized: "
@PRTS CmdBuffer1
@PRTNL
:DidSomething
@JMP MainLoop
#
# First major operation is to Tolkenize
#


