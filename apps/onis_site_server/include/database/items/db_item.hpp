#pragma once

#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/core/types.hpp"
#include "onis_kit/include/utilities/regex.hpp"

#include <json/json.h>
#include <limits>
#include <memory>
#include <regex>
#include <sstream>

#define BASE_VERSION_KEY "version"
#define BASE_FLAGS_KEY "flags"
#define BASE_SEQ_KEY "seq"
#define BASE_UID_KEY "uid"

namespace onis::database {

using json = Json::Value;
using namespace onis;

const std::uint32_t info_all = 0xFFFFFFFF;

// Helper function to convert Json::Value to string (replaces .dump())
inline std::string json_to_string(const Json::Value& value) {
  Json::StreamWriterBuilder builder;
  builder["indentation"] = "";
  std::unique_ptr<Json::StreamWriter> writer(builder.newStreamWriter());
  std::ostringstream oss;
  writer->write(value, &oss);
  return oss.str();
}

class item {
public:
  item() {}
  ~item() {}

  static inline bool pre_verify(const json& input, const char* key,
                                const Json::ValueType& type, bool allow_null) {
    // check if the key is null
    bool is_null = false;
    if (key == nullptr)
      is_null = input.isNull();
    else {
      if (!input.isMember(key)) {
        throw std::invalid_argument("Missing required key: " +
                                    std::string(key));
      }
      is_null = input[key].isNull();
    }

    // Treat null value:
    if (is_null) {
      if (!allow_null) {
        throw std::invalid_argument("Null value not allowed for key: " +
                                    std::string(key));
      }
      return true;
    }

    // Get the target input:
    const json& input_ref = key == nullptr ? input : input[key];
    if (input_ref.type() != type) {
      throw std::invalid_argument(
          "Invalid type for key: " + std::string(key) +
          ", expected: " + std::to_string(static_cast<int>(type)) +
          ", got: " + std::to_string(static_cast<int>(input[key].type())));
    }
    return false;
  }

  static inline void verify_string_value(
      const json& input, const char* key, bool allow_null, bool allow_empty,
      size_t max_length = std::numeric_limits<size_t>::max()) {
    if (pre_verify(input, key, Json::stringValue, allow_null))
      return;
    const json& input_ref = key == nullptr ? input : input[key];
    if (!input_ref.isNull()) {
      const std::string value = input_ref.asString();
      if (!allow_empty && value.empty()) {
        throw std::invalid_argument("Empty string not allowed for key: " +
                                    std::string(key));
      }
      if (value.length() > max_length) {
        throw std::invalid_argument(
            "String too long for key: " + std::string(key) +
            " (max length: " + std::to_string(max_length) + ")");
      }
    }
  }

  static inline void verify_string_value(const json& input, const char* key,
                                         bool allow_null, bool allow_empty,
                                         const std::string& regex_value) {
    if (pre_verify(input, key, Json::stringValue, allow_null))
      return;
    const json& input_ref = key == nullptr ? input : input[key];
    if (!input_ref.isNull()) {
      const std::string value = input_ref.asString();
      if (!allow_empty && value.empty()) {
        throw std::invalid_argument("Empty string not allowed for key: " +
                                    std::string(key));
      }
      onis::util::regex::match(value, regex_value, false);
    }
  }

  static inline void verify_uuid_value(const json& input, const char* key,
                                       bool allow_null, bool allow_empty) {
    if (pre_verify(input, key, Json::stringValue, allow_null))
      return;
    const json& input_ref = key == nullptr ? input : input[key];
    if (!input_ref.isNull()) {
      const std::string value = input_ref.asString();
      if (!allow_empty && value.empty()) {
        throw std::invalid_argument("Empty UUID not allowed for key: " +
                                    std::string(key));
      }
      // UUID format validation - 8-4-4-4-12 hex digits
      static const std::regex uuid_regex(
          "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-"
          "fA-F]{12}$");
      if (!value.empty() && !std::regex_match(value, uuid_regex)) {
        throw std::invalid_argument("Invalid UUID format for key: " +
                                    std::string(key));
      }
    }
  }

