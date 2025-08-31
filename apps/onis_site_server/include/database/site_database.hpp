#pragma once

#include <memory>
#include <nlohmann/json.hpp>
#include <string>
#include <vector>
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/database/database_interface.hpp"

using namespace dgc;
using json = nlohmann::json;

class site_database {
public:
  explicit site_database(
      std::unique_ptr<onis_kit::database::database_connection>&& connection);
  ~site_database();

  // Connection access
  onis_kit::database::database_connection& get_connection();
  const onis_kit::database::database_connection& get_connection() const;

  // Organization operations
  std::string get_organization_columns(bool add_table_name = false);
  std::vector<json> find_organizations(const std::string& where_clause,
                                       dgc::result& res);
  std::optional<json> find_organization(const std::string& where_clause,
                                        dgc::result& res);
  std::optional<json> find_organization_by_seq(const std::string& seq,
                                               dgc::result& res);
  bool create_organization(const json& organization_data, dgc::result& res);
  bool update_organization(const std::string& where_clause,
                           const json& organization_data, dgc::result& res);
  bool delete_organization(const std::string& where_clause, dgc::result& res);

private:
  std::unique_ptr<onis_kit::database::database_connection> connection_;
};