#include <filesystem>
#include <iostream>
#include <string>

#include "../include/site_api.hpp"
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/core/thread.hpp"

extern void dcmtk_init();
extern void dcmtk_deinit();

////////////////////////////////////////////////////////////////////////////////
// main_thread class
////////////////////////////////////////////////////////////////////////////////

class main_thread : public onis::thread {
public:
  main_thread() : thread() {
    std::cout << "Main thread constructor" << std::endl;
  }

  ~main_thread() {}

  void init_instance() {
    onis::thread::init_instance();

    // Initialize the site API with config file
    std::string config_file_path =
        "~/Documents/ONIS5/site_server/config/config.json";

    // Expand the tilde to home directory
    if (config_file_path[0] == '~') {
      const char* home_dir = getenv("HOME");
      if (home_dir) {
        config_file_path = std::string(home_dir) + config_file_path.substr(1);
      }
    }

    std::cout << "Initializing site API with config: " << config_file_path
              << std::endl;

    if (!api().initialize(config_file_path)) {
      std::cerr << "Failed to initialize site API" << std::endl;
      return;
    }

    std::cout << "Site API initialized successfully" << std::endl;
  }

  void exit_instance() {
    // Shutdown the site API
    api().shutdown();
    onis::thread::exit_instance();
  }

private:
  // No longer need individual service pointers as they're managed by site_api
};

int main() {
  std::cout << "Starting ONIS Site Server..." << std::endl;
  std::cout << "Initialize app..." << std::endl;
  dcmtk_init();
  main_thread th;
  th.run();
  std::cout << "Hit a key to stop the server" << std::endl;
  char cp_Buf[256];
  std::cin >> cp_Buf;
  std::cout << "Ending process..." << std::endl;
  th.stop();
  dcmtk_deinit();
  std::cout << "Process ended" << std::endl;
  return 0;
}