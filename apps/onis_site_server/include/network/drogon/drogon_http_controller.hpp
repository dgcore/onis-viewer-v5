#pragma once

#include <drogon/HttpController.h>
// #include "../../services/requests/request_service.hpp"

////////////////////////////////////////////////////////////////////////////////
// drogon_http_controller
////////////////////////////////////////////////////////////////////////////////

class http_drogon_controller;
typedef std::shared_ptr<http_drogon_controller> http_drogon_controller_ptr;

class http_drogon_controller
    : public drogon::HttpController<http_drogon_controller, false> {
public:
  // constructors:
  static http_drogon_controller_ptr create(/*const request_service_ptr& srv*/);
  http_drogon_controller(/*const request_service_ptr& srv*/);

  // cleanup:
  ~http_drogon_controller();

public:
  // routing table:
  METHOD_LIST_BEGIN
  METHOD_LIST_END

private:
  // request_service_ptr rqsrv_;
};