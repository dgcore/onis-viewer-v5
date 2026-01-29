#pragma once

#include <json/json.h>
#include <memory>
#include <optional>
#include <string>
#include <vector>
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/database/database_interface.hpp"
#include "sql_builder.hpp"

using namespace onis;
using json = Json::Value;
using onis::database::lock_mode;

class site_database {
public:
  explicit site_database(
      std::unique_ptr<onis_kit::database::database_connection>&& connection);
  ~site_database();

  // Connection access
  onis_kit::database::database_connection& get_connection();
  const onis_kit::database::database_connection& get_connection() const;

  // Organization operations
  std::string get_organization_columns(std::uint32_t flags,
                                       bool add_table_name = false);
  void read_organization_record(onis_kit::database::database_row& rec,
                                std::uint32_t flags, json& output);
  void find_organization_by_seq(const std::string& seq, std::uint32_t flags,
                                lock_mode lock, json& output);

  // Site operations
  std::string get_site_columns(std::uint32_t flags,
                               bool add_table_name = false);
  void read_site_record(onis_kit::database::database_row& rec,
                        std::uint32_t flags, std::string* org_seq,
                        json& output);
  void lock_site(const std::string& seq, lock_mode lock);
  void find_site_by_seq(const std::string& seq, std::uint32_t flags,
                        lock_mode lock, std::string* org_seq, json& output);
  void find_single_site(std::uint32_t flags, lock_mode lock,
                        std::string* org_seq, json& output);

  // Volume operations
  std::string get_volume_columns(std::uint32_t flags,
                                 bool add_table_name = false);
  void read_volume_record(onis_kit::database::database_row& rec,
                          std::uint32_t flags, std::string* site_seq,
                          json& output);
  void find_volume_by_seq(const std::string& seq, std::uint32_t flags,
                          lock_mode lock, std::string* site_seq, json& output);
  void find_volume_by_seq(const std::string& site_seq, const std::string& seq,
                          std::uint32_t flags, lock_mode lock, json& output);
  void find_volumes_for_site(const std::string& site_seq, std::uint32_t flags,
                             lock_mode mode, json& output);
  void create_volume(const std::string& site_seq, const json& input,
                     json& output, std::uint32_t out_flags);
  void modify_volume(const json& volume);
  void delete_volume(const std::string& seq);

  // Media operations:
  std::string get_media_columns(std::uint32_t flags,
                                bool add_table_name = false);
  void read_media_record(onis_kit::database::database_row& rec,
                         std::uint32_t flags, std::string* site_seq,
                         std::string* volume_seq, json& output);
  void get_volume_media_list(const std::string& volume_seq, std::uint32_t flags,
                             lock_mode lock, json& output);

  // roles:
  std::string get_role_columns(std::uint32_t flags, bool add_table_name);
  void read_role_record(onis_kit::database::database_row& rec,
                        std::uint32_t flags, std::string* site_seq,
                        json& output);
  void find_role_by_seq(const std::string& seq, std::uint32_t flags,
                        lock_mode lock, std::string* site_seq, json& output);
  void find_role_by_seq(const std::string& site_seq, const std::string& seq,
                        std::uint32_t flags, lock_mode lock, json& output);
  void find_roles_for_site(const std::string& site_seq, std::uint32_t flags,
                           lock_mode lock, json& output);
  void create_role(const std::string& site_seq, const json& input, json& output,
                   std::uint32_t out_flags);
  void modify_role(const json& role);
  void delete_role(const std::string& seq);
  void get_role_membership(const std::string& seq, json& output);
  void check_circular_membership(const std::string& parent_id,
                                 const std::string& child_id);
  void get_role_permissions(const std::string& seq, json& output);
  std::string find_role_permission_seq(const std::string& name);
  void create_role_permission_value(const std::string& role_seq,
                                    const std::string& permission_id,
                                    std::int32_t value);
  void modify_role_permission_value(const std::string& role_seq,
                                    const std::string& permission_seq,
                                    std::int32_t value, bool create);

