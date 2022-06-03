I common.mc
#
# Up to now we've shown two usefull Macro's the 'PRT' and 'END' macros.
# Let's introduce another usefull one.
# The PRTI macro
# The PRTI will print the possitive number Value stored at the Address passed as a parameter.
# It prints the number without spaces, so use in combination with the normal PRT macro to format the output.
# And for formating, lets also add the PRTNL macro, which prints a NewLine or Line Return
#
# Lets also take a moment, it not printing the VALUE of the lable givin to it, but rather the value
# the spot in memory that lable POINTS to.
# Lables are 'just' shortcuts for numbers, but a PRTI wants to print the value stored at the ADDRESS
# that number points to, and not the number itself. There IS a macro that can just print the value of a
# label, but we'll get to that some other time.
#
#
# Showing how the macros can combined on one line.
@PRT "one:" @PRTI One @PRT " Two:" @PRTI Two @PRT " Three:" @PRTI Three @PRTNL @PRT "That's all"
@END
:One 102
:Two 402
:Three 625
#
# The output of this program would be:
#     one:102 Two:402 Three:625
#     That's all
#






