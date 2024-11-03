#include "jrfcore/console_app.h"
#include <format>

enum class JDLDefType
{
  GlobalMethod,
  Method,
  Node,
  Attr
};

struct Jaba : public ConsoleApp
{
  void main() override;
  void register_jdl_def(JDLDefType type);
  void load_jdl(const char* name);

  mrb_sym type_sym;
  mrb_sym variant_sym;
};

Jaba app;

struct JabaDef
{
  std::string title;
};

static mrb_value jdl_global_method(mrb_state*, mrb_value self)
{
  app.register_jdl_def(JDLDefType::GlobalMethod);
  return self;
}

static mrb_value jdl_method(mrb_state*, mrb_value self)
{
  app.register_jdl_def(JDLDefType::Method);
  return self;
}

static mrb_value jdl_node(mrb_state*, mrb_value self)
{
  app.register_jdl_def(JDLDefType::Node);
  return self;
}

static mrb_value jdl_attr(mrb_state*, mrb_value self)
{
  app.register_jdl_def(JDLDefType::Attr);
  return self;
}

static mrb_value jdldef_title(mrb_state*, mrb_value self)
{
  MrbState& mrb = app.mrb;
  mrb.args_begin();
  std::string_view title = mrb.pop_string();
  mrb.args_end();
  return self;
}

void Jaba::main()
{
  // Make symbols for all keyword args
  type_sym = mrb.make_symbol("type");
  variant_sym = mrb.make_symbol("variant");
  
  RClass* jdl = mrb.define_module("JDL");
  mrb.define_module_method(jdl, "global_method", jdl_global_method);
  mrb.define_module_method(jdl, "method", jdl_method);
  mrb.define_module_method(jdl, "attr", jdl_attr);
  mrb.define_module_method(jdl, "node", jdl_node);

  RClass* jdldef = mrb.define_class("JDLDef");
  mrb.define_method("title", jdldef_title, jdldef);

  load_jdl("core");
  load_jdl("target");
}

void Jaba::load_jdl(const char* name)
{
  IrepData* irep = IRepRegistry::instance().lookup_irep(std::format("C:/james_projects/GitHub/jaba/src/jdl/{}.rb", name));
  mrb.load_irep(irep);
}

void Jaba::register_jdl_def(JDLDefType type)
{
  switch (type)
  {
  case JDLDefType::Attr:
    mrb.expect_kwarg(type_sym);
    mrb.expect_kwarg(variant_sym);
    break;
  }
  mrb.args_begin();
  std::string_view name = mrb.pop_string();

  switch (type)
  {
  case JDLDefType::Attr:
    std::string_view type = mrb.pop_string(type_sym);
    std::string_view variant = mrb.pop_string(variant_sym, false, "single");
    break;
  }
  mrb.args_end();
}

int main(int argc, char* argv[])
{
  return app.run(argc, argv);
} 
