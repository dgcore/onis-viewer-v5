#pragma once

#include "./db_album.hpp"
#include "./db_smart_album.hpp"

using json = nlohmann::json;

#define PT_NAME_KEY "name"
#define PT_DESC_KEY "desc"
#define PT_STATUS_KEY "status"
#define PT_PARAM_KEY "param"
#define PT_VOLUME_KEY "volume"
#define PT_ALBUMS_KEY "albums"
#define PT_SMART_ALBUMS_KEY "smart_albums"

#define PT_OVERWRITE_MODE_KEY "owm"
#define PT_PID_MODE_KEY "pidm"
#define PT_DEF_PID_KEY "defpid"
#define PT_CONFLICT_CRITERIA_KEY "cc"
#define PT_CONFLICT_MODE_KEY "cm"
#define PT_PREV_ICON "pvi"
#define PT_STREAM_DATA "std"
#define PT_HAVE_CONFLICT_KEY "conflict"
#define PT_RQ_LIMIT "rql"
#define PT_RQ_REJECT "rqr"

#define PTAA_ID_KEY "id"
#define PTAA_TYPE_KEY "type"
#define PTAA_PERMISSION_KEY "permissions"

#define PTAI_ID_KEY "id"
#define PTAI_TYPE_KEY "type"
#define PTAI_MODE_KEY "mode"
#define PTAI_PERMISSION_KEY "permissions"
#define PTAI_ALBUMS_KEY "albums"

#define PTA_ACTIVE_KEY "active"
#define PTA_INHERIT_KEY "inherit"
#define PTA_MODE_KEY "mode"
#define PTA_PARTITIONS_KEY "partitions"

namespace onis::database {

const s32 info_partition_name = 2;
const s32 info_partition_description = 4;
const s32 info_partition_status = 8;
const s32 info_partition_parameters = 16;
const s32 info_partition_volume = 32;
const s32 info_partition_conflict = 64;
const s32 info_partition_albums = 128;
const s32 info_partition_smart_albums = 256;

struct album_access_item {
  static void create(json& album) {
    if (!album.is_object()) {
      throw std::invalid_argument("album_access_item is not an object");
    }
    album.clear();
    album[PTAA_ID_KEY] = "";
    album[PTAA_TYPE_KEY] = 0;
    album[PTAA_PERMISSION_KEY] = 0;
  }

  static void verify(const json& input) {
    onis::database::item::verify_uuid_value(input, PTAA_ID_KEY, false, false);
    onis::database::item::verify_integer_value(input, PTAA_TYPE_KEY, false, 0,
                                               1);
    onis::database::item::verify_integer_value(input, PTAA_PERMISSION_KEY,
                                               false, 0, 0xFFFFFF);
  }
};

struct partition_access_item {
  static void create(json& partition) {
    if (!partition.is_object()) {
      throw std::invalid_argument("partition_access_item is not an object");
    }
    partition.clear();
    partition[PTAI_ID_KEY] = "";
    partition[PTAI_TYPE_KEY] = 0;
    partition[PTAI_MODE_KEY] = 0;
    partition[PTAI_PERMISSION_KEY] = 0;
    partition[PTAI_ALBUMS_KEY] = json::array();
  }

  static void verify(const json& input) {
    onis::database::item::verify_uuid_value(input, PTAI_ID_KEY, false, false);
    onis::database::item::verify_integer_value(input, PTAI_TYPE_KEY, false, 0,
                                               0);
    onis::database::item::verify_integer_value(input, PTAI_MODE_KEY, false);
    onis::database::item::verify_integer_value(input, PTAI_PERMISSION_KEY,
                                               false, 0, 0xFFFFFF);
    onis::database::item::verify_array_value(input, PTAI_ALBUMS_KEY, false);
    for (const auto& album : input[PTAI_ALBUMS_KEY])
      album_access_item::verify(album);
    s32 value = input[PTAI_MODE_KEY].get<s32>();
    if (value != 256) {
      value &= ~2;
      value &= ~4;
      if (value != 0) {
        throw std::invalid_argument(
            "Invalid mode value for partition access item.");
      }
    }
  }
};

struct partition_access {
  static const s32 all_partitions = 1;
  static const s32 all_albums = 2;
  static const s32 all_smart_albums = 4;
  static const s32 limited_access = 256;

  static void create(json& access) {
    if (!access.is_object()) {
      throw std::invalid_argument("partition_access is not an object");
    }
    access.clear();
    access[PTA_ACTIVE_KEY] = 1;
    access[PTA_INHERIT_KEY] = 0;
    access[PTA_MODE_KEY] = 0;
    access[PTA_PARTITIONS_KEY] = json::array();
  }

  static void verify(const json& input) {
    onis::database::item::verify_integer_value(input, PTA_ACTIVE_KEY, false, 0,
                                               1);
    onis::database::item::verify_integer_value(input, PTA_INHERIT_KEY, false, 0,
                                               1);
    onis::database::item::verify_integer_value(input, PTA_MODE_KEY, false);
    onis::database::item::verify_array_value(input, PTA_PARTITIONS_KEY, false);
    for (const auto& partition : input[PTA_PARTITIONS_KEY])
      partition_access_item::verify(partition);
    s32 value = input[PTA_MODE_KEY].get<s32>();
    if (value != 256) {
      value &= ~partition_access::all_partitions;
      value &= ~partition_access::all_albums;
      value &= ~partition_access::all_smart_albums;
      value &= ~partition_access::limited_access;
      if (value != 0) {
        throw std::invalid_argument("Invalid mode value");
      }
    }
  }
};

struct partition {
  static const s32 no_overwrite_failure = 1;
  static const s32 no_overwrite_success = 2;

