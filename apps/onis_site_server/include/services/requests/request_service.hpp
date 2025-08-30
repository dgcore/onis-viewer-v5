#pragma once

#include <memory>
#include "database/site_database_pool.hpp"

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

  // database pool access
  std::shared_ptr<site_database> get_database_connection();
  void return_database_connection(std::shared_ptr<site_database> connection);

  // prevent copy and move
  request_service(const request_service&) = delete;
  request_service& operator=(const request_service&) = delete;
  request_service(request_service&&) = delete;
  request_service& operator=(request_service&&) = delete;

private:
  std::unique_ptr<site_database_pool> database_pool_;
};
