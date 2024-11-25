#include "jrfcore/mrbstate.h"
#include "catch_amalgamated.hpp"

bool cmd_specified(MrbState& mrb, mrb_value clm, const char* cmd)
{
  return mrb_true_p(mrb.funcall(clm, MRB_SYM_Q(cmd_specified), mrb.to_value(mrb.sym(cmd))));
}

int run(int argc, char* argv[])
{
  MrbState mrb;
  mrb.init(argc, argv, MRubyService::ARGV | MRubyService::CoreExt | MRubyService::RequireRelative);
  mrb.define_constant("JABA_VERSION", mrb.to_value("0.1-alpha"));
  mrb.load_irep("C:/james_projects/GitHub/jrf/jrf/utils/cmdline.rb");
  mrb_value cmd_vars = mrb.obj_new(MRB_SYM(Object));
  mrb_value clm = mrb.obj_new(MRB_SYM(CmdlineManager), cmd_vars, mrb.to_value("Jaba"));
  mrb.load_irep("C:/james_projects/GitHub/jaba/src/cmdline_args.rb", clm);
  mrb.funcall(clm, MRB_SYM(process));
  mrb.funcall(clm, MRB_SYM(finalise));
  if (mrb.iv_get_b(cmd_vars, mrb.sym("@show_help")))
  {
    mrb.funcall(clm, mrb.sym("show_help"));
  }
  else if (cmd_specified(mrb, clm, "gen"))
  {

  }
  else if (cmd_specified(mrb, clm, "test"))
  {
    // TODO: Pass through args from cmdline manager
    const char* argv_[] = { argv[0], "--reporter", "compact" };
    int argc_ = sizeof(argv_) / sizeof(argv_[0]);
    int result = Catch::Session().run(argc_, argv_);
    return result;
  }
  return 0;
}

int main(int argc, char* argv[])
{
  try
  {
    run(argc, argv);
  }
  catch (std::exception& e)
  {
    fprintf(stderr, "%s", e.what());
    return 1;
  }
  return 0;
} 
