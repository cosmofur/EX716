# Ahhh, the Classic 'Hello World' first program
# It doesn't really teach you much.
# Trying to make the best out of it.
#  1: The first lesson is just how to run the assembler itself.
#     Use the command line:
#       cpu.py l001.asm
#     If this doesn't work out of the box, then set the environmental variables
#     PATH to where the cpu.py program is
#     CPUPATH to a colon separated list of where the lib folder is.
#     Ex:
#        export PATH=$PATH:~/src/EX716/
#        export CPUPATH=~/src/EX716:~/src/EX716/lib
#     then try again.
#  2: After successfully running cpu.py a few times. Try some of the command line options.
#     cpu.py l001.asm -l           To print a listing of the assembled output with macros expanded
#     cpu.py 1001.asm -g           To enter a 'gdb' like debugger to single step though the program.
#
I common.mc
@PRT "Hello World"
@END
