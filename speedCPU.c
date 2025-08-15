#include <Python.h>
#include <numpy/arrayobject.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <stdint.h>
#include <signal.h>

#include "fcpu.h"
#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION

#define HWSPIDX 0xff
#define CastSelectDisk 20
#define MAXMEMP 0xfffe
#define BLOCK_SIZE 512



int returncode;
void handle_ctrl_c(int sig) {
  printf("\nCaught SIGINT (Ctrl-C). Exiting...\n");
  returncode=-4;
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
p        tcgetattr(STDIN_FILENO, &ttystate);
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


void EvalOne(uint8_t *CPUMemData,uint8_t *CPUStackData,int *CPURegData, int *CPUFlags, int *index1);
int get16memat(int InLocation, uint8_t *CPUMemory);
void put16atmem(int locateaddr,int val, uint8_t *CPUMemory);
int popstack(uint8_t  *CPUStackData);
int topstack(uint8_t *CPUStackData, int nofail);
int sftstack(uint8_t *CPUStackData);
void pushstack(int invalue, uint8_t *CPUStackData);
void ReadFlags(int *CurrentFlags);
void WriteFlags(int *CurrentFlags);
void SetZNFlags(int testval);
void OverCarryTest(int a, int b, int c, int IsSubtraction);
void handleCast(int Param, int ParamI, int ParamII, uint8_t *CPUMemData, uint8_t *CPUStackData, int CPC);
void handlePoll(int Param, int ParamI, int ParamII, uint8_t *CPUMemData, uint8_t *CPUStackData);
int16_t ZF,NF,CF,OF, PC, AdminFlag; /* Global values */
char DiskName[17] = {'\0'}; /* Allocat 16 bytes for temporary filenames and null the first character */
FILE* DiskHandle = NULL;
int DiskPtr = 0;




void EvalSteps(PyObject* CPUMemory, PyObject* CPUHWStack, int*  CPUPC, int* CPUFlags, int* index1, int* returnval) {
  int opcount;
  
  PyArrayObject* np_array1 = (PyArrayObject*)PyArray_FROM_O(CPUMemory);
  PyArrayObject* np_array2 = (PyArrayObject*)PyArray_FROM_O(CPUHWStack);
  //  PyArrayObject* np_array3 = (PyArrayObject*)PyArray_FROM_O(CPURegisters);
  
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
  if (*index1 == -1){
    opcount=0;
    while(returncode == 0) {
      *index1=0;
      opcount++;
      /* Loop until normal exit */
      EvalOne(CPUMemData,CPUStackData, CPUPC, CPUFlags, index1);
    }
    printf("\nOpt Count: %d\n",opcount);
  } else {
    /* loop controled by index1 flag */
      EvalOne(CPUMemData,CPUStackData, CPUPC, CPUFlags, index1);
  }
  Py_XDECREF(np_array1);
  Py_XDECREF(np_array2);
  *returnval=returncode;
  //  Py_XDECREF(np_array3);  

}


  
//
// Define the required support functions.

static PyObject* c_EvalOne(PyObject* self, PyObject* args) {
    PyObject* array1;
    PyObject* array2;
    PyObject* array3;    
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
    cpuCfuncMethods
};

PyMODINIT_FUNC PyInit_cpuCfunc(void) {
    import_array();  // Initialize NumPy

    return PyModule_Create(&cpuCfunc);
}

void   EvalOne(uint8_t *CPUMemData,uint8_t *CPUStackData,int *CPUPC, int *CurrentFlags, int *index1) {
  int a,b,c;
  int Param, ParamI, ParamII,Opsize,OptCode,nbr1,nbr2,OCS,NCF,TF,TSP;
  int tos,sft,A1, A2, B1, B2, R1, R2, OCF;

  PC=(*CPUPC) & 0xffff;
  Opsize=1;

  Param=get16memat(PC+1, CPUMemData);
  ParamI=get16memat(Param, CPUMemData);
  ParamII=get16memat(ParamI, CPUMemData);
  OptCode=CPUMemData[PC];
  //  printf("At %04x Param=%04x, ParamI=%04x, ParamII=%04x OPCODE=%02x\n",PC,Param,ParamI,ParamII,OptCode);  
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
    SetZNFlags(A1);
    OverCarryTest(B1,Param,A1,1);
    Opsize=3;
    break;
  case OptValCMPI:
    B1=tos;
    A1=B1-ParamI;
    SetZNFlags(A1);
    OverCarryTest(B1,ParamI,A1,1); 
    Opsize=3;
    break;
  case OptValCMPII:
    B1=tos;
    A1=B1-ParamII;
    SetZNFlags(A1);
    OverCarryTest(B1,ParamII,A1,1);
    Opsize=3;
    break;
  case OptValCMPS:
    A2=sft;
    B1=tos;
    A1=A2 - B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);
    Opsize=1;
    break;
  case OptValADD:
    B1=popstack(CPUStackData);
    A1=Param + B1;
    SetZNFlags(A1);
    pushstack(A1,CPUStackData);
    OverCarryTest(Param,B1,A1,0);
    Opsize=3;
    break;
  case OptValADDI:
    B1=popstack(CPUStackData);
    A1=ParamI + B1;
    SetZNFlags(A1);
    pushstack(A1,CPUStackData);
    OverCarryTest(ParamI,B1,A1,0);	 
    Opsize=3;
    break;
  case OptValADDII:
    B1=popstack(CPUStackData);
    A1=ParamII + B1;
    SetZNFlags(A1);
    pushstack(A1,CPUStackData);
    OverCarryTest(ParamII,B1,A1,0);
    Opsize=3;
    break;
  case OptValADDS:
    A2=popstack(CPUStackData);
    B1=popstack(CPUStackData);
    A1=A2 + B1;
    SetZNFlags(A1);
    pushstack(A1,CPUStackData);
    OverCarryTest(A2,B1,A1,0);
    Opsize=1;
    break;
	 
  case OptValSUB:
    // We are starting to 'reverse' the older SUB and CMP login. A will be the value currently on the stack
    // and B will be the 'passed' value, except in the case of Stack/Stack which case A if SFT and B is TOS
    B1=popstack(CPUStackData);
    A1=B1-Param;
    SetZNFlags(A1);
    OverCarryTest(B1,Param,A1,1);
    pushstack(A1,CPUStackData);

    Opsize=3;
    break;
  case OptValSUBI:
    B1=popstack(CPUStackData);
    A1=B1-ParamI;
    SetZNFlags(A1);
    OverCarryTest(B1,ParamI,A1,1);	 
    pushstack(A1,CPUStackData);

    Opsize=3;
    break;
  case OptValSUBII:
    B1=popstack(CPUStackData);
    A1=B1-ParamII;
    SetZNFlags(A1);
    OverCarryTest(B1,ParamII,A1,1);	 
    pushstack(A1,CPUStackData);

    Opsize=3;
    break;
  case OptValSUBS:
    B1=popstack(CPUStackData);
    A1=popstack(CPUStackData);
    A1=A1 - B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	 
    pushstack(A1,CPUStackData);

    Opsize=1;
    break;
	 
  case OptValAND:
    B1=popstack(CPUStackData);
    A1=Param & B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);    
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValANDI:
    B1=popstack(CPUStackData);
    A1=ParamI & B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValANDII:
    B1=popstack(CPUStackData);
    A1=ParamII & B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);    
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValANDS:
    A2=popstack(CPUStackData);
    B1=popstack(CPUStackData);
    A1=A2 & B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
    pushstack(A1,CPUStackData);
    Opsize=1;
    break;
  case OptValXOR:
    B1=popstack(CPUStackData);
    A1=Param ^ B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;	 
  case OptValXORI:
    B1=popstack(CPUStackData);
    A1=ParamI ^ B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValXORII:
    B1=popstack(CPUStackData);
    A1=ParamII ^ B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValXORS:
    A2=popstack(CPUStackData);
    B1=popstack(CPUStackData);
    A1=A2 ^ B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
    pushstack(A1,CPUStackData);
    Opsize=1;
    break;
         
  case OptValOR:
    B1=popstack(CPUStackData);
    A1=Param | B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;	 
  case OptValORI:
    B1=popstack(CPUStackData);
    A1=ParamI | B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValORII:
    B1=popstack(CPUStackData);
    A1=ParamII | B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
    pushstack(A1,CPUStackData);
    Opsize=3;
    break;
  case OptValORS:
    A2=popstack(CPUStackData);
    B1=popstack(CPUStackData);
    A1=A2 | B1;
    SetZNFlags(A1);
    OverCarryTest(B1,A2,A1,1);	     
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
    handleCast(Param,ParamI,ParamII, CPUMemData, CPUStackData,PC);
    Opsize=3;
    break;
  case OptValPOLL:
    handlePoll(Param,ParamI,ParamII, CPUMemData, CPUStackData);
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
  case OptValSHR:
    R1=popstack(CPUStackData);
    B1=0;
    if ( R1 & 0x1) { B1=1;}
    R1=R1 >> 1;
    CF=B1;
    pushstack(R1,CPUStackData);	 
    Opsize=1;
    break;
  case OptValSHL:
    R1=popstack(CPUStackData);
    B1=0;
    if ( R1 & 0x8000) { B1=1;}
    R1=R1 << 1;
    CF=B1;
    pushstack(R1,CPUStackData);	 
    Opsize=1;
    break;	   
  case OptValINV:
    R1=~(popstack(CPUStackData));
    pushstack(R1,CPUStackData);
    SetZNFlags(R1);
    CF=0; OF=0;
    Opsize=1;
    break;
  case OptValCOMP2:
    R1=popstack(CPUStackData);
    R1= ((~R1 & 0xffff) + 1) & 0xffff;
    pushstack(R1,CPUStackData);
    SetZNFlags(R1);
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
    HWStack[HWSPIDX]=0;
    break;
  case OptValSRPT:
    if (HWStack[HWSPIDX] < (MAXHWSTACK - 1)) {
      pushstack(HWStack[HWSPIDX],optcode);
    } else if (HWStack[HWSPIDX] == (MAXHWSTACK - 1)) {
      pushstack(-1,optcode);
    }
    break;
  default:
    printf("Unknown OptCode %d at address %04x\n",OptCode,PC);
    PC++;
    break;
  }
  
  WriteFlags(CurrentFlags);
  //  if ( *index1 > 1 ) {
  //      printf(" %04x:%8s P1:%04x [I]:%04x [II]:%04x TOS[%04x,%04x] Z%1d N%1d C%1d O%1d SS(%d)\n",
  //	     PC,optcnames[OptCode],Param,ParamI,ParamII,tos,sft,ZF,NF,CF,OF,CPUStackData[HWSPIDX]);
  //     fflush(stdout);
  //  }
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
  int lsp,csp;  
  lsp=CPUStackData[HWSPIDX];
  if ( lsp > 0 ) {
    CPUStackData[HWSPIDX] -= 1;
    lsp=CPUStackData[HWSPIDX];
    return CPUStackData[(lsp*2)]+(CPUStackData[(lsp*2)+1]<<8);
  } else {
    returncode=-2;
    return -1;
  }
}

