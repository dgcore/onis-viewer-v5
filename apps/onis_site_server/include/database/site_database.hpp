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

  // Utilities:
  std::unique_ptr<onis_kit::database::database_query> create_and_prepare_query(
      const std::string& columns, const std::string& from,
      const std::string& where, lock_mode lock) const;
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
