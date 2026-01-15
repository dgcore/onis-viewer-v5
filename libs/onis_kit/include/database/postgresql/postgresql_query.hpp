#pragma once

#include <libpq-fe.h>
#include <memory>
#include <string>
#include <vector>
#include "../database_interface.hpp"

namespace onis_kit {
namespace database {

/// PostgreSQL-specific database query implementation
class postgresql_query : public database_query {
public:
  explicit postgresql_query(PGconn* connection);
  virtual ~postgresql_query();

  // database_query interface implementation
  virtual std::unique_ptr<database_result> execute() override;
  virtual std::unique_ptr<database_result> execute(
      const std::vector<std::string>& params) override;
  virtual bool execute_non_query() override;
  virtual bool execute_non_query(
      const std::vector<std::string>& params) override;
  virtual bool prepare(const std::string& sql) override;
  virtual bool bind_parameter(int index, const std::string& value) override;
  virtual bool bind_parameter(int index, int value) override;
  virtual bool bind_parameter(int index, double value) override;
  virtual bool bind_parameter(int index, bool value) override;
  virtual void clear_parameters() override;

  std::string convert_placeholders(const std::string& sql) const;

private:
  PGconn* connection_;
  std::string sql_;
  std::vector<std::string> parameters_;
  std::string last_error_;
  bool prepared_;

  /// Set last error message
  void set_last_error(const std::string& error);

  /// Clear last error message
  void clear_last_error();

  /// Convert parameters to PostgreSQL format
  std::vector<const char*> get_param_pointers() const;
};

}  // namespace database
}  // namespace onis_kit