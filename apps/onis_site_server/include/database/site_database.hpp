#pragma once

#include <memory>
#include <string>
#include "database/database_interface.hpp"

class site_database {
public:
  explicit site_database(
      std::unique_ptr<onis_kit::database::database_connection>&& connection);
  ~site_database();

  // Connection access
  onis_kit::database::database_connection& get_connection();
  const onis_kit::database::database_connection& get_connection() const;

private:
  std::unique_ptr<onis_kit::database::database_connection> connection_;
};