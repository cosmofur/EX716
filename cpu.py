#!/usr/bin/env python3

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
import traceback


# Constants
class WatchedDict(dict):
    def __init__(self, *args, **kwargs):
        self.watch_keys = set()
        super().__init__(*args, **kwargs)

    def watch(self, key):
        self.watch_keys.add(key)

    def update(self, other, note=""):
        for k, v in other.items():
            if k in self.watch_keys:
                print(f"[WATCH] FileLabels[{k}] = {v}  ({note})")
                print("Stack trace (most recent call last):")
                for line in traceback.format_stack(limit=10):  # limit for brevity
                    print("   " + line.strip())
            super().update({k: v})

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
            ch=msvcrt.getch()
            if ch in (b'\x00', b'\xe0'):
                ch2=msvcrt.getch()
                return 0x1000 | ch2[0]
            else:
                return ord(ch)
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

            def lread_char(timeout=0.05):
                rlist, _, _ = select.select([fd], [], [], timeout)
                return sys.stdin.read(1) if rlist else ''

            ch1 = lread_char()
            if not ch1:
                return None
            if ch1 != '\x1b':  # Escape
                return ord(ch1)
            ch2 = read_char()

            if ch2 == '':
                return 0x001b      # ESC alone
            ch3 = read_char()
            if ch2 == '[':
                if ch3 == 'A': return 0x1048  # UP
                if ch3 == 'B': return 0x1050  # Down
                if ch3 == 'C': return 0x104D  # Right
                if ch3 == 'D': return 0x104B  # Left
                if ch3 == 'H': return 0x147   # Home
                if ch3 == 'F': return 0x14F   # End
            elif ch2 == 'O':                  # Xterm style F1-F4
                if ch3 == 'P': return 0x13b   # F1
                if ch3 == 'Q': return 0x13b   # F2
                if ch3 == 'R': return 0x13b   # F3
                if ch3 == 'S': return 0x13b   # F4

            return 0x1fff
        finally:
            # Restore the terminal settings and file descriptor flags
            termios.tcsetattr(fd, termios.TCSAFLUSH, old_attr)
            fcntl.fcntl(fd, fcntl.F_SETFL, old_flags)

else:
    raise NotImplementedError("Unsupported platform")

from pstats import SortKey

from pathlib import Path


current_context = None

class AssemblerContext:
    def __init__(self):
        # Memory and address state
        self.StoreMem = np.zeros(0x10000, dtype=np.uint8)        
        self.address = 0
        self.dataaddress = 0
        self.highaddress = 0
        self.Entry = 0
        self.DEFMEMSIZE = 0x10000

        # Labels and variables
        self.FileLabels = {}
        self.GlobeLabels = {}
        self.FWORDLIST = []
        self.FBYTELIST = []

        # Macro state
        self.MacroData = {}
        self.MacroPCount = {}
        self.MacroVars = ['0'] * 64

        self.varcntstack = [0] * 16
        self.varbaseSP = 0
        self.varbaseNext = 0
        self.ActiveMacro = False
        self.ActiveMacroName = ""
        self.MacroLine = ""
        self.backfill = ""

        # File and line tracking
        self.ActiveFile = ""
        self.DeviceFile = 0
        self.GlobalLineNum = 0
        self.FileLineNum = 0
        self.UniqueLineNum = 0
        self.LocalID = ""
        self.LORGFLAG = 0
        self.SkipBlock = 0
        self.AddressedLinesSeen = set()
        self.CurrentLineBeingParsed = 0

        # Data segment state
        self.ExpectData = 0
        self.DataSegment = -1

        # Debug/Options
        self.Debug = 0
        self.GlobalOptCnt = 0
        self.Remote = False
        self.watchwords = []


path_root = os.path.abspath("lib")
sys.path.append(str(path_root))



MacroStack = []
breakpoints = []
tempbreakpoints = []
UniqueLineNum = 0
DeviceHandle = None
EchoFlag = False
UniqueID = 0
LastMLen = 0


GLOBALFLAG = 1
LOCALFLAG = 2
MAXMEMSP = 0xffff
MAXHWSTACK = 0xff - 2


InDebugger = False
RunMode = False
GPC = 0

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
    global current_context
    # This is NOT (as yet) an interupt handler for the CPU, just a way to drop code into the debugger.
    #
    msg = "Ctrl-c"
    print(msg, end="", flush=True)
    debugger("",current_context)


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
    instr=instr.lower()
    if typecode == 16:
        alpha = "0123456789abcdefABCDEF-+x"
    elif typecode == 2:
        alpha = "01+-xb"
    elif typecode == 8:
        alpha = "01234567+-xo"
    elif typecode == 10:
        alpha = "0123456789+-"
    else:
        CPU.raiseerror(f"Unknown base typecode: {typecode}")
    for cc in instr:
        if not (cc in alpha):
            CPU.raiseerror("String %s is not valid for base %d" % (instr, typecode))
    return (int(instr, 0))

LocVarHist = {}

def UpdateVarHistory(varname,value,address):
    global LocVarHist
    if varname in LocVarHist:
        oldvallist=LocVarHist[varname]
        oldvallist.append((value,address))
    else:
        newvallist=[(value,address)]
        LocVarHist[varname]=newvallist

def FindHistoricVal(varname, testaddress,  context: AssemblerContext):
    global LocVarHist

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

def FindLabelMatch(varname, context: AssemblerContext):
    varname=str(varname)
    if varname in context.FileLabels:
        return context.FileLabels[varname]

    potential_matches = [ key for key in context.FileLabels.keys() if key.startswith(varname + "_")]
    if len(potential_matches) == 1:
        return context.FileLabels[potential_matches[0]]
    if len(potential_matches) > 1:
        maxkeywidth=max(len(match) for match in potential_matches)
        maxvaluewidth=max(len(f"{int(context.FileLabels[match]):04x}") for match in potential_matches)
        table = f"Multiple matches found for '{varname}:\n"
        table += f"|{'Name':<{maxkeywidth}}|{'Value':<{maxvaluewidth}}|\n"
        table += f"|{'-'*maxkeywidth}|{'-'*maxvaluewidth}|\n"
        for match in potential_matches:
            value = f"{int(context.FileLabels[match]):04x}"
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
        if memory_address not in self.address_map:
            bisect.insort(self.sorted_addresses, memory_address)
        self.address_map[memory_address] = (filename, line_number)
        

    def get_line_info(self, memory_address, exact=False):
        if memory_address in self.address_map:
            return self.address_map[memory_address]
        if exact:
            return None
        pos=bisect.bisect_right(self.sorted_addresses, memory_address)
        if pos==0:
            return None
        nearest_lower_address = self.sorted_addresses[pos-1]
        return self.address_map[nearest_lower_address]
    
    def get_nearest_address(self, filename, line_number):
        matching_files = [
            afile for afile in self.file_data
            if line_number in self.file_data[afile]
        ]

        if filename not in self.file_data:
            if len(matching_files) > 1:
                print("Multiple Matches for Line:(%d) : Re-enter with one of the following." % line_number)
                for afile in matching_files:
                    addr = self.file_data[afile][line_number][0]
                    print("%s:%d:%04x" % (afile, line_number, addr))
                return None
            elif len(matching_files) == 1:
                filename = matching_files[0]
            else:
                return None

        lines = sorted(self.file_data[filename].keys())

        closest_line = None
        for ln in lines:
            if ln >= line_number:
                closest_line = ln
                break

        if closest_line is None:
            return None

        address = self.file_data[filename][closest_line][0]
        return (filename, closest_line, address)

FileLineData = InputFileData()

