#include "test_common.h"

TEST_CASE("validates jdl path format")
{
  const char* jdl = R"(
node :n
attr "n|a" # 5CFB9574 pipes not allowed
)";
  REQUIRE(1 == 0);
}