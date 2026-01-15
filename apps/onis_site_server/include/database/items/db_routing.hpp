#pragma once

#include "db_item.hpp"

using json = nlohmann::json;

#define AR_ENABLE_KEY "enable"
#define AR_FAILURE_MANAGEMENT_KEY "failure_management"
#define AR_UPDATE_KEY "update"
#define AR_RULES_KEY "rules"
#define AR_STAT_KEY "stats"

#define RR_ACTIVE_KEY "active"
#define RR_NAME_KEY "name"
#define RR_TYPE_KEY "rule_type"
#define RR_FILTERS_KEY "filters"

#define RR_FROM_LOC_KEY "from"
#define RR_FROM_LOC_TYPE_KEY "from_source_type"
#define RR_FROM_LOC_ID_KEY "from_source_id"
#define RR_FROM_LOC_NAME_KEY "from_source_name"

#define RR_DEST_LOC_KEY "dest"
#define RR_DEST_LOC_TYPE_KEY "dest_source_type"
#define RR_DEST_LOC_ID_KEY "dest_source_id"
#define RR_DEST_LOC_NAME_KEY "dest_source_name"

#define RRF_TAG_KEY "tag"
#define RRF_VALUE_KEY "value"
#define RRF_MATCHING_KEY "matching"

#define ARL_SITE_KEY "site"
#define ARL_PARTITION_KEY "partition"
#define ARL_IMAGE_KEY "image"
#define ARL_SERIES_KEY "series"
#define ARL_DEST_ID_KEY "dest_id"
#define ARL_DEST_TYPE_KEY "dest_type"
#define ARL_LOC_KEY "loc"
#define ARL_STATUS_KEY "status"
#define ARL_FIRST_TRY_KEY "ftry"
#define ARL_NEXT_TRY_KEY "ntry"
#define ARL_CRDATE_KEY "crdate"

