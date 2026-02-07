#pragma once

// Compatibility for std::auto_ptr removed in C++17/C++20
#if __cplusplus >= 201703L
#include <memory>
namespace std {
template <typename T>
using auto_ptr = std::unique_ptr<T>;
}
#endif

#include "../../../libs/onis_kit/include/dicom/dicom.hpp"

#include <chrono>

#include "dcmtk/dcmdata/dcitem.h"

#include "dcmtk/dcmdata/dctk.h"
#include "dcmtk/dcmimgle/dcmimage.h"
#include "dcmtk/dcmjpeg/dipijpeg.h"
#include "dcmtk/dcmjpeg/djdecode.h"
#include "dcmtk/dcmjpeg/djencode.h"
#include "dcmtk/dcmjpeg/djrplol.h"
#include "dcmtk/dcmjpeg/djrploss.h"  // for DJ_RPLossy
#include "dcmtk/dcmjpls/djdecode.h"
#include "dcmtk/dcmjpls/djencode.h"

#include "dcmtk/dcmdata/dcddirif.h"
#include "dcmtk/dcmdata/dcistrmb.h"
#include "dcmtk/dcmdata/dcistrmf.h"
#include "dcmtk/dcmdata/dcostrmb.h"
#include "dcmtk/dcmdata/dcostrmf.h"
#include "dcmtk/dcmdata/dcpixseq.h"
#include "dcmtk/dcmdata/dcpxitem.h"
#include "dcmtk/dcmdata/dcrledrg.h" /* for DcmRLEDecoderRegistration */
#include "dcmtk/dcmdata/dcrleerg.h" /* for DcmRLEEncoderRegistration */
#include "dcmtk/dcmdata/dcrlerp.h"
#include "dcmtk/dcmdata/dcxfer.h"
#include "dcmtk/dcmimage/dicopx.h"
#include "dcmtk/dcmimage/diregist.h"
#include "dcmtk/ofstd/ofcmdln.h"
#include "dcmtk/ofstd/ofstd.h"

#include "dcmtk/dcmpstat/dcmpstat.h"

// #include <png.h>

#define CPR_DCM_NOCOMPRESS 1
#define CPR_DCM_JPEG 2
#define CPR_DCM_JPEGLS 3
#define CPR_DCM_RLELS 4
#define CPR_DCM_JPEG2000 5
#define CPR_DCM_JPEG2000LS 6
#define CPR_DCM_MPEG 7

///////////////////////////////////////////////////////////////////////
// odicom_base
///////////////////////////////////////////////////////////////////////

class dicom_dcmtk_base : public virtual onis::dicom_base {
public:
  // constructor:
  dicom_dcmtk_base(const onis::dicom_manager_ptr& manager)
      : onis::dicom_base() {}

  // destructor:
  virtual ~dicom_dcmtk_base() = default;

  // base:
  void lock();
  void unlock();

  // get elements
  void* get_next_element(std::int32_t target, void* elem, std::int32_t* tag,
                         std::string* vr, std::int32_t* vm) const;
  bool get_string_from_element(std::string& output, void* elem) const;
  bool get_string_from_element(std::string& output, void* elem,
                               std::string& specific_character_set) const;
  bool get_string_element(std::string& output, std::int32_t tag,
                          const std::string& type) const;
  bool get_string_element(
      std::string& output, std::int32_t tag, const std::string& type,
      const std::string& specific_character_set,
      onis::dicom_charset_info_list* used_charset_infos = NULL) const;
  bool get_us_element(std::int32_t tag, std::uint16_t* value) const;
  bool get_binary_value(std::int32_t tag, const std::string& type,
                        std::int32_t* length, std::uint8_t** data,
                        const std::string& transfer_syntax) const;
  bool get_date_range_element(std::int32_t tag, onis::core::date_time* start,
                              onis::core::date_time* stop) const;
  bool get_time_range_element(std::int32_t tag, onis::core::time* start,
                              onis::core::time* stop) const;
  onis::dicom_sequence_item_ptr get_sequence_of_items(std::int32_t tag,
                                                      bool create = false);

  // set elements:
  bool set_string_element(std::int32_t tag, const std::string& type,
                          const std::string& value, bool create);
  std::int32_t set_string_element(
      std::int32_t tag, const std::string& type, const std::string& utf8_value,
      std::list<const onis::dicom_charset*>* compatible_charsets, bool create);
  bool set_us_element(std::int32_t tag, std::uint16_t value,
                      bool create = true);
  bool set_binary_value(std::int32_t tag, const std::string& type,
                        std::int32_t length, std::uint8_t* data,
                        bool create = true);
  bool set_date_element(std::int32_t tag, onis::core::date_time* dt,
                        bool create = true);
  bool set_time_element(std::int32_t tag, std::int32_t hour,
                        std::int32_t minute, std::int32_t second,
                        std::int32_t fraction, bool create = true);

  // remove elements:
  bool remove_element(std::int32_t tag);
  bool remove_pixel_data();

  // regions:
  void get_regions(onis::frame_region_list& list) const;

