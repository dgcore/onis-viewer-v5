#include "../../../include/services/config/config_service.hpp"
#include <json/json.h>
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

  try {
    Json::Value j;
    Json::Reader reader;
    if (!reader.parse(file, j)) {
      last_error_ = "JSON parsing error: " + reader.getFormattedErrorMessages();
      return false;
    }

    // Parse database configuration
    if (j.isMember("database")) {
      const auto& db = j["database"];
      db_config_.host =
          db.isMember("host") ? db["host"].asString() : "localhost";
      db_config_.port = db.isMember("port") ? db["port"].asInt() : 5432;
      db_config_.database_name = db.isMember("database_name")
                                     ? db["database_name"].asString()
                                     : "onis_site_db";
      db_config_.user =
          db.isMember("user") ? db["user"].asString() : "postgres";
      db_config_.password =
          db.isMember("password") ? db["password"].asString() : "";
      db_config_.type =
          db.isMember("type") ? db["type"].asString() : "postgresql";
    }

    // Parse HTTP configuration
    if (j.isMember("http")) {
      const auto& http = j["http"];
      http_config_.http_port =
          http.isMember("http_port") ? http["http_port"].asInt() : 5556;
      http_config_.https_port =
          http.isMember("https_port") ? http["https_port"].asInt() : 5555;

      // Parse nested SSL configuration
      if (http.isMember("ssl")) {
        const auto& ssl = http["ssl"];
        http_config_.ssl_enabled =
            ssl.isMember("enabled") ? ssl["enabled"].asBool() : true;
        http_config_.ssl_certificate_file =
            ssl.isMember("certificate_file")
                ? ssl["certificate_file"].asString()
                : "certificates/certificate.crt";
        http_config_.ssl_private_key_file =
            ssl.isMember("private_key_file")
                ? ssl["private_key_file"].asString()
                : "certificates/private.key";
      } else {
        // Fallback to top-level SSL settings if nested structure not found
        http_config_.ssl_enabled =
            http.isMember("ssl_enabled") ? http["ssl_enabled"].asBool() : true;
        http_config_.ssl_certificate_file =
            http.isMember("certificate_file")
                ? http["certificate_file"].asString()
                : "certificates/certificate.crt";
        http_config_.ssl_private_key_file =
            http.isMember("private_key_file")
                ? http["private_key_file"].asString()
                : "certificates/private.key";
      }
    }

    is_valid_ = true;
    last_error_ = "";
    return true;

  } catch (const std::exception& e) {
    last_error_ = "JSON parsing error: " + std::string(e.what());
    return false;
  } catch (const std::exception& e) {
    last_error_ = "File reading error: " + std::string(e.what());
    return false;
  }
}

bool config_service::save_config(const std::string& config_file_path) {
  try {
    Json::Value j;

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
    j["http"]["ssl"]["enabled"] = http_config_.ssl_enabled;
    j["http"]["ssl"]["certificate_file"] = http_config_.ssl_certificate_file;
    j["http"]["ssl"]["private_key_file"] = http_config_.ssl_private_key_file;

    std::ofstream file(config_file_path);
    if (!file.is_open()) {
      last_error_ =
          "Could not open config file for writing: " + config_file_path;
      return false;
    }

    // Pretty print with 2 spaces indentation
    Json::StreamWriterBuilder builder;
    builder["indentation"] = "  ";
    std::unique_ptr<Json::StreamWriter> writer(builder.newStreamWriter());
    writer->write(j, &file);
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