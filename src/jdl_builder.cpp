#include <format>
#include <regex>
#include "jrfcore/mrbstate.h"
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
  MrbState mrb;
  mrb_value attr_def_api_obj;
  mrb_value node_def_api_obj;
  mrb_value flag_option_def_api_obj;
  mrb_value method_def_api_obj;
  const char* errfile;
  int errline = -1;
  std::string errmsg;
};

enum class JDLDefType
{
  GlobalMethod,
  Method,
  Node,
  Attr
};

template <typename... Args>
void fail(JDLBuilder* b, std::format_string<Args...> fmt, Args&&... args)
{
  MrbState& mrb = b->mrb;
  mrb.caller_location(&b->errfile, &b->errline);
  b->errmsg = std::format(fmt, args...);
  throw std::runtime_error(b->errmsg);
}

static const std::regex path_regex1(R"(^(\*\/)?([a-zA-Z0-9]+_?\/?)+$)");
static const std::regex path_regex2(R"([a-zA-Z0-9]$)");

static void register_jdl_def(JDLBuilder* b, JDLDefType type)
{
  MrbState& mrb = b->mrb;

  if (type == JDLDefType::Attr)
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
    fail(b, "'{}' is in invalid format", name);
  }

  if (type == JDLDefType::Attr)
  {
    std::string_view type = mrb.pop_string(MRB_SYM(type));
    std::string_view variant = mrb.pop_string(MRB_SYM(variant), false, "single");
  }
  mrb.args_end();

  switch (type)
  {
  case JDLDefType::GlobalMethod:
  {
    mrb.instance_eval(b->method_def_api_obj, 0, 0, block);
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

static mrb_value jdl_global_method(mrb_state* mrb_, mrb_value self)
{
  JDLBuilder* b = (JDLBuilder*)((MrbState*)mrb_->ud)->user_data();
  register_jdl_def(b, JDLDefType::GlobalMethod);
  return self;
}

static mrb_value jdl_method(mrb_state* mrb_, mrb_value self)
{
  JDLBuilder* b = (JDLBuilder*)((MrbState*)mrb_->ud)->user_data();
  register_jdl_def(b, JDLDefType::Method);
  return self;
}

static mrb_value jdl_node(mrb_state* mrb_, mrb_value self)
{
  JDLBuilder* b = (JDLBuilder*)((MrbState*)mrb_->ud)->user_data();
  register_jdl_def(b, JDLDefType::Node);
  return self;
}

static mrb_value jdl_attr(mrb_state* mrb_, mrb_value self)
{
  JDLBuilder* b = (JDLBuilder*)((MrbState*)mrb_->ud)->user_data();
  register_jdl_def(b, JDLDefType::Attr);
  return self;
}

static mrb_value jdl_title(mrb_state* mrb_, mrb_value self)
{
  JDLBuilder* b = (JDLBuilder*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = b->mrb;
  mrb.args_begin();
  std::string_view title = mrb.pop_string();
  mrb.args_end();
  return self;
}

static mrb_value jdl_note(mrb_state* mrb_, mrb_value self)
{
  JDLBuilder* b = (JDLBuilder*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = b->mrb;
  mrb.args_begin();
  std::string_view note = mrb.pop_string();
  mrb.args_end();
  return self;
}

static mrb_value jdl_example(mrb_state* mrb_, mrb_value self)
{
  JDLBuilder* b = (JDLBuilder*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = b->mrb;
  mrb.args_begin();
  std::string_view example = mrb.pop_string();
  mrb.args_end();
  return self;
}

static mrb_value jdl_transient(mrb_state* mrb_, mrb_value self)
{
  JDLBuilder* b = (JDLBuilder*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = b->mrb;
  mrb.args_begin();
  bool transient = mrb.pop_bool();
  mrb.args_end();
  return self;
}

static mrb_value jdl_on_called(mrb_state* mrb_, mrb_value self)
{
  JDLBuilder* b = (JDLBuilder*)((MrbState*)mrb_->ud)->user_data();
  MrbState& mrb = b->mrb;
  mrb.args_begin();
  mrb_value block;
  mrb.pop_block(block);
  mrb.args_end();
  return self;
}

JDLBuilder* init_jdl_builder()
{
  JDLBuilder* b = new JDLBuilder;
  MrbState& mrb = b->mrb;
  mrb.init();
  mrb.set_user_data(b);

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
  b->flag_option_def_api_obj = mrb_obj_new(mrb.mrb, flag_option_def, 0, 0);

  RClass* method_def = mrb.define_class(MRB_SYM(MethodDef), jdl_def);
  mrb.define_method(MRB_SYM(on_called), jdl_on_called, method_def);
  b->method_def_api_obj = mrb_obj_new(mrb.mrb, method_def, 0, 0);

  RClass* attr_def = mrb.define_class(MRB_SYM(AttributeDef), jdl_def);
  b->attr_def_api_obj = mrb_obj_new(mrb.mrb, method_def, 0, 0);
  return b;
}

void term_jdl_builder(JDLBuilder* b)
{
  delete b;
}

bool load_built_in_jdl_file(JDLBuilder* b, const char* name)
{
  try
  {
    b->mrb.load_irep(std::format("C:/james_projects/GitHub/jaba/src/jdl/{}.rb", name));
  }
  catch (std::runtime_error&)
  {
    return false;
  }
  return true;
}

bool load_jdl_file_dynamically(JDLBuilder* b, std::string_view filepath)
{
  try
  {
    b->mrb.load_rb_file(filepath);
  }
  catch (std::runtime_error&)
  {
    return false;
  }
  return true;
}

std::string_view jdl_errfile(JDLBuilder* b)
{
  return b->errfile;
}

int jdl_errline(JDLBuilder* b)
{
  return b->errline;
}

std::string_view jdl_errmsg(JDLBuilder* b)
{
  return b->errmsg;
}
