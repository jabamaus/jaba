#include <filesystem>
#include <format>
#include "jaba.h"
#include "jdl.h"
#include "jrfcore/utils.h"

namespace fs = std::filesystem;

struct Jaba
{
  ArenaAllocator allocator;
  fs::path src_root;
  fs::path src_root_dir;
};

Jaba* jaba_init(const char* src_root)
{
  Jaba* j = new Jaba;
  j->allocator.reserve(1024 * 32);

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

  return j;
}

void jaba_term(Jaba* j)
{
  delete j;
}

void jaba_run(Jaba* j)
{
  JDL* jdl = jdl_init();
  jdl_load_built_in_file(jdl, "core"); // TODO: error handling
  jdl_load_built_in_file(jdl, "target");
  jdl_term(jdl);
}

void* jaba_alloc(Jaba* j, size_t nbytes)
{
  return j->allocator.alloc(nbytes);
}

void jaba_fail(Jaba* j, std::string_view msg)
{
  throw std::runtime_error(msg.data());
}