#include "../../include/core/date_time.hpp"
#include <ctime>
#include <iomanip>
#include <sstream>

namespace onis::core {

//-----------------------------------------------------------------------
// operators
//-----------------------------------------------------------------------

date_time& date_time::operator=(const date_time& other) {
  if (this == &other)
    return *this;
  date_time_ = other.date_time_;
  initialized_ = other.initialized_;
  have_time_ = other.have_time_;
  return *this;
}

bool date_time::operator==(date_time& other) const {
  if (this == &other)
    return true;
  if (initialized_ && other.initialized_) {
    if (have_time_ == other.have_time_) {
      if (date_time_ == other.date_time_)
        return true;
    }
  } else if (!initialized_ && !other.initialized_)
    return true;

  return false;
}

bool date_time::operator!=(date_time& other) const {
  return !operator==(other);
}

//-----------------------------------------------------------------------
// init
//-----------------------------------------------------------------------

void date_time::init_current_time() {
  date_time_ = std::chrono::system_clock::now();
  initialized_ = true;
  have_time_ = true;
}

void date_time::set_date(std::uint32_t year, std::uint32_t month,
                         std::uint32_t day) {
  try {
    std::tm timeinfo = {};
    timeinfo.tm_year =
        static_cast<int>(year) - 1900;  // tm_year is years since 1900
    timeinfo.tm_mon = static_cast<int>(month) - 1;  // tm_mon is 0-11
    timeinfo.tm_mday = static_cast<int>(day);
    timeinfo.tm_hour = 0;
    timeinfo.tm_min = 0;
    timeinfo.tm_sec = 0;
    timeinfo.tm_isdst = -1;  // Let system determine DST

    std::time_t time_t_value = std::mktime(&timeinfo);
    if (time_t_value == -1) {
      initialized_ = false;
      return;
    }

    date_time_ = std::chrono::system_clock::from_time_t(time_t_value);
    have_time_ = false;
    initialized_ = true;
  } catch (...) {
    initialized_ = false;
  }
}

void date_time::set_date_time(std::uint32_t year, std::uint32_t month,
                              std::uint32_t day, std::uint32_t hour,
                              std::uint32_t minute, std::uint32_t second) {
  try {
    std::tm timeinfo = {};
    timeinfo.tm_year = static_cast<int>(year) - 1900;
    timeinfo.tm_mon = static_cast<int>(month) - 1;
    timeinfo.tm_mday = static_cast<int>(day);
    timeinfo.tm_hour = static_cast<int>(hour);
    timeinfo.tm_min = static_cast<int>(minute);
    timeinfo.tm_sec = static_cast<int>(second);
    timeinfo.tm_isdst = -1;

    std::time_t time_t_value = std::mktime(&timeinfo);
    if (time_t_value == -1) {
      initialized_ = false;
      return;
    }

    date_time_ = std::chrono::system_clock::from_time_t(time_t_value);
    have_time_ = true;
    initialized_ = true;
  } catch (...) {
    initialized_ = false;
  }
}

// Helper function to calculate days since 1970-01-01 for a given date
// This works for dates before 1900 and before Unix epoch (1970)
static std::int64_t days_since_epoch(std::uint32_t year, std::uint32_t month,
                                     std::uint32_t day) {
  // Algorithm based on the proleptic Gregorian calendar
  // Reference: 1970-01-01 (Unix epoch)

  // Adjust month and year for easier calculation
  std::int32_t y = static_cast<std::int32_t>(year);
  std::int32_t m = static_cast<std::int32_t>(month);
  if (m <= 2) {
    y--;
    m += 12;
  }

  // Calculate days using formula
  // Days = 365*y + y/4 - y/100 + y/400 + (153*m+2)/5 + day - 719469
  // 719469 is the offset to make 1970-01-01 = day 0
  std::int64_t days = 365LL * y + y / 4 - y / 100 + y / 400 +
                      (153LL * m + 2) / 5 + day - 719469LL;

  return days;
}

void date_time::set_date_time(std::uint32_t year, std::uint32_t month,
                              std::uint32_t day, std::uint32_t hour,
                              std::uint32_t minute, std::uint32_t second,
                              std::uint32_t millisecond) {
  try {
    // For dates before 1900 or when mktime fails, use manual calculation
    // This handles dates like 1765 correctly
    if (year < 1900) {
      // Calculate days since epoch manually
      std::int64_t days = days_since_epoch(year, month, day);

      // Convert to time_point: days * 86400 seconds + time components
      auto total_seconds = days * 86400LL +
                           static_cast<std::int64_t>(hour) * 3600LL +
                           static_cast<std::int64_t>(minute) * 60LL +
                           static_cast<std::int64_t>(second);

      // Create time_point from epoch (1970-01-01 00:00:00 UTC)
      date_time_ = std::chrono::system_clock::time_point(
          std::chrono::seconds(total_seconds) +
          std::chrono::milliseconds(millisecond));

      have_time_ = true;
      initialized_ = true;
      return;
    }

    // For dates >= 1900, use standard library functions
    std::tm timeinfo = {};
    timeinfo.tm_year =
        static_cast<int>(year) - 1900;  // tm_year is years since 1900
    timeinfo.tm_mon = static_cast<int>(month) - 1;  // tm_mon is 0-11
    timeinfo.tm_mday = static_cast<int>(day);
    timeinfo.tm_hour = static_cast<int>(hour);
    timeinfo.tm_min = static_cast<int>(minute);
    timeinfo.tm_sec = static_cast<int>(second);
    timeinfo.tm_isdst = -1;

    std::time_t time_t_value = std::mktime(&timeinfo);
    if (time_t_value == -1) {
      // If mktime fails (e.g., invalid date), try manual calculation
      std::int64_t days = days_since_epoch(year, month, day);
      auto total_seconds = days * 86400LL +
                           static_cast<std::int64_t>(hour) * 3600LL +
                           static_cast<std::int64_t>(minute) * 60LL +
                           static_cast<std::int64_t>(second);
      date_time_ = std::chrono::system_clock::time_point(
          std::chrono::seconds(total_seconds) +
          std::chrono::milliseconds(millisecond));
    } else {
      // Add milliseconds
      date_time_ = std::chrono::system_clock::from_time_t(time_t_value) +
                   std::chrono::milliseconds(millisecond);
    }

    have_time_ = true;
    initialized_ = true;
  } catch (...) {
    initialized_ = false;
  }
}

//-----------------------------------------------------------------------
// properties
//-----------------------------------------------------------------------

std::uint32_t date_time::year() const {
  if (initialized_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      return static_cast<std::uint32_t>(time_info->tm_year + 1900);
    }
  }
  return 0;
}

