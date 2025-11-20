#include <Python.h>
#include <numpy/arrayobject.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <stdint.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>

#include "speedCPU.h"
#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION

#define HWSPIDX 0xff
#define CastSelectDisk 20
#define MAXMEMP 0xfffe
#define BLOCK_SIZE 512
#define MAXHWSTACK 0x100

/* Error and return codes sent about hardware or monitor important events */

// Control codes
#define RC_END_PROGRAM     -1
#define RC_USER_HALT       -4
#define RC_DEBUG_TOGGLE    -11
// Stack Related
#define RC_STACK_UNDERFLOW -2
#define RC_STACK_OVERFLOW -3
// input related
#define RC_INVALID_INPUT -5
//  DISK/Tape IO
#define RC_DISK_SEEK_FAIL -6
#define RC_DEVICE_READ_FAIL -7
#define RC_DEVICE_MEM_FAIL -8
#define RC_DEVICE_WRITE_FAIL -9
#define RC_DEVICE_GENERAL_FAIL -10



int returncode;
void handle_ctrl_c(int sig) {
  printf("\nCaught SIGINT %d (Ctrl-C). Exiting...\n",sig);
  returncode=RC_USER_HALT;
}



//
// Compile with
// gcc -fPIC -shared -o cpuCfunc.so speedCPU.c -I /usr/include/python3.10/ -I/home/backs1/.local/lib/python3.10/site-packages/numpy/core/include -DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION -lpython3.10


#ifdef _WIN32
#include <conio.h>
#include <windows.h>

void enable_nonblocking_input() {
  HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  GetConsoleMode(hStdin, &mode);
  SetConsoleMode(hStdin, mode & (~ENABLE_LINE_INPUT));
}

int kbhit() {
  return _kbhit();
}

int getch() {
  return _getch();
}

#else
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/select.h>

void enable_nonblocking_input() {
  struct termios ttystate;
  tcgetattr(STDIN_FILENO, &ttystate);
  ttystate.c_lflag &= ~(ICANON | ECHO);
  tcsetattr(STDIN_FILENO, TCSANOW, &ttystate);
}

int kbhit() {
  struct timeval tv;
  fd_set fds;
  tv.tv_sec = 0;
  tv.tv_usec = 0;
  FD_ZERO(&fds);
  FD_SET(STDIN_FILENO, &fds);
  select(STDIN_FILENO + 1, &fds, NULL, NULL, &tv);
  return FD_ISSET(STDIN_FILENO, &fds);
}

int getch() {
  int ch;
  ch = getchar();
  return ch;
}
#endif
void disable_echo() {
#ifdef _WIN32
  HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  GetConsoleMode(hStdin, &mode);
  SetConsoleMode(hStdin, mode & (~ENABLE_ECHO_INPUT));
#else
  struct termios tty;
  tcgetattr(STDIN_FILENO, &tty);
  tty.c_lflag &= ~ECHO;
  tcsetattr(STDIN_FILENO, TCSANOW, &tty);
#endif
}

void enable_echo() {
#ifdef _WIN32
  HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
  DWORD mode;
  GetConsoleMode(hStdin, &mode);
  SetConsoleMode(hStdin, mode | ENABLE_ECHO_INPUT);
#else
  struct termios tty;
  tcgetattr(STDIN_FILENO, &tty);
  tty.c_lflag |= ECHO;
  tcsetattr(STDIN_FILENO, TCSANOW, &tty);
#endif
}


static struct termios saved_attrs;
static int saved_valid = 0;

void enable_raw() {
#ifdef _WIN32
    // Windows doesn’t really have a direct "raw mode", but you can disable
    // line buffering and echo. This is a placeholder.
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    DWORD mode;
    GetConsoleMode(hStdin, &mode);
    // Disable line input, echo, and processed input
    SetConsoleMode(hStdin, mode & ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT));
#else
    if (!saved_valid) {
        tcgetattr(STDIN_FILENO, &saved_attrs);
        saved_valid = 1;
    }
    struct termios raw;
    tcgetattr(STDIN_FILENO, &raw);
    cfmakeraw(&raw);
    raw.c_cc[VMIN]  = 0;
    raw.c_cc[VTIME] = 1;   // 0.1s timeout
    tcsetattr(STDIN_FILENO, TCSANOW, &raw);
#endif
}

void disable_raw() {
#ifdef _WIN32
    // Restore normal input processing
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    DWORD mode;
    GetConsoleMode(hStdin, &mode);
    SetConsoleMode(hStdin, mode | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT);
#else
    if (saved_valid) {
        tcsetattr(STDIN_FILENO, TCSADRAIN, &saved_attrs);
        saved_valid = 0;
    }
#endif
}

void tty_state() {
#ifdef _WIN32
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    DWORD mode;
    GetConsoleMode(hStdin, &mode);
    fprintf(stderr, "TTY state: mode=0x%08lx\n", (unsigned long)mode);
#else
    struct termios attrs;
    tcgetattr(STDIN_FILENO, &attrs);
    fprintf(stderr, "iflag=0x%08x oflag=0x%08x cflag=0x%08x lflag=0x%08x\n",
            attrs.c_iflag, attrs.c_oflag, attrs.c_cflag, attrs.c_lflag);
    fprintf(stderr, "ECHO=%d ICANON=%d ISIG=%d IEXTEN=%d VMIN=%d VTIME=%d\n",
            (attrs.c_lflag & ECHO) != 0,
            (attrs.c_lflag & ICANON) != 0,
            (attrs.c_lflag & ISIG) != 0,
            (attrs.c_lflag & IEXTEN) != 0,
            attrs.c_cc[VMIN], attrs.c_cc[VTIME]);
#endif
}


// Raw, non-blocking, returns -1 if no input
static inline int read_one_char_nowait() {
    unsigned char ch;
    int n = read(STDIN_FILENO, &ch, 1);
    return (n == 1) ? ch : -1;
}


