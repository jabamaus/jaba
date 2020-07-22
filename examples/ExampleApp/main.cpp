#include <stdio.h>
#ifdef WITH_BASIC_LIB
#include "ExampleLib1/ExampleLib1.h"
#endif

int main(int argc, const char* argv[])
{
  printf("Hello world\n");
#ifdef WITH_BASIC_LIB
  printf("examplelib1_func() returned %d\n", examplelib1_func());
#endif
  return 0;
}
