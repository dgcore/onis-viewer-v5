#pragma once

#include "./db_dicom_access.hpp"
#include "./db_partition.hpp"

using json = nlohmann::json;

#define RO_NAME_KEY "name"
#define RO_DESC_KEY "desc"
#define RO_ACTIVE_KEY "status"
#define RO_INHERIT_KEY "inherit"
#define RO_PERMISSION_KEY "permissions"
#define RO_MEMBERSHIP_KEY "membership"
#define RO_PARTITION_ACCESS_KEY "partition_access"
#define RO_DICOM_ACCESS_KEY "dicom_access"
#define RO_PREFSET_ID_KEY "pref_set"
#define RO_PREFSET_INHERIT_KEY "inherit_pref"

namespace onis::database {

const s32 info_role_name = 2;
const s32 info_role_description = 4;
const s32 info_role_permissions = 8;
const s32 info_role_active = 16;
const s32 info_role_inherit = 32;
const s32 info_role_membership = 64;
const s32 info_role_partition_access = 128;
const s32 info_role_dicom_access = 256;
const s32 info_role_pref_set = 512;

struct role {
  static void create(json& item, u32 flags) {
    if (!item.is_object()) {
      throw std::invalid_argument("role is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags & info_role_name)
      item[RO_NAME_KEY] = "";
    if (flags & info_role_description)
      item[RO_DESC_KEY] = "";
    if (flags & info_role_permissions)
      item[RO_PERMISSION_KEY] = json::array();
    if (flags & info_role_active)
      item[RO_ACTIVE_KEY] = 0;
    if (flags & info_role_inherit)
      item[RO_INHERIT_KEY] = 0;
    if (flags & info_role_membership)
      item[RO_MEMBERSHIP_KEY] = json::array();
    if (flags & info_role_partition_access) {
      item[RO_PARTITION_ACCESS_KEY] = json::object();
      onis::database::partition_access::create(item[RO_PARTITION_ACCESS_KEY]);
    }
    if (flags & info_role_dicom_access) {
      item[RO_DICOM_ACCESS_KEY] = json::object();
      onis::database::dicom_access::create(item[RO_DICOM_ACCESS_KEY]);
    }
    if (flags & info_role_pref_set) {
      item[RO_PREFSET_INHERIT_KEY] = 0;
      item[RO_PREFSET_ID_KEY] = "";
    }
  }

  static void verify(const json& input, bool with_seq, u32 must_flags) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    onis::database::item::check_must_flags(flags, must_flags);
    if (flags & info_role_name)
      onis::database::item::verify_string_value(input, RO_NAME_KEY, false,
                                                false, 64);
    if (flags & info_role_active)
      onis::database::item::verify_integer_value(input, RO_ACTIVE_KEY, false, 0,
                                                 1);
    if (flags & info_role_inherit)
      onis::database::item::verify_integer_value(input, RO_INHERIT_KEY, false,
                                                 0, 1);
    if (flags & info_role_description)
      onis::database::item::verify_string_value(input, RO_DESC_KEY, true, true,
                                                255);
    if (flags & info_role_pref_set) {
      onis::database::item::verify_uuid_value(input, RO_PREFSET_ID_KEY, true,
                                              true);
      onis::database::item::verify_integer_value(input, RO_PREFSET_INHERIT_KEY,
                                                 false, 0, 1);
    }
    if (flags & info_role_permissions) {
      onis::database::item::verify_array_value(input, RO_PERMISSION_KEY, false);
      for (const auto& permission : input[RO_PERMISSION_KEY]) {
        onis::database::item::verify_string_value(permission, "id", false,
                                                  false, 100);
        onis::database::item::verify_boolean_value(permission, "value", false);
      }
    }
    if (flags & info_role_membership) {
      onis::database::item::verify_array_value(input, RO_MEMBERSHIP_KEY, false);
      for (const auto& membership : input[RO_MEMBERSHIP_KEY]) {
        onis::database::item::verify_string_value(membership, nullptr, false,
                                                  false);
      }
    }
    if (flags & info_role_partition_access)
      onis::database::partition_access::verify(input[RO_PARTITION_ACCESS_KEY]);
    if (flags & info_role_dicom_access)
      onis::database::dicom_access::verify(input[RO_DICOM_ACCESS_KEY]);
  }
};

}  // namespace onis::database
