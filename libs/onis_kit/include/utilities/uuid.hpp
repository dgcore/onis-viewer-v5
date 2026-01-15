#pragma once

#include <string>

namespace dgc::util::uuid {

std::string generate_random_uuid();
bool is_valid(const std::string& uuid);

}  // namespace dgc::util::uuid
