#include "../../include/database/items/db_volume.hpp"
#include "../../include/database/site_database.hpp"
#include "../../include/database/sql_builder.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

#include <iostream>
#include <sstream>

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Volume operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_volume_columns(u32 flags, bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_volumes." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "site_id, " + prefix + "name, " + prefix +
           "description";
  }
  std::string columns = prefix + "id, " + prefix + "site_id";
  if (flags & onis::database::info_volume_name) {
    columns += ", " + prefix + "name";
  }
  if (flags & onis::database::info_volume_description) {
    columns += ", " + prefix + "description";
  }
  return columns;
}

void site_database::read_volume_record(onis_kit::database::database_row& rec,
                                       u32 flags, std::string* site_seq,
                                       json& output) {
  onis::database::volume::create(output, flags);
  output[BASE_SEQ_KEY] = rec.get_string("id", false, false);
  if (site_seq) {
    *site_seq = rec.get_string("site_id", false, false);
  }
  if (flags & onis::database::info_volume_name) {
    output[VO_NAME_KEY] = rec.get_string(VO_NAME_KEY, false, false);
  }
  if (flags & onis::database::info_volume_description) {
    output[VO_DESC_KEY] = rec.get_string(VO_DESC_KEY, true, true);
  }
}

//------------------------------------------------------------------------------
// Find volumes
//------------------------------------------------------------------------------