  // transfer
  void transfer_init();
  void transfer_end();
  std::int32_t read(
      std::uint8_t* buffer, std::int32_t max_read,
      const std::string transfer_syntax, std::int32_t* read_out,
      onis::dcm_group_len_encoding group_encoding = onis::no_change_in_gl,
      std::uint32_t max_element_read_len = 4096);
  std::int32_t write(
      std::uint8_t* buffer, std::int32_t length, std::string transfer_syntax,
      std::int32_t* write_out, onis::dcm_encoding_type encoding_type,
      onis::dcm_group_len_encoding group_encoding,
      onis::dcm_padding_encoding padding = onis::no_change_in_padding);

  // vr:
  bool get_vr(std::int32_t tag, std::string& vr);

protected:
  mutable std::recursive_mutex _mutex;

  // if file format:
  DcmFileFormat* _file{nullptr};

  // dataset only:
  DcmDataset* _dataset{nullptr};

  // utilities:
  /*static std::string _create_new_file_string(
      const onis::app_ptr& app, const std::string& def_esc,
      const std::string& str, const onis::dicom_charset* set,
      onis::astring_list* used_charsets);
  static std::string _build_person_name(const onis::app_ptr& app,
                                          std::string name[5],
                                          std::string ideo[5],
                                          std::string phono[5]);
  static std::string _construct_new_char_tag(
      const onis::app_ptr& app, const std::string& current_charset,
      const onis::astring_list& additional_charset);*/
  bool _tag_exists(std::int32_t tag);

private:
  E_TransferSyntax _save_write_trs;
  std::string _save_write_trs_string;
  E_TransferSyntax _save_read_trs;
  std::string _save_read_trs_string;
};

///////////////////////////////////////////////////////////////////////
// odicom_dataset (dicom dataset without meta header)
///////////////////////////////////////////////////////////////////////

class dicom_dcmtk_dataset : public onis::dicom_dataset,
                            public virtual dicom_dcmtk_base {
public:
  // static constructor:
  static onis::dicom_dataset_ptr create(const onis::dicom_manager_ptr& manager);

  // constructor:
  dicom_dcmtk_dataset(const onis::dicom_manager_ptr& manager);

  // destructor:
  ~dicom_dcmtk_dataset();
};

///////////////////////////////////////////////////////////////////////
// odicom_file (dicom file with meta header)
///////////////////////////////////////////////////////////////////////

class dicom_dcmtk_file : public onis::dicom_file,
                         public virtual dicom_dcmtk_base {
public:
  // static constructor:
  static onis::dicom_file_ptr create(const onis::dicom_manager_ptr& manager);

  // constructor:
  dicom_dcmtk_file(const onis::dicom_manager_ptr& manager);

  // destructor:
  ~dicom_dcmtk_file();

  // loading:
  // bool load_file(const std::string &utf8_path);
  bool load_file(const std::string& path, std::int32_t retry_interval,
                 std::int32_t limit);
  bool is_loaded() const;

  // properties:
  bool is_temporary_file() const;
  void set_temporary_file(bool temp);
  std::string get_file_path() const;

  // saving:
  bool save_file(const std::string& path,
                 const std::string& transfer_syntax = "",
                 bool set_file_path = false);

  // closing:
  void close();

  // palette:
  onis::dicom_raw_palette* get_raw_palette(std::int32_t channel) const;

  // frames:
  onis::dicom_frame_ptr extract_frame(std::int32_t index);
  bool modify_transfer_syntax(E_TransferSyntax new_transfer_syntax);

  // pixels:
  bool get_pixel_data_positions(std::uint64_t* start, std::uint64_t* end);
  onis::dicom_frame_offsets* get_pixel_data_positions(std::int32_t& count);

  // frames:
  bool set_image(onis::dicom_image_info* info);

  // mpeg streaming:
  virtual bool start_streaming();
  virtual bool stop_streaming();
  virtual bool add_streaming_data(std::uint8_t* data, std::uint32_t len,
                                  std::uint64_t total_expected = -1);
  virtual bool is_streaming();
  virtual bool streaming_is_complete();
  virtual std::uint64_t get_stream_data_len();
  virtual std::uint64_t get_stream_data_expected_len();
  virtual std::uint32_t get_stream_bit_rate();
  virtual void set_stream_bit_rate(std::uint32_t rate);
  virtual onis::file_ptr get_streaming_file();
  void get_streaming_status();

  // mpeg frame
  bool is_mpeg_frame();
  /*onis::bitmap_ptr get_mpeg_frame(bool copy);
  onis::bitmap_ptr update_mpeg_frame(const onis::bitmap_ptr &bmp, bool
  can_retain);*/

  // utilities:
  static E_TransferSyntax get_transfer_syntax_from_name(
      const std::string& name, std::int32_t* compression);
  bool remove_private_tags_with_pixel_data();

protected:
  bool is_loaded_{false};
  bool is_temporary_file_{false};
  std::string path_{""};

  // mpeg icon:
  bool is_mpeg_frame_{false};
  // onis::bitmap_ptr _mpeg_bmp;
};
