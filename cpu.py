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
import cpuCfunc
import re as re
import json
import atexit
import readline
import readchar
import cProfile
#import pstats
import io
import time
import bisect

from collections import defaultdict


import sys
import os
import traceback


# Constants
CastDebugToggle=0
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
CastPrintErrMsg=19
CastSelectDisk=20
CastSeekDisk=21
CastWriteSector=22
CastSyncDisk=23
CastSelectDiskI=24
CastSeekDiskI=25
CastWriteSectorI=26
CastPrint32I=32
CastPrint32II=33
CastPrint32S=34
CastPrint32SignI=35
CastPrint32SignS=36
CastTapeWrite=40
CastTapeWriteI=41
CastEnd=99
CastDebugToggle=100
CastStackDump=102

PollReadIntI=1
PollReadStrI=2
PollReadCharI=3
PollSetNoEcho=4
PollSetEcho=5
PollReadCINoWait=6
PollSetRawCode=7
PollReSetRaw=8
PollTTYStateCode=9
PollReadSector=22
PollReadTapeI=23
PollRewindTape=24
PollReadTime=25
PollReadSectorI=26
PollReadTape=27
DebugOut=sys.stderr
PrevPC=0
#  Error and Command codes sent between C and Python modules.
RC_END_PROGRAM=-1
RC_USER_HALT=-4
RC_DEBUG_TOGGLE=-11
RC_STACK_UNDERFLOW=-2
RC_STACK_OVERFLOW=-3
RC_INVALID_INPUT=-5
RC_DISK_SEEK_FAIL=-6
RC_DEVICE_READ_FAIL=-7
RC_DEVICE_MEM_FAIL=-8
RC_DEVICE_WRITE_FAIL=-9
RC_DEVICE_GENERAL_FAIL=-10

OPT_IFNDEF=1
OPT_IFDEF=2
OPT_IF_EQ=3
OPT_IF_NE=4
OPT_IF_LT=5
OPT_IF_GT=6

MACRO_CONDITIONAL = {
    "!": OPT_IFNDEF,
    "?": OPT_IFDEF,
    "IFDEF": OPT_IFDEF,
    "IFNDEF": OPT_IFNDEF,
    "IF_EQ": OPT_IF_EQ,
    "IF_NE": OPT_IF_NE,
    "IF_LT": OPT_IF_LT,
    "IF_GT": OPT_IF_GT    
    }

def dprint(level, *args):
    if current_context.Debug >= level:
        print(*args)


if sys.platform == "win32":
    import msvcrt

    def get_key():
        if msvcrt.kbhit():
            ch = msvcrt.getch()
            if ch in (b'\x00', b'\xe0'):   # special keys
                ch2 = msvcrt.getch()
                return 0x1000 | ch2[0]
            else:
                return ch[0]
        return None

    def setup_raw():
        # Windows: no setup needed, just use msvcrt
        return None

    def restore_tty(state):
        # Windows: nothing to restore
        pass

else:  # POSIX (Linux, macOS, etc.)
    import termios, fcntl, os

    def setup_raw(fd=sys.stdin.fileno()):
        old_attrs = termios.tcgetattr(fd)
        old_flags = fcntl.fcntl(fd, fcntl.F_GETFL)

        new_attrs = termios.tcgetattr(fd)
        # iflag
        new_attrs[0] &= ~(termios.BRKINT | termios.ICRNL |
                          termios.INPCK | termios.ISTRIP | termios.IXON)
        # oflag
        new_attrs[1] &= ~termios.OPOST
        # cflag
        new_attrs[2] |= termios.CS8
        # lflag
        new_attrs[3] &= ~(termios.ICANON | termios.ECHO |
                          termios.IEXTEN | termios.ISIG)
        # cc
        new_attrs[6][termios.VMIN] = 0
        new_attrs[6][termios.VTIME] = 1   # 0.1s

        termios.tcsetattr(fd, termios.TCSANOW, new_attrs)
        fcntl.fcntl(fd, fcntl.F_SETFL, old_flags | os.O_NONBLOCK)
        return (fd, old_attrs, old_flags)

    def restore_tty(state):
        if state:
            fd, old_attrs, old_flags = state
            termios.tcsetattr(fd, termios.TCSANOW, old_attrs)
            fcntl.fcntl(fd, fcntl.F_SETFL, old_flags)


    def get_key(fd=sys.stdin.fileno()):
        if CPU.char_queue:
            return ord(CPU.char_queue.pop(0))
        try:
            data = os.read(fd, 128)
            if not data:
                return None
            chars = list(data.decode(errors="replace"))
            CPU.char_queue.extend(chars)
        except BlockingIOError:
            return None

        return ord(CPU.char_queue.pop(0)) if CPU.char_queue else None            

#from pstats import SortKey

from pathlib import Path


current_context = None


# Function to make sure already proccessed strings that removed escaped codes, will put them back.
def quote_escape_string(s):
    escmap = {
        '\n': '\\n',
        '\t': '\\t',
        '\0': '\\0',
        '\b': '\\b',
        '\r': '\\r',
        '\\': '\\\\',
        '"': '\\"'
    }
    return '"' + ''.join(escmap.get(c, c) for c in s) + '"'

def escape_for_reinsertion(s):
    escmap = {
        '\n': '\\n',
        '\t': '\\t',
        '\0': '\\0',
        '\b': '\\b',
        '\r': '\\r',
        '\\': '\\\\',
        '"': '\\"'
    }
    return ''.join(escmap.get(c, c) for c in s)


class AssemblerContext:
    def __init__(self):
        # Memory and address state
#        self.StoreMem = np.zeros(0x10000, dtype=np.uint8)
        self.address = 0
        self.dataaddress = 0
        self.highaddress = 0
        self.highwater = 0
        self.Entry = 0
        self.DEFMEMSIZE = 0x10000
        self.AdminFlag = 0
        self.Fast = False
        self.CrossCheck = False
        self.DeviceHandle = None        

        # Labels and variables
        self.FileLabels = {}
        self.GlobeLabels = {}
        self.FWORDLIST = []
        self.FBYTELIST = []
        self.DefinedSymbols = set()
        from collections import defaultdict
        self.UsedSymbols = defaultdict(int)
        self.GlobalDeclarations=set()
        self.GlobalDeclInfo={}
        self.StructStack = []

        

        # Macro state
        self.MacroData = {}
        self.MacroPCount = {}
        self.MacroVars = ['0'] * 64
        self.MacroBlockStack = []
        self.CurrentMacroID = None        

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
        self.FileLineNum = 0
        self.UniqueLineNum = 0
        self.LocalID = ""
        self.LORGFLAG = 0
        self.SkipBlock = 0
        self.AddressedLinesSeen = set()
        self.CurrentLineBeingParsed = 0
        self.LastLineText = ""

        # Data segment state
        self.ExpectData = 0
        self.DataSegment = -1

        # Debug/Options
        self.Debug = 0
        self.GlobalOptCnt = 0
        self.Remote = False
        self.watchpoints = []
        self.Monitor = []
    #
    def push_block(self, executing, block_type="UNKNOWN"):
        block= {
            "executing": executing,
            "else_seen": False,
            "id": self._next_block_id(),            
            "line": f"{current_context.ActiveFile}:{current_context.FileLineNum+1}",
            "type":block_type
            }
        self.MacroBlockStack.append(block)
        dprint(2,f"[MB PUSH] depth={len(self.MacroBlockStack):02d} "
                  f"id={block['id']} type={block['type']} exec={block['executing']} "
                  f"{block['line']}")
    def _next_block_id(self):
        if not hasattr(self, "_block_counter"):
            self._block_counter = 0
        self._block_counter += 1
        return self._block_counter

    def pop_block(self):
        if not self.MacroBlockStack:
            print(f"[MB POP ERROR] EMPTY STACK @ {current_context.ActiveFile}:{current_context.FileLineNum+1}")
            CPU.raiseerror(f"100 ENDBLOCK without matching Start {current_context.ActiveFile}:{current_context.FileLineNum+1}")

        block = self.MacroBlockStack.pop()
        dprint(2,f"[MB POP ] depth={len(self.MacroBlockStack):02d} "
                  f"id={block['id']} type={block['type']} exec={block['executing']} "
                  f"(opened @ {block['line']}) "
                  f"-> closed @ {current_context.ActiveFile}:{current_context.FileLineNum+1}")
    
    def current_block(self):
        if not self.MacroBlockStack:
            return None
        return self.MacroBlockStack[-1]

    def parent_executing(self):
        return all(b["executing"] for b in self.MacroBlockStack[:-1])

    def is_executing(self):
        return all(b["executing"] for b in self.MacroBlockStack)


    def smart_compare(self, a: str, b: str):
        """
        Compare two strings using numeric rules when BOTH can be parsed as integers.
        Supports:
        - decimal integers (e.g., "12", "-5")
        - hex integers with 0x prefix (e.g., "0xFF", "-0x20")
        Otherwise falls back to lexicographic comparison.
        Returns:
        -1 if a < b
         0 if a == b
         1 if a > b
        """

        def parse_int(s: str):
            # Hex with optional sign
            if s.startswith(("+0x", "-0x", "+0X", "-0X")) or s.startswith(("0x", "0X")):
                try:
                    return int(s, 16)
                except ValueError:
                    return None

            # Decimal with optional sign
            try:
                return int(s, 10)
            except ValueError:
                return None
            
        ai = parse_int(a)
        bi = parse_int(b)

        # Numeric compare only if BOTH parsed successfully
        if ai is not None and bi is not None:
            if ai < bi:
                return -1
            elif ai > bi:
                return 1
            else:
                return 0

        # Fallback: lexicographic compare
        if a < b:
            return -1
        elif a > b:
            return 1
        else:
            return 0
        
    def evaluate_condition(self, key, line):

        consumed=0
        # Remove the conditional token from line
        _, size = nextword(line)
        line=line[size:]
        consumed += size

        # Extract argument
        arg, arg_size = nextword(line)
        consumed += arg_size
        line=line[size:]
        
        if not arg:
            CPU.raiseerror("110 Conditional missing argument")

        # ---- Legacy ! and ? ----
        if key == "!":        # IFNDEF
            return arg not in self.MacroData, consumed

        if key == "?":        # IFDEF
            return arg in self.MacroData, consumed

        # ---- Explicit IFDEF / IFNDEF ----
        if key == "IFDEF":
            return arg in self.MacroData, consumed        

        if key == "IFNDEF":
            return arg not in self.MacroData, consumed

        # IF_EQ, IF_NE, IF_LT, etc.
        if key in ["IF_EQ", "IF_NE","IF_LT", "IF_GT"]:
            arg2,arg2_size = nextword(line)
            line = line[arg2_size:]
            consumed += arg2_size            
            if key == "IF_EQ":
                return (arg == arg2), consumed
            if key == "IF_NE":
                return (arg != arg2), consumed
            relcmp=smart_compare(arg,arg2)
            if key == "IF_LT":
                return (relcmp < 0), consumed
            if key == "IF_GT":
                return (relcm > 0), consumed

        CPU.raiseerror(f"120 Unknown conditional operator {key}")


    def handle_macro_definition(context,line):
        pos = 0
        parts = []
        keyname, size = nextwordplus(line[pos:])
        pos += size
        while pos < len(line):
            word, size = nextwordplus(line[pos:])
            pos += size
            if word in ("P","M"):
                parts.append(word)
                # consume until end or semi colon ( or error?)
                while pos < len(line):
                    w2, s2 = nextwordplus(line[pos:])
                    pos += s2
                    parts.append(w2)
                    if w2 == ";":
                        break
                continue
            if word == ";":
                break
            parts.append(word)
        line = line[pos:]
        # Here means now process macro string
        dprint(2,f"{context.Debug}>Define Macro {keyname} = {parts} {context.ActiveFile}:{context.FileLineNum}" )
        if not parts:
            # Empty definition, erase any old macro with this name.            
            context.MacroData.pop(keyname, None)
            context.MacroPCount.pop(keyname, None)
        else:
            newMacro = " ".join(parts)
            if context.Debug > 2:
                def dbg_escape(s):
                    return s.replace("\n", "\\n").replace("\0", "\\0")
                if keyname in context.MacroData:
                    dprint(2,f"Replacing old Macro {keyname}: {context.MacroData[keyname]} ")
                dprint(2,f"New Macro {keyname} = {dbg_escape(newMacro)} {current_context.ActiveFile}:{current_context.FileLineNum}" )
                
            context.MacroData[keyname] = newMacro
            # Now count number of paramaters
            pcount = 0
            for match in re.finditer(r'%([0-9])', newMacro):
                digit=int(match.group(1))
                if digit > pcount:
                    pcount=digit
            context.MacroPCount[keyname]= pcount
        return line
    
path_root = os.path.abspath("lib")
sys.path.append(str(path_root))



MacroStack = []
breakpoints = []
tempbreakpoints = []
watchbreaks = {}
UniqueLineNum = 0
EchoFlag = False
UniqueID = 0
LastMLen = []


WW_EQUAL=1
WW_NOT_EQUAL=2
WW_B_EQUAL=3
WW_B_NOT_EQUAL=4

OPS = {
    WW_EQUAL:    lambda a, b: a==b,
    WW_NOT_EQUAL: lambda a, b: a!=b,
    WW_B_EQUAL:    lambda a, b: (a & 0xff) == (b & 0xff),
    WW_B_NOT_EQUAL:    lambda a, b: (a & 0xff) != (b & 0xff)
}


GLOBALFLAG = 1
LOCALFLAG = 2
MAXMEMSP = 0xffff
MAXHWSTACK = 0xff - 2


InDebugger = False
RunMode = False

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

_fd = sys.stdin.fileno()
old_settings = None
_saved_attrs = None
if sys.stdin.isatty():
    old_settings = termios.tcgetattr(_fd)
    def restore_tty():
        try:
            termios.tcsetattr(_fd, termios.TCSADRAIN, old_settings)
        except Exception:
            pass    
else:
    def restore_tty():
        pass






# --- Echo toggle only ---
def PollSetNoEchoFunc(arg=None):
    """Turn echo off, leave canonical mode as-is."""
    attrs = termios.tcgetattr(_fd)
    attrs[3] &= ~termios.ECHO
    termios.tcsetattr(_fd, termios.TCSANOW, attrs)

def PollSetEchoFunc(arg=None):
    """Turn echo back on, leave canonical mode as-is."""
    attrs = termios.tcgetattr(_fd)
    attrs[3] |= termios.ECHO
    termios.tcsetattr(_fd, termios.TCSANOW, attrs)

# --- Raw mode ---
def PollSetRawFunc(arg=None):
    """Put terminal into full raw mode, save old settings."""
    global _saved_attrs
    if _saved_attrs is None:
        _saved_attrs = termios.tcgetattr(_fd)

    tty.setraw(_fd)

    # Optional: tweak VMIN/VTIME so reads don’t block forever
    attrs = termios.tcgetattr(_fd)
    attrs[6][termios.VMIN]  = 0
    attrs[6][termios.VTIME] = 1   # 0.1s
    termios.tcsetattr(_fd, termios.TCSANOW, attrs)

def PollReSetRawFunc(arg=None):
    """Restore terminal to state before PollSetRaw was called."""
    global _saved_attrs
    if _saved_attrs is not None:
        termios.tcsetattr(_fd, termios.TCSADRAIN, _saved_attrs)
        print("Cleaning up caches")

        old_flags = fcntl.fcntl(_fd, fcntl.F_GETFL)
        fcntl.fcntl(_fd, fcntl.F_SETFL, old_flags | os.O_NONBLOCK)
        try:
            while True:
                rlist, _, _ = select.select([_fd], [], [], 0)
                if not rlist:
                    break
                os.read(_fd, 1024)
                print("#")
        except Exception:
            pass
        finally:
            fcntl.fcntl(_fd, fcntl.F_SETFL, old_flags)
        _saved_attrs = None
        

