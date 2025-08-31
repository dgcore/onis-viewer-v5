#pragma once

#include <memory>
#include <string>

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
  bool initialize();
  void shutdown();
  bool is_initialized() const;

  // Configuration
  void set_config_file(const std::string& config_file_path);
  std::string get_config_file() const;

private:
  // Private constructor for singleton
  site_api();
  ~site_api();

  // Singleton instance
  static site_api_ptr instance_;

  // Internal state
  bool initialized_;
  std::string config_file_path_;
};

////////////////////////////////////////////////////////////////////////////////
// Global function for convenient access
////////////////////////////////////////////////////////////////////////////////

// Global function that returns a reference to the singleton instance
inline site_api& api() {
  return site_api::instance();
}