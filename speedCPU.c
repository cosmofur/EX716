#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <numpy/arrayobject.h>

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#include "speedCPU.h"

#define MAXMEM 0x10000
#define MAXHWSTACK (0xff - 2)
#define BLOCK_SIZE 512

#define FL_Z 0x1
#define FL_N 0x2
#define FL_C 0x4
#define FL_O 0x8

#define RC_END_PROGRAM     -1
#define RC_STACK_UNDERFLOW -2
#define RC_STACK_OVERFLOW  -3
#define RC_USER_HALT       -4
#define RC_INVALID_INPUT   -5
#define RC_DISK_SEEK_FAIL  -6
#define RC_DEVICE_READ_FAIL -7
#define RC_DEVICE_MEM_FAIL -8
#define RC_DEVICE_WRITE_FAIL -9
#define RC_DEVICE_GENERAL_FAIL -10
#define RC_DEBUG_TOGGLE    -11

/* CAST commands */
#define CastPrintStr 1
#define CastPrintInt 2
#define CastPrintIntI 3
#define CastPrintSignI 4
#define CastPrintBinI 5
#define CastPrintChar 6
#define CastPrintStrI 11
#define CastPrintIntUI 12
#define CastPrintCharI 16
#define CastPrintHexI 17
#define CastPrintHexII 18
#define CastPrintErrMsg 19
#define CastSelectDisk 20
#define CastSeekDisk 21
#define CastWriteSector 22
#define CastSyncDisk 23
#define CastSelectDiskI 24
#define CastSeekDiskI 25
#define CastWriteSectorI 26
#define CastPrint32I 32
#define CastPrint32II 33
#define CastPrint32S 34
#define CastPrint32SignI 35
#define CastPrint32SignS 36
#define CastTapeWrite 40
#define CastTapeWriteI 41
#define CastEnd 99
#define CastDebugToggle 100
#define CastStackDump 102

/* POLL commands */
#define PollReadIntI 1
#define PollReadStrI 2
#define PollReadCharI 3
#define PollSetNoEcho 4
#define PollSetEcho 5
#define PollReadCINoWait 6
#define PollSetRawCode 7
#define PollReSetRaw 8
#define PollTTYStateCode 9
#define PollReadSector 22
#define PollReadTapeI 23
#define PollRewindTape 24
#define PollReadTime 25
#define PollReadSectorI 26
#define PollReadTape 27

static volatile sig_atomic_t g_return_code = 0;
static volatile sig_atomic_t g_interrupt_requested = 0;
static FILE *g_disk = NULL;
static FILE *g_tape = NULL;
static int g_disk_ptr = 0;
static struct termios g_saved_attrs;
static int g_saved_valid = 0;

/*
 * What it does:
 * - Signal handler for Ctrl-C that requests VM stop via a global return code.
 * Arguments:
 * - sig: POSIX signal number (unused beyond signature contract).
 * Output structure:
 * - No return value; writes RC_USER_HALT to g_return_code.
 * Parent/call mechanism:
 * - Registered by signal() in c_EvalOne(); invoked by the OS signal subsystem.
 */
static void handle_ctrl_c(int sig) {
    (void)sig;
    g_return_code = RC_USER_HALT;
    g_interrupt_requested = RC_USER_HALT;
    ssize_t ignored = write(STDERR_FILENO, "^C\n", 3);
    (void)ignored;
}

/*
 * What it does:
 * - Reads a 16-bit little-endian word from emulated memory with wrap-around.
 * Arguments:
 * - mem: Pointer to 64K byte-addressable VM memory.
 * - addr: Source byte address (masked to 16-bit range).
 * Output structure:
 * - Returns uint16_t assembled from mem[addr] and mem[addr+1].
 * Parent/call mechanism:
 * - Internal helper called by step_once(), handle_cast(), and handle_poll().
 */
static inline uint16_t get16(const uint8_t *mem, int addr) {
    uint16_t a = (uint16_t)(addr & 0xFFFF);
    uint16_t b = (uint16_t)((a + 1) & 0xFFFF);
    return (uint16_t)(mem[a] | ((uint16_t)mem[b] << 8));
}

/*
 * What it does:
 * - Writes a 16-bit little-endian word into emulated memory with wrap-around.
 * Arguments:
 * - mem: Pointer to 64K byte-addressable VM memory.
 * - addr: Destination byte address (masked to 16-bit range).
 * - val: 16-bit value to store.
 * Output structure:
 * - No return value; mutates mem at addr and addr+1.
 * Parent/call mechanism:
 * - Internal helper called by step_once() and handle_poll().
 */
static inline void put16(uint8_t *mem, int addr, uint16_t val) {
    uint16_t a = (uint16_t)(addr & 0xFFFF);
    uint16_t b = (uint16_t)((a + 1) & 0xFFFF);
    mem[a] = (uint8_t)(val & 0xFF);
    mem[b] = (uint8_t)((val >> 8) & 0xFF);
}

/*
 * What it does:
 * - Pushes one 16-bit value onto the VM hardware stack with bounds checks.
 * Arguments:
 * - stack: Pointer to uint16_t stack storage.
 * - sp: In/out stack pointer (next free slot index).
 * - val: Value to push.
 * Output structure:
 * - Returns 0 on success or RC_STACK_OVERFLOW on failure.
 * Parent/call mechanism:
 * - Internal helper used by step_once() and handle_poll().
 */
