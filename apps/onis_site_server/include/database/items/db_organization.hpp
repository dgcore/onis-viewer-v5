#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define OR_NAME_KEY "name"

namespace onis::database {

using dgc::s32;
using dgc::u32;

const s32 info_organization_name = 1;

struct organization {
  static void create(json& organization, u32 flags) {
    if (!organization.isObject()) {
      throw std::invalid_argument("organization is not an object");
    }
    organization.clear();
    organization[BASE_SEQ_KEY] = "";
    organization[BASE_VERSION_KEY] = "1.0.0";
    organization[BASE_FLAGS_KEY] = flags;
    if (flags & info_organization_name)
      organization[OR_NAME_KEY] = "";
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].asUInt();
    if (flags & info_organization_name)
      onis::database::item::verify_string_value(input, OR_NAME_KEY, false,
                                                false, 64);
  }
};

}  // namespace onis::database