void EvalOne(uint8_t *CPUMemData,uint8_t *CPUStackData,int *CPURegData, int *CPUFlags);
int get16memat(int InLocation, uint8_t *CPUMemory);
void put16atmem(int locateaddr,int val, uint8_t *CPUMemory);
int popstack(uint8_t  *CPUStackData);
int popnull(uint8_t *CPUStackData);
int topstack(uint8_t *CPUStackData, int nofail);
int sftstack(uint8_t *CPUStackData);
void pushstack(int invalue, uint8_t *CPUStackData);
void ReadFlags(int *CurrentFlags);
void WriteFlags(int *CurrentFlags);
void SetFlags(int result );
void OverCarryTest(int a, int b, int c, int IsSubtraction);
int handleCast(int Param, int ParamI, int ParamII, uint8_t *CPUMemData, uint8_t *CPUStackData, int CPC);
int handlePoll(int Param, int ParamI, int ParamII, uint8_t *CPUMemData, uint8_t *CPUStackData);
uint16_t ZF,NF,CF,OF, PC, AdminFlag; /* Global values */
char DiskName[17] = {'\0'}; /* Allocat 16 bytes for temporary filenames and null the first character */
FILE* DiskHandle = NULL;
FILE* TapeHandle = NULL;
int DiskPtr = 0;

#define POPNULLCHK(stack) do { \
int __err = popnull(stack); \
if (__err < 0) return __err; \
} while (0)
    




void EvalSteps(PyObject* CPUMemory, PyObject* CPUHWStack, int*  CPUPC, int* CPUFlags, int* index1, int* returnval) {
  int opcount;
  
  PyArrayObject* np_array1 = (PyArrayObject*)PyArray_FROM_O(CPUMemory);
  PyArrayObject* np_array2 = (PyArrayObject*)PyArray_FROM_O(CPUHWStack);
  
  if (np_array1 == NULL || np_array2 == NULL  ) {
    PyErr_SetString(PyExc_TypeError, "Invalid input arrays");
    return;
  }
  // Perform the modification (add corresponding elements)

    
  uint8_t* CPUMemData = (uint8_t*)PyArray_DATA(np_array1);
  uint8_t* CPUStackData = (uint8_t*)PyArray_DATA(np_array2);
  //  uint8_t* CPURegData = (uint8_t*)PyArray_DATA(np_array3);
  signal(SIGINT, handle_ctrl_c);
  returncode=0;
  if (*index1 == -1) {
    opcount = 0;
    while (returncode == 0) {
      opcount++;
      // Loop until normal exit
      EvalOne(CPUMemData, CPUStackData, CPUPC, CPUFlags);
    }
    printf("\nOpt Count: %d\n", opcount);
  } else {
    // Loop controlled by index1 value
    for (int ii = 0; (ii < *index1) && returncode == 0; ii++) {
      opcount++;
      EvalOne(CPUMemData, CPUStackData, CPUPC, CPUFlags);
    }
    // Reset index1 to 0 so caller knows loop is complete
    *index1 = 0;
  }
  Py_XDECREF(np_array1);
  Py_XDECREF(np_array2);
  *returnval = returncode;
}


  
//
// Define the required support functions.

static PyObject* c_EvalOne(PyObject* self __attribute__((unused)), PyObject* args) {
  PyObject* array1;
  PyObject* array2;
  int index1,CPUFlags,CPUPC, extra;

  if (!PyArg_ParseTuple(args, "OOiiii", &array1, &array2, &CPUPC,  &CPUFlags, &index1, &extra )) {
    return NULL;
  }

  EvalSteps(array1, array2, &CPUPC, &CPUFlags, &index1, &extra);

  // Return None (no need to return any value in this case)
  //    Py_RETURN_NONE;
  return Py_BuildValue("iii", CPUPC, CPUFlags, extra);
}

static PyMethodDef cpuCfuncMethods[] = {
  {"EvalOne", c_EvalOne, METH_VARARGS, "Evaluate on ESX716 Instruciton"},
  {NULL, NULL, 0, NULL}
};

static struct PyModuleDef cpuCfunc = {
  PyModuleDef_HEAD_INIT,
  "cpuCfunc",
  NULL,
  -1,
  cpuCfuncMethods,
  NULL,  /* m_slots */
  NULL,  /* m_traverse */
  NULL,  /* m_clear */
  NULL   /* m_free */
};

PyMODINIT_FUNC PyInit_cpuCfunc(void) {
  import_array();  // Initialize NumPy
  setvbuf(stdin, NULL, _IONBF,0);
  return PyModule_Create(&cpuCfunc);
}

