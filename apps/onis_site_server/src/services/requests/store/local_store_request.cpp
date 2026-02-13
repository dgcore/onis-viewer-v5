#include "../../../../include/services/requests/store/local_store_request.hpp"
#include "../../../../include/database/items/db_image.hpp"
#include "../../../../include/database/items/db_patient.hpp"
#include "../../../../include/database/items/db_series.hpp"
#include "../../../../include/database/items/db_study.hpp"
#include "../../../../include/database/site_database.hpp"
#include "../../../../include/site_api.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/dicom/dicom.hpp"
#include "onis_kit/include/utilities/date_time.hpp"
#include "onis_kit/include/utilities/dicom.hpp"
#include "onis_kit/include/utilities/filesystem.hpp"
#include "onis_kit/include/utilities/string.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

////////////////////////////////////////////////////////////////////////////////
// local_store_request class
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

local_store_request::local_store_request(const request_service_ptr& service)
    : service_(service) {}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

local_store_request::~local_store_request() {}

//------------------------------------------------------------------------------
// init
//------------------------------------------------------------------------------

void local_store_request::import_file_to_partition(
    const request_database& db, std::string& partition_seq,
    const std::string& partition_parameters, std::int32_t media,
    const std::string& media_folder, const std::string& dicom_file_path,
    bool do_commit, Json::Value* output, std::uint32_t* output_flags) {
  try {
    init(partition_parameters, dicom_file_path, media, media_folder);
    import_file(db, partition_seq, output, output_flags);
    if (do_commit) {
      db->commit();
    }
    created_files_.clear();
    cleanup();
  } catch (const onis::exception& e) {
    cleanup();
    throw e;
  } catch (...) {
    cleanup();
    throw;
    cleanup();
  }
}

void local_store_request::init(const std::string& parameters,
                               const std::string& path, std::int32_t media,
                               const std::string& media_folder) {
  if (media_folder.empty()) {
    throw onis::exception(EOS_FILE_WRITE, "No media to store the image");
  }

  site_api_ptr api = site_api::get_instance();
  media_ = media;
  media_folder_ = media_folder;

  // get the dicom manager:
  onis::dicom_manager_ptr manager = api->get_dicom_manager();
  if (manager == NULL) {
    throw onis::exception(EOS_INTERNAL, "Missing Dicom manager");
  }

  // create a DICOM file:
  dcm_.reset();
  dcm_ = manager->create_dicom_file();
  if (dcm_ == nullptr) {
    throw onis::exception(EOS_INTERNAL, "Failed to create a new DICOM file");
  }

  // load the DICOM file:
  if (!dcm_->load_file(path)) {
    throw onis::exception(EOS_FILE_FORMAT, "Failed to load the DICOM file");
  }

  if (!parameters.empty()) {
    Json::Reader reader;
    Json::Value param;
    if (!reader.parse(parameters, param)) {
      throw onis::exception(EOS_PARAM,
                            "Failed to parse the partition parameters");
    }
    reject_no_pid_ = param.isMember(PT_PID_MODE_KEY)
                         ? param[PT_PID_MODE_KEY].asInt() == 0
                         : true;
    conflict_mode_ = param.isMember(PT_CONFLICT_MODE_KEY)
                         ? param[PT_CONFLICT_MODE_KEY].asInt()
                         : 0;
    conflict_criterias_ = param.isMember(PT_CONFLICT_CRITERIA_KEY)
                              ? param[PT_CONFLICT_CRITERIA_KEY].asInt()
                              : 0;
    default_pid_ = param.isMember(PT_DEF_PID_KEY)
                       ? param[PT_DEF_PID_KEY].asString()
                       : "99";
    overwrite_mode_ = param.isMember(PT_OVERWRITE_MODE_KEY)
                          ? param[PT_OVERWRITE_MODE_KEY].asInt()
                          : 0;
    create_image_icon_ =
        param.isMember(PT_PREV_ICON) ? param[PT_PREV_ICON].asInt() != 0 : false;
    create_series_icon_ = create_image_icon_;
    create_stream_file_ = param.isMember(PT_STREAM_DATA)
                              ? param[PT_STREAM_DATA].asInt() != 0
                              : false;
  }

  // read the necessary information from the dicom file:
  site_database::get_patient_info_to_insert(dcm_, &charset_, &name_, &ideogram_,
                                            &phonetic_, &birthdate_,
                                            &birthtime_, &sex_, nullptr);
  dcm_->get_string_element(patient_id_, TAG_PATIENT_ID, "LO", charset_);
  dcm_->get_string_element(study_uid_, TAG_STUDY_INSTANCE_UID, "UI", charset_);
  dcm_->get_string_element(series_uid_, TAG_SERIES_INSTANCE_UID, "UI",
                           charset_);
  dcm_->get_string_element(sop_, TAG_SOP_INSTANCE_UID, "UI", charset_);
  dcm_->get_string_element(modality_, TAG_MODALITY, "CS", charset_);
  dcm_->get_string_element(study_date_, TAG_STUDY_DATE, "DA", charset_);
  dcm_->get_string_element(acc_num_, TAG_ACCESSION_NUMBER, "SH", charset_);
  dcm_->get_string_element(study_id_, TAG_STUDY_ID, "SH", charset_);
  dcm_->get_string_element(study_desc_, TAG_STUDY_DESCRIPTION, "LO", charset_);

  // check if the information is valid:
  check_study_date_format(study_date_);
  if (sop_.empty()) {
    throw onis::exception(EOS_MISSING_SOP_UID, "Missing SOP UID");
  }
  if (series_uid_.empty()) {
    throw onis::exception(EOS_MISSING_SERIES_UID, "Missing series UID");
  }
  if (study_uid_.empty()) {
    throw onis::exception(EOS_MISSING_STUDY_UID, "Missing study UID");
  }
  if (modality_.empty()) {
    throw onis::exception(EOS_MISSING_MODALITY, "Missing modality");
  }
  if (patient_id_.empty() && reject_no_pid_) {
    throw onis::exception(EOS_MISSING_PATIENT_ID, "Missing patient id");
  }
}

