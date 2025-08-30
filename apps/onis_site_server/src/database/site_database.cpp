#include "database/site_database.hpp"

site_database::site_database(
    std::unique_ptr<onis_kit::database::database_connection>&& connection)
    : connection_(std::move(connection)) {}

site_database::~site_database() {
  // Connection is managed by unique_ptr, will be automatically cleaned up
}

onis_kit::database::database_connection& site_database::get_connection() {
  return *connection_;
}

const onis_kit::database::database_connection& site_database::get_connection()
    const {
  return *connection_;
}