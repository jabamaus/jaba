#include "ruby/ruby.h"
#include "ruby/encoding.h"

/* loadpath.c */
const char ruby_exec_prefix[] = "";
const char ruby_initial_load_paths[] = "";

/* localeinit.c */
VALUE
rb_locale_charmap(VALUE klass)
{
	/* never used */
	return Qnil;
}

int
rb_locale_charmap_index(void)
{
	return -1;
}

int
Init_enc_set_filesystem_encoding(void)
{
	return rb_enc_to_index(rb_default_external_encoding());
}

void rb_encdb_declare(const char* name);
int rb_encdb_alias(const char* alias, const char* orig);
void
Init_enc(void)
{
	rb_encdb_declare("ASCII-8BIT");
	rb_encdb_declare("US-ASCII");
	rb_encdb_declare("UTF-8");
	rb_encdb_alias("BINARY", "ASCII-8BIT");
	rb_encdb_alias("ASCII", "US-ASCII");
}

void
Init_ext(void)
{
	// TODO: remove absolute path
	ruby_incpush_expand("C:/projects/GitHub/jaba/lib/ruby_stdlib");
  // fool ruby that requireed .so files are loaded when in fact they are statically linked
	rb_provide("digest.so");
	rb_provide("digest/sha1.so");
	rb_provide("json/ext/generator.so");
	rb_provide("json/ext/parser.so");
	Init_digest();
	Init_sha1();
	Init_parser(); // json parser
	Init_generator(); // json generator
}

#include "mini_builtin.c"
