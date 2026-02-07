#pragma once

#include "../dicom/dicom.hpp"

#include <string>
#include <vector>

namespace onis::util::dicom {

const std::vector<std::string>* get_list_of_page_codes();
void init_page_codes(std::vector<std::string>& list);

void decode_person_name(const std::string& full_name, std::string& name,
                        std::string& ideogram, std::string& phonetic,
                        bool make_short);
bool is_person_name_identical(std::string N1[5], std::string I1[5],
                              std::string P1[5], std::string N2[5],
                              std::string I2[5], std::string P2[5]);
void make_group_name_short(std::string& group);
void decode_person_name(const std::string& full_name, std::string& name,
                        std::string& ideogram, std::string& phonetic,
                        bool make_short);
void decode_person_name(const std::string& full_name, std::string name[5],
                        std::string ideogram[5], std::string phonetic[5]);
void encode_person_name(std::string name[5], std::string ideogram[5],
                        std::string phonetic[5], std::string& output);
void encode_person_name(std::string name, std::string ideogram,
                        std::string phonetic, std::string& output);
void encode_group_name(std::string name[5], std::string& output);
void decode_group_name(std::string name, std::string output[5]);
void get_full_name(const std::string& name, const std::string& ideo,
                   const std::string& phono, std::string& output);
bool is_person_name_length_is_valid(std::string name[5],
                                    std::string ideogram[5],
                                    std::string phonetic[5],
                                    std::int32_t* group);

void modify_date_time_in_dicom_file(const onis::dicom_file_ptr& dcm,
                                    std::int32_t date_tag,
                                    std::int32_t time_tag,
                                    onis::core::date_time& date);

void verify_ae_value(const std::string& value, bool allow_null);
void verify_lo_value(const std::string& value, bool allow_null);

// void verify_ip_value(const std::string& value, bool allow_null);
// void verify_port_value(std::int32_t port, bool allow_zero);
// void verify_login_value(const std::string& value, bool allow_null);
// void verify_password_value(const std::string& value, bool allow_null);
// void verify_guid_value(const std::string& value, bool allow_null);
// void verify_string_value(const std::string& value, bool allow_null,
//                        std::int32_t max_length);
// void verify_email_value(const std::string& value, bool allow_null);

bool get_window_level(onis::dicom_base* dataset, double* center, double* width);

// bool get_date_from_string(const std::string& str, std::int32_t start,
//                         std::string& year, std::string& month,
//                       std::string& day);
// bool get_time_from_string(const std::string& str, std::int32_t start,
//                         std::int32_t* hour, std::int32_t* minute,
//                       std::int32_t* second, std::int32_t* fraction);
// bool get_date_range_from_string(const std::string& str, date_time_value*
// from,
//                               date_time_value* to);
// bool get_time_range_from_string(const std::string& str, time_value* from,
//                               time_value* to);
// void get_string_from_date(const date_time_value& date, bool with_time,
//                         std::string& output);
// void get_string_from_date(const date_time_value& date, std::string&
// output_date,
//                         std::string& output_time);

std::string convert_to_utf8(
    const onis::dicom_manager_ptr&, const std::string& str,
    const std::string& specific_character_set,
    onis::dicom_charset_info_list* used_charset_infos = nullptr);
std::string convert_from_utf8(
    const onis::dicom_manager_ptr&, const std::string& str,
    const onis::dicom_charset_info* charset_info,
    const std::string& default_esc,
    std::vector<std::string>* used_charsets = nullptr);
void find_all_compatible_charsets_with_person_name(
    const onis::dicom_manager_ptr&, bool full_compatibility,
    std::string name[5], std::string ideo[5], std::string phono[5],
    std::list<const onis::dicom_charset*>& charsets);
std::int32_t is_person_name_compatible_with_character_set(
    const onis::dicom_manager_ptr&, const onis::dicom_charset* set,
    bool full_compatibility, std::string* name, std::string* ideo,
    std::string* phono, std::int32_t* group, std::int32_t* index);

bool is_compatible_with_ir6(const std::string& value);
bool is_compatible_with_code_page(const std::string& str,
                                  const std::string& code_page);
void remove_duplicated_escapes(const onis::dicom_manager_ptr&, std::string& str,
                               const std::string& default_esc);
void find_all_compatible_charsets(
    const onis::dicom_manager_ptr&, const std::string& str,
    std::list<const onis::dicom_charset*>& charsets);
const onis::dicom_charset* get_default_character_set(
    const onis::dicom_manager_ptr& manager,
    const std::string& specific_character_set,
    const onis::dicom_charset_info** info);
bool is_value_compatible_with_character_set(const onis::dicom_manager_ptr&,
                                            const onis::dicom_charset* set,
                                            const std::string& str);
void find_common_charsets(const onis::dicom_manager_ptr&,
                          const std::vector<std::string>& list,
                          std::list<const onis::dicom_charset*>& charsets);

void intersect_charset_lists(std::list<const onis::dicom_charset*>& charsets,
                             const std::list<const onis::dicom_charset*>& list);
bool contains_multibyte_characters(const onis::dicom_manager_ptr&,
                                   const std::string& utf8_str,
                                   const std::string& code_page);

bool ensure_single_byte_first_charset(const onis::dicom_manager_ptr&,
                                      std::string& file_charset);
std::string construct_new_char_tag(
    const onis::dicom_manager_ptr& manager, const std::string& current_charset,
    const std::vector<std::string>& additional_charset);

std::string create_new_file_string(const onis::dicom_manager_ptr& manager,
                                   const std::string& def_esc,
                                   const std::string& str,
                                   const onis::dicom_charset* set,
                                   std::vector<std::string>* used_charsets);
std::string build_person_name(const onis::dicom_manager_ptr& manager,
                              std::string name[5], std::string ideo[5],
                              std::string phono[5]);
std::string construct_new_char_tag(
    const onis::dicom_manager_ptr& manager,
    const std::string& specific_character_set,
    const std::vector<std::string>& additional_charset);

}  // namespace onis::util::dicom
