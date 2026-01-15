#pragma once

#include <chrono>
#include <memory>
#include <string>

///////////////////////////////////////////////////////////////////////
// request_session
///////////////////////////////////////////////////////////////////////

class request_session;
typedef std::shared_ptr<request_session> request_session_ptr;
typedef std::weak_ptr<request_session> request_session_wptr;

class request_session {
public:
  // static constructor:
  static request_session_ptr create(const std::string& session_id);

  // constructor:
  request_session(const std::string& session_id);

  // destructor:
  virtual ~request_session();

  // properties:
  std::string prefix_key;
  std::string login;
  std::string session_id;
  std::chrono::system_clock::time_point first_access;
  std::chrono::system_clock::time_point last_access;
  std::string user_id;
  std::string site_id;
  std::string pref_set_id;
  std::string shared_pref_set_id;
  bool superuser;
};
