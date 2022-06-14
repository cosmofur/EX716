n=8,t=65,s,f,x,y,p,e,u=10,w=32,z=95;                 // 8,10 height and width of board. w=ASCII space, also difference between ucase and lcase
                                                     // 95 is bitmask for conversion lowercase to uppercase, but also used as length of array, etc.
char a[95],b[95]="RNBKQBNR";                         // a is main board, b is backup board (but used at start to hold 1st row data.)
 
v(){                                                 // validate move in all aspects except check
  p=a[s]&z;                                          // p=uppercase(character on start square)
  y=f/u-s/u;                                         // signed distance in y direction
  x=f-s-y*u;                                         // and x direction
  e=x*x+y*y;                                         // square of Euclidean distance
  n=s%u/8|f%u/8|                                     // n=true if 2nd digit of input out of bounds OR
  a[s]/w-t/w|a[f]/w==t/w|                            // start sq not friendly piece OR finish sq is friendly piece (also eliminates case where start=finish)
  !(                                                 // OR NOT geometry valid
    p==75&e<3|                                       // 'K'(ASCII75) AND euclidean distance squared =1 or 2 OR
    p>80&x*y==0|                                     // 'Q'or'R' AND x or y = 0 OR
    p%5==1&x*x==y*y|                                 // 'Q'or'B' AND abs(x)=abs(y)
    p==78&e==5|                                      // 'N' AND euclidean distance squared = 5
    p==80&x*(z-t)>0&(a[f]-w?e==2:e==1|e==4&s%5==1)   // 'P'(ASCII80):x direction must correspond with case of player (z-t)
  );                                                 // if capturing e=2. Otherwise e=1 (except on start rows 1 and 6, e can be 4)
  if(!n&&p-78)                                       // if not yet invalid and piece not 'N'(ASCII78) 
    for(e=(f-s)/abs(x*x>y*y?x:y),x=s;(x+=e)-f;)      // Set e to the numeric difference to travel 1 square in right direction. Set x to start square
       n|=a[x]-w;                                    // and iterate x through all intervening squares, checking they are blank
}



main(){

  for(a[93]=40;n--;a[92]=47)                         // iterate n through 8 rows of board. vacant spaces in bracket are use to assign start positions of kings to a[92&93] 
    sprintf(a,"%s%cP    p%c \n",a,b[n],b[n]+w);      // build up start position, each row 10 squares wide, including filler space the end and newline
  
  for(;1;){                                          // loop forever   
    puts(a);                                         // display board
    for(n=1;n;){                                     // loop while move invalid
      putchar(t);                                    // display prompt 'A' for white 'a' for black
      scanf("%d%d",&s,&f);                           // get input
      v();                                           // validate move
      memcpy(b,a,z);                                 // backup board (and king position metadata)  
      if(!n){                                        // if move not yet invalid
        a[f]=p-80|f%u%7?a[s]:t+16;                   // if not a pawn on last row, content of finish square = start square, ELSE queen of correct case (t+16) 
        a[s]=w;                                      // start square becomes blank (ASCII32)
        a[f]&z^75||(a[z-t/w]=f);                     // if finish square king, update king position metadata
        f=a[z-t/w];                                  // to begin scanning to see if king in check, set f to current king position
        t^=w;                                        // and change colour
        for(n=1,s=80;n&&s--;)v();                    // for s=79..0 search for valid opponent move to capture king (stops with n=0)
        if(n=!n)memcpy(a,b,z),t^=32;                 // valid opponent threat on king means invalid player move. Invert n, recover board from backup and change colour back.
      }
    }    
  }
}
