#include "database/postgresql/postgresql_result.hpp"
#include <libpq-fe.h>
#include <iostream>
#include "utilities/uuid.hpp"

namespace onis_kit {
namespace database {

// postgresql_row implementation
postgresql_row::postgresql_row(PGresult* result, int row_index)
    : result_(result), row_index_(row_index) {
  init_column_names();
}

postgresql_row::~postgresql_row() {}

std::string postgresql_row::get_uuid(int& column_index, bool allow_null,
                                     bool allow_empty) const {
  std::string value = get_string(column_index, allow_null, allow_empty);
  if (!value.empty() && !onis::util::uuid::is_valid(value)) {
    throw std::invalid_argument("Invalid UUID format");
  }
  return value;
}

std::string postgresql_row::get_string(int& column_index, bool allow_null,
                                       bool allow_empty) const {
  if (column_index < 0 || column_index >= PQnfields(result_)) {
    throw std::out_of_range("Column index out of range");
  }
  if (PQgetisnull(result_, row_index_, column_index)) {
    if (!allow_null) {
      throw std::invalid_argument("Null value not allowed");
    }
    if (!allow_empty) {
      throw std::invalid_argument("Empty value not allowed");
    }
    column_index++;
    return "";
  }
  std::string value = PQgetvalue(result_, row_index_, column_index);
  if (value.empty() && !allow_empty) {
    throw std::invalid_argument("Empty value not allowed");
  }
  column_index++;
  return value;
}

int postgresql_row::get_int(int& column_index, bool allow_null) const {
  if (column_index < 0 || column_index >= PQnfields(result_)) {
    throw std::out_of_range("Column index out of range");
  }
  if (PQgetisnull(result_, row_index_, column_index)) {
    if (!allow_null) {
      throw std::invalid_argument("Null value not allowed");
    }
    column_index++;
    return 0;
  }
  const char* value = PQgetvalue(result_, row_index_, column_index);
  column_index++;
  return value ? std::stoi(value) : 0;
}

double postgresql_row::get_double(int& column_index, bool allow_null) const {
  if (column_index < 0 || column_index >= PQnfields(result_)) {
    throw std::out_of_range("Column index out of range");
  }

  if (PQgetisnull(result_, row_index_, column_index)) {
    if (!allow_null) {
      throw std::invalid_argument("Null value not allowed");
    }
    column_index++;
    return 0.0;
  }

  const char* value = PQgetvalue(result_, row_index_, column_index);
  column_index++;
  return value ? std::stod(value) : 0.0;
}

bool postgresql_row::get_bool(int& column_index, bool allow_null) const {
  if (column_index < 0 || column_index >= PQnfields(result_)) {
    throw std::out_of_range("Column index out of range");
  }
  if (PQgetisnull(result_, row_index_, column_index)) {
    if (!allow_null) {
      throw std::invalid_argument("Null value not allowed");
    }
    column_index++;
    return false;
  }
  const char* value = PQgetvalue(result_, row_index_, column_index);
  column_index++;
  return value ? std::string(value) == "t" || std::string(value) == "true" ||
                     std::string(value) == "1"
               : false;
}

std::string postgresql_row::get_uuid(const std::string& column_name,
                                     bool allow_null, bool allow_empty) const {
  int column_index = get_column_index(column_name);
  return get_uuid(column_index, allow_null, allow_empty);
}

std::string postgresql_row::get_string(const std::string& column_name,
                                       bool allow_null,
                                       bool allow_empty) const {
  int column_index = get_column_index(column_name);
  return get_string(column_index, allow_null, allow_empty);
}

int postgresql_row::get_int(const std::string& column_name,
                            bool allow_null) const {
  int column_index = get_column_index(column_name);
  return get_int(column_index, allow_null);
}

double postgresql_row::get_double(const std::string& column_name,
                                  bool allow_null) const {
  int column_index = get_column_index(column_name);
  return get_double(column_index, allow_null);
}

bool postgresql_row::get_bool(const std::string& column_name,
                              bool allow_null) const {
  int column_index = get_column_index(column_name);
  return get_bool(column_index, allow_null);
}

bool postgresql_row::is_null(int column_index) const {
  if (column_index < 0 || column_index >= PQnfields(result_)) {
    return true;
  }
  return PQgetisnull(result_, row_index_, column_index) != 0;
}

bool postgresql_row::is_null(const std::string& column_name) const {
  int column_index = get_column_index(column_name);
  return is_null(column_index);
}

int postgresql_row::get_column_count() const {
  return PQnfields(result_);
}

std::vector<std::string> postgresql_row::get_column_names() const {
  return column_names_;
}

int postgresql_row::get_column_index(const std::string& column_name) const {
  for (int i = 0; i < PQnfields(result_); ++i) {
    if (column_names_[i] == column_name) {
      return i;
    }
  }
  return -1;
}

void postgresql_row::init_column_names() {
  column_names_.clear();
  for (int i = 0; i < PQnfields(result_); ++i) {
    const char* name = PQfname(result_, i);
    column_names_.push_back(name ? name : "");
  }
}

// postgresql_result implementation
postgresql_result::postgresql_result(PGresult* result)
    : result_(result),
      current_row_(-1),
      total_rows_(PQntuples(result)),
      total_columns_(PQnfields(result)) {
  init_metadata();
}

postgresql_result::~postgresql_result() {
  if (result_) {
    PQclear(result_);
  }
}

int postgresql_result::get_affected_rows() const {
  if (!result_)
    return 0;

  const char* affected_rows_str = PQcmdTuples(result_);
  if (!affected_rows_str)
    return 0;

  try {
    return std::stoi(affected_rows_str);
  } catch (...) {
    return 0;
  }
}

int64_t postgresql_result::get_last_insert_id() const {
  // PostgreSQL doesn't have a direct way to get last insert ID
  // This would typically require a separate query like "SELECT lastval()"
  // For now, return 0 as this is database-specific
  return 0;
}

bool postgresql_result::has_rows() const {
  return total_rows_ > 0;
}

std::unique_ptr<database_row> postgresql_result::get_next_row() {
  if (current_row_ + 1 >= total_rows_) {
    return nullptr;
  }

  current_row_++;
  return std::make_unique<postgresql_row>(result_, current_row_);
}

void postgresql_result::reset() {
  current_row_ = -1;
}

std::vector<std::unique_ptr<database_row>> postgresql_result::get_all_rows() {
  std::vector<std::unique_ptr<database_row>> rows;

  reset();
  while (current_row_ + 1 < total_rows_) {
    auto row = get_next_row();
    if (row) {
      rows.push_back(std::move(row));
    }
  }

  return rows;
}

void postgresql_result::init_metadata() {
  column_names_ = get_column_names();
}

std::vector<std::string> postgresql_result::get_column_names() const {
  std::vector<std::string> names;
  for (int i = 0; i < total_columns_; ++i) {
    const char* name = PQfname(result_, i);
    names.push_back(name ? name : "");
  }
  return names;
}

}  // namespace database
}  // namespace onis_kit