static inline int push16(uint16_t *stack, int *sp, uint16_t val) {
    if (*sp < 0 || *sp >= MAXHWSTACK) {
        return RC_STACK_OVERFLOW;
    }
    stack[*sp] = val;
    *sp += 1;
    return 0;
}

/*
 * What it does:
 * - Pops one 16-bit value from the VM hardware stack with underflow checks.
 * Arguments:
 * - stack: Pointer to uint16_t stack storage.
 * - sp: In/out stack pointer (decremented on success).
 * - out: Destination for popped value.
 * Output structure:
 * - Returns 0 on success or RC_STACK_UNDERFLOW on failure.
 * Parent/call mechanism:
 * - Internal helper used by step_once(), handle_cast(), and handle_poll().
 */
static inline int pop16(uint16_t *stack, int *sp, uint16_t *out) {
    if (*sp <= 0) {
        return RC_STACK_UNDERFLOW;
    }
    *sp -= 1;
    *out = stack[*sp];
    return 0;
}

/*
 * What it does:
 * - Reads the top-of-stack value without modifying stack pointer.
 * Arguments:
 * - stack: Pointer to uint16_t stack storage.
 * - sp: Current stack pointer value.
 * - out: Destination for top value.
 * Output structure:
 * - Returns 0 on success or RC_STACK_UNDERFLOW if stack is empty.
 * Parent/call mechanism:
 * - Internal helper used by step_once(), handle_cast(), and handle_poll().
 */
static inline int peek0(const uint16_t *stack, int sp, uint16_t *out) {
    if (sp <= 0) {
        return RC_STACK_UNDERFLOW;
    }
    *out = stack[sp - 1];
    return 0;
}

/*
 * What it does:
 * - Reads the second-from-top stack value without modifying stack pointer.
 * Arguments:
 * - stack: Pointer to uint16_t stack storage.
 * - sp: Current stack pointer value.
 * - out: Destination for second-from-top value.
 * Output structure:
 * - Returns 0 on success or RC_STACK_UNDERFLOW if depth < 2.
 * Parent/call mechanism:
 * - Internal helper used by step_once() and handle_cast().
 */
static inline int peek1(const uint16_t *stack, int sp, uint16_t *out) {
    if (sp <= 1) {
        return RC_STACK_UNDERFLOW;
    }
    *out = stack[sp - 2];
    return 0;
}

/*
 * What it does:
 * - Replaces the current top-of-stack value when stack is non-empty.
 * Arguments:
 * - stack: Pointer to uint16_t stack storage.
 * - sp: Current stack pointer value.
 * - val: New value for stack[sp-1].
 * Output structure:
 * - No return value; may mutate top stack entry.
 * Parent/call mechanism:
 * - Internal helper used by step_once() ALU and transform op handlers.
 */
static inline void set_top(uint16_t *stack, int sp, uint16_t val) {
    if (sp > 0) {
        stack[sp - 1] = val;
    }
}

/*
 * What it does:
 * - Updates Zero and Negative flags from a 16-bit result value.
 * Arguments:
 * - flags: In/out flag register pointer.
 * - result: Operation result to evaluate for Z/N.
 * Output structure:
 * - No return value; mutates FL_Z and FL_N bits in *flags.
 * Parent/call mechanism:
 * - Internal helper used by step_once() arithmetic/logical op handlers.
 */
static inline void set_zn(int *flags, uint16_t result) {
    *flags &= ~(FL_Z | FL_N);
    if (result == 0) {
        *flags |= FL_Z;
    }
    if ((result & 0x8000u) != 0u) {
        *flags |= FL_N;
    }
}

/*
 * What it does:
 * - Computes Carry/Overflow for 16-bit addition semantics.
 * Arguments:
 * - flags: In/out flag register pointer.
 * - a: Left addend.
 * - b: Right addend.
 * - r: Truncated 16-bit sum.
 * Output structure:
 * - No return value; mutates FL_C and FL_O bits in *flags.
 * Parent/call mechanism:
 * - Internal helper used by ADD-family handlers in step_once().
 */
static inline void set_cf_of_add(int *flags, uint16_t a, uint16_t b, uint16_t r) {
    int cf = (((uint32_t)a + (uint32_t)b) > 0xFFFFu) ? FL_C : 0;
    int sa = (a & 0x8000u) != 0u;
    int sb = (b & 0x8000u) != 0u;
    int sr = (r & 0x8000u) != 0u;
    int of = ((sa == sb) && (sr != sa)) ? FL_O : 0;
    *flags = (*flags & ~(FL_C | FL_O)) | cf | of;
}

/*
 * What it does:
 * - Computes Borrow/Overflow for 16-bit subtraction semantics.
 * Arguments:
 * - flags: In/out flag register pointer.
 * - a: Minuend.
 * - b: Subtrahend.
 * - r: Truncated 16-bit difference.
 * Output structure:
 * - No return value; mutates FL_C and FL_O bits in *flags.
 * Parent/call mechanism:
 * - Internal helper used by SUB/CMP-family handlers in step_once().
 */
static inline void set_cf_of_sub(int *flags, uint16_t a, uint16_t b, uint16_t r) {
    int cf = (a < b) ? FL_C : 0;
    int sa = (a & 0x8000u) != 0u;
    int sb = (b & 0x8000u) != 0u;
    int sr = (r & 0x8000u) != 0u;
    int of = ((sa != sb) && (sr != sa)) ? FL_O : 0;
    *flags = (*flags & ~(FL_C | FL_O)) | cf | of;
}

