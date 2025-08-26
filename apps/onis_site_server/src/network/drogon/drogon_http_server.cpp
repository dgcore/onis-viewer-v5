

#include "../../../include/network/drogon/drogon_http_server.hpp"

////////////////////////////////////////////////////////////////////////////////
// drogon_http_server
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// static constructor
//------------------------------------------------------------------------------

drogon_http_server_ptr drogon_http_server::create() {
  drogon_http_server_ptr ret = std::make_shared<drogon_http_server>();
  ret->run();
  return ret;
}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

drogon_http_server::drogon_http_server() : dgc::thread() {}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

drogon_http_server::~drogon_http_server() {}

//------------------------------------------------------------------------------
// init / exit
//------------------------------------------------------------------------------

void drogon_http_server::init_instance() {
  dgc::thread::init_instance();
  this->controller_ = http_drogon_controller::create(/*this->rqsrv_*/);
  this->th_ = std::thread(this->worker_thread, this, this->controller_);
}

void drogon_http_server::exit_instance() {
  drogon::app().quit();
  if (this->th_.joinable()) {
    this->th_.join();
  }
  dgc::thread::exit_instance();
}

void drogon_http_server::worker_thread(drogon_http_server* server,
                                       http_drogon_controller_ptr controller) {
  try {
    drogon::app()
        .addListener("0.0.0.0", 5555, true)
        .setThreadNum(10)
        .setSSLFiles(
            "/home/hibino/Documents/HCR-X1/certificate/certificate.crt",
            "/home/hibino/Documents/HCR-X1/certificate/private.key");
    drogon::app().registerController(controller);
    std::thread([]() { drogon::app().run(); }).detach();
  } catch (const std::exception& ex) {
  }
}
