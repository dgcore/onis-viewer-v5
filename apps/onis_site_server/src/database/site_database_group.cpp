#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_group.hpp"
#include "../../include/database/site_database.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Group operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_group_columns(std::uint32_t flags,
                                             bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_roles." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "site_id, " + prefix + "name, " + prefix +
           "active, " + prefix + "description, " + prefix + "partition_mode, " +
           prefix + "role_mode, " + prefix + "role_id";
  }
  std::string columns = prefix + "id, " + prefix + "site_id";
  if (flags & onis::database::info_user_group_name) {
    columns += ", " + prefix + "name";
  }
  if (flags & onis::database::info_user_group_active) {
    columns += ", " + prefix + "active";
  }
  if (flags & onis::database::info_user_group_description) {
    columns += ", " + prefix + "description";
  }
  if (flags & onis::database::info_user_group_partition) {
    columns += ", " + prefix + "partition_mode";
  }
  if (flags & onis::database::info_user_group_role) {
    columns += ", " + prefix + "role_mode, " + prefix + "role_id";
  }
  return columns;
}

void site_database::read_group_record(onis_kit::database::database_row& rec,
                                      std::uint32_t flags,
                                      std::string* site_seq, json& output) {
  onis::database::group::create(output, flags);
  output[BASE_SEQ_KEY] = rec.get_uuid("id", false, false);
  if (site_seq) {
    *site_seq = rec.get_uuid("site_id", false, false);
  }
  if (flags & onis::database::info_user_group_name) {
    output[GR_NAME_KEY] = rec.get_string(GR_NAME_KEY, false, false);
  }
  if (flags & onis::database::info_user_group_active) {
    output[GR_STATUS_KEY] = rec.get_int(GR_STATUS_KEY, false);
  }
  if (flags & onis::database::info_user_group_description) {
    output[GR_DESC_KEY] = rec.get_string(GR_DESC_KEY, true, true);
  }
  if (flags & onis::database::info_user_group_partition) {
    output[GR_PARTITION_MODE_KEY] = rec.get_int(GR_PARTITION_MODE_KEY, false);
    // output[GR_PARTITION_LIST_KEY] = rec.get_array(GR_PARTITION_LIST_KEY,
    // true);
    //  TODO: implement get_array
  }
  if (flags & onis::database::info_user_group_role) {
    output[GR_ROLE_MODE_KEY] = rec.get_int(GR_ROLE_MODE_KEY, false);
    output[GR_ROLE_ID_KEY] = rec.get_string(GR_ROLE_ID_KEY, true, true);
  }
}