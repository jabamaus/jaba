#include <stdio.h>
#include "BasicStaticLib/BasicStaticLib.h"
#include "BasicDynamicLib/BasicDynamicLib.h"
#include "ThirdPartyLib/ThirdPartyLib.h"

int main(int argc, const char* argv[])
{
  printf("basic_static_lib_func() says \"%s\"\n", basic_static_lib_func());
  printf("basic_dynamic_lib_func() says \"%s\"\n", basic_dynamic_lib_func());
  printf("third_party_lib_func() says \"%s\"\n", third_party_lib_func());
  return 0;
}
