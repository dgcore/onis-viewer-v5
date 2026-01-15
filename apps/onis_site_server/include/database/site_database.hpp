#pragma once

#include <memory>
#include <nlohmann/json.hpp>
#include <optional>
#include <string>
#include <vector>
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/database/database_interface.hpp"
#include "sql_builder.hpp"

using namespace dgc;
using json = nlohmann::json;
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
  std::string get_organization_columns(u32 flags, bool add_table_name = false);
  void read_organization_record(onis_kit::database::database_row& rec,
                                u32 flags, json& output);
  void find_organization_by_seq(const std::string& seq, u32 flags,
                                lock_mode lock, json& output);

  // Site operations
  std::string get_site_columns(u32 flags, bool add_table_name = false);
  void read_site_record(onis_kit::database::database_row& rec, u32 flags,
                        std::string* org_seq, json& output);
  void lock_site(const std::string& seq, lock_mode lock);
  void find_site_by_seq(const std::string& seq, u32 flags, lock_mode lock,
                        std::string* org_seq, json& output);
  void find_single_site(u32 flags, lock_mode lock, std::string* org_seq,
                        json& output);

  // Volume operations
  std::string get_volume_columns(u32 flags, bool add_table_name = false);
  void read_volume_record(onis_kit::database::database_row& rec, u32 flags,
                          std::string* site_seq, json& output);
  void find_volume_by_seq(const std::string& seq, u32 flags, lock_mode lock,
                          std::string* site_seq, json& output);
  void find_volume_by_seq(const std::string& site_seq, const std::string& seq,
                          u32 flags, lock_mode lock, json& output);
  void find_volumes_for_site(const std::string& site_seq, u32 flags,
                             lock_mode mode, json& output);
  void create_volume(const std::string& site_seq, const json& input,
                     json& output, u32 out_flags);
  void modify_volume(const json& volume);
  void delete_volume(const std::string& seq);

  // Media operations:
  std::string get_media_columns(u32 flags, bool add_table_name = false);
  void read_media_record(onis_kit::database::database_row& rec, u32 flags,
                         std::string* site_seq, std::string* volume_seq,
                         json& output);
  void get_volume_media_list(const std::string& volume_seq, u32 flags,
                             lock_mode lock, json& output);

  // roles:
  std::string get_role_columns(u32 flags, bool add_table_name);
  void read_role_record(onis_kit::database::database_row& rec, u32 flags,
                        std::string* site_seq, json& output);
  void find_role_by_seq(const std::string& seq, u32 flags, lock_mode lock,
                        std::string* site_seq, json& output);
  void find_role_by_seq(const std::string& site_seq, const std::string& seq,
                        u32 flags, lock_mode lock, json& output);
  void find_roles_for_site(const std::string& site_seq, u32 flags,
                           lock_mode lock, json& output);
  void create_role(const std::string& site_seq, const json& input, json& output,
                   u32 out_flags);
  void modify_role(const json& role);
  void delete_role(const std::string& seq);
  void get_role_membership(const std::string& seq, json& output);
  void check_circular_membership(const std::string& parent_id,
                                 const std::string& child_id);
  void get_role_permissions(const std::string& seq, json& output);
  std::string find_role_permission_seq(const std::string& name);
  void create_role_permission_value(const std::string& role_seq,
                                    const std::string& permission_id,
                                    s32 value);
  void modify_role_permission_value(const std::string& role_seq,
                                    const std::string& permission_seq,
                                    s32 value, bool create);

  // permissions:
  void find_permissions_items(json& output, u32 flags);
  bool exist_permission(bool role, const std::string& seq,
                        const std::string& permission_seq);

  // groups:
  std::string get_group_columns(u32 flags, bool add_table_name);
  void read_group_record(onis_kit::database::database_row& rec, u32 flags,
                         std::string* site_seq, json& output);

  // users:
  std::string get_user_columns(u32 flags, bool add_table_name);
  void read_user_record(onis_kit::database::database_row& rec, u32 flags,
                        bool need_password, std::string* site_seq,
                        json& output);
  void find_user_for_session(const std::string& site_seq,
                             const std::string& login,
                             const std::string& password, u32 flags,
                             json& output);
  void get_user_membership(const std::string& seq, json& output);
  void get_user_permissions(const std::string& seq, json& output);

  // Utilities:
  std::unique_ptr<onis_kit::database::database_query> create_and_prepare_query(
      const std::string& columns, const std::string& from,
      const std::string& where, lock_mode lock);
  std::unique_ptr<onis_kit::database::database_result> execute_query(
      std::unique_ptr<onis_kit::database::database_query>& query);
  void execute_and_check_affected(
      std::unique_ptr<onis_kit::database::database_query>& query,
      const std::string& message);
  std::unique_ptr<onis_kit::database::database_query> prepare_query(
      const std::string& sql, const std::string& context);

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