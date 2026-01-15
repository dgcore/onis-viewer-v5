#pragma once

#include <memory>
#include <string>
#include <vector>
#include "onis_kit/include/core/types.hpp"
#include "onis_kit/include/database/database_interface.hpp"

namespace onis {
namespace database {

/// Database engine types
enum class database_engine { POSTGRESQL, SQLITE, MYSQL, MSSQL };

/// Lock modes for database queries
enum class lock_mode {
  NONE = 0,
  SHARE_LOCK = 1,
  EXCLUSIVE_LOCK = 2,
  NO_LOCK = 3
};

/// SQL query builder for database-specific syntax
class sql_builder {
public:
  explicit sql_builder(database_engine engine);

  /// Build SELECT query with database-specific syntax
  std::string build_select_query(const std::string& columns,
                                 const std::string& table,
                                 const std::string& where_clause = "",
                                 const std::string& order_by = "",
                                 dgc::s32 limit = 0,
                                 lock_mode lock = lock_mode::NONE) const;

  /// Build INSERT query
  std::string build_insert_query(const std::string& table,
                                 const std::vector<std::string>& columns,
                                 const std::vector<std::string>& values) const;

  /// Build UPDATE query
  std::string build_update_query(const std::string& table,
                                 const std::vector<std::string>& set_clauses,
                                 const std::string& where_clause = "") const;

  /// Build DELETE query
  std::string build_delete_query(const std::string& table,
                                 const std::string& where_clause = "") const;

  /// Get database engine type
  database_engine get_engine() const {
    return engine_;
  }

  /// Detect database engine from connection
  static database_engine detect_engine(
      const std::unique_ptr<onis_kit::database::database_connection>&
          connection);

private:
  database_engine engine_;

  /// Add locking clause for PostgreSQL
  std::string add_postgresql_lock(const std::string& table,
                                  lock_mode lock) const;

  /// Add locking clause for SQLite
  std::string add_sqlite_lock(const std::string& table, lock_mode lock) const;

  /// Add locking clause for MySQL
  std::string add_mysql_lock(const std::string& table, lock_mode lock) const;

  /// Add locking clause for MSSQL
  std::string add_mssql_lock(const std::string& table, lock_mode lock) const;

  /// Add LIMIT clause based on database engine
  std::string add_limit_clause(dgc::s32 limit) const;

  /// Add TOP clause for MSSQL
  std::string add_top_clause(dgc::s32 limit) const;

  /// Convert WHERE clause placeholders based on database engine
  std::string convert_where_placeholders(const std::string& where_clause) const;
};

}  // namespace database
}  // namespace onis
