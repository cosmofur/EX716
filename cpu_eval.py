import numpy as np
import sys

class microcpu:
    
    OptValNOP = 0
    OptValPUSH = 1
    OptValDUP = 2
    OptValPUSHI = 3
    OptValPUSHII = 4
    OptValPUSHS = 5
    OptValPOPNULL = 6
    OptValSWP = 7
    OptValPOPI = 8
    OptValPOPII = 9
    OptValPOPS = 10
    OptValCMP = 11
    OptValCMPS = 12
    OptValCMPI = 13
    OptValCMPII = 14
    OptValADD = 15
    OptValADDS = 16
    OptValADDI = 17
    OptValADDII = 18
    OptValSUB = 19
    OptValSUBS = 20
    OptValSUBI = 21
    OptValSUBII = 22
    OptValOR = 23
    OptValORS = 24
    OptValORI = 25
    OptValORII = 26
    OptValAND = 27
    OptValANDS = 28
    OptValANDI = 29
    OptValANDII = 30
    OptValJMPZ = 31
    OptValJMPN = 32
    OptValJMPC = 33
    OptValJMPO = 34
    OptValJMP = 35
    OptValJMPI = 36
    OptValJMPS = 37
    OptValCAST = 38
    OptValPOLL = 39
    OptValRRTC = 40
    OptValRLTC = 41
    OptValSHR = 42
    OptValSHL = 43
    OptValINV = 44
    OptValCOMP2 = 45
    OptValFCLR = 46
    OptValFSAV = 47
    OptValFLOD = 48

    HWStackSize = 128
    MAXHWSTACK = 126
    MAXMEMSP=0xffff

    optcnames = [
        "NOP",
        "PUSH",
        "DUP",
        "PUSHI",
        "PUSHII",
        "PUSHS",
        "POPNULL",
        "SWP",
        "POPI",
        "POPII",
        "POPS",
        "CMP",
        "CMPS",
        "CMPI",
        "CMPII",
        "ADD",
        "ADDS",
        "ADDI",
        "ADDII",
        "SUB",
        "SUBS",
        "SUBI",
        "SUBII",
        "OR",
        "ORS",
        "ORI",
        "ORII",
        "AND",
        "ANDS",
        "ANDI",
        "ANDII",
        "JMPZ",
        "JMPN",
        "JMPC",
        "JMPO",
        "JMP",
        "JMPI",
        "CAST",
        "POLL",
        "RRTC",
        "RLTC",
        "SHR",
        "SHL",
        "INV",
        "COMP2",
        "FCLR",
        "FSAV",
        "FLOD"
    ]
    
    PC=0
    ZF=0
    NF=0
    CF=0
    OF=0
    flags=0
    HWStack=[]
    memory=[]
    HWSPIDX=HWStackSize
    HWStack=[]
    
    def __init__(self):
        """Initilaize values"""
        print("Starting Initilizing CPU")
        self.HWStack = np.zeros( self.HWStackSize, dtype=np.uint16, order='C')
        self.memory = np.zeros( 0x10000, dtype=np.uint8, order='C')
        self.HWSPIDX = self.HWStackSize-2
        self.HWStack[self.HWSPIDX]=0
        self.OptCount = 0

    def get16memat(self,locateaddr):
        locateaddr = locateaddr & 0xffff
        if ( locateaddr == 0xffff):
            return 0
        else:
            return(( self.memory[locateaddr] & 0xff) +
                   ((self.memory[locateaddr+1] & 0xff)  << 8)) & 0xffff

    def put16atmem(self,locateaddr,val):
        locateaddr=locateaddr & 0xffff
        val=val & 0xffff
        self.memory[locateaddr]=val & 0xff
        self.memory[locateaddr+1]=((val >> 8) & 0xff)

    def putwordat(self,val,locateaddr):
        self.put16atmem(locateaddr,val)    # Reverse order of funciton to match replacement.

    def topstack(self,optcode):
        if self.HWStack[self.HWSPIDX] > self.MAXHWSTACK:
            return -1
        elif self.HWStack[self.HWSPIDX] < 1:
            return -1
        return self.HWStack[self.HWStack[self.HWSPIDX]-1]

    def sectopstack(self,optcode):
        if self.HWStack[self.HWSPIDX] > self.MAXHWSTACK:
            return -1
        elif self.HWStack[self.HWSPIDX] < 2:
            return -1
        return self.HWStack[self.HWStack[self.HWSPIDX]-2]

    def popstack(self,optcode):
        if self.HWStack[self.HWSPIDX] > self.MAXHWSTACK:
            return -1
        elif self.HWStack[self.HWSPIDX] < 1:
            return -1
        self.HWStack[self.HWSPIDX] -= 1
        return self.HWStack[self.HWStack[self.HWSPIDX]]

    

    def pushstack(self,invalue,optcode):
        if self.HWStack[self.HWSPIDX] > self.MAXHWSTACK:
            print("005 MB Stack Overflow, OPCODE %d\n", optcode)
        self.HWStack[self.HWStack[self.HWSPIDX]]=invalue
        self.HWStack[self.HWSPIDX] += 1

    def lowbyte(self,invalue):
        return invalue & 0xff

    def highbyte(self,invalue):
        return (invalue >> 8 & 0xff)

    def getwordat(self,invalue):
        return self.get16memat(invalue)

    def SetFlags(self,invalue):
        self.ZF=0
        self.NF=0
        self.CF=0
        B2=abs(invalue) & 0xffff
        self.ZF=1 if (B2 == 0 ) != 0 else 0
        self.NF=1 if (invalue & 0x8000) != 0 else 0
        self.CF=1 if (invalue & 0xffff0000) > 0 else 0

    def OverFlowTest(self,a,b,c, IsSubtraction):
        a = -1 if ((a & 0xffff) > 0x8000) else 1
        b = -1 if ((b & 0xffff) > 0x8000) else 1
        c = -1 if ((c & 0xffff) > 0x8000) else 1
				     
        if ( IsSubtraction == 0):
            if (((a > 0) and (b > 0) and (c < 0)) or ((a < 0) and (b < 0) and (c >= 0))):
                # overflow occurred
                self.OF=1
            else:
                self.OF=0

        else:
            if (((a > 0) and (b < 0) and (c < 0)) or ((a < 0) and (b > 0) and (c >= 0))):
                # overflow occurred
                self.OF=1
            else:
                self.OF=0

    def HandlePoll(self,Param,ParamI,ParamII):
        address=Param
        if (address >= (self.MAXMEMSP-11)):
            self.raiseerror("040 Insufficent space for Message Address at %d, optPOLL" % (address))
        cmd = self.topstack(Param)
        if cmd == 1:
            sys.stdout.flush()
            rawdata = sys.stdin.readline(256)
            justnum = "0"
            for c in rawdata:
                if (c >= '0' and c <= '9') or (c == '-'):
                    justnum = justnum + c
            if int(justnum) < 65535 and int(justnum) >= -32767:
                CPU.putwordat(address, int(justnum))
            else:
                print("Error: %s is not valid 16 bit number" % justnum)
                self.putwordat(address, 0)
        if cmd == 2:
            sys.stdout.flush()
            rawdata = sys.stdin.readline(256)
            i = address
            for c in rawdata:
                if ord(c) > 31:
                    c = ord(c)
