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

// Cut and paste of static function from ruby.c....
static VALUE
runtime_libruby_path(void)
{
#if defined _WIN32 || defined __CYGWIN__
	DWORD len = RSTRING_EMBED_LEN_MAX, ret;
	VALUE path;
	VALUE wsopath = rb_str_new(0, len * sizeof(WCHAR));
	WCHAR* wlibpath;
	char* libpath;

	while (wlibpath = (WCHAR*)RSTRING_PTR(wsopath),
		ret = GetModuleFileNameW(rb_libruby_handle(), wlibpath, len),
		(ret == len))
	{
		rb_str_modify_expand(wsopath, len * sizeof(WCHAR));
		rb_str_set_len(wsopath, (len += len) * sizeof(WCHAR));
	}
	if (!ret || ret > len) rb_fatal("failed to get module file name");
#if defined __CYGWIN__
	{
		const int win_to_posix = CCP_WIN_W_TO_POSIX | CCP_RELATIVE;
		size_t newsize = cygwin_conv_path(win_to_posix, wlibpath, 0, 0);
		if (!newsize) rb_fatal("failed to convert module path to cygwin");
		path = rb_str_new(0, newsize);
		libpath = RSTRING_PTR(path);
		if (cygwin_conv_path(win_to_posix, wlibpath, libpath, newsize)) {
			rb_str_resize(path, 0);
		}
	}
#else
	{
		DWORD i;
		for (len = ret, i = 0; i < len; ++i) {
			if (wlibpath[i] == L'\\') {
				wlibpath[i] = L'/';
				ret = i + 1;	/* chop after the last separator */
			}
		}
	}
	len = WideCharToMultiByte(CP_UTF8, 0, wlibpath, ret, NULL, 0, NULL, NULL);
	path = rb_utf8_str_new(0, len);
	libpath = RSTRING_PTR(path);
	WideCharToMultiByte(CP_UTF8, 0, wlibpath, ret, libpath, len, NULL, NULL);
#endif
	rb_str_resize(wsopath, 0);
	return path;
#elif defined(HAVE_DLADDR)
	Dl_info dli;
	VALUE fname, path;
	const void* addr = (void*)(VALUE)expand_include_path;

	if (!dladdr((void*)addr, &dli)) {
		return rb_str_new(0, 0);
	}
#ifdef __linux__
	else if (origarg.argc > 0 && origarg.argv && dli.dli_fname == origarg.argv[0]) {
		fname = rb_str_new_cstr("/proc/self/exe");
		path = rb_readlink(fname, NULL);
	}
#endif
	else {
		fname = rb_str_new_cstr(dli.dli_fname);
		path = rb_realpath_internal(Qnil, fname, 1);
	}
	rb_str_resize(fname, 0);
	return path;
#else
# error relative load path is not supported on this platform.
#endif
}

void
Init_ext(void)
{
	// 
	char* libpath;
	VALUE sopath;
	sopath = runtime_libruby_path();
	libpath = RSTRING_PTR(sopath);
	char ruby_stdlib_path[1024];
	strcpy(ruby_stdlib_path, libpath);
#ifdef _DEBUG
	strcat(ruby_stdlib_path, "../../../../../../lib/ruby_stdlib");
#else
	strcat(ruby_stdlib_path, "../lib/ruby_stdlib");
#endif

	ruby_incpush(ruby_stdlib_path);

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