  // permissions:
  void find_permissions_items(json& output, std::uint32_t flags);
  bool exist_permission(bool role, const std::string& seq,
                        const std::string& permission_seq);

  // groups:
  std::string get_group_columns(std::uint32_t flags, bool add_table_name);
  void read_group_record(onis_kit::database::database_row& rec,
                         std::uint32_t flags, std::string* site_seq,
                         json& output);

  // users:
  std::string get_user_columns(std::uint32_t flags, bool add_table_name);
  void read_user_record(onis_kit::database::database_row& rec,
                        std::uint32_t flags, bool need_password,
                        std::string* site_seq, json& output);
  void find_user_for_session(const std::string& site_seq,
                             const std::string& login,
                             const std::string& password, std::uint32_t flags,
                             json& output);
  void get_user_membership(const std::string& seq, json& output);
  void get_user_permissions(const std::string& seq, json& output);

  // partitions:
  std::string get_partition_columns(std::uint32_t flags,
                                    bool add_table_name) const;
  /*void find_partitions(const onis::astring &clause, std::uint32_t flags,
  std::uint32_t album_flags, std::uint32_t smart_album_flags, std::int32_t
  lock_mode, Json::Value &output, onis::astring *site_seq, onis::aresult &res);
  b32 find_partition(const onis::astring &clause, std::uint32_t flags,
  std::uint32_t album_flags, std::uint32_t smart_album_flags, std::int32_t
  lock_mode, Json::Value &output, onis::astring *site_seq, onis::aresult
  &res);*/
  void find_partitions_for_site(const std::string& site_id, std::uint32_t flags,
                                std::uint32_t album_flags,
                                std::uint32_t smart_album_flags, lock_mode lock,
                                Json::Value& output);
  void read_partition_record(onis_kit::database::database_row& rec,
                             std::uint32_t flags, std::string* site_id,
                             json& output);
  /*void create_partition_item(onis::odb_record &rec, std::uint32_t flags,
  onis::astring *site_seq, Json::Value &output, onis::aresult &res); void
  create_partition_item(onis::odb_record &rec, std::uint32_t flags,
  onis::astring *site_seq, Json::Value &output, std::int32_t &index,
  onis::aresult &res); void find_partition_by_seq(const onis::astring &seq,
  std::uint32_t flags, std::uint32_t album_flags, std::uint32_t
  smart_album_flags, std::int32_t lock_mode, onis::astring *site_seq,
  Json::Value &output, onis::aresult &res); void find_partition_by_seq(const
  onis::astring &site_seq, const onis::astring &seq, std::uint32_t flags,
  std::uint32_t album_flags, std::uint32_t smart_album_flags, std::int32_t
  lock_mode, Json::Value &output, onis::aresult &res); void
  modify_partition(const Json::Value &output, std::uint32_t flags, onis::aresult
  &res); void create_partition(const onis::astring &site_seq, const Json::Value
  &input, Json::Value &output, std::uint32_t out_flags, onis::aresult &res);
  void find_partition_names_for_site(const onis::astring &site_seq,
  std::list<onis::astring> &list, onis::aresult &res); b32
  partition_have_conflict(const onis::astring &seq, onis::aresult &res); void
  delete_partition(const onis::astring &seq, onis::aresult &res); void
  transfer_images_to_album(const onis::astring &partition_seq, const
  onis::astring &album_seq, const onis::astring &patient_id, const
  onis::astring &patient_seq, const onis::astring &study_uid, const
  onis::astring &study_seq, const onis::astring &series_uid, const
  onis::astring &series_seq, const onis::astring &image_uid, const
  onis::astring &image_seq, onis::aresult &res);*/

