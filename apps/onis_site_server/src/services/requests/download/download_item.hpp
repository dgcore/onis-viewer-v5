#pragma once

#include <json/json.h>
#include <array>
#include <fstream>
#include <unordered_map>
#include <utility>
#include <vector>

#include "../../../../include/services/requests/request_database.hpp"
#include "../../../../include/services/requests/request_service.hpp"
#include "../../../../include/site_api.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/dicom/dicom.hpp"
#include "onis_kit/include/utilities/filesystem.hpp"

enum class DlItemType {
  kDicomFile,
  kJ2kStreamFile,
  kUnknown,
};

struct DlItem {
  std::string download_seq;
  onis::result res;
  std::int32_t index{-1};
  DlItemType type{DlItemType::kUnknown};
  std::string path;
  std::size_t file_size{0};

  void init(const request_database& db, const std::string& download_seq) {
    if (!res.good() || !this->download_seq.empty())
      return;

    this->download_seq = download_seq;

    Json::Value image(Json::objectValue);
    try {
      db->find_download_image_by_index(
          download_seq, index, onis::database::lock_mode::NO_LOCK, image);
    } catch (const onis::exception& e) {
      res.set(OSRSP_FAILURE, e.get_code(), e.what(), false);
    } catch (...) {
      res.set(OSRSP_FAILURE, EOS_UNKNOWN, "Unknown error", false);
    }
    if (!res.good())
      return;

    path = image["path"].asString();

    switch (image["type"].asInt()) {
      case 1:
        type = DlItemType::kDicomFile;
        file_size = static_cast<std::size_t>(
            onis::util::filesystem::get_file_size(path));
        if (file_size <= 0) {
          res.set(OSRSP_FAILURE, EOS_FILE_OPEN, "Failed to open DICOM file",
                  false);
        }
        break;
      case 2:
        type = DlItemType::kJ2kStreamFile;
        break;
      default:
        res.set(OSRSP_FAILURE, EOS_FILE_FORMAT, "Unknown file type", false);
    }
  }
};

struct download_stream {
  enum class phase {
    kMagic,
    kSeriesCount,
    kSeriesSeqLen,
    kSeriesSeq,
    kSeriesCompleted,
    kSeriesExpected,
    kItemCount,
    kItemDownloadSeqLen,
    kItemDownloadSeq,
    kItemIndex,
    kItemType,
    kItemResult,
    kItemFileSize,
    kItemFilePayload,
    kDone,
  };
  std::unordered_map<std::string, Json::Value> dlmap;
  std::vector<std::string> dl_order;
  std::vector<std::unique_ptr<DlItem>> items;
  phase current_phase{phase::kMagic};
  std::size_t series_index{0};
  std::size_t item_index{0};
  std::size_t phase_offset{0};
  std::ifstream current_file;
  std::array<char, 8> magic{{'O', 'N', 'I', 'S', 'D', 'L', '0', '1'}};