  static const s32 reject_if_conflict = 1;
  static const s32 send_to_conflict_list = 2;

  static const s32 conflict_patient_name = 2;
  static const s32 conflict_patient_birthdate = 4;
  static const s32 conflict_patient_sex = 8;
  static const s32 conflict_accession_number = 16;
  static const s32 conflict_study_id = 32;
  static const s32 conflict_study_desc = 64;

  static void create(json& partition, u32 flags) {
    if (!partition.is_object()) {
      throw std::invalid_argument("partition is not an object");
    }
    partition.clear();
    partition[BASE_SEQ_KEY] = "";
    partition[BASE_VERSION_KEY] = "1.0.0";
    partition[BASE_FLAGS_KEY] = flags;

    if (flags != 0) {
      if (flags & info_partition_name)
        partition[PT_NAME_KEY] = "";
      if (flags & info_partition_description)
        partition[PT_DESC_KEY] = "";
      if (flags & info_partition_status)
        partition[PT_STATUS_KEY] = 0;
      if (flags & info_partition_parameters) {
        json param(json::object());
        param[PT_OVERWRITE_MODE_KEY] = no_overwrite_failure;
        param[PT_PID_MODE_KEY] = 0;
        param[PT_DEF_PID_KEY] = "Default";
        param[PT_CONFLICT_MODE_KEY] = reject_if_conflict;
        param[PT_CONFLICT_CRITERIA_KEY] = 0;
        param[PT_PREV_ICON] = 1;
        param[PT_RQ_LIMIT] = 500;
        param[PT_RQ_REJECT] = 1;
        param[PT_STREAM_DATA] = 0;
        partition[PT_PARAM_KEY] = param.dump();
      }
      if (flags & info_partition_volume)
        partition[PT_VOLUME_KEY] = "";
      if (flags & info_partition_conflict)
        partition[PT_HAVE_CONFLICT_KEY] = 0;
      if (flags & info_partition_albums)
        partition[PT_ALBUMS_KEY] = json::array();
      if (flags & info_partition_smart_albums)
        partition[PT_SMART_ALBUMS_KEY] = json::array();
    }
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    if (flags & info_partition_name)
      onis::database::item::verify_string_value(input, PT_NAME_KEY, false,
                                                false, 64);
    if (flags & info_partition_description)
      onis::database::item::verify_string_value(input, PT_DESC_KEY, true, true,
                                                255);
    if (flags & info_partition_status)
      onis::database::item::verify_integer_value(input, PT_STATUS_KEY, false, 0,
                                                 1);

    if (flags & info_partition_parameters) {
      onis::database::item::verify_string_value(input, PT_PARAM_KEY, false,
                                                false);
      json param;
      try {
        param = json::parse(input[PT_PARAM_KEY].get<std::string>());
      } catch (...) {
        throw std::invalid_argument("Invalid parameters for partition.");
      }
      onis::database::item::verify_integer_value(param, PT_OVERWRITE_MODE_KEY,
                                                 false, 0, 1);
      s32 value = param[PT_OVERWRITE_MODE_KEY].get<s32>();
      if (value != no_overwrite_failure && value != no_overwrite_success) {
        throw std::invalid_argument("Invalid overwrite mode for partition.");
      }
      onis::database::item::verify_integer_value(param, PT_PID_MODE_KEY, false,
                                                 0, 1);
      onis::database::item::verify_string_value(param, PT_DEF_PID_KEY, false,
                                                true, 64);
      onis::database::item::verify_integer_value(param, PT_CONFLICT_MODE_KEY,
                                                 false, 0, 2);
      value = param[PT_CONFLICT_MODE_KEY].get<s32>();
      if (value != reject_if_conflict && value != send_to_conflict_list) {
        throw std::invalid_argument("Invalid conflict mode for partition.");
      }
      onis::database::item::verify_integer_value(
          param, PT_CONFLICT_CRITERIA_KEY, false, 0);
      value = param[PT_CONFLICT_CRITERIA_KEY].get<s32>();
      value &= ~conflict_patient_name;
      value &= ~conflict_patient_birthdate;
      value &= ~conflict_patient_sex;
      value &= ~conflict_accession_number;
      value &= ~conflict_study_id;
      value &= ~conflict_study_desc;
      if (value != 0) {
        throw std::invalid_argument("Invalid conflict criteria for partition.");
      }
      onis::database::item::verify_integer_value(param, PT_PREV_ICON, false, 0,
                                                 1);
      onis::database::item::verify_integer_value(param, PT_STREAM_DATA, false,
                                                 0, 1);
      onis::database::item::verify_integer_value(param, PT_RQ_LIMIT, false, 0);
      onis::database::item::verify_integer_value(param, PT_RQ_REJECT, false, 0,
                                                 1);
    }
    if (flags & info_partition_volume)
      onis::database::item::verify_uuid_value(input, PT_VOLUME_KEY, true, true);

    if (flags & info_partition_conflict)
      onis::database::item::verify_integer_value(input, PT_HAVE_CONFLICT_KEY,
                                                 false, 0, 1);

    if (flags & info_partition_albums) {
      onis::database::item::verify_array_value(input, PT_ALBUMS_KEY, false);
      for (const auto& album : input[PT_ALBUMS_KEY])
        onis::database::album::verify(album, false, 0);
    }

    if (flags & info_partition_smart_albums) {
      onis::database::item::verify_array_value(input, PT_SMART_ALBUMS_KEY,
                                               false);
      for (const auto& smart_album : input[PT_SMART_ALBUMS_KEY])
        onis::database::smart_album::verify(smart_album, with_seq, 0);
    }
  }
};

}  // namespace onis::database
