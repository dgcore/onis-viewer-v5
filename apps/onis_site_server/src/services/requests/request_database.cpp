#include "../../../include/services/requests/request_database.hpp"
#include "../../../include/services/requests/request_service.hpp"

////////////////////////////////////////////////////////////////////////////////
// request_database class
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

request_database::request_database(request_service* service) {
  service_ = service;
  db_ = service->get_database_connection();
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

request_database::~request_database() {
  service_->return_database_connection(db_);
}

//------------------------------------------------------------------------------
// operators
//------------------------------------------------------------------------------

std::shared_ptr<site_database> request_database::operator->() {
  return db_;
}

const std::shared_ptr<site_database> request_database::operator->() const {
  return db_;
}