def safeprint(*args, **kwargs):
    try:
        print(*args, **kwargs)
    except Exception as e:
        try:
            print("Logging failed: ", e)
        except:
            pass  # Fail completely silently


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
        self.identity = next(self.cpu_id_iter)
        self.mb = np.zeros(256, dtype=np.uint8)
        self.memspace = np.zeros(memsize, dtype=np.uint8)
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
        CPU.memspace[location] = value

    def dumpstack(self,stack):
        global FileLineData
        print("")
        if not isinstance(stack, np.ndarray):
            raise TypeError("stack must be a NumPy array")
        if len(stack) % 2 != 0:
            stack=np.append(stack,0)
        arr_words=stack.view(np.uint16)
        newlist=[]
        print("Stack Dump:")
        for num in arr_words:
            if num < 0xff:
                newlist.append(f"0x{num:04x} ")
            else:
                tresult=FileLineData.get_line_info(num, False)
                if tresult == None or len(tresult) < 2:
                    newlist.append(f"0x{num:04x} ")
                else:
                    newlist.append(f"{tresult[0]}:{tresult[1]}")
        print(" ".join(newlist))

    def FindWhatLine(self, address):
        global FileLineData
        tresult = FileLineData.get_line_info(address, False)
        if tresult == None or len(tresult)< 2 :
            print("No good line match found for address %04x" % address)
            return " no-file "
        return "%s:%d" % tresult

    def FindAddressLine(self, line_info):
        global FileLineData
        if (":" in line_info):
            parts=line_info.split(":")
            OutFile = parts[0] if parts[0] else None
            self.Last_Filename_used = OutFile
            OutLine= int(digitsonly(parts[1]))
        else:
            OutFile=self.Last_Filename_used
            OutLine = int(digitsonly(line_info))            
        return FileLineData.get_nearest_address(OutFile, OutLine)

    def raiseerror(self, idcode):
        global GPC, RunMode, DebugOut

        valid = -1
        try:
            fd = sys.stdin.fileno()
            new = termios.tcgetattr(fd)
            new[3] = new[3] | termios.ECHO
            termios.tcsetattr(fd, termios.TCSADRAIN, new)
        except Exception as e:
            safeprint("TTY Setup Error:", e, file=DebugOut)

        try:
            safeprint("CPU State:", file=DebugOut)
            i = getattr(self, "pc", -1)
            mem = getattr(self, "memspace", {})

            if current_context is None:
                safeprint("Emulator failed to startup. Code: %s" % idcode, file=DebugOut)
                sys.exit(99)

            if 0 <= i < 0xffff:
                try:
                    try:
                        optcode = mem[i]
                    except:
                        optcode = 0
                    P1 = self.getwordat(i+1)
                    PI = self.getwordat(P1 & 0xfffe)
                    PII = self.getwordat(PI)
                    ZF = 1 if self.flags & 1 else 0
                    NF = 1 if self.flags & 2 else 0
                    CF = 1 if self.flags & 4 else 0
                    OF = 1 if self.flags & 8 else 0
                    opname = OPTSYM[optcode] if optcode < len(OPTSYM) else f"OP{optcode:02x}"
                    outline = "%04x:%8s P1:%04x [I]:%04x [II]:%04x Z%d N%d C%d O%d" % (
                        i, opname, P1, PI, PII, ZF, NF, CF, OF
                    )
                    safeprint(outline, file=DebugOut)
                    pline = self.FindWhatLine(i)
                    if pline is not None:
                        safeprint(f"Line: {pline}", file=DebugOut)
                except Exception as e:
                    safeprint("Error printing instruction context:", e, file=DebugOut)
            else:
                safeprint("Invalid PC: %06x" % i, file=DebugOut)

            # Dump stack if present
            try:
                sp = self.mb[0xff]
                if 0 < sp < 255:
                    for idx in range(sp - 1):
                        val = self.mb[idx*2] + 0xff * self.mb[idx*2 + 1]
                        safeprint(" %04x" % val, file=DebugOut, end="")
                    safeprint(" ", file=DebugOut)
                else:
                    safeprint("Stack Empty or Invalid SP: %02x" % sp, file=DebugOut)
                    self.mb[0xff] = 0xf0  # reset
            except Exception as e:
                safeprint("Stack dump error:", e, file=DebugOut)

            # Print ID code
            safeprint("Error Number: %s at PC:0x%04x" % (idcode, i), file=DebugOut)
            if idcode[:3].isdigit():
                valid = int(idcode[:3])
        except Exception as e:
            safeprint("Error decoding idcode:", e, file=DebugOut)
            valid = -1

        # Always try to enter the debugger if we're in dev mode
        try:
            safeprint("Entering debugger due to fatal error.", file=DebugOut)
            debugger("", current_context)
        except Exception as e:
            safeprint("Debugger failed: %s" % e, file=DebugOut)
            safeprint("Falling back to sys.exit(%d)" % valid, file=DebugOut)
            sys.exit(valid)

   


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
            safeprint("Stack Empty.",file=DebugOut)
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
            self.dumpstack(self.mb)
            self.raiseerror("005 MB Stack overflow, optpush")
        sp *= 2
        self.mb[sp] = self.lowbyte(invalue)
        self.mb[sp + 1] = self.highbyte(invalue)
        self.mb[0xff] += 1

    def optDUP(self, address):
        sp = self.mb[0xff]
        if sp > (0xff/2 - 2):
            self.dumpstack(self.mb)
            self.raiseerror("006 MB Stack overflow, optpush")
        sp *= 2
        self.mb[sp] = self.lowbyte(self.mb[sp - 2])
        self.mb[sp + 1] = self.lowbyte(self.mb[sp - 1])
        self.mb[0xff] += 1

    def optPUSHI(self, address):
        sp = self.mb[0xff]
        if sp > (0xff/2 - 2):
            self.dumpstack(self.mb)            
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
            self.dumpstack(self.mb)            
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
            self.dumpstack(self.mb)
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
        global Debug,  PrevPC
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
                safeprint("Stack: \n".join('%02x ' %
                      item for item in self.mb[0:self.mb[0xff]]))
            DissAsm(self.pc, 3, self)
        if cmd == CastPrintStr:
            i = address
            while self.memspace[i] != 0 and i < MAXMEMSP:
                c = self.memspace[i]
                if c == 0:
                    safeprint("Odd C is zero")
                if (c < 32 or c > 127) and (c != 10 and c != 7 and c != 27 and c != 30 and c!=9 and c!=8 ):
                    sys.stdout.write("%02x" % c)
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
                safeprint("%c" % v)
            else:
                sys.stdout.write(chr(v))
        if cmd == CastPrintStrI:
            i = self.getwordat(address)
            while self.memspace[i] != 0 and i < MAXMEMSP:
                c = self.memspace[i]
                if c == 0:
                    safeprint("0x0")
                if (c < 32 or c > 127) and (c != 10 and c != 7 and c != 30):
                    sys.stdout.write("%02x" % c)
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
        if current_context == None:
            sys.stdout.write("<Stopped>")
            return
        context=current_context     # For readability
        if cmd == CastSelectDisk:            # 20
            if context.DeviceHandle == None:
                context.DeviceHandle = "DISK%02d.disk" % address
            try:
                context.DeviceFile = open(context.DeviceHandle, "r+b")
                self.DiskPtr = 0
                context.DeviceFile.seek(0)
            except IOError:
                self.raiseerror(
                    "037 Error tying to open Random Device: %s" % context.DeviceHandle)
        if cmd == CastSelectDiskI:
            v = self.getwordat(address)
            if context.DeviceHandle == None:
                context.DeviceHandle = "DISK%02d.disk" % v
            try:
#                safeprint("Device Handle: %s set:" % context.DeviceHandle)
                context.DeviceFile = open(context.DeviceHandle, "r+b")
                self.DiskPtr = 0
                context.DeviceFile.seek(0,0)
            except IOError:
                self.raiseerror(
                    "037 Error tying to open Random Device: %s" % context.DeviceHandle)
        if cmd == CastSeekDisk:
            if context.DeviceHandle == None:
                self.raiseerror("038 Attempted to Seek without selecting Disk")
            self.DiskPtr = address*0x200
            context.DeviceFile.seek(self.DiskPtr)
        if cmd == CastSeekDiskI:
            v = self.getwordat(address)
            if context.DeviceHandle == None:
                self.raiseerror("038 Attempted to Seek without selecting Disk")
            self.DiskPtr = v*0x200
            context.DeviceFile.seek(self.DiskPtr)
        if cmd == CastWriteSector:
            if context.DeviceHandle == None:
                self.raiseerror("038 Attempted to write without selecting Disk")
            v = address
            if v < MAXMEMSP-0x1ff:
                block = self.memspace[v:v+512]
                context.DeviceFile.seek(self.DiskPtr)
                context.DeviceFile.write(bytes(block))
                self.DiskPtr =+ 0x200
                context.DeviceFile.flush()
            else:
                self.raiseerror(
                    "038 Attempted to write block larger than memory to storage")
        if cmd == CastWriteSectorI:
            v = self.getwordat(address)
            if context.DeviceHandle == None:
                self.raiseerror("038 Attempted to write without selecting Disk")
            if v < MAXMEMSP-0x1ff:
                block = self.memspace[v:v+512]
                context.DeviceFile.seek(self.DiskPtr)
                context.DeviceFile.write(bytes(block))
                self.DiskPtr =+ 0x200
                context.DeviceFile.flush()
            else:
                self.raiseerror(
                    "038 Attempted to write block larger than memory to storage")
        if cmd == CastSyncDisk:
            if context.DeviceHandle != None:
                context.DeviceFile.close()
                context.DeviceFile = open(context.DeviceHandle, "r+b")
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
            safeprint("\nEND of Run:(%d Opts)" % current_context.GlobalOptCnt)
            sys.exit(address)
        if cmd == CastDebugToggle:
           current_context.Debug = 0 if current_context.Debug else 1
        if cmd == CastStackDump:
            safeprint(" %04x:Stack:(%d):%s [" %
                             (PrevPC,self.mb[0xff]-1,CPU.FindWhatLine(PrevPC)), file=DebugOut,end="")
            for i in range(self.mb[0xff]-1):
                val = self.mb[i*2]+((self.mb[i*2+1])<<8)
                safeprint(" %04x" % (val),file=DebugOut,end="")
            safeprint(" ]",file=DebugOut)
        if cmd == CastTapeWriteI:
            if context.DeviceHandle != None:
                v=address
                if v < MAXMEMSP-0x1ff:
                    block=self.memspace[v:v+512]
                    context.DeviceFile.write(bytes(block))
                    context.DeviceFile.flust()
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
            justnum = ""
            for c in rawdata:
                if (c >= '0' and c <= '9') or (c == '-'):
                    justnum = justnum + c
            if (len(justnum) == 0):
                justnum="0"
            if int(justnum) < 65535 and int(justnum) >= -32767:
                CPU.putwordat(address, int(justnum))
            else:
                safeprint("Error: %s is not valid 16 bit number" % justnum,file=DebugOut)
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
            c = readchar.readkey()
            if not (c):
                c = ""
            self.putwordat(address, ord(c))
        if cmd == PollSetNoEcho:
            fd = sys.stdin.fileno()
            new = termios.tcgetattr(fd)
            new[3] = new[3] & ~termios.ECHO          # lflags
            EchoFlag = True
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, new)
            except:
                safeprint("TTY Error: On No Echo",file=DebugOut)
        if cmd == PollSetEcho:
            fd = sys.stdin.fileno()
            new = termios.tcgetattr(fd)
            new[3] = new[3] | termios.ECHO          # lflags
            EchoFlag = False
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, new)
            except:
                safeprint("TTY Error: On Echo",file=DebugOut)
        if cmd == PollReadCINoWait:
            c='\0'
            while True:
                c=get_key()
            self.putwordat(address,ord(c))            
        if current_context == None:
            safeprint("CPU Stopped")
            return
        if cmd == PollReadSector:
            if current_context.DeviceHandle != None:
                v=address
                if v <= MAXMEMSP-0x1ff:
