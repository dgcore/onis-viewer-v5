#ifdef FDSFDS
#include "../../../../include/database/items/db_album.hpp"
#include "../../../../include/database/items/db_partition.hpp"
#include "../../../../include/database/items/db_smart_album.hpp"
#include "../../../../include/database/site_database.hpp"
#include "../../../../include/database/sql_builder.hpp"
#include "../../../../include/services/requests/sessions/request_session_cache.hpp"

///////////////////////////////////////////////////////////////////////
// search_access_cache
///////////////////////////////////////////////////////////////////////

void search_access_cache::retrieve_all_partition_info(
    const std::string& site_id, std::uint32_t mode,
    const request_database& db) {
  // get the flags for the partitions, albums and smart albums:
  std::uint32_t part_flags = onis::database::info_partition_name |
                             onis::database::info_partition_status |
                             onis::database::info_partition_conflict;
  if (mode & onis::database::partition_access::all_albums)
    part_flags |= onis::database::info_partition_albums;
  if (mode & onis::database::partition_access::all_smart_albums)
    part_flags |= onis::database::info_partition_smart_albums;
  std::uint32_t album_flags =
      onis::database::info_album_name | onis::database::info_album_status;
  std::uint32_t smart_album_flags = onis::database::info_smart_album_name |
                                    onis::database::info_smart_album_status;

  // check if we need to retrieve the information from the database:
  bool need_retrieve =
      ((all_partitions_flags == 0) ||
       (part_flags & onis::database::info_partition_albums &&
        ((all_partitions_flags & onis::database::info_partition_albums) ==
         0)) ||
       (part_flags & onis::database::info_partition_smart_albums &&
        ((all_partitions_flags & onis::database::info_partition_smart_albums) ==
         0)));

  if (need_retrieve) {
    // Retrieve the partitions from the database:
    all_partitions_flags = part_flags | all_partitions_flags;
    partitions = Json::Value(Json::arrayValue);
    db->find_partitions_for_site(
        site_id, all_partitions_flags, album_flags, smart_album_flags,
        onis::database::lock_mode::NO_LOCK, all_partitions);
  }
}

Json::Value& search_access_cache::get_partition(const std::string& site_id,
                                                const std::string& part_id,
                                                std::uint32_t mode,
                                                const request_database& db) {
  std::uint32_t part_flags = onis::database::info_partition_name |
                             onis::database::info_partition_status |
                             onis::database::info_partition_conflict;
  if (mode & onis::database::partition_access::all_albums ||
      mode & onis::database::partition_access::limited_access)
    part_flags |= onis::database::info_partition_albums;
  if (mode & onis::database::partition_access::all_smart_albums ||
      mode & onis::database::partition_access::limited_access)
    part_flags |= onis::database::info_partition_smart_albums;
  std::uint32_t album_flags =
      onis::database::info_album_name | onis::database::info_album_status;
  std::uint32_t smart_album_flags = onis::database::info_smart_album_name |
                                    onis::database::info_smart_album_status;

  // Find the partition in the cache
  Json::ArrayIndex partition_index = 0;
  bool found = false;
  for (Json::ArrayIndex i = 0; i < partitions.size(); ++i) {
    if (partitions[i].isMember(BASE_SEQ_KEY) &&
        partitions[i][BASE_SEQ_KEY].asString() == part_id) {
      partition_index = i;
      found = true;
      break;
    }
  }

  bool need_retrieve = false;
  if (found) {
    // We found the partition information but we may lack the album or smart
    // album information. If this is the case, we need to retrieve it again
    // Note: This assumes partitions store flags somehow - you may need to
    // adjust this based on your actual data structure
    Json::Value& partition = partitions[partition_index];

    // Check if we have the required flags (you'll need to adjust this logic
    // based on how flags are stored in your Json::Value structure)
    need_retrieve = (part_flags & onis::database::info_partition_albums &&
                     !partition.isMember("albums")) ||
                    (part_flags & onis::database::info_partition_smart_albums &&
                     !partition.isMember("smart_albums"));

    if (!need_retrieve) {
      return partition;
    }

    // Remove the old partition info from the partitions list before
    // retrieving new info
    Json::ArrayIndex remove_index = partition_index;
    for (Json::ArrayIndex i = remove_index; i < partitions.size() - 1; ++i) {
      partitions[i] = partitions[i + 1];
    }
    partitions.resize(partitions.size() - 1);
  } else {
    need_retrieve = true;
  }

  if (need_retrieve) {
    // Check if we've previously retrieved all partitions
    if (all_partitions_flags != 0) {
      // Check if we already have the required albums/smart albums info
      bool has_all_info =
          (!(part_flags & onis::database::info_partition_albums) ||
           (all_partitions_flags & onis::database::info_partition_albums)) &&
          (!(part_flags & onis::database::info_partition_smart_albums) ||
           (all_partitions_flags &
            onis::database::info_partition_smart_albums));

      if (has_all_info) {
        // Search in all_partitions
        for (Json::ArrayIndex i = 0; i < all_partitions.size(); ++i) {
          if (all_partitions[i].isMember(BASE_SEQ_KEY) &&
              all_partitions[i][BASE_SEQ_KEY].asString() == part_id) {
            // Add to partitions cache and return
            Json::Value& partition = all_partitions[i];
            partitions.append(partition);
            return partition;
          }
        }
      }
    }

    // Need to retrieve partitions with the required flags
    all_partitions_flags = part_flags | all_partitions_flags;
    all_partitions = Json::Value(Json::arrayValue);
    db->find_partitions_for_site(
        site_id, all_partitions_flags, album_flags, smart_album_flags,
        onis::database::lock_mode::NO_LOCK, all_partitions);

    // Find the requested partition in all_partitions
    for (Json::ArrayIndex i = 0; i < all_partitions.size(); ++i) {
      if (all_partitions[i].isMember(BASE_SEQ_KEY) &&
          all_partitions[i][BASE_SEQ_KEY].asString() == part_id) {
        Json::Value& partition = all_partitions[i];
        partitions.append(partition);
        return partition;
      }
    }
  }

  // Partition not found - return empty object
  static Json::Value empty_partition(Json::objectValue);
  return empty_partition;
}
#endif