#include "../../include/database/items/db_partition.hpp"
#include "../../include/database/site_database.hpp"

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

void site_database::find_partitions_for_site(
    const std::string& site_id, std::uint32_t flags, std::uint32_t album_flags,
    std::uint32_t smart_album_flags, lock_mode lock, Json::Value& output) {
  // Create and prepare query:
  std::string columns = get_partition_columns(flags, false);
  std::string where = "site_id = ?";
  auto query =
      create_and_prepare_query(columns, "pacs_partitions", where, lock);

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

void site_database::read_partition_record(onis_kit::database::database_row& rec,
                                          std::uint32_t flags,
                                          std::string* site_id, json& output) {
  onis::database::partition::create(output, flags);
  output[BASE_SEQ_KEY] = rec.get_uuid("id", false, false);
  if (site_id) {
    *site_id = rec.get_uuid("site_id", false, false);
  }
  if (flags & onis::database::info_partition_volume)
    output[PT_VOLUME_KEY] = rec.get_uuid("volume_id", true, true);
  if (flags & onis::database::info_partition_name)
    output[PT_NAME_KEY] = rec.get_string(PT_NAME_KEY, false, false);
  if (flags & onis::database::info_partition_description)
    output[PT_DESC_KEY] = rec.get_string(PT_DESC_KEY, true, true);
  if (flags & onis::database::info_partition_status)
    output[PT_STATUS_KEY] = rec.get_int(PT_STATUS_KEY, false);
  if (flags & onis::database::info_partition_parameters)
    output[PT_PARAM_KEY] = rec.get_string(PT_PARAM_KEY, false, false);
  if (flags & onis::database::info_partition_conflict)
    output[PT_HAVE_CONFLICT_KEY] = rec.get_int(PT_HAVE_CONFLICT_KEY, false);
}