std::uint32_t date_time::month() const {
  if (initialized_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      return static_cast<std::uint32_t>(time_info->tm_mon + 1);
    }
  }
  return 0;
}

std::uint32_t date_time::day() const {
  if (initialized_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      return static_cast<std::uint32_t>(time_info->tm_mday);
    }
  }
  return 0;
}

bool date_time::get_date(std::uint32_t& year, std::uint32_t& month,
                         std::uint32_t& day) const {
  if (initialized_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      year = static_cast<std::uint32_t>(time_info->tm_year + 1900);
      month = static_cast<std::uint32_t>(time_info->tm_mon + 1);
      day = static_cast<std::uint32_t>(time_info->tm_mday);
      return true;
    }
  }
  return false;
}

std::uint32_t date_time::hour() const {
  if (initialized_ && have_time_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      return static_cast<std::uint32_t>(time_info->tm_hour);
    }
  }
  return 0;
}

std::uint32_t date_time::minute() const {
  if (initialized_ && have_time_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      return static_cast<std::uint32_t>(time_info->tm_min);
    }
  }
  return 0;
}

std::uint32_t date_time::second() const {
  if (initialized_ && have_time_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      return static_cast<std::uint32_t>(time_info->tm_sec);
    }
  }
  return 0;
}

std::uint64_t date_time::millisecond() const {
  if (initialized_ && have_time_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    auto time_point_sec = std::chrono::system_clock::from_time_t(time_t_value);
    auto diff = date_time_ - time_point_sec;
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(diff);
    return static_cast<std::uint64_t>(ms.count());
  }
  return 0;
}

bool date_time::get_time(std::uint32_t& hour, std::uint32_t& minute,
                         std::uint32_t& second) const {
  if (initialized_ && have_time_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      hour = static_cast<std::uint32_t>(time_info->tm_hour);
      minute = static_cast<std::uint32_t>(time_info->tm_min);
      second = static_cast<std::uint32_t>(time_info->tm_sec);
      return true;
    }
  }
  return false;
}

bool date_time::get_time(std::uint32_t& hour, std::uint32_t& minute,
                         std::uint32_t& second,
                         std::uint64_t& millisecond) const {
  if (initialized_ && have_time_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      hour = static_cast<std::uint32_t>(time_info->tm_hour);
      minute = static_cast<std::uint32_t>(time_info->tm_min);
      second = static_cast<std::uint32_t>(time_info->tm_sec);

      auto time_point_sec =
          std::chrono::system_clock::from_time_t(time_t_value);
      auto diff = date_time_ - time_point_sec;
      auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(diff);
      millisecond = static_cast<std::uint64_t>(ms.count());
      return true;
    }
  }
  return false;
}

