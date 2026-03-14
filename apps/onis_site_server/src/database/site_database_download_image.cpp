#include <iomanip>
#include "../../include/database/items/db_download_image.hpp"
#include "../../include/database/site_database.hpp"
#include "onis_kit/include/utilities/date_time.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_download_image_columns(bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_download_image." : "";
  return prefix + "id, " + prefix + "series_id, " + prefix + "num, " + prefix +
         "path, " + prefix + "type, " + prefix + "rescnt, " + prefix + "result";
}

void site_database::create_download_image_item(
    const onis_kit::database::database_row& rec, Json::Value& output) {
  std::int32_t local_index = 0;
  onis::database::download_image::create(output);
  output[BASE_SEQ_KEY] = rec.get_uuid(local_index, false, false);
  output[DI_SERIES_KEY] = rec.get_uuid(local_index, false, false);
  output[DI_NUM_KEY] = rec.get_int(local_index, false);
  output[DI_PATH_KEY] = rec.get_string(local_index, false, false);
  output[DI_TYPE_KEY] = rec.get_int(local_index, false);
  output[DI_RESCNT_KEY] = rec.get_int(local_index, false);
  output[DI_RESULT_KEY] = rec.get_int(local_index, false);
}

//------------------------------------------------------------------------------
// Find operations
//------------------------------------------------------------------------------

void site_database::find_download_image_by_index(
    const std::string& download_seq, std::int32_t index,
    onis::database::lock_mode lock_mode, Json::Value& output) {
  const auto columns = get_download_image_columns(false);
  const std::string from = "pacs_download_image";

  std::string clause = "series_id=? AND num=?";
  auto query = create_and_prepare_query(columns, from, clause, lock_mode);

  std::int32_t bind_pos = 1;
  bind_parameter(query, bind_pos, download_seq, "series_id");
  bind_parameter(query, bind_pos, index, "num");

  auto result = execute_query(query);
  if (result->has_rows()) {
    auto row = result->get_next_row();
    create_download_image_item(*row, output);
  } else {
    throw site_server_exception(EOS_NOT_FOUND, "Download image not found");
  }
}

//------------------------------------------------------------------------------
// Create operations
//------------------------------------------------------------------------------

std::unique_ptr<onis_kit::database::database_query>
site_database::create_download_image_insertion_query(
    const std::string& series_seq, std::int32_t num, const std::string& path,
    std::int32_t type, std::int32_t rescnt, std::int32_t error,
    Json::Value& output) {
  std::string sql =
      "INSERT INTO pacs_download_image (series_id, num, path, type, rescnt, "
      "result) VALUES (?, ?, ?, ?, ?, ?)";
  auto query = prepare_query(sql, "create_download_image_insertion_query");
  std::int32_t index = 1;
  bind_parameter(query, index, series_seq, "series_id");
  bind_parameter(query, index, num, "num");
  bind_parameter(query, index, path, "path");
  bind_parameter(query, index, type, "type");
  bind_parameter(query, index, rescnt, "rescnt");
  bind_parameter(query, index, error, "result");
  return query;
}

void site_database::create_download_image(
    const std::string& series_seq, std::int32_t num, const std::string& path,
    std::int32_t type, std::int32_t rescnt, std::int32_t error,
    Json::Value& output) {
  auto query = create_download_image_insertion_query(
      series_seq, num, path, type, rescnt, error, output);
  execute_and_check_affected(query, "Failed to create download image");
}
