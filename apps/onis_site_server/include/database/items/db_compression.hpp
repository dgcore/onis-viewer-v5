#pragma once

#include "db_item.hpp"

using json = nlohmann::json;

#define CP_ENABLE_KEY "enable"
#define CP_UPDATE_KEY "update"
#define CP_TRANSFER_KEY "transfer"
#define CP_MODE_KEY "mode"
#define CP_START_KEY "start"
#define CP_STOP_KEY "stop"

namespace onis::database {

const s32 info_compression_enable = 2;
const s32 info_compression_mode = 4;
const s32 info_compression_transfer = 8;
const s32 info_compression_update = 16;

struct compression {
  static void create(json& compression, u32 flags) {
    if (!compression.is_object()) {
      throw std::invalid_argument("compression is not an object");
    }
    compression.clear();
    compression[BASE_SEQ_KEY] = "";
    compression[BASE_VERSION_KEY] = "1.0.0";
    compression[BASE_FLAGS_KEY] = flags;
    if (flags & info_compression_enable)
      compression[CP_ENABLE_KEY] = 0;
    if (flags & info_compression_mode) {
      compression[CP_MODE_KEY] = 2;
      compression[CP_START_KEY] = 1;
      compression[CP_STOP_KEY] = 5;
    }
    if (flags & info_compression_transfer)
      compression[CP_TRANSFER_KEY] = "";
    if (flags & info_compression_update)
      compression[CP_UPDATE_KEY] = 1;
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    if (flags & info_compression_enable)
      onis::database::item::verify_integer_value(input, CP_ENABLE_KEY, false, 0,
                                                 1);
    if (flags & info_compression_update)
      onis::database::item::verify_integer_value(input, CP_UPDATE_KEY, false,
                                                 0);
    if (flags & info_compression_transfer)
      onis::database::item::verify_string_value(input, CP_TRANSFER_KEY, true,
                                                true);
    if (flags & info_compression_mode) {
      onis::database::item::verify_integer_value(input, CP_MODE_KEY, false, 0,
                                                 2);
      onis::database::item::verify_integer_value(input, CP_START_KEY, false, 0,
                                                 23);
      onis::database::item::verify_integer_value(input, CP_STOP_KEY, false, 0,
                                                 23);
    }
  }
};
}  // namespace onis::database