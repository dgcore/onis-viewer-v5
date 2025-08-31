#pragma once

#include <nlohmann/json.hpp>
#include "db_item.hpp"

using json = nlohmann::json;

#define OR_NAME_KEY "name"

namespace onis {
namespace database {

const s32 info_organization_name = 1;

struct organization {
  static b32 create(json& organization, u32 flags) {
    if (!organization.is_object())
      return OSFALSE;
    organization.clear();
    organization[BASE_SEQ_KEY] = "";
    organization[BASE_VERSION_KEY] = "1.0.0";
    organization[BASE_FLAGS_KEY] = flags;
    if (flags & info_organization_name)
      organization[OR_NAME_KEY] = "";
    return OSTRUE;
  }

  static void verify(const json& input, b32 with_seq, onis::aresult& res) {
    // don't proceed if an error has earlier occurred:
    if (res.status != OSRSP_SUCCESS)
      return;

    // verify:
    if (with_seq)
      onis::database::item::verify_value(input, json::value_t::string,
                                         BASE_SEQ_KEY, res);
    onis::database::item::verify_string_value(input, BASE_VERSION_KEY, "1.0.0",
                                              res);
    onis::database::item::verify_int_or_uint_value(input, BASE_FLAGS_KEY, res);
    if (res.status == OSRSP_SUCCESS) {
      u32 flags = input[BASE_FLAGS_KEY].get<u32>();
      if (flags & info_organization_name)
        onis::database::item::verify_value(input, json::value_t::string,
                                           OR_NAME_KEY, res);
    }
  }
};

}  // namespace database
}  // namespace onis
