int main()
{
  int a[10],i,j;
  i=0;
  while ( i < 22 ) {
    print("Old ",a[i]);
    a[i] = i*2;
    print("New ",a[i]);
    print("I = ",i);
    i = i + 1;
  }
  i=0;
  while ( i < 22 ) {
    print("Still ",a[i]);
    print("I = ",i);
    i = i + 1;
  }  
  

  return 1;
}

