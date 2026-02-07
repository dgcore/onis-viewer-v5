#pragma once

#include <exception>
#include <string>

namespace onis {

class exception : public std::exception {
public:
  explicit exception(int code, const std::string& message)
      : code_(code), message_(message) {}

  const char* what() const noexcept override {
    return message_.c_str();
  }

  int get_code() const {
    return code_;
  }

private:
  int code_;
  std::string message_;
};

}  // namespace onis