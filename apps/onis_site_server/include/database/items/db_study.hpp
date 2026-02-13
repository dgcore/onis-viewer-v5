#pragma once

#include "../../exceptions/site_server_exceptions.hpp"
#include "./db_item.hpp"
#include "./db_patient.hpp"
#include "onis_kit/include/core/result.hpp"

using json = Json::Value;

#define ST_SEQ_KEY "seq"
#define ST_UID_KEY "uid"
#define ST_CHARSET_KEY "charset"
#define ST_DATE_KEY "date"
#define ST_TIME_KEY "time"
#define ST_MODALITIES_KEY "modalities"
#define ST_BODYPARTS_KEY "bodyparts"
#define ST_ACCNUM_KEY "accnum"
#define ST_STUDYID_KEY "study_id"
#define ST_DESC_KEY "desc"
#define ST_AGE_KEY "age"
#define ST_INSTITUTION_KEY "institution"
#define ST_COMMENT_KEY "comment"
#define ST_STATIONS_KEY "stations"
#define ST_SRCNT_KEY "srcnt"
#define ST_IMCNT_KEY "imcnt"
#define ST_RPTCNT_KEY "rptcnt"
#define ST_STATUS_KEY "status"
#define ST_CONFLICT_KEY "conflict"
#define ST_CRDATE_KEY "crdate"
#define ST_ORIGIN_ID_KEY "oid"
#define ST_ORIGIN_NAME_KEY "oname"
#define ST_ORIGIN_IP_KEY "oip"

namespace onis::database {

const std::uint32_t info_study_character_set = 2;
const std::uint32_t info_study_modalities = 4;
const std::uint32_t info_study_accnum = 8;
const std::uint32_t info_study_id = 16;
const std::uint32_t info_study_description = 32;
const std::uint32_t info_study_body_parts = 64;
const std::uint32_t info_study_age = 128;
const std::uint32_t info_study_date = 256;
const std::uint32_t info_study_statistics = 1024;
const std::uint32_t info_study_creation = 2048;
const std::uint32_t info_study_status = 4096;
const std::uint32_t info_study_report_status = 8192;
const std::uint32_t info_study_comment = 16384;
const std::uint32_t info_study_institution = 32768;
const std::uint32_t info_study_stations = 65536;

struct study {
  static void create(json& study, std::uint32_t flags, bool for_client) {
    if (!study.isObject()) {
      throw site_server_exception(EOS_PARAM, "study is not an json object");
    }
    study.clear();
    study[BASE_SEQ_KEY] = "";
    study[BASE_VERSION_KEY] = "1.0.0";
    study[BASE_FLAGS_KEY] = flags;
    study[BASE_UID_KEY] = "";

    if (flags & info_study_character_set)
      study[ST_CHARSET_KEY] = "";
    if (flags & info_study_modalities)
      study[ST_MODALITIES_KEY] = "";
    if (flags & info_study_accnum)
      study[ST_ACCNUM_KEY] = "";
    if (flags & info_study_id)
      study[ST_STUDYID_KEY] = "";
    if (flags & info_study_description)
      study[ST_DESC_KEY] = "";
    if (flags & info_study_body_parts)
      study[ST_BODYPARTS_KEY] = "";
    if (flags & info_study_age)
      study[ST_AGE_KEY] = "";
    if (flags & info_study_date) {
      study[ST_DATE_KEY] = "";
      study[ST_TIME_KEY] = "";
    }

    if (flags & info_study_statistics) {
      study[ST_SRCNT_KEY] = 0;
      study[ST_IMCNT_KEY] = 0;
      study[ST_RPTCNT_KEY] = 0;
    }
    if (flags & info_study_creation) {
      study[ST_CRDATE_KEY] = "";
      study[ST_ORIGIN_ID_KEY] = "";
      study[ST_ORIGIN_NAME_KEY] = "";
      study[ST_ORIGIN_IP_KEY] = "";
    }
    if (flags & info_study_status) {
      if (for_client)
        study[ST_STATUS_KEY] = 0;
      else {
        study[ST_STATUS_KEY] = "";
        study[ST_CONFLICT_KEY] = "";
      }
    }
    // if (flags & info_study_report_status study[ST_STUDYID_KEY] = "";
    if (flags & info_study_comment)
      study[ST_COMMENT_KEY] = "";
    if (flags & info_study_institution)
      study[ST_INSTITUTION_KEY] = "";
    if (flags & info_study_stations)
      study[ST_STATIONS_KEY] = "";
  }

  static void verify(const json& input, bool with_seq, bool for_client) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    std::uint32_t flags = input[BASE_FLAGS_KEY].asUInt();

    if (flags & info_study_character_set)
      onis::database::item::verify_string_value(input, ST_CHARSET_KEY, true,
                                                true, 255);
    if (flags & info_study_modalities)
      onis::database::item::verify_string_value(input, ST_MODALITIES_KEY, true,
                                                true, 255);
    if (flags & info_study_accnum)
      onis::database::item::verify_string_value(input, ST_ACCNUM_KEY, true,
                                                true, 255);
    if (flags & info_study_id)
      onis::database::item::verify_string_value(input, ST_STUDYID_KEY, true,
                                                true, 255);
    if (flags & info_study_description)
      onis::database::item::verify_string_value(input, ST_DESC_KEY, true, true,
                                                255);
    if (flags & info_study_body_parts)
      onis::database::item::verify_string_value(input, ST_BODYPARTS_KEY, true,
                                                true);
    if (flags & info_study_age)
      onis::database::item::verify_string_value(input, ST_AGE_KEY, true, true,
                                                255);
    if (flags & info_study_date) {
      onis::database::item::verify_string_value(input, ST_DATE_KEY, true, true,
                                                8);
      onis::database::item::verify_string_value(input, ST_TIME_KEY, true, true,
                                                20);
    }
    if (flags & info_study_statistics) {
      onis::database::item::verify_integer_value(input, ST_SRCNT_KEY, true, 0);
      onis::database::item::verify_integer_value(input, ST_IMCNT_KEY, true, 0);
      onis::database::item::verify_integer_value(input, ST_RPTCNT_KEY, true, 0);
    }