def PollTTYStateFunc(arg=None):
    print("PollTTYState")    
    attrs = termios.tcgetattr(_fd)
    iflag, oflag, cflag, lflag, ispeed, ospeed, cc = attrs
    print("iflag:", hex(iflag))
    print("oflag:", hex(oflag))
    print("cflag:", hex(cflag))
    print("lflag:", hex(lflag))
    print("cc[VMIN]:", cc[termios.VMIN], "cc[VTIME]:", cc[termios.VTIME])

    # Human-friendly summary
    print("ECHO:", bool(lflag & termios.ECHO))
    print("ICANON:", bool(lflag & termios.ICANON))
    print("ISIG:", bool(lflag & termios.ISIG))
    print("IEXTEN:", bool(lflag & termios.IEXTEN))

    




def tty_reset(_fd=sys.stdin.fileno()):
    """
    Restore terminal state saved by tty_setraw.
    """
    global _saved_attrs
    if _saved_attrs is not None:
        termios.tcsetattr(_fd, termios.TCSANOW, _saved_attrs)
        _saved_attrs = None

atexit.register(restore_tty)
    
def shandler(signum, frame):
    restore_tty()
    print("Ctrl-C\x1b[?1000l\x1b[?25h\n", flush=True)
    debugger("",current_context)    
    sys.exit(1)   # exit cleanly

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
    global UniqueID,current_context,FileLineData
    UniqueID = UniqueID+1
    return "U_%06x_" % UniqueID
#    return "U_%06x%0x4_" % (UniqueID,current_context.address) 


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
        CPU.raiseerror(f"130 Unknown base typecode: {typecode}")
    for cc in instr:
        if not (cc in alpha):
            CPU.raiseerror("140 String %s is not valid for base %d" % (instr, typecode))
    return (int(instr, 0))

LocVarHist = {}



#def UpdateVarHistory(varname, value, address):
#   global LocVarHist
#    LocVarHist.setdefault(varname, []).append((int(value), int(address)))


def UpdateVarHistory(varname, value, address):
    global LocVarHist

    address = int(address)
    value = int(value)

    history = LocVarHist.setdefault(varname, [])

    # If there is an existing open lifetime for this symbol,
    # close it before starting a new one.
    if history:
        last = history[-1]
        if last.get("end") is None:
            # Close the previous lifetime just before this definition
            last["end"] = address - 1

    # Start a new lifetime
    history.append({
        "value": value,
        "start": address,
        "end": None,   # Open-ended for now
    })
    dprint(2,f"HIST {varname} start={address} value={value}")

def FindHistoricVal(varname, testaddress, context=None):
    global LocVarHist

    testaddress = int(testaddress)

    def in_range(entry):
        start = entry["start"]
        end = entry["end"]
        if testaddress < start:
            return False
        if end is not None and testaddress > end:
            return False
        return True

    # ------------------------------------------------------------
    # 1) Exact-name lookup first
    # ------------------------------------------------------------
    candidates = []
    history = LocVarHist.get(varname)
    if history:
        candidates = [e for e in history if in_range(e)]

        if candidates:
            # Pick the most recent valid definition
            best = max(candidates, key=lambda e: e["start"])
            return best["value"]
        # Fallback if nothing in range return most recent definition
        best = max(history, key=lambda e: e["start"])
        return best["value"]

    # ------------------------------------------------------------
    # 2) Prefix-based lookup (varname__)
    # ------------------------------------------------------------
    prefix = f"{varname}__"
    candidates = []

    for name, history in LocVarHist.items():
        if name.startswith(prefix):
            for entry in history:
                if in_range(entry):
                    candidates.append(entry)

    if candidates:
        best = max(candidates, key=lambda e: e["start"])
        return best["value"]

    # ------------------------------------------------------------
    # 3) No valid historical entry found
    # ------------------------------------------------------------
#    safeprint(f"Error: {varname} not recognized at address {testaddress:04x}.")
    return None


def FindLabelMatch(varname, context: AssemblerContext):
    varname=str(varname)
    if varname in context.FileLabels:
        return context.FileLabels[varname]    # exact match
    pattern = re.compile(rf"^{re.escape(varname)}_+")
    potential_matches = [ key for key in context.FileLabels.keys() if pattern.match(key)]
    if len(potential_matches) == 1:
        return context.FileLabels[potential_matches[0]]        # backdoor exact match.
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

def handle_semicolon(line, filename, context, CPU):
    # Strip leading ';'
    if len(line)>1:
        rest = line[1:]
    else:
        rest = line[1:].lstrip()
    # Parse Label
    label,size = nextword(rest)
    if not label:
        CPU.raiseerror("150 Missing lable in ';' directive")
    rest = rest[size:].lstrip()
    # Parse size expression
    size_expr, size_len = nextwordequation(rest)
    if not size_expr:
        CPU.raiseerror(f"160 Missing size for ';' {label}")
    rest=rest[size_len:].lstrip()
    # Evaluate Size it must resolve 1st pass.
    workingaddress=(
        context.dataadress
        if context.DataSegment != -1
        else context.address
        )
    size_value = DecodeStr(size_expr, workingaddress, CPU, True, context)
    if not isinstance(size_val, int):
        CPU.raiseerror(f"170 Size expression '{size_expr}' must resolve on first pass of ';' {label}")
    if size_value < 0:
        CPU.raiseerror(f"180 Size expression '{size_expr}' can not be negative ';' {label}")        
        
    sym = IsLocalVar(label, context)
    context.FileLabels[sym] = workingaddress
    UpdateVarHistory({sym: workingaddress}, workingaddress, workingaddress)

    #----------------------------------------
    # Setup data consumption
    #----------------------------------------
    context.ExpectData = size_value

    #----------------------------------------
    # Return remaining line for data parsing
    #----------------------------------------
    return rest
        
    



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
        func=self.op_table[optcall]
        func(argument)
#        return getattr(self, "opt" + OPTDICT[str(optcall)][1], lambda: default)(argument)


    def __init__(self, origin, memsize):
        self.pc = origin
        self.flags = np.uint16(0)    # B0 = ZF, B1=NF, B2=CF, B3=OF
        self.identity = next(self.cpu_id_iter)