/*
 * What it does:
 * - Attempts one non-blocking read from stdin for keyboard polling.
 * Arguments:
 * - None.
 * Output structure:
 * - Returns [0..255] byte value on success, or -1 when no byte is available.
 * Parent/call mechanism:
 * - Internal helper called by handle_poll() for char input operations.
 */
static int read_one_char_nowait(void) {
    unsigned char ch;
    ssize_t n = read(STDIN_FILENO, &ch, 1);
    if (n == 1) {
        return (int)ch;
    }
    return -1;
}

/*
 * What it does:
 * - Clears terminal ECHO mode bit on stdin terminal.
 * Arguments:
 * - None.
 * Output structure:
 * - No return value; updates TTY attributes if tcgetattr succeeds.
 * Parent/call mechanism:
 * - Internal helper invoked by handle_poll() for PollSetNoEcho.
 */
static void disable_echo(void) {
    struct termios tty;
    if (tcgetattr(STDIN_FILENO, &tty) == 0) {
        tty.c_lflag &= (tcflag_t)~ECHO;
        tcsetattr(STDIN_FILENO, TCSANOW, &tty);
    }
}

/*
 * What it does:
 * - Sets terminal ECHO mode bit on stdin terminal.
 * Arguments:
 * - None.
 * Output structure:
 * - No return value; updates TTY attributes if tcgetattr succeeds.
 * Parent/call mechanism:
 * - Internal helper invoked by handle_poll() for PollSetEcho.
 */
static void enable_echo(void) {
    struct termios tty;
    if (tcgetattr(STDIN_FILENO, &tty) == 0) {
        tty.c_lflag |= ECHO;
        tcsetattr(STDIN_FILENO, TCSANOW, &tty);
    }
}

/*
 * What it does:
 * - Puts stdin terminal into raw mode and saves original attrs once.
 * Arguments:
 * - None.
 * Output structure:
 * - No return value; updates global g_saved_attrs/g_saved_valid and TTY mode.
 * Parent/call mechanism:
 * - Internal helper invoked by handle_poll() for PollSetRawCode.
 */
static void enable_raw(void) {
    if (!g_saved_valid) {
        if (tcgetattr(STDIN_FILENO, &g_saved_attrs) == 0) {
            g_saved_valid = 1;
        }
    }
    struct termios raw;
    if (tcgetattr(STDIN_FILENO, &raw) == 0) {
        cfmakeraw(&raw);
        raw.c_cc[VMIN] = 0;
        raw.c_cc[VTIME] = 1;
        tcsetattr(STDIN_FILENO, TCSANOW, &raw);
    }
}

/*
 * What it does:
 * - Restores stdin terminal attrs previously saved by enable_raw().
 * Arguments:
 * - None.
 * Output structure:
 * - No return value; restores TTY state and clears g_saved_valid.
 * Parent/call mechanism:
 * - Internal helper invoked by handle_poll() for PollReSetRaw.
 */
static void disable_raw(void) {
    if (g_saved_valid) {
        tcsetattr(STDIN_FILENO, TCSADRAIN, &g_saved_attrs);
        g_saved_valid = 0;
    }
}

/*
 * What it does:
 * - Prints terminal flag register values to stderr for diagnostics.
 * Arguments:
 * - None.
 * Output structure:
 * - No return value; emits formatted TTY state text to stderr.
 * Parent/call mechanism:
 * - Internal helper invoked by handle_poll() for PollTTYStateCode.
 */
static void tty_state(void) {
    struct termios attrs;
    if (tcgetattr(STDIN_FILENO, &attrs) == 0) {
        fprintf(stderr, "iflag=0x%08x oflag=0x%08x cflag=0x%08x lflag=0x%08x\n",
                (unsigned)attrs.c_iflag, (unsigned)attrs.c_oflag,
                (unsigned)attrs.c_cflag, (unsigned)attrs.c_lflag);
    }
}

/*
 * What it does:
 * - Executes CAST device/service commands using current stack-top command ID.
 * Arguments:
 * - mem: VM memory array.
 * - stack: VM hardware stack array.
 * - sp: In/out stack pointer.
 * - flags: VM flags pointer (currently not modified by CAST body).
 * - arg: Decoded operand for CAST instruction.
 * - pc: Current opcode address used for diagnostic output.
 * Output structure:
 * - Returns 0 on success or one RC_* code for stop/error/toggle conditions.
 * Parent/call mechanism:
 * - Internal dispatcher called by step_once() when opcode is OptValCAST.
 */
