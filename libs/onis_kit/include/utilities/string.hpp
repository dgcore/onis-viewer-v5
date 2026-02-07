#pragma once

#include <chrono>
#include <cstdint>
#include <string>
#include <vector>

#include "../core/date_time.hpp"

namespace onis::util::string {

std::string convert_to_utf8(const std::string& text,
                            const std::string& code_page);
void convert_from_utf8(const std::string& utf8_text,
                       const std::string& code_page, std::string& output);

std::int32_t convert_to_s32(const std::string& text);
std::uint32_t convert_to_u32(const std::string& text);
double convert_to_f64(const std::string& text);
float convert_to_f32(const std::string& text);

void replace_antislash_by_slash(std::string& text);

void sort(std::vector<std::string>& list, bool ascending);
void split(std::string text, std::vector<std::string>& list,
           const std::string& separators);

bool is_ip4_address(const std::string& str);
bool is_unsigned_int(const std::string& str);
bool is_unsigned_int32(const std::string& str);
bool is_unsigned_int16(const std::string& str);
bool is_unsigned_int8(const std::string& str);
bool is_int(const std::string& str);
bool is_int32(const std::string& str);
bool is_int16(const std::string& str);
bool is_int8(const std::string& str);
bool is_integer_in_range(bool check_min, std::int32_t min_value, bool check_max,
                         std::int32_t max_value, const std::string& str);
bool is_float32(const std::string& str);

bool get_date_from_string(const std::string& str, std::int32_t start,
                          std::string& year, std::string& month,
                          std::string& day);
bool get_time_from_string(const std::string& str, std::uint32_t start,
                          std::uint32_t* hour, std::uint32_t* minute,
                          std::uint32_t* second, std::uint32_t* fraction);

bool get_date_range_from_string(const std::string& str,
                                onis::core::date_time* from,
                                onis::core::date_time* to);
bool get_time_range_from_string(const std::string& str, onis::core::time* from,
                                onis::core::time* to);

}  // namespace onis::util::string
