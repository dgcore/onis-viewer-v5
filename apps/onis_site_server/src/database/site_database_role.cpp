#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_role.hpp"
#include "../../include/database/site_database.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Role operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_role_columns(std::uint32_t flags,
                                            bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_roles." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "site_id, " + prefix + "name, " + prefix +
           "active, " + prefix + "inherit, " + prefix + "description, " +
           prefix + "inherit_pref, " + prefix + "pref_id";
  }
  std::string columns = prefix + "id, " + prefix + "site_id";
  if (flags & onis::database::info_role_name) {
    columns += ", " + prefix + "name";
  }
  if (flags & onis::database::info_role_active) {
    columns += ", " + prefix + "active";
  }
  if (flags & onis::database::info_role_inherit) {
    columns += ", " + prefix + "inherit";
  }
  if (flags & onis::database::info_role_description) {
    columns += ", " + prefix + "description";
  }
  if (flags & onis::database::info_role_pref_set) {
    columns += ", " + prefix + "inherit_pref, " + prefix + "pref_id";
  }
  return columns;
}

void site_database::read_role_record(onis_kit::database::database_row& rec,
                                     std::uint32_t flags, std::string* site_seq,
                                     json& output) {
  onis::database::role::create(output, flags);
  output[BASE_SEQ_KEY] = rec.get_uuid("id", false, false);
  if (site_seq) {
    *site_seq = rec.get_uuid("site_id", false, false);
  }
  if (flags & onis::database::info_role_name) {
    output[RO_NAME_KEY] = rec.get_string(RO_NAME_KEY, false, false);
  }
  if (flags & onis::database::info_role_active) {
    output[RO_ACTIVE_KEY] = rec.get_int(RO_ACTIVE_KEY, false);
  }
  if (flags & onis::database::info_role_inherit) {
    output[RO_INHERIT_KEY] = rec.get_int(RO_INHERIT_KEY, false);
  }
  if (flags & onis::database::info_role_description) {
    output[RO_DESC_KEY] = rec.get_string(RO_DESC_KEY, true, true);
  }
  if (flags & onis::database::info_role_pref_set) {
    output[RO_PREFSET_INHERIT_KEY] = rec.get_int(RO_PREFSET_INHERIT_KEY, false);
    output[RO_PREFSET_ID_KEY] = rec.get_string(RO_PREFSET_ID_KEY, true, true);
  }
}

//------------------------------------------------------------------------------
// Find roles
//------------------------------------------------------------------------------

void site_database::find_role_by_seq(const std::string& seq,
                                     std::uint32_t flags, lock_mode lock,
                                     std::string* site_seq, json& output) {
  // Create and prepare query:
  std::string columns = get_role_columns(flags, false);
  std::string where = "id = ?";
  auto query = create_and_prepare_query(columns, "pacs_roles", where, lock);

  // Bind the seq parameter
  if (!query->bind_parameter(1, seq)) {
    std::throw_with_nested(std::runtime_error("Failed to bind idparameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    auto row = result->get_next_row();
    if (row) {
      read_role_record(*row, flags, site_seq, output);
      // TODO: Implement permissions, membership, partition access, and dicom
      // access
      if (flags & onis::database::info_role_permissions)
        get_role_permissions(output[BASE_SEQ_KEY].asString(),
                             output[RO_PERMISSION_KEY]);
      if (flags & onis::database::info_role_membership)
        get_role_membership(output[BASE_SEQ_KEY].asString(),
                            output[RO_MEMBERSHIP_KEY]);
      /*if (flags & onis::database::info_role_partition_access)
        find_partition_access(OSTRUE, output[BASE_SEQ_KEY].asString(),
                              onis::db::nolock, output[RO_PARTITION_ACCESS_KEY],
                              NULL, OSTRUE);
      if (flags & onis::database::info_role_dicom_access)
        find_dicom_access(OSTRUE, output[BASE_SEQ_KEY].asString(),
                          onis::db::nolock, output[RO_DICOM_ACCESS_KEY], NULL,
                          OSTRUE);*/
      return;
    }
  }
  throw std::runtime_error("Role not found");
}

void site_database::find_role_by_seq(const std::string& site_seq,
                                     const std::string& seq,
                                     std::uint32_t flags, lock_mode lock,
                                     json& output) {
  std::string site_seq_from_seq;
  find_role_by_seq(seq, flags, lock, &site_seq_from_seq, output);
  if (site_seq_from_seq != site_seq) {
    output.clear();
    throw std::runtime_error("Role not found");
  }
}

void site_database::find_roles_for_site(const std::string& site_seq,
                                        std::uint32_t flags, lock_mode lock,
                                        json& output) {
  // Create and prepare query:
  std::string columns = get_role_columns(flags, false);
  std::string where = "site_id = ?";
  auto query = create_and_prepare_query(columns, "pacs_roles", where, lock);

  // Bind the seq parameter
  if (!query->bind_parameter(1, site_seq)) {
    std::throw_with_nested(std::runtime_error("Failed to bind idparameter"));
  }

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      json item = Json::Value(Json::objectValue);
      read_role_record(*row, flags, nullptr, item);
      // TODO: Implement permissions, membership, partition access, and dicom
      // access
      if (flags & onis::database::info_role_permissions)
        get_role_permissions(item[BASE_SEQ_KEY].asString(),
                             item[RO_PERMISSION_KEY]);
      if (flags & onis::database::info_role_membership)
        get_role_membership(item[BASE_SEQ_KEY].asString(),
                            item[RO_MEMBERSHIP_KEY]);
      /*if (flags & onis::database::info_role_partition_access)
        find_partition_access(OSTRUE, item[BASE_SEQ_KEY].asString(),
                              onis::db::nolock, item[RO_PARTITION_ACCESS_KEY],
                              NULL, OSTRUE);
      if (flags & onis::database::info_role_dicom_access)
        find_dicom_access(OSTRUE, item[BASE_SEQ_KEY].asString(),
                          onis::db::nolock, item[RO_DICOM_ACCESS_KEY], NULL,
                          OSTRUE);*/
      output.append(std::move(item));
    }
  }
}

