#pragma once

#include <functional>
#include <memory>
#include <queue>
#include "site_database.hpp"

class site_database_pool {
public:
  explicit site_database_pool(size_t max_size = 10);
  ~site_database_pool();

  // Pool configuration
  void set_connection_factory(
      std::function<std::unique_ptr<onis_kit::database::database_connection>()>
          factory);
  void set_max_size(size_t max_size);

  // Connection management
  std::shared_ptr<site_database> get_connection();
  void return_connection(std::shared_ptr<site_database> connection);

  // Pool information
  size_t size() const;
  size_t available() const;
  size_t in_use() const;
  bool empty() const;
  bool full() const;

private:
  size_t max_size_;
  size_t in_use_count_;
  std::queue<std::shared_ptr<site_database>> available_connections_;
  std::function<std::unique_ptr<onis_kit::database::database_connection>()>
      connection_factory_;
};