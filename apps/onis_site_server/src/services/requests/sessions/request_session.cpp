#include "../../../../include/services/requests/sessions/request_session.hpp"

///////////////////////////////////////////////////////////////////////
// request_session
///////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// static constructor
//------------------------------------------------------------------------------

request_session_ptr request_session::create(const std::string& session_id) {
  return std::make_shared<request_session>(session_id);
}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

request_session::request_session(const std::string& session_id)
    : session_id(session_id) {
  first_access = std::chrono::system_clock::now();
  last_access = std::chrono::system_clock::now();
  superuser = false;
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

request_session::~request_session() {}
