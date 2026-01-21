#include "../../include/database/sql_builder.hpp"
#include <algorithm>
#include <sstream>
#include "onis_kit/include/database/postgresql/postgresql_connection.hpp"
#include "onis_kit/include/database/sqlite/sqlite_connection.hpp"

namespace onis {
namespace database {

sql_builder::sql_builder(database_engine engine) : engine_(engine) {}

std::string sql_builder::build_select_query(const std::string& columns,
                                            const std::string& table,
                                            const std::string& where_clause,
                                            const std::string& order_by,
                                            std::int32_t limit,
                                            lock_mode lock) const {
  std::ostringstream sql;

  // Start with SELECT
  sql << "SELECT ";

  // Add TOP clause for MSSQL (before columns)
  if (engine_ == database_engine::MSSQL && limit > 0) {
    sql << "TOP " << limit << " ";
  }

  // Add columns
  sql << columns;

  // Add FROM clause
  sql << " FROM ";

  // Add table with locking for MSSQL
  if (engine_ == database_engine::MSSQL) {
    sql << add_mssql_lock(table, lock);
  } else {
    sql << table;
  }

  // Add WHERE clause
  if (!where_clause.empty()) {
    sql << " WHERE " << convert_where_placeholders(where_clause);
  }

  // Add ORDER BY clause
  if (!order_by.empty()) {
    sql << " ORDER BY " << order_by;
  }

  // Add locking for other databases (after ORDER BY)
  if (engine_ != database_engine::MSSQL) {
    std::string lock_clause;
    switch (engine_) {
      case database_engine::POSTGRESQL:
        lock_clause = add_postgresql_lock(table, lock);
        break;
      case database_engine::SQLITE:
        lock_clause = add_sqlite_lock(table, lock);
        break;
      case database_engine::MYSQL:
        lock_clause = add_mysql_lock(table, lock);
        break;
      default:
        break;
    }
    if (!lock_clause.empty()) {
      sql << " " << lock_clause;
    }
  }

  // Add LIMIT clause for non-MSSQL databases
  if (engine_ != database_engine::MSSQL) {
    sql << add_limit_clause(limit);
  }

  return sql.str();
}

std::string sql_builder::build_insert_query(
    const std::string& table, const std::vector<std::string>& columns,
    const std::vector<std::string>& values) const {
  std::ostringstream sql;

  sql << "INSERT INTO " << table << " (";

  // Add columns
  for (size_t i = 0; i < columns.size(); ++i) {
    if (i > 0)
      sql << ", ";
    sql << columns[i];
  }

  sql << ") VALUES (";

  // Add placeholders based on database engine
  for (size_t i = 0; i < values.size(); ++i) {
    if (i > 0)
      sql << ", ";

    switch (engine_) {
      case database_engine::POSTGRESQL:
        sql << "$" << (i + 1);  // PostgreSQL uses $1, $2, etc.
        break;
      case database_engine::SQLITE:
      case database_engine::MYSQL:
      case database_engine::MSSQL:
      default:
        sql << "?";  // Most databases use ? placeholders
        break;
    }
  }

  sql << ")";

  return sql.str();
}

std::string sql_builder::build_update_query(
    const std::string& table, const std::vector<std::string>& set_clauses,
    const std::string& where_clause) const {
  std::ostringstream sql;

  sql << "UPDATE " << table << " SET ";

  // Add SET clauses
  for (size_t i = 0; i < set_clauses.size(); ++i) {
    if (i > 0)
      sql << ", ";
    sql << set_clauses[i];
  }

  // Add WHERE clause
  if (!where_clause.empty()) {
    sql << " WHERE " << where_clause;
  }

  return sql.str();
}

std::string sql_builder::build_delete_query(
    const std::string& table, const std::string& where_clause) const {
  std::ostringstream sql;

  sql << "DELETE FROM " << table;

  // Add WHERE clause
  if (!where_clause.empty()) {
    sql << " WHERE " << where_clause;
  }

  return sql.str();
}

database_engine sql_builder::detect_engine(
    const std::unique_ptr<onis_kit::database::database_connection>&
        connection) {
  if (!connection) {
    return database_engine::SQLITE;  // Default fallback
  }

  // Try to cast to specific connection types
  if (dynamic_cast<onis_kit::database::postgresql_connection*>(
          connection.get())) {
    return database_engine::POSTGRESQL;
  }

  if (dynamic_cast<onis_kit::database::sqlite_connection*>(connection.get())) {
    return database_engine::SQLITE;
  }

  // Fallback: try to detect from connection info
  std::string info = connection->get_connection_info();
  std::transform(info.begin(), info.end(), info.begin(), ::tolower);

  if (info.find("postgresql") != std::string::npos ||
      info.find("postgres") != std::string::npos) {
    return database_engine::POSTGRESQL;
  }

  if (info.find("sqlite") != std::string::npos) {
    return database_engine::SQLITE;
  }

  if (info.find("mysql") != std::string::npos) {
    return database_engine::MYSQL;
  }

  if (info.find("mssql") != std::string::npos ||
      info.find("sql server") != std::string::npos) {
    return database_engine::MSSQL;
  }

  return database_engine::SQLITE;  // Default fallback
}

std::string sql_builder::add_postgresql_lock(const std::string& table,
                                             lock_mode lock) const {
  switch (lock) {
    case lock_mode::EXCLUSIVE_LOCK:
      return "FOR UPDATE";
    case lock_mode::SHARE_LOCK:
      return "FOR SHARE";
    case lock_mode::NO_LOCK:
      return "";  // PostgreSQL doesn't have NOLOCK equivalent
    default:
      return "";
  }
}

std::string sql_builder::add_sqlite_lock(const std::string& table,
                                         lock_mode lock) const {
  // SQLite has limited locking support
  switch (lock) {
    case lock_mode::EXCLUSIVE_LOCK:
      return "FOR UPDATE";
    case lock_mode::SHARE_LOCK:
      return "";  // SQLite doesn't support share locks
    case lock_mode::NO_LOCK:
      return "";  // SQLite doesn't have NOLOCK equivalent
    default:
      return "";
  }
}

std::string sql_builder::add_mysql_lock(const std::string& table,
                                        lock_mode lock) const {
  switch (lock) {
    case lock_mode::EXCLUSIVE_LOCK:
      return "FOR UPDATE";
    case lock_mode::SHARE_LOCK:
      return "LOCK IN SHARE MODE";
    case lock_mode::NO_LOCK:
      return "";  // MySQL doesn't have NOLOCK equivalent
    default:
      return "";
  }
}

std::string sql_builder::add_mssql_lock(const std::string& table,
                                        lock_mode lock) const {
  switch (lock) {
    case lock_mode::EXCLUSIVE_LOCK:
      return table + " WITH (XLOCK, ROWLOCK)";
    case lock_mode::SHARE_LOCK:
      return table + " WITH (HOLDLOCK, ROWLOCK)";
    case lock_mode::NO_LOCK:
      return table + " WITH (NOLOCK)";
    default:
      return table;
  }
}

std::string sql_builder::add_limit_clause(std::int32_t limit) const {
  if (limit <= 0) {
    return "";
  }

  std::ostringstream clause;
  clause << " LIMIT " << limit;
  return clause.str();
}

std::string sql_builder::add_top_clause(std::int32_t limit) const {
  if (limit <= 0) {
    return "";
  }

  std::ostringstream clause;
  clause << "TOP " << limit << " ";
  return clause.str();
}

std::string sql_builder::convert_where_placeholders(
    const std::string& where_clause) const {
  if (engine_ != database_engine::POSTGRESQL) {
    return where_clause;  // SQLite, MySQL, MSSQL use ? placeholders
  }

  // PostgreSQL uses $1, $2, etc. instead of ?
  std::string result = where_clause;
  int param_index = 1;
  size_t pos = 0;
  while ((pos = result.find('?', pos)) != std::string::npos) {
    std::string replacement = "$" + std::to_string(param_index);
    result.replace(pos, 1, replacement);
    pos += replacement.length();
    param_index++;
  }
  return result;
}

}  // namespace database
}  // namespace onis
