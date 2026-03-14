#include "../../../include/services/requests/request_service.hpp"
#include <filesystem>
#include <iostream>
#include <vector>
#include "../../../include/database/items/db_media.hpp"
#include "../../../include/exceptions/site_server_exceptions.hpp"
#include "../../../include/services/requests/sessions/request_session.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/database/postgresql/postgresql_connection.hpp"

////////////////////////////////////////////////////////////////////////////////
// request_service class
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// static constructor
//------------------------------------------------------------------------------

request_service_ptr request_service::create() {
  request_service_ptr ret = std::make_shared<request_service>();
  return ret;
}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

request_service::request_service() : session_timeout_(std::chrono::hours(1)) {
  // Initialize database pool with default max size of 10
  database_pool_ = std::make_unique<site_database_pool>(10);

  // Set up connection factory for PostgreSQL
  database_pool_->set_connection_factory(
      []() -> std::unique_ptr<onis_kit::database::database_connection> {
        auto pg_connection =
            std::make_unique<onis_kit::database::postgresql_connection>();

        // Create database configuration
        onis_kit::database::database_config config;
        config.host = "localhost";
        config.port = 5432;
        config.database_name = "onis_site_db";
        config.username = "postgres";
        config.password = "your_password_here";
        config.use_ssl = false;

        // Connect using the configuration
        pg_connection->connect(config);
        return pg_connection;
      });
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

request_service::~request_service() {}

//------------------------------------------------------------------------------
// database pool access
//------------------------------------------------------------------------------

std::shared_ptr<site_database> request_service::get_database_connection() {
  return database_pool_->get_connection();
}

void request_service::return_database_connection(
    std::shared_ptr<site_database> connection) {
  database_pool_->return_connection(connection);
}

//------------------------------------------------------------------------------
// sessions
//------------------------------------------------------------------------------

void request_service::register_session(const request_session_ptr& session) {
  std::lock_guard<std::mutex> lock(sessions_mutex_);
  // Check if the session already exists:
  if (sessions_.find(session->session_id) != sessions_.end()) {
    throw std::runtime_error("Session already exists");
  }
  // Register the session:
  sessions_[session->session_id] = session;
  session->first_access = std::chrono::system_clock::now();
  session->last_access = std::chrono::system_clock::now();
}

void request_service::unregister_session(const std::string& session_id) {
  std::lock_guard<std::mutex> lock(sessions_mutex_);
  if (sessions_.find(session_id) != sessions_.end()) {
    sessions_.erase(session_id);
  }
}

request_session_ptr request_service::find_session(
    const std::string& session_id) const {
  std::lock_guard<std::mutex> lock(sessions_mutex_);
  auto it = sessions_.find(session_id);
  if (it != sessions_.end()) {
    return it->second;
  }
  throw std::runtime_error("Session not found");
}

void request_service::cleanup_sessions() {
  std::lock_guard<std::mutex> lock(sessions_mutex_);
  auto it = sessions_.begin();
  while (it != sessions_.end()) {
    if (is_session_expired(it->second, false)) {
      it = sessions_.erase(it);
    } else {
      ++it;
    }
  }
}

bool request_service::is_session_expired(const request_session_ptr& session,
                                         bool update_last_access) {
  if (!session) {
    return true;  // Null session is considered expired
  }
  auto now = std::chrono::system_clock::now();
  auto time_since_last_access =
      std::chrono::duration_cast<std::chrono::seconds>(now -
                                                       session->last_access);
  // Check if session has expired (timeout exceeded or negative time difference)
  bool expired = (time_since_last_access < std::chrono::seconds::zero() ||
                  time_since_last_access > session_timeout_);
  // Update last_access if requested and session is not expired
  if (update_last_access && !expired) {
    session->last_access = now;
  }
  return expired;
}

//------------------------------------------------------------------------------
// process request
//------------------------------------------------------------------------------

void request_service::process_request(const request_data_ptr& req) {
  try {
    switch (req->get_type()) {
      case request_type::kAuthenticate:
        process_authenticate_request(req);
        break;
      case request_type::kFindStudies:
        process_find_studies_request(req);
        break;
      case request_type::kImportDicom:
        process_import_dicom_file_request(req);
        break;
      case request_type::kInitSeriesDownload:
        process_init_series_download_request(req);
        break;
      case request_type::kDownloadImages:
        process_download_images_request(req);
        break;
      default:
        break;
    }
  } catch (const onis::exception& e) {
    req->write_output(
        [&](json& output, std::vector<std::uint8_t>& binary_output) {
          output.clear();
          output["status"] = e.get_code();
          output["message"] = e.what();
          std::string error_message = e.what();
          std::cout << "Error: " << error_message << std::endl;
        });
  } catch (const std::exception& e) {
    req->write_output(
        [&](json& output, std::vector<std::uint8_t>& binary_output) {
          output.clear();
          output["status"] = EOS_UNKNOWN;
          output["message"] = e.what();
        });
  } catch (...) {
    req->write_output(
        [&](json& output, std::vector<std::uint8_t>& binary_output) {
          output.clear();
          output["status"] = EOS_UNKNOWN;
          output["message"] = "Unknown error";
        });
  }
}

//------------------------------------------------------------------------------
// permissions
//------------------------------------------------------------------------------

void request_service::verify_partition_access_permission(
    const request_database& db, const request_session_ptr& session,
    const std::string& partition_seq, Json::Value* output, std::uint32_t flags,
    onis::database::lock_mode lock) {
  Json::Value tmp = Json::Value(Json::objectValue);
  Json::Value* target = output ? output : &tmp;
  std::uint32_t part_flags = output
                                 ? flags | onis::database::info_partition_status
                                 : onis::database::info_partition_status;
  try {
    db->find_partition_by_seq(
        /*session->site_id*/ "22a4f7af-e2e9-4e0e-ae3d-3e648713497c",
        partition_seq, part_flags, 0, 0, lock, *target);
    if ((*target)[PT_STATUS_KEY].asInt() != 1)
      throw onis::exception(EOS_NOT_AVAILABLE, "Partition not available");
  } catch (const onis::exception& e) {
    if (e.get_code() == EOS_PERMISSION) {
      throw site_server_exception(EOS_PERMISSION, "Permission denied");
    } else {
      throw;
    }
  }
}

//-------------------------------------------------------
// media
//-------------------------------------------------------

void request_service::check_media() {
  std::lock_guard<std::recursive_mutex> lock(_media_mutex);
  std::vector<std::string> keys_to_erase;
  for (auto& [volume_seq, media_info] : _media) {
    const auto& root = media_info->folder;
    auto space = std::filesystem::space(root);
    bool remove = true;
    if (space.capacity > 0) {
      float tmp = static_cast<float>(space.available) /
                  static_cast<float>(space.capacity);
      if ((1.0f - tmp) * 100.0f <= media_info->ratio)
        remove = false;
    }
    if (remove) {
      keys_to_erase.push_back(volume_seq);
    }
  }
  for (const auto& key : keys_to_erase) {
    _media.erase(key);
  }
}

std::string request_service::get_current_media_folder(
    std::int32_t target, const std::string& volume_seq, std::int32_t* media,
    const request_database& db) {
  std::string folder;
  if (target == onis::database::media_for_images) {
    if (!volume_seq.empty()) {
      std::lock_guard<std::recursive_mutex> lock(_media_mutex);
      if (_media.find(volume_seq) != _media.end()) {
        media_info_ptr info = _media[volume_seq];
        if (info != NULL) {
          *media = info->num;
          folder = info->folder;
        }
      } else {
        Json::Value media_list(Json::arrayValue);
        db->get_volume_media_list(volume_seq, onis::database::info_all,
                                  onis::database::lock_mode::NO_LOCK,
                                  media_list);
        for (const auto& item : media_list) {
          if (item[ME_STATUS_KEY].asInt() == onis::database::media_available) {
            *media = item[ME_NUM_KEY].asInt();
            folder = item[ME_PATH_KEY].asString();
            _media[volume_seq] = media_info::create(
                *media, folder, item[ME_RATIO_KEY].asFloat());
            break;
          }
        }
      }
    }
  }
  return folder;
}

std::string request_service::get_media_folder(std::int32_t target,
                                              const std::string& volume_seq,
                                              std::int32_t media,
                                              const request_database& db) {
  std::string folder;
  if (target == onis::database::media_for_images) {
    if (!volume_seq.empty()) {
      std::lock_guard<std::recursive_mutex> lock(_media_mutex);
      if (_media_list.find(volume_seq) != _media_list.end()) {
        std::vector<media_info_ptr>& list = _media_list[volume_seq];
        for (const auto& info : list) {
          if (info->num == media) {
            folder = info->folder;
            break;
          }
        }
      } else {
        Json::Value media_list(Json::arrayValue);
        db->get_volume_media_list(volume_seq, onis::database::info_all,
                                  onis::database::lock_mode::NO_LOCK,
                                  media_list);
        std::vector<media_info_ptr>& list = _media_list[volume_seq];
        for (const auto& item : media_list) {
          media_info_ptr info = media_info::create(
              item[ME_NUM_KEY].asInt(), item[ME_PATH_KEY].asString(),
              item[ME_RATIO_KEY].asFloat());
          list.push_back(info);
          if (info->num == media)
            folder = info->folder;
        }
      }
    }
  }
  return folder;
}

//------------------------------------------------------------------------------
// utilities
//------------------------------------------------------------------------------

std::string request_service::convert_dicom_file_to_json(
    const onis::dicom_file_ptr& dcm) {
  if (dcm == NULL)
    return "";
  Json::Value root;
  dcm->lock();
  std::string charset;
  dcm->get_string_element(charset, TAG_SPECIFIC_CHARACTER_SET, "CS", "");
  std::int32_t tag;
  std::string vr;
  std::int32_t vm;
  for (std::int32_t i = 0; i < 2; i++) {
    void* elem = dcm->get_next_element(i, NULL, &tag, &vr, &vm);
    while (elem != NULL) {
      std::string value;
      dcm->get_string_from_element(value, elem, charset);
      std::uint16_t* tmp = (std::uint16_t*)&tag;
      char key_buf[16];
      snprintf(key_buf, sizeof(key_buf), "%04X:%04X", std::uint16_t(tmp[1]),
               std::uint16_t(tmp[0]));
      std::string key = key_buf;
      root[key] = value;
      elem = dcm->get_next_element(i, elem, &tag, &vr, &vm);
    }
  }

  onis::frame_region_list regions;
  dcm->get_regions(regions);
  dcm->unlock();

  Json::Value region_nodes(Json::arrayValue);
  for (onis::frame_region_list::iterator it1 = regions.begin();
       it1 != regions.end(); it1++) {
    Json::Value region_node(Json::objectValue);

    Json::Value area(Json::arrayValue);
    area.append((*it1)->x0);
    area.append((*it1)->x1);
    area.append((*it1)->y0);
    area.append((*it1)->y1);
    region_node["area"] = area;
    region_node["spatial_format"] = (*it1)->spatial_format;
    region_node["data_type"] = (*it1)->data_type;
    Json::Value spacing(Json::arrayValue);
    spacing.append((*it1)->original_spacing[0]);
    spacing.append((*it1)->original_spacing[1]);
    region_node["spacing"] = spacing;
    Json::Value units(Json::arrayValue);
    units.append((*it1)->original_unit[0]);
    units.append((*it1)->original_unit[1]);
    region_node["units"] = units;
    region_nodes.append(region_node);
  }
  root["regions"] = region_nodes;

  Json::FastWriter writer;
  return writer.write(root);
}