#                    current_context.DeviceFile.seek(self.DiskPtr)
                    block = current_context.DeviceFile.read(512)
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
            if current_context.DeviceHandle != None:
#                v = self.getwordat(address)
                v = self.memspace[address]+(self.memspace[address+1] << 8)
#                print("Disk Read location %04x to buffer at: %04x" % (int(self.DiskPtr/0x200),v))
                if v <= MAXMEMSP-0x1ff:
#                    print("Disk Sector: %04x" % int(int(self.DiskPtr) / 0x200))
                    current_context.DeviceFile.seek(self.DiskPtr)
                    block = current_context.DeviceFile.read(512)
                    tidx = v
#                    j=0
                    for i in block:
                        self.memspace[tidx] = int(i) & 0xff
                        tidx += 1
#                        j += 1
#                        if ( j > 16):
#                            j=0
                else:
                    self.raiseerror("042 Attempted to read block with insuffient memory %04x < 0x4x" %(v,MAXMEMSP-0xff))
        if cmd == PollReadTapeI:
            if current_context.DeviceHandle != None:
                v=address
                block=current_context.DeviceFile.read(512)
                tidx=v
                if v<= MAXMEMSP-0x1ff:
                    for i in block:
                        self.memspace[tidx] = int(i) & 0xff
                        tidx += 1
                else:
                    self.raiseerror(
                        "043 Attempt to read Tape Block with insufficent memory")
        if cmd == PollRewindTape:
            if current_context.DeviceHandle != None:
                current_context.DeviceFile.seek(0)

        if cmd == PollReadTime:
            self.optPOPNULL(address)          # Most POLLs leave the Call CMD on stack to be poped.
            v32=int(time.time())              # But time returns 32bit value, so needs to do the popnull.
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

    def optSHR(self, unused):
        # SHR mean shift Right and set carry CF to equal current lowest bit
        R1 = self.fetchAcum(0)
        NCF = (1 if (R1 & 0x1 != 0) else 0) << 2
        R1 = R1 >> 1
        self.flags = (self.flags & 0xfffb) | NCF
        self.StoreAcum(0, R1)

    def optSHL(self, unused):
        # SHL mean shift Left and set carry CF to equal current Highest bit
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

    def evalpc(self, context: AssemblerContext):  # main evaluate current instruction at memeory[pc]
        global GPC, PrevPC
        pc = self.pc
        GPC = pc
        PrevPC=pc
        optcode = self.memspace[pc]
        context.GlobalOptCnt += 1
        if not (optcode in OPTLIST):
            self.raiseerror(
                "046 Optcode %s at File %s, Address( %04x ), is invalid:" % (optcode,self.FindWhatLine(pc),pc))
        if context.Debug > 0:
            DissAsm(pc, 1, self)
            watchfield = ""
            if context.watchwords:
                wfcomma = ""
                for wb in context.watchwords:
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
    global current_context
    result = 0

    if not isinstance(instr, str):
        return instr        # Already numberic just return as is.
    instr=instr.strip()
    if len(instr) < 3:
        # Too short to have a prefix, treat a pure decimal
        if instr.isdigit():
            result=int(instr)
        else:
            CPU.raiseerror("048 Short numeric string %s is not a valid decimal value" % instr)
    else:
        prefix=instr[:2].lower()
        if prefix == "0x":
            result = validatestr(instr,16)
        elif prefix == "0b":
            result = validatestr(instr, 2)
        elif prefix == "0o":
            result = validatestr(instr, 8)
        elif instr[0] == '"':  # Quoted character(s)
            result = ord(instr[1:2])
            if len(instr) > 3:
                result += ord(instr[2:3]) << 8
        elif instr[0].upper() in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            if instr in current_context.FileLabels:
                result = current_context.FileLabels[instr]
            else:
                CPU.raiseerror("047 Use of fixed value(%s) as label before defined." % instr)
        else:
            if instr.isdigit():
                result = validatestr(instr, 10)
            elif all(c in "0123456789ABCDEFabcdef" for c in instr):
                safeprint("Ambiguous value '%s': Looks like hex, but missing 0x prefix." % instr)
                result = validatestr("0x"+instr,16)
            else:
                CPU.raiseerror("048 String %s is not a valid decimal value" % instr)

    return int(result) & 0xffffffff
        


def Str2Byte(instr):
    # Just use the Str2Word and keep the lowest byte
    return Str2Word(instr) & 0xff


def DissAsm(start, length, CPU):
    # The DissAsm is not really required for interpitation of the code, but is a usefull tool for debugging
    # The need for the CPU.json file is just used by this module, (and debugger) so a 'speed optimized'
    # version of the code would not need CPU.json at all.
    #
    global DebugOut, OPTDICT, InputFileData, current_context
    i = start

    context=current_context

    endstop=start+length
    P1=0
    PI=0
    PII=0
    while i < endstop:
        OUTLINE = ""
        FoundLabels = ""
        optcode = CPU.memspace[i]
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
        if CPU.mb[0xff] > 0 and addr <= 0xfe:
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
        Group1 = getkeyfromval(i, context.FileLabels).strip()
        FoundLabels += " " + Group1
        # File labels for existing optcode argument
        if P1 != 0:
            Group2=getkeyfromval(P1,context.FileLabels)
            FoundLabels += " " + Group2
        if PI != 0:
            Group3 = getkeyfromval(PI, context.FileLabels).strip()
            FoundLabels += " " + Group3
        FoundLabels=Sort_And_Combine_Labels(FoundLabels)
        FoundLabels = CPU.FindWhatLine(i)+" " + FoundLabels

        if (optcode in OPTLIST):
            OUTLINE = "%04x:%8s P1:%04x [I]:%04x [II]:%04x TOS[%04x,%04x] Z%1d N%1d C%1d O%1d SS(%d)" % \
                (i, OPTSYM[optcode], P1, PI, PII,
                 tos, sft, ZF, NF, CF, OF, addr)
        if FoundLabels != "":
            OUTLINE += " # "+FoundLabels
        if not (optcode in OPTLIST):
            bestmatch = 0xffff
            bestmatchcode=""
            for name, iaddr in context.FileLabels.items():
                if isinstance(iaddr,int):
                    if iaddr > i and iaddr < bestmatch:
                        bestmatch=iaddr
                        bestmatchcode=name
            safeprint("DATA-Segment:")
            hexdump(i,max(min(i+255,bestmatch),i+15),CPU)
