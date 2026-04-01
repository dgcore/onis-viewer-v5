#pragma once

#include "./db_item.hpp"
#include "onis_kit/include/core/exception.hpp"

using json = Json::Value;

#define DS_SERIES_KEY "series"
#define DS_SESSION_KEY "session"
#define DS_DATE_KEY "date"
#define DS_COMPLETED_KEY "completed"
#define DS_RESULT_KEY "result"
#define DS_EXPECTED_KEY "expected"
#define DS_IMAGES_KEY "images"

namespace onis::database {

struct download_series {
  static void create(json& output) {
    if (!output.isObject()) {
      throw onis::exception(EOS_PARAM, "download_series is not an json object");
    }
    output.clear();
    output[BASE_SEQ_KEY] = "";
    output[BASE_VERSION_KEY] = "1.0.0";
    output[DS_SERIES_KEY] = "";
    output[DS_SESSION_KEY] = "";
    output[DS_DATE_KEY] = "";
    output[DS_COMPLETED_KEY] = 1;
    output[DS_RESULT_KEY] = EOS_NONE;
    output[DS_EXPECTED_KEY] = -1;
  }

  static void verify(const json& input, bool with_seq) {
    // verify:
    if (with_seq) {
      onis::database::item::verify_uuid_value(input, BASE_SEQ_KEY, false,
                                              false);
    }
    onis::database::item::verify_string_value(input, BASE_VERSION_KEY, false,
                                              false, "1.0.0");
    onis::database::item::verify_string_value(input, DS_SERIES_KEY, false,
                                              false);
    onis::database::item::verify_string_value(input, DS_SESSION_KEY, false,
                                              false);
    onis::database::item::verify_string_value(input, DS_DATE_KEY, false, false);
    onis::database::item::verify_integer_value(input, DS_COMPLETED_KEY, false,
                                               0);
    onis::database::item::verify_integer_value(input, DS_RESULT_KEY, false, 0);
    onis::database::item::verify_integer_value(input, DS_EXPECTED_KEY, false,
                                               0);
  }

  static void copy(const json& input, json& output) {
    create(output);
    output[DS_SERIES_KEY] = input[DS_SERIES_KEY].asString();
    output[DS_SESSION_KEY] = input[DS_SESSION_KEY].asString();
    output[DS_DATE_KEY] = input[DS_DATE_KEY].asString();
    output[DS_COMPLETED_KEY] = input[DS_COMPLETED_KEY].asInt();
    output[DS_RESULT_KEY] = input[DS_RESULT_KEY].asInt();
    output[DS_EXPECTED_KEY] = input[DS_EXPECTED_KEY].asInt();
  }
};
}  // namespace onis::database