void site_database::find_volume_by_seq(const std::string& seq, u32 flags,
                                       lock_mode lock, std::string* site_seq,
                                       json& output) {
  // Create and prepare query:
  std::string columns = get_volume_columns(flags, false);
  std::string where = "id = ?";
  auto query = create_and_prepare_query(columns, "pacs_volumes", where, lock);

  // Bind the seq parameter
  if (!query->bind_parameter(1, seq)) {
    std::throw_with_nested(std::runtime_error("Failed to bind seq parameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    auto row = result->get_next_row();
    if (row) {
      read_volume_record(*row, flags, site_seq, output);
      if (result->get_next_row()) {
        throw std::runtime_error("Multiple volumes found");
      }
      return;
    }
  }
  throw std::runtime_error("Volume not found");
}

void site_database::find_volume_by_seq(const std::string& site_seq,
                                       const std::string& seq, u32 flags,
                                       lock_mode lock, json& output) {
  // Create and prepare query:
  std::string columns = get_volume_columns(flags, false);
  std::string where = "id = ? AND site_id = ?";
  auto query = create_and_prepare_query(columns, "pacs_volumes", where, lock);

  // Bind the seq parameter
  if (!query->bind_parameter(1, seq)) {
    std::throw_with_nested(std::runtime_error("Failed to bind idparameter"));
  }
  if (!query->bind_parameter(2, site_seq)) {
    std::throw_with_nested(
        std::runtime_error("Failed to bind site_id parameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    auto row = result->get_next_row();
    if (row) {
      read_volume_record(*row, flags, nullptr, output);
      return;
    }
  }
  throw std::runtime_error("Volume not found");
}

void site_database::find_volumes_for_site(const std::string& site_seq,
                                          u32 flags, lock_mode lock,
                                          json& output) {
  // Create and prepare query:
  std::string columns = get_volume_columns(flags, false);
  std::string where = "site_id = ?";
  auto query = create_and_prepare_query(columns, "pacs_volumes", where, lock);

  // Bind the seq parameter
  int index = 1;
  bind_parameter(query, index, site_seq, "site_seq");

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      json volume = Json::Value(Json::objectValue);
      read_volume_record(*row, flags, nullptr, volume);
      output.append(std::move(volume));
    }
  }
}

//------------------------------------------------------------------------------
// Create volumes
//------------------------------------------------------------------------------

void site_database::create_volume(const std::string& site_seq,
                                  const json& input, json& output,
                                  u32 out_flags) {
  // construct the sql command:
  u32 in_flags = input[BASE_FLAGS_KEY].asUInt();
  std::string seq = dgc::util::uuid::generate_random_uuid();
  std::string sql = "INSERT INTO PACS_VOLUMES (ID, SITE_ID";
  if (in_flags & onis::database::info_volume_name)
    sql += ", NAME";
  if (in_flags & onis::database::info_volume_description)
    sql += ", DESCRIPTION";
  sql += ") VALUES (?, ?";
  if (in_flags & onis::database::info_volume_name)
    sql += ", ?";
  if (in_flags & onis::database::info_volume_description)
    sql += ", ?";
  sql += ")";

  auto query = prepare_query(sql, "create_volume");

  int index = 1;
  bind_parameter(query, index, seq, "seq");
  bind_parameter(query, index, site_seq, "site_seq");
  if (in_flags & onis::database::info_volume_name) {
    bind_parameter(query, index, input[VO_NAME_KEY].asString(), "name");
  }
  if (in_flags & onis::database::info_volume_description) {
    bind_parameter(query, index, input[VO_DESC_KEY].asString(), "description");
  }

  // Excute query:
  execute_and_check_affected(query, "Volume not created");
  find_volume_by_seq(seq, out_flags, onis::database::lock_mode::NONE, nullptr,
                     output);
}

//------------------------------------------------------------------------------
// Modify volumes
//------------------------------------------------------------------------------

void site_database::modify_volume(const json& volume) {
  std::string sql =
      "UPDATE pacs_volumes SET";  // name = ?, path = ? WHERE id = ?";
  u32 flags = volume[BASE_FLAGS_KEY].asUInt();
  std::string values = "";
  if (flags & onis::database::info_volume_name)
    values += ", name=?";
  if (flags & onis::database::info_volume_description)
    values += ", description=?";
  if (!values.empty()) {
    sql += values.substr(2);
    sql += " WHERE id=?";

    // Create and prepare query:
    auto query = prepare_query(sql, "modify_volume");

    // Bind the seq parameter
    s32 index = 1;
    if (flags & onis::database::info_volume_name) {
      bind_parameter(query, index, volume[VO_NAME_KEY].asString(), "name");
    }
    if (flags & onis::database::info_volume_description) {
      bind_parameter(query, index, volume[VO_DESC_KEY].asString(),
                     "description");
    }
    bind_parameter(query, index, volume[BASE_SEQ_KEY].asString(), "seq");

    // Execute query and check if any rows were affected
    execute_and_check_affected(query, "Volume not found");
  }

  // update the media:
  if (flags & onis::database::info_volume_media) {
    // delete all media related with the volume:
    sql = "DELETE FROM PACS_MEDIA WHERE VOLUME_ID=?";
    auto query = prepare_query(sql, "delete_volume");
    int index = 1;
    bind_parameter(query, index, volume[BASE_SEQ_KEY].asString(), "seq");
    execute_query(query);

    // insert the media one by one:
    for (size_t i = 0; i < volume[VO_MEDIA_KEY].size(); i++) {
      std::string seq = dgc::util::uuid::generate_random_uuid();
      std::string sql =
          "INSERT INTO PACS_MEDIA (ID, VOLUME_ID, TYPE, NUM, PATH, MAXFILL, "
          "STATUS) VALUES (?, ?, ?, ?, ?, ?, ?)";

      auto query = prepare_query(sql, "create_media");
      index = 1;
      bind_parameter(query, index, seq, "seq");
      bind_parameter(query, index, volume[BASE_SEQ_KEY].asString(), "site_id");
      const auto& media_item =
          volume[VO_MEDIA_KEY][static_cast<Json::ArrayIndex>(i)];
      bind_parameter(query, index, media_item[ME_TYPE_KEY].asInt(), "type");
      bind_parameter(query, index, media_item[ME_NUM_KEY].asInt(), "num");
      bind_parameter(query, index, media_item[ME_PATH_KEY].asString(), "path");
      bind_parameter(query, index, media_item[ME_RATIO_KEY].asDouble(),
                     "ratio");
      bind_parameter(query, index, media_item[ME_STATUS_KEY].asInt(), "status");
      execute_and_check_affected(query, "Media not created");
    }
  }
}

//------------------------------------------------------------------------------
// Delete volumes
//------------------------------------------------------------------------------

void site_database::delete_volume(const std::string& seq) {
  // delete the media:
  std::string sql =
      sql_builder_->build_delete_query("PACS_MEDIA", "VOLUME_ID=?");
  auto query = prepare_query(sql, "delete_media");
  if (!query->bind_parameter(1, seq)) {
    std::throw_with_nested(std::runtime_error("Failed to bind seq parameter"));
  }
  execute_query(query);

  // update the partitions using the volume:
  sql = sql_builder_->build_update_query("PACS_PARTITIONS", {"VOLUME_ID=NULL"},
                                         "VOLUME_ID=?");
  query = prepare_query(sql, "delete_partition");
  int index = 1;
  bind_parameter(query, index, seq, "seq");
  execute_query(query);

  // delete the volume:
  sql = sql_builder_->build_delete_query("PACS_VOLUMES", "ID=?");
  query = prepare_query(sql, "delete_volume");
  index = 1;
  bind_parameter(query, index, seq, "seq");
  execute_and_check_affected(query, "Volume not found");
}