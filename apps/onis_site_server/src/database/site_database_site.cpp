#include <iostream>
#include <sstream>
#include "../../include/database/items/db_site.hpp"
#include "../../include/database/site_database.hpp"
#include "../../include/database/sql_builder.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Site operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_site_columns(u32 flags, bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_sites." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "organization_id, " + prefix + "name";
  }
  if (flags & onis::database::info_site_name) {
    return prefix + "id, " + prefix + "organization_id, " + prefix + "name";
  }
  return prefix + "id, " + prefix + "organization_id";
}

void site_database::read_site_record(onis_kit::database::database_row& rec,
                                     u32 flags, std::string* org_seq,
                                     json& output) {
  onis::database::site::create(output, flags);
  output[BASE_SEQ_KEY] = rec.get_string("id", false, false);
  if (org_seq) {
    *org_seq = rec.get_string("organization_id", false, false);
  }
  if (flags & onis::database::info_site_name) {
    output[SI_NAME_KEY] = rec.get_string(SI_NAME_KEY, false, false);
  }
}

//------------------------------------------------------------------------------
// Lock site
//------------------------------------------------------------------------------

void site_database::lock_site(const std::string& seq, lock_mode lock) {
  // Create and prepare query:
  std::string columns = get_site_columns(0, false);
  std::string where = "id = ?";
  auto query = create_and_prepare_query(columns, "pacs_sites", where, lock);

  // Bind the seq parameter
  if (!query->bind_parameter(1, seq)) {
    std::throw_with_nested(std::runtime_error("Failed to bind seq parameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Ensure the site exists:
  if (!result->has_rows()) {
    throw std::runtime_error("Site not found");
  }
}

//------------------------------------------------------------------------------
// Find sites
//------------------------------------------------------------------------------

void site_database::find_site_by_seq(const std::string& seq, u32 flags,
                                     lock_mode lock, std::string* org_seq,
                                     json& output) {
  // Create and prepare query:
  std::string columns = get_site_columns(flags, false);
  std::string where = "id = ?";
  auto query = create_and_prepare_query(columns, "pacs_sites", where, lock);

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
      read_site_record(*row, flags, org_seq, output);
      return;
    }
  }
  throw std::runtime_error("Site not found");
}

void site_database::find_single_site(u32 flags, lock_mode lock,
                                     std::string* org_seq, json& output) {
  // Create and prepare query:
  std::string columns = get_site_columns(flags, false);
  auto query = create_and_prepare_query(columns, "pacs_sites", "", lock);

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    auto row = result->get_next_row();
    if (row) {
      read_site_record(*row, flags, org_seq, output);
      if (result->get_next_row()) {
        throw std::runtime_error("Multiple sites found");
      }
      return;
    }
  }
  throw std::runtime_error("Site not found");
}

/*void find_all_sites(const std::string& seq, u32 flags, lock_mode lock,
std::vector<std::string>& org_seqs, json& output);*/
