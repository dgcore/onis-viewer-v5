// #include "../../../include/database/items/db_role.hpp"
#include "../../../include/database/items/db_source.hpp"
#include "../../../include/database/site_database.hpp"
#include "../../../include/services/requests/find_request_data.hpp"
#include "../../../include/services/requests/request_exceptions.hpp"
#include "../../../include/services/requests/request_service.hpp"

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
          request_database db(this);
          Json::Value filters(Json::objectValue);
          Json::Value& studies = source_output["studies"];
          db->find_studies(source.seq, source.reject_empty_request,
                           source.limit, filters, onis::database::info_all,
                           onis::database::info_all, true,
                           onis::database::lock_mode::NO_LOCK, studies);
          source_output["status"] = 0;
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