void   EvalOne(uint8_t *CPUMemData,uint8_t *CPUStackData,int *CPUPC, int *CurrentFlags) {
  int Param, ParamI, ParamII,Opsize,OptCode,NCF,TF,TSP;
  int tos,sft,A1, A2, B1,  R1, OCF;

  PC=(*CPUPC) & 0xffff;
  Opsize=1;

  Param=get16memat(PC+1, CPUMemData);
  ParamI=get16memat(Param, CPUMemData);
  ParamII=get16memat(ParamI, CPUMemData);
  OptCode=CPUMemData[PC];

  TSP=CPUStackData[HWSPIDX];
  tos = -1;
  sft = -1;
  if ( TSP > 0 ) {
    tos=topstack(CPUStackData,1);
    sft=sftstack(CPUStackData);
  }
  tos = tos & 0xffff;
  sft = sft & 0xffff;
  ReadFlags(CurrentFlags);
  

  switch(OptCode) {
  case OptValNOP:
    Opsize=1;
    break;
  case OptValPUSH:
    pushstack(Param,CPUStackData);
    Opsize=3; 
    break;
  case OptValDUP:
    A1=tos;
    pushstack(A1,CPUStackData);
    Opsize=1;
    break;
  case OptValPUSHI:
    pushstack(ParamI,CPUStackData);
    Opsize=3; 
    break;
  case OptValPUSHII:
    pushstack(ParamII,CPUStackData);
    Opsize=3; 
    break;	 
  case OptValPUSHS:
    int a;    
    a=get16memat(popstack(CPUStackData),CPUMemData);
    pushstack(a,CPUStackData);
    Opsize=1;
    break;
  case OptValPOPNULL:
    A1=popstack(CPUStackData);
    Opsize=1;
    break;
  case OptValSWP:
    A1=popstack(CPUStackData);
    A2=popstack(CPUStackData);	 
    pushstack(A1,CPUStackData);
    pushstack(A2,CPUStackData);
    Opsize=1;
    break;
  case OptValPOPI:
    put16atmem(Param,popstack(CPUStackData), CPUMemData);
    Opsize=3;
    break;
  case OptValPOPII:
    put16atmem(ParamI,popstack(CPUStackData), CPUMemData);
    Opsize=3;
    break; 
  case OptValPOPS:
    A1=popstack(CPUStackData);
    B1=popstack(CPUStackData);
    put16atmem(A1,B1, CPUMemData);
    Opsize=1;
    break;
  case OptValCMP:
    B1=tos;
    A1=B1-Param;
    A1=A1 & 0xffff;
    SetFlags(A1);
    OverCarryTest(B1,Param,A1,1);
    Opsize=3;
    break;
  case OptValCMPI:
    B1=tos;
    A1=B1-ParamI;
    A1=A1 & 0xffff;
    SetFlags(A1);
    OverCarryTest(B1,ParamI,A1,1); 
    Opsize=3;
    break;
  case OptValCMPII:
    B1=tos;
    A1=B1-ParamII;
    A1=A1 & 0xffff;
    SetFlags(A1);
    OverCarryTest(B1,ParamII,A1,1);
    Opsize=3;
    break;

case OptValCMPS:
    A2 = sft;                          // left operand (second on stack)
    B1 = tos;                          // right operand (top of stack)
    A1 = (A2 - B1) & 0xffff;           // result
    SetFlags(A1);
    OverCarryTest(A2, B1, A1, 1);      // left - right
    Opsize=1;
    break;

  case OptValADD:
    B1=popstack(CPUStackData);
    A1=Param + B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    OverCarryTest(Param,B1,A1,0);
    Opsize=3;
    break;
  case OptValADDI:
    B1=popstack(CPUStackData);
    A1=ParamI + B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    OverCarryTest(ParamI,B1,A1,0);	 
    Opsize=3;
    break;
  case OptValADDII:
    B1=popstack(CPUStackData);
    A1=ParamII + B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    OverCarryTest(ParamII,B1,A1,0);
    Opsize=3;
    break;
  case OptValADDS:
    A2=popstack(CPUStackData);
    B1=popstack(CPUStackData);
    A1=A2 + B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    OverCarryTest(A2,B1,A1,0);
    Opsize=1;
    break;
	 
  case OptValSUB:
    B1=popstack(CPUStackData);
    A1=B1-Param;
    A1=A1 & 0xffff;
    SetFlags(A1);
    OverCarryTest(B1,Param,A1,1);
    pushstack(A1,CPUStackData);

    Opsize=3;
    break;
  case OptValSUBI:
    B1=popstack(CPUStackData);
    A1=B1-ParamI;
    A1=A1 & 0xffff;
    SetFlags(A1);
    OverCarryTest(B1,ParamI,A1,1);	 
    pushstack(A1,CPUStackData);

    Opsize=3;
    break;
  case OptValSUBII:
    B1=popstack(CPUStackData);
    A1=B1-ParamII;
    A1=A1 & 0xffff;
    SetFlags(A1);
    OverCarryTest(B1,ParamII,A1,1);	 
    pushstack(A1,CPUStackData);

    Opsize=3;
    break;
  case OptValSUBS:
    B1 = popstack(CPUStackData);       // right operan
    A2 = popstack(CPUStackData);       // left operand
    A1 = (A2 - B1) & 0xffff;           // result
    SetFlags(A1);
    OverCarryTest(A2, B1, A1, 1);      // left - right
    pushstack(A1,CPUStackData);
    Opsize=1;
    break;

  case OptValAND:
    B1=popstack(CPUStackData);
    A1=Param & B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValANDI:
    B1=popstack(CPUStackData);
    A1=ParamI & B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValANDII:
    B1=popstack(CPUStackData);
    A1=ParamII & B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValANDS:
    A2=popstack(CPUStackData);
    B1=popstack(CPUStackData);
    A1=A2 & B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=1;
    break;
  case OptValXOR:
    B1=popstack(CPUStackData);
    A1=Param ^ B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;	 
  case OptValXORI:
    B1=popstack(CPUStackData);
    A1=ParamI ^ B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValXORII:
    B1=popstack(CPUStackData);
    A1=ParamII ^ B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValXORS:
    A2=popstack(CPUStackData);
    B1=popstack(CPUStackData);
    A1=A2 ^ B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=1;
    break;
         
  case OptValOR:
    B1=popstack(CPUStackData);
    A1=Param | B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;	 
  case OptValORI:
    B1=popstack(CPUStackData);
    A1=ParamI | B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValORII:
    B1=popstack(CPUStackData);
    A1=ParamII | B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValORS:
    A2=popstack(CPUStackData);
    B1=popstack(CPUStackData);
    A1=A2 | B1;
    A1=A1 & 0xffff;
    SetFlags(A1);
    pushstack(A1,CPUStackData);
    Opsize=1;
    break;
	 
  case OptValJMPZ:	   
    if ( ZF ) { Opsize=0;PC=Param; }
    else {
      Opsize=3;
    }
    break;
  case OptValJMPN:
    if ( NF ) { Opsize=0;PC=Param; }
    else {
      Opsize=3;
    }
    break;
  case OptValJMPC:
    if ( CF ) { Opsize=0;PC=Param; }
    else {
      Opsize=3;
    }
    break;	 
  case OptValJMPO:
    if ( OF ) { Opsize=0;PC=Param; }
    else {
      Opsize=3;
    }
    break;
  case OptValJMP:
    Opsize=0;
    PC=Param;
    break;
  case OptValJMPI:
    Opsize=0;
    PC=ParamI;
    break;
  case OptValJMPS:
    Opsize=0;
    PC=popstack(CPUStackData);
    break;	 	   
  case OptValCAST:
    if (handleCast(Param,ParamI,ParamII, CPUMemData, CPUStackData,PC) != 0) {
      fprintf(stderr, "Device State Message sent by CAST"); }
    Opsize=3;
    break;
  case OptValPOLL:
    if (handlePoll(Param,ParamI,ParamII, CPUMemData, CPUStackData) != 0) {      
      fprintf(stderr, "Device State Message sent by POLL");      }
    Opsize=3;
    break;
  case OptValRRTC:
    B1=popstack(CPUStackData);
    NCF=0;
    if ( B1 & 1 ) {
      NCF = 1 << 2;
    }
    OCF=CF << 15;
    B1=B1 >> 1 | OCF;
    CF=NCF > 0 ? 1:0;
    pushstack(B1,CPUStackData);
    Opsize=1;
    break;
  case OptValRLTC:
    R1=popstack(CPUStackData);
    NCF=0;
    if ( R1 & 0x8000) { NCF=1;}
    OCF=CF;
    R1=(R1<<1) + OCF;
    CF=NCF > 0? 1:0;
    pushstack(R1,CPUStackData);
    Opsize=1;
    break;
  case OptValSHR: {
    uint16_t R1 = (uint16_t) popstack(CPUStackData);
    uint8_t B1 = (R1 & 0x1) ? 1 : 0;
    R1 = (R1 >> 1) & 0xFFFF;
    CF = B1;
    pushstack(R1, CPUStackData);
    Opsize = 1;
    break; }
  case OptValSHL: {
    uint16_t R1 = (uint16_t) popstack(CPUStackData);
    uint8_t B1 = (R1 & 0x8000) ? 1 : 0;
    R1 = (uint16_t)((R1 << 1) & 0xFFFF);
    CF = B1;
    pushstack(R1, CPUStackData);
    Opsize = 1;
    break; }
  case OptValINV:
    R1=~(popstack(CPUStackData));
    pushstack(R1,CPUStackData);
    SetFlags(R1);
    CF=0; OF=0;
    Opsize=1;
    break;
  case OptValCOMP2:
    R1=popstack(CPUStackData);
    R1= ((~R1 & 0xffff) + 1) & 0xffff;
    pushstack(R1,CPUStackData);
    SetFlags(R1);
    CF=0; OF=0;
    Opsize=1;
    break;
  case OptValFCLR:
    NF=0;CF=0;ZF=0;OF=0;
    Opsize=1;
    break;
  case OptValFSAV:
    TF=ZF+(NF<<1)+(CF<<2)+(OF<<3);
    pushstack(TF,CPUStackData);
    Opsize=1;
    break;
  case OptValFLOD:
    ZF=0; NF=0;CF=0;OF=0;
    R1=popstack(CPUStackData);
    if ( R1 & 0x1) { ZF=1; }
    if ( R1 & 0x2) { NF=1; }
    if ( R1 & 0x4) { CF=1; }
    if ( R1 & 0x8) { OF=1; }
    Opsize=1;
    break;
  case OptValADM:
    if (PC <= 0x4000) {
      AdminFlag = ~AdminFlag;
    }
    break;
  case OptValSCLR:
    CPUStackData[HWSPIDX]=0;
    break;
  case OptValSRPT:
    if (CPUStackData[HWSPIDX] < (MAXHWSTACK - 1)) {
      pushstack(CPUStackData[HWSPIDX],CPUStackData);
    } else if (CPUStackData[HWSPIDX] == (MAXHWSTACK - 1)) {
      pushstack(-1,CPUStackData);
    }
    break;
  default:
    printf("Unknown OptCode %d at address %04x\n",OptCode,PC);
    returncode=RC_DEVICE_GENERAL_FAIL;
    PC++;
    break;
  }

  WriteFlags(CurrentFlags);
  PC=PC+Opsize;    
  *CPUPC=PC;    
}
    
  
int get16memat(int InLocation, uint8_t *CPUMemData)
{
  InLocation = InLocation & 0xffff;
  return ((CPUMemData[InLocation] & 0xff) + ((CPUMemData[InLocation+1] & 0xff) << 8) ) & 0xffff;
}
void put16atmem(int locateaddr,int val,uint8_t  *CPUMemData) {
  locateaddr=locateaddr & 0xffff;
  CPUMemData[locateaddr]=val & 0xff;
  CPUMemData[locateaddr+1]=((val >> 8) & 0xff);
}

