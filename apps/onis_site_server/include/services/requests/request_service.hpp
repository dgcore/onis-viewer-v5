#pragma once

#include <chrono>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include "../../database/site_database_pool.hpp"

#include "./request_data.hpp"
#include "./request_database.hpp"
#include "./request_exceptions.hpp"

#include "./sessions/request_session.hpp"

// #include "./sessions/request_session_access.hpp"
// #include "./sessions/request_session_cache.hpp"
#include "onis_kit/include/core/result.hpp"

class request_service;
typedef std::shared_ptr<request_service> request_service_ptr;

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

  // Authentication:
  void get_user_configuration(const request_database& db,
                              const request_session_ptr& session,
                              Json::Value& config) const;
  void create_configuration_source_nodes(const request_database& db,
                                         const request_session_ptr& session,
                                         Json::Value& sources) const;

  void analyze_partition_access(
      const request_session_ptr& session, const Json::Value& user,
      const std::unordered_map<std::string, const Json::Value&>& roles,
      const request_database& db) const;
  void analyze_partition_access_from_role(
      const request_session_ptr& session, const std::string& role_id,
      const std::unordered_map<std::string, const Json::Value&>& roles,
      std::set<std::string>& circular_loop, const request_database& db) const;
  /*void get_session_permissions(bool only_privileges,
                               search_access_result& result,
                               const request_database& db,
                               const request_session_ptr& session,
                               const Json::Value& user) const;*/
  /*void _get_session_permissions(b32 only_privileges,
                                search_access_result* result,
                                sdb_access_ptr& db,
                                const request_session_ptr& session,
                                const Json::Value& user, onis::aresult& res);
  void _get_session_permission_from_role(
      b32 only_privileges, const request_session_ptr& session,
      search_access_result* result, search_access_memo* memo,
      const sdb_access_ptr& db, const onis::astring& role_seq,
      const onis::astring& site_seq,
      std::map<onis::astring, std::int32_t>& circular_loop, onis::aresult& res);
  void _get_session_permission_from_role(
      b32 privileges, b32 partitions, b32 dicom, b32 pref,
      const request_session_ptr& session, search_access_result* result,
      search_access_memo* memo, const sdb_access_ptr& db,
      const onis::astring& role_seq, const onis::astring& site_seq,
      std::map<onis::astring, std::int32_t>& circular_loop, onis::aresult&
  res);*/
  /*void analyze_partition_access(search_access_result& result,
                                search_access_cache& cache,
                                const request_database& db,
                                const Json::Value& access, bool superuser,
                                const std::string& site_id) const;
  void analyze_dicom_access(search_access_result& result,
                            search_access_cache& cache,
                            const request_database& db,
                            const Json::Value& access, bool superuser,
                            const std::string& site_id) const;
  void analyze_user_privileges(const request_session_ptr& session,
                               const Json::Value& permissions) const;*/
};
