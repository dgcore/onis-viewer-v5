#pragma once

#include <json/json.h>
#include <functional>
#include <memory>
#include <mutex>

using json = Json::Value;

////////////////////////////////////////////////////////////////////////////////
// request_type enum
////////////////////////////////////////////////////////////////////////////////

enum class request_type {
  kAuthenticate,
  kLogout,
};

////////////////////////////////////////////////////////////////////////////////
// request_data class
////////////////////////////////////////////////////////////////////////////////

class request_data;
typedef std::shared_ptr<request_data> request_data_ptr;

class request_data {
public:
  // static constructor
  static request_data_ptr create(request_type type);

  // constructor
  request_data(request_type type);

  // destructor
  ~request_data();

  // prevent copy and move
  request_data(const request_data&) = delete;
  request_data& operator=(const request_data&) = delete;
  request_data(request_data&&) = delete;
  request_data& operator=(request_data&&) = delete;

  // members:
  json input_json;

  // Get the request type
  request_type get_type() const;

  // Method to write to output_json using a lambda (thread-safe)
  template <typename Func>
  void write_output(Func&& func) {
    std::lock_guard<std::mutex> lock(output_mutex_);
    func(output_json_);
  }

  // Method to read from output_json using a lambda (thread-safe)
  template <typename Func>
  void read_output(Func&& func) const {
    std::lock_guard<std::mutex> lock(output_mutex_);
    func(output_json_);
  }

private:
  request_type type_;
  json output_json_;
  mutable std::mutex output_mutex_;
};