#            print("Label : %s" % bestmatchcode)
            i = bestmatch
        else:
            i = i + OPTDICT[str(optcode)][2]
        rstring = ""
        # When debugging we might setup some Watchs for changes in known memory locations.
        if len(context.watchwords) > 0:
            rstring = "Watch:"
            lastad = 0
            for ii in context.watchwords:
                if (lastad + 1) != ii:
                    rstring = rstring + "%04x:[%02x]" % (ii, CPU.memspace[ii])
                else:
                    rstring = rstring + "[%02x]" % (CPU.memspace[ii])
                lastad = ii
                rstring += "SD:(%d)" % CPU.mb[0xff]

        safeprint("%s %s" % (OUTLINE, rstring),file=DebugOut)
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
    safeprint("Range is %04x to %04x" % (startaddr, endaddr))
    
    base = startaddr & ~0xF  # align to 16-byte row start
    offset = startaddr % 16

    # Print header from current offset to end of row
    header = "    " + " ".join(f"{x:02x}" for x in range(offset, 16))
    safeprint("  %s" % header)

    i = base
    while i < endaddr:
        Fstring = "%04x: " % i
        sys.stdout.write(Fstring)

        # Hex output
        for j in range(16):
            addr = i + j
            if addr < startaddr or addr >= endaddr or addr >= len(CPU.memspace):
                sys.stdout.write("   ")  # blank space
            else:
                sys.stdout.write("%02x " % CPU.memspace[addr])
        
        sys.stdout.write("  ")

        # ASCII output
        for j in range(16):
            addr = i + j
            if addr < startaddr or addr >= endaddr or addr >= len(CPU.memspace):
                sys.stdout.write(" ")
            else:
                c = CPU.memspace[addr]
                if (c != 0x7f) and (((c & 0xc0) == 0x40) or ((c & 0xe0) == 0x20)):
                    sys.stdout.write("%c" % c)
                else:
                    sys.stdout.write("_")
        
        i += 16
        safeprint(" ")

        
def hexdumpold(startaddr, endaddr, CPU):
    safeprint("Range is %04x to %04x" % (startaddr, endaddr))
    i = startaddr
    header = "0  .  .  .  .  5  .  .  .  .  A  .  .  .  .  F  .  .  .  .  5  .  .  .  .  A  .  .  .  .  F"
    header = header[(startaddr % 16)*3:][0:47]
    safeprint("       %s" % header)
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
        safeprint(" ")

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
    safeprint("Import Filename error, %s not found" % (filename),file=DebugOut)
    sys.exit(-1)


# This is how we tell if a label been defined as global for local for library inserts.
def IsLocalVar(inlabel,  context: AssemblerContext):
    # The structure is that GlobeLabels if they match inlabel will always override the dynamic locallabels.
    # So to define a Globale, just add it to GlobeLabels, but it should become part of FileLabels until
    # really defined...ie with an '=' or a ':' code.

    if inlabel in context.GlobeLabels:
        return inlabel
    else:
        if context.LORGFLAG == LOCALFLAG:
#            return inlabel + "___" + str(context.LocalID) +"."+ str(context.UniqueLineNum)
            return inlabel + "___" + str(context.LocalID)
        else:
            return inlabel


def ReplaceMacVars(line,  filename, context: AssemblerContext):
    global MacroStack, Debug, LastMLen
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
            if (line[i:i+6] == "STRLEN"):
                # Adding MS Macro concept of 'string len' for macros.
                # Notation is %STRLEN symbol, saves most recent result in %%LEN
                (tempkey,tempsize) = nextword(line[i+6:])
                tempkey=ReplaceMacVars(tempkey, filename, context)
                if tempkey[0] == '"' and tempkey[-1] == '"':
                    tempkey=tempkey[1:-1]
                LastMLen=len(tempkey)
                i=i+6+tempsize            
            elif (line[i:i+1] == "P"):
                # POP value from refrence stack...does not change newline
                if context.Debug > 1:
                    safeprint("Pop From MacroStack(%s,%s)" % (MacroStack,line[i:]),file=DebugOut)
                if (not MacroStack):
                    CPU.raiseerror(
                        "049 Macro Refrence Stack Underflow: %s" % line)
                i += 1
                MacroStack.pop()
                continue
            elif (line[i:i+1] == "S"):
                # Stores the current %0 value to refrence stack
                # Does not change the newline
                MacroStack.append(context.MacroVars[context.varcntstack[context.varbaseSP]])
                if context.Debug > 1:
                    safeprint("Push to MacroStack(%s,%s) Depth: %s" % (MacroStack,line[i:], len(MacroStack)),file=DebugOut)
                i += 1
                continue
            elif (line[i:i+1] == "V"):
                # Insert into newline value that top of refrence stack...do not pop it
                if context.Debug > 1:
                    safeprint("Refrence top of MacroStack(%s,%s,[%d])" % (MacroStack,line,i),file=DebugOut)
                if (not MacroStack):
                    CPU.raiseerror(
                        "050 Macro Refrence Stack Underflow: %s at %s:%s" % (line,filename,context.FileLineNum))
                newline = newline + MacroStack[-1]
                i += 1
                continue
            elif (line[i:i+1] == "W"):
                # Insert into newline value that is second from top of refrense stack, do not pop it.
                if context.Debug > 1:
                    safeprint("Refrence second from top of MacroStack(%s,%s,[%d])" % (MacroStack,line,i),file=DebugOut)
                if (not MacroStack or len(MacroStack) < 2 ):
                    CPU.raiseerror(
                        "051 Macro Refrence Stack Underflow: %s" % line)
                newline = newline + MacroStack[-2]
                i += 1
            elif (line[i:i+4] == "%LEN"):
                newline = newline + str(LastMLen)
                i += 4
            elif (line[i:i+1] >= "0" and line[i:i+1] <= "9"):
                varval = int(line[i:i+1])
                if len(context.MacroVars) < varval:
                    CPU.raiseerror(
                        "052 Macro %v Var %s is not defined" % (varval, line))
                newline = newline+context.MacroVars[context.varcntstack[context.varbaseSP] + varval]
                i = i + 1
        else:
            newline = newline + c
    return newline

# Our two pass assembly is very limited on what it can handle on the 2nd pass.
# Basicly, if a value (with possible +/- modifier) does NOT take up a word of memory in the final
# code, and only is a 'value' used by the assembler. Then it CAN NOT be defered for a second pass.
# We need that 'word' of storage to hold temporary values that will later be replaed. All other
# values (such as when labels are themselves used a +/- modifiers) must resolve durring 1st pass.
def FirstPassVal(instr,  context: AssemblerContext):
    (value, size) = nextword(instr[1:])
    firstch=value[0:1]
    if firstch == "$":
        value=context.address
    elif firstch.upper() >= "A" and firstch.upper() <= "Z":
        if value[0:] in context.FileLabels.keys():
            value=Str2Word(context.FileLabels[IsLocalVar(value[0:], context)])
        else:
            CPU.raiseerror(
                "055 Line %s, : %s Can not use label that is yet definied in first pass of assembler." %
                           (context.GlobalOptCnt, value))
    else:
        value=Str2Word(value)
    return (value, size)

# This is a newer version of the core work item in DecodeStr but cocentrating on number processing


import re

def parse_expression(expr):
    """
    Splits expression into (prefix, base_expr, modifiers[]).
    Example: '$$label+4-0x10' -> ('$$', 'label', ['+4', '-0x10'])
    """
    expr = expr.strip()
    prefix_match = re.match(r'^(\${1,3})', expr)
    prefix = prefix_match.group(1) if prefix_match else ''
    rest = expr[len(prefix):]

    tokens = []
    current = ''
    i = 0
    while i < len(rest):
        if rest[i] in '+-' and i > 0:
            tokens.append(current)
            current = rest[i]
        else:
            current += rest[i]
        i += 1
    tokens.append(current)

    base_expr = tokens[0]
    modifiers = tokens[1:]
    return prefix, base_expr, modifiers


def decode_token(token, curaddress, CPU,  JUSTRESULT, context: AssemblerContext):
    """
    Decodes a single token — either a literal or label.
    """

    token = token.strip()
    
    # Handle quoted string
    if token.startswith('"') and token.endswith('"'):
        if JUSTRESULT:
            safeprint("String Values can't be modified with offsets:%s" % (token), file=DebugOut)
            return 0
        for c in token[1:-1]:
            CPU.memspace[curaddress] = ord(c)
            curaddress += 1
        return ("string", curaddress)

    # Determine base for numeric literal
    base = 10
    value = None
    if token.startswith(('0x', '0X')):
        base = 16
        token = token[2:]
    elif token.startswith(('0b', '0B')):
        base = 2
        token = token[2:]
    elif token.startswith(('0o', '0O')):
        base = 8
        token = token[2:]

    try:
        value = int(token, base)
        return ("value",value)
    except ValueError:
        pass  # not a numeric constant — try label

    # Determine if it's a label
    labelname = token
    modval = 0
    if labelname in context.FileLabels:
        return ("value",Str2Word(context.FileLabels[labelname]))
    localkey = IsLocalVar(labelname, context)
    if localkey in context.FileLabels:
        return ("value",Str2Word(context.FileLabels[localkey]))
    else:
        # Unresolved label — mark for second pass
        newkey = localkey
        context.FWORDLIST.append([newkey, curaddress, 0, f"{context.ActiveFile}:{context.FileLineNum}"])
        return ("value",0)


