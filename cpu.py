#!/usr/bin/python3

from functools import lru_cache
import signal
import termios
import tty
import select
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
import cProfile
import pstats
import io
import time
import bisect
from collections import defaultdict

import sys
import os


# Constants


CastPrintStr=1
CastPrintInt=2
CastPrintIntI=3
CastPrintSignI=4
CastPrintBinI=5
CastPrintChar=6
CastPrintStrI=11
CastPrintCharI=16
CastPrintHexI=17
CastPrintHexII=18
CastSelectDisk=20
CastSelectDiskI=24
CastSeekDisk=21
CastSeekDiskI=25
CastWriteSector=22
CastWriteSectorI=26
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
PollReadSectorI=26
PollReadTapeI=23
PollRewindTape=24
PollReadTime=25
DebugOut=sys.stderr
PrevPC=0

if sys.platform == 'win32':
    import msvcrt

    def get_key():
        if msvcrt.kbhit():
            return msvcrt.getch().decode()
        else:
            return None

elif sys.platform.startswith('linux'):
    import termios
    import fcntl
    import os

    def get_key():
        fd = sys.stdin.fileno()

        # Save the current terminal settings
        old_attr = termios.tcgetattr(fd)
        old_flags = fcntl.fcntl(fd, fcntl.F_GETFL)

        try:
            # Set the terminal to non-blocking mode
            new_attr = termios.tcgetattr(fd)
            new_attr[3] = new_attr[3] & ~termios.ICANON & ~termios.ECHO
            termios.tcsetattr(fd, termios.TCSANOW, new_attr)

            # Set the file descriptor to non-blocking mode
            fcntl.fcntl(fd, fcntl.F_SETFL, old_flags | os.O_NONBLOCK)

            try:
                # Attempt to read a single character
                char = sys.stdin.read(1)
                if len(char) == 0:
                    char='\0'
                return char
            except IOError:
                return None

        finally:
            # Restore the terminal settings and file descriptor flags
            termios.tcsetattr(fd, termios.TCSAFLUSH, old_attr)
            fcntl.fcntl(fd, fcntl.F_SETFL, old_flags)

else:
    raise NotImplementedError("Unsupported platform")

from pstats import SortKey

from pathlib import Path

path_root = os.path.abspath("lib")
sys.path.append(str(path_root))


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
UniqueLineNum = 0
GlobalOptCnt = 0
Entry = 0
DeviceHandle = None
DeviceFile = 0
ActiveFile = ""
EchoFlag = False
UniqueID = 0
SkipBlock = 0
DataSegment=-1      # if DataSegment is -1 then Data and Address overlap.
dataaddress = 0


GLOBALFLAG = 1
LOCALFLAG = 2
watchwords = []
MAXMEMSP = 0xffff
MAXHWSTACK = 0xff - 2
Debug = 0

InDebugger = False
RunMode = False
GPC = 0
LineAddrList = [[0, 0], [0, 0]]

CPUPATH = os.getenv('CPUPATH')
JSONFNAME = "CPU.json"
if CPUPATH is None:
    CPUPATH = ".:../lib/:./lib/"
for testpath in CPUPATH.split(":"):
    if os.path.exists(testpath + "/" + JSONFNAME):
        JSONFNAME = testpath + "/" + JSONFNAME
with open(JSONFNAME, "r") as openfile:
    SymToValMap = json.load(openfile)
OPTLIST = []
OPTSYM = []
OPTDICT = {}
for i in SymToValMap:
    # We are going 'old school' 8 bit ascii encoding only.
    # None of this newfagle 2 or 3 byte character sets. :-)
    OPTLIST.append(i[0])
    OPTSYM.append(i[1].encode('ascii', "ignore").decode('utf-8', 'ignore'))
    OPTDICT[i[1].encode('ascii', "ignore").decode('utf-8', 'ignore')] = [i[0],
                        i[1].encode('ascii', "ignore").decode('utf-8', 'ignore'), i[2]]
    OPTDICT[str(i[0])] = [i[0], i[1].encode(
        'ascii', "ignore").decode('utf-8', 'ignore'), i[2]]


def shandler(signum, frame):
    # This is NOT (as yet) an interupt handler for the CPU, just a way to drop code into the debugger.
    #
    msg = "Ctrl-c"
    print(msg, end="", flush=True)
    debugger(FileLabels,"")


signal.signal(signal.SIGINT, shandler)

def is_string_numeric(s):
    return str(s).isdigit()

def digitsonly(s):
    s=str(s)
    digits = ''.join(c for c in s if c.isdigit())
    return digits if digits else "0"


def create_new_filename(original_filename, new_extension):
    # Get the base filename without the extension
    base_filename = os.path.splitext(original_filename)[0]

    # Create the new filename by adding the new extension
    new_filename = f"{base_filename}.{new_extension}"

    return new_filename


def create_new_unique():
    global UniqueID
    UniqueID = UniqueID+1
    return "_U_%06x_" % UniqueID


def validatestr(instr, typecode):
    # When we call int() function we must first make sure the string passed if value for that
    # numeric base. We support hex, octal, binary and 'decimal'
    alpha = "0123456789xo"
    if typecode == 16:
        alpha = "0123456789abcdefABCDEF-+x"
    elif typecode == 2:
        alpha = "01+-xb"
    elif typecode == 8:
        alpha = "01234567+-xo"
    newstr = ""
    for cc in instr:
        if not (cc in alpha):
            print("String %s is not valid for base %d" % (instr, typecode))
        else:
            newstr += cc
    return (int(newstr, typecode))

LocVarHist = {}

def UpdateVarHistory(varname,value,address):
    global LocVarHist
    if varname in LocVarHist:
        oldvallist=LocVarHist[varname]
        oldvallist.append((value,address))
    else:
        newvallist=[(value,address)]
        LocVarHist[varname]=newvallist

def FindHistoricVal(varname, testaddress):
    global LocVarHist,GlobeLabels

    matchkeys=[]
    bestmatch=0xffff
    if varname in LocVarHist:           # exact match?
        matchkeys.append(LocVarHist[varname])
        for item_name in LocVarHist.keys():
            if item_name.startswith(varname+"_"):
                matchkeys.append(LocVarHist[item_name])
    if len(matchkeys) == 0:
        print("Error: %s not recognized." % varname)
        return 0
    # Flatten the matches into one list
    flatten = [ item for sublist in matchkeys for item in sublist]
    sortedlist = sorted(flatten, key=lambda x: x[1], reverse=True)
    for item in sortedlist:        # For local variables, we expect them to be defined before they are used. Not always true.
        if int(item[1]) <= testaddress:
            return int(item[0])
    if len(item) > 0:     # This is for when item is defined in later memory, likely the main file.
        return int(item[0])
    return testaddress

def FindLabelMatch(varname):
    global FileLabels
    varname=str(varname)
    if varname in FileLabels:
        return FileLabels[varname]

    potential_matches = [ key for key in FileLabels.keys() if key.startswith(varname + "_")]
    if len(potential_matches) == 1:
        return FileLabels[potential_matches[0]]
    if len(potential_matches) == 1:
        return FileLabels[potential_matches[0]]
    if len(potential_matches) > 1:
        maxkeywidth=max(len(match) for match in potential_matches)
        maxvaluewidth=max(len(f"{int(FileLabels[match]):04x}") for match in potential_matches)
        table = f"Multiple matches found for '{varname}:\n"
        table += f"|{'Name':<{maxkeywidth}}|{'Value':<{maxvaluewidth}}|\n"
        table += f"|{'-'*maxkeywidth}|{'-'*maxvaluewidth}|\n"
        for match in potential_matches:
            value = f"{int(FileLabels[match]):04x}"
            table += f"|{match:<{maxkeywidth}}|{value:<{maxvaluewidth}}|\n"
        print(table)
    return None

def Sort_And_Combine_Labels(inboundtext):

    if isinstance(inboundtext, str):
        words = inboundtext.split()
    else:
        print("inbound text is not string:", inboundtext)
        return inboundtext


    processed_words = set()

    for word in words:
        if not word.startswith('__'):
            head_word = re.split('__', word)[0]
            processed_words.add(head_word)
    words = sorted(processed_words)
    groups = {
        "M": [],
        "other":[],
        }
    for word in words:
        if word.startswith("M."):
            groups["M"].append(word)
        else:
            groups["other"].append(word)
    for group in groups.values():
        group = sorted(set(group))
        group = list(set(group[:3]))
    groups["M"]=sorted(set(groups["M"]))
    groups["other"]=sorted(set(groups["other"]))
    return " ".join(groups["other"]+groups["M"])

class InputFileData:
    def __init__(self):
        self.file_data={}  # map filenams to linenumber and memory
        self.address_map = {} # map address to filenames, line numbers)
        self.sorted_addresses = []

    def add_entry(self, filename, line_number, memory_address):
        if filename not in self.file_data:
            self.file_data[filename] = {}
        if line_number not in self.file_data[filename]:
            self.file_data[filename][line_number] = []
        self.file_data[filename][line_number].append(memory_address)
        self.address_map[memory_address] = (filename, line_number)
        bisect.insort(self.sorted_addresses, memory_address)

    def get_line_info(self, memory_address):
        if memory_address in self.address_map:
            return self.address_map[memory_address]

        pos=bisect.bisect_right(self.sorted_addresses, memory_address)
        if pos==0:
            return None
        nearest_lower_address = self.sorted_addresses[pos-1]
        return self.address_map[nearest_lower_address]

    def get_nearest_address(self, filename, line_number):
        if filename not in self.file_data:
            if len(self.file_data) > 1:
                print("Multiple Matches for (%04x) : Re-enter with one of the following. " % line_number)
                for afile in self.file_data:
                    Result1 = self.get_nearest_address(afile, line_number)
                    if Result1 != None:
                        print("%s:%d:%04x" % (afile, line_number, Result1))
                return None
            filename=self.file_data[0]
        lines=sorted(self.file_data[filename].keys())
        closest_line = None
        for ln in lines:
            if ln >= line_number:
                closest_line = ln
                break
        if closest_line is None:
            return None
        return self.file_data[filename][closest_line][0]

FileLineData = InputFileData()



