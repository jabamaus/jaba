#pragma once

#ifdef SODL_STATIC
# define SODLAPI
#elif DLL_EXPORT
# define SODLAPI __declspec(dllexport)
#else
# define SODLAPI __declspec(dllimport)
#endif

SODLAPI char* static_or_dynamic_lib_func();
