#pragma once

#include "./db_item.hpp"
#include "./db_patient.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/core/result.hpp"

#include <cstdint>

using json = Json::Value;

#define IM_SEQ_KEY "seq"
#define IM_UID_KEY "uid"
#define IM_CHARSET_KEY "charset"
#define IM_INSTNUM_KEY "instnum"
#define IM_ACQNUM_KEY "acqnum"
#define IM_SOPCLASS_KEY "sopclass"
#define IM_WIDTH_KEY "width"
#define IM_HEIGHT_KEY "height"
#define IM_DEPTH_KEY "depth"
#define IM_COMP_STATUS_KEY "cstatus"
#define IM_COMP_UPDATE_KEY "cupd"
#define IM_IMAGE_MEDIA_KEY "imgmedia"
#define IM_IMAGE_PATH_KEY "imgpath"
#define IM_IMAGE_KEY "img"
#define IM_ICON_MEDIA_KEY "iconmedia"
#define IM_ICON_PATH_KEY "iconpath"
#define IM_ICON_KEY "icon"
#define IM_STREAM_MEDIA_KEY "streammedia"
#define IM_STREAM_PATH_KEY "streampath"
#define IM_STREAM_KEY "stream"
#define IM_STATUS_KEY "status"
#define IM_CRDATE_KEY "crdate"
#define IM_ORIGIN_ID_KEY "oid"
#define IM_ORIGIN_NAME_KEY "oname"
#define IM_ORIGIN_IP_KEY "oip"

namespace onis::database {

const std::uint32_t info_image_charset = 1;
const std::uint32_t info_image_instance_number = 2;
const std::uint32_t info_image_acq_number = 4;
const std::uint32_t info_image_sop_class = 8;
const std::uint32_t info_image_dimension = 16;
const std::uint32_t info_image_depth = 32;
const std::uint32_t info_image_icon = 64;
// const s32 info_image_icon_detail = 128;
const std::uint32_t info_image_path = 256;
const std::uint32_t info_image_compression = 512;
// const std::uint32_t info_image_original_transfer_syntax = 1024;
const std::uint32_t info_image_creation = 2048;
const std::uint32_t info_image_status = 4096;
const std::uint32_t info_image_stream = 8192;
// const s32 info_image_stream_detail = 16384;

struct image {
  static void create(json& image, std::uint32_t flags, bool for_client) {
    if (!image.isObject()) {
      throw onis::exception(EOS_PARAM, "series is not an json object");
    }
    image.clear();
    image[BASE_SEQ_KEY] = "";
    image[BASE_VERSION_KEY] = "1.0.0";
    image[BASE_FLAGS_KEY] = flags;
    image[BASE_UID_KEY] = "";

    if (flags & info_image_charset)
      image[IM_CHARSET_KEY] = "";
    if (flags & info_image_instance_number)
      image[IM_INSTNUM_KEY] = "";
    if (flags & info_image_acq_number)
      image[IM_ACQNUM_KEY] = "";
    if (flags & info_image_sop_class)
      image[IM_SOPCLASS_KEY] = "";
    if (flags & info_image_dimension) {
      image[IM_WIDTH_KEY] = 0;
      image[IM_HEIGHT_KEY] = 0;
    }
    if (flags & info_image_depth)
      image[IM_DEPTH_KEY] = -1.0;
    if (flags & info_image_path) {
      if (for_client)
        image[IM_IMAGE_KEY] = 0;
      else {
        image[IM_IMAGE_MEDIA_KEY] = 0;
        image[IM_IMAGE_PATH_KEY] = "";
      }
    }
    if (flags & info_image_icon) {
      if (for_client)
        image[IM_ICON_KEY] = 0;
      else {
        image[IM_ICON_MEDIA_KEY] = 0;
        image[IM_ICON_PATH_KEY] = "";
      }
    }
    if (flags & info_image_stream) {
      if (for_client)
        image[IM_STREAM_KEY] = 0;
      else {
        image[IM_STREAM_MEDIA_KEY] = 0;
        image[IM_STREAM_PATH_KEY] = "";
      }
    }

    if (flags & info_image_creation) {
      image[IM_CRDATE_KEY] = "";
      image[IM_ORIGIN_ID_KEY] = "";
      image[IM_ORIGIN_NAME_KEY] = "";
      image[IM_ORIGIN_IP_KEY] = "";
    }

    if (flags & info_image_status) {
      if (for_client)
        image[IM_STATUS_KEY] = 0;
      else
        image[IM_STATUS_KEY] = "";
    }
    if (flags & info_image_compression) {
      image[IM_COMP_STATUS_KEY] = 0;
      image[IM_COMP_UPDATE_KEY] = 0;
    }
  }

