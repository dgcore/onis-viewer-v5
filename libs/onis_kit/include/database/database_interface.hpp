#pragma once

#include <memory>
#include <string>
#include <vector>

namespace onis_kit {
namespace database {

// Forward declarations
class database_connection;
class database_query;
class database_result;
class database_transaction;

/// Database connection parameters
struct database_config {
  std::string host;
  int port;
  std::string database_name;
  std::string username;
  std::string password;
  std::string connection_string;

  // Optional SSL configuration
  bool use_ssl = false;
  std::string ssl_cert_path;
  std::string ssl_key_path;
  std::string ssl_ca_path;

  // Connection pool settings
  int max_connections = 10;
  int connection_timeout = 30;
  int query_timeout = 60;
};

/// Database result row
class database_row {
public:
  virtual ~database_row() = default;

  /// Get value by column index
  virtual std::string get_string(int column_index) const = 0;
  virtual int get_int(int column_index) const = 0;
  virtual double get_double(int column_index) const = 0;
  virtual bool get_bool(int column_index) const = 0;

  /// Get value by column name
  virtual std::string get_string(const std::string& column_name) const = 0;
  virtual int get_int(const std::string& column_name) const = 0;
  virtual double get_double(const std::string& column_name) const = 0;
  virtual bool get_bool(const std::string& column_name) const = 0;

  /// Check if value is null
  virtual bool is_null(int column_index) const = 0;
  virtual bool is_null(const std::string& column_name) const = 0;

  /// Get column count
  virtual int get_column_count() const = 0;

  /// Get column names
  virtual std::vector<std::string> get_column_names() const = 0;
};

/// Database query result
class database_result {
public:
  virtual ~database_result() = default;

  /// Get number of rows affected
  virtual int get_affected_rows() const = 0;

  /// Get last insert ID
  virtual int64_t get_last_insert_id() const = 0;

  /// Check if result has rows
  virtual bool has_rows() const = 0;

  /// Get next row
  virtual std::unique_ptr<database_row> get_next_row() = 0;

  /// Reset result cursor
  virtual void reset() = 0;

  /// Get all rows
  virtual std::vector<std::unique_ptr<database_row>> get_all_rows() = 0;
};

/// Database query interface
class database_query {
public:
  virtual ~database_query() = default;

  /// Execute query and return result
  virtual std::unique_ptr<database_result> execute() = 0;

  /// Execute query with parameters
  virtual std::unique_ptr<database_result> execute(
      const std::vector<std::string>& params) = 0;

  /// Execute query without returning result (for INSERT, UPDATE, DELETE)
  virtual bool execute_non_query() = 0;

  /// Execute query with parameters without returning result
  virtual bool execute_non_query(const std::vector<std::string>& params) = 0;

  /// Prepare statement
  virtual bool prepare(const std::string& sql) = 0;

  /// Bind parameter
  virtual bool bind_parameter(int index, const std::string& value) = 0;
  virtual bool bind_parameter(int index, int value) = 0;
  virtual bool bind_parameter(int index, double value) = 0;
  virtual bool bind_parameter(int index, bool value) = 0;

  /// Clear bound parameters
  virtual void clear_parameters() = 0;
};

/// Database connection interface
class database_connection {
public:
  virtual ~database_connection() = default;

  /// Connect to database
  virtual bool connect(const database_config& config) = 0;

  /// Disconnect from database
  virtual void disconnect() = 0;

  /// Check if connected
  virtual bool is_connected() const = 0;

  /// Create query object
  virtual std::unique_ptr<database_query> create_query() = 0;

  /// Execute query directly
  virtual std::unique_ptr<database_result> execute_query(
      const std::string& sql) = 0;
  virtual std::unique_ptr<database_result> execute_query(
      const std::string& sql, const std::vector<std::string>& params) = 0;

  /// Execute non-query directly
  virtual bool execute_non_query(const std::string& sql) = 0;
  virtual bool execute_non_query(const std::string& sql,
                                 const std::vector<std::string>& params) = 0;

  /// Get connection info
  virtual std::string get_connection_info() const = 0;

  /// Ping database
  virtual bool ping() = 0;

  /// Get last error
  virtual std::string get_last_error() const = 0;
};

}  // namespace database
}  // namespace onis_kit