#pragma once

#include "./db_item.hpp"
#include "./db_patient.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/core/result.hpp"

#include <cstdint>

using json = Json::Value;

#define SR_SEQ_KEY "seq"
#define SR_UID_KEY "uid"
#define SR_CHARSET_KEY "charset"
#define SR_DATE_KEY "date"
#define SR_TIME_KEY "time"
#define SR_MODALITY_KEY "modality"
#define SR_BODYPART_KEY "bodypart"
#define SR_DESC_KEY "desc"
#define SR_NUM_KEY "srnum"
#define SR_COMMENT_KEY "comment"
#define SR_STATION_KEY "station"
#define SR_IMCNT_KEY "imcnt"
#define SR_STATUS_KEY "status"
#define SR_CRDATE_KEY "crdate"
#define SR_ORIGIN_ID_KEY "oid"
#define SR_ORIGIN_NAME_KEY "oname"
#define SR_ORIGIN_IP_KEY "oip"
#define SR_ICON_MEDIA_KEY "iconmedia"
#define SR_ICON_PATH_KEY "iconpath"
#define SR_ICON_KEY "icon"
#define SR_PROP_MEDIA_KEY "propmedia"
#define SR_PROP_PATH_KEY "proppath"
#define SR_PROP_KEY "properties"

namespace onis::database {

const std::uint32_t info_series_character_set = 2;
const std::uint32_t info_series_num = 4;
const std::uint32_t info_series_description = 8;
const std::uint32_t info_series_body_part = 16;
const std::uint32_t info_series_date = 32;
const std::uint32_t info_series_icon = 64;
// const std::uint32_t info_series_icon_detail = 128;
const std::uint32_t info_series_properties = 256;
// const std::uint32_t info_series_properties_detail = 512;
// const std::uint32_t info_series_transfer_syntax = 1024;
const std::uint32_t info_series_statistics = 2048;
const std::uint32_t info_series_creation = 4096;
const std::uint32_t info_series_status = 8192;
const std::uint32_t info_series_modality = 16384;
const std::uint32_t info_series_station = 32768;
const std::uint32_t info_series_comment = 65536;

struct series {
  static void create(json& series, std::uint32_t flags, bool for_client) {
    if (!series.isObject()) {
      throw onis::exception(EOS_PARAM, "series is not an json object");
    }
    series.clear();
    series[BASE_SEQ_KEY] = "";
    series[BASE_VERSION_KEY] = "1.0.0";
    series[BASE_FLAGS_KEY] = flags;
    series[BASE_UID_KEY] = "";

    if (flags & info_series_character_set)
      series[SR_CHARSET_KEY] = "";
    if (flags & info_series_num)
      series[SR_NUM_KEY] = "";
    if (flags & info_series_description)
      series[SR_DESC_KEY] = "";
    if (flags & info_series_body_part)
      series[SR_BODYPART_KEY] = "";
    if (flags & info_series_date) {
      series[SR_DATE_KEY] = "";
      series[SR_TIME_KEY] = "";
    }
    if (flags & info_series_icon) {
      if (for_client)
        series[SR_ICON_KEY] = 0;
      else {
        series[SR_ICON_MEDIA_KEY] = 0;
        series[SR_ICON_PATH_KEY] = "";
      }
    }
    if (flags & info_series_properties) {
      if (for_client)
        series[SR_PROP_KEY] = 0;
      else {
        series[SR_PROP_MEDIA_KEY] = 0;
        series[SR_PROP_PATH_KEY] = "";
      }
    }
    if (flags & info_series_statistics) {
      series[SR_IMCNT_KEY] = 0;
    }
    if (flags & info_series_status) {
      if (for_client)
        series[SR_STATUS_KEY] = 0;
      else {
        series[SR_STATUS_KEY] = "";
      }
    }
    if (flags & info_series_creation) {
      series[SR_CRDATE_KEY] = "";
      series[SR_ORIGIN_ID_KEY] = "";
      series[SR_ORIGIN_NAME_KEY] = "";
      series[SR_ORIGIN_IP_KEY] = "";
    }
    if (flags & info_series_modality) {
      series[SR_MODALITY_KEY] = "";
    }
    if (flags & info_series_station) {
      series[SR_STATION_KEY] = "";
    }
    if (flags & info_series_comment) {
      series[SR_COMMENT_KEY] = "";
    }
  }

