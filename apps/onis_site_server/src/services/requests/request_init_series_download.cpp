#include "../../../include/database/items/db_image.hpp"
#include "../../../include/database/items/db_media.hpp"
#include "../../../include/database/items/db_series.hpp"
#include "../../../include/database/items/db_source.hpp"
#include "../../../include/services/requests/request_data.hpp"
#include "../../../include/services/requests/request_entity_access_info.hpp"
#include "../../../include/services/requests/request_service.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/utilities/filesystem.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

////////////////////////////////////////////////////////////////////////////////
// process_init_series_download_request
////////////////////////////////////////////////////////////////////////////////

void request_service::process_init_series_download_request(
    const request_data_ptr& req) {
  // Verify input parameters:
  onis::database::item::verify_string_value(req->input_json, "source", false,
                                            false);
  onis::database::item::verify_integer_value(req->input_json, "type", false);
  onis::database::item::verify_array_value(req->input_json, "data", false);

  std::string source_id = req->input_json["source"].asString();
  std::int32_t type = req->input_json["type"].asInt();
  const Json::Value& data = req->input_json["data"];

  for (const auto& item : data) {
    onis::database::item::verify_string_value(item, "patient_id", false, false);
    onis::database::item::verify_string_value(item, "study_uid", false, false);
    onis::database::item::verify_string_value(item, "series_uid", false, false);
    onis::database::item::verify_string_value(item, "guid", false, false);
    if (type != onis::database::source::type_dicom_client) {
      onis::database::item::verify_string_value(item, "patient_seq", false,
                                                false);
      onis::database::item::verify_string_value(item, "study_seq", false,
                                                false);
      onis::database::item::verify_string_value(item, "series_seq", false,
                                                false);
    }
  }

  // treat each series one by one:
  for (const auto& item : data) {
    std::string patient_seq = item["patient_seq"].asString();
    std::string patient_id = item["patient_id"].asString();
    std::string study_seq = item["study_seq"].asString();
    std::string study_uid = item["study_uid"].asString();
    std::string series_seq = item["series_seq"].asString();
    std::string series_uid = item["series_uid"].asString();
    std::string guid = item["guid"].asString();

    req->write_output(
        [&](json& output, std::vector<std::uint8_t>& binary_output) {
          Json::Value& item = output["data"].append(Json::objectValue);
          item["source"] = source_id;
          item["patient_id"] = patient_id;
          item["study_uid"] = study_uid;
          item["series_uid"] = series_uid;
          item["guid"] = guid;
          item["status"] = EOS_NONE;
          if (type != onis::database::source::type_dicom_client) {
            item["patient_seq"] = patient_seq;
            item["study_seq"] = study_seq;
            item["series_seq"] = series_seq;
          }
        });

    request_database db(this);
    db->begin_transaction();
    try {
      Json::Value images(Json::arrayValue);
      Json::Value partition(Json::objectValue);
      verify_partition_access_permission(db, req->session, source_id,
                                         &partition,
                                         onis::database::info_partition_volume,
                                         onis::database::lock_mode::NO_LOCK);
      std::string volume_seq = partition[PT_VOLUME_KEY].asString();
      site_database_entity_access_info info(source_id, "", patient_seq,
                                            patient_id, study_seq, study_uid,
                                            series_seq, series_uid, "", "");
      info.find(db, onis::database::lock_mode::NO_LOCK, 0, 0,
                onis::database::info_series_properties, 0);
      db->find_images(series_seq, onis::database::info_all, false,
                      onis::database::lock_mode::NO_LOCK, images);
      if (images.size() == 0) {
        throw onis::exception(EOS_NO_IMAGE, "No image found for series");
      }

      // record the download process in the database:
      onis::core::date_time current_time;
      current_time.init_current_time();
      Json::Value download_series(Json::objectValue);
      db->create_download_series(
          series_seq, /*req->session->session_id*/ "fdsafsdfasf", current_time,
          0, EOS_NONE, static_cast<std::int32_t>(images.size()),
          download_series);
      std::string seq = download_series[BASE_SEQ_KEY].asString();

      std::string full_path;
      for (Json::ArrayIndex i = 0; i < images.size(); i++) {
        full_path.clear();
        std::int32_t media = -1;
        std::int32_t type = -1;
        std::string relative_path = images[i][IM_STREAM_PATH_KEY].asString();
        if (!relative_path.empty()) {
          media = images[i][IM_STREAM_MEDIA_KEY].asInt();
          type = 2;
        } else {
          type = 1;
          relative_path = images[i][IM_IMAGE_PATH_KEY].asString();
          media = images[i][IM_IMAGE_MEDIA_KEY].asInt();
        }
        if (!relative_path.empty()) {
          full_path = get_media_folder(onis::database::media_for_images,
                                       volume_seq, media, db);
          if (!full_path.empty())
            onis::util::filesystem::concat(full_path, relative_path);
        }
        Json::Value download_image(Json::objectValue);
        db->create_download_image(download_series[BASE_SEQ_KEY].asString(), i,
                                  full_path, type, type == 2 ? 6 : 1, EOS_NONE,
                                  download_image);
      }
      db->commit();

      req->write_output(
          [&](json& output, std::vector<std::uint8_t>& binary_output) {
            Json::Value& item = output["data"][output["data"].size() - 1];
            item["seq"] = seq;
            item["image_count"] = images.size();
          });

    } catch (const onis::exception& e) {
      req->write_output(
          [&](json& output, std::vector<std::uint8_t>& binary_output) {
            Json::Value& item = output["data"][output["data"].size() - 1];
            item["status"] = e.get_code();
          });
      db->rollback();
      throw e;
    } catch (...) {
      req->write_output(
          [&](json& output, std::vector<std::uint8_t>& binary_output) {
            Json::Value& item = output["data"][output["data"].size() - 1];
            item["status"] = EOS_INTERNAL;
          });
      db->rollback();
      throw;
    }
  }
}