# I must admit it, I am not a 'natural' OO programmer.
# I learned to code back in the 'waterfall' days and to me using 'class' here
# just feels like fluff around good and true solid 'functions'
# I'd appologize for bad code, except I really don't want to, as I consider OO a
# handicap, and not a feature.
#
class microcpu:
    cpu_id_iter = itertools.count()
    DiskPtr = -1
    OPTDICTFUNC={}

    def switcher(self, optcall, argument):
        return getattr(self, "opt" + OPTDICT[str(optcall)][1], lambda: default)(argument)


    def __init__(self, origin, memsize):
        self.pc = origin
        self.flags = 0    # B0 = ZF, B1=NF, B2=CF, B3=OF
        self.memspace = np.zeros(memsize, dtype=np.uint8,)
        self.identity = next(self.cpu_id_iter)
        self.mb = np.zeros(256, dtype=np.uint8)
        self.netqueue = []
        self.netapps = []
        self.hwtimer = 0
        self.mb[0xff] = 0
        self.simtime = False
        self.clocksec = 1000
        self.Last_Filename_used = None


    def insertbyte(self, location, value):
        if location >= 65536:
            CPU.raiseerror("000 Address OverFlow %05x" % location)
        self.memspace[location] = value

    def FindWhatLine(self, address):
        global FileLineData

        tresult = FileLineData.get_line_info(address)
        if tresult == None or len(tresult)< 2 :
            print("No good line match found for address %04x" % address)
            return " no-file "
        return "%s:%d" % tresult

    def FindAddressLine(self, line_info):
        global FileLineData

        if (":" in line_info):
            parts=line_info.split(":")
            if len(parts[0]) == 0:
                self.Last_Filename_used = None
                OutFile=None
            else:
                self.Last_Filename_used = parts[0]
                OutFile=self.Last_Filename_used
            OutLine=int(digitsonly(parts[1]))
        else:
            OutFile=self.Last_Filename_used
            OutLine = int(digitsonly(line_info))
        return FileLineData.get_nearest_address(OutFile, OutLine)

    def raiseerror(self, idcode):
        global GPC, RunMode, FileLabels
        fd = sys.stdin.fileno()
        new = termios.tcgetattr(fd)
        new[3] = new[3] | termios.ECHO          # lflags
        print("CPU State: ",file=DebugOut)
        i=CPU.pc
        if ( i+1 < 0xffff ):
           optcode = StoreMem[i]
           P1 = CPU.getwordat(i+1)
           if (P1 > 0xfffe):
               OUTLINE="Invalide number at address %04x[%06x] " % (i,P1)
               P1=P1 & 0xfffe
           PI = CPU.getwordat(P1)
           PII = CPU.getwordat(PI)
           ZF = 1 if CPU.flags & 1 else 0
           NF = 1 if CPU.flags & 2 else 0
           CF = 1 if CPU.flags & 4 else 0
           OF = 1 if CPU.flags & 8 else 0
           OUTLINE = "%04x:%8s P1:%04x [I]:%04x [II]:%04x Z%1d N%1d C%1d O%1d" % \
                (i, OPTSYM[optcode], P1, PI, PII,
                 ZF, NF, CF, OF)
           pline=CPU.FindWhatLine(i)
           if pline != None:
               print(f"Line: {pline}")
        else:
            OUTLINE="Invalid PC ( %06x ) " % i
        print(OUTLINE, file=DebugOut)
        if (self.mb[0xff]-1 > 0):
            for i in range(self.mb[0xff]-1):
                val = self.mb[i*2]+(0xff*self.mb[i*2+1])
                print(" %04x" % (val),file=DebugOut,end="")
            print(" ",file=DebugOut)
            sys.stdout.flush()
        else:
            print("Stack Empty",file=DebugOut)
            print("Stack Empty at %04x" % i)
        if self.mb[0xff] > 0 and self.mb[0xff] < 255:
            print("Invalid range for stack info: SP:%03x" % ( self.mb[0xff]-1))
            self.mb[0xff]=0xf0
        try:
            termios.tcsetattr(fd, termios.TCSADRAIN, new)
        except:
            print("TTY Error: On No Echo", file=DebugOut)

        print("Error Number: %s \n\tat PC:0x%04x " % (idcode, int(CPU.pc)),file=DebugOut)
        if is_string_numeric(idcode[0:3]):
            valid = int(idcode[0:3])
        else:
            valid=-1
        if RunMode:
            print("At OpCount: %s,%s " % (self.FindWhatLine(GPC), GPC),file=DebugOut)
        print(new[3])
        if not InDebugger:
            sys.exit(valid)
        else:
            print("At OpCount: %s,%s " % (self.FindWhatLine(GPC), GPC),file=DebugOut)
            debugger(FileLabels,"")

    def lowbyte(self, invalue):
        invalue = int(invalue)
        return invalue & 0xff

    def highbyte(self, invalue):
        invalue = int(invalue)
        return ((invalue & 0xff00) >> 8)

    def fetchAcum(self, address):
        # Returns value at the top of stack.
        # address zero is alwasy top of stack, other values will attempt to fetch from that stack depth.
        CTPS = self.mb[0xff]
        if address >= MAXHWSTACK:
            self.raiseerror(
                "001 Invalide Buffer Refrence %d. fetchAcum" % address)
        if address == 0 and CTPS > 0:
            address = (CTPS-1)*2
        elif address != 0 and address <= CTPS:
            address = CTPS * 2 - (address+1) * 2
        else:
            print("Stack Empty.",file=DebugOut)
            CPU.raiseerror("Stack Empty Fetch %04x " % address)
            return 0
        return self.mb[address]+(self.mb[address+1] << 8)

    def StoreAcum(self, address, value):
        # Saves at top of stack the Acum value. Does not change stack.
        # Address zero is always top, a given index >0 will try to save value at that stack depth
        CTPS = self.mb[0xff]
        if address > MAXHWSTACK:
            self.raiseerror(
                "002 Invalide Buffer Refrence %d, StoreAcum" % address)
        if address == 0:
            address = (CTPS-1)*2
        else:
            address = (CTPS * 2) - (address*2)
        self.mb[address] = self.lowbyte(value)
        self.mb[address+1] = self.highbyte(value)

    def getwordat(self, address):
        a=0
        if address == MAXMEMSP:
            return 0
        if address >= MAXMEMSP:
            self.raiseerror("003 Invalid Address: %d, getwordat" % (address))
            return 0
        a = self.memspace[address] + (self.memspace[address+1] << 8)
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
            self.raiseerror("005 MB Stack overflow, optpush")
        sp *= 2
        self.mb[sp] = self.lowbyte(invalue)
        self.mb[sp + 1] = self.highbyte(invalue)
        self.mb[0xff] += 1

    def optDUP(self, address):
        sp = self.mb[0xff]
        if sp > (0xff/2 - 2):
            self.raiseerror("006 MB Stack overflow, optpush")
        sp *= 2
        self.mb[sp] = self.lowbyte(self.mb[sp - 2])
        self.mb[sp + 1] = self.lowbyte(self.mb[sp - 1])
        self.mb[0xff] += 1

    def optPUSHI(self, address):
        sp = self.mb[0xff]
        if sp > (0xff/2 - 2):
            self.raiseerror("007 MB Stack overflow, optPUSHI")
        sp *= 2
        if (address+1 > MAXMEMSP):
            self.raiseerror("008 Invalid Address: %d, optPUSHI" % (address))
        self.mb[sp] = self.memspace[address]
        address += 1
        if (address <= MAXMEMSP):
            self.mb[sp+1] = self.memspace[address]
        self.mb[0xff] += 1

    def optPUSHII(self, address):
        sp = self.mb[0xff]
        if sp > (0xff/2 - 2):
            self.raiseerror("009 MB Stack overflow, optPUSHII")
        sp *= 2
        newaddress = self.getwordat(address)
        if (newaddress+1 > MAXMEMSP):
            self.raiseerror(
                "010 Invalid Indirect Address: %d, optPUSHII" % (newaddress))
        self.mb[sp] = self.memspace[newaddress]
        newaddress += 1
        if (newaddress <= MAXMEMSP):
            self.mb[sp+1] = self.memspace[newaddress]
        self.mb[0xff] += 1

    def optPUSHS(self, address):
        # Since we are storing the result in the same stack spot as the address was, no need for overflow checks
        newaddress = self.fetchAcum(0)
        self.StoreAcum(0, self.getwordat(newaddress))

    def optPOPNULL(self, address):
        if (address > MAXMEMSP):
            self.raiseerror("011 Invalid Address: %d, optPOPI" % (address))
        sp = self.mb[0xff]
        if sp < 1:
            self.raiseerror("012 Stack underflow, optPOPI")
        self.mb[0xff] -= 1

    def optSWP(self, address):
        # We're not changing the sp level, so no need for tests.
        sp = self.mb[0xff]
        sp *= 2
        # Pythonic swap
        self.mb[sp - 2], self.mb[sp - 4] = self.mb[sp - 4], self.mb[sp - 2]
        self.mb[sp - 1], self.mb[sp - 3] = self.mb[sp - 3], self.mb[sp - 1]

    def optPOPI(self, address):
        if (address > MAXMEMSP):
            self.raiseerror("013 Invalid Address: %d, optPOPI" % (address))
        sp = self.mb[0xff]
        if sp < 1:
            self.raiseerror("014 Stack underflow, optPOPI")
        sp -= 1
        sp *= 2
        if sp > (0xff/2 - 2):
            self.raiseerror("015 MB Stack overflow, optPOPI")
        self.insertbyte(address, self.mb[sp])
        if (address+1 <= MAXMEMSP):
            self.insertbyte(address+1, self.mb[sp+1])
        self.mb[0xff] -= 1

    def optPOPII(self, firstaddress):
        address = self.getwordat(firstaddress)
        if (address+1 > MAXMEMSP):
            self.raiseerror(
                "016 Invalid Indirect Address: %d, optPOPII" % (address))
        sp = self.mb[0xff]
        if sp < 1:
            self.raiseerror("017 Stack underflow, optPOPII")
        self.optPOPI(address)

    def optPOPS(self, notused):
        if self.mb[0xff] < 2:
            self.raiseerror("018 Stack underflow, OptPOPS")
        newaddress = self.fetchAcum(0)
        A1 = self.fetchAcum(1)
        self.putwordat(newaddress, A1)
        self.mb[0xff] -= 2

    def SetFlags(self, A1, WasSubt):
        global ZF,NF,CF,OF
        # The Basic SetFlags only works for fixed numbers so we'll only look at
        # Zero, Negative and Carry.
        # Overflow requires us to know if we are adding or subtracting so we'll do
        # That inside the add/sub/cmp operations
        ZF = 0
        NF = 0
        OF = 0
        B2 = abs(A1) & 0xffff
        ZF = 1 if (B2 == 0) else 0
        NF = 1 if (((A1 & 0xffff) & 0x8000) != 0) else 0
        self.flags = 0
        self.flags = (ZF+(NF << 1))
    def OverCarryTest(self, a, b, c, IsSubStraction):
        global OF,CF
        OF=0
        CF=0
