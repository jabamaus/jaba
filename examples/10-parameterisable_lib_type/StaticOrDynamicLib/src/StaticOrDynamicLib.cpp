#include "StaticOrDynamicLib/StaticOrDynamicLib.h"

char* static_or_dynamic_lib_func()
{
#ifdef SODL_STATIC
  return "Static build";
#else
  return "Dynamic build";
#endif
}
