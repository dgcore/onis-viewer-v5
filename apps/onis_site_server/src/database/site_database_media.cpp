#include <iostream>
#include <sstream>
#include "../../include/database/items/db_media.hpp"
#include "../../include/database/site_database.hpp"
// #include "../../include/database/sql_builder.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Media operations
////////////////////////////////////////////////////////////////////////////////

std::string site_database::get_media_columns(std::uint32_t flags,
                                             b32 add_table_name) {
  std::string prefix = add_table_name ? "pacs_media." : "";
  std::string columns =
      prefix + "id, " + prefix + "site_id, " + prefix + "volume_id";
  if (flags == onis::database::info_media_data ||
      flags == onis::database::info_media_statistics) {
    columns += ", " + prefix + "type, " + prefix + "num, " + prefix + "path, " +
               prefix + "maxfill, " + prefix + "status";
  }
  return columns;
}

void site_database::read_media_record(onis_kit::database::database_row& rec,
                                      std::uint32_t flags,
                                      std::string* site_seq,
                                      std::string* volume_seq, json& output) {
  onis::database::media::create(output, flags);
  output[BASE_SEQ_KEY] = rec.get_string("id");
  if (site_seq) {
    *site_seq = rec.get_string("site_id");
  }
  if (volume_seq) {
    *volume_seq = rec.get_string("volume_id");
  }
  std::string folder;
  f64 ratio = 0.0;
  if (flags & onis::database::info_media_data) {
    output[ME_TYPE_KEY] = rec.get_int(ME_TYPE_KEY);
    output[ME_NUM_KEY] = rec.get_int(ME_NUM_KEY);
    output[ME_PATH_KEY] = rec.get_string(ME_PATH_KEY);
    output[ME_RATIO_KEY] = rec.get_double(ME_RATIO_KEY);
    output[ME_STATUS_KEY] = rec.get_int(ME_STATUS_KEY);
    folder = output[ME_PATH_KEY].asString();
    ratio = output[ME_RATIO_KEY].asDouble();
  } else if (flags & onis::database::info_media_statistics) {
    json tmp(Json::Value(Json::objectValue));
    folder = rec.get_string(ME_PATH_KEY);
    ratio = rec.get_double(ME_RATIO_KEY);
  }
  if (folder.empty() && flags & onis::database::info_media_statistics) {
    throw std::runtime_error("Media path is empty");
  }
  if (flags & onis::database::info_media_statistics) {
    try {
      std::error_code ec;
      auto space = std::filesystem::space(folder, ec);
      if (ec) {
        throw std::runtime_error("Failed to get disk space: " + ec.message());
      }
      std::uintmax_t total_space = space.capacity;
      std::uintmax_t free_space = space.free;
      std::uintmax_t available_space = space.available;
      output[ME_TOTAL_BYTES_KEY] = total_space;
      output[ME_FREE_BYTES_KEY] = available_space;
      if (flags & onis::database::info_media_data) {
        if (info.total_space > 0) {
          f32 tmp = (f32)available_space / (f32)total_space;
          if ((1.0 - tmp) * 100.0 > ratio)
            output[ME_STATUS_KEY] = onis::server::media_full;
          else
            output[ME_STATUS_KEY] = onis::server::media_available;
        } else
          output[ME_STATUS_KEY] = onis::server::media_full;
      }
    } catch (const std::runtime_error& e) {
      output[ME_TOTAL_BYTES_KEY] = 0;
      output[ME_FREE_BYTES_KEY] = 0;
      if (flags & onis::database::info_media_data) {
        output[ME_STATUS_KEY] = onis::server::media_full;
      }
    }
  }
}

void site_database::get_volume_media_list(const std::string& volume_seq,
                                          std::uint32_t flags, lock_mode lock,
                                          json& output) {
  // Create and prepare query:
  std::string columns = get_media_columns(flags, false);
  std::string where = "volume_id=?";
  auto query = create_and_prepare_query(columns, "pacs_media", where, lock);

  // Bind the seq parameter
  int index = 1;
  bind_parameter(query, index, volume_seq, "volume_seq");

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      json media = Json::Value(Json::objectValue);
      read_media_record(*row, flags, nullptr, nullptr, media);
      output.append(std::move(media));
    }
  }
}
