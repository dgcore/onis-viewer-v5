#pragma once

#include "../../exceptions/site_server_exceptions.hpp"
#include "./db_item.hpp"

using json = Json::Value;

#define PA_SEQ_KEY "seq"
#define PA_UID_KEY "uid"
#define PA_CHARSET_KEY "charset"
#define PA_NAME_KEY "name"
#define PA_IDEOGRAM_KEY "ideogram"
#define PA_PHONETIC_KEY "phonetic"
#define PA_SEX_KEY "sex"
#define PA_BDATE_KEY "birthdate"
#define PA_BTIME_KEY "birthtime"
#define PA_STCNT_KEY "stcnt"
#define PA_SRCNT_KEY "srcnt"
#define PA_IMCNT_KEY "imcnt"
#define PA_STATUS_KEY "status"
#define PA_CRDATE_KEY "crdate"
#define PA_ORIGIN_ID_KEY "oid"
#define PA_ORIGIN_NAME_KEY "oname"
#define PA_ORIGIN_IP_KEY "oip"

#define ONLINE_STATUS "00000000-0000-4000-0000-000000000000"
#define DELETE_STATUS "11111111-1111-4000-1111-111111111111"

namespace onis::database {

const std::uint32_t info_patient_charset = 1;
const std::uint32_t info_patient_name = 2;
const std::uint32_t info_patient_birthdate = 4;
const std::uint32_t info_patient_sex = 8;
const std::uint32_t info_patient_statistics = 16;
const std::uint32_t info_patient_status = 32;
const std::uint32_t info_patient_creation = 64;

struct patient {
  static void create(json& patient, std::uint32_t flags, bool for_client) {
    if (!patient.isObject()) {
      throw site_server_exception(EOS_PARAM, "patient is not an json object");
    }
    patient.clear();
    patient[BASE_SEQ_KEY] = "";
    patient[BASE_VERSION_KEY] = "1.0.0";
    patient[BASE_FLAGS_KEY] = flags;
    patient[BASE_UID_KEY] = "";

    if (flags & info_patient_charset)
      patient[PA_CHARSET_KEY] = "";
    if (flags & info_patient_name) {
      patient[PA_NAME_KEY] = "";
      patient[PA_IDEOGRAM_KEY] = "";
      patient[PA_PHONETIC_KEY] = "";
    }
    if (flags & info_patient_birthdate) {
      patient[PA_BDATE_KEY] = "";
      patient[PA_BTIME_KEY] = "";
    }
    if (flags & info_patient_sex)
      patient[PA_SEX_KEY] = "";
    if (flags & info_patient_statistics) {
      patient[PA_STCNT_KEY] = 0;
      patient[PA_SRCNT_KEY] = 0;
      patient[PA_IMCNT_KEY] = 0;
    }
    if (flags & info_patient_status) {
      if (for_client)
        patient[PA_STATUS_KEY] = 0;
      else
        patient[PA_STATUS_KEY] = "";
    }
    if (flags & info_patient_creation) {
      patient[PA_CRDATE_KEY] = "";
      patient[PA_ORIGIN_ID_KEY] = "";
      patient[PA_ORIGIN_NAME_KEY] = "";
      patient[PA_ORIGIN_IP_KEY] = "";
    }
  }

  static void verify(const json& input, bool with_seq, bool for_client) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    std::uint32_t flags = input[BASE_FLAGS_KEY].asUInt();
    if (flags & info_patient_charset)
      onis::database::item::verify_string_value(input, PA_CHARSET_KEY, true,
                                                true, 255);
    if (flags & info_patient_name) {
      onis::database::item::verify_string_value(input, PA_NAME_KEY, true, true,
                                                64);
      onis::database::item::verify_string_value(input, PA_IDEOGRAM_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, PA_PHONETIC_KEY, true,
                                                true, 64);
    }
    if (flags & info_patient_birthdate) {
      onis::database::item::verify_string_value(input, PA_BDATE_KEY, true, true,
                                                8);
      onis::database::item::verify_string_value(input, PA_BTIME_KEY, true, true,
                                                20);
    }
    if (flags & info_patient_sex)
      onis::database::item::verify_string_value(input, PA_SEX_KEY, true, true,
                                                1);
    if (flags & info_patient_statistics) {
      onis::database::item::verify_integer_value(input, PA_STCNT_KEY, false, 0);
      onis::database::item::verify_integer_value(input, PA_SRCNT_KEY, false, 0);
      onis::database::item::verify_integer_value(input, PA_IMCNT_KEY, false, 0);
    }

    if (flags & info_patient_status) {
      if (for_client)
        onis::database::item::verify_integer_value(input, PA_STATUS_KEY, false);
      else
        onis::database::item::verify_uuid_value(input, PA_STATUS_KEY, false,
                                                false);
    }

    if (flags & info_patient_creation) {
      onis::database::item::verify_string_value(input, PA_CRDATE_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, PA_ORIGIN_ID_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, PA_ORIGIN_NAME_KEY, true,
                                                true, 255);
      onis::database::item::verify_string_value(input, PA_ORIGIN_IP_KEY, true,
                                                true, 255);
    }
  }

  static void copy(const json& input, std::uint32_t flags, bool for_client,
                   json& output) {
    create(output, flags, for_client);
    output[BASE_UID_KEY] = input[BASE_UID_KEY].asString();
    std::uint32_t input_flags = input[BASE_FLAGS_KEY].asUInt();

    if (flags & info_patient_charset) {
      if ((input_flags & info_patient_charset) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the patient json object.");
      output[PA_CHARSET_KEY] = input[PA_CHARSET_KEY].asString();
    }

    if (flags & info_patient_name) {
      if ((input_flags & info_patient_name) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the patient json object.");
      output[PA_NAME_KEY] = input[PA_NAME_KEY].asString();
      output[PA_IDEOGRAM_KEY] = input[PA_IDEOGRAM_KEY].asString();
      output[PA_PHONETIC_KEY] = input[PA_PHONETIC_KEY].asString();
    }

    if (flags & info_patient_birthdate) {
      if ((input_flags & info_patient_birthdate) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the patient json object.");
      output[PA_BDATE_KEY] = input[PA_BDATE_KEY].asString();
      output[PA_BTIME_KEY] = input[PA_BTIME_KEY].asString();
    }

    if (flags & info_patient_sex) {
      if ((input_flags & info_patient_sex) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the patient json object.");
      output[PA_SEX_KEY] = input[PA_SEX_KEY].asString();
    }

    if (flags & info_patient_statistics) {
      if ((input_flags & info_patient_statistics) == 0)
        throw site_server_exception(EOS_PARAM,
                                    "Failed to copy the patient json object.");
      output[PA_STCNT_KEY] = input[PA_STCNT_KEY].asInt();
      output[PA_SRCNT_KEY] = input[PA_SRCNT_KEY].asInt();
      output[PA_IMCNT_KEY] = input[PA_IMCNT_KEY].asInt();
    }

    if (flags & info_patient_status) {
      if (for_client)
        onis::database::item::verify_integer_value(input, PA_STATUS_KEY, false);
      else
        onis::database::item::verify_uuid_value(input, PA_STATUS_KEY, false,
                                                false);
    }
    if (flags & info_patient_creation) {
      onis::database::item::verify_string_value(input, PA_CRDATE_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, PA_ORIGIN_ID_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, PA_ORIGIN_NAME_KEY, true,
                                                true, 255);
      onis::database::item::verify_string_value(input, PA_ORIGIN_IP_KEY, true,
                                                true, 255);
    }
  }
};
}  // namespace onis::database
