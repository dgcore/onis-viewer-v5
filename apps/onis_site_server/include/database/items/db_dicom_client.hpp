#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define DCMCLT_STATUS_KEY "status"
#define DCMCLT_AE_KEY "ae"
#define DCMCLT_NAME_KEY "name"
#define DCMCLT_IP_KEY "ip"
#define DCMCLT_PORT_KEY "port"
#define DCMCLT_RIGHTS_KEY "rights"
#define DCMCLT_TYPE_KEY "client_type"
#define DCMCLT_DESC_KEY "desc"
#define DCMCLT_TARGET_TYPE_KEY "target_type"
#define DCMCLT_TARGET_NAME_KEY "target_name"
#define DCMCLT_TARGET_ID_KEY "target_id"
#define DCMCLT_CONV_KEY "conversion"

namespace onis::database {

const std::int32_t dcfind = 1;
const std::int32_t dcstore = 2;
const std::int32_t dcmove = 4;

const std::int32_t type_undefined = 0;
const std::int32_t type_server = 1;
const std::int32_t type_client = 2;
const std::int32_t type_client_and_server = 3;
const std::int32_t type_modality = 4;

const std::uint32_t info_dicom_client_ae = 2;
const std::uint32_t info_dicom_client_name = 4;
const std::uint32_t info_dicom_client_ip = 8;
const std::uint32_t info_dicom_client_port = 16;
const std::uint32_t info_dicom_client_permissions = 32;
const std::uint32_t info_dicom_client_type = 64;
const std::uint32_t info_dicom_client_comment = 128;
const std::uint32_t info_dicom_client_target = 256;
const std::uint32_t info_dicom_client_conversion = 512;
const std::uint32_t info_dicom_client_status = 1024;

struct dicom_client {
  static void create(json& client, std::uint32_t flags) {
    if (!client.isObject()) {
      throw std::invalid_argument("dicom_client is not an object");
    }
    client.clear();
    client[BASE_SEQ_KEY] = "";
    client[BASE_VERSION_KEY] = "1.0.0";
    client[BASE_FLAGS_KEY] = flags;
    if (flags & info_dicom_client_status)
      client[DCMCLT_STATUS_KEY] = 1;
    if (flags & info_dicom_client_ae)
      client[DCMCLT_AE_KEY] = "";
    if (flags & info_dicom_client_name)
      client[DCMCLT_NAME_KEY] = "";
    if (flags & info_dicom_client_ip)
      client[DCMCLT_IP_KEY] = "";
    if (flags & info_dicom_client_port)
      client[DCMCLT_PORT_KEY] = "";
    if (flags & info_dicom_client_permissions)
      client[DCMCLT_RIGHTS_KEY] = onis::database::dcfind |
                                  onis::database::dcstore |
                                  onis::database::dcmove;
    if (flags & info_dicom_client_type)
      client[DCMCLT_TYPE_KEY] = onis::database::type_client;
    if (flags & info_dicom_client_comment)
      client[DCMCLT_DESC_KEY] = "";
    if (flags & info_dicom_client_target) {
      client[DCMCLT_TARGET_TYPE_KEY] = -1;  // onis::server::target_partition;
      client[DCMCLT_TARGET_ID_KEY] = "";
      client[DCMCLT_TARGET_NAME_KEY] = "";
    }
    if (flags & info_dicom_client_conversion)
      client[DCMCLT_CONV_KEY] = "";
  }

  static void verify(const json& input, bool with_seq,
                     std::uint32_t must_flags) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    std::uint32_t flags = input[BASE_FLAGS_KEY].asUInt();
    onis::database::item::check_must_flags(flags, must_flags);

    if (flags & info_dicom_client_status)
      onis::database::item::verify_integer_value(input, DCMCLT_STATUS_KEY,
                                                 false, 0, 1);
    if (flags & info_dicom_client_ae)
      onis::database::item::verify_string_value(input, DCMCLT_AE_KEY, false,
                                                false, OS_REGEX_AE);
    if (flags & info_dicom_client_name)
      onis::database::item::verify_string_value(input, DCMCLT_NAME_KEY, true,
                                                true, 64);
    if (flags & info_dicom_client_ip)
      onis::database::item::verify_string_value(input, DCMCLT_IP_KEY, false,
                                                false, OS_REGEX_IP);
    if (flags & info_dicom_client_port)
      onis::database::item::verify_integer_value(input, DCMCLT_PORT_KEY, false,
                                                 1, 65535);
    if (flags & info_dicom_client_permissions)
      onis::database::item::verify_integer_value(input, DCMCLT_RIGHTS_KEY,
                                                 false, 0, 7);
    if (flags & info_dicom_client_type)
      onis::database::item::verify_integer_value(input, DCMCLT_TYPE_KEY, false,
                                                 0, 4);
    if (flags & info_dicom_client_comment)
      onis::database::item::verify_string_value(input, DCMCLT_DESC_KEY, true,
                                                true, 255);
    if (flags & info_dicom_client_target) {
      onis::database::item::verify_integer_value(input, DCMCLT_TARGET_TYPE_KEY,
                                                 false, 0, 4);
      onis::database::item::verify_uuid_value(input, DCMCLT_TARGET_ID_KEY, true,
                                              true);
      onis::database::item::verify_string_value(input, DCMCLT_TARGET_NAME_KEY,
                                                true, true, 255);
    }
    if (flags & info_dicom_client_conversion)
      onis::database::item::verify_string_value(input, DCMCLT_CONV_KEY, true,
                                                true, 255);
    onis::astring value = input[DCMCLT_CONV_KEY].asString();
    const onis::astring_list* list =
        onis::util::dicom::get_list_of_page_codes();
    if (std::find(list->begin(), list->end(), value) == list->end()) {
      throw std::runtime_error("Invalid page code: " + value);
    }
  }
};

}  // namespace onis::database