int popstack(uint8_t *CPUStackData) {
  int lsp;  
  lsp=CPUStackData[HWSPIDX];
  if ( lsp > 0 ) {
    CPUStackData[HWSPIDX] -= 1;
    lsp=CPUStackData[HWSPIDX];
    return CPUStackData[(lsp*2)]+(CPUStackData[(lsp*2)+1]<<8);
  } else {
    returncode=RC_STACK_UNDERFLOW;
    return -1;
  }
}

int popnull(uint8_t *CPUStackData) {
  int tval;
  tval=popstack(CPUStackData);
  if ( tval < 0 ) {
    return tval; }
  else {
    return 0; }
}
  
int topstack(uint8_t *CPUStackData,int nofail) {
  int lsp;  
  lsp=CPUStackData[HWSPIDX];
  if (lsp > 0 ) {
    lsp--;
    return CPUStackData[lsp*2]+(CPUStackData[(lsp*2)+1]<<8);
  }
  else {
    if (nofail == 1) {
      return -1; }
    else {
      returncode=RC_STACK_UNDERFLOW;
      return -1; 
    }
  }
}

int sftstack(uint8_t *CPUStackData) {
  int lsp;
  lsp=CPUStackData[HWSPIDX];
  if ( lsp > 1 ) {
    lsp=(lsp-2)*2;
    return CPUStackData[lsp]+(CPUStackData[lsp+1]<<8);
  }
  return -1;
}
    

