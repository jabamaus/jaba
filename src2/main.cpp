#if 0
#include "vld.h"
#endif
#include <stdexcept>
#include "jaba/ireps.h"
#include "jrfjaba/ireps.h"
#include "jrfcore/mrb_state.h"
#include "mrubygems.h"

void run(MrbState& mrb)
{
  mrubygems_init(mrb);
  jrfjaba::register_ireps(mrb);
  jaba::register_ireps(mrb);
  mrb.run(src2_jaba_symbol);
  mrubygems_term(mrb);
  mrb.term();
}

int main(int argc, char* argv[])
{
  MrbState mrb;
  return mrb.execute(&run, argc, argv);
}