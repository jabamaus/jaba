#include "jrf/core/public/console_app.h"
#include "mimalloc-new-delete.h"

extern const uint8_t jaba_jaba_irep[];

int main(int argc, char* argv[])
{
  ConsoleApp app;
  return app.run(argc, argv, MRubyService::All, jaba_jaba_irep);
}
