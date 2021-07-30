void
Init_ext(void)
{
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
