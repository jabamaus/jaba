#if 0
#include "vld.h"
#endif
#include <stdexcept>
#include "ireps.h"
#include "mrubyjrf/mrb_state.h"

extern "C" void mrb_mruby_onig_regexp_gem_init(mrb_state*);
extern "C" void mrb_mruby_stringio_gem_init(mrb_state*);
extern "C" const uint8_t jrf_core_ext_symbol[];

int run(int argc, char* argv[])
{
  MrbState& mrb = MrbState::instance();
  mrb.open(argc, argv);
  mrb_mruby_onig_regexp_gem_init(mrb.raw()); // TODO: make this nicer
  mrb_mruby_stringio_gem_init(mrb.raw());
  mrb.init(src2_jaba_symbol, jrf_core_ext_symbol);
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
    fprintf(stderr, "%s\n", e.what());
    return EXIT_FAILURE;
  }
}