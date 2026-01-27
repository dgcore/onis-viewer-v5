#pragma once

#include <string>

namespace onis::util::uuid {

std::string generate_random_uuid();
bool is_valid(const std::string& uuid);

}  // namespace onis::util::uuid
