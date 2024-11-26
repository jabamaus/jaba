#include <format>
#include <regex>
#include "jrfcore/mrbstate.h"
#include "jdl.h"

struct JDLDef
{
  const char* file;
  int line;
  std::string title;
  std::string notes;
  std::string examples;
};

struct FlagOptionDef : public JDLDef
{
  bool transient;
};

struct AttributeBaseDef : public JDLDef
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

struct MethodDef;
struct NodeDef;

struct GlobalMethodsDef : public JDLDef
{
  std::vector<MethodDef*> method_defs;
};

struct AttributeGroupDef : public JDLDef
{
  RClass* api_class;
  NodeDef* parent_node_def;
  std::vector<AttributeBaseDef*> attr_defs;
  std::vector<AttributeBaseDef*> option_attr_defs;
  std::vector<MethodDef*> method_defs;
};

struct NodeDef : public JDLDef
{

};

struct MethodDef : public JDLDef
{
  mrb_value on_called;
};

struct JDL
{
  MrbState mrb;
  mrb_value attr_def_api_obj;
  mrb_value node_def_api_obj;
  mrb_value flag_option_def_api_obj;
  mrb_value method_def_api_obj;

  MrbState tmrb;
  RClass* base_api;
  RClass* top_level_api;
  RClass* common_attrs_module;
  RClass* common_methods_module;
  RClass* global_methods_module;

  const char* errfile;
  int errline = -1;
  std::string errmsg;
};

enum class JDLType
{
  GlobalMethod,
  Method,
  Node,
  Attr
};

template <typename... Args>
void jdl_fail(JDL* j, std::format_string<Args...> fmt, Args&&... args)
{
  MrbState& mrb = j->mrb;
  mrb.caller_location(&j->errfile, &j->errline);
  j->errmsg = std::format(fmt, args...);
  throw std::runtime_error(j->errmsg);
}

static const std::regex path_regex1(R"(^(\*\/)?([a-zA-Z0-9]+_?\/?)+$)");
static const std::regex path_regex2(R"([a-zA-Z0-9]$)");

static void jdl_register_def(JDL* j, JDLType type)
{
  MrbState& mrb = j->mrb;

  if (type == JDLType::Attr)
  {
    mrb.expect_kwarg(MRB_SYM(type));
    mrb.expect_kwarg(MRB_SYM(variant));
  }
  mrb.args_begin();
  mrb_value block;
  mrb.pop_block(block, false); // block is optional

  std::string_view name = mrb.pop_string();

  if (!std::regex_match(name.data(), path_regex1) ||
      !std::regex_match(name.data(), path_regex2))
  {
    jdl_fail(j, "'{}' is in invalid format", name);
  }

  if (type == JDLType::Attr)
  {
    std::string_view type = mrb.pop_string(MRB_SYM(type));
    std::string_view variant = mrb.pop_string(MRB_SYM(variant), false, "single");
  }
  mrb.args_end();

  switch (type)
  {
  case JDLType::GlobalMethod:
  {
    mrb.instance_eval(j->method_def_api_obj, 0, 0, block);
  }
  break;
  case JDLType::Method:
    break;
  case JDLType::Attr:
  {
  }
  break;
  case JDLType::Node:
    break;
  default:
    IO::error("Unhandled JDLDefType");
  }
}

static mrb_value jdl_global_method(mrb_state* mrb_, mrb_value self)
{
  JDL* j = (JDL*)((MrbState*)mrb_->ud)->user_data();
  jdl_register_def(j, JDLType::GlobalMethod);
  return self;
}

static mrb_value jdl_method(mrb_state* mrb_, mrb_value self)
{
  JDL* j = (JDL*)((MrbState*)mrb_->ud)->user_data();
  jdl_register_def(j, JDLType::Method);
  return self;
}

static mrb_value jdl_node(mrb_state* mrb_, mrb_value self)
{
  JDL* j = (JDL*)((MrbState*)mrb_->ud)->user_data();
  jdl_register_def(j, JDLType::Node);
  return self;
}

static mrb_value jdl_attr(mrb_state* mrb_, mrb_value self)
{
  JDL* j = (JDL*)((MrbState*)mrb_->ud)->user_data();
  jdl_register_def(j, JDLType::Attr);
  return self;
}

