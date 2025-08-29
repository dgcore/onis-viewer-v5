

#include "../../../include/network/drogon/drogon_http_server.hpp"

////////////////////////////////////////////////////////////////////////////////
// drogon_http_server
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// static constructor
//------------------------------------------------------------------------------

drogon_http_server_ptr drogon_http_server::create(
    const request_service_ptr& srv) {
  drogon_http_server_ptr ret = std::make_shared<drogon_http_server>(srv);
  ret->run();
  return ret;
}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

drogon_http_server::drogon_http_server(const request_service_ptr& srv)
    : dgc::thread() {
  this->rqsrv_ = srv;
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

drogon_http_server::~drogon_http_server() {}

//------------------------------------------------------------------------------
// init / exit
//------------------------------------------------------------------------------

void drogon_http_server::init_instance() {
  dgc::thread::init_instance();
  this->controller_ = http_drogon_controller::create(this->rqsrv_);
  this->th_ = std::thread(this->worker_thread, this, this->controller_);
}

void drogon_http_server::exit_instance() {
  std::cout << "Stopping drogon server..." << std::endl;
  drogon::app().quit();

  // Give the server a moment to stop gracefully
  std::this_thread::sleep_for(std::chrono::milliseconds(500));

  if (this->th_.joinable()) {
    std::cout << "Joining worker thread..." << std::endl;

    // Try to join with a timeout
    auto start = std::chrono::steady_clock::now();
    while (this->th_.joinable()) {
      auto now = std::chrono::steady_clock::now();
      auto elapsed =
          std::chrono::duration_cast<std::chrono::milliseconds>(now - start);
      if (elapsed.count() > 2000) {  // 2 second timeout
        std::cout << "Timeout waiting for worker thread, detaching..."
                  << std::endl;
        this->th_.detach();
        break;
      }
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    std::cout << "Worker thread handled" << std::endl;
  }
  dgc::thread::exit_instance();
}

void drogon_http_server::worker_thread(drogon_http_server* server,
                                       http_drogon_controller_ptr controller) {
  try {
    drogon::app()
        .addListener("0.0.0.0", 5555, true)
        .setThreadNum(10)
        .setSSLFiles("/Users/cedric/Documents/certificate.crt",
                     "/Users/cedric/Documents/private.key");
    drogon::app().registerController(controller);

    // Run Drogon directly in this thread (not detached)
    std::cout << "Starting drogon server" << std::endl;
    drogon::app().run();
    std::cout << "Drogon server stopped" << std::endl;
  } catch (const std::exception& ex) {
  }
}
