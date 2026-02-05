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

void request_service::process_import_dicom_file_request(
    const request_data_ptr& req) {
  // Verify input parameters:
  onis::database::item::verify_string_value(req->input_json, "source", false,
                                            false);
  onis::database::item::verify_integer_value(req->input_json, "type", false);
  onis::database::item::verify_string_value(req->input_json, "dicom_file_path",
                                            false, false);

  request_database db(this);

  /*Json::Value partition(Json::objectValue);
  verify_partition_access_permission(
      db, req->session, source_id, &partition,
      onis::server::info_partition_volume |
          onis::server::info_partition_parameters,
      onis::db::nolock, req->res);
  onis::astring partition_name = partition.isMember(PT_NAME_KEY)
                                     ? partition[PT_NAME_KEY].asString()
                                     : source_id;
  logger->write_event(req->log_info, onis::log::error,
                      "Target partition: '" + partition_name + "'");

  if (req->res.good()) {
    // get the storage media:
    s32 media = -1;
    onis::string folder = get_current_media_folder(
        onis::server::media_for_images,
        req->res.status == OSRSP_SUCCESS ? partition[PT_VOLUME_KEY].asString()
                                         : "",
        &media, db, req->res);

    // start a transaction:
    db->begin_transactionA(req->res);

    // import the dicom file into the partition:
    local_store_request store(shared_from_this(), req->log_info);
    store.init(partition[PT_PARAM_KEY].asString(), import_data->image_path1,
               media, folder, req->res);
    store.set_origin(req->session->user_seq,
                     "Imported by " + req->session->login,
                     req->log_info->get_client_ip());
    u32 flags[4] = {0, onis::server::info_study_status, 0, 0};
    store.import_file(db, req->input["source"].asString(), &req->output, flags,
                      req->res);

    // commit or rollback the transaction:
    db->commit_or_rollback_transactionA(req->res);

    // must clean up after the commit:
    store.cleanup(req->res);
  }*/

  /*import_request_info_ptr import_data =
      std::static_pointer_cast<import_request_info>(req->data);


  // verify the input:
  onis::server::item::verify_string_value(req->input, "source", (b32)OSFALSE,
                                          req->res);
  onis::server::item::verify_string_value(req->input, "type", (b32)OSFALSE,
                                          req->res);
  // onis::server::item::verify_int_or_uint_value(req->input, SO_TYPE_KEY,
  // req->res);
  onis::server::item::verify_string_value(req->input, "image", (b32)OSFALSE,
                                          req->res);
  onis::astring from_path = req->input["image"].asString();
  // onis::util::string::convert_utf8_to_local(req->input["image"].asString(),
  // from_path);
  _prepare_file(from_path, &import_data->image_path1, NULL,
                &import_data->delete_image_file, req->res);
  if (req->res.status == OSRSP_SUCCESS) {
    // s32 type = req->input[SO_TYPE_KEY].asInt();
    onis::astring stype = req->input[SO_TYPE_KEY].asString();
    s32 type = onis::util::string::convert_to_s32(stype);
    if (type != onis::server::source::type_partition &&
        type != onis::server::source::type_dicom_client)
      req->res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);
  }*/
}
