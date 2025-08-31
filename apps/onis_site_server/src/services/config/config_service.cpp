#include "../../../include/services/config/config_service.hpp"
#include <fstream>
#include <iostream>
#include <nlohmann/json.hpp>
#include <sstream>

using json = nlohmann::json;

////////////////////////////////////////////////////////////////////////////////
// config_service class
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// static constructor
//------------------------------------------------------------------------------

config_service_ptr config_service::create() {
  config_service_ptr ret = std::make_shared<config_service>();
  return ret;
}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

config_service::config_service() : is_valid_(false), last_error_("") {
  // Initialize with default values
  db_config_.host = "localhost";
  db_config_.port = 5432;
  db_config_.database_name = "onis_site_db";
  db_config_.user = "postgres";
  db_config_.password = "";
  db_config_.type = "postgresql";

  http_config_.http_port = 5556;
  http_config_.https_port = 5555;
  http_config_.ssl_enabled = true;
  http_config_.ssl_certificate_file = "certificates/certificate.crt";
  http_config_.ssl_private_key_file = "certificates/private.key";
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

config_service::~config_service() {}

//------------------------------------------------------------------------------
// configuration management
//------------------------------------------------------------------------------

bool config_service::load_config(const std::string& config_file_path) {
  std::ifstream file(config_file_path);
  if (!file.is_open()) {
    last_error_ = "Could not open config file: " + config_file_path;
    return false;
  }

  try {
    json j = json::parse(file);

    // Parse database configuration
    if (j.contains("database")) {
      auto& db = j["database"];
      db_config_.host = db.value("host", "localhost");
      db_config_.port = db.value("port", 5432);
      db_config_.database_name = db.value("database_name", "onis_site_db");
      db_config_.user = db.value("user", "postgres");
      db_config_.password = db.value("password", "");
      db_config_.type = db.value("type", "postgresql");
    }

    // Parse HTTP configuration
    if (j.contains("http")) {
      auto& http = j["http"];
      http_config_.http_port = http.value("http_port", 5556);
      http_config_.https_port = http.value("https_port", 5555);
      http_config_.ssl_enabled = http.value("ssl_enabled", true);
      http_config_.ssl_certificate_file =
          http.value("ssl_certificate_file", "certificates/certificate.crt");
      http_config_.ssl_private_key_file =
          http.value("ssl_private_key_file", "certificates/private.key");
    }

    is_valid_ = true;
    last_error_ = "";
    return true;

  } catch (const json::exception& e) {
    last_error_ = "JSON parsing error: " + std::string(e.what());
    return false;
  } catch (const std::exception& e) {
    last_error_ = "File reading error: " + std::string(e.what());
    return false;
  }
}

bool config_service::save_config(const std::string& config_file_path) {
  try {
    json j;

    // Database configuration
    j["database"]["host"] = db_config_.host;
    j["database"]["port"] = db_config_.port;
    j["database"]["database_name"] = db_config_.database_name;
    j["database"]["user"] = db_config_.user;
    j["database"]["password"] = db_config_.password;
    j["database"]["type"] = db_config_.type;

    // HTTP configuration
    j["http"]["http_port"] = http_config_.http_port;
    j["http"]["https_port"] = http_config_.https_port;
    j["http"]["ssl_enabled"] = http_config_.ssl_enabled;
    j["http"]["ssl_certificate_file"] = http_config_.ssl_certificate_file;
    j["http"]["ssl_private_key_file"] = http_config_.ssl_private_key_file;

    std::ofstream file(config_file_path);
    if (!file.is_open()) {
      last_error_ =
          "Could not open config file for writing: " + config_file_path;
      return false;
    }

    file << j.dump(2);  // Pretty print with 2 spaces indentation
    file.close();

    last_error_ = "";
    return true;

  } catch (const std::exception& e) {
    last_error_ = "Save config error: " + std::string(e.what());
    return false;
  }
}

//------------------------------------------------------------------------------
// database configuration
//------------------------------------------------------------------------------

std::string config_service::get_database_host() const {
  return db_config_.host;
}

int config_service::get_database_port() const {
  return db_config_.port;
}

std::string config_service::get_database_name() const {
  return db_config_.database_name;
}

std::string config_service::get_database_user() const {
  return db_config_.user;
}

std::string config_service::get_database_password() const {
  return db_config_.password;
}

std::string config_service::get_database_type() const {
  return db_config_.type;
}

//------------------------------------------------------------------------------
// HTTP configuration
//------------------------------------------------------------------------------

int config_service::get_http_port() const {
  return http_config_.http_port;
}

int config_service::get_https_port() const {
  return http_config_.https_port;
}

bool config_service::is_ssl_enabled() const {
  return http_config_.ssl_enabled;
}

std::string config_service::get_ssl_certificate_file() const {
  return http_config_.ssl_certificate_file;
}

std::string config_service::get_ssl_private_key_file() const {
  return http_config_.ssl_private_key_file;
}

//------------------------------------------------------------------------------
// configuration validation
//------------------------------------------------------------------------------

bool config_service::is_valid() const {
  return is_valid_;
}

std::string config_service::get_last_error() const {
  return last_error_;
}