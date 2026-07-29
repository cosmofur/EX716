#!/usr/bin/env python3

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
import time
import bisect
import tempfile
from collections import deque
from dataclasses import dataclass, field

@dataclass
class DynFunction:
    name: str
    body: list[str] = field(default_factory=list)
    uses: set[str] = field(default_factory=set)
    source_file: str = ""
    start_line: int = 0

from collections import defaultdict


#import traceback


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

DBG_RUN      = 1   # emulator/runtime instruction trace: DissAsm per executed instruction
DBG_ASM      = 2   # assembler source/load/basic symbol trace
DBG_MACRO    = 3   # macro expansion before/after, brace expansion, % expansion
DBG_INTERNAL = 4   # stack frames, MacroVars, symbol history, low-level internals

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
#
# List of built in commands and how many arguments they take.
COMMAND_SPEC = {
    "ENDBLOCK":{"arity":0,"arg_kind":[]},
    "?": {"arity":1,"arg_kind":["word"]},
    "!": {"arity":1,"arg_kind":["word"]},
    "IFDEF": {"arity":1,"arg_kind":["word"]},
    "IFNDEF": {"arity":1,"arg_kind":["word"]},
    "IF_EQ": {"arity":2,"arg_kind":["word", "word"]},
    "IF_NE": {"arity":2,"arg_kind":["word","word"]},
    "IF_LT": {"arity":2,"arg_kind":["word","word"]},
    "IF_GT": {"arity":2,"arg_kind":["word","word"]},
    "I": {"arity":1,"arg_kind":["word"]},
    "L": {"arity":1,"arg_kind":["word"]},
    "D": {"arity":1,"arg_kind":["word"]},    
    "G": {"arity":1,"arg_kind":["word"]},
    "MF": {"arity":2,"arg_kind":["word","macro_token"]},
    "MA": {"arity":2,"arg_kind":["word"]},
    ".": {"arity":1,"arg_kind":["word"]},
    ".ORG": {"arity":1,"arg_kind":["word"]},
    ".DATA": {"arity":1,"arg_kind":["word"]},
    ":": {"arity":-1,"arg_kind":["word"]},
    "=": {"arity":-2,"arg_kind":["word","equation"]},
    }

def dprint(level, *args, **kwargs):
    ctx = current_context
    if ctx is not None and ctx.Debug >= level:
        kwargs.setdefault("file", DebugOut)
        safeprint(*args, **kwargs)

def skip_ws(s, i=0):
    while i < len(s) and s[i].isspace():
        i += 1
    return i

if sys.platform == "win32":
    import msvcrt
    print("Windows Mode")
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

#from pathlib import Path


current_context = None



from dataclasses import dataclass
@dataclass
class SourceCommand:
    text: str
    filename: str
    resolved_filename: str
    line_num: int
    address: int
    origin: str="file"
    segments: list[str] | None = None

@dataclass
class ForwardRef:
    symbol: str
    address: int
    delta: int = 0
    file: str=""
    line:int | None=None
    

def record_symbol_use(context, sym, addr, file=None, line=None):
    file = file or getattr(context, "CurrentSourceFile", "") or getattr(context, "ActiveFile", "")
    line = line or getattr(context, "CurrentSourceLine", 0) or getattr(context, "FileLineNum", None)

    context.UsedSymbols[sym] = context.UsedSymbols.get(sym, 0) + 1

    if not hasattr(context, "MissingSymbols"):
        context.MissingSymbols = {}

    entry = context.MissingSymbols.setdefault(sym, {"refs": []})
    entry["refs"].append((file, line, addr))


class AssemblerContext:
    def __init__(self):
        # Memory and address state
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
        self.LoadDepth = 0
        


        # Labels and variables
        self.FileLabels = {}
        self.GlobeLabels = {}
        self.FWORDLIST = []
        self.FBYTELIST = []
        self.DefinedSymbols = set()
        from collections import defaultdict
        self.UsedSymbols = defaultdict(int)
        self.GlobalDeclarations={"END__"}
        self.GlobalDeclInfo={}
        self.StructStack = []
        self.UseRequested = set()
        
        self.KeepDynamicLibraries = True
        

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
        self.ActiveResolvedFile = ""
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
    def max_macro_arg_index(self,body):
        nums=[int(x) for x in re.findall(r"%([0-9]+)", body)]
        return max(nums, default=0)
        
    def define_macro(self, name, body, filename=None, resolved_filename=None, line_num=None):
        self.MacroData[name] = body
        self.MacroPCount[name] = self.max_macro_arg_index(body)

        if hasattr(self, "MacroDefInfo"):
            self.MacroDefInfo[name] = (filename, resolved_filename, line_num)
        dprint(DBG_MACRO, f"[DEFINE MACRO] {name} = {body!r}")

    def macro_or_label_exists(self, name):
        name = name.strip()

        if name in self.MacroData:
            return True

        lname = IsLocalVar(name, self)
        if lname in self.FileLabels:
            return True

        if name in self.GlobeLabels:
            return True

        return False
    
    def push_block(self, executing, block_type="UNKNOWN"):
        block= {
            "executing": executing,
            "else_seen": False,
            "id": self._next_block_id(),            
            "line": f"{current_context.ActiveFile}:{current_context.FileLineNum+1}",
            "type":block_type
            }
        self.MacroBlockStack.append(block)
        dprint(DBG_ASM,f"[MB PUSH] depth={len(self.MacroBlockStack):02d} "
                  f"id={block['id']} type={block['type']} exec={block['executing']} "
                  f"{block['line']}")
    def _next_block_id(self):
        if not hasattr(self, "_block_counter"):
            self._block_counter = 0
        self._block_counter += 1
        return self._block_counter

    def pop_block(self):
        if not self.MacroBlockStack:
            safeprint(f"[MB POP ERROR] EMPTY STACK @ {current_context.ActiveFile}:{current_context.FileLineNum+1}", file=DebugOut)
            CPU.raiseerror(f"100 ENDBLOCK without matching Start {current_context.ActiveFile}:{current_context.FileLineNum+1}")

        block = self.MacroBlockStack.pop()
        dprint(DBG_ASM,f"[MB POP ] depth={len(self.MacroBlockStack):02d} "
                  f"id={block['id']} type={block['type']} exec={block['executing']} "
                  f"(opened @ {block['line']}) "
                  f"-> closed @ {current_context.ActiveFile}:{current_context.FileLineNum+1}")
        dprint(DBG_MACRO,f"[MACRO Pop_Block]: {block}")

    
    def current_block(self):
        if not self.MacroBlockStack:
            return None
        return self.MacroBlockStack[-1]

    def parent_executing(self):
        return all(b["executing"] for b in self.MacroBlockStack[:-1])

    def is_executing(self):
        result = all(b["executing"] for b in self.MacroBlockStack)
        dprint(DBG_ASM, f"[MB EXEC?] depth={len(self.MacroBlockStack)} result={result} stack={self.MacroBlockStack}")
        return result

        
    def evaluate_condition(self, key, line, filename, CPU):
        spec = COMMAND_SPEC[key]
        consumed = len(key)

        args = []
        for kind in spec["arg_kind"]:
            consumed = skip_ws(line, consumed)

            if kind == "equation":
                arg, used = nextwordequation(line[consumed:])
            else:
                arg, used = nextwordplus(line[consumed:])

            if not arg:
                CPU.raiseerror(f"Missing argument for {key}")

            args.append(arg)
            consumed += used

        if key in ("?", "IFDEF"):
            result = self.macro_or_label_exists(args[0])
        elif key in ("!", "IFNDEF"):
            result = not self.macro_or_label_exists(args[0])
        elif key == "IF_EQ":
            result = self.eval_arg(args[0], filename, CPU) == self.eval_arg(args[1], filename, CPU)
        elif key == "IF_NE":
            result = self.eval_arg(args[0], filename, CPU) != self.eval_arg(args[1], filename, CPU)
        elif key == "IF_LT":
            result = self.eval_arg(args[0], filename, CPU) < self.eval_arg(args[1], filename, CPU)
        elif key == "IF_GT":
            result = self.eval_arg(args[0], filename, CPU) > self.eval_arg(args[1], filename, CPU)
        else:
            CPU.raiseerror(f"Unknown conditional {key}")

        return result, consumed

    def eval_arg(self, arg, filename, CPU):
        arg = expand_unquoted_text(arg, filename, self, CPU)

        try:
            value, used = FirstPassVal(
                arg,
                self,
                filename=filename,
                allow_braces=True,
            )
            if not arg[used:].strip():
                return value
        except Exception:
            pass

        return arg

    
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

_saved_attrs = None
_saved_flags = None


def PollSetRawFunc(arg=None):
    """Put terminal into raw, non-blocking mode."""
    global _saved_attrs, _saved_flags

    if _saved_attrs is None:
        _saved_attrs = termios.tcgetattr(_fd)

    if _saved_flags is None:
        _saved_flags = fcntl.fcntl(_fd, fcntl.F_GETFL)

    tty.setraw(_fd)

    attrs = termios.tcgetattr(_fd)
    attrs[6][termios.VMIN] = 0
    attrs[6][termios.VTIME] = 1
    termios.tcsetattr(_fd, termios.TCSANOW, attrs)

    fcntl.fcntl(
        _fd,
        fcntl.F_SETFL,
        _saved_flags | os.O_NONBLOCK
    )

def PollReSetRawFunc(arg=None):
    """Restore terminal state from before PollSetRawFunc."""
    global _saved_attrs, _saved_flags

    if _saved_attrs is None and _saved_flags is None:
        return

    try:
        # Discard unread terminal input while still in raw mode.
        termios.tcflush(_fd, termios.TCIFLUSH)

    except termios.error:
        # Flushing is best effort.
        pass

    finally:
        if _saved_attrs is not None:
            termios.tcsetattr(
                _fd,
                termios.TCSADRAIN,
                _saved_attrs
            )

        if _saved_flags is not None:
            fcntl.fcntl(
                _fd,
                fcntl.F_SETFL,
                _saved_flags
            )

        _saved_attrs = None
        _saved_flags = None
        

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

    

