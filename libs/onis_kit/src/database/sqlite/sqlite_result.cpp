#include "database/sqlite/sqlite_result.hpp"
#include <sqlite3.h>
#include <iostream>
#include "utilities/uuid.hpp"

namespace onis_kit {
namespace database {

// sqlite_row implementation
sqlite_row::sqlite_row(sqlite3_stmt* stmt) : stmt_(stmt) {
  init_column_names();
}

sqlite_row::~sqlite_row() {}

std::string sqlite_row::get_uuid(int& column_index, bool allow_null,
                                 bool allow_empty) const {
  std::string value = get_string(column_index, allow_null, allow_empty);
  if (!value.empty() && !onis::util::uuid::is_valid(value)) {
    throw std::invalid_argument("Invalid UUID format");
  }
  return value;
}

std::string sqlite_row::get_string(int& column_index, bool allow_null,
                                   bool allow_empty) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    throw std::out_of_range("Column index out of range");
  }

  if (sqlite3_column_type(stmt_, column_index) == SQLITE_NULL) {
    if (!allow_null) {
      throw std::invalid_argument("Null value not allowed");
    }
    if (!allow_empty) {
      throw std::invalid_argument("Empty value not allowed");
    }
    column_index++;
    return "";
  }

  const std::string value =
      reinterpret_cast<const char*>(sqlite3_column_text(stmt_, column_index));
  if (value.empty() && !allow_empty) {
    throw std::invalid_argument("Empty value not allowed");
  }
  column_index++;
  return value;
}

int sqlite_row::get_int(int& column_index, bool allow_null) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    throw std::out_of_range("Column index out of range");
  }

  if (sqlite3_column_type(stmt_, column_index) == SQLITE_NULL) {
    if (!allow_null) {
      throw std::invalid_argument("Null value not allowed");
    }
    column_index++;
    return 0;
  }
  column_index++;
  return sqlite3_column_int(stmt_, column_index);
}

double sqlite_row::get_double(int& column_index, bool allow_null) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    throw std::out_of_range("Column index out of range");
  }

  if (sqlite3_column_type(stmt_, column_index) == SQLITE_NULL) {
    if (!allow_null) {
      throw std::invalid_argument("Null value not allowed");
    }
    column_index++;
    return 0.0;
  }

  column_index++;
  return sqlite3_column_double(stmt_, column_index);
}

double sqlite_row::get_float(int& column_index, bool allow_null) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    throw std::out_of_range("Column index out of range");
  }

  if (sqlite3_column_type(stmt_, column_index) == SQLITE_NULL) {
    if (!allow_null) {
      throw std::invalid_argument("Null value not allowed");
    }
    column_index++;
    return 0.0;
  }

  column_index++;
  return (float)sqlite3_column_double(stmt_, column_index);
}

bool sqlite_row::get_bool(int& column_index, bool allow_null) const {
  if (column_index < 0 || column_index >= get_column_count()) {
    throw std::out_of_range("Column index out of range");
  }

  if (sqlite3_column_type(stmt_, column_index) == SQLITE_NULL) {
    if (!allow_null) {
      throw std::invalid_argument("Null value not allowed");
    }
    column_index++;
    return false;
  }
  column_index++;
  return sqlite3_column_int(stmt_, column_index) != 0;
}

std::string sqlite_row::get_uuid(const std::string& column_name,
                                 bool allow_null, bool allow_empty) const {
  int index = get_column_index(column_name);
  return get_uuid(index, allow_null, allow_empty);
}

std::string sqlite_row::get_string(const std::string& column_name,
                                   bool allow_null, bool allow_empty) const {
  int column_index = get_column_index(column_name);
  return get_string(column_index, allow_null, allow_empty);
}

int sqlite_row::get_int(const std::string& column_name, bool allow_null) const {
  int column_index = get_column_index(column_name);
  return get_int(column_index, allow_null);
}

double sqlite_row::get_double(const std::string& column_name,
                              bool allow_null) const {
  int column_index = get_column_index(column_name);
  return get_double(column_index, allow_null);
}

double sqlite_row::get_float(const std::string& column_name,
                             bool allow_null) const {
  int column_index = get_column_index(column_name);
  return get_float(column_index, allow_null);
}

bool sqlite_row::get_bool(const std::string& column_name,
                          bool allow_null) const {
  int column_index = get_column_index(column_name);
  return get_bool(column_index, allow_null);
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