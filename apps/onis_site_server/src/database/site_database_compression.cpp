#include <iostream>
#include <list>
#include <sstream>
#include "../../include/database/items/db_compression.hpp"
#include "../../include/database/site_database.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

using onis::database::lock_mode;

////////////////////////////////////////////////////////////////////////////////
// Compression operations
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Utilities
//------------------------------------------------------------------------------

std::string site_database::get_compression_columns(std::uint32_t flags,
                                                   bool add_table_name) {
  std::string prefix = add_table_name ? "pacs_compressions." : "";
  if (flags == onis::database::info_all) {
    return prefix + "id, " + prefix + "partition_id, " + prefix + "active, " +
           prefix + "mode, " + prefix + "start, " + prefix + "stop, " + prefix +
           "transfer, " + prefix + "updatecnt";
  }
  std::string columns = prefix + "id, " + prefix + "partition_id";
  if (flags & onis::database::info_compression_enable)
    columns += ", " + prefix + "active";
  if (flags & onis::database::info_compression_mode)
    columns += ", " + prefix + "mode, " + prefix + "start, " + prefix + "stop";
  if (flags & onis::database::info_compression_transfer)
    columns += ", " + prefix + "transfer";
  if (flags & onis::database::info_compression_update)
    columns += ", " + prefix + "updatecnt";
  return columns;
}

void site_database::create_compression_item(
    onis_kit::database::database_row& rec, std::uint32_t flags,
    std::string* partition_seq, std::int32_t* start_index, json& output) {
  onis::database::compression::create(output, flags);
  std::int32_t local_index = 0;
  std::int32_t* target_index = start_index ? start_index : &local_index;
  output[BASE_SEQ_KEY] = rec.get_uuid(*target_index, false, false);
  if (partition_seq) {
    *partition_seq = rec.get_uuid(*target_index, false, false);
  } else {
    (*target_index)++;
  }
  output[BASE_UID_KEY] = rec.get_string(*target_index, false, false);

  if (flags & onis::database::info_compression_enable) {
    output[CP_ENABLE_KEY] = rec.get_int(*target_index, false);
  }
  if (flags & onis::database::info_compression_mode) {
    output[CP_MODE_KEY] = rec.get_int(*target_index, false);
    output[CP_START_KEY] = rec.get_int(*target_index, true);
    output[CP_STOP_KEY] = rec.get_int(*target_index, true);
  }
  if (flags & onis::database::info_compression_transfer) {
    output[CP_TRANSFER_KEY] = rec.get_string(*target_index, false, false);
  }
  if (flags & onis::database::info_compression_update) {
    output[CP_UPDATE_KEY] = rec.get_int(*target_index, false);
  }
}

/*void create_compression(const onis::astring& partition_seq,
                        onis::aresult& res);
void find_compressions(const onis::astring& clause, u32 flags, s32 lock_mode,
                       Json::Value& output, onis::astring* partition_seq,
                       onis::aresult& res);
b32 find_compression(const onis::astring& clause, u32 flags, s32 lock_mode,
                     Json::Value& output, onis::astring* partition_seq,
                     onis::aresult& res);
void find_compression_by_seq(const onis::astring& seq, u32 flags,
                             s32 lock_mode, onis::astring* partition_seq,
                             Json::Value& output, onis::aresult& res);
void find_compression_by_seq(const onis::astring& site_seq,
                             const onis::astring& seq, u32 flags,
                             s32 lock_mode, onis::astring* partition_seq,
                             Json::Value& output, onis::aresult& res);
void modify_compression(const Json::Value& compression, u32 flags,
                        s32 updateIndex, onis::aresult& res);*/
void site_database::get_partition_compressions(const std::string& partition_seq,
                                               std::uint32_t flags,
                                               lock_mode lock,
                                               Json::Value& output) {
  auto columns = get_compression_columns(flags, false);
  auto where = "partition_id = ?";
  auto query =
      create_and_prepare_query(columns, "pacs_compressions", where, lock);
  if (!query->bind_parameter(1, partition_seq)) {
    std::throw_with_nested(
        std::runtime_error("Failed to bind partition_id parameter"));
  }
  auto result = execute_query(query);
  if (result->has_rows()) {
    while (auto row = result->get_next_row()) {
      Json::Value& item = output.append(Json::objectValue);
      create_compression_item(*row, flags, nullptr, nullptr, item);
    }
  }
}
/*void get_first_hundred_images_to_compress(onis::astring_list& images,
                                          onis::aresult& res);*/
