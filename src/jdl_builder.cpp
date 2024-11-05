#include <format>
#include "jdl_builder.h"

struct JabaDef
{
  std::string title;
  std::string notes;
  std::string examples;
};

struct FlagOptionDef : public JabaDef
{
  bool transient;
};

struct AttributeBaseDef : public JabaDef
{

};

struct AttributeSingleDef : public AttributeBaseDef
{

};

struct AttributeArrayDef : public AttributeBaseDef
{

};

struct AttributeHashDef : public AttributeBaseDef
{

};

struct AttributeGroupDef : public JabaDef
{
  RClass* api_class;
};

struct NodeDef : public JabaDef
{

};

struct MethodDef : public JabaDef
{
  mrb_value on_called;
};

struct JDLBuilder
{
  MrbState* mrb;
  mrb_sym variant_sym;
  mrb_value attr_def_api_obj;
  mrb_value node_def_api_obj;
  mrb_value flag_option_def_api_obj;
  mrb_value method_def_api_obj;
};

enum class JDLDefType
{
  GlobalMethod,
  Method,
  Node,
  Attr
};

JDLBuilder jdlb;

static void register_jdl_def(JDLDefType type)
{
  MrbState& mrb = *jdlb.mrb;

  if (type == JDLDefType::Attr)
  {
    mrb.expect_kwarg(MRB_SYM(type));
    mrb.expect_kwarg(jdlb.variant_sym);
  }
  mrb.args_begin();
  mrb_value block;
  mrb.pop_block(block);

  std::string_view name = mrb.pop_string();

  if (type == JDLDefType::Attr)
  {
    std::string_view type = mrb.pop_string(MRB_SYM(type));
    std::string_view variant = mrb.pop_string(jdlb.variant_sym, false, "single");
  }
  mrb.args_end();

  switch (type)
  {
  case JDLDefType::GlobalMethod:
  {
    mrb.instance_eval(jdlb.method_def_api_obj, 0, 0, block);
  }
  break;
  case JDLDefType::Method:
    break;
  case JDLDefType::Attr:
  {
  }
  break;
  case JDLDefType::Node:
    break;
  default:
    IO::error("Unhandled JDLDefType");
  }
}

static mrb_value jdl_global_method(mrb_state*, mrb_value self)
{
  register_jdl_def(JDLDefType::GlobalMethod);
  return self;
}

static mrb_value jdl_method(mrb_state*, mrb_value self)
{
  register_jdl_def(JDLDefType::Method);
  return self;
}

static mrb_value jdl_node(mrb_state*, mrb_value self)
{
  register_jdl_def(JDLDefType::Node);
  return self;
}

static mrb_value jdl_attr(mrb_state*, mrb_value self)
{
  register_jdl_def(JDLDefType::Attr);
  return self;
}

static mrb_value jdl_title(mrb_state*, mrb_value self)
{
  MrbState& mrb = *jdlb.mrb;
  mrb.args_begin();
  std::string_view title = mrb.pop_string();
  mrb.args_end();
  return self;
}

static mrb_value jdl_note(mrb_state*, mrb_value self)
{
  MrbState& mrb = *jdlb.mrb;
  mrb.args_begin();
  std::string_view note = mrb.pop_string();
  mrb.args_end();
  return self;
}

static mrb_value jdl_example(mrb_state*, mrb_value self)
{
  MrbState& mrb = *jdlb.mrb;
  mrb.args_begin();
  std::string_view example = mrb.pop_string();
  mrb.args_end();
  return self;
}

static mrb_value jdl_transient(mrb_state*, mrb_value self)
{
  MrbState& mrb = *jdlb.mrb;
  mrb.args_begin();
  bool transient = mrb.pop_bool();
  mrb.args_end();
  return self;
}

static mrb_value jdl_on_called(mrb_state*, mrb_value self)
{
  MrbState& mrb = *jdlb.mrb;
  mrb.args_begin();
  mrb_value block;
  mrb.pop_block(block);
  mrb.args_end();
  return self;
}

static void load_jdl(const char* name)
{
  MrbState& mrb = *jdlb.mrb;
  IrepData* irep = IRepRegistry::instance().lookup_irep(std::format("C:/james_projects/GitHub/jaba/src/jdl/{}.rb", name));
  mrb.load_irep(irep);
}

mrb_value create_api_obj(JDLBuilder& jdlb, const char* classname, std::initializer_list<const char*> methods)
{
  MrbState& mrb = *jdlb.mrb;
  RClass* cls = mrb.define_class(classname);
}

void build_jdl(MrbState& mrb)
{
  jdlb.mrb = &mrb;
  jdlb.variant_sym = mrb_intern_lit(mrb.mrb, "variant");

  RClass* jdl = mrb.define_module("JDL");
  mrb.define_module_method(jdl, "global_method", jdl_global_method);
  mrb.define_module_method(jdl, "method", jdl_method);
  mrb.define_module_method(jdl, "attr", jdl_attr);
  mrb.define_module_method(jdl, "node", jdl_node);

  RClass* jdl_def = mrb.define_class("JDLDef");
  mrb.define_method("title", jdl_title, jdl_def);
  mrb.define_method("note", jdl_note, jdl_def);
  mrb.define_method("example", jdl_example, jdl_def);

  RClass* flag_option_def = mrb.define_class("FlagOptionDef", jdl_def);
  mrb.define_method("transient", jdl_transient, flag_option_def);
  jdlb.flag_option_def_api_obj = mrb_obj_new(mrb.mrb, flag_option_def, 0, 0);

  RClass* method_def = mrb.define_class("MethodDef", jdl_def);
  mrb.define_method("on_called", jdl_on_called, method_def);
  jdlb.method_def_api_obj = mrb_obj_new(mrb.mrb, method_def, 0, 0);

  RClass* attr_def = mrb.define_class("AttributeDef", jdl_def);
  jdlb.attr_def_api_obj = mrb_obj_new(mrb.mrb, method_def, 0, 0);
  
  load_jdl("core");
  load_jdl("target");
}
