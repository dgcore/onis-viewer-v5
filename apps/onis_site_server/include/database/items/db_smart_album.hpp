#pragma once

#include "db_item.hpp"

using json = nlohmann::json;

#define SA_NAME_KEY "name"
#define SA_DESC_KEY "desc"
#define SA_STATUS_KEY "status"
#define SA_CRITERIA_KEY "criteria"

namespace onis::database {

const s32 info_smart_album_name = 2;
const s32 info_smart_album_description = 4;
const s32 info_smart_album_status = 8;
const s32 info_smart_album_criteria = 16;

struct smart_album {
  const s32 criteria_modality = 0;
  const s32 criteria_patient_id = 1;
  const s32 criteria_study_date = 2;

  const s32 cp_equal = 0;
  const s32 cp_start = 1;
  const s32 cp_end = 2;
  const s32 cp_contain = 3;
  const s32 cp_greater = 4;
  const s32 cp_less = 5;
  const s32 cp_greater_or_equal = 6;
  const s32 cp_less_or_equal = 7;

  static void create(json& album, u32 flags) {
    if (!album.is_object()) {
      throw std::invalid_argument("smart_album is not an object");
    }
    album.clear();
    album[BASE_SEQ_KEY] = "";
    album[BASE_VERSION_KEY] = "1.0.0";
    album[BASE_FLAGS_KEY] = flags;
    if (flags != 0) {
      if (flags & info_smart_album_name)
        album[SA_NAME_KEY] = "";
      if (flags & info_smart_album_description)
        album[SA_DESC_KEY] = "";
      if (flags & info_smart_album_status)
        album[SA_STATUS_KEY] = "";
      if (flags & info_smart_album_criteria) {
        json param = json::object();
        album[SA_CRITERIA_KEY] = param.dump();
      }
    }
  }

  static void verify_criteria_group(const json& input) {
    onis::database::item::verify_integer_value(input, "op", false);
    bool have_groups = input.contains("groups");
    bool have_criteria = input.contains("criteria");
    if ((have_groups && have_criteria)) {
      throw std::invalid_argument(
          "Smart album criteria group and criteria cannot be used together");
    } else {
      if (have_groups) {
        onis::database::item::verify_array_value(input, "groups", false);
        for (const auto& group : input["groups"]) {
          verify_criteria_group(group);
        }
      } else if (have_criteria) {
        onis::database::item::verify_array_value(input, "criteria", false);
        for (const auto& criteria : input["criteria"]) {
          verify_criteria(criteria);
        }
      }
    }
  }

  static void verify_criteria(const json& input) {
    onis::database::item::verify_integer_value(input, "cr", false, 0, 2);
    onis::database::item::verify_integer_value(input, "cp", false, 0, 7);
    onis::database::item::verify_string_value(input, "val", false, false, 64);
  }

  static void verify(const json& input, bool with_seq, u32 must_flags) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    onis::database::item::check_must_flags(flags, must_flags);
    if (flags & info_smart_album_name)
      onis::database::item::verify_string_value(input, SA_NAME_KEY, false,
                                                false, 64);
    if (flags & info_smart_album_description)
      onis::database::item::verify_string_value(input, SA_DESC_KEY, true, true,
                                                255);
    if (flags & info_smart_album_status)
      onis::database::item::verify_integer_value(input, SA_STATUS_KEY, false, 0,
                                                 1);
    if (flags & info_smart_album_criteria) {
      onis::database::item::verify_string_value(input, SA_CRITERIA_KEY, false,
                                                true);
      const std::string& value = input[SA_CRITERIA_KEY].get<std::string>();
      if (value.length()) {
        json criteria;
        try {
          criteria = json::parse(value);
        } catch (...) {
          throw std::invalid_argument("Invalid criteria format");
        }
        verify_criteria_group(criteria);
      }
    }
  }
};

}  // namespace onis::database