static int handle_cast(uint8_t *mem, uint16_t *stack, int *sp, int *flags, uint16_t arg, uint16_t pc) {
    (void)flags;
    uint16_t cmd;
    if (peek0(stack, *sp, &cmd) != 0) {
        return RC_STACK_UNDERFLOW;
    }

    uint16_t argi = get16(mem, arg);
    uint16_t argii = get16(mem, argi);

    if (pop16(stack, sp, &cmd) != 0) {
        return RC_STACK_UNDERFLOW;
    }

    switch (cmd) {
        case CastPrintStr: {
            uint16_t i = arg;
            while (i < 0xFFFF && mem[i] != 0) {
                unsigned char c = mem[i++];
                if ((c < 32) && c != 7 && c != 8 && c !=9  && c != 10 && c!=13 && c != 27 && c != 30) {
                    printf("%02x", c);
                } else {
                    putchar((int)c);
                }
            }
            break;
        }
        case CastPrintErrMsg: {
            uint16_t i = arg;
            while (i < 0xFFFF && mem[i] != 0) {
                unsigned char c = mem[i++];
                if ((c < 32 || c > 127) && c != 7 && c != 9 && c != 10 && c != 27 && c != 30) {
                    fprintf(stderr, "%02x", c);
                } else {
                    fputc((int)c, stderr);
                }
            }
            break;
        }
        case CastPrintInt:
            printf("%u", (unsigned)(arg & 0xFFFFu));
            break;
        case CastPrintIntI:
            printf("%u", (unsigned)(argi & 0xFFFFu));
            break;
        case CastPrintSignI:
            printf("%d", (int16_t)argi);
            break;
        case CastPrintBinI: {
            uint16_t v = argi;
            for (int bit = 15; bit >= 0; --bit) {
                putchar((v & (1u << bit)) ? '1' : '0');
            }
            break;
        }
        case CastPrintChar: {
            unsigned char c = mem[arg & 0xFFFFu];
            putchar((int)c);
            break;
        }
        case CastPrintStrI: {
            uint16_t i = argi;
            while (i < 0xFFFF && mem[i] != 0) {
                unsigned char c = mem[i++];
                if ((c < 32) && c != 7 && c != 8 && c !=9  && c != 10 && c!=13 && c != 27 && c != 30) {                
                    printf("%02x", c);
                } else {
                    putchar((int)c);
                }
            }
            break;
        }
        case CastPrintIntUI:
            printf("%u", (unsigned)(argi & 0xFFFFu));
            break;
        case CastPrintCharI:
            putchar((int)(argi & 0xFFu));
            break;
        case CastPrintHexI:
            printf("%04x", (unsigned)(argi & 0xFFFFu));
            break;
        case CastPrintHexII:
            printf("%04x", (unsigned)(argii & 0xFFFFu));
            break;
        case CastSelectDisk: {
            if (g_disk != NULL) {
                fclose(g_disk);
                g_disk = NULL;
            }
            char name[32];
            snprintf(name, sizeof(name), "DISK%02u.disk", (unsigned)arg);
            g_disk = fopen(name, "r+b");
            if (!g_disk) {
                return RC_DEVICE_READ_FAIL;
            }
            g_disk_ptr = 0;
            fseek(g_disk, 0, SEEK_SET);
            break;
        }
        case CastSeekDisk:
            if (!g_disk) {
                return RC_DISK_SEEK_FAIL;
            }
            g_disk_ptr = (int)arg * BLOCK_SIZE;
            if (fseek(g_disk, g_disk_ptr, SEEK_SET) != 0) {
                return RC_DISK_SEEK_FAIL;
            }
            break;
        case CastWriteSector:
        case CastWriteSectorI: {
            uint16_t src = (cmd == CastWriteSector) ? arg : argi;
            if (!g_disk) {
                return RC_DEVICE_GENERAL_FAIL;
            }
            if (src > (uint16_t)(0xFFFF - BLOCK_SIZE)) {
                return RC_DEVICE_MEM_FAIL;
            }
            if (fseek(g_disk, g_disk_ptr, SEEK_SET) != 0) {
                return RC_DISK_SEEK_FAIL;
            }
            if (fwrite(&mem[src], 1, BLOCK_SIZE, g_disk) != BLOCK_SIZE) {
                return RC_DEVICE_WRITE_FAIL;
            }
            g_disk_ptr += BLOCK_SIZE;
            fflush(g_disk);
            break;
        }
        case CastSyncDisk:
            if (g_disk && fflush(g_disk) != 0) {
                return RC_DEVICE_WRITE_FAIL;
            }
            break;
        case CastSelectDiskI: {
            if (g_disk != NULL) {
                fclose(g_disk);
                g_disk = NULL;
            }
            char name[32];
            snprintf(name, sizeof(name), "DISK%02u.disk", (unsigned)argi);
            g_disk = fopen(name, "r+b");
            if (!g_disk) {
                return RC_DEVICE_READ_FAIL;
            }
            g_disk_ptr = 0;
            fseek(g_disk, 0, SEEK_SET);
            break;
        }
        case CastSeekDiskI:
            if (!g_disk) {
                return RC_DISK_SEEK_FAIL;
            }
            g_disk_ptr = (int)argi * BLOCK_SIZE;
            if (fseek(g_disk, g_disk_ptr, SEEK_SET) != 0) {
                return RC_DISK_SEEK_FAIL;
            }
            break;
        case CastPrint32I: {
            uint32_t v = (uint32_t)get16(mem, arg) | ((uint32_t)get16(mem, arg + 2) << 16);
            printf("%u", (unsigned)v);
            break;
        }
        case CastPrint32II: {
            uint32_t base = get16(mem, arg);
            uint32_t v = (uint32_t)get16(mem, (int)base) | ((uint32_t)get16(mem, (int)base + 2) << 16);
            printf("%u", (unsigned)v);
            break;
        }
        case CastPrint32S: {
            uint16_t lo, hi;
            if (peek0(stack, *sp, &hi) != 0 || peek1(stack, *sp, &lo) != 0) {
                return RC_STACK_UNDERFLOW;
            }
            uint32_t v = ((uint32_t)hi << 16) | (uint32_t)lo;
            if (pop16(stack, sp, &hi) != 0 || pop16(stack, sp, &lo) != 0) {
                return RC_STACK_UNDERFLOW;
            }
            printf("%u", (unsigned)v);
            break;
        }
        case CastPrint32SignI: {
            int32_t v = (int32_t)((uint32_t)get16(mem, arg) | ((uint32_t)get16(mem, arg + 2) << 16));
            printf("%d", v);
            break;
        }
        case CastPrint32SignS: {
            uint16_t lo, hi;
            if (peek0(stack, *sp, &hi) != 0 || peek1(stack, *sp, &lo) != 0) {
                return RC_STACK_UNDERFLOW;
            }
            uint32_t uv = ((uint32_t)hi << 16) | (uint32_t)lo;
            int32_t v = (int32_t)uv;
            if (pop16(stack, sp, &hi) != 0 || pop16(stack, sp, &lo) != 0) {
                return RC_STACK_UNDERFLOW;
            }
            printf("%d", v);
            break;
        }
        case CastTapeWrite:
        case CastTapeWriteI: {
            uint16_t src = (cmd == CastTapeWrite) ? arg : argi;
            if (!g_tape) {
                return RC_DEVICE_GENERAL_FAIL;
            }
            if (src > (uint16_t)(0xFFFF - BLOCK_SIZE)) {
                return RC_DEVICE_MEM_FAIL;
            }
            if (fwrite(&mem[src], 1, BLOCK_SIZE, g_tape) != BLOCK_SIZE) {
                return RC_DEVICE_WRITE_FAIL;
            }
            fflush(g_tape);
            break;
        }
        case CastEnd:
            return RC_END_PROGRAM;
        case CastDebugToggle:
            return RC_DEBUG_TOGGLE;
        case CastStackDump: {
            fprintf(stderr, " %04x:Stack:(%d)", (unsigned)pc, *sp);
            for (int i = 0; i < *sp; ++i) {
                fprintf(stderr, " %04x", (unsigned)stack[i]);
            }
            fputc('\n', stderr);
            break;
        }
        default:
            return RC_DEVICE_GENERAL_FAIL;
    }

    fflush(stdout);
    return 0;
}