  static inline void verify_boolean_value(const json& input, const char* key,
                                          bool allow_null) {
    pre_verify(input, key, Json::booleanValue, allow_null);
  }

  static inline void verify_integer_value(
      const json& input, const char* key, bool allow_null,
      std::int32_t min_value = std::numeric_limits<std::int32_t>::min(),
      std::int32_t max_value = std::numeric_limits<std::int32_t>::max()) {
    if (pre_verify(input, key, Json::intValue, allow_null))
      return;
    const json& input_ref = key == nullptr ? input : input[key];
    if (!input_ref.isNull()) {
      std::int32_t value = input_ref.asInt();
      if (value < min_value || value > max_value) {
        throw std::invalid_argument(
            "Integer value out of range for key: " + std::string(key) +
            ", min: " + std::to_string(min_value) +
            ", max: " + std::to_string(max_value));
      }
    }
  }

  static inline void verify_integer_or_real_value(
      const json& input, const char* key, bool allow_null,
      float min_value = std::numeric_limits<float>::lowest(),
      float max_value = std::numeric_limits<float>::max()) {
    try {
      verify_float_value(input, key, allow_null, min_value, max_value);
    } catch (const std::invalid_argument& e) {
      verify_integer_value(input, key, allow_null, min_value, max_value);
    }
  }

  static inline void verify_float_value(
      const json& input, const char* key, bool allow_null,
      float min_value = std::numeric_limits<float>::lowest(),
      float max_value = std::numeric_limits<float>::max()) {
    if (pre_verify(input, key, Json::realValue, allow_null))
      return;
    const json& input_ref = key == nullptr ? input : input[key];
    if (!input_ref.isNull()) {
      float value = static_cast<float>(input_ref.asDouble());
      if (value < min_value || value > max_value) {
        throw std::invalid_argument(
            "Float value out of range for key: " + std::string(key) +
            ", min: " + std::to_string(min_value) +
            ", max: " + std::to_string(max_value));
      }
    }
  }

  static inline void verify_unsigned_integer_value(
      const json& input, const char* key, bool allow_null,
      std::uint32_t min_value = 0,
      std::uint32_t max_value = std::numeric_limits<std::uint32_t>::max()) {
    if (pre_verify(input, key, Json::uintValue, allow_null))
      return;
    const json& input_ref = key == nullptr ? input : input[key];
    if (!input_ref.isNull()) {
      std::uint32_t value = input_ref.asUInt();
      if (value < min_value || value > max_value) {
        throw std::invalid_argument(
            "Unsigned integer value out of range for key: " + std::string(key) +
            ", min: " + std::to_string(min_value) +
            ", max: " + std::to_string(max_value));
      }
    }
  }

  static inline void verify_array_value(const json& input, const char* key,
                                        bool allow_null) {
    if (pre_verify(input, key, Json::arrayValue, allow_null))
      return;
    const json& input_ref = key == nullptr ? input : input[key];
    if (!input_ref.isNull()) {
      if (!input_ref.isArray()) {
        throw std::invalid_argument("Expected array value for key: " +
                                    std::string(key));
      }
    }
  }

  static inline void verify_seq_version_flags(const json& input,
                                              bool with_seq) {
    if (with_seq) {
      onis::database::item::verify_uuid_value(input, BASE_SEQ_KEY, false,
                                              false);
    }
    onis::database::item::verify_string_value(input, BASE_VERSION_KEY, false,
                                              false);
    onis::database::item::verify_unsigned_integer_value(input, BASE_FLAGS_KEY,
                                                        false);
    std::string version = input[BASE_VERSION_KEY].asString();
    if (version != "1.0.0") {
      throw std::invalid_argument("Invalid version for key: " +
                                  std::string(BASE_VERSION_KEY));
    }
  }

  static inline void check_must_flags(std::uint32_t flags,
                                      std::uint32_t must_flags) {
    if (must_flags)
      if ((flags & must_flags) != must_flags) {
        throw std::invalid_argument("Missing required flags");
      }
  }
};

}  // namespace onis::database
