#include "../../include/database/items/db_partition.hpp"
#include "../../include/database/site_database.hpp"
#include "onis_kit/include/core/exception.hpp"

#include <string>

////////////////////////////////////////////////////////////////////////////////
// Partition operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_partition_columns(std::uint32_t flags,
                                                 bool add_table_name) const {
  std::string prefix = add_table_name ? "pacs_partitions." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "site_id, " + prefix + "volume_id, " +
           prefix + "name, " + prefix + "comment, " + prefix + "status, " +
           prefix + "parameters, " + prefix + "conflict";
  }
  std::string columns = prefix + "id, " + prefix + "site_id";
  if (flags & onis::database::info_partition_volume)
    columns += ", " + prefix + "volume_id";
  if (flags & onis::database::info_partition_name)
    columns += ", " + prefix + "name";
  if (flags & onis::database::info_partition_description)
    columns += ", " + prefix + "comment";
  if (flags & onis::database::info_partition_status)
    columns += ", " + prefix + "status";
  if (flags & onis::database::info_partition_parameters)
    columns += ", " + prefix + "parameters";
  if (flags & onis::database::info_partition_conflict)
    columns += ", " + prefix + "conflict";
  return columns;
}

void site_database::read_partition_record(onis_kit::database::database_row& rec,
                                          std::uint32_t flags,
                                          std::string* site_id, json& output) {
  onis::database::partition::create(output, flags);
  std::int32_t index = 0;
  output[BASE_SEQ_KEY] = rec.get_uuid(index, false, false);
  if (site_id) {
    *site_id = rec.get_uuid(index, false, false);
  } else {
    index++;
  }
  if (flags & onis::database::info_partition_volume)
    output[PT_VOLUME_KEY] = rec.get_uuid(index, true, true);
  if (flags & onis::database::info_partition_name)
    output[PT_NAME_KEY] = rec.get_string(index, false, false);
  if (flags & onis::database::info_partition_description)
    output[PT_DESC_KEY] = rec.get_string(index, true, true);
  if (flags & onis::database::info_partition_status)
    output[PT_STATUS_KEY] = rec.get_int(index, false);
  if (flags & onis::database::info_partition_parameters)
    output[PT_PARAM_KEY] = rec.get_string(index, false, false);
  if (flags & onis::database::info_partition_conflict)
    output[PT_HAVE_CONFLICT_KEY] = rec.get_int(index, false);
}

//------------------------------------------------------------------------------
// Find operations
//------------------------------------------------------------------------------