/*
 * What it does:
 * - Executes POLL input/device commands using current stack-top command ID.
 * Arguments:
 * - mem: VM memory array.
 * - stack: VM hardware stack array.
 * - sp: In/out stack pointer.
 * - arg: Decoded operand for POLL instruction.
 * Output structure:
 * - Returns 0 on success or one RC_* code for invalid input/device errors.
 * Parent/call mechanism:
 * - Internal dispatcher called by step_once() when opcode is OptValPOLL.
 */
static int handle_poll(uint8_t *mem, uint16_t *stack, int *sp, uint16_t arg) {
    uint16_t cmd;
    if (peek0(stack, *sp, &cmd) != 0) {
        return RC_STACK_UNDERFLOW;
    }
    uint16_t argi = get16(mem, arg);

    if (pop16(stack, sp, &cmd) != 0) {
        return RC_STACK_UNDERFLOW;
    }

    switch (cmd) {
        case PollReadIntI: {
            int v;
            if (scanf("%d", &v) != 1) {
                return RC_INVALID_INPUT;
            }
            put16(mem, arg, (uint16_t)v);
            break;
        }
        case PollReadStrI: {
            char line[256];
            char *res = fgets(line, sizeof(line), stdin);
            uint16_t dst = arg;
            if (!res) {
                mem[dst] = 0;
                break;
            }
            size_t len = strlen(line);
            if (len > 0 && line[len - 1] == '\n') {
                line[--len] = '\0';
            }
            for (size_t i = 0; i < len; ++i) {
                unsigned char c = (unsigned char)line[i];
                if (c > 31) {
                    if (dst >= 0xFFFFu) {
                        return RC_DEVICE_MEM_FAIL;
                    }
                    mem[dst++] = c;
                }
            }
            mem[dst] = 0;
            break;
        }
        case PollReadCharI:
        case PollReadCINoWait: {
            int c = read_one_char_nowait();
            if (c < 0) {
                c = 0;
            }
            put16(mem, arg, (uint16_t)c);
            break;
        }
        case PollSetNoEcho:
            disable_echo();
            break;
        case PollSetEcho:
            enable_echo();
            break;
        case PollSetRawCode:
            enable_raw();
            break;
        case PollReSetRaw:
            disable_raw();
            break;
        case PollTTYStateCode:
            tty_state();
            break;
        case PollReadSector:
        case PollReadSectorI: {
            if (!g_disk) {
                break;
            }
            uint16_t dst = (cmd == PollReadSector) ? arg : argi;
            if (dst > (uint16_t)(0xFFFF - BLOCK_SIZE)) {
                return RC_DEVICE_MEM_FAIL;
            }
            if (fseek(g_disk, g_disk_ptr, SEEK_SET) != 0) {
                return RC_DISK_SEEK_FAIL;
            }
            if (fread(&mem[dst], 1, BLOCK_SIZE, g_disk) != BLOCK_SIZE) {
                return RC_DEVICE_READ_FAIL;
            }
            g_disk_ptr += BLOCK_SIZE;
            break;
        }
        case PollReadTape:
        case PollReadTapeI: {
            if (!g_tape) {
                break;
            }
            uint16_t dst = (cmd == PollReadTape) ? arg : argi;
            if (dst > (uint16_t)(0xFFFF - BLOCK_SIZE)) {
                return RC_DEVICE_MEM_FAIL;
            }
            if (fread(&mem[dst], 1, BLOCK_SIZE, g_tape) != BLOCK_SIZE) {
                return RC_DEVICE_READ_FAIL;
            }
            break;
        }
        case PollRewindTape:
            if (g_tape) {
                fseek(g_tape, 0, SEEK_SET);
            }
            break;
        case PollReadTime: {
            if (*sp < 0 || *sp > (MAXHWSTACK - 2)) {
                return RC_STACK_OVERFLOW;
            }
            time_t now = time(NULL);
            if (push16(stack, sp, (uint16_t)(now & 0xFFFF)) != 0) {
                return RC_STACK_OVERFLOW;
            }
            if (push16(stack, sp, (uint16_t)(((uint64_t)now >> 16) & 0xFFFF)) != 0) {
                return RC_STACK_OVERFLOW;
            }
            break;
        }
        default:
            return RC_DEVICE_GENERAL_FAIL;
    }

    return 0;
}