def DecodeStr(instr, curaddress, CPU,  JUSTRESULT, context: AssemblerContext):

   # 📌 Direct string handling (base case, no parsing)
    if instr.startswith('"') and instr.endswith('"') and not JUSTRESULT:
        context = instr[1:-1]
        for c in context:
            CPU.memspace[curaddress] = ord(c)
            curaddress += 1
        return curaddress
    elif instr.startswith('"') and JUSTRESULT:
        safeprint("String values can't be modified or used as numeric results", file=DebugOut)
        return 0

    prefix, base_token, modifiers = parse_expression(instr)

    # Evaluate base token
    base_result = decode_token(base_token, curaddress, CPU, JUSTRESULT,  context)
    if isinstance(base_result, tuple) and base_result[0] == "string":
        return base_result[1]
    
    result = base_result if not isinstance(base_result, tuple) else base_result[1]

    # Apply modifiers
    for mod in modifiers:
        sign = 1 if mod[0] == '+' else -1
        base_mod=decode_token(mod[1:], curaddress, CPU, JUSTRESULT, context)
        # Should always be a truple but also should always be numeric.
        if base_mod[0] != "value":
            safeprint("Unexpected mix of strings and numbers.: %s" % (mod[1:]), file=DebugOut)
            return 0
        mod_val = base_mod[1]
        result += sign * mod_val

    if JUSTRESULT:
        return result

    # Memory writing based on prefix
    # $$ => byte (8bit)
    # $$$ -> long (32bit)
    # $ or none -> word (16 bit, default)
    assert prefix in ('', '$', '$$', '$$$'), f"Unexpected size prefix: {prefix}"
    if prefix == '$$':
        CPU.memspace[curaddress] = result & 0xFF
        curaddress += 1
    elif prefix == '$$$':
        CPU.memspace[curaddress]     = result & 0xFF
        CPU.memspace[curaddress + 1] = (result >> 8) & 0xFF
        CPU.memspace[curaddress + 2] = (result >> 16) & 0xFF
        CPU.memspace[curaddress + 3] = (result >> 24) & 0xFF
        curaddress += 4
    else:  # default or $ (2-byte)
        CPU.memspace[curaddress]     = result & 0xFF
        CPU.memspace[curaddress + 1] = (result >> 8) & 0xFF
        curaddress += 2

    return curaddress

# Load file is also the effective main loop for the assembler


# def loadfile(filename, offset, CPU, LorgFlag,  LocalID, context: AssemblerContext):

def loadfile(filename, offset, CPU, LorgFlag,  LocalID, context: AssemblerContext):
    global FileLineData
    prior_lorgflag = context.LORGFLAG
    prior_localid = context.LocalID
    prior_activefile = context.ActiveFile
    context.LORGFLAG = LorgFlag
    context.LocalID = LocalID
    context.FileLineNum = 1
    if context.Debug > 1:
        if  context.LORGFLAG == LOCALFLAG:
            safeprint("LOCAL:",end="",file=DebugOut)
        else:
            safeprint("Global:",end="",file=DebugOut)
        safeprint("FileLoad Start: %s Addr: %04x" % (filename, offset),file=DebugOut)
    context.ActiveFile = filename
    context.address = int(offset)
    line = "#Start"
    context.backfill = ""
    context.highaddress = offset
    context.ExpectData = 0                   # Used as flag and counter when seperate datasegment is in use.
    wfilename = fileonpath(filename)
    with open(wfilename, "r") as infile:
        if context.address > context.highaddress:
            context.highaddress = context.address
        context.FBYTELIST = []
        context.ActiveMacro = False
        varcnt = 0
        context.varbaseSP = 0
        context.varbaseNext = 0
        context.varcntstack = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#        context.SkipBlock = 0
        varcnt = 0
        context.MacroLine = ""
        varpos = 0
        if context.Debug > 1:
            safeprint("Reading Filename %s" % wfilename,file=DebugOut)
        while True:
            if context.ActiveMacro and line == "":
                # If we are inside a Macro expansion keep reading here, until the macro is fully consumed.
                if len(context.MacroLine) > 0:
                    NewLine = {"M."+context.ActiveMacroName+" "+filename + ":" +
                    str(context.FileLineNum): context.address}
                    context.FileLabels.update(NewLine)

                    (PosParams, PosSize) = nextwordplus(context.MacroLine)
                    while (PosParams != "" and PosParams != "ENDMACENDMAC"):
                        context.MacroLine = context.MacroLine[PosSize:]
                        line = line + " " + PosParams
                        (PosParams, PosSize) = nextwordplus(context.MacroLine)


                    # at this point line should contain the macro and its possible parameters
                    # Need to subsutute and %# that are not in quotes with varval
                    line = ReplaceMacVars(line, filename, context)
                    if context.Debug > 1:
                        safeprint("Expanded Macro: %s(%40s)" % (line,context.MacroLine),file=DebugOut)
                    context.varbaseNext = context.varbaseSP
                    context.varbaseSP -= 1 if context.varbaseSP > 0 else 0
                    if PosParams == "ENDMACENDMAC":
                        # As macro's may call other macros, we need to mark in the stream where they end.
                        context.MacroLine = context.MacroLine[PosSize:]
                    if context.Debug > 1:
                        safeprint("End-Macro: [:]%s" % context.backfill,file=DebugOut)
                    line = line + " " + context.backfill
                    context.backfill = ""
                    context.ActiveMacro = False
                else:
                    line = context.backfill
                    if context.Debug > 1:
                        safeprint("End-Macro: [:]%s" % context.backfill,file=DebugOut)
                    context.backfill = ""
                    context.ActiveMacro = False
                    continue
            else:
                # If we are macro, or in plain text, we still end up here.                
                if line == "":
                    ExitOut = False
                    GetAnother = True
                    context.CurrentLineBeingParsed = context.FileLineNum                    
                    while GetAnother:
#                        if filename == "foo9.asm":
#                            safeprint("Line:",context.FileLineNum)
                        context.FileLineNum += 1
                        context.UniqueLineNum += 1
                        GetAnother = False
                        inline = infile.readline()
                        if context.Debug > 1 and context.SkipBlock == 0:
                            safeprint("%s:%s> %60s:%2d" % (wfilename,str(context.FileLineNum),inline,context.SkipBlock), file=DebugOut)

#                        print("Inserting Label: Filename: %s, %d, %04x" % (filename,context.CurrentLineBeingParsed, context.address))
#                        if context.address not in context.AddressedLinesSeen:
                        FileLineData.add_entry(filename, context.CurrentLineBeingParsed, context.address)
                        context.AddressedLinesSeen.add(context.address)
#                        if not (context.address in context.FileLabels):
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
                    if context.Debug > 1 and context.SkipBlock == 0:
                        safeprint("%04x: %s:%2d" % (context.address, line,context.SkipBlock),file=DebugOut)
                    if ExitOut:
                        break
            line = removecomments(line).strip()
            if context.Debug > 1:
                if context.ActiveMacro == False and context.SkipBlock == 0:
                    safeprint("%04x: %s> %s" % (context.address, context.FileLineNum, line),file=DebugOut)
                elif context.SkipBlock == 0:
                    safeprint("%04x: M-%s> %s : %s" %
                          (context.address, context.FileLineNum, line, context.MacroLine[:16]),file=DebugOut)
                else:
                    safeprint("Skip.%s(%s)," % (filename, line[:5]),file=DebugOut,end="")

            if context.SkipBlock != 0:                
                while (line != ""):
                    (key, size) = nextword(line)
                    # Because it's not a single letter command, ENDBLOCK is a bit of a outsider.
                    # We allow embeded !/ENDBLOCK blocks, so we need to scan for three states
                    # 1: Are we going down another depth of !'s
                    # 2: Did we find an 'inner' ENDBLOCK
                    # 3: Anything that's not outer ENDBLOCK is skipped.
                    if key == "!" or key == "?":
                        # Handle embeded or nested Blocks
                        context.SkipBlock = context.SkipBlock + 1
                        line = line[size:]
                        continue
                    elif key != "ENDBLOCK":
                        line = line[size:]
                        continue
                    else:
                        context.SkipBlock = context.SkipBlock - 1
                        if context.SkipBlock <= 0:
                            line = line[size:]
                            context.SkipBlock=0
                            break
                        else:
                            line = line[size:]
                            continue
                continue
            elif line[:8] == "ENDBLOCK":
                line = line[8:]
                continue
