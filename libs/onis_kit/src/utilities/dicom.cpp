#include "../../include/utilities/dicom.hpp"
#include "../../include/core/exception.hpp"
#include "../../include/core/result.hpp"
#include "../../include/dicom/dicom.hpp"
#include "../../include/utilities/string.hpp"

#include <iconv.h>

namespace onis::util::dicom {

static std::vector<std::string> page_codes;

const std::vector<std::string>* get_list_of_page_codes() {
  return &page_codes;
}

void init_page_codes(std::vector<std::string>& list) {
  list.push_back("ANSI_X3.4-1968");
  list.push_back("ANSI_X3.4-1986");
  list.push_back("ASCII");
  list.push_back("CP367");
  list.push_back("IBM367");
  list.push_back("ISO-IR-6");
  list.push_back("ISO646-US");
  list.push_back("ISO_646.IRV:1991");
  list.push_back("US");
  list.push_back("US-ASCII");
  list.push_back("CSASCII");
  list.push_back("UTF-8");
  list.push_back("UTF-8-MAC");
  list.push_back("UTF8-MAC");
  list.push_back("ISO-10646-UCS-2");
  list.push_back("UCS-2");
  list.push_back("CSUNICODE");
  list.push_back("UCS-2BE");
  list.push_back("UNICODE-1-1");
  list.push_back("UNICODEBIG");
  list.push_back("CSUNICODE11");
  list.push_back("UCS-2LE");
  list.push_back("UNICODELITTLE");
  list.push_back("ISO-10646-UCS-4");
  list.push_back("UCS-4");
  list.push_back("CSUCS4");
  list.push_back("UCS-4BE");
  list.push_back("UCS-4LE");
  list.push_back("UTF-16");
  list.push_back("UTF-16BE");
  list.push_back("UTF-16LE");
  list.push_back("UTF-32");
  list.push_back("UTF-32BE");
  list.push_back("UTF-32LE");
  list.push_back("UNICODE-1-1-UTF-7");
  list.push_back("UTF-7");
  list.push_back("CSUNICODE11UTF7");
  list.push_back("UCS-2-INTERNAL");
  list.push_back("UCS-2-SWAPPED");
  list.push_back("UCS-4-INTERNAL");
  list.push_back("UCS-4-SWAPPED");
  list.push_back("C99");
  list.push_back("JAVA");
  list.push_back("CP819");
  list.push_back("IBM819");
  list.push_back("ISO-8859-1");
  list.push_back("ISO-IR-100");
  list.push_back("ISO8859-1");
  list.push_back("ISO_8859-1");
  list.push_back("ISO_8859-1:1987");
  list.push_back("L1");
  list.push_back("LATIN1");
  list.push_back("CSISOLATIN1");
  list.push_back("ISO-8859-2");
  list.push_back("ISO-IR-101");
  list.push_back("ISO8859-2");
  list.push_back("ISO_8859-2");
  list.push_back("ISO_8859-2:1987");
  list.push_back("L2");
  list.push_back("LATIN2");
  list.push_back("CSISOLATIN2");
  list.push_back("ISO-8859-3");
  list.push_back("ISO-IR-109");
  list.push_back("ISO8859-3");
  list.push_back("ISO_8859-3");
  list.push_back("ISO_8859-3:1988");
  list.push_back("L3");
  list.push_back("LATIN3");
  list.push_back("CSISOLATIN3");
  list.push_back("ISO-8859-4");
  list.push_back("ISO-IR-110");
  list.push_back("ISO8859-4");
  list.push_back("ISO_8859-4");
  list.push_back("ISO_8859-4:1988");
  list.push_back("L4");
  list.push_back("LATIN4");
  list.push_back("CSISOLATIN4");
  list.push_back("CYRILLIC");
  list.push_back("ISO-8859-5");
  list.push_back("ISO-IR-144");
  list.push_back("ISO8859-5");
  list.push_back("ISO_8859-5");
  list.push_back("ISO_8859-5:1988");
  list.push_back("CSISOLATINCYRILLIC");
  list.push_back("ARABIC");
  list.push_back("ASMO-708");
  list.push_back("ECMA-114");
  list.push_back("ISO-8859-6");
  list.push_back("ISO-IR-127");
  list.push_back("ISO8859-6");
  list.push_back("ISO_8859-6");
  list.push_back("ISO_8859-6:1987");
  list.push_back("CSISOLATINARABIC");
  list.push_back("ECMA-118");
  list.push_back("ELOT_928");
  list.push_back("GREEK");
  list.push_back("GREEK8");
  list.push_back("ISO-8859-7");
  list.push_back("ISO-IR-126");
  list.push_back("ISO8859-7");
  list.push_back("ISO_8859-7");
  list.push_back("ISO_8859-7:1987");
  list.push_back("ISO_8859-7:2003");
  list.push_back("CSISOLATINGREEK");
  list.push_back("HEBREW");
  list.push_back("ISO-8859-8");
  list.push_back("ISO-IR-138");
  list.push_back("ISO8859-8");
  list.push_back("ISO_8859-8");
  list.push_back("ISO_8859-8:1988");
  list.push_back("CSISOLATINHEBREW");
  list.push_back("ISO-8859-9");
  list.push_back("ISO-IR-148");
  list.push_back("ISO8859-9");
  list.push_back("ISO_8859-9");
  list.push_back("ISO_8859-9:1989");
  list.push_back("L5");
  list.push_back("LATIN5");
  list.push_back("CSISOLATIN5");
  list.push_back("ISO-8859-10");
  list.push_back("ISO-IR-157");
  list.push_back("ISO8859-10");
  list.push_back("ISO_8859-10");
  list.push_back("ISO_8859-10:1992");
  list.push_back("L6");
  list.push_back("LATIN6");
  list.push_back("CSISOLATIN6");
  list.push_back("ISO-8859-11");
  list.push_back("ISO8859-11");
  list.push_back("ISO_8859-11");
  list.push_back("ISO-8859-13");
  list.push_back("ISO-IR-179");
  list.push_back("ISO8859-13");
  list.push_back("ISO_8859-13");
  list.push_back("L7");
  list.push_back("LATIN7");
  list.push_back("ISO-8859-14");
  list.push_back("ISO-CELTIC");
  list.push_back("ISO-IR-199");
  list.push_back("ISO8859-14");
  list.push_back("ISO_8859-14");
  list.push_back("ISO_8859-14:1998");
  list.push_back("L8");
  list.push_back("LATIN8");
  list.push_back("ISO-8859-15");
  list.push_back("ISO-IR-203");
  list.push_back("ISO8859-15");
  list.push_back("ISO_8859-15");
  list.push_back("ISO_8859-15:1998");
  list.push_back("LATIN-9");
  list.push_back("ISO-8859-16");
  list.push_back("ISO-IR-226");
  list.push_back("ISO8859-16");
  list.push_back("ISO_8859-16");
  list.push_back("ISO_8859-16:2001");
  list.push_back("L10");
  list.push_back("LATIN10");
  list.push_back("KOI8-R");
  list.push_back("CSKOI8R");
  list.push_back("KOI8-U");
  list.push_back("KOI8-RU");
  list.push_back("CP1250");
  list.push_back("MS-EE");
  list.push_back("WINDOWS-1250");
  list.push_back("CP1251");
  list.push_back("MS-CYRL");
  list.push_back("WINDOWS-1251");
  list.push_back("CP1252");
  list.push_back("MS-ANSI");
  list.push_back("WINDOWS-1252");
  list.push_back("CP1253");
  list.push_back("MS-GREEK");
  list.push_back("WINDOWS-1253");
  list.push_back("CP1254");
  list.push_back("MS-TURK");
  list.push_back("WINDOWS-1254");
  list.push_back("CP1255");
  list.push_back("MS-HEBR");
  list.push_back("WINDOWS-1255");
  list.push_back("CP1256");
  list.push_back("MS-ARAB");
  list.push_back("WINDOWS-1256");
  list.push_back("CP1257");
  list.push_back("WINBALTRIM");
  list.push_back("WINDOWS-1257");
  list.push_back("CP1258");
  list.push_back("WINDOWS-1258");
  list.push_back("850");
  list.push_back("CP850");
  list.push_back("IBM850");
  list.push_back("CSPC850MULTILINGUAL");
  list.push_back("862");
  list.push_back("CP862");
  list.push_back("IBM862");
  list.push_back("CSPC862LATINHEBREW");
  list.push_back("866");
  list.push_back("CP866");
  list.push_back("IBM866");
  list.push_back("CSIBM866");
  list.push_back("CP1131");
  list.push_back("MAC");
  list.push_back("MACINTOSH");
  list.push_back("MACROMAN");
  list.push_back("CSMACINTOSH");
  list.push_back("MACCENTRALEUROPE");
  list.push_back("MACICELAND");
  list.push_back("MACCROATIAN");
  list.push_back("MACROMANIA");
  list.push_back("MACCYRILLIC");
  list.push_back("MACUKRAINE");
  list.push_back("MACGREEK");
  list.push_back("MACTURKISH");
  list.push_back("MACHEBREW");
  list.push_back("MACARABIC");
  list.push_back("MACTHAI");
  list.push_back("HP-ROMAN8");
  list.push_back("R8");
  list.push_back("ROMAN8");
  list.push_back("CSHPROMAN8");
  list.push_back("NEXTSTEP");
  list.push_back("ARMSCII-8");
  list.push_back("GEORGIAN-ACADEMY");
  list.push_back("GEORGIAN-PS");
  list.push_back("KOI8-T");
  list.push_back("CP154");
  list.push_back("CYRILLIC-ASIAN");
  list.push_back("PT154");
  list.push_back("PTCP154");
  list.push_back("CSPTCP154");
  list.push_back("KZ-1048");
  list.push_back("RK1048");
  list.push_back("STRK1048-2002");
  list.push_back("CSKZ1048");
  list.push_back("MULELAO-1");
  list.push_back("CP1133");
  list.push_back("IBM-CP1133");
  list.push_back("ISO-IR-166");
  list.push_back("TIS-620");
  list.push_back("TIS620");
  list.push_back("TIS620-0");
  list.push_back("TIS620.2529-1");
  list.push_back("TIS620.2533-0");
  list.push_back("TIS620.2533-1");
  list.push_back("CP874");
  list.push_back("WINDOWS-874");
  list.push_back("VISCII");
  list.push_back("VISCII1.1-1");
  list.push_back("CSVISCII");
  list.push_back("TCVN");
  list.push_back("TCVN-5712");
  list.push_back("TCVN5712-1");
  list.push_back("TCVN5712-1:1993");
  list.push_back("ISO-IR-14");
  list.push_back("ISO646-JP");
  list.push_back("JIS_C6220-1969-RO");
  list.push_back("JP");
  list.push_back("CSISO14JISC6220RO");
  list.push_back("JISX0201-1976");
  list.push_back("JIS_X0201");
  list.push_back("X0201");
  list.push_back("CSHALFWIDTHKATAKANA");
  list.push_back("ISO-IR-87");
  list.push_back("JIS0208");
  list.push_back("JIS_C6226-1983");
  list.push_back("JIS_X0208");
  list.push_back("JIS_X0208-1983");
  list.push_back("JIS_X0208-1990");
  list.push_back("X0208");
  list.push_back("CSISO87JISX0208");
  list.push_back("ISO-IR-159");
  list.push_back("JIS_X0212");
  list.push_back("JIS_X0212-1990");
  list.push_back("JIS_X0212.1990-0");
  list.push_back("X0212");
  list.push_back("CSISO159JISX02121990");
  list.push_back("CN");
  list.push_back("GB_1988-80");
  list.push_back("ISO-IR-57");
  list.push_back("ISO646-CN");
  list.push_back("CSISO57GB1988");
  list.push_back("CHINESE");
  list.push_back("GB_2312-80");
  list.push_back("ISO-IR-58");
  list.push_back("CSISO58GB231280");
  list.push_back("CN-GB-ISOIR165");
  list.push_back("ISO-IR-165");
  list.push_back("ISO-IR-149");
  list.push_back("KOREAN");
  list.push_back("KSC_5601");
  list.push_back("KS_C_5601-1987");
  list.push_back("KS_C_5601-1989");
  list.push_back("CSKSC56011987");
  list.push_back("EUC-JP");
  list.push_back("EUCJP");
  list.push_back("EXTENDED_UNIX_CODE_PACKED_FORMAT_FOR_JAPANESE");
  list.push_back("CSEUCPKDFMTJAPANESE");
  list.push_back("MS_KANJI");
  list.push_back("SHIFT-JIS");
  list.push_back("SHIFT_JIS");
  list.push_back("SJIS");
  list.push_back("CSSHIFTJIS");
  list.push_back("CP932");
  list.push_back("ISO-2022-JP");
  list.push_back("CSISO2022JP");
  list.push_back("ISO-2022-JP-1");
  list.push_back("ISO-2022-JP-2");
  list.push_back("CSISO2022JP2");
  // list.push_back("CP50221");
  list.push_back("ISO-2022-JP-MS");
  list.push_back("CN-GB");
  list.push_back("EUC-CN");
  list.push_back("EUCCN");
  list.push_back("GB2312");
  list.push_back("CSGB2312");
  list.push_back("GBK");
  list.push_back("CP936");
  list.push_back("MS936");
  list.push_back("WINDOWS-936");
  list.push_back("GB18030");
  list.push_back("ISO-2022-CN");
  list.push_back("CSISO2022CN");
  list.push_back("ISO-2022-CN-EXT");
  list.push_back("HZ");
  list.push_back("HZ-GB-2312");
  list.push_back("EUC-TW");
  list.push_back("EUCTW CSEUCTW");
  list.push_back("BIG-5");
  list.push_back("BIG-FIVE");
  list.push_back("BIG5");
  list.push_back("BIGFIVE");
  list.push_back("CN-BIG5");
  list.push_back("CSBIG5");
  list.push_back("CP950");
  list.push_back("BIG5-HKSCS:1999");
  list.push_back("BIG5-HKSCS:2001");
  list.push_back("BIG5-HKSCS:2004");
  list.push_back("BIG5-HKSCS");
  list.push_back("BIG5-HKSCS:2008");
  list.push_back("BIG5HKSCS");
  list.push_back("EUC-KR");
  list.push_back("EUCKR");
  list.push_back("CSEUCKR");
  list.push_back("CP949");
  list.push_back("UHC");
  list.push_back("CP1361");
  list.push_back("JOHAB");
  list.push_back("ISO-2022-KR");
  list.push_back("CSISO2022KR");
  list.push_back("CP856");
  list.push_back("CP922");
  list.push_back("CP943");
  list.push_back("CP1046");
  list.push_back("CP1124");
  list.push_back("CP1129");
  list.push_back("CP1161");
  list.push_back("IBM-1161");
  list.push_back("IBM1161");
  list.push_back("CSIBM1161");
  list.push_back("CP1162");
  list.push_back("IBM-1162");
  list.push_back("IBM1162");
  list.push_back("CSIBM1162");
  list.push_back("CP1163");
  list.push_back("IBM-1163");
  list.push_back("IBM1163");
  list.push_back("CSIBM1163");
  list.push_back("DEC-KANJI");
  list.push_back("DEC-HANYU");
  list.push_back("437");
  list.push_back("CP437");
  list.push_back("IBM437");
  list.push_back("CSPC8CODEPAGE437");
  list.push_back("CP737");
  list.push_back("CP775");
  list.push_back("IBM775");
  list.push_back("CSPC775BALTIC");
  list.push_back("852");
  list.push_back("CP852");
  list.push_back("IBM852");
  list.push_back("CSPCP852");
  list.push_back("CP853");
  list.push_back("855");
  list.push_back("CP855");
  list.push_back("IBM855");
  list.push_back("CSIBM855");
  list.push_back("857");
  list.push_back("CP857");
  list.push_back("IBM857");
  list.push_back("CSIBM857");
  list.push_back("CP858");
  list.push_back("860");
  list.push_back("CP860");
  list.push_back("IBM860");
  list.push_back("CSIBM860");
  list.push_back("861");
  list.push_back("CP-IS");
  list.push_back("CP861");
  list.push_back("IBM861");
  list.push_back("CSIBM861");
  list.push_back("863");
  list.push_back("CP863");
  list.push_back("IBM863");
  list.push_back("CSIBM863");
  list.push_back("CP864");
  list.push_back("IBM864");
  list.push_back("CSIBM864");
  list.push_back("865");
  list.push_back("CP865");
  list.push_back("IBM865");
  list.push_back("CSIBM865");
  list.push_back("869");
  list.push_back("CP-GR");
  list.push_back("CP869");
  list.push_back("IBM869");
  list.push_back("CSIBM869");
  list.push_back("CP1125");
  list.push_back("EUC-JIS-2004");
  list.push_back("EUC-JISX0213");
  list.push_back("SHIFT_JIS-2004");
  list.push_back("SHIFT_JISX0213");
  list.push_back("ISO-2022-JP-2004");
  list.push_back("ISO-2022-JP-3");
  list.push_back("BIG5-2003");
  list.push_back("ISO-IR-230");
  list.push_back("TDS565");
  list.push_back("ATARI");
  list.push_back("ATARIST");
  list.push_back("RISCOS-LATIN1");
}

void remove_first_escape_sequence_if_same_than_default(
    std::string& str, const std::string& default_esc) {
  if (str.size() < default_esc.size())
    return;
  std::string compare_to = default_esc;
  std::int32_t count = (std::int32_t)compare_to.size();

  std::string first_escape;
  for (std::int32_t i = 0; i < count; i++)
    first_escape += str[i];
  if (first_escape == default_esc)
    str = str.substr(count);
  else {
    // if the first escape is IR14 and the default escape is IR13, we consider
    // this the same:
    if (first_escape[1] == 0x28 && first_escape[2] == 0x4A)
      if (default_esc.size() == 3) {
        if (default_esc[0] == 0x29 && default_esc[1] == 0x49) {
          str = str.substr(count);
        }
      }
  }
}

void add_first_escape_sequence_if_different_than_default(
    std::string& str, const std::string& current_esc,
    const std::string& default_esc) {
  if (current_esc == default_esc)
    return;
  else {
    // if the current escape if IR14 and the default escape is IR13, we don't
    // need to add
    bool add = true;
    if (current_esc.size() == 3 && default_esc.size() == 3)
      if (current_esc[1] == 0x28 && current_esc[2] == 0x4A)
        if (default_esc[1] == 0x29 && default_esc[2] == 0x49)
          add = false;
    if (add)
      str = current_esc + str;
  }
}

void remove_duplicated_escapes(const onis::dicom_manager_ptr& manager,
                               std::string& str,
                               const std::string& default_esc) {
  std::string current_esc = default_esc;

  std::string final_value;
  std::int32_t count = (std::int32_t)str.size();
  for (std::int32_t i = 0; i < count; i++) {
    if (str[i] == 0x1B) {
      std::string new_esc;
      if (i + 3 <= count) {
        new_esc += str[i];
        new_esc += str[i + 1];
        new_esc += str[i + 2];
        if (manager->find_character_set_by_escape(new_esc, nullptr, nullptr) ==
            nullptr) {
          if (i + 4 <= count) {
            new_esc += str[i + 3];
            if (manager->find_character_set_by_escape(new_esc, nullptr,
                                                      nullptr) == nullptr) {
              new_esc = "";
            }
          }
        }
      }
      if (new_esc.empty()) {
        // unknown escape!
        // we keep it
        final_value += str[i];

      } else {
        bool keep_it = true;
        if (new_esc == current_esc)
          keep_it = false;
        if (keep_it) {
          final_value += str[i];
          current_esc = new_esc;

        } else
          i += (std::int32_t)new_esc.size() - 1;
      }

    } else
      final_value += str[i];
  }
  str = final_value;
}

void get_escape_list(const onis::dicom_manager_ptr& manager,
                     const std::string& str, const std::string& default_esc,
                     std::vector<std::string>& list) {
  std::int32_t count = (std::int32_t)str.size();

  bool add_default = true;
  if (!str.empty())
    if (str[0] == 0x1B)
      add_default = false;

  if (add_default) {
    if (default_esc.empty())
      list.push_back("ISO 2022 IR 6");
    else {
      const onis::dicom_charset_info* info;
      const dicom_charset* set =
          manager->find_character_set_by_escape(default_esc, &info, nullptr);
      if (info != nullptr) {
        std::string defined_term = info->defined_term;
        if (defined_term == "ISO 2022 IR 14")
          defined_term = "ISO 2022 IR 13";
        if (std::find(list.begin(), list.end(), defined_term) == list.end())
          list.push_back(defined_term);
      }
    }
  }

  for (std::int32_t i = 0; i < count; i++) {
    if (str[i] == 0x1B) {
      if (i + 3 <= count) {
        std::string new_esc;
        new_esc += str[i];
        new_esc += str[i + 1];
        new_esc += str[i + 2];

        const onis::dicom_charset_info* info;
        const dicom_charset* set =
            manager->find_character_set_by_escape(new_esc, &info, nullptr);
        if (set == nullptr) {
          if (i + 4 <= count) {
            new_esc += str[i + 3];
            set =
                manager->find_character_set_by_escape(new_esc, &info, nullptr);
          }
        }
        if (info != nullptr) {
          std::string defined_term = info->defined_term;
          if (defined_term == "ISO 2022 IR 14")
            defined_term = "ISO 2022 IR 13";
          if (std::find(list.begin(), list.end(), defined_term) == list.end())
            list.push_back(defined_term);
        }
      }
    }
  }
}

bool contains_multibyte_characters(const onis::dicom_manager_ptr& manager,
                                   const std::string& utf8_str,
                                   const std::string& code_page) {
  if (!utf8_str.empty()) {
    std::string buf;
    onis::util::string::convert_from_utf8(utf8_str, code_page, buf);
    std::int32_t size = (std::int32_t)buf.length();
    for (std::int32_t j = 0; j < size - 3; j++) {
      if (buf[j] == 0x1B) {
        if (j + 2 < size) {
          std::string escape;
          escape += buf[j];
          escape += buf[j + 1];
          escape += buf[j + 2];
          const onis::dicom_charset_info* info = nullptr;
          if (!manager->find_character_set_by_escape(escape, &info, nullptr)) {
            if (j + 3 < size) {
              escape += buf[j + 3];
              manager->find_character_set_by_escape(escape, &info, nullptr);
            }
          }
          if (info != nullptr) {
            if (!info->single_byte)
              return true;
          }
        }
      }
    }
  }
  return false;
}

void check_character_offset(std::string& str) {
  if (!str.empty()) {
    if (str.length() >= 3) {
      if (str[0] == 0x1B && str[1] == 0x29 && str[2] == 0x49) {
        std::string convert;
        convert += 0x1B;
        convert += 0x28;
        convert += 0x49;
        std::int8_t offset = 128;
        for (std::int32_t i = 3; i < str.length(); i++) {
          if (std::int8_t(str[i]) > (0x20 + offset) &&
              std::int8_t(str[i]) < (0x60 + offset))
            convert += std::int8_t(str[i]) - offset;
          else
            convert += str[i];
        }
        str = convert;
      }
    }
  }
}

void find_all_compatible_charsets(
    const onis::dicom_manager_ptr& manager, const std::string& str,
    std::list<const onis::dicom_charset*>& charsets) {
  const onis::dicom_charset_list* list = manager->get_character_set_list();
  onis::dicom_charset_list::const_iterator it;
  for (it = list->begin(); it != list->end(); it++) {
    if (is_value_compatible_with_character_set(manager, *it, str)) {
      if (std::find(charsets.begin(), charsets.end(), *it) == charsets.end())
        charsets.push_back(*it);
    }
  }
}

bool is_value_compatible_with_character_set(
    const onis::dicom_manager_ptr& manager, const onis::dicom_charset* set,
    const std::string& str) {
  // empty strings are always compatible:
  if (str.empty())
    return true;

  for (auto& info : set->info) {
    std::string tmp, back;
    onis::util::string::convert_from_utf8(str, info->code_page, tmp);
    back = onis::util::string::convert_to_utf8(tmp, info->code_page);
    if (back == str)
      return true;
  }
  return false;
}

void find_common_charsets(const onis::dicom_manager_ptr& manager,
                          const std::vector<std::string>& list,
                          std::list<const onis::dicom_charset*>& charsets) {
  bool first_time = true;
  for (std::vector<std::string>::const_iterator it = list.begin();
       it != list.end(); it++) {
    if ((*it).empty())
      continue;
    if (first_time) {
      onis::util::dicom::find_all_compatible_charsets(manager, *it, charsets);
      first_time = false;

    } else {
      std::list<const onis::dicom_charset*> tmp;
      onis::util::dicom::find_all_compatible_charsets(manager, *it, tmp);
      intersect_charset_lists(charsets, tmp);
    }
  }
}

void intersect_charset_lists(
    std::list<const onis::dicom_charset*>& charsets,
    const std::list<const onis::dicom_charset*>& list) {
  std::list<const onis::dicom_charset*>::iterator it1 = charsets.begin();
  while (it1 != charsets.end()) {
    if (std::find(list.begin(), list.end(), *it1) == list.end()) {
      std::list<const onis::dicom_charset*>::iterator it2 = it1;
      it1++;
      charsets.erase(it2);

    } else
      it1++;
  }
}

void make_group_name_short(std::string& group) {
  std::int32_t count = 0;
  for (std::int64_t i = group.length() - 1; i >= 0; i--)
    if (group[i] == '^')
      count++;
    else
      break;
  if (count > 0)
    group = group.substr(0, group.length() - count);
}

bool is_person_name_identical(std::string N1[5], std::string I1[5],
                              std::string P1[5], std::string N2[5],
                              std::string I2[5], std::string P2[5]) {
  for (std::int32_t i = 0; i < 5; i++) {
    if ((!N1[i].empty()) || (!N2[i].empty()))
      if (N1[i] != N2[i])
        return false;
    if ((!I1[i].empty()) || (!I2[i].empty()))
      if (I1[i] != I2[i])
        return false;
    if ((!P1[i].empty()) || (!P2[i].empty()))
      if (P1[i] != P2[i])
        return false;
  }
  return true;
}

void decode_person_name(const std::string& full_name, std::string& name,
                        std::string& ideogram, std::string& phonetic,
                        bool make_short) {
  name = "";
  ideogram = "";
  phonetic = "";
  if (full_name.empty())
    return;
  std::size_t pos = full_name.find('=');
  if (pos == std::string::npos)
    name = full_name;
  else {
    name = full_name.substr(0, pos);
    std::string remaining = full_name.substr(pos + 1);
    pos = remaining.find('=');
    if (pos == std::string::npos)
      ideogram = remaining;
    else {
      ideogram = remaining.substr(0, pos);
      phonetic = remaining.substr(pos + 1);
    }
  }

  if (make_short) {
    for (std::int32_t i = 0; i < 3; i++) {
      std::string* str;
      switch (i) {
        case 0:
          str = &name;
          break;
        case 1:
          str = &ideogram;
          break;
        case 2:
          str = &phonetic;
          break;
        default:
          str = nullptr;
          break;
      };

      if (!str->empty()) {
        std::int32_t count = 0;
        std::int32_t j = (std::int32_t)str->length() - 1;
        while ((*str)[j] == '^' && j >= 0) {
          count++;
          j--;
        }
        if (count > 0)
          *str = str->substr(0, str->length() - count);
      }
    }
  }
}

void decode_person_name(const std::string& full_name, std::string name[5],
                        std::string ideogram[5], std::string phonetic[5]) {
  for (std::int32_t i = 0; i < 5; i++) {
    name[i] = "";
    ideogram[i] = "";
    phonetic[i] = "";
  }
  if (full_name.empty())
    return;

  std::int32_t component = 0;
  std::string group_name, group_ideo, group_phono;

  // we separate by group:
  std::size_t pos = full_name.find('=');
  if (pos == std::string::npos)
    group_name = full_name;
  else {
    group_name = full_name.substr(0, pos);
    std::string remaining = full_name.substr(pos + 1);
    pos = remaining.find('=');
    if (pos == std::string::npos)
      group_ideo = remaining;
    else {
      group_ideo = remaining.substr(0, pos);
      group_phono = remaining.substr(pos + 1);
    }
  }

  // ok, we have to separate by components:
  std::string* target;
  std::string* study;
  for (int i = 0; i < 3; i++) {
    component = 0;
    switch (i) {
      case 0:
        target = &name[0];
        study = &group_name;
        break;
      case 1:
        target = &ideogram[0];
        study = &group_ideo;
        break;
      case 2:
        target = &phonetic[0];
        study = &group_phono;
        break;
      default:
        target = nullptr;
        study = nullptr;
        break;
    };

    while (1) {
      pos = study->find('^');
      if (pos == std::string::npos) {
        target[component] = *study;
        break;

      } else {
        target[component] = study->substr(0, pos);
        *study = study->substr(pos + 1);
        component++;
        if (component == 4) {
          target[component] = *study;
          break;
        }
      }
    }
  }
}

bool ensure_single_byte_first_charset(const onis::dicom_manager_ptr& manager,
                                      std::string& file_charset) {
  // get the first character set:
  std::string tmp;
  std::size_t pos = file_charset.find("\\");
  if (pos == std::string::npos)
    tmp = file_charset;
  else
    tmp = file_charset.substr(0, pos);

  // if not character set is found, it is IR6, so we are fine:
  if (tmp.empty())
    return false;

  // retrieve the character set information:
  const onis::dicom_charset* default_file_set = nullptr;
  const onis::dicom_charset_info* default_file_charset_info = nullptr;
  default_file_set = manager->find_character_set_by_iso_number(
      tmp, &default_file_charset_info);

  // if we don't know anything about this character set, simply return:
  if (default_file_charset_info == nullptr)
    return false;

  // if the default character set is a single byte one or if it is unicode, just
  // leave:
  if (default_file_charset_info->single_byte ||
      default_file_charset_info->no_extention_term == "UNICODE")
    return false;

  // ok, we need to modify the character set.
  // we need to search the most appropriate one:
  std::string new_char_set;
  const onis::dicom_charset* set = default_file_set;
  onis::dicom_charset_info_list::const_iterator it1;
  for (it1 = set->info.begin(); it1 != set->info.end(); it1++) {
    if ((*it1)->single_byte) {
      new_char_set = (*it1)->defined_term;
      break;
    }
  }
  std::vector<std::string> current;
  onis::util::string::split(file_charset, current, "\\");
  file_charset = construct_new_char_tag(manager, new_char_set, current);
  return true;
}

std::string construct_new_char_tag(
    const onis::dicom_manager_ptr& manager, const std::string& current_charset,
    const std::vector<std::string>& additional_charset) {
  std::vector<std::string> current;

  std::size_t pos = current_charset.find("\\");
  if (pos == 0)
    current.push_back("ISO 2022 IR 6");

  onis::util::string::split(current_charset, current, "\\");
  if (current.empty())
    current.push_back("");

  onis::dicom_charset_info_list current_info;

  std::vector<std::string>::const_iterator it1;
  for (it1 = current.begin(); it1 != current.end(); it1++) {
    const onis::dicom_charset_info* info;
    manager->find_character_set_by_iso_number(*it1, &info);
    if (info != nullptr)
      current_info.push_back((onis::dicom_charset_info*)info);
  }

  for (it1 = additional_charset.begin(); it1 != additional_charset.end();
       it1++) {
    if (std::find(current.begin(), current.end(), *it1) == current.end()) {
      const onis::dicom_charset_info* info;
      manager->find_character_set_by_iso_number(*it1, &info);
      if (info == nullptr) {
        current.push_back(*it1);

      } else {
        if (std::find(current_info.begin(), current_info.end(), info) ==
            current_info.end()) {
          current.push_back(*it1);
          current_info.push_back((onis::dicom_charset_info*)info);
        }
      }
    }
  }
  std::string new_char_tag;
  for (it1 = current.begin(); it1 != current.end(); it1++) {
    if (it1 == current.begin()) {
      if (*it1 != "ISO 2022 IR 6" && !(*it1).empty()) {
        new_char_tag = *it1;
      }

    } else
      new_char_tag += "\\" + *it1;
  }
  return new_char_tag;
}

void encode_person_name(std::string name[5], std::string ideogram[5],
                        std::string phonetic[5], std::string& output) {
  std::string grp_name, grp_ideo, grp_phono;
  encode_group_name(name, grp_name);
  encode_group_name(ideogram, grp_ideo);
  encode_group_name(phonetic, grp_phono);
  encode_person_name(grp_name, grp_ideo, grp_phono, output);
}

void encode_person_name(std::string name, std::string ideogram,
                        std::string phonetic, std::string& output) {
  output = name;
  if (ideogram.empty()) {
    if (!phonetic.empty())
      output += "==" + phonetic;

  } else {
    output += "=" + ideogram;
    if (!phonetic.empty())
      output += "=" + phonetic;
  }
}

void encode_group_name(std::string name[5], std::string& output) {
  output.clear();
  bool delimiter = false;
  for (std::int32_t i = 4; i >= 0; i--) {
    if (!name[i].empty()) {
      if (delimiter)
        output = "^" + output;
      output = name[i] + output;
      delimiter = true;

    } else if (delimiter)
      output = "^" + output;
  }
}

void decode_group_name(std::string name, std::string output[5]) {
  for (std::int32_t i = 0; i < 5; i++)
    output[i] = "";
  if (name.empty())
    return;

  std::int32_t component = 0;
  // ok, we have to separate by components:
  std::string* target = &output[0];
  std::string* study = &name;
  while (1) {
    std::size_t pos = study->find('^');
    if (pos == std::string::npos) {
      target[component] = *study;
      break;

    } else {
      target[component] = study->substr(0, pos);
      *study = study->substr(pos + 1);
      component++;
      if (component == 4) {
        target[component] = *study;
        break;
      }
    }
  }
}

void get_full_name(const std::string& name, const std::string& ideo,
                   const std::string& phono, std::string& output) {
  output = name;
  if (ideo.empty()) {
    if (!phono.empty())
      output += "==" + phono;

  } else {
    output += "=" + ideo;
    if (!phono.empty())
      output += "=" + phono;
  }
}

bool is_person_name_length_is_valid(std::string name[5],
                                    std::string ideogram[5],
                                    std::string phonetic[5],
                                    std::int32_t* group) {
  for (std::int32_t k = 0; k < 3; k++) {
    std::string* input;
    switch (k) {
      case 0:
        input = name;
        break;
      case 1:
        input = ideogram;
        break;
      case 2:
        input = phonetic;
        break;
      default:
        input = nullptr;
        break;
    };
    std::string group_name;
    encode_group_name(input, group_name);
    if (group_name.length() > 64) {
      if (group != nullptr)
        *group = k;
      return false;
    }
  }
  return true;
}

void modify_date_time_in_dicom_file(const onis::dicom_file_ptr& dcm,
                                    std::int32_t date_tag,
                                    std::int32_t time_tag,
                                    onis::core::date_time& date) {
  if (date.is_initialized()) {
    dcm->set_date_element(date_tag, &date);
    if (date.have_time())
      dcm->set_time_element(time_tag, date.hour(), date.minute(), date.second(),
                            0);
    else
      dcm->remove_element(time_tag);

  } else {
    dcm->remove_element(date_tag);
    dcm->remove_element(time_tag);
  }
}

void verify_ae_value(const std::string& value, bool allow_null) {
  bool valid = true;
  if (value.length() == 0 && !allow_null)
    valid = false;
  else if (value.length() > 16)
    valid = false;
  else if (!is_compatible_with_ir6(value))
    valid = false;
  if (!valid) {
    throw onis::exception(EOS_PARAM, "AE value is invalid");
  }
}

void verify_lo_value(const std::string& value, bool allow_null) {
  if (value.length() > 64) {
    throw onis::exception(EOS_PARAM, "LO value is invalid");
  }
}

const onis::dicom_charset* get_default_character_set(
    const onis::dicom_manager_ptr& manager,
    const std::string& specific_character_set,
    const onis::dicom_charset_info** info) {
  *info = nullptr;
  const onis::dicom_charset* set = nullptr;
  std::string def_charset;
  std::size_t pos = specific_character_set.find("\\");
  if (pos == std::string::npos)
    def_charset = specific_character_set;
  else
    def_charset = specific_character_set.substr(0, pos);
  if (!def_charset.empty())
    set = manager->find_character_set_by_iso_number(def_charset, info);
  if (set == nullptr) {
    set = manager->get_default_character_set();
    *info = set->info.front();
  }
  return set;
}

const onis::dicom_charset* find_next_character_set(
    const onis::dicom_manager_ptr& manager, const std::string& str,
    std::size_t offset, const onis::dicom_charset_info** info,
    std::string& next_esc) {
  *info = nullptr;
  const onis::dicom_charset* set = nullptr;
  // try to find a matching escape sequence of length 3:
  if (str.length() - offset >= 3) {
    // we have at least 3 bytes
    std::string tmp = str.substr(offset, 3);
    bool g0;
    set = manager->find_character_set_by_escape(tmp, info, &g0);
    if (set != nullptr) {
      next_esc = tmp;
      return set;
    } else {
      // no luck, try with 4 bytes:
      if (str.length() - offset >= 4) {
        // we have at least 4 bytes
        tmp += str[offset + 3];
        set = manager->find_character_set_by_escape(tmp, info, &g0);
        if (set != nullptr) {
          next_esc = tmp;
          return set;
        }
      }
    }
  }
  *info = nullptr;
  next_esc = "";
  return nullptr;
}

void add_last_escape_if_different_that_delimiter(
    std::string& str, const std::string& delimiter_esc) {
  std::int32_t pos = -1;
  std::int32_t count = (std::int32_t)str.size();
  for (std::int32_t i = count - 1; i >= 0; i--)
    if (str[i] == 0x1B) {
      pos = i;
      break;
    }

  bool add = false;
  std::string last_esc;
  if (pos != -1) {
    std::int32_t len = (std::int32_t)delimiter_esc.size();
    if (pos + len >= str.length())
      add = true;
    else {
      for (std::int32_t i = 0; i < len; i++)
        if (str[pos + i] != delimiter_esc[i]) {
          add = true;
          break;
        }
    }
  }
  if (add)
    str += delimiter_esc;
}

std::string convert_to_utf8(const onis::dicom_manager_ptr& manager,
                            const std::string& str,
                            const std::string& specific_character_set,
                            onis::dicom_charset_info_list* used_charset_infos) {
  std::string output;

  // get the default character set:
  if (manager == nullptr)
    return "";

  // get the default character set:
  const onis::dicom_charset_info* current_info = nullptr;
  const onis::dicom_charset* current_set =
      get_default_character_set(manager, specific_character_set, &current_info);

  // start the conversion:
  // create the list of strings to decode (string using different character
  // sets):
  std::size_t index = 0;
  bool valid = true;
  while (index < str.length()) {
    if (!valid)
      break;
    // extract the next string to convert:
    std::string string_to_convert;
    std::size_t pos = str.find((char)0x1B, index);
    if (pos == std::string::npos) {
      // no escape sequence, we should convert the whole remaining string:
      string_to_convert = str.substr(index);
      index += string_to_convert.length();

    } else if (pos == index) {
      // character set is changing now, nothing to convert, just update the
      // current character set:
      std::string esc;
      current_set =
          find_next_character_set(manager, str, pos, &current_info, esc);
      index += esc.length();
      if (current_set == nullptr)
        valid = false;

    } else {
      // get the string to convert using the current character set:
      string_to_convert = str.substr(index, pos - index);
      index += string_to_convert.length();
    }

    // convert the string:
    if (!string_to_convert.empty()) {
      if (used_charset_infos != nullptr && current_info != nullptr)
        if (std::find(used_charset_infos->begin(), used_charset_infos->end(),
                      current_info) == used_charset_infos->end())
          used_charset_infos->push_back(
              (onis::dicom_charset_info*)current_info);

      std::string convert = onis::util::string::convert_to_utf8(
          string_to_convert, current_info->code_page);
      output += convert;
    }
  }
  if (!valid)
    output.clear();
  return output;
}

std::string convert_from_utf8(const onis::dicom_manager_ptr& manager,
                              const std::string& str,
                              const onis::dicom_charset_info* charset_info,
                              const std::string& default_esc,
                              std::vector<std::string>* used_charsets) {
  // empty string doesn't need any conversion:
  if (str.empty())
    return str;

  // convert the utf8 string using the code page:
  std::string res;
  onis::util::string::convert_from_utf8(str, charset_info->code_page, res);

  // if the code page to use is single byte, we need to insert escape sequences
  // if g0 and g1 are used (only if the default character set is not g0)
  if (!charset_info->esc_g1.empty() && !charset_info->esc_g0.empty() &&
      default_esc != charset_info->esc_g0) {
    std::string res1;
    std::string current_esc;
    bool use_g0;
    for (std::int32_t i = 0; i < res.length(); i++) {
      use_g0 = ((std::int8_t)res[i] >= 0x20 && (std::int8_t)res[i] <= 0x7F);
      if (use_g0 && current_esc != charset_info->esc_g0) {
        current_esc = charset_info->esc_g0;
        res1 += current_esc;

      } else if (!use_g0 && current_esc != charset_info->esc_g1) {
        current_esc = charset_info->esc_g1;
        res1 += current_esc;
      }
      res1 += res[0];
    }
  }

  // handle the first escape sequence:
  if (res[0] == 0x1B)
    remove_first_escape_sequence_if_same_than_default(res, default_esc);
  else
    add_first_escape_sequence_if_different_than_default(
        res, charset_info->esc_g0, default_esc);

  // handle the last escape:
  add_last_escape_if_different_that_delimiter(res, default_esc);

  // remove duplicated escapes:
  remove_duplicated_escapes(manager, res, default_esc);

  if (used_charsets != nullptr) {
    get_escape_list(manager, res, default_esc, *used_charsets);
  }
  return res;
}

void find_all_compatible_charsets_with_person_name(
    const onis::dicom_manager_ptr& manager, bool full_compatibility,
    std::string name[5], std::string ideo[5], std::string phono[5],
    std::list<const onis::dicom_charset*>& charsets) {
  const onis::dicom_charset_list* list = manager->get_character_set_list();
  onis::dicom_charset_list::const_iterator it;
  for (it = list->begin(); it != list->end(); it++) {
    if (is_person_name_compatible_with_character_set(
            manager, *it, full_compatibility, name, ideo, phono, nullptr,
            nullptr) == 0) {
      if (std::find(charsets.begin(), charsets.end(), *it) == charsets.end())
        charsets.push_back(*it);
    }
  }
}

std::int32_t is_person_name_compatible_with_character_set(
    const onis::dicom_manager_ptr& manager, const onis::dicom_charset* set,
    bool full_compatibility, std::string* name, std::string* ideo,
    std::string* phono, std::int32_t* group, std::int32_t* index) {
  // return 0 if compatible
  // return -2 if the first group contains multi-bytes characters
  // return -3 if not compatible with the provided character set (if not default
  // one).

  // test each group:
  for (int k = 0; k < 3; k++) {
    std::string* input = k == 0 ? name : k == 1 ? ideo : phono;
    // test each component:
    for (std::int32_t i = 0; i < 5; i++) {
      // empty strings are always compatible:
      if (input[i].empty())
        continue;

      // test each code pages of the set:
      bool is_compatible = false;
      bool single_bytes = false;
      for (auto& info : set->info) {
        std::string tmp, back;
        onis::util::string::convert_from_utf8(input[i], info->code_page, tmp);
        back = onis::util::string::convert_to_utf8(tmp, info->code_page);
        if (back == input[i]) {
          is_compatible = true;
          single_bytes = info->single_byte;
          break;
        }
      }

      if (!is_compatible ||
          (k == 0 && !single_bytes && set->code != "UNICODE")) {
        if (group)
          *group = k;
        if (index)
          *index = i;
        return is_compatible ? -2 : -3;
      }
    }
  }
  return 0;
}

bool is_compatible_with_ir6(const std::string& value) {
  for (size_t i = 0; i < value.length(); i++)
    if ((std::int8_t)value[i] < 0x20 && (std::int8_t)value[i] > 0x7F)
      return false;
  return true;
}

bool is_compatible_with_code_page(const std::string& str,
                                  const std::string& code_page) {
  std::string tmp, back;
  onis::util::string::convert_from_utf8(str, code_page, tmp);
  back = onis::util::string::convert_to_utf8(tmp, code_page);
  return str == back ? true : false;
}

std::string create_new_file_string(const onis::dicom_manager_ptr& manager,
                                   const std::string& def_esc,
                                   const std::string& str,
                                   const onis::dicom_charset* set,
                                   std::vector<std::string>* used_charsets) {
  std::string res;
  if (set->info.size() == 1)
    res = onis::util::dicom::convert_from_utf8(manager, str, set->info.front(),
                                               def_esc, used_charsets);
  else {
    // search the compatible one:
    bool found = false;
    for (onis::dicom_charset_info_list::const_iterator it1 = set->info.begin();
         it1 != set->info.end(); it1++) {
      if (onis::util::dicom::is_compatible_with_code_page(str,
                                                          (*it1)->code_page)) {
        res = onis::util::dicom::convert_from_utf8(manager, str, *it1, def_esc,
                                                   used_charsets);
        found = true;
        break;
      }
    }
    if (!found)
      res = onis::util::dicom::convert_from_utf8(
          manager, str, set->info.front(), def_esc, used_charsets);
  }
  return res;
}

std::string build_person_name(const onis::dicom_manager_ptr& manager,
                              std::string name[5], std::string ideo[5],
                              std::string phono[5]) {
  std::string group_value[3];
  for (std::int32_t j = 0; j < 3; j++) {
    std::string* source;
    std::string* target;
    switch (j) {
      case 0:
        source = name;
        target = &group_value[0];
        break;
      case 1:
        source = ideo;
        target = &group_value[1];
        break;
      case 2:
        source = phono;
        target = &group_value[2];
        break;
      default:
        break;
    };

    *target += source[0];
    if (source[1].empty()) {
      if (source[2].empty()) {
        if (source[3].empty()) {
          if (!source[4].empty())
            *target += "^^^^" + source[4];

        } else {
          *target += "^^^" + source[3];
          if (!source[4].empty())
            *target += "^" + source[4];
        }

      } else {
        *target += "^^" + source[2];
        if (source[3].empty()) {
          if (!source[4].empty())
            *target += "^^" + source[4];

        } else {
          *target += "^" + source[3];
          if (!source[4].empty())
            *target += "^" + source[4];
        }
      }

    } else {
      *target += "^" + source[1];
      if (source[2].empty()) {
        if (source[3].empty()) {
          if (!source[4].empty())
            *target += "^^^" + source[4];

        } else {
          *target += "^^" + source[3];
          if (!source[4].empty())
            *target += "^" + source[4];
        }

      } else {
        *target += "^" + source[2];
        if (source[3].empty()) {
          if (!source[4].empty())
            *target += "^^" + source[4];

        } else {
          *target += "^" + source[3];
          if (!source[4].empty())
            *target += "^" + source[4];
        }
      }
    }
  }

  std::string final_value = group_value[0];
  if (group_value[1].empty()) {
    if (!group_value[2].empty())
      final_value += "==" + group_value[2];

  } else {
    final_value += "=" + group_value[1];
    if (!group_value[2].empty())
      final_value += "=" + group_value[2];
  }

  // remove the duplicated escape sequences:
  std::vector<std::string> escapes;
  std::vector<std::string> texts;
  std::string escape;
  std::string text;
  std::int32_t count = (std::int32_t)final_value.length();
  for (std::int32_t i = 0; i < count; i++) {
    if (final_value[i] == 0x1B) {
      if (!text.empty()) {
        escapes.push_back(escape);
        texts.push_back(text);
        text = "";
        escape = "";
      }

      if (i + 3 >= count) {
        if (i + 3 == count) {
          const onis::dicom_charset* set = nullptr;
          const onis::dicom_charset_info* info = nullptr;
          std::string tmp;
          tmp += final_value[i];
          tmp += final_value[i + 1];
          tmp += final_value[i + 2];
          bool g0;
          set = manager->find_character_set_by_escape(tmp, &info, &g0);
          if (set != nullptr)
            escape = tmp;
        }
        break;

      } else {
        const onis::dicom_charset* set = nullptr;
        const onis::dicom_charset_info* info = nullptr;
        std::string tmp;
        tmp += final_value[i];
        tmp += final_value[i + 1];
        tmp += final_value[i + 2];

        bool g0;
        set = manager->find_character_set_by_escape(tmp, &info, &g0);
        if (set == nullptr && i + 4 <= count) {
          tmp += final_value[i + 3];
          set = manager->find_character_set_by_escape(tmp, &info, &g0);
        }
        if (set != nullptr) {
          escape = tmp;
          i += (std::int32_t)escape.length() - 1;
        }
      }

    } else
      text += final_value[i];
  }
  if (!text.empty() || !escape.empty()) {
    escapes.push_back(escape);
    texts.push_back(text);
  }

  // reconstruct the final string:
  final_value = "";
  std::vector<std::string>::iterator it1, it2;
  std::string current_escape;
  for (it1 = escapes.begin(), it2 = texts.begin(); it1 != escapes.end();
       it1++, it2++) {
    if (it1 == escapes.begin()) {
      final_value = *it1 + *it2;
      current_escape = *it1;

    } else {
      if (current_escape == *it1)
        final_value += *it2;
      else {
        final_value += *it1 + *it2;
        current_escape = *it1;
      }
    }
  }

  return final_value;
}

}  // namespace onis::util::dicom
