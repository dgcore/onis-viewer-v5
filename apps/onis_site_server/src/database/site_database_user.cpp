#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_user.hpp"
#include "../../include/database/site_database.hpp"
#include "../../include/exceptions/site_server_exceptions.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// User operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_user_columns(u32 flags, bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_users." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "site_id, " + prefix + "login, " +
           prefix + "password, " + prefix + "active, " + prefix + "inherit, " +
           prefix + "superuser, " + prefix + "inherit_pref, " + prefix +
           "shared_pref_id, " + prefix + "pref_id, " + prefix +
           "family_name, " + prefix + "first_name, " + prefix + "prefix, " +
           prefix + "suffix, " + prefix + "organization, " + prefix +
           "address1, " + prefix + "address2, " + prefix + "city, " + prefix +
           "zip, " + prefix + "country, " + prefix + "email, " + prefix +
           "fax, " + prefix + "phone";
  }

  std::string columns = prefix + "id, " + prefix + "site_id";
  if (flags & onis::database::info_user_login)
    columns += ", " + prefix + "login";
  if (flags & onis::database::info_user_password)
    columns += ", " + prefix + "password";
  if (flags & onis::database::info_user_active)
    columns += ", " + prefix + "active";
  if (flags & onis::database::info_user_inherit)
    columns += ", " + prefix + "inherit";
  if (flags & onis::database::info_user_superuser)
    columns += ", " + prefix + "superuser";
  if (flags & onis::database::info_user_pref_set)
    columns += ", " + prefix + "inherit_pref, " + prefix + "shared_pref_id, " +
               prefix + "pref_id";
  if (flags & onis::database::info_user_identity)
    columns += ", " + prefix + "family_name, " + prefix + "first_name, " +
               prefix + "prefix, " + prefix + "suffix";
  if (flags & onis::database::info_user_organization)
    columns += ", " + prefix + "organization";
  if (flags & onis::database::info_user_address)
    columns += ", " + prefix + "address1, " + prefix + "address2, " + prefix +
               "city, " + prefix + "zip, " + prefix + "country";
  if (flags & onis::database::info_user_contact)
    columns += ", " + prefix + "email, " + prefix + "fax, " + prefix + "phone";
  return columns;
}

void site_database::read_user_record(onis_kit::database::database_row& rec,
                                     u32 flags, bool need_password,
                                     std::string* site_seq, json& output) {
  onis::database::user::create(output, flags);
  output[BASE_SEQ_KEY] = rec.get_uuid("id", false, false);
  if (site_seq) {
    *site_seq = rec.get_uuid("site_id", false, false);
  }
  if (flags & onis::database::info_user_login) {
    output[US_LOGIN_KEY] = rec.get_string(US_LOGIN_KEY, false, false);
  }
  if (flags & onis::database::info_user_password) {
    if (need_password)
      output[US_PASSWORD_KEY] = rec.get_string(US_PASSWORD_KEY, false, false);
    else
      output[US_PASSWORD_KEY] = "xxxxxxxxxx";
  }
  if (flags & onis::database::info_user_active) {
    output[US_ACTIVE_KEY] = rec.get_int(US_ACTIVE_KEY, false);
  }
  if (flags & onis::database::info_user_inherit) {
    output[US_INHERIT_KEY] = rec.get_int(US_INHERIT_KEY, false);
  }
  if (flags & onis::database::info_user_superuser) {
    output[US_SUPERUSER_KEY] = rec.get_int(US_SUPERUSER_KEY, false);
  }
  if (flags & onis::database::info_user_pref_set) {
    output[US_PREFSET_INHERIT_KEY] = rec.get_int(US_PREFSET_INHERIT_KEY, false);
    output[US_PREFSET_SHARED_ID_KEY] =
        rec.get_string(US_PREFSET_SHARED_ID_KEY, true, true);
    output[US_PREFSET_ID_KEY] = rec.get_string(US_PREFSET_ID_KEY, true, true);
  }
  if (flags & onis::database::info_user_identity) {
    output[US_FAMILY_NAME_KEY] = rec.get_string(US_FAMILY_NAME_KEY, true, true);
    output[US_FIRST_NAME_KEY] = rec.get_string(US_FIRST_NAME_KEY, true, true);
    output[US_PREFIX_KEY] = rec.get_string(US_PREFIX_KEY, true, true);
    output[US_SUFFIX_KEY] = rec.get_string(US_SUFFIX_KEY, true, true);
  }
  if (flags & onis::database::info_user_organization) {
    output[US_ORGANIZATION_KEY] =
        rec.get_string(US_ORGANIZATION_KEY, true, true);
  }
  if (flags & onis::database::info_user_address) {
    output[US_ADDRESS1_KEY] = rec.get_string(US_ADDRESS1_KEY, true, true);
    output[US_ADDRESS2_KEY] = rec.get_string(US_ADDRESS2_KEY, true, true);
    output[US_CITY_KEY] = rec.get_string(US_CITY_KEY, true, true);
    output[US_ZIPCODE_KEY] = rec.get_string(US_ZIPCODE_KEY, true, true);
    output[US_COUNTRY_KEY] = rec.get_string(US_COUNTRY_KEY, true, true);
  }
  if (flags & onis::database::info_user_contact) {
    output[US_EMAIL_KEY] = rec.get_string(US_EMAIL_KEY, true, true);
    output[US_FAX_KEY] = rec.get_string(US_FAX_KEY, true, true);
    output[US_PHONE_KEY] = rec.get_string(US_PHONE_KEY, true, true);
  }
}