#        self.hwstack = np.zeros(256, dtype=np.uint16)
        self.hwstack = [0] * MAXHWSTACK
        self.hwstacksp = 0
        self.memspace = np.zeros(memsize, dtype=np.uint8)
        self.netqueue = []
        self.netapps = []
        self.hwtimer = 0
        self.simtime = False
        self.clocksec = 1000
        self.Last_Filename_used = None
        self.char_queue = []
        self.op_table=[
            self.optNOP, self.optPUSH, self.optDUP, self.optPUSHI, self.optPUSHII, self.optPUSHS, self.optPOPNULL, self.optSWP, self.optPOPI, self.optPOPII, self.optPOPS, self.optCMP, self.optCMPS, self.optCMPI, self.optCMPII, self.optADD, self.optADDS, self.optADDI, self.optADDII, self.optSUB, self.optSUBS, self.optSUBI, self.optSUBII, self.optOR, self.optORS, self.optORI, self.optORII, self.optAND, self.optANDS, self.optANDI, self.optANDII, self.optXOR, self.optXORS, self.optXORI, self.optXORII, self.optJMPZ, self.optJMPN, self.optJMPC, self.optJMPO, self.optJMP, self.optJMPI, self.optJMPS, self.optCAST, self.optPOLL, self.optRRTC, self.optRLTC, self.optSHR, self.optSHL, self.optINV, self.optCOMP2, self.optFCLR, self.optFSAV ]
        
        self.op_size = [OPTDICT.get(str(i), (None, None, 1))[2] for i in range(256)]
        self.op_func = [getattr(self, "opt" + OPTDICT[str(i)][1], None)
                        if str(i) in OPTDICT else None
                        for i in range(256)]

    def insertbyte(self, location, value):
        if location >= 65536:
            CPU.raiseerror("190 Address OverFlow %05x" % location)
        CPU.memspace[location] = value

    def getwordmem(self, index):
        return (int(self.memspace[index]) + (int(self.memspace[index+1]) << 8))    

    def dumpstack(self,stack):
        global FileLineData
        print("\nStack Dump:")
        for i in range(self.hwstacksp):
            val = stack[i]
            # If value looks like an address, try symbolic lookup
            tresult = FileLineData.get_line_info(val, False)
            if tresult and len(tresult) >= 2:
                print(f"{i:03}: {tresult[0]}:{tresult[1]}")
            else:
                print(f"{i:03}: 0x{val:04x}")
                
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
        global  RunMode, DebugOut

        valid = -1
        try:
            restore_tty()
        except Exception as e:
            safeprint("TTY Setup Error:", e, file=DebugOut)

        try:
            safeprint("CPU State:", file=DebugOut)
            i = getattr(self, "pc", -1)
            mem = getattr(self, "memspace", {})

            if current_context is None:
                safeprint("Emulator failed to startup. Code: %s" % idcode, file=DebugOut)
                sys.exit(99)
            safeprint(f"Filename: {current_context.ActiveFile}:{current_context.FileLineNum+1}" )

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
                sp = self.hwstacksp
                if 0 < sp < 255:
                    for idx in range(sp - 1):
                        val = int(self.hwstack[idx])
                        safeprint(" %04x" % val, file=DebugOut, end="")
                    safeprint(" ", file=DebugOut)
                else:
                    safeprint("Stack Empty or Invalid SP: %02x" % sp, file=DebugOut)
                    self.hwstacksp = 0
            except Exception as e:
                safeprint("Stack dump error:", e, file=DebugOut)

            # Print ID code
            safeprint("Error Number: %s at PC:0x%04x" % (idcode, i), file=DebugOut)
            safeprint("%s:%s" % (current_context.ActiveFile, current_context.FileLineNum+1))
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

    def fetchStack(self, address):
        sp=self.hwstacksp
        if sp == 0:
            self.raiseerror("200 Empty stack.")
        if address < 0 or address >= sp or address >= MAXHWSTACK:
            self.raiseerror("210 Stack address out of range.")
        index=sp - 1 - address
        return self.hwstack[index]

    def StoreAcum(self, address, value):
        # Saves at top of stack the Acum value. Does not change stack.
        # Address zero is always top, a given index >0 will try to save value at that stack depth
        sp = self.hwstacksp
        if sp ==0:
            self.raiseerror(
                "002 Empty stack.")
        if address < 0 or address >= sp or address >= MAXHWSTACK:
            self.raiseerror(
                "002 stack addres out of range.")
        index = sp - 1 - address
        self.hwstack[index] = value & 0xffff

    def getwordat(self, address):
        a=0
        if address == MAXMEMSP:
            return 0
        if address >= MAXMEMSP:
            self.raiseerror("220 Invalid Address: %d, getwordat" % (address))
            return 0
        a = self.getwordmem(address)
        return a

    def putwordat(self, address, value):
        address = int(address)
        if address > MAXMEMSP:
            self.raiseerror("230 Invalid Address: %d, putwordat" % (address))
        self.insertbyte(address, self.lowbyte(value))
        self.insertbyte(address + 1, self.highbyte(value))

    def optNOP(self, count):
        return

    def optPUSH(self, invalue):
        sp = self.hwstacksp
        if sp >= len(self.hwstack):
            self.dumpstack(self.hwstack)
            self.raiseerror("240 MB Stack overflow, optpush")
        self.hwstack[sp] = invalue
        self.hwstacksp += 1

    def optDUP(self, address):
        sp = self.hwstacksp
        if sp >= len(self.hwstack):
            self.dumpstack(self.hwstack)
            self.raiseerror("250 MB Stack overflow, optpush")
        self.hwstack[sp] = self.hwstack[sp - 1]
        self.hwstacksp += 1

    def optPUSHI(self, address):
        sp = self.hwstacksp
        if sp >= len(self.hwstack):
            self.dumpstack(self.hwstack)
            self.raiseerror("260 MB Stack overflow, optPUSHI")
        if (address+1 > MAXMEMSP):
            self.raiseerror("270 Invalid Address: %d, optPUSHI" % (address))
        self.hwstack[sp] = self.getwordmem(address)
        self.hwstacksp += 1

    def optPUSHII(self, address):
        sp = self.hwstacksp
        if sp >= len(self.hwstack):
            self.dumpstack(self.hwstack)
            self.raiseerror("280 MB Stack overflow, optPUSHII")
        newaddress = self.getwordat(address)
        if (newaddress+1 > MAXMEMSP):
            self.raiseerror(
                "010 Invalid Indirect Address: %d, optPUSHII" % (newaddress))
        self.hwstack[sp] = self.getwordat(newaddress)
        self.hwstacksp += 1

    def optPUSHS(self, address):
        # Since we are storing the result in the same stack spot as the address was, no need for overflow checks
        newaddress = self.fetchStack(0)
        self.StoreAcum(0, self.getwordat(newaddress))

    def optPOPNULL(self, address):
        if (address > MAXMEMSP):
            self.raiseerror("290 Invalid Address: %d, optPOPI" % (address))
        sp = self.hwstacksp
        if sp < 1:
            self.raiseerror("300 Stack underflow, optPOPI")
        self.hwstacksp -= 1

    def optSWP(self, address):
        # We're not changing the sp level, so no need for tests.
        sp = self.hwstacksp
        if sp >= 2:
            # Pythonic swap
            self.hwstack[sp - 1], self.hwstack[sp - 2] = self.hwstack[sp - 2], self.hwstack[sp - 1]
        else:
            self.raiseerror("310 SWP on stack with less than 2 items.")

    def optPOPI(self, address):
        if (address > MAXMEMSP):
            self.raiseerror("320 Invalid Address: %d, optPOPI" % (address))
        sp = self.hwstacksp
        if sp < 1:
            self.raiseerror("330 Stack underflow, optPOPI")
        sp -= 1
        if sp >= len(self.hwstack):
            self.dumpstack(self.hwstack)
            self.raiseerror("340  MB Stack overflow, optPOPI")
        self.insertbyte(address, self.lowbyte(self.hwstack[sp]))
        self.insertbyte(address+1, self.highbyte(self.hwstack[sp]))                
        self.hwstacksp -= 1

    def optPOPII(self, firstaddress):
        address = self.getwordat(firstaddress)
        if (address+1 > MAXMEMSP):
            self.raiseerror(
                "016 Invalid Indirect Address: %d, optPOPII" % (address))
        sp = self.hwstacksp
        if sp < 1:
            self.raiseerror("350 Stack underflow, optPOPII")
        self.optPOPI(address)

    def optPOPS(self, notused):
        if self.hwstacksp < 1:
            self.raiseerror("360 Stack underflow, OptPOPS")
        newaddress = self.fetchStack(0)
        A1 = self.fetchStack(1)
        self.putwordat(newaddress, A1)
        self.hwstacksp -= 2

    def SetFlags(self, A1, WasSubt):
        global ZF, NF
        # Zero and Negative are based solely on the result
        ZF = 1 if (A1 & 0xffff) == 0 else 0
        NF = 1 if (A1 & 0x8000) != 0 else 0
        # Don’t touch CF/OF here, leave them for OverCarryTest
        self.flags = (ZF | (NF << 1))

    def OverCarryTest(self, a, b, c, IsSubtraction):
        global CF, OF
        CF = 0
        OF = 0

        a16 = a & 0xffff
        b16 = b & 0xffff
        c16 = c & 0xffff

        sa = (a16 & 0x8000) != 0
        sb = (b16 & 0x8000) != 0
        sc = (c16 & 0x8000) != 0

        if IsSubtraction:
            # Borrow: CF=1 if a < b
            CF = 1 if a16 < b16 else 0
            # Overflow if sign(a) != sign(b) and sign(result) != sign(a)
            if (sa != sb) and (sc != sa):
                OF = 1
        else:
            # Carry: CF=1 if unsigned sum exceeded 16 bits
            if (a16 + b16) > 0xFFFF:
                CF = 1
            # Overflow if sign(a) == sign(b) and sign(result) != sign(a)
            if (sa == sb) and (sc != sa):
                OF = 1

        # Merge into final flag word
        self.flags |= (CF << 2) | (OF << 3)

    def optCMP(self, asvalue):
        R1 = asvalue
        R2 = self.fetchStack(0)
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R2, R1, A1, 1)

    def optCMPS(self, address):
        R1 = self.fetchStack(0)
        R2 = self.fetchStack(1)
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R2, R1, A1, 1)

    def optCMPI(self, address):
        R1 = self.getwordat(address)
        R2 = self.fetchStack(0)
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
        R1 = self.fetchStack(0)
        R2 = invalue
        A1 = R1 + R2
        self.SetFlags(A1,0)
        self.OverCarryTest(R1, R2, A1, 0)
        self.StoreAcum(0, A1)

    def optADDS(self, invalue):
        R1 = self.fetchStack(0)
        R2 = self.fetchStack(1)
        A1 = R1 + R2
        self.SetFlags(A1,0)
        self.OverCarryTest(R1, R2, A1, 0)
        self.hwstacksp -= 1
        self.StoreAcum(0, A1)

    def optADDI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("370 Invalid Address: %d, optADDI" % (address))
        newaddress = self.getwordat(address)
        self.optADD(newaddress)

    def optADDII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("380 Invalid Address: %d, optADDII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("390 Invalid Address %d, optADDII" % (address))
        self.optADDI(newaddress)

    def optSUB(self, invalue):
        R2 = self.fetchStack(0)
        R1 = invalue
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R2, R1, A1, 1)
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optSUBS(self, invalue):
        R1 = self.fetchStack(0)
        R2 = self.fetchStack(1)
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R2,R1,A1,1)
        self.hwstacksp -= 1
        self.StoreAcum(0, A1)

    def optSUBI(self, address):
        R1 = self.getwordat(address)
        R2 = self.fetchStack(0)
        A1 = R2 - R1
        self.SetFlags(A1,1)
        self.OverCarryTest(R2,R1,A1,1)
        self.StoreAcum(0, A1 & 0xffff )

    def optSUBII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("400 Invalid Address: %d, optSUBII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("410 Invalid Address %d, optSUBII" % (address))
        self.optSUBI(newaddress)

    def optOR(self, ivalue):
        R1 = self.fetchStack(0)
        R2 = ivalue
        A1 = R1 | R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optORS(self, ivalue):
        R1 = self.fetchStack(0)
        R2 = self.fetchStack(1)
        A1 = R1 | R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.hwstacksp -= 1
        self.StoreAcum(0, A1)

    def optORI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("420 Invalid Address: %d, optORI" % (address))
        newaddress = self.getwordat(address)
        self.optOR(newaddress)

    def optORII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("430 Invalid Address: %d, optORII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("440 Invalid Address %d, optORII" % (address))
        self.optORI(newaddress)

    def optAND(self, ivalue):
        R1 = self.fetchStack(0)
        R2 = ivalue
        A1 = R1 & R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optANDS(self, ivalue):
        R1 = self.fetchStack(0)
        R2 = self.fetchStack(1)
        A1 = R1 & R2
        self.SetFlags(A1,0)
        A1 = A1 & 0xffff
        self.hwstacksp -= 1
        self.StoreAcum(0, A1)

    def optANDI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("450 Invalid Address: %d, optANDI" % (address))
        newaddress = self.getwordat(address)
        self.optAND(newaddress)

    def optANDII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("460 Invalid Address: %d, optANDII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("470 Invalid Address %d, optANDII" % (address))
        self.optANDI(newaddress)
    def optXOR(self, ivalue):        
        R1 = self.fetchStack(0)
        R2 = ivalue & 0xffff
        A1 = (R1 ^ R2) & 0xffff
        self.SetFlags(A1,0)
        self.StoreAcum(0, A1)

    def optXORS(self, ivalue):
        R1 = self.fetchStack(0)
        R2 = self.fetchStack(1) & 0xffff
        A1 = (R1 ^ R2) & 0xffff
        self.SetFlags(A1,0)
        self.StoreAcum(0, A1)
        self.hwstacksp -= 1
        self.StoreAcum(0, A1)

    def optXORI(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("480 Invalid Address: %d, optORI" % (address))
        newaddress = self.getwordat(address)
        self.optXOR(newaddress)

    def optXORII(self, address):
        if address >= MAXMEMSP:
            self.raiseerror("490 Invalid Address: %d, optORII" % (address))
        newaddress = self.getwordat(address)
        if (newaddress > MAXMEMSP):
            self.raiseerror("500 Invalid Address %d, optORII" % (address))
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
        newaddress = self.fetchStack(0)
        self.hwstacksp -= 1
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
                "036 Insufficent space for Message Address at %d, optCAST %s:%d" % (address, filename, get_line_info(address)))
        cmd = self.fetchStack(0)
        if cmd == CastPrintStr:
            self.optPOPNULL(address)            
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
        if cmd == CastPrintErrMsg:
            self.optPOPNULL(address)            
            i = address
            while self.memspace[i] != 0 and i < MAXMEMSP:
                c = self.memspace[i]
                if c == 0:
                    safeprint("Odd C is zero")
                if (c < 32 or c > 127) and (c != 10 and c != 7 and c != 27 and c != 30 and c!=9 and c!=8 ):
                    safeprint("%02x" % c, file=DebugOut,end="")
                else:
                    safeprint("%c" % c, file=DebugOut, end="")
                i += 1        
        if cmd == CastPrintInt:
            self.optPOPNULL(address)            
            sys.stdout.write("%d" % (address & 0xffff) )
        if cmd == CastPrintIntI:
            self.optPOPNULL(address)
            v = self.getwordmem(address)
            sys.stdout.write("%d" % (v & 0xffff))
        if cmd == CastPrintSignI:
            self.optPOPNULL(address)            
            v = self.getwordmem(address)
            v = v & 0xffff
            if ( v & 0x8000):
                v = -((v - 1) ^ 0xffff)
            sys.stdout.write("%d" % v)
        if cmd == CastPrintBinI:
            v = self.getwordmem(address)
            sys.stdout.write("%s" % format(v, "016b"))
        if cmd == CastPrintChar:
            self.optPOPNULL(address)            
            v = self.memspace[address]
            if (v < 31):
                safeprint("%c" % v)
            else:
                sys.stdout.write(chr(v))
        if cmd == CastPrintStrI:
            self.optPOPNULL(address)            
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
            self.optPOPNULL(address)            
            sys.stdout.write("%d" % self.getwordat(address))
        if cmd == CastPrintCharI:
            self.optPOPNULL(address)
            v = self.getwordmem(address)
            sys.stdout.write("%c" % chr(v))
        if cmd == CastPrintHexI:
            self.optPOPNULL(address)            
            v = self.getwordat(address)
            sys.stdout.write("%04x" % (v))
        if cmd == CastPrintHexII:
            self.optPOPNULL(address)            
            v = self.getwordat(self.getwordat(address))
            sys.stdout.write("%04x" % v)
        if current_context == None:
            self.optPOPNULL(address)            
            sys.stdout.write("<Stopped>")
            return
        context=current_context     # For readability
        if cmd == CastSelectDisk:            # 20
            self.optPOPNULL(address)            
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
            self.optPOPNULL(address)            
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
            self.optPOPNULL(address)            
            if context.DeviceHandle == None:
                self.raiseerror("510 Attempted to Seek without selecting Disk")
            self.DiskPtr = address*0x200
            context.DeviceFile.seek(self.DiskPtr)
        if cmd == CastSeekDiskI:
            self.optPOPNULL(address)            
            v = self.getwordat(address)
            if context.DeviceHandle == None:
                self.raiseerror("520 Attempted to Seek without selecting Disk")
            self.DiskPtr = v*0x200
            context.DeviceFile.seek(self.DiskPtr)
        if cmd == CastWriteSector:
            self.optPOPNULL(address)            
            if context.DeviceHandle == None:
                self.raiseerror("530 Attempted to write without selecting Disk")
            v = address
            if v < MAXMEMSP-0x1ff:
                block = self.memspace[v:v+512]
                context.DeviceFile.seek(self.DiskPtr)
                context.DeviceFile.write(bytes(block))
                self.DiskPtr += 0x200
                context.DeviceFile.flush()
            else:
                self.raiseerror(
                    "038 Attempted to write block larger than memory to storage")
        if cmd == CastWriteSectorI:
            self.optPOPNULL(address)            
            v = self.getwordat(address)
            if context.DeviceHandle == None:
                self.raiseerror("540 Attempted to write without selecting Disk")
            if v < MAXMEMSP-0x1ff:
                block = self.memspace[v:v+512]
                context.DeviceFile.seek(self.DiskPtr)
                context.DeviceFile.write(bytes(block))
                self.DiskPtr += 0x200
                context.DeviceFile.flush()
            else:
                self.raiseerror(
                    "038 Attempted to write block larger than memory to storage")
        if cmd == CastSyncDisk:
            self.optPOPNULL(address)            
            if context.DeviceHandle != None:
                context.DeviceFile.close()
                context.DeviceFile = open(context.DeviceHandle, "r+b")
        if cmd == CastPrint32I:
            self.optPOPNULL(address)            
            iaddr = address
            v = self.getwordat(iaddr) + (self.getwordat(iaddr + 2) << 16)
            v = v & 0xffffffff
            sys.stdout.write(f"{v}")
        if cmd == CastPrint32II:
            self.optPOPNULL(address)            
            iaddr = self.getwordat(address)
            v = self.getwordat(iaddr) + (self.getwordat(iaddr + 2) << 16)
            v = v & 0xffffffff
            sys.stdout.write(f"{v}")            
        if cmd == CastPrint32S:
            self.optPOPNULL(address)            
            hval=self.fetchStack(0) & 0xffff
            lval=self.fetchStack(1) & 0xffff
            v = (hval << 16) + lval
            v = v & 0xffffffff
            self.hwstacksp -= 1
            sys.stdout.write(f"{v}")
        if cmd == CastPrint32SignI:
            self.optPOPNULL(address)            
            iaddr = address
            v = self.getwordat(iaddr) + (self.getwordat(iaddr + 2) << 16)
            v = v & 0xffffffff
            if v & 0x80000000:
                v -= 0x100000000
            sys.stdout.write(f"{v}")
        if cmd == CastPrint32SignS:
            self.optPOPNULL(address)            
            hval=self.fetchStack(0) & 0xffff
            lval=self.fetchStack(1) & 0xffff
            v = (hval << 16) + lval
            v = v & 0xffffffff
            if v & 0x80000000:
                v -= 0x100000000            
            self.hwstacksp -= 1
            sys.stdout.write(f"{v}")
        if cmd == CastEnd:
            self.optPOPNULL(address)            
            safeprint("\nEND of Run:(%d Opts)" % current_context.GlobalOptCnt)
            sys.exit(address)
        if cmd == CastDebugToggle:
            self.optPOPNULL(address)            
            current_context.Debug = 0 if current_context.Debug else 1
        if cmd == CastStackDump:
            self.optPOPNULL(address)
            depth = int(self.hwstacksp)
            if depth == 0:
                safeprint(" %04x:Stack:(empty):%s [---,---]" %
                          (PrevPC, CPU.FindWhatLine(PrevPC)),
                          file=DebugOut)
            else:
                safeprint(" %04x:Stack:(%d):%s [" %
                          (PrevPC, depth-1, CPU.FindWhatLine(PrevPC)),
                          file=DebugOut,end="")
                for i in range(depth):
                    val = self.fetchStack(i)
                    safeprint(" %04x" % val, file=DebugOut,end="")
                safeprint(" ]", file=DebugOut)
        if cmd == CastTapeWrite:
            self.optPOPNULL(address)            
            if context.DeviceHandle != None:
                v=address
                if v < MAXMEMSP-0x1ff:
                    block=self.memspace[v:v+512]
                    context.DeviceFile.write(bytes(block))
                    context.DeviceFile.flush()
                else:
                    self.raiseerror(
                        "039 Attempt to write from source memory past availabel memory")
        if cmd == CastTapeWriteI:
            self.optPOPNULL(address)            
            if context.DeviceHandle != None:
                v=self.getwordat(address)
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
        cmd = self.fetchStack(0)
        if cmd == PollReadIntI:
            sys.stdout.flush()
            self.optPOPNULL(address)              # consume the POLL arg
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
            self.optPOPNULL(address)
            rawdata = sys.stdin.readline(256)
            i = address
            for c in rawdata:
                if ord(c) > 31:
                    c = ord(c)
                    self.putwordat(i, (c & 0xff))
                    i += 1
                    if (i > (MAXMEMSP-11)):
                        self.raiseerror(
                            "041 Insufficent space for Message Address at %d, optPOLL" % (i))
        if cmd == PollReadCharI:
            self.optPOPNULL(address)                 # consume POLL arg
            if not self.char_queue:
                if sys.stdin.isatty():
                    try:
                        c = readchar.readkey()
                    except:
                        c = ""
                else:
                    c = sys.stdin.read(1)
                if not c:
                    c = "\0"
                elif len(c) > 1:
                    self.char_queue = c[1:]
                    c=c[0]
            else:
                c=self.char_queue[0]
                self.char_queue=self.char_queue[1:]
                    
            self.putwordat(address, ord(c))
        if cmd == PollReadCINoWait:
            self.optPOPNULL(address)                # consume POLL arg
            if self.char_queue:
                c = self.char_queue[0]
                self.char_queue = self.char_queue[1:]
            else:
                k = get_key()
                if k is None:
                    c = "\0"
                elif isinstance(k, str):
                    if len(k) > 1:
                        c = k[0]
                        self.char_queue = k[1:]
                    else:
                        c = k
                elif isinstance(k, int):
                    try:
                        c = chr(k & 0xFF)
                    except ValueError:
                        c = "\0"
                else:
                    c = "\0"
            self.putwordat(address, ord(c))
        if cmd == PollSetNoEcho:
            self.optPOPNULL(address)            
            PollSetNoEchoFunc()
        if cmd == PollSetEcho:
            self.optPOPNULL(address)
            PollSetEchoFunc()
        if cmd == PollSetRawCode:
            self.optPOPNULL(address)
            PollSetRawFunc()
        if cmd == PollReSetRaw:
            self.optPOPNULL(address)
            PollReSetRawFunc()
        if cmd == PollTTYStateCode:
            self.optPOPNULL(address)
            PollTTYStateFunc()
        if current_context == None:
            safeprint("CPU Stopped")
            return
        if cmd == PollReadSector:
            self.optPOPNULL(address)
            if current_context.DeviceHandle != None:
                v=address
                if v <= MAXMEMSP-0x1ff:
                    block = current_context.DeviceFile.read(512)
                    tidx = v
                    for i in block:
                        self.memspace[tidx] = int(i) & 0xff
                        tidx += 1
                else:
                    self.raiseerror(
                        "042 Attempted to read block with insuffient memory %04x < 0x4x" %(v,MAXMEMSP-0xff))
        if cmd == PollReadSectorI:
            self.optPOPNULL(address)            
            if current_context.DeviceHandle is not None:
                v = self.getwordmem(address)
                if v <= MAXMEMSP-0x1ff:
                    current_context.DeviceFile.seek(self.DiskPtr)
                    block = current_context.DeviceFile.read(512)
                    tidx = v
                    for i in block:
                        self.memspace[tidx] = int(i) & 0xff
                        tidx += 1
                else:
                    self.raiseerror("550 Attempted to read block with insuffient memory %04x < 0x4x" %(v,MAXMEMSP-0xff))
        if cmd == PollReadTape:
            self.optPOPNULL(address)            
            if current_context.DeviceHandle is not None:
                v=address
                if v<= MAXMEMSP - 0x1ff:                
                    block=current_context.DeviceFile.read(512)
                    tidx=v
                    for i in block:
                        self.memspace[tidx] = int(i) & 0xff
                        tidx += 1
                else:
                    self.raiseerror(
                        "043 Attempt to read Tape Block with insufficent memory")
        if cmd == PollReadTapeI:
            self.optPOPNULL(address)            
            if current_context.DeviceHandle is not None:
                v=self.getwordmem(address)
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
            self.optPOPNULL(address)
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
        R1 = self.fetchStack(0)
        # New Carry Flag from Right most bit
        NCF = (1 if (R1 & 1 != 0) else 0) << 2
        # Pull CF from flags and make it 1 | 0
        OCF = (1 if (self.flags & 0x04 != 0) else 0) << 15
        R1 = R1 >> 1 | OCF
        self.flags = (int(self.flags) & 0xfffb) | NCF
        self.StoreAcum(0, R1)

    def optRLTC(self, unused):
        # RLTC means Rotate Left Through Carry
        # After rotation current CF becomes low bit, and previous high bit saves to CF
        R1 = self.fetchStack(0)
        # New Carry Flag from Left Most bit
        NCF = (1 if (R1 & 0x08000 != 0) else 0) << 2
        # Pull CF from flags and make 1 | 0
        OCF = (1 if (self.flags & 0x04 != 0) else 0)
        R1 = (R1 << 1) | OCF
        self.flags = (int(self.flags) & 0xfffb) | NCF
        self.StoreAcum(0, R1)

    def optSHR(self, unused):
        # SHR mean shift Right and set carry CF to equal current lowest bit
        
        R1 = self.fetchStack(0) & 0xFFFF
        NCF = 0x4 if (R1 & 0x0001) else 0
        R1 = (R1 >> 1) & 0xFFFF
        self.flags = (self.flags & ~0x4) | NCF
        self.StoreAcum(0, R1)
        
    def optSHL(self, unused):
        # SHL mean shift Left and set carry CF to equal current Highest bit
        R1 = self.fetchStack(0) & 0xFFFF
        NCF = 0x4 if (R1 & 0x8000) else 0  # carry in bit 2
        R1 = ((R1 << 1) & 0xFFFF)          # mask to 16 bits
        self.flags = (self.flags & ~0x4) | NCF
        self.StoreAcum(0, R1)

    def optINV(self, address):
        R2 = self.fetchStack(0)
        A1 = ~R2
        self.SetFlags(A1,0)
        self.flags = self.flags & 0x3      # Only care about NF or ZF
        A1 = A1 & 0xffff
        self.StoreAcum(0, A1)

    def optCOMP2(self, address):
        R2 = self.fetchStack(0)
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
        sp = self.hwstacksp
        if sp < 1:
            self.raiseerror("560 Stack underflow, OptFLOD")
        sp -= 1
        if sp >= len(self.hwstack):
            self.raiseerror("570 Stack overflow, optFLOD")
        self.flags = self.hwstack[sp]
        self.hwstacksp -= 1
    def optADM(self,address):
        # Toggle ADM Flag, but has to run < 16K for protection.
        global current_context
        if self.pc <= 0x4000:
            current_context.AdminFlag = ~current_context.AdminFlag
    def optSCLR(self,address):
        # Empties Stack.
        self.hwstacksp=0
    def optSRPT(self,address):
        # Reports Stack size if < max-1 or -1 if >= max-1
        if self.hwstacksp <= 0xff:
            self.optPUSH(self.hwstacksp)
        elif self.hwstacksp == (0xff/2 - 3):
            self.optPUSH(-1)

    def evalpc(self, context, dosteps):
        """
        Main evaluate loop – dispatches to Python or C backend
        depending on context.Fast.
        """
        if context.CrossCheck:
            halted = False
            step_count = 0
            while not halted:
                # --- snapshot current state ---
                pc0, flags0 = self.pc, self.flags
                mem0 = self.memspace[:]   # Main Memory snapshot
                mb0  = self.hwstack[:]         # HW stack snapshot

                # --- run C version with its own copies ---
                memC = mem0[:]            # independent copy for C
                mbC  = mb0[:]
                pcC, flagsC, rcC = cpuCfunc.EvalOne(memC, mbC, pc0, flags0, 1, 0)

                # --- run Python version with its own copies ---
                self.pc, self.flags = pc0, flags0
                self.memspace = mem0[:]   # independent copy for Python
                self.hwstack       = mb0[:]
                rcPy = self._evalpc_py(context, dosteps=1)

                pcPy, flagsPy = self.pc, self.flags
                memPy, mbPy   = self.memspace, self.hwstack

                # --- compare results ---
                if pcC != pcPy:
                    print(f"[CrossCheck] Step {step_count}: PC mismatch "
                          f"Start={pc0:04x}, C_end={pcC:04x}, Py_end={pcPy:04x}")
                if flagsC != flagsPy:
                    print(f"[CrossCheck] Step {step_count}: Flags mismatch at PC={pc0:04x} "
                           f"C={flagsC:04x}, Py={flagsPy:04x}")
                for addr, (wC, wP) in enumerate(zip(memC, memPy)):
                    if wC != wP:
                        print(f"[CrossCheck] Step {step_count}: Memory mismatch at {addr:04x} "
                              f"C={wC:04x}, Py={wP:04x}")
                        break
                for spadd, (wC, wP) in enumerate(zip(mbC, mbPy)):
                    if wC != wP:
                        print(f"[CrossCheck] Step {step_count}: Stack mismatch at {spadd:02x} "
                              f"C={wC:04x}, Py={wP:04x}")
                        break
                # --- detect HALT or stop condition ---
                halted = (rcC == 0 or rcPy == 0)  # adjust condition to your return codes
        elif context.Fast:
            return self._evalpc_c(context, dosteps)
        else:
            return self._evalpc_py(context, dosteps)

    def _evalpc_c_OLD(self, context, dosteps):
        global  PrevPC
        pc = self.pc
        PrevPC = self.pc
        ReturnCode = 0        
        if context.Debug > 0:
            if dosteps == -1:
                # Run until halt/error
                while ReturnCode == 0:
                    DissAsm(self.pc, 1, self)
                    context.GlobalOptCnt += 1                    
                    (self.pc, self.flags, ReturnCode) = cpuCfunc.EvalOne(
                        self.memspace, self.hwstack, self.pc, self.flags, 1, ReturnCode )
            else:
                # Run fixed number of steps.
                for _ in range(dosteps):
                    if ReturnCode != 0:
                        break
                    DissAsm(self.pc, 1, self)                
                    context.GlobalOptCnt += 1
                    (self.pc, self.flags, ReturnCode) = cpuCfunc.EvalOne(
                        self.memspace, self.hwstack, self.pc, self.flags, 1, ReturnCode )
        else:
            (self.pc, self.flags, ReturnCode) = cpuCfunc.EvalOne(
                self.memspace, self.hwstack, self.pc, self.flags, dosteps, ReturnCode )
            if dosteps>0:
                context.GlobalOptCnt += dosteps
        if ReturnCode != 0:
            self._handle_return_code(ReturnCode)
        return ReturnCode

    def _evalpc_c(self, context, dosteps):
        global PrevPC

        PrevPC = self.pc
        ReturnCode = 0

        # --------------------------------------------------------------
        # Helper: single instruction step
        # --------------------------------------------------------------
        def step_one():
            nonlocal ReturnCode

            PrevPC = self.pc

            # Optional debug disassembly
            if context.Debug > 0:
                DissAsm(self.pc, 1, self)
                context.GlobalOptCnt += 1

            (self.pc, self.flags, ReturnCode) = cpuCfunc.EvalOne(
                self.memspace,
                self.hwstack,
                self.pc,
                self.flags,
                1,
                ReturnCode
            )

            return ReturnCode

        # total steps to run (in normal mode)
        steps_remaining = dosteps if dosteps > 0 else None  # None = unlimited

        # --------------------------------------------------------------
        #  MAIN EXECUTION LOOP (state machine)
        #
        #  States:
        #    Debug mode       -> context.Debug > 0
        #    Normal mode      -> context.Debug == 0
        # --------------------------------------------------------------
        while True:

            # -------------------------------
            #    NORMAL MODE
            # -------------------------------
            if context.Debug == 0:

                # Fast-path for multi-step run, but only if:
                #   - more than 1 step remaining
                #   - AND no pending debug events
                if steps_remaining is not None and steps_remaining > 1:
                    # use the C batch executor for speed
                    batch = steps_remaining
                    (self.pc, self.flags, ReturnCode) = cpuCfunc.EvalOne(
                        self.memspace, self.hwstack, self.pc, self.flags, batch, ReturnCode
                    )
                    context.GlobalOptCnt += batch

                    # interpret result
                    if ReturnCode == -11:  # toggle -> enter debug mode
                        context.Debug = 1
                        steps_remaining -= batch
                        ReturnCode = 0
                        continue

                    if ReturnCode != 0:
                        break  # exit condition

                    # batch OK
                    steps_remaining = 0 if steps_remaining is not None else None
                    if steps_remaining == 0:
                        break
                    continue

                # Otherwise fall back to single-step normal execution
                rc = step_one()

                if rc == -11:
                    # toggle into debug
                    context.Debug = 1
                    ReturnCode = 0
                    continue

                if rc != 0:
                    break

                if steps_remaining is not None:
                    steps_remaining -= 1
                    if steps_remaining <= 0:
                        break

                continue

            # -------------------------------
            #    DEBUG MODE
            # -------------------------------
            else:
                rc = step_one()

                if rc == -11:
                    # toggle back to normal mode
                    context.Debug = 0
                    ReturnCode = 0
                    continue

                if rc != 0:
                    break

                # unlimited steps in debug mode
                # (normal "dosteps" does not apply unless restored after toggle)
                continue

        # --------------------------------------------------------------
        # Final exit code handler
        # --------------------------------------------------------------
        if ReturnCode not in (0, -11):
            self._handle_return_code(ReturnCode)

        return ReturnCode
    

    
    def _evalpc_py(self, context, dosteps):
        global PrevPC

        pc = self.pc & 0xFFFF
        PrevPC = pc

        mem = self.memspace
        op_func = self.op_func
        op_size = self.op_size
        getwordat = self.getwordat
        raiseerror = self.raiseerror
        debug = context.Debug
        dissasm = DissAsm
        findline = self.FindWhatLine
        optcnt = context

        if dosteps == -1:
            while True:
                pc = self.pc & 0xffff
                PrevPC = pc                
                optcode = mem[pc]
                
                func = op_func[optcode]
                
                if func is None:
                    raiseerror(
                        f"046 Optcode {optcode:02x} at File {findline(pc)}, Address({pc:04x}), is invalid"
                    )

                if context.Debug > 0:
                    dissasm(pc, 1, self)

                optcnt.GlobalOptCnt += 1

                size = op_size[optcode]
                next_pc = (pc + size) & 0xffff
                
                if size == 3:
                    argument = getwordat(pc + 1)
                else:
                    argument = 0

                self.pc = next_pc
                func(argument)
        else:
            for _ in range(dosteps):
                pc = self.pc & 0xffff
                PrevPC = pc                
                optcode = mem[pc]
                
                func = op_func[optcode]
                
                if func is None:
                    raiseerror(
                        f"046 Optcode {optcode:02x} at File {findline(pc)}, Address({pc:04x}), is invalid"
                    )

                if context.Debug > 0:
                    dissasm(pc, 1, self)

                optcnt.GlobalOptCnt += 1

                size = op_size[optcode]
                next_pc = (pc + size) & 0xffff
                
                if size == 3:
                    argument = getwordat(pc + 1)
                else:
                    argument = 0

                self.pc = next_pc
                func(argument)
        return 0
    
    
    def _handle_return_code(self, code):
        if code == RC_END_PROGRAM:
            print("Normal Exit:")
            sys.exit(0)
        elif code == RC_STACK_UNDERFLOW:
            print(f"Stack Underflow: {self.pc:04x}")
        elif code == RC_STACK_OVERFLOW:
            print(f"Stack Overflow: {self.pc:04x}")
        elif code == RC_USER_HALT:
            print(f"^C at {self.pc:04x}")
            debugger(FileLabels, "")
        elif code == RC_INVALID_INPUT:
            print(f"Non numeric User Input")
        elif code == RC_DISK_SEEK_FAIL:
            print(f"Failed to select track on device.")
        elif code == RC_DEVICE_READ_FAIL:
            print(f"Device hard read error.")
        elif code == RC_DEVICE_MEM_FAIL:
            print(f"Device requested invalid memory.")
        elif code == RC_DEVICE_WRITE_FAIL:
            print(f"Device hard write error.")
        elif code == RC_DEVICE_GENERAL_FAIL:
            print(f"Device Error (general)")
        elif code == RC_DEBUG_TOGGLE:
            print(f"Debug Toggle")
            current_context.Debug = 0 if current_context.Debug else 1 
        else:
            print("Return Code:", code)

def removecomments(inline):
    if not inline:
        return ""
    out = []
    inquote = False
    i = 0
    L = len(inline)

    while i < L:
        c = inline[i]

        # -------------------------
        # Escape handling INSIDE quotes
        # -------------------------
        if inquote and c == '\\':
            # Copy '\' and the next char literally (if any)
            if i + 1 < L:
                out.append(c)
                out.append(inline[i + 1])
                i += 2
                continue
            else:
                # '\' at end of line — keep it
                out.append(c)
                break

        # -------------------------
        # Quote toggles
        # -------------------------
        if c == '"' and not inquote:
            inquote = True
            out.append(c)
            i += 1
            continue
        elif c == '"' and inquote:
            inquote = False
            out.append(c)
            i += 1
            continue

        # -------------------------
        # Outside quotes
        # -------------------------
        if not inquote:

            # Comment starts
            if c == '#':
                break  # discard rest of input

            # Remove brackets only outside quotes,
            # BUT preserve %( and %) constructs
            if c in '()[]':

                # Preserve "%("  (previous char is '%')
                if c == '(' and i > 0 and inline[i - 1] == '%':
                    out.append(c)
                    i += 1
                    continue

                # Preserve "%)"  (previous char is '%')
                if c == ')' and i > 0 and inline[i - 1] == '%':
                    out.append(c)
                    i += 1
                    continue

                # Otherwise treat as whitespace
                i += 1
                continue

            # Normal character outside quotes
            out.append(c)
            i += 1
            continue

        # -------------------------
        # Inside quotes, normal char
        # -------------------------
        out.append(c)
        i += 1
    return ''.join(out).rstrip()    


def GetQuoted(inline):
    inquote = False
    outputtext = ""
    inescape = False
    qsize = 0
    maxlen = len(inline)


    while qsize < maxlen:
        c = inline[qsize]

        if not inquote:
            if c == '"':
                inquote = True
                qsize += 1
            else:
                # Not in a quote, and not a quote starter → invalid
                return (0, "")
            continue

        if inescape:
            escmap = {
                'n': '\n',
                't': '\t',
                'e': chr(27),
                '0': '\0',
                'b': '\b',
                '"': '"',
                '\\': '\\'
            }
            outputtext += escmap.get(c, c)
            qsize += 1
            inescape = False
        elif c == '\\':
            inescape = True
            qsize += 1
        elif c == '"':
            qsize += 1  # count closing quote
            break
        else:
            outputtext += c
            qsize += 1
    return (qsize, outputtext)

def GetRawQuoted(inline):
    outputtext=""
    qsize=0
    maxlen=len(inline)
    while qsize < maxlen:
        c=inline[qsize]
        if c != "'":
            outputtext += c
            qsize += 1
        else:
            qsize += 1
            break
    return (qsize, outputtext)
        



def nextwordplus(ltext):
    if not ltext:
        return ("", 0)
    (result, rsize) = nextword(ltext)

    # Only extend if there is more text and previous token didn’t end cleanly
    if rsize < len(ltext) and ltext[rsize - 1] not in ' ,':
        while rsize < len(ltext) and ltext[rsize] in "+-":
            (nresult, nsize) = nextword(ltext[rsize:])
            if not nresult:
                break
            result += nresult
            rsize += nsize

    return (result, rsize)

def nextwordequation(line):
    pos = 0

    result, size = nextword(line[pos:])
    pos += size

    while True:
        rest = line[pos:].lstrip()
        if not rest:
            break

        op = rest[0]
        if op not in "+-*/":
            break

        pos += len(line[pos:]) - len(rest)  # skip whitespace
        pos += 1                            # consume operator

        token, size = nextword(line[pos:])
        result = result + op + token
        pos += size

    return result, pos

def check_loss(label, before, after):
    if "%V" in before and "%V" not in after and "_V_" in after:
        print(f"[LOSS @ {label}]")
        print(f"  BEFORE: '{before}'")
        print(f"  AFTER : '{after}'")

def nextword(ltext):
    maxlen = len(ltext)
    size = 0

    # Skip leading whitespace and commas
    while size < maxlen and ltext[size] in ' ,[]':
        size += 1

    if size >= maxlen:
        return ("", 0)

    c = ltext[size]

    # ----------------------------------------
    # Special single-character tokens
    # ----------------------------------------
    if c == ";":
        return (';', size + 1)

    # ----------------------------------------
    # Quoted strings
    # ----------------------------------------
    if c == '"':
        (qsize, qtext) = GetQuoted(ltext[size:])
        return ('"' + qtext + '"', size + qsize)

    if c == "'":
        (qsize, qtext) = GetRawQuoted(ltext[size+1:])
        return ("'" + qtext + "'", size + qsize + 2)

    # ----------------------------------------
    # NEW: Handle % constructs atomically
    # ----------------------------------------
    if c == '%':
        start = size
        size += 1

        # Handle %( ... %) with nesting
        if size < maxlen and ltext[size] == '(':
            size += 1
            depth = 1

            while size < maxlen and depth > 0:
                if ltext[size:size+2] == '%(':
                    depth += 1
                    size += 2
                elif ltext[size:size+2] == '%)':
                    depth -= 1
                    size += 2
                else:
                    size += 1

            return (ltext[start:size], size)

        # Otherwise: %V, %S, %1, etc.
        # consume macro symbol core (V, S, digit, etc.)
        if size < maxlen:
            size += 1

        # NEW: consume suffix (like _SKIP, _DoCase1, etc.)
        while size < maxlen and (ltext[size].isalnum() or ltext[size] == "_"):
            size += 1

        return (ltext[start:size], size)        

    # ----------------------------------------
    # Optional leading + or -
    # ----------------------------------------
    result = ""
    if c in "+-":
        result += c
        size += 1
        if size >= maxlen:
            return (result, size)

    # ----------------------------------------
    # Normal token consumption
    # ----------------------------------------
    while size < maxlen and ltext[size] not in " ,+-[];()":
        result += ltext[size]
        size += 1

    return (result, size)

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
            CPU.raiseerror("580 Short numeric string %s is not a valid decimal value" % instr)
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
                CPU.raiseerror("590 Use of fixed value(%s) as label before defined." % instr)
        else:
            if instr.isdigit():
                result = validatestr(instr, 10)
            elif all(c in "0123456789ABCDEFabcdef" for c in instr):
                safeprint("Ambiguous value '%s': Looks like hex, but missing 0x prefix." % instr)
                result = validatestr("0x"+instr,16)
            else:
                CPU.raiseerror("600 String %s is not a valid decimal value" % instr)

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
        addr = 0 if CPU.hwstacksp < 1 else CPU.hwstacksp
        
        if CPU.hwstacksp == 0:
            addr = 0
        else:
            addr = CPU.hwstacksp
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
            tos = f"{CPU.fetchStack(0):04x}" if CPU.hwstacksp > 0 else "----"
            sft = f"{CPU.fetchStack(1):04x}" if CPU.hwstacksp > 1 else "----"
            OUTLINE = "%04x:%8s P1:%04x [I]:%04x [II]:%04x TOS[%s,%s] Z%1d N%1d C%1d O%1d SS(%d)" % (
                i, OPTSYM[optcode], P1, PI, PII,
                tos, sft, ZF, NF, CF, OF, addr
            )
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
            hexdump(i,min(i+15,bestmatch)-i,CPU)
            i = bestmatch
        else:
            i = i + OPTDICT[str(optcode)][2]
        rstring = ""
        # When debugging we might setup some Watchs for changes in known memory locations.
        if len(context.watchpoints) > 0:
            rstring = "Watch:"
            ii_list = sorted(context.watchpoints)
            for idx in range(0, len(ii_list), 1):
                ii = ii_list[idx]
                value = CPU.memspace[ii] | (CPU.memspace[ii+1].astype(int) << 8)
                rstring += " %04x:[%04x]" % (ii, value)

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

def hexdump(startaddr, length, CPU):
    endaddr = startaddr + length
    safeprint("Range is %04x to %04x" % (startaddr, endaddr))

    base = startaddr & ~0xF  # Align down to 16-byte boundary

    header = "      " + " ".join(f"{x:02x}" for x in range(16)) + "  ASCII"
    safeprint(header)

    i = base
    while i < endaddr:
        hex_part = ""
        ascii_part = ""
        line_has_data = False

        for j in range(16):
            addr = i + j
            if addr < startaddr or addr >= endaddr or addr >= len(CPU.memspace):
                hex_part += "   "
                ascii_part += " "
            else:
                line_has_data = True
                byte = CPU.memspace[addr]
                hex_part += f"{byte:02x} "
                ascii_part += chr(byte) if 32 <= byte <= 126 else "_"

        if not line_has_data:
            break  # Don’t print blank rows after the range

        safeprint(f"{i:04x}: {hex_part} {ascii_part}")
        i += 16


# Allow use of the CPUPATH OS Enviroment variable to find library directories.

def fileonpath(filename):
    import os

    cpupath = os.environ.get("CPUPATH")
    if cpupath is None:
        cpupath = ".:lib:test:."
    else:
        cpupath = ".:" + cpupath   # prepend cwd

    for testpath in cpupath.split(":"):
        candidate = os.path.join(testpath, filename)
        # Debugging
        # print("DEBUG trying", candidate)
        if os.path.exists(candidate):
            return candidate

    safeprint(f"Import Filename error, {filename} not found", file=DebugOut)
    sys.exit(-1)


def IsLocalVar(inlabel, context: AssemblerContext):

    # ---------------------------------------------
    # Internal / special symbols
    # ---------------------------------------------
    if inlabel.startswith("_"):
        return inlabel

    if inlabel.startswith("@"):
        return inlabel

    # ---------------------------------------------
    # Global symbols are NEVER mangled
    # (must use GlobalDeclarations, not GlobeLabels)
    # ---------------------------------------------
    if inlabel in context.GlobalDeclarations:
        return inlabel

    # ---------------------------------------------
    # Already mangled? Leave it alone
    # ---------------------------------------------
    if "___" in inlabel:
        return inlabel

    # ---------------------------------------------
    # Apply local mangling if in library context
    # ---------------------------------------------
    if context.LORGFLAG == LOCALFLAG:
        return f"{inlabel}___{context.LocalID}"

    return inlabel

def parse_arg(segment, filename, context):
    """
    Parse a single argument from `segment`.
    Handles literals, macro vars, and nested %( ... %).
    Returns (string_value, chars_consumed).
    """

    i = 0
    # Skip leading whitespace
    while i < len(segment) and segment[i].isspace():
        i += 1

    # Case 1: Nested %( ... %)
    if segment[i:i+2] == "%(":
        depth = 1
        j = i + 2
        while j < len(segment) and depth > 0:
            if segment[j:j+2] == "%(":
                depth += 1
                j += 2
            elif segment[j:j+2] == "%)":
                depth -= 1
                j += 2
            else:
                j += 1

        inner = segment[i+2:j-2]   # contents inside %( ... %)
        # Recursively expand/evaluate the inner block
        inner_val, _ = ReplaceMacVars(inner, filename, context)
        inner_val = Str2Word(inner_val)
        return inner_val, j  # chars consumed = whole block

    # Case 2: Single token (literal or %digit)
    token_str, size = nextword(segment[i:])
    token_expanded, _ = ReplaceMacVars(token_str, filename, context)
    token_expanded = Str2Word(token_expanded)

    return token_expanded, i + size


        
# Special case when we don't care about the size of consumed string just its result
def ReplaceMacStr(line, filename, context):
    result, _ = ReplaceMacVars(line, filename, context)
    return result

# Normally ReplaceMacVars will return modified string, and how much of the input string was consumed.
# Mostly this last value is used when there early exits from RMV like with '%)'
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
        # ============================================================
        # MACRO % HANDLER (FIXED)
        # ============================================================
        if c == "%" and not inquote:
            dprint(3,f"[TRACE % ENTRY] line='{line}' i={i}")

            # ========================================================
            # %( ... %) — MUST BE FIRST
            # ========================================================
            if i < len(line) and line[i] == "(":
                i += 1
                start = i
                depth = 1

                while i < len(line) and depth > 0:
                    if line[i] == "%" and i + 1 < len(line):
                        if line[i+1] == "(":
                            depth += 1
                            i += 2
                            continue
                        elif line[i+1] == ")":
                            depth -= 1
                            i += 2
                            continue
                    i += 1

                if depth != 0:
                    CPU.raiseerror(f"Unmatched %( ... %) in macro: {line}")

                inner = line[start:i-2]

                dprint(3,f"[TRACE %() INNER] '{inner}'")

                expanded = ReplaceMacStr(inner, filename, context)

                dprint(3,f"[TRACE %() EXPANDED] '{expanded}'")

                newline += expanded
                continue

            # ========================================================
            # EXISTING HANDLERS (UNCHANGED ORDER)
            # ========================================================

            if (line[i:i+6] == "STRLEN"):
                (tempkey,tempsize) = nextword(line[i+6:])
                tempkey=ReplaceMacStr(tempkey, filename, context)
                if tempkey[0] == '"' and tempkey[-1] == '"':
                    (_,tempkey)=GetQuoted(tempkey)
                LastMLen.append(len(tempkey))
                i=i+6+tempsize
                continue
            elif (line[i:i+1] == "P"):
                if (not MacroStack):
                    CPU.raiseerror("049 Macro Refrence Stack Underflow: %s" % line)
                i += 1
                MacroStack.pop()
                
                continue

            elif (line[i:i+1] == "S"):
                val = context.MacroVars[context.varcntstack[context.varbaseSP]]
                MacroStack.append(val)
                dprint(3,f"[PUSH %S] pushing {val} → stack={MacroStack}")
                i += 1
                continue

            elif (line[i:i+1] == "V"):
                if not MacroStack:
                    CPU.raiseerror("050 Macro Refrence not in stack: %s" % line)
                val = MacroStack[-1]
                dprint(3,f"[READ %V] using {val} → stack={MacroStack}")
                newline += val
                i += 1
                continue

            elif (line[i:i+1] == "W"):
                if (not MacroStack or len(MacroStack) < 2 ):
                    CPU.raiseerror("051 Macro Refrence Stack Underflow: %s" % line)
                newline += MacroStack[-2]
                i += 1
                continue

            elif (line[i:i+3] == "LEN"):
                if LastMLen:
                    newline += str(LastMLen.pop())
                else:
                    CPU.raiseerror("610 Macro %STRLEN/%LEN stack underflow")
                i += 4
                continue

            elif (line[i:i+4] == "LINE"):
                newline += "\"" + f"{context.ActiveFile}:{context.FileLineNum+1}" + "\""
                i += 5
                continue

            elif (line[i:i+6] == "REPEAT"):
                i += 7
                (count_str, size) = nextword(line[i:])
                i += size
                count_str = ReplaceMacStr(count_str, filename, context)
                repeat_count = Str2Word(count_str)

                nest = 1
                block_start = i
                search_pos = block_start

                while nest > 0:
                    next_repeat = line.find("%REPEAT", search_pos)
                    next_endr   = line.find("%ENDR", search_pos)

                    if next_endr == -1:
                        CPU.raiseerror("620 Macro %REPEAT missing %ENDR terminator")

                    if next_repeat != -1 and next_repeat < next_endr:
                        nest += 1
                        search_pos = next_repeat + 7
                    else:
                        nest -= 1
                        search_pos = next_endr + 5

                block_end = search_pos - 5
                block = line[block_start:block_end]

                for rc in range(repeat_count):
                    newline += ReplaceMacStr(block, filename, context)

                i = search_pos
                continue

            elif line[i:i+1] == "(":
                i += 1
                R1, subsize = ReplaceMacVars(line[i:], filename, context)
                newline += R1
                i += subsize
                if i < len(line) and line[i] == "%":
                    i += 1
                continue

            elif line[i:i+1] == ")":
                i += 1
                return newline, i+1

            elif line[i:i+3] == "AND":
                i += 3
                while i < len(line) and line[i].isspace():
                    i += 1
                v1, used1 = parse_arg(line[i:], filename, context)
                i += used1
                while i < len(line) and line[i].isspace():
                    i += 1
                v2, used2 = parse_arg(line[i:], filename, context)
                i += used2
                newline += str(int(v1) & int(v2))
                continue

            elif line[i:i+2] == "OR":
                i += 2
                v1, used1 = parse_arg(line[i:], filename, context)
                i += used1
                v2, used2 = parse_arg(line[i:], filename, context)
                i += used2
                return str(v1 | v2), i

            elif line[i:i+5] == "Field":
                i += 5
                while i < len(line) and line[i].isspace():
                    i += 1
                v1, used1 = parse_arg(line[i:], filename, context)
                i += used1
                while i < len(line) and line[i].isspace():
                    i += 1
                v2, used2 = parse_arg(line[i:], filename, context)
                i += used2
                while i < len(line) and line[i].isspace():
                    i += 1
                v3, used3 = parse_arg(line[i:], filename, context)
                i += used3
                mask = (1 << v2) - 1
                newline += str((v3 & mask) << v1)
                continue

            elif line[i:i+3] == "Bit":
                i += 3
                while i < len(line) and line[i].isspace():
                    i += 1
                v1, used1 = parse_arg(line[i:], filename, context)
                i += used1
                while i < len(line) and line[i].isspace():
                    i += 1
                v2, used2 = parse_arg(line[i:], filename, context)
                i += used2
                newline += str((v2 & 1) << v1)
                continue

            elif line[i:i+1].isdigit():
                varval = int(line[i])
                base = context.varcntstack[context.varbaseSP]
                idx = base + varval

                dprint(3,f"[TRACE %DIGIT] %{varval} base={base} idx={idx}")

                if idx >= len(context.MacroVars):
                    CPU.raiseerror(f"052 Macro %{varval} not defined")

                val = context.MacroVars[idx]
                newline += val
                i += 1
                continue

            else:
                # ====================================================
                # FIXED FALLBACK (this fixes your % _ bug)
                # ====================================================
                start = i - 1

                while i < len(line) and (line[i].isalnum() or line[i] == "_"):
                    i += 1

                literal = line[start:i]

                dprint(3,f"[TRACE %FALLBACK] preserving '{literal}'")

                newline += literal
                continue
        else:
            newline = newline + c
    return newline, i
            

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
        lookup = IsLocalVar(value[0:], context)

        if lookup in context.FileLabels:
            value = Str2Word(context.FileLabels[lookup])
        elif lookup in context.GlobeLabels:
            value = Str2Word(context.GlobeLabels[lookup])            
        else:
            CPU.raiseerror(
                "055 Line %s, : %s Can not use label that is not yet definied in first pass of assembler." %
                (context.GlobalOptCnt, value))
    else:
        value=Str2Word(value)
    return (value, size)


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

    if "%" in token:
        dprint(3,f"[TRACE decode_token] token='{token}' at {context.ActiveFile}:{context.FileLineNum}")

    if token == "":
        return("value",0)

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
        return ("value", Str2Word(context.FileLabels[labelname]))

    localkey = IsLocalVar(labelname, context)

    if localkey in context.FileLabels:
        return ("value", Str2Word(context.FileLabels[localkey]))

    # NEW: historical lookup
    value = FindHistoricVal(localkey, curaddress, context)
    if value is not None:
        return ("value", Str2Word(value))
    else:
        # Unresolved label — mark for second pass        
        newkey = localkey
        if not newkey:
            safeprint(f"Warning: Empty labe; refreces at {context.ActiveFile}:{context.FileLineNum+1}",file=DebugOut)
            return("value",0)
        return ("unresolved",newkey)


def handle_macro_invocation(line, filename, context, CPU):

    cpos = 1
    (macname, size) = nextword(line[cpos:])
    cpos += size

    context.varbaseSP = context.varbaseNext

    # Ensure space exists
    while context.varcntstack[context.varbaseSP] >= len(context.MacroVars):
        context.MacroVars.append('0')

    # 🔥 Assign %0 ONCE per macro invocation
    unique_id = "_" + create_new_unique()
    context.MacroVars[context.varcntstack[context.varbaseSP]] = unique_id
    dprint(3,f"[MACRO ENTER] {macname} %0={unique_id}  stack={MacroStack}")

    if macname not in context.MacroData:
        safeprint("Missing macro:", macname, file=DebugOut)
        CPU.raiseerror("630 Macro %s is not defined %s:%s" %
                       (macname, filename, context.FileLineNum))
        return ""
    context.MacroLine = context.MacroData[macname].strip() + \
        " ENDMACENDMAC " + context.MacroLine

    varcnt = 0
    if cpos < len(line) and context.MacroPCount[macname] > 0:
        # Parse arguments
        while varcnt < context.MacroPCount[macname] and cpos < len(line):
            snippet = line[cpos:].lstrip()
            cpos += len(line[cpos:]) - len(snippet)
            if snippet.startswith("%("):
                # Balanced expression as one argument
                depth = 1
                j = cpos + 2
                while j < len(line) and depth > 0:
                    if line[j:j+2] == "%(":
                        depth += 1
                        j += 2
                    elif line[j:j+2] == "%)":
                        depth -= 1
                        j += 2
                    else:
                        j += 1
                if depth != 0:
                    CPU.raiseerror("640 Unmatched %(...%) in macro argument")
                key = line[cpos:j]
                size = j - cpos
                cpos = j
                while cpos < len(line) and line[cpos].isspace():
                    cpos += 1
            else:
                (key, size) = nextwordplus(line[cpos:])
                cpos += size

            raw = key.strip()[1:-1] if (key.startswith('"') and key.endswith('"')) else key
            while cpos < len(line) and line[cpos] in ' ,\t':
                cpos += 1

            varcnt += 1

            # Ensure MacroVars stack has space
            while (context.varcntstack[context.varbaseSP] + varcnt + 2) >= len(context.MacroVars):
                context.MacroVars.append('0')

            if key.startswith('"') and key.endswith('"'):
                context.MacroVars[varcnt + context.varcntstack[context.varbaseSP]] = \
                    '"' + escape_for_reinsertion(raw) + '"'
            elif key.startswith("'") and key.endswith("'"):
                context.MacroVars[varcnt + context.varcntstack[context.varbaseSP]] = \
                    "'" + raw + "'"
            else:
                context.MacroVars[varcnt + context.varcntstack[context.varbaseSP]] = key
        # Argument count check (runs even for 0-arg macros)
        if varcnt < context.MacroPCount[macname]:
            CPU.raiseerror("650 Insufficient required parameters (%s/%s) for Macro %s %s:%s" %
                           (varcnt, context.MacroPCount[macname], macname, filename, context.FileLineNum))

    # Bookkeeping — always run
    context.varcntstack[context.varbaseSP + 1] = context.varcntstack[context.varbaseSP] + varcnt + 1
    context.varbaseNext = context.varbaseSP + 1
    context.ActiveMacro = True
    context.ActiveMacroName = macname

    # Preserve any remainder of this line to expand after macro finishes
    if cpos < len(line):
        remainder = line[cpos:].lstrip()
        if remainder:
            context.backfill = remainder + " " + context.backfill                                
    line = ""


def normalize_token(val):
    if isinstance(val, tuple):
        return val
    return ("value", val)
    


def DecodeStr(instr, curaddress, CPU, JUSTRESULT, context: AssemblerContext):

    # Direct string handling (base case, no parsing)
    if ((instr.startswith('"') and instr.endswith('"')) or (instr.startswith("'") and instr.endswith("'"))) and not JUSTRESULT:
        midtext = instr[1:-1]
        for c in midtext:
            CPU.memspace[curaddress] = (int(ord(c)) & 0xff)
            curaddress += 1
        return curaddress

    elif instr.startswith('"') and JUSTRESULT:
        safeprint("String values can't be modified or used as numeric results", file=DebugOut)
        return 0

    #----------------------------------------
    # Parse expression
    #----------------------------------------
    prefix, base_token, modifiers = parse_expression(instr)

    #----------------------------------------
    # Detect deferred label + delta case
    #----------------------------------------
    if not JUSTRESULT and prefix in ('', '$'):

        base_result = decode_token(base_token, curaddress, CPU, True, context)

        # If unresolved symbol -> defer
        if isinstance(base_result, tuple) and base_result[0] == "unresolved":
            raw_label = base_result[1]

            # Ensure proper scoping (safe even if already scoped)
#            resolved_label = IsLocalVar(raw_label, context)
            resolved_label = raw_label
            delta = 0
            for mod in modifiers:
                op = mod[0]
                token = mod[1:].strip()

                sign = 1 if op == '+' else -1

                val = decode_token(token, curaddress, CPU, True, context)

                if not isinstance(val, tuple) or val[0] != "value":
                    CPU.raiseerror(f"660 Invalid modifier in expression: {mod}")

                delta += sign * val[1]

    
            # Store for second pass (symbol, address, delta)

            context.FWORDLIST.append((resolved_label, curaddress, delta))
            if context.Debug > 1:
                print(f"REF {resolved_label} at addr {curaddress:04x} with delta {delta} from {context.ActiveFile}:{context.FileLineNum}")
            

            # Reserve space (word = 2 bytes)
            CPU.memspace[curaddress] = 0
            CPU.memspace[curaddress + 1] = 0

            curaddress += 2

            if context.highwater < curaddress:
                context.highwater = curaddress

            return curaddress

    #----------------------------------------
    # Evaluate base token normally
    #----------------------------------------
    base_result = decode_token(base_token, curaddress, CPU, JUSTRESULT, context)


    if not isinstance(base_result, tuple):
        CPU.raiseerror(f"670 Internal error: decode_token returned non-tuple: {base_result}")

    if base_result[0] == "value":
        result = base_result[1]

    elif base_result[0] == "string":
        return base_result[1]

    elif base_result[0] == "unresolved":
        CPU.raiseerror(f"680 Internal error: unresolved symbol '{base_result[1]}' reached evaluation stage")
    else:
        CPU.raiseerror(f"690 Unknown token type: {base_result[0]}")


    #----------------------------------------
    # Apply modifiers
    #----------------------------------------
    for mod in modifiers:
        sign = 1 if mod[0] == '+' else -1
        token=mod[1:].strip()
        base_mod = decode_token(token, curaddress, CPU, JUSTRESULT, context)

        if not isinstance(base_mod, tuple) or base_mod[0] != "value":
            CPU.raiseerror(f"700 Invalid Modifier in expression: {mod}")
        result += sign * base_mod[1]

    #----------------------------------------
    # Return result only (no write)
    #----------------------------------------
    if JUSTRESULT:
        return result

    #----------------------------------------
    # Memory writing based on prefix
    #----------------------------------------
    # $$ => byte (8bit)
    # $$$ => long (32bit)
    # $ or none => word (16 bit, default)
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

    else:  # default or $
        CPU.memspace[curaddress]     = result & 0xFF
        CPU.memspace[curaddress + 1] = (result >> 8) & 0xFF
        curaddress += 2

    if context.highwater < curaddress:
        context.highwater = curaddress

    return curaddress

def IsUserSymbol(sym):
    # Hide compiler-generated symbols
    if sym.startswith("__"):
        return False

    # Hide mangled locals
    if "___" in sym:
        return False

    return True

def IsCompilerGenerated(sym):
    return (
        sym.startswith("_J_") or
        sym.startswith("_U_") or
        sym.startswith("__")
    )

def FinalSymbolReport(context):
    
    print("\n=== Symbol Resolution Report ===")

    # -----------------------------------------
    # Build final symbol sets
    # -----------------------------------------
    defined = set(context.GlobeLabels.keys())   # keep for reporting only
    declared = context.GlobalDeclarations
    used = set(context.UsedSymbols.keys())
    resolved = getattr(context, "ResolvedSymbols", set())

    unresolved = used - resolved

    undefined_globals = sorted(sym for sym in unresolved if sym in declared)
    missing_symbols = sorted(sym for sym in unresolved if sym not in declared)
    print("DEBUG:",
      "used=", len(used),
      "resolved=", len(resolved),
      "unresolved=", len(unresolved))


    # -----------------------------------------
    # Declared globals not defined
    # -----------------------------------------
    if undefined_globals:
        print("\n=== Declared Global but NOT Defined ===")

        for sym in undefined_globals:
            count = context.UsedSymbols.get(sym, 0)
            print(f"  {sym}  (used {count} times)")

            # Show where it was declared
            if hasattr(context, "GlobalDeclInfo") and sym in context.GlobalDeclInfo:
                file, line = context.GlobalDeclInfo[sym]
                print(f"     declared at {file}:{line}")

    # -----------------------------------------
    # Missing symbols (likely missing @USE)
    # -----------------------------------------
    if missing_symbols:
        print("\n=== Missing Symbols (likely missing @USE) ===")

        for sym in missing_symbols:
#            if not IsUserSymbol(sym):
#                continue

            count = context.UsedSymbols.get(sym, 0)

            print(f"\n  {sym}  (used {count} times)")

            refs = context.MissingSymbols.get(sym, {}).get("refs", [])

            for (file, line, addr) in refs[:5]:
                if line is not None:
                    print(f"     at {file}:{line} (addr {addr:#04x})")
                else:
                    print(f"     at {file} (addr {addr:#04x})")

            if len(refs) > 5:
                print(f"     ... {len(refs) - 5} more")

            print(f"     suggestion: @USE {sym}")

    # -----------------------------------------
    # Summary
    # -----------------------------------------
    print("\n=== Summary ===")
    print(f"  Defined symbols   : {len(defined)}")
    print(f"  Used symbols      : {len(used)}")
    print(f"  Unresolved symbols: {len(unresolved)}")

    if not unresolved:
        print("  ✔ All symbols resolved")            


# Load file is also the effective main loop for the assembler


# def loadfile(filename, offset, CPU, LorgFlag,  LocalID, context: AssemblerContext):

def loadfile(filename, offset, CPU, LorgFlag,  LocalID, context: AssemblerContext):
    global FileLineData

    if context.Debug > 1:
        print(f"Load file: {filename} Starts Address: {offset:04x}")

    gflag = context.LORGFLAG
    prior_localid = context.LocalID
    prior_activefile = context.ActiveFile
    prior_lorgflag = context.LORGFLAG

    context.LORGFLAG = LorgFlag
    if LorgFlag == LOCALFLAG:
        context.LocalID = LocalID
    else:
        context.LocalID = None
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
        context.varcntstack = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        varcnt = 0
        context.MacroLine = ""
        varpos = 0
        if context.Debug > 1:
            safeprint("Reading Filename %s" % wfilename,file=DebugOut)
        while True:

            if not hasattr(context, "_loop_counter"):
                context._loop_counter = 0
            context._loop_counter += 1


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
                    old_line=line
                    outline, used = ReplaceMacVars(line, filename, context)
                    line = outline
                    check_loss("ReplaceMacVars", old_line, line)

                    context.MacroLine.strip()
                    context.varbaseNext = context.varbaseSP
                    context.varbaseSP -= 1 if context.varbaseSP > 0 else 0
                    if PosParams == "ENDMACENDMAC":
                        # As macro's may call other macros, we need to mark in the stream where they end.
                        context.MacroLine = context.MacroLine[PosSize:]
                    line = line + " " + context.backfill
                    context.backfill = ""
                    context.ActiveMacro = False
                else:
                    line = context.backfill
                    context.backfill = ""
                    context.ActiveMacro = False
                    continue
            else:
                # If we are macro, or in plain text, we still end up here.
                context.LastLineText = line
                if line == "":
                    ExitOut = False
                    GetAnother = True
                    context.CurrentLineBeingParsed = context.FileLineNum
                    while GetAnother:
                        context.FileLineNum += 1
                        context.UniqueLineNum += 1
                        GetAnother = False
                        inline = infile.readline()
                        if current_context.Debug > 1 and inline.strip():
                            safeprint(f"{context.ActiveFile}:{context.FileLineNum+1} MS({len(context.MacroBlockStack)}) {inline.strip()}")
                        FileLineData.add_entry(filename, context.CurrentLineBeingParsed, context.address)
                        context.AddressedLinesSeen.add(context.address)                        
                        if inline:
                            inline = removecomments(inline).strip()
                            if inline.strip()[-1:] == '\\':
                                GetAnother = True
                                line = line + " " + inline.strip()[:-1]
                            else:
                                line = line + " " + inline.strip()
                        else:
                            ExitOut = True
                            break
                    if ExitOut:
                        break
            line = removecomments(line).strip()

            if not line:
                continue

            if "%V" not in line and "_V_" in line:
                dprint(3,f"[TRACE LOST %] line became: '{line}'")
            key, size = nextwordplus(line)
            if key.startswith("@"):
                line = handle_macro_invocation(line, filename, context, CPU)
                continue

            if key == "M" and context.is_executing():
                line=context.handle_macro_definition(line[size:])
                continue

            if key == "M" and not  context.is_executing():
                line = ""
                continue

            # ----- CONDITIONAL START -----
            if key in MACRO_CONDITIONAL:

                parent_exec = context.is_executing()

                if parent_exec:
                    result, consumed = context.evaluate_condition(key, line)
                    context.push_block(result)
                else:
                    consumed=size
                    context.push_block(False)
                line = line[consumed:].lstrip()
                continue
            # ----- ELSEBLOCK -----
            if key == "ELSEBLOCK":
                line = line[size:]

                block = context.current_block()
                if block is None:
                    raise RuntimeError("ELSEBLOCK without matching IF")

                if block["else_seen"]:
                    raise RuntimeError("Multiple ELSEBLOCK in same block")

                block["else_seen"] = True

                if context.parent_executing():
                    block["executing"] = not block["executing"]
                else:
                    block["executing"] = False

                continue
            line = line[size:]            
            # ----- ENDBLOCK -----
            if key == "ENDBLOCK":
                if context.Debug > 2:
                    print(f"[MB STACK] depth={len(context.MacroBlockStack)}")
                    for b in context.MacroBlockStack[-5:]:
                        print(f"   id={b['id']} type={b['type']} exec={b['executing']} "
                              f"@ {b['line']}")
                context.pop_block()
                continue
            # Execution guard if inside skipping block.
            if not context.is_executing():
                continue 
            
            if len(key) > 1:
                IsOneChar = False
            else:
                IsOneChar = True

            if key[0] == "^":
                if key[1] >= "0" and key[1] <= "4":
                    context.Debug=int(key[1])
                line=line[size:]
                continue


            if key[0] == ":":
                # ---------------------------------------------
                # Parse label name (supports ":FOO" and ": FOO")
                # ---------------------------------------------
                if len(key) > 1:
                    DestKey = key[1:]
                else:
                    (DestKey, size) = nextword(line)
                    line = line[size:].lstrip()

                SrcVal = context.address

                # ---------------------------------------------
                # Generate mangled/local-safe name
                # ---------------------------------------------
                newitem = IsLocalVar(DestKey, context)

                # ---------------------------------------------
                # Remove auto-generated line label if present
                # ---------------------------------------------
                auto_label = f"F.{filename}:{context.FileLineNum}"
                if auto_label in context.FileLabels:
                    del context.FileLabels[auto_label]

                # ---------------------------------------------
                # Store definition (always mangled internally)
                # ---------------------------------------------
                context.FileLabels[newitem] = SrcVal
                context.DefinedSymbols.add(newitem)

                # ---------------------------------------------
                # If declared global, export unmangled name
                # ---------------------------------------------
                if DestKey in context.GlobalDeclarations:
                     context.GlobeLabels[DestKey] = SrcVal
                     if context.Debug > 1 and context.Debug < 3:
                         print(f"[LABEL] {DestKey} = {SrcVal:04x}")
                     context.DefinedSymbols.add(DestKey) 



                # ---------------------------------------------
                # Track history/debug
                # ---------------------------------------------
                UpdateVarHistory(newitem, SrcVal, SrcVal)

                if current_context.Debug > 2:
                    safeprint(
                        f"DEF ':' {DestKey} -> {newitem} @ {SrcVal:#04x} "
                        f"{current_context.ActiveFile}:{current_context.FileLineNum + 1}"
                    )

                continue

            elif key.startswith(";"):
                line = handle_semicolon(line, filename, context, CPU)
                continue
            elif key[0] == ";--disable":
                if len(key)>1:           # Handle cases were no space followed key
                    DestKey=key[1:]                    
                elif len(key) == 1:
                    (DestKey, size) = nextwordequation(line)
                    line=line[size:].lstrip()
                (dsize,size) = nextword(line)
                line = line[size:]                    
                if context.DataSegment != -1:
                    # If context.DataSegment was defined, the we use a seperate dataaddress counter
                    workingaddress=context.dataaddress
                    context.ExpectData=Str2Word(dsize)   # Defines how many bytes to expect goes into the dataaddress
                else:
                    context.ExpectData=0
                    workingaddress=context.address
                if ("F."+filename+":"+str(context.FileLineNum) in context.FileLabels):
                    # We created an internal label for each line number, but this label will replace it.
                    del context.FileLabels["F."+filename+":"+str(context.FileLineNum)]
                newitem = {IsLocalVar(DestKey,  context): workingaddress}
                context.FileLabels.update(newitem)
                UpdateVarHistory(newitem,workingaddress,workingaddress)

            elif key[0] == "=":
                if len(key)>1:           # Handle cases were no space followed key
                    DestKey=key[1:]
                elif len(key) == 1:
                    (DestKey, size) = nextword(line)
                    line = line[size:]
                expanded_line, _ = ReplaceMacVars(line, filename, context)
                (value, size) = nextwordequation(expanded_line)
                line=line[size:]
                if not value.isdecimal():
                    value_expand, _ = ReplaceMacVars(value, filename, context)
                    value = DecodeStr(value_expand, context.address, CPU, True, context)
                newitem=IsLocalVar(DestKey, context)                
                context.FileLabels.update({newitem: value})
                UpdateVarHistory(newitem,value,context.address)
                if current_context.Debug > 2:
                    safeprint(f"DEF '=' {DestKey} -> {newitem} @ {value} {current_context.ActiveFile}:{current_context.FileLineNum+1}")
                continue
            elif ( key[0] == "." and IsOneChar) or (key[:4].upper() == ".ORG" and len(key) == 4):
                (value, size) = FirstPassVal(line,  context)
                line = line[size+1:] # at this point value is #val of 1st label or constant.
                # We should also allow label or constant values be modified with +/- another label or constant
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

            elif ( key[:5].upper() == ".DATA" and len(key) == 5):
                (Value, size) = FirstPassVal(line, context)
                context.DataSegment = value
                context.dataaddress = context.DataSegment
                line=line[size+1:]
                continue
            elif key[0] == "L" and IsOneChar:
                # Load a file into memory as a library, enable 'local' variables.
                (newfilename, size) = nextword(line)
                HoldGlobeLine = context.FileLineNum
                oldfilename = context.ActiveFile
                NewLocalID = str(context.UniqueLineNum)+newfilename
                context.highaddress = context.address = \
                    loadfile(newfilename, context.address, CPU , LOCALFLAG, NewLocalID, context)
                context.ActiveFile = oldfilename
                context.FileLineNum = HoldGlobeLine
                line = line[size+1:]
                continue
            elif key[0] == "I" and IsOneChar:
                # Load a file, but keep it in the 'global' context
                (newfilename, size) = nextword(line)
                HoldGlobeLine = context.FileLineNum
                oldfilename = context.ActiveFile
#                    NewLocalID = str(context.UniqueLineNum)+newfilename
                # Force GLOBAL Scope for INCLUDES
                save_largflag = context.LORGFLAG
                save_localid = context.LocalID                    
                context.highaddress = context.address = \
                    loadfile(newfilename, context.address, CPU , GLOBALFLAG, context.LocalID, context)
                context.LORGFLAG = save_largflag
                context.LocalID = save_localid

                context.ActiveFile = oldfilename
                context.FileLineNum = HoldGlobeLine
                line = line[size+1:]
                continue
            elif key[0] == "P" and IsOneChar:
                # "P" Print debug messages durring assembly.
                pos = 0
                nline = ""
                while pos < len(line):
                    word,size = nextwordplus(line[pos:])
                    if word == ";":
                        pos += size
                        break
                    word=word.strip()
                    if ( word.startswith("{") and word.endswith("}") ):

                        if word[1:-1] in context.MacroData:
                            PosVar=context.MacroData[word[1:-1]]
                        else:
                            PosVar=FindHistoricVal(word[1:-1], context.address, context)
                        if (PosVar != None):
                            nline=f"{nline} {PosVar} "
                        else:
                            nline=f"{nline} Undef#"

                    else:
                        nline=f"{nline} {word} "
                    pos += size
                line = line[pos:].lstrip()
                safeprint(nline)
                continue
            elif key[0:2] == "MA" and len(key) == 2:
                # MA macros append text to an existing macro.
                substr = line
                (key,ksize) = nextword(substr)
                substr=substr[ksize:].lstrip()
                (value,vsize) = nextword(substr)
                line=substr[vsize:].lstrip()
                oldval=context.MacroData[key]
                context.MacroData.update({key: oldval+" "+value})
                context.MacroPCount.update({key: 0})                    
            elif key[0:2] == "MF" and len(key) == 2:
                # MF Macro is for setting, or freeing single value macros. For use as flags
                substr = line
                (key,ksize) = nextword(substr)
                substr=substr[ksize:].lstrip()
                (value,vsize) = nextword(substr)
                line=substr[vsize:].lstrip()
                if (value == '""'):
                    # empty string, erase existing macro named key, if any
                    context.MacroData.pop(key,None)
                    context.MacroPCount.pop(key,None)
                else:
                    # Otherwise inerset a simple one word or value to enable the MacroKey
                    context.MacroData.update({key: value})
                    context.MacroPCount.update({key: 0})
            elif key[0] == "G" and IsOneChar:
                # Globale labels are an override of 'Local' Labels by 'pre-defining them.                
                (key, size) = nextword(line)
                if key in context.GlobalDeclInfo and context.Debug > 2:
                    print(f"WARNING: duplicate global declaration of {key} "
                          f"(first at {context.GlobalDeclInfo[key]}, "
                          f"again at {current_context.ActiveFile}:{current_context.FileLineNum})")                
                context.GlobalDeclarations.add(key)
                # Optional debug info (recommended)
                if not hasattr(context, "GlobalDeclInfo"):
                    context.GlobalDeclInfo = {}

                context.GlobalDeclInfo[key] = (
                    current_context.ActiveFile,
                    current_context.FileLineNum
                )
                line = line[size:]
                continue
            else:
                # Pretty much every else drops here to be evaulated as numbers or macros to be defined.
                # Note than nearly everything here will take up some sort of storage, so address will
                # be incremented. This is where labels become 'variables'
                context.CurrentLineBeingParsed = context.FileLineNum
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
        #
        #
        # --------------------------------------------------
        # Resolve forward references (FWORDLIST)
        # --------------------------------------------------

        context.GlobeLabels["_END_"] = context.highwater

        # Ensure tracking structures exist
        if not hasattr(context, "UsedSymbols"):
            from collections import defaultdict
            context.UsedSymbols = defaultdict(int)

        if not hasattr(context, "MissingSymbols"):
            context.MissingSymbols = {}

        if not hasattr(context, "ResolvedSymbols"):
            context.ResolvedSymbols = set()

        # --------------------------------------------------
        # Resolve forward references
        # --------------------------------------------------

        for store in context.FWORDLIST:
            key = store[0]
            vaddress = store[1]

            if context.Debug > 1 and context.Debug < 3:
                found = key in context.GlobeLabels
                val = context.GlobeLabels[key] if found else None
                dprint(3,f"[CHECK] addr={vaddress:04x} symbol={key} found={found} value={val}")

                # Track usage
            if not IsCompilerGenerated(key):
                context.UsedSymbols[key] += 1

            resolved = False

            # --------------------------------------------------
            # Try resolving from local labels
            # --------------------------------------------------
            if key in context.FileLabels:
                v = Str2Word(context.FileLabels[key])
                resolved = True

            # --------------------------------------------------
            # Try resolving from global labels
            # --------------------------------------------------
            elif key in context.GlobeLabels:
                v = Str2Word(context.GlobeLabels[key])
                resolved = True

            # --------------------------------------------------
            # If resolved, write to memory
            # --------------------------------------------------
            if vaddress == 0x7f4b:
                dprint(3,f"[CHECK] addr={vaddress:04x} symbol={key} resolved={resolved}")
            
            if resolved:
                context.ResolvedSymbols.add(key)   # <-- ADD THIS LINE ONLY

                if len(store) > 2 and store[2] != 0:
                    v = v + Str2Word(store[2])
                CPU.memspace[int(vaddress)] = CPU.lowbyte(v)
                CPU.memspace[int(vaddress + 1)] = CPU.highbyte(v)
                        
    if context.Debug > 1:
        i = 0
    if context.address > context.highaddress:
        context.highaddress = context.address
    if context.dataaddress > context.highaddress:
        context.highaddress = context.dataaddress
        # --- CLOSE LOCAL LABEL LIFETIMES AT LIBRARY EXIT ---
    if context.LORGFLAG == LOCALFLAG:
        CloseLocalHistories(context.LocalID, context.highaddress)

    context.LORGFLAG = prior_lorgflag
    context.LocalID = prior_localid
    context.ActiveFile = prior_activefile
    return context.highaddress

def CloseLocalHistories(local_id, end_address):
    global LocVarHist

    suffix = "___" + str(local_id)
    end_address = int(end_address)

    for name, history in LocVarHist.items():
        if suffix not in name:
            continue

        for entry in history:
            if entry.get("end") is None:
                entry["end"] = end_address

def debugger(passline, context: AssemblerContext):
    global InDebugger, breakpoints, tempbreakpoints, EchoFlag, watchbreaks
    startrange = 0
    stoprange = 0
    redoword = "Null"
    InDebugger = True
    size = 0
    cmdword = ""
    # Main Loop of debugger
    while True:
        sys.stdout.write("%04x> " % CPU.pc)
        _fd = sys.stdin.fileno()
        if EchoFlag:
            restore_tty()
            safeprint("\x1b[?1000l\x1b[?25h\n")
            EchoFlag=False
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
        if cmdword.upper() == "REM":
            thisword=" "
        while thisword != "":            
            rawlist.append(thisword)
            if not looks_numeric(thisword) and (thisword[0].isalpha() or thisword[0] == "_"):
                varval = FindHistoricVal(thisword, CPU.pc, context)
                if varval != None:
                    arglist.append(varval)
                    argcnt += 1
            else:
                Signval=0
                if thisword[0] in "+-":
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
            if cmdword.upper() == "BWHEN" and thisword in ("==","!=","b==","b!="):
                rawlist.append(thisword)
                thisword="0"
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
            depth = CPU.hwstacksp

            if depth == 0:
                safeprint("Empty Stack")
                continue

            safeprint(f"HW Stack Depth: {depth}\n")
            safeprint("Idx Value   Mem[v]  Mem[Mem[v]]")
            safeprint("-------------------------------")

            for idx in range(0, min(depth, 64)):

                v = CPU.fetchStack(idx)

                mem1 = None
                mem2 = None

                if 0 < v < (len(CPU.memspace) - 2):
                    mem1 = CPU.getwordat(v)

                    if 0 < mem1 < (len(CPU.memspace) - 2):
                        mem2 = CPU.getwordat(mem1)

                mem1_str = f"{mem1:04x}" if mem1 is not None else "----"
                mem2_str = f"{mem2:04x}" if mem2 is not None else "----"

                tos_marker = " <- TOS" if idx == 0 else ""

                safeprint(
                    f"{CPU.hwstacksp-idx:3d} {v:04x}    {mem1_str:>4}    {mem2_str:>4}{tos_marker}"
                )
            continue
        if cmdword == "spush":
            if argcnt > 0:
                if (CPU.hwstacksp > len(self.hwstack)):
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
        if cmdword == "range":
            if argcnt >= 2:
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
                       if isinstance(ci, int):
                           c=ci
                       else:
                           c=ord(ci)
                       if ((c != 0x7f) & (((c & 0xc0) == 0x40) | ((c & 0xe0) == 0x20))):
                           SInfo += "%c" % c
                       else:
                           SInfo += "_"
                   safeprint(SInfo)
            else:
                safeprint("ERR: Need to specify what Range print")
            continue
        if cmdword == "p":
           if argcnt > 0:
               # For each argument, print that address independently.
               for arg in arglist:
                   try:
                       if isinstance(arg, int):
                           v = int(arg)
                       else:
                           v = int(arg, 0)    # string with base auto-detect
                   except Exception as e:
                       safeprint(f"ERR: Invalid address: {arg} ({e})")
                       continue

                   # Build the print string (existing logic preserved)
                   SInfo = "%04x:" % v
                   w1 = CPU.getwordat(v)
                   w2 = CPU.getwordat(w1)

                   SInfo += "[%02x]" % w1
                   SInfo += "[[%02x]]" % w2
                   SInfo += "  "

                   # Use your original char-display logic
                   char_items = (
                       "'", v & 0xff, (v >> 8) & 0xff, "'",
                       "[",
                       "'", w1 & 0xff, (w1 >> 8) & 0xff, "'", "]",
                       "[",
                       "[", "'", w2 & 0xff, (w2 >> 8) & 0xff, "'", "]", "]"
                   )

                   for ci in char_items:
                       if isinstance(ci, int):
                           c = ci
                       else:
                           c = ord(ci)

                       # Your printable-char detection
                       if ((c != 0x7f) & (((c & 0xc0) == 0x40) |
                                          ((c & 0xe0) == 0x20))):
                           SInfo += "%c" % c
                       else:
                           SInfo += "_"

                   safeprint(SInfo)

               continue

           # no args
           safeprint("ERR: Need to specify one or more addresses")
           continue
        if cmdword == "pa":
           # Filter labels
           filtered_labels = {
               key: value for key, value in context.FileLabels.items()
               if not key.startswith("_")
               and not key.startswith("F.")
               and not key.startswith("M.")
           }

           import re
           rows = []

           for key, value in filtered_labels.items():
               value_str = str(value)
               if not rawlist or any(
                   re.search(pattern, key) or re.search(pattern, value_str)
                   for pattern in rawlist
               ):
                   active = "Y" if IsLabelActive(key, CPU.pc) else "N"
                   rows.append((key, f"{int(value):04x}", active))

           # Determine column widths
           name_width  = max(len("Name"),  max(len(k) for k, _, _ in rows)) if rows else len("Name")
           value_width = max(len("Value"), max(len(v) for _, v, _ in rows)) if rows else len("Value")
           act_width   = len("Active")

           # Build the table
           table = (
               f"| {'Name'.ljust(name_width)} | "
               f"{'Value'.ljust(value_width)} | "
               f"{'Active'.ljust(act_width)} |\n"
           )
           table += (
               f"|{'-'*(name_width+2)}|"
               f"{'-'*(value_width+2)}|"
               f"{'-'*(act_width+2)}|\n"
           )

           for k, v, a in rows:
               table += (
                   f"| {k.ljust(name_width)} | "
                   f"{v.ljust(value_width)} | "
                   f"{a.ljust(act_width)} |\n"
               )

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
                        mvalue = int(iad) >> 8
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
                                safeprint("End Modify")
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
                stopaddr = (startaddr + 3) & 0xffff

            # If only start address found, compute default end
            if startaddr is not None and stopaddr is None:
                stopaddr = (startaddr + 3) & 0xffff

                # Validate range
            if startaddr is not None and stopaddr is not None:
                if stopaddr < startaddr:
                    stopaddr = startaddr + abs(stopaddr)
                elif stopaddr == startaddr:
                    stopaddr = (startaddr + 3) & 0xffff

                DissAsm(startaddr, stopaddr - startaddr, CPU)
            else:
                safeprint("Multiple Matches.")
            continue
        if cmdword == "hex":
            if argcnt > 0:
                arglist[0]=int(arglist[0], 0) if isinstance(arglist[0], str) else arglist[0]
                if argcnt == 1:
                    startv = arglist[0]  # allows 0x...
                    length = 16
                else:
                    arglist[1]=int(arglist[1], 0) if isinstance(arglist[1], str) else arglist[1]
                    startv = arglist[0]
                    length = arglist[1]
                if length < 0:
                    length = 0  # Avoid negatives
                hexdump(startv, length, CPU)
            else:
                safeprint("ERR: Need to specify what to print")
            continue
        if cmdword == "hexi":
            if argcnt > 0:
                arglist[0]=int(arglist[0], 0) if isinstance(arglist[0], str) else arglist[0]
                if argcnt == 1:
                    startv = CPU.getwordat(arglist[0])  # dereference pointer
                    length = 16
                else:
                    arglist[1]=int(arglist[1], 0) if isinstance(arglist[1], str) else arglist[1]
                    startv = CPU.getwordat(arglist[0])
                    length = arglist[1]
                if length < 0:
                    length = 0
                hexdump(startv, length, CPU)
            else:
                safeprint("ERR: Need pointer label and optional length")
            continue
        if cmdword == "n":
            stepcnt = 1
            stoprange = 0
            if argcnt > 0:
                stepcnt = arglist[0]
            for i in range(stepcnt):
                oldpc=CPU.pc
                CPU.evalpc(context,1)
                DissAsm(CPU.pc, 1, CPU)
                if watchbreaks:
                    for addr1, (value1, oper1) in watchbreaks.items():
                        if OPS[oper1](CPU.getwordat(addr1), value1):
                            safeprint("Watch Point(n) Triggered CPU:%04x Memory:%04x TestVal:%04x Now %04x" % (CPU.pc,addr1,value1,CPU.getwordat(addr1)))
                            tempbreakpoints.append(oldpc)
                            break
                if oldpc in breakpoints or oldpc in tempbreakpoints:
                    safeprint("Break Point %04x" % CPU.pc)
                    if CPU.pc in tempbreakpoints:
                        tempbreakpoints.remove(CPU.pc)
                    break                
            continue
        if cmdword == "s":
            CurrentAddress=CPU.pc
            OriginalAddress = CurrentAddress
            OriginalLine=int(CPU.FindWhatLine(CurrentAddress).split(':')[1])
            is_call = False
            StateCtrl=0
            if "PUSH" in OPTDICT:
                PUSHCODE=OPTDICT["PUSH"][0]
                JMPCODE=OPTDICT["JMP"][0]
                # At this time we'll not worry about CALLZ and CALLNZ as they are rare.
                while CPU.pc <= 0xffff:
                    # We only care about JMP if the previous Call was PUSH addr
                    if CPU.memspace[CPU.pc] != JMPCODE and StateCtrl == 1:
                        StateCtrl = 0
                    if CPU.memspace[CPU.pc] == JMPCODE and StateCtrl == 1:
                        is_call = True
                        StateCtrl = 0
                    if CPU.memspace[CPU.pc] == PUSHCODE:
                        PossAddress = CPU.getwordmem(CPU.pc+1)
                        if CPU.pc <= PossAddress <= CPU.pc+12:
                            StateCtrl=1
                    if is_call:
                        # We are doing a call, loop until PossAddress = CurrentAddress for the RET
                        while(PossAddress != CPU.pc):
                            CPU.evalpc(context,1)
                        is_call=False
                        StateCtrl=0
                    else:
                        if OriginalLine != int(CPU.FindWhatLine(CPU.pc).split(':')[1]):
                            DissAsm(CPU.pc,1,CPU)
                            break
                        else:
                            CPU.evalpc(context,1)
        if cmdword == "c":
            stoprange = 0
            DissAsm(CPU.pc, 1, CPU)
            AtLeastOne = 1
            while CPU.pc <= 0xffff:
                if watchbreaks:
                    for addr1, (value1, oper1) in watchbreaks.items():
                        if OPS[oper1](CPU.getwordat(addr1), value1):
                            safeprint("Watch Point(c) Triggered CPU:%04x Memory:%04x TestVal:%04x Now %04x" % (CPU.pc,addr1,value1,CPU.getwordat(addr1)))
                            tempbreakpoints.append(CPU.pc)
                            break
                if (CPU.pc in breakpoints or CPU.pc in tempbreakpoints) and AtLeastOne != 1:
                    safeprint("Break Point %04x" % CPU.pc)
                    if ( CPU.pc in tempbreakpoints):
                        tempbreakpoints.remove(CPU.pc)
                    DissAsm(CPU.pc, 1, CPU)
                    break                
                AtLeastOne = 0
                context.GlobalOptCnt += 1
                CPU.evalpc(context,1)
        if cmdword == "r":
            stoprange = 0
            if argcnt < 1:
                CPU.pc = context.Entry
                CPU.hwstacksp = 0
                safeprint("PC set to %0x4" % context.Entry)
                CPU.flags = 0
            else:
                CPU.pc = arglist[0]
                CPU.address = CPU.pc
                safeprint("PC set to %04x" % arglist[0])
            CPU.flags = 0
            CPU.hwstacksp = 0
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
        if cmdword == "bwhen":
            if argcnt == 0:
                for addr,(value, oper1) in watchbreaks.items():
                    OSTR=""
                    Omask=0xffff
                    if oper1==WW_EQUAL:
                        OSTR="=="
                    elif oper1 == WW_NOT_EQUAL:
                        OSTR="!="
                    elif oper1 == WW_B_EQUAL:
                        OSTR="Byte =="
                        Omask=0xff
                    elif oper1==WW_B_NOT_EQUAL:
                        OSTR="Byte !="
                        Omask=0xff
                    safeprint("Break when:[%04x] %s %04x" % (addr, OSTR, value & Omask))
                continue
            if argcnt < 2:
                safeprint("Break When requires add cond val, cond={==,!=,b==,b!=}",argcnt)
            else:
                # Format is address test value
                Oaddr=arglist[0]
                value=arglist[2]
                OSTR=rawlist[1]
                if OSTR=="==":
                    OVal=WW_EQUAL                    
                elif OSTR=="!=":
                    OVal=WW_NOT_EQUAL
                elif OSTR=="b==":
                    OVal=WW_B_EQUAL
                    value=value & 0xff
                elif OSTR=="b!=":
                    OVal=WW_B_NOT_EQUAL
                    value=value & 0xff                    
                else:
                    safeprint("Not a valid watch test, use == != b== or b!= only")
                    continue
                print("Adding ", Oaddr, value, OVal)
                watchbreaks[Oaddr]=(value,OVal)
        if cmdword=="clearwhen":
            safeprint("Clearing watch points")
            watchbreaks={}
        if cmdword == "w":
            if argcnt < 1:
                safeprint(context.watchpoints)
            else:
                for ii in arglist:
                    context.watchpoints.append(Str2Word(ii))
        if cmdword == "cw":
            safeprint("Clearing watchs")
            context.watchpoints.clear()
        if cmdword == "tty":
            safeprint("Resetting Terminal")
            PollReSetRawFunc()
            PollSetEchoFunc()
            continue            
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
            restore_tty()
            print("\x1b[?1000l\x1b[?25h\n")
            sys.exit(0)
        if cmdword == "ttyreset":
            PollReSetRawFunc()
            PollSetEchoFunc()
        if cmdword == "ttyraw":
            PollSetRawFunc()
        if cmdline[0:4] == "REM ":
            # Allow Comments in debugger commands.
            cmdline=""
            cmdword == ""
            continue
        if cmdword == "h":
            help_commands = [
                ##123456789A123456789B123456789C12345   Linit help text to 35 chars per colum
                ("b", "break points"),
                ("c", "continue [ $1 steps ]"),
                ("cb", "clear breakpoints"),
                ("cw", "clear watches"),                
                ("d", "DissAsm $1 $2"),
                ("g","goto $1"),
                ("h", "this test"),
                ("hex", "Print hexdump $1[-$2]"),
                ("l", "DissAsm from line"),
                ("m", "modify or edit memory"),
                ("n", "Do one step"),
                ("p", "print values $1"),
                ("pa", "Search for lables"),
                ("ps", "Print HW Stack"),
                ("q", "quit debugger"),
                ("r", "reset"),
                ("range","print range of memory"),
                ("spush","Push $1 to Stack"),
                ("spop","POPNULL stack, [dest]"),                
                ("ttyreset","Resets terminal ."),
                ("ttyraw","Sets terminal raw mode.",),
                ("w", "watch $1"),
                ("bwhen","adr ? val, == != b== b!="),
                ("clearwhen","null bwhen"),
                ("REM", "Debug Comment")
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
            cmd_width  = max(len(cmd) for cmd, _ in help_commands)
            desc_width = max(len(desc) for _, desc in help_commands)
            safeprint("Debug Mode Commands:")
            for left, right in zip(col1, col2):
                safeprint(
                    f"{left[0]:<{cmd_width}} - {left[1]:<{desc_width}}    "
                    f"{right[0]:<{cmd_width}} - {right[1]:<{desc_width}}"
                    )
        continue

def looks_numeric(tok: str) -> bool:
    if not tok:
        return False

    # handle leading sign
    if tok[0] in "+-":
        tok = tok[1:]
        if not tok:
            return False

    # hex forms
    if tok.startswith(("0x", "0X")):
        return tok[2:].isdigit()

    if tok.startswith("$"):
        return tok[1:].isdigit()

    # decimal
    return tok.isdigit()



def IsLabelActive(name, pc):
    history = LocVarHist.get(name)
    if not history:
        return False

    for entry in history:
        start = entry["start"]
        end = entry["end"]
        if pc >= start and (end is None or pc <= end):
            return True

    return False

    
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
                current_context.watchword.append(Str2Word(arg))
                safeprint("New Watchword %s" % (current_context.watchword))
            if prpcmd == 2:
                breakafter.append(Str2Word(arg))
            if prpcmd == 3:
               firstcmd+=[arg]
            if prpcmd == 4:
                context.Monitor.append(Str2Word(arg))                
        else:
            if arg == "-d":
                context.Debug = context.Debug + 1
            elif arg == "-d25":
                context.Debug = 2.5
            elif arg == "-i":
                Skipone=True
                prpcmd=4                
            elif arg == "-l":
                ListOut = True
            elif arg == "-g":
                UseDebugger = True
                DebugOut=sys.stdout
            elif arg == "-f":
                context.Fast = True
            elif arg == "-X":
                context.CrossCheck = True            
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
#                DebugOut=sys.stdout
            elif arg == "-h":
                safeprint("-d Debug Assembly and Run\n-d more debugging info.\n-l List Src\n-g Run interactive debugger\n-c Hex Dump of Assembly\n-O Binary Dump of Assembly\n-w Add Watch Address to debug listing\n-b Set Breakpoint to debugger\n-f Run with Fash Emulation\n-h help, this listing\n-X debugging mode compare Python and C emulations\n-e 'command' pass to debugger")
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
    FinalSymbolReport(context)

    context.GlobalOptCnt = 0

    if len(files) == 0:
        # if no files given then drop to debugger for machine lang tests.
        # Default to common.mc to provide base macros
        maxusedmem = \
            loadfile("common.mc", maxusedmem, CPU, GLOBALFLAG, "common.mc",  context)
        FinalSymbolReport(context)
        
        UseDebugger = True
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
        safeprint("Start of Run: Debug: %s: Watch: %s" % (context.Debug, context.watchword))
    if ListOut:
        safeprint("-------0--Max:%04x------" % (maxusedmem),file=DebugOut)
        DissAsm(0, maxusedmem, CPU)
    elif UseDebugger:
        debugger(firstcmd,context)
    else:
        CPU.evalpc(context,-1)


if __name__ == '__main__':
    main()

    if sys.stdin.isatty():
        _fd = sys.stdin.fileno()
        try:
            new = termios.tcgetattr(_fd)
            new[3] = new[3] | termios.ECHO   # turn echo back on
            termios.tcsetattr(_fd, termios.TCSADRAIN, new)
        except termios.error:
            safeprint("TTY Error: Unable to restore echo")
############################################