//------------------------------------------------------------------------------
// set origin
//------------------------------------------------------------------------------

void local_store_request::set_origin(const std::string& id,
                                     const std::string& name,
                                     const std::string& ip) {
  origin_id_ = id;
  origin_name_ = name;
  origin_ip_ = ip;
}

//------------------------------------------------------------------------------
// import file
//------------------------------------------------------------------------------

void local_store_request::import_file(const request_database& db,
                                      const std::string& partition_seq,
                                      Json::Value* output,
                                      std::uint32_t* output_flags) {
  Json::Value created_items[4] = {
      Json::Value(Json::objectValue), Json::Value(Json::objectValue),
      Json::Value(Json::objectValue), Json::Value(Json::objectValue)};
  Json::Value* existing_items[4] = {nullptr, nullptr, nullptr, nullptr};
  Json::Value existing_series(Json::objectValue);
  const Json::Value* conflict_study = nullptr;
  partition_seq_ = partition_seq;

  // get the current time:
  current_time_.init_current_time();

  // share lock the partition to make sure nobody can modify it during our
  // process:
  std::string site_seq;
  Json::Value partition(Json::objectValue);
  db->find_partition_by_seq(
      partition_seq_, onis::database::info_partition_conflict, 0, 0,
      onis::database::lock_mode::SHARE_LOCK, &site_seq, partition);

  // we retrieve all the online and conflicted studies matching the study uid:
  Json::Value studies(Json::arrayValue);
  db->find_online_and_conflicted_studies(
      partition_seq_, study_uid_, onis::database::lock_mode::EXCLUSIVE_LOCK,
      onis::database::info_all, onis::database::info_all, false, studies);

  // if the patient id is empty, try to get one from the study uid.
  /*if (patient_id_.empty() && res.status == OSRSP_FAILURE) {
    const Json::Value* online_study = _find_online_study(studies, OSTRUE,
  res); if (online_study != NULL) _patient_id =
  ((*online_study)["patient"])[PA_UID_KEY].asString(); else _patient_id =
          _default_pid + "_" +
          boost::uuids::to_string(db->application()->generate_random_uuid());

    if (debug_level && !had_error) {
      logger->write_event(
          _log_info, onis::log::info,
          "Patient id not defined. Created one: '" + _patient_id + "'");
    }
  }*/

  // retrieve and lock the online patients matching the patient id:
  Json::Value patients(Json::arrayValue);
  db->find_online_patients(partition_seq_, patient_id_,
                           onis::database::info_all, false,
                           onis::database::lock_mode::EXCLUSIVE_LOCK, patients);
  // make sure that the sop does not already exist under any online or
  // conflicted study:
  bool sop_already_exist =
      (studies.empty())
          ? false
          : db->check_if_sop_already_exist_under_online_or_conflicted_study(
                sop_, studies);
  if (sop_already_exist) {
    // the image already exist in the database
    switch (overwrite_mode_) {
      case onis::database::partition::no_overwrite_failure:
        throw onis::exception(EOS_DUPLICATE,
                              "The sop already exist in the database");
      case onis::database::partition::no_overwrite_success:
        break;
      default:
        throw onis::exception(EOS_PARAM,
                              "Unsupported value for overwrite behavior");
    }
  } else {
    // the image is unique
    // the study might be in conflict with an existing study !
    // the patients can only be online or deleted (no conflict flag!)
    if (studies.empty()) {
      // the study does not exist in the database.
      // the study can't be in conflict with an existing study
      // we might be able to insert the study to an existing patient
      // otherwise we will need to create a new patient.

      // search if we have an online patient that we can use:
      existing_items[0] = find_matching_patient(patients);
    } else {
      // are we in conflict with the online study?
      Json::Value* online_study = find_online_study(studies, false);
      if (!study_is_in_conflict(online_study)) {
        // the incoming study does not conflict with the online study !
        // we can insert the new image under the online study
        existing_items[0] = &(*online_study)["patient"];
        existing_items[1] = &(*online_study)["study"];
      } else {
        // the incoming image is in conflict with the online study.
        if (conflict_mode_ == onis::database::partition::reject_if_conflict) {
          throw onis::exception(EOS_CONFLICT, "The image is rejected");
        } else {
          conflict_study = online_study;
          // search if it can be attached to one study in conflict:
          Json::Value* winner = find_conflict_study(studies);
          if (winner) {
            // we can insert the new image under this study:
            existing_items[0] = &(*winner)["patient"];
            existing_items[1] = &(*winner)["study"];
          } else {
            // we didn't find a study where to attach the incoming image.
            // we will need to create a new study
            // however, we might be able to attach this new study to an
            // existing patient
            existing_items[0] = find_matching_patient(patients);
          }
        }
      }

      if (existing_items[0] != nullptr && existing_items[1] != nullptr) {
        // we will attach the image to an existing patient and study in the
        // database maybe we also have a series to which we can attach the
        // image
        // !
        if (db->get_online_series((*existing_items[1])[ST_SEQ_KEY].asString(),
                                  series_uid_, onis::database::info_all, false,
                                  onis::database::lock_mode::EXCLUSIVE_LOCK,
                                  existing_series)) {
          existing_items[2] = &existing_series;
        }
      }
    }

    add_new_image_to_partition(db, conflict_study, existing_items,
                               created_items);

    Json::Value* final_items[4];
    for (std::int32_t i = 0; i < 4; i++)
      final_items[i] =
          existing_items[i] == nullptr ? &created_items[i] : existing_items[i];

    if (conflict_study != nullptr) {
      if (partition[PT_HAVE_CONFLICT_KEY].asInt() == 0) {
        partition[BASE_FLAGS_KEY] = onis::database::info_partition_conflict;
        partition[PT_HAVE_CONFLICT_KEY] = 1;
        db->modify_partition(partition, 0);
      }
    }

    if (conflict_study == nullptr) {
      /*db->add_image_to_routing_table(
          site_seq, _partition_seq,
          (*final_items[2])[BASE_SEQ_KEY].asString(),
          (*final_items[3])[BASE_SEQ_KEY].asString(), _dcm, _T(""), _T(""),
          NULL, NULL, NULL, res);*/
    }

    if (output != nullptr && output_flags != nullptr) {
      (*output)["patient"] = Json::Value(Json::objectValue);
      (*output)["study"] = Json::Value(Json::objectValue);
      (*output)["series"] = Json::Value(Json::objectValue);
      (*output)["image"] = Json::Value(Json::objectValue);
      onis::database::patient::copy(*final_items[0], output_flags[0], true,
                                    (*output)["patient"]);
      onis::database::study::copy(*final_items[1], output_flags[1], true,
                                  (*output)["study"]);
      onis::database::series::copy(*final_items[2], output_flags[2], true,
                                   (*output)["series"]);
      onis::database::image::copy(*final_items[3], output_flags[3], true,
                                  (*output)["image"]);
    }
  }
}