#            if context.FileLineNum == 212 and filename == "tests/forth.asm":
#               safeprint("Break here:%s:",filename)            
            if len(line) > 0:
                IsOneChar = False
                if len(nextword(line)[0]) == 1:
                    IsOneChar = True
                if line[0] == "@":
                    # Use a defined Macro Remain words on line will become local variables
                    cpos = 1
                    # Logic of context.varcntstack:
                    # Initial vcs[0]==0, so vcs[1] should = # vars + 1
                    # So we alway set the n' top of vcs to vcs[n]+#vars in this macro
                    (macname, size) = nextword(line[cpos:])
                    context.varbaseSP = context.varbaseNext
                    context.MacroVars[context.varcntstack[context.varbaseSP]] = "__" + \
                        create_new_unique() + str(len(context.MacroData))

                    cpos += size
                    if macname in context.MacroData:
                        # To understand what's going on here: We are making a stack that will
                        # store the local macro var values (%1-max) and macros that call other
                        # macros will just use a diffrent range in that same stack.
                        context.MacroLine = context.MacroData[macname] + \
                            " ENDMACENDMAC " + context.MacroLine
                        if cpos < len(line):
                            varcnt = 0
                            for i in range(context.MacroPCount[macname]):
                                (key, size) = nextwordplus(line[cpos:])
                                varcnt += 1
                                while (context.varcntstack[context.varbaseSP]+varcnt + 2) >= len(context.MacroVars):
                                    context.MacroVars.append(['0'])
                                context.MacroVars[varcnt +
                                          context.varcntstack[context.varbaseSP]] = key
                                cpos += size
                            if varcnt < context.MacroPCount[macname]:
                                # When Macro was defined we counted the max %# and now require that # Parms
                                CPU.raiseerror("053 Insufficent required parameters (%s/%s) for Macro %s" %
                                               (varcnt, context.MacroPCount[macname], macname))
                        context.varcntstack[context.varbaseSP +
                                    1] = context.varcntstack[context.varbaseSP]+varcnt + 1
                        context.varbaseNext = context.varbaseSP + 1
                        context.ActiveMacro = True
                        context.ActiveMacroName = macname
                        context.backfill = line[cpos:] + " " + context.backfill
                        line = ""
                    else:
                        safeprint("Missing: ", macname,file=DebugOut)
                        CPU.raiseerror(
                            "054  Macro %s is not defined" % (macname))
                # Here is were we start the 'switch case' looking for commands.
                elif line[0] == ":":
                    # The ":" is a label whos value is current address
                    (key, size) = nextword(line[1:])
                    newitem = IsLocalVar(key, context)
                    if context.Debug >1:
                        safeprint(">>> adding %s at location %s with name: %s" %
                              (newitem, hex(context.address),IsLocalVar(newitem,  context)),file=DebugOut)

                    context.FileLabels.update({newitem:context.address})
                    UpdateVarHistory(newitem,context.address,context.address)
                    line = line[size+1:]
                    continue
                elif line[0] == ";":
                    # The ';' version uses the DATA address but also requires 2 paramater the lable and size/string
                    (key, size) = nextword(line[1:])
                    line = line[size+1:]
                    (dsize,size) = nextword(line)
                    line = line[size:]
                    if context.DataSegment != -1:
                        # If context.DataSegment was defined, the we use a seperate dataaddress counter
                        workingaddress=context.dataaddress
                        context.ExpectData=Str2Word(dsize)   # Defines how many bytes to expect goes into the dataaddress
                    else:
                        context.ExpectData=0
                    if ("F."+filename+":"+str(context.FileLineNum) in context.FileLabels):
                        # We created an internal label for each line number, but this label will replace it.
                        del context.FileLabels["F."+filename+":"+str(context.FileLineNum)]
                    newitem = {IsLocalVar(key,  context): workingaddress}
                    context.FileLabels.update(newitem)
                    UpdateVarHistory(newitem,workingaddress,workingaddress)

                elif line[0] == "=":
                    (key, size) = nextword(line[1:])
                    line = line[size+1:]
                    (value, size) = nextwordplus(line)
                    if (not (value[0:len(value)].isdecimal())):
                        value = DecodeStr(value, context.address, CPU, True, context)
                    newitem=IsLocalVar(key, context)
#                    safeprint("Setting Fixed Value: %s to %s: %s:line: %s(%s)\n" % ( newitem, value, filename,line, context.FileLineNum))
                    context.FileLabels.update({newitem: value})
                    UpdateVarHistory(newitem,value,context.address)
                    line = line[size:]
                    continue
                elif ( line[0] == "." and IsOneChar) or line[:4].upper() == ".ORG":
                    if line[:4].upper() == ".ORG":
                        line=line[4:]
                    else:
                        line=line[1:]
                    (value, size) = FirstPassVal(line,  context)
                    line = line[size+1:] # at this point value is #val of 1st label or constant.
                    # We should also allow labeld or constant values be modified with +/- another label or constant
                    if line[0:1] == "+" or line[0:1] == "-":
                        (modvalue,size) = FirstPassVal(line, context)
                        if (line[0:1] == "+"):
                            value = Str2Word(value) + Str2Word(modvalue)
                        else:
                            value = Str2Word(value) - Str2Word(modvalue)
                        line = line[size+1:]    # if there was a second label or constant bump up line past it.
                    context.address = Str2Word(value)
                    context.Entry = context.address
                    continue

                elif ( line[:5].upper() == ".DATA" ):
                    line=line[5:]
                    (Value, Size) = FirstPassVal(line, context)
                    context.DataSegment = value
                    context.dataaddress = context.DataSegment
                    line=line[size+1:]
                    continue
                elif line[0] == "L" and IsOneChar:
                    # Load a file into memory as a library, enable 'local' variables.                    
                    (newfilename, size) = nextword(line[1:])
                    HoldGlobeLine = context.FileLineNum
                    oldfilename = context.ActiveFile
                    NewLocalID = str(context.UniqueLineNum)+newfilename
                    context.highaddress = context.address = \
                        loadfile(newfilename, context.address, CPU , LOCALFLAG, NewLocalID, context)
                    context.ActiveFile = oldfilename
                    context.FileLineNum = HoldGlobeLine
                    line = line[size+1:]
                    continue
                elif line[0] == "I" and IsOneChar:
                    # Load a file, but keep it in the 'global' context
                    (newfilename, size) = nextword(line[1:])
                    HoldGlobeLine = context.FileLineNum
                    oldfilename = context.ActiveFile
                    NewLocalID = str(context.UniqueLineNum)+newfilename
                    # May need come back here and use context.LORGFLAG rather than GLOBALFLAG..test this.
                    context.highaddress = context.address = \
                        loadfile(newfilename, context.address, CPU , GLOBALFLAG, NewLocalID, context)
                    context.ActiveFile = oldfilename
                    context.FileLineNum = HoldGlobeLine
                    line = line[size+1:]
                    continue
                elif line[0] == "P" and IsOneChar:
                    # "P" Print debug messages durring assembly.
                    nline=""
                    for word in line[2:].split(" "):
                        PosVar=FindLabelMatch(word.strip(),context)
                        if (PosVar != None):
                            nline=f"{nline} {word.strip()}:{PosVar} "
                        else:
                            nline=f"{nline} {word.strip()} "
                    safeprint("%04x: %s" % (context.address, nline),file=DebugOut)
                    line = ""
                    continue
                elif line[0] == "!" and IsOneChar:    # If Macro does NOT exist, then eval until matching ENDBLOCK
                    (key, size) = nextword(line[1:])
                    if key in context.MacroData:
                        context.SkipBlock =+ 1
                    line = line[size+1:]
                    continue
                elif line[0] == "?" and IsOneChar:     # If Macro exists, then skip until next ENDBLOCK
                    L=nextword(line[1:])
                    key=L[0]
                    size=L[1]
                    if key in context.MacroData:
                        L=1
                    else:
                        context.SkipBlock += 1
                    line = line[size+1:]
                elif line[0] == "M" and IsOneChar:
                    # Macros
                    # name word word %v word
                    (key, size) = nextword(line[1:])
                    # We identify how many arguments are used, by the max pcount value. (0-9)
                    # %0 doesn't count as that sys generated, and %'s do not count if quoted
                    # Minit state engine. var_num is next 0-9 after % unless '\' preceded %
                    context.MacroData.update({key: line[size:]})
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
                    context.MacroPCount.update({key: pcount})
                    line = ""
                    continue
                elif line[0:2] == "MF" and not(IsOneChar):
                    # MF Macro is for setting, or freeing single value macros. For use as flags
