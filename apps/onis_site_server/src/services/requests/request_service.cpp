#include "../../../include/services/requests/request_service.hpp"
#include "onis_kit/include/database/postgresql/postgresql_connection.hpp"

////////////////////////////////////////////////////////////////////////////////
// request_service class
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// static constructor
//------------------------------------------------------------------------------

request_service_ptr request_service::create() {
  request_service_ptr ret = std::make_shared<request_service>();
  return ret;
}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

request_service::request_service() {
  // Initialize database pool with default max size of 10
  database_pool_ = std::make_unique<site_database_pool>(10);

  // Set up connection factory for PostgreSQL
  database_pool_->set_connection_factory(
      []() -> std::unique_ptr<onis_kit::database::database_connection> {
        auto pg_connection =
            std::make_unique<onis_kit::database::postgresql_connection>();

        // Create database configuration
        onis_kit::database::database_config config;
        config.host = "localhost";
        config.port = 5432;
        config.database_name = "onis_site_db";
        config.username = "postgres";
        config.password = "your_password_here";
        config.use_ssl = false;

        // Connect using the configuration
        pg_connection->connect(config);
        return pg_connection;
      });
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

request_service::~request_service() {}

//------------------------------------------------------------------------------
// database pool access
//------------------------------------------------------------------------------

std::shared_ptr<site_database> request_service::get_database_connection() {
  return database_pool_->get_connection();
}

void request_service::return_database_connection(
    std::shared_ptr<site_database> connection) {
  database_pool_->return_connection(connection);
}