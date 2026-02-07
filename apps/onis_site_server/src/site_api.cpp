#include "../include/site_api.hpp"
#include <iostream>
#include "../../../libs/onis_kit/include/core/exception.hpp"
#include "../../../shared/cpp/dicom/dicom_dcmtk.hpp"

////////////////////////////////////////////////////////////////////////////////
// site_api class - Singleton
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Static instance
//------------------------------------------------------------------------------

site_api_ptr site_api::instance_ = nullptr;

//------------------------------------------------------------------------------
// Singleton access
//------------------------------------------------------------------------------

site_api_ptr site_api::get_instance() {
  if (!instance_) {
    instance_ = std::make_shared<site_api>();
  }
  return instance_;
}

site_api& site_api::instance() {
  if (!instance_) {
    instance_ = std::make_shared<site_api>();
  }
  return *instance_;
}

//------------------------------------------------------------------------------
// Constructor and destructor
//------------------------------------------------------------------------------

site_api::site_api() noexcept {
  std::cout << "site_api: Singleton instance created" << std::endl;
}

site_api::~site_api() {
  if (initialized_) {
    shutdown();
  }
  std::cout << "site_api: Singleton instance destroyed" << std::endl;
}

//------------------------------------------------------------------------------
// API lifecycle
//------------------------------------------------------------------------------

bool site_api::initialize(const std::string& config_file_path) {
  if (initialized_) {
    std::cerr << "site_api: API already initialized" << std::endl;
    return false;
  }

  try {
    // Initialize config service
    config_service_ = config_service::create();
    if (!config_service_) {
      std::cerr << "site_api: Failed to create config service" << std::endl;
      return false;
    }

    // Load configuration from file
    if (!config_service_->load_config(config_file_path)) {
      std::cerr << "site_api: Failed to load configuration from: "
                << config_file_path << std::endl;
      return false;
    }

    // Validate configuration
    if (!config_service_->is_valid()) {
      std::cerr << "site_api: Configuration is not valid" << std::endl;
      return false;
    }

    // Initialize DICOM manager
    dicom_manager_ = dicom_dcmtk_manager::create();
    if (!dicom_manager_) {
      std::cerr << "site_api: Failed to create DICOM manager" << std::endl;
      return false;
    }

    // Initialize request service
    request_service_ = request_service::create();
    if (!request_service_) {
      std::cerr << "site_api: Failed to create request service" << std::endl;
      return false;
    }

    // Initialize HTTP server
    http_server_ =
        drogon_http_server::create(request_service_, config_service_);
    if (!http_server_) {
      std::cerr << "site_api: Failed to create HTTP server" << std::endl;
      return false;
    } else {
      std::cout << "site_api: HTTP server created successfully" << std::endl;
      http_server_->run();
      // drogon server will exit the application if it encounters a problem
      // to avoid crash, we pause the application here:
      std::this_thread::sleep_for(std::chrono::milliseconds(3));
    }
    initialized_ = true;
    std::cout << "site_api: Initialized successfully with config: "
              << config_file_path << std::endl;
    return true;
  } catch (const onis::exception& e) {
    std::cerr << "site_api: Initialization failed: " << e.what() << std::endl;
    shutdown();
    return false;
  } catch (const std::exception& e) {
    std::cerr << "site_api: Initialization failed: " << e.what() << std::endl;
    shutdown();
    return false;
  }
}

void site_api::shutdown() {
  try {
    // Shutdown HTTP server
    if (http_server_) {
      http_server_->stop();
      http_server_.reset();
    }

    // Shutdown request service
    if (request_service_) {
      request_service_.reset();
    }

    // Shutdown config service
    if (config_service_) {
      config_service_.reset();
    }

    // Shutdown DICOM manager
    if (dicom_manager_) {
      dicom_manager_.reset();
    }
    initialized_ = false;
    std::cout << "site_api: Shutdown completed" << std::endl;
  } catch (const std::exception& e) {
    std::cerr << "site_api: Shutdown failed: " << e.what() << std::endl;
  }
}

bool site_api::is_initialized() const {
  return initialized_;
}

//------------------------------------------------------------------------------
// Request service access
//------------------------------------------------------------------------------

request_service_ptr site_api::get_request_service() const {
  return request_service_;
}

//------------------------------------------------------------------------------
// Config service access
//------------------------------------------------------------------------------

config_service_ptr site_api::get_config_service() const {
  return config_service_;
}

//------------------------------------------------------------------------------
// HTTP server access
//------------------------------------------------------------------------------

drogon_http_server_ptr site_api::get_http_server() const {
  return http_server_;
}