# Check for overflow in signed subtraction
        if (IsSubStraction != 0):
            if (((a & 0x8000) != 0 and (b & 0x8000) == 0 and (c & 0x8000) == 0)
                or ((a & 0x8000) == 0 and (b & 0x8000) != 0 and (c & 0x8000) != 0)):
                OF = 1
        else:
            if (((a & 0x8000) != 0 and (b & 0x8000) != 0 and (c & 0x8000) == 0) or
                ((a & 0x8000) == 0 and (b & 0x8000) == 0 and (c & 0x8000) != 0)):
                OF = 1
        if ( c & 0xffff0000 ) > 0:
            CF=1
        self.flags=self.flags | (CF << 2 | OF << 3)



    def optCMP(self, asvalue):
        R1 = asvalue
        R2 = self.fetchAcum(0)
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R2, R1, A1, 1)

    def optCMPS(self, address):
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R2, R1, A1, 1)

    def optCMPI(self, address):
        R1 = self.getwordat(address)
        R2 = self.fetchAcum(0)
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R2, R1, A1, 1)

    def optCMPII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror(
                "019 Invalid Address for CMP: %d, optCMPII" % (address))
        newaddress = self.getwordat(address)
        self.optCMPI(newaddress)

    def optADD(self, invalue):
        R1 = self.fetchAcum(0)
        R2 = invalue
        A1 = R1 + R2
        self.SetFlags(A1,0)
        self.OverCarryTest(R1, R2, A1, 0)
        self.StoreAcum(0, A1)

    def optADDS(self, invalue):
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R1 + R2
        self.SetFlags(A1,0)
        self.OverCarryTest(R1, R2, A1, 0)
        self.mb[0xff] -= 1
        self.StoreAcum(0, A1)

    def optADDI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("020 Invalid Address: %d, optADDI" % (address))
        newaddress = self.getwordat(address)
        self.optADD(newaddress)

    def optADDII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("021 Invalid Address: %d, optANDII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("022 Invalid Address %d, optANDII" % (address))
        self.optADDI(newaddress)

    def optSUB(self, invalue):
        R2 = self.fetchAcum(0)
        R1 = invalue
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R2, R1, A1, 1)
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optSUBS(self, invalue):
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R1, R2, A1, 1)
        self.mb[0xff] -= 1
        self.StoreAcum(0, A1)

    def optSUBI(self, address):
        R1 = self.getwordat(address)
        R2 = self.fetchAcum(0)
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R1, R2, A1, 1)
        self.StoreAcum(0, A1 & 0xffff )

    def optSUBII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("023 Invalid Address: %d, optSUBII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("024 Invalid Address %d, optSUBII" % (address))
        self.optSUBI(newaddress)

    def optOR(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = ivalue
        A1 = R1 | R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optORS(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R1 | R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.mb[0xff] -= 1
        self.StoreAcum(1, A1)

    def optORI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("025 Invalid Address: %d, optORI" % (address))
        newaddress = self.getwordat(address)
        self.optOR(newaddress)

    def optORII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("026 Invalid Address: %d, optORII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("027 Invalid Address %d, optORII" % (address))
        self.optORI(newaddress)

    def optAND(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = ivalue
        A1 = R1 & R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optANDS(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R1 & R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.mb[0xff] -= 1
        self.StoreAcum(0, A1)

    def optANDI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("028 Invalid Address: %d, optANDI" % (address))
        newaddress = self.getwordat(address)
        self.optAND(newaddress)

    def optANDII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("029 Invalid Address: %d, optANDII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("030 Invalid Address %d, optANDII" % (address))
        self.optANDI(newaddress)
    def optXOR(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = ivalue
        A1 = R1 ^ R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optXORS(self, ivalue):
        R1 = self.fetchAcum(0)
        R2 = self.fetchAcum(1)
        A1 = R1 ^ R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.mb[0xff] -= 1
        self.StoreAcum(1, A1)

    def optXORI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("025 Invalid Address: %d, optORI" % (address))
        newaddress = self.getwordat(address)
        self.optXOR(newaddress)

    def optXORII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("026 Invalid Address: %d, optORII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("027 Invalid Address %d, optORII" % (address))
        self.optXORI(newaddress)

    def optJMPZ(self, address):
        if address >= MAXMEMSP:
            self.raiseerror(
                "031 Invalid Address for Jump: %d, optJMPZ" % (address))
        if ((self.flags & 0x1) != 0):
            self.pc = address

    def optJMPN(self, address):
        if address >= MAXMEMSP:
            self.raiseerror(
                "032 Invalid Address for Jump: %d, optJMPN" % (address))
        if ((self.flags & 0x2) != 0):
            self.pc = address

    def optJMPC(self, address):
        if address >= MAXMEMSP:
            self.raiseerror(
                "033 Invalid Address for Jump: %d, optJMPC" % (address))
        if ((self.flags & 0x4) != 0):
            self.pc = address

    def optJMPO(self, address):
        if address >= MAXMEMSP:
            self.raiseerror(
                "034 Invalid Address for Jump: %d, optJMPO" % (address))
        if ((self.flags & 0x8) != 0):
            self.pc = address

    def optJMP(self, address):
        if address >= MAXMEMSP:
            self.raiseerror(
                "035 Invalid Address for Jump: %d, optJMP" % (address))
        self.pc = address

    def optJMPI(self, address):
        newaddress = self.getwordat(address)
        self.pc = newaddress

    def optJMPS(self,address):
        newaddress = self.fetchAcum(0)
        self.mb[0xff] -= 1
        self.pc = newaddress

    def optCAST(self, address):
        global Debug, DeviceHandle, DeviceFile, PrevPC
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
        # Disk Hardware Codes: A very primitive 'random IO Block' device, no filesystem, just addresses of 512 byte blocks.
        # 20 is selects Random Access storage device (disk) address is the ID of the device (disk 0 , disk 1 etc)
        # 21 is 'seek' identifies the record in the current disk.
        # 22 is 'write block' address points to a block of memory (512 bytes) that will be written to disk
        # 23 is sync, closes the device until the next write.
        # if 32 it will print the 32 bit integer value stored AT location of address
        # if 33 if will print the 32 bit integer value stored At location on Stack

        if address >= (MAXMEMSP-11):
            self.raiseerror(
                "036 Insufficent space for Message Address at %d, optCAST" % (address))
        cmd = self.fetchAcum(0)
        if cmd == 0:
            if self.mb[0xff] > 0:
                print("Stack: \n".join('%02x ' %
                      item for item in self.mb[0:self.mb[0xff]]))
            DissAsm(self.pc, 3, self)
        if cmd == CastPrintStr:
            i = address
            while self.memspace[i] != 0 and i < MAXMEMSP:
                c = self.memspace[i]
                if c == 0:
                    print("Odd C is zero")
                if (c < 32 or c > 127) and (c != 10 and c != 7 and c != 27 and c != 30):
                    sys.stdout.write("\%02x" % c)
                else:
                    sys.stdout.write(chr(c))
                i += 1
        if cmd == CastPrintInt:
            sys.stdout.write("%d" % (address & 0xffff) )
        if cmd == CastPrintIntI:
            v = self.memspace[address]+(self.memspace[address+1] << 8)
            sys.stdout.write("%d" % (v & 0xffff))
        if cmd == CastPrintSignI:
            v = self.memspace[address]+(self.memspace[address+1] << 8)
            v = v & 0xffff
            if ( v & 0x8000):
                v = -((v - 1) ^ 0xffff)
            sys.stdout.write("%d" % v)
        if cmd == CastPrintBinI:
            v = self.memspace[address]+(self.memspace[address+1] << 8)
            sys.stdout.write("%s" % format(v, "016b"))
        if cmd == CastPrintChar:
            v = self.memspace[address]
            if (v < 31):
                print("%c" % v)
            else:
                sys.stdout.write(chr(v))
        if cmd == CastPrintStrI:
            i = self.getwordat(address)
            while self.memspace[i] != 0 and i < MAXMEMSP:
                c = self.memspace[i]
                if c == 0:
                    print("0x0")
                if (c < 32 or c > 127) and (c != 10 and c != 7 and c != 30):
                    sys.stdout.write("\%02x" % c)
                else:
                    sys.stdout.write(chr(c))
                i += 1
#            sys.stdout.write("%d" % address)
        if cmd == 12:
            sys.stdout.write("%d" % self.getwordat(address))
        if cmd == CastPrintCharI:
            v = self.memspace[address]+(self.memspace[address+1] << 8)
            sys.stdout.write("%c" % chr(v))
        if cmd == CastPrintHexI:
            v = self.getwordat(address)
            sys.stdout.write("%04x" % (v))
        if cmd == CastPrintHexII:
            v = self.getwordat(self.getwordat(address))
            sys.stdout.write("%04x" % v)
        if cmd == CastSelectDisk:            # 20
            if DeviceHandle == None:
                DeviceHandle = "DISK%02d.disk" % address
            try:
                DeviceFile = open(DeviceHandle, "r+b")
                self.DiskPtr = 0
                DeviceFile.seek(0,0)
            except IOError:
                self.raiseerror(
                    "037 Error tying to open Random Device: %s" % DeviceHandle)
        if cmd == CastSelectDiskI:
            v = self.getwordat(address)
            if DeviceHandle == None:
                DeviceHandle = "DISK%02d.disk" % v
            try:
#                print("Device Handle: %s set:" % DeviceHandle)
                DeviceFile = open(DeviceHandle, "r+b")
                self.DiskPtr = 0
                DeviceFile.seek(0,0)
            except IOError:
                self.raiseerror(
                    "037 Error tying to open Random Device: %s" % DeviceHandle)
        if cmd == CastSeekDisk:
            if DeviceHandle == None:
                self.raiseerror("038 Attempted to Seek without selecting Disk")
            self.DiskPtr = address*0x200
            DeviceFile.seek(self.DiskPtr, 0)
        if cmd == CastSeekDiskI:
            v = self.getwordat(address)
#            print("Debug: Seeking Disk Value: %04x" % v)
            if DeviceHandle == None:
                self.raiseerror("038 Attempted to Seek without selecting Disk")
            self.DiskPtr = v*0x200
            DeviceFile.seek(self.DiskPtr, 0)
        if cmd == CastWriteSector:
            if DeviceHandle == None:
                self.raiseerror("038 Attempted to write without selecting Disk")
            v = address
            if v < MAXMEMSP-0x1ff:
                block = self.memspace[v:v+512]
                DeviceFile.seek(self.DiskPtr)
                DeviceFile.write(bytes(block))
                self.DiskPtr =+ 0x200
                DeviceFile.flush()
            else:
                self.raiseerror(
                    "038 Attempted to write block larger than memory to storage")
        if cmd == CastWriteSectorI:
            v = self.getwordat(address)
            if DeviceHandle == None:
                self.raiseerror("038 Attempted to write without selecting Disk")
            if v < MAXMEMSP-0x1ff:
                block = self.memspace[v:v+512]
                DeviceFile.seek(self.DiskPtr)
                DeviceFile.write(bytes(block))
                self.DiskPtr =+ 0x200
                DeviceFile.flush()
            else:
                self.raiseerror(
                    "038 Attempted to write block larger than memory to storage")
        if cmd == CastSyncDisk:
            if DeviceHandle != None:
                DeviceFile.close()
                DeviceFile = open(DeviceHandle, "r+b")
        if cmd == CastPrint32I:
            iaddr = address
            v = self.getwordat(iaddr) + (self.getwordat(iaddr + 2) << 16)
            if (v & (1 << 31) != 0):
                v = v - (1 << 32)
            sys.stdout.write("%s" % v)
        if cmd == CastPrint32S:
            iaddr = self.fetchAcum(1)
            v = self.getwordat(iaddr) + (self.getwordat(iaddr + 2) << 16)
            sys.stdout.write("%d" % v)
        if cmd == CastEnd:
            print("\nEND of Run:(%d Opts)" % GlobalOptCnt)
            sys.exit(address)
        if cmd == CastDebugToggle:
            Debug = 0 if Debug else 1
        if cmd == CastStackDump:
            print(" %04x:Stack:(%d):%s [" %
                             (PrevPC,self.mb[0xff]-1,CPU.FindWhatLine(PrevPC)), file=DebugOut,end="")
            for i in range(self.mb[0xff]-1):
                val = self.mb[i*2]+((self.mb[i*2+1])<<8)
                print(" %04x" % (val),file=DebugOut,end="")
            print(" ]",file=DebugOut)
        if cmd == CastTapeWriteI:
            if DeviceHandle != None:
                v=address
                if v < MAXMEMSP-0x1ff:
                    block=self.memspace[v:v+512]
                    DeviceFile.write(bytes(block))
                    DeviceFile.flust()
                else:
                    self.raiseerror(
                        "039 Attempt to write from source memory past availabel memory")

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
        # 19        Read Time clock
        # 22        Requires Disk Device already initilized. Reads 512 Byte block from [address]
        # 25        Reads system time as seconds since 1970
        #
        if address >= (MAXMEMSP-11):
            self.raiseerror(
                "040 Insufficent space for Message Address at %d, optPOLL" % (address))
        cmd = self.fetchAcum(0)
        if cmd == PollReadIntI:
            sys.stdout.flush()
            rawdata = sys.stdin.readline(256)
            justnum = "0"
            for c in rawdata:
                if (c >= '0' and c <= '9') or (c == '-'):
                    justnum = justnum + c
            if int(justnum) < 65535 and int(justnum) >= -32767:
                CPU.putwordat(address, int(justnum))
            else:
                print("Error: %s is not valid 16 bit number" % justnum,file=DebugOut)
                CPU.putwordat(address, 0)
        if cmd == PollReadStrI:
            sys.stdout.flush()
            rawdata = sys.stdin.readline(256)
            i = address
            for c in rawdata:
                if ord(c) > 31:
                    c = ord(c)
#                    c = ( ord(c) << 8  & 0xff00 )
                    self.putwordat(i, c)
                    i += 1
                    if (i > (MAXMEMSP-11)):
                        self.raiseerror(
                            "041 Insufficent space for Message Address at %d, optPOLL" % (i))
        if cmd == PollReadCharI:
            # Address must be at least 4 bytes for special code strings.
            c = readchar.readkey()
            if not (c):
                c = ""
#            c = keyboard.read_key()
#            c = raw_input("")
#            c = readchar.readkey()

            if len(c) == 1:
                self.putwordat(address, ord(c))
            elif len(c) == 2:
                self.putwordat(address, (ord(c[0])) << 8 + (ord(c[1])))
                self.putwordat(address+2, 0)
            elif len(c) == 3:
                self.putwordat(address, (ord(c[1])) << 8 + (ord(c[1])))
                # This will create a 3 char string null terminated
                self.putwordat(address+2, (ord(c[2])))
        if cmd == PollSetNoEcho:
            fd = sys.stdin.fileno()
            new = termios.tcgetattr(fd)
            new[3] = new[3] & ~termios.ECHO          # lflags
            EchoFlag = True
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, new)
            except:
                print("TTY Error: On No Echo",file=DebugOut)
        if cmd == PollSetEcho:
            fd = sys.stdin.fileno()
            new = termios.tcgetattr(fd)
            new[3] = new[3] | termios.ECHO          # lflags
            EchoFlag = False
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, new)
            except:
                print("TTY Error: On Echo",file=DebugOut)
        if cmd == PollReadCINoWait:
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
        if cmd == PollReadSector:
            if DeviceHandle != None:
                v=address
                print("Disk Read: %04x" % v)
                if v <= MAXMEMSP-0x1ff:
                    DeviceFile.seek(self.DiskPtr,v)
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
                        "042 Attempted to read block with insuffient memory %04x < 0x4x" %(v,MAXMEMSP-0xff))
        if cmd == PollReadSectorI:
            if DeviceHandle != None:
#                v = self.getwordat(address)
                v = self.memspace[address]+(self.memspace[address+1] << 8)
                if v <= MAXMEMSP-0x1ff:
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
                    self.raiseerror("042 Attempted to read block with insuffient memory %04x < 0x4x" %(v,MAXMEMSP-0xff))
        if cmd == PollReadTapeI:
            if DeviceHandle != None:
                v=address
                block=DeviceFile.read(512)
                tidx=v
                if v<= MAXMEMSP-0x1ff:
                    for i in block:
                        self.memspace[tidx] = int(i) & 0xff
                        tidx += 1
                else:
                    self.raiseerror(
                        "043 Attempt to read Tape Block with insufficent memory")
        if cmd == PollRewindTape:
            if DeviceHandle != None:
                DeviceFile.seek(0)

        if cmd == PollReadTime:
            v32=int(time.time())
            v1=v32 & 0xffff
            v2=v32 >> 16
            self.optPUSH(v1)
            self.optPUSH(v2)

    def optRRTC(self, unused):
        # RRTC mean Rotate Right Through Carry
        # Means after rotation current CF becomes high bit, and previous low bit saves to CF
        R1 = self.fetchAcum(0)
        # New Carry Flag from Right most bit
        NCF = (1 if (R1 & 1 != 0) else 0) << 2
        # Pull CF from flags and make it 1 | 0
        OCF = (1 if (self.flags & 0x04 != 0) else 0) << 15
        R1 = R1 >> 1 | OCF
        self.flags = (self.flags & 0xfffb) | NCF
        self.StoreAcum(0, R1)

    def optRLTC(self, unused):
        # RLTC means Rotate Left Through Carry
        # After rotation current CF becomes low bit, and previous high bit saves to CF
        R1 = self.fetchAcum(0)
        # New Carry Flag from Left Most bit
        NCF = (1 if (R1 & 0x08000 != 0) else 0) << 2
        # Pull CF from flags and make 1 | 0
        OCF = (1 if (self.flags & 0x04 != 0) else 0)
        R1 = (R1 << 1) | OCF
        self.flags = (self.flags & 0xfffb) | NCF
        self.StoreAcum(0, R1)

    def optRTR(self, unused):
        # RTR mean rotat Right and set carry CF to equal current lowest bit
        R1 = self.fetchAcum(0)
        NCF = (1 if (R1 & 0x1 != 0) else 0) << 2
        R1 = R1 >> 1
        self.flags = (self.flags & 0xfffb) | NCF
        self.StoreAcum(0, R1)

    def optRTL(self, unused):
        # RTL mean rotat Left and set carry CF to equal current Highest bit
        R1 = self.fetchAcum(0)
        NCF = (1 if (R1 & 0x8000 != 0) else 0) << 2
        R1 = R1 << 1
        self.flags = (self.flags & 0xfffb) | NCF
        self.StoreAcum(0, R1)

    def optINV(self, address):
        R2 = self.fetchAcum(0)
        A1 = ~R2
        self.SetFlags(A1,0)
        self.flags = self.flags & 0x3      # Only care about NF or ZF
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optCOMP2(self, address):
        R2 = self.fetchAcum(0)
        A1 = ~R2 + 1
        self.SetFlags(A1,0)
        self.flags = self.flags & 0x3      # Only care about NF or ZF
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optFCLR(self, address):
        self.flags = 0

    def optFSAV(self, address):
        CPU.optPUSH( self.flags)

    def optFLOD(self, address):
        sp = self.mb[0xff]
        if sp < 1:
            self.raiseerror("044 Stack underflow, OptFLOD")
        sp -= 1
        sp *= 2
        if sp > (0xff/2-2):
            self.raiseerror("045 Stack overflow, optFLOD")
        self.flags = self.mb[sp]
        self.mb[0xff] -= 1

    def evalpc(self):  # main evaluate current instruction at memeory[pc]
        global GPC, GlobalOptCnt, PrevPC
        pc = self.pc
        GPC = pc
        PrevPC=pc
        optcode = self.memspace[pc]
        GlobalOptCnt += 1
        if not (optcode in OPTLIST):
            print(OPTLIST)
            self.raiseerror(
                "046 Optcode %s at File %s, Address( %04x ), is invalid:" % (optcode,self.FindWhatLine(pc),pc))
        if Debug > 0:
            DissAsm(pc, 1, self)
            watchfield = ""
            if watchwords:
                wfcomma = ""
                for wb in watchwords:
                    nv = self.memspace[wb]
                    watchfield = (watchfield + wfcomma + "%04x" %
                                  self.getwordat(nv))
                    wfcomma = ","
                watchfield = "Watch[" + watchfield + "]"
        # In HW this would be when we know if we read 3 bytes or 1
        if (OPTDICT[str(optcode)][2] == 3):
            argument = self.getwordat(pc + 1)
        else:
            argument = 0
        pc += OPTDICT[str(optcode)][2]

        self.pc = pc
        self.switcher(optcode, argument)


def removecomments(inline):
    # Return inline up to to any '#' that is not inside quotes, else return full inline.
    inquote = False
    cptr = 0
    for c in inline:
        if c == '"' and not (inquote):
            inquote = True
        elif c == '"' and inquote:
            inquote = False
        elif c == '#' and not (inquote):
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
        return (qsize, "")
    for c in inline:
        if not (inquote) and c == '"':
            inquote = True
            qsize += 1
        elif inquote and not (inescape) and c == '"':
            inquote = False
            break
        elif not (inescape) and c == '\\':
            inescape = True
        elif inescape:        # We support some but not all the \ codes 'c' does
            if c == 'n':
                outputtext += '\n'         # Newline
            elif c == 't':
                outputtext += '\t'         # Tab
            elif c == 'e':
                outputtext += chr(27)      # ESC
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
    return (qsize if qsize == 0 else qsize + 1, outputtext)

def nextwordplus(ltext):
    # This version of nextword treats "+" and "-" as part of the word. But has to end on " "
    if (len(ltext) == 0 ):
        return ("",0)
    (result,rsize)=nextword(ltext)
    if ( len(ltext) > (rsize-1) ):
        if ltext[rsize-1] != " ":   # We only care about +/- if the previous character was NOT space.
            while ((len(ltext)>rsize) and (ltext[rsize]=="+" or ltext[rsize]=="-")):
                (nresult,nsize)=nextword(ltext[rsize:])
                result+=nresult
                rsize+=nsize
                if len(ltext) < rsize:
                    break
    return (result,rsize)


def nextword(ltext):
    # Nextword skips past any heading whitespace
    # Ends when it find end of line, or more whitespace
    # If it finds "+" or "-" it exits, but backspaced out so not to include them.
    signstart=True
    size = 0
    result = ""
    maxlen=len(ltext)
    if maxlen == 0:
        return ("",0)
    c=ltext[size:size+1]
    while ((c== " " or c == ",") and (size < maxlen)):
        size += 1
        c=ltext[size:size+1]
    if size >= maxlen:   # all while space
        return ("",0)
    if c == '"':
        # Special case for quoted text
            (size, result) = GetQuoted(ltext)
            result = '"'+result+'"'
            return (result,size)
    if c in "+-" and size < maxlen:  #handle case where start character IS sign character
        result += c
        size +=1
        c=ltext[size:size+1]
    while ( not c in " ,+-" ) and size < maxlen:
        result += c
        size += 1
        c = ltext[size:size+1]
    # When we hit '+' or '-' return immeditly, but not if its the first character seen
    if c in "+-":
        return (result,size)
    signstart=False
    # cleanup tailing whitespace
    while c in " ," and size < maxlen:
        c = ltext[size:size+1]
        size += 1
    if size > maxlen:
        return (result,maxlen)
    return (result,size-1)

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
        result = int("".join(char for char in instr if char.isdigit()))
    else:
        if instr[0:2] == "0x":            # Hex
            result = validatestr(instr, 16)
        elif instr[0:2] == "0b":          # Binary
            result = validatestr(instr, 2)
        elif instr[0:2] == "0o":          # Octal
            result = validatestr(instr, 8)
        elif instr[0:1] == '"':           # Quoted text
            result = ord(instr[1:2])
            if (len(instr) > 3):
                result = result + (ord(instr[2:3]) << 8)
        elif (instr[0:1].upper() >= "A" and instr[0:1].upper() <= "Z"):
            if instr in FileLabels:
                result = FileLabels[instr]
            else:
                CPU.raiseerror(
                    "047 Use of fixed value(%s) as label before defined." % instr)
        else:
            valid = True
            for i in instr:
                if (i > '9' or i < '0'):
                    valid = False
                    break
            if valid:
                result = validatestr(instr, 10)
            else:
                result = 0
                CPU.raiseerror(
                    "048 String %s is not a valid decimal value" % instr)
#    result = int("".join(char for char in result if char.isdigit()))
    result = int(result) & 0xffffffff
    return result


def Str2Byte(instr):
    # Just use the Str2Word and keep the lowest byte
    return Str2Word(instr) & 0xff


def DissAsm(start, length, CPU):
    # The DissAsm is not really required for interpitation of the code, but is a usefull tool for debugging
    # The need for the CPU.json file is just used by this module, (and debugger) so a 'speed optimized'
    # version of the code would not need CPU.json at all.
    #
    global watchwords,DebugOut, OPTDICT, InputFileData
    StoreMem = CPU.memspace
    i = start

    endstop=start+length
    P1=0
    PI=0
    PII=0
    while i < endstop:
        OUTLINE = ""
        FoundLabels = ""
        optcode = StoreMem[i]
        if str(optcode) in OPTDICT:
            if (OPTDICT[str(optcode)][2] == 3):
                P1 = CPU.getwordat(i+1)
                PI = CPU.getwordat(P1)
                PII = CPU.getwordat(PI)
            else:
                P1=PI=PII=0              # For Byte size commands, there are no labels.
        ZF = 1 if CPU.flags & 1 else 0
        NF = 1 if CPU.flags & 2 else 0
        CF = 1 if CPU.flags & 4 else 0
        OF = 1 if CPU.flags & 8 else 0
        tos = -1
        sft = -1
        addr = 0 if CPU.mb[0xff] < 1 else (CPU.mb[0xff]-1)*2
        if CPU.mb[0xff] > 0 and addr <= 0xfffe:
            tos = CPU.mb[addr]+(CPU.mb[addr+1] << 8)
        if CPU.mb[0xff] > 1:
            sft = CPU.mb[addr-2]+(CPU.mb[addr-1] << 8)
        tos = tos & 0xffff
        sft = sft & 0xffff
        if CPU.mb[0xff] == 0:
            addr = 0
        else:
            addr = CPU.mb[0xff]
        DispRef = False
        # We are trying to find if the Direct value, Indirect and double indirect values are Labeled
        # File labels for current PC
        Group1 = getkeyfromval(i, FileLabels).strip()
        FoundLabels += " " + Group1
        # File labels for existing optcode argument
        if P1 != 0:
            Group2=getkeyfromval(P1,FileLabels)
            FoundLabels += " " + Group2
        if PI != 0:
            Group3 = getkeyfromval(PI, FileLabels).strip()
            FoundLabels += " " + Group3
        FoundLabels=Sort_And_Combine_Labels(FoundLabels)
        FoundLabels = CPU.FindWhatLine(i)+" " + FoundLabels

        if (optcode in OPTLIST):    # This is making the assumption that value OptCodes are in the range 0 to len(OPTSYM), which really only valid in our special case.
            OUTLINE = "%04x:%8s P1:%04x [I]:%04x [II]:%04x TOS[%04x,%04x] Z%1d N%1d C%1d O%1d SS(%d)" % \
                (i, OPTSYM[optcode], P1, PI, PII,
                 tos, sft, ZF, NF, CF, OF, addr)
        if FoundLabels != "":
            OUTLINE += " # "+FoundLabels
        if not (optcode in OPTLIST):
            bestmatch = 0xffff
            bestmatchcode=""
            for name, iaddr in FileLabels.items():
                if isinstance(iaddr,int):
                    if iaddr > i and iaddr < bestmatch:
                        bestmatch=iaddr
                        bestmatchcode=name
            print("DATA-Segment:")
            hexdump(i,max(min(i+255,bestmatch),i+15),CPU)
#            print("Label : %s" % bestmatchcode)
            i = bestmatch
        else:
            i = i + OPTDICT[str(optcode)][2]
        rstring = ""
        # When debugging we might setup some Watchs for changes in known memory locations.
        if len(watchwords) > 0:
            rstring = "Watch:"
            lastad = 0
            for ii in watchwords:
                if (lastad + 1) != ii:
                    rstring = rstring + "%04x:[%02x]" % (ii, CPU.memspace[ii])
                else:
                    rstring = rstring + "[%02x]" % (CPU.memspace[ii])
                lastad = ii
                rstring += "SD:(%d)" % CPU.mb[0xff]

        print("%s %s" % (OUTLINE, rstring),file=DebugOut)
    return i

def reverse_lookup(my_dict):
    for key,value in my_dict.items():
        reverse_dict[value].append(key)
    return reverse_dict

def getkeyfromval(val, my_dict):
    import re
    global LocVarHist
    result = []
    prefered = []
    nresult = ""
    matchlimit = 0
    if val == 0:
        return ""       # Zero is specal case. It almost never a usefull linenumber
    for key in my_dict:
        if my_dict[key] == val:
            prefered.append(key)
    if prefered:
        m_entries = set()
        non_patterned_entries = set()
        f_entries = {}
        for s in prefered:
            if isinstance(s, tuple):
                s=s[0]
            if s.startswith('M.'):    # Macros
                match = re.match(r'(M\.[^\s]+)', s)
                if match:
                    m_entries.add(match.group(1))
            elif "M." not in s:   # simple labels case
                non_patterned_entries.add(s)
        sorted_non_patterned_entries = sorted(set(non_patterned_entries))
        m_entries = sorted(set(m_entries))
        # Limit to just 3 of each type
        result =  sorted_non_patterned_entries[:3] + list(m_entries[:3])
        return " ".join(result)
    else:
        return ""   # Empty set case
    return

def hexdump(startaddr, endaddr, CPU):
    print("Range is %04x to %04x" % (startaddr, endaddr))
    i = startaddr
    header = "0  .  .  .  .  5  .  .  .  .  A  .  .  .  .  F  .  .  .  .  5  .  .  .  .  A  .  .  .  .  F"
    header = header[(startaddr % 16)*3:][0:47]
    print("       %s" % header)
    while i < endaddr:
        Fstring = "%04x: " % int(i)
        sys.stdout.write(Fstring)
        for j in range(i, i+16 if (i + 16 <= len(CPU.memspace)) else len(CPU.memspace)):
            sys.stdout.write("%02x " % CPU.memspace[j])
        sys.stdout.write("   ")
        for j in range(i, i+16 if (i + 16 <= len(CPU.memspace)) else len(CPU.memspace)):
            c = CPU.memspace[j]
            if ((c != 0x7f) & (((c & 0xc0) == 0x40) | ((c & 0xe0) == 0x20))):
                sys.stdout.write("%c" % c)
            else:
                sys.stdout.write("_")
        i += 16
        print(" ")

# Allow use of the CPUPATH OS Enviroment variable to find library directories.
def fileonpath(filename):
    CPUPATH = os.getenv('CPUPATH')
    if CPUPATH == None:
        CPUPATH = ".:lib:test:."     # Default is working directory and sub-dirs lib and test
    else:
        CPUPATH = ".:"+CPUPATH      # Make sure we include CWD
    for testpath in CPUPATH.split(":"):
        if os.path.exists(testpath+"/"+filename):
            return testpath+"/"+filename
    print("Import Filename error, %s not found" % (filename),file=DebugOut)
    sys.exit(-1)


# This is how we tell if a label been defined as global for local for library inserts.
def IsLocalVar(inlabel, LocalID, LORGFLAG):
    # The structure is that GlobeLabels if they match inlabel will always override the dynamic locallabels.
    # So to define a Globale, just add it to GlobeLabels, but it should become part of FileLabels until
    # really defined...ie with an '=' or a ':' code.
    global GlobeLabels, UniqueLineNum

    if inlabel in GlobeLabels:
        return inlabel
    else:
        if LORGFLAG == LOCALFLAG:
#            return inlabel + "___" + str(LocalID) +"."+ str(UniqueLineNum)
            return inlabel + "___" + str(LocalID)
        else:
            return inlabel


def ReplaceMacVars(line, MacroVars, varcntstack, varbaseSP, filename):
    global MacroStack, Debug
    i = 0
    newline = ""
    inquote = False
    seeescape = False
    while i < len(line):
        c = line[i]
        i = i + 1
        if c == '"' and not (seeescape):
            inquote = not (inquote)
            newline += c
            continue
        seeescape = False
        if c == "\\" and inquote:
            # Main concern for \ is if someone \" inside a quote don't want to exist 'inquote' too soon.
            seeescape = True
            newline += c
            continue
        if c == "%" and not (inquote):
            Before = line[0:i-1]
            After = line[i+1:]
            if (line[i:i+1] == "P"):
                # POP value from refrence stack...does not change newline
                if Debug > 1:
                    print("Pop From MacroStack(%s,%s)" % (MacroStack,line[i:]),file=DebugOut)
                if (not MacroStack):
                    CPU.raiseerror(
                        "049 Macro Refrence Stack Underflow: %s" % line)
                i += 1
                MacroStack.pop()
                continue
            elif (line[i:i+1] == "S"):
                # Stores the current %0 value to refrence stack
                # Does not change the newline
                MacroStack.append(MacroVars[varcntstack[varbaseSP]])
                if Debug > 1:
                    print("Push to MacroStack(%s,%s) Depth: %s" % (MacroStack,line[i:], len(MacroStack)),file=DebugOut)
                i += 1
                continue
            elif (line[i:i+1] == "V"):
                # Insert into newline value that top of refrence stack...do not pop it
                if Debug > 1:
                    print("Refrence top of MacroStack(%s,%s,[%d])" % (MacroStack,line,i),file=DebugOut)
                if (not MacroStack):
                    CPU.raiseerror(
                        "050 Macro Refrence Stack Underflow: %s at %s:%s" % (line,filename,GlobalLineNum))
                newline = newline + MacroStack[-1]
                i += 1
                continue
            elif (line[i:i+1] == "W"):
                # Insert into newline value that is second from top of refrense stack, do not pop it.
                if Debug > 1:
                    print("Refrence second from top of MacroStack(%s,%s,[%d])" % (MacroStack,line,i),file=DebugOut)
                if (not MacroStack or len(MacroStack) < 2 ):
                    CPU.raiseerror(
                        "051 Macro Refrence Stack Underflow: %s" % line)
                newline = newline + MacroStack[-2]
                i += 1
            elif (line[i:i+1] >= "0" and line[i:i+1] <= "9"):
                varval = int(line[i:i+1])
                if len(MacroVars) < varval:
                    CPU.raiseerror(
                        "052 Macro %v Var %s is not defined" % (varval, line))
                newline = newline+MacroVars[varcntstack[varbaseSP] + varval]
                i = i + 1
        else:
            newline = newline + c
    return newline

# Our two pass assembly is very limited on what it can handle on the 2nd pass.
# Basicly, if a value (with possible +/- modifier) does NOT take up a word of memory in the final
# code, and only is a 'value' used by the assembler. Then it CAN NOT be defered for a second pass.
# We need that 'word' of storage to hold temporary values that will later be replaed. All other
# values (such as when labels are themselves used a +/- modifiers) must resolve durring 1st pass.
def FirstPassVal(instr, address, FileLabels, LocalID, LORGFLAG,GlobalOptCnt):
    (value, size) = nextword(instr[1:])
    firstch=value[0:1]
    if firstch == "$":
        value=address
    elif firstch.upper() >= "A" and firstch.upper() <= "Z":
        if value[0:] in FileLabels.keys():
            value=Str2Word(FileLabels[IsLocalVar(value[0:], LocalID, LORGFLAG)])
        else:
            CPU.raiseerror(
                "055 Line %s, : %s Can not use label that is yet definied in first pass of assembler." %
                           (GlobalOptCnt, value))
    else:
        value=Str2Word(value)
    return (value, size)

def DecodeStr(instr, curaddress, CPU, LocalID, LORGFLAG, JUSTRESULT):
    global FileLabels, FWORDLIST, FBYTELIST, GlobeLabels, GlobalLineNum, ActiveFile, UniqueLineNum
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
    # Add some whitespace so we don't have to worry about testing for length
    working = instr + "       "
    if (working[0] == '$' and working[1] == '$' and working[2] != '$'):
        ByteFlag = True
    elif (working[0] == '$' and working[1] == '$' and working[2] == '$'):
        LongWordFlag = True
    # Handle possible quoted text
    starti = 0
    if working[starti] == '"' and not (JUSTRESULT):  # Handle quoted text
        starti += 1
        stopi = len(instr)
        if working[stopi - 1] == '"':
            stopi -= 1
        for c in working[starti:stopi]:
            StoreMem[int(curaddress)] = ord(c)
            curaddress += 1
        return curaddress
    # Can't do a JUSTRESULT for strings.
    elif working[starti] == '"' and JUSTRESULT:
        print("String Values can't be modifed with offsets",file=DebugOut)
        return 0
    # Skip past any remaining modifiers
    while working[starti] == '$':
        starti += 1
    # If first 2 characters are in set "0x" "0o" "0b" then we know its a number in a given base. No Labels, no Post Modifiers
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
        Result = int(working[starti:], BaseNum)
    else:
        # Here be declared labels, look them up, but also look for post modifiers
        stopi = starti + 1
        modval = 0
        while working[stopi].isalnum() or working[stopi] == "_" or working[stopi] == ".":
            stopi += 1
        # in working[stopi+1] is a '+' or '-' then there is a modifier
        modstart = stopi
        modstop = modstart + 1
        while working[modstart] == '+' or working[modstart] == '-':
            if working[modstart] == "-":
                modsign=-1
            else:
                modsign=1
            modvalstr = ""
            modstart = modstart + 1
            while (working[modstop].isspace() == False and
                   (working[modstop] != "+" and working[modstop] != "-")):
                modstop += 1
            modval = modval + DecodeStr(
                working[modstart:modstop], curaddress, CPU, LocalID, LORGFLAG, True) * modsign
            modstart=modstop
            modstop=modstop + 1
        if working[starti:stopi] in FileLabels.keys():
            # First test for Global Labels
            Result = Str2Word(FileLabels[working[starti:stopi]]) + modval
        elif IsLocalVar(working[starti:stopi], LocalID, LORGFLAG) in FileLabels.keys():
            # Now existing Local Labels
            Result = Str2Word(FileLabels[IsLocalVar(working[starti:stopi], LocalID, LORGFLAG)]) + modval
        else:
            # This is case where the label has not yet been defined, we will save it in FWORDLIST for 2nd pass.
            Result = 0
            newkey = IsLocalVar(working[starti:stopi], LocalID, LORGFLAG)
            FWORDLIST.append([newkey, curaddress, modval, "%s:%s"%(ActiveFile,GlobalLineNum)])
            # Labels that are not yet defined HAVE to be 16b
            ByteFlag = False
            LongWordFlag = False
    if JUSTRESULT:
        # This is for cases were the assembler is not to save it into memory.
        return Result
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
    global GlobalLineNum, GlobalOptCnt, Debug, MacroData, MacroPCount, FileLabels, Entry, ActiveFile, FWORDLIST, FBYTELIST, GlobeLabels, SkipBlock, dataaddress, UniqueLineNum, FileLineData
    if Debug > 1:
        if LocalID == 1:
            print("LOCAL:",end="",file=DebugOut)
        else:
            print("Global:",end="",file=DebugOut)
        print("FileLoad Start: %s Addr: %04x" % (filename, offset),file=DebugOut)
    ActiveFile = filename
    StoreMem = CPU.memspace
    address = int(offset)
    line = "#Start"
    backfill = ""
    highaddress = offset
    ExpectData = 0                   # Used as flag and counter when seperate datasegment is in use.
    wfilename = fileonpath(filename)
    with open(wfilename, "r") as infile:
        if address > highaddress:
            highaddress = address
        FBYTELIST = []
        ActiveMacro = False
        MacroVars = ['0']*10
        varcnt = 0
        varbaseSP = 0
        varbaseNext = 0
        varcntstack = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#        SkipBlock = 0
        varcnt = 0
        MacroLine = ""
        varpos = 0
        if Debug > 1:
            print("Reading Filename %s" % wfilename,file=DebugOut)
        while True:
            if ActiveMacro and line == "":
                # If we are inside a Macro expansion keep reading here, until the macro is fully consumed.
                if len(MacroLine) > 0:
                    NewLine = {"M."+ActiveMacroName+" "+filename + ":" +
                    str(GlobalLineNum): address}
                    FileLabels.update(NewLine)

                    (PosParams, PosSize) = nextwordplus(MacroLine)
                    while (PosParams != "" and PosParams != "ENDMACENDMAC"):
                        MacroLine = MacroLine[PosSize:]
                        line = line + " " + PosParams
                        (PosParams, PosSize) = nextwordplus(MacroLine)


                    # at this point line should contain the macro and its possible parameters
                    # Need to subsutute and %# that are not in quotes with varval
                    line = ReplaceMacVars(
                        line, MacroVars, varcntstack, varbaseSP, filename)
                    if Debug > 1:
                        print("Expanded Macro: %s(%40s)" % (line,MacroLine),file=DebugOut)
                    varbaseNext = varbaseSP
                    varbaseSP -= 1 if varbaseSP > 0 else 0
                    if PosParams == "ENDMACENDMAC":
                        # As macro's may call other macros, we need to mark in the stream where they end.
                        MacroLine = MacroLine[PosSize:]
                    if Debug > 1:
                        print("End-Macro: [:]%s" % backfill,file=DebugOut)
                    line = line + " " + backfill
                    backfill = ""
                    ActiveMacro = False
                else:
                    line = backfill
                    if Debug > 1:
                        print("End-Macro: [:]%s" % backfill,file=DebugOut)
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
                        UniqueLineNum += 1
                        GetAnother = False
                        inline = infile.readline()
                        if Debug > 1 and SkipBlock == 0:
                            print("%s:%s> %60s:%2d" % (wfilename,str(GlobalLineNum),inline,SkipBlock), file=DebugOut)
                        if not (address in FileLabels):
                            FileLineData.add_entry(filename, GlobalLineNum, address)
                        if inline:
                            if inline.strip()[-1:] == '\\':
                                GetAnother = True
                                inline = removecomments(inline).strip()
                                line = line + inline.strip()[:-1]
                            else:
                                line = line + inline.strip()
                        else:
                            ExitOut = True
                            break
                    if Debug > 1 and SkipBlock == 0:
                        print("%04x: %s:%2d" % (address, line,SkipBlock),file=DebugOut)
                    if ExitOut:
                        break
            line = removecomments(line).strip()
            if Debug > 1:
                if ActiveMacro == False and SkipBlock == 0:
                    print("%04x: %s> %s" % (address, GlobalLineNum, line),file=DebugOut)
                elif SkipBlock == 0:
                    print("%04x: M-%s> %s : %s" %
                          (address, GlobalLineNum, line, MacroLine[:16]),file=DebugOut)
                else:
                    print("S.",file=DebugOut,end="")

            if SkipBlock != 0:
                while (line != ""):
                    (key, size) = nextword(line)
                    # Because it's not a single letter command, ENDBLOCK is a bit of a outsider.
                    # We allow embeded !/ENDBLOCK blocks, so we need to scan for three states
                    # 1: Are we going down another depth of !'s
                    # 2: Did we find an 'inner' ENDBLOCK
                    # 3: Anything that's not outer ENDBLOCK is skipped.
                    if key == "!" or key == "?":
                        # Handle embeded or nested Blocks
                        SkipBlock = SkipBlock + 1
                        line = line[size:]
                        continue
                    elif key != "ENDBLOCK":
                        line = line[size:]
                        continue
                    else:
                        SkipBlock = SkipBlock - 1
                        if SkipBlock <= 0:
                            line = line[size:]
                            SkipBlock=0
                            break
                        else:
                            line = line[size:]
                            continue
                continue
            elif line[:8] == "ENDBLOCK":
                line = line[8:]
                continue
            if len(line) > 0:
                IsOneChar = False
                if len(nextword(line)[0]) == 1:
                    IsOneChar = True
                if line[0] == "@":
                    # Use a defined Macro Remain words on line will become local variables
                    cpos = 1
                    # Logic of varcntstack:
                    # Initial vcs[0]==0, so vcs[1] should = # vars + 1
                    # So we alway set the n' top of vcs to vcs[n]+#vars in this macro
                    (macname, size) = nextword(line[cpos:])
                    varbaseSP = varbaseNext
                    MacroVars[varcntstack[varbaseSP]] = "__" + \
                        create_new_unique() + str(len(MacroData))
                    cpos += size
                    if macname in MacroData:
                        # To understand what's going on here: We are making a stack that will
                        # store the local macro var values (%1-max) and macros that call other
                        # macros will just use a diffrent range in that same stack.
                        MacroLine = MacroData[macname] + \
                            " ENDMACENDMAC " + MacroLine
                        if cpos < len(line):
                            varcnt = 0
                            for i in range(MacroPCount[macname]):
                                (key, size) = nextwordplus(line[cpos:])
                                varcnt += 1
                                while (varcntstack[varbaseSP]+varcnt + 2) >= len(MacroVars):
                                    MacroVars.append(['0'])
                                MacroVars[varcnt +
                                          varcntstack[varbaseSP]] = key
                                cpos += size
                            if varcnt < MacroPCount[macname]:
                                # When Macro was defined we counted the max %# and now require that # Parms
                                CPU.raiseerror("053 Insufficent required parameters (%s/%s) for Macro %s" %
                                               (varcnt, MacroPCount[macname], macname))
                        varcntstack[varbaseSP +
                                    1] = varcntstack[varbaseSP]+varcnt + 1
                        varbaseNext = varbaseSP + 1
                        ActiveMacro = True
                        ActiveMacroName = macname
                        backfill = line[cpos:] + " " + backfill
                        line = ""
                    else:
                        print("Missing: ", macname,file=DebugOut)
                        CPU.raiseerror(
                            "054  Macro %s is not defined" % (macname))
                # Here is were we start the 'switch case' looking for commands.
                elif line[0] == ":":
                    # The ":" is a label whos value is current address
                    (key, size) = nextword(line[1:])
                    newitem = IsLocalVar(key, LocalID, LORGFLAG)
                    if Debug >1:
                        print(">>> adding %s at location %s with name: %s" %
                              (newitem, hex(address),IsLocalVar(newitem, LocalID, LORGFLAG)),file=DebugOut)

                    FileLabels.update({newitem:address})
                    UpdateVarHistory(newitem,address,address)
                    line = line[size+1:]
                    continue
                elif line[0] == ";":
                    (key, size) = nextword(line[1:])
                    line = line[size+1:]
                    (dsize,size) = nextword(line)
                    line = line[size:]
                    if DataSegment != -1:
                        # If DataSegment was defined, the we use a seperate dataaddress counter
                        workingaddress=dataaddress
                        ExpectData=Str2Word(dsize)   # Defines how many bytes to expect goes into the dataaddress
                    else:
                        ExpectData=0
                    if ("F."+filename+":"+str(GlobalLineNum) in FileLabels):
                        # We created an internal label for each line number, but this label will replace it.
                        del FileLabels["F."+filename+":"+str(GlobalLineNum)]
                    newitem = {IsLocalVar(key, LocalID, LORGFLAG): workingaddress}
                    FileLabels.update(newitem)
                    UpdateVarHistory(newitem,workingaddress,workingaddress)

                elif line[0] == "=":
                    (key, size) = nextword(line[1:])
                    line = line[size+1:]
                    (value, size) = nextwordplus(line)
                    if (not (value[0:len(value)].isdecimal())):
                        value = DecodeStr(value, address, CPU,
                                          LocalID, LORGFLAG, True)
                    newitem=IsLocalVar(key, LocalID, LORGFLAG)
                    FileLabels.update({newitem: value})
                    UpdateVarHistory(newitem,value,address)
                    line = line[size:]
                    continue
                elif ( line[0] == "." and IsOneChar) or line[:4].upper() == ".ORG":
                    if line[:4].upper() == ".ORG":
                        line=line[4:]
                    else:
                        line=line[1:]
                    (value, size) = FirstPassVal(line, address, FileLabels, LocalID, LORGFLAG, GlobalOptCnt)
                    line = line[size+1:] # at this point value is #val of 1st label or constant.
                    # We should also allow labeld or constant values be modified with +/- another label or constant
                    if line[0:1] == "+" or line[0:1] == "-":
                        (modvalue,size) = FirstPassVal(line, address, FileLabels, LocalID, LORGFLAG, GlobalOptCnt)
                        if (line[0:1] == "+"):
                            value = Str2Word(value) + Str2Word(modvalue)
                        else:
                            value = Str2Word(value) - Str2Word(modvalue)
                        line = line[size+1:]    # if there was a second label or constant bump up line past it.
                    address = Str2Word(value)
                    Entry = address
                    continue
                elif ( line[:5].upper() == ".DATA" ):
                    line=line[5:]
                    (value, size) = FirstPassVal(line, address, FileLabels, LocalID, LORGFLAG, GlobalOptCnt)
                    DataSegment = value
                    dataaddress = DataSegment
                    line=line[size+1:]
                    continue
                elif line[0] == "L" and IsOneChar:
                    # Load a file into memory as a library, enable 'local' variables.
                    (newfilename, size) = nextword(line[1:])
                    HoldGlobeLine = GlobalLineNum
                    GlobalLineNum = 0
                    oldfilename = ActiveFile
                    highaddress = address = loadfile(
                        newfilename, address, CPU, LOCALFLAG, str(UniqueLineNum)+newfilename)
                    ActiveFile = oldfilename
                    GlobalLineNum = HoldGlobeLine
                    line = line[size+1:]
                    continue
                elif line[0] == "I" and IsOneChar:
                    # Load a file, but keep it in the 'global' context
                    (newfilename, size) = nextword(line[1:])
                    HoldGlobeLine = GlobalLineNum
                    GlobalLineNum = 0
                    oldfilename = ActiveFile
                    highaddress = address = loadfile(
                        newfilename, address, CPU, GLOBALFLAG, str(UniqueLineNum)+newfilename)
                    ActiveFile = oldfilename
                    GlobalLineNum = HoldGlobeLine
                    line = line[size+1:]
                    continue
                elif line[0] == "P" and IsOneChar:
                    # "P" Print debug messages durring assembly.
                    nline=""
                    for word in line[2:].split(" "):
                        PosVar=FindLabelMatch(word.strip())
                        if (PosVar != None):
                            nline=f"{nline} {word.strip()}:{PosVar} "
                        else:
                            nline=f"{nline} {word.strip()} "
                    print("%04x: %s" % (address, nline),file=DebugOut)
                    line = ""
                    continue
                elif line[0] == "!" and IsOneChar:    # If Macro does NOT exist, then eval until matching ENDBLOCK
                    (key, size) = nextword(line[1:])
                    if key in MacroData:
                        SkipBlock =+ 1
                    line = line[size+1:]
                    continue
                elif line[0] == "?" and IsOneChar:     # If Macro exists, then skip until next ENDBLOCK
                    L=nextword(line[1:])
                    key=L[0]
                    size=L[1]
                    if key in MacroData:
                        L=1
                    else:
                        SkipBlock += 1
                    line = line[size+1:]
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
                        if not (inesc) and invar and (c >= "0" and c <= "9"):
                            invar = False
                            if int(c) > pcount:
                                pcount = int(c)
                        inesc = False
                        if c == '\\':
                            inesc = True
                            continue
                        if c == '%':
                            invar = True
                    MacroPCount.update({key: pcount})
                    line = ""
                    continue
                elif line[0:2] == "MF" and not(IsOneChar):
                    # MF Macro is for setting, or freeing single value macros. For use as flags
                    (key,size) = nextword(line[2:])
                    line=line[size+1:]
                    (value,size) = nextword(line)
                    line=line[size+1:]
                    if (value == ""):
                        # empty string, erase existing macro named key, if any
                        MacroData.pop(key,None)
                    else:
                        # Otherwise inerset a simple one word or value to enable the MacroKey
                        MacroData.update({key: value})
                elif line[0] == "G" and IsOneChar:
                    # Globale labels are an override of 'Local' Labels by 'pre-defining them.
                    (key, size) = nextword(line[1:])
                    GlobeLabels.update({key: address})
                    line = line[size+1:]
                    continue
                else:
                    # Pretty much every else drops here to be evaulated as numbers or macros to be defined.
                    # Note than nearly everything here will take up some sort of storage, so address will
                    # be incremented. This is where labels become 'variables'
                    LineAddrList.append([address, GlobalLineNum, filename])
                    (key, size) = nextwordplus(line)
                    line = line[size:]
                    if address > highaddress:
                        highaddress = address
                    if len(key) > 0:
                        if ExpectData > 0:
                            # We do this because after we define a custom dataaddress constant
                            # we may have a mix of values that will act as the initialization fill
                            # for that defined space. It might be made of more than one word
                            # do we keep subtracting from ExpectData until we've filled it all.
                            prevval=dataaddress
                            dataaddress = DecodeStr(key, dataaddress, CPU,  LocalID, LORGFLAG, False)
                            ExpectData -= (dataaddress - prevval)
                        else:
                            address = DecodeStr(key, address, CPU,  LocalID, LORGFLAG, False)
        for store in FWORDLIST:
            key = store[0]
            vaddress = store[1]
            if key in FileLabels.keys():
                v = Str2Word(FileLabels[key])
                if (len(store) > 2):
                    if store[2] != 0:
                        v = v + Str2Word(store[2])
                        # This extra bit logic handles the case of labels+## math.
                StoreMem[int(vaddress)] = CPU.lowbyte(v)
                StoreMem[int(vaddress + 1)] = CPU.highbyte(v)
            elif key in GlobeLabels.keys():
                v = Str2Word(GlobeLabels[key])
                if (len(store) > 2):
                    if store[2] != 0:
                        v = v + Str2Word(store[2])
                        # This extra bit logic handles the case of labels+## math.
                StoreMem[int(vaddress)] = CPU.lowbyte(v)
                StoreMem[int(vaddress + 1)] = CPU.highbyte(v)
            else:
                print(key, " is missing (SYM,ADDR,Delta,LineNum)", store,key,vaddress,file=DebugOut)
    if Debug > 1:
        i = 0
    if address > highaddress:
        highaddress = address
    if dataaddress > highaddress:
        highaddress = dataaddress
    return highaddress


def debugger(FileLabels,passline):
    global InDebugger, LineAddrList, watchwords, breakpoints, tempbreakpoints, GlobalOptCnt, EchoFlag, GlobalLineNum, ActiveFile
    startrange = 0
    stoprange = 0
    redoword = "Null"
    InDebugger = True
    size = 0
    cmdword = ""
    # Main Loop of debugger
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
        sys.stdout.flush()
        if len(passline) != 0:
            # passline is a way debugger can be called and process some fixed commands before returning to user inputed commands.
            print("processing %s\n" % passline)
            cmdline=passline[0]
            passline=passline[1:]
        else:
            cmdline = input()
        if EchoFlag:
            # If tty operations have disabled echo, which is needed by interactive prompts of the debugger
            new[3] = new[3] & ~termios.ECHO
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, new)
            except:
                print("TTY Error: On Echo On")
        # To file redirection from 'scipted debug files' we also allow possible comments in those files.
        cmdline = removecomments(cmdline).strip()
        if cmdline != "":
            (cmdword, size) = nextword(cmdline)
        cmdline = cmdline[size:]
        stepnumber = 1
        doexec = False
        arglist = []
        rawlist = []
        argcnt = 0
        (thisword, size) = nextword(cmdline)
        cmdline = cmdline[size:]
        varval = 0
        best_score = 0
        best_match = None
        while thisword != "":
            rawlist.append(thisword)
            if "A" <= thisword[0] <= "z":
                if thisword in FileLabels:
                    varval = FindHistoricVal(thisword, CPU.pc)
                    arglist.append(varval)
                    argcnt += 1
                    print("%s found: %04x" % (thisword, varval))
                else:
                    varval = FindLabelMatch(thisword)
                    if varval != None:
                        arglist.append(varval)
                        argcnt += 1
            else:
                Signval=0
                if (thisword[0] if thisword and len(thisword) > 0 else "Invalid") in [ "+", "-"]:
                    # Handle case where user did label+/-value
                    Signval=1 if thisword[0]=="+" else -1
                    thisword=thisword[1:]                
                # Convert to 16 bit number allow 0x formats
                thisword = Str2Word(thisword)
                if Signval != 0:
                    if arglist: # check to make sure arglist is not empty (args start with +/- value)
                        arglist[argcnt - 1]=arglist[argcnt - 1]+(Signval*thisword)
                    else:
                        # Handle the odd case where first argument is +/- value
                        arglist.append(thisword * Signval)
                        argcnt += 1                        
                else:
                    arglist.append(thisword)
                    argcnt += 1
            (thisword, size) = nextword(cmdline)
            cmdline = cmdline[size:]
# at this point cmdword == a possible comand and arglist is a group of 16b numbers if any given.
        if cmdword == "Null":
            # Do nothing
            continue
        if cmdword == "d":
            if argcnt > 0:
                startrange = int(arglist[0])
                stoprange = startrange+3
            if argcnt > 1:
                stoprange = int(arglist[1])
            if argcnt == 0:
                if stoprange != 0:
                    startrange = stoprange
                else:
                    startrange = CPU.pc
                stoprange = startrange+42
            print("Range of DissAsmby %04x - %04x" % ( startrange, stoprange))
            stoprange = DissAsm(startrange, stoprange - startrange, CPU)
            continue
        if cmdword == "ps":
            if (CPU.mb[0xff] == 0):
                print("Empty Stack")
                continue
            print("Print HW Stack, Depth (%d)" % CPU.mb[0xff])
            for i in range(0, min(CPU.mb[0xff]*2, 64), 2):
                v = CPU.mb[i] + (CPU.mb[i+1] << 8)
                SInfo = "%04x:" % v
                if (v > 0 and v < (len(CPU.memspace)-2)):
                    SInfo = SInfo+"[%0x]" % CPU.getwordat(v)
                    SInfo = SInfo+"[[%0x]]" % CPU.getwordat(CPU.getwordat(v))
                else:
                    SInfo = SInfo + "[*]"
                print(SInfo)
                continue
        if cmdword == "p":
            if argcnt > 0:
                if argcnt == 1:
                    startv = int(arglist[0])
                    stopv = startv + 1
                else:
                    startv = int(arglist[0])
                    stopv = int(arglist[1]) + 1
                if stopv < startv:
                    stopv = startv + stopv + 1
                for v in range(startv, stopv):
                   SInfo = "%04x:" % v
                   SInfo = SInfo+"[%02x]" % CPU.getwordat(v)
                   SInfo = SInfo+"[[%02x]]" % CPU.getwordat(CPU.getwordat(v))
                   SInfo += "  "
                   for ci in ("'",
                           v & 0xff,
                           (v >> 8) &0xff,
                           "'","[","'",
                           CPU.getwordat(v) & 0xff,
                           (CPU.getwordat(v) >> 8) & 0xff,
                           "'","]","[","[","'",
                           CPU.getwordat(CPU.getwordat(v)) & 0xff,
                           (CPU.getwordat(CPU.getwordat(v))>>8) & 0xff,
                           "'","]","]"):
                       if isinstance(ci, int) or isinstance(ci, np.int64):
                           c=ci
                       else:
                           c=ord(ci)
                       if ((c != 0x7f) & (((c & 0xc0) == 0x40) | ((c & 0xe0) == 0x20))):
                           SInfo += "%c" % c
                       else:
                           SInfo += "_"
                   print(SInfo)
            else:
                print("ERR: Need to specify what to print")
                continue
        if cmdword == "pa":
            if argcnt > 0:
                for label in arglist:
                    FindLabelMatch(label)
            else:
                # Handle prety print of all variables
                filtered_labels = {key: value for key, value in FileLabels.items() if (not key.startswith("_") and not key.startswith("F.") and not key.startswith("M."))}

                table = "| Name | Value |\n"
                table += "|------|-------|\n"

                # Add each filtered label to the table
                for key, value in filtered_labels.items():
                    table += f"| {key} | {int(value):04x} |\n"
                print(table)

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
                        DissAsm(int(arglist[0]), 1, CPU)
                else:
                    # Start sub-command mode
                    cmdline = "NONE"
                    sys.stdout.write("Key: ")
                    sys.stdout.write("### is decimal 0-9 ")
                    sys.stdout.write(
                        "Prepend 0x, 0o or 0b for hex, octal or binary format\n")
                    sys.stdout.write(
                        "By default 16 bit integer, prepend $$ for 8 bit bytes or $$$ for 32 bit words\n")
                    sys.stdout.write(
                        "8 bit ascii codes can be entered using double quotes\n")
                    sys.stdout.write(
                        "Use '.' on line byself to exit back to main mode.\n\n")
                    while cmdline != "BREAK":
                        sys.stdout.write("%04x[b%02x,b%02x]: " % (
                            maddr, CPU.memspace[maddr], CPU.memspace[(maddr+1) & 0xffff]))
                        sys.stdout.flush()
#                  cmdline = sys.stdin.readline(256)
                        cmdline = input()
                        cmdline = removecomments(cmdline).strip()
                        L=nextword(cmdline)
                        while len(cmdline) > 0 and cmdline != "BREAK":
                            L=nextword(cmdline)
                            if L[0] == "":
                                # empty command means just move forward one byte
                                maddr += 1
                                cmdline=""
                                L=("",0)
                                continue
                            if cmdline != ".":
                                if (L[0][0:1] == '"'):
                                    (quotesize, quotetext) = GetQuoted(cmdline)
                                    for iii in range(0, len(quotetext)):
                                        CPU.memspace[maddr] = ord(
                                            quotetext[iii]) & 0xff
                                        maddr += 1
                                    cmdline=cmdline[L[1]:]
                                    L=("",0)
                                    continue
                                if len(L[0]) == 1 and L[0][0:1] >= "0" and L[0][0:1] <= "9":
                                    newval = int(L[0])
                                    # Single digit number must be b10
                                    CPU.memspace[maddr] = newval & 0xff
                                    maddr += 1
                                    # high byte has to be zero
                                    CPU.memspace[maddr] = 0
                                    maddr += 1
                                    cmdline=cmdline[L[1]:]
                                    L=("",L[1])
                                    continue
                                else:
                                    startnum = 0
                                    expectsize = 2       # Number of bytes in value
                                    if L[0][0:3] == "$$$":
                                        expectsize = 4
                                        startnum = 3
                                if L[0][0:2] == "$$":
                                    expectsize = 1
                                    startnum = 2
                                elif L[0][0:1] == "$":
                                    startnum = 1
                                try:
                                    if expectsize != 4:
                                        cmdline=cmdline[L[1]:]
                                        L=nextword(L[0][startnum:])
                                        if (L[0] in FileLabels.keys()):
                                            newval = Str2Word(
                                                FileLabels[L[0]])
                                        else:
                                            newval = Str2Word(
                                                L[0])
                                    else:
                                        newval = int(L[0][startnum:])
                                    for iii in range(0, expectsize):
                                        CPU.memspace[maddr] = newval & 0xff
                                        newval = newval >> 8
                                        maddr += 1
                                    cmdline=cmdline[L[1]:]
                                    L=("",0)
                                    continue
                                except:
                                    print("Input %s not valid" % cmdline)
                                    cmdline=""
                                L=("",0)
                                continue
                            else:
                                cmdline = "BREAK"
                                cmdword = ""
                                L=("",0)
                                print("End Modify")
                                break
        if cmdword == "l":
            startaddr = 0
            stopaddr = 30
            if argcnt > 0 or len(rawlist) > 0:
                print(rawlist)
                tresult = CPU.FindAddressLine(rawlist[0])
                if tresult == None:
                    print("Range 1(%s) not valid:" % rawlist[0])
                    startaddr=0
                else:
                    startaddr=int(tresult)
                if argcnt > 1:
                    tresult=CPU.FindAddressLine(rawlist[1])
                    if tresult == None:
                        print("Range 2(%s) not valid:" % rawlist[1])
                        stopaddr=0
                    else:
                        stopaddr=int(tresult)
                else:
                    if startaddr != 0:
                        stopaddr=startaddr+30
                    else:
                        stopaddr=startaddr
            if stopaddr < startaddr:     # Handle cases when labels are swapped.
                stopaddr = startaddr + abs(stopaddr)
            print("Dissasembly from src lines %04x to %04x" %
                  (startaddr, stopaddr))
            DissAsm(startaddr, stopaddr - startaddr, CPU)
            continue
        if cmdword == "hex":
            if argcnt > 0:
                if argcnt == 1:
                    startv = int(arglist[0])
                    stopv = startv + 16
                else:
                    startv = int(arglist[0])
                    stopv = int(arglist[1]) + 1
                    if stopv < startv:
                        stopv = startv + stopv + 1
                hexdump(startv, stopv, CPU)
            else:
                print("ERR: Need to specify what to print")
                continue
        if cmdword == "n":
            stepcnt = 1
            stoprange = 0
            if argcnt > 0:
                stepcnt = arglist[0]
            for i in range(stepcnt):
                CPU.evalpc()
                DissAsm(CPU.pc, 1, CPU)
                if CPU.pc in breakpoints or CPU.pc in tempbreakpoints:
                    print("Break Point %04x" % CPU.pc)
                    if CPU.pc in tempbreakpoints:
                        tempbreakpoints.remove(CPU.pc)
                    break
            continue
        if cmdword == "s":
            TestFlag = False
            stoprange = 0
            for ii in SymToValMap:
                if CPU.memspace[CPU.pc] == ii[0]:
                    TestFlag = True
            if TestFlag:
                CurInstSize = SymToValMap[CPU.memspace[CPU.pc]][2]
                tempbreakpoints.append(CPU.pc + CurInstSize)
                print("Setting Temporary Break Point at %04x" %
                      (CPU.pc + CurInstSize))
                cmdword = "c"  # This only works because cmdword == "c" is bellow this 'if block'
            else:
                print("PC Not resting on valid Opt Code. Can not single step.")
        if cmdword == "c":
            stoprange = 0
            DissAsm(CPU.pc, 1, CPU)
            AtLeastOne = 1
            while CPU.pc <= 0xffff:
                if (CPU.pc in breakpoints or CPU.pc in tempbreakpoints) and AtLeastOne != 1:
                    print("Break Point %04x" % CPU.pc)
                    if ( CPU.pc in tempbreakpoints):
                        tempbreakpoints.remove(CPU.pc)
                    DissAsm(CPU.pc, 1, CPU)
                    break
                AtLeastOne = 0
                GlobalOptCnt += 1
                CPU.evalpc()
        if cmdword == "r":
            stoprange = 0
            if argcnt < 1:
                CPU.pc = Entry
                CPU.mb[0xff] = 0
                print("PC set to %0x4" % Entry)
                CPU.flags = 0
            else:
                CPU.pc = arglist[0]
                print("PC set to %04x" % arglist[0])
            CPU.flags = 0
            CPU.mb[0xff] = 0
            continue
        if cmdword == "g":
            stoprange = 0
            if argcnt < 1:
                print("Need to provide an address to go to.")
                cmdword = "Null"
                continue
            CPU.pc = arglist[0]
            print("PC set to %04x" % arglist[0])
            continue
        if cmdword == "tb":
            if argcnt < 1:
                cmdword = "b"
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
                        print("%04x" % int(ii))
                if len(tempbreakpoints) != 0:
                    for ii in tempbreakpoints:
                        print("Temp Break:%04x" % ii)
            else:
                for ii in arglist:
                    breakpoints.append(ii)
            continue

        if cmdword == "cb":
            print("Clearing Breakpoints")
            breakpoints = []
            continue
        if cmdword == "w":
            if argcnt < 1:
                print(watchwords)
            else:
                for ii in arglist:
                    watchwords.append(Str2Word(ii))
        if cmdword == "L":
            if argcnt < 1:
                sys.stdout.write("Filename: ")
                ii = input()
            else:
                ii=arglist[0]
            if os.path.exists(ii):
                HoldGlobeLine = GlobalLineNum
                GlobalLineNum = 0
                oldfilename = ActiveFile
                highaddress = loadfile(
                    ii, 0, CPU, LOCALFLAG, str(UniqueLineNum)+ii)
                ActiveFile = oldfilename
                GlobalLineNum = HoldGlobeLine
            else:
                print("File: %s Not found" % ii)
            continue
        if cmdword == "I":
            if argcnt < 1:
                sys.stdout.write("Filename: ")
                ii = input()
            else:
                ii=arglist[0]
            if os.path.exists(ii):
                HoldGlobeLine = GlobalLineNum
                GlobalLineNum = 0
                oldfilename = ActiveFile
                highaddress = loadfile(
                    ii, 0, CPU, GLOBALFLAG, str(GlobalOptCnt)+filename)
                ActiveFile = oldfilename
                GlobalLineNum = HoldGlobeLine
            else:
                print("File: %s Not found" % ii)
            continue
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
            print("""
Debug Mode Commands:
b - break points        c - continue [ $1 steps ]
cb - clear breakpoints  d - DissAsm $1 $2
h  - this test          hex-Print hexdump $1[-$2]
l  - DissAsm from line  m  - modify address starting wiht $1
n  - Do one step        p - print values $1
ps - Print HW Stacl     q - quit debugger
r  - reset              w - watch $1 """)
        continue

def main():
    global Debug, CPU, GlobeLabels, watchwords, DebugOut, SkipBlock

    # Setup some test filelabels
    DEFMEMSIZE = 0x10000
    Remote = False
    SkipBlock = 0
    Debug = 0
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
    firstcmd=[]
    for i, arg in enumerate(sys.argv[1:]):
        if skipone:
            skipone = False
            if prpcmd == 1:
                watchwords.append(Str2Word(arg))
                print("New Watchwords %s" % (watchwords))
            if prpcmd == 2:
                breakafter.append(Str2Word(arg))
            if prpcmd == 3:
               firstcmd+=[arg]
        else:
            if arg == "-d":
                Debug = Debug + 1
            elif arg == "-l":
                ListOut = True
            elif arg == "-g":
                UseDebugger = True
                DebugOut=sys.stdout
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
            elif arg == "-e":
                prpcmd = 3
                skipone = True
                UseDebugger = True
                DebugOut=sys.stdout
            elif arg == "-r":
                Remote = not (Remote)
            elif arg == "-h":
                print("-d Debug Assembly and Run\n-d more debugging info.\n-l List Src\n-g Run interactive debugger\n-c Hex Dump of Assembly\n-O Binary Dump of Assembly\n-w Add Watch Address to debug listing\n-b Set Breakpoint to debugger\n-r Enable Remote PDB\n-h help, this listing\n-e 'command' pass to debugger")
            elif arg[0] >= "0" and arg[0] <= "9":
                breakafter += (arg)
            else:
                files.append(arg)
#    Entry = 0
    maxusedmem = 0
    for curfile in files:
        maxusedmem = loadfile(curfile, maxusedmem, CPU, GLOBALFLAG, 0)
    GlobalOptCnt = 0

    if len(files) == 0:
        # if no files given then drop to debugger for machine lang tests.
        # Default to common.mc to provide base macros
        maxusedmem = loadfile("common.mc", maxusedmem, CPU, GLOBALFLAG, 0)
        UseDebugger = True
    if Remote:
        print("RDB running on port 4444, use nc localhost 4444")
        rpdb.set_trace()
    if OptCodeFlag:
        # Write the 'compiled' code as a hex dump file.
        newfile = create_new_filename(files[0], "hex")
        f = open(newfile, "w")
        f.write("# BIN(%s,%s,%s\n. 0\n" % (files, CPU.pc, len(CPU.memspace)))
        toplimit = len(CPU.memspace)
        for i in range(len(CPU.memspace)-1, 1, -1):
            if CPU.memspace[i] != 0:
                break
            toplimit -= 1
        i = 0
        zerocount = 0
        while (i < toplimit):
            if (CPU.memspace[i] == 0):
                zerostart = i
                while (CPU.memspace[i] == 0 and i < toplimit):
                    zerocount += 1
                    i += 1
                if zerocount < 10:
                    # If zero count is < 10 then just print it out
                    for j in range(0, zerocount):
                        f.write("$$0x%01x " % 0)
                        if (((j + zerostart + 1) % 16) == 0):
                            f.write("# %04x - %04x\n" %
                                    (j + zerostart - 0xf, i))
                    zerocount = 0
                    continue
                else:
                    # More than 10 zerros, just set new '.' spot
                    f.write(
                        "\n# Skipping zero block size: 0x%04x\n. 0x%04x\n" % (zerocount, i))
                    zerocount = 0
                    continue   # We already inc'ed i so skip the common one.
            else:
                # Not a zero, so just write normally
                v = CPU.memspace[i]
                f.write("$$0x%02x " % v)
                if (((i + 1) % 16) == 0):
                    f.write("# %04x - %04x\n" % (i-0xf, i))
            i += 1
        f.write("\n#End Memory:\n")

        for gkey in GlobeLabels:
            if gkey in FileLabels:
                f.write("=%s %s\nG %s\n" % (gkey, FileLabels[gkey], gkey))
        f.write("\n# Set Entry:\n. 0x%04x\n" % (Entry))
        f.close()
        sys.exit()
    if BinaryOutFlag:
        newfile = create_new_filename(files[0], "bin")
        f = open(newfile, "wb")
        limiter = len(CPU.memspace)
        for i in range(len(CPU.memspace)-1, 1, -1):
            if CPU.memspace[i] != 0:
                break
            limiter -= 1
        filler = 0x100 - (limiter % 0x100)
        print("Writeing Binary Output from %s with spacer of %s" %
              (limiter, filler))
        for i in range(0, limiter):
            cval = ((CPU.memspace[i]) & 0xff)
            f.write(''.join(chr(cval)).encode('charmap'))
        for i in range(0, filler):
            f.write('\0'.encode('charmap'))
        f.close()
        sys.exit()
    i = 0
    SP = -1
    RunMode = True
    CPU.pc = Entry
    if Debug > 1:
        print("Start of Run: Debug: %s: Watch: %s" % (Debug, watchwords))
    if ListOut:
        print("-------0--Max:%04x------" % (maxusedmem),file=DebugOut)
        DissAsm(0, maxusedmem, CPU)
    elif UseDebugger:
        debugger(FileLabels,firstcmd)
    else:
        while True:
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
