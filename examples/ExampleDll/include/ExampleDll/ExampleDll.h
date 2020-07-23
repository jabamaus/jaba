#pragma once

#ifdef DLL_EXPORT
# define ED_API __declspec(dllexport)
#else
# define ED_API __declspec(dllimport)
#endif

ED_API char* example_dll_func();
