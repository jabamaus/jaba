#include <filesystem>
#include <format>
#include "jaba.h"
#include "jdl.h"
#include "node.h"
#include "jrfcore/file_manager.h"
#include "jrfcore/mrbstate.h"
#include "jrfcore/utils.h"

namespace fs = std::filesystem;

struct Jaba
{
  ArenaAllocator allocator;
  FileManager* fm;
  fs::path src_root;
  fs::path src_root_dir;
  JDL* jdl;
  MrbState mrb;
  JabaNode* root_node;
};

mrb_value obj_method_missing(mrb_state* mrb_, mrb_value self)
{
  Jaba* j = (Jaba*)((MrbState*)mrb_->ud)->user_data();
  return self;
}

Jaba* jaba_init(const char* src_root)
{
  Jaba* j = new Jaba;
  j->allocator.reserve(1024 * 32);
  j->fm = fm_init();
  j->mrb.init();
  j->mrb.set_user_data(j);
  j->mrb.define_method(MRB_SYM(method_missing), obj_method_missing);

  if (src_root)
    j->src_root = src_root;
  else
    j->src_root = fs::current_path();
  
  if (!fs::exists(j->src_root))
    jaba_fail(j, std::format("source root '{}' does not exist", j->src_root.string()));

  if (fs::is_directory(j->src_root))
    j->src_root_dir = j->src_root;
  else
    j->src_root_dir = j->src_root.parent_path();

  j->jdl = jdl_init();
  return j;
}

void jaba_term(Jaba* j)
{
  jdl_term(j->jdl);
  j->mrb.term();
  fm_term(j->fm);
  delete j;
}

void jaba_process_file(Jaba* j, const fs::path& path)
{
#if 0
  if !f.absolute_path ?
    JABA.error("'#{f}' must be an absolute path")
  end
  f = f.cleanpath

  if @jdl_file_lookup.has_key ? (f)
    return # Already loaded.Ignore.
  end

  @jdl_file_lookup[f] = nil
#endif

}

void jaba_process_load_path(Jaba* j, const fs::path& path, bool fail_if_empty = false)
{
  if (!path.is_absolute())
    jaba_fail(j, std::format("'{}' must be an absolute path", path.string()));

  if (!fs::exists(path))
    jaba_fail(j, std::format("'{}' does not exist", path.string()));

  if (fs::is_directory(path))
  {
    bool found = false;
    for (auto const& entry : fs::directory_iterator{ path })
    {
      if (entry.is_regular_file())
      {
        const fs::path& p = entry.path();
        if (p.extension() == ".jaba")
        {
          found = true;
          jaba_process_file(j, p);
        }
      }
    }
    if (!found)
    {
      std::string msg = std::format("No .jaba files found in '{}'", path.string());
      if (fail_if_empty)
        jaba_fail(j, msg);
      else
        jaba_warn(j, msg);
    }
  }
  else
  {
    jaba_process_file(j, path);
  }
}

void jaba_run(Jaba* j)
{
  jdl_load_built_in_file(j->jdl, "core"); // TODO: error handling
  jdl_load_built_in_file(j->jdl, "target");
  j->root_node = jaba_node_init(j);
  jaba_process_load_path(j, j->src_root, true);
}

void* jaba_alloc(Jaba* j, size_t nbytes)
{
  return j->allocator.alloc(nbytes);
}

void jaba_fail(Jaba* j, std::string_view msg)
{
  throw std::runtime_error(msg.data());
}

void jaba_warn(Jaba* j, std::string_view msg)
{
  // TODO: store warnings and strip duplicates
  printf("%s\n", msg.data());
}
