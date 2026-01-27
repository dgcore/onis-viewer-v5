#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define DA_ACTIVE_KEY "active"
#define DA_INHERIT_KEY "inherit"
#define DA_MODE_KEY "mode"
#define DA_CLIENTS_KEY "clients"

namespace onis::database {

struct dicom_access {
  static const std::int32_t all_clients = 1;
  static const std::int32_t limited_access = 256;

  static void create(json& access) {
    if (!access.isObject()) {
      throw std::invalid_argument("dicom_access is not an object");
    }
    access.clear();
    access[DA_ACTIVE_KEY] = 1;
    access[DA_INHERIT_KEY] = 0;
    access[DA_MODE_KEY] = 0;
    access[DA_CLIENTS_KEY] = Json::Value(Json::arrayValue);
  }

  static void verify(const json& input) {
    onis::database::item::verify_integer_value(input, DA_ACTIVE_KEY, false, 0,
                                               1);
    onis::database::item::verify_integer_value(input, DA_INHERIT_KEY, false, 0,
                                               1);
    onis::database::item::verify_integer_value(input, DA_MODE_KEY, false, 0,
                                               256);
    std::uint32_t mode = input[DA_MODE_KEY].asUInt();
    if (mode != 256) {
      mode &= ~all_clients;
      mode &= ~limited_access;
      if (mode != 0)
        throw std::invalid_argument("Invalid mode");
    }

    onis::database::item::verify_array_value(input, DA_CLIENTS_KEY, false);
    for (const auto& client : input[DA_CLIENTS_KEY]) {
      onis::database::item::verify_uuid_value(client, nullptr, false, false);
    }
  }
};

}  // namespace onis::database
