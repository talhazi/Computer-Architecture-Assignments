#include <stdio.h>
#define	MAX_LEN 34			/* maximal input string size */
					/* enough to get 32-bit string + '\n' + null terminator */
extern void assFunc(int x);

char c_checkValidity(int x){
  return (x%2 != 0);
}

int main(int argc, char** argv){
  int x;
  char y[MAX_LEN];
  fgets(y,MAX_LEN,stdin);		/* get user input string */ 
  sscanf(y, "%d", &x);
  assFunc(x);		              /* call your assembly function */
  return 0;
}

