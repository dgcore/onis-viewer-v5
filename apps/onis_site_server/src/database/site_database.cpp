#include "../../include/database/site_database.hpp"
#include <iostream>
#include <sstream>
#include "../../include/database/sql_builder.hpp"
#include "onis_kit/include/core/exception.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// site_database
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

site_database::site_database(
    std::unique_ptr<onis_kit::database::database_connection>&& connection)
    : connection_(std::move(connection)) {
  std::cout << "site_database: Constructor" << std::endl;
  sql_builder_ = std::make_unique<onis::database::sql_builder>(
      onis::database::sql_builder::detect_engine(connection_));
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

site_database::~site_database() {
  std::cout << "site_database: Destructor" << std::endl;
}

//------------------------------------------------------------------------------
// connection access
//------------------------------------------------------------------------------

onis_kit::database::database_connection& site_database::get_connection() {
  return *connection_;
}

const onis_kit::database::database_connection& site_database::get_connection()
    const {
  return *connection_;
}

//------------------------------------------------------------------------------
// Utility methods
//------------------------------------------------------------------------------

std::unique_ptr<onis_kit::database::database_query>
site_database::create_and_prepare_query(const std::string& columns,
                                        const std::string& from,
                                        const std::string& where,
                                        lock_mode lock,
                                        std::int32_t limit) const {
  std::string sql =
      sql_builder_->build_select_query(columns, from, where, "", limit, lock);
  auto query = connection_->create_query();
  if (!query) {
    throw onis::exception(EOS_DB_QUERY, "Failed to create query");
  }
  if (!query->prepare(sql)) {
    throw onis::exception(EOS_DB_QUERY, "Failed to prepare the query");
  }
  return query;
}

std::unique_ptr<onis_kit::database::database_query>
site_database::prepare_query(const std::string& sql,
                             const std::string& context) const {
  auto query = connection_->create_query();
  if (!query->prepare(sql)) {
    std::string error_msg = "Failed to prepare query";
    if (!context.empty()) {
      error_msg += " for " + context;
    }
    error_msg += ": " + sql;
    throw onis::exception(EOS_DB_QUERY, error_msg);
  }
  return query;
}

std::unique_ptr<onis_kit::database::database_result>
site_database::execute_query(
    std::unique_ptr<onis_kit::database::database_query>& query) const {
  if (!query) {
    throw onis::exception(EOS_DB_QUERY, "Query is null");
  }
  return query->execute();
}

void site_database::execute_and_check_affected(
    std::unique_ptr<onis_kit::database::database_query>& query,
    const std::string& message) const {
  auto result = execute_query(query);

  // Check if any rows were affected
  if (result->get_affected_rows() == 0) {
    throw onis::exception(EOS_DB_QUERY, message);
  }
}

//------------------------------------------------------------------------------
// Transaction management
//------------------------------------------------------------------------------

void site_database::begin_transaction() {
  if (!connection_->begin_transaction()) {
    throw onis::exception(EOS_DB_TRANSACTION, "Failed to begin transaction");
  }
}

void site_database::commit() {
  if (!connection_->commit()) {
    throw onis::exception(EOS_DB_TRANSACTION_COMMIT,
                          "Failed to commit transaction");
  }
}

void site_database::rollback() {
  if (!connection_->rollback()) {
    throw onis::exception(EOS_DB_TRANSACTION_ROLLBACK,
                          "Failed to commit transaction");
  }
}

bool site_database::in_transaction() const {
  return connection_->in_transaction();
}

void site_database::commit_or_rollback_transaction() {
  if (in_transaction()) {
    try {
      commit();
    } catch (const onis::exception& e) {
      rollback();
      throw e;
    } catch (...) {
      rollback();
      throw;
    }
  } else {
    throw onis::exception(EOS_DB_TRANSACTION_COMMIT,
                          "No transaction in progress");
  }
}