atexit.register(restore_tty)
    
def shandler(signum, frame):
    restore_tty()
    print("Ctrl-C\x1b[?1000l\x1b[?25h\n", flush=True)
    debugger("",current_context)    
    sys.exit(1)   # exit cleanly

signal.signal(signal.SIGINT, shandler)


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
    dprint(DBG_INTERNAL,f"HIST {varname} value={value} address={address}")


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

    # 1) Exact-name lookup, but active/in-range only.
    exact_history = LocVarHist.get(varname)
    if exact_history:
        candidates = [e for e in exact_history if in_range(e)]
        if candidates:
            best = max(candidates, key=lambda e: e["start"])
            return best["value"]

    # 2) Prefix/scoped lookup.
    prefix = f"{varname}__"
    candidates = []

    for name, history in LocVarHist.items():
        if not name.startswith(prefix):
            continue
        for entry in history:
            if in_range(entry):
                candidates.append(entry)

    if candidates:
        best = max(candidates, key=lambda e: e["start"])
        return best["value"]

    # 3) Handle cases where it not a declaired global but has a larger context that its valud in.
    if exact_history and len(exact_history) == 1:
        return exact_history[0]["value"]
    # 4 No active or unique value found.
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
    # line is already after the leading ';'

    label, used = nextword(line)
    if not label:
        CPU.raiseerror(f"150 Missing label in ';' directive {filename}:{context.FileLineNum}")

    rest = line[used:].lstrip()

    size_expr, used = nextwordequation(rest)
    if not size_expr:
        CPU.raiseerror(f"160 Missing size for ';' {label}")

    workingaddress = (
        context.dataaddress
        if context.DataSegment != -1
        else context.address
    )

    size_value = DecodeStr(size_expr, workingaddress, CPU, True, context)

    if not isinstance(size_value, int):
        CPU.raiseerror(
            f"170 Size expression '{size_expr}' must resolve on first pass of ';' {label}"
        )

    if size_value < 0:
        CPU.raiseerror(
            f"180 Size expression '{size_expr}' cannot be negative in ';' {label}"
        )

    sym = IsLocalVar(label, context)
    context.FileLabels[sym] = workingaddress
    context.DefinedSymbols.add(sym)

    UpdateVarHistory(sym, workingaddress, workingaddress)

    context.ExpectData = size_value
    return rest[used:].lstrip()


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
    



    def __init__(self, origin, memsize):
        self.pc = origin
        self.flags = np.uint16(0)    # B0 = ZF, B1=NF, B2=CF, B3=OF
        self.identity = next(self.cpu_id_iter)
        self.hwstack = np.zeros(MAXHWSTACK, dtype=np.uint16)
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
            self.optNOP, self.optPUSH, self.optDUP, self.optPUSHI, self.optPUSHII, self.optPUSHS, self.optPOPNULL, self.optSWP, self.optPOPI, self.optPOPII, self.optPOPS, self.optCMP, self.optCMPS, self.optCMPI, self.optCMPII, self.optADD, self.optADDS, self.optADDI, self.optADDII, self.optSUB, self.optSUBS, self.optSUBI, self.optSUBII, self.optOR, self.optORS, self.optORI, self.optORII, self.optAND, self.optANDS, self.optANDI, self.optANDII, self.optXOR, self.optXORS, self.optXORI, self.optXORII, self.optJMPZ, self.optJMPN, self.optJMPC, self.optJMPO, self.optJMP, self.optJMPI, self.optJMPS, self.optCAST, self.optPOLL, self.optRRTC, self.optRLTC, self.optSHR, self.optSHL, self.optINV, self.optCOMP2, self.optFCLR, self.optFSAV, self.optFLOD, self.optADM, self.optSCLR, self.optSRPT]
        
        self.op_size = [OPTDICT.get(str(i), (None, None, 1))[2] for i in range(256)]
        self.op_func = [getattr(self, "opt" + OPTDICT[str(i)][1], None)
                        if str(i) in OPTDICT else None
                        for i in range(256)]

    def insertbyte(self, location, value, context=None):
        global FileLineData

        if location >= 65536:
            self.raiseerror("190 Address OverFlow %05x" % location)

        if context is not None:
            src_file = getattr(context, "CurrentSourceFile", "") or context.ActiveFile
            src_line = getattr(context, "CurrentSourceLine", 0) or context.FileLineNum

            FileLineData.add_entry(src_file, src_line, location)
            FileLineData.add_entry(
                src_file,
                src_line,
                location,
            )

        self.memspace[location] = value & 0xff

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

    def FindWhatLineInfo(self, address):
        global FileLineData
        tresult = FileLineData.get_line_info(address, False)
        if tresult is None or len(tresult) < 2:
            return None
        return tresult  # (filename, line)
    
    def FindWhatLine(self, address):
        global FileLineData
        tresult = FileLineData.get_line_info(address, False)

        if tresult is None or len(tresult) < 2:
            print("No good line match found for address %04x" % address)
            return ""

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
        global  DebugOut

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
        return int(self.hwstack[index])

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
        # 32 Print 32 bit integer at address  (32 version of PRTI)
        # 33 print 32 bit integer at [address] (32 version of PRTII)

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
                if (c < 32 ) and c not in (7, 8, 9, 10, 13, 27, 30):                    
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
            while i < MAXMEMSP and self.memspace[i] != 0:
                c = self.memspace[i]
                if (c < 32 ) and c not in (7, 8, 9, 10, 13, 27, 30):
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
            self.hwstacksp -= 2
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
            else:
                self.raiseerror("042 No Disk selected before Read Block.")
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
                    self.raiseerror(f"550 Attempted to read block with insuffient memory {v:04x} < {MAXMEMSP-0xff}")
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
            else:
                self.raiseerror("042 No Tape selected before Read Block.")
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
            else:
                self.raiseerror("042 No Tape selected before Read Block.")
        if cmd == PollRewindTape:
            self.optPOPNULL(address)
            if current_context.DeviceHandle != None:
                current_context.DeviceFile.seek(0)
            else:
                self.raiseerror("042 No Tape selected before Rewind Operation.")

