#pragma once

#include "../../../libs/onis_kit/include/utilities/regex.hpp"
#include "db_dicom_client.hpp"

using json = Json::Value;

#define DCMAE_TITLE_KEY "ae"
#define DCMAE_STATUS_KEY "status"
#define DCMAE_TYPE_KEY "destination"
#define DCMAE_DESC_KEY "comment"
#define DCMAE_CLIENTS_KEY "clients"

namespace onis::database {

const s32 info_dicom_ae_name = 2;
const s32 info_dicom_ae_status = 4;
const s32 info_dicom_ae_type = 8;
const s32 info_dicom_ae_comment = 16;
const s32 info_dicom_ae_clients = 32;

const s32 ae_type_local = 0;

struct dicom_ae {
  static void create(json& ae, u32 flags) {
    if (!ae.isObject()) {
      throw std::invalid_argument("dicom_ae is not an object");
    }
    ae.clear();
    ae.clear();
    ae[BASE_SEQ_KEY] = "";
    ae[BASE_VERSION_KEY] = "1.0.0";
    ae[BASE_FLAGS_KEY] = flags;
    if (flags & info_dicom_ae_name)
      ae[DCMAE_TITLE_KEY] = "";
    if (flags & info_dicom_ae_status)
      ae[DCMAE_STATUS_KEY] = 1;
    if (flags & info_dicom_ae_type)
      ae[DCMAE_TYPE_KEY] = onis::server::ae_type_local;
    if (flags & info_dicom_ae_comment)
      ae[DCMAE_DESC_KEY] = "";
    if (flags & info_dicom_ae_clients)
      ae[DCMAE_CLIENTS_KEY] = Json::Value(Json::arrayValue);
  }

  static void verify(const json& input, bool with_seq, u32 must_flags) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    onis::database::item::check_must_flags(flags, must_flags);
    if (flags & info_dicom_ae_name) {
      onis::database::item::verify_string_value(input, DCMAE_TITLE_KEY, false,
                                                false, OS_REGEX_AE);
    }
    if (flags & info_dicom_ae_status)
      onis::database::item::verify_integer_value(input, DCMAE_STATUS_KEY, false,
                                                 0, 1);
    if (flags & info_dicom_ae_type)
      onis::database::item::verify_integer_value(input, DCMAE_TYPE_KEY, false,
                                                 0, 0);
    if (flags & info_dicom_ae_comment)
      onis::database::item::verify_string_value(input, DCMAE_DESC_KEY, true,
                                                true, 255);
    if (flags & info_dicom_ae_clients) {
      onis::database::item::verify_array_value(input, DCMAE_CLIENTS_KEY, false);
      for (const auto& client : input[DCMAE_CLIENTS_KEY])
        onis::database::dicom_client::verify(client, with_seq, 0);
    }
  }
};
}  // namespace onis::database