  // partition access:
  /*b32 find_partition_access(b32 is_role, const onis::astring &seq,
  std::int32_t lockmode, Json::Value &output, onis::astring *access_seq, b32
  include_items, onis::aresult &res); void
  create_partition_access_item(onis::odb_record &rec, Json::Value &output,
  onis::astring *access_seq, onis::aresult &res); void
  create_partition_access(b32 is_role, const onis::astring &seq, const
  Json::Value &input, std::int32_t lockmode, Json::Value &output, onis::astring
  *access_seq, onis::aresult &res); void modify_partition_access(b32 is_role,
  const onis::astring &seq, const Json::Value &input, onis::aresult &res);
  void add_partition_access_item(const onis::astring &access_seq, const
  Json::Value input, onis::aresult &res); void add_album_access_item(const
  onis::astring &from_seq, const Json::Value input, onis::aresult &res); void
  remove_partition_access_items(b32 is_role, const onis::astring &seq,
  onis::aresult &res); void find_partition_access_items(const onis::astring
  &access_seq, std::int32_t lockmode, b32 include_albums, Json::Value &output,
  onis::aresult &res); void create_partition_access_item_item(onis::odb_record
  &rec, Json::Value &output, onis::astring *item_seq, onis::aresult &res);
  void find_albums_access_items(const onis::astring &item_seq, std::int32_t
  lockmode, Json::Value &output, onis::aresult &res); void
  create_album_access_item_item(onis::odb_record &rec, Json::Value &output,
  onis::astring *item_seq, onis::aresult &res); void
  update_partition_access(b32 is_role, const onis::astring &seq, const
  Json::Value &partition_access, onis::aresult &res); void
  delete_partition_access(b32 is_role, const onis::astring &seq, onis::aresult
  &res);

  //dicom access:
  b32 find_dicom_access(b32 is_role, const onis::astring &seq, std::int32_t
  lockmode, Json::Value &output, onis::astring *access_seq, b32 include_items,
  onis::aresult &res); void create_dicom_access_item(onis::odb_record &rec,
  Json::Value &output, onis::astring *access_seq, onis::aresult &res); void
  create_dicom_access(b32 is_role, const onis::astring &seq, const Json::Value
  &input, std::int32_t lockmode, Json::Value &output, onis::astring *access_seq,
  onis::aresult &res); void remove_dicom_access_items(b32 is_role, const
  onis::astring &seq, onis::aresult &res); void add_dicom_access_item(const
  onis::astring &access_seq, const onis::astring &client_seq, onis::aresult
  &res); void find_dicom_access_items(const onis::astring &access_seq,
  std::int32_t lockmode, Json::Value &output, onis::aresult &res); void
  modify_dicom_access(b32 is_role, const onis::astring &seq, const Json::Value
  &input, onis::aresult &res); void update_dicom_access(b32 is_role, const
  onis::astring &seq, const Json::Value &dicom_access, onis::aresult &res);
  void delete_dicom_access(b32 is_role, const onis::astring &seq,
  onis::aresult &res);*/

  // albums:
  static std::string get_album_columns(std::uint32_t flags,
                                       bool add_table_name);
  void get_partition_albums(const std::string& partition_id,
                            std::uint32_t flags, lock_mode lock,
                            Json::Value& output) const;
  void read_album_record(onis_kit::database::database_row& rec,
                         std::uint32_t flags, std::string* partition_id,
                         json& output) const;

  // smart albums:
  static std::string get_smart_album_columns(std::uint32_t flags,
                                             bool add_table_name);
  void get_partition_smart_albums(const std::string& partition_id,
                                  std::uint32_t flags, lock_mode lock,
                                  Json::Value& output) const;
  void read_smart_album_record(onis_kit::database::database_row& rec,
                               std::uint32_t flags, std::string* partition_id,
                               Json::Value& output) const;