//------------------------------------------------------------------------------
// Create roles
//------------------------------------------------------------------------------

void site_database::create_role(const std::string& site_seq, const json& input,
                                json& output, std::uint32_t out_flags) {
  std::uint32_t in_flags = input[BASE_FLAGS_KEY].asUInt();
  std::string seq = onis::util::uuid::generate_random_uuid();
  std::string sql = "INSERT INTO pacs_roles (id, site_id";
  if (in_flags & onis::database::info_role_name)
    sql += ", name";
  sql += ", active, inherit";
  if (in_flags & onis::database::info_role_description)
    sql += ", description";
  sql += ", inherit_pref, pref_id";
  sql += ") VALUES (?, ?";
  if (in_flags & onis::database::info_role_name) {
    sql += ", ?";
  }
  if (in_flags & onis::database::info_role_active) {
    sql += ", ?";
  } else {
    sql += ", 1";
  }
  if (in_flags & onis::database::info_role_inherit) {
    sql += ", ?";
  } else {
    sql += ", 0";
  }
  if (in_flags & onis::database::info_role_description) {
    sql += ", ?";
  }
  if (in_flags & onis::database::info_role_pref_set) {
    sql += ", ?, ?";
  } else {
    sql += ", 0, NULL";
  }
  sql += ")";

  auto query = prepare_query(sql, "create_role");

  int index = 1;
  bind_parameter(query, index, seq, "seq");
  bind_parameter(query, index, site_seq, "site_seq");
  if (in_flags & onis::database::info_role_name)
    bind_parameter(query, index, input[RO_NAME_KEY].asString(), "name");
  if (in_flags & onis::database::info_role_active)
    bind_parameter(query, index, input[RO_ACTIVE_KEY].asInt(), "active");
  if (in_flags & onis::database::info_role_inherit)
    bind_parameter(query, index, input[RO_INHERIT_KEY].asInt(), "inherit");
  if (in_flags & onis::database::info_role_description)
    bind_parameter(query, index, input[RO_DESC_KEY].asString(), "description");
  if (in_flags & onis::database::info_role_pref_set) {
    bind_parameter(query, index, input[RO_PREFSET_INHERIT_KEY].asInt(),
                   "inherit_pref");
    bind_parameter(query, index, input[RO_PREFSET_ID_KEY].asString(),
                   "pref_id");
  }

  // Excute query:
  execute_and_check_affected(query, "Role not created");
  find_role_by_seq(seq, out_flags, onis::database::lock_mode::NONE, nullptr,
                   output);
}

