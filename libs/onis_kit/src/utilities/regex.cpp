#include "../../include/utilities/regex.hpp"

#include <regex>

namespace dgc::util::regex {
void match(const std::string value, const std::string& exp, bool allow_empty) {
  if (value.empty() && !allow_empty)
    throw std::invalid_argument("Value is empty and allow_empty is false");
  else {
    std::regex e(exp);
    if (!std::regex_match(value, e))
      throw std::invalid_argument("Value does not match the regex");
  }
}
}  // namespace dgc::util::regex
