#pragma once

#include "../../exceptions/site_server_exceptions.hpp"
#include "./db_item.hpp"

using json = Json::Value;

#define DI_SERIES_KEY "series"
#define DI_NUM_KEY "num"
#define DI_PATH_KEY "path"
#define DI_TYPE_KEY "type"
#define DI_RESCNT_KEY "rescnt"
#define DI_RESULT_KEY "result"

namespace onis::database {

struct download_image {
  static void create(json& output) {
    if (!output.isObject()) {
      throw site_server_exception(EOS_PARAM,
                                  "download_image is not an json object");
    }
    output.clear();
    output[BASE_SEQ_KEY] = "";
    output[BASE_VERSION_KEY] = "1.0.0";
    output[DI_SERIES_KEY] = "";
    output[DI_NUM_KEY] = 0;
    output[DI_PATH_KEY] = "";
    output[DI_TYPE_KEY] = -1;
    output[DI_RESCNT_KEY] = 1;
    output[DI_RESULT_KEY] = EOS_NONE;
  }

  static void verify(const json& input, bool with_seq) {
    // verify:
    if (with_seq) {
      onis::database::item::verify_uuid_value(input, BASE_SEQ_KEY, false,
                                              false);
    }
    onis::database::item::verify_string_value(input, BASE_VERSION_KEY, false,
                                              false, "1.0.0");
    onis::database::item::verify_uuid_value(input, DI_SERIES_KEY, false, false);
    onis::database::item::verify_integer_value(input, DI_NUM_KEY, false, 0);
    onis::database::item::verify_string_value(input, DI_PATH_KEY, false, false);
    onis::database::item::verify_integer_value(input, DI_TYPE_KEY, false, -1);
    onis::database::item::verify_integer_value(input, DI_RESCNT_KEY, false, 1);
    onis::database::item::verify_integer_value(input, DI_RESULT_KEY, false, 0);
  }

  static void copy(const json& input, json& output) {
    create(output);
    output[DI_SERIES_KEY] = input[DI_SERIES_KEY].asString();
    output[DI_NUM_KEY] = input[DI_NUM_KEY].asInt();
    output[DI_PATH_KEY] = input[DI_PATH_KEY].asString();
    output[DI_TYPE_KEY] = input[DI_TYPE_KEY].asInt();
    output[DI_RESCNT_KEY] = input[DI_RESCNT_KEY].asInt();
    output[DI_RESULT_KEY] = input[DI_RESULT_KEY].asInt();
  }
};
}  // namespace onis::database
