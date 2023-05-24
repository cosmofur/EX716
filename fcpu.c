#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "fcpu.h"

int memory[0xffff];
int PC=0;
int Entry=0;
int GetNextWord();
#define MAXHWSTACK 0x100
#define HWSPIDX 0xff

int HWStack[MAXHWSTACK+1];
int ZF=0;
int NF=0;
int CF=0;
int OF=0;
int R1,R2,A1,B1,A2,B2;  // Scratch Variables
int DebugRange1,DebugRange2;
unsigned long long int OptCount=0;

int FileRead(char *fname) {
  FILE *fp = fopen(fname,"r");
  int temp;

  if (!fp) {
    printf("Count not open filename %s\n", fname);
    return 1;
  }

  char *line=NULL;
  size_t len=0;
  ssize_t read;
  int LineCount=0;
  int FinishQuick=0;
  while((read = getline(&line, &len, fp)) != -1) {
    if ( line[read-1] == '\n') {
      line[read-1] = '\0';
    }
    LineCount++;
    char *ptr = line;
    FinishQuick=0;
    while ( *ptr != '\0' && FinishQuick == 0) {
      switch(*ptr) {
      case 'b':
	temp=GetNextWord(&ptr);
	if (PC > 0xfffe) {
	  printf("Ran out of memory\n");
	  return -1;
	}
	memory[PC]=temp;
	PC++;	
	break;
      case '.':
	ptr++;
	temp=GetNextWord(&ptr);
	PC=temp;
	Entry=PC;
	break;
      case ' ':
      case '\t':
	ptr++;
	break;
      case '#':
      case '=':
      case 'G':
	/* Comment */
	FinishQuick=1;
	break;
      default:
	printf("Unexpected content at %d of %s\n",LineCount,ptr); 
	FinishQuick=1;
	break;
      }
    }
  }
  fclose(fp);
  return 0;
}

void SetFlags(int testval) {
  ZF=0;
  NF=0;
  CF=0;
  B2=abs(testval) & 0xffff;
  ZF=(B2 == 0) ? 1:0;
  NF=(testval & 0x8000) != 0?1:0;
  CF=(testval & 0xffff0000) > 0 ? 1:0;
  return;
}

void OverFlowTest(int a, int b, int c, int IsSubtraction) {
  a=((a & 0xffff) > 0x8000) ? -1: 1;
  b=((b & 0xffff) > 0x8000) ? -1: 1;
  c=((c & 0xffff) > 0x8000) ? -1: 1;  
				     
  if ( IsSubtraction == 0) {
    if (((a > 0) && (b > 0) && (c < 0)) || ((a < 0) && (b < 0) && (c >= 0))) {
      // overflow occurred
      OF=1;
    } else {
      // no overflow
      OF=0;
    }
  }
  else {
    if (((a > 0) && (b < 0) && (c < 0)) || ((a < 0) && (b > 0) && (c >= 0))) {
      // overflow occurred
      OF=1;
    } else {
      // no overflow
      OF=0;
    }
  }
}
      

int get16memat(int locateaddr) {
  locateaddr=locateaddr & 0xffff;
  if ( locateaddr == 0xffff) { return 0;}
  return ((memory[locateaddr] & 0xff) + ((memory[locateaddr+1] & 0xff) << 8) ) &0xffff;

}
void put16atmem(int locateaddr,int val) {
  locateaddr=locateaddr & 0xffff;
  memory[locateaddr]=val & 0xff;
  memory[locateaddr+1]=((val >> 8) & 0xff);
}
int topstack(int optcode) {
  if (HWStack[HWSPIDX] > MAXHWSTACK) {
    printf("001 MB Stack Overflow, OPCODE %d\n",optcode);
    return 0;
  } else if (HWStack[HWSPIDX] < 1) {
    printf("002 MB Stack Underflow, OPCODE %d\n",optcode);
    return 0;
  }
  return (HWStack[HWStack[HWSPIDX]-1] & 0xffff);
}