#                    print("MF Parse: Before(%s) " % line,end="")
#                    print(" Step1: %s (%s)" % (key,line[size+1:]),end="")
#                    print(" Step2: %s (%s)" % (value, line[size:]))
                    (key,size) = nextword(line[2:])
                    line = line[size+1:] if line[size+1:size+2] == " " else line[size:]
                    (value,size) = nextword(line)
                    line = line[size+1:] if line[size+1:size+2] == " " else line[size:]                    
                    if (value == '""'):
                        # empty string, erase existing macro named key, if any
                        context.MacroData.pop(key,None)
                        context.MacroPCount.pop(key,None)
                    else:
                        # Otherwise inerset a simple one word or value to enable the MacroKey
                        context.MacroData.update({key: value})
                        context.MacroPCount.update({key: 0})
                elif line[0] == "G" and IsOneChar:
                    # Globale labels are an override of 'Local' Labels by 'pre-defining them.
                    (key, size) = nextword(line[1:])
                    context.GlobeLabels.update({key: context.address})
                    line = line[size+1:]
                    continue
                else:
                    # Pretty much every else drops here to be evaulated as numbers or macros to be defined.
                    # Note than nearly everything here will take up some sort of storage, so address will
                    # be incremented. This is where labels become 'variables'
                    context.CurrentLineBeingParsed = context.FileLineNum
                    (key, size) = nextwordplus(line)
                    line = line[size:]
                    if context.address > context.highaddress:
                        context.highaddress = context.address
                    if len(key) > 0:
                        if context.ExpectData > 0:
                            # We do this because after we define a custom dataaddress constant
                            # we may have a mix of values that will act as the initialization fill
                            # for that defined space. It might be made of more than one word
                            # do we keep subtracting from ExpectData until we've filled it all.
                            prevval=context.dataaddress
                            context.dataaddress = DecodeStr(key, dataaddress, CPU, False,  context)
                            context.ExpectData -= (context.dataaddress - prevval)
                        else:
                            context.address = DecodeStr(key, context.address, CPU, False, context)
        for store in context.FWORDLIST:
            key = store[0]
            vaddress = store[1]
            if key in context.FileLabels.keys():
                v = Str2Word(context.FileLabels[key])
                if (len(store) > 2):
                    if store[2] != 0:
                        v = v + Str2Word(store[2])
                        # This extra bit logic handles the case of labels+## math.
                CPU.memspace[int(vaddress)] = CPU.lowbyte(v)
                CPU.memspace[int(vaddress + 1)] = CPU.highbyte(v)
            elif key in context.GlobeLabels.keys():
                v = Str2Word(context.GlobeLabels[key])
                if (len(store) > 2):
                    if store[2] != 0:
                        v = v + Str2Word(store[2])
                        # This extra bit logic handles the case of labels+## math.
                CPU.memspace[int(vaddress)] = CPU.lowbyte(v)
                CPU.memspace[int(vaddress + 1)] = CPU.highbyte(v)
            else:
                print(key, " is missing (SYM,ADDR,Delta,LineNum)", store,key,vaddress,file=DebugOut)
    if context.Debug > 1:
        i = 0
    if context.address > context.highaddress:
        context.highaddress = context.address
    if context.dataaddress > context.highaddress:
        highaddress = context.dataaddress
    context.LORGFLAG = prior_lorgflag
    context.LocalID = prior_localid
    context.ActiveFile = prior_activefile
    return context.highaddress


def debugger(passline, context: AssemblerContext):
    global InDebugger, breakpoints, tempbreakpoints, EchoFlag
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
            safeprint("processing %s\n" % passline)
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
                safeprint("TTY Error: On Echo On")
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
                if thisword in context.FileLabels:
                    varval = FindHistoricVal(thisword, CPU.pc, context)
                    arglist.append(varval)
                    argcnt += 1
                    safeprint("%s found: %04x" % (thisword, varval))
                else:
                    varval = FindLabelMatch(thisword, context)
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
            safeprint("Range of DissAsmby %04x - %04x" % ( startrange, stoprange))
            stoprange = DissAsm(startrange, stoprange - startrange, CPU)
            continue
        if cmdword == "ps":
            if (CPU.mb[0xff] == 0):
                safeprint("Empty Stack")
                continue
            safeprint("Print HW Stack, Depth (%d)" % CPU.mb[0xff])
            for i in range(0, min(CPU.mb[0xff]*2, 64), 2):
                v = CPU.mb[i] + (CPU.mb[i+1] << 8)
                SInfo = "%04x:" % v
                if (v > 0 and v < (len(CPU.memspace)-2)):
                    SInfo = SInfo+"[%0x]" % CPU.getwordat(v)
                    SInfo = SInfo+"[[%0x]]" % CPU.getwordat(CPU.getwordat(v))
                else:
                    SInfo = SInfo + "[*]"
                safeprint(SInfo)
                continue
        if cmdword == "spush":
            if argcnt > 0:
                if (CPU.mb[0xff] > (0xff/2 -2)):
                    safeprint("Stack full")
                    continue
                if (arglist[0] & 0xfffff) < 0xffff:
                    CPU.optPUSH(arglist[0])
                else:
                    safeprint("Invalid number:")                    
                continue
            else:
                safeprint("Need an argument")
                continue
        if cmdword == "spop":
            if argcnt == 0:
                safeprint("POPNULL")
                CPU.optPOPNULL(0)
                continue
            else:
                if (arglist[0] & 0xfffff) > 0xffff:
                    safeprint("Not valid address:")
                    continue
                CPU.optPOPI(arglist[0])
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
                   safeprint(SInfo)
            else:
                safeprint("ERR: Need to specify what to print")
                continue
        if cmdword == "pa":
            # Filter labels
            filtered_labels = {
                key: value for key, value in context.FileLabels.items()
                if not key.startswith("_") and not key.startswith("F.") and not key.startswith("M.")
            }

            # Step 1: Collect rows based on rawlist filtering
            import re
            rows = []
            for key, value in filtered_labels.items():
                value_str = str(value)
                if not rawlist or any(re.search(pattern, key) or re.search(pattern, value_str) for pattern in rawlist):
                    rows.append((key, f"{int(value):04x}"))

            # Step 2: Determine column widths
            name_width = max(len("Name"), max(len(k) for k, _ in rows)) if rows else len("Name")
            value_width = max(len("Value"), max(len(v) for _, v in rows)) if rows else len("Value")

            # Step 3: Build the table
            table = f"| {'Name'.ljust(name_width)} | {'Value'.ljust(value_width)} |\n"
            table += f"|{'-' * (name_width + 2)}|{'-' * (value_width + 2)}|\n"
            for key, val in rows:
                table += f"| {key.ljust(name_width)} | {val.ljust(value_width)} |\n"

            safeprint(table)
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
                                        if (L[0] in context.FileLabels.keys()):
                                            newval = Str2Word(
                                                context.FileLabels[L[0]])
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
                                    safeprint("Input %s not valid" % cmdline)
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
            startaddr = None
            stopaddr = None
            if argcnt > 0 or len(rawlist) > 0:
                tresult = CPU.FindAddressLine(rawlist[0])
                if tresult is None:
                    safeprint("Start line not valid or is ambiguous: %s" % rawlist[0])
                else:
                    (_, _, startaddr)=tresult
                if argcnt > 1:
                    tresult=CPU.FindAddressLine(rawlist[1])
                    if tresult == None:
                        safeprint("End Line is not valid or is ambiguous: %s" % rawlist[1])
                    else:
                        (_, _, stopaddr)=tresult
            else:
                startaddr = CPU.pc  # Default to current PC
                stopaddr = (startaddr + 30) & 0xffff

            # If only start address found, compute default end
            if startaddr is not None and stopaddr is None:
                stopaddr = (startaddr + 30) & 0xffff

                # Validate range
            if startaddr is not None and stopaddr is not None:
                if stopaddr < startaddr:
                    stopaddr = startaddr + abs(stopaddr)
                elif stopaddr == startaddr:
                    stopaddr = (startaddr + 30) & 0xffff

                DissAsm(startaddr, stopaddr - startaddr, CPU)
            else:
                safeprint("Unable to disassemble; start or end address not resolved.")
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
                safeprint("ERR: Need to specify what to print")
                continue
        if cmdword == "hexi":
            if argcnt > 0:
                if argcnt == 1:
                    startv = CPU.getwordat(int(arglist[0]))
                    stopv = startv + 16
                else:
                    startv = CPU.getwordat(int(arglist[0]))
                    stopv = int(arglist[1]) + 1
                    if stopv < startv:
                        stopv = startv + stopv + 1
                hexdump(startv, stopv, CPU)
            else:
                safeprint("ERR: Need to specify what to print")
                continue
        if cmdword == "n":
            stepcnt = 1
            stoprange = 0
            if argcnt > 0:
                stepcnt = arglist[0]
            for i in range(stepcnt):
                CPU.evalpc(context)
                DissAsm(CPU.pc, 1, CPU)
                if CPU.pc in breakpoints or CPU.pc in tempbreakpoints:
                    safeprint("Break Point %04x" % CPU.pc)
                    if CPU.pc in tempbreakpoints:
                        tempbreakpoints.remove(CPU.pc)
                    break
            continue
        if cmdword == "s":
            CurrentAddress=CPU.pc
            OriginalAddress = CurrentAddress
            CurrentLine=int(CPU.FindWhatLine(CurrentAddress).split(':')[1])
            NewLine=0
# Limit forward search to about 15 instructions based on average of 2.5 bytes per instruction. or 40 bytes.
            while ( NewLine <= CurrentLine):
