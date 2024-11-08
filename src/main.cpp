#include "jrfcore/console_app.h"

extern "C" const uint8_t jaba_irep[];

int main(int argc, char* argv[])
{
  ConsoleApp app;
  return app.run(argc, argv, MRubyService::All, jaba_irep);
}
