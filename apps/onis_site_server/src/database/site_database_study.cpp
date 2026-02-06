#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_study.hpp"
#include "../../include/database/site_database.hpp"
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
    study[ST_COMMENT_KEY] = rec.get_string(*target_index, true, false);
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
  std::string filter_clause;  // =
                              // construct_study_filter_clause(filters, true,
                              // have_criteria);
  if (reject_empty_request && !have_criteria)
    return;

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

  if (!query->bind_parameter(1, partition_seq)) {
    std::throw_with_nested(
        std::runtime_error("Failed to bind partition_id parameter"));
  }

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
/*void create_study_item_from_album(onis::odb_record& rec, std::uint32_t flags,
                                  bool for_client, Json::Value& study,
                                  std::int32_t* start_index, onis::aresult&
res); void create_study_item(onis::odb_record& rec, std::uint32_t flags, bool
for_client, onis::astring* patient_seq, Json::Value& study, std::int32_t*
start_index, onis::aresult& res); void
create_patient_and_study_item(onis::odb_record& rec, std::uint32_t
patient_flags, std::uint32_t study_flags, bool for_client, bool for_album,
Json::Value& patient, Json::Value& study, onis::aresult& res); void
find_online_and_conflicted_studies(const onis::astring& partition_seq, const
onis::astring& study_uid, std::int32_t lockmode, std::uint32_t patient_flags,
                                        std::uint32_t study_flags, bool
for_client, Json::Value& output, onis::aresult& res); void
get_online_and_conflicted_studies( const onis::astring& partition_seq, const
onis::astring& conflict_study_seq, std::uint32_t patient_flags, std::uint32_t
study_flags, std::int32_t for_client_online, std::int32_t for_client_conflict,
std::int32_t lock_mode, Json::Value& online_study, Json::Value& conflict_study,
onis::aresult& res); bool study_has_conflicted_studies(const onis::astring&
online_study_seq, onis::aresult& res); void create_study( const onis::astring&
partition_seq, const Json::Value* conflict_study, const onis::astring&
patient_seq, const onis::core::date_time& dt, const onis::astring& study_uid,
const onis::dicom_base_ptr& dataset, const onis::astring& origin_id, const
onis::astring& origin_name, const onis::astring& origin_ip, Json::Value& study,
onis::aresult& res); void create_study( const onis::astring& partition_seq,
const onis::astring& patient_seq, const onis::core::date_time& dt, const
onis::astring& charset, const onis::astring& study_uid, const onis::astring&
study_id, const onis::astring& accnum, const onis::astring& description, const
onis::astring& institution, const onis::astring& study_date, const
onis::astring& study_time, std::int32_t series_count, std::int32_t image_count,
    const onis::astring& origin_id, const onis::astring& origin_name,
    const onis::astring& origin_ip, Json::Value& study, onis::aresult& res);
onis::astring create_study_insertion_string(
    const Json::Value* conflict_study, const onis::astring& partition_seq,
    const onis::astring& patient_seq, const onis::astring& uid,
    const onis::core::date_time& dt, const onis::dicom_base_ptr& dataset,
    const onis::astring& origin_id, const onis::astring& origin_name,
    const onis::astring& origin_ip, Json::Value& study);
onis::astring create_study_insertion_string(
    const onis::astring& partition_seq, const onis::astring& patient_seq,
    const onis::core::date_time& dt, const onis::astring& charset,
    const onis::astring& study_uid, const onis::astring& study_id,
    const onis::astring& accnum, const onis::astring& description,
    const onis::astring& institution, const onis::astring& age,
    const onis::astring& study_date, const onis::astring& study_time,
    const onis::astring& modalities, const onis::astring& bodyparts,
    const onis::astring& stations, std::int32_t series_count, std::int32_t
image_count, const onis::astring& origin_id, const onis::astring& origin_name,
    const onis::astring& origin_ip, const Json::Value* conflict_study,
    Json::Value& study);
bool update_study_modalities_bodyparts_and_station_names(
    Json::Value& study, const onis::astring& ignore_series_seq,
    onis::aresult& res);
void modify_study(const Json::Value& study, std::uint32_t flags, onis::aresult&
res); void modify_study_uid(const onis::astring& seq, const onis::astring& uid,
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
output, onis::aresult& res); void add_partition_study_link(const onis::astring&
patient_link_seq, const onis::astring& study_seq, bool all_series, const
onis::astring& modalities, const onis::astring& bodyparts, const onis::astring&
stations, std::int32_t series_count, std::int32_t image_count, std::int32_t
report_count, Json::Value& output, onis::aresult& res); bool
get_partition_study_link(const onis::astring& patient_link_seq, const
onis::astring& study_seq, std::int32_t lock_mode, Json::Value& output,
onis::aresult& res); bool get_partition_study_link_from_study_seq_in_album(
const onis::astring& album_seq, const onis::astring& study_seq, std::int32_t
lock_mode, Json::Value& output, onis::aresult& res); bool
get_partition_study_from_link(const onis::astring& study_link_seq, std::uint32_t
flags, std::int32_t lock_mode, Json::Value& output, onis::astring*
study_patient_seq, onis::aresult& res); void
get_partition_studies_from_patient_link( const onis::astring& patient_link_seq,
bool reject_empty_request, const Json::Value& filters, std::uint32_t flags, bool
for_client, std::int32_t lock_mode, Json::Value& output, onis::aresult& res);
void get_partition_study_links(const onis::astring& study_seq, std::int32_t
lock_mode, Json::Value& output, onis::aresult& res); void
get_partition_study_links_from_patient_link( const onis::astring&
patient_link_seq, std::int32_t lock_mode, Json::Value& output, onis::aresult&
res); void create_partition_study_link_item(onis::odb_record& rec, Json::Value&
link, onis::aresult& res); void update_partition_study_link(const Json::Value&
link, onis::aresult& res); bool
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