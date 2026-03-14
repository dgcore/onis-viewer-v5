#include <png.h>
#include <cstdlib>
#include <cstring>

#include "../../../include/database/items/db_download_image.hpp"
#include "../../../include/database/items/db_download_series.hpp"
#include "../../../include/services/requests/request_data.hpp"
#include "../../../include/services/requests/request_service.hpp"
#include "./download/download_item.hpp"
#include "onis_kit/include/core/exception.hpp"
#include "onis_kit/include/utilities/date_time.hpp"
#include "onis_kit/include/utilities/filesystem.hpp"
#include "onis_kit/include/utilities/string.hpp"
#include "onis_kit/include/utilities/uuid.hpp"

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

}  // namespace

void request_service::process_download_images_request(
    const request_data_ptr& req) {
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
      dlitem->cur_res = image["from"].asInt();
      dlitem->index = image["index"].asInt();

      // get the series download information:
      Json::Value* dlinfo = dlmap[dlseq];
      if (dlinfo == NULL) {
        dlinfo = new Json::Value(Json::objectValue);
        try {
          db->find_download_series_by_seq(
              dlseq, onis::database::lock_mode::NO_LOCK, *dlinfo);
        } catch (const site_server_exception& e) {
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
      total_bytes += dlitem->cloud_increase_image_resolution();
      if (total_bytes > max_bytes)
        break;
    }
  }

  // now we calculate the exact length of the output:
  std::int32_t total_length = 0;
  for (std::list<DlItem*>::iterator it = dlitems.begin(); it != dlitems.end();
       it++) {
    if ((*it)->res.good() && (*it)->new_res == -1)
      continue;

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
      }
      if ((*it)->type == 1 || (*it)->type == 3) {  // raw or png format
        // raw format or png!
        std::int32_t count = 0;
        const void* pixels = (*it)->frame->get_intermediate_pixel_data(&count);
        if ((*it)->cur_res == -1) {
          if ((*it)->type == 3) {  // png format
            // convert to png:
            std::int32_t width, height;
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
                      png_set_write_fn(png_ptr, *it, my_png_write_data,
                                       my_png_flush);
                      png_set_IHDR(png_ptr, info_ptr, width, height, 16,
                                   PNG_COLOR_TYPE_GRAY, PNG_INTERLACE_NONE,
                                   PNG_COMPRESSION_TYPE_DEFAULT,
                                   PNG_FILTER_TYPE_DEFAULT);
                      png_set_rows(png_ptr, info_ptr, row_pointers);
                      png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY,
                                    NULL);
                    }

                  } else {
                    // reconstruct the rgb data:
                    std::uint8_t* rgb = new std::uint8_t[width * height * 3];
                    std::uint8_t* source[3];
                    source[0] = ((std::uint8_t**)pixels)[0];
                    source[1] = ((std::uint8_t**)pixels)[1];
                    source[2] = ((std::uint8_t**)pixels)[2];
                    std::int32_t offset = 0;
                    for (int i = 0; i < height; i++) {
                      std::int32_t k = width * i;
                      for (std::int32_t j = 0; j < width; j++) {
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
              (*it)->data_len = count;
              (*it)->delete_data = false;
            }

          } else {  // raw format

            (*it)->data = (std::uint8_t*)pixels;
            (*it)->data_len = count;
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
          if ((*it)->res.good() && (*it)->new_res == -1)
            continue;

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

              std::int32_t width, height;
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
                  if ((*it)->data_len)
                    memcpy(&binary_output[current_offset], (*it)->data,
                           (*it)->data_len);
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

            } else if ((*it)->type == 2) {  // stream data

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
}