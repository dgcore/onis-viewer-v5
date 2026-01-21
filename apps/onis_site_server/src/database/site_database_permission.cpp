#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_permission.hpp"
#include "../../include/database/site_database.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Permission operations
////////////////////////////////////////////////////////////////////////////////

void site_database::find_permissions_items(json& output, std::uint32_t flags) {
  std::string where = "";
  auto query = create_and_prepare_query("id, name, type", "pacs_role_items", "",
                                        onis::database::lock_mode::NONE);
  auto result = execute_query(query);

  // Process result
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      json item = Json::Value(Json::objectValue);
      onis::database::permission::create(item, flags);
      item[BASE_SEQ_KEY] = row->get_uuid("id", false, false);
      try {
        item[PM_NAME_KEY] = row->get_string("name", false, false);
      } catch (const std::exception& e) {
        item[PM_TYPE_KEY] = row->get_int("type", false);
      }
      output.append(std::move(item));
    }
  }
}

bool site_database::exist_permission(bool role, const std::string& seq,
                                     const std::string& permission_seq) {
  std::string sql =
      "SELECT COUNT(id) AS result FROM pacs_role_has_role_items WHERE ";
  if (role)
    sql += "role_id=?";
  else
    sql += "user_id=?";
  sql += " AND item_id=?";
  auto query = prepare_query(sql, "exist_permission");
  query->bind_parameter(1, seq);
  query->bind_parameter(2, permission_seq);
  auto result = execute_query(query);

  if (!result->has_rows()) {
    throw std::runtime_error("No result from exist_permission query");
  }
  auto row = result->get_next_row();
  return row->get_int("result", false) > 0;
}