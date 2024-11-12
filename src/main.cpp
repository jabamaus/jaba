#include "jrfcore/console_app.h"
#include "jdl_builder.h"

struct Jaba : public ConsoleApp
{
  MrbState mrb_jdl;

  void main() override
  {
    mrb.load_irep("C:/james_projects/GitHub/jrf/jrf/utils/cmdline.rb");
    mrb_value cmd_vars = mrb.obj_new(MRB_SYM(Object));
    mrb_value clm = mrb.obj_new("CmdlineManager", cmd_vars, mrb.string_value("Jaba"));
    mrb.load_irep("C:/james_projects/GitHub/jaba/src/cmdline_args.rb", clm);
    mrb.funcall(clm, MRB_SYM(process));
    mrb.funcall(clm, MRB_SYM(finalise));
    build_jdl(mrb_jdl);
  }
};

int main(int argc, char* argv[])
{
  Jaba app;
  return app.run(argc, argv, MRubyService::ARGV | MRubyService::Regexp | MRubyService::RequireRelative);
} 
