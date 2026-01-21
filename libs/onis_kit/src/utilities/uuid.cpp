#include "../../include/utilities/uuid.hpp"

#include <random>
#include <sstream>

namespace onis::util::uuid {

std::string generate_random_uuid() {
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dis(0, 15);
  std::uniform_int_distribution<> dis2(8, 11);

  std::stringstream ss;
  int i;

  ss << std::hex;
  for (i = 0; i < 8; i++) {
    ss << dis(gen);
  }
  ss << "-";
  for (i = 0; i < 4; i++) {
    ss << dis(gen);
  }
  ss << "-4";
  for (i = 0; i < 3; i++) {
    ss << dis(gen);
  }
  ss << "-";
  ss << dis2(gen);
  for (i = 0; i < 3; i++) {
    ss << dis(gen);
  }
  ss << "-";
  for (i = 0; i < 12; i++) {
    ss << dis(gen);
  }

  return ss.str();
}

bool is_valid(const std::string& uuid) {
  // Verify UUID format: 8-4-4-4-12 hexadecimal digits
  if (uuid.length() != 36 || uuid[8] != '-' || uuid[13] != '-' ||
      uuid[18] != '-' || uuid[23] != '-') {
    return false;
  }

  // Check that all non-dash characters are valid hex digits
  for (size_t i = 0; i < uuid.length(); i++) {
    if (i != 8 && i != 13 && i != 18 && i != 23) {
      char c = uuid[i];
      if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') ||
            (c >= 'A' && c <= 'F'))) {
        return false;
      }
    }
  }
  return true;
}

}  // namespace onis::util::uuid
