#include "database/sqlite/sqlite_query.hpp"
#include <sqlite3.h>
#include <iostream>
#include <sstream>
#include "database/sqlite/sqlite_result.hpp"

namespace onis_kit {
namespace database {

sqlite_query::sqlite_query(sqlite3* db)
    : db_(db), stmt_(nullptr), prepared_(false) {}

sqlite_query::~sqlite_query() {
  finalize_statement();
}

std::unique_ptr<database_result> sqlite_query::execute() {
  if (!prepared_) {
    set_last_error("Query not prepared");
    return nullptr;
  }

  // Reset the statement for reuse
  if (!reset_statement()) {
    return nullptr;
  }

  auto db_result = std::make_unique<sqlite_result>(stmt_, db_);
  clear_last_error();
  return db_result;
}

std::unique_ptr<database_result> sqlite_query::execute(
    const std::vector<std::string>& params) {
  if (!prepared_) {
    set_last_error("Query not prepared");
    return nullptr;
  }

  // Reset the statement for reuse
  if (!reset_statement()) {
    return nullptr;
  }

  // Bind parameters
  for (size_t i = 0; i < params.size(); ++i) {
    int result = sqlite3_bind_text(stmt_, i + 1, params[i].c_str(), -1,
                                   SQLITE_TRANSIENT);
    if (result != SQLITE_OK) {
      set_last_error("Parameter binding failed: " +
                     std::string(sqlite3_errmsg(db_)));
      return nullptr;
    }
  }

  auto db_result = std::make_unique<sqlite_result>(stmt_, db_);
  clear_last_error();
  return db_result;
}

bool sqlite_query::execute_non_query() {
  if (!prepared_) {
    set_last_error("Query not prepared");
    return false;
  }

  // Reset the statement for reuse
  if (!reset_statement()) {
    return false;
  }

  int result = sqlite3_step(stmt_);
  if (result != SQLITE_DONE) {
    set_last_error("Non-query execution failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return false;
  }

  clear_last_error();
  return true;
}

bool sqlite_query::execute_non_query(const std::vector<std::string>& params) {
  if (!prepared_) {
    set_last_error("Query not prepared");
    return false;
  }

  // Reset the statement for reuse
  if (!reset_statement()) {
    return false;
  }

  // Bind parameters
  for (size_t i = 0; i < params.size(); ++i) {
    int result = sqlite3_bind_text(stmt_, i + 1, params[i].c_str(), -1,
                                   SQLITE_TRANSIENT);
    if (result != SQLITE_OK) {
      set_last_error("Parameter binding failed: " +
                     std::string(sqlite3_errmsg(db_)));
      return false;
    }
  }

  int result = sqlite3_step(stmt_);
  if (result != SQLITE_DONE) {
    set_last_error("Non-query execution failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return false;
  }

  clear_last_error();
  return true;
}

bool sqlite_query::prepare(const std::string& sql) {
  finalize_statement();
  int result = sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt_, nullptr);
  if (result != SQLITE_OK) {
    set_last_error("Statement preparation failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return false;
  }

  sql_ = sql;
  prepared_ = true;
  clear_last_error();
  return true;
}

bool sqlite_query::bind_parameter(int index, const std::string& value) {
  if (!prepared_ || !stmt_) {
    set_last_error("Query not prepared");
    return false;
  }

  int result =
      sqlite3_bind_text(stmt_, index, value.c_str(), -1, SQLITE_TRANSIENT);
  if (result != SQLITE_OK) {
    set_last_error("Parameter binding failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return false;
  }

  return true;
}

bool sqlite_query::bind_parameter(int index, int value) {
  if (!prepared_ || !stmt_) {
    set_last_error("Query not prepared");
    return false;
  }

  int result = sqlite3_bind_int(stmt_, index, value);
  if (result != SQLITE_OK) {
    set_last_error("Parameter binding failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return false;
  }

  return true;
}

bool sqlite_query::bind_parameter(int index, double value) {
  if (!prepared_ || !stmt_) {
    set_last_error("Query not prepared");
    return false;
  }

  int result = sqlite3_bind_double(stmt_, index, value);
  if (result != SQLITE_OK) {
    set_last_error("Parameter binding failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return false;
  }

  return true;
}

bool sqlite_query::bind_parameter(int index, bool value) {
  if (!prepared_ || !stmt_) {
    set_last_error("Query not prepared");
    return false;
  }

  int result = sqlite3_bind_int(stmt_, index, value ? 1 : 0);
  if (result != SQLITE_OK) {
    set_last_error("Parameter binding failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return false;
  }

  return true;
}

void sqlite_query::clear_parameters() {
  if (stmt_) {
    sqlite3_clear_bindings(stmt_);
  }
}

void sqlite_query::set_last_error(const std::string& error) {
  last_error_ = error;
}

void sqlite_query::clear_last_error() {
  last_error_.clear();
}

void sqlite_query::finalize_statement() {
  if (stmt_) {
    sqlite3_finalize(stmt_);
    stmt_ = nullptr;
  }
  prepared_ = false;
}

bool sqlite_query::reset_statement() {
  if (!stmt_) {
    return false;
  }

  int result = sqlite3_reset(stmt_);
  if (result != SQLITE_OK) {
    set_last_error("Statement reset failed: " +
                   std::string(sqlite3_errmsg(db_)));
    return false;
  }

  return true;
}

}  // namespace database
}  // namespace onis_kit