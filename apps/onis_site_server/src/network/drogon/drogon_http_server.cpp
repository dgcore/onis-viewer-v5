#include "../../../include/network/drogon/drogon_http_server.hpp"

////////////////////////////////////////////////////////////////////////////////
// drogon_http_server
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// static constructor
//------------------------------------------------------------------------------

drogon_http_server_ptr drogon_http_server::create(
    const request_service_ptr& srv, const config_service_ptr& config) {
  return std::make_shared<drogon_http_server>(srv, config);
}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

drogon_http_server::drogon_http_server(const request_service_ptr& srv,
                                       const config_service_ptr& config)
    : rqsrv_(srv), config_service_(config) {
  std::cout << "drogon_http_server: Constructor" << std::endl;
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

drogon_http_server::~drogon_http_server() {
  std::cout << "drogon_http_server: Destructor" << std::endl;
}

//------------------------------------------------------------------------------
// init / exit
//------------------------------------------------------------------------------

void drogon_http_server::init_instance() {
  onis::thread::init_instance();
  std::cout << "drogon_http_server: init_instance" << std::endl;

  controller_ = http_drogon_controller::create(rqsrv_);
  th_ = std::thread(worker_thread, this, controller_);
}

void drogon_http_server::exit_instance() {
  std::cout << "drogon_http_server: exit_instance" << std::endl;
  drogon::app().quit();
  if (th_.joinable()) {
    th_.join();
  }
  onis::thread::exit_instance();
}

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

request_service_ptr drogon_http_server::get_request_service() const {
  return rqsrv_;
}

config_service_ptr drogon_http_server::get_config_service() const {
  return config_service_;
}

//------------------------------------------------------------------------------
// worker thread
//------------------------------------------------------------------------------

void drogon_http_server::worker_thread(drogon_http_server* server,
                                       http_drogon_controller_ptr controller) {
  try {
    // Get configuration values
    auto config = server->get_config_service();
    if (!config) {
      std::cerr << "drogon_http_server: No config service available"
                << std::endl;
      return;
    }

    int http_port = config->get_http_port();
    int https_port = config->get_https_port();
    bool ssl_enabled = config->is_ssl_enabled();
    std::string cert_file = config->get_ssl_certificate_file();
    std::string key_file = config->get_ssl_private_key_file();

    std::cout << "drogon_http_server: Configuring server with:" << std::endl;
    std::cout << "  HTTP port: " << http_port << std::endl;
    std::cout << "  HTTPS port: " << https_port << std::endl;
    std::cout << "  SSL enabled: " << (ssl_enabled ? "yes" : "no") << std::endl;
    if (ssl_enabled) {
      std::cout << "  Certificate file: " << cert_file << std::endl;
      std::cout << "  Private key file: " << key_file << std::endl;
    }

    // Configure Drogon with config values
    drogon::app()
        .addListener("0.0.0.0", https_port, true)   // HTTPS listener
        .addListener("0.0.0.0", http_port, false);  // HTTP listener

    // Set SSL files only if SSL is enabled
    if (ssl_enabled) {
      drogon::app().setSSLFiles(cert_file, key_file);
    }

    drogon::app().setThreadNum(10).registerController(controller);

    // Run Drogon directly in this thread (not detached)
    std::cout << "drogon_http_server: Starting drogon server" << std::endl;
    drogon::app().run();
    std::cout << "drogon_http_server: Drogon server stopped" << std::endl;
  } catch (const std::exception& ex) {
    std::cerr << "drogon_http_server: Exception in worker thread: " << ex.what()
              << std::endl;
  }
}
