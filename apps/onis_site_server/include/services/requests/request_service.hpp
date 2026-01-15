#pragma once

#include <chrono>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include "../../database/site_database_pool.hpp"
#include "./request_data.hpp"
#include "./request_exceptions.hpp"
#include "./sessions/request_session.hpp"
#include "onis_kit/include/core/result.hpp"

class request_service;
typedef std::shared_ptr<request_service> request_service_ptr;

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

////////////////////////////////////////////////////////////////////////////////
// request_service class
////////////////////////////////////////////////////////////////////////////////

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

  // sessions:
  void register_session(const request_session_ptr& session);
  void unregister_session(const std::string& session_id);
  request_session_ptr find_session(const std::string& session_id) const;
  void cleanup_sessions();
  bool is_session_expired(const request_session_ptr& session,
                          bool update_last_access = false);

  void process_request(const request_data_ptr& req);

  void process_authenticate_request(const request_data_ptr& req);

private:
  // database pool
  std::unique_ptr<site_database_pool> database_pool_;

  // sessions
  std::map<std::string, request_session_ptr> sessions_;
  mutable std::mutex sessions_mutex_;
  std::chrono::seconds session_timeout_;
};
