#include <iomanip>
#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_patient.hpp"
#include "../../include/database/site_database.hpp"
#include "../../include/site_api.hpp"
#include "onis_kit/include/utilities/date_time.hpp"
#include "onis_kit/include/utilities/dicom.hpp"
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
  patient[BASE_UID_KEY] = rec.get_string(*target_index, false, false);
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

//------------------------------------------------------------------------------
// Create patients
//------------------------------------------------------------------------------

std::unique_ptr<onis_kit::database::database_query>
site_database::create_patient_insertion_query(
    const std::string& partition_seq, const onis::core::date_time& dt,
    const std::string& charset, const std::string& pid, const std::string& name,
    const std::string& ideogram, const std::string& phonetic,
    const std::string& birthdate, const std::string birthtime,
    const std::string& sex, std::int32_t study_count, std::int32_t series_count,
    std::int32_t image_count, const std::string& origin_id,
    const std::string& origin_name, const std::string& origin_ip,
    Json::Value& patient) {
  // Format date and time as YYYYMMDD HHMMSS using standard C++
  std::ostringstream crdate_oss;
  crdate_oss << std::setfill('0') << std::setw(4) << dt.year() << std::setw(2)
             << dt.month() << std::setw(2) << dt.day() << " " << std::setw(2)
             << dt.hour() << std::setw(2) << dt.minute() << std::setw(2)
             << dt.second();
  std::string crdate = crdate_oss.str();
  std::string sql =
      "INSERT INTO PACS_PATIENTS (ID, PARTITION_ID, PID, NAME, IDEOGRAM, "
      "PHONETIC, CHARSET, BIRTHDATE, BIRTHTIME, SEX, STCNT, SRCNT, IMCNT, "
      "STATUS, CRDATE, OID, ONAME, OIP) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, "
      "?, ?, ?, ?, ?, ?, ?, ?)";

  auto query = prepare_query(sql, "create_patient_insertion_query");

  int index = 1;
  std::string seq = onis::util::uuid::generate_random_uuid();
  bind_parameter(query, index, seq, "id");
  bind_parameter(query, index, partition_seq, "partition_id");
  bind_parameter(query, index, pid, "pid");
  bind_parameter(query, index, name, "name");
  bind_parameter(query, index, ideogram, "ideogram");
  bind_parameter(query, index, phonetic, "phonetic");
  bind_parameter(query, index, charset, "charset");
  bind_parameter(query, index, birthdate, "birthdate");
  bind_parameter(query, index, birthtime, "birthtime");
  bind_parameter(query, index, sex, "sex");
  bind_parameter(query, index, study_count, "study_count");
  bind_parameter(query, index, series_count, "series_count");
  bind_parameter(query, index, image_count, "image_count");
  bind_parameter(query, index, ONLINE_STATUS, "status");
  bind_parameter(query, index, crdate, "crdate");
  bind_parameter(query, index, origin_id, "origin_id");
  bind_parameter(query, index, origin_name, "origin_name");
  bind_parameter(query, index, origin_ip, "origin_ip");

  onis::database::patient::create(patient, onis::database::info_all, false);
  patient[BASE_SEQ_KEY] = seq;
  patient[BASE_UID_KEY] = pid;
  patient[PA_CHARSET_KEY] = charset;
  patient[PA_NAME_KEY] = name;
  patient[PA_IDEOGRAM_KEY] = ideogram;
  patient[PA_PHONETIC_KEY] = phonetic;
  patient[PA_SEX_KEY] = sex;
  patient[PA_BDATE_KEY] = birthdate;
  patient[PA_BTIME_KEY] = birthtime;
  patient[PA_STCNT_KEY] = study_count;
  patient[PA_SRCNT_KEY] = series_count;
  patient[PA_IMCNT_KEY] = image_count;
  patient[PA_STATUS_KEY] = ONLINE_STATUS;
  patient[PA_CRDATE_KEY] = crdate;
  patient[PA_ORIGIN_ID_KEY] = origin_id;
  patient[PA_ORIGIN_NAME_KEY] = origin_name;
  patient[PA_ORIGIN_IP_KEY] = origin_ip;

  return query;
}

