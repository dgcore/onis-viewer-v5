#ifdef FDSFSD
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

///////////////////////////////////////////////////////////////////////
// search_album_access
///////////////////////////////////////////////////////////////////////

enum class album_type { album = 0, smart_album = 1 };

struct search_album_access {
  std::string id;
  std::string name;
  album_type type{album_type::album};
  std::uint32_t permission{0};
};

///////////////////////////////////////////////////////////////////////
// search_partition_access
///////////////////////////////////////////////////////////////////////

enum class partition_type { partition = 0, smart_partition = 1 };

struct search_partition_access {
  std::string id;
  std::string name;
  partition_type type{partition_type::partition};
  std::uint32_t permission{0};
  std::vector<std::unique_ptr<search_album_access>> albums;
};

///////////////////////////////////////////////////////////////////////
// search_dicom_access
///////////////////////////////////////////////////////////////////////

struct search_dicom_access {
  std::string id;
  std::string name;
  std::uint32_t permission{0};
};

///////////////////////////////////////////////////////////////////////
// search_access_result
///////////////////////////////////////////////////////////////////////
struct search_access_result {
  // void add_all_partitions_access(const Json::Value &partitions, std::int32_t
  // mode, onis::aresult &res); void add_partition_access(const Json::Value
  // &part_access, const Json::Value &partition, onis::aresult &res); void
  // add_all_albums_access(search_partition_access *p, const Json::Value
  // &partition, std::uint32_t partition_mode); void
  // add_album_access_from_list(search_partition_access *p, const Json::Value
  // &albums, std::int32_t album_type); void
  // add_album_access(search_partition_access *p, const Json::Value &album,
  // std::int32_t album_type, std::uint32_t permissions); search_album_access
  // *create_search_album_access(const Json::Value &album, std::int32_t
  // album_type, std::uint32_t permission); void
  // add_dicom_access(search_dicom_access_memo *info, onis::aresult &res); void
  // add_all_dicom_access(std::list<search_dicom_access_memo *> *clients,
  // onis::aresult &res);

  std::uint32_t partition_mode{0};
  std::uint32_t dicom_mode{0};
  std::vector<std::unique_ptr<search_partition_access>> partition_access;
  std::vector<std::unique_ptr<search_dicom_access>> dicom_access;
};

#endif