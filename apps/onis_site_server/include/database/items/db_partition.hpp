#pragma once

#include "./db_album.hpp"
#include "./db_smart_album.hpp"

using json = Json::Value;

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

const std::uint32_t info_partition_name = 2;
const std::uint32_t info_partition_description = 4;
const std::uint32_t info_partition_status = 8;
const std::uint32_t info_partition_parameters = 16;
const std::uint32_t info_partition_volume = 32;
const std::uint32_t info_partition_conflict = 64;
const std::uint32_t info_partition_albums = 128;
const std::uint32_t info_partition_smart_albums = 256;

///////////////////////////////////////////////////////////////////////
// partition_access_mode
///////////////////////////////////////////////////////////////////////

enum class partition_access_mode : std::uint32_t {
  NONE = 0,
  ALL_PARTITIONS = 1 << 0,
  ALL_ALBUMS = 1 << 1,
  ALL_SMART_ALBUMS = 1 << 2,
  LIMITED_ACCESS = 1 << 8
};

constexpr std::int32_t partition_access_mode_mask =
    static_cast<std::int32_t>(partition_access_mode::ALL_PARTITIONS) |
    static_cast<std::int32_t>(partition_access_mode::ALL_ALBUMS) |
    static_cast<std::int32_t>(partition_access_mode::ALL_SMART_ALBUMS) |
    static_cast<std::int32_t>(partition_access_mode::LIMITED_ACCESS);

inline partition_access_mode operator|(partition_access_mode a,
                                       partition_access_mode b) {
  return static_cast<partition_access_mode>(static_cast<std::uint32_t>(a) |
                                            static_cast<std::uint32_t>(b));
}

inline partition_access_mode operator&(partition_access_mode a,
                                       partition_access_mode b) {
  return static_cast<partition_access_mode>(static_cast<std::uint32_t>(a) &
                                            static_cast<std::uint32_t>(b));
}

inline partition_access_mode operator~(partition_access_mode a) {
  return static_cast<partition_access_mode>((~static_cast<std::uint32_t>(a)) &
                                            partition_access_mode_mask);
}

///////////////////////////////////////////////////////////////////////
// album_access_item
///////////////////////////////////////////////////////////////////////

struct album_access_item {
  static void create(json& album) {
    if (!album.isObject()) {
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
    if (!partition.isObject()) {
      throw std::invalid_argument("partition_access_item is not an object");
    }
    partition.clear();
    partition[PTAI_ID_KEY] = "";
    partition[PTAI_TYPE_KEY] = 0;
    partition[PTAI_MODE_KEY] = 0;
    partition[PTAI_PERMISSION_KEY] = 0;
    partition[PTAI_ALBUMS_KEY] = Json::Value(Json::arrayValue);
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
    std::int32_t value = input[PTAI_MODE_KEY].asInt();
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
  static void create(json& access) {
    if (!access.isObject()) {
      throw std::invalid_argument("partition_access is not an object");
    }
    access.clear();
    access[PTA_ACTIVE_KEY] = 1;
    access[PTA_INHERIT_KEY] = 0;
    access[PTA_MODE_KEY] = 0;
    access[PTA_PARTITIONS_KEY] = Json::Value(Json::arrayValue);
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
    std::int32_t value = input[PTA_MODE_KEY].asInt();
    if (value != 256) {
      value &=
          ~static_cast<std::uint32_t>(partition_access_mode::ALL_PARTITIONS);
      value &= ~static_cast<std::uint32_t>(partition_access_mode::ALL_ALBUMS);
      value &=
          ~static_cast<std::uint32_t>(partition_access_mode::ALL_SMART_ALBUMS);
      value &=
          ~static_cast<std::uint32_t>(partition_access_mode::LIMITED_ACCESS);
      if (value != 0) {
        throw std::invalid_argument("Invalid mode value");
      }
    }
  }
};

struct partition {
  static const std::int32_t no_overwrite_failure = 1;
  static const std::int32_t no_overwrite_success = 2;

  static const std::int32_t reject_if_conflict = 1;
  static const std::int32_t send_to_conflict_list = 2;

  static const std::int32_t conflict_patient_name = 2;
  static const std::int32_t conflict_patient_birthdate = 4;
  static const std::int32_t conflict_patient_sex = 8;
  static const std::int32_t conflict_accession_number = 16;
  static const std::int32_t conflict_study_id = 32;
  static const std::int32_t conflict_study_desc = 64;

  static void create(json& partition, std::uint32_t flags) {
    if (!partition.isObject()) {
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
        json param(Json::objectValue);
        param[PT_OVERWRITE_MODE_KEY] = no_overwrite_failure;
        param[PT_PID_MODE_KEY] = 0;
        param[PT_DEF_PID_KEY] = "Default";
        param[PT_CONFLICT_MODE_KEY] = reject_if_conflict;
        param[PT_CONFLICT_CRITERIA_KEY] = 0;
        param[PT_PREV_ICON] = 1;
        param[PT_RQ_LIMIT] = 500;
        param[PT_RQ_REJECT] = 1;
        param[PT_STREAM_DATA] = 0;
        partition[PT_PARAM_KEY] = onis::database::json_to_string(param);
      }
      if (flags & info_partition_volume)
        partition[PT_VOLUME_KEY] = "";
      if (flags & info_partition_conflict)
        partition[PT_HAVE_CONFLICT_KEY] = 0;
      if (flags & info_partition_albums)
        partition[PT_ALBUMS_KEY] = Json::Value(Json::arrayValue);
      if (flags & info_partition_smart_albums)
        partition[PT_SMART_ALBUMS_KEY] = Json::Value(Json::arrayValue);
    }
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    std::uint32_t flags = input[BASE_FLAGS_KEY].asUInt();
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
        Json::Reader reader;
        if (!reader.parse(input[PT_PARAM_KEY].asString(), param)) {
          throw std::invalid_argument("Invalid param format");
        }
      } catch (...) {
        throw std::invalid_argument("Invalid parameters for partition.");
      }
      onis::database::item::verify_integer_value(param, PT_OVERWRITE_MODE_KEY,
                                                 false, 0, 1);
      std::int32_t value = param[PT_OVERWRITE_MODE_KEY].asInt();
      if (value != no_overwrite_failure && value != no_overwrite_success) {
        throw std::invalid_argument("Invalid overwrite mode for partition.");
      }
      onis::database::item::verify_integer_value(param, PT_PID_MODE_KEY, false,
                                                 0, 1);
      onis::database::item::verify_string_value(param, PT_DEF_PID_KEY, false,
                                                true, 64);
      onis::database::item::verify_integer_value(param, PT_CONFLICT_MODE_KEY,
                                                 false, 0, 2);
      value = param[PT_CONFLICT_MODE_KEY].asInt();
      if (value != reject_if_conflict && value != send_to_conflict_list) {
        throw std::invalid_argument("Invalid conflict mode for partition.");
      }
      onis::database::item::verify_integer_value(
          param, PT_CONFLICT_CRITERIA_KEY, false, 0);
      value = param[PT_CONFLICT_CRITERIA_KEY].asInt();
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
