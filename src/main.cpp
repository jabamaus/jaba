#include "jrfcore/console_app.h"
#include "jdl_builder.h"

struct Jaba : public ConsoleApp
{
  void main() override
  {
    mrb.load_irep("C:/james_projects/GitHub/jrf/jrf/utils/cmdline.rb");
    build_jdl(mrb);
  }
};

int main(int argc, char* argv[])
{
  Jaba app;
  return app.run(argc, argv, MRubyService::None);
} 
