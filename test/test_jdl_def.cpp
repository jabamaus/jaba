#include <filesystem>
#include <fstream>
#include "test_common.h"
#include "jdl.h"

bool test_jdl_str(JDL* j, const char* str)
{
  std::filesystem::create_directories(section_path);
  section_path /= "test.jdl";
  std::ofstream(section_path) << str;
  bool result = jdl_load_file_dynamically(j, section_path.string());
  section_path.remove_filename();
  return result;
}

void test_invalid_jdl_path(JDL* j, const char* jdl, int errline, const char* errmsg)
{
  REQUIRE(test_jdl_str(j, jdl) == false);
  REQUIRE(jdl_errline(j) == errline);
  REQUIRE(jdl_errmsg(j) == errmsg);
}

TEST_CASE("validates jdl path format")
{
  JDL* j = jdl_init();
  
  WHEN("paths valid")
  {
    const char* valid_jdl = R"(
JDL.node 'n'
JDL.attr 'n/a', type: :int
JDL.attr 'n/snake_case', type: :bool
JDL.attr 'n/a2', type: :bool
JDL.attr "*/id", type: :string
JDL.global_method '__dir__'
JDL.global_method 'x86_64?'
)";
    REQUIRE(test_jdl_str(j, valid_jdl) == true);
  }
  WHEN("pipes not slashes")
  {
    test_invalid_jdl_path(j, "JDL.node :n\nJDL.attr 'n|a'", 2, "'n|a' is in invalid format");
  }
  WHEN("double underscore")
  {
    test_invalid_jdl_path(j, "JDL.node :n\nJDL.attr 'n/a__b'", 2, "'n/a__b' is in invalid format");
  }
  WHEN("contains spaces")
  {
    test_invalid_jdl_path(j, "JDL.node :n\nJDL.attr 'n/a b'", 2, "'n/a b' is in invalid format");
  }
  WHEN("contains double slashes")
  {
    test_invalid_jdl_path(j, "JDL.node :n\nJDL.attr 'n//a_b'", 2, "'n//a_b' is in invalid format");
  }
  WHEN("starts with slash")
  {
    test_invalid_jdl_path(j, "JDL.node :n\nJDL.attr '/n/a'", 2, "'/n/a' is in invalid format");
  }
  WHEN("ends in slash")
  {
    test_invalid_jdl_path(j, "JDL.node :n\nJDL.attr 'n/a_b/'", 2, "'n/a_b/' is in invalid format");
  }
  WHEN("invalid numerics inside path")
  {
    test_invalid_jdl_path(j, "JDL.node :n\nJDL.attr 'n/a1b'", 2, "'n/a1b' is in invalid format");
  }
  jdl_term(j);
}