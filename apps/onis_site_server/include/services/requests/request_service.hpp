#pragma once

#include <memory>

////////////////////////////////////////////////////////////////////////////////
// request_service class
////////////////////////////////////////////////////////////////////////////////

class request_service;
typedef std::shared_ptr<request_service> request_service_ptr;

class request_service {
public:
  // static constructor:
  static request_service_ptr create();

  // constructor:
  request_service();

  // destructor:
  ~request_service();

  // prevent copy and move
  request_service(const request_service&) = delete;
  request_service& operator=(const request_service&) = delete;
  request_service(request_service&&) = delete;
  request_service& operator=(request_service&&) = delete;
};