  void on_data_written() {
    switch (current_phase) {
      case download_stream::phase::kMagic:
        if (phase_offset == magic.size()) {
          current_phase = phase::kSeriesCount;
          phase_offset = 0;
        }
        break;
      case download_stream::phase::kSeriesCount:
        if (phase_offset == sizeof(std::uint32_t)) {
          phase_offset = 0;
          if (!dlmap.empty()) {
            series_index = 0;
            current_phase = phase::kSeriesSeqLen;
          } else {
            current_phase = phase::kItemCount;
          }
        }
        break;
      case download_stream::phase::kSeriesSeqLen:
        if (phase_offset == sizeof(std::uint32_t)) {
          phase_offset = 0;
          current_phase = phase::kSeriesSeq;
        }
        break;
      case download_stream::phase::kSeriesSeq:
        if (phase_offset == dl_order[series_index].size()) {
          phase_offset = 0;
          current_phase = phase::kSeriesCompleted;
        }
        break;
      case download_stream::phase::kSeriesCompleted:
        if (phase_offset == sizeof(std::uint32_t)) {
          phase_offset = 0;
          current_phase = phase::kSeriesExpected;
        }
        break;
      case download_stream::phase::kSeriesExpected:
        if (phase_offset == sizeof(std::uint32_t)) {
          phase_offset = 0;
          series_index++;
          if (series_index < dl_order.size()) {
            current_phase = phase::kSeriesSeqLen;
          } else {
            current_phase = phase::kItemCount;
            item_index = 0;
          }
        }
        break;
      case download_stream::phase::kItemCount:
        if (phase_offset == sizeof(std::uint32_t)) {
          phase_offset = 0;
          if (!items.empty()) {
            item_index = 0;
            current_phase = phase::kItemDownloadSeqLen;
          } else {
            current_phase = phase::kDone;
          }
        }
        break;
      case download_stream::phase::kItemDownloadSeqLen:
        if (phase_offset == sizeof(std::uint32_t)) {
          phase_offset = 0;
          current_phase = phase::kItemDownloadSeq;
        }
        break;
      case download_stream::phase::kItemDownloadSeq:
        if (phase_offset == items[item_index]->download_seq.size()) {
          phase_offset = 0;
          current_phase = phase::kItemIndex;
        }
        break;
      case download_stream::phase::kItemIndex:
        if (phase_offset == sizeof(std::uint32_t)) {
          // open the file now:
          current_file.close();
          current_file.clear();
          current_file.open(items[item_index]->path, std::ios::binary);
          if (!current_file.is_open()) {
            items[item_index]->res.set(OSRSP_FAILURE, EOS_FILE_OPEN,
                                       "Failed to open file", false);
          } else {
            try {
              current_file.seekg(0, std::ios::end);
              std::streampos file_size = current_file.tellg();
              items[item_index]->file_size =
                  static_cast<std::size_t>(file_size);
              current_file.seekg(0, std::ios::beg);
            } catch (...) {
              items[item_index]->res.set(OSRSP_FAILURE, EOS_FILE_OPEN,
                                         "Failed to open file", false);
            }
          }
          phase_offset = 0;
          current_phase = phase::kItemResult;
        }
        break;
      case download_stream::phase::kItemResult:
        if (phase_offset == sizeof(std::uint32_t)) {
          phase_offset = 0;
          if (items[item_index]->res.good()) {
            current_phase = phase::kItemType;
          } else {
            on_item_done();
          }
        }
        break;
      case download_stream::phase::kItemType:
        if (phase_offset == sizeof(std::uint32_t)) {
          phase_offset = 0;
          current_phase = phase::kItemFileSize;
        }
        break;

      case download_stream::phase::kItemFileSize:
        if (phase_offset == sizeof(std::uint64_t)) {
          phase_offset = 0;
          if (items[item_index]->file_size == 0) {
            on_item_done();
          } else {
            current_phase = phase::kItemFilePayload;
          }
        }
        break;
      case download_stream::phase::kItemFilePayload:
        if (phase_offset == items[item_index]->file_size) {
          phase_offset = 0;
          on_item_done();
        }
        break;
      default:
        break;
    }
  }

private:
  void on_item_done() {
    item_index++;
    if (item_index < items.size()) {
      current_phase = phase::kItemDownloadSeqLen;
    } else {
      current_phase = phase::kDone;
    }
  }
};

typedef std::shared_ptr<download_stream> download_stream_ptr;

#ifdef _BEFORE_FILE_STREAMING_SUPPORT_

struct DlItem {
  // constructor:
  DlItem(const std::string& id) {
    srdlid = id;
    index = -1;
    frame_index = 0;
    cur_res = -1;
    new_res = -1;
    offsets = nullptr;
    offset_count = 0;
    type = -1;
    data_len = 0;
    data = nullptr;
    delete_data = false;
  }

  // destructor:
  ~DlItem() {
    delete[] offsets;
    if (delete_data)
      delete[] data;
  }

