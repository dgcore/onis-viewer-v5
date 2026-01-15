#pragma once

#include <exception>
#include <string>

class request_exception : public std::exception {
public:
  explicit request_exception(int code, const std::string& message)
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