  // patients:
  static std::string get_patient_columns(std::uint32_t flags,
                                         bool add_table_name);
  void find_online_patients(const std::string& partition_seq,
                            const std::string& patient_id, std::uint32_t flags,
                            bool for_client, lock_mode lock,
                            Json::Value& patients);
  bool have_online_patient(const std::string& partition_seq,
                           const std::string& patient_id,
                           const std::string& name, const std::string& ideogram,
                           const std::string& phonetic, const std::string& sex,
                           const std::string& birthdate,
                           const std::string& birthtime);
  void find_patient_by_seq(const std::string& seq, std::uint32_t flags,
                           bool for_client, lock_mode lock_mode,
                           Json::Value& output, std::string* partition_seq);
  void create_patient_item(onis_kit::database::database_row& rec,
                           std::uint32_t flags, bool for_client,
                           std::string* partition_seq, Json::Value& patient,
                           std::int32_t* start_index);
  /*static void get_patient_info_to_insert(
      const onis::dicom_base_ptr& dataset, std::string* charset,
      std::string* name, std::string* ideo, std::string* phono,
      std::string* birthdate, std::string* birthtime, std::string* sex,
      onis::dicom_charset_info_list* used_charsets = NULL);*/
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
      Json::Value& patient);*/
  void modify_patient(const Json::Value& patient, std::uint32_t flags);
  void modify_patient_id(const std::string& seq, const std::string& pid);
  void delete_patient(const std::string& patient_seq);
  bool patient_have_studies(const std::string& patient_seq);
  bool some_studies_are_in_conflict_with_some_patient_study(
      const std::string& patient_seq);
  bool patient_have_studies_in_conflict(const std::string& patient_seq);

  // patient links:
  /*void find_partition_patient_link_by_seq(const onis::astring&
  patient_link_seq, s32 lock_mode, Json::Value& output, onis::aresult& res); b32
  get_partition_patient_link(const onis::astring& album_seq, const
  onis::astring& patient_seq, s32 lock_mode, Json::Value& output, onis::aresult&
  res); b32 get_partition_patient_from_link(const onis::astring&
  patient_link_seq, u32 flags, s32 lock_mode, Json::Value& output,
                                      onis::astring* partition_seq,
                                      onis::aresult& res);
  b32 get_partition_patient_link_from_patient_seq_in_album(
      const onis::astring& album_seq, const onis::astring& patient_seq,
      s32 lock_mode, Json::Value& output, onis::aresult& res);
  void get_partition_patient_links(const onis::astring& patient_seq,
                                   s32 lock_mode, Json::Value& output,
                                   onis::aresult& res);
  void add_partition_patient_link(const onis::astring& album_seq,
                                  const onis::astring& patient_seq,
                                  b32 all_studies, s32 study_count,
                                  s32 series_count, s32 image_count,
                                  Json::Value& output, onis::aresult& res);
  void create_partition_patient_link_item(onis::odb_record& rec,
                                          Json::Value& link,
                                          onis::aresult& res);
  void update_partition_patient_link(const Json::Value& patient_link,
                                     onis::aresult& res);
  void remove_partition_patient_links(const onis::astring& patient_seq,
                                      sdb_access_elements_info* info,
                                      onis::aresult& res);
  // void remove_partition_patient_link(const onis::astring &patient_link_seq,
  // b32 display_all_studies, onis::aresult &res);
  u64 count_study_links_related_with_patient_link(
      const onis::astring patient_link_seq, onis::aresult& res);
  // void get_patient_links(s64 patient_seq, partition_patient_link_list &list,
  // s32 lock_mode, oresult &result); partition_patient_link_ptr
  // get_patient_link(s64 seq, s32 lock_mode, oresult &result);
  // partition_patient_link_ptr get_patient_link(s64 sub_partition_seq, s64
  // patient_seq, s32 lock_mode, oresult &result); partition_patient_link_ptr
  // create_patient_link(odb_record &rec, oresult &result); void
  // update_patient_link(const partition_patient_link_ptr &link, oresult
  // &result); partition_patient_link_ptr add_patient_link(s64 sub_database_seq,
  // s64 patient_seq, b32 all_studies, s32 study_count, s32 series_count, s32
  // image_count, s32 report_count, onis::oresult &result);*/

  // studies:
  std::string get_study_columns(std::uint32_t flags, bool add_table_name);
  void create_study_item(onis_kit::database::database_row& rec,
                         std::uint32_t flags, bool for_client,
                         std::string* patient_seq, Json::Value& study,
                         std::int32_t* start_index);
  void create_patient_and_study_item(onis_kit::database::database_row& rec,
                                     std::uint32_t patient_flags,
                                     std::uint32_t study_flags, bool for_client,
                                     bool for_album, Json::Value& patient,
                                     Json::Value& study);

  /*void find_studies(const std::string& partition_seq,
                    bool reject_empty_request, std::int32_t limit,
                    const onis::dicom_file_ptr& dataset,
                    const onis::astring& code_page, b32 patient_root,
                    u32 patient_flags, u32 study_flags, b32 for_client,
                    s32 lock_mode, Json::Value& output, onis::aresult& res);*/
  void find_studies(const std::string& partition_seq, bool reject_empty_request,
                    std::int32_t limit, const Json::Value& filters,
                    std::uint32_t patient_flags, std::uint32_t study_flags,
                    bool for_client, lock_mode lock, Json::Value& output);
  void find_studies(const std::string& patient_seq, std::uint32_t flags,
                    bool for_client, lock_mode lock, Json::Value& output);
  /*bool decode_find_study_filters_from_dataset(
      const onis::dicom_file_ptr& dataset, const std::string& code_page,
      bool patient_root, Json::Value& filters);*/
  void find_online_studies(const std::string& patient_seq, std::uint32_t flags,
                           bool for_client, lock_mode lock,
                           Json::Value& output);
  /*void find_studies_from_album(const onis::astring& album_seq,
                               b32 reject_empty_request, s32 limit,
                               const onis::dicom_file_ptr& dataset,
                               const onis::astring& code_page, b32 patient_root,
                               u32 patient_flags, u32 study_flags,
                               b32 for_client, s32 lock_mode,
                               Json::Value& output, onis::aresult& res);
  void find_studies_from_album(const onis::astring& album_seq,
                               b32 reject_empty_request, s32 limit,
                               const Json::Value& filters, u32 patient_flags,
                               u32 study_flags, b32 for_client, s32 lock_mode,
                               Json::Value& output, onis::aresult& res);*/
  void find_study_by_seq(const std::string& partition_seq,
                         const std::string& study_seq,
                         std::uint32_t patient_flags, std::uint32_t study_flags,
                         bool for_client, lock_mode lock, Json::Value& output);
  void find_study_by_seq(const std::string& seq, std::uint32_t flags,
                         bool for_client, lock_mode lock, Json::Value& output,
                         std::string* patient_seq);
  bool find_study_patient(const std::string& study_seq,
                          std::uint32_t patient_flags, bool for_client,
                          lock_mode lock, Json::Value& output,
                          std::string* partition_seq);
  /*void create_study_item_from_album(onis::odb_record& rec, u32 flags,
                                    b32 for_client, Json::Value& study,
                                    s32* start_index, onis::aresult& res);
  void create_study_item(onis::odb_record& rec, u32 flags, b32 for_client,
                         onis::astring* patient_seq, Json::Value& study,
                         s32* start_index, onis::aresult& res);
  void create_patient_and_study_item(onis::odb_record& rec, u32 patient_flags,
                                     u32 study_flags, b32 for_client,
                                     b32 for_album, Json::Value& patient,
                                     Json::Value& study, onis::aresult& res);
  void find_online_and_conflicted_studies(const onis::astring& partition_seq,
                                          const onis::astring& study_uid,
                                          s32 lockmode, u32 patient_flags,
                                          u32 study_flags, b32 for_client,
                                          Json::Value& output,
                                          onis::aresult& res);
  void get_online_and_conflicted_studies(
      const onis::astring& partition_seq,
      const onis::astring& conflict_study_seq, u32 patient_flags,
      u32 study_flags, s32 for_client_online, s32 for_client_conflict,
      s32 lock_mode, Json::Value& online_study, Json::Value& conflict_study,
      onis::aresult& res);
  b32 study_has_conflicted_studies(const onis::astring& online_study_seq,
                                   onis::aresult& res);
  void create_study(
      const onis::astring& partition_seq, const Json::Value* conflict_study,
      const onis::astring& patient_seq, const onis::core::date_time& dt,
      const onis::astring& study_uid, const onis::dicom_base_ptr& dataset,
      const onis::astring& origin_id, const onis::astring& origin_name,
      const onis::astring& origin_ip, Json::Value& study, onis::aresult& res);
  void create_study(
      const onis::astring& partition_seq, const onis::astring& patient_seq,
      const onis::core::date_time& dt, const onis::astring& charset,
      const onis::astring& study_uid, const onis::astring& study_id,
      const onis::astring& accnum, const onis::astring& description,
      const onis::astring& institution, const onis::astring& study_date,
      const onis::astring& study_time, s32 series_count, s32 image_count,
      const onis::astring& origin_id, const onis::astring& origin_name,
      const onis::astring& origin_ip, Json::Value& study, onis::aresult& res);
  onis::astring create_study_insertion_string(
      const Json::Value* conflict_study, const onis::astring& partition_seq,
      const onis::astring& patient_seq, const onis::astring& uid,
      const onis::core::date_time& dt, const onis::dicom_base_ptr& dataset,
      const onis::astring& origin_id, const onis::astring& origin_name,
      const onis::astring& origin_ip, Json::Value& study);
  onis::astring create_study_insertion_string(
      const onis::astring& partition_seq, const onis::astring& patient_seq,
      const onis::core::date_time& dt, const onis::astring& charset,
      const onis::astring& study_uid, const onis::astring& study_id,
      const onis::astring& accnum, const onis::astring& description,
      const onis::astring& institution, const onis::astring& age,
      const onis::astring& study_date, const onis::astring& study_time,
      const onis::astring& modalities, const onis::astring& bodyparts,
      const onis::astring& stations, s32 series_count, s32 image_count,
      const onis::astring& origin_id, const onis::astring& origin_name,
      const onis::astring& origin_ip, const Json::Value* conflict_study,
      Json::Value& study);
  b32 update_study_modalities_bodyparts_and_station_names(
      Json::Value& study, const onis::astring& ignore_series_seq,
      onis::aresult& res);
  void modify_study(const Json::Value& study, u32 flags, onis::aresult& res);
  void modify_study_uid(const onis::astring& seq, const onis::astring& uid,
                        onis::aresult& res);
  onis::astring construct_study_filter_clause(const Json::Value& filters,
                                              b32 with_patient,
                                              b32& have_criteria);
  onis::astring prepare_for_like(const onis::astring& value);
  b32 compose_filter_clause(const Json::Value& filters,
                            const onis::astring& key,
                            const onis::astring& column,
                            onis::astring& filter_clause);
  b32 compose_filter_clause(const Json::Value& filters,
                            const onis::astring& key,
                            const onis::astring& column,
                            const onis::astring& separator,
                            onis::astring& filter_clause);
  b32 compose_name_filter_clause(const Json::Value& filters,
                                 const onis::astring& key,
                                 const onis::astring& column1,
                                 const onis::astring& column2,
                                 const onis::astring& column3,
                                 onis::astring& filter_clause);
  b32 compose_date_range_filter_clause(const Json::Value& filters,
                                       const onis::astring& key1,
                                       const onis::astring& key2,
                                       const onis::astring& column,
                                       onis::astring& filter_clause);
  void delete_study(const onis::astring& study_seq, onis::aresult& res);
  void switch_study_conflict_status(const onis::astring& online_study_seq,
                                    const onis::astring& conflict_study_seq,
                                    onis::aresult& res);
  u64 get_study_count(const onis::astring& patient_seq, onis::aresult& res);
  void set_studies_patient_seq(const onis::astring from_patient_seq,
                               const onis::astring& new_patient_seq,
                               onis::aresult& res);
  void attach_study_to_patient(const onis::astring& study_seq,
                               const onis::astring& patient_seq,
                               onis::aresult& res);
  void
  remove_studies_not_satisfying_the_modalities_bodyparts_and_station_filters(
      s32 offset, Json::Value& output, b32 have_patient,
      const Json::Value& filters, onis::aresult& res);

  // study links:
  void find_partition_study_link_by_seq(const onis::astring& study_link_seq,
                                        s32 lock_mode, Json::Value& output,
                                        onis::aresult& res);
  void add_partition_study_link(const onis::astring& patient_link_seq,
                                const onis::astring& study_seq, b32 all_series,
                                const onis::astring& modalities,
                                const onis::astring& bodyparts,
                                const onis::astring& stations, s32 series_count,
                                s32 image_count, s32 report_count,
                                Json::Value& output, onis::aresult& res);
  b32 get_partition_study_link(const onis::astring& patient_link_seq,
                               const onis::astring& study_seq, s32 lock_mode,
                               Json::Value& output, onis::aresult& res);
  b32 get_partition_study_link_from_study_seq_in_album(
      const onis::astring& album_seq, const onis::astring& study_seq,
      s32 lock_mode, Json::Value& output, onis::aresult& res);
  b32 get_partition_study_from_link(const onis::astring& study_link_seq,
                                    u32 flags, s32 lock_mode,
                                    Json::Value& output,
                                    onis::astring* study_patient_seq,
                                    onis::aresult& res);
  void get_partition_studies_from_patient_link(
      const onis::astring& patient_link_seq, b32 reject_empty_request,
      const Json::Value& filters, u32 flags, b32 for_client, s32 lock_mode,
      Json::Value& output, onis::aresult& res);
  void get_partition_study_links(const onis::astring& study_seq, s32 lock_mode,
                                 Json::Value& output, onis::aresult& res);
  void get_partition_study_links_from_patient_link(
      const onis::astring& patient_link_seq, s32 lock_mode, Json::Value& output,
      onis::aresult& res);
  void create_partition_study_link_item(onis::odb_record& rec,
                                        Json::Value& link, onis::aresult& res);
  void update_partition_study_link(const Json::Value& link, onis::aresult& res);
  b32 update_partition_study_link_modalities_bodyparts_and_stations(
      Json::Value& link,
      Json::Value* add_series /*, const Json::Value &remove_series*//*,
      onis::aresult& res);
  void get_series_from_study_link(const onis::astring& study_link,
                                  Json::Value& output, u32 flags,
                                  onis::aresult& res);
  void remove_partition_study_links(const onis::astring& study_seq,
                                    sdb_access_elements_info* info,
                                    onis::aresult& res);
  u64 count_series_links_related_with_study_link(
      const onis::astring study_link_seq, onis::aresult& res);*/

  // Utilities:
  std::unique_ptr<onis_kit::database::database_query> create_and_prepare_query(
      const std::string& columns, const std::string& from,
      const std::string& where, lock_mode lock, std::int32_t limit = 0) const;
  std::unique_ptr<onis_kit::database::database_result> execute_query(
      std::unique_ptr<onis_kit::database::database_query>& query) const;
  void execute_and_check_affected(
      std::unique_ptr<onis_kit::database::database_query>& query,
      const std::string& message) const;
  std::unique_ptr<onis_kit::database::database_query> prepare_query(
      const std::string& sql, const std::string& context) const;

  template <typename T>
  bool bind_parameter(
      std::unique_ptr<onis_kit::database::database_query>& query, int& index,
      const T& value, const std::string& param_name) {
    if (!query->bind_parameter(index, value)) {
      std::throw_with_nested(
          std::runtime_error("Failed to bind " + param_name + " parameter"));
    }
    index++;
    return true;
  }

private:
  std::unique_ptr<onis_kit::database::database_connection> connection_;
  std::unique_ptr<onis::database::sql_builder> sql_builder_;
};
