#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define PM_NAME_KEY "name"
#define PM_TYPE_KEY "type"

namespace onis::database {

const std::uint32_t info_permission_name = 2;
const std::uint32_t info_permission_type = 4;

struct permission {
  static void create(json& item, std::uint32_t flags) {
    if (!item.isObject()) {
      throw std::invalid_argument("permission is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags & info_permission_name)
      item[PM_NAME_KEY] = "";
    if (flags & info_permission_type)
      item[PM_TYPE_KEY] = 0;
  }
};

static void verify(const json& input, bool with_seq) {
  onis::database::item::verify_seq_version_flags(input, with_seq);
  std::uint32_t flags = input[BASE_FLAGS_KEY].asUInt();
  if (flags & info_permission_name)
    onis::database::item::verify_string_value(input, PM_NAME_KEY, false, false,
                                              64);
  if (flags & info_permission_type)
    onis::database::item::verify_integer_value(input, PM_TYPE_KEY, false);
}

}  // namespace onis::database
