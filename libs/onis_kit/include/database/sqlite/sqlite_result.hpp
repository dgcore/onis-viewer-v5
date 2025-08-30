#pragma once

#include <sqlite3.h>
#include <memory>
#include <string>
#include <vector>
#include "../database_interface.hpp"

namespace onis_kit {
namespace database {

/// SQLite-specific database result row implementation
class sqlite_row : public database_row {
public:
  explicit sqlite_row(sqlite3_stmt* stmt);
  virtual ~sqlite_row();

  // database_row interface implementation
  virtual std::string get_string(int column_index) const override;
  virtual int get_int(int column_index) const override;
  virtual double get_double(int column_index) const override;
  virtual bool get_bool(int column_index) const override;
  virtual std::string get_string(const std::string& column_name) const override;
  virtual int get_int(const std::string& column_name) const override;
  virtual double get_double(const std::string& column_name) const override;
  virtual bool get_bool(const std::string& column_name) const override;
  virtual bool is_null(int column_index) const override;
  virtual bool is_null(const std::string& column_name) const override;
  virtual int get_column_count() const override;
  virtual std::vector<std::string> get_column_names() const override;

private:
  sqlite3_stmt* stmt_;
  std::vector<std::string> column_names_;

  /// Get column index by name
  int get_column_index(const std::string& column_name) const;

  /// Initialize column names
  void init_column_names();

  /// Get column name by index
  std::string get_column_name(int column_index) const;
};

/// SQLite-specific database result implementation
class sqlite_result : public database_result {
public:
  explicit sqlite_result(sqlite3_stmt* stmt, sqlite3* db);
  virtual ~sqlite_result();

  // database_result interface implementation
  virtual int get_affected_rows() const override;
  virtual int64_t get_last_insert_id() const override;
  virtual bool has_rows() const override;
  virtual std::unique_ptr<database_row> get_next_row() override;
  virtual void reset() override;
  virtual std::vector<std::unique_ptr<database_row>> get_all_rows() override;

private:
  sqlite3_stmt* stmt_;
  sqlite3* db_;
  int current_row_;
  int total_rows_;
  int total_columns_;
  std::vector<std::string> column_names_;
  bool has_more_rows_;

  /// Initialize result metadata
  void init_metadata();

  /// Get column names
  std::vector<std::string> get_column_names() const;

  /// Step to next row
  bool step_to_next_row();
};

}  // namespace database
}  // namespace onis_kit