/*
 * Sparse instruction-size map:
 * - Entries listed here are 3-byte opcodes (opcode + 16-bit operand).
 * - Any opcode not listed defaults to size 1 in step_once().
 * This matches the current EX716 encoding where immediate/addressed forms are
 * 3 bytes and all other implemented ops are single-byte.
 */
static const uint8_t OP_SIZE[256] = {
    [OptValPUSH] = 3,
    [OptValPUSHI] = 3,
    [OptValPUSHII] = 3,
    [OptValPOPI] = 3,
    [OptValPOPII] = 3,
    [OptValCMP] = 3,
    [OptValCMPI] = 3,
    [OptValCMPII] = 3,
    [OptValADD] = 3,
    [OptValADDI] = 3,
    [OptValADDII] = 3,
    [OptValSUB] = 3,
    [OptValSUBI] = 3,
    [OptValSUBII] = 3,
    [OptValOR] = 3,
    [OptValORI] = 3,
    [OptValORII] = 3,
    [OptValAND] = 3,
    [OptValANDI] = 3,
    [OptValANDII] = 3,
    [OptValXOR] = 3,
    [OptValXORI] = 3,
    [OptValXORII] = 3,
    [OptValJMPZ] = 3,
    [OptValJMPN] = 3,
    [OptValJMPC] = 3,
    [OptValJMPO] = 3,
    [OptValJMP] = 3,
    [OptValJMPI] = 3,
    [OptValCAST] = 3,
    [OptValPOLL] = 3,
};

/*
 * What it does:
 * - Executes exactly one VM instruction and updates machine state in place.
 * Arguments:
 * - mem: VM memory array.
 * - stack: VM hardware stack array.
 * - pc: In/out program counter.
 * - flags: In/out flag register.
 * - sp: In/out stack pointer.
 * Output structure:
 * - Returns 0 on success or one RC_* code signaling halt/debug/error.
 * Parent/call mechanism:
 * - Internal core execution primitive called in loops by c_EvalOne().
 */
