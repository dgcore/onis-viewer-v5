#pragma once

#include <memory>
#include <string>
#include "network/drogon/drogon_http_server.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/dicom/dicom.hpp"
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
  [[nodiscard]] bool is_initialized() const;

  // Request service access
  [[nodiscard]] request_service_ptr get_request_service() const;

  // Config service access
  [[nodiscard]] config_service_ptr get_config_service() const;

  // HTTP server access
  [[nodiscard]] drogon_http_server_ptr get_http_server() const;

  // Managers:
  [[nodiscard]] onis::dicom_manager_ptr get_dicom_manager() const;

  // Constructor and destructor
  site_api() noexcept;
  ~site_api();

private:
  // Singleton instance
  static site_api_ptr instance_;

  // Internal state
  bool initialized_{false};

  // Services
  request_service_ptr request_service_{nullptr};
  config_service_ptr config_service_{nullptr};
  drogon_http_server_ptr http_server_{nullptr};
  onis::dicom_manager_ptr dicom_manager_;
};

////////////////////////////////////////////////////////////////////////////////
// Global function for convenient access
////////////////////////////////////////////////////////////////////////////////

// Global function that returns a reference to the singleton instance
inline site_api& api() {
  return site_api::instance();
}