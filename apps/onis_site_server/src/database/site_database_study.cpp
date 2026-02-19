#include <iomanip>
#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_series.hpp"
#include "../../include/database/items/db_study.hpp"
#include "../../include/database/site_database.hpp"
#include "../../include/site_api.hpp"
#include "onis_kit/include/utilities/date_time.hpp"
#include "onis_kit/include/utilities/string.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Study operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_study_columns(std::uint32_t flags,
                                             bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_studies." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "patient_id, " + prefix + "uid, " +
           prefix + "charset, " + prefix + "studydate, " + prefix +
           "studytime, " + prefix + "modalities, " + prefix + "bodyparts, " +
           prefix + "accnum, " + prefix + "studyid, " + prefix +
           "description, " + prefix + "age, " + prefix + "institution, " +
           prefix + "comment, " + prefix + "stations, " + prefix + "srcnt, " +
           prefix + "imcnt, " + prefix + "rptcnt, " + prefix + "status, " +
           prefix + "conflict_id, " + prefix + "crdate, " + prefix + "oid, " +
           prefix + "oname, " + prefix + "oip";
  }

  std::string columns =
      prefix + "id, " + prefix + "patient_id, " + prefix + "uid";
  if (flags & onis::database::info_study_character_set) {
    columns += ", " + prefix + "charset";
  }
  if (flags & onis::database::info_study_date) {
    columns += ", " + prefix + "studydate, " + prefix + "studytime";
  }
  if (flags & onis::database::info_study_modalities) {
    columns += ", " + prefix + "modalities";
  }
  if (flags & onis::database::info_study_body_parts) {
    columns += ", " + prefix + "bodyparts";
  }
  if (flags & onis::database::info_study_accnum) {
    columns += ", " + prefix + "accnum";
  }
  if (flags & onis::database::info_study_id) {
    columns += ", " + prefix + "studyid";
  }
  if (flags & onis::database::info_study_description) {
    columns += ", " + prefix + "description";
  }
  if (flags & onis::database::info_study_age) {
    columns += ", " + prefix + "age";
  }
  if (flags & onis::database::info_study_institution) {
    columns += ", " + prefix + "institution";
  }
  if (flags & onis::database::info_study_comment) {
    columns += ", " + prefix + "comment";
  }
  if (flags & onis::database::info_study_stations) {
    columns += ", " + prefix + "stations";
  }
  if (flags & onis::database::info_study_statistics) {
    columns +=
        ", " + prefix + "srcnt, " + prefix + "imcnt, " + prefix + "rptcnt";
  }
  if (flags & onis::database::info_study_status) {
    columns += ", " + prefix + "status, " + prefix + "conflict_id";
  }
  if (flags & onis::database::info_study_creation) {
    columns += ", " + prefix + "crdate, " + prefix + "oid, " + prefix +
               "oname, " + prefix + "oip";
  }
  return columns;
}

