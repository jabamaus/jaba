#include <filesystem>
#include "test_common.h"

const char* test_root = "";
std::filesystem::path section_path(test_root);

struct SectionNameTracker : public Catch::EventListenerBase
{
  using Catch::EventListenerBase::EventListenerBase;
  void sectionStarting(Catch::SectionInfo const& si) override
  {
    size_t pos = si.name.find(':');
    if (pos != std::string::npos) // Skip over "    When : " style prefixes
      section_path /= si.name.substr(pos + 2);
    else
      section_path /= si.name;
  }
  void sectionEnded(Catch::SectionStats const&) override
  {
    section_path.remove_filename();
  }
};

CATCH_REGISTER_LISTENER(SectionNameTracker)
