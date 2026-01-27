
#pragma once

#include <json/json.h>
#include <cstdint>
#include "../request_database.hpp"

///////////////////////////////////////////////////////////////////////
// search_partition_access_memo
///////////////////////////////////////////////////////////////////////

/*struct search_partition_access_cache {
  std::uint32_t partitions_flags{0};
  Json::Value partition{Json::objectValue};
};*/

///////////////////////////////////////////////////////////////////////
// search_dicom_access_memo
///////////////////////////////////////////////////////////////////////

/*struct search_dicom_access_cache {
  bool active{false};
  std::string client_seq;
  std::string client_ae;
  std::string client_name;
  std::string ae_ae;
};*/

///////////////////////////////////////////////////////////////////////
// search_access_cache
///////////////////////////////////////////////////////////////////////

/*using search_partition_access_cache_ptr =
    std::shared_ptr<search_partition_access_cache>;*/

// struct request_session_access_cache {
//  partition access:
// onis::database::partition_access_mode _partition_mode;

/*void retrieve_all_partition_info(const std::string& site_id,
                                 std::uint32_t mode,
                                 const request_database& db);
Json::Value& get_partition(const std::string& site_id,
                           const std::string& part_id, std::uint32_t mode,
                           const request_database& db);*/

/*search_partition_access_cache_ptr get_partition_info(
    const std::string& site_id, const std::string& part_id,
    std::uint32_t mode, const request_database& db);*/

// partition access:
// std::uint32_t all_partitions_flags{0};
// Json::Value all_partitions{Json::arrayValue};
// Json::Value partitions{Json::arrayValue};

// std::uint32_t all_partitions_flags{0};

// std::vector<search_partition_access_cache_ptr> partitions;

// dicom access:
// bool all_clients_retrieved{false};
// std::vector<std::unique_ptr<search_dicom_access_cache>> all_clients;
// std::vector<std::unique_ptr<search_dicom_access_cache>> clients;
//};
