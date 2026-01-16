#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define RPTT_NAME_KEY "name"
#define RPTT_VERSION_KEY "template_version"
#define RPTT_FILTERS_KEY "filters"
#define RPTT_STATUS_KEY "status"
#define RPTT_MEDIA_KEY "media"

namespace onis::database {

const s32 info_report_template_version = 2;
const s32 info_report_template_media = 4;
const s32 info_report_template_name = 8;
const s32 info_report_template_status = 16;
const s32 info_report_template_filters = 32;

struct report_template {
  static void create(json& item, u32 flags) {
    if (!item.isObject()) {
      throw std::invalid_argument("report_template is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags & info_report_template_version)
      item[RPTT_VERSION_KEY] = "";
    if (flags & info_report_template_media)
      item[RPTT_MEDIA_KEY] = -1;
    if (flags & info_report_template_name)
      item[RPTT_NAME_KEY] = "";
    if (flags & info_report_template_filters)
      item[RPTT_FILTERS_KEY] = "[]";
    if (flags & info_report_template_status)
      item[RPTT_STATUS_KEY] = 0;
  }
};

static void verify(const json& input, bool with_seq, u32 must_flags) {
  onis::database::item::verify_seq_version_flags(input, with_seq);
  u32 flags = input[BASE_FLAGS_KEY].asUInt();
  onis::database::item::check_must_flags(flags, must_flags, res);

  if (flags & info_report_template_name)
    onis::database::item::verify_string_value(input, RPTT_NAME_KEY, false,
                                              false, 64);
  if (flags & info_report_template_version)
    onis::database::item::verify_string_value(input, RPTT_VERSION_KEY, false,
                                              false, 64);
  if (flags & info_report_template_status)
    onis::database::item::verify_integer_value(input, RPTT_STATUS_KEY, false, 0,
                                               1);
  if (flags & info_report_template_media)
    onis::database::item::verify_integer_value(input, RPTT_MEDIA_KEY, false, 0);
  if (flags & info_report_template_filters) {
    onis::database::item::verify_string_value(input, RPTT_FILTERS_KEY, false,
                                              false);
    json reader;
    json param;
    if (!reader.parse(input[RPTT_FILTERS_KEY].asString(), param)) {
      throw std::invalid_argument("Filters must be a valid JSON object");
    }
  }
}

}  // namespace onis::database