//------------------------------------------------------------------------------
// cleanup
//------------------------------------------------------------------------------

void local_store_request::cleanup() {
  dcm_.reset();
  media_folder_.clear();
  origin_id_.clear();
  origin_name_.clear();
  origin_ip_.clear();
  partition_seq_.clear();
  reject_no_pid_ = false;
  conflict_mode_ = 0;
  conflict_criterias_ = 0;
  overwrite_mode_ = 0;
  default_pid_.clear();
  create_image_icon_ = false;
  create_series_icon_ = false;
  create_stream_file_ = false;
  charset_.clear();
  patient_id_.clear();
  name_.clear();
  ideogram_.clear();
  phonetic_.clear();
  birthdate_.clear();
  birthtime_.clear();
  sex_.clear();
  study_uid_.clear();
  series_uid_.clear();
  sop_.clear();
  modality_.clear();
  study_date_.clear();
  acc_num_.clear();
  study_id_.clear();
  study_desc_.clear();
  current_time_.init_current_time();
  for (auto& file : created_files_) {
    onis::util::filesystem::delete_file(file);
  }
  created_files_.clear();
}

//------------------------------------------------------------------------------
// add new image to partition
//------------------------------------------------------------------------------

void local_store_request::add_new_image_to_partition(
    const request_database& db, const Json::Value* conflict_study,
    Json::Value* existing_items[4], Json::Value* created_items) {
  // search the compression information for the partition:
  Json::Value compressions(Json::arrayValue);
  db->get_partition_compressions(partition_seq_, onis::database::info_all,
                                 onis::database::lock_mode::NO_LOCK,
                                 compressions);
  std::string compression_id =
      compressions.size() == 1 ? compressions[0][BASE_SEQ_KEY].asString() : "";

  // save the dicom file:
  std::string image_path, image_relative_path;
  std::string stream_path, stream_relative_path;
  save_dicom_file(dcm_, media_folder_, partition_seq_, study_date_, modality_,
                  series_uid_, sop_, &image_path, &image_relative_path);
  if (!image_path.empty())
    created_files_.push_back(image_path);

  // create the necessary items:
  if (existing_items[0] == nullptr && created_items[0].empty()) {
    db->create_patient(partition_seq_, current_time_, patient_id_, dcm_,
                       origin_id_, origin_name_, origin_ip_, created_items[0]);
  }

  if (existing_items[1] == nullptr && created_items[1].empty()) {
    db->create_study(partition_seq_, conflict_study,
                     existing_items[0] == nullptr
                         ? created_items[0][BASE_SEQ_KEY].asString()
                         : (*existing_items[0])[BASE_SEQ_KEY].asString(),
                     current_time_, study_uid_, dcm_, origin_id_, origin_name_,
                     origin_ip_, created_items[1]);
  }

  if (existing_items[2] == nullptr && created_items[2].empty()) {
    db->create_series(existing_items[1] == nullptr
                          ? created_items[1][BASE_SEQ_KEY].asString()
                          : (*existing_items[1])[BASE_SEQ_KEY].asString(),
                      current_time_, dcm_, create_series_icon_, origin_id_,
                      origin_name_, origin_ip_, created_items[2]);
  }

  if (existing_items[3] == nullptr && created_items[3].empty()) {
    db->create_image(0, 0,
                     existing_items[2] == NULL
                         ? created_items[2][BASE_SEQ_KEY].asString()
                         : (*existing_items[2])[BASE_SEQ_KEY].asString(),
                     current_time_, dcm_, media_, image_relative_path,
                     create_stream_file_, create_image_icon_, origin_id_,
                     origin_name_, origin_ip_, created_items[3]);
  }

  Json::Value* final_items[4];
  for (std::int32_t i = 0; i < 4; i++)
    final_items[i] =
        existing_items[i] == nullptr ? &created_items[i] : existing_items[i];

  // increase the image count:
  (*final_items[2])[SR_IMCNT_KEY] = (*final_items[2])[SR_IMCNT_KEY].asInt() + 1;
  (*final_items[1])[ST_IMCNT_KEY] = (*final_items[1])[ST_IMCNT_KEY].asInt() + 1;
  if ((*final_items[1])[ST_STATUS_KEY].asString() == ONLINE_STATUS)
    (*final_items[0])[PA_IMCNT_KEY] =
        (*final_items[0])[PA_IMCNT_KEY].asInt() + 1;

  // increase the series count:
  if (existing_items[2] == NULL) {
    (*final_items[1])[ST_SRCNT_KEY] =
        (*final_items[1])[ST_SRCNT_KEY].asInt() + 1;
    if ((*final_items[1])[ST_STATUS_KEY].asString() == ONLINE_STATUS)
      (*final_items[0])[PA_SRCNT_KEY] =
          (*final_items[0])[PA_SRCNT_KEY].asInt() + 1;
  }

  // increasing the study count:
  if (existing_items[1] == NULL) {
    if ((*final_items[1])[ST_STATUS_KEY].asString() == ONLINE_STATUS)
      (*final_items[0])[PA_STCNT_KEY] =
          (*final_items[0])[PA_STCNT_KEY].asInt() + 1;
  }

  // define the modalities, body parts and station names for the study:
  bool modif = db->update_study_modalities_bodyparts_and_station_names(
      *final_items[1], "");

  // now update the database:
  if ((*final_items[1])[ST_STATUS_KEY].asString() == ONLINE_STATUS) {
    db->modify_patient(*final_items[0],
                       onis::database::info_patient_statistics);
  }
  db->modify_series(*final_items[2], onis::database::info_series_statistics);
  db->modify_study(*final_items[1],
                   modif ? onis::database::info_study_statistics |
                               onis::database::info_study_body_parts |
                               onis::database::info_study_modalities |
                               onis::database::info_study_stations
                         : onis::database::info_study_statistics);

  // update the albums:
  /*if (res.good()) {
    db->update_albums_after_adding_images(
        *final_items[0], *final_items[1], *final_items[2],
        existing_items[2] == NULL ? OSTRUE : OSFALSE, 1, res);
  }*/
}

