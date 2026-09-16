#include "../firmware/input_tool/InputProtocol.h"
#include <assert.h>
#include <stdio.h>
int main() {
  InputRecord absolute[] = {{1,0,'h',0,0},{16,0,0,255,127},{17,0,0,255,127},{17,255,127,0,0},{16,255,127,0,0},{24,255,0,0,0},{3,100,0,0,0}};
  assert(validateInput(absolute,7));
  assert(!validateInput(absolute,0));
  assert(!validateInput(absolute,4));
  absolute[3].b=128; assert(!validateInput(absolute,7)); absolute[3].b=127;
  absolute[3]={2,0,0,0,0}; assert(!validateInput(absolute,7));
  absolute[3]={3,1,0,0,0}; assert(!validateInput(absolute,7));
  absolute[3]={17,255,127,0,0}; absolute[5].a=128; assert(!validateInput(absolute,7));
  absolute[5].a=1; absolute[6]={3,255,255,0,0}; assert(!validateInput(absolute,7));
  puts("Absolute input validation passed.");
}