void site_database::create_study_item(onis_kit::database::database_row& rec,
                                      std::uint32_t flags, bool for_client,
                                      std::string* patient_seq,
                                      Json::Value& study,
                                      std::int32_t* start_index) {
  onis::database::study::create(study, flags, for_client);
  std::int32_t index = 0;
  std::int32_t* target_index = start_index ? start_index : &index;
  study[BASE_SEQ_KEY] = rec.get_uuid(*target_index, false, false);
  if (patient_seq) {
    *patient_seq = rec.get_uuid(*target_index, false, false);
  } else {
    (*target_index)++;
  }
  study[BASE_UID_KEY] = rec.get_string(*target_index, false, false);
  if (flags & onis::database::info_study_character_set) {
    study[ST_CHARSET_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_date) {
    study[ST_DATE_KEY] = rec.get_string(*target_index, true, true);
    study[ST_TIME_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_modalities) {
    study[ST_MODALITIES_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_body_parts) {
    study[ST_BODYPARTS_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_accnum) {
    study[ST_ACCNUM_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_id) {
    study[ST_STUDYID_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_description) {
    study[ST_DESC_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_age) {
    study[ST_AGE_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_institution) {
    study[ST_INSTITUTION_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_comment) {
    study[ST_COMMENT_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_stations) {
    study[ST_STATIONS_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_study_statistics) {
    study[ST_SRCNT_KEY] = rec.get_int(*target_index, false);
    study[ST_IMCNT_KEY] = rec.get_int(*target_index, false);
    study[ST_RPTCNT_KEY] = rec.get_int(*target_index, false);
  }
  if (flags & onis::database::info_study_status) {
    auto status = rec.get_uuid(*target_index, false, false);
    auto conflict = rec.get_uuid(*target_index, true, true);
    if (for_client) {
      if (status == ONLINE_STATUS)
        study[ST_STATUS_KEY] = 0;
      else if (conflict.empty())
        study[ST_STATUS_KEY] = 1;
      else
        study[ST_STATUS_KEY] = 2;
    } else {
      study[ST_STATUS_KEY] = status;
      study[ST_CONFLICT_KEY] = conflict;
    }
  }
  if (flags & onis::database::info_study_creation) {
    study[ST_CRDATE_KEY] = rec.get_string(*target_index, false, false);
    study[ST_ORIGIN_ID_KEY] = rec.get_string(*target_index, true, true);
    study[ST_ORIGIN_NAME_KEY] = rec.get_string(*target_index, true, true);
    study[ST_ORIGIN_IP_KEY] = rec.get_string(*target_index, true, true);
  }
}

void site_database::create_patient_and_study_item(
    onis_kit::database::database_row& rec, std::uint32_t patient_flags,
    std::uint32_t study_flags, bool for_client, bool for_album,
    Json::Value& patient, Json::Value& study) {
  std::int32_t start_index = 0;
  create_patient_item(rec, patient_flags, for_client, nullptr, patient,
                      &start_index);
  create_study_item(rec, study_flags, for_client, nullptr, study, &start_index);
  /*if (for_album && res.good()) {
    bool valid = true;
    std::int32_t all_studies = 0;
    // we need to update the patient seq with the one from the patient link
    // table:
    if (!_help_read_uuid(rec, start_index, patient, BASE_SEQ_KEY, false))
      valid = false;
    // does the patient link displays all the studies?
    else if (rec.get_int32(start_index, &all_studies) != EOS_NONE)
      valid = false;
    else
      start_index++;

    // if the patient link display all the studies, the statistics of the
    // patient and studies are the ones from the patient and study itself
    if (valid && all_studies == 0) {
      // the patient does not display all the studies.
      // the patient statistics must be taken from the patient link.
      if (!_help_read_int32(rec, start_index, patient_flags,
                            onis::server::info_patient_statistics, patient,
                            PA_STCNT_KEY))
        valid = false;
      else if (!_help_read_int32(rec, start_index, patient_flags,
                                 onis::server::info_patient_statistics, patient,
                                 PA_SRCNT_KEY))
        valid = false;
      else if (!_help_read_int32(rec, start_index, patient_flags,
                                 onis::server::info_patient_statistics, patient,
                                 PA_IMCNT_KEY))
        valid = false;
      else {
        std::int32_t all_series = 0;
        // the study seq must be the one from the study link:
        if (!_help_read_uuid(rec, start_index, study, BASE_SEQ_KEY, false))
          valid = false;
        // does the study link displays all the series?
        else if (rec.get_int32(start_index, &all_series) != EOS_NONE)
          valid = false;
        else
          start_index++;

        if (valid && all_series == 0) {
          // the study does not display all the series.
          // we have to read the statistics and others properties from the study
          // link:
          if (!_help_read_string(rec, start_index, study_flags,
                                 onis::server::info_study_modalities, study,
                                 ST_MODALITIES_KEY, true))
            valid = false;
          else if (!_help_read_string(rec, start_index, study_flags,
                                      onis::server::info_study_body_parts,
                                      study, ST_BODYPARTS_KEY, true))
            valid = false;
          else if (!_help_read_string(rec, start_index, study_flags,
                                      onis::server::info_study_stations, study,
                                      ST_STATIONS_KEY, true))
            valid = false;
          else if (!_help_read_int32(rec, start_index, study_flags,
                                     onis::server::info_study_statistics, study,
                                     ST_SRCNT_KEY))
            valid = false;
          else if (!_help_read_int32(rec, start_index, study_flags,
                                     onis::server::info_study_statistics, study,
                                     ST_IMCNT_KEY))
            valid = false;
          else if (!_help_read_int32(rec, start_index, study_flags,
                                     onis::server::info_study_statistics, study,
                                     ST_RPTCNT_KEY))
            valid = false;
        }
      }
    }
    if (!valid)
      res.set(OSRSP_FAILURE, EOS_DB_QUERY, "", false);
  }*/
}

//------------------------------------------------------------------------------
// Find studies
//------------------------------------------------------------------------------

/*void find_studies(const std::string& partition_seq,
                  bool reject_empty_request, std::int32_t limit,
                  const onis::dicom_file_ptr& dataset,
                  const onis::astring& code_page, bool patient_root,
                  std::uint32_t patient_flags, std::uint32_t study_flags, bool
   for_client, std::int32_t lock_mode, Json::Value& output, onis::aresult&
   res);*/
void site_database::find_studies(const std::string& partition_seq,
                                 bool reject_empty_request, std::int32_t limit,
                                 const Json::Value& filters,
                                 std::uint32_t patient_flags,
                                 std::uint32_t study_flags, bool for_client,
                                 lock_mode lock, Json::Value& output) {
  // create the filter clause:
  bool have_criteria = false;
  std::string filter_clause =
      construct_study_filter_clause(filters, true, have_criteria);
  if (reject_empty_request && !have_criteria) {
    return;
  }

  // construct the sql command:
  const auto study_columns = get_study_columns(study_flags, true);
  const auto patient_columns = get_patient_columns(patient_flags, true);
  const auto columns = patient_columns + ", " + study_columns;
  const std::string from =
      "pacs_studies inner join pacs_patients on pacs_patients.id = "
      "pacs_studies.patient_id";
  const auto clause = "pacs_patients.partition_id=?" + filter_clause +
                      " order by pacs_studies.studydate desc";
  auto query = create_and_prepare_query(columns, from, clause, lock, limit);

  std::int32_t index = 1;
  bind_parameter(query, index, partition_seq, "partition_seq");
  bind_parameters_for_study_filter_clause(query, index, filters, true);

  auto result = execute_query(query);
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      Json::Value& item = output.append(Json::objectValue);
      item["patient"] = Json::Value(Json::objectValue);
      item["study"] = Json::Value(Json::objectValue);
      create_patient_and_study_item(*row, patient_flags, study_flags,
                                    for_client, false, item["patient"],
                                    item["study"]);
    }
  }
}

void site_database::find_studies(const std::string& patient_seq,
                                 std::uint32_t flags, bool for_client,
                                 lock_mode lock, Json::Value& output) {}
/*bool decode_find_study_filters_from_dataset(
    const onis::dicom_file_ptr& dataset, const std::string& code_page,
    bool patient_root, Json::Value& filters);*/
void site_database::find_online_studies(const std::string& patient_seq,
                                        std::uint32_t flags, bool for_client,
                                        lock_mode lock, Json::Value& output) {}
/*void find_studies_from_album(const onis::astring& album_seq,
                             bool reject_empty_request, std::int32_t limit,
                             const onis::dicom_file_ptr& dataset,
                             const onis::astring& code_page, bool patient_root,
                             std::uint32_t patient_flags, std::uint32_t
study_flags, bool for_client, std::int32_t lock_mode, Json::Value& output,
onis::aresult& res); void find_studies_from_album(const onis::astring&
album_seq, bool reject_empty_request, std::int32_t limit, const Json::Value&
filters, std::uint32_t patient_flags, std::uint32_t study_flags, bool
for_client, std::int32_t lock_mode, Json::Value& output, onis::aresult& res);*/
void site_database::find_study_by_seq(const std::string& partition_seq,
                                      const std::string& study_seq,
                                      std::uint32_t patient_flags,
                                      std::uint32_t study_flags,
                                      bool for_client, lock_mode lock,
                                      Json::Value& output) {}
void site_database::find_study_by_seq(const std::string& seq,
                                      std::uint32_t flags, bool for_client,
                                      lock_mode lock, Json::Value& output,
                                      std::string* patient_seq) {}
bool site_database::find_study_patient(const std::string& study_seq,
                                       std::uint32_t patient_flags,
                                       bool for_client, lock_mode lock,
                                       Json::Value& output,
                                       std::string* partition_seq) {}

void site_database::find_online_and_conflicted_studies(
    const std::string& partition_seq, const std::string& study_uid,
    lock_mode lock, std::uint32_t patient_flags, std::uint32_t study_flags,
    bool for_client, Json::Value& output) {
  const auto study_columns = get_study_columns(study_flags, true);
  const auto patient_columns = get_patient_columns(patient_flags, true);
  const auto columns = patient_columns + ", " + study_columns;
  const std::string from =
      "pacs_studies inner join pacs_patients on pacs_patients.id = "
      "pacs_studies.patient_id";
  const auto clause =
      "pacs_patients.partition_id=? and pacs_studies.uid=? and "
      "(pacs_studies.status=? or pacs_studies.conflict_id is not null)";
  auto query = create_and_prepare_query(columns, from, clause, lock, 0);

  std::string online_status = ONLINE_STATUS;

  std::int32_t index = 1;
  bind_parameter(query, index, partition_seq, "partition_seq");
  bind_parameter(query, index, study_uid, "study_uid");
  bind_parameter(query, index, online_status, "status");

  auto result = execute_query(query);
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      Json::Value& item = output.append(Json::objectValue);
      item["patient"] = Json::Value(Json::objectValue);
      item["study"] = Json::Value(Json::objectValue);
      create_patient_and_study_item(*row, patient_flags, study_flags,
                                    for_client, false, item["patient"],
                                    item["study"]);
    }
  }
}

//------------------------------------------------------------------------------
// Create studies
//------------------------------------------------------------------------------

std::unique_ptr<onis_kit::database::database_query>
site_database::create_study_insertion_query(
    const Json::Value* conflict_study, const std::string& partition_seq,
    const std::string& patient_seq, const std::string& uid,
    const onis::core::date_time& dt, const onis::dicom_base_ptr& dataset,
    const std::string& origin_id, const std::string& origin_name,
    const std::string& origin_ip, Json::Value& study) {
  site_api_ptr api = site_api::get_instance();
  onis::dicom_manager_ptr manager = api->get_dicom_manager();
  std::string charset, date, time, accnum, study_id, desc, age, modality,
      body_part, institution, station, comment;
  onis::dicom_charset_info_list accnum_charsets, study_id_charsets,
      desc_charsets, institution_charsets, station_charsets;

  dataset->get_string_element(charset, TAG_SPECIFIC_CHARACTER_SET, "CS");
  dataset->get_string_element(date, TAG_STUDY_DATE, "DA", charset);
  dataset->get_string_element(time, TAG_STUDY_TIME, "TM", charset);
  dataset->get_string_element(accnum, TAG_ACCESSION_NUMBER, "SH", charset,
                              &accnum_charsets);
  dataset->get_string_element(study_id, TAG_STUDY_ID, "SH", charset,
                              &study_id_charsets);
  dataset->get_string_element(desc, TAG_STUDY_DESCRIPTION, "LO", charset,
                              &desc_charsets);
  dataset->get_string_element(age, TAG_PATIENT_AGE, "AS", charset);
  dataset->get_string_element(institution, TAG_INSTITUTION_NAME, "LO", charset,
                              &institution_charsets);
  dataset->get_string_element(station, TAG_STATION_NAME, "SH", charset,
                              &station_charsets);
  dataset->get_string_element(modality, TAG_MODALITY, "CS");
  dataset->get_string_element(body_part, TAG_BODY_PART_EXAMINED, "CS");
  if (institution.length() > 64)
    institution = institution.substr(0, 64);
  if (station.length() > 16)
    station = station.substr(0, 16);

  onis::core::date_time study_date;
  onis::util::datetime::check_date_and_time_validity(date, time, &study_date);

  charset = "";
  onis::dicom_charset_list done;
  for (std::int32_t i = 0; i < 5; i++) {
    onis::dicom_charset_info_list* list;
    switch (i) {
      case 0:
        list = &accnum_charsets;
        break;
      case 1:
        list = &study_id_charsets;
        break;
      case 2:
        list = &desc_charsets;
        break;
      case 3:
        list = &institution_charsets;
        break;
      case 4:
        list = &station_charsets;
        break;
      default:
        list = NULL;
        break;
    };

    onis::dicom_charset_info_list::const_iterator it1;
    for (it1 = list->begin(); it1 != list->end(); it1++) {
      const onis::dicom_charset* set =
          manager->find_character_set_by_info(*it1);
      if (set != NULL) {
        if (std::find(done.begin(), done.end(), set) == done.end()) {
          if (!charset.empty())
            charset += "\\";
          charset += set->code;
          done.push_back(set);
        }
      }
    }
  }

  return create_study_insertion_query(
      partition_seq, patient_seq, dt, charset, uid, study_id, accnum, desc,
      institution, age, date, time, modality, body_part, comment, station, 0, 0,
      origin_id, origin_name, origin_ip,
      conflict_study ? &((*conflict_study)["study"]) : NULL, study);
}

std::unique_ptr<onis_kit::database::database_query>
site_database::create_study_insertion_query(
    const std::string& partition_seq, const std::string& patient_seq,
    const onis::core::date_time& dt, const std::string& charset,
    const std::string& study_uid, const std::string& study_id,
    const std::string& accnum, const std::string& description,
    const std::string& institution, const std::string& age,
    const std::string& study_date, const std::string& study_time,
    const std::string& modalities, const std::string& bodyparts,
    const std::string& comment, const std::string& stations,
    std::int32_t series_count, std::int32_t image_count,
    const std::string& origin_id, const std::string& origin_name,
    const std::string& origin_ip, const Json::Value* conflict_study,
    Json::Value& study) {
  // Format date and time as YYYYMMDD HHMMSS using standard C++
  std::ostringstream crdate_oss;
  crdate_oss << std::setfill('0') << std::setw(4) << dt.year() << std::setw(2)
             << dt.month() << std::setw(2) << dt.day() << " " << std::setw(2)
             << dt.hour() << std::setw(2) << dt.minute() << std::setw(2)
             << dt.second();
  std::string crdate = crdate_oss.str();
  std::string sql =
      "INSERT INTO PACS_STUDIES (ID, PARTITION_ID, PATIENT_ID, UID, CHARSET, "
      "STUDYDATE, STUDYTIME, MODALITIES, BODYPARTS, ACCNUM, STUDYID, "
      "DESCRIPTION, AGE, INSTITUTION, COMMENT, STATIONS, SRCNT, IMCNT, RPTCNT, "
      "STATUS, CONFLICT_ID, CRDATE, OID, ONAME, OIP) VALUES (?, ?, ?, ?, ?, ?, "
      "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

  std::string online_status = ONLINE_STATUS;
  auto query = prepare_query(sql, "create_study_insertion_query");

  int index = 1;
  std::string seq = onis::util::uuid::generate_random_uuid();
  bind_parameter(query, index, seq, "id");
  bind_parameter(query, index, partition_seq, "partition_id");
  bind_parameter(query, index, patient_seq, "patient_id");
  bind_parameter(query, index, study_uid, "uid");
  bind_parameter(query, index, charset, "charset");
  bind_parameter(query, index, study_date, "studydate");
  bind_parameter(query, index, study_time, "studytime");
  bind_parameter(query, index, modalities, "modalities");
  bind_parameter(query, index, bodyparts, "bodyparts");
  bind_parameter(query, index, accnum, "accnum");
  bind_parameter(query, index, study_id, "studyid");
  bind_parameter(query, index, description, "description");
  bind_parameter(query, index, age, "age");
  bind_parameter(query, index, institution, "institution");
  bind_parameter(query, index, comment, "comment");
  bind_parameter(query, index, stations, "stations");
  bind_parameter(query, index, series_count, "srcnt");
  bind_parameter(query, index, image_count, "imcnt");
  bind_parameter(query, index, 0, "rptcnt");
  if (conflict_study == nullptr) {
    bind_parameter(query, index, online_status, "status");
    bind_parameter(query, index, nullptr, "conflict_id");
  } else {
    bind_parameter(query, index, seq, "status");
    bind_parameter(query, index, (*conflict_study)[BASE_SEQ_KEY].asString(),
                   "conflict_id");
  }
  bind_parameter(query, index, crdate, "crdate");
  bind_parameter(query, index, origin_id, "oid");
  bind_parameter(query, index, origin_name, "oname");
  bind_parameter(query, index, origin_ip, "oip");

  onis::database::study::create(study, onis::database::info_all, false);
  study[ST_SEQ_KEY] = seq;
  study[ST_UID_KEY] = study_uid;
  study[ST_CHARSET_KEY] = charset;
  study[ST_DATE_KEY] = study_date;
  study[ST_TIME_KEY] = study_time;
  study[ST_ACCNUM_KEY] = accnum;
  study[ST_STUDYID_KEY] = study_id;
  study[ST_DESC_KEY] = description;
  study[ST_AGE_KEY] = age;
  study[ST_MODALITIES_KEY] = modalities;
  study[ST_BODYPARTS_KEY] = bodyparts;
  study[ST_INSTITUTION_KEY] = institution;
  study[ST_STATIONS_KEY] = stations;
  study[ST_SRCNT_KEY] = series_count;
  study[ST_IMCNT_KEY] = image_count;
  study[ST_RPTCNT_KEY] = 0;
  if (conflict_study == NULL) {
    study[ST_STATUS_KEY] = ONLINE_STATUS;
    study[ST_CONFLICT_KEY] = "";
  } else {
    study[ST_STATUS_KEY] = seq;
    study[ST_CONFLICT_KEY] = (*conflict_study)[BASE_SEQ_KEY].asString();
  }
  study[ST_CRDATE_KEY] = crdate;
  study[ST_ORIGIN_ID_KEY] = origin_id;
  study[ST_ORIGIN_NAME_KEY] = origin_name;
  study[ST_ORIGIN_IP_KEY] = origin_ip;

  return query;
}

void site_database::create_study(
    const std::string& partition_seq, const Json::Value* conflict_study,
    const std::string& patient_seq, const onis::core::date_time& dt,
    const std::string& study_uid, const onis::dicom_base_ptr& dataset,
    const std::string& origin_id, const std::string& origin_name,
    const std::string& origin_ip, Json::Value& study) {
  auto query = create_study_insertion_query(
      conflict_study, partition_seq, patient_seq, study_uid, dt, dataset,
      origin_id, origin_name, origin_ip, study);
  execute_and_check_affected(query, "Failed to create patient");
}

//------------------------------------------------------------------------------
// Update studies
//------------------------------------------------------------------------------

bool site_database::update_study_modalities_bodyparts_and_station_names(
    Json::Value& study, const std::string& ignore_series_seq) {
  bool ret = false;

  // memorize the previous values:
  std::string prev_modalities = study[ST_MODALITIES_KEY].asString();
  std::string prev_body_parts = study[ST_BODYPARTS_KEY].asString();
  std::string prev_stations = study[ST_STATIONS_KEY].asString();

  // prepare the new values:
  std::vector<std::string> modalities;
  std::vector<std::string> body_parts;
  std::vector<std::string> stations;

  // retrieve all the online series of the study:
  Json::Value online_series(Json::arrayValue);
  find_online_series(study[ST_SEQ_KEY].asString(),
                     onis::database::info_series_modality |
                         onis::database::info_series_body_part |
                         onis::database::info_series_station,
                     false, onis::database::lock_mode::NO_LOCK, online_series);

  // construct the new values:
  for (const auto& series : online_series) {
    if (!ignore_series_seq.empty() &&
        series[BASE_SEQ_KEY].asString() == ignore_series_seq)
      continue;
    std::string value = series[SR_MODALITY_KEY].asString();
    if (!value.empty() && std::find(modalities.begin(), modalities.end(),
                                    value) == modalities.end())
      modalities.push_back(value);
    value = series[SR_BODYPART_KEY].asString();
    if (!value.empty() && std::find(body_parts.begin(), body_parts.end(),
                                    value) == body_parts.end())
      body_parts.push_back(value);
    value = series[SR_STATION_KEY].asString();
    if (!value.empty() &&
        std::find(stations.begin(), stations.end(), value) == stations.end())
      stations.push_back(value);
  }

  // reorder the new values:
  onis::util::string::sort(modalities, true);
  onis::util::string::sort(body_parts, true);
  onis::util::string::sort(stations, true);

  // create the new values:
  for (std::int32_t i = 0; i < 3; i++) {
    std::string key;
    std::vector<std::string>* source;
    switch (i) {
      case 1:
        key = ST_STATIONS_KEY;
        source = &stations;
        break;
      case 2:
        key = ST_BODYPARTS_KEY;
        source = &body_parts;
        break;
      default:
        key = ST_MODALITIES_KEY;
        source = &modalities;
        break;
    };

    std::string new_value;
    for (std::vector<std::string>::const_iterator it = source->begin();
         it != source->end(); it++) {
      if (it != source->begin())
        new_value += ", " + *it;
      else
        new_value = *it;
    }
    if (new_value != study[key].asString()) {
      study[key] = new_value;
      ret = true;
    }
  }
  return ret;
}

//------------------------------------------------------------------------------
// Modify studies
//------------------------------------------------------------------------------

void site_database::modify_study(const Json::Value& study,
                                 std::uint32_t flags) {
  // analyze the flags:
  if (flags == 0)
    flags = study[BASE_FLAGS_KEY].asUInt();
  else {
    std::uint32_t study_flags = study[BASE_FLAGS_KEY].asUInt();
    if ((study_flags & flags) != flags) {
      throw onis::exception(EOS_INTERNAL, "Invalid study flags");
    }
  }

  // construct the sql command:
  std::string sql = "UPDATE PACS_STUDIES SET ";
  std::string values;

  if (flags & onis::database::info_study_modalities)
    values += ", MODALITIES=?";
  if (flags & onis::database::info_study_body_parts)
    values += ", BODYPARTS=?";
  if (flags & onis::database::info_study_accnum)
    values += ", ACCNUM=?";
  if (flags & onis::database::info_study_id)
    values += ", STUDYID=?";
  if (flags & onis::database::info_study_description)
    values += ", DESCRIPTION=?";
  if (flags & onis::database::info_study_institution)
    values += ", INSTITUTION=?";
  if (flags & onis::database::info_study_comment)
    values += ", COMMENT=?";
  if (flags & onis::database::info_study_stations)
    values += ", STATIONS=?";
  if (flags & onis::database::info_study_age)
    values += ", AGE=?";
  if (flags & onis::database::info_study_date)
    values += ", STUDYDATE=?, STUDYTIME=?";
  if (flags & onis::database::info_study_statistics)
    values += ", SRCNT=?, IMCNT=?, RPTCNT=?";
  if (flags & onis::database::info_study_creation)
    values += ", CRDATE=?, OID=?, ONAME=?, OIP=?";
  if (flags & onis::database::info_study_status) {
    values += ", STATUS=?";
    if (study[ST_CONFLICT_KEY].asString().empty())
      values += ", CONFLICT_ID=NULL";
    else
      values += ", CONFLICT_ID=?";
  }
  if (!values.empty()) {
    sql += values.substr(2);
    sql += " WHERE ID=?";

    auto query = prepare_query(sql, "modify_study");
    int index = 1;
    if (flags & onis::database::info_study_modalities)
      bind_parameter(query, index, study[ST_MODALITIES_KEY].asString(),
                     "modalities");
    if (flags & onis::database::info_study_body_parts)
      bind_parameter(query, index, study[ST_BODYPARTS_KEY].asString(),
                     "bodyparts");
    if (flags & onis::database::info_study_accnum)
      bind_parameter(query, index, study[ST_ACCNUM_KEY].asString(), "accnum");
    if (flags & onis::database::info_study_id)
      bind_parameter(query, index, study[ST_STUDYID_KEY].asString(), "studyid");
    if (flags & onis::database::info_study_description)
      bind_parameter(query, index, study[ST_DESC_KEY].asString(),
                     "description");
    if (flags & onis::database::info_study_institution)
      bind_parameter(query, index, study[ST_INSTITUTION_KEY].asString(),
                     "institution");
    if (flags & onis::database::info_study_comment)
      bind_parameter(query, index, study[ST_COMMENT_KEY].asString(), "comment");
    if (flags & onis::database::info_study_stations)
      bind_parameter(query, index, study[ST_STATIONS_KEY].asString(),
                     "stations");
    if (flags & onis::database::info_study_age)
      bind_parameter(query, index, study[ST_AGE_KEY].asString(), "age");
    if (flags & onis::database::info_study_date) {
      bind_parameter(query, index, study[ST_DATE_KEY].asString(), "studydate");
      bind_parameter(query, index, study[ST_TIME_KEY].asString(), "studytime");
    }
    if (flags & onis::database::info_study_statistics) {
      bind_parameter(query, index, study[ST_SRCNT_KEY].asInt(), "series_count");
      bind_parameter(query, index, study[ST_IMCNT_KEY].asInt(), "image_count");
      bind_parameter(query, index, study[ST_RPTCNT_KEY].asInt(),
                     "report_count");
    }
    if (flags & onis::database::info_study_creation) {
      bind_parameter(query, index, study[ST_CRDATE_KEY].asString(), "crdate");
      bind_parameter(query, index, study[ST_ORIGIN_ID_KEY].asString(),
                     "origin_id");
      bind_parameter(query, index, study[ST_ORIGIN_NAME_KEY].asString(),
                     "origin_name");
      bind_parameter(query, index, study[ST_ORIGIN_IP_KEY].asString(),
                     "origin_ip");
    }
    if (flags & onis::database::info_study_status) {
      bind_parameter(query, index, study[ST_STATUS_KEY].asString(), "status");
      if (study[ST_CONFLICT_KEY].asString().empty())
        bind_parameter(query, index, nullptr, "conflict_id");
      else
        bind_parameter(query, index, study[ST_CONFLICT_KEY].asString(),
                       "conflict_id");
    }
    bind_parameter(query, index, study[BASE_SEQ_KEY].asString(), "id");
    execute_and_check_affected(query, "Study not found");
  }
}

/*void create_study_item_from_album(onis::odb_record& rec, std::uint32_t
flags, bool for_client, Json::Value& study, std::int32_t* start_index,
onis::aresult& res); void create_study_item(onis::odb_record& rec,
std::uint32_t flags, bool for_client, onis::astring* patient_seq, Json::Value&
study, std::int32_t* start_index, onis::aresult& res); void
create_patient_and_study_item(onis::odb_record& rec, std::uint32_t
patient_flags, std::uint32_t study_flags, bool for_client, bool for_album,
Json::Value& patient, Json::Value& study, onis::aresult& res);  void
get_online_and_conflicted_studies( const onis::astring& partition_seq, const
onis::astring& conflict_study_seq, std::uint32_t patient_flags, std::uint32_t
study_flags, std::int32_t for_client_online, std::int32_t for_client_conflict,
std::int32_t lock_mode, Json::Value& online_study, Json::Value&
conflict_study, onis::aresult& res); bool study_has_conflicted_studies(const
onis::astring& online_study_seq, onis::aresult& res);  void create_study(
const onis::astring& partition_seq, const onis::astring& patient_seq, const
onis::core::date_time& dt, const onis::astring& charset, const onis::astring&
study_uid, const onis::astring& study_id, const onis::astring& accnum, const
onis::astring& description, const onis::astring& institution, const
onis::astring& study_date, const onis::astring& study_time, std::int32_t
series_count, std::int32_t image_count, const onis::astring& origin_id, const
onis::astring& origin_name, const onis::astring& origin_ip, Json::Value&
study, onis::aresult& res);

 void modify_study_uid(const onis::astring& seq, const onis::astring& uid,
                      onis::aresult& res);
onis::astring construct_study_filter_clause(const Json::Value& filters,
                                            bool with_patient,
                                            bool& have_criteria);
onis::astring prepare_for_like(const onis::astring& value);
bool compose_filter_clause(const Json::Value& filters,
                          const onis::astring& key,
                          const onis::astring& column,
                          onis::astring& filter_clause);
bool compose_filter_clause(const Json::Value& filters,
                          const onis::astring& key,
                          const onis::astring& column,
                          const onis::astring& separator,
                          onis::astring& filter_clause);
bool compose_name_filter_clause(const Json::Value& filters,
                               const onis::astring& key,
                               const onis::astring& column1,
                               const onis::astring& column2,
                               const onis::astring& column3,
                               onis::astring& filter_clause);
bool compose_date_range_filter_clause(const Json::Value& filters,
                                     const onis::astring& key1,
                                     const onis::astring& key2,
                                     const onis::astring& column,
                                     onis::astring& filter_clause);
void delete_study(const onis::astring& study_seq, onis::aresult& res);
void switch_study_conflict_status(const onis::astring& online_study_seq,
                                  const onis::astring& conflict_study_seq,
                                  onis::aresult& res);
std::uint64_t get_study_count(const onis::astring& patient_seq, onis::aresult&
res); void set_studies_patient_seq(const onis::astring from_patient_seq, const
onis::astring& new_patient_seq, onis::aresult& res); void
attach_study_to_patient(const onis::astring& study_seq, const onis::astring&
patient_seq, onis::aresult& res); void
remove_studies_not_satisfying_the_modalities_bodyparts_and_station_filters(
    std::int32_t offset, Json::Value& output, bool have_patient,
    const Json::Value& filters, onis::aresult& res);

// study links:
void find_partition_study_link_by_seq(const onis::astring& study_link_seq,
                                      std::int32_t lock_mode, Json::Value&
output, onis::aresult& res); void add_partition_study_link(const
onis::astring& patient_link_seq, const onis::astring& study_seq, bool
all_series, const onis::astring& modalities, const onis::astring& bodyparts,
const onis::astring& stations, std::int32_t series_count, std::int32_t
image_count, std::int32_t report_count, Json::Value& output, onis::aresult&
res); bool get_partition_study_link(const onis::astring& patient_link_seq,
const onis::astring& study_seq, std::int32_t lock_mode, Json::Value& output,
onis::aresult& res); bool get_partition_study_link_from_study_seq_in_album(
const onis::astring& album_seq, const onis::astring& study_seq, std::int32_t
lock_mode, Json::Value& output, onis::aresult& res); bool
get_partition_study_from_link(const onis::astring& study_link_seq,
std::uint32_t flags, std::int32_t lock_mode, Json::Value& output,
onis::astring* study_patient_seq, onis::aresult& res); void
get_partition_studies_from_patient_link( const onis::astring&
patient_link_seq, bool reject_empty_request, const Json::Value& filters,
std::uint32_t flags, bool for_client, std::int32_t lock_mode, Json::Value&
output, onis::aresult& res); void get_partition_study_links(const
onis::astring& study_seq, std::int32_t lock_mode, Json::Value& output,
onis::aresult& res); void get_partition_study_links_from_patient_link( const
onis::astring& patient_link_seq, std::int32_t lock_mode, Json::Value& output,
onis::aresult& res); void create_partition_study_link_item(onis::odb_record&
rec, Json::Value& link, onis::aresult& res); void
update_partition_study_link(const Json::Value& link, onis::aresult& res); bool
update_partition_study_link_modalities_bodyparts_and_stations( Json::Value&
link, Json::Value* add_series /*, const Json::Value &remove_series*//*,
    onis::aresult& res);
void get_series_from_study_link(const onis::astring& study_link,
                                Json::Value& output, std::uint32_t flags,
                                onis::aresult& res);
void remove_partition_study_links(const onis::astring& study_seq,
                                  sdb_access_elements_info* info,
                                  onis::aresult& res);
std::uint64_t count_series_links_related_with_study_link(
    const onis::astring study_link_seq, onis::aresult& res);*/

//------------------------------------------------------------------------------
// Study filter clause
//------------------------------------------------------------------------------

std::string site_database::construct_study_filter_clause(
    const Json::Value& filters, bool with_patient, bool& have_criteria) {
  bool study_root = true;
  std::string filter_clause;
  have_criteria = false;
  if (with_patient) {
    have_criteria |= compose_filter_clause(filters, "pid", "PACS_PATIENTS.PID",
                                           filter_clause);
    have_criteria |= compose_name_filter_clause(
        filters, "name", "PACS_PATIENTS.NAME", "PACS_PATIENTS.IDEOGRAM",
        "PACS_PATIENTS.PHONETIC", filter_clause);
    have_criteria |= compose_filter_clause(filters, "sex", "PACS_PATIENTS.SEX",
                                           filter_clause);
  }
  have_criteria |= compose_filter_clause(filters, "accnum",
                                         "PACS_STUDIES.ACCNUM", filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "institution", "PACS_STUDIES.INSTITUTION", filter_clause);
  have_criteria |= compose_filter_clause(filters, "comment",
                                         "PACS_STUDIES.COMMENT", filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "desc", "PACS_STUDIES.DESCRIPTION", filter_clause);
  have_criteria |= compose_filter_clause(filters, "studyid",
                                         "PACS_STUDIES.STUDYID", filter_clause);
  have_criteria |= compose_date_range_filter_clause(
      filters, "startStudyDate", "endStudyDate", "PACS_STUDIES.STUDYDATE",
      filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "modalities", "PACS_STUDIES.MODALITIES", "|", filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "parts", "PACS_STUDIES.BODYPARTS", "|", filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "stations", "PACS_STUDIES.STATIONS", "|", filter_clause);

  // status filter:
  std::int32_t status = -2;
  if (filters.isMember("status") && filters["status"].isMember("value"))
    status = filters["status"]["value"].asInt();

  if (!study_root)
    return filter_clause;  // nothing to do

  auto online_patients =
      " AND PACS_PATIENTS.STATUS='" + std::string(ONLINE_STATUS) + "'";
  auto online_studies =
      " AND PACS_STUDIES.STATUS='" + std::string(ONLINE_STATUS) + "'";

  if (with_patient) {
    if (status == -1) {
      filter_clause += online_patients;
    } else if (status == 1 || status == 2) {
      filter_clause += online_patients +
                       " AND PACS_STUDIES.STATUS=PACS_STUDIES.ID AND "
                       "PACS_STUDIES.CONFLICT_ID IS " +
                       (status == 1 ? "NULL" : "NOT NULL");
      have_criteria = true;
    } else {
      filter_clause += online_patients + online_studies;
    }
  } else {
    if (status == 1 || status == 2) {
      filter_clause +=
          " AND PACS_STUDIES.STATUS=PACS_STUDIES.ID AND "
          "PACS_STUDIES.CONFLICT_ID IS " +
          std::string(status == 1 ? "NULL" : "NOT NULL");
      have_criteria = true;
    } else if (status != -1) {
      filter_clause += online_studies;
    }
    // if status == -1, do nothing
  }
  return filter_clause;
}

bool site_database::compose_filter_clause(const Json::Value& filters,
                                          const std::string& key,
                                          const std::string& column,
                                          std::string& filter_clause) {
  bool have_filter = false;
  if (filters.isMember(key) && filters[key].isMember("value") &&
      filters[key]["value"].isString()) {
    std::string value = filters[key]["value"].asString();
    if (!value.empty()) {
      filter_clause += " AND " + column;
      std::int32_t match_type =
          filters[key].isMember("type") && filters[key]["type"].isInt()
              ? filters[key]["type"].asInt()
              : 0;
      switch (match_type) {
        case 0:  // perfect match
          have_filter = true;
          filter_clause += "=?";
          break;
        case 1:  // like
          have_filter = true;
          filter_clause += " LIKE ?";
          break;
        case 2:  // use wildcards
          value = prepare_for_like(value);
          if (!value.empty()) {
            have_filter = true;
            filter_clause += " LIKE ?";
          }
          break;
        default:  // perfect match
          have_filter = true;
          filter_clause += "=?";
          break;
      };
    }
  }
  return have_filter;
}

bool site_database::compose_filter_clause(const Json::Value& filters,
                                          const std::string& key,
                                          const std::string& column,
                                          const std::string& separator,
                                          std::string& filter_clause) {
  bool have_filter = false;
  if (filters.isMember(key) && filters[key].isMember("value") &&
      filters[key]["value"].isString()) {
    std::string value = filters[key]["value"].asString();
    if (!value.empty()) {
      std::int32_t match_type = 0;  // perfect match
      if (filters[key].isMember("type"))
        match_type = filters[key]["type"].asInt();
      std::vector<std::string> list;
      if (separator.empty())
        list.push_back(value);
      else
        onis::util::string::split(value, list, separator);

      std::string total;
      std::int32_t elements = 0;
      for (auto& item : list) {
        if (item.empty())
          continue;
        if (!total.empty())
          total += " OR ";
        switch (match_type) {
          case 0:  // perfect match
            have_filter = true;
            total += column + "=?";
            break;
          case 1:  // like
            have_filter = true;
            total += column + " LIKE ?";
            break;
          case 2:  // wildcards
            item = prepare_for_like(item);
            if (!item.empty()) {
              have_filter = true;
              filter_clause += " LIKE ?";
            }
            break;
          default:
            have_filter = true;
            total += column + "=?";
            break;
        };
        elements++;
      }
      if (elements == 1)
        filter_clause += " AND " + total;
      else if (elements > 1)
        filter_clause += " AND (" + total + ")";
    }
  }
  return have_filter;
}

bool site_database::compose_date_range_filter_clause(
    const Json::Value& filters, const std::string& key1,
    const std::string& key2, const std::string& column,
    std::string& filter_clause) {
  bool have_filter = false;

  std::string from;
  if (filters.isMember(key1) && filters[key1].isMember("value") &&
      filters[key1]["value"].isString()) {
    from = filters[key1]["value"].asString();
  }
  std::string to;
  if (filters.isMember(key2) && filters[key2].isMember("value") &&
      filters[key2]["value"].isString()) {
    to = filters[key2]["value"].asString();
  }
  if (from.length() == 10 && to.length() == 10) {
    have_filter = true;
    if (from == to)
      filter_clause += " AND " + column + "=?";
    else
      filter_clause += " AND " + column + ">=? AND " + column + "<=?";
  } else if (from.length() == 10) {
    have_filter = true;
    filter_clause += " AND " + column + ">=?";
  } else if (to.length() == 10) {
    have_filter = true;
    filter_clause += " AND " + column + "<=?";
  }
  return have_filter;
}

bool site_database::compose_name_filter_clause(const Json::Value& filters,
                                               const std::string& key,
                                               const std::string& column1,
                                               const std::string& column2,
                                               const std::string& column3,
                                               std::string& filter_clause) {
  if (!filters.isMember(key) || !filters[key].isMember("value") ||
      !filters[key]["value"].isString()) {
    return false;
  }

  std::string value = filters[key]["value"].asString();
  if (value.empty()) {
    return false;
  }

  std::int32_t match_type =
      filters[key].isMember("type") && filters[key]["type"].isInt()
          ? filters[key]["type"].asInt()
          : 0;

  // Perfect match case
  if (match_type != 1 && match_type != 2) {
    filter_clause +=
        " AND (" + column1 + "=? OR " + column2 + "=? OR " + column3 + "=?)";
    return true;
  }

  // LIKE or wildcards case
  std::vector<std::string> words;
  onis::util::string::split(value, words, " ");

  // Build LIKE clauses for each column
  std::array<std::string, 3> column_clauses;
  std::array<const std::string*, 3> columns = {&column1, &column2, &column3};

  for (std::size_t i = 0; i < 3; ++i) {
    std::vector<std::string> column_parts;
    for (auto& word : words) {
      if (match_type == 2) {
        word = prepare_for_like(word);
      }
      if (!word.empty()) {
        column_parts.push_back(*columns[i] + " LIKE ?");
      }
    }
    if (!column_parts.empty()) {
      column_clauses[i] = column_parts[0];
      for (std::size_t j = 1; j < column_parts.size(); ++j) {
        column_clauses[i] += " AND " + column_parts[j];
      }
    }
  }

  // Collect non-empty column clauses
  std::vector<std::string> active_clauses;
  for (const auto& clause : column_clauses) {
    if (!clause.empty()) {
      active_clauses.push_back(clause);
    }
  }

  if (active_clauses.empty()) {
    return false;
  }

  // Build final clause: wrap multi-word clauses in parentheses, join with OR
  filter_clause += " AND (";
  bool first = true;
  for (const auto& clause : active_clauses) {
    if (!first) {
      filter_clause += " OR ";
    }
    // Check if clause needs parentheses (contains AND)
    if (clause.find(" AND ") != std::string::npos) {
      filter_clause += "(" + clause + ")";
    } else {
      filter_clause += clause;
    }
    first = false;
  }
  filter_clause += ")";

  return true;
}

std::string site_database::prepare_for_like(const std::string& value) {
  if (value.empty())
    return {};

  // Find first and last non-'*' character
  auto first = value.find_first_not_of('*');
  auto last = value.find_last_not_of('*');
  if (first == std::string::npos)  // string is all '*'
    return "%";

  std::string res;
  if (first != 0)
    res += '%';
  res += value.substr(first, last - first + 1);
  if (last != value.length() - 1)
    res += '%';

  // Replace '?' with '_'
  for (auto& ch : res)
    if (ch == '?')
      ch = '_';

  return res;
}

void site_database::bind_parameters_for_study_filter_clause(
    std::unique_ptr<onis_kit::database::database_query>& query,
    std::int32_t& index, const Json::Value& filters, bool with_patient) {
  if (with_patient) {
    bind_parameter_for_study_filter_clause(query, index, filters, "pid");
    /*have_criteria |= compose_name_filter_clause(
        filters, "name", "PACS_PATIENTS.NAME", "PACS_PATIENTS.IDEOGRAM",
        "PACS_PATIENTS.PHONETIC", filter_clause);
    have_criteria |= compose_filter_clause(filters, "sex", "PACS_PATIENTS.SEX",
                                           filter_clause);*/
  }

  /*have_criteria |= compose_filter_clause(filters, "accnum",
                                         "PACS_STUDIES.ACCNUM", filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "institution", "PACS_STUDIES.INSTITUTION", filter_clause);
  have_criteria |= compose_filter_clause(filters, "comment",
                                         "PACS_STUDIES.COMMENT", filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "desc", "PACS_STUDIES.DESCRIPTION", filter_clause);
  have_criteria |= compose_filter_clause(filters, "studyid",
                                         "PACS_STUDIES.STUDYID", filter_clause);
  have_criteria |= compose_date_range_filter_clause(
      filters, "startStudyDate", "endStudyDate", "PACS_STUDIES.STUDYDATE",
      filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "modalities", "PACS_STUDIES.MODALITIES", "|", filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "parts", "PACS_STUDIES.BODYPARTS", "|", filter_clause);
  have_criteria |= compose_filter_clause(
      filters, "stations", "PACS_STUDIES.STATIONS", "|", filter_clause);*/
}

void site_database::bind_parameter_for_study_filter_clause(
    std::unique_ptr<onis_kit::database::database_query>& query,
    std::int32_t& index, const Json::Value& filters, const std::string& key) {
  if (filters.isMember(key) && filters[key].isMember("value") &&
      filters[key]["value"].isString()) {
    std::string value = filters[key]["value"].asString();
    if (!value.empty()) {
      std::int32_t match_type =
          filters[key].isMember("type") && filters[key]["type"].isInt()
              ? filters[key]["type"].asInt()
              : 0;
      switch (match_type) {
        case 0:  // perfect match
          bind_parameter(query, index, value, key);
          break;
        case 1:  // like
          bind_parameter(query, index, "%" + value + "%", key);
          break;
        case 2:  // use wildcards
          value = prepare_for_like(value);
          if (!value.empty()) {
            bind_parameter(query, index, value, key);
          }
          break;
        default:  // perfect match
          bind_parameter(query, index, value, key);
          break;
      };
    }
  }
}
