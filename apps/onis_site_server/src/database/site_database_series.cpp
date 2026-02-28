#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_series.hpp"
#include "../../include/database/site_database.hpp"
#include "../../include/site_api.hpp"
#include "onis_kit/include/utilities/date_time.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Series operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_series_columns(std::uint32_t flags,
                                              bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_series." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "study_id, " + prefix + "uid, " + prefix +
           "charset, " + prefix + "seriesdate, " + prefix + "seriestime, " +
           prefix + "modality, " + prefix + "bodypart, " + prefix + "srnum, " +
           prefix + "description, " + prefix + "comment, " + prefix +
           "station, " + prefix + "iconmedia, " + prefix + "iconpath, " +
           prefix + "propmedia, " + prefix + "proppath, " + prefix + "imcnt, " +
           prefix + "status, " + prefix + "crdate, " + prefix + "oid, " +
           prefix + "oname, " + prefix + "oip";
  }
  std::string columns =
      prefix + "id, " + prefix + "study_id, " + prefix + "uid";
  if (flags & onis::database::info_series_character_set) {
    columns += ", " + prefix + "charset";
  }
  if (flags & onis::database::info_series_date) {
    columns += ", " + prefix + "seriesdate, " + prefix + "seriestime";
  }
  if (flags & onis::database::info_series_modality) {
    columns += ", " + prefix + "modality";
  }
  if (flags & onis::database::info_series_body_part) {
    columns += ", " + prefix + "bodypart";
  }
  if (flags & onis::database::info_series_num) {
    columns += ", " + prefix + "srnum";
  }
  if (flags & onis::database::info_series_description) {
    columns += ", " + prefix + "description";
  }
  if (flags & onis::database::info_series_comment) {
    columns += ", " + prefix + "comment";
  }
  if (flags & onis::database::info_series_station) {
    columns += ", " + prefix + "station";
  }
  if (flags & onis::database::info_series_icon) {
    columns += ", " + prefix + "iconmedia, " + prefix + "iconpath";
  }
  if (flags & onis::database::info_series_properties) {
    columns += ", " + prefix + "propmedia, " + prefix + "proppath";
  }
  if (flags & onis::database::info_series_statistics) {
    columns += ", " + prefix + "imcnt";
  }
  if (flags & onis::database::info_series_status) {
    columns += ", " + prefix + "status";
  }
  if (flags & onis::database::info_series_creation) {
    columns += ", " + prefix + "crdate, " + prefix + "oid, " + prefix +
               "oname, " + prefix + "oip";
  }
  return columns;
}

