#pragma once

#include <chrono>
#include <cstdint>
#include <string>

namespace onis::core {

const std::uint32_t date_only = 0;
const std::uint32_t date_and_time = 1;

///////////////////////////////////////////////////////////////////////
// date_time
///////////////////////////////////////////////////////////////////////

class date_time {
public:
  // constructor:
  date_time() = default;

  // destructor:
  ~date_time() = default;

  // operators:
  date_time& operator=(const date_time& other);
  bool operator==(date_time& other) const;
  bool operator!=(date_time& other) const;

  // init:
  void init_current_time();
  void set_date(std::uint32_t year, std::uint32_t month, std::uint32_t day);
  void set_date_time(std::uint32_t year, std::uint32_t month, std::uint32_t day,
                     std::uint32_t hour, std::uint32_t minute,
                     std::uint32_t second);
  void set_date_time(std::uint32_t year, std::uint32_t month, std::uint32_t day,
                     std::uint32_t hour, std::uint32_t minute,
                     std::uint32_t second, std::uint32_t millisecond);

  // properties:
  std::uint32_t year() const;
  std::uint32_t month() const;
  std::uint32_t day() const;
  bool get_date(std::uint32_t& year, std::uint32_t& month,
                std::uint32_t& day) const;
  std::uint32_t hour() const;
  std::uint32_t minute() const;
  std::uint32_t second() const;
  std::uint64_t millisecond() const;
  bool get_time(std::uint32_t& hour, std::uint32_t& minute,
                std::uint32_t& second) const;
  bool get_time(std::uint32_t& hour, std::uint32_t& minute,
                std::uint32_t& second, std::uint64_t& millisecond) const;
  bool have_time() const;
  bool is_initialized() const;
  bool is_valid() const;

  // string conversion:
  std::string format(std::uint32_t mode) const;

  // Operations:
  void add_days(std::int32_t day_count);
  void add_seconds(std::int32_t second_count);
  std::uint32_t day_of_week() const;
  std::int64_t time_difference(const date_time& dt) const;
  double time_difference_with_millisec(const date_time& dt) const;
  void invalidate();

protected:
  std::chrono::system_clock::time_point date_time_;
  bool initialized_{false};
  bool have_time_{false};
};

///////////////////////////////////////////////////////////////////////
// time
///////////////////////////////////////////////////////////////////////

class time {
public:
  // constructor:
  time() = default;

  // destructor:
  ~time() = default;

  // operators:
  time& operator=(time& tm);
  bool operator==(time& other) const;
  bool operator!=(time& other) const;

  // int:
  void init_with_current_time();
  void set_time(std::uint32_t hour, std::uint32_t minute, std::uint32_t second);

  // Properties:
  std::uint32_t hour() const;
  std::uint32_t minute() const;
  std::uint32_t second() const;
  bool is_initialized() const;

protected:
  // members:
  bool initialized_{false};
  std::uint32_t hour_{0};
  std::uint32_t minute_{0};
  std::uint32_t second_{0};
};

}  // namespace onis::core