#                    c = ( ord(c) << 8  & 0xff00 )
                    self.putwordat(i, c)
                    i += 1
                    if (i > (self.MAXMEMSP-11)):
                        self.raiseerror(
                            "041 Insufficent space for Message Address at %d, optPOLL" % (i))
        if cmd == 3:
            # Address must be at least 4 bytes for special code strings.
            c = readchar.readkey()
            if not (c):
                c = ""
            if len(c) == 1:
                self.putwordat(address, ord(c))
            elif len(c) == 2:
                self.putwordat(address, (ord(c[0])) << 8 + (ord(c[1])))
                self.putwordat(address+2, 0)
            elif len(c) == 3:
                self.putwordat(address, (ord(c[1])) << 8 + (ord(c[1])))
                # This will create a 3 char string null terminated
                self.putwordat(address+2, (ord(c[2])))
        if cmd == 4:
            fd = sys.stdin.fileno()
            new = termios.tcgetattr(fd)
            new[3] = new[3] & ~termios.ECHO          # lflags
            EchoFlag = True
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, new)
            except:
                print("TTY Error: On No Echo")
        if cmd == 5:
            fd = sys.stdin.fileno()
            new = termios.tcgetattr(fd)
            new[3] = new[3] | termios.ECHO          # lflags
            EchoFlag = False
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, new)
            except:
                print("TTY Error: On Echo")
        if cmd == 6:
            c='\0'
            while True:
                c=get_key()
                if len(c) != '\0':
                    break
            if len(c)==1:
                self.putwordat(address,ord(c))
            elif len(c)==2:
                self.putwordat(address, (ord(c[0])) << 8 + (ord(c[1])))
                self.putwordat(address+2, 0)
            elif len(c) == 3:
                self.putwordat(address, (ord(c[1])) << 8 + (ord(c[1])))
                # This will create a 3 char string null terminated
                self.putwordat(address+2, (ord(c[2])))            
        if cmd == 22:
            if DeviceHandle != None:
                v=address
                if v <= self.MAXMEMSP-0x1ff:
                    DeviceFile.seek(self.DiskPtr,0)
                    block = DeviceFile.read(512)
                    tidx = v
                    j=0
                    for i in block:
                        self.memspace[tidx] = int(i) & 0xff
                        tidx += 1
                        j += 1
                        if ( j > 16):
                            j=0
                else:
                    self.raiseerror(
                        "042 Attempted to read block with insuffient memory %04x < 0x4x" %(v,self.MAXMEMSP-0xff))
        if cmd == 23:
            if DeviceHandle != None:
                v=address
                block=DeviceFile.read(512)
                tidx=v
                if v<= self.MAXMEMSP-0x1ff:
                    for i in block:
                        self.memspace[tidx] = int(i) & 0xff
                        tidx += 1
                else:
                    self.raiseerror(
                        "043 Attempt to read Tape Block with insufficent memory")
        if cmd == 24:
            if DeviceHandle != None:
                DeviceFile.seek(0)


    def HandleCast(self,Param,ParamI,ParamII):
        CastPrintStrI=1
        CastPrintInt=2
        CastPrintIntI=3
        CastPrintSignI=4
        CastPrintBinI=5
        CastPrintChar=6
        CastPrintStrII=11
        CastPrintCharI=16
        CastPrintHexI=17
        CastPrintHexII=18
        CastSelectDisk=20
        CastSeekDisk=21
        CastWriteSector=22
        CastSyncDisk=23
        CastPrint32I=32
        CastPrint32S=33
        CastTapeWriteI=34
        CastEnd=99
        CastDebugToggle=100
        CastStackDump=102

        PollReadIntI=1
        PollReadStrI=2
        PollReadCharI=3
        PollSetNoEcho=4
        PollSetEcho=5
        PollReadCINoWait=6
        PollReadSector=22
        PollReadTapeI=23
        PollRewindTape=24
        
        MAXMEMSP=self.MAXMEMSP
        if (Param >= (MAXMEMSP - 11)):
            print("036 Insufficent space for Message Address at %s, optCAST" % Param)                
        match self.topstack(self.pc):
            case 0:
               print("Stack: \n".join('%02x ' %
                      item for item in self.HWStack[0:self.HWStack[self.HWSPIDX]]))
            case 1 :   # CastPrintStrI
                i=Param
                while self.memory[i] !=0 and i < MAXMEMSP:
                    c=self.memory[i]
                    if c == 0:
                        print("Odd internal null in string")
                    if (c < 32 or c > 127) and ( c != 10 and c != 7 and c != 27 and c != 30):
                        sys.stdout.write("\%02x" % c)
                    else:
                        sys.stdout.write(chr(c))
                    i += 1
            case 2 :   # CastPrintInt
                 sys.stdout.write("%d" % Param)
            case 3 :   # CastPrintIntI
                v = self.memory[Param]+(self.memory[Param+1] << 8)
                sys.stdout.write("%d" % v)
            case 4 :   # CastPrintSignI
                v = self.memory[Param]+(self.memory[Param+1] << 8)
                sys.stdout.write("%d" % (self.twos_compFrom(v, 16)))
            case 5 :   # CastPrintBinI
                v = self.memory[Param]+(self.memory[Param+1] << 8)
                sys.stdout.write("%s" % format(v, "016b"))
            case 6 :   # CastPrintChar
                v = self.memory[Param]
                if (v < 31):
                    print("%c" % v)
                else:
                    sys.stdout.write(chr(v))
            case 11:
                i = self.getwordat(self.getwordat(Param))
                while self.memory[i] != 0 and i < MAXMEMSP:
                    c = self.memory[i]
                    print("ORD-C: %02x" % c)
                    if c == 0:
                        print("Odd C is zero")
                    if (c < 32 or c > 127) and (c != 10 and c != 7 and c != 30):
                        sys.stdout.write("\%02x" % c)
                    else:
                        sys.stdout.write(chr(c))
                    i += 1
                sys.stdout.write("%d" % Param)
            case 12:
                sys.stdout.write("%d" % self.getwordat(Param))
            case 16 :   # CastPrintCharI
                v = self.memory[self.getwordat(Param)]
                sys.stdout.write("%c" % chr(v))
            case 17 :   # CastPrintHexI
                v = self.getwordat(Param)
                sys.stdout.write("%04x" % (v))
            case 18 :   # CastPrintHexII
                v = self.getwordat(self.getwordat(Param))
                sys.stdout.write("%04x" % v)
            case 19:
                v = self.getwordat(Param)
                v = v + (self.getwordat(Param+2) << 16)
                sys.stdout.write("%s" % v)
            case 20 :   # CastSelectDisk
                if DeviceHandle == None:
                    DeviceHandle = "DISK%02d.disk" % Param
                try:
                    DeviceFile = open(DeviceHandle, "r+b")
                    self.DiskPtr = 0
                    DeviceFile.seek(0,0)
                except IOError:
                    self.raiseerror(
                        "037 Error tying to open Random Device: %s" % DeviceHandle)
            case 21 :   # CastSeekDisk
                self.DiskPtr = Param*0x200
                DeviceFile.seek(self.DiskPtr, 0)
            case 22 :   # CastWriteSector
                v = Param
                if v < MAXMEMSP-0x1ff:
                    block = self.memory[v:v+512]
                    DeviceFile.seek(self.DiskPtr)
                    DeviceFile.write(bytes(block))
                    self.DiskPtr =+ 0x200
                    DeviceFile.flush()
                else:
                    self.raiseerror(
                        "038 Attempted to write block larger than memory to storage")
            case 23 :   # CastSyncDisk
                if DeviceHandle != None:
                    DeviceFile.close()
                    self.DiskPtr = -1
                    DeviceHandle = None
            case 32 :   # CastPrint32I
                iaddr = Param
                v = self.getwordat(iaddr) + (self.getwordat(iaddr + 2) << 16)
                if (v & (1 << 31) != 0):
                    v = v - (1 << 32)
                sys.stdout.write("%s" % v)
            case 33 :   # CastPrint32S
                iaddr = self.fetchAcum(1)
                v = self.getwordat(iaddr) + (self.getwordat(iaddr + 2) << 16)
                sys.stdout.write("%d" % v)
            case 99 :   # CastEnd
                print("\nEND of Run:(%d Opts)" %  self.OptCount)
                sys.exit(Param)
            case 100 :   # CastDebugToggle
                Debug = 0 if Debug else 1
            case 102 :   # CastStackDump
                print(" %04x:Stack ( %d):" %
                      (self.pc, self.HWStack[0xff]-1), file=DebugOut,end="")
                for i in range(self.HWStack[0xff]-1):
                    val = self.HWStack[i*2]+(0xff*self.HWStack[i*2+1])
                    print(" %04x" % (val),file=DebugOut,end="")
                    print(" ",file=DebugOut)
            case 34 :   # CastTapeWriteI
                if DeviceHandle != None:
                    v=Param
                    if v < MAXMEMSP-0x1ff:
                        block=self.memory[v:v+512]
                        DeviceFile.write(bytes(block))
                        DeviceFile.flust()
                    else:
                        self.raiseerror(
                            "039 Attempt to write from source memory past available memory")
            case _:
                print("Invalid CASE Option:")
                        
                        
    sys.stdout.flush()