#            and (CurrentAddress <= (OriginalAddress+40 ))): 
                CurrentAddress += 1
                NewLine=int(CPU.FindWhatLine(CurrentAddress).split(':')[1])
            if NewLine <= CurrentLine:
                safeprint("Could not find good match, set breakpoint manually near %04x" % OriginalAddress)
            else:            
                tempbreakpoints.append(CurrentAddress)
                cmdword = "c"    # Continue the code.
        if cmdword == "c":
            stoprange = 0
            DissAsm(CPU.pc, 1, CPU)
            AtLeastOne = 1
            while CPU.pc <= 0xffff:
                if (CPU.pc in breakpoints or CPU.pc in tempbreakpoints) and AtLeastOne != 1:
                    safeprint("Break Point %04x" % CPU.pc)
                    if ( CPU.pc in tempbreakpoints):
                        tempbreakpoints.remove(CPU.pc)
                    DissAsm(CPU.pc, 1, CPU)
                    break
                AtLeastOne = 0
                context.GlobalOptCnt += 1
                CPU.evalpc(context)
        if cmdword == "r":
            stoprange = 0
            if argcnt < 1:
                CPU.pc = context.Entry
                CPU.mb[0xff] = 0
                safeprint("PC set to %0x4" % context.Entry)
                CPU.flags = 0
            else:
                CPU.pc = arglist[0]
                safeprint("PC set to %04x" % arglist[0])
            CPU.flags = 0
            CPU.mb[0xff] = 0
            continue
        if cmdword == "g":
            stoprange = 0
            if argcnt < 1:
                safeprint("Need to provide an address to go to.")
                cmdword = "Null"
                continue
            CPU.pc = arglist[0]
            safeprint("PC set to %04x" % arglist[0])
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
                    safeprint("No break points set")
                else:
                    safeprint("Break Points:")
                    for ii in breakpoints:
                        safeprint("%04x" % int(ii))
                if len(tempbreakpoints) != 0:
                    for ii in tempbreakpoints:
                        safeprint("Temp Break:%04x" % ii)
            else:
                for ii in arglist:
                    breakpoints.append(ii)
            continue

        if cmdword == "cb":
            safeprint("Clearing Breakpoints")
            breakpoints = []
            continue
        if cmdword == "w":
            if argcnt < 1:
                safeprint(context.watchwords)
            else:
                for ii in arglist:
                    context.watchwords.append(Str2Word(ii))
        if cmdword == "cw":
            safeprint("Clearing watchs")
            context.watchwords.clear()

        if cmdword == "L":
            if argcnt < 1:
                sys.stdout.write("Filename: ")
                ii = input()
            else:
                ii=arglist[0]
            if os.path.exists(ii):
                HoldGlobeLine = context.FileLineNum
                oldfilename = context.ActiveFile
                NewLocalID = str(context.UniqueLineNum)+ii                
                context.highaddress = \
                    loadfile(ii, 0, CPU , LOCALFLAG, NewLocalID, context)                    
                context.ActiveFile = oldfilename
                context.FileLineNum = HoldGlobeLine
            else:
                safeprint("File: %s Not found" % ii)
            continue
        if cmdword == "I":
            if argcnt < 1:
                sys.stdout.write("Filename: ")
                ii = input()
            else:
                ii=arglist[0]
            if os.path.exists(ii):
                HoldGlobeLine = context.FileLineNum
                oldfilename = context.ActiveFile
                NewLocalID = str(context.UniqueLineNum)+ii                
                context.highaddress = \
                    loadfile(ii, 0, CPU , GLOBALFLAG, NewLocalID, context)                
                context.ActiveFile = oldfilename
                context.FileLineNum = HoldGlobeLine
            else:
                safeprint("File: %s Not found" % ii)
            continue
        if cmdword == "q":
            safeprint("End Debugging.")
            fd = sys.stdin.fileno()
            new = termios.tcgetattr(fd)
            new[3] = new[3] | termios.ECHO          # lflags
            try:
                termios.tcsetattr(fd, termios.TCSADRAIN, new)
            except:
                safeprint("TTY Error: On No Echo")
            sys.exit(0)
        if cmdword == "h":
            help_commands = [
                ("b", "break points"),
                ("c", "continue [ $1 steps ]"),
                ("cb", "clear breakpoints"),
                ("d", "DissAsm $1 $2"),
                ("g","goto $1"),
                ("h", "this test"),
                ("hex", "Print hexdump $1[-$2]"),
                ("l", "DissAsm from line"),
                ("m", "modify address starting with $1"),
                ("n", "Do one step"),
                ("p", "print values $1"),
                ("pa", "Print all or some labels [pattern,pattern]"),
                ("ps", "Print HW Stack"),
                ("spush","Push $1 to Stack"),
                ("spop","POPNULL stack | $1 saves to Address"),
                ("pa", "Print all G lables | pa $1 print lable value"),
                ("q", "quit debugger"),
                ("r", "reset"),
                ("w", "watch $1"),
                ("cw", "clear watches"),
            ]
            help_commands.sort(key=lambda x: x[0])
            num_columns = 2
            half = (len(help_commands) + 1) // num_columns
            col1 = help_commands[:half]
            col2 = help_commands[half:]

            # Pad second column if needed
            if len(col2) < len(col1):
                col2.append(("", ""))

            # Format and print
            safeprint("Debug Mode Commands:")
            for left, right in zip(col1, col2):
                safeprint(f"{left[0]:<4} - {left[1]:<30}    {right[0]:<4} - {right[1]}") 
        continue

def main():
    global CPU,  DebugOut, current_context



    context = AssemblerContext()
    current_context = context        # GLobal for the functions that are too deeep to pass context too.
    CPU = microcpu(0, context.DEFMEMSIZE)
    context.DEFMEMSIZE = 0x10000        
    context.address = 0
    context.ActiveFile = "start.ld"
    context.LocalID = "main"
    context.LORGFLAG = 0
    context.SkipBlock = 0
    context.Remote = False
    context.watchword = []

#    context.FileLabels = WatchedDict()     # ⬅ replace dict with subclass
#    context.FileLabels.watch("HeapID___1169heapmgr.ld")      # ⬅ optional: monitor a specific key
#    context.FileLabels.watch("Var04")      # ⬅ optional: monitor a specific key

    
    CPU.pc = 0

    


    ListOut = False
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
                current_context.watchwords.append(Str2Word(arg))
                safeprint("New Watchwords %s" % (current_context.watchwords))
            if prpcmd == 2:
                breakafter.append(Str2Word(arg))
            if prpcmd == 3:
               firstcmd+=[arg]
        else:
            if arg == "-d":
                context.Debug = context.Debug + 1
            elif arg == "-l":
                ListOut = True
            elif arg == "-g":
                UseDebugger = True
                DebugOut=sys.stdout
            elif arg == "-c":
                OptCodeFlag = True
                safeprint("Optcode flag set")
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
                context.Remote = not (context.Remote)
            elif arg == "-h":
                safeprint("-d Debug Assembly and Run\n-d more debugging info.\n-l List Src\n-g Run interactive debugger\n-c Hex Dump of Assembly\n-O Binary Dump of Assembly\n-w Add Watch Address to debug listing\n-b Set Breakpoint to debugger\n-r Enable Remote PDB\n-h help, this listing\n-e 'command' pass to debugger")
            elif arg[0] >= "0" and arg[0] <= "9":
                breakafter += (arg)
            else:
                files.append(arg)
#    Entry = 0
    maxusedmem = 0
    for curfile in files:
        NewLocalID = curfile
        maxusedmem = \
            loadfile(curfile, maxusedmem, CPU , GLOBALFLAG, NewLocalID, context)            
    context.GlobalOptCnt = 0

    if len(files) == 0:
        # if no files given then drop to debugger for machine lang tests.
        # Default to common.mc to provide base macros
        maxusedmem = \
            loadfile("common.mc", maxusedmem, CPU, GLOBALFLAG, "common.mc",  context)        
        UseDebugger = True
    if context.Remote:
        safeprint("RDB running on port 4444, use nc localhost 4444")
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

        for gkey in context.GlobeLabels:
            if gkey in context.FileLabels:
                f.write("=%s %s\nG %s\n" % (gkey, context.FileLabels[gkey], gkey))
        f.write("\n# Set Entry:\n. 0x%04x\n" % (context.Entry))
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
        safeprint("Writeing Binary Output from %s with spacer of %s" %
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
    CPU.pc = context.Entry
    if context.Debug > 1:
        safeprint("Start of Run: Debug: %s: Watch: %s" % (context.Debug, context.watchwords))
    if ListOut:
        safeprint("-------0--Max:%04x------" % (maxusedmem),file=DebugOut)
        DissAsm(0, maxusedmem, CPU)
    elif UseDebugger:
        debugger(firstcmd,context)
    else:
        while True:
            CPU.evalpc(context)


if __name__ == '__main__':
    main()
    fd = sys.stdin.fileno()
    new = termios.tcgetattr(fd)
    new[3] = new[3] | termios.ECHO          # lflags
    try:
        termios.tcsetattr(fd, termios.TCSADRAIN, new)
    except:
        safeprint("TTY Error: On No Echo")

#    cProfile.run('main()')
