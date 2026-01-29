#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_patient.hpp"
#include "../../include/database/site_database.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Patient operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_patient_columns(std::uint32_t flags,
                                               bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_patients." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "partition_id, " + prefix + "pid, " +
           prefix + "name, " + prefix + "ideogram, " + prefix + "phonetic, " +
           prefix + "charset, " + prefix + "birthdate, " + prefix +
           "birthtime, " + prefix + "sex, " + prefix + "stcnt, " + prefix +
           "srcnt, " + prefix + "imcnt, " + prefix + "status, " + prefix +
           "crdate, " + prefix + "oid, " + prefix + "oname, " + prefix + "oip";
  }

  std::string columns =
      prefix + "id, " + prefix + "partition_id, " + prefix + "pid";
  if (flags & onis::database::info_patient_name) {
    columns += ", " + prefix + "name";
  }
  if (flags & onis::database::info_patient_charset) {
    columns += ", " + prefix + "charset";
  }
  if (flags & onis::database::info_patient_birthdate) {
    columns += ", " + prefix + "birthdate, " + prefix + "birthtime";
  }
  if (flags & onis::database::info_patient_sex) {
    columns += ", " + prefix + "sex";
  }
  if (flags & onis::database::info_patient_statistics) {
    columns +=
        ", " + prefix + "stcnt, " + prefix + "srcnt, " + prefix + "imcnt";
  }
  if (flags & onis::database::info_patient_status) {
    columns += ", " + prefix + "status";
  }
  if (flags & onis::database::info_patient_creation) {
    columns += ", " + prefix + "crdate, " + prefix + "oid, " + prefix +
               "oname, " + prefix + "oip";
  }
  return columns;
}

