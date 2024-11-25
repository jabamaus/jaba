#include <filesystem>
#include <fstream>
#include "test_common.h"
#include "jdl_builder.h"

bool test_jdl_str(JDLBuilder* b, const char* str)
{
  std::filesystem::create_directories(section_path);
  section_path /= "test.jdl";
  std::ofstream(section_path) << str;
  bool result = load_jdl_file_dynamically(b, section_path.string());
  section_path.remove_filename();
  return result;
}

TEST_CASE("validates jdl path format")
{
  JDLBuilder* b = init_jdl_builder();

  WHEN("pipes used")
  {
    const char* jdl = R"(
JDL.node :n
JDL.attr "n|a"
)";
    REQUIRE(test_jdl_str(b, jdl) == false);
    REQUIRE(jdl_errline(b) == 3);
    REQUIRE(jdl_errmsg(b) == "'n|a' is in invalid format");
    // TODO: check filename
  }
  term_jdl_builder(b);
}