static int step_once(uint8_t *mem, uint16_t *stack, int *pc, int *flags, int *sp) {
    uint16_t cur_pc = (uint16_t)(*pc & 0xFFFF);
    uint8_t op = mem[cur_pc];
    uint8_t size = OP_SIZE[op] == 0 ? 1 : OP_SIZE[op];
    uint16_t arg = (size == 3) ? get16(mem, (int)cur_pc + 1) : 0;
    uint16_t argi = get16(mem, arg);
    uint16_t argii = get16(mem, argi);
    uint16_t a, b, r;

    *pc = (int)((cur_pc + size) & 0xFFFF);

    switch (op) {
        case OptValNOP:
            break;
        case OptValPUSH:
            if (push16(stack, sp, arg) != 0) return RC_STACK_OVERFLOW;
            break;
        case OptValDUP:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            if (push16(stack, sp, a) != 0) return RC_STACK_OVERFLOW;
            break;
        case OptValPUSHI:
            if (push16(stack, sp, argi) != 0) return RC_STACK_OVERFLOW;
            break;
        case OptValPUSHII:
            if (push16(stack, sp, argii) != 0) return RC_STACK_OVERFLOW;
            break;
        case OptValPUSHS:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            set_top(stack, *sp, get16(mem, a));
            break;
        case OptValPOPNULL:
            if (pop16(stack, sp, &a) != 0) return RC_STACK_UNDERFLOW;
            break;
        case OptValSWP:
            if (*sp < 2) return RC_STACK_UNDERFLOW;
            a = stack[*sp - 1];
            stack[*sp - 1] = stack[*sp - 2];
            stack[*sp - 2] = a;
            break;
        case OptValPOPI:
            if (pop16(stack, sp, &a) != 0) return RC_STACK_UNDERFLOW;
            put16(mem, arg, a);
            break;
        case OptValPOPII:
            if (pop16(stack, sp, &a) != 0) return RC_STACK_UNDERFLOW;
            put16(mem, argi, a);
            break;
        case OptValPOPS:
            if (*sp < 2) return RC_STACK_UNDERFLOW;
            a = stack[*sp - 1];
            b = stack[*sp - 2];
            put16(mem, a, b);
            *sp -= 2;
            break;
        case OptValCMP:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a - arg);
            set_zn(flags, r);
            set_cf_of_sub(flags, a, arg, r);
            break;
        case OptValCMPS:
            if (peek0(stack, *sp, &a) != 0 || peek1(stack, *sp, &b) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(b - a);
            set_zn(flags, r);
            set_cf_of_sub(flags, b, a, r);
            break;
        case OptValCMPI:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a - argi);
            set_zn(flags, r);
            set_cf_of_sub(flags, a, argi, r);
            break;
        case OptValCMPII:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a - argii);
            set_zn(flags, r);
            set_cf_of_sub(flags, a, argii, r);
            break;
        case OptValADD:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a + arg);
            set_zn(flags, r);
            set_cf_of_add(flags, a, arg, r);
            set_top(stack, *sp, r);
            break;
        case OptValADDS:
            if (peek0(stack, *sp, &a) != 0 || peek1(stack, *sp, &b) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a + b);
            set_zn(flags, r);
            set_cf_of_add(flags, a, b, r);
            *sp -= 1;
            set_top(stack, *sp, r);
            break;
        case OptValADDI:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a + argi);
            set_zn(flags, r);
            set_cf_of_add(flags, a, argi, r);
            set_top(stack, *sp, r);
            break;
        case OptValADDII:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a + argii);
            set_zn(flags, r);
            set_cf_of_add(flags, a, argii, r);
            set_top(stack, *sp, r);
            break;
        case OptValSUB:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a - arg);
            set_zn(flags, r);
            set_cf_of_sub(flags, a, arg, r);
            set_top(stack, *sp, r);
            break;
        case OptValSUBS:
            if (peek0(stack, *sp, &a) != 0 || peek1(stack, *sp, &b) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(b - a);
            set_zn(flags, r);
            set_cf_of_sub(flags, b, a, r);
            *sp -= 1;
            set_top(stack, *sp, r);
            break;
        case OptValSUBI:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a - argi);
            set_zn(flags, r);
            set_cf_of_sub(flags, a, argi, r);
            set_top(stack, *sp, r);
            break;
        case OptValSUBII:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a - argii);
            set_zn(flags, r);
            set_cf_of_sub(flags, a, argii, r);
            set_top(stack, *sp, r);
            break;
        case OptValOR:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a | arg);
            set_zn(flags, r);
            set_top(stack, *sp, r);
            break;
        case OptValORS:
            if (peek0(stack, *sp, &a) != 0 || peek1(stack, *sp, &b) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a | b);
            set_zn(flags, r);
            *sp -= 1;
            set_top(stack, *sp, r);
            break;
        case OptValORI:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a | argi);
            set_zn(flags, r);
            set_top(stack, *sp, r);
            break;
        case OptValORII:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a | argii);
            set_zn(flags, r);
            set_top(stack, *sp, r);
            break;
        case OptValAND:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a & arg);
            set_zn(flags, r);
            set_top(stack, *sp, r);
            break;
        case OptValANDS:
            if (peek0(stack, *sp, &a) != 0 || peek1(stack, *sp, &b) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a & b);
            set_zn(flags, r);
            *sp -= 1;
            set_top(stack, *sp, r);
            break;
        case OptValANDI:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a & argi);
            set_zn(flags, r);
            set_top(stack, *sp, r);
            break;
        case OptValANDII:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a & argii);
            set_zn(flags, r);
            set_top(stack, *sp, r);
            break;
        case OptValXOR:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a ^ arg);
            set_zn(flags, r);
            set_top(stack, *sp, r);
            break;
        case OptValXORS:
            if (peek0(stack, *sp, &a) != 0 || peek1(stack, *sp, &b) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a ^ b);
            set_zn(flags, r);
            *sp -= 1;
            set_top(stack, *sp, r);
            break;
        case OptValXORI:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a ^ argi);
            set_zn(flags, r);
            set_top(stack, *sp, r);
            break;
        case OptValXORII:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(a ^ argii);
            set_zn(flags, r);
            set_top(stack, *sp, r);
            break;
        case OptValJMPZ:
            if ((*flags & FL_Z) != 0) *pc = arg;
            break;
        case OptValJMPN:
            if ((*flags & FL_N) != 0) *pc = arg;
            break;
        case OptValJMPC:
            if ((*flags & FL_C) != 0) *pc = arg;
            break;
        case OptValJMPO:
            if ((*flags & FL_O) != 0) *pc = arg;
            break;
        case OptValJMP:
            *pc = arg;
            break;
        case OptValJMPI:
            *pc = argi;
            break;
        case OptValJMPS:
            if (pop16(stack, sp, &a) != 0) return RC_STACK_UNDERFLOW;
            *pc = a;
            break;
        case OptValCAST: {
            int rc = handle_cast(mem, stack, sp, flags, arg, cur_pc);
            if (rc != 0) return rc;
            break;
        }
        case OptValPOLL: {
            int rc = handle_poll(mem, stack, sp, arg);
            if (rc != 0) return rc;
            break;
        }
        case OptValRRTC:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(((a >> 1) & 0x7FFFu) | ((*flags & FL_C) ? 0x8000u : 0u));
            *flags = (*flags & ~FL_C) | ((a & 0x1u) ? FL_C : 0);
            set_top(stack, *sp, r);
            break;
        case OptValRLTC:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(((a << 1) & 0xFFFEu) | ((*flags & FL_C) ? 1u : 0u));
            *flags = (*flags & ~FL_C) | ((a & 0x8000u) ? FL_C : 0);
            set_top(stack, *sp, r);
            break;
        case OptValSHR:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            *flags = (*flags & ~FL_C) | ((a & 0x1u) ? FL_C : 0);
            set_top(stack, *sp, (uint16_t)(a >> 1));
            break;
        case OptValSHL:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            *flags = (*flags & ~FL_C) | ((a & 0x8000u) ? FL_C : 0);
            set_top(stack, *sp, (uint16_t)(a << 1));
            break;
        case OptValINV:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)(~a);
            set_zn(flags, r);
            *flags &= (FL_Z | FL_N);
            set_top(stack, *sp, r);
            break;
        case OptValCOMP2:
            if (peek0(stack, *sp, &a) != 0) return RC_STACK_UNDERFLOW;
            r = (uint16_t)((~a) + 1u);
            set_zn(flags, r);
            *flags &= (FL_Z | FL_N);
            set_top(stack, *sp, r);
            break;
        case OptValFCLR:
            *flags = 0;
            break;
        case OptValFSAV:
            if (push16(stack, sp, (uint16_t)(*flags & 0xFFFF)) != 0) return RC_STACK_OVERFLOW;
            break;
        case OptValFLOD:
            if (pop16(stack, sp, &a) != 0) return RC_STACK_UNDERFLOW;
            *flags = (int)(a & 0xFFFFu);
            break;
        case OptValADM:
            break;
        case OptValSCLR:
            *sp = 0;
            break;
        case OptValSRPT:
            if (push16(stack, sp, (uint16_t)(*sp & 0xFFFF)) != 0) return RC_STACK_OVERFLOW;
            break;
        default:
            fprintf(stderr, "Unknown OptCode %u at address %04x\n", (unsigned)op, (unsigned)cur_pc);
            return RC_DEVICE_GENERAL_FAIL;
    }

    return 0;
}

