#if 0
#include "vld.h"
#endif
#include <stdexcept>
#include "ireps.h"
#include "mrubyjrf/mrb_state.h"

extern "C" void mrb_mruby_dir_glob_gem_init(mrb_state * mrb);
extern "C" void mrb_mruby_fileutils_gem_init(mrb_state*);
extern "C" void mrb_mruby_onig_regexp_gem_init(mrb_state*);
extern "C" void mrb_mruby_stringio_gem_init(mrb_state*);
extern "C" const uint8_t jrf_core_ext_symbol[];

int run(int argc, char* argv[])
{
  MrbState& mrb = MrbState::instance();
  mrb.open();
  mrb_mruby_dir_glob_gem_init(mrb.raw());
  mrb_mruby_fileutils_gem_init(mrb.raw());
  mrb_mruby_onig_regexp_gem_init(mrb.raw()); // TODO: move into mrubygems lib
  mrb_mruby_stringio_gem_init(mrb.raw());
  mrb.run(argc, argv, src2_jaba_symbol, jrf_core_ext_symbol);
  mrb.term();
  return EXIT_SUCCESS;
}

int main(int argc, char* argv[])
{
  try
  {
    return run(argc, argv);
  }
  catch (std::exception& e)
  {
    fprintf(stderr, "%s", e.what());
    return EXIT_FAILURE;
  }
}