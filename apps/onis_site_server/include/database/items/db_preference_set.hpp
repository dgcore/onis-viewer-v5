#pragma once

#include "db_item.hpp"

using json = nlohmann::json;

#define PFS_NAME_KEY "name"
#define PFS_DESC_KEY "desc"
#define PFS_ACTIVE_KEY "status"
#define PFS_ITEMS_KEY "items"

namespace onis::database {

const s32 info_pref_set_name = 2;
const s32 info_pref_set_description = 4;
const s32 info_pref_set_active = 8;
const s32 info_pref_set_items = 16;

struct preference_set {
  static void create(json& item, u32 flags) {
    if (!item.is_object()) {
      throw std::invalid_argument("preference_set is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags & info_pref_set_name)
      item[PFS_NAME_KEY] = "";
    if (flags & info_pref_set_description)
      item[PFS_DESC_KEY] = "";
    if (flags & info_pref_set_active)
      item[PFS_ACTIVE_KEY] = 0;
    if (flags & info_pref_set_items)
      item[PFS_ITEMS_KEY] = json::array();
  }
};

static void verify(const json& input, bool with_seq, u32 must_flags) {
  onis::database::item::verify_seq_version_flags(input, with_seq);
  u32 flags = input[BASE_FLAGS_KEY].get<u32>();
  onis::database::item::check_must_flags(flags, must_flags, res);
  if (flags & info_pref_set_name)
    onis::database::item::verify_string_value(input, PFS_NAME_KEY, false, false,
                                              64);
  if (flags & info_pref_set_active)
    onis::database::item::verify_integer_value(input, PFS_ACTIVE_KEY, false, 0,
                                               1);
  if (flags & info_pref_set_description)
    onis::database::item::verify_string_value(input, PFS_DESC_KEY, false, false,
                                              255);
  if (flags & info_pref_set_items) {
    onis::database::item::verify_array_value(input, PFS_ITEMS_KEY, false);
    for (const auto& item : input[PFS_ITEMS_KEY]) {
      onis::database::preference_item::verify(item, with_seq, 0);
    }
  }
}

}  // namespace onis::database
