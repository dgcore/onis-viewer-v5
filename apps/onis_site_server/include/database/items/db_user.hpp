#pragma once

#include "db_dicom_access.hpp"
#include "db_partition.hpp"

using json = nlohmann::json;

#define US_LOGIN_KEY "login"
#define US_ACTIVE_KEY "active"
#define US_PASSWORD_KEY "password"
#define US_SUPERUSER_KEY "superuser"
#define US_INHERIT_KEY "inherit"
#define US_FAMILY_NAME_KEY "family_name"
#define US_FIRST_NAME_KEY "first_name"
#define US_PREFIX_KEY "prefix"
#define US_SUFFIX_KEY "suffix"
#define US_ORGANIZATION_KEY "organization"
#define US_ADDRESS1_KEY "address1"
#define US_ADDRESS2_KEY "address2"
#define US_CITY_KEY "city"
#define US_ZIPCODE_KEY "zip"
#define US_COUNTRY_KEY "country"
#define US_EMAIL_KEY "email"
#define US_PHONE_KEY "phone"
#define US_FAX_KEY "fax"
#define US_PERMISSION_KEY "permissions"
#define US_MEMBERSHIP_KEY "membership"
#define US_PARTITION_ACCESS_KEY "partition_access"
#define US_DICOM_ACCESS_KEY "dicom_access"
#define US_PREFSET_ID_KEY "pref_id"
#define US_PREFSET_SHARED_ID_KEY "shared_pref_id"
#define US_PREFSET_INHERIT_KEY "inherit_pref"

namespace onis::database {

const s32 info_user_login = 2;
const s32 info_user_password = 4;
const s32 info_user_active = 8;
const s32 info_user_identity = 32;
const s32 info_user_organization = 64;
const s32 info_user_address = 128;
const s32 info_user_contact = 256;
const s32 info_user_superuser = 512;
const s32 info_user_inherit = 1024;
const s32 info_user_permissions = 2048;
const s32 info_user_membership = 4096;
const s32 info_user_partition_access = 8192;
const s32 info_user_dicom_access = 16384;
const s32 info_user_pref_set = 32768;

struct user {
  static void create(json& item, u32 flags) {
    if (!item.is_object()) {
      throw std::invalid_argument("user is not an object");
    }
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags & info_user_login)
      item[US_LOGIN_KEY] = "";
    if (flags & info_user_password)
      item[US_PASSWORD_KEY] = "";
    if (flags & info_user_active)
      item[US_ACTIVE_KEY] = 0;
    if (flags & info_user_superuser)
      item[US_SUPERUSER_KEY] = 0;
    if (flags & info_user_inherit)
      item[US_INHERIT_KEY] = 1;
    if (flags & info_user_identity) {
      item[US_FAMILY_NAME_KEY] = "";
      item[US_FIRST_NAME_KEY] = "";
      item[US_PREFIX_KEY] = "";
      item[US_SUFFIX_KEY] = "";
    }
    if (flags & info_user_organization)
      item[US_ORGANIZATION_KEY] = "";
    if (flags & info_user_address) {
      item[US_ADDRESS1_KEY] = "";
      item[US_ADDRESS2_KEY] = "";
      item[US_CITY_KEY] = "";
      item[US_ZIPCODE_KEY] = "";
      item[US_COUNTRY_KEY] = "";
    }
    if (flags & info_user_contact) {
      item[US_EMAIL_KEY] = "";
      item[US_PHONE_KEY] = "";
      item[US_FAX_KEY] = "";
    }
    if (flags & info_user_permissions)
      item[US_PERMISSION_KEY] = json::array();
    if (flags & info_user_membership)
      item[US_MEMBERSHIP_KEY] = json::array();

    if (flags & info_user_partition_access) {
      item[US_PARTITION_ACCESS_KEY] = json::object();
      onis::database::partition_access::create(item[US_PARTITION_ACCESS_KEY]);
    }

