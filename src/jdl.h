#pragma once

struct JDL;

JDL* jdl_init();
void jdl_term(JDL* j);
bool jdl_load_built_in_file(JDL* j, const char* name);
bool jdl_load_file_dynamically(JDL* j, std::string_view filepath);
std::string_view jdl_errfile(JDL* j);
int jdl_errline(JDL* j);
std::string_view jdl_errmsg(JDL* j);
