#include <iomanip>
#include "../../include/database/items/db_download_series.hpp"
#include "../../include/database/site_database.hpp"
#include "onis_kit/include/utilities/date_time.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_download_series_columns(bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_download_series." : "";
  return prefix + "id, " + prefix + "series_id, " + prefix + "session_id, " +
         prefix + "date, " + prefix + "completed, " + prefix + "result, " +
         prefix + "expected";
}

void site_database::create_download_series_item(
    const onis_kit::database::database_row& rec, int* index,
    Json::Value& item) {
  std::int32_t local_index = 0;
  int* target_index = index != nullptr ? index : &local_index;
  onis::database::download_series::create(item);
  item[BASE_SEQ_KEY] = rec.get_uuid(*target_index, false, false);
  item[DS_SERIES_KEY] = rec.get_string(*target_index, false, false);
  item[DS_SESSION_KEY] = rec.get_string(*target_index, false, false);
  item[DS_DATE_KEY] = rec.get_string(*target_index, false, false);
  item[DS_COMPLETED_KEY] = rec.get_int(*target_index, false);
  item[DS_RESULT_KEY] = rec.get_int(*target_index, false);
  item[DS_EXPECTED_KEY] = rec.get_int(*target_index, false);
}

//------------------------------------------------------------------------------
// Creation
//------------------------------------------------------------------------------

std::unique_ptr<onis_kit::database::database_query>
site_database::create_download_series_insertion_query(
    const std::string& series_seq, const std::string& session_id,
    const onis::core::date_time& dt, std::int32_t completed, std::int32_t error,
    std::int32_t expected, Json::Value& output) {
  // Format date and time as YYYYMMDD HHMMSS using standard C++
  std::ostringstream crdate_oss;
  crdate_oss << std::setfill('0') << std::setw(4) << dt.year() << std::setw(2)
             << dt.month() << std::setw(2) << dt.day() << " " << std::setw(2)
             << dt.hour() << std::setw(2) << dt.minute() << std::setw(2)
             << dt.second();
  std::string crdate = crdate_oss.str();
  std::string sql =
      "INSERT INTO PACS_DOWNLOAD_SERIES (ID, SERIES_ID, SESSION_ID, DATE, "
      "COMPLETED, RESULT, EXPECTED) VALUES (?, ?, ?, ?, ?, ?, ?)";

  auto query = prepare_query(sql, "create_download_series_insertion_query");

  int index = 1;
  std::string seq = onis::util::uuid::generate_random_uuid();
  bind_parameter(query, index, seq, "id");
  bind_parameter(query, index, series_seq, "series_id");
  bind_parameter(query, index, session_id, "session_id");
  bind_parameter(query, index, crdate, "date");
  bind_parameter(query, index, completed, "completed");
  bind_parameter(query, index, error, "result");
  bind_parameter(query, index, expected, "expected");

  onis::database::download_series::create(output);
  output[BASE_SEQ_KEY] = seq;
  output[DS_SERIES_KEY] = series_seq;
  output[DS_SESSION_KEY] = session_id;
  output[DS_DATE_KEY] = crdate;
  output[DS_COMPLETED_KEY] = completed;
  output[DS_RESULT_KEY] = error;
  output[DS_EXPECTED_KEY] = expected;

  return query;
}

void site_database::create_download_series(
    const std::string& series_seq, const std::string& session_id,
    const onis::core::date_time& dt, std::int32_t completed, std::int32_t error,
    std::int32_t expected, Json::Value& output) {
  auto query = create_download_series_insertion_query(
      series_seq, session_id, dt, completed, error, expected, output);
  execute_and_check_affected(query, "Failed to create download series");
}

//------------------------------------------------------------------------------
// Find
//------------------------------------------------------------------------------

void site_database::find_download_series_by_seq(const std::string& seq,
                                                lock_mode lock_mode,
                                                Json::Value& output) {
  const auto columns = get_download_series_columns(false);
  const std::string from = "pacs_download_series";
  const auto clause = "id=?";
  auto query = create_and_prepare_query(columns, from, clause, lock_mode);

  int index = 1;
  bind_parameter(query, index, seq, "id");

  auto result = execute_query(query);
  if (result->has_rows()) {
    auto row = result->get_next_row();
    create_download_series_item(*row, nullptr, output);
  } else {
    throw onis::exception(EOS_NOT_FOUND, "Download series not found");
  }
}

//------------------------------------------------------------------------------
// Modify
//------------------------------------------------------------------------------

void site_database::set_download_series_status(const std::string& seq,
                                               std::int32_t completed,
                                               std::int32_t error,
                                               std::int32_t expected) {
  std::string sql =
      "UPDATE PACS_DOWNLOAD_SERIES SET COMPLETED=?, ERROR=?, EXPECTED=? WHERE "
      "ID=?";
  auto query = prepare_query(sql, "set_download_series_status");
  int index = 1;
  bind_parameter(query, index, completed, "completed");
  bind_parameter(query, index, error, "error");
  bind_parameter(query, index, expected, "expected");
  bind_parameter(query, index, seq, "id");
  execute_and_check_affected(query, "Failed to set download series status");
}