    if (flags & info_user_dicom_access) {
      item[US_DICOM_ACCESS_KEY] = json::object();
      onis::database::dicom_access::create(item[US_DICOM_ACCESS_KEY]);
    }
    if (flags & info_user_pref_set) {
      item[US_PREFSET_INHERIT_KEY] = 0;
      item[US_PREFSET_ID_KEY] = "";
      item[US_PREFSET_SHARED_ID_KEY] = "";
    }
  }

  static void verify(const json& input, bool with_seq, u32 must_flags) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    onis::database::item::check_must_flags(flags, must_flags);

    if (flags & info_user_login)
      onis::database::item::verify_string_value(input, US_LOGIN_KEY, false,
                                                false, OS_REGEX_LOGIN);
    if (flags & info_user_password)
      onis::database::item::verify_string_value(input, US_PASSWORD_KEY, false,
                                                OS_REGEX_PASSWORD);
    if (flags & info_user_active)
      onis::database::item::verify_integer_value(input, US_ACTIVE_KEY, false, 0,
                                                 1);
    if (flags & info_user_superuser)
      onis::database::item::verify_integer_value(input, US_SUPERUSER_KEY, false,
                                                 0, 1);
    if (flags & info_user_inherit)
      onis::database::item::verify_integer_value(input, US_INHERIT_KEY, false,
                                                 0, 1);
    if (flags & info_user_identity) {
      onis::database::item::verify_string_value(input, US_FAMILY_NAME_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, US_FIRST_NAME_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, US_PREFIX_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, US_SUFFIX_KEY, true,
                                                true, 64);
    }
    if (flags & info_user_organization)
      onis::database::item::verify_string_value(input, US_ORGANIZATION_KEY,
                                                true, true, 64);
    if (flags & info_user_address) {
      onis::database::item::verify_string_value(input, US_ADDRESS1_KEY, true,
                                                true, 255);
      onis::database::item::verify_string_value(input, US_ADDRESS2_KEY, true,
                                                true, 255);
      onis::database::item::verify_string_value(input, US_CITY_KEY, true, true,
                                                64);
      onis::database::item::verify_string_value(input, US_ZIPCODE_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, US_COUNTRY_KEY, true,
                                                true, 64);
    }
    if (flags & info_user_contact) {
      onis::database::item::verify_string_value(input, US_EMAIL_KEY, true, true,
                                                OS_REGEX_EMAIL);
      onis::database::item::verify_string_value(input, US_PHONE_KEY, true, true,
                                                OS_REGEX_STR64);
      onis::database::item::verify_string_value(input, US_FAX_KEY, true, true,
                                                OS_REGEX_STR64);
    }
    if (flags & info_user_permissions) {
      onis::database::item::verify_array_value(input, US_PERMISSION_KEY, false);
      for (const auto& permission : input[US_PERMISSION_KEY]) {
        onis::database::item::verify_string_value(permission, nullptr, false,
                                                  false, 100);
      }
    }
    if (flags & info_user_membership) {
      onis::database::item::verify_array_value(input, US_MEMBERSHIP_KEY, false);
      for (const auto& membership : input[US_MEMBERSHIP_KEY]) {
        onis::database::item::verify_uuid_value(membership, nullptr, false,
                                                false);
      }
    }
    if (flags & info_user_partition_access)
      onis::database::partition_access::verify(input[US_PARTITION_ACCESS_KEY]);
    if (flags & info_user_dicom_access)
      onis::database::dicom_access::verify(input[US_DICOM_ACCESS_KEY]);
    if (flags & info_user_pref_set) {
      onis::database::item::verify_uuid_value(input, US_PREFSET_ID_KEY, true,
                                              true);
      onis::database::item::verify_uuid_value(input, US_PREFSET_SHARED_ID_KEY,
                                              true, true);
      onis::database::item::verify_integer_value(input, US_PREFSET_INHERIT_KEY,
                                                 false, 0, 1);
    }
  }
};
}  // namespace onis::database