//------------------------------------------------------------------------------
// Find user for session
//------------------------------------------------------------------------------

void site_database::find_user_for_session(const std::string& site_seq,
                                          const std::string& login,
                                          const std::string& password,
                                          u32 flags, json& output) {
  // always refuse empty password!
  if (password.empty()) {
    throw std::runtime_error("Password is empty");
  }

  // prepare the query:
  std::string sql;
  flags |= onis::database::info_user_password;
  std::string columns = get_user_columns(flags, false);
  std::string from = "pacs_users";
  std::string clause = "active=1 AND site_id=? AND login=?";

  auto query = create_and_prepare_query(columns, from, clause,
                                        onis::database::lock_mode::NONE);
  if (!query->bind_parameter(1, site_seq)) {
    std::throw_with_nested(
        std::runtime_error("Failed to bind site_seq parameter"));
  }
  if (!query->bind_parameter(2, login)) {
    std::throw_with_nested(
        std::runtime_error("Failed to bind login parameter"));
  }

  // execute the query:
  auto result = execute_query(query);
  if (!result->has_rows()) {
    throw site_server_exception(1234, "User '" + login + "' not found");
  }

  // read the user record:
  auto row = result->get_next_row();
  if (!row) {
    throw std::runtime_error("User not found");
  }
  read_user_record(*row, flags, true, nullptr, output);

  // verify the password:
  std::string hashed_pwd = output[US_PASSWORD_KEY].asString();
  // if (!argon2_verify_password(password, hashed_pwd))
  // res.set(OSRSP_REFUSED, EOS_PERMISSION, "", OSFALSE);

  if (output.isMember(US_PASSWORD_KEY))
    output[US_PASSWORD_KEY] = "xxxxxxxxxx";
  if (flags & onis::database::info_user_permissions)
    get_user_permissions(output[BASE_SEQ_KEY].asString(),
                         output[US_PERMISSION_KEY]);
  if (flags & onis::database::info_user_membership)
    get_user_membership(output[BASE_SEQ_KEY].asString(),
                        output[US_MEMBERSHIP_KEY]);
  /*if (flags & onis::server::info_user_partition_access &&
      res.status == OSRSP_SUCCESS)
    find_partition_access(OSFALSE, output[BASE_SEQ_KEY].asString(),
                          onis::db::nolock, output[US_PARTITION_ACCESS_KEY],
                          NULL, OSTRUE, res);
  if (flags & onis::server::info_user_dicom_access &&
      res.status == OSRSP_SUCCESS)
    find_dicom_access(OSFALSE, output[BASE_SEQ_KEY].asString(),
                      onis::db::nolock, output[US_DICOM_ACCESS_KEY], NULL,
                      OSTRUE, res);*/
}

void site_database::get_user_permissions(const std::string& seq, json& output) {
  // prepare the sql command:
  std::string sql =
      "SELECT pacs_role_items.name, pacs_role_has_role_items.value FROM "
      "pacs_role_items INNER JOIN pacs_role_has_role_items ON "
      "pacs_role_has_role_items.item_id=pacs_role_items.id WHERE "
      "pacs_role_has_role_items.user_id=?";

  auto query = prepare_query(sql, "get_role_permissions");
  query->bind_parameter(1, seq);

  // Execute query:
  auto result = execute_query(query);

  // Process result
  while (auto row = result->get_next_row()) {
    json permission = Json::Value(Json::objectValue);
    permission["id"] = row->get_string("name", false, false);
    permission["value"] = row->get_int("value", false);
    output.append(std::move(permission));
  }
}

void site_database::get_user_membership(const std::string& seq, json& output) {
  // prepare the sql command:
  std::string sql =
      "SELECT pacs_role_membership.parent_id FROM pacs_role_membership WHERE "
      "pacs_role_membership.user_id=?";
  auto query = prepare_query(sql, "get_user_membership");
  query->bind_parameter(1, seq);

  // Execute query:
  auto result = execute_query(query);

  // Process result
  while (auto row = result->get_next_row()) {
    output.append(row->get_uuid("parent_id", false, false));
  }
}
