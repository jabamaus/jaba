#include "jrfcore/console_app.h"

struct Jaba : public ConsoleApp
{
  void main() override;
};

static mrb_value jdl_global_method(mrb_state*, mrb_value self)
{
  //app->mrb.args_begin();

  //app->mrb.args_end();
  return self;
}

static mrb_value jdl_method(mrb_state*, mrb_value self)
{
  //app->mrb.args_begin();

  //app->mrb.args_end();
  return self;
}

static mrb_value jdl_attr(mrb_state*, mrb_value self)
{
  //app->mrb.args_begin();

  //app->mrb.args_end();
  return self;
}

static mrb_value jdl_node(mrb_state*, mrb_value self)
{
  //app->mrb.args_begin();

  //app->mrb.args_end();
  return self;
}

void Jaba::main()
{
  RClass* rm = mrb.define_module("JDL");
  mrb.define_module_method(rm, "global_method", jdl_global_method, MRB_ARGS_REQ(1));
  mrb.define_module_method(rm, "method", jdl_method, MRB_ARGS_REQ(1));
  mrb.define_module_method(rm, "attr", jdl_attr, MRB_ARGS_REQ(1));
  mrb.define_module_method(rm, "node", jdl_node, MRB_ARGS_REQ(1));

  IrepData* jdl_core = IRepRegistry::instance().lookup_irep("C:/james_projects/GitHub/jaba/src/jdl/core.rb");
  mrb.load_irep(jdl_core);
}

int main(int argc, char* argv[])
{
  Jaba app;
  return app.run(argc, argv);
} 
