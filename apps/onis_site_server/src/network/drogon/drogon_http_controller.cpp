#include "../../../include/network/drogon/drogon_http_controller.hpp"

////////////////////////////////////////////////////////////////////////////////
// drogon_http_controller
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

http_drogon_controller_ptr http_drogon_controller::create(
    /* const request_service_ptr& srv*/) {
  return std::make_shared<http_drogon_controller>(/*srv*/);
}

http_drogon_controller::http_drogon_controller(
    /*const request_service_ptr& srv*/) {
  // this->rqsrv_ = srv;
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

http_drogon_controller::~http_drogon_controller() {}
