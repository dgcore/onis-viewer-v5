#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>
#include "../request_database.hpp"

class request_service;
typedef std::shared_ptr<request_service> request_service_ptr;

////////////////////////////////////////////////////////////////////////////////
// local_store_request class
////////////////////////////////////////////////////////////////////////////////

class local_store_request {
public:
  // constructor:
  local_store_request(const request_service_ptr& service);

  // destructor:
  ~local_store_request();

  // prevent copy and move:
  local_store_request(const local_store_request&) = delete;
  local_store_request& operator=(const local_store_request&) = delete;
  local_store_request(local_store_request&&) = delete;
  local_store_request& operator=(local_store_request&&) = delete;

  // operations:
  void init(const std::string& parameters, const std::string& path,
            std::int32_t media, const std::string& media_folder);
  void set_origin(const std::string& id, const std::string& name,
                  const std::string& ip);
  void import_file(request_database* db, const std::string& partition_seq,
                   Json::Value* output, std::uint32_t* output_flags);
  void cleanup();

private:
  request_service_ptr service_;
  // onis::dicom_file_ptr _dcm;
  std::int32_t media_{0};
  std::string media_folder_;
  std::vector<std::string> created_files_;

  std::string origin_id_;
  std::string origin_name_;
  std::string origin_ip_;

  // information about the partition:
  std::string partition_seq_;
  bool reject_no_pid_{false};
  std::uint32_t conflict_mode_{0};
  std::uint32_t conflict_criterias_{0};
  std::uint32_t overwrite_mode_{0};
  std::string default_pid_;
  bool create_image_icon_{false};
  bool create_series_icon_{false};
  bool create_stream_file_{false};

  // information from the dicom file:
  std::string charset_;
  std::string patient_id_;
  std::string name_;
  std::string ideogram_;
  std::string phonetic_;
  std::string birthdate_;
  std::string birthtime_;
  std::string sex_;
  std::string study_uid_;
  std::string series_uid_;
  std::string sop_;
  std::string modality_;
  std::string study_date_;
  std::string acc_num_;
  std::string study_id_;
  std::string study_desc_;

  // other:
  // onis::core::date_time _current_time;

  // utilities:
  /*void _set_error_status(s32 status, s32 reason, onis::aresult& res);
  void _check_study_date_format();
  Json::Value* _find_matching_patient(Json::Value& patients);
  Json::Value* _find_online_study(Json::Value& items, b32 allow_none,
                                  onis::aresult& res);
  Json::Value* _find_conflict_study(Json::Value& items, onis::aresult& res);
  b32 _study_is_in_conflict(const Json::Value* item, onis::aresult& res);

  // process:
  void _add_new_image_to_partition(const sdb_access_ptr& db,
                                   const Json::Value* conflict_study,
                                   Json::Value* existing_items[4],
                                   Json::Value* created_items,
                                   onis::aresult& res);*/
};
