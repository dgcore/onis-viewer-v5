#include <iomanip>
#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_image.hpp"
#include "../../include/database/items/db_patient.hpp"
#include "../../include/database/items/db_study.hpp"
#include "../../include/database/site_database.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/utilities/string.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Image operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_image_columns(std::uint32_t flags,
                                             bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_images." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "series_id, " + prefix + "uid, " +
           prefix + "charset, " + prefix + "instnum, " + prefix + "sopclass, " +
           prefix + "acqnum, " + prefix + "imgmedia, " + prefix + "imgpath, " +
           prefix + "streammedia, " + prefix + "streampath, " + prefix +
           "iconmedia, " + prefix + "iconpath, " + prefix + "width, " + prefix +
           "height, " + prefix + "depth, " + prefix + "cstatus, " + prefix +
           "cupd, " + prefix + "status, " + prefix + "crdate, " + prefix +
           "oid, " + prefix + "oname, " + prefix + "oip";
  }

  std::string columns =
      prefix + "id, " + prefix + "series_id, " + prefix + "uid";
  if (flags & onis::database::info_image_charset) {
    columns += ", " + prefix + "charset";
  }
  if (flags & onis::database::info_image_instance_number) {
    columns += ", " + prefix + "instnum";
  }
  if (flags & onis::database::info_image_sop_class) {
    columns += ", " + prefix + "sopclass";
  }
  if (flags & onis::database::info_image_acq_number) {
    columns += ", " + prefix + "acqnum";
  }
  if (flags & onis::database::info_image_path) {
    columns += ", " + prefix + "imgmedia, " + prefix + "imgpath";
  }
  if (flags & onis::database::info_image_stream) {
    columns += ", " + prefix + "streammedia, " + prefix + "streampath";
  }
  if (flags & onis::database::info_image_icon) {
    columns += ", " + prefix + "iconmedia, " + prefix + "iconpath";
  }
  if (flags & onis::database::info_image_dimension) {
    columns += ", " + prefix + "width, " + prefix + "height";
  }
  if (flags & onis::database::info_image_depth) {
    columns += ", " + prefix + "depth";
  }
  if (flags & onis::database::info_image_compression) {
    columns += ", " + prefix + "cstatus, " + prefix + "cupd";
  }
  if (flags & onis::database::info_image_status) {
    columns += ", " + prefix + "status";
  }
  if (flags & onis::database::info_image_creation) {
    columns += ", " + prefix + "crdate, " + prefix + "oid, " + prefix +
               "oname, " + prefix + "oip";
  }
  return columns;
}

void site_database::create_image_item(onis_kit::database::database_row& rec,
                                      std::uint32_t flags, bool for_client,
                                      std::int32_t* index,
                                      std::string* series_seq,
                                      Json::Value& image) {
  onis::database::image::create(image, flags, for_client);
  std::int32_t local_index = 0;
  std::int32_t* target_index = index ? index : &local_index;
  image[BASE_SEQ_KEY] = rec.get_uuid(*target_index, false, false);
  if (series_seq) {
    *series_seq = rec.get_uuid(*target_index, false, false);
  } else {
    (*target_index)++;
  }
  image[BASE_UID_KEY] = rec.get_string(*target_index, false, false);

  if (flags & onis::database::info_image_charset) {
    image[IM_CHARSET_KEY] = rec.get_string(*target_index, true, true);
  }

  if (flags & onis::database::info_image_instance_number) {
    image[IM_INSTNUM_KEY] = rec.get_string(*target_index, true, true);
  }

  if (flags & onis::database::info_image_sop_class) {
    image[IM_SOPCLASS_KEY] = rec.get_string(*target_index, true, true);
  }

  if (flags & onis::database::info_image_acq_number) {
    image[IM_ACQNUM_KEY] = rec.get_string(*target_index, true, true);
  }

  if (flags & onis::database::info_image_path) {
    if (for_client) {
      (*target_index)++;
      std::string path = rec.get_string(*target_index, true, true);
      image[IM_IMAGE_KEY] = path.empty() ? 0 : 1;
    } else {
      image[IM_IMAGE_MEDIA_KEY] = rec.get_int(*target_index, false);
      image[IM_IMAGE_PATH_KEY] = rec.get_string(*target_index, true, true);
    }
  }

  if (flags & onis::database::info_image_stream) {
    if (for_client) {
      (*target_index)++;
      std::string path = rec.get_string(*target_index, true, true);
      image[IM_STREAM_KEY] = path.empty() ? 0 : 1;
    } else {
      image[IM_STREAM_MEDIA_KEY] = rec.get_int(*target_index, false);
      image[IM_STREAM_PATH_KEY] = rec.get_string(*target_index, true, true);
    }
  }

  if (flags & onis::database::info_image_icon) {
    if (for_client) {
      (*target_index)++;
      std::string path = rec.get_string(*target_index, true, true);
      image[IM_ICON_KEY] = path.empty() ? 0 : 1;
    } else {
      image[IM_ICON_MEDIA_KEY] = rec.get_int(*target_index, false);
      image[IM_ICON_PATH_KEY] = rec.get_string(*target_index, true, true);
    }
  }

  if (flags & onis::database::info_image_dimension) {
    image[IM_WIDTH_KEY] = rec.get_int(*target_index, false);
    image[IM_HEIGHT_KEY] = rec.get_int(*target_index, false);
  }

  if (flags & onis::database::info_image_depth) {
    image[IM_DEPTH_KEY] = rec.get_float(*target_index, false);
  }

  if (flags & onis::database::info_image_compression) {
    image[IM_COMP_STATUS_KEY] = rec.get_int(*target_index, false);
    image[IM_COMP_UPDATE_KEY] = rec.get_int(*target_index, false);
  }

  if (flags & onis::database::info_image_status) {
    auto value = rec.get_uuid(*target_index, false, false);
    if (for_client) {
      if (value == ONLINE_STATUS)
        image[IM_STATUS_KEY] = 0;
      else
        image[IM_STATUS_KEY] = 1;
    } else {
      image[IM_STATUS_KEY] = value;
    }
  }

  if (flags & onis::database::info_image_creation) {
    image[IM_CRDATE_KEY] = rec.get_string(*target_index, false, false);
    image[IM_ORIGIN_ID_KEY] = rec.get_string(*target_index, true, true);
    image[IM_ORIGIN_NAME_KEY] = rec.get_string(*target_index, true, true);
    image[IM_ORIGIN_IP_KEY] = rec.get_string(*target_index, true, true);
  }
}