//------------------------------------------------------------------------------
// utilities
//------------------------------------------------------------------------------

void local_store_request::check_study_date_format(std::string& study_date) {
  if (study_date.empty())
    return;
  // check if we have multiple dates:
  std::size_t pos = study_date.find('\\');
  if (pos != std::string::npos)
    study_date = study_date.substr(pos);
  // check the date information
  if (study_date.length() != 8)
    study_date = "";
  else {
    for (char c : study_date) {
      if (c < '0' || c > '9') {
        study_date = "";
        break;
      }
    }
  }
}

Json::Value* local_store_request::find_matching_patient(Json::Value& patients) {
  for (auto& patient : patients) {
    if (patient[PA_UID_KEY].asString() == patient_id_ &&
        patient[PA_NAME_KEY].asString() == name_ &&
        patient[PA_IDEOGRAM_KEY].asString() == ideogram_ &&
        patient[PA_PHONETIC_KEY].asString() == phonetic_ &&
        patient[PA_BDATE_KEY].asString() == birthdate_ &&
        patient[PA_BTIME_KEY].asString() == birthtime_ &&
        patient[PA_SEX_KEY].asString() == sex_) {
      return &patient;
    }
  }
  return nullptr;
}

Json::Value* local_store_request::find_online_study(Json::Value& items,
                                                    bool allow_none) {
  Json::Value* online_study = NULL;
  for (auto& item : items) {
    if (item["study"][ST_STATUS_KEY].asString() == ONLINE_STATUS) {
      if (online_study == nullptr) {
        online_study = &item;
      } else {
        // we should not have 2 online studies !
        throw onis::exception(EOS_DB_CONSISTENCY, "Two online studies found");
      }
    }
  }
  if (online_study == nullptr && !allow_none) {
    // we should have one online study !
    throw onis::exception(EOS_DB_CONSISTENCY, "No online study found");
  }
  return online_study;
}

