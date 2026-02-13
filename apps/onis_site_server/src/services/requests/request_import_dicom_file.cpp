#include <cstdlib>
#include <ctime>
#include <random>
#include <string>
#include <vector>
#include "../../../include/database/items/db_media.hpp"
#include "../../../include/database/items/db_patient.hpp"
#include "../../../include/database/items/db_source.hpp"
#include "../../../include/database/items/db_study.hpp"
#include "../../../include/database/site_database.hpp"
#include "../../../include/services/requests/find_request_data.hpp"
#include "../../../include/services/requests/request_exceptions.hpp"
#include "../../../include/services/requests/request_service.hpp"
#include "../../../include/services/requests/store/local_store_request.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

void request_service::process_import_dicom_file_request(
    const request_data_ptr& req) {
  // Verify input parameters:
  onis::database::item::verify_string_value(req->input_json, "source", false,
                                            false);
  // onis::database::item::verify_integer_value(req->input_json, "type", false);
  onis::database::item::verify_string_value(req->input_json, "dicom_file_path",
                                            false, false);

  request_database db(this);
  std::string source_id = req->input_json["source"].asString();
  Json::Value partition(Json::objectValue);
  verify_partition_access_permission(
      db, req->session, source_id, &partition,
      onis::database::info_partition_volume |
          onis::database::info_partition_parameters,
      onis::database::lock_mode::NO_LOCK);

  std::string partition_name = partition.isMember(PT_NAME_KEY)
                                   ? partition[PT_NAME_KEY].asString()
                                   : source_id;

  // get the storage media:
  std::int32_t media = -1;
  std::string folder =
      get_current_media_folder(onis::database::media_for_images,
                               partition[PT_VOLUME_KEY].asString(), &media, db);

  // start a transaction:
  db->begin_transaction();

  try {
    // import the dicom file into the partition:
    std::string dicom_file_path = req->input_json["dicom_file_path"].asString();
    req->write_output([&](Json::Value& output) {
      std::uint32_t flags[4] = {0, onis::database::info_study_status, 0, 0};
      local_store_request store(shared_from_this());
      /*store.set_origin(req->session->user_seq,
                       "Imported by " + req->session->login,
                       req->log_info->get_client_ip());*/
      store.import_file_to_partition(
          db, source_id, partition[PT_PARAM_KEY].asString(), media, folder,
          dicom_file_path, true, &output, flags);
    });
  } catch (const onis::exception& e) {
    db->rollback();
    throw e;
  } catch (const std::exception& e) {
    db->rollback();
    throw;
  } catch (...) {
    db->rollback();
    throw;
  }

  // must clean up after the commit:
  // store.cleanup(req->res);
}
