#pragma once

#include <string>
#include "../core/types.hpp"

#define OS_REGEX_AE "^[a-zA-Z0-9]{1,16}$"
#define OS_REGEX_IP                                                            \
  "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]" \
  "|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
#define OS_REGEX_PORT                                                        \
  "^()([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|" \
  "6553[0-5])$"
#define OS_REGEX_PASSWORD "^[a-zA-Z0-9]{4,}$"
#define OS_REGEX_STR64 "^.{0,64}$"
#define OS_REGEX_STR255 "^.{0,255}$"
#define OS_REGEX_CS "^[A-Z0-9 _]{0,16}$"
#define OS_REGEX_INT32                                                         \
  "^(-?\\d{1,9}|-?1\\d{9}|-?20\\d{8}|-?21[0-3]\\d{7}|-?214[0-6]\\d{6}|-?2147[" \
  "0-3]\\d{5}|-?21474[0-7]\\d{4}|-?214748[012]\\d{4}|-?2147483[0-5]\\d{3}|-?"  \
  "21474836[0-3]\\d{2}|214748364[0-7]|-214748364[0-8])$"
#define OS_REGEX_EMAIL "^.{0,255}$"
#define OS_REGEX_LOGIN "^[a-zA-Z0-9]{4,}$"

namespace onis::util::regex {

void match(const std::string value, const std::string& exp, bool allow_empty);

}  // namespace onis::util::regex