  static void verify(const json& input, bool with_seq, bool for_client) {
    onis::database::item::verify_seq_version_flags(input, with_seq);
    std::uint32_t flags = input[BASE_FLAGS_KEY].asUInt();
    if (flags & info_image_charset)
      onis::database::item::verify_string_value(input, IM_CHARSET_KEY, true,
                                                true, 255);
    if (flags & info_image_instance_number)
      onis::database::item::verify_string_value(input, IM_INSTNUM_KEY, true,
                                                true, 255);
    if (flags & info_image_acq_number)
      onis::database::item::verify_string_value(input, IM_ACQNUM_KEY, true,
                                                true, 255);
    if (flags & info_image_sop_class)
      onis::database::item::verify_string_value(input, IM_SOPCLASS_KEY, true,
                                                true, 255);
    if (flags & info_image_dimension) {
      onis::database::item::verify_integer_value(input, IM_WIDTH_KEY, true, 0);
      onis::database::item::verify_integer_value(input, IM_HEIGHT_KEY, true, 0);
    }
    if (flags & info_image_depth)
      onis::database::item::verify_float_value(input, IM_DEPTH_KEY, true, -1.0);
    if (flags & info_image_path) {
      if (for_client)
        onis::database::item::verify_integer_value(input, IM_IMAGE_KEY, true);
      else {
        onis::database::item::verify_integer_value(input, IM_IMAGE_MEDIA_KEY,
                                                   false, 0);
        onis::database::item::verify_string_value(input, IM_IMAGE_PATH_KEY,
                                                  true, true, 255);
      }
    }
    if (flags & info_image_creation) {
      onis::database::item::verify_string_value(input, IM_CRDATE_KEY, false,
                                                false, 64);
      onis::database::item::verify_string_value(input, IM_ORIGIN_ID_KEY, true,
                                                true, 64);
      onis::database::item::verify_string_value(input, IM_ORIGIN_NAME_KEY, true,
                                                true, 255);
      onis::database::item::verify_string_value(input, IM_ORIGIN_IP_KEY, true,
                                                true, 255);
    }
    if (flags & info_image_status) {
      if (for_client)
        onis::database::item::verify_integer_value(input, IM_STATUS_KEY, false);
      else
        onis::database::item::verify_string_value(input, IM_STATUS_KEY, false,
                                                  false, 255);
    }
    if (flags & info_image_icon) {
      if (for_client)
        onis::database::item::verify_integer_value(input, IM_ICON_KEY, false);
      else {
        onis::database::item::verify_integer_value(input, IM_ICON_MEDIA_KEY,
                                                   false);
        onis::database::item::verify_string_value(input, IM_ICON_PATH_KEY, true,
                                                  true, 255);
      }
    }
    if (flags & info_image_stream) {
      if (for_client)
        onis::database::item::verify_integer_value(input, IM_STREAM_KEY, true);
      else {
        onis::database::item::verify_integer_value(input, IM_STREAM_MEDIA_KEY,
                                                   false);
        onis::database::item::verify_string_value(input, IM_STREAM_PATH_KEY,
                                                  true, true, 255);
      }
    }
    if (flags & info_image_compression) {
      onis::database::item::verify_integer_value(input, IM_COMP_STATUS_KEY,
                                                 true, 0);
      onis::database::item::verify_integer_value(input, IM_COMP_UPDATE_KEY,
                                                 true, 0);
    }
  }

