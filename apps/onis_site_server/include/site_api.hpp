#pragma once

#include <memory>
#include <string>
#include "network/drogon/drogon_http_server.hpp"
#include "services/config/config_service.hpp"
#include "services/requests/request_service.hpp"

////////////////////////////////////////////////////////////////////////////////
// site_api class - Singleton
////////////////////////////////////////////////////////////////////////////////

class site_api;
typedef std::shared_ptr<site_api> site_api_ptr;

class site_api {
public:
  // Singleton access
  static site_api_ptr get_instance();
  static site_api& instance();

  // Prevent copy and move
  site_api(const site_api&) = delete;
  site_api& operator=(const site_api&) = delete;
  site_api(site_api&&) = delete;
  site_api& operator=(site_api&&) = delete;

  // API lifecycle
  bool initialize(const std::string& config_file_path);
  void shutdown();
  bool is_initialized() const;

  // Request service access
  request_service_ptr get_request_service() const;

  // Config service access
  config_service_ptr get_config_service() const;

  // HTTP server access
  drogon_http_server_ptr get_http_server() const;

  // Constructor and destructor
  site_api();
  ~site_api();

private:
  // Singleton instance
  static site_api_ptr instance_;

  // Internal state
  bool initialized_;

  // Services
  request_service_ptr request_service_;
  config_service_ptr config_service_;
  drogon_http_server_ptr http_server_;
};

////////////////////////////////////////////////////////////////////////////////
// Global function for convenient access
////////////////////////////////////////////////////////////////////////////////

// Global function that returns a reference to the singleton instance
inline site_api& api() {
  return site_api::instance();
}