#include "../../include/database/site_database.hpp"
#include <iostream>
#include <sstream>
#include "../../include/database/sql_builder.hpp"

using onis::database::lock_mode;

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
  sql_builder_ = std::make_unique<onis::database::sql_builder>(
      onis::database::sql_builder::detect_engine(connection_));
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
// Utility methods
//------------------------------------------------------------------------------

std::unique_ptr<onis_kit::database::database_query>
site_database::create_and_prepare_query(const std::string& columns,
                                        const std::string& from,
                                        const std::string& where,
                                        lock_mode lock) const {
  std::string sql =
      sql_builder_->build_select_query(columns, from, where, "", 0, lock);
  auto query = connection_->create_query();
  if (!query->prepare(sql)) {
    return nullptr;
  }
  return query;
}

std::unique_ptr<onis_kit::database::database_query>
site_database::prepare_query(const std::string& sql,
                             const std::string& context) const {
  auto query = connection_->create_query();
  if (!query->prepare(sql)) {
    std::string error_msg = "Failed to prepare query";
    if (!context.empty()) {
      error_msg += " for " + context;
    }
    error_msg += ": " + sql;
    std::throw_with_nested(std::runtime_error(error_msg));
  }
  return query;
}

std::unique_ptr<onis_kit::database::database_result>
site_database::execute_query(
    std::unique_ptr<onis_kit::database::database_query>& query) const {
  if (!query) {
    throw std::runtime_error("Query is null");
  }
  return query->execute();
}

void site_database::execute_and_check_affected(
    std::unique_ptr<onis_kit::database::database_query>& query,
    const std::string& message) const {
  auto result = execute_query(query);

  // Check if any rows were affected
  if (result->get_affected_rows() == 0) {
    throw std::runtime_error(message);
  }
}