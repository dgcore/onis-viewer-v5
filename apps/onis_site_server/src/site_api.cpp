#include "site_api.hpp"
#include <iostream>

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
    instance_ = std::shared_ptr<site_api>(new site_api());
  }
  return instance_;
}

site_api& site_api::instance() {
  if (!instance_) {
    instance_ = std::shared_ptr<site_api>(new site_api());
  }
  return *instance_;
}

//------------------------------------------------------------------------------
// Constructor and destructor
//------------------------------------------------------------------------------

site_api::site_api() : initialized_(false), config_file_path_("") {
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

bool site_api::initialize() {
  if (initialized_) {
    std::cerr << "site_api: API already initialized" << std::endl;
    return false;
  }

  try {
    // TODO: Initialize configuration service
    // TODO: Initialize database pool
    // TODO: Initialize HTTP server components

    initialized_ = true;
    std::cout << "site_api: Initialized successfully" << std::endl;
    return true;
  } catch (const std::exception& e) {
    std::cerr << "site_api: Initialization failed: " << e.what() << std::endl;
    return false;
  }
}

void site_api::shutdown() {
  if (!initialized_) {
    return;
  }

  try {
    // TODO: Shutdown HTTP server components
    // TODO: Shutdown database pool
    // TODO: Shutdown configuration service

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
// Configuration
//------------------------------------------------------------------------------

void site_api::set_config_file(const std::string& config_file_path) {
  config_file_path_ = config_file_path;
  std::cout << "site_api: Config file set to: " << config_file_path_
            << std::endl;
}

std::string site_api::get_config_file() const {
  return config_file_path_;
}