#####################################################################                            
                    
                

        
                
        
    def evalpc(self,startpc):
        Param=0
        ParamI=0
        ParamII=0
        Opsize=0
        OptCode=0
        nbr1=0
        nbr2=0
        TF=0
        A1=0
        A2=0
        B1=0
        #
        self.pc=startpc
        self.OptCount+=1
        Param=self.get16memat(self.pc+1)
        ParamI=self.get16memat(Param)
        ParamII=self.get16memat(ParamI)    
        Opsize=1
        OptCode=self.memory[self.pc]
        nbr1=0
        nbr2=0
        #
        # Set nbr1/2 to the top and sct values of HW stack or -1 if not valid.
        if self.HWStack[self.HWSPIDX] >= 1:
            nbr1=self.topstack(self.pc)
        else:
            nbr1 -= 1
        if self.HWStack[self.HWSPIDX] >= 2:
            nbr2=self.sectopstack(self.pc)
        else:
            nbr2 -= 1
        match OptCode:
            case self.OptValNOP:
                Opsize=1                
                self.pc += Opsize


            case self.OptValPUSH:
                self.pushstack(Param,OptCode)
                Opsize=3 
                self.pc += Opsize

            case self.OptValDUP:
                A1=self.topstack(OptCode)
                self.pushstack(A1,OptCode)
                Opsize=1
                self.pc += Opsize         

            case self.OptValPUSHI:
                self.pushstack(ParamI,OptCode)
                Opsize=3 
                self.pc += Opsize

            case self.OptValPUSHII:
                self.pushstack(ParamII,OptCode)
                Opsize=3 
                self.pc += Opsize

            case self.OptValPUSHS:
                self.pushstack(self.get16memat(self.popstack(OptCode)),OptCode)
                Opsize=1
                self.pc += Opsize

            case self.OptValPOPNULL:
                A1=self.popstack(OptCode)
                Opsize=1
                self.pc += 1

            case self.OptValSWP:
                A1=self.popstack(OptCode)
                A2=self.popstack(OptCode)         
                self.pushstack(A1,OptCode)
                self.pushstack(A2,OptCode)
                Opsize=1
                self.pc += 1

            case self.OptValPOPI:
                self.put16atmem(Param,self.popstack(OptCode))
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValPOPII:
                self.put16atmem(ParamI,self.popstack(OptCode))         
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValPOPS:
                A1=self.popstack(OptCode)
                B1=self.popstack(OptCode)
                self.put16atmem(A1,B1)
                Opsize=1
                self.pc=self.pc+Opsize

            case self.OptValCMP:
                B1=self.topstack(OptCode)
                A1=B1-Param
                self.SetFlags(A1)
                self.OverFlowTest(B1,Param,A1,1)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValCMPI:
                B1=self.topstack(OptCode)
                A1=B1-ParamI
                self.SetFlags(A1)
                self.OverFlowTest(B1,ParamI,A1,1)         
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValCMPII:
                B1=self.topstack(OptCode)
                A1=B1-ParamII
                self.SetFlags(A1)
                self.OverFlowTest(B1,ParamII,A1,1)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValCMPS:
                A2=self.topstack(OptCode) & 0xffff
                B1=self.sectopstack(OptCode) & 0xffff
                A1=B1 - A2
                self.SetFlags(A1)
                self.OverFlowTest(B1,A2,A1,1)
                Opsize=1
                self.pc=self.pc+Opsize

            case self.OptValADD:
                B1=self.popstack(OptCode)
                A1=Param + B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                self.OverFlowTest(Param,B1,A1,0)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValADDI:
                B1=self.popstack(OptCode)
                A1=ParamI + B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                self.OverFlowTest(ParamI,B1,A1,0)         
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValADDII:
                B1=self.popstack(OptCode)
                A1=ParamII + B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                self.OverFlowTest(ParamII,B1,A1,0)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValADDS:
                A2=self.popstack(OptCode) & 0xffff
                B1=self.popstack(OptCode) & 0xffff
                A1=A2 + B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                self.OverFlowTest(A2,B1,A1,0)                 
                Opsize=1
                self.pc=self.pc+Opsize


            case self.OptValSUB:
                B1=self.popstack(OptCode)
                A1=B1-Param
                self.SetFlags(A1)
                self.OverFlowTest(B1,Param,A1,1)
                self.pushstack(A1,OptCode)

                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValSUBI:
                B1=self.popstack(OptCode)
                A1=B1-ParamI
                self.SetFlags(A1)
                self.OverFlowTest(B1,ParamI,A1,1)         
                self.pushstack(A1,OptCode)

                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValSUBII:
                B1=self.popstack(OptCode)
                A1=B1-ParamII
                self.OverFlowTest(B1,ParamII,A1,1)         
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)

                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValSUBS:
                A2=self.popstack(OptCode)
                B1=self.popstack(OptCode)
                A1=np.int16( np.int16(B1) - np.int16(A2))
                self.SetFlags(A1)
                self.OverFlowTest(B1,A2,A1,1)         
                self.pushstack(A1,OptCode)

                Opsize=1
                self.pc=self.pc+Opsize


            case self.OptValAND:
                B1=self.popstack(OptCode)
                A1=Param & B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValANDI:
                B1=self.popstack(OptCode)
                A1=ParamI & B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValANDII:
                B1=self.popstack(OptCode)
                A1=ParamII & B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValANDS:
                A2=self.popstack(OptCode)
                B1=self.popstack(OptCode)
                A1=A2 & B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                Opsize=1
                self.pc=self.pc+Opsize


            case self.OptValOR:
                B1=self.popstack(OptCode)
                A1=Param | B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValORI:
                B1=self.popstack(OptCode)
                A1=ParamI | B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValORII:
                B1=self.popstack(OptCode)
                A1=ParamII | B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValORS:
                A2=self.popstack(OptCode)
                B1=self.popstack(OptCode)
                A1=A2 | B1
                self.SetFlags(A1)
                self.pushstack(A1,OptCode)
                Opsize=1
                self.pc=self.pc+Opsize


            case self.OptValJMPZ:
                if ( self.ZF ):
                    self.pc=Param
                else:
                    Opsize=3
                    self.pc=self.pc+Opsize

            case self.OptValJMPN:
                if ( self.NF ):
                    self.pc=Param
                else:
                    Opsize=3
                    self.pc=self.pc+Opsize

            case self.OptValJMPC:
                if ( self.CF ):
                    self.pc=Param
                else:
                    Opsize=3
                    self.pc=self.pc+Opsize

            case self.OptValJMPO:
                if ( self.OF ):
                    self.pc=Param
                else:
                    Opsize=3
                    self.pc=self.pc+Opsize

            case self.OptValJMP:
                self.pc=Param

            case self.OptValJMPI:
                self.pc=ParamI

            case self.OptValJMPS:
                self.pc=self.popstack(OptCode)

            case self.OptValCAST:
                self.HandleCast(Param,ParamI,ParamII)
                Opsize=3
                self.pc=self.pc+Opsize

            case self.OptValPOLL:
                self.HandlePoll(Param,ParamI,ParamII)
                Opsize=3
                self.pc=self.pc+Opsize         

            case self.OptValRRTC:
                R1=self.popstack(OptCode)
                NCF=0
                if ( R1 & 1 ):
                    NCF = 1 << 2              
                OCF=self.CF << 15
                R1=R1 >> 1 | OCF
                self.CF=1 if NCF > 0 else 0
                self.pushstack(R1,OptCode)
                Opsize=1
                self.pc=self.pc+Opsize         

            case self.OptValRLTC:
                R1=self.popstack(OptCode)
                NCF=0
                if ( R1 & 0x8000):
                    NCF=1
                OCF=self.CF
                R1=(R1<<1) + OCF
                self.CF=1 if  NCF > 0 else 0
                self.pushstack(R1,OptCode)
                Opsize=1
                self.pc=self.pc+Opsize

            case self.OptValSHR:
                R1=self.popstack(OptCode)
                B1=0
                if ( R1 & 0x1):
                    B1=1
                R1=R1 >> 1
                self.CF=B1
                self.pushstack(R1,OptCode)         
                Opsize=1
                self.pc=self.pc+Opsize         

            case self.OptValSHL:
                R1=self.popstack(OptCode)
                B1=0
                if ( R1 & 0x8000):
                    B1=1
                R1=R1 << 1
                self.CF=B1
                self.pushstack(R1,OptCode)         
                Opsize=1
                self.pc=self.pc+Opsize

            case self.OptValINV:
                R1=~(self.popstack(OptCode))
                self.pushstack(R1,OptCode)
                self.SetFlags(R1)
                self.CF=0
                self.OF=0
                Opsize=1
                self.pc=self.pc+Opsize

            case self.OptValCOMP2:
                R1=self.popstack(OptCode)
                R1= ((~R1 & 0xffff) + 1) & 0xffff
                self.pushstack(R1,OptCode)
                self.SetFlags(R1)
                self.CF=0
                self.OF=0
                Opsize=1
                self.pc=self.pc+Opsize

            case self.OptValFCLR:
                self.NF=0
                self.CF=0
                self.ZF=0
                self.OF=0
                Opsize=1
                self.pc=self.pc+Opsize

            case self.OptValFSAV:
                TF=self.ZF+(self.NF<<1)+(CF<<2)+(OF<<3)
                self.pushstack(TF,OptCode)
                Opsize=1
                self.pc=self.pc+Opsize

            case self.OptValFLOD:
                self.ZF=0
                self.NF=0
                self.CF=0
                self.OF=0
                R1=self.popstack(OptCode)
                if ( R1 & 0x1):
                    self.ZF=1
                if ( R1 & 0x2):
                    self.NF=1
                if ( R1 & 0x4):
                    self.CF=1              
                if ( R1 & 0x8):
                    self.OF=1
                Opsize=1
                self.pc=self.pc+Opsize

            case _:
                print("Unknown OptCode %d at address %0x04\n",OptCode,self.pc)
                self.pc += 1
                