int sectopstack(int optcode) {
  if (HWStack[HWSPIDX] > MAXHWSTACK) {
    printf("001 MB Stack Overflow, OPCODE %d\n",optcode);
    return 0;
  } else if (HWStack[HWSPIDX] < 2) {
    printf("002 MB Stack Underflow, OPCODE %d\n",optcode);
    return 0;
  }
  return HWStack[HWStack[HWSPIDX]-2];
}
int popstack(int optcode) {
  if (HWStack[HWSPIDX] > MAXHWSTACK) {
    printf("001 MB Stack Overflow, OPCODE %d\n",optcode);
    return 0;
  } else if (HWStack[HWSPIDX] < 1) {
    printf("002 MB Stack Underflow, OPCODE %d\n",optcode);
    return 0;
  }
  HWStack[HWSPIDX]--;
  return HWStack[HWStack[HWSPIDX]];
}
void pushstack(int invalue,int optcode) {  
  if (HWStack[HWSPIDX] > MAXHWSTACK) {
    printf("004 MB Stack Overflow, OPCODE %d\n",optcode);
    return;
  }
  HWStack[HWStack[HWSPIDX]]=invalue;
  HWStack[HWSPIDX]++;
}

void handleCast(int Param, int ParamI, int ParamII) {
  int16_t i,c,a;
  int i32;
  // printf("Cast Codes Mode %04x: %04x - %04x - %04x\n",topstack(PC),Param,ParamI,ParamII);
  switch (topstack(PC)) {
  case 0:
    printf("Stack Dump: ");
    for(i=0;i<HWStack[HWSPIDX];i++) {
      printf("%04x ",HWStack[i]);
    }
    printf("\n");
  case 1:
    i=Param;
    while (memory[i] != 0 && i < 0xffff) {
      c=memory[i]; i++;
      if ((c<32 || c> 127) && ( c !=0 && c != 7 && c != 27 && c != 30 && c!=10)) {
	printf("%02x",c);
      } else {
	printf("%c",(char) c);
      }
    }
    break;
  case 2:
    a=Param & 0xffff;
    printf("%u",a);
    break;
  case 3:
    a=ParamI & 0xffff;
    printf("%u", a);
    break;
  case 4:
    a=ParamI & 0xffff;
    printf("%d", a);
    break;
  case 5:
    a=ParamI & 0xffff;
    printf("%x", a);
    break;    
  case 6:
    if ( ParamI < 32 || ParamI > 128 ) {
      printf("%02x", ParamI);
    } else {
      printf("%c",ParamI);
    }
    break;
  case 11:
    i=ParamI;
    while (memory[i] != 0 && i < 0xffff) {
      c=memory[i];
      if ((c<32 || c> 127) && ( c !=0 && c != 7 && c != 27 && c != 30)) {
	printf("%02x",c);
      } else {
	printf("%c",c);
      }
    }
    break;
  case 12:
    a=ParamI & 0xffff;
    printf("%u",a);
    break;
  case 16:
    if ( ParamII < 32 || ParamII > 128 ) {
      printf("%02x", ParamII);
    } else {
      printf("%c",ParamII);
    }
    break;    
  case 17:
    a=ParamI & 0xffff;
    printf("%04x",a);
    break;
  case 18:
    a=ParamII & 0xffff;
    printf("%04x",a);
    break;    
  case 32:
    i32=(ParamI+(memory[Param+2]+( memory[Param+3] << 8))) << 16;
    printf("%d",i32);
    break;
  case 33:
    i32=topstack(PC) + (sectopstack(PC)<<16);
    printf("%d",i32);
    break;
  case 99:
    printf("END(%llu) Ops\n",OptCount);    
    exit(0);
    break;  
  default:
    printf("Error No such Cast Code.\n");
    break;
  }
}
void handlePoll(int Param,int ParamI,int ParamII) {
  int a,i,pc,c;
  char inlines[255];
  switch (topstack(PC)) {
  case 1:
    scanf("%d",&a);
    put16atmem(Param,a);
    break;
  case 2:
    fgets(inlines,254,stdin);
    pc=ParamI;
    for(i=0;i<strlen(inlines);i++) {      
      memory[pc]=(int)inlines[i];
    }
    break;
  case 3:
    c=getc(stdin);
    put16atmem(Param,(int)c);
    break;
  default:
    printf("Poll Code not implmented");
  }
}
  