void site_database::find_partitions_for_site(
    const std::string& site_id, std::uint32_t flags, std::uint32_t album_flags,
    std::uint32_t smart_album_flags, lock_mode lock, Json::Value& output) {
  // Create and prepare query:
  std::string columns = get_partition_columns(flags, false);
  std::string where = "site_id = ?";
  auto query =
      create_and_prepare_query(columns, "pacs_partitions", where, lock);

  if (!query) {
    throw onis::exception(
        EOS_DB_QUERY, "Failed to create query for find_partitions_for_site");
  }

  // Bind the seq parameter
  if (!query->bind_parameter(1, site_id)) {
    std::throw_with_nested(std::runtime_error("Failed to bind idparameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      json item = Json::Value(Json::objectValue);
      read_partition_record(*row, flags, nullptr, item);
      if (flags & onis::database::info_partition_albums)
        get_partition_albums(item[BASE_SEQ_KEY].asString(), album_flags,
                             onis::database::lock_mode::NO_LOCK,
                             item[PT_ALBUMS_KEY]);
      if (flags & onis::database::info_partition_smart_albums)
        get_partition_smart_albums(
            item[BASE_SEQ_KEY].asString(), smart_album_flags,
            onis::database::lock_mode::NO_LOCK, item[PT_SMART_ALBUMS_KEY]);
      output.append(std::move(item));
    }
  }
}

void site_database::find_partition_by_seq(const std::string& seq,
                                          std::uint32_t flags,
                                          std::uint32_t album_flags,
                                          std::uint32_t smart_album_flags,
                                          lock_mode lock, std::string* site_seq,
                                          Json::Value& output) {
  // Create and prepare query:
  std::string columns = get_partition_columns(flags, false);
  std::string where = "id = ?";
  auto query =
      create_and_prepare_query(columns, "pacs_partitions", where, lock);

  if (!query) {
    throw onis::exception(EOS_DB_QUERY,
                          "Failed to create query for find_partition_by_seq");
  }

  // Bind the seq parameter
  if (!query->bind_parameter(1, seq)) {
    std::throw_with_nested(std::runtime_error("Failed to bind idparameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    auto row = result->get_next_row();
    read_partition_record(*row, flags, nullptr, output);
    if (flags & onis::database::info_partition_albums)
      get_partition_albums(seq, album_flags, onis::database::lock_mode::NO_LOCK,
                           output[PT_ALBUMS_KEY]);
    if (flags & onis::database::info_partition_smart_albums)
      get_partition_smart_albums(seq, smart_album_flags,
                                 onis::database::lock_mode::NO_LOCK,
                                 output[PT_SMART_ALBUMS_KEY]);
  } else {
    throw onis::exception(EOS_NOT_FOUND, "Partition not found");
  }
}

void site_database::find_partition_by_seq(
    const std::string& site_seq, const std::string& seq, std::uint32_t flags,
    std::uint32_t album_flags, std::uint32_t smart_album_flags,
    onis::database::lock_mode lock, Json::Value& output) {
  // Create and prepare query:
  std::string columns = get_partition_columns(flags, false);
  std::string where = "id = ? AND site_id = ?";
  auto query =
      create_and_prepare_query(columns, "pacs_partitions", where, lock);
  int index = 1;
  bind_parameter(query, index, seq, "seq");
  bind_parameter(query, index, site_seq, "site_seq");

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    auto row = result->get_next_row();
    read_partition_record(*row, flags, nullptr, output);
    if (flags & onis::database::info_partition_albums)
      get_partition_albums(seq, album_flags, onis::database::lock_mode::NO_LOCK,
                           output[PT_ALBUMS_KEY]);
    if (flags & onis::database::info_partition_smart_albums)
      get_partition_smart_albums(seq, smart_album_flags,
                                 onis::database::lock_mode::NO_LOCK,
                                 output[PT_SMART_ALBUMS_KEY]);
  } else {
    throw onis::exception(EOS_NOT_FOUND, "Partition not found");
  }
}

//------------------------------------------------------------------------------
// Modify operations
//------------------------------------------------------------------------------

void site_database::modify_partition(const Json::Value& partition,
                                     std::uint32_t flags) {
  // construct the sql command:
  std::string sql = "UPDATE pacs_partitions SET ";

  if (flags == 0)
    flags = partition[BASE_FLAGS_KEY].asUInt();
  else {
    std::uint32_t partition_flags = partition[BASE_FLAGS_KEY].asUInt();
    if ((partition_flags & flags) != flags) {
      throw onis::exception(EOS_INTERNAL, "Invalid flags");
    }
  }
  std::string values;
  if (flags & onis::database::info_partition_volume)
    values += ", VOLUME_ID=?";
  if (flags & onis::database::info_partition_name)
    values += ", NAME=?";
  if (flags & onis::database::info_partition_description)
    values += ", COMMENT=?";
  if (flags & onis::database::info_partition_status)
    values += ", STATUS=?";
  if (flags & onis::database::info_partition_parameters)
    values += ", PARAMETERS=?";
  if (flags & onis::database::info_partition_conflict)
    values += ", CONFLICT=?";
  if (!values.empty()) {
    sql += values.substr(2);
    sql += " WHERE ID=?";
    auto query = prepare_query(sql, "modify_partition");
    int index = 1;
    if (flags & onis::database::info_partition_volume) {
      auto volume_seq = partition[PT_VOLUME_KEY].asString();
      if (volume_seq.empty())
        query->bind_parameter(index, nullptr);
      else
        query->bind_parameter(index, volume_seq);
    }
    if (flags & onis::database::info_partition_name) {
      query->bind_parameter(index, partition[PT_NAME_KEY].asString());
    }
    if (flags & onis::database::info_partition_description) {
      query->bind_parameter(index, partition[PT_DESC_KEY].asString());
    }
    if (flags & onis::database::info_partition_status) {
      query->bind_parameter(index, partition[PT_STATUS_KEY].asInt());
    }
    if (flags & onis::database::info_partition_parameters) {
      query->bind_parameter(index, partition[PT_PARAM_KEY].asString());
    }
    if (flags & onis::database::info_partition_conflict) {
      query->bind_parameter(index, partition[PT_HAVE_CONFLICT_KEY].asInt());
    }
    query->bind_parameter(index, partition[BASE_SEQ_KEY].asString());
    execute_and_check_affected(query, "Partition not found");
  }
}