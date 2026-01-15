#pragma once

#include "db_item.hpp"

using json = nlohmann::json;

#define GR_NAME_KEY "name"
#define GR_DESC_KEY "desc"
#define GR_STATUS_KEY "status"
#define GR_PARTITION_MODE_KEY "partition_mode"
#define GR_PARTITION_LIST_KEY "partitions"
#define GR_ROLE_MODE_KEY "role_mode"
#define GR_ROLE_ID_KEY "role"

namespace onis::database {

const u32 info_user_group_name = 2;
const u32 info_user_group_description = 4;
const u32 info_user_group_active = 8;
const s32 info_user_group_role = 32;
const s32 info_user_group_partition = 128;

struct group {
  static void create(json& item, u32 flags) {
    if (!item.is_object()) {
      throw std::invalid_argument("group is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags & info_user_group_name)
      item[GR_NAME_KEY] = "";
    if (flags & info_user_group_description)
      item[GR_DESC_KEY] = "";
    if (flags & info_user_group_active)
      item[GR_STATUS_KEY] = 0;
    if (flags & info_user_group_partition) {
      item[GR_PARTITION_MODE_KEY] = 0;
      item[GR_PARTITION_LIST_KEY] = json::array();
    }
    if (flags & info_user_group_role) {
      item[GR_ROLE_MODE_KEY] = 0;
      item[GR_ROLE_ID_KEY] = "";
    }
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    if (flags & info_user_group_name)
      onis::database::item::verify_string_value(input, GR_NAME_KEY, false,
                                                false, 64);

    if (flags & onis::database::info_user_group_description)
      onis::database::item::verify_string_value(input, GR_DESC_KEY, true, true,
                                                255);

    if (flags & onis::database::info_user_group_active)
      onis::database::item::verify_integer_value(input, GR_STATUS_KEY, false, 0,
                                                 1);

    if (flags & onis::database::info_user_group_partition) {
      onis::database::item::verify_integer_value(input, GR_PARTITION_MODE_KEY,
                                                 false, 0, 1);
      onis::database::item::verify_array_value(input, GR_PARTITION_LIST_KEY,
                                               true);
    }
    if (flags & onis::database::info_user_group_role) {
      onis::database::item::verify_integer_value(input, GR_ROLE_MODE_KEY, false,
                                                 0, 1);
      onis::database::item::verify_string_value(input, GR_ROLE_ID_KEY, true,
                                                true, 255);
    }
  }
};

}  // namespace onis::database
