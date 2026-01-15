#pragma once

#include "db_item.hpp"

using json = nlohmann::json;

#define SI_NAME_KEY "name"

namespace onis::database {

const s32 info_site_name = 1;

struct site {
  static void create(json& site, u32 flags) {
    if (!site.is_object()) {
      throw std::invalid_argument("site is not an object");
    }
    site.clear();
    site[BASE_SEQ_KEY] = "";
    site[BASE_VERSION_KEY] = "1.0.0";
    site[BASE_FLAGS_KEY] = flags;
    if (flags & info_site_name)
      site[SI_NAME_KEY] = "";
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    if (flags & info_site_name) {
      onis::database::item::verify_string_value(input, SI_NAME_KEY, false,
                                                false, 64);
    }
  }
};

}  // namespace onis::database
