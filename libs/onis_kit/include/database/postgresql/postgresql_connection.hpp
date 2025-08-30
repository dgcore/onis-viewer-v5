#pragma once

#include <libpq-fe.h>
#include <memory>
#include <string>
#include "../database_interface.hpp"

namespace onis_kit {
namespace database {

/// PostgreSQL-specific database connection implementation
class postgresql_connection : public database_connection {
public:
  postgresql_connection();
  virtual ~postgresql_connection();

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
  PGconn* connection_;
  database_config config_;
  std::string last_error_;
  bool connected_;

  /// Build PostgreSQL connection string from config
  std::string build_connection_string(const database_config& config) const;

  /// Set last error message
  void set_last_error(const std::string& error);

  /// Clear last error message
  void clear_last_error();
};

}  // namespace database
}  // namespace onis_kit