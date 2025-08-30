#include "database/sqlite/sqlite_result.hpp"
#include <sqlite3.h>
#include <iostream>

namespace onis_kit {
namespace database {

// sqlite_row implementation
sqlite_row::sqlite_row(sqlite3_stmt* stmt) : stmt_(stmt) {
  init_column_names();
}

sqlite_row::~sqlite_row() {}

std::string sqlite_row::get_string(int column_index) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    return "";
  }

  if (sqlite3_column_type(stmt_, column_index) == SQLITE_NULL) {
    return "";
  }

  const unsigned char* value = sqlite3_column_text(stmt_, column_index);
  return value ? reinterpret_cast<const char*>(value) : "";
}

int sqlite_row::get_int(int column_index) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    return 0;
  }

  if (sqlite3_column_type(stmt_, column_index) == SQLITE_NULL) {
    return 0;
  }

  return sqlite3_column_int(stmt_, column_index);
}

double sqlite_row::get_double(int column_index) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    return 0.0;
  }

  if (sqlite3_column_type(stmt_, column_index) == SQLITE_NULL) {
    return 0.0;
  }

  return sqlite3_column_double(stmt_, column_index);
}

bool sqlite_row::get_bool(int column_index) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    return false;
  }

  if (sqlite3_column_type(stmt_, column_index) == SQLITE_NULL) {
    return false;
  }

  return sqlite3_column_int(stmt_, column_index) != 0;
}

std::string sqlite_row::get_string(const std::string& column_name) const {
  int column_index = get_column_index(column_name);
  return get_string(column_index);
}

int sqlite_row::get_int(const std::string& column_name) const {
  int column_index = get_column_index(column_name);
  return get_int(column_index);
}

double sqlite_row::get_double(const std::string& column_name) const {
  int column_index = get_column_index(column_name);
  return get_double(column_index);
}

bool sqlite_row::get_bool(const std::string& column_name) const {
  int column_index = get_column_index(column_name);
  return get_bool(column_index);
}

bool sqlite_row::is_null(int column_index) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    return true;
  }
  return sqlite3_column_type(stmt_, column_index) == SQLITE_NULL;
}

bool sqlite_row::is_null(const std::string& column_name) const {
  int column_index = get_column_index(column_name);
  return is_null(column_index);
}

int sqlite_row::get_column_count() const {
  return sqlite3_column_count(stmt_);
}

std::vector<std::string> sqlite_row::get_column_names() const {
  return column_names_;
}

int sqlite_row::get_column_index(const std::string& column_name) const {
  for (int i = 0; i < get_column_count(); ++i) {
    if (column_names_[i] == column_name) {
      return i;
    }
  }
  return -1;
}

void sqlite_row::init_column_names() {
  column_names_.clear();
  int count = get_column_count();
  for (int i = 0; i < count; ++i) {
    const char* name = sqlite3_column_name(stmt_, i);
    column_names_.push_back(name ? name : "");
  }
}

std::string sqlite_row::get_column_name(int column_index) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    return "";
  }
  return column_names_[column_index];
}

// sqlite_result implementation
sqlite_result::sqlite_result(sqlite3_stmt* stmt, sqlite3* db)
    : stmt_(stmt), db_(db), current_row_(-1), has_more_rows_(false) {
  init_metadata();
  // Check if there are any rows
  if (stmt_) {
    int result = sqlite3_step(stmt_);
    has_more_rows_ = (result == SQLITE_ROW);
    if (has_more_rows_) {
      current_row_ = 0;
    }
  }
}

sqlite_result::~sqlite_result() {
  if (stmt_) {
    sqlite3_finalize(stmt_);
  }
}

int sqlite_result::get_affected_rows() const {
  if (!db_)
    return 0;
  return sqlite3_changes(db_);
}

int64_t sqlite_result::get_last_insert_id() const {
  if (!db_)
    return 0;
  return sqlite3_last_insert_rowid(db_);
}

bool sqlite_result::has_rows() const {
  return has_more_rows_;
}

std::unique_ptr<database_row> sqlite_result::get_next_row() {
  if (!has_more_rows_ || !stmt_) {
    return nullptr;
  }

  // Create row from current statement position
  auto row = std::make_unique<sqlite_row>(stmt_);

  // Move to next row
  int result = sqlite3_step(stmt_);
  has_more_rows_ = (result == SQLITE_ROW);

  return row;
}

void sqlite_result::reset() {
  if (stmt_) {
    sqlite3_reset(stmt_);
    current_row_ = -1;
    has_more_rows_ = false;

    // Check if there are any rows
    int result = sqlite3_step(stmt_);
    has_more_rows_ = (result == SQLITE_ROW);
    if (has_more_rows_) {
      current_row_ = 0;
    }
  }
}

std::vector<std::unique_ptr<database_row>> sqlite_result::get_all_rows() {
  std::vector<std::unique_ptr<database_row>> rows;

  reset();
  while (has_more_rows_) {
    auto row = get_next_row();
    if (row) {
      rows.push_back(std::move(row));
    }
  }

  return rows;
}

void sqlite_result::init_metadata() {
  column_names_ = get_column_names();
}

std::vector<std::string> sqlite_result::get_column_names() const {
  std::vector<std::string> names;
  if (!stmt_)
    return names;

  int count = sqlite3_column_count(stmt_);
  for (int i = 0; i < count; ++i) {
    const char* name = sqlite3_column_name(stmt_, i);
    names.push_back(name ? name : "");
  }
  return names;
}

bool sqlite_result::step_to_next_row() {
  if (!stmt_)
    return false;

  int result = sqlite3_step(stmt_);
  has_more_rows_ = (result == SQLITE_ROW);
  return has_more_rows_;
}

}  // namespace database
}  // namespace onis_kit