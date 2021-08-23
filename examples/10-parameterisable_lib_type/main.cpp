#include <stdio.h>
#include "StaticOrDynamicLib/StaticOrDynamicLib.h"

int main(int argc, const char* argv[])
{
  printf(static_or_dynamic_lib_func());
  return 0;
}
