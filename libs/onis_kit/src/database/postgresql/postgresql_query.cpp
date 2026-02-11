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
    throw std::runtime_error("Query not prepared");
  }

  // If parameters were bound, use PQexecParams
  if (!parameters_.empty()) {
    std::vector<const char*> param_ptrs;
    for (const auto& param : parameters_) {
      param_ptrs.push_back(param.c_str());
    }

    PGresult* result =
        PQexecParams(connection_, sql_.c_str(), parameters_.size(), nullptr,
                     param_ptrs.data(), nullptr, nullptr, 0);

    if (PQresultStatus(result) != PGRES_TUPLES_OK &&
        PQresultStatus(result) != PGRES_COMMAND_OK) {
      set_last_error("Query execution failed: " +
                     std::string(PQresultErrorMessage(result)));
      PQclear(result);
      throw std::runtime_error(last_error_);
    }

    auto db_result = std::make_unique<postgresql_result>(result);
    clear_last_error();
    return db_result;
  }

  // Execute the SQL directly if no parameters
  PGresult* result = PQexec(connection_, sql_.c_str());
  if (PQresultStatus(result) != PGRES_TUPLES_OK &&
      PQresultStatus(result) != PGRES_COMMAND_OK) {
    set_last_error("Query execution failed: " +
                   std::string(PQresultErrorMessage(result)));
    PQclear(result);
    throw std::runtime_error(last_error_);
  }

  auto db_result = std::make_unique<postgresql_result>(result);
  clear_last_error();
  return db_result;
}

std::unique_ptr<database_result> postgresql_query::execute(
    const std::vector<std::string>& params) {
  if (!prepared_) {
    set_last_error("Query not prepared");
    throw std::runtime_error(last_error_);
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
    throw std::runtime_error(last_error_);
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
  sql_ = convert_placeholders(sql);
  prepared_ = true;
  clear_last_error();
  return true;
}

std::string postgresql_query::convert_placeholders(
    const std::string& sql) const {
  std::string result = sql;
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

bool postgresql_query::bind_parameter(int index, const std::string& value) {
  // Validate index first (before any other operations)
  if (index <= 0) {
    set_last_error("Parameter index must be greater than 0");
    return false;
  }

  // Validate connection
  if (!connection_) {
    set_last_error("Database connection is null");
    return false;
  }

  try {
    // Store parameter for later use
    // Resize vector to accommodate the index if needed
    while (static_cast<int>(parameters_.size()) < index) {
      parameters_.push_back("");
    }

    // Now safely assign the parameter
    if (index - 1 < static_cast<int>(parameters_.size())) {
      parameters_[index - 1] = value;
      return true;
    } else {
      set_last_error("Parameter index out of bounds after resize");
      return false;
    }
  } catch (const std::exception& e) {
    set_last_error("Exception in bind_parameter: " + std::string(e.what()));
    return false;
  } catch (...) {
    set_last_error("Unknown exception in bind_parameter");
    return false;
  }
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