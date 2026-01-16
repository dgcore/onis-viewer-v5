#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define RPT_STATUS_KEY "status"
#define RPT_READING_DOC_KEY "rdoc"
#define RPT_READING_INST_KEY "rinst"
#define RPT_VERIF_DOC_KEY "vdoc"
#define RPT_VERIF_INST_KEY "vinst"
#define RPT_TEMPLATE_ID_KEY "template_id"
#define RPT_CREATE_DATE_KEY "create_date"
#define RPT_MODIF_DATE_KEY "modif_date"
#define RPT_VERIF_DATE_KEY "verif_date"
#define RPT_MEDIA_KEY "media"
#define RPT_PATH_KEY "path"
#define RPT_CRDATE_KEY "crdate"
#define RPT_UPDATE_KEY "update"

namespace onis::database {

const s32 info_report_status = 2;
const s32 info_report_reading_doctor = 4;
const s32 info_report_verify_doctor = 8;
const s32 info_report_study = 16;
const s32 info_report_media = 32;
const s32 info_report_template = 64;
const s32 info_report_date = 128;
const s32 info_report_creation = 256;
const s32 info_report_update = 512;

struct report {
  static void create(json& item, u32 flags) {
    if (!item.isObject()) {
      throw std::invalid_argument("report is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    item[BASE_UID_KEY] = "";

    if (flags & info_report_status)
      item[RPT_STATUS_KEY] = -1;
    if (flags & info_report_reading_doctor) {
      item[RPT_READING_DOC_KEY] = "";
      item[RPT_READING_INST_KEY] = "";
    }
    if (flags & info_report_verify_doctor) {
      item[RPT_VERIF_DOC_KEY] = "";
      item[RPT_VERIF_INST_KEY] = "";
    }
    if (flags & info_report_template) {
      item[RPT_TEMPLATE_ID_KEY] = "";
    }
    if (flags & info_report_date) {
      item[RPT_CREATE_DATE_KEY] = "";
      item[RPT_MODIF_DATE_KEY] = "";
      item[RPT_VERIF_DATE_KEY] = "";
    }
    if (flags & info_report_creation) {
      item[RPT_CRDATE_KEY] = "";
    }
    if (flags & info_report_update)
      item[RPT_UPDATE_KEY] = 0;
  }
};

static void verify(const json& input, bool with_seq, u32 must_flags) {
  onis::database::item::verify_seq_version_flags(input, with_seq);
  u32 flags = input[BASE_FLAGS_KEY].asUInt();
  onis::server::item::check_must_flags(flags, must_flags, res);

  if (flags & info_report_status)
    onis::database::item::verify_integer_value(input, RPT_STATUS_KEY, false, 0,
                                               2);
  if (flags & info_report_reading_doctor) {
    onis::database::item::verify_string_value(input, RPT_READING_DOC_KEY, true,
                                              true, 255);
    onis::database::item::verify_string_value(input, RPT_READING_INST_KEY, true,
                                              true, 64);
  }
  if (flags & info_report_verify_doctor) {
    onis::database::item::verify_string_value(input, RPT_VERIF_DOC_KEY, true,
                                              true, 255);
    onis::database::item::verify_string_value(input, RPT_VERIF_INST_KEY, true,
                                              true, 64);
  }
  if (flags & info_report_template)
    onis::database::item::verify_uuid_value(input, RPT_TEMPLATE_ID_KEY, false,
                                            false);
  if (flags & info_report_date) {
    onis::database::item::verify_string_value(input, RPT_CREATE_DATE_KEY, false,
                                              false, 255);
    onis::database::item::verify_string_value(input, RPT_MODIF_DATE_KEY, false,
                                              false, 255);
    onis::database::item::verify_string_value(input, RPT_VERIF_DATE_KEY, false,
                                              false, 255);
  }
  if (flags & info_report_creation) {
    onis::database::item::verify_string_value(input, RPT_CRDATE_KEY, false,
                                              false);
    if (!onis::util::datetime::extract_date_and_time(
            input[RPT_CREATE_DATE_KEY].asString(), dt, OSFALSE, OSTRUE) ||
        !onis::util::datetime::extract_date_and_time(
            input[RPT_MODIF_DATE_KEY].asString(), dt, OSFALSE, OSTRUE) ||
        !onis::util::datetime::extract_date_and_time(
            input[RPT_VERIF_DATE_KEY].asString(), dt, OSFALSE, OSTRUE))
      res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);
  }
  if (flags & info_report_update) {
    onis::database::item::verify_integer_value(input, RPT_UPDATE_KEY, false, 0,
                                               1);
    onis::core::date_time dt;
    if (!onis::util::datetime::extract_date_and_time(value, dt, OSFALSE,
                                                     OSTRUE))
      res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);
  }
}

}  // namespace onis::database