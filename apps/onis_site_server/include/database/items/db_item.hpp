#pragma once

#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/core/types.hpp"

#include <nlohmann/json.hpp>

#define BASE_VERSION_KEY "version"
#define BASE_FLAGS_KEY "flags"
#define BASE_SEQ_KEY "seq"
#define BASE_UID_KEY "uid"

using json = nlohmann::json;

namespace onis {
namespace database {

const u32 info_all = 0xFFFFFFFF;

class item {
public:
  db_item() {}
  ~db_item() {}

  static inline void verify_value(const json& input, const json::value_t& type,
                                  const char* key, dgc::result& res) {
    if (res.status != OSRSP_SUCCESS)
      return;
    if (input.contains(key) && input[key].type() == type)
      return;
    res.status = OSRSP_FAILURE;
    res.reason = EOS_PARAM;
  }

  static inline void verify_value(const json& input, const json::value_t& type,
                                  dgc::result& res) {
    // don't proceed if an error has earlier occurred:
    if (res.status != OSRSP_SUCCESS)
      return;
    if (input.type() == type)
      return;
    res.status = OSRSP_FAILURE;
    res.reason = EOS_PARAM;
  }

  static inline void verify_boolean_value(const json& input, const char* key,
                                          bool allow_null, dgc::result& res) {
    if (res.status != OSRSP_SUCCESS)
      return;
    if (allow_null) {
      if (input.contains(key)) {
        if (input[key].type() != json::value_t::boolean) {
          res.status = OSRSP_FAILURE;
          res.reason = EOS_PARAM;
        }
      }
    } else
      verify_value(input, json::value_t::boolean, key, res);
  }

  static inline void verify_int_or_uint_value(const json& input,
                                              const char* key,
                                              dgc::result& res) {
    if (res.status != OSRSP_SUCCESS)
      return;
    verify_value(input, json::value_t::number_integer, key, res);
    if (res.status != OSRSP_SUCCESS) {
      res.status = OSRSP_SUCCESS;
      res.reason = EOS_NONE;
      verify_value(input, json::value_t::number_unsigned, key, res);
    }
  }

  static inline void verify_int_or_uint_or_real_value(const json& input,
                                                      const char* key,
                                                      dgc::result& res) {
    if (res.status != OSRSP_SUCCESS)
      return;
    verify_value(input, json::value_t::number_integer, key, res);
    if (res.status != OSRSP_SUCCESS) {
      res.status = OSRSP_SUCCESS;
      res.reason = EOS_NONE;
      verify_value(input, json::value_t::number_unsigned, key, res);
      if (res.status != OSRSP_SUCCESS) {
        res.status = OSRSP_SUCCESS;
        res.reason = EOS_NONE;
        verify_value(input, json::value_t::number_float, key, res);
      }
    }
  }

  static inline u32 get_flag_value(const json& input, bool allow_null,
                                   u32 default_value, dgc::result& res) {
    // don't proceed if an error has earlier occurred:
    if (res.status != OSRSP_SUCCESS)
      return 0;
    s32 ret = verify_int_or_uint_value(input, BASE_FLAGS_KEY, res);
    if (res.status != OSRSP_SUCCESS) {
      if (allow_null) {
        if (input.contains(BASE_FLAGS_KEY)) {
          res.status = OSRSP_SUCCESS;
          res.reason = EOS_NONE;
          return default_value;
        } else
          return 0;
      } else
        return 0;
    } else {
      if (ret == 0)
        return (u32)input[BASE_FLAGS_KEY].get<s32>();
      else
        return input[BASE_FLAGS_KEY].get<u32>();
    }
  }

  static inline bool get_flag_value(const json& input, const char* key,
                                    bool allow_null, u32& value,
                                    dgc::result& res) {
    // don't proceed if an error has earlier occurred:
    if (res.status != OSRSP_SUCCESS)
      return false;
    s32 ret = verify_int_or_uint_value(input, key, res);
    if (res.status != OSRSP_SUCCESS) {
      if (allow_null) {
        res.status = OSRSP_SUCCESS;
        res.reason = EOS_NONE;
      }
      return false;
    } else {
      if (ret == 0)
        value = (u32)input[key].get<s32>();
      else
        value = input[key].get<u32>();
      return true;
    }
  }

  static inline void check_must_flags(u32 flags, u32 must_flags,
                                      dgc::result& res) {
    if (res.status != OSRSP_SUCCESS)
      return;
    if (must_flags)
      if ((flags & must_flags) != must_flags) {
        res.status = OSRSP_FAILURE;
        res.reason = EOS_PARAM;
      }
  }

  static inline void verify_flags(const json& input, u32 flags,
                                  dgc::result& res) {
    u32 tmp = get_flag_value(input, false, 0, res);
    if (res.status == OSRSP_SUCCESS)
      if ((tmp & flags) != flags) {
        res.status = OSRSP_FAILURE;
        res.reason = EOS_PARAM;
      }
  }

  static inline void verify_string_value(const json& input, const char* key,
                                         const char* value, dgc::result& res) {
    verify_value(input, json::value_t::string, key, res);
    if (res.status == OSRSP_SUCCESS)
      if (input[key].get<std::string>() != value) {
        res.status = OSRSP_FAILURE;
        res.reason = EOS_PARAM;
      }
  }

  static inline void verify_string_value(const json& input, const char* key,
                                         bool allow_emtpy, dgc::result& res) {
    verify_value(input, json::value_t::string, key, res);
    if (res.status == OSRSP_SUCCESS && !allow_emtpy)
      if (input[key].get<std::string>().empty()) {
        res.status = OSRSP_FAILURE;
        res.reason = EOS_PARAM;
      }
  }

  static inline void verify_string_value(const json& input, const char* key,
                                         bool key_must_exist,
                                         bool empty_string_ok,
                                         dgc::result& res) {
    // don't proceed if an error has earlier occurred:
    if (res.status != OSRSP_SUCCESS)
      return;
    if (!input.contains(key)) {
      if (key_must_exist || !empty_string_ok)
        res.set(OSRSP_FAILURE, EOS_PARAM, "", false);
    } else if (input[key].type() != json::value_t::string)
      res.set(OSRSP_FAILURE, EOS_PARAM, "", false);
    else if (!empty_string_ok && input[key].get<std::string>().empty())
      res.set(OSRSP_FAILURE, EOS_PARAM, "", false);
  }

  static inline bool get_uint_value(const json& input, const char* key,
                                    bool allow_null, u32& value,
                                    dgc::result& res) {
    // don't proceed if an error has earlier occurred:
    if (res.status != OSRSP_SUCCESS)
      return false;
    s32 ret = verify_int_or_uint_value(input, key, res);
    if (res.status != OSRSP_SUCCESS) {
      if (allow_null) {
        res.status = OSRSP_SUCCESS;
        res.reason = EOS_NONE;
      }
      return false;
    } else {
      if (ret == 0)
        value = (u32)input[key].get<s32>();
      else
        value = input[key].get<u32>();
      return true;
    }
  }

  static inline bool get_uint_value(const json& input, u32& value,
                                    dgc::result& res) {
    // don't proceed if an error has earlier occurred:
    if (res.status != OSRSP_SUCCESS)
      return false;
    s32 ret = verify_int_or_uint_value(input, res);
    if (res.status != OSRSP_SUCCESS)
      return false;
    else {
      if (ret == 0)
        value = (u32)input.get<s32>();
      else
        value = input.get<u32>();
      return true;
    }
  }
};

}  // namespace database
}  // namespace onis
