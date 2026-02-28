#pragma once

#include <json/json.h>
#include <memory>
#include <optional>
#include <string>
#include <vector>
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/database/database_interface.hpp"
#include "onis_kit/include/dicom/dicom.hpp"
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
  bool find_partition(const onis::astring &clause, std::uint32_t flags,
  std::uint32_t album_flags, std::uint32_t smart_album_flags, std::int32_t
  lock_mode, Json::Value &output, onis::astring *site_seq, onis::aresult
  &res);*/
  void find_partitions_for_site(const std::string& site_id, std::uint32_t flags,
                                std::uint32_t album_flags,
                                std::uint32_t smart_album_flags, lock_mode lock,
                                Json::Value& output);
  void find_partition_by_seq(const std::string& seq, std::uint32_t flags,
                             std::uint32_t album_flags,
                             std::uint32_t smart_album_flags, lock_mode lock,
                             std::string* site_seq, Json::Value& output);
  void find_partition_by_seq(const std::string& site_seq,
                             const std::string& seq, std::uint32_t flags,
                             std::uint32_t album_flags,
                             std::uint32_t smart_album_flags,
                             onis::database::lock_mode lock,
                             Json::Value& output);
  void read_partition_record(onis_kit::database::database_row& rec,
                             std::uint32_t flags, std::string* site_id,
                             json& output);
  void modify_partition(const Json::Value& partition, std::uint32_t flags);

  /*void create_partition_item(onis::odb_record &rec, std::uint32_t flags,
  onis::astring *site_seq, Json::Value &output, onis::aresult &res); void
  create_partition_item(onis::odb_record &rec, std::uint32_t flags,
  onis::astring *site_seq, Json::Value &output, std::int32_t &index,
  onis::aresult &res);  void find_partition_by_seq(const
  onis::astring &site_seq, const onis::astring &seq, std::uint32_t flags,
  std::uint32_t album_flags, std::uint32_t smart_album_flags, std::int32_t
  lock_mode, Json::Value &output, onis::aresult &res);  void
  create_partition(const onis::astring &site_seq, const Json::Value &input,
  Json::Value &output, std::uint32_t out_flags, onis::aresult &res); void
  find_partition_names_for_site(const onis::astring &site_seq,
  std::list<onis::astring> &list, onis::aresult &res); bool
  partition_have_conflict(const onis::astring &seq, onis::aresult &res); void
  delete_partition(const onis::astring &seq, onis::aresult &res); void
  transfer_images_to_album(const onis::astring &partition_seq, const
  onis::astring &album_seq, const onis::astring &patient_id, const
  onis::astring &patient_seq, const onis::astring &study_uid, const
  onis::astring &study_seq, const onis::astring &series_uid, const
  onis::astring &series_seq, const onis::astring &image_uid, const
  onis::astring &image_seq, onis::aresult &res);*/

  // partition access:
  /*bool find_partition_access(bool is_role, const onis::astring &seq,
  std::int32_t lockmode, Json::Value &output, onis::astring *access_seq, bool
  include_items, onis::aresult &res); void
  create_partition_access_item(onis::odb_record &rec, Json::Value &output,
  onis::astring *access_seq, onis::aresult &res); void
  create_partition_access(bool is_role, const onis::astring &seq, const
  Json::Value &input, std::int32_t lockmode, Json::Value &output, onis::astring
  *access_seq, onis::aresult &res); void modify_partition_access(bool is_role,
  const onis::astring &seq, const Json::Value &input, onis::aresult &res);
  void add_partition_access_item(const onis::astring &access_seq, const
  Json::Value input, onis::aresult &res); void add_album_access_item(const
  onis::astring &from_seq, const Json::Value input, onis::aresult &res); void
  remove_partition_access_items(bool is_role, const onis::astring &seq,
  onis::aresult &res); void find_partition_access_items(const onis::astring
  &access_seq, std::int32_t lockmode, bool include_albums, Json::Value &output,
  onis::aresult &res); void create_partition_access_item_item(onis::odb_record
  &rec, Json::Value &output, onis::astring *item_seq, onis::aresult &res);
  void find_albums_access_items(const onis::astring &item_seq, std::int32_t
  lockmode, Json::Value &output, onis::aresult &res); void
  create_album_access_item_item(onis::odb_record &rec, Json::Value &output,
  onis::astring *item_seq, onis::aresult &res); void
  update_partition_access(bool is_role, const onis::astring &seq, const
  Json::Value &partition_access, onis::aresult &res); void
  delete_partition_access(bool is_role, const onis::astring &seq, onis::aresult
  &res);

  //dicom access:
  bool find_dicom_access(bool is_role, const onis::astring &seq, std::int32_t
  lockmode, Json::Value &output, onis::astring *access_seq, bool include_items,
  onis::aresult &res); void create_dicom_access_item(onis::odb_record &rec,
  Json::Value &output, onis::astring *access_seq, onis::aresult &res); void
  create_dicom_access(bool is_role, const onis::astring &seq, const Json::Value
  &input, std::int32_t lockmode, Json::Value &output, onis::astring *access_seq,
  onis::aresult &res); void remove_dicom_access_items(bool is_role, const
  onis::astring &seq, onis::aresult &res); void add_dicom_access_item(const
  onis::astring &access_seq, const onis::astring &client_seq, onis::aresult
  &res); void find_dicom_access_items(const onis::astring &access_seq,
  std::int32_t lockmode, Json::Value &output, onis::aresult &res); void
  modify_dicom_access(bool is_role, const onis::astring &seq, const Json::Value
  &input, onis::aresult &res); void update_dicom_access(bool is_role, const
  onis::astring &seq, const Json::Value &dicom_access, onis::aresult &res);
  void delete_dicom_access(bool is_role, const onis::astring &seq,
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

  // compression:
  std::string get_compression_columns(std::uint32_t flags, bool add_table_name);
  void create_compression_item(onis_kit::database::database_row& rec,
                               std::uint32_t flags, std::string* partition_seq,
                               std::int32_t* start_index, json& output);
  /*void create_compression(const onis::astring& partition_seq,
                          onis::aresult& res);
  void find_compressions(const onis::astring& clause, u32 flags, s32 lock_mode,
                         Json::Value& output, onis::astring* partition_seq,
                         onis::aresult& res);
  b32 find_compression(const onis::astring& clause, u32 flags, s32 lock_mode,
                       Json::Value& output, onis::astring* partition_seq,
                       onis::aresult& res);
  void find_compression_by_seq(const onis::astring& seq, u32 flags,
                               s32 lock_mode, onis::astring* partition_seq,
                               Json::Value& output, onis::aresult& res);
  void find_compression_by_seq(const onis::astring& site_seq,
                               const onis::astring& seq, u32 flags,
                               s32 lock_mode, onis::astring* partition_seq,
                               Json::Value& output, onis::aresult& res);
  void modify_compression(const Json::Value& compression, u32 flags,
                          s32 updateIndex, onis::aresult& res);*/
  void get_partition_compressions(const std::string& partition_seq,
                                  std::uint32_t flags, lock_mode mode,
                                  Json::Value& output);
  /*void get_first_hundred_images_to_compress(onis::astring_list& images,
                                            onis::aresult& res);*/

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
  std::unique_ptr<onis_kit::database::database_query>
  create_patient_insertion_query(
      const std::string& partition_seq, const onis::core::date_time& dt,
      const std::string& default_pid, const onis::dicom_base_ptr& dataset,
      const std::string& origin_id, const std::string& origin_name,
      const std::string& origin_ip, Json::Value& patient);
  std::unique_ptr<onis_kit::database::database_query>
  create_patient_insertion_query(
      const std::string& partition_seq, const onis::core::date_time& dt,
      const std::string& charset, const std::string& pid,
      const std::string& name, const std::string& ideogram,
      const std::string& phonetic, const std::string& birthdate,
      const std::string birthtime, const std::string& sex,
      std::int32_t study_count, std::int32_t series_count,
      std::int32_t image_count, const std::string& origin_id,
      const std::string& origin_name, const std::string& origin_ip,
      Json::Value& patient);
  static void get_patient_info_to_insert(
      const onis::dicom_base_ptr& dataset, std::string* charset,
      std::string* name, std::string* ideo, std::string* phono,
      std::string* birthdate, std::string* birthtime, std::string* sex,
      onis::dicom_charset_info_list* used_charsets = nullptr);
  void create_patient(const std::string& partition_seq,
                      const onis::core::date_time& dt,
                      const std::string& default_pid,
                      const onis::dicom_base_ptr& dataset,
                      const std::string& origin_id,
                      const std::string& origin_name,
                      const std::string& origin_ip, Json::Value& patient);

  /*void create_patient(
    const std::string& partition_seq, const onis::core::date_time& dt,
    const onis::astring& charset, const onis::astring& pid,
    const onis::astring& name, const onis::astring& ideogram,
    const onis::astring& phonetic, const onis::astring& birthdate,
    const onis::astring birthtime, const onis::astring& sex, std::int32_t
study_count, std::int32_t series_count, std::int32_t image_count, const
onis::astring& origin_id, const onis::astring& origin_name, const
onis::astring& origin_ip, Json::Value& patient, onis::aresult& res);*/

  void modify_patient(const Json::Value& patient, std::uint32_t flags);
  /*void modify_patient_id(const std::string& seq, const std::string& pid);
  void delete_patient(const std::string& patient_seq);
  bool patient_have_studies(const std::string& patient_seq);
  bool some_studies_are_in_conflict_with_some_patient_study(
      const std::string& patient_seq);
  bool patient_have_studies_in_conflict(const std::string& patient_seq);*/

  // patient links:
  /*void find_partition_patient_link_by_seq(const onis::astring&
  patient_link_seq, std::int32_t lock_mode, Json::Value& output, onis::aresult&
  res); bool get_partition_patient_link(const onis::astring& album_seq, const
  onis::astring& patient_seq, std::int32_t lock_mode, Json::Value& output,
  onis::aresult& res); bool get_partition_patient_from_link(const onis::astring&
  patient_link_seq, std::uint32_t flags, std::int32_t lock_mode, Json::Value&
  output, onis::astring* partition_seq, onis::aresult& res); bool
  get_partition_patient_link_from_patient_seq_in_album( const onis::astring&
  album_seq, const onis::astring& patient_seq, std::int32_t lock_mode,
  Json::Value& output, onis::aresult& res); void
  get_partition_patient_links(const onis::astring& patient_seq, std::int32_t
  lock_mode, Json::Value& output, onis::aresult& res); void
  add_partition_patient_link(const onis::astring& album_seq, const
  onis::astring& patient_seq, bool all_studies, std::int32_t study_count,
                                  std::int32_t series_count, std::int32_t
  image_count, Json::Value& output, onis::aresult& res); void
  create_partition_patient_link_item(onis::odb_record& rec, Json::Value& link,
                                          onis::aresult& res);
  void update_partition_patient_link(const Json::Value& patient_link,
                                     onis::aresult& res);
  void remove_partition_patient_links(const onis::astring& patient_seq,
                                      sdb_access_elements_info* info,
                                      onis::aresult& res);
  // void remove_partition_patient_link(const onis::astring &patient_link_seq,
  // bool display_all_studies, onis::aresult &res);
  std::uint64_t count_study_links_related_with_patient_link(
      const onis::astring patient_link_seq, onis::aresult& res);
  // void get_patient_links(std::int64_t patient_seq,
  partition_patient_link_list &list,
  // std::int32_t lock_mode, oresult &result); partition_patient_link_ptr
  // get_patient_link(std::int64_t seq, std::int32_t lock_mode, oresult
  &result);
  // partition_patient_link_ptr get_patient_link(std::int64_t sub_partition_seq,
  std::int64_t
  // patient_seq, std::int32_t lock_mode, oresult &result);
  partition_patient_link_ptr
  // create_patient_link(odb_record &rec, oresult &result); void
  // update_patient_link(const partition_patient_link_ptr &link, oresult
  // &result); partition_patient_link_ptr add_patient_link(std::int64_t
  sub_database_seq,
  // std::int64_t patient_seq, bool all_studies, std::int32_t study_count,
  std::int32_t series_count, std::int32_t
  // image_count, std::int32_t report_count, onis::oresult &result);*/

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
                    const onis::astring& code_page, bool patient_root,
                    std::uint32_t patient_flags, std::uint32_t study_flags, bool
     for_client, std::int32_t lock_mode, Json::Value& output, onis::aresult&
     res);*/
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
                               bool reject_empty_request, std::int32_t limit,
                               const onis::dicom_file_ptr& dataset,
                               const onis::astring& code_page, bool
  patient_root, std::uint32_t patient_flags, std::uint32_t study_flags, bool
  for_client, std::int32_t lock_mode, Json::Value& output, onis::aresult& res);
  void find_studies_from_album(const onis::astring& album_seq, bool
  reject_empty_request, std::int32_t limit, const Json::Value& filters,
  std::uint32_t patient_flags, std::uint32_t study_flags, bool for_client,
  std::int32_t lock_mode, Json::Value& output, onis::aresult& res);*/
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
  void find_online_and_conflicted_studies(const std::string& partition_seq,
                                          const std::string& study_uid,
                                          lock_mode lock,
                                          std::uint32_t patient_flags,
                                          std::uint32_t study_flags,
                                          bool for_client, Json::Value& output);
  std::unique_ptr<onis_kit::database::database_query>
  create_study_insertion_query(
      const Json::Value* conflict_study, const std::string& partition_seq,
      const std::string& patient_seq, const std::string& uid,
      const onis::core::date_time& dt, const onis::dicom_base_ptr& dataset,
      const std::string& origin_id, const std::string& origin_name,
      const std::string& origin_ip, Json::Value& study);
  std::unique_ptr<onis_kit::database::database_query>
  create_study_insertion_query(
      const std::string& partition_seq, const std::string& patient_seq,
      const onis::core::date_time& dt, const std::string& charset,
      const std::string& study_uid, const std::string& study_id,
      const std::string& accnum, const std::string& description,
      const std::string& institution, const std::string& age,
      const std::string& study_date, const std::string& study_time,
      const std::string& modalities, const std::string& bodyparts,
      const std::string& comment, const std::string& stations,
      std::int32_t series_count, std::int32_t image_count,
      const std::string& origin_id, const std::string& origin_name,
      const std::string& origin_ip, const Json::Value* conflict_study,
      Json::Value& study);
  void create_study(
      const std::string& partition_seq, const Json::Value* conflict_study,
      const std::string& patient_seq, const onis::core::date_time& dt,
      const std::string& study_uid, const onis::dicom_base_ptr& dataset,
      const std::string& origin_id, const std::string& origin_name,
      const std::string& origin_ip, Json::Value& study);

  /*void create_study_item_from_album(onis::odb_record& rec, std::uint32_t
  flags, bool for_client, Json::Value& study, std::int32_t* start_index,
  onis::aresult& res); void create_study_item(onis::odb_record& rec,
  std::uint32_t flags, bool for_client, onis::astring* patient_seq, Json::Value&
  study, std::int32_t* start_index, onis::aresult& res); void
  create_patient_and_study_item(onis::odb_record& rec, std::uint32_t
  patient_flags, std::uint32_t study_flags, bool for_client, bool for_album,
  Json::Value& patient, Json::Value& study, onis::aresult& res);  void
  get_online_and_conflicted_studies( const onis::astring& partition_seq, const
  onis::astring& conflict_study_seq, std::uint32_t patient_flags, std::uint32_t
  study_flags, std::int32_t for_client_online, std::int32_t for_client_conflict,
  std::int32_t lock_mode, Json::Value& online_study, Json::Value&
  conflict_study, onis::aresult& res); bool study_has_conflicted_studies(const
  onis::astring& online_study_seq, onis::aresult& res);  void
  create_study( const onis::astring& partition_seq, const onis::astring&
  patient_seq, const onis::core::date_time& dt, const onis::astring& charset,
      const onis::astring& study_uid, const onis::astring& study_id,
      const onis::astring& accnum, const onis::astring& description,
      const onis::astring& institution, const onis::astring& study_date,
      const onis::astring& study_time, std::int32_t series_count, std::int32_t
  image_count, const onis::astring& origin_id, const onis::astring& origin_name,
      const onis::astring& origin_ip, Json::Value& study, onis::aresult& res);*/

  bool update_study_modalities_bodyparts_and_station_names(
      Json::Value& study, const std::string& ignore_series_seq);
  void modify_study(const Json::Value& study, std::uint32_t flags);

  std::string construct_study_filter_clause(const Json::Value& filters,
                                            bool with_patient,
                                            bool& have_criteria);
  bool compose_filter_clause(const Json::Value& filters, const std::string& key,
                             const std::string& column,
                             std::string& filter_clause);
  bool compose_filter_clause(const Json::Value& filters, const std::string& key,
                             const std::string& column,
                             const std::string& separator,
                             std::string& filter_clause);
  bool compose_date_range_filter_clause(const Json::Value& filters,
                                        const std::string& key1,
                                        const std::string& key2,
                                        const std::string& column,
                                        std::string& filter_clause);
  bool compose_name_filter_clause(const Json::Value& filters,
                                  const std::string& key,
                                  const std::string& column1,
                                  const std::string& column2,
                                  const std::string& column3,
                                  std::string& filter_clause);
  std::string prepare_for_like(const std::string& value);
  void bind_parameters_for_study_filter_clause(
      std::unique_ptr<onis_kit::database::database_query>& query,
      std::int32_t& index, const Json::Value& filters, bool with_patient);
  void bind_parameter_for_study_filter_clause(
      std::unique_ptr<onis_kit::database::database_query>& query,
      std::int32_t& index, const Json::Value& filters, const std::string& key);

  /*void modify_study_uid(const onis::astring& seq, const onis::astring& uid,
                        onis::aresult& res);


  onis::astring
  construct_study_filter_clause(const Json::Value& filters, bool with_patient,
                                              bool& have_criteria);
  onis::astring prepare_for_like(const onis::astring& value);
  bool compose_filter_clause(const Json::Value& filters,
                            const onis::astring& key,
                            const onis::astring& column,
                            onis::astring& filter_clause);
  bool compose_filter_clause(const Json::Value& filters,
                            const onis::astring& key,
                            const onis::astring& column,
                            const onis::astring& separator,
                            onis::astring& filter_clause);
  bool compose_name_filter_clause(const Json::Value& filters,
                                 const onis::astring& key,
                                 const onis::astring& column1,
                                 const onis::astring& column2,
                                 const onis::astring& column3,
                                 onis::astring& filter_clause);
  bool compose_date_range_filter_clause(const Json::Value& filters,
                                       const onis::astring& key1,
                                       const onis::astring& key2,
                                       const onis::astring& column,
                                       onis::astring& filter_clause);
  void delete_study(const onis::astring& study_seq, onis::aresult& res);
  void switch_study_conflict_status(const onis::astring& online_study_seq,
                                    const onis::astring& conflict_study_seq,
                                    onis::aresult& res);
  std::uint64_t get_study_count(const onis::astring& patient_seq, onis::aresult&
  res); void set_studies_patient_seq(const onis::astring from_patient_seq, const
  onis::astring& new_patient_seq, onis::aresult& res); void
  attach_study_to_patient(const onis::astring& study_seq, const onis::astring&
  patient_seq, onis::aresult& res); void
  remove_studies_not_satisfying_the_modalities_bodyparts_and_station_filters(
      std::int32_t offset, Json::Value& output, bool have_patient,
      const Json::Value& filters, onis::aresult& res);

  // study links:
  void find_partition_study_link_by_seq(const onis::astring& study_link_seq,
                                        std::int32_t lock_mode, Json::Value&
  output, onis::aresult& res); void add_partition_study_link(const
  onis::astring& patient_link_seq, const onis::astring& study_seq, bool
  all_series, const onis::astring& modalities, const onis::astring& bodyparts,
                                const onis::astring& stations, std::int32_t
  series_count, std::int32_t image_count, std::int32_t report_count,
                                Json::Value& output, onis::aresult& res);
  bool get_partition_study_link(const onis::astring& patient_link_seq,
                               const onis::astring& study_seq, std::int32_t
  lock_mode, Json::Value& output, onis::aresult& res); bool
  get_partition_study_link_from_study_seq_in_album( const onis::astring&
  album_seq, const onis::astring& study_seq, std::int32_t lock_mode,
  Json::Value& output, onis::aresult& res); bool
  get_partition_study_from_link(const onis::astring& study_link_seq,
                                    std::uint32_t flags, std::int32_t lock_mode,
                                    Json::Value& output,
                                    onis::astring* study_patient_seq,
                                    onis::aresult& res);
  void get_partition_studies_from_patient_link(
      const onis::astring& patient_link_seq, bool reject_empty_request,
      const Json::Value& filters, std::uint32_t flags, bool for_client,
  std::int32_t lock_mode, Json::Value& output, onis::aresult& res); void
  get_partition_study_links(const onis::astring& study_seq, std::int32_t
  lock_mode, Json::Value& output, onis::aresult& res); void
  get_partition_study_links_from_patient_link( const onis::astring&
  patient_link_seq, std::int32_t lock_mode, Json::Value& output, onis::aresult&
  res); void create_partition_study_link_item(onis::odb_record& rec,
                                        Json::Value& link, onis::aresult& res);
  void update_partition_study_link(const Json::Value& link, onis::aresult& res);
  bool update_partition_study_link_modalities_bodyparts_and_stations(
      Json::Value& link,
      Json::Value* add_series ,
      onis::aresult& res);
  void get_series_from_study_link(const onis::astring& study_link,
                                  Json::Value& output, std::uint32_t flags,
                                  onis::aresult& res);
  void remove_partition_study_links(const onis::astring& study_seq,
                                    sdb_access_elements_info* info,
                                    onis::aresult& res);
  std::uint64_t count_series_links_related_with_study_link(
      const onis::astring study_link_seq, onis::aresult& res);*/

  // Series:
  std::string get_series_columns(std::uint32_t flags, bool add_table_name);
  void create_series_item(onis_kit::database::database_row& rec,
                          std::uint32_t flags, bool for_client,
                          std::int32_t* index, std::string* study_seq,
                          Json::Value& series);
  bool get_online_series(const std::string& study_seq,
                         const std::string& series_uid, std::uint32_t flags,
                         bool for_client, lock_mode lock, Json::Value& output);
  void find_series(const std::string& study_seq, std::uint32_t flags,
                   bool for_client, lock_mode lock, Json::Value& output);
  /*void find_series(const onis::astring& partition_seq,
                   const onis::dicom_file_ptr& dataset,
                   const onis::astring& code_page, b32 patient_root, u32 flags,
                   b32 for_client, s32 lock_mode, Json::Value& output,
                   onis::aresult& res);
  void find_series(const onis::astring& partition_seq,
                   const onis::astring& pseq, const onis::astring& pid,
                   const onis::astring& stseq, const onis::astring& stuid,
                   const Json::Value& filters, u32 flags, b32 for_client,
                   s32 lock_mode, Json::Value& output, onis::aresult& res);
  void find_series(const onis::astring& study_seq, const Json::Value& filters,
                   u32 flags, b32 for_client, s32 lock_mode,
                   Json::Value& output, onis::aresult& res);
  void find_series_from_album(const onis::astring& partition_seq,
                              const onis::astring& album_seq,
                              const onis::dicom_file_ptr& dataset,
                              const onis::astring& code_page, b32 patient_root,
                              u32 flags, b32 for_client, s32 lock_mode,
                              Json::Value& output, onis::aresult& res);
  void find_series_from_album(
      const onis::astring& partition_seq, const onis::astring& album_seq,
      const onis::astring& pseq, const onis::astring& pid,
      const onis::astring& stseq, const onis::astring& stuid,
      const Json::Value& filters, u32 flags, b32 for_client, s32 lock_mode,
      Json::Value& output, onis::aresult& res);
  b32 decode_find_series_filters_from_dataset(
      const onis::dicom_file_ptr& dataset, const onis::astring code_page,
      b32 include_pid_and_study_uid, Json::Value& filters);
  void find_online_series(const onis::astring& study_seq, u32 flags,
                          b32 for_client, s32 lock_mode, Json::Value& output,
                          onis::aresult& res);
  b32 find_single_series(const onis::astring& clause, u32 flags,
                         b32 for_clients, s32 lock_mode, Json::Value& output,
                         onis::astring* study_seq, onis::aresult& res);
  void find_series_by_seq(const onis::astring& seq, u32 flags, b32 for_client,
                          s32 lock_mode, Json::Value& output,
                          onis::astring* study_seq, onis::aresult& res);
  b32 find_series_study(const onis::astring& series_seq, u32 study_flags,
                        b32 for_client, s32 lock_mode, Json::Value& output,
                        onis::aresult& res);*/
  void create_series(const std::string& study_seq,
                     const onis::core::date_time& dt,
                     const onis::dicom_base_ptr& dataset, bool create_icon,
                     const std::string& origin_id,
                     const std::string& origin_name,
                     const std::string& origin_ip, Json::Value& series);
  /*void create_series(
      const onis::astring& study_seq, const onis::core::date_time& dt,
      const onis::astring& charset, const onis::astring& series_uid,
      const onis::astring& series_date, const onis::astring& series_time,
      const onis::astring& modality, const onis::astring& srnum,
      const onis::astring& bodypart, const onis::astring& description,
      const onis::astring& station, b32 create_icon,
      const onis::astring& origin_id, const onis::astring& origin_name,
      const onis::astring& origin_ip, Json::Value& series, onis::aresult&
     res);*/
  std::unique_ptr<onis_kit::database::database_query>
  create_series_insertion_query(const std::string& study_seq,
                                const onis::core::date_time& dt,
                                const onis::dicom_base_ptr& dataset,
                                bool create_icon, const std::string& origin_id,
                                const std::string& origin_name,
                                const std::string& origin_ip,
                                Json::Value& series);
  std::unique_ptr<onis_kit::database::database_query>
  create_series_insertion_query(
      const std::string& study_seq, const onis::core::date_time& dt,
      const std::string& charset, const std::string& series_uid,
      const std::string& series_date, const std::string& series_time,
      const std::string& modality, const std::string& srnum,
      const std::string& bodypart, const std::string& description,
      const std::string& station, bool create_icon,
      const std::string& origin_id, const std::string& origin_name,
      const std::string& origin_ip, Json::Value& series);
  void modify_series(const Json::Value& series, std::uint32_t flags);
  /* void modify_series_uid(const onis::astring& seq, const onis::astring&
  uid, onis::aresult& res); void attach_series_to_study(const onis::astring&
  series_seq, const onis::astring& study_seq, onis::aresult& res); void
  delete_series_from_study(const onis::astring& study_seq, onis::aresult& res);
  u64 get_series_count(const onis::astring& study_seq, onis::aresult& res);
  onis::astring construct_series_filter_clause(const Json::Value& filters);
  // void find_series(const onis::astring &clause, b32 with_details, s32
  // lock_mode, std::list<Json::Value *> &list, onis::astring *study_seq,
  // onis::aresult &res); Json::Value *get_online_series(const onis::astring
  // &study_seq, const onis::astring &series_uid, b32 with_details, s32
  // lock_mode, onis::aresult &res); static onis::server::aseries_ptr
  // create_series(Json::Value &value); void create_series(const onis::astring
  // &study_seq, const onis::core::date_time &dt, const onis::dicom_base_ptr
  // &dataset, Json::Value &series, onis::aresult &res); onis::astring
  // create_series_insertion_string(const onis::astring &study_seq, const
  // onis::core::date_time &dt, const onis::dicom_base_ptr &dataset, Json::Value
  // &series); Json::Value *create_series_item(onis::odb_record &rec, b32
  // with_details, onis::astring *study_seq, onis::aresult &res); void

  // series:
  std::string get_series_columns(std::uint32_t flags, bool add_table_name);
  void create_series_item(onis_kit::database::database_row& rec,
                          std::uint32_t flags, bool for_client,
                          std::int32_t* index, std::string* study_seq,
                          Json::Value& series);
  void find_series(const onis::astring& clause, u32 flags, b32 for_client,
                   s32 lock_mode, Json::Value& list, onis::astring* study_seq,
                   onis::aresult& res);
  void find_series(const onis::astring& study_seq, u32 flags, b32 for_client,
                   s32 lock_mode, Json::Value& output, onis::aresult& res);
  void find_series(const onis::astring& partition_seq,
                   const onis::dicom_file_ptr& dataset,
                   const onis::astring& code_page, b32 patient_root, u32 flags,
                   b32 for_client, s32 lock_mode, Json::Value& output,
                   onis::aresult& res);
  void find_series(const onis::astring& partition_seq,
                   const onis::astring& pseq, const onis::astring& pid,
                   const onis::astring& stseq, const onis::astring& stuid,
                   const Json::Value& filters, u32 flags, b32 for_client,
                   s32 lock_mode, Json::Value& output, onis::aresult& res);
  void find_series(const onis::astring& study_seq, const Json::Value& filters,
                   u32 flags, b32 for_client, s32 lock_mode,
                   Json::Value& output, onis::aresult& res);
  void find_series_from_album(const onis::astring& partition_seq,
                              const onis::astring& album_seq,
                              const onis::dicom_file_ptr& dataset,
                              const onis::astring& code_page, b32 patient_root,
                              u32 flags, b32 for_client, s32 lock_mode,
                              Json::Value& output, onis::aresult& res);
  void find_series_from_album(
      const onis::astring& partition_seq, const onis::astring& album_seq,
      const onis::astring& pseq, const onis::astring& pid,
      const onis::astring& stseq, const onis::astring& stuid,
      const Json::Value& filters, u32 flags, b32 for_client, s32 lock_mode,
      Json::Value& output, onis::aresult& res);
  b32 decode_find_series_filters_from_dataset(
      const onis::dicom_file_ptr& dataset, const onis::astring code_page,
      b32 include_pid_and_study_uid, Json::Value& filters);
  void find_online_series(const onis::astring& study_seq, u32 flags,
                          b32 for_client, s32 lock_mode, Json::Value& output,
                          onis::aresult& res);
  b32 find_single_series(const onis::astring& clause, u32 flags,
                         b32 for_clients, s32 lock_mode, Json::Value& output,
                         onis::astring* study_seq, onis::aresult& res);
  void find_series_by_seq(const onis::astring& seq, u32 flags, b32 for_client,
                          s32 lock_mode, Json::Value& output,
                          onis::astring* study_seq, onis::aresult& res);
  b32 find_series_study(const onis::astring& series_seq, u32 study_flags,
                        b32 for_client, s32 lock_mode, Json::Value& output,
                        onis::aresult& res);
  */

  void find_online_series(const std::string& study_seq, std::uint32_t flags,
                          bool for_client, lock_mode lock, Json::Value& output);

  /*void create_series(const onis::astring& study_seq,
                     const onis::core::date_time& dt,
                     const onis::dicom_base_ptr& dataset, b32 create_icon,
                     const onis::astring& origin_id,
                     const onis::astring& origin_name,
                     const onis::astring& origin_ip, Json::Value& series,
                     onis::aresult& res);
  void create_series(
      const onis::astring& study_seq, const onis::core::date_time& dt,
      const onis::astring& charset, const onis::astring& series_uid,
      const onis::astring& series_date, const onis::astring& series_time,
      const onis::astring& modality, const onis::astring& srnum,
      const onis::astring& bodypart, const onis::astring& description,
      const onis::astring& station, b32 create_icon,
      const onis::astring& origin_id, const onis::astring& origin_name,
      const onis::astring& origin_ip, Json::Value& series, onis::aresult&
  res); onis::astring create_series_insertion_string( const onis::astring&
  study_seq, const onis::core::date_time& dt, const onis::dicom_base_ptr&
  dataset, b32 create_icon, const onis::astring& origin_id, const
  onis::astring& origin_name, const onis::astring& origin_ip, Json::Value&
  series); onis::astring create_series_insertion_string( const
  onis::astring& study_seq, const onis::core::date_time& dt, const
  onis::astring& charset, const onis::astring& series_uid, const
  onis::astring& series_date, const onis::astring& series_time, const
  onis::astring& modality, const onis::astring& srnum, const onis::astring&
  bodypart, const onis::astring& description, const onis::astring& station,
  b32 create_icon, const onis::astring& origin_id, const onis::astring&
  origin_name, const onis::astring& origin_ip, Json::Value& series); void
  modify_series(const Json::Value& series, u32 flags, onis::aresult& res);
  void modify_series_uid(const onis::astring& seq, const onis::astring& uid,
                         onis::aresult& res);
  void attach_series_to_study(const onis::astring& series_seq,
                              const onis::astring& study_seq,
                              onis::aresult& res);
  void delete_series_from_study(const onis::astring& study_seq,
                                onis::aresult& res);
  u64 get_series_count(const onis::astring& study_seq, onis::aresult& res);
  onis::astring construct_series_filter_clause(const Json::Value&
  filters);*/

  // Images:
  std::string get_image_columns(std::uint32_t flags, bool add_table_name);
  void create_image_item(onis_kit::database::database_row& rec,
                         std::uint32_t flags, bool for_client,
                         std::int32_t* index, std::string* series_seq,
                         Json::Value& image);
  /*
  void find_images(const onis::astring& clause, u32 flags, b32 for_client,
                   s32 lock_mode, Json::Value& list, onis::astring*
  series_seq, onis::aresult& res); void find_images(const onis::astring&
  series_seq, u32 flags, b32 for_client, s32 lock_mode, Json::Value& output,
  onis::aresult& res); void find_images(const onis::astring& partition_seq,
                   const onis::dicom_file_ptr& dataset,
                   const onis::astring& code_page, b32 patient_root, u32
  flags, b32 for_client, s32 lock_mode, Json::Value& output, onis::aresult&
  res); void find_images(const onis::astring& partition_seq, const
  onis::astring& pseq, const onis::astring& pid, const onis::astring& stseq,
  const onis::astring& stuid, const onis::astring& srseq, const
  onis::astring& sruid, const Json::Value& filters, u32 flags, b32
  for_client, s32 lock_mode, Json::Value& output, onis::aresult& res); void
  find_images(const onis::astring& series_seq, const Json::Value& filters,
                   u32 flags, b32 for_client, s32 lock_mode,
                   Json::Value& output, onis::aresult& res);
  void find_images_from_album(const onis::astring& partition_seq,
                              const onis::astring& album_seq,
                              const onis::dicom_file_ptr& dataset,
                              const onis::astring& code_page, b32
  patient_root, u32 flags, b32 for_client, s32 lock_mode, Json::Value&
  output, onis::aresult& res); void find_images_from_album( const
  onis::astring& partition_seq, const onis::astring& album_seq, const
  onis::astring& pseq, const onis::astring& pid, const onis::astring& stseq,
  const onis::astring& stuid, const onis::astring& srseq, const
  onis::astring& sruid, const Json::Value& filters, u32 flags, b32
  for_client, s32 lock_mode, Json::Value& output, onis::aresult& res); b32
  decode_find_image_filters_from_dataset( const onis::dicom_file_ptr&
  dataset, const onis::astring code_page, b32 include_pid_and_study_uid,
  Json::Value& filters); void find_online_images(const onis::astring&
  series_seq, u32 flags, b32 for_client, s32 lock_mode, Json::Value& output,
                          onis::aresult& res);
  void find_image_by_seq(const onis::astring& seq, u32 flags, b32
  for_client, s32 lock_mode, Json::Value& output, onis::astring* series_seq,
  onis::aresult& res); b32 find_image_series(const onis::astring& image_seq,
  u32 series_flags, b32 for_client, s32 lock_mode, Json::Value& output,
                        onis::aresult& res);
  b32 find_single_image(const onis::astring& clause, u32 flags, b32
  for_client, s32 lock_mode, Json::Value& output, onis::astring* series_seq,
  onis::aresult& res);*/
  bool check_if_sop_already_exist_under_online_or_conflicted_study(
      const std::string& sop, const Json::Value& studies);
  void create_image(
      std::int32_t compression_status, std::int32_t compression_update,
      const std::string& series_seq, const onis::core::date_time& dt,
      const onis::dicom_base_ptr& dataset, std::int32_t image_media,
      const std::string& image_path, bool create_stream, bool create_icon,
      const std::string& origin_id, const std::string& origin_name,
      const std::string& origin_ip, Json::Value& image);
  std::unique_ptr<onis_kit::database::database_query>
  create_image_insertion_query(
      std::int32_t compression_status, std::int32_t compression_update,
      const std::string& series_seq, const onis::core::date_time& dt,
      const onis::dicom_base_ptr& dataset, std::int32_t image_media,
      const std::string& image_path, bool create_stream, bool create_icon,
      const std::string& origin_id, const std::string& origin_name,
      const std::string& origin_ip, Json::Value& image);
  /*void modify_image(const Json::Value& image, u32 flags, onis::aresult& res);
  void modify_image_uid(const onis::astring& seq, const onis::astring& uid,
                        onis::aresult& res);
  void delete_images_from_series(const onis::astring& series_seq,
                                 onis::aresult& res);
  u64 get_image_count(const onis::astring& series_seq, onis::aresult& res);
  void attach_image_to_series(const onis::astring& image_seq,
                              const onis::astring& series_seq,
                              onis::aresult& res);
  void update_albums_after_adding_images(const Json::Value& patient,
                                         const Json::Value& study,
                                         const Json::Value& series,
                                         b32 series_created, s32 image_count,
                                         onis::aresult& res);
  void update_albums(sdb_access_elements_info* info, onis::aresult& res);
  onis::astring construct_image_filter_clause(const Json::Value& filters);
  void get_origin_id_and_origin_name(const onis::astring& partition_seq,
                                     onis::astring& origin_id,
                                     onis::astring& origin_name,
                                     onis::aresult& res);
  s32 get_image_compression_update_index(const onis::astring& image_id,
                                         onis::aresult& res);*/

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
  void bind_parameter(
      std::unique_ptr<onis_kit::database::database_query>& query, int& index,
      const T& value, const std::string& param_name) {
    if (!query) {
      throw std::runtime_error("Query is null when binding " + param_name +
                               " parameter");
    }
    try {
      if (!query->bind_parameter(index, value)) {
        throw std::runtime_error("Failed to bind " + param_name +
                                 " parameter (index " + std::to_string(index) +
                                 ")");
      }
    } catch (const std::exception& e) {
      std::throw_with_nested(
          std::runtime_error("Exception while binding " + param_name +
                             " parameter: " + std::string(e.what())));
    } catch (...) {
      throw std::runtime_error("Unknown exception while binding " + param_name +
                               " parameter");
    }
    index++;
  }

  // Specialization for nullptr
  void bind_parameter(
      std::unique_ptr<onis_kit::database::database_query>& query, int& index,
      std::nullptr_t, const std::string& param_name) {
    if (!query) {
      throw std::runtime_error("Query is null when binding " + param_name +
                               " parameter");
    }
    try {
      if (!query->bind_parameter(index, nullptr)) {
        throw std::runtime_error("Failed to bind " + param_name +
                                 " parameter (index " + std::to_string(index) +
                                 ")");
      }
    } catch (const std::exception& e) {
      std::throw_with_nested(
          std::runtime_error("Exception while binding " + param_name +
                             " parameter: " + std::string(e.what())));
    } catch (...) {
      throw std::runtime_error("Unknown exception while binding " + param_name +
                               " parameter");
    }
    index++;
  }

  // Overload for nullable string pointer (binds NULL if pointer is null or
  // string is empty)
  void bind_parameter(
      std::unique_ptr<onis_kit::database::database_query>& query, int& index,
      const std::string* value, const std::string& param_name) {
    if (!value || value->empty()) {
      bind_parameter(query, index, nullptr, param_name);
    } else {
      bind_parameter(query, index, *value, param_name);
    }
  }

  // Overload for string that binds NULL if empty
  void bind_parameter_optional(
      std::unique_ptr<onis_kit::database::database_query>& query, int& index,
      const std::string& value, const std::string& param_name) {
    if (value.empty()) {
      bind_parameter(query, index, nullptr, param_name);
    } else {
      bind_parameter(query, index, value, param_name);
    }
  }

  // Transaction management
  void begin_transaction();
  void commit();
  void rollback();
  bool in_transaction() const;
  void commit_or_rollback_transaction();

private:
  std::unique_ptr<onis_kit::database::database_connection> connection_;
  std::unique_ptr<onis::database::sql_builder> sql_builder_;
};
