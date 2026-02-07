#include "../../include/utilities/string.hpp"
#include <iconv.h>  // Will use libiconv header from include directories

namespace onis::util::string {

std::string convert_to_utf8(const std::string& text,
                            const std::string& code_page) {
  // https://design215.com/toolbox/utf8-3byte-characters.php

  if (code_page == "ISO-IR-13") {
    // for dicom, iso-ir-13 includes ISO-IR13 (G1, single byte katakana) and
    // ISO-IR14 (G0 single byte romanjis)
    bool valid = true;
    std::string output;
    for (std::int32_t i = 0; i < text.length(); i++) {
      std::uint8_t c = (std::uint8_t)text[i];

      if (!valid)
        break;
      if (c >= 0xA1 && c <= 0xBF) {  // it is a katakana (first group) ?

        output += 0xEF;
        output += 0xBD;
        output += c;

      } else if (c >= 0xC0 && c <= 0xDF) {  // it is a katakana (second group) ?

        output += 0xEF;
        output += 0xBE;
        output += c - 0x40;

      } else if (c >= 0x20 && c <= 0x7F) {  // is it a romanji ?

        if (c == 0x5C) {  // special yens character

          output += 0xEF;
          output += 0xBF;
          output += 0xD5;
        }
        if (c == 0x7E) {  // special character

          output += 0xEF;
          output += 0xBF;
          output += 0xA3;

        } else
          output += c;

      } else
        valid = false;  // invalid character!
    }
    return valid ? output : "";

  } else {
    if (code_page == "UTF-8")
      return text;
    else {
      std::size_t total = text.size() * 5 + 5;
      char* output = new char[total];
      output[0] = 0;
      char* outptr = output;
      std::size_t avail = total;

      iconv_t cd = iconv_open("UTF-8", code_page.data());
      if (cd != (iconv_t)-1) {
        const char* inptr = text.data();
        std::size_t insize = text.size();
        iconv(cd, &inptr, &insize, &outptr, &avail);
        output[total - avail] = 0;

      } else {
        memcpy(outptr, (char*)text.data(), text.length());
        outptr += text.length();
        *outptr = 0;
        avail -= text.length();
      }
      std::string ret = output;
      delete[] output;
      return ret;
    }
  }
}

void convert_from_utf8(const std::string& str, const std::string& code_page,
                       std::string& output) {
  // https://design215.com/toolbox/utf8-3byte-characters.php
  output.clear();
  /*if (code_page == "ISO-IR-13") {

  //convert utf8 to single byte katakana:
  //https://tools.m-bsys.com/data/charlist_kana.php*/

  if (code_page == "ISO-IR-13") {
    bool valid = true;
    output.clear();
    std::int32_t count = str.length();
    for (std::int32_t i = 0; i < count; i++) {
      if (!valid)
        break;
      std::uint8_t c = (std::uint8_t)str[i];
      if (c == 0xEF) {
        if (i + 2 < count) {
          if ((std::uint8_t)str[i + 1] == 0xBF) {
            // special romanji (IR 14)
            if ((std::uint8_t)str[i + 2] == 0xD5)
              output += 0x5C;
            else if ((std::uint8_t)str[i + 2] == 0xA3)
              output += 0x7E;
            else
              valid = false;

          } else if ((std::uint8_t)str[i + 1] == 0xBD) {
            // katakana first group:
            if ((std::uint8_t)str[i + 2] >= 0xA1 &&
                (std::uint8_t)str[i + 2] <= 0xBF)
              output += (std::uint8_t)str[i + 2];
            else
              valid = false;

          } else if ((std::uint8_t)str[i + 1] == 0xBE) {
            // katakana second group:
            if ((std::uint8_t)str[i + 2] >= 0x80 &&
                (std::uint8_t)str[i + 2] <= 0x9F)
              output += (std::uint8_t)str[i + 2] + 0x40;
            else
              valid = false;

          } else
            valid = false;
          i += 2;

        } else
          valid = false;

      } else if (c >= 0x20 && c <= 0x7F) {
        // japanese romanji (IR 14)
        output += c;

      } else
        valid = false;
    }
    if (!valid)
      output = "";

  } else {
    if (code_page == "UTF-8")
      output = str;
    else {
      iconv_t cd1 = iconv_open(code_page.data(), "UTF-8");
      if (cd1 != (iconv_t)-1) {
        std::size_t total = str.size() * 5 + 5;
        char* output1 = new char[total];
        output1[0] = 0;
        char* outptr = output1;
        std::size_t avail = total;
        const char* inptr = str.data();
        std::size_t insize = str.size();
        iconv(cd1, &inptr, &insize, &outptr, &avail);
        output1[total - avail] = 0;
        output = output1;
        delete[] output1;

      } else
        output = str;
    }
  }
}

std::int32_t convert_to_s32(const std::string& text) {
  return atoi(text.data());
}

std::uint32_t convert_to_u32(const std::string& text) {
  return (std::uint32_t)strtoul(text.data(), nullptr, 10);
}

double convert_to_f64(const std::string& text) {
  return atof(text.data());
}

float convert_to_f32(const std::string& text) {
  return (float)atof(text.data());
}

void replace_antislash_by_slash(std::string& text) {
  std::int32_t length = (std::int32_t)text.length();
  for (std::int32_t i = 0; i < length; i++)
    if (text[i] == '\\')
      text[i] = '/';
}

int sort_ascending(const void* elem1, const void* elem2) {
  std::string node1 = *((std::string*)elem1);
  std::string node2 = *((std::string*)elem2);
  if (node1 == node2)
    return 0;
  else if (node1 > node2)
    return 1;
  else
    return -1;
}

int sort_descending(const void* elem1, const void* elem2) {
  std::string node1 = *((std::string*)elem1);
  std::string node2 = *((std::string*)elem2);
  if (node1 == node2)
    return 0;
  else if (node1 > node2)
    return -1;
  else
    return 1;
}

void sort(std::vector<std::string>& list, bool ascending) {
  std::size_t count = list.size();
  if (count <= 1)
    return;

  std::string* tab = new std::string[count];
  std::int32_t index = 0;
  std::vector<std::string>::iterator it;
  for (it = list.begin(); it != list.end(); it++) {
    tab[index] = *it;
    index++;
  }

  if (ascending)
    qsort(tab, count, sizeof(std::string), sort_ascending);
  else
    qsort(tab, count, sizeof(std::string), sort_descending);

  list.clear();
  for (int i = 0; i < count; i++)
    list.push_back(tab[i]);

  delete[] tab;
}

void split(std::string text, std::vector<std::string>& list,
           const std::string& separators) {
  list.clear();

  if (text.empty()) {
    return;
  }

  if (separators.empty()) {
    // If no separators, return the whole string as a single token
    list.push_back(text);
    return;
  }

  std::string::size_type start = 0;
  std::string::size_type pos = 0;

  while ((pos = text.find_first_of(separators, start)) != std::string::npos) {
    // Extract token from start to pos (before separator)
    if (pos > start) {
      list.push_back(text.substr(start, pos - start));
    } else {
      // Empty token between consecutive separators
      list.push_back("");
    }
    // Move start to after the separator
    start = pos + 1;
  }

  // Add the last token (after the last separator)
  if (start < text.length()) {
    list.push_back(text.substr(start));
  } else if (start == text.length() && !list.empty()) {
    // If text ends with a separator, add empty token
    list.push_back("");
  }
}

bool is_ip4_address(const std::string& str) {
  std::int32_t len = (std::int32_t)str.length();
  std::int32_t ptcnt = 0;
  std::int32_t grplength = 0;
  for (int i = 0; i < len; i++) {
    if (str[i] >= '0' && str[i] <= '9')
      grplength++;
    else if (str[i] == '.') {
      // end of group
      ptcnt++;
      if (grplength == 0)
        return false;
      else if (grplength > 3)
        return false;
      grplength = 0;
    } else
      return false;
  }

  // end of group:
  if (grplength == 0)
    return false;
  else if (grplength > 3)
    return false;
  if (ptcnt != 3)
    return false;
  return true;
}

bool is_unsigned_int(const std::string& str) {
  std::int32_t len = (std::int32_t)str.length();
  if (!len)
    return false;
  for (std::int32_t i = 0; i < len; i++) {
    if (str[i] < 48)
      return false;
    else if (str[i] > 57)
      return false;
  }
  return true;
}

bool is_unsigned_int32(const std::string& str) {
  if (!is_unsigned_int(str))
    return false;

  return true;
}

bool is_unsigned_int16(const std::string& str) {
  if (!is_unsigned_int32(str))
    return false;
  if (atoi(str.data()) > 65536)
    return false;
  return true;
}

bool is_unsigned_int8(const std::string& str) {
  if (!is_unsigned_int32(str))
    return false;
  if (atoi(str.data()) > 256)
    return false;
  return true;
}

bool is_int(const std::string& str) {
  std::int32_t len = (std::int32_t)str.length();
  if (!len)
    return false;
  for (std::int32_t i = 0; i < len; i++) {
    if (str[i] == '-') {
      if (i != 0)
        return false;
    } else if (str[i] < 48)
      return false;
    else if (str[i] > 57)
      return false;
  }
  return true;
}

bool is_int32(const std::string& str) {
  if (!is_int(str))
    return false;
  if (atoi(str.data()) > 2147483647)
    return false;
  else if (atoi(str.data()) < -2147483647 - 1)
    return false;
  return true;
}

bool is_int16(const std::string& str) {
  if (!is_int(str))
    return false;
  std::int32_t value = atoi(str.data());
  if (value > 32767)
    return false;
  else if (value < -32768)
    return false;
  return true;
}

bool is_int8(const std::string& str) {
  if (!is_int(str))
    return false;
  std::int32_t value = atoi(str.data());
  if (value > 127)
    return false;
  else if (value < -128)
    return false;
  return true;
}

bool is_integer_in_range(bool check_min, std::int32_t min_value, bool check_max,
                         std::int32_t max_value, const std::string& str) {
  if (!is_int32(str))
    return false;
  std::int32_t val = atoi(str.data());
  if (check_min)
    if (val < min_value)
      return false;
  if (check_max)
    if (val > max_value)
      return false;
  return true;
}

bool is_float32(const std::string& str) {
  std::int32_t len = (std::int32_t)str.length();
  if (!len)
    return false;

  std::int32_t alreadypoint = 0;
  std::int32_t i_exp = -1;
  for (std::int32_t i = 0; i < len; i++)  // for each caractere of ch
  {
    if ((str[i] == 'e') || (str[i] == 'E')) {
      if (i == 0)
        return false;
      if ((i == 1) && (str[0] == '-'))
        return false;
      i_exp = i;
    } else if (str[i] == '-')  // if the caractere is '-' but not at the
    {
      if (i_exp == -1) {
        if (i != 0)
          return false;
      }  // first place, it's not good.
      else {
        if (i != i_exp + 1)
          return false;
      }
    } else if (str[i] == '+')  // if the caractere is '-' but not at the
    {
      if (i_exp == -1) {
        if (i != 0)
          return false;
      }  // first place, it's not good.
      else {
        if (i != i_exp + 1)
          return false;
      }
    }

    else if (str[i] == '.') {  // if the caractere is '.' but it already
      if (alreadypoint)
        return false;  // exist one, it's not good.
      else
        alreadypoint = 1;
      if (i_exp != -1)
        return false;
    } else if (str[i] < 48)
      return false;  // if the caracter is not between 0 and 9
    else             // it's not good (check with ascii
      if (str[i] > 57)
        return false;  //               caractere code).
  }
  return true;
}

bool get_date_from_string(const std::string& str, std::int32_t start,
                          std::string& year, std::string& month,
                          std::string& day) {
  year = month = day = "";

  std::int32_t index = start;
  std::int32_t count = (std::int32_t)str.length();
  if (index >= count)
    return false;

  // get the year:
  year += str[index];
  index++;
  if (index >= count)
    return false;
  year += str[index];
  index++;
  if (index >= count)
    return false;
  year += str[index];
  index++;
  if (index >= count)
    return false;
  year += str[index];
  index++;
  if (index >= count)
    return false;
  if (str[index] == '.')
    index++;
  if (index >= count)
    return false;

  // get the month:
  month += str[index];
  index++;
  if (index >= count)
    return false;
  month += str[index];
  index++;
  if (index >= count)
    return false;
  if (str[index] == '.')
    index++;
  if (index >= count)
    return false;

  // get the day:
  day += str[index];
  index++;
  if (index >= count)
    return false;
  day += str[index];

  return true;
}

bool get_time_from_string(const std::string& str, std::uint32_t start,
                          std::uint32_t* hour, std::uint32_t* minute,
                          std::uint32_t* second, std::uint32_t* fraction) {
  std::int32_t index = start;
  std::int32_t count = (std::int32_t)str.length();
  if (index >= count)
    return false;

  std::string shour, smin, ssec, sfrac;

  // get the hour:
  shour += str[index];
  index++;
  if (index >= count)
    return false;
  shour += str[index];
  index++;

  if (index < count) {  // get the minutes

    if (str[index] == ':')
      index++;
    if (index >= count)
      return false;
    smin += str[index];
    index++;
    if (index >= count)
      return false;
    smin += str[index];
    index++;
    if (index < count) {  // get the seconds

      if (str[index] == ':')
        index++;
      if (index >= count)
        return false;
      ssec += str[index];
      index++;
      if (index >= count)
        return false;
      ssec += str[index];
      index++;

      if (index < count) {  // get the frac

        if (str[index] == '.') {
          index++;
          if (index >= count)
            return false;
        } else
          return false;
        for (std::int32_t i = 0; i < 6; i++) {
          sfrac += str[index];
          index++;
          if (index >= count)
            break;
        }

        std::int32_t size = (std::int32_t)sfrac.length();
        for (std::int32_t j = size; j < 6; j++)
          sfrac += '0';
      }
    }
  }

  // ok, we check if all datas are valid:
  count = (std::uint32_t)shour.length();
  std::int32_t i;
  for (i = 0; i < count; i++)
    if ((shour[i] < '0') || (shour[i] > '9'))
      return false;

  count = (std::uint32_t)smin.length();
  for (i = 0; i < count; i++)
    if ((smin[i] < '0') || (smin[i] > '9'))
      return false;

  count = (std::uint32_t)ssec.length();
  for (i = 0; i < count; i++)
    if ((ssec[i] < '0') || (ssec[i] > '9'))
      return false;

  count = (std::uint32_t)sfrac.length();
  for (i = 0; i < count; i++)
    if ((sfrac[i] < '0') || (sfrac[i] > '9'))
      return false;

  std::uint32_t ihour = onis::util::string::convert_to_u32(shour);
  std::uint32_t imin = onis::util::string::convert_to_u32(smin);
  std::uint32_t isec = onis::util::string::convert_to_u32(ssec);
  if (ihour >= 24)
    return false;
  if (imin >= 60)
    return false;
  if (isec >= 60)
    return false;

  if (hour)
    *hour = ihour;
  if (minute)
    *minute = imin;
  if (second)
    *second = isec;
  if (fraction)
    *fraction = onis::util::string::convert_to_u32(sfrac);
  return true;
}

bool get_date_range_from_string(const std::string& str,
                                onis::core::date_time* from,
                                onis::core::date_time* to) {
  /* These are the rules:
  1.    The date inside DICOM is formatted as yyyymmdd so
  "19930822" would represent August 22,1993.
  2.    A string of the form "<date1> - <date2>" shall match
  all occurrences of dates which fall between <date1>
  and <date2> inclusive.
  3. A string of the form "- <date1>" shall match all occurrences of
  dates prior to and including <date1>
  4. A string of the form "<date1> -" shall match all occurrences of
  <date1> and subsequent dates
  */

  if (str.empty())
    return false;
  std::string year, month, day;
  if (str[0] == '-') {
    if (!get_date_from_string(str, 1, year, month, day))
      return false;
    to->set_date(onis::util::string::convert_to_u32(year),
                 onis::util::string::convert_to_u32(month),
                 onis::util::string::convert_to_u32(day));

  } else if (str[str.length() - 1] == '-') {
    if (!get_date_from_string(str, 0, year, month, day))
      return false;
    from->set_date(onis::util::string::convert_to_u32(year),
                   onis::util::string::convert_to_u32(month),
                   onis::util::string::convert_to_u32(day));

  } else {
    std::size_t pos = str.find('-');
    if (pos != std::string::npos) {
      if (!get_date_from_string(str, 0, year, month, day))
        return false;
      from->set_date(onis::util::string::convert_to_u32(year),
                     onis::util::string::convert_to_u32(month),
                     onis::util::string::convert_to_u32(day));
      if (!get_date_from_string(str, pos + 1, year, month, day))
        return false;
      to->set_date(onis::util::string::convert_to_u32(year),
                   onis::util::string::convert_to_u32(month),
                   onis::util::string::convert_to_u32(day));

    } else {
      if (!get_date_from_string(str, 0, year, month, day))
        return false;
      from->set_date(onis::util::string::convert_to_u32(year),
                     onis::util::string::convert_to_u32(month),
                     onis::util::string::convert_to_u32(day));
      to->set_date(onis::util::string::convert_to_u32(year),
                   onis::util::string::convert_to_u32(month),
                   onis::util::string::convert_to_u32(day));
    }
  }
  return true;
}

bool get_time_range_from_string(const std::string& str, onis::core::time* from,
                                onis::core::time* to) {
  /* These are the rules:
  1.    The Time inside DICOM is formatted as hhmmss.frac (frac can contains up
  to 6 digits) The format hh:mm:ss.frac is also supported
  2.    A string of the form "<time1> - <time2>" shall match all occurrences of
  times which fall between <time1> and <time2> inclusive.
  3.    A string of the form "-<time1>" shall match all occurrences of times
  prior to and including <time1>
  4.    A string of the form "<time1>-" shall match all occurrences of <time1>
  and subsequent times
  */

  if (str.empty())
    return false;
  std::uint32_t hour, minute, second, fraction;
  if (str[0] == '-') {
    if (!get_time_from_string(str, 1, &hour, &minute, &second, &fraction))
      return false;
    to->set_time(hour, minute, second);

  } else if (str[str.length() - 1] == '-') {
    if (!get_time_from_string(str, 0, &hour, &minute, &second, &fraction))
      return false;
    from->set_time(hour, minute, second);

  } else {
    std::size_t pos = str.find('-');
    if (pos != std::string::npos) {
      if (!get_time_from_string(str, 0, &hour, &minute, &second, &fraction))
        return false;
      to->set_time(hour, minute, second);
      if (!get_time_from_string(str, pos + 1, &hour, &minute, &second,
                                &fraction))
        return false;
      to->set_time(hour, minute, second);

    } else {
      if (!get_time_from_string(str, 0, &hour, &minute, &second, &fraction))
        return false;
      from->set_time(hour, minute, second);
      to->set_time(hour, minute, second);
    }
  }
  return true;
}

}  // namespace onis::util::string