bool site_database::check_if_sop_already_exist_under_online_or_conflicted_study(
    const std::string& sop, const Json::Value& studies) {
  // obviously, the sop does not exist if the study list if empty:
  if (studies.empty())
    return false;

  // prepare the sql command:
  std::string sql =
      "SELECT COUNT(PACS_IMAGES.ID) AS RESULT FROM PACS_IMAGES INNER JOIN "
      "PACS_SERIES ON PACS_SERIES.ID=PACS_IMAGES.SERIES_ID INNER JOIN "
      "PACS_STUDIES ON PACS_STUDIES.ID = PACS_SERIES.STUDY_ID WHERE "
      "PACS_IMAGES.UID=? AND PACS_IMAGES.STATUS=? AND PACS_SERIES.STATUS=? AND "
      "(";

  for (Json::ArrayIndex i = 0; i < studies.size(); i++) {
    sql += "PACS_STUDIES.ID=?";
    if (i != studies.size() - 1)
      sql += " OR ";
  }
  sql += ")";

  auto query = prepare_query(
      sql, "check_if_sop_already_exist_under_online_or_conflicted_study");
  int index = 1;
  std::string online_status = ONLINE_STATUS;
  bind_parameter(query, index, sop, "sop");
  bind_parameter(query, index, online_status, "status");
  bind_parameter(query, index, online_status, "series_status");
  for (Json::ArrayIndex i = 0; i < studies.size(); i++) {
    bind_parameter(query, index, studies[i]["study"][ST_SEQ_KEY].asString(),
                   "series_status");
  }

  auto result = execute_query(query);
  if (result->has_rows()) {
    auto row = result->get_next_row();
    std::int32_t column_index = 0;
    return row->get_int(column_index, false) > 0;
  }
  throw onis::exception(
      EOS_DB_QUERY,
      "Failed to check if sop already exist under online or conflicted study");
}

//------------------------------------------------------------------------------
// Create operations
//------------------------------------------------------------------------------