//------------------------------------------------------------------------------
// Modify roles
//------------------------------------------------------------------------------
void site_database::modify_role(const json& role) {
  // construct the sql command:
  std::string sql = "UPDATE pacs_roles SET ";
  std::string values;
  std::uint32_t flags = role[BASE_FLAGS_KEY].asUInt();
  if (flags & onis::database::info_role_name)
    values += ", name=?";
  if (flags & onis::database::info_role_description)
    values += ", description=?";
  if (flags & onis::database::info_role_active)
    values += ", active=?";
  if (flags & onis::database::info_role_inherit)
    values += ", inherit=?";
  if (flags & onis::database::info_role_pref_set)
    values += ", inherit_pref=?, pref_id=?";
  if (!values.empty()) {
    sql += values.substr(2);
    sql += " WHERE id=?";

    // Create and prepare query:
    auto query = prepare_query(sql, "modify_role");

    std::int32_t index = 1;
    if (flags & onis::database::info_role_name) {
      bind_parameter(query, index, role[RO_NAME_KEY].asString(), "name");
    }
    if (flags & onis::database::info_role_description) {
      bind_parameter(query, index, role[RO_DESC_KEY].asString(), "description");
    }
    if (flags & onis::database::info_role_active) {
      bind_parameter(query, index, role[RO_ACTIVE_KEY].asInt(), "active");
    }
    if (flags & onis::database::info_role_inherit) {
      bind_parameter(query, index, role[RO_INHERIT_KEY].asInt(), "inherit");
    }
    if (flags & onis::database::info_role_pref_set) {
      bind_parameter(query, index, role[RO_PREFSET_INHERIT_KEY].asInt(),
                     "inherit_pref");
      bind_parameter(query, index, role[RO_PREFSET_ID_KEY].asString(),
                     "pref_id");
    }
    bind_parameter(query, index, role[BASE_SEQ_KEY].asString(), "seq");

    // Execute query and check if any rows were affected
    execute_and_check_affected(query, "Role not found");
  }

  // update the permissions:
  if (flags & onis::database::info_role_permissions) {
    const auto& permissions = role[RO_PERMISSION_KEY];
    for (Json::ArrayIndex i = 0; i < permissions.size(); ++i) {
      const auto& permission = permissions[i];
      std::string name = permission["id"].asString();
      std::int32_t value = permission["value"].asInt();
      std::string perm_seq = find_role_permission_seq(name);
      modify_role_permission_value(role[BASE_SEQ_KEY].asString(), perm_seq,
                                   value, true);
    }
  }

  // update the memberships:
  if (flags & onis::database::info_role_membership) {
    // remove all existing membership:
    std::string sql = "DELETE FROM pacs_role_membership WHERE role_id=?";
    auto query = prepare_query(sql, "delete_role_membership");
    query->bind_parameter(1, role[BASE_SEQ_KEY].asString());
    execute_query(query);

    // insert the membership one by one:
    const auto& membership = role[RO_MEMBERSHIP_KEY];
    for (Json::ArrayIndex i = 0; i < membership.size(); ++i) {
      std::string parent_id = membership[i].asString();
      std::string child_id = role[BASE_SEQ_KEY].asString();
      check_circular_membership(parent_id, child_id);

      // insert the membership:
      std::string seq = onis::util::uuid::generate_random_uuid();
      std::string sql =
          "INSERT INTO pacs_role_membership (id, role_id, parent_id) VALUES "
          "(?, ?, ?)";
      auto query = prepare_query(sql, "insert_role_membership");
      query->bind_parameter(1, seq);
      query->bind_parameter(2, child_id);
      query->bind_parameter(3, parent_id);
      execute_and_check_affected(query, "Role membership not created");
    }
  }

  /*if (flags & onis::server::info_role_partition_access)
    update_partition_access(OSTRUE, role_seq, role[RO_PARTITION_ACCESS_KEY],
                            res);

  if (flags & onis::server::info_role_dicom_access)
    update_dicom_access(OSTRUE, role_seq, role[RO_DICOM_ACCESS_KEY], res);*/
}

//------------------------------------------------------------------------------
// Delete roles
//------------------------------------------------------------------------------
void site_database::delete_role(const std::string& seq) {
  // delete the permissions:
  std::string sql = "DELETE FROM pacs_role_has_role_items WHERE role_id=?";
  auto query = prepare_query(sql, "delete_role_permissions");
  query->bind_parameter(1, seq);
  execute_query(query);

  // delete the memberships:
  sql = "DELETE FROM pacs_role_membership WHERE role_id=?";
  query = prepare_query(sql, "delete_role_membership");
  query->bind_parameter(1, seq);
  execute_query(query);

  // delete the partition access:
  /*delete_partition_access(OSTRUE, seq, res);

  // delete the dicom access:
  delete_dicom_access(OSTRUE, seq, res);*/

  // delete the role:
  sql = "DELETE FROM pacs_roles WHERE id=?";
  query = prepare_query(sql, "delete_role");
  query->bind_parameter(1, seq);
  execute_and_check_affected(query, "Role not found");
}

