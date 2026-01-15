#pragma once

#include "db_item.hpp"

using json = nlohmann::json;

#define SO_NAME_KEY "name"
#define SO_SOURCE_ID_KEY "source_id"
#define SO_HAVE_CONFLICT_KEY "conflict"
#define SO_PATIENT_MODE_KEY "pmode"
#define SO_TYPE_KEY "type"
#define SO_CHILDREN_KEY "children"

namespace onis::database {

static const u32 delete_permanently = 1;
static const u32 delete_temporary = 2;
static const u32 delete_upper = 4;

static const s32 type_site = 0;
static const s32 type_partitions = 1;
static const s32 type_partition = 2;
static const s32 type_dicom_clients = 3;
static const s32 type_dicom_client = 4;
static const s32 type_album = 5;
static const s32 type_smart_album = 6;

struct source {
  static void create(json& item, u32 flags) {
    if (!item.is_object()) {
      throw std::invalid_argument("source is not an object");
    }
    item.clear();
    item[BASE_SEQ_KEY] = "";
    item[BASE_VERSION_KEY] = "1.0.0";
    item[BASE_FLAGS_KEY] = flags;
    if (flags != 0) {
      item[SO_NAME_KEY] = "";
      item[SO_SOURCE_ID_KEY] = "";
      item[SO_HAVE_CONFLICT_KEY] = 0;
      item[SO_PATIENT_MODE_KEY] = 0;
      item[SO_TYPE_KEY] = 1;
      item[SO_CHILDREN_KEY] = Json::Value(Json::arrayValue);
    }
  }

  static void verify(const json& input, bool with_seq) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    u32 flags = input[BASE_FLAGS_KEY].get<u32>();
    if (flags != 0) {
      onis::database::item::verify_string_value(input, SO_NAME_KEY, false,
                                                false, 64);
      onis::database::item::verify_string_value(input, SO_SOURCE_ID_KEY, false,
                                                false, 255);
      onis::database::verify_integer_value(input, SO_HAVE_CONFLICT_KEY, false,
                                           0, 1);
      onis::database::verify_integer_value(input, SO_PATIENT_MODE_KEY, false,
                                           0);
      onis::database::item::verify_array_value(input, SO_CHILDREN_KEY, false);
    }
  }
};

}  // namespace onis::database
