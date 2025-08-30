#include "../../../include/services/config/config_service.hpp"
#include <fstream>
#include <iostream>
#include <sstream>

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

  std::stringstream buffer;
  buffer << file.rdbuf();
  std::string content = buffer.str();
  file.close();

  // TODO: Implement JSON parsing
  // For now, just mark as valid if file exists
  is_valid_ = true;
  last_error_ = "";

  return true;
}

bool config_service::save_config(const std::string& config_file_path) {
  // TODO: Implement JSON generation and file writing
  last_error_ = "Save config not implemented yet";
  return false;
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