bool date_time::have_time() const {
  return have_time_;
}

bool date_time::is_initialized() const {
  return initialized_;
}

bool date_time::is_valid() const {
  if (!initialized_)
    return false;
  // Check if time_point is valid (not at min/max)
  return date_time_ != std::chrono::system_clock::time_point::min() &&
         date_time_ != std::chrono::system_clock::time_point::max();
}

//-----------------------------------------------------------------------
// operations
//-----------------------------------------------------------------------

void date_time::add_days(std::int32_t day_count) {
  if (initialized_) {
    date_time_ += std::chrono::hours(24) * day_count;
  }
}

void date_time::add_seconds(std::int32_t second_count) {
  if (initialized_) {
    date_time_ += std::chrono::seconds(second_count);
  }
}

std::uint32_t date_time::day_of_week() const {
  if (initialized_) {
    auto time_t_value = std::chrono::system_clock::to_time_t(date_time_);
    std::tm* time_info = std::localtime(&time_t_value);
    if (time_info != nullptr) {
      // tm_wday is 0 (Sunday) to 6 (Saturday)
      return static_cast<std::uint32_t>(time_info->tm_wday);
    }
  }
  return 0;
}

std::int64_t date_time::time_difference(const date_time& dt) const {
  if (initialized_) {
    auto diff = date_time_ - dt.date_time_;
    auto seconds = std::chrono::duration_cast<std::chrono::seconds>(diff);
    return seconds.count();
  }
  return 0;
}

double date_time::time_difference_with_millisec(const date_time& dt) const {
  if (initialized_) {
    auto diff = date_time_ - dt.date_time_;
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(diff);
    return ms.count() / 1000.0;
  }
  return 0.0;
}

void date_time::invalidate() {
  initialized_ = false;
}

//-----------------------------------------------------------------------
// string conversion
//-----------------------------------------------------------------------

std::string date_time::format(std::uint32_t mode) const {
  // Default: format as YYYYMMDD_HHMMSS or YYYYMMDD
  if (initialized_) {
    std::ostringstream oss;
    oss << std::setfill('0') << std::setw(4) << year() << std::setw(2)
        << month() << std::setw(2) << day();
    if (mode == date_and_time && have_time_) {
      oss << "_" << std::setw(2) << hour() << std::setw(2) << minute()
          << std::setw(2) << second();
    }
    return oss.str();
  }
  return "";
}

///////////////////////////////////////////////////////////////////////
// time
///////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------
// operators
//-----------------------------------------------------------------------

time& time::operator=(time& tm) {
  if (this == &tm)
    return *this;
  hour_ = tm.hour_;
  minute_ = tm.minute_;
  second_ = tm.second_;
  return *this;
}

bool time::operator==(time& other) const {
  if (this == &other)
    return true;
  if (initialized_ && other.initialized_) {
    if (hour_ != other.hour_)
      return false;
    if (minute_ != other.minute_)
      return false;
    if (second_ != other.second_)
      return false;
    return true;
  } else if (!initialized_ && !other.initialized_)
    return true;
  return false;
}

bool time::operator!=(time& other) const {
  return !operator==(other);
}

//-----------------------------------------------------------------------
// init
//-----------------------------------------------------------------------

void time::init_with_current_time() {
  // Get current time
  auto now = std::chrono::system_clock::now();
  auto time_t_value = std::chrono::system_clock::to_time_t(now);
  std::tm* time_info = std::localtime(&time_t_value);

  if (time_info != nullptr) {
    hour_ = static_cast<std::uint32_t>(time_info->tm_hour);
    minute_ = static_cast<std::uint32_t>(time_info->tm_min);
    second_ = static_cast<std::uint32_t>(time_info->tm_sec);
    initialized_ = true;
  } else {
    initialized_ = false;
  }
}

void time::set_time(std::uint32_t hour, std::uint32_t minute,
                    std::uint32_t second) {
  hour_ = hour;
  minute_ = minute;
  second_ = second;
  initialized_ = true;
}

//-----------------------------------------------------------------------
// properties
//-----------------------------------------------------------------------

std::uint32_t time::hour() const {
  return hour_;
}

std::uint32_t time::minute() const {
  return minute_;
}

std::uint32_t time::second() const {
  return second_;
}

bool time::is_initialized() const {
  return initialized_;
}

}  // namespace onis::core