void pushstack(int invalue, uint8_t *CPUStackData) {
  int lsp,a,b,csp;
  lsp=CPUStackData[HWSPIDX];
  if (lsp >= 0x7e) {
    printf("HW Stack OverFlow\n");
    returncode=RC_STACK_OVERFLOW; 
    return;
  }  
  csp=lsp*2;
  a=invalue & 0xff;
  b=(invalue & 0xff00) >> 8;
  CPUStackData[csp] = a;
  CPUStackData[csp+1] = b;
  CPUStackData[HWSPIDX] += 1;
}
 

void ReadFlags(int *CurrentFlags){
  ZF=0; NF=0; CF=0; OF=0;
  if (*CurrentFlags & 0x1) {
    ZF=1;
  }
  if (*CurrentFlags & 0x2) {
    NF=1;
  }
  if (*CurrentFlags & 0x4) {
    CF=1;
  }
  if (*CurrentFlags & 0x8) {
    OF=1;
  }
}
 

void WriteFlags(int *CurrentFlags) {
  *CurrentFlags=0;
  if (ZF) { *CurrentFlags = *CurrentFlags | 0x1; }
  if (NF) { *CurrentFlags = *CurrentFlags | 0x2; }
  if (CF) { *CurrentFlags = *CurrentFlags | 0x4; }
  if (OF) { *CurrentFlags = *CurrentFlags | 0x8; }
}


// Set Zero and Negative flags only
void SetFlags(int result) {
  // Zero
  ZF = (result & 0xFFFF) == 0;

  // Negative (sign bit of result)
  NF = (result & 0x8000) != 0;
}
// Set Carry and Overflow only
void OverCarryTest(int a, int b, int c, int IsSubtraction) {
    int a16 = a & 0xffff;
    int b16 = b & 0xffff;
    int c16 = c & 0xffff;

    int sa = (a16 & 0x8000) != 0;   // sign of a
    int sb = (b16 & 0x8000) != 0;   // sign of b
    int sc = (c16 & 0x8000) != 0;   // sign of c (result)

    // Default clear (so no stale state lingers)
    CF = 0;
    OF = 0;

    if (IsSubtraction) {
        // Borrow occurs if a < b (unsigned compare)
        CF = (a16 < b16) ? 1 : 0;

        // Overflow: if signs of a and b differ,
        // and result sign differs from a
        if ((sa != sb) && (sc != sa)) {
            OF = 1;
        }
    } else {
        // Carry: unsigned sum overflowed
        if ((unsigned)a16 + (unsigned)b16 > 0xFFFF) {
            CF = 1;
        }

        // Overflow: if signs of a and b same,
        // and result sign differs
        if ((sa == sb) && (sc != sa)) {
            OF = 1;
        }
    }
}