  onis::result res;
  std::string srdlid;        // download id that needs to be returned
  std::int32_t index;        // load index of the image
  std::int32_t frame_index;  // frame index of the image.
  std::int32_t cur_res;      // current resolution of the image
  std::int32_t new_res;      // the resolution we should send
  std::int64_t dicom_byte_offset =
      0;  // next byte to read for type==0 (full DICOM file transfer)
  std::int64_t dicom_byte_end =
      -1;  // exclusive end byte for this response packet (type==0), -1 = skip
  std::int32_t offset_count;  // length of the offset array
  std::int32_t* offsets;      // offets to decode each available j2k resolution
  std::string path;           // path of the dicom or streaming file
  std::int32_t type;          // type of the file (dicom or streaming file)

  // raw data:
  onis::dicom_frame_ptr frame;
  std::string tags;  // dicom tags in json format
  onis::dicom_raw_palette* palette[3] = {nullptr, nullptr, nullptr};

  // image data:
  std::uint32_t data_len;
  std::uint8_t* data;
  bool delete_data;

  void cloud_decode_image_j2k_offsets(const request_database& db,
                                      const std::string& dlseq) {
    // don't proceed if an error occured earlier or if we already decoded the
    // offsets before:
    if (type != -1 || !res.good())
      return;

    // get the download image information:
    Json::Value image(Json::objectValue);
    try {
      db->find_download_image_by_index(
          dlseq, index, onis::database::lock_mode::NO_LOCK, image);
    } catch (const onis::exception& e) {
      res.set(OSRSP_FAILURE, e.get_code(), e.what(), false);
      return;
    } catch (...) {
      res.set(OSRSP_FAILURE, EOS_UNKNOWN, "Unknown error", false);
      return;
    }

    // initialize the image file path and the format:
    path = image["path"].asString();
    type = image["type"].asInt();
    if (type == 1) {
      // dicom file
      type = 0;

      // raw format!
      /*site_api_ptr api = site_api::get_instance();
      onis::dicom_manager_ptr manager = api->get_dicom_manager();
      if (manager == NULL) {
        res.set(OSRSP_FAILURE, EOS_INTERNAL, "Missing Dicom manager", false);
        return;
      }
      onis::dicom_file_ptr dcm = manager->create_dicom_file();
      if (!dcm->load_file(path)) {
        res.set(OSRSP_FAILURE, EOS_FILE_FORMAT, "Failed to load the DICOM file",
                false);
        return;
      }
      // read the tags:
      tags = request_service::convert_dicom_file_to_json(dcm);

      // read the raw palette:
      for (std::int32_t i = 0; i < 3; i++)
        palette[i] = dcm->get_raw_palette(i);

      // try to extract the required frame:
      try {
        frame = dcm->extract_frame(0);
      } catch (const onis::exception& e) {
        res.set(OSRSP_FAILURE, e.get_code(), e.what(), false);
        return;
      } catch (...) {
        res.set(OSRSP_FAILURE, EOS_UNKNOWN, "Unknown error", false);
        return;
      }

      if (frame == nullptr) {
        res.set(OSRSP_FAILURE, EOS_FAILED_TO_EXTRACT_IMAGE,
                "Failed to extract the frame", false);
        return;
      }

      std::size_t count;
      if (frame->get_intermediate_pixel_data(&count) == nullptr)
        res.set(OSRSP_FAILURE, EOS_FAILED_TO_EXTRACT_IMAGE, "", false);*/

    } else if (type == 2) {
      // j2k stream format!
      // we need to decode the offsets from the file:
      /*onis::file_ptr fp = onis::file::open_file(
          path, onis::fflags::read | onis::fflags::binary);
      if (fp == NULL)
        res.set(OSRSP_FAILURE, EOS_FILE_OPEN, "", OSFALSE);
      else {
        s32 error = 0;
        f32 version;
        if (fp->read(&version, sizeof(f32)) != sizeof(f32))
          res.set(OSRSP_FAILURE, EOS_FILE_FORMAT, "", OSFALSE);
        else if (version != 1.0 && version != 2.0)
          res.set(OSRSP_FAILURE, EOS_FILE_FORMAT, "", OSFALSE);
        else {
          // dicom file:
          u32 dcm_length = 0;
          if (fp->read(&dcm_length, sizeof(u32)) != sizeof(u32))
            res.set(OSRSP_FAILURE, EOS_FILE_FORMAT, "", OSFALSE);
          else {
            u64 pos = fp->get_position() + dcm_length;
            fp->seek(pos, onis::fflags::begin);
            // json info:
            s64 start_pos = pos;
            u32 json_length;
            if (fp->read(&json_length, sizeof(u32)) != sizeof(u32))
              res.set(OSRSP_FAILURE, EOS_FILE_FORMAT, "", OSFALSE);
            else {
              pos = fp->get_position() + json_length;
              fp->seek(pos, onis::fflags::begin);
              // palette:
              u32 palette_len;
              if (fp->read(&palette_len, sizeof(u32)) != sizeof(u32))
                res.set(OSRSP_FAILURE, EOS_FILE_FORMAT, "", OSFALSE);
              else {
                pos = fp->get_position() + palette_len;
                fp->seek(pos, onis::fflags::begin);

                // progression order, resolution count and layer count:
                u8 progression_order;
                s32 resolution_count;
                s32 layer_count;
                if (fp->read(&progression_order, sizeof(u8)) != sizeof(u8) ||
                    fp->read(&resolution_count, sizeof(s32)) != sizeof(s32) ||
                    fp->read(&layer_count, sizeof(s32)) != sizeof(s32))
                  error = EOS_FILE_FORMAT;
                else {
                  if (resolution_count <= 0 || resolution_count > 6 ||
                      layer_count <= 0 || layer_count > 6)
                    res.set(OSRSP_FAILURE, EOS_FILE_FORMAT, "", OSFALSE);
                  else {
                    // resolutions:
                    pos =
                        fp->get_position() + sizeof(s32) * 2 * resolution_count;
                    fp->seek(pos, onis::fflags::begin);
                    // offsets:
                    s32* j2k_offsets = new s32[resolution_count * layer_count];
                    offsets = new s32[resolution_count * layer_count * 2];
                    offset_count = resolution_count * layer_count;
                    if (fp->read(j2k_offsets, sizeof(s32) * resolution_count *
                                                  layer_count) !=
                        sizeof(s32) * resolution_count * layer_count)
                      res.set(OSRSP_FAILURE, EOS_FILE_FORMAT, "", OSFALSE);
                    else {
                      for (s32 i = 0; i < resolution_count * layer_count; i++) {
                        s32 read_count = j2k_offsets[i];
                        if (i == 0) {
                          offsets[0] = start_pos;
                          offsets[1] =
                              fp->get_position() - start_pos + read_count;

                        } else {
                          read_count -= j2k_offsets[i - 1];
                          offsets[i * 2] =
                              fp->get_position() + j2k_offsets[i - 1];
                          offsets[i * 2 + 1] = read_count;
                        }
                      }
                    }
                    delete[] j2k_offsets;
                  }
                }
              }
            }
          }
        }
      }*/
    }
  }

  std::int32_t cloud_increase_image_resolution() {
    if (!res.good())
      return 0;
    if (type == 1) {
      if (frame != nullptr) {
        new_res = 0;
        std::size_t count = 0;
        frame->get_intermediate_pixel_data(&count);
        return static_cast<std::int32_t>(count);
      }

    } else if (type == 2) {
      std::int32_t max_res = offset_count - 1;
      if (new_res == -1) {
        if (cur_res <= max_res) {
          new_res = cur_res + 1;
          return offsets[new_res * 2 + 1];
        }

      } else if (new_res < max_res) {
        new_res++;
        return offsets[new_res * 2 + 1];
      }
    }
    return 0;
  }
};

#endif