Json::Value* local_store_request::find_conflict_study(Json::Value& items) {
  // try to find a perfect match:
  Json::Value* conflict_study = nullptr;
  for (auto& item : items) {
    const Json::Value& study = item["study"];
    if (study[ST_STATUS_KEY].asString() != ONLINE_STATUS) {
      const Json::Value& patient = item["patient"];
      if (patient[PA_UID_KEY].asString() == patient_id_ &&
          patient[PA_NAME_KEY].asString() == name_ &&
          patient[PA_IDEOGRAM_KEY].asString() == ideogram_ &&
          patient[PA_PHONETIC_KEY].asString() == phonetic_ &&
          patient[PA_BDATE_KEY].asString() == birthdate_ &&
          patient[PA_SEX_KEY].asString() == sex_ &&
          study[ST_ACCNUM_KEY].asString() == acc_num_ &&
          study[ST_STUDYID_KEY].asString() == study_id_ &&
          study[ST_DESC_KEY].asString() == study_desc_) {
        conflict_study = &item;
        break;
      }
    }
  }
  if (conflict_study == nullptr) {
    // we didn't get a perfect match !
    // we search one who is not in conflict:
    for (auto& item : items) {
      if (!study_is_in_conflict(&item)) {
        conflict_study = &item;
        break;
      }
    }
  }
  return conflict_study;
}

