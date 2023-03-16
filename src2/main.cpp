#if 0
#include "vld.h"
#endif
#include <stdexcept>
#include "jaba/ireps.h"
#include "jrfjaba/ireps.h"
#include "mrubyjrf/mrb_state.h"
#include "mrubygems.h"

extern "C" const uint8_t jrfutils_core_ext_symbol[];

int run(int argc, char* argv[])
{
  MrbState mrb;
  mrubygems_init(mrb);
  jrfjaba::register_ireps(mrb);
  jaba::register_ireps(mrb);
  mrb.run(argc, argv, src2_jaba_symbol, jrfutils_core_ext_symbol);
  mrubygems_term(mrb);
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