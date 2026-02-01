// #include "../../../include/database/items/db_role.hpp"
#include <cstdlib>
#include <ctime>
#include <random>
#include <string>
#include <vector>
#include "../../../include/database/items/db_patient.hpp"
#include "../../../include/database/items/db_source.hpp"
#include "../../../include/database/items/db_study.hpp"
#include "../../../include/database/site_database.hpp"
#include "../../../include/services/requests/find_request_data.hpp"
#include "../../../include/services/requests/request_exceptions.hpp"
#include "../../../include/services/requests/request_service.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

////////////////////////////////////////////////////////////////////////////////
// Helper function to generate random test data
////////////////////////////////////////////////////////////////////////////////

namespace {
// Check if test mode is enabled via environment variable
bool is_test_mode_enabled() {
  // const char* test_mode = std::getenv("ONIS_TEST_MODE");
  // return test_mode != nullptr && std::string(test_mode) == "1";
  return true;
}

// Get test data count from environment variable (default: 1000)
int get_test_data_count() {
  const char* count_str = std::getenv("ONIS_TEST_DATA_COUNT");
  if (count_str != nullptr) {
    try {
      int count = std::stoi(count_str);
      return count > 0 ? count : 1000;
    } catch (...) {
      return 1000;
    }
  }
  return 1000;
}

// Generate random string
std::string random_string(size_t length) {
  const std::string chars =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dis(0, chars.size() - 1);
  std::string result;
  result.reserve(length);
  for (size_t i = 0; i < length; ++i) {
    result += chars[dis(gen)];
  }
  return result;
}

// Generate random number in range
int random_int(int min, int max) {
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dis(min, max);
  return dis(gen);
}

// Generate random date in YYYYMMDD format
std::string random_date() {
  int year = random_int(1950, 2024);
  int month = random_int(1, 12);
  int day = random_int(1, 28);  // Use 28 to avoid month/day issues
  char buffer[9];
  std::snprintf(buffer, sizeof(buffer), "%04d%02d%02d", year, month, day);
  return std::string(buffer);
}

// Generate random time in HHMMSS format
std::string random_time() {
  int hour = random_int(0, 23);
  int minute = random_int(0, 59);
  int second = random_int(0, 59);
  char buffer[7];
  std::snprintf(buffer, sizeof(buffer), "%02d%02d%02d", hour, minute, second);
  return std::string(buffer);
}

// Generate random patient/study data
void generate_test_data(Json::Value& studies, int count,
                        const std::string& source_seq) {
  const std::vector<std::string> first_names = {
      "John",        "Jane",     "Robert", "Mary",  "Michael", "Patricia",
      "William",     "Jennifer", "David",  "Linda", "Richard", "Elizabeth",
      "Joseph",      "Barbara",  "Thomas", "Susan", "Charles", "Jessica",
      "Christopher", "Sarah",    "Daniel", "Karen", "Matthew", "Nancy"};
  const std::vector<std::string> last_names = {
      "Smith",  "Johnson",  "Williams",  "Brown",    "Jones",     "Garcia",
      "Miller", "Davis",    "Rodriguez", "Martinez", "Hernandez", "Lopez",
      "Wilson", "Anderson", "Thomas",    "Taylor"};
  const std::vector<std::string> modalities = {"CT", "MR", "US", "CR",
                                               "DX", "MG", "PT", "NM"};
  const std::vector<std::string> body_parts = {"HEAD",   "CHEST",     "ABDOMEN",
                                               "PELVIS", "EXTREMITY", "SPINE"};
  const std::vector<std::string> sexes = {"M", "F", "O"};

  for (int i = 0; i < count; ++i) {
    Json::Value item(Json::objectValue);
    Json::Value& patient = item["patient"] = Json::Value(Json::objectValue);
    Json::Value& study = item["study"] = Json::Value(Json::objectValue);

    // Patient data
    patient[BASE_SEQ_KEY] = onis::util::uuid::generate_random_uuid();
    patient[BASE_VERSION_KEY] = "1.0.0";
    patient[BASE_FLAGS_KEY] = onis::database::info_all;
    patient[BASE_UID_KEY] = "PATIENT_" + random_string(10);
    patient[PA_CHARSET_KEY] = "ISO_IR 192";
    patient[PA_NAME_KEY] = first_names[random_int(0, first_names.size() - 1)] +
                           " " +
                           last_names[random_int(0, last_names.size() - 1)];
    patient[PA_IDEOGRAM_KEY] = "";
    patient[PA_PHONETIC_KEY] = "";
    patient[PA_SEX_KEY] = sexes[random_int(0, sexes.size() - 1)];
    patient[PA_BDATE_KEY] = random_date();
    patient[PA_BTIME_KEY] = "";
    patient[PA_STCNT_KEY] = random_int(1, 10);
    patient[PA_SRCNT_KEY] = random_int(5, 50);
    patient[PA_IMCNT_KEY] = random_int(50, 500);
    patient[PA_STATUS_KEY] = 0;
    patient[PA_CRDATE_KEY] = "";
    patient[PA_ORIGIN_ID_KEY] = "";
    patient[PA_ORIGIN_NAME_KEY] = "";
    patient[PA_ORIGIN_IP_KEY] = "";

    // Study data
    study[BASE_SEQ_KEY] = onis::util::uuid::generate_random_uuid();
    study[BASE_VERSION_KEY] = "1.0.0";
    study[BASE_FLAGS_KEY] = onis::database::info_all;
    study[BASE_UID_KEY] = "STUDY_" + random_string(10);
    study[ST_CHARSET_KEY] = "ISO_IR 192";
    study[ST_DATE_KEY] = random_date();
    study[ST_TIME_KEY] = random_time();
    study[ST_MODALITIES_KEY] = modalities[random_int(0, modalities.size() - 1)];
    study[ST_BODYPARTS_KEY] = body_parts[random_int(0, body_parts.size() - 1)];
    study[ST_ACCNUM_KEY] = "ACC" + random_string(8);
    study[ST_STUDYID_KEY] = "STU" + random_string(8);
    study[ST_DESC_KEY] = "Study Description " + std::to_string(i + 1);
    study[ST_AGE_KEY] = std::to_string(random_int(18, 90)) + "Y";
    study[ST_INSTITUTION_KEY] =
        "Test Hospital " + std::to_string(random_int(1, 5));
    study[ST_COMMENT_KEY] = "Test comment " + std::to_string(i + 1);
    study[ST_STATIONS_KEY] = "STATION" + std::to_string(random_int(1, 10));
    study[ST_SRCNT_KEY] = random_int(1, 20);
    study[ST_IMCNT_KEY] = random_int(10, 200);
    study[ST_RPTCNT_KEY] = random_int(0, 5);
    study[ST_STATUS_KEY] = 0;
    study[ST_CONFLICT_KEY] = "";
    study[ST_CRDATE_KEY] = "";
    study[ST_ORIGIN_ID_KEY] = "";
    study[ST_ORIGIN_NAME_KEY] = "";
    study[ST_ORIGIN_IP_KEY] = "";

    studies.append(item);
  }
}
}  // namespace

