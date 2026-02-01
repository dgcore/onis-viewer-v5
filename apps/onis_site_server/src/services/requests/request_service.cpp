#include "../../../include/services/requests/request_service.hpp"
#include "../../../include/exceptions/site_server_exceptions.hpp"
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

request_service::request_service() : session_timeout_(std::chrono::hours(1)) {
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

//------------------------------------------------------------------------------
// sessions
//------------------------------------------------------------------------------

void request_service::register_session(const request_session_ptr& session) {
  std::lock_guard<std::mutex> lock(sessions_mutex_);

  // Check if the session already exists:
  if (sessions_.find(session->session_id) != sessions_.end()) {
    throw std::runtime_error("Session already exists");
  }

  // Register the session:
  sessions_[session->session_id] = session;
  session->first_access = std::chrono::system_clock::now();
  session->last_access = std::chrono::system_clock::now();
}

void request_service::unregister_session(const std::string& session_id) {
  std::lock_guard<std::mutex> lock(sessions_mutex_);
  if (sessions_.find(session_id) != sessions_.end()) {
    sessions_.erase(session_id);
  }
}

request_session_ptr request_service::find_session(
    const std::string& session_id) const {
  std::lock_guard<std::mutex> lock(sessions_mutex_);
  auto it = sessions_.find(session_id);
  if (it != sessions_.end()) {
    return it->second;
  }
  throw std::runtime_error("Session not found");
}

void request_service::cleanup_sessions() {
  std::lock_guard<std::mutex> lock(sessions_mutex_);
  auto it = sessions_.begin();
  while (it != sessions_.end()) {
    if (is_session_expired(it->second, false)) {
      it = sessions_.erase(it);
    } else {
      ++it;
    }
  }
}

bool request_service::is_session_expired(const request_session_ptr& session,
                                         bool update_last_access) {
  if (!session) {
    return true;  // Null session is considered expired
  }

  auto now = std::chrono::system_clock::now();
  auto time_since_last_access =
      std::chrono::duration_cast<std::chrono::seconds>(now -
                                                       session->last_access);

  // Check if session has expired (timeout exceeded or negative time difference)
  bool expired = (time_since_last_access < std::chrono::seconds::zero() ||
                  time_since_last_access > session_timeout_);

  // Update last_access if requested and session is not expired
  if (update_last_access && !expired) {
    session->last_access = now;
  }
  return expired;
}

//------------------------------------------------------------------------------
// process request
//------------------------------------------------------------------------------

void request_service::process_request(const request_data_ptr& req) {
  try {
    switch (req->get_type()) {
      case request_type::kAuthenticate:
        process_authenticate_request(req);
        break;
      case request_type::kFindStudies:
        process_find_studies_request(req);
        break;
      default:
        break;
    }
  } catch (const site_server_exception& e) {
    req->write_output([&](json& output) {
      output.clear();
      output["status"] = e.get_code();
      output["message"] = e.what();
    });
  } catch (const std::exception& e) {
    req->write_output([&](json& output) {
      output.clear();
      output["status"] = EOS_UNKNOWN;
      output["message"] = e.what();
    });
  } catch (...) {
    req->write_output([&](json& output) {
      output.clear();
      output["status"] = EOS_UNKNOWN;
      output["message"] = "Unknown error";
    });
  }
}
