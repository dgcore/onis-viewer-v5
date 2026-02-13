#pragma once

#include "../core/date_time.hpp"

namespace onis::util::datetime {

bool is_leap_year(std::int32_t year);
std::int32_t check_date_and_time_validity(std::string& date, std::string& time,
                                          onis::core::date_time* dt);
bool extract_date_and_time(const std::string& datetime,
                           onis::core::date_time& dt, bool date_only,
                           bool time_mandatory);
bool extract_time(const std::string& time, std::int32_t* h, std::int32_t* m,
                  std::int32_t* s, std::int32_t* fraction);
}  // namespace onis::util::datetime
