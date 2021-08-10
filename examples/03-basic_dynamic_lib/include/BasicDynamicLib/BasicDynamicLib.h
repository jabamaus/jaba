#pragma once

#ifdef DLL_EXPORT
# define BDL_API __declspec(dllexport)
#else
# define BDL_API __declspec(dllimport)
#endif

BDL_API char* basic_dynamic_lib_func();
