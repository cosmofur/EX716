#!/usr/bin/python3

import numpy as np
import itertools
import sys
import os
import re as re
import json
import rpdb
import atexit
import readline
import readchar
import cProfile, pstats, io
from pstats import SortKey

from pathlib import Path
path_root = os.path.abspath("lib")
sys.path.append(str(path_root))


import select
import tty
import termios


import signal
from functools import lru_cache

StoreMem = np.zeros(0x10000, dtype=np.uint8)
FileLabels = {}
GlobeLabels = {}
FWORDLIST = []
FBYTELIST = []
MacroData = {}
MacroStack = []
breakpoints = []
tempbreakpoints = []
MacroPCount = {}
GlobalLineNum = 0
GlobalOptCnt = 0
Entry = 0
DeviceHandle = None
DeviceFile = 0
ActiveFile = ""
EchoFlag = False


GLOBALFLAG = 1
LOCALFLAG = 2
watchwords = []
MAXMEMSP=0xffff
MAXHWSTACK=0xff - 2
Debug = False

InDebugger=False
RunMode = False
GPC = 0
LineAddrList = [[0,0],[0,0]]


CPUPATH = os.getenv('CPUPATH')
JSONFNAME="CPU.json"
if CPUPATH is None:
    CPUPATH = ".:../lib/:./lib/"
for testpath in CPUPATH.split(":"):
    if os.path.exists(testpath + "/" + JSONFNAME):
        JSONFNAME=testpath + "/" + JSONFNAME
with open(JSONFNAME,"r") as openfile:
    SymToValMap = json.load(openfile)
OPTLIST = []
OPTSYM = []
OPTDICT = {}

for i in SymToValMap:
    # We are going 'old school' 8 bit ascii encoding only.
    # None of this newfagle 2 or 3 byte character sets. :-)
    OPTLIST.append(i[0])
    OPTSYM.append(i[1].encode('ascii', "ignore").decode('utf-8', 'ignore'))
    OPTDICT[i[1].encode('ascii', "ignore").decode('utf-8', 'ignore')] = [i[0],i[1].encode('ascii', "ignore").decode('utf-8', 'ignore'),i[2]]
    OPTDICT[str(i[0])] = [i[0],i[1].encode('ascii', "ignore").decode('utf-8', 'ignore'),i[2]]

def shandler(signum, frame):
    # This is NOT (as yet) an interupt handler for the CPU, just a way to drop code into the debugger.
    # 
    msg = "Ctrl-c"
    print(msg, end="", flush=True)
    debugger()
signal.signal(signal.SIGINT, shandler)

def validatestr(instr,typecode):
    # When we call int() function we must first make sure the string passed if value for that
    # numeric base. We support hex, octal, binary and 'decimal' 
    alpha="0123456789xo"
    if typecode == 16:
        alpha="0123456789abcdefABCDEF-+x"
    elif typecode == 2:
        alpha="01+-xb"
    elif typecode == 8:
        alpha="01234567+-xo"
    newstr=""
    for cc in instr:
        if not( cc in alpha ):
            print("String %s is not valid for base %d" % (instr,typecode))
        else:
            newstr += cc
    return(int(newstr,typecode))
    
    

# I must admit it, I am not a 'natural' OO programmer.
# I learned to code back in the 'waterfall' days and to me using 'class' here
# just feels like fluff around good and true solid 'functions'
# I'd appologize for bad code, except I really don't want to, as I consider OO a
# handicap, and not a feature.  
#
class microcpu:

    cpu_id_iter = itertools.count()

    def switcher(self,optcall,argument):
        default = "Invalid call"
#        if Debug:
#            print("Trying to run opt%s %04x" % (OPTDICT[str(optcall)][1],argument))
        return getattr(self, "opt" + OPTDICT[str(optcall)][1], lambda: default)(argument)

    def __init__(self, origin, memspace):
        self.pc = origin
        self.flags = 0    # B0 = ZF, B1=NF, B2=CF, B3=OF
        self.memspace = np.zeros(memspace, dtype = np.uint8,)
        self.identity = next(self.cpu_id_iter)
        self.mb = np.zeros(256, dtype = np.uint8)
        self.netqueue = []
        self.netapps = []
        self.hwtimer = 0
        self.mb[0xff] = 0
        self.simtime = False
        self.clocksec = 1000

    def insertbyte(self,location,value):
        self.memspace[location] = value

    def twos_compToo(self,val,bits):
        # Convert an 'anysize' signed interget into 2comp bits size integer
        if ( val & ( 1 << (bit -1))) != 0:
            val = val - ( 1 << bits)
        return val

    def twos_compFrom(self,val,bits):
#        return val
        if (val & (1 << (bits - 1))) != 0:    # Sign bit set
            val = val - ( 2 ** bits)
        return val

    def FindWhatLine(self, address):
        global LineAddrList
        i=(-1)
        for i in LineAddrList:
            if i[0] >= address:
                break
        return i[1]

    def raiseerror(self, idcode):
        global GPC, RunMode,FileLabels
        fd = sys.stdin.fileno()
        new = termios.tcgetattr(fd)
        new[3] = new[3] | termios.ECHO          # lflags
        try:
            termios.tcsetattr(fd, termios.TCSADRAIN, new)
        except:
            print("TTY Error: On No Echo")
        
        print("Error Number: %s \n\tat PC:%04x" % (idcode,int(CPU.pc)))
        valid = int(idcode[0:3])
        if RunMode:
            print("At OpCount: %s,%04x" % (self.FindWhatLine(GPC),GPC))
        new[3]
        if not InDebugger:
            sys.exit(valid)
        else:
            print("At OpCount: %s,%04x" % (self.FindWhatLine(GPC),GPC))
            debugger(FileLabels)

    def loadat(self, location, values):
        i = location
        for val in values:
            self.memspace[i] = val
            i += 1

    def readfrom(self, location, blocksize):
        result = []
        for i in range(blocksize):
            result += self.memspace[i+location]
        return result

    def lowbyte(self, invalue):
        invalue = int(invalue)
        return invalue & 0xff

    def highbyte(self, invalue):
        invalue = int(invalue)
        return ((invalue & 0xff00) >> 8)

    def fetchAcum(self, address):
        # Returns value at the top of stack.
        # address zero is alwasy top of stack, other values will attempt to fetch from that stack depth.
        CTPS=self.mb[0xff]
        if address >= MAXHWSTACK:
            self.raiseerror("001 Invalide Buffer Refrence %d. fetchAcum" % address)
        if address == 0 and CTPS>0:
            address = (CTPS-1)*2
        elif address != 0 and address <= CTPS:
            address = CTPS * 2 - (address+1) * 2
        else:
            print("Stack Empty.")
            return 0
        return self.mb[address]+(self.mb[address+1] << 8)

    def StoreAcum(self,address, value):
        # Saves at top of stack the Acum value. Does not change stack.
        # Address zero is always top, a given index >0 will try to save value at that stack depth
        CTPS=self.mb[0xff]
        if address>=MAXHWSTACK:
            self.raiseerror("002 Invalide Buffer Refrence %d, StoreAcum" % address)
        if address == 0:
            address = (CTPS-1)*2
        else:
            address = (CTPS * 2 )  - (address*2)
        self.mb[address] = self.lowbyte(value)
        self.mb[address+1] = self.highbyte(value)

    def getwordat(self, address):
        a = 0
        if address >= MAXMEMSP:
            print("Invalid address %s" % address)
            return 0
            self.raiseerror("003 Invalid Address: %d, getwordat" % (address))
        a = (self.memspace[address] + (self.memspace[address+1] << 8))
        return a

    def putwordat(self, address, value):
        address = int(address)
        if address > MAXMEMSP:
            self.raiseerror("004 Invalid Address: %d, putwordat" % (address))
        self.insertbyte(address, self.lowbyte(value))
        self.insertbyte(address + 1, self.highbyte(value))

    def optNOP(self, count):
        return

    def optPUSH(self, invalue):
        sp = self.mb[0xff]
        if sp > (0xff/2 - 2):
            self.raiseerror("005 MB Stack overflow, optpush" )
        sp *= 2
        self.mb[sp] = self.lowbyte(invalue)
        self.mb[sp + 1] = self.highbyte(invalue)
        self.mb[0xff] += 1

    def optDUP(self, address):
        sp = self.mb[0xff]
        if sp > (0xff/2 - 2):
            self.raiseerror("005 MB Stack overflow, optpush" )
        sp *= 2
        self.mb[sp] = self.lowbyte(self.mb[sp - 2])
        self.mb[sp + 1 ] = self.lowbyte(self.mb[sp - 1])
        self.mb[0xff] += 1

    def optPUSHI(self, address):
        sp = self.mb[0xff]
        if sp > (0xff/2 - 2):
            self.raiseerror("006 MB Stack overflow, optPUSHI")
        sp *= 2
        if (address+1 > MAXMEMSP):
            self.raiseerror("007 Invalid Address: %d, optPUSHI" % (address))
        self.mb[sp] = self.memspace[address]
        address += 1
        if (address <= MAXMEMSP):
            self.mb[sp+1] = self.memspace[address]
        self.mb[0xff] += 1

    def optPUSHII(self, address):
        sp = self.mb[0xff]
        if sp > (0xff/2 - 2):
            self.raiseerror("008 MB Stack overflow, optPUSHII")
        sp *= 2
        newaddress = self.getwordat(address)
        if (newaddress+1 > MAXMEMSP):
            self.raiseerror("009 Invalid Indirect Address: %d, optPUSHII" % (newaddress))
        self.mb[sp] = self.memspace[newaddress]
        newaddress += 1
        if (newaddress <= MAXMEMSP):
            self.mb[sp+1] = self.memspace[newaddress]
        self.mb[0xff] += 1

    def optPUSHS(self, address):
        # Since we are storing the result in the same stack spot as the address was, no need for overflow checks
        newaddress = self.fetchAcum(0)
        self.StoreAcum(0,self.getwordat(newaddress))
        
    def optPOPNULL(self, address):
        if (address > MAXMEMSP):
            self.raiseerror("010 Invalid Address: %d, optPOPI" % (address))
        sp = self.mb[0xff]
        if sp < 1:
            self.raiseerror("011 Stack underflow, optPOPI")
        self.mb[0xff] -= 1

    def optSWP(self, address):
        # We're not changing the sp level, so no need for tests.
        sp = self.mb[0xff]
        sp *= 2
        # Pythonic swap
        self.mb[sp - 2],self.mb[sp - 4] = self.mb[sp - 4], self.mb[sp - 2]
        self.mb[sp - 1],self.mb[sp - 3] = self.mb[sp - 3], self.mb[sp - 1]

    def optPOPI(self, address):
        if (address > MAXMEMSP):
            self.raiseerror("010 Invalid Address: %d, optPOPI" % (address))
        sp = self.mb[0xff]
        if sp < 1:
            self.raiseerror("011 Stack underflow, optPOPI")
        sp -= 1
        sp *= 2
        if sp > (0xff/2 - 2):
            self.raiseerror("012 MB Stack overflow, optPOPI")
        self.insertbyte(address, self.mb[sp])
        if (address+1 <= MAXMEMSP):
            self.insertbyte(address+1, self.mb[sp+1])
        self.mb[0xff] -= 1

    def optPOPII(self, firstaddress):
        address = self.getwordat(firstaddress)
        if (address+1 > MAXMEMSP):
            self.raiseerror("013 Invalid Indirect Address: %d, optPOPII" % (address))
        sp = self.mb[0xff]
        if sp < 1:
            self.raiseerror("014 Stack underflow, optPOPII")
        self.optPOPI(address)

    def optPOPS(self, notused):
        if self.mb[0xff] < 2:
            self.raiseerror("051 Stack underflow, OptPOPS")
        newaddress = self.fetchAcum(0)
        A1 = self.fetchAcum(1)
        self.putwordat(newaddress,A1)
        self.mb[0xff] -= 2

    def SetFlags(self, A1):
        # The Basic SetFlags only works for fixed numbers so we'll only look at
        # Zero, Negative and Carry.
        # Overflow requires us to know if we are adding or subtracting so we'll do
        # That inside the add/sub/cmp operations
        ZF = 0
        NF = 0
        CF = 0
        B2=abs(A1) & 0xffff;
        ZF=1 if (B2 == 0) else 1
        NF=1 if ((B2 & 0x8000) != 0) else 0
        CF=1 if (A1 & 0xffff0000) > 0 else 0
        self.flags = ZF+(NF<<1)+(CF<<2)

    def OverFlowTest(a,b,c,IsSubStraction):
        if ( IsSubStraction == 0):
            if (((a > 0) and (b > 0) and (c < 0)) or ((a < 0) and (b < 0) and (c >= 0))):
                OF=1
            else:
                OF=0
        else:
            if (((a > 0) and (b < 0) and (c < 0)) or ((a < 0) and (b > 0) and (c >= 0))):
                OF=1
            else:
                OF=0
        self.flags=(self.flags & 0x37) | (OF << 3)
                
    def optCMP(self, asvalue):
        R1 = asvalue
        R2 = self.fetchAcum(0)
        A1 = R2 - R1
        self.SetFlags(A1)
        self.OverFlowTest(R2,R1,A1,1)

    def optCMPS(self, address):
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R2 - R1
        self.SetFlags(A1)
        self.OverFlowTest(R2,R1,A1,1)        

    def optCMPI(self, address):
        R1 = self.getwordat(address)
        R2 = self.fetchAcum(0)        
        A1 = R2 - R1
        self.SetFlags(A1 & 0xffff)
        self.OverFlowTest(R2,R1,A1,1)

    def optCMPII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("017 Invalid Address for CMP: %d, optCMPII" % (address))
        newaddress = self.getwordat(address)
        self.optCMPI(newaddress)

    def optADD(self, invalue):
