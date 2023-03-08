#if 0
#include "vld.h"
#endif
#include <stdexcept>
#include "ireps.h"
#include "mrubyjrf/mrb_state.h"
#include "mrubygems.h"

extern "C" const uint8_t jrf_core_ext_symbol[];

int run(int argc, char* argv[])
{
  MrbState& mrb = MrbState::instance();
  mrb.open();
  mrubygems_init(mrb.raw());
  mrb.run(argc, argv, src2_jaba_symbol, jrf_core_ext_symbol);
  mrubygems_term(mrb.raw());
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