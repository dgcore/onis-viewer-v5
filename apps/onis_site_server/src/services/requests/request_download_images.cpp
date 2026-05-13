#include <png.h>
#include <algorithm>
#include <array>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <sstream>
#include <vector>

#include "../../../include/database/items/db_download_image.hpp"
#include "../../../include/database/items/db_download_series.hpp"
#include "../../../include/database/items/db_item.hpp"
#include "../../../include/services/requests/request_data.hpp"
#include "../../../include/services/requests/request_service.hpp"
#include "./download/download_item.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/utilities/date_time.hpp"
#include "onis_kit/include/utilities/filesystem.hpp"
#include "onis_kit/include/utilities/string.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

void request_service::process_download_images_request(
    const request_data_ptr& req) {
  // verify the input:
  onis::database::item::verify_integer_value(req->input_json, "max_bytes",
                                             false);
  onis::database::item::verify_array_value(req->input_json, "images", false);

  // prepare the download items array:
  download_stream_ptr dstream = std::make_shared<download_stream>();
  std::size_t dlitems_index = 0;
  std::size_t max_bytes = req->input_json["max_bytes"].asInt();
  std::size_t total_bytes = 0;

  // Fill the download items array:
  {
    request_database db(this);
    for (const auto& image : req->input_json["images"]) {
      std::string download_seq = image["dl"].asString();

      // prepare a download item for the image:
      std::unique_ptr<DlItem> dlitem = std::make_unique<DlItem>();
      dlitem->index = image["index"].asInt();
      dlitem->init(db, download_seq);

      // get the series download information:
      if (dstream->dlmap.find(download_seq) == dstream->dlmap.end()) {
        dstream->dlmap[download_seq] = Json::Value(Json::objectValue);
        try {
          db->find_download_series_by_seq(download_seq,
                                          onis::database::lock_mode::NO_LOCK,
                                          dstream->dlmap[download_seq]);
          dstream->dl_order.push_back(download_seq);
        } catch (const onis::exception& e) {
          dlitem->res.set(OSRSP_FAILURE, e.get_code(), e.what(), false);
          dstream->dlmap.erase(download_seq);
          continue;
        } catch (...) {
          dlitem->res.set(OSRSP_FAILURE, EOS_UNKNOWN, "Unknown error", false);
          dstream->dlmap.erase(download_seq);
          continue;
        }
      }
      if (!dlitem->res.good()) {
        continue;
      }
      dstream->items.emplace_back(std::move(dlitem));
      if (total_bytes > max_bytes)
        break;
    }
  }

  auto to_le_u32 = [](std::uint32_t value) -> std::array<char, 4> {
    return std::array<char, 4>{
        static_cast<char>(value & 0xFF),
        static_cast<char>((value >> 8) & 0xFF),
        static_cast<char>((value >> 16) & 0xFF),
        static_cast<char>((value >> 24) & 0xFF),
    };
  };
  auto to_le_u64 = [](std::uint64_t value) -> std::array<char, 8> {
    return std::array<char, 8>{
        static_cast<char>(value & 0xFF),
        static_cast<char>((value >> 8) & 0xFF),
        static_cast<char>((value >> 16) & 0xFF),
        static_cast<char>((value >> 24) & 0xFF),
        static_cast<char>((value >> 32) & 0xFF),
        static_cast<char>((value >> 40) & 0xFF),
        static_cast<char>((value >> 48) & 0xFF),
        static_cast<char>((value >> 56) & 0xFF),
    };
  };

  auto stream_callback = [dstream, to_le_u32, to_le_u64](
                             char* out, std::size_t max_len) -> std::size_t {
    if (max_len == 0) {
      return 0;
    }

    std::size_t written = 0;
    while (written < max_len &&
           dstream->current_phase != download_stream::phase::kDone) {
      auto write_from = [&](const char* src, std::size_t len) -> std::size_t {
        const std::size_t remaining = len - dstream->phase_offset;
        const std::size_t can_copy = std::min(max_len - written, remaining);
        std::memcpy(out + written, src + dstream->phase_offset, can_copy);
        written += can_copy;
        dstream->phase_offset += can_copy;
        return can_copy;
      };

      switch (dstream->current_phase) {
        case download_stream::phase::kMagic:
          write_from(dstream->magic.data(), dstream->magic.size());
          dstream->on_data_written();
          break;
        case download_stream::phase::kSeriesCount: {
          std::uint32_t series_count =
              static_cast<std::uint32_t>(dstream->dl_order.size());
          auto series_count_le = to_le_u32(series_count);
          write_from(series_count_le.data(), series_count_le.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kSeriesSeqLen: {
          const std::string& series_seq =
              dstream->dl_order[dstream->series_index];
          auto series_seq_len =
              to_le_u32(static_cast<std::uint32_t>(series_seq.size()));
          write_from(series_seq_len.data(), series_seq_len.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kSeriesSeq: {
          const std::string& series_seq =
              dstream->dl_order[dstream->series_index];
          write_from(series_seq.data(), series_seq.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kSeriesCompleted: {
          const std::string& series_seq =
              dstream->dl_order[dstream->series_index];
          const std::int32_t completed =
              dstream->dlmap[series_seq][DS_COMPLETED_KEY].asInt();
          auto series_completed_le =
              to_le_u32(static_cast<std::uint32_t>(completed));
          write_from(series_completed_le.data(), series_completed_le.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kSeriesExpected: {
          const std::string& series_seq =
              dstream->dl_order[dstream->series_index];
          const std::int32_t expected =
              dstream->dlmap[series_seq][DS_EXPECTED_KEY].asInt();
          auto series_expected_le =
              to_le_u32(static_cast<std::uint32_t>(expected));
          write_from(series_expected_le.data(), series_expected_le.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kItemCount: {
          const std::int32_t item_count =
              static_cast<std::int32_t>(dstream->items.size());
          auto item_count_le =
              to_le_u32(static_cast<std::uint32_t>(item_count));
          write_from(item_count_le.data(), item_count_le.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kItemDownloadSeqLen: {
          const std::string& download_seq =
              dstream->items[dstream->item_index]->download_seq;
          auto download_seq_len =
              to_le_u32(static_cast<std::uint32_t>(download_seq.size()));
          write_from(download_seq_len.data(), download_seq_len.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kItemDownloadSeq: {
          const std::string& download_seq =
              dstream->items[dstream->item_index]->download_seq;
          write_from(download_seq.data(), download_seq.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kItemIndex: {
          const std::int32_t index = dstream->items[dstream->item_index]->index;
          auto index_le = to_le_u32(static_cast<std::uint32_t>(index));
          write_from(index_le.data(), index_le.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kItemType: {
          const DlItemType type = dstream->items[dstream->item_index]->type;
          auto type_le = to_le_u32(static_cast<std::uint32_t>(type));
          write_from(type_le.data(), type_le.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kItemResult: {
          const auto& code = dstream->items[dstream->item_index]->res.reason;
          auto code_le = to_le_u32(code);
          write_from(code_le.data(), code_le.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kItemFileSize: {
          const std::size_t file_size =
              dstream->items[dstream->item_index]->file_size;
          auto file_size_le = to_le_u64(static_cast<std::uint64_t>(file_size));
          write_from(file_size_le.data(), file_size_le.size());
          dstream->on_data_written();
          break;
        }
        case download_stream::phase::kItemFilePayload: {
          auto& item = dstream->items[dstream->item_index];
          const std::size_t file_remaining =
              item->file_size - dstream->phase_offset;
          if (file_remaining == 0) {
            dstream->current_file.close();
            dstream->on_data_written();
            break;
          }
          const std::size_t to_read =
              std::min(max_len - written, file_remaining);
          dstream->current_file.read(out + written,
                                     static_cast<std::streamsize>(to_read));
          const std::size_t read_count =
              static_cast<std::size_t>(dstream->current_file.gcount());
          written += read_count;
          dstream->phase_offset += read_count;
          if (read_count == 0 || dstream->phase_offset >= item->file_size ||
              dstream->current_file.eof()) {
            dstream->current_file.close();
            dstream->phase_offset = item->file_size;
            dstream->on_data_written();
          }
          break;
        }
        case download_stream::phase::kDone:
          break;
      }
    }
    return written;
  };

  req->write_output(
      [&stream_callback](request_data::stream_reader_fn& output_stream) {
        output_stream = stream_callback;
      });
}
#ifdef _BEFORE_FILE_STREAMING_SUPPORT_
namespace {
void my_png_write_data(png_structp png_ptr, png_bytep data, png_size_t length) {
  /* with libpng15 next line causes pointer deference error; use libpng12 */
  struct DlItem* p = (DlItem*)png_get_io_ptr(png_ptr); /* was png_ptr->io_ptr */
  size_t nsize = p->data_len + length;

  /* allocate or grow buffer */
  if (p->data)
    p->data = (std::uint8_t*)realloc(p->data, nsize);
  else
    p->data = (std::uint8_t*)malloc(nsize);

  if (!p->data)
    png_error(png_ptr, "Write Error");

  /* copy new bytes to end of buffer */
  memcpy(p->data + p->data_len, data, length);
  p->data_len += length;
}

void my_png_flush(png_structp png_ptr) {}

/*void dump_bytes_as_hex(const std::uint8_t* data, std::size_t len,
                       const std::string& label,
                       const std::string& file_name = "pngData.txt") {
  if (data == nullptr || len == 0)
    return;
  const char* home = std::getenv("HOME");
  std::string path =
      home ? std::string(home) + "/Documents/" + file_name : file_name;
  std::ofstream out(path, std::ios::out | std::ios::app);
  if (!out.is_open())
    return;

  out << "==== " << label << " len=" << len << " ====\n";
  if (len >= 2) {
    std::int16_t min_s16 = std::numeric_limits<std::int16_t>::max();
    std::int16_t max_s16 = std::numeric_limits<std::int16_t>::min();
    for (std::size_t i = 0; i + 1 < len; i += 2) {
      // Read as signed short (little-endian byte order).
      const std::uint16_t raw = static_cast<std::uint16_t>(data[i]) |
                                (static_cast<std::uint16_t>(data[i + 1]) <<
8); const std::int16_t v = static_cast<std::int16_t>(raw); if (v < min_s16)
        min_s16 = v;
      if (v > max_s16)
        max_s16 = v;
    }
    out << "s16_min=" << min_s16 << " s16_max=" << max_s16 << "\n";
  }
  const std::size_t bytes_per_line = 32;
  for (std::size_t i = 0; i < len; i += bytes_per_line) {
    const std::size_t end = std::min(i + bytes_per_line, len);
    out << std::hex << std::setw(8) << std::setfill('0') << i << ": ";
    for (std::size_t j = i; j < end; ++j) {
      out << std::hex << std::setw(2) << std::setfill('0')
          << static_cast<std::int32_t>(data[j]);
      if (j + 1 < end)
        out << ' ';
    }
    out << '\n';
  }
  out << std::dec << '\n';
}

struct png_mem_reader {
  const std::uint8_t* data;
  std::size_t size;
  std::size_t offset;
};

void png_read_from_mem(png_structp png_ptr, png_bytep outBytes,
                       png_size_t byteCountToRead) {
  png_mem_reader* reader =
      static_cast<png_mem_reader*>(png_get_io_ptr(png_ptr));
  if (!reader || reader->offset + byteCountToRead > reader->size) {
    png_error(png_ptr, "png_read_from_mem: read beyond end of buffer");
    return;
  }
  std::memcpy(outBytes, reader->data + reader->offset, byteCountToRead);
  reader->offset += byteCountToRead;
}

void dump_png_decoded_as_hex(
    const std::uint8_t* data, std::size_t len, const std::string& label,
    const std::uint8_t* original_data = nullptr, std::size_t original_len =
0) { if (data == nullptr || len == 0) return;

  png_mem_reader reader{data, len, 0};

  png_structp png_ptr =
      png_create_read_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr,
nullptr); if (!png_ptr) return;

  png_infop info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr) {
    png_destroy_read_struct(&png_ptr, nullptr, nullptr);
    return;
  }

  if (setjmp(png_jmpbuf(png_ptr))) {
    png_destroy_read_struct(&png_ptr, &info_ptr, nullptr);
    return;
  }

  png_set_read_fn(png_ptr, &reader, png_read_from_mem);
  png_read_info(png_ptr, info_ptr);

  png_uint_32 width = 0, height = 0;
  int bit_depth = 0, color_type = 0;
  png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type,
               nullptr, nullptr, nullptr);

  if (width == 0 || height == 0) {
    png_destroy_read_struct(&png_ptr, &info_ptr, nullptr);
    return;
  }

  // Only handle grayscale images here; bail out otherwise.
  if (color_type != PNG_COLOR_TYPE_GRAY) {
    png_destroy_read_struct(&png_ptr, &info_ptr, nullptr);
    return;
  }

  const png_size_t rowbytes = png_get_rowbytes(png_ptr, info_ptr);
  std::vector<std::uint8_t> buffer(rowbytes * height);
  std::vector<png_bytep> row_pointers(height);
  for (png_uint_32 y = 0; y < height; ++y) {
    row_pointers[y] = buffer.data() + y * rowbytes;
  }

  // Keep decoded 16-bit samples in host endianness (little-endian on
macOS). if (bit_depth == 16) { png_set_swap(png_ptr);
  }

  png_read_image(png_ptr, row_pointers.data());
  png_read_end(png_ptr, info_ptr);
  png_destroy_read_struct(&png_ptr, &info_ptr, nullptr);

  const char* home = std::getenv("HOME");
  std::string path =
      home ? std::string(home) + "/Documents/pngDecoded.txt" :
"pngDecoded.txt"; std::ofstream out(path, std::ios::out | std::ios::app); if
(!out.is_open()) return;

  out << "==== " << label << " decoded GRAY "
      << "w=" << width << " h=" << height << " bit_depth=" << bit_depth
      << " bytes=" << buffer.size() << " ====\n";
  if (bit_depth == 16 && buffer.size() >= 2) {
    std::int16_t min_s16 = std::numeric_limits<std::int16_t>::max();
    std::int16_t max_s16 = std::numeric_limits<std::int16_t>::min();
    for (std::size_t i = 0; i + 1 < buffer.size(); i += 2) {
      // PNG stores 16-bit samples in big-endian.
      const std::uint16_t raw =
          (static_cast<std::uint16_t>(buffer[i]) << 8) |
          static_cast<std::uint16_t>(buffer[i + 1]);
      const std::int16_t v = static_cast<std::int16_t>(raw);
      if (v < min_s16)
        min_s16 = v;
      if (v > max_s16)
        max_s16 = v;
    }
    out << "s16_min=" << min_s16 << " s16_max=" << max_s16 << "\n";

    if (original_data != nullptr && original_len >= 2) {
      const std::size_t decoded_samples = buffer.size() / 2;
      const std::size_t original_samples = original_len / 2;
      const std::size_t sample_count = std::min(decoded_samples,
original_samples); std::size_t mismatch_count = 0; std::size_t
first_mismatch_index = 0; std::int16_t first_decoded_value = 0; std::int16_t
first_original_value = 0; bool found_first = false;

      for (std::size_t s = 0; s < sample_count; ++s) {
        const std::size_t db = s * 2;
        const std::size_t ob = s * 2;
        // Decoded PNG bytes are big-endian.
        const std::uint16_t decoded_raw =
            (static_cast<std::uint16_t>(buffer[db]) << 8) |
            static_cast<std::uint16_t>(buffer[db + 1]);
        // Original pixels in memory are little-endian on this platform.
        const std::uint16_t original_raw =
            static_cast<std::uint16_t>(original_data[ob]) |
            (static_cast<std::uint16_t>(original_data[ob + 1]) << 8);
        const std::int16_t decoded_s16 =
static_cast<std::int16_t>(decoded_raw); const std::int16_t original_s16 =
static_cast<std::int16_t>(original_raw); if (decoded_s16 != original_s16) {
          ++mismatch_count;
          if (!found_first) {
            found_first = true;
            first_mismatch_index = s;
            first_decoded_value = decoded_s16;
            first_original_value = original_s16;
          }
        }
      }

      const bool same_length = decoded_samples == original_samples;
      out << "compare_with_original_s16 "
          << "decoded_samples=" << decoded_samples
          << " original_samples=" << original_samples
          << " compared_samples=" << sample_count
          << " mismatches=" << mismatch_count
          << " same_length=" << (same_length ? "true" : "false") << "\n";
      if (found_first) {
        out << "first_mismatch index=" << first_mismatch_index
            << " decoded=" << first_decoded_value
            << " original=" << first_original_value << "\n";
      }
    }
  }

  const std::size_t bytes_per_line = 32;
  for (std::size_t i = 0; i < buffer.size(); i += bytes_per_line) {
    const std::size_t end = std::min(i + bytes_per_line, buffer.size());
    out << std::hex << std::setw(8) << std::setfill('0') << i << ": ";
    for (std::size_t j = i; j < end; ++j) {
      out << std::hex << std::setw(2) << std::setfill('0')
          << static_cast<std::int32_t>(buffer[j]);
      if (j + 1 < end)
        out << ' ';
    }
    out << '\n';
  }
  out << std::dec << '\n';
}*/

}  // namespace

void request_service::process_download_images_request(
    const request_data_ptr& req) {
  const bool stream_response =
      req->input_json.isMember("stream") && req->input_json["stream"].asBool();
  auto get_file_size = [](const std::string& path) -> std::int64_t {
    std::ifstream ifs(path, std::ios::binary | std::ios::ate);
    if (!ifs.is_open()) {
      return -1;
    }
    const auto pos = ifs.tellg();
    if (pos < 0) {
      return -1;
    }
    return static_cast<std::int64_t>(pos);
  };

  // verify the input:
  onis::database::item::verify_integer_value(req->input_json, "max_bytes",
                                             false);
  onis::database::item::verify_array_value(req->input_json, "images", false);

  // get an access to the database:
  std::unordered_map<std::string, Json::Value*> dlmap;
  std::list<DlItem*> dlitems;
  std::int32_t max_bytes = req->input_json["max_bytes"].asInt();

  {
    request_database db(this);
    std::int32_t total_bytes = 0;
    for (const auto& image : req->input_json["images"]) {
      // prepare a download item for the image:
      std::string dlseq = image["dl"].asString();
      DlItem* dlitem = new DlItem(dlseq);
      dlitems.push_back(dlitem);
      dlitem->index = image["index"].asInt();

      // get the series download information:
      Json::Value* dlinfo = dlmap[dlseq];
      if (dlinfo == NULL) {
        dlinfo = new Json::Value(Json::objectValue);
        try {
          db->find_download_series_by_seq(
              dlseq, onis::database::lock_mode::NO_LOCK, *dlinfo);
        } catch (const onis::exception& e) {
          dlitem->res.set(OSRSP_FAILURE, e.get_code(), e.what(), false);
          continue;
        } catch (...) {
          dlitem->res.set(OSRSP_FAILURE, EOS_UNKNOWN, "Unknown error", false);
          continue;
        }
        dlmap[dlseq] = dlinfo;
      }

      // verify the permission:
      /*if (dlitem->res.good() &&
          req->session->session_id != (*dlinfo)[DS_SESSION_KEY].asString())
        dlitem->res.set(OSRSP_FAILURE, EOS_PERMISSION, "", OSFALSE);*/

      // init path and resolution offset:
      dlitem->cloud_decode_image_j2k_offsets(db, dlseq);
      if (dlitem->res.good() && dlitem->type != 0) {
        dlitem->cur_res = image["from"].asInt();
      }
      if (dlitem->res.good() && dlitem->type == 0) {  // dicom file format
        if (image.isMember("byte_offset")) {
          dlitem->dicom_byte_offset = image["byte_offset"].asInt64();
        } else {
          dlitem->dicom_byte_offset = 0;
        }
        if (dlitem->dicom_byte_offset < 0) {
          dlitem->dicom_byte_offset = 0;
        }

        const std::int64_t file_size = get_file_size(dlitem->path);
        if (file_size <= 0) {
          dlitem->res.set(OSRSP_FAILURE, EOS_FILE_OPEN,
                          "Failed to open DICOM file", false);
          continue;
        }

        std::int64_t from_offset = dlitem->dicom_byte_offset;
        if (from_offset >= file_size) {
          dlitem->dicom_byte_end = -1;
          continue;
        }

        std::int64_t chunk_len = file_size - from_offset;
        if (max_bytes > 0) {
          if (total_bytes == 0) {
            chunk_len = std::min<std::int64_t>(
                chunk_len, static_cast<std::int64_t>(max_bytes));
          } else {
            std::int64_t remaining_budget =
                static_cast<std::int64_t>(max_bytes - total_bytes);
            if (remaining_budget <= 0) {
              break;
            }
            chunk_len = std::min<std::int64_t>(chunk_len, remaining_budget);
          }
        }

        if (chunk_len <= 0) {
          break;
        }

        dlitem->dicom_byte_end = from_offset + chunk_len;
        total_bytes += static_cast<std::int32_t>(chunk_len);
      } else {
        total_bytes += dlitem->cloud_increase_image_resolution();
      }
      if (total_bytes > max_bytes)
        break;
    }
  }

  // now we calculate the exact length of the output:
  std::int32_t total_length = 0;
  for (std::list<DlItem*>::iterator it = dlitems.begin(); it != dlitems.end();
       it++) {
    if ((*it)->res.good()) {
      if ((*it)->type == 0) {
        if ((*it)->dicom_byte_end <= (*it)->dicom_byte_offset) {
          continue;
        }
      } else if ((*it)->new_res == -1) {
        continue;
      }
    } else {
      continue;
    }

    // we will write the series id:
    total_length += sizeof(std::uint8_t) + (*it)->srdlid.length();
    // we will write the image index (32 bits):
    total_length += sizeof(std::int32_t);
    // we will write the image result (32 bits):
    total_length += sizeof(std::int32_t);
    // additional data only if the result was ok:
    if ((*it)->res.good()) {
      if ((*it)->type == 1) {  // raw format
        (*it)->type = 3;       // png format
        (*it)->type = 0;       // dicom format
      }
      if ((*it)->type == 1 || (*it)->type == 3) {  // raw or png format
        // raw format or png!
        std::size_t count = 0;
        const void* pixels = (*it)->frame->get_intermediate_pixel_data(&count);
        if ((*it)->cur_res == -1) {
          if ((*it)->type == 3) {  // png format
            // convert to png:
            std::size_t width, height;
            (*it)->frame->get_dimensions(&width, &height);
            png_structp png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING,
                                                          NULL, NULL, NULL);
            if (png_ptr) {
              png_infop info_ptr = png_create_info_struct(png_ptr);
              if (info_ptr) {
                if (!setjmp(png_jmpbuf(png_ptr))) {
                  png_bytep* row_pointers = new png_bytep[height];
                  if ((*it)->frame->is_monochrome()) {
                    std::int32_t bpp = (*it)->frame->get_bits_per_pixel();
                    if (bpp <= 8) {
                      std::uint8_t* data = (std::uint8_t*)pixels;
                      for (int i = 0; i < height; i++)
                        row_pointers[i] = (png_bytep)&data[width * i];
                      png_set_write_fn(png_ptr, *it, my_png_write_data,
                                       my_png_flush);
                      png_set_IHDR(png_ptr, info_ptr, width, height, 8,
                                   PNG_COLOR_TYPE_GRAY, PNG_INTERLACE_NONE,
                                   PNG_COMPRESSION_TYPE_DEFAULT,
                                   PNG_FILTER_TYPE_DEFAULT);
                      png_set_rows(png_ptr, info_ptr, row_pointers);
                      png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY,
                                    nullptr);

                    } else if (bpp <= 16) {
                      std::uint16_t* data = (std::uint16_t*)pixels;
                      for (int i = 0; i < height; i++)
                        row_pointers[i] = (png_bytep)&data[width * i];
                      /*dump_bytes_as_hex(
                          reinterpret_cast<const std::uint8_t*>(data),
                          static_cast<std::size_t>(width) *
                              static_cast<std::size_t>(height) *
                              sizeof(std::uint16_t),
                          "pre-png monochrome 16-bit pixels",
                          "pngPreEncode.txt");*/
                      png_set_write_fn(png_ptr, *it, my_png_write_data,
                                       my_png_flush);
                      png_set_IHDR(png_ptr, info_ptr, width, height, 16,
                                   PNG_COLOR_TYPE_GRAY, PNG_INTERLACE_NONE,
                                   PNG_COMPRESSION_TYPE_DEFAULT,
                                   PNG_FILTER_TYPE_DEFAULT);
                      // Our source buffer is uint16 in host endianness.
                      // PNG requires big-endian 16-bit samples.
                      png_set_swap(png_ptr);
                      png_set_rows(png_ptr, info_ptr, row_pointers);
                      png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY,
                                    NULL);
                      /*if ((*it)->data && (*it)->data_len) {
                         dump_png_decoded_as_hex(
                             (*it)->data, (*it)->data_len,
                             "decoded from just-encoded png (16-bit)",
                             reinterpret_cast<const std::uint8_t*>(data),
                             static_cast<std::size_t>(width) *
                                 static_cast<std::size_t>(height) *
                                 sizeof(std::uint16_t));
                       }*/
                    }
                  } else {
                    // reconstruct the rgb data:
                    std::uint8_t* rgb = new std::uint8_t[width * height * 3];
                    std::uint8_t* source[3];
                    source[0] = ((std::uint8_t**)pixels)[0];
                    source[1] = ((std::uint8_t**)pixels)[1];
                    source[2] = ((std::uint8_t**)pixels)[2];
                    std::int32_t offset = 0;
                    for (std::size_t i = 0; i < height; i++) {
                      std::int32_t k = width * i;
                      for (std::size_t j = 0; j < width; j++) {
                        rgb[offset] = source[0][k + j];
                        offset++;
                        rgb[offset] = source[1][k + j];
                        offset++;
                        rgb[offset] = source[2][k + j];
                        offset++;
                      }
                      row_pointers[i] = (png_bytep)&rgb[width * 3 * i];
                    }
                    png_set_write_fn(png_ptr, *it, my_png_write_data,
                                     my_png_flush);
                    png_set_IHDR(png_ptr, info_ptr, width, height, 8,
                                 PNG_COLOR_TYPE_RGB, PNG_INTERLACE_NONE,
                                 PNG_COMPRESSION_TYPE_DEFAULT,
                                 PNG_FILTER_TYPE_DEFAULT);
                    png_set_rows(png_ptr, info_ptr, row_pointers);
                    png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY,
                                  nullptr);
                    delete[] rgb;
                  }
                  delete[] row_pointers;
                }
                png_destroy_info_struct(png_ptr, &info_ptr);
              }
              png_destroy_write_struct(&png_ptr, (png_infopp) nullptr);
            }
            if ((*it)->data_len != 0)
              (*it)->delete_data = true;
            else {
              (*it)->type = 1;
              delete[] (*it)->data;
              (*it)->data = (std::uint8_t*)pixels;
              (*it)->data_len = static_cast<std::uint32_t>(count);
              (*it)->delete_data = false;
            }

          } else {  // raw format

            (*it)->data = (std::uint8_t*)pixels;
            (*it)->data_len = static_cast<std::uint32_t>(count);
            (*it)->delete_data = false;
          }

          // we will write the image format:
          total_length += sizeof(std::int32_t);
          // we will write the tag length:
          total_length += sizeof(std::int32_t);
          // we will write the tags:
          total_length += (*it)->tags.length();

          // write the palette:
          total_length += sizeof(std::int32_t);
          if ((*it)->palette[0]) {
            for (std::int32_t k = 0; k < 3; k++) {
              total_length += sizeof(std::int32_t) * 4;
              total_length += (*it)->palette[k]->data_len;
            }
          }

          // total_length += 8; //frame index + frame count
          total_length += 8;  // width + height
          total_length += 1;  // monochrome or rgb

          if ((*it)
                  ->frame
                  ->is_monochrome() /* && !(*it)->frame->have_palette()*/) {
            total_length += 2;  // representation
            total_length += 1;  // signed

            total_length += 4;  // pixel data length

            total_length += (*it)->data_len;

          } else {
            bool have_palette = (*it)->frame->have_palette();
            std::int32_t bits_per_pixel =
                have_palette ? 24 : (*it)->frame->get_bits_per_pixel();
            total_length += 1;  // bits per pixel
            if (bits_per_pixel == 24 || bits_per_pixel == 32) {
              total_length += 4;  // pixel data length
              if ((*it)->type == 1)
                total_length += (*it)->data_len * 3;  // pixel data
              else
                total_length += (*it)->data_len;  // pixel data
            }
          }
        }
      } else if ((*it)->type == 2) {  // stream format

        if ((*it)->cur_res == -1) {
          // this is the first time we send the image data!
          // we will write the image format:
          total_length += sizeof(std::int32_t);
          // we will write the new image resolution:
          total_length += sizeof(std::int32_t);
          // we will write the data length:
          total_length += sizeof(std::int32_t);
          if ((*it)->new_res != -1) {
            // we will write the data:
            total_length += (*it)->offsets[(*it)->new_res * 2] +
                            (*it)->offsets[(*it)->new_res * 2 + 1] -
                            (*it)->offsets[((*it)->cur_res + 1) * 2];
          }

        } else {
          // we already sent a previous resolution data
          // we just need to send additional data:
          // we will write the data length:
          total_length += sizeof(std::int32_t);
          if ((*it)->new_res != -1) {
            // we will write the data:
            total_length += (*it)->offsets[(*it)->new_res * 2] +
                            (*it)->offsets[(*it)->new_res * 2 + 1] -
                            (*it)->offsets[((*it)->cur_res + 1) * 2];
          }
        }
      } else if ((*it)->type == 0) {  // dicom format
        std::int64_t data_offset = (*it)->dicom_byte_offset;
        std::int64_t data_end = (*it)->dicom_byte_end;
        if (data_end > data_offset) {
          std::int64_t data_length = data_end - data_offset;
          std::int64_t file_size = get_file_size((*it)->path);
          if (file_size <= 0) {
            (*it)->res.set(OSRSP_FAILURE, EOS_FILE_OPEN,
                           "Failed to open DICOM file", false);
            continue;
          }

          if (data_offset == 0) {
            // first packet for this image: announce file format and full
            // size.
            total_length += sizeof(std::int32_t);  // image format = 0
            total_length += sizeof(std::int32_t);  // total file size
          }

          // write next offset and bytes for this packet.
          total_length += sizeof(std::int32_t);  // next offset
          total_length += sizeof(std::int32_t);  // data length
          total_length += static_cast<std::int32_t>(data_length);  // data
        }
      }
    }
  }

  // we have to write also the header of the request:
  // we will write the status of the request:
  total_length += sizeof(std::int32_t);
  // number of series input
  total_length += sizeof(std::int32_t);
  total_length +=
      (sizeof(std::int32_t) + sizeof(std::int32_t)) *
      dlmap.size();  // number of received and expected images for each series
  for (std::unordered_map<std::string, Json::Value*>::iterator it =
           dlmap.begin();
       it != dlmap.end(); it++) {
    std::string value = (*it->second)[BASE_SEQ_KEY].asString();
    total_length += sizeof(std::uint8_t) + value.length();
  }

  // now, we can prepare the output:
  std::int32_t current_offset = 0;
  req->write_output(
      [&](json& output, std::vector<std::uint8_t>& binary_output) {
        binary_output.resize(total_length);
        // write the status of the request:
        *((std::int32_t*)&binary_output[current_offset]) = 0;
        current_offset += sizeof(std::int32_t);
        // write the number of series information:
        *((std::int32_t*)&binary_output[current_offset]) =
            (std::int32_t)dlmap.size();
        current_offset += sizeof(std::int32_t);
        for (std::unordered_map<std::string, Json::Value*>::iterator it =
                 dlmap.begin();
             it != dlmap.end(); it++) {
          Json::Value* elt = it->second;
          // write the series identifier:
          std::string value = (*elt)[BASE_SEQ_KEY].asString();
          *((std::uint8_t*)&binary_output[current_offset]) =
              (std::uint8_t)value.length();
          current_offset += sizeof(std::uint8_t);
          memcpy(&binary_output[current_offset], value.data(), value.length());
          current_offset += value.length();
          // write the number of image received:
          *((std::int32_t*)&binary_output[current_offset]) =
              (*elt)[DS_COMPLETED_KEY].asInt();
          current_offset += sizeof(std::int32_t);
          // write the number of expected images:
          *((std::int32_t*)&binary_output[current_offset]) =
              (*elt)[DS_EXPECTED_KEY].asInt();
          current_offset += sizeof(std::int32_t);
        }

        // write each image data:
        for (std::list<DlItem*>::iterator it = dlitems.begin();
             it != dlitems.end(); it++) {
          if ((*it)->res.good()) {
            if ((*it)->type == 0) {
              if ((*it)->dicom_byte_end <= (*it)->dicom_byte_offset) {
                continue;
              }
            } else if ((*it)->new_res == -1) {
              continue;
            }
          } else {
            continue;
          }

          // write the series id:
          *((std::uint8_t*)&binary_output[current_offset]) =
              (std::uint8_t)(*it)->srdlid.length();
          current_offset += sizeof(std::uint8_t);
          memcpy(&binary_output[current_offset], (*it)->srdlid.data(),
                 (*it)->srdlid.length());
          current_offset += (*it)->srdlid.length();
          // write the image index (32 bits):
          *((std::int32_t*)&binary_output[current_offset]) = (*it)->index;
          current_offset += sizeof(std::int32_t);
          // write the image result (32 bits):
          *((std::int32_t*)&binary_output[current_offset]) = (*it)->res.reason;
          current_offset += sizeof(std::int32_t);
          // additional data only if the result was ok:
          if ((*it)->res.good()) {
            if ((*it)->type == 1 || (*it)->type == 3) {  // raw or png format

              printf("bordel1¥n");

              std::size_t width, height;
              (*it)->frame->get_dimensions(&width, &height);

              if ((*it)->cur_res == -1) {
                // write the image format:
                *((std::int32_t*)&binary_output[current_offset]) = (*it)->type;
                current_offset += sizeof(std::int32_t);
                // write the tag length:
                *((std::int32_t*)&binary_output[current_offset]) =
                    (*it)->tags.size();
                current_offset += sizeof(std::int32_t);
                // write the tags:
                memcpy(&binary_output[current_offset], (*it)->tags.data(),
                       (*it)->tags.size());
                current_offset += (*it)->tags.size();

                // write the palette:
                std::int32_t palette_len_pos = current_offset;
                *((std::int32_t*)&binary_output[current_offset]) = 0;
                current_offset += sizeof(std::int32_t);
                // onis::dicom_palette
                if ((*it)->palette[0]) {
                  for (std::int32_t k = 0; k < 3; k++) {
                    *((std::int32_t*)&binary_output[current_offset]) =
                        (*it)->palette[k]->count;
                    current_offset += sizeof(std::int32_t);
                    *((std::int32_t*)&binary_output[current_offset]) =
                        (*it)->palette[k]->bits;
                    current_offset += sizeof(std::int32_t);
                    *((std::int32_t*)&binary_output[current_offset]) =
                        (*it)->palette[k]->value;
                    current_offset += sizeof(std::int32_t);
                    *((std::int32_t*)&binary_output[current_offset]) =
                        (*it)->palette[k]->data_len;
                    current_offset += sizeof(std::int32_t);
                    memcpy(&binary_output[current_offset],
                           (*it)->palette[k]->data,
                           (*it)->palette[k]->data_len);
                    current_offset += (*it)->palette[k]->data_len;
                  }
                  *((std::int32_t*)&binary_output[palette_len_pos]) =
                      current_offset - palette_len_pos - sizeof(std::int32_t);
                }
                // write the image dimensions:
                *((std::int32_t*)&binary_output[current_offset]) = width;
                current_offset += sizeof(std::int32_t);
                *((std::int32_t*)&binary_output[current_offset]) = height;
                current_offset += sizeof(std::int32_t);

                if ((*it)->frame->is_monochrome() /*&& !(*it)->frame->have_palette()*/) {
                  *((std::int8_t*)&binary_output[current_offset]) = 0;
                  current_offset += sizeof(std::int8_t);  // monochrome
                  bool signed_data;
                  std::int32_t representation =
                      (*it)->frame->get_representation(&signed_data);
                  *((std::int16_t*)&binary_output[current_offset]) =
                      (std::int16_t)representation;
                  current_offset += sizeof(std::int16_t);
                  *((std::int8_t*)&binary_output[current_offset]) =
                      signed_data ? 1 : 0;
                  current_offset += sizeof(std::int8_t);
                  *((std::int32_t*)&binary_output[current_offset]) =
                      (*it)->data_len;
                  current_offset += sizeof(std::int32_t);
                  if ((*it)->data_len) {
                    /*dump_bytes_as_hex((*it)->data, (*it)->data_len,
                                      "monochrome image data (PNG or raw)");
                    dump_png_decoded_as_hex((*it)->data, (*it)->data_len,
                                            "monochrome image data
                    decoded");*/
                    memcpy(&binary_output[current_offset], (*it)->data,
                           (*it)->data_len);
                  }
                  current_offset += (*it)->data_len;

                } else {
                  *((std::int8_t*)&binary_output[current_offset]) = 1;
                  current_offset += sizeof(std::int8_t);  // rgb
                  bool have_palette = (*it)->frame->have_palette();
                  std::int32_t bits_per_pixel =
                      have_palette ? 24 : (*it)->frame->get_bits_per_pixel();
                  *((std::int8_t*)&binary_output[current_offset]) =
                      (std::int8_t)bits_per_pixel;
                  current_offset += sizeof(std::int8_t);
                  if (bits_per_pixel == 24 || bits_per_pixel == 32) {
                    // Get the RGB pixels:

                    // pixel data:
                    if ((*it)->data_len) {
                      if ((*it)->type == 1) {
                        std::uint8_t* source[3];
                        source[0] = ((std::uint8_t**)(*it)->data)[0];
                        source[1] = ((std::uint8_t**)(*it)->data)[1];
                        source[2] = ((std::uint8_t**)(*it)->data)[2];

                        *((std::int32_t*)&binary_output[current_offset]) =
                            (*it)->data_len * 3;
                        current_offset += sizeof(std::int32_t);
                        memcpy(&binary_output[current_offset], source[0],
                               (*it)->data_len);
                        current_offset += (*it)->data_len;
                        memcpy(&binary_output[current_offset], source[1],
                               (*it)->data_len);
                        current_offset += (*it)->data_len;
                        memcpy(&binary_output[current_offset], source[2],
                               (*it)->data_len);
                        current_offset += (*it)->data_len;

                      } else {
                        *((std::int32_t*)&binary_output[current_offset]) =
                            (*it)->data_len;
                        current_offset += sizeof(std::int32_t);
                        memcpy(&binary_output[current_offset], (*it)->data,
                               (*it)->data_len);
                        current_offset += (*it)->data_len;
                      }
                    }
                  }
                }

              } else {
              }

            } else if ((*it)->type == 3) {  // png format
              printf("bordel2¥n");

            } else if ((*it)->type == 2) {  // stream data
              printf("bordel3¥n");

              std::int32_t data_offset = 0;
              std::int32_t data_length = 0;
              if ((*it)->cur_res == -1) {
                // this is the first time we send the image data!
                // write the image format:
                *((std::int32_t*)&binary_output[current_offset]) = (*it)->type;
                current_offset += sizeof(std::int32_t);
                // write the new image resolution:
                *((std::int32_t*)&binary_output[current_offset]) =
                    (*it)->new_res;
                current_offset += sizeof(std::int32_t);
              }
              if ((*it)->new_res != -1) {
                // calculate the data length and offset:
                data_length = (*it)->offsets[(*it)->new_res * 2] +
                              (*it)->offsets[(*it)->new_res * 2 + 1] -
                              (*it)->offsets[((*it)->cur_res + 1) * 2];
                data_offset = (*it)->offsets[((*it)->cur_res + 1) * 2];
              }

              // write the data from file:
              onis::file_ptr fp = onis::file::open_file(
                  (*it)->path, onis::fflags::read | onis::fflags::binary);
              if (fp != NULL) {
                // write the data length:
                *((std::int32_t*)&binary_output[current_offset]) = data_length;
                current_offset += sizeof(std::int32_t);
                // write the data:
                fp->seek(data_offset, onis::fflags::begin);
                std::int32_t read =
                    fp->read(&binary_output[current_offset], data_length);
                fp->close();
                if (read == data_length)
                  current_offset += data_length;
                else
                  *((std::int32_t*)&binary_output[current_offset] - 4) = 0;

              } else {
                // couldn't open the file.
                // write the data length:
                *((std::int32_t*)&binary_output[current_offset]) = 0;
                current_offset += sizeof(std::int32_t);
              }
            } else if ((*it)->type == 0) {  // dicom file data
              printf("bordel4¥n");
              std::int64_t data_offset = (*it)->dicom_byte_offset;
              std::int64_t data_end = (*it)->dicom_byte_end;
              std::int64_t data_length = 0;
              if (data_end > data_offset)
                data_length = data_end - data_offset;

              if (data_length > 0) {
                onis::file_ptr fp = onis::file::open_file(
                    (*it)->path, onis::fflags::read | onis::fflags::binary);
                if (fp != NULL) {
                  if (data_offset == 0) {
                    const std::int64_t file_size_i64 =
                        get_file_size((*it)->path);
                    std::int32_t file_size =
                        file_size_i64 > std::numeric_limits<std::int32_t>::max()
                            ? std::numeric_limits<std::int32_t>::max()
                            : static_cast<std::int32_t>(file_size_i64);
                    // first packet: image format and full size
                    *((std::int32_t*)&binary_output[current_offset]) = 0;
                    current_offset += sizeof(std::int32_t);
                    *((std::int32_t*)&binary_output[current_offset]) =
                        file_size;
                    current_offset += sizeof(std::int32_t);
                    printf("coucou1¥n");
                    std::cerr
                        << "request_download_images: dicom first packet"
                        << " dl=" << (*it)->srdlid << " index=" << (*it)->index
                        << " path=" << (*it)->path << " file_size=" << file_size
                        << " data_offset=" << data_offset
                        << " data_end=" << data_end
                        << " data_length=" << data_length << std::endl;
                  }

                  // next offset
                  *((std::int32_t*)&binary_output[current_offset]) =
                      data_end > std::numeric_limits<std::int32_t>::max()
                          ? std::numeric_limits<std::int32_t>::max()
                          : static_cast<std::int32_t>(data_end);
                  current_offset += sizeof(std::int32_t);
                  // data length
                  *((std::int32_t*)&binary_output[current_offset]) =
                      data_length > std::numeric_limits<std::int32_t>::max()
                          ? std::numeric_limits<std::int32_t>::max()
                          : static_cast<std::int32_t>(data_length);
                  current_offset += sizeof(std::int32_t);

                  fp->seek(data_offset, onis::fflags::begin);
                  const std::int32_t read_len =
                      data_length > std::numeric_limits<std::int32_t>::max()
                          ? std::numeric_limits<std::int32_t>::max()
                          : static_cast<std::int32_t>(data_length);
                  std::int32_t read =
                      fp->read(&binary_output[current_offset], read_len);
                  fp->close();
                  if (read == read_len) {
                    current_offset += read_len;
                  } else {
                    // keep framing coherent: empty payload and rollback copy
                    // size.
                    *((std::int32_t*)&binary_output[current_offset -
                                                    sizeof(std::int32_t)]) = 0;
                  }
                } else {
                  printf("coucou2¥n");
                  std::cerr
                      << "request_download_images: failed to open dicom file"
                      << " dl=" << (*it)->srdlid << " index=" << (*it)->index
                      << " path=" << (*it)->path
                      << " data_offset=" << data_offset
                      << " data_end=" << data_end
                      << " data_length=" << data_length << std::endl;
                  if (data_offset == 0) {
                    *((std::int32_t*)&binary_output[current_offset]) = 0;
                    current_offset += sizeof(std::int32_t);
                    *((std::int32_t*)&binary_output[current_offset]) = 0;
                    current_offset += sizeof(std::int32_t);
                  }
                  *((std::int32_t*)&binary_output[current_offset]) =
                      data_offset > std::numeric_limits<std::int32_t>::max()
                          ? std::numeric_limits<std::int32_t>::max()
                          : static_cast<std::int32_t>(data_offset);
                  current_offset += sizeof(std::int32_t);
                  *((std::int32_t*)&binary_output[current_offset]) = 0;
                  current_offset += sizeof(std::int32_t);
                }
              }
            }
          }
        }

        // cleanup:
        for (auto& it : dlmap)
          delete it.second;
        dlmap.clear();
        for (auto& it : dlitems)
          delete it;
        dlitems.clear();

        /*if (!req->res.good()) {
          binary_output.clear();
          binary_output.resize(sizeof(std::int32_t));
          *((std::int32_t*)&binary_output[0]) = req->res.reason;
        }*/
      });

  if (stream_response) {
    auto stream_payload = std::make_shared<std::vector<std::uint8_t>>();
    req->read_output([&](const json& output,
                         const std::vector<std::uint8_t>& binary_output) {
      stream_payload->assign(binary_output.begin(), binary_output.end());
    });

    req->write_stream_output(
        [stream_payload](const request_data::stream_send_fn& send,
                         const request_data::stream_close_fn& close) {
          static constexpr std::size_t kChunkSize = 64 * 1024;
          std::size_t offset = 0;
          while (offset < stream_payload->size()) {
            const std::size_t len =
                std::min(kChunkSize, stream_payload->size() - offset);
            send(std::string_view(
                reinterpret_cast<const char*>(stream_payload->data() + offset),
                len));
            offset += len;
          }
          close();
        });
  }
}

#endif