////////////////////////////////////////////////////////////////////////////////
// request_service_authenticate
////////////////////////////////////////////////////////////////////////////////

void request_service::process_find_studies_request(
    [[maybe_unused]] const request_data_ptr& req) {
  find_request_data_ptr find_req =
      std::static_pointer_cast<find_request_data>(req);

  // Verify input parameters:
  onis::database::item::verify_string_value(req->input_json, "source", true,
                                            false);
  onis::database::item::verify_integer_value(req->input_json, SO_TYPE_KEY,
                                             false);
  onis::database::item::verify_integer_value(req->input_json, "limit", true);

  // Build target sources:
  std::string source_id = req->input_json["source"].asString();
  std::int32_t type = req->input_json[SO_TYPE_KEY].asInt();
  bool search_partitions = false;
  bool search_dicoms = false;
  if (type == onis::database::source::type_site) {
    search_partitions = true;
    search_dicoms = true;
  } else if (type == onis::database::source::type_partitions)
    search_partitions = true;
  else if (type == onis::database::source::type_dicom_clients)
    search_dicoms = true;

  if (search_partitions || search_dicoms) {
  } else if (type == onis::database::source::type_partition) {
    find_source source;
    source.seq = "ab827b22-a4b9-44a4-96d8-28c6d2a29884";  // source_id;
    source.type = type;
    source.have_conflict = false;
    source.reject_empty_request = false;
    source.limit = 500;
    source.name = "tralala";
    find_req->sources.emplace_back(source);
  }

  // prepare output:
  req->write_output([&](json& output) {
    output["sources"] = Json::Value(Json::objectValue);
  });

  // Search studies:
  for (const auto& source : find_req->sources) {
    if (source.type == onis::database::source::type_partition) {
      req->write_output([&](json& output) {
        Json::Value& source_output = output["sources"][source.seq] =
            Json::Value(Json::objectValue);
        source_output["conflict"] = source.have_conflict;
        source_output["studies"] = Json::Value(Json::arrayValue);
        try {
          Json::Value& studies = source_output["studies"];

          // Check if test mode is enabled
          if (is_test_mode_enabled()) {
            // Generate random test data
            int test_count = get_test_data_count();
            // Respect the limit if specified
            int actual_count = (source.limit > 0 && source.limit < test_count)
                                   ? source.limit
                                   : test_count;
            generate_test_data(studies, actual_count, source.seq);
            source_output["status"] = 0;
          } else {
            // Use real database
            request_database db(this);
            Json::Value filters(Json::objectValue);
            db->find_studies(source.seq, source.reject_empty_request,
                             source.limit, filters, onis::database::info_all,
                             onis::database::info_all, true,
                             onis::database::lock_mode::NO_LOCK, studies);
            source_output["status"] = 0;
          }
        } catch (request_exception& e) {
          source_output["status"] = e.get_code();
        } catch (const std::exception& e) {
          source_output["status"] = EOS_UNKNOWN;
          source_output["error"] = e.what();
        } catch (...) {
          source_output["status"] = EOS_UNKNOWN;
          source_output["error"] = "Unknown error";
        }
      });
    }
  }

  // Send response:
}