int handleCast(int Param, int ParamI, int ParamII,  uint8_t *memory, uint8_t *HWStack, int CPC) {
  uint16_t i,c,a, tos, sft;
  int i32;
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
#define CastSelectDisk 20
#define CastSeekDisk 21
#define CastSelectDiskI 24
#define CastSeekDiskI 25
#define CastWriteSector 22
#define CastSyncDisk 23
#define CastWriteSectorI 26
#define CastSyncDisk 23
#define CastPrint32I 32
#define CastPrint32S 33
#define CastTapeWrite 34
#define CastTapeWriteI 35
#define CastEnd 99
#define CastDebugToggle 100
#define CastStackDump 102

  
  // printf("Cast Codes Mode %04x: %04x - %04x - %04x\n",topstack(PC),Param,ParamI,ParamII);
  tos=topstack(HWStack,0);
  sft=sftstack(HWStack);

  switch (tos) {
  case CastDebugToggle:
    POPNULLCHK(HWStack);
    returncode=RC_DEBUG_TOGGLE;
    break;
  case CastPrintStr:           // CastPrintStr 1
    POPNULLCHK(HWStack);    
    i=Param;
    while (memory[i] != 0 && i < 0xffff) {
      c=memory[i]; i++;
      if ((c<32 || c> 127) && ( c !=0 && c != 7 && c != 9 && c != 27 && c != 30 && c!=10)) {
	printf("%02x",c);
      } else {
	printf("%c",(char) c);
      }
    }
    break;
  case CastPrintInt:           // CastPrintInt 2
    POPNULLCHK(HWStack);    
    a=Param & 0xffff;
    printf("%d",(short)a);
    break;
  case CastPrintIntI:          // CastPrintIntI
    POPNULLCHK(HWStack);    
    a=ParamI & 0xffff;
    printf("%d", (unsigned short)a);
    break;
  case CastPrintSignI:          // CastPrintSignI
    POPNULLCHK(HWStack);
    a=ParamI & 0xffff;
    printf("%d", (short)a);
    break;
  case CastPrintBinI:          // CastPrintBinI
    POPNULLCHK(HWStack);
    {
      unsigned int val = ParamI & 0xffff;
      printf("0b");
      for (int bit = 15; bit >= 0; bit--) {
        putchar((val & (1u << bit)) ? '1' : '0');
      }
    }
    break;    
  case CastPrintChar:          // CastPrintChar
    POPNULLCHK(HWStack);
    if ( ParamI < 32 || ParamI > 128 ) {
      printf("%02x", (unsigned short)ParamI);
    } else {
      printf("%c",ParamI);
    }
    break;
  case CastPrintStrI:         // CastPrintStrI
    POPNULLCHK(HWStack);
    i=ParamI;
    while (memory[i] != 0 && i < 0xffff) {
      c=memory[i];
      i++;
      if ((c< 32 || c > 127) && ( c !=0 && c != 7 && c != 27 && c != 30)) {
	printf("%02x",c);
      } else {
	printf("%c",c);
      }
    }
    break;
  case CastPrintIntUI:         // CastPrintIntUI
    POPNULLCHK(HWStack);
    a=ParamI & 0xffff;
    printf("%u",(unsigned short)a);
    break;
  case CastPrintCharI:         // CastPrintCharI
    POPNULLCHK(HWStack);
    if ( ParamII < 32 || ParamII > 128 ) {
      printf("%02x", ParamII);
    } else {
      printf("%c",ParamII);
    }
    break;    
  case CastPrintHexI:         // CastPrintHexI
    POPNULLCHK(HWStack);
    a=ParamI & 0xffff;
    printf("%04x",(unsigned short)a);
    break;
  case CastPrintHexII:        // CastPrintHexII
    POPNULLCHK(HWStack);
    a=ParamII & 0xffff;
    printf("%04x",a);
    break;
  case CastSelectDisk:   // CastSelectDisk
    POPNULLCHK(HWStack);
    if (DiskHandle != NULL ) {
      fclose(DiskHandle);
    } else {
      returncode = RC_DEVICE_GENERAL_FAIL;
    }
    snprintf(DiskName,sizeof(DiskName), "DISK%02d.disk", Param);
    DiskHandle = fopen(DiskName, "r+b");
    if (DiskHandle != NULL) {
      DiskPtr = 0;
      fseek(DiskHandle, 0, SEEK_SET);
    } else {
      returncode=RC_DEVICE_READ_FAIL;
      fprintf(stderr,"Error accessing DISK device: %d\n",Param);
    }
    break;
  case CastSeekDisk:   //CastSeekDisk
    POPNULLCHK(HWStack);
    if (DiskHandle == NULL) {
      returncode=RC_DISK_SEEK_FAIL;
      fprintf(stderr,"Error, Attempted to Seek before selecting Disk.\n");
    }
    DiskPtr = Param * BLOCK_SIZE;
    if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0){
      returncode=RC_DISK_SEEK_FAIL;
      fprintf(stderr,"Erorr seeking block %d on disk.\n",DiskPtr);
    }
    break;
    if ( Param < MAXMEMP - BLOCK_SIZE+1) {
      unsigned char block[BLOCK_SIZE];
      memcpy(block, &memory[Param], BLOCK_SIZE);
      if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0) {
	returncode=RC_DEVICE_READ_FAIL;
        fprintf(stderr, "Error seeking disk sector %d\n",DiskPtr);
      }
      if (fwrite(block,1,BLOCK_SIZE, DiskHandle) != BLOCK_SIZE) {
        fprintf(stderr, "Error writing to Disk.");
	returncode=RC_DEVICE_WRITE_FAIL;
      }
      DiskPtr += BLOCK_SIZE;
      if (fflush(DiskHandle) != 0) {
        fprintf(stderr, "Error flushing HW Disk Buffer\n");
	returncode=RC_DEVICE_WRITE_FAIL;	
      }
    } else {
      fprintf(stderr, "038 Attempted to write to disk block larger than memory available\n");
      returncode=RC_DEVICE_MEM_FAIL;
    }
    break;
  case CastSyncDisk:   // CastSyncDisk
    POPNULLCHK(HWStack);
    if (fflush(DiskHandle) != 0) {
      returncode=RC_DEVICE_GENERAL_FAIL;
      fprintf(stderr, "Error flushing HW Disk Buffer\n");
    }
    break;
  case CastSelectDiskI:   // CastSelectDiskI
    POPNULLCHK(HWStack);
    if (DiskHandle != NULL ) {
      fclose(DiskHandle);
    }
    snprintf(DiskName,sizeof(DiskName), "DISK%02d.disk", ParamI);
    DiskHandle = fopen(DiskName, "r+b");
    if (DiskHandle != NULL) {
      DiskPtr = 0;
      fseek(DiskHandle, 0, SEEK_SET);
    } else {
      returncode=RC_DISK_SEEK_FAIL;
      fprintf(stderr,"Error accessing DISK device: %d",ParamI);
    }
    break;    
    
  case CastSeekDiskI:   // CastSeekDiskI
    POPNULLCHK(HWStack);
    if (DiskHandle == NULL) {
      returncode=RC_DISK_SEEK_FAIL;
      fprintf(stderr,"Error, Attempted to Seek before selecting Disk.\n");
    }
    DiskPtr = ParamI * BLOCK_SIZE;
    if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0){
      returncode=RC_DISK_SEEK_FAIL;
      fprintf(stderr,"Erorr seeking block %d on disk.\n",DiskPtr);
    }
    break;        
  case CastWriteSectorI:   //CastWriteSectorI
    POPNULLCHK(HWStack);
    if (DiskHandle == NULL) {
      returncode=RC_DEVICE_GENERAL_FAIL;
      fprintf(stderr,"038 Attempted to write to disk without selecting Disk\n");
    }
    if ( ParamI < MAXMEMP - BLOCK_SIZE+1) {
      unsigned char block[BLOCK_SIZE];
      memcpy(block, &memory[ParamI], BLOCK_SIZE);
      if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0) {
	returncode=RC_DISK_SEEK_FAIL;	
        fprintf(stderr, "Error seeking disk sector %d\n",DiskPtr);
      }
      if (fwrite(block,1,BLOCK_SIZE, DiskHandle) != BLOCK_SIZE) {
	returncode=RC_DEVICE_WRITE_FAIL;
        fprintf(stderr, "Error writing to Disk.");
      }
      DiskPtr += BLOCK_SIZE;
      if (fflush(DiskHandle) != 0) {
	returncode=RC_DEVICE_WRITE_FAIL;	
        fprintf(stderr, "Error flusing HW Disk Buffer\n");
      }
    } else {
      fprintf(stderr, "038 Attempted to write to disk block larger than memory available\n");
      returncode=RC_DEVICE_MEM_FAIL;
    }  
    break;
  case CastTapeWrite:   // CastTapeWrite
    POPNULLCHK(HWStack);
    if (TapeHandle == NULL) {
        fprintf(stderr,"Attempted to write to tape without selecting device\n");
    } else if (Param <= MAXMEMP - BLOCK_SIZE) {
        unsigned char block[BLOCK_SIZE];
        memcpy(block, &memory[Param], BLOCK_SIZE);
        if (fwrite(block, 1, BLOCK_SIZE, TapeHandle) != BLOCK_SIZE) {
            fprintf(stderr, "Error writing to tape.\n");
	    returncode=RC_DEVICE_WRITE_FAIL;
        }
        if (fflush(TapeHandle) != 0) {
            fprintf(stderr, "Error flushing tape buffer\n");
	    returncode=RC_DEVICE_WRITE_FAIL;	    
        }
    } else {
        fprintf(stderr,"039 Attempt to write from source memory past available memory\n");
	returncode=RC_DEVICE_MEM_FAIL;
    }
    break;

  case CastTapeWriteI:   // CastTapeWriteI
    POPNULLCHK(HWStack);
    if (TapeHandle == NULL) {
        fprintf(stderr,"Attempted to write to tape without selecting device\n");
    } else if (ParamI <= MAXMEMP - BLOCK_SIZE) {
        unsigned char block[BLOCK_SIZE];
        memcpy(block, &memory[ParamI], BLOCK_SIZE);
        if (fwrite(block, 1, BLOCK_SIZE, TapeHandle) != BLOCK_SIZE) {
	  returncode=RC_DEVICE_WRITE_FAIL;	  
            fprintf(stderr, "Error writing to tape.\n");
        }
        if (fflush(TapeHandle) != 0) {
            fprintf(stderr, "Error flushing tape buffer\n");
	    returncode=RC_DEVICE_WRITE_FAIL;	    
        }
    } else {
        fprintf(stderr,"039 Attempt to write from source memory past available memory\n");
	returncode=RC_DEVICE_MEM_FAIL;
    }
    break;

    
  case CastPrint32I:       // CastPrint32I
    POPNULLCHK(HWStack);
    // Print 32bit number Param points to.    
    i32=get16memat(Param,memory)+(get16memat(Param+2,memory) << 16);
    if ( (i32 & ( 1 << 31)) != 0) {
      i32= ~(i32) + 1;
    }
    printf("%d",i32);    
    break;
  case CastPrint32S:        // CastPrint32II
    POPNULLCHK(HWStack);
    // Print 32bit number that top of stack points to.    
    i32=get16memat(tos,memory)+(get16memat(sft,memory)<<16);
    printf("%d",i32);
    break;
    
  case CastEnd:
    POPNULLCHK(HWStack);
    returncode=RC_END_PROGRAM;
    break;
  case CastStackDump:
    int t1;
    POPNULLCHK(HWStack);
    printf(" %04x:Stack:(%d)",CPC,HWStack[HWSPIDX]-1);
    for(i=0;i<(HWStack[HWSPIDX]-1);i++) {
      t1=HWStack[i*2] + (HWStack[i*2+1] << 8);
      printf(" %04x",t1);
    }
    printf("\n");
    break;
      
  default:
    returncode=RC_DEVICE_GENERAL_FAIL;    
    printf("Error No such Cast Code(%d).\n",tos);
    break;
  }
  fflush(stdout);
  return 0;
}
int handlePoll(int Param, int ParamI, int ParamII,uint8_t *memory, uint8_t *HWStack) {
  int a,c, tos, sft;

  char inlines[255];
  time_t seconds;
  (void) ParamII;      /* Possible future poll */
  tos = -1;
  sft = -1;  
  tos=topstack(HWStack,1);
  sft=sftstack(HWStack);
  tos = tos & 0xffff;
  sft = sft & 0xffff;
  
  seconds = time(NULL);
#define PollReadIntI 1
#define PollReadStrI 2
#define PollReadCharI 3
#define PollSetNoEcho 4
#define PollSetEcho 5
#define PollReadCINoWait 6
#define PollSetRawCode 7
#define PollReSetRaw 8
#define PollTTYState 9
#define PollReadSector 22
#define PollReadTapeI 23
#define PollRewindTape 24
#define PollReadTime 25
#define PollReadSectorI 26
#define PollReadTape 27
  switch (tos) {
  case PollReadIntI:
    POPNULLCHK(HWStack);
    if (scanf("%d",&a) != 1) {
      fprintf(stderr, "Invalid input\n");
      returncode=RC_INVALID_INPUT;
      return -1;
    }
    put16atmem(Param,a, memory);
    break;

  case PollReadStrI:

    POPNULLCHK(HWStack);   // consume POLL arg
    size_t strpc=ParamI;
    
    char *res = fgets(inlines, sizeof(inlines), stdin);

    
    // res will only equal NULL if EOF character was typed on empty line.
    if (res == NULL) {
      // we tell the user EOF by setting memory[Param]=0
      a=0;
      put16atmem(ParamI,a, memory);
    }
    else {
      // now our question is was the an empty line with <ENTER> or valid text.
      size_t len = strlen(inlines);
      if ( len > 1 && inlines[len-1] == '\n') {
	// Strip the /n and make it the null terminator
	inlines[--len] = '\0';
      } else if ( len == 1) {
	// case when empty line with <enter>
	inlines[0]='\n';
	inlines[1]='\0';
      }
      for(size_t i = 0; i<len; i++ ) {
	unsigned char c = (unsigned char) inlines[i];
	if (c > 31) { // printable characters only
	  memory[strpc++] = c;
	}
      }
    }
    memory[strpc]='\0';
    break;
  case PollReadCharI:
    POPNULLCHK(HWStack);
    c = read_one_char_nowait();
    if (c < 0) c = 0;
    put16atmem(Param, c, memory);
    break;
  case PollReadCINoWait:
    POPNULLCHK(HWStack);
    c = read_one_char_nowait();
    if (c < 0) c = 0;
    put16atmem(Param, c, memory);
    break;
  case PollSetNoEcho:
    POPNULLCHK(HWStack);
    disable_echo();
    break;
  case PollSetEcho:
    POPNULLCHK(HWStack);
    enable_echo();
    break;
  case PollSetRawCode:
    POPNULLCHK(HWStack);
    enable_raw();
    break;
  case PollReSetRaw:
    POPNULLCHK(HWStack);
    disable_raw();
    break;
  case PollTTYState:
    POPNULLCHK(HWStack);
    tty_state();
    break;
  case PollReadSector:
    POPNULLCHK(HWStack);
    if (DiskHandle != NULL ) {
      if ( Param <= MAXMEMP-0x200) {
        if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0) {
	  returncode=RC_DISK_SEEK_FAIL;
          fprintf(stderr, "Error Seeking in disk failed.\n");
        }
        unsigned char block[BLOCK_SIZE];
        size_t bytesRead = fread(block, 1, BLOCK_SIZE, DiskHandle);
        if (bytesRead != BLOCK_SIZE) {
	  returncode=RC_DEVICE_READ_FAIL;
          fprintf(stderr, "Error reading from disk.\n");
        } else {
          DiskPtr += BLOCK_SIZE;
        }
        
        unsigned int tidx = Param;
        for(int i = 0; i < BLOCK_SIZE; ++i) {
          memory[tidx++] = block[i] & 0xff;
        }
      } else {
	returncode=RC_DEVICE_MEM_FAIL;
        fprintf(stderr, "042 Attempted to read block with insufficen memory address %04x\n",Param);
      }
    }
    break;    
  case PollReadSectorI:
    POPNULLCHK(HWStack);
    if (DiskHandle != NULL ) {
      if ( ParamI <= MAXMEMP-0x200) {
        if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0) {
	  returncode=RC_DISK_SEEK_FAIL;
          fprintf(stderr, "Error Seeking in disk failed.\n");
        }
        unsigned char block[BLOCK_SIZE];
        size_t bytesRead = fread(block, 1, BLOCK_SIZE, DiskHandle);
        if (bytesRead != BLOCK_SIZE) {
	  returncode=RC_DEVICE_READ_FAIL;
          fprintf(stderr, "Error reading from disk.\n");
        } else {
          DiskPtr += BLOCK_SIZE;
        }        
        unsigned int tidx = ParamI;
        for(int i = 0; i < BLOCK_SIZE; ++i) {
          memory[tidx++] = block[i] & 0xff;
        }
      } else {
	returncode=RC_DEVICE_MEM_FAIL;
        fprintf(stderr, "042 Attempted to read block with insufficen memory address %04x\n",Param);
      }
    }    
    break;
  case PollReadTape:
    POPNULLCHK(HWStack);
    if (TapeHandle != NULL) {
        if (Param <= MAXMEMP - BLOCK_SIZE) {
            unsigned char block[BLOCK_SIZE];
            size_t bytesRead = fread(block, 1, BLOCK_SIZE, TapeHandle);
            if (bytesRead != BLOCK_SIZE) {
	      returncode=RC_DEVICE_READ_FAIL;
	      fprintf(stderr, "Error reading tape block.\n");
            }
            unsigned int tidx = Param;
            for (size_t i = 0; i < bytesRead; ++i) {
	      memory[tidx++] = block[i] & 0xff;
            }
        }
	else {
	  returncode=RC_DEVICE_MEM_FAIL;	  
	  fprintf(stderr, "043 Attempt to read Tape Block with insufficient memory\n");
        }
    } 
    break;

  case PollReadTapeI:
    POPNULLCHK(HWStack);
    if (TapeHandle != NULL) {
        if (ParamI <= MAXMEMP - BLOCK_SIZE) {
            unsigned char block[BLOCK_SIZE];
            size_t bytesRead = fread(block, 1, BLOCK_SIZE, TapeHandle);
            if (bytesRead != BLOCK_SIZE) {
	      returncode=RC_DEVICE_READ_FAIL;
	      fprintf(stderr, "Error reading tape block.\n");
            }
            unsigned int tidx = ParamI;
            for (size_t i = 0; i < bytesRead; ++i) {
                memory[tidx++] = block[i] & 0xff;
            }
        } else {
            fprintf(stderr, "043 Attempt to read Tape Block with insufficient memory\n");
	    returncode=RC_DEVICE_MEM_FAIL;
        }
    }
    break;

  case PollRewindTape:
    POPNULLCHK(HWStack);
    if (TapeHandle != NULL) {
        fseek(TapeHandle, 0, SEEK_SET);
    }
    break;
  
             

  case PollReadTime:
    POPNULLCHK(HWStack);          // consume POLL argument
    seconds = time(NULL);
    pushstack(seconds & 0xffff, HWStack);   // low
    pushstack(seconds >> 16, HWStack);      // high
    break;
    
  default:
    returncode=RC_DEVICE_GENERAL_FAIL;
    printf("Poll Code not implmented");
  }
  return 0;
}