/* Rule about HW stack.
   HWStack is int array of MAXHWSTACK size
   Location HWSPIDX in that array is also the Stack Pointer.
   Stack Pointer always points at the INSERTION point of the next
   value to be pushed to the stack. The TOP value is therefor 
   [HWSPIDX]-1 location. If HWSPIDX is zero, there there is no TOP */


int doeval(int startpc) {
  PC=startpc;
  int LoopForever=1;
  int Param=0;
  int ParamI=0;
  int ParamII=0;
  int Opsize;
  int OptCode;
  int nbr1; int nbr2;
  int OCF,NCF;
  int TF;
  
  while(LoopForever == 1 )
    {
      if ( PC == 0x185f ) {
	printf("Place to put break");
      }
      OptCount++;
      Param=get16memat(PC+1);
      ParamI=get16memat(Param);
      ParamII=get16memat(ParamI);
      Opsize=1;
      OptCode=memory[PC];
      nbr1=0; nbr2=0;
      if (HWStack[HWSPIDX]>=1) nbr1=topstack(PC); else nbr1=-1;
      if (HWStack[HWSPIDX]>=2) nbr2=sectopstack(PC); else nbr2=-1;
      nbr1=nbr1 & 0xffff;
      nbr2=nbr2 & 0xffff;
      if (PC >= DebugRange1 && PC <= DebugRange2) {
      printf("%04x:%8s P1:%04x [I]:%04x [II]:%04x TOS[%04x,%04x] Z%1d N%1d C%1d O%1d SS(%d)\n",
	     PC,optcnames[OptCode],Param,ParamI,ParamII,nbr1,nbr2,ZF,NF,CF,OF,HWStack[HWSPIDX]);
	}
       switch(OptCode) {
       case OptValNOP:
	 PC++;
	 Opsize=1;
	 break;
       case OptValPUSH:
	 pushstack(Param,OptCode);
	 Opsize=3; 
	 PC += Opsize;
	 break;
       case OptValDUP:
	 A1=topstack(OptCode);
	 pushstack(A1,OptCode);
	 Opsize=1;
	 PC += Opsize;	 
	 break;
       case OptValPUSHI:
	 pushstack(ParamI,OptCode);
	 Opsize=3; 
	 PC += Opsize;
	 break;
       case OptValPUSHII:
	 pushstack(ParamII,OptCode);
	 Opsize=3; 
	 PC += Opsize;
	 break;	 
       case OptValPUSHS:
	 pushstack(get16memat(popstack(OptCode)),OptCode);
	 Opsize=1;
	 PC += Opsize;
	 break;
       case OptValPOPNULL:
	 A1=popstack(OptCode);
	 Opsize=1;
	 PC++;
	 break;
       case OptValSWP:
	 A1=popstack(OptCode);
	 A2=popstack(OptCode);	 
	 pushstack(A1,OptCode);
	 pushstack(A2,OptCode);
	 Opsize=1;
	 PC++;
	 break;
       case OptValPOPI:
	 put16atmem(Param,popstack(OptCode));
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValPOPII:
	 put16atmem(ParamI,popstack(OptCode));	 
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValPOPS:
	 A1=popstack(OptCode);
	 B1=popstack(OptCode);
	 put16atmem(A1,B1);
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
       case OptValCMP:
	 B1=topstack(OptCode);
	 A1=B1-Param;
	 SetFlags(A1);
	 OverFlowTest(B1,Param,A1,1);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValCMPI:
	 B1=topstack(OptCode);
	 A1=B1-ParamI;
	 SetFlags(A1);
	 OverFlowTest(B1,ParamI,A1,1);	 
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValCMPII:
	 B1=topstack(OptCode);
	 A1=B1-ParamII;
	 SetFlags(A1);
	 OverFlowTest(B1,ParamII,A1,1);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValCMPS:
	 A2=topstack(OptCode);
	 B1=sectopstack(OptCode);
	 A1=B1 - A2;
	 SetFlags(A1);
	 OverFlowTest(B1,A2,A1,1);
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
       case OptValADD:
	 B1=popstack(OptCode);
	 A1=Param + B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 OverFlowTest(Param,B1,A1,0);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValADDI:
	 B1=popstack(OptCode);
	 A1=ParamI + B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 OverFlowTest(ParamI,B1,A1,0);	 
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValADDII:
	 B1=popstack(OptCode);
	 A1=ParamII + B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 OverFlowTest(ParamII,B1,A1,0);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValADDS:
	 A2=popstack(OptCode);
	 B1=popstack(OptCode);
	 A1=A2 + B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 OverFlowTest(A2,B1,A1,0);		 
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
	 
       case OptValSUB:
	 // We are starting to 'reverse' the older SUB and CMP login. A will be the value currently on the stack
	 // and B will be the 'passed' value, except in the case of Stack/Stack which case A if SFT and B is TOS
	 B1=popstack(OptCode);
	 A1=B1-Param;
	 SetFlags(A1);
	 OverFlowTest(B1,Param,A1,1);
	 pushstack(A1,OptCode);

	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValSUBI:
	 B1=popstack(OptCode);
	 A1=B1-ParamI;
	 SetFlags(A1);
	 OverFlowTest(B1,ParamI,A1,1);	 
	 pushstack(A1,OptCode);

	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValSUBII:
	 B1=popstack(OptCode);
	 A1=B1-ParamII;
	 OverFlowTest(B1,ParamII,A1,1);	 
	 SetFlags(A1);
	 pushstack(A1,OptCode);

	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValSUBS:
	 A2=popstack(OptCode);
	 B1=popstack(OptCode);
	 A1=B1 - A2;
	 SetFlags(A1);
	 OverFlowTest(B1,A2,A1,1);	 
	 pushstack(A1,OptCode);

	 Opsize=1;
	 PC=PC+Opsize;
	 break;
	 
       case OptValAND:
	 B1=popstack(OptCode);
	 A1=Param & B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValANDI:
	 B1=popstack(OptCode);
	 A1=ParamI & B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValANDII:
	 B1=popstack(OptCode);
	 A1=ParamII & B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValANDS:
	 A2=popstack(OptCode);
	 B1=popstack(OptCode);
	 A1=A2 & B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
	 
       case OptValOR:
	 B1=popstack(OptCode);
	 A1=Param | B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;	 
       case OptValORI:
	 B1=popstack(OptCode);
	 A1=ParamI | B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValORII:
	 B1=popstack(OptCode);
	 A1=ParamII | B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValORS:
	 A2=popstack(OptCode);
	 B1=popstack(OptCode);
	 A1=A2 | B1;
	 SetFlags(A1);
	 pushstack(A1,OptCode);
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
	 
       case OptValJMPZ:	   
	 if ( ZF ) { PC=Param; }
	 else {
	   Opsize=3;
	   PC=PC+Opsize;
	 }
	 break;
       case OptValJMPN:
	 if ( NF ) { PC=Param; }
	 else {
	   Opsize=3;
	   PC=PC+Opsize;
	 }
	 break;
       case OptValJMPC:
	 if ( CF ) { PC=Param; }
	 else {
	   Opsize=3;
	   PC=PC+Opsize;
	 }
	 break;	 
       case OptValJMPO:
	 if ( OF ) { PC=Param; }
	 else {
	   Opsize=3;
	   PC=PC+Opsize;
	 }
	 break;
       case OptValJMP:
	 PC=Param;
	 break;
       case OptValJMPI:
	 PC=ParamI;
	 break;
       case OptValCAST:
	 handleCast(Param,ParamI,ParamII);
	 Opsize=3;
	 PC=PC+Opsize;
	 break;
       case OptValPOLL:
	 handlePoll(Param,ParamI,ParamII);
	 Opsize=3;
	 PC=PC+Opsize;	 
	 break;
       case OptValRRTC:
	 R1=popstack(OptCode);
	 NCF=0;
	 if ( R1 & 1 ) {
	   NCF = 1 << 2;
	 }
	 OCF=CF << 15;
	 R1=R1 >> 1 | OCF;
	 CF=NCF;
	 pushstack(R1,OptCode);
	 Opsize=1;
	 PC=PC+Opsize;	 
	 break;	 
       case OptValRLTC:
	 R1=popstack(OptCode);
	 NCF=0;
	 if ( R1 & 0x8000) { NCF=1;}
	 OCF=CF;
	 R1=(R1<<1) + OCF;
	 CF=NCF;
	 pushstack(R1,OptCode);
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
       case OptValRTR:
	 R1=popstack(OptCode);
	 B1=0;
	 if ( R1 & 0x1) { B1=1;}
	 R1=R1 >> 1;
	 CF=B1;
	 pushstack(R1,OptCode);	 
	 Opsize=1;
	 PC=PC+Opsize;	 
	 break;
       case OptValRTL:
	 R1=popstack(OptCode);
	 B1=0;
	 if ( R1 & 0x8000) { B1=1;}
	 R1=R1 << 1;
	 CF=B1;
	 pushstack(R1,OptCode);	 
	 Opsize=1;
	 PC=PC+Opsize;
	 break;	   
       case OptValINV:
	 R1=~(popstack(OptCode));
	 pushstack(R1,OptCode);
	 SetFlags(R1);
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
       case OptValCOMP2:
	 R1=popstack(OptCode);
	 R1= ((~R1 & 0xffff) + 1) & 0xffff;
	 pushstack(R1,OptCode);
	 SetFlags(R1);
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
       case OptValFCLR:
	 NF=0;CF=0;ZF=0;OF=0;
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
       case OptValFSAV:
	 TF=ZF+(NF<<1)+(CF<<2)+(OF<<3);
	 pushstack(TF,OptCode);
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
       case OptValFLOD:
	 ZF=0; NF=0;CF=0;OF=0;
	 R1=popstack(OptCode);
	 if ( R1 & 0x1) { ZF=1; }
	 if ( R1 & 0x2) { NF=1; }
	 if ( R1 & 0x4) { CF=1; }
	 if ( R1 & 0x8) { OF=1; }
	 Opsize=1;
	 PC=PC+Opsize;
	 break;
       default:
	 printf("Unknown OptCode %d at address %0x04\n",OptCode,PC);
	 PC++;
	 break;
       }       
    }
  return 0;
}

