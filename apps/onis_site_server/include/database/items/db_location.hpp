#pragma once

#include "db_item.hpp"

using json = nlohmann::json;

#define LC_NAME_KEY "name"
#define LC_TYPE_KEY "loctype"
#define LC_ORG_KEY "org"
#define LC_SITE_ID_KEY "site_id"
#define LC_SITE_NAME_KEY "site_name"
#define LC_URL_KEY "url"
#define LC_LOGIN_KEY "login"
#define LC_PWD_KEY "pwd"

namespace onis::database {

const s32 info_location_name = 2;
const s32 info_location_type = 4;
const s32 info_location_org_name = 16;
const s32 info_location_site_name = 32;
const s32 info_location_url = 64;
const s32 info_location_login = 256;
const s32 info_location_password = 512;

struct location {
  static void create(json& item, u32 flags) {
    if (!item.is_object()) {
      throw std::invalid_argument("location is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags & info_location_name)
      item[LC_NAME_KEY] = "";
    if (flags & info_location_type)
      item[LC_TYPE_KEY] = 1;
    if (flags & info_location_url)
      item[LC_URL_KEY] = "";
    if (flags & info_location_org_name)
      item[LC_ORG_KEY] = "";
    if (flags & info_location_site_name) {
      item[LC_SITE_ID_KEY] = "";
      item[LC_SITE_NAME_KEY] = "";
    }
    if (flags & info_location_login)
      item[LC_LOGIN_KEY] = "";
    if (flags & info_location_password)
      item[LC_PWD_KEY] = "";
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    s32 type = -1;
    if (flags & info_location_type) {
      onis::database::item::verify_integer_value(input, LC_TYPE_KEY, false, 0,
                                                 1);
      type = input[LC_TYPE_KEY].get<s32>();
    }
    if (flags & info_location_name)
      onis::database::item::verify_string_value(input, LC_NAME_KEY, false,
                                                false, 64);
    if (flags & info_location_url)
      onis::database::item::verify_string_value(input, LC_URL_KEY, false, false,
                                                255);
    if (flags & info_location_login)
      onis::database::item::verify_string_value(input, LC_LOGIN_KEY, false,
                                                false, 64);
    if (flags & info_location_password)
      onis::database::item::verify_string_value(input, LC_PWD_KEY, false, false,
                                                64);
    if (flags & info_location_site_name) {
      onis::database::item::verify_uuid_value(input, LC_SITE_ID_KEY, true,
                                              true);
      onis::database::item::verify_string_value(input, LC_SITE_NAME_KEY, true,
                                                true, 255);
    }
    if (flags & info_location_org_name)
      onis::database::item::verify_string_value(input, LC_ORG_KEY, type == 1,
                                                type == 1, 64);
    if (flags & info_location_site_name) {
      onis::database::item::verify_uuid_value(input, LC_SITE_ID_KEY, type == 1,
                                              type == 1);
      onis::database::item::verify_string_value(input, LC_SITE_NAME_KEY,
                                                type == 1, type == 1, 255);
    }
  }
};

}  // namespace onis::database
