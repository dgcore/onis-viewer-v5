#pragma once

#include <sqlite3.h>
#include <memory>
#include <string>
#include "../database_interface.hpp"

namespace onis_kit {
namespace database {

/// SQLite-specific database connection implementation
class sqlite_connection : public database_connection {
public:
  sqlite_connection();
  virtual ~sqlite_connection();

  // database_connection interface implementation
  virtual bool connect(const database_config& config) override;
  virtual void disconnect() override;
  virtual bool is_connected() const override;
  virtual std::unique_ptr<database_query> create_query() override;
  virtual std::unique_ptr<database_result> execute_query(
      const std::string& sql) override;
  virtual std::unique_ptr<database_result> execute_query(
      const std::string& sql, const std::vector<std::string>& params) override;
  virtual bool execute_non_query(const std::string& sql) override;
  virtual bool execute_non_query(
      const std::string& sql, const std::vector<std::string>& params) override;
  virtual std::string get_connection_info() const override;
  virtual bool ping() override;
  virtual std::string get_last_error() const override;

private:
  sqlite3* db_;
  database_config config_;
  std::string last_error_;
  bool connected_;

  /// Set last error message
  void set_last_error(const std::string& error);

  /// Clear last error message
  void clear_last_error();

  /// Get SQLite error message
  std::string get_sqlite_error() const;
};

}  // namespace database
}  // namespace onis_kit