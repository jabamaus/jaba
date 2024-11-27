#pragma once
#include <string>

struct Jaba;

Jaba* jaba_init(const char* src_root);
void jaba_term(Jaba* j);
void jaba_run(Jaba* j);
void* jaba_alloc(Jaba* j, size_t nbytes);
void jaba_fail(Jaba* j, std::string_view msg);