#        R1 = self.twos_compFrom(self.fetchAcum(0),16)
#        R2 = self.twos_compFrom(invalue, 16)
        R1 = self.fetchAcum(0)
        R2 = invalue
        A1 = R1 + R2
        self.SetFlags(A1)
        self.OverFlowTest(R1,R2,A1,0)
        self.StoreAcum(0,A1)

    def optADDS(self, invalue):
#        R1 = self.twos_compFrom(self.fetchAcum(0),16)
#        R2 = self.twos_compFrom(self.fetchAcum(1),16)
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R1 + R2
        self.SetFlags(A1)
        self.OverFlowTest(R1,R2,A1,0)        
        self.mb[0xff] -= 1
        self.StoreAcum(0,A1)

    def optADDI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("023 Invalid Address: %d, optADDI" % (address))
        newaddress = self.getwordat(address)
        self.optADD(newaddress)

    def optADDII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("029 Invalid Address: %d, optANDII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("030 Invalid Address %d, optANDII" % (address))
        self.optADDI(newaddress)

    def optSUB(self, invalue):
#       R1 = self.twos_compFrom(self.fetchAcum(0),16)
#       R2 = self.twos_compFrom(invalue,16)
        R2 = self.fetchAcum(0)
        R1 = invalue
        A1 = R2 - R1
        self.SetFlags(A1)
        self.OverFlowTest(R2,R1,A1,1)
        A1 = A1 & 0xffff
        self.StoreAcum(0,A1)

    def optSUBS(self, invalue):
#        R1 = self.twos_compFrom(self.fetchAcum(0),16)
#        R2 = self.twos_compFrom(self.fetchAcum(1),16)
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R1 - R2
        self.SetFlags(A1)
        self.OverFlowTest(R1,R2,A1,1)
        self.mb[0xff] -= 1
        self.StoreAcum(0,A1)


    def optSUBI(self, address):
#        R1 = self.twos_compFrom(self.getwordat(address),16)
#        R2 = self.twos_compFrom(self.fetchAcum(0),16)
        R1 = self.getwordat(address)
        R2 = self.fetchAcum(0)      
        A1 = (R1 - R2) & 0xffff
        self.SetFlags(A1)
        self.OverFlowTest(R1,R2,A1,1)
        self.StoreAcum(0,A1)


    def optSUBII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("031 Invalid Address: %d, optSUBII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("032 Invalid Address %d, optSUBII" % (address))
        self.optSUBI(newaddress)

    def optOR(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = ivalue
        A1 = R1 | R2
        self.SetFlags(A1)
        A1 = A1 & 0xffff
        self.StoreAcum(0,A1)

    def optORS(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R1 | R2
        self.SetFlags(A1)
        A1 = A1 & 0xffff
        self.mb[0xff] -= 1
        self.StoreAcum(1,A1)

    def optORI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("028 Invalid Address: %d, optORI" % (address))
        newaddress = self.getwordat(address)
        self.optOR(newaddress)

    def optORII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("035 Invalid Address: %d, optORII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("036 Invalid Address %d, optORII" % ( address ))
        self.optORI(newaddress)

    def optAND(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = ivalue
        A1 = R1 & R2
        self.SetFlags(A1)
        A1 = A1 & 0xffff
        self.StoreAcum(0,A1)

    def optANDS(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R1 & R2
        self.SetFlags(A1)
        A1 = A1 & 0xffff
        self.mb[0xff] -= 1
        self.StoreAcum(0,A1)

    def optANDI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("027 Invalid Address: %d, optANDI" % (address))
        newaddress = self.getwordat(address)
        self.optAND(newaddress)

    def optANDII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("033 Invalid Address: %d, optANDII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("034 Invalid Address %d, optANDII" %  (address))
        self.optANDI(newaddress)

    def optJMPZ(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("018 Invalid Address for Jump: %d, optJMPZ" % (address))
        if ((self.flags & 0x1) != 0 ):
            self.pc = address

    def optJMPN(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("019 Invalid Address for Jump: %d, optJMPN" % (address))
        if ((self.flags & 0x2) != 0 ):
            self.pc = address

    def optJMPC(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("020 Invalid Address for Jump: %d, optJMPC" % (address))
        if ((self.flags & 0x4) != 0 ):
            self.pc = address

    def optJMPO(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("021 Invalid Address for Jump: %d, optJMPO" % (address))
        if ((self.flags & 0x8) != 0 ):
            self.pc = address

    def optJMP(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("022 Invalid Address for Jump: %d, optJMP" % (address))
        self.pc = address

    def optJMPI(self, address):
        newaddress = self.getwordat(address)
        self.pc = newaddress

    def optCAST(self, address):
        global Debug, DeviceHandle, DeviceFile
        # In the future 'CAST' will related to networking, for now it will just write to stdout
        # for now it acts as the stdout write tool
        # if Acum is 0, it will print a small dump of the memory of address and the current Stack
        # if 1, it will print the null terminated string starting at address
        # if 2 it will print the 16bit integer value
        # if 3 it will print the value at the address given
        # if 4 it will print the signed value at the address given.
        # if 5 it will print the binary at the address given.
        # if 6 it will print just ascii code of lower byte of operand
        # 11 is like 1, but using indirect address [address]
        # 12 is like 2, but using indirect address [address]
        # 16 is like 6, but will priunt lower byte of value at [address]
        # 17 print 16b hex value at address
        # 18 print 16b hex value at [address]
        # 19 print 32bit int stored at 4 bytes starting at address
        # Disk Hardware Codes: A very primitive 'random IO Block' device, no filesystem, just addresses of 256 byte blocks.
        # 20 is selects Random Access storage device (disk) address is the ID of the device (disk 0 , disk 1 etc)
        # 21 is 'seek' identifies the record in the current disk.
        # 22 is 'write block' address points to a block of memory (256 bytes) that will be written to disk
        # 23 is sync, closes the device until the next write.
        # if 32 it will print the 32 bit integer value stored AT location of address
        # if 33 if will print the 32 bit integer value combining top two 16b words on HW stack

        if address >= (MAXMEMSP-11):
            self.raiseerror("037 Insufficent space for Message Address at %d, optCAST" % (address))
        cmd = self.fetchAcum(0)
        if cmd == 0:
            if self.mb[0xff] > 0:
                print("Stack: \n".join('%02x '%item for item in self.mb[0:self.mb[0xff]]))
            DissAsm(self.pc, 3, self)
        if cmd == 1:
            i = address
            while self.memspace[i] != 0 and i < MAXMEMSP:
                c = self.memspace[i]
                if c == 0:
                    print("Odd C is zero")
                if (c<32 or c > 127) and ( c != 10 and c != 7 and c != 27 and c != 30 ):
                    sys.stdout.write("\%02x" % c)
                else:
                    sys.stdout.write(chr(c))
                i += 1
        if cmd == 2:
            sys.stdout.write("%d" % address)
        if cmd == 3:
            v = self.memspace[address]+(self.memspace[address+1] << 8)
            sys.stdout.write("%d" % v)
        if cmd == 4:
            v = self.memspace[address]+(self.memspace[address+1] << 8)
            sys.stdout.write("%d" % (self.twos_compFrom(v,16)))
        if cmd == 5:
            v = self.memspace[address]+(self.memspace[address+1] << 8)
            sys.stdout.write("%s" % bin(v)[0:15])
        if cmd == 6:
            v = self.memspace[address]
            if ( v<31):
                 print("%c"%v)
            else:
                sys.stdout.write(chr(v))
        if cmd == 11:
            i = self.getwordat(self.getwordat(address))
            while self.memspace[i] != 0 and i < MAXMEMSP:
                c = self.memspace[i]
                print("ORD-C: %02x" % c)
                if c == 0:
                    print("Odd C is zero")
                if (c<32 or c > 127) and ( c != 10 and c != 7 and c != 30 ):
                    sys.stdout.write("\%02x" % c)
                else:
                    sys.stdout.write(chr(c))
                i += 1
            sys.stdout.write("%d" % address)
        if cmd == 12:
            sys.stdout.write("%d" % self.getwordat(address))
        if cmd == 16:
            v = self.memspace[self.getwordat(address)]
            sys.stdout.write("%c" % chr(v))
        if cmd == 17:
            v = self.getwordat(address)
            sys.stdout.write("%04x" % (v))
        if cmd == 18:
            v = self.getwordat(self.getwordat(address))
            sys.stdout.write("%04x" % v)
        if cmd == 19:
            v = self.getwordat(address)
            v = v + (self.getwordat(address+2) << 16)
            sys.stdout.write("%s" % v)
        if cmd == 20:
            if DeviceHandle == None:
                DeviceHandle = "DISK%02d.disk" % self.getwordat(address)
            try:
                DeviceFile = open(DeviceHandle,"r+b")
            except IOError:
                self.raiseerror("048 Error tying to open Random Device: %s" % DeviceHandle)
        if cmd == 21:
            saddr = self.getwordat(address)*0x100
            DeviceFile.seek(saddr,0)
        if cmd == 22:
            if address <  MAXMEMSP-0xff:
                block = self.memspace[address:address+0xff]
                DeviceFile.write(bytes(block))
            else:
                self.raiseerror("049 Attempted to write block larger than memory to storage")
        if cmd == 23:
            if DeviceHandle != None:
                DeviceFile.close()
                DeviceHandle = None
        if cmd == 32:
            iaddr=address
            v=self.getwordat(iaddr) + (self.getwordat(iaddr + 2) << 16)
            if ( v & ( 1 << 31 ) != 0) :
                v = v - (1 << 32)
            sys.stdout.write("%s" % v)
        if cmd == 33:
            v=self.fetchAcum(0) + (self.fetchAcum(1) << 16)
            sys.stdout.write("%d" % v)
        if cmd == 99:
            sys.stdout.write("\nEND of Code:(%d Opts)" % GlobalOptCnt )
            sys.exit(address)
        if cmd == 100:
            Debug = not(Debug)
        if cmd == 102:
            sys.stdout.write("\nStack ( %d):" % (self.mb[0xff]))
            for i in range(self.mb[0xff]):
                val = self.mb[i*2]+(0xff*self.mb[i*2+1])
                sys.stdout.write(" %04x" % (val))
            print("")
        sys.stdout.flush()

    def optPOLL(self, address):
        global Debug, EchoFlag
        # POLL is the Input funciton
        # Acum holds the funciton and parm holds either value or address
        # Acum,            Action
        # 1         Read in just digts or '-' for signed integer. Store at address
        # 2         Read line of text, linefeed replaced by null
        # 3         Read keybord character saved it as 16 bit value at address, no echo. Some See list for 'special' keys
        # 4         Set TTY no-echo
        # 5         Set TTY ech
        # 22        Requires Disk Device already initilized. Reads 256 Byte block from [address]
        # 
        if address >= (MAXMEMSP-11):
            self.raiseerror("046 Insufficent space for Message Address at %d, optPOLL" % (address))
        cmd = self.fetchAcum(0)
        if cmd == 1:
            sys.stdout.flush()
            rawdata = sys.stdin.readline(256)
            justnum = "0"
            for c in rawdata:
                if ( c >= '0' and c <= '9') or ( c == '-' ):
                    justnum = justnum + c
            if int(justnum) < 65535 and int(justnum) >= -32767:
                CPU.putwordat(address,int(justnum))
            else:
                print("Error: %s is not valid 16 bit number" %justnum)
                CPU.putwordat(address,0)
        if cmd == 2:
            sys.stdout.flush()
            rawdata = sys.stdin.readline(256)
            i = address
            for c in rawdata:
                if ord(c) > 31:
                    c = ord(c)
#                    c = ( ord(c) << 8  & 0xff00 )
                    self.putwordat(i,c)
                    i += 1
                    if ( i > ( MAXMEMSP-11) ):
                        self.raiseerror("047 Insufficent space for Message Address at %d, optPOLL" % (i))
        if cmd == 3:
            # Address must be at least 4 bytes for special code strings.
            c = readchar.readkey()
            if not(c):
                c=""            
#            c = keyboard.read_key()
#            c = raw_input("")
#            c = readchar.readkey()
 
            if len(c) == 1:
                self.putwordat(address,ord(c))
            elif len(c) == 2:
                self.putwordat(address,(ord(c[0])) << 8 + (ord(c[1])))
                self.putwordat(address+2,0)
            elif len(c) == 3:
                self.putwordat(address,(ord(c[1])) << 8 + (ord(c[1])))
                self.putwordat(address+2,(ord(c[2]))) # This will create a 3 char string null terminated
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
        if cmd == 22:
            if DeviceHandle != None:
                if address < MAXMEMSP-0xff:
                    block = DeviceFile.read(256)
                    tidx=self.getwordat(address)
                    for i in block:
                        self.memspace[tidx] = int(i) & 0xff
                        tidx += 1
                else:
                    self.raiseerror("053 Attempted to read block with insuffient memory")
            
    def optRRTC(self, unused):
        # RRTC mean Rotate Right Through Carry
        # Means after rotation current CF becomes high bit, and previous low bit saves to CF
        R1 = self.fetchAcum(0)
        NCF = ( 1 if ( R1 & 1 != 0) else 0 ) << 2              # New Carry Flag from Right most bit
        OCF = (1 if (self.flags & 0x04 != 0) else 0) << 15     # Pull CF from flags and make it 1 | 0
        R1 = R1 >> 1 | OCF
        self.flags = ( self.flags & 0xfffb) | NCF
        self.StoreAcum(0,R1)

    def optRLTC(self, unused):
        # RLTC means Rotate Left Through Carry
        # After rotation current CF becomes low bit, and previous high bit saves to CF
        R1 = self.fetchAcum(0)
        NCF = ( 1 if ( R1 & 0x08000 != 0) else 0) << 2       # New Carry Flag from Left Most bit
        OCF = ( 1 if (self.flags & 0x04 != 0) else 0)        # Pull CF from flags and make 1 | 0
        R1 = R1 << 1 + OCF
        self.flags = ( self.flags & 0xfffb) | NCF
        self.StoreAcum(0,R1)

    def optRTR(self, unused):
        # RTR mean rotat Right and set carry CF to equal current lowest bit
        R1 = self.fetchAcum(0)
        NCF = ( 1 if ( R1 & 0x1 != 0) else 0) << 2
        R1 = R1 >> 1
        self.flags = ( self.flags & 0xfffb) | NCF
        self.StoreAcum(0,R1)

    def optRTL(self, unused):
        # RTL mean rotat Left and set carry CF to equal current Highest bit
        R1 = self.fetchAcum(0)
        NCF = ( 1 if ( R1 & 0x8000 != 0) else 0) << 2
        R1 = R1 << 1
        self.flags = ( self.flags & 0xfffb) | NCF
        self.StoreAcum(0,R1)

    def optINV(self, address):
        R2 = self.fetchAcum(0)
        A1 = ~R2
        self.SetFlags(A1)
        A1 = A1 & 0xffff
        self.StoreAcum(0,A1)

    def optCOMP2(self, address):
        R2 = self.fetchAcum(0)
        A1 = ~R2 + 1
        self.SetFlags(A1)
        A1 = A1 & 0xffff
        self.StoreAcum(0,A1)

    def optFCLR(self, address):
        self.flags = 0

    def optFSAV(self, address):
        self.optPUSH(self,self.flags)
        
    def optFLOD(self, address):
        if sp < 1:
            self.raiseerror("051 Stack underflow, OptFLOD")
        sp -= 1
        sp *= 2
        if sp > (0xff/2-2):
            self.raiseerror("052 Stack overflow, optFLOD")
        self.flags = self.mb[sp]
        self.mb[0xff] -= 1

    def evalpc(self):      #main evaluate current instruction at memeory[pc]
        global GPC
        pc = self.pc
        GPC = pc
        optcode = self.memspace[pc]
        if not(optcode in OPTLIST):
            print(OPTLIST)
            self.raiseerror("038 Optcode %s at Addr %04xis invalid:" % (optcode, pc))
        if Debug:
            print("###   ",end="")
            DissAsm(pc, 1, self)
            watchfield = ""
            if watchwords:    
                wfcomma = ""
                for wb in watchwords:
                    nv = self.memspace[wb]
                    watchfield = (watchfield + wfcomma + "%04x" % self.getwordat(nv))
                    wfcomma = ","
                watchfield = "Watch[" + watchfield + "]"
        if (OPTDICT[str(optcode)][2] == 3):  # In HW this would be when we know if we read 3 bytes or 1
            argument = self.getwordat(pc + 1)
        else:
            argument = 0
        pc += OPTDICT[str(optcode)][2]

        self.pc = pc
        self.switcher(optcode,argument)


def removecomments(inline):
    # Return inline up to to any '#' that is not inside quotes, else return full inline.
    inquote = False
    cptr = 0
    for c in inline:
        if c == '"' and not(inquote):
            inquote = True
        elif c == '"' and inquote:
            inquote = False
        elif c == '#' and not(inquote):
            if cptr == 0:
                return ""
            else:
                return inline[:cptr]
        cptr += 1
    return inline



def GetQuoted(inline):
    # Return both the quoted text (if any) and length of original line used by quote, including quotes and escapes
    inquote = False
    outputtext = ""
    inescape = False
    qsize = 0
    if not inline:
        return ( qsize,"")
    for c in inline:
        if not(inquote) and c == '"':
            inquote = True
            qsize += 1
        elif inquote and not(inescape) and c == '"':
            inquote = False
            break
        elif not(inescape) and c == '\\':
            inescape = True            
        elif inescape:        # We support some but not all the \ codes 'c' does
            if c == 'n':
                outputtext += '\n'         # Newline
            elif c == 't':
                outputtext += '\t'         # Tab
            elif c == 'e':
                outputtext += ord(32)      # ESC
            elif c == '0':
                outputtext += '\0'         # Null
            elif c == 'b':
                outputtext += '\b'         # BackSpace
            else:
                outputtext += c
            inescape = False
            qsize += 2
        elif inquote:
            outputtext += c
            qsize += 1
    return (qsize if qsize == 0 else qsize + 1,outputtext)

def nextword(ltext):
    size = 0
    result = ""
    wbefore = True
    wafter = False
    spliter = " ,"            # We allow both " "s and "," as word splitters
    for c in ltext:
        size += 1
        if c in spliter and wbefore:
            continue
        if c == '"' and wbefore:
            # Quoted text is it's own thing.
            (size,result)=GetQuoted(ltext)
            result = '"'+result+'"'
            break
        wbefore = False
        if not( c in spliter)  and wafter:
            size = size - 1 if size > 0 else 0
            break
        if c in spliter and not(wafter):
            wafter = True
            continue
        elif c in spliter and wafter:
            continue
        if not(wbefore) and not(wafter):
            result += c

    return (result,size)

def Str2Word(instr):
    # Both 32 and 16 bit string numbers have same rules just diffrent lengths.
    # So use the 32 bit code, but filter just the 16bit size out of it.
    Result = Str32Word(instr) & 0xffff
    return Result

def Str32Word(instr):
    # Support for 0x, hex, 0b for binary and Oo for ocatal as well as decimal by default
    result = 0
    if type(instr) != str:
        # Conversion doesn't make sense if instr is not a string.
        return instr
    if len(instr) < 3:
        # Must be decimal as 0x0 is the smallest by length non decimal
        result = int(instr)
    else:
        if instr[0:2] == "0x":            # Hex
            result = validatestr(instr,16)
        elif instr[0:2] == "0b":          # Binary
            result = validatestr(instr,2)
        elif instr[0:2] == "0o":          # Octal
            result = validatestr(instr,8)
        elif instr[0:1] == '"':           # Quoted text
            result = ord(instr[1:2])
            if (len(instr)>3):
                result = result + (ord(instr[2:3]) << 8)
        elif instr[0:1] != "b" and ( instr[0:1].upper() >= "A" and instr[0:1].upper() <= "Z" ):
            # Note the test for 'b', its a shame but to allow b0 to mean byte 0, we lost lables that start with 'b'
            if instr in FileLabels:
                result = FileLabels[instr]
            else:
                # While we allow lables that represent future addresses to be used before being defined.
                # becuase we just need to overwrite the fixed size 16b memory address once we figure it out
                # But with 'STR2WORD' is used when we need a final value that maybe used in calculation rather
                # that a fixed storage as that result may not occupy any spot in memory, that we can 'fix' in
                # a second pass.
                CPU.raiseerror("054 Use of fixed value as label before defined.")
        else:
            valid=True
            for i in instr:
                if ( i > '9' or i < '0' ):
                    valid=False
                    break
            if valid:
                result = validatestr(instr,10)
            else:
                result = 0
                CPU.raiseerror("050 String %s is not a valid decimal value" % instr)
    result = result & 0xffffffff
    return result

    

def Str2Byte(instr):
    # Just use the Str2Word and keep the lowest byte
    return Str2Word(instr) & 0xff

def DissAsm(start, length, CPU):
    # The DissAsm is not really required for interpitation of the code, but is a usefull tool for debugging
    # The need for the CPU.json file is just used by this module, (and debugger) so a 'speed optimized'
    # version of the code would not need CPU.json at all.
    #
    global watchwords
    StoreMem = CPU.memspace
    i = start
    while i < (start+length):
        OUTLINE=""
        optcode = StoreMem[i]
        DispRef = False
        MaybeLabel = removecomments(getkeyfromval(i,FileLabels)).strip()
        if MaybeLabel != "":
            OUTLINE="%04x: <%s> \n" % (i,MaybeLabel)
        if not(optcode in OPTLIST):
            MESG = "%04x DATA -- %02x " % ( i,optcode)
            if (optcode >= ord('0') and optcode <= ord('9') or (optcode >= ord('A') and optcode <= ord('z'))):
                MESG = MESG+"   '"+chr(optcode)+"' (Skipping forward to next labled block)"
            OUTLINE += " "+MESG
            bestmatch =  len(StoreMem)
            for name, iaddr in FileLabels.items():
                if int(iaddr) > i and int(iaddr) < bestmatch:
                    bestmatch = int(iaddr)
            i = bestmatch
        else:
            OUTLINE += "%04x\t%s\t" % (i, OPTSYM[optcode])
            FLAGSTAT = "FL:"
            if CPU.flags & 1:
                FLAGSTAT += "Z"
            else:
                FLAGSTAT += "_"
            if CPU.flags & 2:
                FLAGSTAT += "N"
            else:
                FLAGSTAT += "_"
            if CPU.flags & 4:
                FLAGSTAT += "C"
            else:
                FLAGSTAT += "_"
            if CPU.flags & 8:
                FLAGSTAT += "O"
            else:
                FLAGSTAT += "_"            
            if OPTDICT[str(optcode)][2] == 1:
                if OPTSYM[optcode][-1] == "S":
                    OUTLINE += "HW Stack: "
                    for ii in range(0,CPU.mb[0xff]):
                        OUTLINE += "%02x[%04x]" % (ii,CPU.fetchAcum(ii))
            if OPTSYM[optcode][-2] == "II":
                OUTLINE += "[["
                wordv = CPU.getwordat(CPU.getwordat(i + 1 ))
                DispRef = True
                OUTLINE += "%04x" % (wordv)
                MaybeLabel = removecomments(getkeyfromval(wordv,FileLabels)).strip()
                if MaybeLabel != "":
                    OUTLINE += "(" +MaybeLabel +")"
            elif OPTSYM[optcode][-1] == "I":
                OUTLINE += "["
                DispRef = True
                wordv = CPU.getwordat(i + 1)
                OUTLINE += "%04x" % (wordv)
                MaybeLabel = removecomments(getkeyfromval(wordv,FileLabels)).strip()
                if MaybeLabel != "":
                    OUTLINE += "(" +MaybeLabel +")"                
            if OPTSYM[optcode][-2] == "II":
                OUTLINE += "]]"
            elif OPTSYM[optcode][-1] == "I":
                OUTLINE += "]"
            elif OPTSYM[optcode][0] == "J":
                wordv = CPU.getwordat(i + 1)
                OUTLINE += "%04x" % (wordv)
                MaybeLabel = removecomments(getkeyfromval(wordv,FileLabels)).strip()
                if MaybeLabel != "":
                    OUTLINE += "(" +MaybeLabel +")"
            else:
                wordv = CPU.getwordat(i + 1)
                OUTLINE += "%04x" % (wordv)
                MaybeLabel = removecomments(getkeyfromval(wordv,FileLabels)).strip()
                if MaybeLabel != "":
                    OUTLINE += "(" +MaybeLabel +")"                
            i += OPTDICT[str(optcode)][2]
            rstring = ""
            if len(watchwords) > 0:
                rstring="Watch:"
                lastad=0
                for ii in watchwords:
                    if (lastad + 1) != ii:
                        rstring = rstring + "%04x:[%02x]" % (ii,CPU.memspace[ii])
                    else:                        
                        rstring = rstring + "[%02x]" % (CPU.memspace[ii])
                    lastad = ii
            rstring += "SD:(%d)" % CPU.mb[0xff]
                
            print("%s %s %s" % (OUTLINE,FLAGSTAT, rstring))
    return i

def getkeyfromval(val,my_dict):
   result = []
   prefered = []
   nresult = ""
   matchlimit = 0
   if val == 0:
       return ""       # Zero is specal case. It almost never a usefull linenumber
   for key,value in sorted(list(my_dict.items()),reverse = True):
      if val == value:
         if "F." in key:
            if matchlimit == 0:
               result =  [str(key)] + result
               matchlimit = 1
         else:
            result.append(key)
   for fld in result:
      if len(fld) != 0:
         nresult += fld + " "
   prefered = [ word for word in nresult.split(' ') if word ]
   i = 0
   nresult = ""
   while i < len(prefered) and i < 2:
      nresult += prefered[i] + " "
      i += 1
   return nresult

def hexdump(startaddr,endaddr,CPU):
    print("Range is %04x to %04x" % ( startaddr, endaddr))
    i = startaddr
    header="0  .  .  .  .  5  .  .  .  .  A  .  .  .  .  F  .  .  .  .  5  .  .  .  .  A  .  .  .  .  F"
    header=header[(startaddr % 16)*3:][0:47]
    print("       %s" % header)
    while i < endaddr:
        Fstring = "%04x: " % int(i)
        sys.stdout.write(Fstring)
        for j in range(i,i+16 if (i + 16 <= len(CPU.memspace)) else len(CPU.memspace)):
            sys.stdout.write("%02x " % CPU.memspace[j] )
        sys.stdout.write("   ")
        for j in range(i,i+16 if (i + 16 <= len(CPU.memspace)) else len(CPU.memspace)):
            c = CPU.memspace[j]
            if (c >= ord('A') and c<= ord('z')) or ( c >= ord('0') and c <= ord('9')):
                sys.stdout.write("%c" % c)
            else:
                sys.stdout.write("_")
        i += 16
        print(" ")
def fileonpath(filename):
    CPUPATH = os.getenv('CPUPATH')
    if CPUPATH == None:
        CPUPATH = ".:lib:test:."
    else:
        CPUPATH = CPUPATH + ":."
    for testpath in CPUPATH.split(":"):
        if os.path.exists(testpath+"/"+filename):
            return testpath+"/"+filename
    print("Import Filename error, %s not found" % ( filename))
    sys.exit(-1)

def IsLocalVar(inlable, LocalID, LORGFLAG):
    global GlobeLabels
    if inlable in GlobeLabels or LORGFLAG == GLOBALFLAG or inlable in FileLabels:
        return inlable
    else:
        return inlable + "___" + str(LocalID)

def ReplaceMacVars(line,MacroVars,varcntstack,varbaseSP):
    global MacroStack
    i = 0
    newline = ""
    inquote = False
    seeescape = False
    while i<len(line):
        c = line[i]
        i = i + 1
        if c == '"' and not(seeescape):
            inquote = not(inquote)
            newline += c
            continue
        seeescape = False
        if c =="\\" and inquote:
            # Main concern for \ is if someone \" inside a quote don't want to exist 'inquote' too soon.
            seeescape = True
            newline += c
            continue
        if c == "%" and not(inquote):
            Before = line[0:i-1]
            After = line[i+1:]
            if ( line[i:i+1] == "P"):
                # POP value from refrence stack...does not change newline
                if (not MacroStack ):
                    CPU.raiseerror("039a Macro Refrence Stack Underflow: %s" % line)
                i += 1
                MacroStack.pop()
                continue
            elif (line[i:i+1] == "S" ):
                # Stores the current %0 value to refrence stack
                # Does not change the newline
                MacroStack.append(MacroVars[varcntstack[varbaseSP]])
                i += 1
                continue
            elif (line[i:i+1] == "V"):
                # Insert into newline value that top if refrence stack...do not pop it
                if (not MacroStack):
                   CPU.raiseerror("039b Macro Refrence Stack Underflow: %s" % line)
                newline = newline + MacroStack[-1]
                i += 1
                continue
            elif (line[i:i+1] >= "0" and line[i:i+1] <= "9"):
                varval = int(line[i:i+1])
                if len(MacroVars) < varval:
                    CPU.raiseerror("039 Macro %v Var %s is not defined" % (varval,line))
                newline = newline+MacroVars[varcntstack[varbaseSP] + varval]
                i = i + 1
        else:
            newline = newline + c
    return newline


def DecodeStr(instr, curaddress, CPU, LocalID, LORGFLAG, JUSTRESULT):
    global FileLabels, FWORDLIST, FBYTELIST, GlobeLabels
    # pass in string that is either a number, or a label, with possible modifiers
    # possible results
    #    instr is a label.
    #          Determine if there is a +/- modifier
    #          Determine if there is a '$', '$$', '$$$'  or 'b' modifier
    #          If label was already defined, then save it to memory
    #          If not yet defined  then return the information needed in return to add it to FWORDLIST
    #    instr is a number
    #          Identifty what base it is in (hex, decimal, ocatal or binary)
    #          Determine if there is a '$', '$$', '$$$' or 'b' modifier
    #
    StoreMem = CPU.memspace
    PNModifier = 0
    ByteFlag = False
    LongWordFlag = False
    Result = 0
    working = instr + "       "   # Add some whitespace so we don't have to worry about testing for length
    if ( working[0] == 'b' ) or ( working[0] == '$' and working[1] == '$' and working[2] != '$'):
        ByteFlag = True
    elif ( working[0] == '$' and working[1] == '$' and working[2] == '$' ):
        LongWordFlag = True
    # Handle possible quoted text
    starti=0
    if working[starti] == '"' and not(JUSTRESULT): # Handle quoted text
        starti += 1
        stopi=len(instr)
        if working[stopi - 1] == '"':
            stopi -= 1
        if starti < 100 and CPU.pc != 0:
            print("DEBUG: mem add %s at pc %s\n" % (starti,CPU.pc))
        for c in working[starti:stopi]:
            StoreMem[int(curaddress)] = ord(c)
            curaddress += 1
        return curaddress
    elif working[starti] == '"' and JUSTRESULT: # Can't do a JUSTRESULT for strings.
        print("String Values can't be modifed with offsets")
        return 0
    # Skip past any remaining modifiers
    while working[starti] == '$' or working[starti] == 'b':
        starti += 1
    # If first 2 characters are in set "0x" "0o" "0b" then we know its a number in a given base. No Lables, no Post Modifiers
    if working[starti] >= "0" and working[starti] <= "9" or (working[starti] == "-" or working[starti] == "+"):
        BaseNum = 10
        if working[starti:starti+2] == "0x":
            BaseNum = 16
            starti += 2
        elif working[starti:starti+2] == "0o":
            BaseNum = 8
            starti += 2
        elif working[starti:starti+2] == "0b":
            BaseNum = 2
            starti += 2
        Result = int(working[starti:],BaseNum)
    else:
        # Here be text lables, look them up, but also look for post modifiers
        stopi = starti + 1
        modval = 0
        while working[stopi].isalnum() or working[stopi] == "_" or working[stopi] == ".":
            stopi += 1 
        # in working[stopi+1] is a '+' or '-' then there is a modifier
        if working[stopi] == '+' or working[stopi] == '-':
            modvalstr=""
            modstart = stopi + 1
            modstop = modstart + 1
            while (working[modstop].isspace() == False ):
                modstop += 1
            modval = DecodeStr(working[modstart:modstop], curaddress, CPU, LocalID, LORGFLAG, True)
#            modval = int(working[modstart:modstop])
        if working[starti:stopi] in FileLabels.keys():
            Result = Str2Word(FileLabels[working[starti:stopi]]) + modval
        else:
            # This is case where the lable has not yet been defined, we will save it in FWORDLIST for 2nd pass.
            Result = 0
            newkey = IsLocalVar(working[starti:stopi], LocalID, LORGFLAG)
            FWORDLIST.append([newkey, curaddress, modval])
            # Lables that are not yet defined HAVE to be 16b
            ByteFlag = False
            LongWordFlag = False
    if JUSTRESULT:
        # This is for cases were the assembler is not to save it into memory.
        return Result
    if curaddress < 100 and CPU.pc != 0:
            print("DEBUG: mem add %s at pc %s\n" % (curaddress ,CPU.pc))  
    if ByteFlag:
        StoreMem[curaddress] = (Result & 0xff)
        curaddress += 1
    elif LongWordFlag:
        StoreMem[curaddress] = (Result & 0xff)
        StoreMem[curaddress + 1] = ((Result >> 8) & 0xff)
        StoreMem[curaddress + 2] = ((Result >> 16) & 0xff)            
        StoreMem[curaddress + 3] = ((Result >> 24) & 0xff)            
        curaddress += 4
    else:
        StoreMem[curaddress] = (Result & 0xff)
        StoreMem[curaddress + 1] = ((Result >> 8) & 0xff)
        curaddress += 2
    return curaddress

# Load file is also the effective main loop for the assembler
def loadfile(filename, offset, CPU, LORGFLAG, LocalID):
    global GlobalLineNum, GlobalOptCnt, Debug, MacroData, MacroPCount, FileLabels, Entry, ActiveFile, FWORDLIST, FBYTELIST, GlobeLabels
    ActiveFile = filename
    StoreMem = CPU.memspace
    address = int(offset)
    line = "#Start"
    backfill = ""
    highaddress = offset
    wfilename = fileonpath(filename)
    with open(wfilename, "r") as infile:
        if address > highaddress:
            highaddress = address
        linecount = 0
        FBYTELIST = []
        ActiveMacro = False
        MacroVars = ['0']*10
        varcnt = 0
        varbaseSP = 0
        varbaseNext = 0
        varcntstack = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        SkipBlock = False
        varcnt = 0
        MacroLine = ""
        varpos = 0
        if Debug:
            print("Reading Filename %s" % wfilename)
        while True:
            if ActiveMacro and line == "":
                # If we are inside a Macro expansion keep reading here, until the macro is fully consumed.
                if len(MacroLine) > 0:
                    (PosParams,PosSize)=nextword(MacroLine)
                    while (PosParams != "" and PosParams != "ENDMACENDMAC"):
                        MacroLine = MacroLine[PosSize:]
                        line = line + " " + PosParams
                        (PosParams,PosSize)=nextword(MacroLine)
                    # at this point line should contain the macro and its possible parameters
                    # Need to subsutute and %# that are not in quotes with varval
                    line = ReplaceMacVars(line,MacroVars,varcntstack,varbaseSP)
                    if Debug:
                        print("Expanded Macro: %s" % line)
                    varbaseNext = varbaseSP
                    varbaseSP -= 1 if varbaseSP > 0 else 0
                    if PosParams == "ENDMACENDMAC":
                        # As macro's may call other macros, we need to mark in the stream where they end.
                        MacroLine = MacroLine[PosSize:]
                    if Debug:
                        print("End-Macro: [:]%s" % backfill)
                    line = line + " "  + backfill
                    backfill = ""
                    ActiveMacro = False
                else:
                    line = backfill
                    if Debug:
                        print("End-Macro: [:]%s" % backfill)
                    backfill = ""
                    ActiveMacro = False
                    continue
            else:
                # If we are macro, or in plain text, we still end up here.
                if line == "":
                    ExitOut = False
                    GetAnother = True
                    while GetAnother:
                        GlobalLineNum += 1
                        GetAnother = False
                        inline = infile.readline()
                        if not ( address in FileLabels):
                            NewLine = {"F."+filename+str(GlobalLineNum):address}
                            FileLabels.update(NewLine)
                        if inline:
                            if inline.strip()[-1:] == '\\':
                                GetAnother = True
                                line = line + inline.strip()[:-1]
                            else:
                                line = line + inline.strip()
                        else:
                            ExitOut = True
                            break
                    if Debug:
                        print("%04x: %s" % (address,line))
                    if ExitOut:
                        break
            line = removecomments(line).strip()
            if Debug:
                if ActiveMacro == False:
                    print("%04x: %s> %s" % (address, GlobalLineNum, line))
                else:
                    print("%04x: M-%s> %s : %s" % (address, GlobalLineNum, line, MacroLine[:16]))

            if SkipBlock:
                while (line != ""):
                    (key, size) = nextword(line)
                    # Because it's not a single letter command, ENDBLOCK is a bit of a outsider.
                    if key != "ENDBLOCK":
                        line = line[size:]
                        continue
                    else:
                        SkipBlock = False
                        line = line[size:]
                        break
                continue
            elif line[:8] == "ENDBLOCK":
                line = line[9:]
                continue
            if len(line) > 0:
                GlobalOptCnt += 1
                IsOneChar = False
                if len(nextword(line)[0]) == 1:
                    IsOneChar = True
                if line[0] == "@":
                    # Use a defined Macro Remain words on line will become local variables
                    cpos = 1
                    # Logic of varcntstack:
                    # Initial vcs[0]==0, so vcs[1] should = # vars + 1
                    # So we alway set the n' top of vcs to vcs[n]+#vars in this macro
                    (macname,size) = nextword(line[cpos:])
                    varbaseSP = varbaseNext
                    MacroVars[varcntstack[varbaseSP]]="__"+str(GlobalOptCnt)+"."+str(len(MacroData))
                    cpos += size
                    if macname in MacroData:
                        # To understand what's going on here: We are making a stack that will
                        # store the local macro var values (%1-max) and macros that call other
                        # macros will just use a diffrent range in that same stack.
                        MacroLine = MacroData[macname] + " ENDMACENDMAC " + MacroLine
                        if  cpos < len(line):
                            varcnt = 0                            
                            for i in range(MacroPCount[macname]):
                                (key,size) = nextword(line[cpos:])
                                varcnt += 1
                                while (varcntstack[varbaseSP]+varcnt + 2) >= len(MacroVars):
                                    MacroVars.append(['0'])
                                MacroVars[varcnt + varcntstack[varbaseSP]] = key
                                cpos += size
                            if varcnt < MacroPCount[macname]:
                                # When Macro was defined we counted the max %# and now require that # Parms
                                CPU.raiseerror("045 Insufficent required parameters (%s/%s) for Macro %s" %
                                               (varcnt, MacroPCount[macname], macname))
                        varcntstack[varbaseSP + 1] = varcntstack[varbaseSP]+varcnt + 1
                        varbaseNext = varbaseSP + 1
                        ActiveMacro = True
                        backfill = line[cpos:] + " " + backfill
                        line = ""
                    else:
                        print("Missing: ", macname)
                        CPU.raiseerror("044  Macro %s is not defined" % (macname))
                # Here is were we start the 'switch case' looking for commands.
                elif line[0] == ":":
                    (key,size) = nextword(line[1:])
                    if Debug:
                        print(">>> adding %s at location %s" % (key, hex(address)))
                    if ("F."+filename+str(GlobalLineNum) in FileLabels):
                        # We are creating an internal 'lable' for each line number.
                        # This will allow us to print in dissassembly mode approximate src line numbers.
                        del FileLabels["F."+filename+str(GlobalLineNum)]
                    newitem = {IsLocalVar(key, LocalID, LORGFLAG): address}
                    FileLabels.update(newitem)
                    line = line[size+1:]
                    continue
                elif line[0] == "=":
                    (key,size) = nextword(line[1:])
                    line = line[size+1:]
                    (value,size) = nextword(line)
                    if (not(value[0:len(value)].isdecimal())):
                        value = DecodeStr(value, address, CPU, LocalID, LORGFLAG, True)
                    FileLabels.update({IsLocalVar(key, LocalID, LORGFLAG): value})
                    line = line[size+1:]
                    continue
                elif line[0] == "." and IsOneChar:
                    (value,size) = nextword(line[1:])
                    if (value[0:1] == '$' or ( not value[0:1].isdigit )):
                        # We are alloing the possibility to set origin point to a lable
                        # that has already been defined. (Like early in file do :main, then at end do . main at end)
                        if value[1:] in FileLabels.keys():
                            value = FileLabels[IsLocalVar(value[1:], LocalID, LORGFLAG)]
                        else:
                            CPU.raiseerror("040 Line %s, Origin point labels %s have to be defined before use:" % (GlobalOptCnt,value))
                    address = Str2Word(value)
                    Entry = address
                    line = line[size+1:]
                    continue
                elif line[0] == "L" and IsOneChar:
                    # Load a file into memory as a library, enable 'local' variables.
                    (newfilename,size) = nextword(line[1:])
                    HoldGlobeLine = GlobalLineNum
                    GlobalLineNum = 0
                    oldfilename = ActiveFile
                    highaddress = address = loadfile(newfilename, address, CPU, LOCALFLAG, GlobalOptCnt)
                    ActiveFile = oldfilename
                    GlobalLineNum = HoldGlobeLine
                    line = line[size+1:]
                    continue
                elif line[0] == "I" and IsOneChar:
                    # Load a file, but keep it in the 'global' context
                    (newfilename,size) = nextword(line[1:])
                    HoldGlobeLine = GlobalLineNum
                    GlobalLineNum = 0
                    oldfilename = ActiveFile
                    highaddress = address = loadfile(newfilename, address, CPU, GLOBALFLAG, GlobalOptCnt)
                    ActiveFile = oldfilename
                    GlobalLineNum = HoldGlobeLine
                    line = line[size+1:]
                    continue
                elif line[0] == "P" and IsOneChar:
                    print("%04x: %s" %(address,line))
                    line = ""
                    continue
                elif line[0] == "!" and IsOneChar:
                    (key, size) = nextword(line[1:])
                    if key in MacroData:
                        SkipBlock = True
                    line = line[size+1:]
                    continue
                elif line[0] == "M" and IsOneChar:
                    # Macros
                    # name word word %v word
                    (key, size) = nextword(line[1:])
                    # We identify how many arguments are used, by the max pcount value. (0-9)
                    # %0 doesn't count as that sys generated, and %'s do not count if quoted
                    # Minit state engine. var_num is next 0-9 after % unless '\' preceded %
                    MacroData.update({key: line[size:]})
                    pcount = 0
                    inesc = False
                    invar = False
                    for c in line[size:]:
                        if not(inesc) and invar and ( c >= "0" and c <= "9" ):
                            invar = False
                            if int(c) > pcount:
                                pcount = int(c)
                        inesc = False
                        if c == '\\':
                            inesc = True
                            continue
                        if c == '%':
                            invar = True
                    MacroPCount.update({key:pcount})
                    line = ""
                    continue
                elif line[0] == "G" and IsOneChar:
                    (key, size) = nextword(line[1:])
                    GlobeLabels.update({key: address})
                    line = line[size+1:]
                    continue
                else:
                    # Pretty much every else drops here to be evaulated as numbers or macros to be defined.
                    LineAddrList.append([address, GlobalLineNum,filename])
#                    LineAddrList.sort(key = lambda x: x[1])
                    (key,size) = nextword(line)
                    line = line[size:]
                    if address > highaddress:
                        highaddress = address
                    if len(key) > 0:
                        address = DecodeStr(key, address, CPU,  LocalID, LORGFLAG, False)
        for store in FWORDLIST:
            key = store[0]
            vaddress = store[1]
            if key in FileLabels.keys():                
                v = Str2Word(FileLabels[key])
                if (len(store) > 2) :
                   if store[2] != 0:
                       v = v + Str2Word(store[2])
                       # This extra bit logic handles the case of lables+## math.
                if int(vaddress) < 100 and CPU.pc != 0:
                    print("DEBUG: mem add %s at pc %s\n" % (vaddress ,CPU.pc))
                StoreMem[int(vaddress)] = CPU.lowbyte(v)
                StoreMem[int(vaddress + 1)] = CPU.highbyte(v)
            else:
                print(key," is missing ", store)
    if Debug:
        i = 0
        print("Pre-Run Memory Dump:")
        hexdump(i+offset,highaddress,CPU)
        DissAsm(i,highaddress,CPU)
        print("----------------END OF DUMP ---------------")
    if address > highaddress:
        highaddress = address
    return highaddress

def debugger(FileLabels):
   global InDebugger,LineAddrList,watchwords, breakpoints, tempbreakpoints, GlobalOptCnt, EchoFlag
   startrange = 0
   stoprange = 0
   redoword = "Null"
   InDebugger = True
   size=0
   cmdword = ""
   while True:
      sys.stdout.write("%04x> " % CPU.pc)
      fd = sys.stdin.fileno()
      if EchoFlag:
            fd = sys.stdin.fileno()
            new = termios.tcgetattr(fd)
            new[3] = new[3] | termios.ECHO          # lflags
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, new)
            except:
                sys.stdout.write("TTY Error: On No Echo")
      else:
          sys.stdout.write(">>")
#      cmdline = sys.stdin.readline(256)
      sys.stdout.flush()
      cmdline = input()
      if EchoFlag:
          new[3] = new[3] & ~termios.ECHO
          try:
              termios.tcsetattr(fd, termios.TCSADRAIN, new)
          except:
              print("TTY Error: On Echo On")
      cmdline = removecomments(cmdline).strip()
      if cmdline != "": 
         (cmdword,size)=nextword(cmdline)
      cmdline = cmdline[size:]
      stepnumber = 1
      doexec = False
      arglist = []
      argcnt = 0
      (thisword,size) = nextword(cmdline)
      cmdline = cmdline[size:]
      varval = 0
      while thisword != "":
          # check to see if argument is a label
         if thisword[0] >= "A" and (thisword[0] <= "z" and thisword[0] != "b"):
            if thisword in FileLabels:
               varval = FileLabels[thisword]
            else:
               print("[%s] is not found in dictionary" % thisword)
               thisword = ""
               continue
            tempdic=[i for i in FileLabels if thisword in i ]
            if len(tempdic) == 1:
               print("Label Match. Using %s "% tempdic)
               varval=FileLabels[tempdic[0]]
               arglist.append(varval)
               argcnt +=1
            else:
               varval = None
               for pi in tempdic:
                   if pi == thisword:
                       varval=FileLabels[pi]
                       arglist.append(varval)
                       argcnt += 1
                       thisword = ""
               if varval == None:
               # Drop here is no exact matchs
                   print("%d Possible matches: "% len(tempdic), tempdic)
                   cmdword="Null"
                   thisword=""
               continue
            if varval == thisword:
               # Not modified, means not defined.
               print("ERR %s was not found in dictionary:" % thisword)
               cmdword = "Null"
               continue
         else:
            thisword = Str2Word(thisword) # Convert to 16 bit number allow 0x formats
            arglist.append(thisword)
            argcnt += 1
         (thisword,size) = nextword(cmdline)
         cmdline = cmdline[size:]
# at this point cmdword == a possible comand and arglist is a group of 16b numbers if any given.
      if cmdword == "Null":
         # Do nothing
         continue
      if cmdword == "d":
         if argcnt > 0:
            startrange=int(arglist[0])
            stoprange=3
         if argcnt > 1:
            stoprange=startrange - int(arglist[1])
            stoprange = DissAsm(arglist[0],stoprange,CPU)
         if argcnt == 0:
            if stoprange != 0:
               startrange = stoprange
            else:
               startrange=CPU.pc
            stoprange=20
         stoprange = DissAsm(startrange, stoprange, CPU)
         continue
      if cmdword == "ps":
         if (CPU.mb[0xff] == 0 ):
            print("Empty Stack")
            continue
         print("Print HW Stack, Depth (%d)" % CPU.mb[0xff])
         for i in range(0,min(CPU.mb[0xff]*2,64),2):
            v = CPU.mb[i] + (CPU.mb[i+1] << 8)
            SInfo = "%04x:" % v
            if ( v > 0 and v < (len(CPU.memspace)-2)):
               SInfo = SInfo+"[%0x]" % CPU.getwordat(v)
               SInfo = SInfo+"[[%0x]]" % CPU.getwordat(CPU.getwordat(v))
            else:
               SInfo = SInfo + "[*]"
            print(SInfo)
            continue
      if cmdword == "p":
         if argcnt > 0:
            if argcnt == 1:
               startv=int(arglist[0])
               stopv=startv + 1
            else:
               startv=int(arglist[0])
               stopv=int(arglist[1]) + 1
            if stopv < startv:
               stopv = startv + stopv + 1
            for v in range(startv,stopv):
               SInfo = "%04x:" % v
               SInfo = SInfo+"[%02x]" % CPU.getwordat(v)
               SInfo = SInfo+"[[%02x]]" % CPU.getwordat(CPU.getwordat(v))
               print(SInfo)
         else:
            print("ERR: Need to specify what to print")
            continue
      if cmdword == "m":
         if argcnt >= 1:
            maddr = arglist[0]
            if argcnt >= 2:
               # This is case where 'm' command was followed by an address and
               # a series of 1 or more word integers on same line.
               for iad in arglist[1:]:
                  mvalue = Str2Byte(iad)
                  CPU.memspace[maddr] = mvalue & 0xff
                  mval = mvap >> 8      
                  CPU.memspace[maddr + 1] = mvalue & 0xff
                  maddr += 2
                  DissAsm(int(arglist[0]),1,CPU)
            else:
               # Start sub-command mode
               cmdline="NONE"
               sys.stdout.write("Key: ")
               sys.stdout.write("### is decimal 0-9 ")
               sys.stdout.write("Prepend 0x, 0o or 0b for hex, octal or binary format\n")
               sys.stdout.write("By default 16 bit integer, prepend $$ for 8 bit bytes or $$$ for 32 bit words\n")
               sys.stdout.write("8 bit ascii codes can be entered using double quotes\n")
               sys.stdout.write("Use '.' on line byself to exit back to main mode.\n\n")
               while True:
                  sys.stdout.write("%04x[b%02x,b%02x]: " % (maddr,CPU.memspace[maddr],CPU.memspace[(maddr+1) &0xffff]))
                  sys.stdout.flush()
#                  cmdline = sys.stdin.readline(256)
                  cmdline = input()
                  cmdline = removecomments(cmdline).strip()
                  if len(cmdline) > 0:
                     if cmdline == "":
                        # empty command means just move forward one byte
                        maddr += 1
                        continue
                     if cmdline != ".":
                        if (cmdline[0:1] == '"'):
                           (quotesize, quotetext) = GetQuoted(cmdline)
                           for iii in range(0,len(quotetext)):
                              CPU.memspace[maddr] = ord(quotetext[iii]) & 0xff
                              maddr += 1
                              cmdline = ""
                           continue
                        if len(cmdline) == 1 and cmdline[0:1] >= "0" and cmdline[0:1] <= "9":
                           newval = int(cmdline)
                           CPU.memspace[maddr] = newval & 0xff # Single digit number must be b10
                           maddr += 1
                           CPU.memspace[maddr] = 0   # high byte has to be zero
                           maddr += 1
                        else:
                           startnum = 0
                           expectsize = 2
                           if cmdline[0:3] == "$$$":
                              expectsize = 4
                              startnum = 3
                        if cmdline[0:2] == "$$":
                           expectsize = 1
                           startnum = 2
                        elif cmdline[0:1] == "$":
                           startnum = 1
                        try:
                           if expectsize != 4:
                              if ( cmdline[startnum:] in FileLabels.keys()):
                                 newval = Str2Word(FileLabels[cmdline[startnum:]])
                              else:
                                 newval = Str2Word(cmdline[startnum:])
                           else:
                              newval = int(cmdline[startnum:])
                           for iii in range(0,expectsize):
                              CPU.memspace[maddr] = newval & 0xff
                              newval = newval >> 8
                              maddr += 1
                        except:
                           print("Input %s not valid" % cmdline)
                        continue
                     else:
                        cmdline=""
                        print("End Modify")
                        break
      if cmdword == "l":
         startaddr=0
         stopaddr=30
         if argcnt > 0:
            v=int(arglist[0])
            startaddr = 0
            for i in LineAddrList:
               if i[1] >= v:
                  if len(i) > 1:
                     if i[2] == ActiveFile:
                        startaddr = i[0]                                
                        break
            startaddr = i[0]                            
            stopaddr=startaddr + 30
            if argcnt > 1:
               v=int(arglist[1])
               for i in LineAddrList:
                  if i[1] >= v:
                     if len(i) > 1:
                        if i[2] == ActiveFile:
                           stopaddr = i[0]
                           break
         if stopaddr < startaddr:
            stopaddr = startaddr + abs(stopaddr)
         print("Dissasembly from src lines %s to %s" %(startaddr,stopaddr))
         DissAsm(startaddr,stopaddr - startaddr,CPU)
         continue
      if cmdword == "hex":
         if argcnt > 0:
            if argcnt == 1:
               startv=int(arglist[0])
               stopv=startv + 16
            else:
               startv=int(arglist[0])
               stopv=int(arglist[1]) + 1
               if stopv < startv:
                  stopv = startv + stopv + 1
            hexdump(startv,stopv,CPU)
         else:
            print("ERR: Need to specify what to print")
            continue
      if cmdword == "n":
         stepcnt = 1
         if argcnt > 0:
            stepcnt = arglist[0]
         for i in range(stepcnt):
            GlobalOptCnt += 1
            CPU.evalpc()
            DissAsm(CPU.pc, 1, CPU)
            if CPU.pc in breakpoints or CPU.pc in tempbreakpoints:
               print("Break Point %04x" % CPU.pc)
               if CPU.pc in tempbreakpoints:
                   tempbreakpoints.remove(CPU.pc)
               break
         continue
      if cmdword == "s":
          TestFlag=False
          for ii in SymToValMap:
              if CPU.memspace[CPU.pc] == ii[0]:
                  TestFlag = True
          if TestFlag:
              CurInstSize=SymToValMap[CPU.memspace[CPU.pc]][2]
              tempbreakpoints.append(CPU.pc + CurInstSize)
              print("Setting Temporary Break Point at %04x" % (CPU.pc + CurInstSize))
              cmdword = "c" # This only works because cmdword == "c" is bellow this 'if block'
          else:
              print("PC Not resting on valid Opt Code. Can not single step.")
      if cmdword == "c":
         DissAsm(CPU.pc, 1, CPU)
         AtLeastOne = 1
         while CPU.pc <= 0xffff:
            if (CPU.pc in breakpoints or CPU.pc in tempbreakpoints) and AtLeastOne != 1:
               print("Break Point %04x" % CPU.pc)
               DissAsm(CPU.pc, 1, CPU)
               break
            AtLeastOne = 0
            GlobalOptCnt += 1
            CPU.evalpc()
      if cmdword == "r":
          if argcnt < 1:
              CPU.pc = 0
              CPU.mb[0xff] = 0
              print("PC set to 0")
          else:
              CPU.pc = arglist[0]
              print("PC set to %04x" % arglist[0])
          CPU.flags = 0
          CPU.mb[0xff] = 0
          continue
      if cmdword == "g":
         if argcnt < 1:
            print("Need to provide an address to go to.")
            cmdword="Null"
            continue
         CPU.pc = arglist[0]
         print("PC set to %04x" % arglist[0])
         continue
      if cmdword == "tb":
          if argcnt < 1:
            cmdword="b"
          else:
            for ii in arglist:
                tempbreakpoints.append(ii)
            continue
      if cmdword == "b":
         if argcnt < 1:
            if len(breakpoints) == 0:
               print("No break points set")
            else:
               print("Break Points:")
               for ii in breakpoints:
                  print("%04x" % ii)
            if len(tempbreakpoints) != 0:
                for ii in tempbreakpoints:
                    print("Temp Break:%04x" % ii)
         else:
            for ii in arglist:
               breakpoints.append(ii)
         continue
          
      if cmdword == "cb":
         print("Clearing Breakpoints")
         breakpoints=[]
         continue
      if cmdword == "w":
         if argcnt < 1:
            print(watchwords)
         else:
            for ii in arglist:
               watchwords.append(Str2Word(ii))
      if cmdword == "q":
         print("End Debugging.")
         fd = sys.stdin.fileno()
         new = termios.tcgetattr(fd)
         new[3] = new[3] | termios.ECHO          # lflags
         try:
             termios.tcsetattr(fd, termios.TCSADRAIN, new)
         except:
             print("TTY Error: On No Echo")
         sys.exit(0)
      if cmdword == "h":
         print("Debug Mode Commands")
         print("d - DissAsm $1 $2           ps - Print HW Stacl")
         print("p - print values $1         n  - Do one step")
         print("c - continue [ $1 steps ]   r  - reset PC set to 0")
         print("q - quit debugger           h  - this test")
         print("b - break points            cb - clear breakpoints")
         print("hex-Print hexdump $1[-$2]   l  - DissAsm based on src code lines")
         print("w - watch $1                m  - modify address starting wiht $1")
      continue


def main():
    global Debug, CPU, GlobeLabels
    
    DEFMEMSIZE = 0x10000
    Remote = False
    Debug = False
    CPU = microcpu(0, DEFMEMSIZE)


    CPUCNT = 0
    ListOut = False
    breakafter = []
    CPU.pc = 0
    watchwords = []
    watchbytes = []
    skipone = False
    prpcmd = 0
    files = []
    OptCodeFlag = False
    BinaryOutFlag = False
    UseDebugger = False
    
    histfile = os.path.join(os.path.expanduser("~"), ".cpu_history")
    try:
       readline.read_history_file(histfile)
       # default history len is -1 (infinite), which may grow unruly
       readline.set_history_length(1000)
    except FileNotFoundError:
       pass

    atexit.register(readline.write_history_file, histfile)
    for i, arg in enumerate(sys.argv[1:]):
        if skipone:
            skipone = False
            if prpcmd == 1:
                watchwords.append(Str2Word(arg))
                print("New Watchwords %s" % (watchwords))
            if prpcmd == 2:
                breakafter.append(Str2Word(arg))
        else:
            if arg == "-d":
                Debug = not(Debug)
            elif arg == "-l":
                ListOut = True
            elif arg == "-g":
                UseDebugger = True
            elif arg == "-c":
                OptCodeFlag = True
                print("Optcode flag set")
            elif arg == "-O":
                BinaryOutFlag = True
            elif arg == "-w":
                skipone = True
                prpcmd = 1
            elif arg == "-b":
                skipone = True
                prpcmd = 2
            elif arg == "-r":
                Remote = not(Remote)
            elif arg == "-h":
                print("-d Debug Assembly and Run\n-l List Src\n-g Run interactive debugger\n-c Hex Dump of Assembly\n-O Binary Dump of Assembly\n-w Add Watch Address to debug listing\n-b Set Breakpoint to debugger\n-r Enable Remote PDB\n-h help, this listing\n")
            elif arg[0] >= "0" and arg[0] <= "9":
                breakafter+=(arg)
            else:
                files.append(arg)
#    Entry = 0
    maxusedmem = 0
    print("# Assembly Start")
    for curfile in files:
        maxusedmem = loadfile(curfile, maxusedmem, CPU, GLOBALFLAG,0)
    GlobalOptCnt = 0            
    if len(files) == 0:
        # if no files given then drop to debugger for machine lang tests.
        UseDebugger = True        
    if Remote:
        print("RDB running on port 4444, use nc localhost 4444")
        rpdb.set_trace()
    if OptCodeFlag:
        newfile = files[0][:-2]+".o"
        f = open(newfile, "w")
        f.write("# BIN(%s,%s,%s\n. 0\n"%(files,CPU.pc,len(CPU.memspace)))
        toplimit = len(CPU.memspace)
        for i in range(len(CPU.memspace)-1,1,-1):
            if CPU.memspace[i] !=0:
                break
            toplimit -= 1
        i = 0
        zerocount=0
        while ( i < toplimit):
            if (CPU.memspace[i] == 0):
                zerostart=i
                while (CPU.memspace[i] == 0 and i < toplimit):
                    zerocount += 1
                    i += 1
                if zerocount < 10:
                 # If zero count is < 10 then just print it out
                    for j in range(0,zerocount):
                        f.write("b0x%01x " % 0)
                        if ( (( j + zerostart + 1) % 16 ) == 0):
                            f.write("# %04x - %04x\n" % ( j + zerostart - 0xf, i))
                    zerocount=0
                    continue
                else:
                    # More than 10 zerros, just set new '.' spot
                    f.write("\n# Skipping zero block size: 0x%04x\n. 0x%04x\n" % (zerocount,i))
                    zerocount=0
                    continue   # We already inc'ed i so skip the common one.
            else:
                # Not a zero, so just write normally
                v = CPU.memspace[i]
                f.write("b0x%02x " % v )
                if ( ((i + 1) % 16) == 0 ):
                    f.write("# %04x - %04x\n" % (i-0xf,i))
            i += 1
        f.write("\n#End Memory:\n")
        
        for gkey in GlobeLabels:
            if gkey in FileLabels:
                f.write("=%s %s\nG %s\n" % ( gkey,FileLabels[gkey],gkey))
        f.write("\n# Set Entry:\n. 0x%04x\n" % (Entry))
    if BinaryOutFlag:
        newfile = files[0][:-2]+".bin"
        f = open(newfile,"wb")
        limiter = len(CPU.memspace)
        for i in range(len(CPU.memspace)-1, 1, -1):
            if CPU.memspace[i] != 0:
                break
            limiter -= 1
        filler = 0x100 - (limiter % 0x100)
        print("Writeing Binary Output from %s with spacer of %s" % (limiter,filler))
        for i in range(0,limiter):
            cval=((CPU.memspace[i]) & 0xff )
            f.write(''.join(chr(cval)).encode('charmap'))
        for i in range(0,filler):
            f.write('\0'.encode('charmap'))
        f.close()
        


    i = 0
    SP = -1
    print("# Assembly Done.")
    RunMode = True
    CPU.pc = Entry
    if Debug:
        print("Start of Run: Debug: %s: Watch: %s" % (Debug,watchwords))
    if ListOut:
        print("-------0---%04x------" % (maxusedmem))
        DissAsm(0,maxusedmem,CPU)
    elif UseDebugger:
        debugger(FileLabels)
    else:
        while True:
            GlobalOptCnt += 1
            CPU.evalpc()

if __name__ == '__main__':
    main()
    fd = sys.stdin.fileno()
    new = termios.tcgetattr(fd)
    new[3] = new[3] | termios.ECHO          # lflags
    try:
        termios.tcsetattr(fd, termios.TCSADRAIN, new)
    except:
        print("TTY Error: On No Echo")
        
#    cProfile.run('main()')
