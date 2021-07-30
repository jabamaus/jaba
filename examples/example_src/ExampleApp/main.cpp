#include <stdio.h>
#ifdef WITH_EXAMPLE_LIB
#include "ExampleLib/ExampleLib.h"
#endif
#ifdef WITH_EXAMPLE_DLL
#include "ExampleDll/ExampleDll.h"
#endif
#ifdef WITH_3RDPARTY_LIB
#include "3rdPartyLib/3rdPartyLib.h"
#endif

int main(int argc, const char* argv[])
{
  printf("Hello world\n");
#ifdef WITH_EXAMPLE_LIB
  printf("example_lib_func() says \"%s\"\n", example_lib_func());
#endif
#ifdef WITH_EXAMPLE_DLL
  printf("example_dll_func() says \"%s\"\n", example_dll_func());
#endif
#ifdef WITH_3RDPARTY_LIB
  printf("third_party_lib_func() says \"%s\"\n", third_party_lib_func());
#endif
  return 0;
}
