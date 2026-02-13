#pragma once

#include <libpq-fe.h>
#include <memory>
#include <string>
#include <vector>
#include "../database_interface.hpp"

namespace onis_kit {
namespace database {

/// PostgreSQL-specific database result row implementation
class postgresql_row : public database_row {
public:
  explicit postgresql_row(PGresult* result, int row_index);
  virtual ~postgresql_row();

  // database_row interface implementation
  virtual std::string get_uuid(int& column_index, bool allow_null,
                               bool allow_empty) const override;
  virtual std::string get_string(int& column_index, bool allow_null,
                                 bool allow_empty) const override;
  virtual int get_int(int& column_index, bool allow_null) const override;
  virtual double get_double(int& column_index, bool allow_null) const override;
  virtual double get_float(int& column_index, bool allow_null) const override;
  virtual bool get_bool(int& column_index, bool allow_null) const override;

  virtual std::string get_uuid(const std::string& column_name, bool allow_null,
                               bool allow_empty) const override;
  virtual std::string get_string(const std::string& column_name,
                                 bool allow_null,
                                 bool allow_empty) const override;
  virtual int get_int(const std::string& column_name,
                      bool allow_null) const override;
  virtual double get_double(const std::string& column_name,
                            bool allow_null) const override;
  virtual double get_float(const std::string& column_name,
                           bool allow_null) const override;
  virtual bool get_bool(const std::string& column_name,
                        bool allow_null) const override;

  virtual bool is_null(int column_index) const override;
  virtual bool is_null(const std::string& column_name) const override;
  virtual int get_column_count() const override;
  virtual std::vector<std::string> get_column_names() const override;

private:
  PGresult* result_;
  int row_index_;
  std::vector<std::string> column_names_;

  /// Get column index by name
  int get_column_index(const std::string& column_name) const;

  /// Initialize column names
  void init_column_names();
};

/// PostgreSQL-specific database result implementation
class postgresql_result : public database_result {
public:
  explicit postgresql_result(PGresult* result);
  virtual ~postgresql_result();

  // database_result interface implementation
  virtual int get_affected_rows() const override;
  virtual int64_t get_last_insert_id() const override;
  virtual bool has_rows() const override;
  virtual std::unique_ptr<database_row> get_next_row() override;
  virtual void reset() override;
  virtual std::vector<std::unique_ptr<database_row>> get_all_rows() override;

private:
  PGresult* result_;
  int current_row_;
  int total_rows_;
  int total_columns_;
  std::vector<std::string> column_names_;

  /// Initialize result metadata
  void init_metadata();

  /// Get column names
  std::vector<std::string> get_column_names() const;
};

}  // namespace database
}  // namespace onis_kit