int GetNextWord(char **Passptr) {
  char *ptr = *Passptr;
  int base;
  char *fwdptr;
  // Skip whitespace if any.
  fwdptr=ptr;
  while ( (*ptr != '\0') & ( *ptr == ' ' || *ptr == '\t')) {
    ptr++;
  }
  if ( *ptr == 'b' ) {  // skip past any 'b'
    fwdptr++;
    ptr++;
  }  
  
  fwdptr=ptr; // Look ahead to see if it's hex
  if ( strlen(fwdptr) < 2) {
    // Single digit numbers are always decimal
    base=10;
  } else {
    if ( *fwdptr == '0' ) {
      fwdptr++;
      if ( *fwdptr == 'x' ) {
	base=16; // Hex number
      } else {
	base=10;
      }
    }
  }
  long int number=strtol(ptr, &fwdptr, base);
  if ( fwdptr != ptr) {
    *Passptr=fwdptr;
    return number;
  } else {
    // Failed to match number.
    printf("Unexpected value %s\n",ptr);
    return 0;
  }
}


int main(int argc, char *argv[])
{
  int opt;
  if ( argc < 2) {
    printf("Usage: %s filename\n", argv[0]);
    return(1);
  }
  DebugRange1=0x10000;
  DebugRange2=0x10000;


  while ((opt = getopt(argc, argv, "hd:e:")) != -1)
{
    switch (opt) {
       case 'd':
          DebugRange1=GetNextWord(&optarg);
          break;
       case 'e':
          DebugRange2=GetNextWord(&optarg);
          break;
       case 'h':
       case '?':
          printf("Put help here\n");
          exit(0);
    }
}
  if ( optind < argc) {
    if (FileRead(argv[optind]) == 0)
      if (doeval(Entry) == 0) {
	printf("END(%llu) Ops\n",OptCount);
      }
  } else {
  printf("Usage [-h] [-d addr] [-e addr] filename\n");
  }
}

   
