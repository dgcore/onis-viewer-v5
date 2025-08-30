#include "database/sqlite/sqlite_connection.hpp"
#include <sqlite3.h>
#include <iostream>
#include <sstream>
#include "database/sqlite/sqlite_query.hpp"
#include "database/sqlite/sqlite_result.hpp"

namespace onis_kit {
namespace database {

sqlite_connection::sqlite_connection() : db_(nullptr), connected_(false) {}

sqlite_connection::~sqlite_connection() {
  disconnect();
}

bool sqlite_connection::connect(const database_config& config) {
  if (connected_) {
    disconnect();
  }

  // For SQLite, we use the database_name as the file path
  std::string db_path = config.database_name;
  if (db_path.empty()) {
    set_last_error("SQLite database path is required");
    return false;
  }

  // Open SQLite database
  int result = sqlite3_open(db_path.c_str(), &db_);
  if (result != SQLITE_OK) {
    set_last_error("Failed to open SQLite database: " +
                   std::string(sqlite3_errmsg(db_)));
    sqlite3_close(db_);
    db_ = nullptr;
    return false;
  }

  // Enable foreign keys
  sqlite3_exec(db_, "PRAGMA foreign_keys = ON", nullptr, nullptr, nullptr);

  connected_ = true;
  config_ = config;
  clear_last_error();
  return true;
}

void sqlite_connection::disconnect() {
  if (db_) {
    sqlite3_close(db_);
    db_ = nullptr;
  }
  connected_ = false;
}

bool sqlite_connection::is_connected() const {
  return connected_ && db_ != nullptr;
}

std::unique_ptr<database_query> sqlite_connection::create_query() {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return nullptr;
  }
  return std::make_unique<sqlite_query>(db_);
}

std::unique_ptr<database_result> sqlite_connection::execute_query(
    const std::string& sql) {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return nullptr;
  }

  sqlite3_stmt* stmt = nullptr;
  int result = sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr);
  if (result != SQLITE_OK) {
    set_last_error("Query preparation failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return nullptr;
  }

  auto db_result = std::make_unique<sqlite_result>(stmt, db_);
  clear_last_error();
  return db_result;
}

std::unique_ptr<database_result> sqlite_connection::execute_query(
    const std::string& sql, const std::vector<std::string>& params) {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return nullptr;
  }

  sqlite3_stmt* stmt = nullptr;
  int result = sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr);
  if (result != SQLITE_OK) {
    set_last_error("Query preparation failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return nullptr;
  }

  // Bind parameters
  for (size_t i = 0; i < params.size(); ++i) {
    result =
        sqlite3_bind_text(stmt, i + 1, params[i].c_str(), -1, SQLITE_TRANSIENT);
    if (result != SQLITE_OK) {
      set_last_error("Parameter binding failed: " +
                     std::string(sqlite3_errmsg(db_)));
      sqlite3_finalize(stmt);
      return nullptr;
    }
  }

  auto db_result = std::make_unique<sqlite_result>(stmt, db_);
  clear_last_error();
  return db_result;
}

bool sqlite_connection::execute_non_query(const std::string& sql) {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return false;
  }

  char* error_msg = nullptr;
  int result = sqlite3_exec(db_, sql.c_str(), nullptr, nullptr, &error_msg);
  if (result != SQLITE_OK) {
    std::string error = error_msg ? error_msg : "Unknown error";
    set_last_error("Non-query execution failed: " + error);
    sqlite3_free(error_msg);
    return false;
  }

  clear_last_error();
  return true;
}

bool sqlite_connection::execute_non_query(
    const std::string& sql, const std::vector<std::string>& params) {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return false;
  }

  sqlite3_stmt* stmt = nullptr;
  int result = sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr);
  if (result != SQLITE_OK) {
    set_last_error("Query preparation failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return false;
  }

  // Bind parameters
  for (size_t i = 0; i < params.size(); ++i) {
    result =
        sqlite3_bind_text(stmt, i + 1, params[i].c_str(), -1, SQLITE_TRANSIENT);
    if (result != SQLITE_OK) {
      set_last_error("Parameter binding failed: " +
                     std::string(sqlite3_errmsg(db_)));
      sqlite3_finalize(stmt);
      return false;
    }
  }

  // Execute the statement
  result = sqlite3_step(stmt);
  if (result != SQLITE_DONE) {
    set_last_error("Non-query execution failed: " +
                   std::string(sqlite3_errmsg(db_)));
    sqlite3_finalize(stmt);
    return false;
  }

  sqlite3_finalize(stmt);
  clear_last_error();
  return true;
}

std::string sqlite_connection::get_connection_info() const {
  if (!db_) {
    return "Not connected";
  }

  std::ostringstream oss;
  oss << "SQLite connection to " << config_.database_name;
  return oss.str();
}

bool sqlite_connection::ping() {
  if (!is_connected()) {
    return false;
  }

  sqlite3_stmt* stmt = nullptr;
  int result = sqlite3_prepare_v2(db_, "SELECT 1", -1, &stmt, nullptr);
  if (result != SQLITE_OK) {
    return false;
  }

  result = sqlite3_step(stmt);
  sqlite3_finalize(stmt);

  return result == SQLITE_ROW;
}

std::string sqlite_connection::get_last_error() const {
  return last_error_;
}

void sqlite_connection::set_last_error(const std::string& error) {
  last_error_ = error;
}

void sqlite_connection::clear_last_error() {
  last_error_.clear();
}

std::string sqlite_connection::get_sqlite_error() const {
  if (!db_) {
    return "No database connection";
  }
  return sqlite3_errmsg(db_);
}

}  // namespace database
}  // namespace onis_kit