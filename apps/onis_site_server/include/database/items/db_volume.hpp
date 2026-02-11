#pragma once

#include "db_media.hpp"

using json = Json::Value;

#define VO_NAME_KEY "name"
#define VO_DESC_KEY "desc"
#define VO_MEDIA_KEY "media"

namespace onis::database {

const std::uint32_t info_volume_name = 2;
const std::uint32_t info_volume_description = 4;
const std::uint32_t info_volume_media = 8;

struct volume {
  static void create(json& volume, std::uint32_t flags) {
    if (!volume.isObject()) {
      throw std::invalid_argument("volume is not an object");
    }
    volume.clear();
    volume[BASE_SEQ_KEY] = "";
    volume[BASE_VERSION_KEY] = "1.0.0";
    volume[BASE_FLAGS_KEY] = flags;
    if (flags & info_volume_name)
      volume[VO_NAME_KEY] = "";
    if (flags & info_volume_description)
      volume[VO_DESC_KEY] = "";
    if (flags & info_volume_media)
      volume[VO_MEDIA_KEY] = Json::Value(Json::arrayValue);
  }

  static void verify(const json& input, bool with_seq, bool with_media_seq,
                     std::uint32_t must_flags) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    std::uint32_t flags = input[BASE_FLAGS_KEY].asUInt();
    onis::database::item::check_must_flags(flags, must_flags);
    if (flags & info_volume_name)
      onis::database::item::verify_string_value(input, VO_NAME_KEY, false,
                                                false, 64);
    if (flags & info_volume_description)
      onis::database::item::verify_string_value(input, VO_DESC_KEY, true, true,
                                                255);
    if (flags & info_volume_media)
      onis::database::item::verify_array_value(input, VO_MEDIA_KEY, false);
    for (const auto& media : input[VO_MEDIA_KEY])
      onis::database::media::verify(media, with_media_seq);
  }
};

}  // namespace onis::database