    if (flags & info_study_creation) {
      onis::database::item::verify_string_value(input, ST_CRDATE_KEY, false,
                                                false, 64);
      onis::database::item::verify_string_value(input, ST_ORIGIN_ID_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, ST_ORIGIN_NAME_KEY, true,
                                                true, 255);
      onis::database::item::verify_string_value(input, ST_ORIGIN_IP_KEY, true,
                                                true, 255);
    }

    if (flags & info_study_status) {
      if (for_client)
        onis::database::item::verify_integer_value(input, ST_STATUS_KEY, false);
      else {
        onis::database::item::verify_string_value(input, ST_STATUS_KEY, false,
                                                  false);
        onis::database::item::verify_string_value(input, ST_CONFLICT_KEY, false,
                                                  false);
      }
    }
    if (flags & info_study_comment)
      onis::database::item::verify_string_value(input, ST_COMMENT_KEY, true,
                                                true);
    if (flags & info_study_institution)
      onis::database::item::verify_string_value(input, ST_INSTITUTION_KEY, true,
                                                true, 255);
    if (flags & info_study_stations)
      onis::database::item::verify_string_value(input, ST_STATIONS_KEY, true,
                                                true);
  }

  static void copy(const json& input, std::uint32_t flags, bool for_client,
                   json& output) {
    create(output, flags, for_client);
    output[BASE_UID_KEY] = input[BASE_UID_KEY].asString();
    std::uint32_t input_flags = input[BASE_FLAGS_KEY].asUInt();

    if (flags & info_study_character_set) {
      if ((input_flags & info_study_character_set) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_CHARSET_KEY] = input[ST_CHARSET_KEY].asString();
    }

    if (flags & info_study_modalities) {
      if ((input_flags & info_study_modalities) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_MODALITIES_KEY] = input[ST_MODALITIES_KEY].asString();
    }

    if (flags & info_study_accnum) {
      if ((input_flags & info_study_accnum) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_ACCNUM_KEY] = input[ST_ACCNUM_KEY].asString();
    }

    if (flags & info_study_id) {
      if ((input_flags & info_study_id) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_STUDYID_KEY] = input[ST_STUDYID_KEY].asString();
    }

    if (flags & info_study_description) {
      if ((input_flags & info_study_description) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_DESC_KEY] = input[ST_DESC_KEY].asString();
    }

    if (flags & info_study_body_parts) {
      if ((input_flags & info_study_body_parts) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_BODYPARTS_KEY] = input[ST_BODYPARTS_KEY].asString();
    }

    if (flags & info_study_age) {
      if ((input_flags & info_study_age) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_AGE_KEY] = input[ST_AGE_KEY].asString();
    }

    if (flags & info_study_date) {
      if ((input_flags & info_study_date) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_DATE_KEY] = input[ST_DATE_KEY].asString();
      output[ST_TIME_KEY] = input[ST_TIME_KEY].asString();
    }
    // if (flags & info_study_icon study) [ST_STUDYID_KEY] = "";
    if (flags & info_study_statistics) {
      if ((input_flags & info_study_statistics) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_SRCNT_KEY] = input[ST_SRCNT_KEY].asInt();
      output[ST_IMCNT_KEY] = input[ST_IMCNT_KEY].asInt();
      output[ST_RPTCNT_KEY] = input[ST_RPTCNT_KEY].asInt();
    }

    if (flags & info_study_creation) {
      if ((input_flags & info_study_creation) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_CRDATE_KEY] = input[ST_CRDATE_KEY].asString();
      output[ST_ORIGIN_ID_KEY] = input[ST_ORIGIN_ID_KEY].asString();
      output[ST_ORIGIN_NAME_KEY] = input[ST_ORIGIN_NAME_KEY].asString();
      output[ST_ORIGIN_IP_KEY] = input[ST_ORIGIN_IP_KEY].asString();
    }

    if (flags & info_study_status) {
      if ((input_flags & info_study_status) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      if (!for_client && input[ST_STATUS_KEY].type() != Json::stringValue)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      if (for_client) {
        if (input[ST_STATUS_KEY].type() == Json::stringValue) {
          if (input[ST_STATUS_KEY] == ONLINE_STATUS)
            output[ST_STATUS_KEY] = 0;
          else if (input[ST_CONFLICT_KEY].asString().empty())
            output[ST_STATUS_KEY] = 1;
          else
            output[ST_STATUS_KEY] = 2;

        } else
          output[ST_STATUS_KEY] = input[ST_STATUS_KEY].asInt();

      } else {
        output[ST_STATUS_KEY] = input[ST_STATUS_KEY].asString();
        output[ST_CONFLICT_KEY] = input[ST_CONFLICT_KEY].asString();
      }
    }
    // if (flags & info_study_report_status study[ST_STUDYID_KEY] = "";
    if (flags & info_study_comment) {
      if ((input_flags & info_study_comment) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_COMMENT_KEY] = input[ST_COMMENT_KEY].asString();
    }

    if (flags & info_study_institution) {
      if ((input_flags & info_study_institution) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_INSTITUTION_KEY] = input[ST_INSTITUTION_KEY].asString();
    }

    if (flags & info_study_stations) {
      if ((input_flags & info_study_stations) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the study json object.");
      output[ST_STATIONS_KEY] = input[ST_STATIONS_KEY].asString();
    }
  }
};
}  // namespace onis::database
