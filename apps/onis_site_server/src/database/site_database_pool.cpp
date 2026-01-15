#include "../../include/database/site_database_pool.hpp"

site_database_pool::site_database_pool(size_t max_size)
    : max_size_(max_size), in_use_count_(0) {}

site_database_pool::~site_database_pool() {
  // All connections will be automatically cleaned up by shared_ptr
}

void site_database_pool::set_connection_factory(
    std::function<std::unique_ptr<onis_kit::database::database_connection>()>
        factory) {
  connection_factory_ = factory;
}

void site_database_pool::set_max_size(size_t max_size) {
  max_size_ = max_size;
}

std::shared_ptr<site_database> site_database_pool::get_connection() {
  // Check available connections and remove invalid ones
  while (!available_connections_.empty()) {
    auto connection = available_connections_.front();
    available_connections_.pop();

    // Check if the connection is still valid
    if (connection && connection->get_connection().is_connected()) {
      in_use_count_++;
      return connection;
    }
    // If connection is invalid, it will be destroyed automatically
  }

  // If we haven't reached max size, create a new connection
  if (in_use_count_ < max_size_ && connection_factory_) {
    auto db_connection = connection_factory_();
    if (db_connection) {
      auto site_db = std::make_shared<site_database>(std::move(db_connection));
      in_use_count_++;
      return site_db;
    }
  }

  // Pool is full or factory is not set
  throw std::runtime_error("Failed to get database connection");
}

void site_database_pool::return_connection(
    std::shared_ptr<site_database> connection) {
  if (connection && in_use_count_ > 0) {
    available_connections_.push(connection);
    in_use_count_--;
  }
}

size_t site_database_pool::size() const {
  return available_connections_.size() + in_use_count_;
}

size_t site_database_pool::available() const {
  return available_connections_.size();
}

size_t site_database_pool::in_use() const {
  return in_use_count_;
}

bool site_database_pool::empty() const {
  return available_connections_.empty() && in_use_count_ == 0;
}

bool site_database_pool::full() const {
  return in_use_count_ >= max_size_;
}