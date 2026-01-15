#include <iostream>
#include <sstream>
#include "../../include/database/items/db_item.hpp"
#include "../../include/database/items/db_organization.hpp"
#include "../../include/database/site_database.hpp"
#include "../../include/database/sql_builder.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Organization operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_organization_columns(u32 flags,
                                                    bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_organizations." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "name";
  }
  if (flags & onis::database::info_organization_name) {
    return prefix + "id, " + prefix + "name";
  }
  return prefix + "id";
}

void site_database::read_organization_record(
    onis_kit::database::database_row& rec, u32 flags, json& output) {
  onis::database::organization::create(output, flags);
  output[BASE_SEQ_KEY] = rec.get_string("id", false, false);
  if (flags & onis::database::info_organization_name) {
    output[OR_NAME_KEY] = rec.get_string(OR_NAME_KEY, false, false);
  }
}

//------------------------------------------------------------------------------
// Find organizations
//------------------------------------------------------------------------------

void site_database::find_organization_by_seq(const std::string& seq, u32 flags,
                                             lock_mode lock, json& output) {
  // Query and prepare query:
  std::string columns = get_organization_columns(flags, false);
  std::string where = "id = ?";
  auto query =
      create_and_prepare_query(columns, "pacs_organizations", where, lock);

  // Bind the seq parameter
  if (!query->bind_parameter(1, seq)) {
    std::throw_with_nested(std::runtime_error("Failed to bind seq parameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    auto row = result->get_next_row();
    if (row) {
      read_organization_record(*row, flags, output);
      return;
    }
  }
  throw std::runtime_error("Organization not found");
}