namespace onis::database {

const s32 info_auto_routing_rule_active = 2;
const s32 info_auto_routing_rule_name = 4;
const s32 info_auto_routing_rule_type = 8;
const s32 info_auto_routing_rule_from = 16;
const s32 info_auto_routing_rule_destination = 32;
const s32 info_auto_routing_rule_filters = 64;

const s32 info_auto_routing_enable = 2;
const s32 info_auto_routing_failure_management = 4;
const s32 info_auto_routing_update = 8;
const s32 info_auto_routing_rules = 16;
const s32 info_auto_routing_statistics = 32;

const s32 info_auto_routing_line_source = 2;
const s32 info_auto_routing_line_image = 4;
const s32 info_auto_routing_line_series = 8;
const s32 info_auto_routing_line_destination = 16;
const s32 info_auto_routing_line_status = 32;
const s32 info_auto_routing_line_first_try = 64;
const s32 info_auto_routing_line_next_try = 128;
const s32 info_auto_routing_line_crdate = 256;

const s32 type_standard = 0;
const s32 type_backup = 1;

struct routing_rule {
  static void create(json& item, u32 flags) {
    if (!item.is_object()) {
      throw std::invalid_argument("routing_rule is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags & info_auto_routing_rule_active)
      item[RR_ACTIVE_KEY] = 0;
    if (flags & info_auto_routing_rule_name)
      item[RR_NAME_KEY] = "";
    if (flags & info_auto_routing_rule_type)
      item[RR_TYPE_KEY] = onis::server::type_standard;
    if (flags & info_auto_routing_rule_from) {
      item[RR_FROM_LOC_KEY] = "";
      item[RR_FROM_LOC_TYPE_KEY] = -1;
      item[RR_FROM_LOC_ID_KEY] = "";
      item[RR_FROM_LOC_NAME_KEY] = "";
    }
    if (flags & info_auto_routing_rule_destination) {
      item[RR_DEST_LOC_KEY] = "";
      item[RR_DEST_LOC_TYPE_KEY] = -1;
      item[RR_DEST_LOC_ID_KEY] = "";
      item[RR_DEST_LOC_NAME_KEY] = "";
    }
    if (flags & info_auto_routing_rule_filters) {
      item[RR_FILTERS_KEY] = Json::Value(Json::arrayValue);
    }
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    if (flags & onis::server::info_auto_routing_rule_active)
      onis::database::item::verify_integer_value(input, RR_ACTIVE_KEY, false, 0,
                                                 1);
    if (flags & info_auto_routing_rule_name)
      onis::database::item::verify_string_value(input, RR_NAME_KEY, false,
                                                false, 64);
    if (flags & info_auto_routing_rule_type) {
      onis::database::item::verify_integer_value(input, RR_TYPE_KEY, false);
      s32 value = input[RR_TYPE_KEY].get<s32>();
      if (value != onis::server::type_standard &&
          value != onis::server::type_backup) {
        throw std::invalid_argument("routing_rule type is invalid");
      }
    }
    if (flags & onis::server::info_auto_routing_rule_filters) {
      onis::database::item::verify_array_value(input, RR_FILTERS_KEY, false);
      for (const auto& filter : input[RR_FILTERS_KEY]) {
        onis::database::item::verify_integer_value(filter, RRF_TAG_KEY, false);
        onis::database::item::verify_string_value(filter, RRF_VALUE_KEY, false,
                                                  false);
        onis::database::item::verify_integer_value(filter, RRF_MATCHING_KEY,
                                                   false, 0);
      }
    }

    if (flags & onis::server::info_auto_routing_rule_name)
      onis::database::item::verify_string_value(input, RR_NAME_KEY, false,
                                                false, 64);
    if (flags & onis::server::info_auto_routing_rule_type) {
      onis::database::item::verify_integer_value(input, RR_TYPE_KEY, false);
      s32 value = input[RR_TYPE_KEY].get<s32>();
      if (value != onis::server::type_standard &&
          value != onis::server::type_backup) {
        throw std::invalid_argument("routing_rule type is invalid");
      }
    }
    if (flags & onis::server::info_auto_routing_rule_filters) {
      onis::database::item::verify_array_value(input, RR_FILTERS_KEY, false);
      for (const auto& filter : input[RR_FILTERS_KEY]) {
        onis::database::item::verify_integer_value(filter, RRF_TAG_KEY, false,
                                                   0);
        onis::database::item::verify_string_value(filter, RRF_VALUE_KEY, false,
                                                  false, 64);
        onis::database::item::verify_integer_value(filter, RRF_MATCHING_KEY,
                                                   false, 0, 1);
      }
    }

    if (flags & onis::server::info_auto_routing_rule_from) {
      onis::database::item::verify_uuid_value(input, RR_FROM_LOC_KEY, true);
      onis::database::item::verify_integer_value(input, RR_FROM_LOC_TYPE_KEY,
                                                 false, 0);
      onis::database::item::verify_uuid_value(input, RR_FROM_LOC_ID_KEY, true);
      onis::database::item::verify_string_value(input, RR_FROM_LOC_NAME_KEY,
                                                true, true, 64);
    }
    if (flags & onis::server::info_auto_routing_rule_destination) {
      onis::database::item::verify_string_value(input, RR_DEST_LOC_KEY, false,
                                                false, 64);
      onis::database::item::verify_integer_value(input, RR_DEST_LOC_TYPE_KEY,
                                                 false);
      onis::database::item::verify_string_value(input, RR_DEST_LOC_ID_KEY,
                                                false, false, 64);
      onis::database::item::verify_string_value(input, RR_DEST_LOC_NAME_KEY,
                                                false, false, 64);
    }
  }
};

struct routing {
  static void create(json& item, u32 flags) {
    if (!item.is_object()) {
      throw std::invalid_argument("routing is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags & info_auto_routing_enable)
      item[AR_ENABLE_KEY] = 0;
    if (flags & info_auto_routing_failure_management) {
      item[AR_FAILURE_MANAGEMENT_KEY] = Json::Value(Json::arrayValue);
      item[AR_FAILURE_MANAGEMENT_KEY].append(300);
      item[AR_FAILURE_MANAGEMENT_KEY].append(1);
      item[AR_FAILURE_MANAGEMENT_KEY].append(300);
      item[AR_FAILURE_MANAGEMENT_KEY].append(1);
    }
    if (flags & info_auto_routing_update)
      item[AR_UPDATE_KEY] = 0;
    if (flags & info_auto_routing_rules)
      item[AR_RULES_KEY] = Json::Value(Json::arrayValue);
    if (flags & info_auto_routing_statistics)
      item[AR_STAT_KEY] = 0;
    return OSTRUE;
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    if (flags & info_auto_routing_enable)
      onis::database::item::verify_integer_value(input, AR_ENABLE_KEY, false, 0,
                                                 1);
    if (flags & info_auto_routing_update)
      onis::database::item::verify_integer_value(input, AR_UPDATE_KEY, false,
                                                 0);
    if (flags & info_auto_routing_statistics)
      onis::database::item::verify_integer_value(input, AR_STAT_KEY, false);
    if (flags & info_auto_routing_failure_management) {
      onis::database::item::verify_array_value(input, AR_FAILURE_MANAGEMENT_KEY,
                                               false);
      if (input[AR_FAILURE_MANAGEMENT_KEY].size() != 4)
        throw std::invalid_argument("routing failure management is invalid");
      for (const auto& failure_management : input[AR_FAILURE_MANAGEMENT_KEY])
        onis::database::item::verify_integer_value(failure_management, false);
    }
    if (flags & info_auto_routing_rules) {
      onis::database::item::verify_array_value(input, AR_RULES_KEY, false);
      for (const auto& rule : input[AR_RULES_KEY])
        onis::database::routing_rule::verify(rule, with_seq);
    }
  }
};

struct routing_line {
  static void create(json& item, u32 flags) {
    if (!item.is_object()) {
      throw std::invalid_argument("routing_line is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;

    if (flags & info_auto_routing_line_source) {
      item[ARL_SITE_KEY] = "";
      item[ARL_PARTITION_KEY] = "";
    }
    if (flags & info_auto_routing_line_image)
      item[ARL_IMAGE_KEY] = "";
    if (flags & info_auto_routing_line_series)
      item[ARL_SERIES_KEY] = "";
    if (flags & info_auto_routing_line_destination) {
      item[ARL_DEST_ID_KEY] = "";
      item[ARL_DEST_TYPE_KEY] = -1;
      item[ARL_LOC_KEY] = "";
    }
    if (flags & info_auto_routing_line_status)
      item[ARL_STATUS_KEY] = 0;
    if (flags & info_auto_routing_line_first_try)
      item[ARL_FIRST_TRY_KEY] = "";
    if (flags & info_auto_routing_line_next_try)
      item[ARL_NEXT_TRY_KEY] = "";
    if (flags & info_auto_routing_line_crdate)
      item[ARL_CRDATE_KEY] = "";
  }
};

}  // namespace onis::database