bool local_store_request::study_is_in_conflict(const Json::Value* item) {
  // analyze:
  const Json::Value& patient = (*item)["patient"];
  const Json::Value& study = (*item)["study"];
  // check the patient id:
  if (patient[PA_UID_KEY].asString() != patient_id_)
    return true;

  // if no criteria, no conflict:
  if (conflict_criterias_ == 0)
    return false;

  // analyze each criteria:
  if (conflict_criterias_ &
      onis::database::partition::conflict_accession_number)
    if (study[ST_ACCNUM_KEY].asString() != acc_num_)
      return true;
  if (conflict_criterias_ & onis::database::partition::conflict_study_id)
    if (study[ST_STUDYID_KEY].asString() != study_id_)
      return true;
  if (conflict_criterias_ & onis::database::partition::conflict_study_id)
    if (study[ST_DESC_KEY].asString() != study_desc_)
      return true;
  if (conflict_criterias_ & onis::database::partition::conflict_patient_name) {
    if (patient[PA_NAME_KEY].asString() != name_)
      return true;
    if (patient[PA_IDEOGRAM_KEY].asString() != ideogram_)
      return true;
    if (patient[PA_PHONETIC_KEY].asString() != phonetic_)
      return true;
  }
  if (conflict_criterias_ &
      onis::database::partition::conflict_patient_birthdate) {
    if (patient[PA_BDATE_KEY].asString() != birthdate_)
      return true;
  }
  if (conflict_criterias_ & onis::database::partition::conflict_patient_sex)
    if (patient[PA_SEX_KEY].asString() != sex_)
      return true;
  return false;
}

//------------------------------------------------------------------------------
// Dicom file saving
//------------------------------------------------------------------------------

void local_store_request::save_dicom_file(
    const onis::dicom_file_ptr& dcm, const std::string& folder,
    const std::string& partition_id, std::string study_date,
    std::string modality, std::string series_uid, std::string sop,
    std::string* file_path, std::string* relative_path) {
  if (sop.empty())
    dcm->get_string_element(sop, TAG_SOP_INSTANCE_UID, "UI");
  std::string full_path = get_dicom_file_path_saving_directory(
      dcm, folder, partition_id, study_date, modality, series_uid, sop);
  if (!full_path.empty()) {
    // we need to save the file into our directory
    std::string id = onis::util::uuid::generate_random_uuid();
    if (id.empty()) {
      throw onis::exception(
          EOS_FILE_WRITE,
          "Failed to create a unique file name for storing dicom file.");
    }
    std::string file_name = "IM_" + id + ".dcm";
    onis::util::filesystem::concat(full_path, file_name);
    if (!dcm->save_file(full_path)) {
      throw onis::exception(EOS_FILE_WRITE, "Failed to store the dicom file.");
    }
    if (file_path != nullptr) {
      *file_path = full_path;
      onis::util::string::replace_antislash_by_slash(*file_path);
    }
    if (relative_path != nullptr) {
      *relative_path =
          onis::util::filesystem::get_relative_path(full_path, folder);
      onis::util::string::replace_antislash_by_slash(*relative_path);
    }
  }
}

std::string local_store_request::get_dicom_file_path_saving_directory(
    const onis::dicom_file_ptr& dcm, const std::string& folder,
    const std::string& partition_id, std::string study_date,
    std::string modality, std::string series_uid, std::string sop) {
  if (folder.empty()) {
    throw onis::exception(EOS_FILE_WRITE, "No folder to save the dicom file");
  } else {
    if (study_date.empty())
      dcm->get_string_element(study_date, TAG_STUDY_DATE, "DA");
    check_study_date_format(study_date);
    if (modality.empty())
      dcm->get_string_element(modality, TAG_MODALITY, "CS");
    if (series_uid.empty())
      dcm->get_string_element(series_uid, TAG_SERIES_INSTANCE_UID, "UI");
    if (sop.empty())
      dcm->get_string_element(sop, TAG_SOP_INSTANCE_UID, "UI");

    std::string dir = partition_id;
    onis::util::filesystem::concat(dir,
                                   study_date.empty() ? "NoDate" : study_date);
    onis::util::filesystem::concat(dir, modality);
    onis::util::filesystem::concat(dir, series_uid);
    std::string full_path = folder;
    onis::util::filesystem::concat(full_path, dir);
    if (!onis::util::filesystem::create_multi_directories(full_path))
      throw onis::exception(EOS_FILE_WRITE, "Failed to create the directory");
    return full_path;
  }
}