  static void verify(const json& input, bool with_seq, bool for_client) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    std::uint32_t flags = input[BASE_FLAGS_KEY].asUInt();
    if (flags & info_series_character_set)
      onis::database::item::verify_string_value(input, SR_CHARSET_KEY, true,
                                                true, 255);
    if (flags & info_series_date) {
      onis::database::item::verify_string_value(input, SR_DATE_KEY, true, true,
                                                8);
      onis::database::item::verify_string_value(input, SR_TIME_KEY, true, true,
                                                20);
    }
    if (flags & info_series_modality)
      onis::database::item::verify_string_value(input, SR_MODALITY_KEY, true,
                                                true, 255);
    if (flags & info_series_body_part)
      onis::database::item::verify_string_value(input, SR_BODYPART_KEY, true,
                                                true, 255);
    if (flags & info_series_num)
      onis::database::item::verify_string_value(input, SR_NUM_KEY, true, true,
                                                255);
    if (flags & info_series_description)
      onis::database::item::verify_string_value(input, SR_DESC_KEY, true, true,
                                                255);
    if (flags & info_series_comment)
      onis::database::item::verify_string_value(input, SR_COMMENT_KEY, true,
                                                true, 255);
    if (flags & info_series_station)
      onis::database::item::verify_string_value(input, SR_STATION_KEY, true,
                                                true, 255);
    if (flags & info_series_icon) {
      if (for_client)
        onis::database::item::verify_integer_value(input, SR_ICON_KEY, true);
      else {
        onis::database::item::verify_integer_value(input, SR_ICON_MEDIA_KEY,
                                                   true);
        onis::database::item::verify_string_value(input, SR_ICON_PATH_KEY, true,
                                                  true, 255);
      }
    }
    if (flags & info_series_properties) {
      if (for_client)
        onis::database::item::verify_integer_value(input, SR_PROP_KEY, true);
      else {
        onis::database::item::verify_integer_value(input, SR_PROP_MEDIA_KEY,
                                                   true);
        onis::database::item::verify_string_value(input, SR_PROP_PATH_KEY, true,
                                                  true, 255);
      }
    }
    if (flags & info_series_statistics) {
      onis::database::item::verify_integer_value(input, SR_IMCNT_KEY, false, 0);
    }
    if (flags & info_series_status) {
      if (for_client)
        onis::database::item::verify_integer_value(input, SR_STATUS_KEY, false);
      else {
        onis::database::item::verify_string_value(input, SR_STATUS_KEY, false,
                                                  false, 255);
      }
    }
    if (flags & info_series_creation) {
      onis::database::item::verify_string_value(input, SR_CRDATE_KEY, false,
                                                false, 64);
      onis::database::item::verify_string_value(input, SR_ORIGIN_ID_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, SR_ORIGIN_NAME_KEY, true,
                                                true, 255);
      onis::database::item::verify_string_value(input, SR_ORIGIN_IP_KEY, true,
                                                true, 255);
    }
  }

  static void copy(const json& input, std::uint32_t flags, bool for_client,
                   json& output) {
    create(output, flags, for_client);
    output[BASE_UID_KEY] = input[BASE_UID_KEY].asString();
    std::uint32_t input_flags = input[BASE_FLAGS_KEY].asUInt();

    if (flags & info_series_character_set) {
      if ((input_flags & info_series_character_set) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_CHARSET_KEY] = input[SR_CHARSET_KEY].asString();
    }

    if (flags & info_series_num) {
      if ((input_flags & info_series_num) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_NUM_KEY] = input[SR_NUM_KEY].asString();
    }

    if (flags & info_series_description) {
      if ((input_flags & info_series_description) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_DESC_KEY] = input[SR_DESC_KEY].asString();
    }

    if (flags & info_series_body_part) {
      if ((input_flags & info_series_body_part) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_BODYPART_KEY] = input[SR_BODYPART_KEY].asString();
    }

    if (flags & info_series_date) {
      if ((input_flags & info_series_date) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_DATE_KEY] = input[SR_DATE_KEY].asString();
      output[SR_TIME_KEY] = input[SR_TIME_KEY].asString();
    }

    if (flags & info_series_icon) {
      if ((input_flags & info_series_icon) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      if (for_client)
        output[SR_ICON_KEY] = input[SR_ICON_KEY].asInt();
      else {
        output[SR_ICON_MEDIA_KEY] = input[SR_ICON_MEDIA_KEY].asInt();
        output[SR_ICON_PATH_KEY] = input[SR_ICON_PATH_KEY].asString();
      }
    }

    if (flags & info_series_properties) {
      if ((input_flags & info_series_properties) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      if (for_client)
        output[SR_PROP_KEY] = input[SR_PROP_KEY].asInt();
      else {
        output[SR_PROP_MEDIA_KEY] = input[SR_PROP_MEDIA_KEY].asInt();
        output[SR_PROP_PATH_KEY] = input[SR_PROP_PATH_KEY].asString();
      }
    }

    if (flags & info_series_statistics) {
      if ((input_flags & info_series_statistics) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_IMCNT_KEY] = input[SR_IMCNT_KEY].asInt();
    }

    if (flags & info_series_creation) {
      if ((input_flags & info_series_creation) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_CRDATE_KEY] = input[SR_CRDATE_KEY].asString();
      output[SR_ORIGIN_ID_KEY] = input[SR_ORIGIN_ID_KEY].asString();
      output[SR_ORIGIN_NAME_KEY] = input[SR_ORIGIN_NAME_KEY].asString();
      output[SR_ORIGIN_IP_KEY] = input[SR_ORIGIN_IP_KEY].asString();
    }

    if (flags & info_series_status) {
      if ((input_flags & info_series_status) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      if (!for_client && input[SR_STATUS_KEY].type() != Json::stringValue) {
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      }
      if (for_client) {
        if (input[SR_STATUS_KEY].type() == Json::stringValue) {
          if (input[SR_STATUS_KEY] == ONLINE_STATUS)
            output[SR_STATUS_KEY] = 0;
          else
            output[SR_STATUS_KEY] = 1;
        } else
          output[SR_STATUS_KEY] = input[SR_STATUS_KEY].asInt();
      } else
        output[SR_STATUS_KEY] = input[SR_STATUS_KEY].asString();
    }

    if (flags & info_series_modality) {
      if ((input_flags & info_series_modality) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_MODALITY_KEY] = input[SR_MODALITY_KEY].asString();
    }
    if (flags & info_series_station) {
      if ((input_flags & info_series_station) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_STATION_KEY] = input[SR_STATION_KEY].asString();
    }
    if (flags & info_series_comment) {
      if ((input_flags & info_series_comment) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the series json object.");
      output[SR_COMMENT_KEY] = input[SR_COMMENT_KEY].asString();
    }
  }
};

}  // namespace onis::database