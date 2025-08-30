#pragma once

/// @file postgresql.hpp
/// @brief PostgreSQL database implementation for ONIS Kit
///
/// This header includes all PostgreSQL-specific database implementation
/// classes. It provides concrete implementations of the database interface for
/// PostgreSQL.

#include "postgresql_connection.hpp"
#include "postgresql_query.hpp"
#include "postgresql_result.hpp"

namespace onis_kit {
namespace database {

/// @brief PostgreSQL namespace documentation
///
/// The PostgreSQL implementation provides concrete classes that implement
/// the database interface for PostgreSQL databases.
///
/// Key classes:
/// - postgresql_connection: PostgreSQL-specific connection management
/// - postgresql_query: PostgreSQL-specific query execution
/// - postgresql_result: PostgreSQL-specific result processing
/// - postgresql_row: PostgreSQL-specific row data access
///
/// Example usage:
/// @code
/// #include "onis_kit/include/database/postgresql.hpp"
///
/// using namespace onis_kit::database;
///
/// // Create PostgreSQL connection
/// auto connection = std::make_unique<postgresql_connection>();
///
/// // Configure connection
/// database_config config;
/// config.host = "localhost";
/// config.port = 5432;
/// config.database_name = "my_database";
/// config.username = "user";
/// config.password = "password";
///
/// // Connect to database
/// if (connection->connect(config)) {
///     // Execute query
///     auto result = connection->execute_query("SELECT * FROM users WHERE id =
///     $1", {"123"});
///
///     // Process results
///     while (result->has_rows()) {
///         auto row = result->get_next_row();
///         std::string name = row->get_string("name");
///         int age = row->get_int("age");
///     }
/// }
/// @endcode

}  // namespace database
}  // namespace onis_kit