/*
 * What it does:
 * - Python extension entry point that executes one-or-more VM steps in C.
 * Arguments:
 * - self: Python module object (unused).
 * - args: Python tuple (mem, stack, pc, flags, sp, steps, in_rc).
 * Output structure:
 * - Returns Python tuple (pc, flags, sp, rc), or NULL on Python exception.
 * Parent/call mechanism:
 * - External call target for cpuCfunc.EvalOne from cpu.py fast-mode paths.
 */

static PyObject *c_EvalOne(PyObject *self, PyObject *args)
{
    (void)self;

    PyObject *mem_obj;
    PyObject *stack_obj;
    int pc;
    int flags;
    int sp;
    int steps;
    int in_rc;

    if (!PyArg_ParseTuple(
            args,
            "OOiiiii",
            &mem_obj,
            &stack_obj,
            &pc,
            &flags,
            &sp,
            &steps,
            &in_rc)) {
        return NULL;
    }

    PyArrayObject *mem_arr =
        (PyArrayObject *)PyArray_FROM_OTF(
            mem_obj,
            NPY_UINT8,
            NPY_ARRAY_INOUT_ARRAY2
        );

    PyArrayObject *stack_arr =
        (PyArrayObject *)PyArray_FROM_OTF(
            stack_obj,
            NPY_UINT16,
            NPY_ARRAY_INOUT_ARRAY2
        );

    if (mem_arr == NULL || stack_arr == NULL) {
        Py_XDECREF(mem_arr);
        Py_XDECREF(stack_arr);
        return NULL;
    }

    if (PyArray_SIZE(mem_arr) < MAXMEM) {
        PyErr_SetString(PyExc_ValueError, "mem array must contain at least 65536 uint8 entries");
        PyArray_DiscardWritebackIfCopy(mem_arr);
        PyArray_DiscardWritebackIfCopy(stack_arr);
        Py_DECREF(mem_arr);
        Py_DECREF(stack_arr);
        return NULL;
    }

    if (PyArray_SIZE(stack_arr) < MAXHWSTACK) {
        PyErr_SetString(PyExc_ValueError, "stack array is too small for EX716 hardware stack");
        PyArray_DiscardWritebackIfCopy(mem_arr);
        PyArray_DiscardWritebackIfCopy(stack_arr);
        Py_DECREF(mem_arr);
        Py_DECREF(stack_arr);
        return NULL;
    }

    uint8_t *mem = (uint8_t *)PyArray_DATA(mem_arr);
    uint16_t *stack = (uint16_t *)PyArray_DATA(stack_arr);

    PyOS_sighandler_t old_sigint = PyOS_setsig(SIGINT, handle_ctrl_c);

    int return_code = in_rc;
    g_interrupt_requested = 0;

    if (steps == -1) {
        while (return_code == 0 && !g_interrupt_requested) {
            return_code = step_once(mem, stack, &pc, &flags, &sp);
        }
    } else if (steps > 0) {
        for (int i = 0;
             i < steps &&
             return_code == 0 &&
             !g_interrupt_requested;
             ++i) {
            return_code = step_once(mem, stack, &pc, &flags, &sp);
        }
    }

    if (g_interrupt_requested && return_code == 0) {
        return_code = RC_USER_HALT;
    }

    PyOS_setsig(SIGINT, old_sigint);

    PyArray_ResolveWritebackIfCopy(mem_arr);
    PyArray_ResolveWritebackIfCopy(stack_arr);
    Py_DECREF(mem_arr);
    Py_DECREF(stack_arr);

    return Py_BuildValue("iiii", pc, flags, sp, return_code);
}

static PyMethodDef cpuCfuncMethods[] = {
    {"EvalOne", c_EvalOne, METH_VARARGS, "Evaluate one or more EX716 instructions"},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef cpuCfunc = {
    PyModuleDef_HEAD_INIT,
    "cpuCfunc",
    NULL,
    -1,
    cpuCfuncMethods,
    NULL,
    NULL,
    NULL,
    NULL
};

/*
 * What it does:
 * - Initializes the cpuCfunc extension module and NumPy C API bindings.
 * Arguments:
 * - None (standard CPython module-init signature).
 * Output structure:
 * - Returns a new Python module object, or NULL if initialization fails.
 * Parent/call mechanism:
 * - External CPython import hook called when importing cpuCfunc.
 */
PyMODINIT_FUNC PyInit_cpuCfunc(void) {
    import_array();
    setvbuf(stdin, NULL, _IONBF, 0);
    return PyModule_Create(&cpuCfunc);
}