int topstack(uint8_t *CPUStackData,int nofail) {
  int lsp;  
  lsp=CPUStackData[HWSPIDX];
  if (lsp > 0 ) {
    lsp--;
    return CPUStackData[lsp*2]+(CPUStackData[(lsp*2)+1]<<8);
  }
  else {
    return -1;
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
    returncode=-3;    
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


void SetZNFlags(int testval) {
  int B2;
  ZF=0;
  NF=0;
  CF=0;
  B2=0;
  B2=abs(testval) & 0xffff;
  ZF=(B2 == 0) ? 1:0;
  NF=(testval & 0x8000) != 0?1:0;
}

void OverCarryTest(int a, int b, int c, int IsSubtraction) {
  int a16,b16,c16,sa,sb,sc;
    
  OF=0;    /* Globals */
  CF=0;    /* Globals */
  a16 = a & 0xffff;
  b16 = b & 0xffff;
  c16 = c & 0xffff;
  sa=(a16 & 0x8000) != 0;
  sb=(b16 & 0x8000) != 0;
  sc=(c16 & 0x8000) != 0;
  if(IsSubtraction) {
    if (a < b ){ CF=1; }
    else     { CF=0; }
    if ((sa != sb) && (sc !=sa)) {
        OF=1;
      }
  } else {

    if ((unsigned int)a16 + (unsigned int)b16 > 0xFFFF) {
      CF = 1;
    } else {
      CF = 0;
    }
    if ((sa == sb) && (sc != sa)) {
      OF = 1;
    }
  }
}
void handleCast(int Param, int ParamI, int ParamII,  uint8_t *memory, uint8_t *HWStack, int CPC) {
  int16_t i,c,a, tos, sft;
  int i32, TSP;

  // printf("Cast Codes Mode %04x: %04x - %04x - %04x\n",topstack(PC),Param,ParamI,ParamII);
  tos=topstack(HWStack,0);
  sft=sftstack(HWStack);

  switch (tos) {
  case 0:
    printf("Stack Dump: ");
    for(i=0;i<(HWStack[HWSPIDX] << 1);i++) {
      printf("%04x ",HWStack[i<<1]+(HWStack[(i<<1)+1]));
    }
    printf("\n");
  case 1:           // CastPrintStr 1
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
  case 2:           // CastPrintInt 2
    a=Param & 0xffff;
    printf("%d",(short)a);
    break;
  case 3:          // CastPrintIntI
    a=ParamI & 0xffff;
    printf("%d", (unsigned short)a);
    break;
  case 4:          // CastPrintSignI
    a=ParamI & 0xffff;
    printf("%d", (short)a);
    break;
  case 5:          // CastPrintBinI
    a=ParamI & 0xffff;
    printf("%x", (unsigned short)a);
    break;    
  case 6:          // CastPrintChar
    if ( ParamI < 32 || ParamI > 128 ) {
      printf("%02x", (unsigned short)ParamI);
    } else {
      printf("%c",ParamI);
    }
    break;
  case 11:         // CastPrintStrI
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
  case 12:         // CastPrintIntUI
    a=ParamI & 0xffff;
    printf("%u",(unsigned short)a);
    break;
  case 16:         // CastPrintCharI
    if ( ParamII < 32 || ParamII > 128 ) {
      printf("%02x", ParamII);
    } else {
      printf("%c",ParamII);
    }
    break;    
  case 17:         // CastPrintHexI
    a=ParamI & 0xffff;
    printf("%04x",(unsigned short)a);
    break;
  case 18:        // CastPrintHexII
    a=ParamII & 0xffff;
    printf("%04x",a);
    break;
  case 20:   // CastSelectDisk
    if (DiskHandle != NULL ) {
      fclose(DiskHandle);
    }
    snprintf(DiskName,sizeof(DiskName), "DISK%02d.disk", Param);
    DiskHandle = fopen(DiskName, "r+b");
    if (DiskHandle != NULL) {
      DiskPtr = 0;
      fseek(DiskHandle, 0, SEEK_SET);
    } else {
      fprintf(stderr,"Error accessing DISK device: %d\n",Param);
        }
    break;
  case 21:   //CastSeekDisk
    if (DiskHandle == NULL) {
      fprintf(stderr,"Error, Attempted to Seek before selecting Disk.\n");
    }
    DiskPtr = Param * BLOCK_SIZE;
    if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0){
      fprintf(stderr,"Erorr seeking block %d on disk.\n",DiskPtr);
    }
    break;
  case 22:   //CastWriteSector
    if (DiskHandle == NULL) {
      fprintf(stderr,"038 Attempted to write to disk without selecting Disk\n");
    }
    if ( Param < MAXMEMP - BLOCK_SIZE+1) {
      unsigned char block[BLOCK_SIZE];
      memcpy(block, &memory[Param], BLOCK_SIZE);
      if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0) {
        fprintf(stderr, "Error seeking disk sector %d\n",DiskPtr);
      }
      if (fwrite(block,1,BLOCK_SIZE, DiskHandle) != BLOCK_SIZE) {
        fprintf(stderr, "Error writing to Disk.");
          }
      DiskPtr += BLOCK_SIZE;
      if (fflush(DiskHandle) != 0) {
        fprintf(stderr, "Error flushing HW Disk Buffer\n");
      }
    } else {
      fprintf(stderr, "038 Attempted to write to disk block larger than memory available\n");
    }
    break;
  case 23:   // CastSyncDisk
    if (fflush(DiskHandle) != 0) {
      fprintf(stderr, "Error flushing HW Disk Buffer\n");
    }
    break;
  case 24:   // CastSelectDiskI
    if (DiskHandle != NULL ) {
      fclose(DiskHandle);
    }
    snprintf(DiskName,sizeof(DiskName), "DISK%02d.disk", ParamI);
    DiskHandle = fopen(DiskName, "r+b");
    if (DiskHandle != NULL) {
      DiskPtr = 0;
      fseek(DiskHandle, 0, SEEK_SET);
    } else {
      fprintf(stderr,"Error accessing DISK device: %d",ParamI);
        }
    break;    
    
  case 25:   // CastSeekDiskI
    if (DiskHandle == NULL) {
      fprintf(stderr,"Error, Attempted to Seek before selecting Disk.\n");
    }
    DiskPtr = ParamI * BLOCK_SIZE;
    if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0){
      fprintf(stderr,"Erorr seeking block %d on disk.\n",DiskPtr);
    }
    break;        
  case 26:   //CastWriteSectorI
    if (DiskHandle == NULL) {
      fprintf(stderr,"038 Attempted to write to disk without selecting Disk\n");
    }
    if ( ParamI < MAXMEMP - BLOCK_SIZE+1) {
      unsigned char block[BLOCK_SIZE];
      memcpy(block, &memory[ParamI], BLOCK_SIZE);
      if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0) {
        fprintf(stderr, "Error seeking disk sector %d\n",DiskPtr);
      }
      if (fwrite(block,1,BLOCK_SIZE, DiskHandle) != BLOCK_SIZE) {
        fprintf(stderr, "Error writing to Disk.");
          }
      DiskPtr += BLOCK_SIZE;
      if (fflush(DiskHandle) != 0) {
        fprintf(stderr, "Error flusing HW Disk Buffer\n");
      }
    } else {
      fprintf(stderr, "038 Attempted to write to disk block larger than memory available\n");
    }  
    break;
  case 32:       // CastPrint32I
    // Print 32bit number Param points to.    
    i32=get16memat(Param,memory)+(get16memat(Param+2,memory) << 16);
    if ( (i32 & ( 1 << 31)) != 0) {
      i32= ~(i32) + 1;
    }
    printf("%d",i32);    
    break;
  case 33:        // CastPrint32II
    // Print 32bit number that top of stack points to.    
    i32=get16memat(tos,memory)+(get16memat(sft,memory)<<16);
    printf("%d",i32);
    break;
    
  case 99:
    returncode=-1;
    break;
  case 102:
    int t1;
    printf(" %04x:Stack:(%d)",CPC,HWStack[HWSPIDX]-1);
    for(i=0;i<(HWStack[HWSPIDX]-1);i++) {
      t1=HWStack[i*2] + (HWStack[i*2+1] << 8);
      printf(" %04x",t1);
    }
    printf("\n");
    break;
      
  default:
    printf("Error No such Cast Code(%d).\n",tos);
    break;
  }
  fflush(stdout);
}
void handlePoll(int Param, int ParamI, int ParamII,uint8_t *memory, uint8_t *HWStack) {
  int a,i,pc,c, TSP, tos, sft;
  char inlines[255];
  time_t seconds;
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
  #define PollReadSector 22
  #define PollReadSectorI 26
  #define PollReadTapeI 23
  #define PollRewindTape 24
  #define PollReadTime 25   
  switch (tos) {
  case PollReadIntI:
    scanf("%d",&a);
    put16atmem(Param,a, memory);
    break;
  case PollReadStrI:
    fgets(inlines,254,stdin);
    pc=ParamI;
    for(i=0;i<strlen(inlines);i++) {      
      memory[pc]=(int)inlines[i];
    }
    break;
  case PollReadCharI:
    c=getc(stdin);
    put16atmem(Param,(int)c, memory);
    break;
  case PollSetNoEcho:
    disable_echo();
    break;
  case PollSetEcho:
    enable_echo();
    break;
  case PollReadCINoWait:
    enable_nonblocking_input();
    while (1) {
      c=0;
      if (kbhit()) {
	c=getch();	
      }
      break;
    }
    put16atmem(Param,(int)c,memory);
    break;
  case PollReadSector:
    if (DiskHandle != NULL ) {
      if ( Param <= MAXMEMP-0x200) {
        if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0) {
          fprintf(stderr, "Error Seeking in disk failed.\n");
        }
        unsigned char block[BLOCK_SIZE];
        size_t bytesRead = fread(block, 1, BLOCK_SIZE, DiskHandle);
        if (bytesRead != BLOCK_SIZE) {
          fprintf(stderr, "Error reading from disk.\n");
        }
        unsigned int tidx = Param;
        for(int i = 0; i < BLOCK_SIZE; ++i) {
          memory[tidx] = block[i] & 0xff;
          tidx += 1;
        }
      } else {
        fprintf(stderr, "042 Attempted to read block with insufficen memory address %04x\n",Param);
      }
    } else {
      fprintf(stderr, "Error, attempted to write to Disk without first selecting it.");
    }
    break;
  case PollReadSectorI:
    if (DiskHandle != NULL ) {
      if ( ParamI <= MAXMEMP-0x200) {
        if (fseek(DiskHandle, DiskPtr, SEEK_SET) != 0) {
          fprintf(stderr, "Error Seeking in disk failed.\n");
        }
        unsigned char block[BLOCK_SIZE];
        size_t bytesRead = fread(block, 1, BLOCK_SIZE, DiskHandle);
        if (bytesRead != BLOCK_SIZE) {
          fprintf(stderr, "Error reading from disk.\n");
        }
        unsigned int tidx = ParamI;
        for(int i = 0; i < BLOCK_SIZE; ++i) {
          memory[tidx] = block[i] & 0xff;
          tidx += 1;
        }
      } else {
        fprintf(stderr, "042 Attempted to read block with insufficen memory address %04x\n",Param);
      }
    } else {
      fprintf(stderr, "Error, attempted to write to Disk without first selecting it.");
    }
    break;
  
           
                
            
  case PollReadTapeI:
    break;
  case PollReadTime:
    seconds = time(NULL);
    pushstack(seconds & 0xffff, HWStack);
    pushstack(seconds >> 16, HWStack);
    break;
    
  default:
    printf("Poll Code not implmented");
  }

}
