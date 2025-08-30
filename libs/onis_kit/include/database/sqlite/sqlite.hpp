#pragma once

/// @file sqlite.hpp
/// @brief SQLite database implementation for ONIS Kit
///
/// This header includes all SQLite-specific database implementation classes.
/// It provides concrete implementations of the database interface for SQLite.

#include "sqlite_connection.hpp"
#include "sqlite_query.hpp"
#include "sqlite_result.hpp"

namespace onis_kit {
namespace database {

/// @brief SQLite namespace documentation
///
/// The SQLite implementation provides concrete classes that implement
/// the database interface for SQLite databases.
///
/// Key classes:
/// - sqlite_connection: SQLite-specific connection management
/// - sqlite_query: SQLite-specific query execution
/// - sqlite_result: SQLite-specific result processing
/// - sqlite_row: SQLite-specific row data access
///
/// Example usage:
/// @code
/// #include "onis_kit/include/database/sqlite/sqlite.hpp"
///
/// using namespace onis_kit::database;
///
/// // Create SQLite connection
/// auto connection = std::make_unique<sqlite_connection>();
///
/// // Configure connection
/// database_config config;
/// config.database_name = "my_database.db";
/// config.connection_string = "file:my_database.db?mode=rwc";
///
/// // Connect to database
/// if (connection->connect(config)) {
///     // Execute query
///     auto result = connection->execute_query("SELECT * FROM users WHERE id =
///     ?", {"123"});
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