#include "database/postgresql/postgresql_connection.hpp"
#include <libpq-fe.h>
#include <iostream>
#include <sstream>
#include "database/postgresql/postgresql_query.hpp"
#include "database/postgresql/postgresql_result.hpp"

namespace onis_kit {
namespace database {

postgresql_connection::postgresql_connection()
    : connection_(nullptr), connected_(false), in_transaction_(false) {}

postgresql_connection::~postgresql_connection() {
  disconnect();
}

bool postgresql_connection::connect(const database_config& config) {
  if (connected_) {
    disconnect();
  }

  // Build connection string
  std::string conninfo;
  if (!config.connection_string.empty()) {
    conninfo = config.connection_string;
  } else {
    std::ostringstream oss;
    oss << "host=" << config.host << " ";
    oss << "port=" << config.port << " ";
    oss << "dbname=" << config.database_name << " ";
    if (!config.username.empty()) {
      oss << "user=" << config.username << " ";
    }
    if (!config.password.empty()) {
      oss << "password=" << config.password << " ";
    }
    conninfo = oss.str();
  }

  // Connect to database
  connection_ = PQconnectdb(conninfo.c_str());

  if (PQstatus(connection_) != CONNECTION_OK) {
    set_last_error("Failed to connect to PostgreSQL: " +
                   std::string(PQerrorMessage(connection_)));
    PQfinish(connection_);
    connection_ = nullptr;
    return false;
  }

  connected_ = true;
  config_ = config;
  clear_last_error();
  return true;
}

void postgresql_connection::disconnect() {
  if (connection_) {
    // Rollback any pending transaction before disconnecting
    if (in_transaction_) {
      PQexec(connection_, "ROLLBACK");
      in_transaction_ = false;
    }
    PQfinish(connection_);
    connection_ = nullptr;
  }
  connected_ = false;
}

bool postgresql_connection::is_connected() const {
  return connected_ && connection_ && PQstatus(connection_) == CONNECTION_OK;
}

std::unique_ptr<database_query> postgresql_connection::create_query() {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return nullptr;
  }
  return std::make_unique<postgresql_query>(connection_);
}

std::unique_ptr<database_result> postgresql_connection::execute_query(
    const std::string& sql) {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return nullptr;
  }

  PGresult* result = PQexec(connection_, sql.c_str());
  if (PQresultStatus(result) != PGRES_TUPLES_OK &&
      PQresultStatus(result) != PGRES_COMMAND_OK) {
    set_last_error("Query execution failed: " +
                   std::string(PQresultErrorMessage(result)));
    PQclear(result);
    return nullptr;
  }

  auto db_result = std::make_unique<postgresql_result>(result);
  clear_last_error();
  return db_result;
}

std::unique_ptr<database_result> postgresql_connection::execute_query(
    const std::string& sql, const std::vector<std::string>& params) {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return nullptr;
  }

  // Convert string parameters to char* array for PostgreSQL
  std::vector<const char*> param_ptrs;
  for (const auto& param : params) {
    param_ptrs.push_back(param.c_str());
  }

  PGresult* result =
      PQexecParams(connection_, sql.c_str(), params.size(), nullptr,
                   param_ptrs.data(), nullptr, nullptr, 0);

  if (PQresultStatus(result) != PGRES_TUPLES_OK &&
      PQresultStatus(result) != PGRES_COMMAND_OK) {
    set_last_error("Query execution failed: " +
                   std::string(PQresultErrorMessage(result)));
    PQclear(result);
    return nullptr;
  }

  auto db_result = std::make_unique<postgresql_result>(result);
  clear_last_error();
  return db_result;
}

bool postgresql_connection::execute_non_query(const std::string& sql) {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return false;
  }

  PGresult* result = PQexec(connection_, sql.c_str());
  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    set_last_error("Non-query execution failed: " +
                   std::string(PQresultErrorMessage(result)));
    PQclear(result);
    return false;
  }

  PQclear(result);
  clear_last_error();
  return true;
}

bool postgresql_connection::execute_non_query(
    const std::string& sql, const std::vector<std::string>& params) {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return false;
  }

  // Convert string parameters to char* array for PostgreSQL
  std::vector<const char*> param_ptrs;
  for (const auto& param : params) {
    param_ptrs.push_back(param.c_str());
  }

  PGresult* result =
      PQexecParams(connection_, sql.c_str(), params.size(), nullptr,
                   param_ptrs.data(), nullptr, nullptr, 0);

  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    set_last_error("Non-query execution failed: " +
                   std::string(PQresultErrorMessage(result)));
    PQclear(result);
    return false;
  }

  PQclear(result);
  clear_last_error();
  return true;
}

std::string postgresql_connection::get_connection_info() const {
  if (!connection_) {
    return "Not connected";
  }

  std::ostringstream oss;
  oss << "PostgreSQL connection to ";
  oss << PQhost(connection_) << ":" << PQport(connection_) << "/"
      << PQdb(connection_);
  return oss.str();
}

bool postgresql_connection::ping() {
  if (!is_connected()) {
    return false;
  }

  PGresult* result = PQexec(connection_, "SELECT 1");
  if (PQresultStatus(result) != PGRES_TUPLES_OK) {
    PQclear(result);
    return false;
  }

  PQclear(result);
  return true;
}

std::string postgresql_connection::get_last_error() const {
  return last_error_;
}

void postgresql_connection::set_last_error(const std::string& error) {
  last_error_ = error;
}

void postgresql_connection::clear_last_error() {
  last_error_.clear();
}

bool postgresql_connection::begin_transaction() {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return false;
  }

  if (in_transaction_) {
    set_last_error("Transaction already in progress");
    return false;
  }

  PGresult* result = PQexec(connection_, "BEGIN");
  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    set_last_error("Failed to begin transaction: " +
                   std::string(PQresultErrorMessage(result)));
    PQclear(result);
    return false;
  }

  PQclear(result);
  in_transaction_ = true;
  clear_last_error();
  return true;
}

bool postgresql_connection::commit() {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return false;
  }

  if (!in_transaction_) {
    set_last_error("No transaction in progress");
    return false;
  }

  PGresult* result = PQexec(connection_, "COMMIT");
  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    set_last_error("Failed to commit transaction: " +
                   std::string(PQresultErrorMessage(result)));
    PQclear(result);
    return false;
  }

  PQclear(result);
  in_transaction_ = false;
  clear_last_error();
  return true;
}

bool postgresql_connection::rollback() {
  if (!is_connected()) {
    set_last_error("Not connected to database");
    return false;
  }

  if (!in_transaction_) {
    set_last_error("No transaction in progress");
    return false;
  }

  PGresult* result = PQexec(connection_, "ROLLBACK");
  if (PQresultStatus(result) != PGRES_COMMAND_OK) {
    set_last_error("Failed to rollback transaction: " +
                   std::string(PQresultErrorMessage(result)));
    PQclear(result);
    return false;
  }

  PQclear(result);
  in_transaction_ = false;
  clear_last_error();
  return true;
}

bool postgresql_connection::in_transaction() const {
  return in_transaction_;
}

}  // namespace database
}  // namespace onis_kit