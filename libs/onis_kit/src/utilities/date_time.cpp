#include "../../include/utilities/date_time.hpp"
#include "../../include/utilities/string.hpp"

namespace onis::util::datetime {

bool is_leap_year(std::int32_t year) {
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

std::int32_t check_date_and_time_validity(std::string& date, std::string& time,
                                          onis::core::date_time* dt) {
  std::int32_t result = 0;
  if (!date.empty()) {
    onis::core::date_time tmp;
    if (!onis::util::datetime::extract_date_and_time(date, tmp, true, false)) {
      date = "";
      time = "";
      return 1;
    } else {
      if (!time.empty()) {
        std::int32_t h, m, s;
        if (!onis::util::datetime::extract_time(time, &h, &m, &s, NULL)) {
          time = "";
          if (dt)
            dt->set_date(tmp.year(), tmp.month(), tmp.day());
          return 2;
        } else {
          if (dt)
            dt->set_date_time(tmp.year(), tmp.month(), tmp.day(), h, m, s);
        }
      } else {
        time = "";
        if (dt)
          dt->set_date(tmp.year(), tmp.month(), tmp.day());
        return 2;
      }
    }
  }
  return 0;
}

template <class T>
bool extract_date_and_time_base(const std::basic_string<T>& datetime,
                                onis::core::date_time& dt, bool date_only,
                                bool time_mandatory) {
  if (datetime.length() < 8)
    return false;
  std::basic_string<T> date = datetime.substr(0, 8);
  for (std::int32_t i = 0; i < 8; i++)
    if ((std::int32_t)date[i] < (std::int32_t)'0' ||
        (std::int32_t)date[i] > (std::int32_t)'9')
      return false;

  std::basic_string<T> year = date.substr(0, 4);
  std::basic_string<T> month = date.substr(4, 2);
  std::basic_string<T> day = date.substr(6, 2);
  std::int32_t iyear = onis::util::string::convert_to_s32(year);
  std::int32_t imonth = onis::util::string::convert_to_s32(month);
  std::int32_t iday = onis::util::string::convert_to_s32(day);
  std::int32_t ihour = 0;
  std::int32_t iminute = 0;
  std::int32_t isecond = 0;

  bool time_valid = false;
  if (!date_only) {
    // is there a time present?
    if (datetime.length() >= 15) {
      std::basic_string<T> time = datetime.substr(9, 6);
      for (std::int32_t i = 0; i < 6; i++)
        if ((std::int32_t)time[i] < (std::int32_t)'0' ||
            (std::int32_t)time[i] > (std::int32_t)'9')
          return false;
      std::basic_string<T> hour = time.substr(0, 2);
      std::basic_string<T> minute = time.substr(2, 2);
      std::basic_string<T> second = time.substr(4, 2);
      ihour = onis::util::string::convert_to_s32(hour);
      iminute = onis::util::string::convert_to_s32(minute);
      isecond = onis::util::string::convert_to_s32(second);
      time_valid = true;
    }
  }

  if (date_only)
    dt.set_date(iyear, imonth, iday);
  else if (time_valid)
    dt.set_date_time(iyear, imonth, iday, ihour, iminute, isecond);
  else if (time_mandatory)
    return false;
  else
    dt.set_date(iyear, imonth, iday);

  // check if the date is valid or not:
  std::int32_t month_len[13] = {0,  31, 28, 31, 30, 31, 30,
                                31, 31, 30, 31, 30, 31};
  if (iyear <= 0 || iyear >= 5000)
    return false;
  if (is_leap_year(iyear))
    month_len[2] = 29;
  if (imonth < 1 || imonth > 12)
    return false;
  if (iday < 1 || iday > month_len[imonth])
    return false;

  // check if the time is valid:
  if (!date_only) {
    if (time_valid) {
      if (ihour < 0 || ihour > 23)
        return false;
      if (iminute < 0 || iminute > 59)
        return false;
      if (isecond < 0 || isecond > 59)
        return false;
    }
  }
  return true;
}

bool extract_date_and_time(const std::string& datetime,
                           onis::core::date_time& dt, bool date_only,
                           bool time_mandatory) {
  return extract_date_and_time_base<char>(datetime, dt, date_only,
                                          time_mandatory);
}

bool extract_time(const std::string& time, std::int32_t* h, std::int32_t* m,
                  std::int32_t* s, std::int32_t* fraction) {
  std::size_t pos = time.find(':');
  std::string hour, minute, second, frac;
  std::int32_t length = (std::int32_t)time.length();
  if (pos == std::string::npos) {
    if (length == 2)
      hour = time.substr(0, 2);
    else if (length == 4) {
      hour = time.substr(0, 2);
      minute = time.substr(2, 2);
    } else if (length >= 6) {
      hour = time.substr(0, 2);
      minute = time.substr(2, 2);
      second = time.substr(4, 2);
      if (length > 6) {
        if (time[6] != '.')
          return false;
        frac = time.substr(7);
      }

    } else
      return false;

  } else {
    // old standard
    if (length == 5) {
      if (time[2] == ':') {
        hour = time.substr(0, 2);
        minute = time.substr(3, 2);

      } else
        return false;

    } else if (length >= 8) {
      if (time[2] == ':' && time[5] == ':') {
        hour = time.substr(0, 2);
        minute = time.substr(3, 2);
        second = time.substr(6, 2);
        if (length > 8) {
          if (time[8] != '.')
            return false;
          frac = time.substr(9);
        }
      }

    } else
      return false;
  }

  // check if the data is valid:
  if (!hour.empty())
    for (std::int32_t i = 0; i < 2; i++)
      if (hour[i] < '0' || hour[i] > '9')
        return false;

  if (!minute.empty())
    for (std::int32_t i = 0; i < 2; i++)
      if (minute[i] < '0' || minute[i] > '9')
        return false;

  if (!second.empty())
    for (std::int32_t i = 0; i < 2; i++)
      if (second[i] < '0' || second[i] > '9')
        return false;

  if (!frac.empty()) {
    for (std::int32_t i = 0; i < (std::int32_t)frac.length(); i++)
      if (frac[i] < '0' || frac[i] > '9')
        return false;

    std::int32_t add = 6 - (std::int32_t)frac.length();
    if (add < 0)
      return false;
    else
      for (std::int32_t i = 0; i < add; i++)
        frac += '0';
  }

  *h = onis::util::string::convert_to_s32(hour);
  *m = onis::util::string::convert_to_s32(minute);
  *s = onis::util::string::convert_to_s32(second);
  if (fraction)
    *fraction = onis::util::string::convert_to_s32(frac);

  if (*h < 0 || *h > 23)
    return false;
  if (*m < 0 || *m > 59)
    return false;
  if (*s < 0 || *s > 59)
    return false;
  return true;
}

}  // namespace onis::util::datetime