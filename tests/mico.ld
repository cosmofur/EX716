# Micro Load is for debugging, proving only a mininal of OPS to peek, poke and print meory while not loading up a lot of macros
M PUSHI $$3 %1
M PUSH $$1 %1
M POPI $$8 %1
M PRTI $$1 3 $$42 %1
M PRT $$JMP _J%01 :_%0M %1 :_J%01 $$1 1 $$42 $$6 %1
M StackDump $$1 102 $$42 0 $$6
M END $$1 99 $$42 0



