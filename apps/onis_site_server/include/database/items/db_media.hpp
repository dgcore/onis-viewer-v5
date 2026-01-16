#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define ME_TYPE_KEY "media_type"
#define ME_NUM_KEY "num"
#define ME_PATH_KEY "path"
#define ME_RATIO_KEY "ratio"
#define ME_STATUS_KEY "status"
#define ME_FREE_BYTES_KEY "free_bytes"
#define ME_TOTAL_BYTES_KEY "total_bytes"

namespace onis::database {

const s32 media_for_any = 0;
const s32 media_for_images = 1;
const s32 media_for_reports = 2;
const s32 media_for_temp = 4;
const s32 media_for_logs = 8;

const s32 media_full = 0;
const s32 media_available = 1;
const s32 media_not_found = 2;
const s32 media_unknown = 3;

const s32 info_media_data = 2;
const s32 info_media_statistics = 4;

struct media {
  static void create(json& media, u32 flags) {
    if (!media.isObject()) {
      throw std::invalid_argument("media is not an object");
    }
    media.clear();
    media[BASE_SEQ_KEY] = "";
    media[BASE_VERSION_KEY] = "1.0.0";
    media[BASE_FLAGS_KEY] = flags;
    if (flags & info_media_data) {
      media[ME_TYPE_KEY] = media_for_any;
      media[ME_NUM_KEY] = 0;
      media[ME_PATH_KEY] = "";
      media[ME_RATIO_KEY] = 0.0;
      media[ME_STATUS_KEY] = media_not_found;
    }
    if (flags & info_media_statistics) {
      media[ME_FREE_BYTES_KEY] = 0;
      media[ME_TOTAL_BYTES_KEY] = 0;
    }
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].asUInt();
    if (flags & info_media_data) {
      onis::database::item::verify_integer_value(input, ME_TYPE_KEY, false);
      onis::database::item::verify_integer_value(input, ME_NUM_KEY, false);
      onis::database::item::verify_string_value(input, ME_PATH_KEY, false,
                                                false);
      onis::database::item::verify_integer_or_real_value(input, ME_RATIO_KEY,
                                                         false, 0.0, 100.0);
      onis::database::item::verify_integer_value(input, ME_STATUS_KEY, false);

      s32 value = input[ME_TYPE_KEY].asInt();
      if (value != media_for_any && value != media_for_images &&
          value != media_for_reports && value != media_for_temp &&
          value != media_for_logs) {
        throw std::invalid_argument("Invalid media type");
      }

      value = input[ME_STATUS_KEY].asInt();
      if (value != media_full && value != media_available &&
          value != media_not_found && value != media_unknown) {
        throw std::invalid_argument("Invalid media status");
      }
    }
    if (flags & info_media_statistics) {
      onis::database::item::verify_integer_value(input, ME_FREE_BYTES_KEY,
                                                 false);
      onis::database::item::verify_integer_value(input, ME_TOTAL_BYTES_KEY,
                                                 false);
    }
  }
};
}  // namespace onis::database
