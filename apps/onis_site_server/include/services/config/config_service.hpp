#pragma once

#include <map>
#include <memory>
#include <string>

////////////////////////////////////////////////////////////////////////////////
// config_service class
////////////////////////////////////////////////////////////////////////////////

class config_service;
typedef std::shared_ptr<config_service> config_service_ptr;

class config_service {
public:
  // static constructor:
  static config_service_ptr create();

  // constructor:
  config_service();

  // destructor:
  ~config_service();

  // configuration management
  bool load_config(const std::string& config_file_path);
  bool save_config(const std::string& config_file_path);

  // database configuration
  std::string get_database_host() const;
  int get_database_port() const;
  std::string get_database_name() const;
  std::string get_database_user() const;
  std::string get_database_password() const;
  std::string get_database_type() const;

  // HTTP configuration
  int get_http_port() const;
  int get_https_port() const;
  bool is_ssl_enabled() const;
  std::string get_ssl_certificate_file() const;
  std::string get_ssl_private_key_file() const;

  // configuration validation
  bool is_valid() const;
  std::string get_last_error() const;

  // prevent copy and move
  config_service(const config_service&) = delete;
  config_service& operator=(const config_service&) = delete;
  config_service(config_service&&) = delete;
  config_service& operator=(config_service&&) = delete;

private:
  struct database_config {
    std::string host;
    int port;
    std::string database_name;
    std::string user;
    std::string password;
    std::string type;
  };

  struct http_config {
    int http_port;
    int https_port;
    bool ssl_enabled;
    std::string ssl_certificate_file;
    std::string ssl_private_key_file;
  };

  database_config db_config_;
  http_config http_config_;
  bool is_valid_;
  std::string last_error_;
};