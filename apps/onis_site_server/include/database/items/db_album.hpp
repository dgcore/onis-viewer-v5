#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define AL_NAME_KEY "name"
#define AL_DESC_KEY "desc"
#define AL_STATUS_KEY "status"

namespace onis::database {

const std::uint32_t info_album_name = 2;
const std::uint32_t info_album_description = 4;
const std::uint32_t info_album_status = 8;

struct album {
  static void create(json& album, std::uint32_t flags) {
    if (!album.isObject()) {
      throw std::invalid_argument("album is not an object");
    }
    album.clear();
    album[BASE_SEQ_KEY] = "";
    album[BASE_VERSION_KEY] = "1.0.0";
    album[BASE_FLAGS_KEY] = flags;
    if (flags != 0) {
      if (flags & info_album_name)
        album[AL_NAME_KEY] = "";
      if (flags & info_album_description)
        album[AL_DESC_KEY] = "";
      if (flags & info_album_status)
        album[AL_STATUS_KEY] = "";
    }
  }

  static void verify(const json& input, bool with_seq,
                     std::uint32_t must_flags) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    std::uint32_t flags = input[BASE_FLAGS_KEY].asUInt();
    onis::database::item::check_must_flags(flags, must_flags);

    if (flags & onis::database::info_album_name) {
      onis::database::item::verify_string_value(input, AL_NAME_KEY, false,
                                                false, 64);
    }
    if (flags & onis::database::info_album_description) {
      onis::database::item::verify_string_value(input, AL_DESC_KEY, true, true,
                                                255);
    }
    if (flags & onis::database::info_album_status) {
      onis::database::item::verify_integer_value(input, AL_STATUS_KEY, false, 0,
                                                 1);
    }
  }
};
}  // namespace onis::database