void site_database::create_series_item(onis_kit::database::database_row& rec,
                                       std::uint32_t flags, bool for_client,
                                       std::int32_t* index,
                                       std::string* study_seq,
                                       Json::Value& series) {
  onis::database::series::create(series, flags, for_client);
  std::int32_t local_index = 0;
  std::int32_t* target_index = index ? index : &local_index;
  series[BASE_SEQ_KEY] = rec.get_uuid(*target_index, false, false);
  if (study_seq) {
    *study_seq = rec.get_uuid(*target_index, false, false);
  } else {
    (*target_index)++;
  }
  series[BASE_UID_KEY] = rec.get_string(*target_index, false, false);

  if (flags & onis::database::info_series_character_set) {
    series[SR_CHARSET_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_series_date) {
    series[SR_DATE_KEY] = rec.get_string(*target_index, true, true);
    series[SR_TIME_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_series_modality) {
    series[SR_MODALITY_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_series_body_part) {
    series[SR_BODYPART_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_series_num) {
    series[SR_NUM_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_series_description) {
    series[SR_DESC_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_series_comment) {
    series[SR_COMMENT_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_series_station) {
    series[SR_STATION_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_series_icon) {
    if (for_client) {
      (*target_index)++;
      std::string path = rec.get_string(*target_index, true, true);
      series[SR_ICON_KEY] = path.empty() ? 0 : 1;
    } else {
      series[SR_ICON_MEDIA_KEY] = rec.get_int(*target_index, false);
      series[SR_ICON_PATH_KEY] = rec.get_string(*target_index, true, true);
    }
  }
  if (flags & onis::database::info_series_properties) {
    if (for_client) {
      (*target_index)++;
      auto path = rec.get_string(*target_index, true, true);
      series[SR_PROP_KEY] = path.empty() ? 0 : 1;
    } else {
      series[SR_PROP_MEDIA_KEY] = rec.get_int(*target_index, false);
      series[SR_PROP_PATH_KEY] = rec.get_string(*target_index, true, true);
    }
  }
  if (flags & onis::database::info_series_statistics) {
    series[SR_IMCNT_KEY] = rec.get_int(*target_index, false);
  }
  if (flags & onis::database::info_series_status) {
    auto value = rec.get_uuid(*target_index, false, false);
    if (for_client) {
      if (value == ONLINE_STATUS)
        series[SR_STATUS_KEY] = 0;
      else
        series[SR_STATUS_KEY] = 1;

    } else
      series[SR_STATUS_KEY] = value;
  }
  if (flags & onis::database::info_series_creation) {
    series[SR_CRDATE_KEY] = rec.get_string(*target_index, false, false);
    series[SR_ORIGIN_ID_KEY] = rec.get_string(*target_index, true, true);
    series[SR_ORIGIN_NAME_KEY] = rec.get_string(*target_index, true, true);
    series[SR_ORIGIN_IP_KEY] = rec.get_string(*target_index, true, true);
  }
}

//------------------------------------------------------------------------------
// Get series
//------------------------------------------------------------------------------

bool site_database::get_online_series(const std::string& study_seq,
                                      const std::string& series_uid,
                                      std::uint32_t flags, bool for_client,
                                      lock_mode lock, Json::Value& output) {
  const auto columns = get_series_columns(flags, false);
  const std::string from = "pacs_series";
  const auto clause = "study_id=? and uid=? and status=?";
  auto query = create_and_prepare_query(columns, from, clause, lock);

  int index = 1;
  bind_parameter(query, index, study_seq, "study_id");
  bind_parameter(query, index, series_uid, "uid");
  bind_parameter(query, index, std::string(ONLINE_STATUS), "status");

  auto result = execute_query(query);
  if (result->has_rows()) {
    auto row = result->get_next_row();
    create_series_item(*row, flags, for_client, nullptr, nullptr, output);
    return true;
  } else
    return false;
}

//------------------------------------------------------------------------------
// Find operations
//------------------------------------------------------------------------------

void site_database::find_series(const std::string& study_seq,
                                std::uint32_t flags, bool for_client,
                                lock_mode lock, Json::Value& output) {
  const auto columns = get_series_columns(flags, false);
  const std::string from = "pacs_series";
  const auto clause = "study_id=?";
  auto query = create_and_prepare_query(columns, from, clause, lock);

  int index = 1;
  bind_parameter(query, index, study_seq, "study_id");

  auto result = execute_query(query);
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      Json::Value& series = output.append(Json::objectValue);
      create_series_item(*row, flags, for_client, nullptr, nullptr, series);
    }
  }
}

void site_database::find_online_series(const std::string& study_seq,
                                       std::uint32_t flags, bool for_client,
                                       lock_mode lock, Json::Value& output) {
  // construct the sql command:
  const auto columns = get_series_columns(flags, false);
  const std::string from = "pacs_series";
  const auto clause = "study_id=? and status=?";
  auto query = create_and_prepare_query(columns, from, clause, lock);

  int index = 1;
  bind_parameter(query, index, study_seq, "study_id");
  bind_parameter(query, index, std::string(ONLINE_STATUS), "status");

  auto result = execute_query(query);
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      Json::Value& series = output.append(Json::objectValue);
      create_series_item(*row, flags, for_client, nullptr, nullptr, series);
    }
  }
}

//------------------------------------------------------------------------------
// Create operations
//------------------------------------------------------------------------------

std::unique_ptr<onis_kit::database::database_query>
site_database::create_series_insertion_query(
    const std::string& study_seq, const onis::core::date_time& dt,
    const onis::dicom_base_ptr& dataset, bool create_icon,
    const std::string& origin_id, const std::string& origin_name,
    const std::string& origin_ip, Json::Value& series) {
  site_api_ptr api = site_api::get_instance();
  onis::dicom_manager_ptr manager = api->get_dicom_manager();

  std::string sql;
  std::string charset, date, time, series_uid, study_id, desc, modality,
      body_part, series_num, station;
  onis::dicom_charset_info_list desc_charsets, station_charsets;

  dataset->get_string_element(charset, TAG_SPECIFIC_CHARACTER_SET, "CS");
  dataset->get_string_element(series_uid, TAG_SERIES_INSTANCE_UID, "UI");
  dataset->get_string_element(modality, TAG_MODALITY, "CS");
  dataset->get_string_element(series_num, TAG_SERIES_NUMBER, "IS", charset);
  dataset->get_string_element(body_part, TAG_BODY_PART_EXAMINED, "CS", charset);
  dataset->get_string_element(desc, TAG_SERIES_DESCRIPTION, "LO", charset,
                              &desc_charsets);
  dataset->get_string_element(date, TAG_SERIES_DATE, "DA", charset);
  dataset->get_string_element(time, TAG_SERIES_TIME, "TM", charset);
  dataset->get_string_element(station, TAG_STATION_NAME, "SH", charset);
  if (station.length() > 16)
    station = station.substr(0, 16);

  charset = "";
  onis::dicom_charset_list done;
  for (std::int32_t i = 0; i < 1; i++) {
    onis::dicom_charset_info_list* list;
    switch (i) {
      case 0:
        list = &desc_charsets;
        break;
      default:
        list = nullptr;
        break;
    };

    onis::dicom_charset_info_list::const_iterator it1;
    for (it1 = list->begin(); it1 != list->end(); it1++) {
      const onis::dicom_charset* set =
          manager->find_character_set_by_info(*it1);
      if (set != nullptr) {
        if (std::find(done.begin(), done.end(), set) == done.end()) {
          if (!charset.empty())
            charset += "\\";
          charset += set->code;
          done.push_back(set);
        }
      }
    }
  }

  onis::core::date_time series_date;
  onis::util::datetime::check_date_and_time_validity(date, time, &series_date);

  return create_series_insertion_query(study_seq, dt, charset, series_uid, date,
                                       time, modality, series_num, body_part,
                                       desc, station, create_icon, origin_id,
                                       origin_name, origin_ip, series);
}

std::unique_ptr<onis_kit::database::database_query>
site_database::create_series_insertion_query(
    const std::string& study_seq, const onis::core::date_time& dt,
    const std::string& charset, const std::string& series_uid,
    const std::string& series_date, const std::string& series_time,
    const std::string& modality, const std::string& srnum,
    const std::string& bodypart, const std::string& description,
    const std::string& station, bool create_icon, const std::string& origin_id,
    const std::string& origin_name, const std::string& origin_ip,
    Json::Value& series) {
  // Format date and time as YYYYMMDD HHMMSS using standard C++
  std::ostringstream crdate_oss;
  crdate_oss << std::setfill('0') << std::setw(4) << dt.year() << std::setw(2)
             << dt.month() << std::setw(2) << dt.day() << " " << std::setw(2)
             << dt.hour() << std::setw(2) << dt.minute() << std::setw(2)
             << dt.second();
  std::string crdate = crdate_oss.str();
  std::string sql =
      "INSERT INTO PACS_SERIES (ID, STUDY_ID, UID, CHARSET, SERIESDATE, "
      "SERIESTIME, MODALITY, BODYPART, SRNUM, DESCRIPTION, COMMENT, STATION, "
      "ICONMEDIA, PROPMEDIA, IMCNT, STATUS, CRDATE, OID, ONAME, OIP) VALUES "
      "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

  std::string online_status = ONLINE_STATUS;
  auto query = prepare_query(sql, "create_series_insertion_query");

  int index = 1;
  std::string seq = onis::util::uuid::generate_random_uuid();
  bind_parameter(query, index, seq, "id");
  bind_parameter(query, index, study_seq, "study_id");
  bind_parameter(query, index, series_uid, "uid");
  bind_parameter(query, index, charset, "charset");
  bind_parameter(query, index, series_date, "seriesdate");
  bind_parameter(query, index, series_time, "seriestime");
  bind_parameter(query, index, modality, "modality");
  bind_parameter(query, index, bodypart, "bodypart");
  bind_parameter(query, index, srnum, "srnum");
  bind_parameter(query, index, description, "description");
  bind_parameter(query, index, std::string(""), "comment");
  bind_parameter(query, index, station, "station");
  bind_parameter(query, index, create_icon ? -2 : -1, "iconmedia");
  bind_parameter(query, index, -1, "propmedia");
  bind_parameter(query, index, 0, "imcnt");
  bind_parameter(query, index, online_status, "status");
  bind_parameter(query, index, crdate, "crdate");
  bind_parameter(query, index, origin_id, "oid");
  bind_parameter(query, index, origin_name, "oname");
  bind_parameter(query, index, origin_ip, "oip");

  onis::database::series::create(series, onis::database::info_all, false);
  series[SR_SEQ_KEY] = seq;
  series[SR_UID_KEY] = series_uid;
  series[SR_CHARSET_KEY] = charset;
  series[SR_DATE_KEY] = series_date;
  series[SR_TIME_KEY] = series_time;
  series[SR_NUM_KEY] = srnum;
  series[SR_NUM_KEY] = description;
  series[SR_MODALITY_KEY] = modality;
  series[SR_BODYPART_KEY] = bodypart;
  series[SR_STATION_KEY] = station;
  series[SR_IMCNT_KEY] = 0;
  series[SR_STATUS_KEY] = ONLINE_STATUS;
  series[SR_CRDATE_KEY] = crdate;
  series[SR_ORIGIN_ID_KEY] = origin_id;
  series[SR_ORIGIN_NAME_KEY] = origin_name;
  series[SR_ORIGIN_IP_KEY] = origin_ip;
  series[SR_ICON_MEDIA_KEY] = create_icon ? -2 : -1;
  series[SR_ICON_PATH_KEY] = "";
  series[SR_PROP_MEDIA_KEY] = -1;
  series[SR_PROP_PATH_KEY] = "";

  return query;
}

void site_database::create_series(
    const std::string& study_seq, const onis::core::date_time& dt,
    const onis::dicom_base_ptr& dataset, bool create_icon,
    const std::string& origin_id, const std::string& origin_name,
    const std::string& origin_ip, Json::Value& series) {
  auto query =
      create_series_insertion_query(study_seq, dt, dataset, create_icon,
                                    origin_id, origin_name, origin_ip, series);
  execute_and_check_affected(query, "Failed to create series");
}

//------------------------------------------------------------------------------
// Modify operations
//------------------------------------------------------------------------------

void site_database::modify_series(const Json::Value& series,
                                  std::uint32_t flags) {
  // analyze the flags:
  if (flags == 0)
    flags = series[BASE_FLAGS_KEY].asUInt();
  else {
    std::uint32_t series_flags = series[BASE_FLAGS_KEY].asUInt();
    if ((series_flags & flags) != flags) {
      throw onis::exception(EOS_INTERNAL, "Invalid series flags");
    }
  }

  // construct the sql command:
  std::string sql = "UPDATE PACS_SERIES SET ";
  std::string values;

  if (flags & onis::database::info_series_character_set)
    values += ", CHARSET=?";
  if (flags & onis::database::info_series_modality)
    values += ", MODALITY=?";
  if (flags & onis::database::info_series_num)
    values += ", SRNUM=?";
  if (flags & onis::database::info_series_body_part)
    values += ", BODYPART=?";
  if (flags & onis::database::info_series_description)
    values += ", DESCRIPTION=?";
  if (flags & onis::database::info_series_date)
    values += ", SERIESDATE=?, SERIESTIME=?";
  if (flags & onis::database::info_series_station)
    values += ", STATION=?";
  if (flags & onis::database::info_series_icon)
    values += ", ICONMEDIA=?, ICONPATH=?";
  if (flags & onis::database::info_series_properties)
    values += ", PROPMEDIA=?, PROPPATH=?";
  if (flags & onis::database::info_series_statistics)
    values += ", IMCNT=?";
  if (flags & onis::database::info_series_creation)
    values += ", CRDATE=?, OID=?, ONAME=?, OIP=?";
  if (flags & onis::database::info_series_status)
    values += ", STATUS=?";

  if (!values.empty()) {
    sql += values.substr(2);
    sql += " WHERE ID=?";

    auto query = prepare_query(sql, "modify_series");
    int index = 1;
    if (flags & onis::database::info_series_character_set)
      bind_parameter(query, index, series[SR_CHARSET_KEY].asString(),
                     "charset");
    if (flags & onis::database::info_series_modality)
      bind_parameter(query, index, series[SR_MODALITY_KEY].asString(),
                     "modality");
    if (flags & onis::database::info_series_num)
      bind_parameter(query, index, series[SR_NUM_KEY].asString(), "srnum");
    if (flags & onis::database::info_series_body_part)
      bind_parameter(query, index, series[SR_BODYPART_KEY].asString(),
                     "bodypart");
    if (flags & onis::database::info_series_description)
      bind_parameter(query, index, series[SR_DESC_KEY].asString(),
                     "description");
    if (flags & onis::database::info_series_date) {
      bind_parameter(query, index, series[SR_DATE_KEY].asString(),
                     "seriesdate");
      bind_parameter(query, index, series[SR_TIME_KEY].asString(),
                     "seriestime");
    }
    if (flags & onis::database::info_series_station)
      bind_parameter(query, index, series[SR_STATION_KEY].asString(),
                     "station");
    if (flags & onis::database::info_series_icon) {
      bind_parameter(query, index, series[SR_ICON_MEDIA_KEY].asInt(),
                     "iconmedia");
      bind_parameter(query, index, series[SR_ICON_PATH_KEY].asString(),
                     "iconpath");
    }
    if (flags & onis::database::info_series_properties) {
      bind_parameter(query, index, series[SR_PROP_MEDIA_KEY].asInt(),
                     "propmedia");
      bind_parameter(query, index, series[SR_PROP_PATH_KEY].asString(),
                     "proppath");
    }
    if (flags & onis::database::info_series_statistics)
      bind_parameter(query, index, series[SR_IMCNT_KEY].asInt(), "imcnt");
    if (flags & onis::database::info_series_creation) {
      bind_parameter(query, index, series[SR_CRDATE_KEY].asString(), "crdate");
      bind_parameter(query, index, series[SR_ORIGIN_ID_KEY].asString(), "oid");
      bind_parameter(query, index, series[SR_ORIGIN_NAME_KEY].asString(),
                     "oname");
      bind_parameter(query, index, series[SR_ORIGIN_IP_KEY].asString(), "oip");
    }
    if (flags & onis::database::info_series_status)
      bind_parameter(query, index, series[SR_STATUS_KEY].asString(), "status");
    bind_parameter(query, index, series[BASE_SEQ_KEY].asString(), "id");
    execute_and_check_affected(query, "Series not found");
  }
}