void site_database::create_patient_item(onis_kit::database::database_row& rec,
                                        std::uint32_t flags, bool for_client,
                                        std::string* partition_seq,
                                        Json::Value& patient,
                                        std::int32_t* start_index) {
  onis::database::patient::create(patient, flags, for_client);
  std::int32_t index = 0;
  std::int32_t* target_index = start_index ? start_index : &index;
  patient[BASE_SEQ_KEY] = rec.get_uuid(*target_index, false, false);
  if (partition_seq) {
    *partition_seq = rec.get_uuid(*target_index, false, false);
  } else {
    (*target_index)++;
  }
  if (partition_seq) {
    *partition_seq = rec.get_uuid("partition_id", false, false);
  }
  if (flags & onis::database::info_patient_name) {
    patient[PA_NAME_KEY] = rec.get_string(*target_index, true, true);
    patient[PA_IDEOGRAM_KEY] = rec.get_string(*target_index, true, true);
    patient[PA_PHONETIC_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_patient_charset) {
    patient[PA_CHARSET_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_patient_birthdate) {
    patient[PA_BDATE_KEY] = rec.get_string(*target_index, true, true);
    patient[PA_BTIME_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_patient_sex) {
    patient[PA_SEX_KEY] = rec.get_string(*target_index, true, true);
  }
  if (flags & onis::database::info_patient_statistics) {
    patient[PA_STCNT_KEY] = rec.get_int(*target_index, false);
    patient[PA_SRCNT_KEY] = rec.get_int(*target_index, false);
    patient[PA_IMCNT_KEY] = rec.get_int(*target_index, false);
  }
  if (flags & onis::database::info_patient_status) {
    auto status = rec.get_uuid(*target_index, false, false);
    if (for_client)
      patient[PA_STATUS_KEY] = status == ONLINE_STATUS ? 0 : 1;
    else
      patient[PA_STATUS_KEY] = status;
  }
  if (flags & onis::database::info_patient_creation) {
    patient[PA_CRDATE_KEY] = rec.get_string(*target_index, false, false);
    patient[PA_ORIGIN_ID_KEY] = rec.get_string(*target_index, true, true);
    patient[PA_ORIGIN_NAME_KEY] = rec.get_string(*target_index, true, true);
    patient[PA_ORIGIN_IP_KEY] = rec.get_string(*target_index, true, true);
  }
}

//------------------------------------------------------------------------------
// Find patients
//------------------------------------------------------------------------------

void site_database::find_online_patients(const std::string& partition_seq,
                                         const std::string& patient_id,
                                         std::uint32_t flags, bool for_client,
                                         lock_mode lock,
                                         Json::Value& patients) {
  auto columns = get_patient_columns(flags, false);
  auto where =
      "partition_id = ? AND pid = ? AND status = "
      "'00000000-0000-4000-0000-000000000000'";
  auto query = create_and_prepare_query(columns, "pacs_patients", where, lock);

  if (!query->bind_parameter(1, partition_seq)) {
    std::throw_with_nested(
        std::runtime_error("Failed to bind partition_id parameter"));
  }
  if (!query->bind_parameter(2, patient_id)) {
    std::throw_with_nested(std::runtime_error("Failed to bind pid parameter"));
  }

  auto result = execute_query(query);
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      Json::Value& item = patients.append(Json::objectValue);
      create_patient_item(*row, flags, for_client, nullptr, item, nullptr);
    }
  }
}

bool site_database::have_online_patient(
    const std::string& partition_seq, const std::string& patient_id,
    const std::string& name, const std::string& ideogram,
    const std::string& phonetic, const std::string& sex,
    const std::string& birthdate, const std::string& birthtime) {
  // prepare the sql command:
  std::string sql =
      "SELECT COUNT(ID) AS RESULT FROM PACS_PATIENTS WHERE PARTITION_ID=? AND "
      "PID=? AND NAME=? AND IDEOGRAM=? AND PHONETIC=? AND SEX=? AND "
      "BIRTHDATE=? AND BIRTHTIME=? AND STATUS=?";

  auto query = prepare_query(sql, "have_online_patient");
  int index = 1;
  bind_parameter(query, index, partition_seq, "partition_seq");
  bind_parameter(query, index, patient_id, "patient_id");
  bind_parameter(query, index, name, "name");
  bind_parameter(query, index, ideogram, "ideogram");
  bind_parameter(query, index, phonetic, "phonetic");
  bind_parameter(query, index, sex, "sex");
  bind_parameter(query, index, birthdate, "birthdate");
  bind_parameter(query, index, birthtime, "birthtime");
  bind_parameter(query, index, ONLINE_STATUS, "status");

  auto result = execute_query(query);
  if (result->has_rows()) {
    auto row = result->get_next_row();
    return row->get_int("result", false) > 0;
  }
  return false;
}

void site_database::find_patient_by_seq(const std::string& seq,
                                        std::uint32_t flags, bool for_client,
                                        lock_mode lock, Json::Value& output,
                                        std::string* partition_seq) {
  // Create and prepare query:
  std::string columns = get_patient_columns(flags, false);
  std::string where = "id = ?";
  auto query = create_and_prepare_query(columns, "pacs_patients", where, lock);

  // Bind the seq parameter
  if (!query->bind_parameter(1, seq)) {
    std::throw_with_nested(std::runtime_error("Failed to bind idparameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    auto row = result->get_next_row();
    if (row) {
      create_patient_item(*row, flags, for_client, partition_seq, output,
                          nullptr);
      return;
    }
  }
  throw std::runtime_error("Patient not found");
}

/*void site_database::get_patient_info_to_insert(
    const onis::dicom_base_ptr& dataset, std::string* charset,
    std::string* name, std::string* ideo, std::string* phono,
    std::string* birthdate, std::string* birthtime, std::string* sex,
    onis::dicom_charset_info_list* used_charsets = NULL) {}*/

/*void create_patient(
const std::string& partition_seq, const onis::core::date_time& dt,
const onis::astring& charset, const onis::astring& pid,
const onis::astring& name, const onis::astring& ideogram,
const onis::astring& phonetic, const onis::astring& birthdate,
const onis::astring birthtime, const onis::astring& sex, s32 study_count,
s32 series_count, s32 image_count, const onis::astring& origin_id,
const onis::astring& origin_name, const onis::astring& origin_ip,
Json::Value& patient, onis::aresult& res);
onis::astring create_patient_insertion_string(
const onis::astring& partition_seq, const onis::core::date_time& dt,
const onis::astring& default_pid, const onis::dicom_base_ptr& dataset,
const onis::astring& origin_id, const onis::astring& origin_name,
const onis::astring& origin_ip, Json::Value& patient);
onis::astring create_patient_insertion_string(
const onis::astring& partition_seq, const onis::core::date_time& dt,
const onis::astring& charset, const onis::astring& pid,
const onis::astring& name, const onis::astring& ideogram,
const onis::astring& phonetic, const onis::astring& birthdate,
const onis::astring birthtime, const onis::astring& sex, s32 study_count,
s32 series_count, s32 image_count, const onis::astring& origin_id,
const onis::astring& origin_name, const onis::astring& origin_ip,
Json::Value& patient);
void site_database::modify_patient(const Json::Value& patient,
                                   std::uint32_t flags) {}
void site_database::modify_patient_id(const std::string& seq,
                                      const std::string& pid) {}
void site_database::delete_patient(const std::string& patient_seq) {}
bool site_database::patient_have_studies(const std::string& patient_seq) {}
bool site_database::some_studies_are_in_conflict_with_some_patient_study(
    const std::string& patient_seq) {}
bool site_database::patient_have_studies_in_conflict(
    const std::string& patient_seq) {}*/