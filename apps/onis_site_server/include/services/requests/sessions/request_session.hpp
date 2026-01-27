#pragma once

#include <chrono>
#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include "../../../../include/database/items/db_partition.hpp"

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

  // partition access:
  onis::database::partition_access_mode partition_mode;
  std::unordered_map<
      std::string,
      std::pair<onis::database::partition_access_mode, std::uint32_t>>
      partition_access;
  // Individual access for each partition, album, and smart album (if
  // partition_mode is LIMITED_ACCESS):
  // key: partition_id, value: permission

  // std::unordered_map<std::string, std::uint32_t> partition_access;
  // std::unordered_map<std::string, std::uint32_t> album_access;
  // std::unordered_map<std::string, std::uint32_t> smart_album_access;
};
