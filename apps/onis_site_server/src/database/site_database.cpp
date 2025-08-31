#include "../../include/database/site_database.hpp"
#include <iostream>
#include <sstream>

////////////////////////////////////////////////////////////////////////////////
// site_database
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

site_database::site_database(
    std::unique_ptr<onis_kit::database::database_connection>&& connection)
    : connection_(std::move(connection)) {
  std::cout << "site_database: Constructor" << std::endl;
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

site_database::~site_database() {
  std::cout << "site_database: Destructor" << std::endl;
}

//------------------------------------------------------------------------------
// connection access
//------------------------------------------------------------------------------

onis_kit::database::database_connection& site_database::get_connection() {
  return *connection_;
}

const onis_kit::database::database_connection& site_database::get_connection()
    const {
  return *connection_;
}

//------------------------------------------------------------------------------
// organization operations
//------------------------------------------------------------------------------

std::string site_database::get_organization_columns(bool add_table_name) {
  std::string prefix = add_table_name ? "organizations." : "";
  return prefix + "id, " + prefix + "name, " + prefix + "description, " +
         prefix + "created_at, " + prefix + "updated_at";
}

/*
onis::astring columns;
  if (add_table_name) {

    if (flags == onis::server::info_all) columns = "PACS_ORGANIZATIONS.ID,
PACS_ORGANIZATIONS.NAME"; else {

      columns = "PACS_ORGANIZATIONS.ID";
      if (flags & onis::server::info_organization_name) columns += ",
PACS_ORGANIZATIONS.NAME";

    }

  }
  else {

    if (flags == onis::server::info_all) columns = "ID, NAME";
    else {

      columns = "ID";
      if (flags & onis::server::info_organization_name) columns += ", NAME";

    }

  }
  return columns;
*/

std::vector<json> site_database::find_organizations(
    const std::string& where_clause, dgc::result& res) {
  std::vector<json> organizations;

  try {
    std::string sql =
        "SELECT " + get_organization_columns(true) + " FROM organizations";
    if (!where_clause.empty()) {
      sql += " WHERE " + where_clause;
    }
    sql += " ORDER BY name";

    auto query = connection_->create_query();
    if (!query->prepare(sql)) {
      res.set(OSRSP_FAILURE, EOS_DB_QUERY,
              "Failed to prepare query: " + connection_->get_last_error(),
              false);
      return organizations;
    }

    auto result = query->execute();
    if (!result) {
      res.set(OSRSP_FAILURE, EOS_DB_QUERY,
              "Failed to execute query: " + connection_->get_last_error(),
              false);
      return organizations;
    }

    while (result->has_rows()) {
      auto row = result->get_next_row();
      if (!row)
        break;

      json org;
      org["id"] = row->get_int("id");
      org["name"] = row->get_string("name");
      org["description"] = row->get_string("description");
      org["created_at"] = row->get_string("created_at");
      org["updated_at"] = row->get_string("updated_at");

      organizations.push_back(org);
    }

    res.set(OSRSP_SUCCESS, 0, "", false);

  } catch (const std::exception& e) {
    res.set(OSRSP_FAILURE, EOS_DB_QUERY,
            "Exception in find_organizations: " + std::string(e.what()), false);
  }

  return organizations;
}

std::optional<json> site_database::find_organization(
    const std::string& where_clause, dgc::result& res) {
  try {
    std::string sql =
        "SELECT " + get_organization_columns(true) + " FROM organizations";
    if (!where_clause.empty()) {
      sql += " WHERE " + where_clause;
    }
    sql += " LIMIT 1";

    auto query = connection_->create_query();
    if (!query->prepare(sql)) {
      res.set(OSRSP_FAILURE, EOS_DB_QUERY,
              "Failed to prepare query: " + connection_->get_last_error(),
              false);
      return std::nullopt;
    }

    auto result = query->execute();
    if (!result || !result->has_rows()) {
      res.set(OSRSP_FAILURE, EOS_NOT_FOUND, "Organization not found", false);
      return std::nullopt;
    }

    auto row = result->get_next_row();
    if (!row) {
      res.set(OSRSP_FAILURE, EOS_NOT_FOUND, "Organization not found", false);
      return std::nullopt;
    }

    json org;
    org["id"] = row->get_int("id");
    org["name"] = row->get_string("name");
    org["description"] = row->get_string("description");
    org["created_at"] = row->get_string("created_at");
    org["updated_at"] = row->get_string("updated_at");

    res.set(OSRSP_SUCCESS, 0, "", false);
    return org;

  } catch (const std::exception& e) {
    res.set(OSRSP_FAILURE, EOS_DB_QUERY,
            "Exception in find_organization: " + std::string(e.what()), false);
    return std::nullopt;
  }
}

std::optional<json> site_database::find_organization_by_seq(
    const std::string& seq, dgc::result& res) {
  return find_organization("seq = '" + seq + "'", res);
}

bool site_database::create_organization(const json& organization_data,
                                        dgc::result& res) {
  try {
    std::string sql =
        "INSERT INTO organizations (name, description, created_at, updated_at) "
        "VALUES (?, ?, NOW(), NOW())";

    auto query = connection_->create_query();
    if (!query->prepare(sql)) {
      res.set(
          OSRSP_FAILURE, EOS_DB_QUERY,
          "Failed to prepare insert query: " + connection_->get_last_error(),
          false);
      return false;
    }

    // Bind parameters
    query->bind_parameter(1, organization_data.value("name", ""));
    query->bind_parameter(2, organization_data.value("description", ""));

    if (!query->execute_non_query()) {
      res.set(OSRSP_FAILURE, EOS_DB_QUERY,
              "Failed to execute insert: " + connection_->get_last_error(),
              false);
      return false;
    }

    res.set(OSRSP_SUCCESS, 0, "", false);
    return true;

  } catch (const std::exception& e) {
    res.set(OSRSP_FAILURE, EOS_DB_QUERY,
            "Exception in create_organization: " + std::string(e.what()),
            false);
    return false;
  }
}

bool site_database::update_organization(const std::string& where_clause,
                                        const json& organization_data,
                                        dgc::result& res) {
  try {
    std::string sql =
        "UPDATE organizations SET name = ?, description = ?, updated_at = "
        "NOW()";
    if (!where_clause.empty()) {
      sql += " WHERE " + where_clause;
    }

    auto query = connection_->create_query();
    if (!query->prepare(sql)) {
      res.set(
          OSRSP_FAILURE, EOS_DB_QUERY,
          "Failed to prepare update query: " + connection_->get_last_error(),
          false);
      return false;
    }

    // Bind parameters
    query->bind_parameter(1, organization_data.value("name", ""));
    query->bind_parameter(2, organization_data.value("description", ""));

    if (!query->execute_non_query()) {
      res.set(OSRSP_FAILURE, EOS_DB_QUERY,
              "Failed to execute update: " + connection_->get_last_error(),
              false);
      return false;
    }

    res.set(OSRSP_SUCCESS, 0, "", false);
    return true;

  } catch (const std::exception& e) {
    res.set(OSRSP_FAILURE, EOS_DB_QUERY,
            "Exception in update_organization: " + std::string(e.what()),
            false);
    return false;
  }
}

bool site_database::delete_organization(const std::string& where_clause,
                                        dgc::result& res) {
  try {
    std::string sql = "DELETE FROM organizations";
    if (!where_clause.empty()) {
      sql += " WHERE " + where_clause;
    }

    auto query = connection_->create_query();
    if (!query->prepare(sql)) {
      res.set(
          OSRSP_FAILURE, EOS_DB_QUERY,
          "Failed to prepare delete query: " + connection_->get_last_error(),
          false);
      return false;
    }

    if (!query->execute_non_query()) {
      res.set(OSRSP_FAILURE, EOS_DB_QUERY,
              "Failed to execute delete: " + connection_->get_last_error(),
              false);
      return false;
    }

    res.set(OSRSP_SUCCESS, 0, "", false);
    return true;

  } catch (const std::exception& e) {
    res.set(OSRSP_FAILURE, EOS_DB_QUERY,
            "Exception in delete_organization: " + std::string(e.what()),
            false);
    return false;
  }
}