# PollReadTime should be reworked to write time to 32 bit block at address rather than stack.
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
        self.flags = (int(self.flags) & 0x0b) | NCF
        self.StoreAcum(0, R1)

    def optSHR(self, unused):
        # SHR mean shift Right and set carry CF to equal current lowest bit
        
        R1 = self.fetchStack(0) & 0xFFFF
        NCF = 0x4 if (R1 & 0x0001) else 0
        R1 = (R1 >> 1) & 0xFFFF
        self.flags = (int(self.flags) & 0xfffb) | NCF
        self.StoreAcum(0, R1)
        
    def optSHL(self, unused):
        # SHL mean shift Left and set carry CF to equal current Highest bit
        R1 = self.fetchStack(0) & 0xFFFF
        NCF = 0x4 if (R1 & 0x8000) else 0  # carry in bit 2
        R1 = ((R1 << 1) & 0xFFFF)          # mask to 16 bits
        self.flags = (int(self.flags) & 0x0b) | NCF
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
            safeprint("Cross Check Mode: Both C and Python and compair results.")
            halted = False
            step_count = 0
            while not halted:
                # --- snapshot current state ---
                pc0, flags0 = self.pc, self.flags
                sp0 = self.hwstacksp
                mem0 = self.memspace[:]   # Main Memory snapshot
                mb0  = self.hwstack.copy()         # HW stack snapshot

                # --- run C version with its own copies ---
                memC = mem0[:]            # independent copy for C
                mbC  = mb0.copy()
                pcC, flagsC, spC, rcC = cpuCfunc.EvalOne(memC, mbC, pc0, flags0, sp0, 1, 0)

                # --- run Python version with its own copies ---
                self.pc, self.flags, self.hwstacksp = pc0, flags0, sp0
                self.memspace = mem0[:]   # independent copy for Python
                self.hwstack       = mb0.copy()
                rcPy = self._evalpc_py(context, dosteps=1)

                pcPy, flagsPy, spPy = self.pc, self.flags, self.hwstacksp
                memPy, mbPy   = self.memspace, self.hwstack

                # --- compare results ---
                if pcC != pcPy:
                    print(f"[CrossCheck] Step {step_count}: PC mismatch "
                          f"Start={pc0:04x}, C_end={pcC:04x}, Py_end={pcPy:04x}")
                if flagsC != flagsPy:
                    print(f"[CrossCheck] Step {step_count}: Flags mismatch at PC={pc0:04x} "
                           f"C={flagsC:04x}, Py={flagsPy:04x}")
                if spC != spPy:
                    print(f"[CrossCheck] Step {step_count}: Stack pointer mismatch at PC={pc0:04x} "
                          f"C={spC}, Py={spPy}")
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
            safeprint("Fast Mode:")
            return self._evalpc_c(context, dosteps)
        else:
            return self._evalpc_py(context, dosteps)

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
            if context.Debug >= DBG_RUN:
                DissAsm(self.pc, 1, self)
                context.GlobalOptCnt += 1

            (self.pc, self.flags, self.hwstacksp, ReturnCode) = cpuCfunc.EvalOne(
                self.memspace,
                self.hwstack,
                self.pc,
                self.flags,
                self.hwstacksp,
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
                # Unlimited normal execution: let C run until completion,
                # interruption, or a debug-toggle event.
                if steps_remaining is None:
                    (self.pc, self.flags, self.hwstacksp, ReturnCode) = cpuCfunc.EvalOne(
                        self.memspace,
                        self.hwstack,
                        self.pc,
                        self.flags,
                        self.hwstacksp,
                        -1,
                        ReturnCode
                    )

                    if ReturnCode == -11:
                        context.Debug = 1
                        ReturnCode = 0
                        continue

                    if ReturnCode != 0:
                        break

                    # An unlimited call normally should not return zero unless the
                    # C executor intentionally yielded. If yielding is valid, continue.
                    continue

                # Finite multi-step execution
                if steps_remaining > 1:
                    batch = steps_remaining
                    (self.pc, self.flags, self.hwstacksp, ReturnCode) = cpuCfunc.EvalOne(
                        self.memspace,
                        self.hwstack,
                        self.pc,
                        self.flags,
                        self.hwstacksp,
                        batch,
                        ReturnCode
                    )
                    context.GlobalOptCnt += batch

                    if ReturnCode == -11:
                        context.Debug = 1
                        ReturnCode = 0
                        continue

                    if ReturnCode != 0:
                        break

                    steps_remaining = 0
                    break

                # Exactly one finite step remains
                rc = step_one()

                if rc == -11:
                    context.Debug = 1
                    ReturnCode = 0
                    continue

                if rc != 0:
                    break

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

                if context.Debug >= DBG_RUN:
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

                if context.Debug >= DBG_RUN:
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
            debugger("",current_context)
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

        if inquote and c == "\\":
            if i + 1 < L:
                out.append(c)
                out.append(inline[i + 1])
                i += 2
                continue
            out.append(c)
            break

        if c == '"':
            inquote = not inquote
            out.append(c)
            i += 1
            continue

        if not inquote and c == "#":
            break

        out.append(c)
        i += 1

    return "".join(out).rstrip()


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
                'r': '\r',
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
        
def next_macro_arg(s):
    s2 = s.lstrip()
    skipped = len(s) - len(s2)

    if not s2:
        return "", skipped

    if s2[0] in ('"', "'"):
        q = s2[0]
        i = 1
        escape = False
        while i < len(s2):
            ch = s2[i]
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == q:
                i += 1
                return s2[:i], skipped + i
            i += 1
        return s2, skipped + len(s2)

    i = 0
    while i < len(s2) and not s2[i].isspace():
        i += 1

    return s2[:i], skipped + i

def next_macro_name_token(s):
    i = 0
    while i < len(s) and s[i].isspace():
        i += 1

    start = i
    paren = 0

    while i < len(s):
        ch = s[i]

        if ch.isspace():
            break

        if ch == "(":
            paren += 1
        elif ch == ")":
            if paren > 0:
                paren -= 1

        # semicolon ends token only outside parens
        if ch == ";" and paren == 0:
            break

        i += 1

    return s[start:i], i

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

        if ltext[start:start+2] == "%(":
            end = find_matching_percent_paren(ltext, start)
            if end < 0:
                CPU.raiseerror(f"Unmatched %( ... %) in token: {ltext}")
            return ltext[start:end], end

        size += 1
        
        # Otherwise: %V, %S, %1, etc.

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

def getkeyfromval(val, my_dict):
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


def expand_brace_refs(text, filename, context, CPU, preserve_unresolved=True):
    """
    Universal {name} expansion.

    This should run after macro argument substitution, but before normal
    assembler command handling.

    Resolution order:
      1. MacroData symbolic value
      2. Historic/current label value
      3. Preserve unresolved {name}, unless preserve_unresolved=False
    """
    out = []
    i = 0
    inquote = False
    escaped = False

    while i < len(text):
        ch = text[i]

        if inquote:
            out.append(ch)

            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                inquote = False

            i += 1
            continue

        if ch == '"':
            inquote = True
            out.append(ch)
            i += 1
            continue

        if ch != "{":
            out.append(ch)
            i += 1
            continue

        start = i + 1
        j = start

        while j < len(text) and (
            text[j].isalnum()
            or text[j] == "_"
            or text[j] == "."
        ):
            j += 1

        if j >= len(text) or text[j] != "}":
            out.append(ch)
            i += 1
            continue

        name = text[start:j]
        resolved = None

        if name in context.MacroData:
            resolved = context.MacroData[name]
        elif name in context.GlobeLabels:
            resolved = context.GlobeLabels[name]
        else:
            resolved = FindHistoricVal(name, context.address, context)

        dprint(DBG_MACRO, f"[BRACE-EXPAND] {{{name}}} -> {resolved!r}")

        if resolved is not None:
            out.append(str(resolved))
        elif preserve_unresolved:
            out.append("{" + name + "}")
        else:
            out.append(name)

        i = j + 1

    return "".join(out)

def parse_percent_arg(line, filename, context, CPU):
    line2 = line.lstrip()
    skipped = len(line) - len(line2)

    word, size = nextwordequation(line2)
    if not word:
        CPU.raiseerror(f"Missing % function argument {filename}:{context.FileLineNum+1}")

    word = expand_unquoted_text(word, filename, context, CPU)

    try:
        value, used = FirstPassVal(
            word,
            context,
            filename=filename,
            allow_braces=True,
        )
        if not word[used:].strip():
            return str(value), skipped + size
    except Exception:
        pass

    return word, skipped + size

def expand_macro_pipeline(text, filename, context, CPU, do_stack_ops=True):
    if do_stack_ops:
        text = substitute_macro_stack_opts(text, filename, context, CPU)
    text = expand_percent_functions(text, filename, context, CPU)
    text = expand_unquoted_text(text, filename, context, CPU)
    return text



def substitute_macro_params_only(line, filename, context, CPU):
    i = 0
    out = []
    inquote = False
    escape = False

    while i < len(line):
        c = line[i]

        if escape:
            out.append(c)
            escape = False
            i += 1
            continue

        if c == "\\" and inquote:
            out.append(c)
            escape = True
            i += 1
            continue

        if c == '"':
            inquote = not inquote
            out.append(c)
            i += 1
            continue

        if c != "%" or inquote:
            out.append(c)
            i += 1
            continue

        # Saw %
        i += 1

        if i < len(line) and line[i].isdigit():
            n = int(line[i])
            base = context.varcntstack[context.varbaseSP]
            idx = base + n

            if idx >= len(context.MacroVars):
                CPU.raiseerror(f"052 Macro %{n} not defined")

            out.append(context.MacroVars[idx])
            i += 1
            continue

        # Preserve non-parameter % functions/ops for command-time handling.
        out.append("%")
        if i < len(line):
            out.append(line[i])
            i += 1

    return "".join(out)

def substitute_macro_stack_opts(line, filename, context, CPU):
    i = 0
    out = []
    inquote = False
    escape = False

    while i < len(line):
        c = line[i]

        if escape:
            out.append(c)
            escape = False
            i += 1
            continue

        if c == "\\" and inquote:
            out.append(c)
            escape = True
            i += 1
            continue

        if c == '"':
            inquote = not inquote
            out.append(c)
            i += 1
            continue

        if c != "%" or inquote:
            out.append(c)
            i += 1
            continue

        i += 1  # consume %

        op = line[i:i+1]

        if op == "S":
            val = context.MacroVars[context.varcntstack[context.varbaseSP]]
            MacroStack.append(val)
            i += 1
            continue

        if op == "P":
            if not MacroStack:
                CPU.raiseerror(f"049 Macro Reference Stack Underflow: {line}")
            MacroStack.pop()
            i += 1
            continue

        if op == "V":
            if not MacroStack:
                CPU.raiseerror(f"050 Macro Reference not in stack: {line}")
            out.append(MacroStack[-1])
            i += 1
            continue

        if op == "W":
            if len(MacroStack) < 2:
                CPU.raiseerror(f"051 Macro Reference Stack Underflow: {line}")
            out.append(MacroStack[-2])
            i += 1
            continue

        # Unknown % sequence: preserve it for expand_percent_functions().        
        out.append("%")
        if i < len(line):
            out.append(line[i])
            i += 1

    return "".join(out)

def expand_percent_functions(line, filename, context, CPU, scan_mode=False):
    saved_LastMLen = None
    if scan_mode:
        saved_LastMLen = list(LastMLen)

    try:
        return _expand_percent_functions(
            line, filename, context, CPU, scan_mode=scan_mode
        )
    finally:
        if scan_mode:
            LastMLen[:] = saved_LastMLen

def _expand_percent_functions(line, filename, context, CPU, scan_mode=False):
    i = 0
    out = []
    inquote = False
    escape = False

    while i < len(line):
        c = line[i]

        if escape:
            out.append(c)
            escape = False
            i += 1
            continue

        if c == "\\" and inquote:
            out.append(c)
            escape = True
            i += 1
            continue

        if c == '"':
            inquote = not inquote
            out.append(c)
            i += 1
            continue

        if c != "%" or inquote:
            out.append(c)
            i += 1
            continue

        if i >= len(line):
            out.append("%")
            break
        i += 1  # consume %
        if line[i:i+6] == "STRLEN":
            i += 6
            while i < len(line) and line[i].isspace():
                i += 1

            arg, used = nextwordplus(line[i:])
            if not arg:
                CPU.raiseerror("Missing argument for %STRLEN")

            arg = expand_unquoted_text(arg, filename, context, CPU)

            if arg.startswith('"') and arg.endswith('"'):
                _, arg = GetQuoted(arg)

            LastMLen.append(len(arg))
            i += used
            continue

        if line[i:i+3] == "LEN":
            if not LastMLen:
                CPU.raiseerror("610 Macro %STRLEN/%LEN stack underflow")
            out.append(str(LastMLen.pop()))
            i += 3
            continue

        if line[i:i+4] == "LINE":
            out.append(f'"{context.ActiveFile}:{context.FileLineNum+1}"')
            i += 4
            continue

        if line[i:i+3] == "AND":
            i += 3
            v1, used1 = parse_percent_arg(line[i:], filename, context, CPU)
            i += used1
            v2, used2 = parse_percent_arg(line[i:], filename, context, CPU)
            i += used2
            out.append(str(int(v1) & int(v2)))
            continue

        if line[i:i+2] == "OR":
            i += 2
            v1, used1 = parse_percent_arg(line[i:], filename, context, CPU)
            i += used1
            v2, used2 = parse_percent_arg(line[i:], filename, context, CPU)
            i += used2
            out.append(str(int(v1) | int(v2)))
            continue

        if line[i:i+5].upper() == "FIELD":
            i += 5
            v1, u1 = parse_percent_arg(line[i:], filename, context, CPU); i += u1
            v2, u2 = parse_percent_arg(line[i:], filename, context, CPU); i += u2
            v3, u3 = parse_percent_arg(line[i:], filename, context, CPU); i += u3

            mask = (1 << int(v2)) - 1
            out.append(str((int(v3) & mask) << int(v1)))
            continue

        if line[i:i+3].upper() == "BIT":
            i += 3
            v1, u1 = parse_percent_arg(line[i:], filename, context, CPU); i += u1
            v2, u2 = parse_percent_arg(line[i:], filename, context, CPU); i += u2
            out.append(str((int(v2) & 1) << int(v1)))
            continue

        # Unknown % function: preserve it.
        out.append("%")

    return "".join(out)

            



# Our two pass assembly is very limited on what it can handle on the 2nd pass.
# Basicly, if a value (with possible +/- modifier) does NOT take up a word of memory in the final
# code, and only is a 'value' used by the assembler. Then it CAN NOT be defered for a second pass.
# We need that 'word' of storage to hold temporary values that will later be replaed. All other
# values (such as when labels are themselves used a +/- modifiers) must resolve durring 1st pass.

def FirstPassVal(instr, context, filename=None, allow_braces=True):
    original = instr

    dprint(DBG_INTERNAL, f"[FP IN] {original!r}")

    # First isolate only the expression being consumed.
    # The returned size must refer to the original input string.
    expr, size = nextwordequation(original)

    if not expr:
        CPU.raiseerror(
            f"055 Missing first-pass value "
            f"{context.ActiveFile}:{context.FileLineNum+1}"
        )

    dprint(DBG_INTERNAL,
           f"[FP RAW TOKEN] expr={expr!r} size={size} "
           f"rest={original[size:].lstrip()!r}")

    expanded_expr = expr

    if allow_braces:
        expanded_expr = expand_brace_refs(
            expr,
            filename or context.ActiveFile,
            context,
            CPU,
            preserve_unresolved=True
        )
        dprint(DBG_ASM,
               f"[FP BRACE TOKEN] {expr!r} -> {expanded_expr!r}")

    resolved = DecodeStr(expanded_expr, context.address, CPU, True, context)

    if resolved is None:
        CPU.raiseerror(
            "055 Line %s, %s can not use label that is not yet defined "
            "in first pass of assembler." %
            (context.GlobalOptCnt, expanded_expr)
        )

    dprint(DBG_INTERNAL,
           f"[FP OUT] expr={expr!r} expanded={expanded_expr!r} "
           f"resolved={resolved!r} size={size}")

    return Str2Word(resolved), size

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
        dprint(DBG_INTERNAL,f"[TRACE decode_token] token='{token}' at {context.ActiveFile}:{context.FileLineNum}")

    if token == "":
        return("value",0)

    # Handle quoted string
    if token.startswith('"') and token.endswith('"'):
        if JUSTRESULT:
            safeprint("String Values can't be modified with offsets:%s" % (token), file=DebugOut)
            return 0
        for c in token[1:-1]:
            CPU.insertbyte(curaddress, ord(c), context)
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

    if labelname in context.GlobeLabels:
        return ("value", Str2Word(context.GlobeLabels[labelname]))

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
            safeprint(f"Warning: Empty label; refreces at {context.ActiveFile}:{context.FileLineNum+1}",file=DebugOut)
            return("value",0)
        return ("unresolved",newkey)


def find_matching_percent_paren(text, start):
    """
    Given text[start:start+2] == "%(", return the index just after the
    matching "%)".

    Supports nested %( ... %) groups.

    Example:to l 
        text = "%(A+%(B%)%)"
        start = 0
        returns len(text)
    """
    if text[start:start+2] != "%(":
        cpu.raiseerror("find_matching_percent_paren called at non-%( position")

    depth = 1
    i = start + 2

    while i < len(text):
        if text[i:i+2] == "%(":
            depth += 1
            i += 2
        elif text[i:i+2] == "%)":
            depth -= 1
            i += 2
            if depth == 0:
                return i
        else:
            i += 1

    return -1

def expand_macro_assignment_value(value, filename, context, CPU):
    value = value.strip()

    # First resolve {MacroName} / {LabelName}
    value = expand_brace_refs(
        value,
        filename,
        context,
        CPU,
        preserve_unresolved=False,
    ).strip()

    # Evaluate arithmetic when explicitly requested.
    if value.startswith("%EVAL"):
        expr = value[len("%EVAL"):].strip()

        expr = expand_brace_refs(
            expr,
            filename,
            context,
            CPU,
            preserve_unresolved=False,
        ).strip()

        return str(DecodeStr(expr, context.address, CPU, True, context))

    return value

def find_matching_endr(line, start, CPU):
    """
    start points just after %REPEAT's count argument.
    Returns index of matching %ENDR start.
    """
    i = start
    depth = 1
    inquote = False
    escape = False

    while i < len(line):
        c = line[i]

        if escape:
            escape = False
            i += 1
            continue

        if c == "\\" and inquote:
            escape = True
            i += 1
            continue

        if c == '"':
            inquote = not inquote
            i += 1
            continue

        if not inquote and line.startswith("%REPEAT", i):
            depth += 1
            i += len("%REPEAT")
            continue

        if not inquote and line.startswith("%ENDR", i):
            depth -= 1
            if depth == 0:
                return i
            i += len("%ENDR")
            continue

        i += 1

    CPU.raiseerror(f"Unmatched %REPEAT in macro text: {line!r}")


def macro_stack_value(which):
    """
    Expand MacroStack references.

    %V = top of MacroStack
    %W = second item from top

    This assumes MacroStack is the global list you are already using.
    """
    global MacroStack

    if which == "V":
        if len(MacroStack) >= 1:
            return str(MacroStack[-1])
        return ""

    if which == "W":
        if len(MacroStack) >= 2:
            return str(MacroStack[-2])
        return ""

    return ""


def DecodeStr(instr, curaddress, CPU, JUSTRESULT, context: AssemblerContext):

    # Direct string handling (base case, no parsing)
    if ((instr.startswith('"') and instr.endswith('"')) or (instr.startswith("'") and instr.endswith("'"))) and not JUSTRESULT:
        midtext = instr[1:-1]
        for c in midtext:
            CPU.insertbyte(curaddress, int(ord(c)) & 0xff)
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

            context.FWORDLIST.append(
                ForwardRef(
                    symbol=resolved_label,
                    address=curaddress,
                    delta=delta,
                    file=context.ActiveFile,
                    line=context.FileLineNum,
                )
            )
            
            dprint(DBG_ASM,f"REF {resolved_label} at addr {curaddress:04x} with delta {delta} from {context.ActiveFile}:{context.FileLineNum}")
            

            # Reserve space (word = 2 bytes)
            CPU.insertbyte(curaddress, 0, context)
            CPU.insertbyte(curaddress+1, 0, context)  

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
        CPU.insertbyte(curaddress, result & 0xff, context)
        curaddress += 1

    elif prefix == '$$$':
        CPU.insertbyte(curaddress, result & 0xff, context)
        CPU.insertbyte(curaddress+1, (result  >> 8 ) & 0xff, context)
        CPU.insertbyte(curaddress+2, (result >> 16) & 0xff, context)
        CPU.insertbyte(curaddress+3, (result >> 24) & 0xff, context)        
        curaddress += 4

    else:  # default or $
        CPU.insertbyte(curaddress, result & 0xff, context)
        CPU.insertbyte(curaddress+1, (result >> 8)  & 0xff, context)        
        curaddress += 2

    if context.highwater < curaddress:
        context.highwater = curaddress

    return curaddress


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
        print("\n=== Missing Symbols ===")

        for sym in missing_symbols:
            count = context.UsedSymbols.get(sym, 0)
            refs = context.MissingSymbols.get(sym, {}).get("refs", [])

            print(f"\n  {sym}  (used {count} times)")

            if not refs:
                print("     no reference locations recorded")
                continue

            print("     References:")
            print("       #   Address  Source")
            print("       --  -------  ------------------------------")

            for idx, (file, line, addr) in enumerate(refs[:5], start=1):
                loc = f"{file}:{line}" if line is not None else str(file)
                print(f"       {idx:<2}  {addr:#06x}   {loc}")

            if len(refs) > 5:
                print(f"       ... {len(refs) - 5} more")


    # -----------------------------------------
    # Summary
    # -----------------------------------------
    print("\n=== Summary ===")
    print(f"  Defined symbols   : {len(defined)}")
    print(f"  Used symbols      : {len(used)}")
    print(f"  Unresolved symbols: {len(unresolved)}")

    if not unresolved:
        print("  ✔ All symbols resolved")            






def is_macro_word_at(s, i, word):
    if not s.startswith(word, i):
        return False

    before_ok = (
        i == 0
        or s[i - 1].isspace()
        or s[i - 1] == ";"
    )

    after = i + len(word)
    after_ok = (
        after >= len(s)
        or s[after].isspace()
        or s[after] == ";"
    )

    return before_ok and after_ok


def expand_macro_control(line, filename, context, CPU, scan_mode=False):
    i = 0
    out = []
    inquote = False
    escaped = False

    while i < len(line):
        ch = line[i]

        if inquote:
            out.append(ch)

            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                inquote = False

            i += 1
            continue

        if ch == '"':
            inquote = True
            out.append(ch)
            i += 1
            continue

        if not is_macro_word_at(line, i, "%REPEAT"):
            out.append(ch)
            i += 1
            continue

        # Found %REPEAT
        i += len("%REPEAT")

        count_val, used = parse_percent_arg(line[i:], filename, context, CPU)
        i += used

        count = int(count_val)
        if count < 0:
            CPU.raiseerror(f"%REPEAT count cannot be negative: {count}")

        body_start = i
        endr_start = find_matching_endr(line, body_start, CPU)

        body = line[body_start:endr_start]

        # Expand nested %REPEAT inside the body.
        body = expand_macro_control(body, filename, context, CPU, scan_mode=scan_mode)

        for _ in range(count):
            out.append(body)

        i = endr_start + len("%ENDR")

    return "".join(out)


def split_at_semicolon_outside_quotes(text):
    buf = []
    inquote = False
    inbackq = False
    escape = False

    for i, ch in enumerate(text):
        if escape:
            buf.append(ch)
            escape = False
            continue

        if ch == "\\":
            buf.append(ch)
            escape = True
            continue

        if ch == '"' and not inbackq:
            buf.append(ch)
            inquote = not inquote
            continue

        if ch == "`" and not inquote:
            buf.append(ch)
            inbackq = not inbackq
            continue

        if ch == ";" and not inquote and not inbackq:
            return "".join(buf).strip(), text[i + 1:].lstrip()

        buf.append(ch)

    return "".join(buf).strip(), ""

def enqueue_front(cmdq, cmd, text, context, origin=None):
    text = (text or "").strip()
    if not text:
        return
#    print(f"[LINE] {cmd.filename}:{cmd.line_num} : {text:.20}")
    for newcmd in reversed(split_source_commands(
        text,
        cmd.filename,
        cmd.resolved_filename,
        cmd.line_num,
        context.address,
        origin=origin or cmd.origin,
    )):
        cmdq.appendleft(newcmd)
def handle_skipped_command(line, key, size, context, CPU):
    if key == "ENDBLOCK":
        context.pop_block()
        return line[size:].strip()

    if key in MACRO_CONDITIONAL:
        _result, consumed = context.evaluate_condition(
            key, line, context.ActiveFile, CPU
            )
        context.push_block(executing=False, block_type=key)
        return line[consumed:].strip()
    
    # A skipped label may have ENDBLOCK after it:
    #   :_U_xxx_ENDIF ENDBLOCK
    # We must discard the label but keep the tail.
    if key.startswith(":"):
        return line[size:].strip()

    # Ordinary skipped command:
    # discard the whole command up to top-level semicolon.
    _, rest = split_at_semicolon_outside_quotes(line)
    return rest.strip()


def expand_unquoted_text(body, filename, context, CPU):
    out = []

    in_cmd_quote = False
    in_double_quote = False
    in_single_quote = False
    escape = False

    i = 0
    n = len(body)

    while i < n:
        ch = body[i]

        # Preserve escaped char literally inside normal text/quotes.
        if escape:
            out.append("\\" + ch)
            escape = False
            i += 1
            continue

        if ch == "\\":
            escape = True
            i += 1
            continue

        # Backquote protects macro expansion.
        if ch == "`" and not in_double_quote and not in_single_quote:
            in_cmd_quote = not in_cmd_quote
            # First pass: remove the protection quotes from stored expansion.
            i += 1
            continue

        if ch == '"' and not in_single_quote and not in_cmd_quote:
            in_double_quote = not in_double_quote
            out.append(ch)
            i += 1
            continue

        if ch == "'" and not in_double_quote and not in_cmd_quote:
            in_single_quote = not in_single_quote
            out.append(ch)
            i += 1
            continue

        # Quoted/protected text passes through unchanged.
        if in_cmd_quote or in_double_quote or in_single_quote:
            out.append(ch)
            i += 1
            continue

        # Expand macro invocation.
        if ch == "@":
            rest = body[i:]
            expanded = expand_macro_invocation_text(
                rest,
                filename,
                context,
                CPU,
                append_rest=False)
            consumed = consumed_one_source_command(rest, context, CPU)
            out.append(expanded)
            i += consumed
            continue

        # Otherwise copy normal text unchanged.
        out.append(ch)
        i += 1

    if in_cmd_quote:
        CPU.raiseerror(f"Unclosed backquote in macro text {filename}")
    if in_double_quote:
        CPU.raiseerror(f"Unclosed double quote in macro text {filename}")
    if in_single_quote:
        CPU.raiseerror(f"Unclosed single quote in macro text {filename}")

    return "".join(out).strip()            


def expand_macro_invocation(cmd, context, CPU, scan_mode=False):
    return expand_macro_invocation_text(
        removecomments(cmd.text).strip(),
        cmd.filename,
        context,
        CPU,
        scan_mode=scan_mode,
    )


def expand_macro_invocation_text(line, filename, context, CPU, append_rest=True, scan_mode=False):
    key, used = next_macro_name_token(line)
    if not key.startswith("@"):
        CPU.raiseerror(f"Expected macro invocation, got {key!r}")

    macro_name = key[1:]

    if macro_name not in context.MacroData:
        CPU.raiseerror(f"Unknown Macro @{macro_name}")

    body = context.MacroData[macro_name]
    argc = context.MacroPCount.get(macro_name, 0)

    args = []
    rest = line[used:].lstrip()

    dprint(DBG_MACRO, f"[MACRO INVOKE] key={key!r} used={used} macro_name={macro_name!r} rest={rest!r}")

    for _ in range(argc):
        arg, n = next_macro_arg(rest)
        if not arg:
            CPU.raiseerror(f"Missing argument for @{macro_name}")
        args.append(arg)
        rest = rest[n:].lstrip()

    old_varbaseSP = context.varbaseSP
    old_varbaseNext = context.varbaseNext

    base = context.varbaseNext
    context.varbaseSP += 1
    context.varcntstack[context.varbaseSP] = base

    context.MacroVars[base] = create_new_unique()
    for n, arg in enumerate(args, start=1):
        context.MacroVars[base + n] = arg

    context.varbaseNext = base + argc + 1
    # Do NOT expand {name} here.
    # A macro body may contain multiple semicolon-separated commands where an
    # earlier command changes a macro symbol used by a later command:
    #
    #   MF __LocalNum {VarCount} ; @LocalVar %1 {__LocalNum}
    #
    # Expanding braces across the whole body would see the old __LocalNum value.
    # Brace expansion belongs in command execution, after semicolon splitting.
    try:
        # 1. Invocation-local %0, %1, %2... substitution only.
        #    This is safe to do across the whole macro body because these values
        #    belong to this macro invocation frame and do not change command-by-command.
        expanded = substitute_macro_params_only(body, filename, context, CPU)
        # 2. Percent functions are invocation-time/template-time features.
        #    Be careful: functions that depend on mutable macro symbols should not
        #    force brace expansion across the whole body.
        expanded = expand_percent_functions(expanded, filename, context, CPU, scan_mode=scan_mode)
        # 3. Macro control expansion, e.g. %REPEAT/%ENDR.
        #    This may duplicate text, but should preserve {name} references inside
        #    each repeated command so they resolve when each command is executed.
        expanded = expand_macro_control(expanded, filename, context, CPU, scan_mode=scan_mode)
    finally:
        context.varbaseSP = old_varbaseSP
        context.varbaseNext = old_varbaseNext

    if rest and append_rest:
        expanded = expanded + " " + rest

    return expanded
def read_backquoted_body(text):
    """
    text must start with `.
    Returns (body_without_outer_backquotes, chars_consumed).

    Backslash may escape a backquote inside the body.
    Double-quoted strings are preserved and may contain backquotes.
    """
    if not text.startswith("`"):
        CPU.raiseerror("read_backquoted_body called on non-backquoted text")

    out = []
    i = 1
    in_dquote = False
    escaped = False

    while i < len(text):
        c = text[i]

        if escaped:
            out.append(c)
            escaped = False
            i += 1
            continue

        if c == "\\":
            out.append(c)
            escaped = True
            i += 1
            continue

        if c == '"':
            in_dquote = not in_dquote
            out.append(c)
            i += 1
            continue

        if c == "`" and not in_dquote:
            return "".join(out), i + 1

        out.append(c)
        i += 1

    CPU.raiseerror(f"Unterminated backquoted macro body: {text!r}")

def read_next_source_command(infile, filename, wfilename, context, CPU):
    """
    Read one logical source command from infile.

    Rules:
      - Physical lines may continue with trailing backslash.
      - Comments are removed before checking for continuation.
      - Blank/comment-only lines are skipped.
      - Returned object is a SourceCommand.
      - Returns None at EOF.
    """

    parts = []
    start_line_num = None

    while True:
        raw = infile.readline()
        physical_line_num = context.FileLineNum + 1
        context.FileLineNum = physical_line_num        
        dprint(DBG_MACRO, F"[DEBUG READ_LINE] {context.ActiveFile}:{context.FileLineNum}):\" {raw.rstrip()}\" len({len(raw.rstrip())})")
        if raw == "":
            if not parts:
                return None

            text = " ".join(parts).strip()
            return SourceCommand(
                text=text,
                filename=filename,
                resolved_filename=wfilename,
                line_num=start_line_num,
                address=context.address,
                origin="file",
            )


        line = raw.rstrip("\n\r")

        # Strip comments before continuation handling.
        directive, dargs = ParseDynDirective(line)
        if directive == "USE":
            context.UseRequested.update(ParseUseList(dargs))
            line=None
        line = removecomments(line).rstrip()

        if not line:
            if parts:
                continue
            continue

        if start_line_num is None:
            start_line_num = context.FileLineNum

        if line.endswith("\\"):
            parts.append(line[:-1].rstrip())
            continue

        parts.append(line)

        text = " ".join(parts).strip()
        if not text:
            parts = []
            start_line_num = None
            continue
        return SourceCommand(
            text=text,
            filename=filename,
            resolved_filename=wfilename,
            line_num=start_line_num,
            address=context.address,
            origin="file",
        )

def parse_macro_definition_command(line, key, size, cmdq=None):
    rest = line[size:].lstrip()

    macro_name, used = next_macro_name_token(rest)
    if not macro_name:
        CPU.raiseerror(f"{key} missing macro name: {line!r}")
    
    rest = rest[used:].lstrip()
    bt = -1
    inquote = False
    escaped = False

    for i, ch in enumerate(rest):
        if inquote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                inquote = False
            continue

        if ch == '"':
            inquote = True
            continue

        if ch == "`":
            bt = i
            break

    if bt >= 0:
        prefix = rest[:bt].strip()
        macro_body, used = read_backquoted_body(rest[bt:])
        tail = rest[bt + used:].lstrip()

        if tail.startswith(";"):
            tail = tail[1:].lstrip()

        if prefix:
            macro_body = prefix + " " + macro_body

        return macro_name, macro_body.strip(), tail.strip()

    macro_body, tail = split_at_semicolon_outside_quotes(rest)
    return macro_name, macro_body.strip(), tail.strip()

    
# Load file is also the effective main loop for the assembler
# def loadfile(filename, offset, CPU, LorgFlag,  LocalID, context: AssemblerContext):

def loadfile(filename, offset, CPU, LorgFlag,  LocalID, context: AssemblerContext):
    global FileLineData

    context.LoadDepth += 1

    old_lorgflag = context.LORGFLAG
    old_localid = context.LocalID

    context.LORGFLAG = LorgFlag
    context.LocalID = LocalID
    PreviousLineNumber = context.FileLineNum
    context.FileLineNum = 0

    try:
        context.address = offset        
        cmdq = deque()

        wfilename = fileonpath(filename)  # uses CPUPATH env to find matches if not cwd

        with open(wfilename, "r") as infile:
            while True:
                # If no pending command, read more physical source.
                if not cmdq:
                    cmds = read_next_source_command(infile, filename, wfilename, context, CPU)
                    if not cmds :
                        break
                    if isinstance(cmds, list):
                        cmdq.extend(cmds)
                    else:
                        cmdq.append(cmds)
                cmd = cmdq.popleft()
                line = removecomments(cmd.text).strip()
                if not line:
                    continue                

                context.ActiveFile = cmd.filename
                context.ActiveResolvedFile = cmd.resolved_filename

                key, size = nextwordplus(line)
                if not key:
                    continue
                
                dprint(DBG_ASM,
                       f"[CMD] exec={context.is_executing()} "
                       f"depth={len(context.MacroBlockStack)} "
                       f"addr={context.address:04x} "
                       f"line={context.ActiveFile}:{context.FileLineNum} "
                       f"cmd={line!r}"
                       )

                # 1. Skipped conditional body.
                # Still parse only control structure commands so nesting stays balanced.
                if not context.is_executing():
                    if key.startswith("@"):
                        expanded = expand_macro_invocation(cmd, context, CPU, scan_mode=True)
                        enqueue_front(cmdq, cmd, expanded, context, origin="macro-scan")
                        continue

                    rest = handle_skipped_command(line, key, size, context, CPU)
                    enqueue_front(cmdq, cmd, rest, context)
                    continue
                # 2. Conditional close.
                if key == "ENDBLOCK":
                    context.pop_block()
                    enqueue_front(cmdq, cmd, line[size:].strip(), context)
                    continue

                # 3. Conditional open.
                if key in MACRO_CONDITIONAL:
                    result, consumed = context.evaluate_condition(key, line, cmd.filename, CPU)
                    context.push_block(executing=result, block_type=key)
                    enqueue_front(cmdq, cmd, line[consumed:].strip(), context)
                    continue
                # 4. M Declarations:
                if key == "M":
                    macro_name, macro_body, rest = parse_macro_definition_command(
                        line, key, size, cmdq
                    )
                    context.define_macro(
                        macro_name,
                        macro_body,
                        cmd.filename,
                        cmd.resolved_filename,
                        cmd.line_num,
                    )

                    enqueue_front(cmdq, cmd, rest, context)
                    continue
                line = substitute_macro_stack_opts(line, cmd.filename, context, CPU)
                line = line.strip()
                if not line:
                    continue
                cmd.text = line

                key, size = nextwordplus(line)
                if not key:
                    continue


                # 5. Macro invocation.
                if key.startswith("@"):
                    expanded = expand_macro_invocation(cmd, context, CPU)
                    dprint(DBG_MACRO, f"[AT EXPAND] {line!r} -> {expanded!r}")
                    enqueue_front(cmdq, cmd, expanded, context, origin="macro")
                    continue

                # 6. Everything else is an assembler/meta command:
                # M, MF, =, :, P, I, L, raw opcode/data, etc.
                context.CurrentSourceFile = cmd.filename
                context.CurrentSourceLine = cmd.line_num
                try:
                    rest = execute_assembler_command(cmd, CPU, context)
                finally:
                    context.CurrentSourceFile = ""
                    context.CurrentSourceLine = 0
#                tail = execute_assembler_command(cmd, CPU, context)
                enqueue_front(cmdq, cmd, rest, context)
                continue
                        
    finally:
        context.LoadDepth -= 1
        context.LORGFLAG = old_lorgflag
        context.LocalID = old_localid
    if context.LoadDepth == 0:
        resolve_all_forward_references(context, CPU)
        
    context.FileLineNum=PreviousLineNumber
    
    return context.address

def longest_prefix_match(s,d):
    for key in sorted(d.keys(), key=len, reverse=True):
        if s.startswith(key):
            return key
    return None

def consumed_one_source_command(line, context, CPU=None):
    i = skip_ws(line, 0)
    if i >= len(line):
        return i

    key, kused = nextwordplus(line[i:])
    if not key:
        return i

    # @macro
    if key.startswith("@"):
        macro_name = key[1:]
        if macro_name not in context.MacroPCount:
            if CPU:
                CPU.raiseerror(f"Unknown macro @{macro_name}")
            return i + kused

        used = i + kused
        for _ in range(context.MacroPCount[macro_name]):
            used = skip_ws(line, used)
            arg, n = next_macro_arg(line[used:])
            if not arg:
                if CPU:
                    CPU.raiseerror(f"Missing argument for @{macro_name}")
                return used
            used += n
        return used

    # built-in
    match = longest_prefix_match(line[i:], COMMAND_SPEC)
    if match is None:
        return i + kused

    spec = COMMAND_SPEC[match]
    used = i + len(match)
    arg_kinds = list(spec.get("arg_kind", []))

    if spec.get("arity", 0) < 0:
        attached = line[used:]
        if attached and not attached[0].isspace():
            _, au = nextword(attached)
            used += au
            arg_kinds = arg_kinds[1:]

    for kind in arg_kinds:
        used = skip_ws(line, used)

        if kind == "equation":
            arg, n = nextwordequation(line[used:])
        else:
            arg, n = nextwordplus(line[used:])

        if not arg:
            if CPU:
                CPU.raiseerror(f"Missing {kind} argument after {match}")
            return used

        used += n

    return used

def split_source_commands(text, filename, resolved_filename, line_num, address, origin="file"):
    """
    Split expanded source text into SourceCommand objects.

    Semicolon is a command separator only when not inside:
      - double quotes: "..."
      - single quotes: '...'
      - backquote macro-protection: `...`

    Backquotes are preserved here. They are macro-expansion syntax, not
    source-command separators.
    """
    out = []
    buf = []

    in_double = False
    in_single = False
    in_backquote = False
    escape = False

    text = text.replace("ENDMACENDMAC", " ; ")

    def flush():
        s = "".join(buf).strip()
        buf.clear()
        if s:
            out.append(SourceCommand(
                text=s,
                filename=filename,
                resolved_filename=resolved_filename,
                line_num=line_num,
                address=address,
                origin=origin,
            ))

    for ch in text:
        if escape:
            buf.append(ch)
            escape = False
            continue

        if ch == "\\":
            buf.append(ch)
            escape = True
            continue

        if ch == "`" and not in_single and not in_double:
            buf.append(ch)
            in_backquote = not in_backquote
            continue

        if not in_backquote:
            if ch == '"' and not in_single:
                buf.append(ch)
                in_double = not in_double
                continue

            if ch == "'" and not in_double:
                buf.append(ch)
                in_single = not in_single
                continue

        if ch == ";" and not in_double and not in_single and not in_backquote:
            flush()
            continue

        buf.append(ch)

    flush()
    return out

def execute_assembler_command(cmd, CPU, context):
    
    line = cmd.text.strip()
    filename = cmd.filename

    if not line:
        return

    context.ActiveFile = cmd.filename
    context.ActiveResolvedFile = cmd.resolved_filename

    key, size = nextwordplus(line)
    rest = line[size:].lstrip()
    IsOneChar = len(key) == 1

    if key[0] == "^":
        if len(key) > 1 and  key[1] >= "0" and key[1] <= "4":
            context.Debug=int(key[1])
            dprint(DBG_ASM,f"[DEBUG LEVEL] {context.Debug}")                    
            return rest
        CPU.raiseerror(f"Invalid debug directive {key!r}")

    if key[0] == ":":
        # Supports both ":FOO" and ": FOO"
        if len(key) > 1:
            DestKey = key[1:]
            used = 0
        else:
            DestKey, used = nextword(rest)
            if not DestKey:
                CPU.raiseerror(
                    f"Missing label name after ':' {filename}:{cmd.line_num}"
                )

        SrcVal = context.address

        dprint(
            DBG_INTERNAL,
            f"[LABEL] {DestKey} address={context.address:04x} "
            f"file={context.ActiveFile}"
        )

        newitem = IsLocalVar(DestKey, context)

        auto_label = f"F.{filename}:{context.FileLineNum}"
        context.FileLabels.pop(auto_label, None)

        context.FileLabels[newitem] = SrcVal
        context.DefinedSymbols.add(newitem)

        if DestKey in context.GlobalDeclarations:
            context.GlobeLabels[DestKey] = SrcVal
            context.DefinedSymbols.add(DestKey)
            dprint(DBG_ASM, f"[LABEL] {DestKey} = {SrcVal:04x}")

        UpdateVarHistory(newitem, SrcVal, SrcVal)

        dprint(
            DBG_ASM,
            f"DEF ':' {DestKey} -> {newitem} = {SrcVal:#04x} "
            f"{context.ActiveFile}:{context.FileLineNum}"
        )

        return rest[used:].lstrip()
    
    elif key.startswith(";"):
        if len(key) > 1:
            rest=key[1:]+rest
        rest=handle_semicolon(rest, filename, context, CPU)
        return rest.lstrip()
    elif key[0] == "=":
        if len(key) > 1:
            DestKey = key[1:]
            expr = rest
            dest_used = 0
        else:
            DestKey, dest_used = nextword(rest)
            expr = rest[dest_used:].lstrip()

        if not DestKey:
            CPU.raiseerror(
                f"Missing destination in '=' directive {filename}:{context.FileLineNum}"
            )

        if not expr:
            CPU.raiseerror(
                f"Missing expression in '=' directive for {DestKey} "
                f"{filename}:{context.FileLineNum}"
            )

        dprint(DBG_INTERNAL, f"[= EVAL IN] DestKey={DestKey!r} expr={expr!r}")

        expanded_expr = expand_macro_pipeline(expr, filename, context, CPU)

        value, expr_used = FirstPassVal(
            expanded_expr,
            context,
            filename=filename,
            allow_braces=True
        )

        newitem = IsLocalVar(DestKey, context)
        context.FileLabels[newitem] = value
        context.DefinedSymbols.add(newitem)
        UpdateVarHistory(newitem, value, context.address)

        dprint(
            DBG_ASM,
            f"DEF '=' {DestKey} -> {newitem} @ {value} "
            f"{context.ActiveFile}:{context.FileLineNum}"
        )

        trailing = expanded_expr[expr_used:].strip()
        return trailing
    elif (key == ".") and context.Entry == 0:
        if not rest:
            CPU.raiseerror(f"Missing address for {key} {filename}:{context.FileLineNum}")

        value, used = FirstPassVal(
            rest,
            context,
            filename=filename,
            allow_braces=True
        )

        trailing = rest[used:].lstrip()
        if trailing:
            CPU.raiseerror(
                f"Unexpected trailing text after {key}: {trailing!r} "
                f"{filename}:{context.FileLineNum}"
            )

        context.address = Str2Word(value)
        context.Entry = context.address
        return

    elif (key == ".") and context.Entry != 0:
        if not rest:
            CPU.raiseerror(f"Missing address for {key} {filename}:{context.FileLineNum}")

        value, used = FirstPassVal(
            rest,
            context,
            filename=filename,
            allow_braces=True
        )

        trailing = rest[used:].lstrip()
        if trailing:
            CPU.raiseerror(
                f"Unexpected trailing text after {key}: {trailing!r} "
                f"{filename}:{context.FileLineNum}"
            )

        context.address = Str2Word(value)
        return
    
    elif key.upper() == ".ORG":
        if not rest:
            CPU.raiseerror(f"Missing address for {key} {filename}:{context.FileLineNum}")

        value, used = FirstPassVal(
            rest,
            context,
            filename=filename,
            allow_braces=True
        )

        trailing = rest[used:].lstrip()
        if trailing:
            CPU.raiseerror(
                f"Unexpected trailing text after {key}: {trailing!r} "
                f"{filename}:{context.FileLineNum}"
            )

        context.address = Str2Word(value)
        context.Entry = context.address
        return

    elif key.upper() == ".DATA":
        if not rest:
            CPU.raiseerror(f"Missing address for .DATA {filename}:{context.FileLineNum}")

        value, used = FirstPassVal(
            rest,
            context,
            filename=filename,
            allow_braces=True,
        )

        rest2 = rest[used:].lstrip()
        if rest2:
            CPU.raiseerror(
                f"Unexpected trailing text after .DATA: {rest2!r} "
                f"{filename}:{context.FileLineNum}"
            )

        value = Str2Word(value)
        context.DataSegment = value
        context.dataaddress = value
        return ""
    elif key == "D":
        origfilename, used = nextword(rest)
        if not origfilename:
            CPU.raiseerror(f"Missing filename for D directive {filename}:{context.FileLineNum}")

        newfilename = None

        hold_file = context.ActiveFile
        hold_resolved = context.ActiveResolvedFile
        hold_line = context.FileLineNum

        try:
            newfilename = FilterLibrary(origfilename, context)
        
            new_local_id = f"{context.UniqueLineNum}:{newfilename}"

            context.highaddress = context.address = loadfile(
                newfilename,
                context.address,
                CPU,
                LOCALFLAG,
                new_local_id,
                context,
            )
        finally:
            if newfilename:
                FilterLibraryCleanUp(newfilename, context)
        
            context.ActiveFile = hold_file
            context.ActiveResolvedFile = hold_resolved
            context.FileLineNum = hold_line
        
        return rest[used:].lstrip()

        

    elif key == "L":
        newfilename, used = nextword(rest)
        if not newfilename:
            CPU.raiseerror(f"Missing filename for L directive {filename}:{context.FileLineNum}")

        hold_file = context.ActiveFile
        hold_resolved = context.ActiveResolvedFile
        hold_line = context.FileLineNum
        new_local_id = f"{context.UniqueLineNum}:{newfilename}"

        context.highaddress = context.address = loadfile(
            newfilename,
            context.address,
            CPU,
            LOCALFLAG,
            new_local_id,
            context,
        )

        context.ActiveFile = hold_file
        context.ActiveResolvedFile = hold_resolved
        return rest[used:].lstrip()

    elif key == "I":
        # Include a file in the current/global label context.
        newfilename, used = nextword(rest)
        if not newfilename:
            CPU.raiseerror(
                f"Missing filename for I directive "
                f"{cmd.filename}:{cmd.line_num}"
            )

        hold_file = context.ActiveFile
        hold_resolved_file = context.ActiveResolvedFile
        save_lorgflag = context.LORGFLAG
        save_localid = context.LocalID
        
        context.highaddress = context.address = loadfile(
            newfilename,
            context.address,
            CPU,
            GLOBALFLAG,
            context.LocalID,
            context,
        )

        context.LORGFLAG = save_lorgflag
        context.LocalID = save_localid
        context.ActiveFile = hold_file
        context.ActiveResolvedFile = hold_resolved_file
        return rest[used:].lstrip()

    elif key == "P":        
        # Assembly-time debug print.
        body, tail = split_at_semicolon_outside_quotes(rest)

        body = expand_macro_pipeline(body, filename, context, CPU)

        before_brace = body
        nline = expand_brace_refs(
            body,
            filename,
            context,
            CPU,
            preserve_unresolved=True,
        )

        dprint(DBG_MACRO, f"[P BRACE] {before_brace} -> {nline}")
        safeprint(nline.strip())

        return tail
    elif key == "MA":
        # Append one token to an existing macro.
        macro_name, nsize = nextword(rest)
        if not macro_name:
            CPU.raiseerror("MA missing macro name")

        tail = rest[nsize:].lstrip()
        value, vsize = nextword(tail)
        if not value:
            CPU.raiseerror(f"MA {macro_name} missing value")

        oldval = context.MacroData.get(macro_name, "")
        newval = (oldval + " " + value).strip()

        context.MacroData[macro_name] = newval
        context.MacroPCount[macro_name] = 0
        return tail[vsize:].lstrip()

    elif key == "MF":
        macro_name, nsize = nextword(rest)
        if not macro_name:
            CPU.raiseerror("MF missing macro name")

        tail = rest[nsize:].lstrip()
        value_text, vsize = nextwordplus(tail)
        if value_text == "%EVAL":
            expr_tail = tail[vsize:].lstrip()
            expr, esize = nextwordplus(expr_tail)
            if not expr:
                CPU.raiseerror(f"MF {macro_name} missing %EVAL expression")
            value_text = "%EVAL" + expr
            rest_after= expr_tail[esize:].lstrip()
        else:
            rest_after = tail[vsize:].lstrip()
        
        
        if not value_text:
            CPU.raiseerror(f"MF {macro_name} missing value")
        
        value = expand_macro_assignment_value(value_text, filename, context, CPU)
        if value == '""':
            CPU.raiseerror(f"MF {macro_name} missing value")

        if value == '""':
            context.MacroData.pop(macro_name, None)
            context.MacroPCount.pop(macro_name, None)
        else:
            context.define_macro(macro_name,
                             value,
                             context.ActiveFile,
                             context.ActiveResolvedFile,
                             context.FileLineNum)

        return rest_after

    elif key == "G":
        gkey, gsize = nextword(rest)
        if not gkey:
            CPU.raiseerror(
                f"Global declaration missing symbol "
                f"{context.ActiveFile}:{context.FileLineNum}"
            )

        if not hasattr(context, "GlobalDeclInfo"):
            context.GlobalDeclInfo = {}

        if gkey in context.GlobalDeclarations:
            first = context.GlobalDeclInfo.get(gkey, "<unknown>")
            dprint(
                DBG_ASM,
                f"WARNING: duplicate global declaration of {gkey} "
                f"(first at {first}, again at "
                f"{context.ActiveFile}:{context.FileLineNum})"
            )
        else:
            dprint(
                DBG_ASM,
                f"[GLOBAL] {gkey} declared at "
                f"{context.ActiveFile}:{context.FileLineNum}"
            )

        context.GlobalDeclarations.add(gkey)
        context.GlobalDeclInfo[gkey] = (
            context.ActiveFile,
            context.FileLineNum,
        )

        return rest[gsize:].lstrip()

    else:
        # Raw data / opcode / label expression.
        # DecodeStr consumes one already-split command token.
        context.CurrentLineBeingParsed = context.FileLineNum

        if context.address > context.highaddress:
            context.highaddress = context.address

        if not key:
            return rest.lstrip()

        if context.ExpectData > 0:
            prevval = context.dataaddress
            key = expand_brace_refs(
                key,
                filename,
                context,
                CPU,
                preserve_unresolved=True,
            )
            dprint(DBG_INTERNAL,f"[RAW BRACE] {raw_key!r} -> {key!r}")


            context.dataaddress = DecodeStr(
                key,
                context.dataaddress,
                CPU,
                False,
                context
            )

            context.ExpectData -= context.dataaddress - prevval

            if context.ExpectData < 0:
                CPU.raiseerror(
                    f"Too much data supplied for reserved data block "
                    f"{context.ActiveFile}:{context.FileLineNum}"
                )

            if context.dataaddress > context.highaddress:
                context.highaddress = context.dataaddress
        else:
            raw_key = key
            key = expand_brace_refs(
                key,
                filename,
                context,
                CPU,
                preserve_unresolved=True,
                )
            dprint(DBG_INTERNAL,f"[RAW BRACE] {raw_key!r} -> {key!r}")
            context.address = DecodeStr(
                key,
                context.address,
                CPU,
                False,
                context
            )
            if context.dataaddress > context.highaddress:
                context.highaddress = context.dataaddress

        return rest.lstrip()

def resolve_all_forward_references(context, CPU):
    #
    #
    # --------------------------------------------------
    # Resolve forward references (FWORDLIST)
    # --------------------------------------------------

    end_address = max(
        context.highwater,
        context.highaddress,
        context.address,
        context.dataaddress if context.DataSegment >= 0 else 0,
    )
    context.GlobeLabels["END__"] = end_address
    context.FileLabels["END__"] = end_address
    context.DefinedSymbols.add("END__")
    LocVarHist["END__"] = [{"value": end_address, "start": 0, "end": None}]

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

    for ref in context.FWORDLIST:
        key = ref.symbol
        vaddress = ref.address

        found = key in context.GlobeLabels
        val = context.GlobeLabels[key] if found else None
        dprint(DBG_INTERNAL,f"[CHECK] addr={vaddress:04x} symbol={key} found={found} value={val}")

            # Track usage
        if not IsCompilerGenerated(key):
            record_symbol_use(context, key, vaddress, file=ref.file, line=ref.line)

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
        if resolved:
            context.ResolvedSymbols.add(key) 

            if ref.delta:
                v = v + Str2Word(ref.delta)
            CPU.insertbyte(int(vaddress), CPU.lowbyte(v), context)
            CPU.insertbyte(int(vaddress+1), CPU.highbyte(v), context)                            

        if context.address > context.highaddress:
            context.highaddress = context.address
        if context.dataaddress > context.highaddress:
            context.highaddress = context.dataaddress

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
        if cmdword == "pm":
            matches = []

            for key, body in context.MacroData.items():
                body_str = str(body)
                argc = context.MacroPCount.get(key, 0)

                if not rawlist or any(
                        re.search(pattern, key) or re.search(pattern, body_str)
                    for pattern in rawlist
                ):
                    matches.append((key, argc, body_str))

            if not matches:
                safeprint("No matching macros.\n")
                continue

            for key, argc, body in matches:
                safeprint(f"{key}({argc})")
                safeprint("Body: ",end="")
                safeprint(body)

            continue

        if cmdword == "pa":
            # Filter labels
            filtered_labels = {
                key: value for key, value in context.FileLabels.items()
                if not IsCompilerGenerated(key) 
                and not key.startswith("F.")
                and not key.startswith("M.")
            }

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
                         CPU.insertbyte(maddr, mvalue & 0xff, context)
                         mvalue = int(iad) >> 8
                         CPU.insertbyte(maddr, mvalue & 0xff, context)                        
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
                                         CPU.insertbyte(maddr, ord(quotetext[iii]) & 0xff , context)
                                         maddr += 1
                                     cmdline=cmdline[L[1]:]
                                     L=("",0)
                                     continue
                                 if len(L[0]) == 1 and L[0][0:1] >= "0" and L[0][0:1] <= "9":
                                     newval = int(L[0])
                                     # Single digit number must be b10
                                     CPU.insertbyte(maddr, newval &0xff , context)
                                     maddr += 1
                                     # high byte has to be zero
                                     CPU.insertbyte(maddr, 0 , context)                                    
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
                                         CPU.insertbyte(maddr, newval & 0xff, context)
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
                    if tresult != None:
                        (_, _, stopaddr)=tresult
            else:
                startaddr = CPU.pc  # Default to current PC
                stopaddr = (startaddr + 3) & 0xfffe

            # If only start address found, compute default end
            if startaddr is not None and stopaddr is None:
                stopaddr = (startaddr + 3) & 0xffff

                # Validate range
            if startaddr is not None and stopaddr is not None:
                if stopaddr < startaddr:
                    stopaddr = startaddr + abs(stopaddr)
                elif stopaddr == startaddr:
                    stopaddr = (startaddr + 3) & 0xffff
                print(f"Best Match: {startaddr:04x}")
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

            CurrentAddress = CPU.pc
            OriginalAddress = CurrentAddress

            info = CPU.FindWhatLineInfo(CurrentAddress)
            if info is None:
                OriginalFile = None
                OriginalLine = None
            else:
                OriginalFile, OriginalLine = info

            is_call = False
            StateCtrl = 0

            if "PUSH" in OPTDICT:
                PUSHCODE = OPTDICT["PUSH"][0]
                JMPCODE = OPTDICT["JMP"][0]

                # At this time we'll not worry about CALLZ and CALLNZ as they are rare.
                while CPU.pc <= 0xffff:
                    # We only care about JMP if the previous call was PUSH addr.
                    if CPU.memspace[CPU.pc] != JMPCODE and StateCtrl == 1:
                        StateCtrl = 0

                    if CPU.memspace[CPU.pc] == JMPCODE and StateCtrl == 1:
                        is_call = True
                        StateCtrl = 0

                    if CPU.memspace[CPU.pc] == PUSHCODE:
                        PossAddress = CPU.getwordmem(CPU.pc + 1)
                        if CPU.pc <= PossAddress <= CPU.pc + 12:
                            StateCtrl = 1

                    if is_call:
                        # We are doing a call; run until the pushed return address.
                        while PossAddress != CPU.pc:
                            CPU.evalpc(context, 1)

                        is_call = False
                        StateCtrl = 0

                    else:
                        info = CPU.FindWhatLineInfo(CPU.pc)

                        # If there is no source-line mapping, fall back to one opcode step.
                        if OriginalLine is None or info is None:
                            CPU.evalpc(context, 1)
                            DissAsm(CPU.pc, 1, CPU)
                            break

                        ThisFile, ThisLine = info

                        if ThisFile != OriginalFile or ThisLine != OriginalLine:
                            DissAsm(CPU.pc, 1, CPU)
                            break

                        CPU.evalpc(context, 1)

        if cmdword == "c":
            stoprange = 0
#            DissAsm(CPU.pc, 1, CPU)
            AtLeastOne = 1
            while CPU.pc <= 0xfffe:
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
                oldfilename = context.ActiveFile
                NewLocalID = str(context.UniqueLineNum)+ii
                context.highaddress = \
                    loadfile(ii, 0, CPU , LOCALFLAG, NewLocalID, context)
                context.ActiveFile = oldfilename
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
                oldfilename = context.ActiveFile
                NewLocalID = str(context.UniqueLineNum)+ii
                context.highaddress = \
                    loadfile(ii, 0, CPU , GLOBALFLAG, NewLocalID, context)
                context.ActiveFile = oldfilename
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
#    context.UseRequested = []
def ResolveUses(functions, root_uses):
    selected = set()
    pending = list(root_uses)

    while pending:
        name = pending.pop()

        if name in selected:
            continue

        func = functions.get(name)
        if func is None:
            continue

        selected.add(name)

        for dep in func.uses:
            if dep not in selected:
                pending.append(dep)

    return selected
def ParseDynDirective(line):
    s = line.strip()

    if not s:
        return None, ""

    if s.startswith("#"):
        s = s[1:].lstrip()
        parts = s.split(None, 1)
        key = parts[0].upper() if parts else ""
        argstr = parts[1] if len(parts) > 1 else ""

        if key == "USE":
            return "USE", argstr

        return None, ""

    if s.startswith("@"):
        parts = s.split(None, 1)
        key = parts[0].upper()
        argstr = parts[1] if len(parts) > 1 else ""

        if key in ("@FUNCTION", "@ENDFUNCTION"):
            return key[1:], argstr   # return FUNCTION / ENDFUNCTION

    return None, ""

def ParseUseList(argstr):
    result = []

    for part in argstr.replace(",", " ").split():
        name = part.strip()
        if name:
            result.append(name)

    return result

# Scan file for UseRequested rules and create new temp file based filtered rules
# Returns new filename thats result of filtering input filename.

def FilterLibrary(origfilename, context):
    functions = {}
    function_order = []
    global_body = []
    chunks = []
    global_chunk = []

    def flush_global():
        nonlocal global_chunk
        if global_chunk:
            chunks.append(("global", global_chunk))
            global_chunk = []
        


    newfilename = CreateTempFilename(origfilename)  

    current = None

    wfilename = fileonpath(origfilename)

    with open(wfilename) as f:
        for lineno, line in enumerate(f, start=1):
            directive, args = ParseDynDirective(line)

            if directive == "FUNCTION":
                name = args.split()[0]
                flush_global()                

                current = DynFunction(
                    name=name,
                    source_file=wfilename,
                    start_line=lineno,
                )

                functions[name] = current
                function_order.append(name)
                chunks.append(("function",name))                
                current.body.append(line)
                continue

            if directive == "ENDFUNCTION":
                if current is not None:
                    current.body.append(line)
                    current = None
                else:
                    global_body.append(line)
                continue

            if directive == "USE":
                names = ParseUseList(args)

                if current is None:
                    context.UseRequested.update(names)
                else:
                    current.uses.update(names)

                continue

            if current is not None:
                current.body.append(line)
            else:
                global_chunk.append(line)


    flush_global()

    selected = ResolveUses(functions, context.UseRequested)
    with open(newfilename, "w") as out:
        out.write(f"# Dynamic library generated from {origfilename}\n")
        for kind, data in chunks:
            if kind == "global":
                out.writelines(data)
            elif kind == "function":
                name = data
                if name in selected:
                    func = functions[name]
                    out.write(f"\n# DYNAMIC FUNCTION {name} from {func.source_file}:{func.start_line}\n")
                    out.writelines(func.body)
                    out.write(f"# END DYNAMIC FUNCTION {name}\n")

    return newfilename        

def FilterLibraryCleanUp(filename, context):
    if not filename:
        return

    # Optional debug escape hatch
    if getattr(context, "KeepDynamicLibraries", False):
        return

    try:
        os.remove(filename)
    except FileNotFoundError:
        pass
    except OSError as e:
        print(f"Warning: could not remove dynamic library temp file {filename}: {e}")


def CreateTempFilename(origfilename):
    base = os.path.basename(origfilename)

    fd, path = tempfile.mkstemp(
        prefix=f"dynlib_{base}_",
        suffix=".ld",
        text=True,
    )

    os.close(fd)
    return path

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
    breakafter = ()

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
                context.Debug = min(context.Debug + 1, DBG_INTERNAL)
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
    CPU.pc = context.Entry
    if context.Debug > 1:
        dprint(DBG_ASM,"Start of Run: Debug: %s: Watch: %s" % (context.Debug, context.watchword))
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