std::unique_ptr<onis_kit::database::database_query>
site_database::create_image_insertion_query(
    std::int32_t compression_status, std::int32_t compression_update,
    const std::string& series_seq, const onis::core::date_time& dt,
    const onis::dicom_base_ptr& dataset, std::int32_t image_media,
    const std::string& image_path, bool create_stream, bool create_icon,
    const std::string& origin_id, const std::string& origin_name,
    const std::string& origin_ip, Json::Value& image) {
  std::string charset, sop, instance_num, sop_class, acqnum, width, height,
      depth, original_transfer;
  dataset->get_string_element(charset, TAG_SPECIFIC_CHARACTER_SET, "CS");
  dataset->get_string_element(sop, TAG_SOP_INSTANCE_UID, "UI");
  dataset->get_string_element(instance_num, TAG_INSTANCE_NUMBER, "IS", "");
  dataset->get_string_element(sop_class, TAG_SOP_CLASS_UID, "UI", "");
  dataset->get_string_element(acqnum, TAG_ACQUISITION_NUMBER, "IS", "");
  dataset->get_string_element(width, TAG_COLUMNS, "US", "");
  dataset->get_string_element(height, TAG_ROWS, "US", "");
  dataset->get_string_element(depth, TAG_SLICE_LOCATION, "DS", "");
  dataset->get_string_element(original_transfer, TAG_TRANSFER_SYNTAX_UID, "UI",
                              "");

  // Format date and time as YYYYMMDD HHMMSS using standard C++
  std::ostringstream crdate_oss;
  crdate_oss << std::setfill('0') << std::setw(4) << dt.year() << std::setw(2)
             << dt.month() << std::setw(2) << dt.day() << " " << std::setw(2)
             << dt.hour() << std::setw(2) << dt.minute() << std::setw(2)
             << dt.second();
  std::string crdate = crdate_oss.str();

  std::string sql =
      "INSERT INTO PACS_IMAGES (ID, SERIES_ID, UID, CHARSET, INSTNUM, "
      "SOPCLASS, ACQNUM, IMGMEDIA, IMGPATH, STREAMMEDIA, ICONMEDIA, WIDTH, "
      "HEIGHT, DEPTH, CSTATUS, CUPD, STATUS, CRDATE, OID, ONAME, OIP) VALUES "
      "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

  std::string seq = onis::util::uuid::generate_random_uuid();
  std::string online_status = ONLINE_STATUS;

  auto query = prepare_query(sql, "create_image_insertion_query");

  int index = 1;
  bind_parameter(query, index, seq, "id");
  bind_parameter(query, index, series_seq, "series_id");
  bind_parameter(query, index, sop, "uid");
  bind_parameter(query, index, charset, "charset");
  bind_parameter_optional(query, index, instance_num, "instnum");
  bind_parameter(query, index, sop_class, "sopclass");
  bind_parameter_optional(query, index, acqnum, "acqnum");
  bind_parameter(query, index, image_media, "imgmedia");
  bind_parameter(query, index, image_path, "imgpath");
  bind_parameter(query, index, create_stream ? -2 : -1, "streammedia");
  bind_parameter(query, index, create_icon ? -2 : -1, "iconmedia");
  bind_parameter_optional(query, index, width, "width");
  bind_parameter_optional(query, index, height, "height");
  bind_parameter_optional(query, index, depth, "depth");
  bind_parameter(query, index, compression_status, "cstatus");
  bind_parameter(query, index, compression_update, "cupd");
  bind_parameter(query, index, online_status, "status");
  bind_parameter(query, index, crdate, "crdate");
  bind_parameter(query, index, origin_id, "oid");
  bind_parameter(query, index, origin_name, "oname");
  bind_parameter(query, index, origin_ip, "oip");

  onis::database::image::create(image, onis::database::info_all, false);
  image[IM_SEQ_KEY] = seq;
  image[IM_UID_KEY] = sop;
  image[IM_CHARSET_KEY] = charset;
  image[IM_SOPCLASS_KEY] = sop_class;
  image[IM_INSTNUM_KEY] =
      instance_num == "NULL" ? 0xFFFFFFFF
                             : onis::util::string::convert_to_s32(instance_num);
  image[IM_ACQNUM_KEY] = acqnum == "NULL"
                             ? 0xFFFFFFFF
                             : onis::util::string::convert_to_s32(acqnum);
  image[IM_WIDTH_KEY] = onis::util::string::convert_to_s32(width);
  image[IM_IMAGE_MEDIA_KEY] = image_media;
  image[IM_IMAGE_PATH_KEY] = image_path;
  image[IM_HEIGHT_KEY] = onis::util::string::convert_to_s32(height);
  image[IM_DEPTH_KEY] = depth == "NULL"
                            ? std::numeric_limits<float>::max()
                            : onis::util::string::convert_to_f32(depth);
  image[IM_STATUS_KEY] = ONLINE_STATUS;
  image[IM_CRDATE_KEY] = crdate;
  image[IM_ORIGIN_ID_KEY] = origin_id;
  image[IM_ORIGIN_NAME_KEY] = origin_name;
  image[IM_ORIGIN_IP_KEY] = origin_ip;
  image[IM_STREAM_MEDIA_KEY] = create_stream ? -2 : -1;
  image[IM_STREAM_PATH_KEY] = "";
  image[IM_ICON_MEDIA_KEY] = create_icon ? -2 : -1;
  image[IM_ICON_PATH_KEY] = "";
  image[IM_COMP_STATUS_KEY] = compression_status;
  image[IM_COMP_UPDATE_KEY] = compression_update;

  return query;
}

void site_database::create_image(
    std::int32_t compression_status, std::int32_t compression_update,
    const std::string& series_seq, const onis::core::date_time& dt,
    const onis::dicom_base_ptr& dataset, std::int32_t image_media,
    const std::string& image_path, bool create_stream, bool create_icon,
    const std::string& origin_id, const std::string& origin_name,
    const std::string& origin_ip, Json::Value& image) {
  auto query = create_image_insertion_query(
      compression_status, compression_update, series_seq, dt, dataset,
      image_media, image_path, create_stream, create_icon, origin_id,
      origin_name, origin_ip, image);
  execute_and_check_affected(query, "Failed to create image");
}