  static void copy(const json& input, std::uint32_t flags, bool for_client,
                   json& output) {
    create(output, flags, for_client);
    output[BASE_UID_KEY] = input[BASE_UID_KEY].asString();
    std::uint32_t input_flags = input[BASE_FLAGS_KEY].asUInt();

    if (flags & info_image_charset) {
      if ((input_flags & info_image_charset) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      output[IM_CHARSET_KEY] = input[IM_CHARSET_KEY].asString();
    }

    if (flags & info_image_instance_number) {
      if ((input_flags & info_image_instance_number) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      output[IM_INSTNUM_KEY] = input[IM_INSTNUM_KEY].asString();
    }

    if (flags & info_image_acq_number) {
      if ((input_flags & info_image_acq_number) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      output[IM_ACQNUM_KEY] = input[IM_ACQNUM_KEY].asString();
    }

    if (flags & info_image_sop_class) {
      if ((input_flags & info_image_sop_class) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      output[IM_SOPCLASS_KEY] = input[IM_SOPCLASS_KEY].asString();
    }

    if (flags & info_image_dimension) {
      if ((input_flags & info_image_dimension) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      output[IM_WIDTH_KEY] = input[IM_WIDTH_KEY].asInt();
      output[IM_HEIGHT_KEY] = input[IM_HEIGHT_KEY].asInt();
    }

    if (flags & info_image_depth) {
      if ((input_flags & info_image_depth) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      output[IM_DEPTH_KEY] = input[IM_DEPTH_KEY].asFloat();
    }

    if (flags & info_image_icon) {
      if ((input_flags & info_image_icon) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      if (for_client)
        output[IM_ICON_KEY] = input[IM_ICON_KEY].asInt();
      else {
        output[IM_ICON_MEDIA_KEY] = input[IM_ICON_MEDIA_KEY].asInt();
        output[IM_ICON_PATH_KEY] = input[IM_ICON_PATH_KEY].asString();
      }
    }

    if (flags & info_image_path) {
      if ((input_flags & info_image_path) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      if (for_client)
        output[IM_IMAGE_KEY] = input[IM_IMAGE_KEY].asInt();
      else {
        output[IM_IMAGE_MEDIA_KEY] = input[IM_IMAGE_MEDIA_KEY].asInt();
        output[IM_IMAGE_PATH_KEY] = input[IM_IMAGE_PATH_KEY].asString();
      }
    }

    if (flags & info_image_compression) {
      if ((input_flags & info_image_compression) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      output[IM_COMP_STATUS_KEY] = input[IM_COMP_STATUS_KEY].asInt();
      output[IM_COMP_UPDATE_KEY] = input[IM_COMP_UPDATE_KEY].asInt();
    }

    if (flags & info_image_creation) {
      if ((input_flags & info_image_creation) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      output[IM_CRDATE_KEY] = input[IM_CRDATE_KEY].asString();
      output[IM_ORIGIN_ID_KEY] = input[IM_ORIGIN_ID_KEY].asString();
      output[IM_ORIGIN_NAME_KEY] = input[IM_ORIGIN_NAME_KEY].asString();
      output[IM_ORIGIN_IP_KEY] = input[IM_ORIGIN_IP_KEY].asString();
    }

    if (flags & info_image_status) {
      if ((input_flags & info_image_status) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      if (for_client) {
        if (input[IM_STATUS_KEY].type() == Json::stringValue) {
          if (input[IM_STATUS_KEY] == ONLINE_STATUS)
            output[IM_STATUS_KEY] = 0;
          else
            output[IM_STATUS_KEY] = 1;

        } else
          output[IM_STATUS_KEY] = input[IM_STATUS_KEY].asInt();

      } else
        output[IM_STATUS_KEY] = input[IM_STATUS_KEY].asString();
    }

    if (flags & info_image_stream) {
      if ((input_flags & info_image_stream) == 0)
        throw onis::exception(EOS_PARAM,
                              "Failed to copy the image json object.");
      if (for_client)
        output[IM_STREAM_KEY] = input[IM_STREAM_KEY].asInt();
      else {
        output[IM_STREAM_MEDIA_KEY] = input[IM_STREAM_MEDIA_KEY].asInt();
        output[IM_STREAM_PATH_KEY] = input[IM_STREAM_PATH_KEY].asString();
      }
    }
  }
};

}  // namespace onis::database