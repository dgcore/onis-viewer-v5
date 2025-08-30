#include "database/postgresql/postgresql_query.hpp"
#include <libpq-fe.h>
#include <iostream>
#include <sstream>
#include "database/postgresql/postgresql_result.hpp"

namespace onis_kit {
namespace database {

postgresql_query::postgresql_query(PGconn* connection)
    : connection_(connection), prepared_(false) {}

postgresql_query::~postgresql_query() {}

std::unique_ptr<database_result> postgresql_query::execute() {
  if (!prepared_) {
    set_last_error("Query not prepared");
    return nullptr;
  }

  // Execute the SQL directly
  PGresult* result = PQexec(connection_, sql_.c_str());
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

std::unique_ptr<database_result> postgresql_query::execute(
    const std::vector<std::string>& params) {
  if (!prepared_) {
    set_last_error("Query not prepared");
    return nullptr;
  }

  // Convert string parameters to char* array for PostgreSQL
  std::vector<const char*> param_ptrs;
  for (const auto& param : params) {
    param_ptrs.push_back(param.c_str());
  }

  PGresult* result =
      PQexecParams(connection_, sql_.c_str(), params.size(), nullptr,
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

bool postgresql_query::execute_non_query() {
  if (!prepared_) {
    set_last_error("Query not prepared");
    return false;
  }

  PGresult* result = PQexec(connection_, sql_.c_str());
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

bool postgresql_query::execute_non_query(
    const std::vector<std::string>& params) {
  if (!prepared_) {
    set_last_error("Query not prepared");
    return false;
  }

  // Convert string parameters to char* array for PostgreSQL
  std::vector<const char*> param_ptrs;
  for (const auto& param : params) {
    param_ptrs.push_back(param.c_str());
  }

  PGresult* result =
      PQexecParams(connection_, sql_.c_str(), params.size(), nullptr,
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

bool postgresql_query::prepare(const std::string& sql) {
  sql_ = sql;
  prepared_ = true;
  clear_last_error();
  return true;
}

bool postgresql_query::bind_parameter(int index, const std::string& value) {
  // Store parameter for later use
  if (index > 0 && index <= static_cast<int>(parameters_.size()) + 1) {
    while (static_cast<int>(parameters_.size()) < index) {
      parameters_.push_back("");
    }
    parameters_[index - 1] = value;
    return true;
  }
  return false;
}

bool postgresql_query::bind_parameter(int index, int value) {
  return bind_parameter(index, std::to_string(value));
}

bool postgresql_query::bind_parameter(int index, double value) {
  return bind_parameter(index, std::to_string(value));
}

bool postgresql_query::bind_parameter(int index, bool value) {
  return bind_parameter(index, value ? "true" : "false");
}

void postgresql_query::clear_parameters() {
  parameters_.clear();
}

void postgresql_query::set_last_error(const std::string& error) {
  last_error_ = error;
}

void postgresql_query::clear_last_error() {
  last_error_.clear();
}

}  // namespace database
}  // namespace onis_kit