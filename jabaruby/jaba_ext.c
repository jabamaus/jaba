void
Init_ext(void)
{
	rb_provide("digest.so");
	Init_digest();
	Init_sha1();
}