std::unique_ptr<onis_kit::database::database_query>
site_database::create_patient_insertion_query(
    const std::string& partition_seq, const onis::core::date_time& dt,
    const std::string& default_pid, const onis::dicom_base_ptr& dataset,
    const std::string& origin_id, const std::string& origin_name,
    const std::string& origin_ip, Json::Value& patient) {
  site_api_ptr api = site_api::get_instance();
  onis::dicom_manager_ptr manager = api->get_dicom_manager();
  std::string sql, convert;
  std::string charset, name, ideo, phono, bdate, btime, sex;
  onis::dicom_charset_info_list id_charsets, name_charsets;
  get_patient_info_to_insert(dataset, &charset, &name, &ideo, &phono, &bdate,
                             &btime, &sex, &name_charsets);
  std::string patient_id;
  dataset->get_string_element(patient_id, TAG_PATIENT_ID, "LO", charset,
                              &id_charsets);

  // Set the default patient id if empty:
  if (patient_id.empty())
    patient_id = default_pid;

  charset = "";
  onis::dicom_charset_list done;
  for (std::int32_t i = 0; i < 2; i++) {
    onis::dicom_charset_info_list* list;
    switch (i) {
      case 0:
        list = &id_charsets;
        break;
      case 1:
        list = &name_charsets;
        break;
      default:
        list = NULL;
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
  return create_patient_insertion_query(
      partition_seq, dt, charset, patient_id, name, ideo, phono, bdate, btime,
      sex, 0, 0, 0, origin_id, origin_name, origin_ip, patient);
}

void site_database::create_patient(
    const std::string& partition_seq, const onis::core::date_time& dt,
    const std::string& default_pid, const onis::dicom_base_ptr& dataset,
    const std::string& origin_id, const std::string& origin_name,
    const std::string& origin_ip, Json::Value& patient) {
  auto query = create_patient_insertion_query(partition_seq, dt, default_pid,
                                              dataset, origin_id, origin_name,
                                              origin_ip, patient);
  execute_and_check_affected(query, "Failed to create patient");
}

void site_database::get_patient_info_to_insert(
    const onis::dicom_base_ptr& dataset, std::string* charset,
    std::string* name, std::string* ideo, std::string* phono,
    std::string* birthdate, std::string* birthtime, std::string* sex,
    onis::dicom_charset_info_list* used_charsets) {
  std::string full_name;
  dataset->get_string_element(*charset, TAG_SPECIFIC_CHARACTER_SET, "CS");
  dataset->get_string_element(full_name, TAG_PATIENT_NAME, "PN", *charset,
                              used_charsets);
  dataset->get_string_element(*sex, TAG_PATIENT_SEX, "CS", *charset);
  dataset->get_string_element(*birthdate, TAG_PATIENT_BIRTH_DATE, "DA",
                              *charset);
  dataset->get_string_element(*birthtime, TAG_PATIENT_BIRTH_TIME, "TM",
                              *charset);
  onis::util::dicom::decode_person_name(full_name, *name, *ideo, *phono, true);
  onis::core::date_time date;
  onis::util::datetime::check_date_and_time_validity(*birthdate, *birthtime,
                                                     &date);
}

//------------------------------------------------------------------------------
// Modify patients
//------------------------------------------------------------------------------

void site_database::modify_patient(const Json::Value& patient,
                                   std::uint32_t flags) {
  // analyze the flags:
  if (flags == 0)
    flags = patient[BASE_FLAGS_KEY].asUInt();
  else {
    std::uint32_t patient_flags = patient[BASE_FLAGS_KEY].asUInt();
    if ((patient_flags & flags) != flags) {
      throw onis::exception(EOS_INTERNAL, "Invalid flags");
    }
  }

  // construct the sql command:
  std::string sql = "UPDATE PACS_PATIENTS SET ";
  std::string values;
  if (flags & onis::database::info_patient_name)
    values += ", NAME=?, IDEOGRAM=?, PHONETIC=?, CHARSET=?";
  if (flags & onis::database::info_patient_birthdate)
    values += ", BIRTHDATE=?, BIRTHTIME=?";
  if (flags & onis::database::info_patient_sex)
    values += ", SEX=?";
  if (flags & onis::database::info_patient_statistics)
    values += ", STCNT=?, SRCNT=?, IMCNT=?";
  if (flags & onis::database::info_patient_creation)
    values += ", CRDATE=?, OID=?, ONAME=?, OIP=?";
  if (flags & onis::database::info_patient_status)
    values += ", STATUS=?";
  if (!values.empty()) {
    sql += values.substr(2) + " WHERE ID=?";

    // execute the sql command:
    auto query = prepare_query(sql, "modify_patient");
    int index = 1;
    if (flags & onis::database::info_patient_name) {
      bind_parameter(query, index, patient[PA_NAME_KEY].asString(), "name");
      bind_parameter(query, index, patient[PA_IDEOGRAM_KEY].asString(),
                     "ideogram");
      bind_parameter(query, index, patient[PA_PHONETIC_KEY].asString(),
                     "phonetic");
      bind_parameter(query, index, patient[PA_CHARSET_KEY].asString(),
                     "charset");
    }
    if (flags & onis::database::info_patient_birthdate) {
      bind_parameter(query, index, patient[PA_BDATE_KEY].asString(),
                     "birthdate");
      bind_parameter(query, index, patient[PA_BTIME_KEY].asString(),
                     "birthtime");
    }
    if (flags & onis::database::info_patient_sex)
      bind_parameter(query, index, patient[PA_SEX_KEY].asString(), "sex");
    if (flags & onis::database::info_patient_statistics) {
      bind_parameter(query, index, patient[PA_STCNT_KEY].asInt(),
                     "study_count");
      bind_parameter(query, index, patient[PA_SRCNT_KEY].asInt(),
                     "series_count");
      bind_parameter(query, index, patient[PA_IMCNT_KEY].asInt(),
                     "image_count");
    }
    if (flags & onis::database::info_patient_creation) {
      bind_parameter(query, index, patient[PA_CRDATE_KEY].asString(), "crdate");
      bind_parameter(query, index, patient[PA_ORIGIN_ID_KEY].asString(),
                     "origin_id");
      bind_parameter(query, index, patient[PA_ORIGIN_NAME_KEY].asString(),
                     "origin_name");
      bind_parameter(query, index, patient[PA_ORIGIN_IP_KEY].asString(),
                     "origin_ip");
    }
    if (flags & onis::database::info_patient_status)
      bind_parameter(query, index, patient[PA_STATUS_KEY].asString(), "status");
    bind_parameter(query, index, patient[BASE_SEQ_KEY].asString(), "id");
    execute_and_check_affected(query, "Patient not found");
  }
}

/*void create_patient(
const std::string& partition_seq, const onis::core::date_time& dt,
const onis::astring& charset, const onis::astring& pid,
const onis::astring& name, const onis::astring& ideogram,
const onis::astring& phonetic, const onis::astring& birthdate,
const onis::astring birthtime, const onis::astring& sex, std::int32_t
study_count, std::int32_t series_count, std::int32_t image_count, const
onis::astring& origin_id, const onis::astring& origin_name, const
onis::astring& origin_ip, Json::Value& patient, onis::aresult& res); void
site_database::modify_patient_id(const std::string& seq, const std::string&
pid) {} void site_database::delete_patient(const std::string& patient_seq) {}
bool site_database::patient_have_studies(const std::string& patient_seq) {}
bool site_database::some_studies_are_in_conflict_with_some_patient_study(
    const std::string& patient_seq) {}
bool site_database::patient_have_studies_in_conflict(
    const std::string& patient_seq) {}*/