//------------------------------------------------------------------------------
// Role permissions
//------------------------------------------------------------------------------

void site_database::get_role_permissions(const std::string& seq, json& output) {
  // prepare the sql command:
  std::string sql =
      "SELECT pacs_role_items.name, pacs_role_has_role_items.value FROM "
      "pacs_role_items INNER JOIN pacs_role_has_role_items ON "
      "pacs_role_has_role_items.item_id=pacs_role_items.id WHERE "
      "pacs_role_has_role_items.role_id=?";

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

std::string site_database::find_role_permission_seq(const std::string& name) {
  // prepare the sql command:
  std::string sql = "SELECT id FROM pacs_role_items WHERE name=?";
  auto query = prepare_query(sql, "find_role_permission_seq");
  query->bind_parameter(1, name);

  // Excute query:
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    auto row = result->get_next_row();
    if (row) {
      return row->get_uuid("ID", false, false);
    }
  }
  throw std::runtime_error("Role Permission not found");
}

void site_database::create_role_permission_value(
    const std::string& role_seq, const std::string& permission_id,
    std::int32_t value) {
  // search the permission seq:
  std::string perm_seq = find_role_permission_seq(permission_id);

  // prepare the sql command:
  std::string seq = onis::util::uuid::generate_random_uuid();
  std::string sql =
      "INSERT INTO pacs_role_has_role_items (id, role_id, item_id, value) "
      "VALUES (?, ?, ?, ?)";
  auto query = prepare_query(sql, "create_role_permission_value");
  query->bind_parameter(1, seq);
  query->bind_parameter(2, role_seq);
  query->bind_parameter(3, perm_seq);
  query->bind_parameter(4, value);

  // execute the sql command:
  execute_and_check_affected(query, "Role permission value not created");
}

void site_database::modify_role_permission_value(
    const std::string& role_seq, const std::string& permission_seq,
    std::int32_t value, bool create) {
  // create sql command:
  std::string sql =
      "UPDATE pacs_role_has_role_items SET value=? WHERE role_id=? AND "
      "ITEM_ID=?";
  auto query = prepare_query(sql, "modify_role_permission_value");
  query->bind_parameter(1, value);
  query->bind_parameter(2, role_seq);
  query->bind_parameter(3, permission_seq);

  // Excute query:
  auto result = execute_query(query);
  if (result->get_affected_rows() == 0 && create) {
    /*if (!exist_permission(OSTRUE, role_seq, permission_seq, res)) {
      std::string seq = onis::util::uuid::generate_random_uuid();
      sql =
          "INSERT INTO PACS_ROLE_HAS_ROLE_ITEMS (ID, ROLE_ID, ITEM_ID, "
          "VALUE) VALUES (?, ?, ?, ?)";
      query->bind_parameter(1, seq);
      query->bind_parameter(2, role_seq);
      query->bind_parameter(3, permission_seq);
      query->bind_parameter(4, value);
      execute_query(query);
    }*/
  }
}

//------------------------------------------------------------------------------
// Role memberships
//------------------------------------------------------------------------------

void site_database::get_role_membership(const std::string& seq, json& output) {
  // prepare the sql command:
  std::string sql =
      "SELECT pacs_role_membership.parent_id FROM pacs_role_membership WHERE "
      "pacs_role_membership.role_id=?";
  auto query = prepare_query(sql, "get_role_membership");
  query->bind_parameter(1, seq);

  // Excute query:
  auto result = execute_query(query);

  // Process result
  while (auto row = result->get_next_row()) {
    output.append(row->get_uuid("PARENT_ID", false, false));
  }
}

void site_database::check_circular_membership(const std::string& parent_id,
                                              const std::string& child_id) {
  // parent and child should not be the same:
  if (parent_id == child_id) {
    throw std::runtime_error("Circular membership detected");
  } else {
    // retrieve the list of parents of parent_id:
    std::list<std::string> parents;

    // prepare the sql command:
    std::string sql =
        "SELECT parent_id FROM pacs_role_membership WHERE role_id=?";
    auto query = prepare_query(sql, "check_circular_membership");
    query->bind_parameter(1, parent_id);

    // Excute query:
    auto result = execute_query(query);

    // Process result
    while (auto row = result->get_next_row()) {
      int column_index = 0;
      parents.push_back(row->get_uuid(column_index, false, false));
    }

    // check the list:
    for (const auto& id : parents)
      check_circular_membership(id, child_id);
  }
}
