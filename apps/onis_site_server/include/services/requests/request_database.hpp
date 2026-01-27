#pragma once

#include <memory>
#include "../../database/site_database.hpp"

class request_service;

////////////////////////////////////////////////////////////////////////////////
// request_service class
////////////////////////////////////////////////////////////////////////////////

class request_database {
public:
  // constructor:
  request_database(request_service* service);

  // destructor:
  ~request_database();

  // prevent copy and move:
  request_database(const request_database&) = delete;
  request_database& operator=(const request_database&) = delete;
  request_database(request_database&&) = delete;
  request_database& operator=(request_database&&) = delete;

  // operators:
  std::shared_ptr<site_database> operator->();
  const std::shared_ptr<site_database> operator->() const;

private:
  request_service* service_;
  std::shared_ptr<site_database> db_;
};
