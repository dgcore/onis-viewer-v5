#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define PFI_NAME_KEY "name"
#define PFI_DESC_KEY "desc"
#define PFI_STATUS_KEY "status"
#define PFI_TYPE_KEY "ptype"
#define PFI_VERSION_KEY "pversion"
#define PFI_DATA_KEY "data"
#define PFI_SHORTCUT_KEY "shortcut"

namespace onis::database {

const s32 info_pref_item_name = 1;
const s32 info_pref_item_status = 2;
const s32 info_pref_item_description = 4;
const s32 info_pref_item_shortcut = 8;
const s32 info_pref_item_data = 16;

struct preference_item {
  static void create(json& item, u32 flags) {
    if (!item.isObject()) {
      throw std::invalid_argument("preference_item is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    item[PFI_TYPE_KEY] = "";
    item[PFI_VERSION_KEY] = "";
    if (flags & info_pref_item_name)
      item[PFI_NAME_KEY] = "";
    if (flags & info_pref_item_description)
      item[PFI_DESC_KEY] = "";
    if (flags & info_pref_item_status)
      item[PFI_STATUS_KEY] = 0;
    if (flags & info_pref_item_shortcut) {
      item[PFI_SHORTCUT_KEY] = Json::Value(Json::arrayValue);
      item[PFI_SHORTCUT_KEY].append(0);
      item[PFI_SHORTCUT_KEY].append(0);
    }
    if (flags & info_pref_item_data)
      item[PFI_DATA_KEY] = "";
  }
};

static void verify(const json& input, bool with_seq) {
  onis::database::item::verify_seq_version_flags(input, with_seq);
  u32 flags = input[BASE_FLAGS_KEY].asUInt();

  onis::database::item::check_must_flags(flags, must_flags, res);
  onis::database::item::verify_string_value(input, PFI_TYPE_KEY, false, false);
  onis::database::item::verify_string_value(input, PFI_VERSION_KEY, false,
                                            false);
  if (flags & info_pref_item_name)
    onis::database::item::verify_string_value(input, PFI_NAME_KEY, false, false,
                                              64);
  if (flags & info_pref_item_status)
    onis::database::item::verify_integer_value(input, PFI_STATUS_KEY, false, 0,
                                               1);
  if (flags & info_pref_item_description)
    onis::database::item::verify_string_value(input, PFI_DESC_KEY, false, false,
                                              255);
  if (flags & info_pref_item_data)
    onis::database::item::verify_string_value(input, PFI_DATA_KEY, false,
                                              false);

  if (flags & info_pref_item_shortcut) {
    onis::database::item::verify_array_value(input, PFI_SHORTCUT_KEY, false);
    if (input[PFI_SHORTCUT_KEY].size() != 2) {
      throw std::invalid_argument("Shortcut must have 2 elements");
    } else {
      if ((input[PFI_SHORTCUT_KEY][0].type() != json::value_t::number_integer &&
           input[PFI_SHORTCUT_KEY][0].type() !=
               json::value_t::number_unsigned) ||
          (input[PFI_SHORTCUT_KEY][1].type() != json::value_t::number_integer &&
           input[PFI_SHORTCUT_KEY][1].type() !=
               json::value_t::number_unsigned)) {
        throw std::invalid_argument("Shortcut must be an integer");
      }
    }
  }
}

}  // namespace onis::database
