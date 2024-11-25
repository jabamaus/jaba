#pragma once

struct JDLBuilder;

JDLBuilder* init_jdl_builder();
void term_jdl_builder(JDLBuilder* b);
bool load_built_in_jdl_file(JDLBuilder* b, const char* name);
bool load_jdl_file_dynamically(JDLBuilder* b, std::string_view filepath);
int jdl_errline(JDLBuilder* b);
std::string_view jdl_errmsg(JDLBuilder* b);