static mrb_value jdl_title(mrb_state* mrb_, mrb_value self)
{
  JDL* j = (JDL*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = j->mrb;
  mrb.args_begin();
  std::string_view title = mrb.pop_string();
  mrb.args_end();
  return self;
}

static mrb_value jdl_note(mrb_state* mrb_, mrb_value self)
{
  JDL* j = (JDL*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = j->mrb;
  mrb.args_begin();
  std::string_view note = mrb.pop_string();
  mrb.args_end();
  return self;
}

static mrb_value jdl_example(mrb_state* mrb_, mrb_value self)
{
  JDL* j = (JDL*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = j->mrb;
  mrb.args_begin();
  std::string_view example = mrb.pop_string();
  mrb.args_end();
  return self;
}

static mrb_value jdl_transient(mrb_state* mrb_, mrb_value self)
{
  JDL* j = (JDL*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = j->mrb;
  mrb.args_begin();
  bool transient = mrb.pop_bool();
  mrb.args_end();
  return self;
}

static mrb_value jdl_on_called(mrb_state* mrb_, mrb_value self)
{
  JDL* j = (JDL*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = j->mrb;
  mrb.args_begin();
  mrb_value block;
  mrb.pop_block(block);
  mrb.args_end();
  return self;
}

JDL* jdl_init()
{
  JDL* j = new JDL;
  MrbState& mrb = j->mrb;
  mrb.init();
  mrb.set_user_data(j);

  RClass* jdl = mrb.define_module(MRB_SYM(JDL));
  mrb.define_module_method(MRB_SYM(global_method), jdl_global_method, jdl);
  mrb.define_module_method(MRB_SYM(method), jdl_method, jdl);
  mrb.define_module_method(MRB_SYM(attr), jdl_attr, jdl);
  mrb.define_module_method(MRB_SYM(node), jdl_node, jdl);

  RClass* jdl_def = mrb.define_class(MRB_SYM(JDLDef));
  mrb.define_method(MRB_SYM(title), jdl_title, jdl_def);
  mrb.define_method(MRB_SYM(note), jdl_note, jdl_def);
  mrb.define_method(MRB_SYM(example), jdl_example, jdl_def);

  RClass* flag_option_def = mrb.define_class(MRB_SYM(FlagOptionDef), jdl_def);
  mrb.define_method(MRB_SYM(transient), jdl_transient, flag_option_def);
  j->flag_option_def_api_obj = mrb_obj_new(mrb.mrb, flag_option_def, 0, 0);

  RClass* method_def = mrb.define_class(MRB_SYM(MethodDef), jdl_def);
  mrb.define_method(MRB_SYM(on_called), jdl_on_called, method_def);
  j->method_def_api_obj = mrb_obj_new(mrb.mrb, method_def, 0, 0);

  RClass* attr_def = mrb.define_class(MRB_SYM(AttributeDef), jdl_def);
  j->attr_def_api_obj = mrb_obj_new(mrb.mrb, method_def, 0, 0);

  MrbState& tmrb = j->tmrb;
  tmrb.init();
  j->base_api = tmrb.define_class(tmrb.sym("BaseAPI"));
  // TODO: need to set an inspect name?
  // TODO: define method_missing to report undefined methods/attrs
  j->top_level_api = tmrb.define_class(tmrb.sym("TopLevelAPI"), j->base_api);
  j->common_attrs_module = tmrb.define_module(tmrb.sym("CommonAttrs"));
  j->common_methods_module = tmrb.define_module(tmrb.sym("CommonMethods"));
  j->global_methods_module = tmrb.define_module(tmrb.sym("GlobalMethods"));

  // Everything has access to global methods
  tmrb.include_module(j->base_api, j->global_methods_module);
  return j;
}

void jdl_term(JDL* j)
{
  delete j;
}

bool jdl_load_built_in_file(JDL* j, const char* name)
{
  try
  {
    j->mrb.load_irep(std::format("C:/james_projects/GitHub/jaba/src/jdl/{}.rb", name));
  }
  catch (std::runtime_error&)
  {
    return false;
  }
  return true;
}

bool jdl_load_file_dynamically(JDL* j, std::string_view filepath)
{
  try
  {
    j->mrb.load_rb_file(filepath);
  }
  catch (std::runtime_error&)
  {
    return false;
  }
  return true;
}

std::string_view jdl_errfile(JDL* j)
{
  return j->errfile;
}

int jdl_errline(JDL* j)
{
  return j->errline;
}

std::string_view jdl_errmsg(JDL* j)
{
  return j->errmsg;
}
