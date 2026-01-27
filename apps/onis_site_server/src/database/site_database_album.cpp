#include "../../include/database/items/db_album.hpp"
#include "../../include/database/site_database.hpp"

std::string site_database::get_album_columns(std::uint32_t flags,
                                             bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_albums." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "partition_id, " + prefix + "name, " +
           prefix + "comment, " + prefix + "status";
  }
  std::string columns = prefix + "id, " + prefix + "partition_id";
  if (flags & onis::database::info_album_name)
    columns += ", " + prefix + "name";
  if (flags & onis::database::info_album_description)
    columns += ", " + prefix + "comment";
  if (flags & onis::database::info_album_status)
    columns += ", " + prefix + "status";
  return columns;
}

void site_database::get_partition_albums(const std::string& partition_id,
                                         std::uint32_t flags, lock_mode lock,
                                         Json::Value& output) const {
  // Create and prepare query:
  const auto columns = get_album_columns(flags, false);
  auto where = std::string("partition_id = ?");
  auto query = create_and_prepare_query(columns, "pacs_albums", where, lock);

  // Bind the seq parameter
  if (!query->bind_parameter(1, partition_id)) {
    std::throw_with_nested(std::runtime_error("Failed to bind idparameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      auto item = Json::Value(Json::objectValue);
      read_album_record(*row, flags, nullptr, item);
      output.append(std::move(item));
    }
  }
}

void site_database::read_album_record(onis_kit::database::database_row& rec,
                                      std::uint32_t flags,
                                      std::string* partition_id,
                                      json& output) const {
  onis::database::album::create(output, flags);
  output[BASE_SEQ_KEY] = rec.get_uuid("id", false, false);
  if (partition_id) {
    *partition_id = rec.get_uuid("partition_id", false, false);
  }
  if (flags & onis::database::info_album_name)
    output[AL_NAME_KEY] = rec.get_string(AL_NAME_KEY, false, false);
  if (flags & onis::database::info_album_description)
    output[AL_DESC_KEY] = rec.get_string(AL_DESC_KEY, true, true);
  if (flags & onis::database::info_album_status)
    output[AL_STATUS_KEY] = rec.get_int(AL_STATUS_KEY, false);
}