#pragma once

// Compatibility for std::auto_ptr removed in C++17/C++20
#if __cplusplus >= 201703L
#include <memory>
namespace std {
template <typename T>
using auto_ptr = std::unique_ptr<T>;
}
#endif

#include "../../../libs/onis_kit/include/core/bitmap.hpp"
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
// dicom_dcmtk_base
///////////////////////////////////////////////////////////////////////

class dicom_dcmtk_base : public virtual onis::dicom_base {
public:
  // constructor:
  dicom_dcmtk_base(const onis::dicom_manager_ptr& manager)
      : onis::dicom_base() {
    weak_manager_ = manager;
  }

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
// dicom_dcmtk_dataset (dicom dataset without meta header)
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
// dicom_dcmtk_file (dicom file with meta header)
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

///////////////////////////////////////////////////////////////////////
// dcmtk_dicom_frame
///////////////////////////////////////////////////////////////////////

class dcmtk_dicom_frame : public onis::dicom_frame {
  friend class dicom_dcmtk_file;

public:
  // static creator:
  static onis::dicom_frame_ptr create();

  // constructor:
  dcmtk_dicom_frame() = default;

  // destructor:
  ~dcmtk_dicom_frame() override;

  // dicom file:
  // bool set_dicom_file(const onis::dicom_file_ptr& file) override;
  // onis::dicom_file_ptr get_dicom_file() override;

  // frame:
  void set_frame_index(std::int32_t index) override;
  std::int32_t get_frame_index() override;

  // properties:
  bool is_monochrome() const override;
  bool get_dimensions(std::size_t* width, std::size_t* height) const override;
  std::int32_t get_bits_per_pixel() const override;

  // window Level:
  void set_window_level(double center, double width) override;
  bool get_window_level(double* center, double* width) const override;
  void set_original_window_level(double center, double width) override;
  void get_original_window_level(double* center, double* width) const override;

  // voi lut:
  void set_voi_lut_function(std::int32_t mode) override;
  std::int32_t get_voi_lut_function() const override;

  // palette:
  onis::dicom_palette* get_palette(std::int32_t channel) override;
  bool have_palette() const override;
  void reconstruct_palette_image(std::uint8_t* red, std::uint8_t* green,
                                 std::uint8_t* blue) override;

  // internal data:
  const void* get_intermediate_pixel_data(std::size_t* count) const override;
  std::int32_t get_representation(bool* signed_data) const override;

  // min-max values:
  bool get_min_max_values(double* min_val, double* max_val,
                          bool intermediate) const override;
  bool set_min_max_values(double min_val, double max_val,
                          bool intermediate) override;

  // rescale/intercept:
  bool get_rescale_and_intercept(double* rescale, double* intercept) override;
  bool set_rescale_and_intercept(double rescale, double intercept) override;

  // mpeg frame:
  bool is_mpeg_frame() override;

  // overlays:
  // void show_all_overlays(b32 show);
  // void show_overlay(s32 index, b32 show);
  // b32 is_overlay_hidden(s32 index);
  // const onis::dicom_overlay* get_overlay(s32 index);

  // extract bitmap:
  onis::core::bitmap_ptr create_bitmap(
      std::int32_t bits, bool inverse_color = false,
      onis::core::bitmap_ptr use_this_bitmap = nullptr) override;
  std::uint8_t* get_png_data(std::size_t* len) const override;

  // representation of internal data
  // void* merge_intermediate_pixel_data_with_overlays(s32* count) const;

  // utilities:
  // void inter_to_display_window_level(f64* center, f64* width);
  // void display_to_inter_window_level(f64* center, f64* width);

  // regions:
  // void get_regions(onis::frame_region_list& list) const;
  // void set_regions(const onis::frame_region_list& list);

  // void reconstruct_palette_image(u8* red, u8* green, u8* blue);

protected:
  // members:
  DicomImage* _image{nullptr};
  onis::core::bitmap_ptr _mpeg_bmp;
  bool _is_mpeg_frame{false};
  mutable std::recursive_mutex _mutex;

  // png:
  // static void _my_png_write_data(png_structp png_ptr, png_bytep data,
  // png_size_t length);
  // static void _my_png_flush(png_structp png_ptr);

  // overlays:
  onis::dicom_overlay _overlays[16];

  // values of window level are saved here in the display world (not
  // intermediate image)
  double _original_window_center{50.0};
  double _original_window_width{100.0};
  double _window_center{0.0};
  double _window_width{1.0};
  bool _window_level_valid{false};
  // onis::dicom_file_ptr _dicom_file;
  std::int32_t _frame_index{0};
  double _rescale_slope{1.0};
  double _intercept{0.0};
  bool _is_monochrome1{false};
  // onis::db::convolution_filter_wptr _wconv_filter;
  // onis::db::color_lut_wptr _wcolor_lut;
  // onis::db::opacity_table_wptr _wopacity_table;
  std::int32_t _voi_lut_function{0};

  // regions:
  onis::frame_region_list _regions;

  // Min and max values are saved in the intermediate world
  double _min_value{0.0};  // because dcmtk lost the value in a clone image
  double _max_value{0.0};  // because dcmtk lost the value in a clone image

  onis::dicom_palette _palette[3];

  void create_window_level_lut(std::uint8_t* lut, std::int32_t representation,
                               bool is_signed, bool inverse);
  void create_window_level_lut_for_RGB_image(std::uint8_t* lut, bool inverse);

  void calculate_pixel_data(std::int32_t bits, bool inverse_color,
                            std::size_t width, std::size_t height,
                            std::uint8_t* output);

  /*template<class T> void
  ProcessConvolutionFilter3x3ForMonochrome(onis::db::convolution_filter
  *pup_Filter, s32 pi_Width, s32 pi_Height, T *pup_Pixels, s32 *pip_Output);
  template<class T> void
  ProcessConvolutionFilter5x5ForMonochrome(onis::db::convolution_filter
  *pup_Filter, s32 pi_Width, s32 pi_Height, T *pup_Pixels, s32 *pip_Output);
  void ProcessConvolutionFilter3x3ForRGBData(onis::db::convolution_filter
  *pup_Filter, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels[3], u8
  *pup_Output[3]); void
  ProcessConvolutionFilter5x5ForRGBData(onis::db::convolution_filter
  *pup_Filter, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels[3], u8
  *pup_Output[3]); void
  ProcessConvolutionFilter3x3ForRGBData_MPEG(onis::db::convolution_filter
  *pup_Filter, s32 stride, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  *pup_Output); void
  ProcessConvolutionFilter5x5ForRGBData_MPEG(onis::db::convolution_filter
  *pup_Filter, s32 stride, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  *pup_Output);*/

  // void CalculatePixelDataForSignedIntDataWithColorLutAndOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels,
  // u8 *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut,
  // onis::db::opacity_table *pup_Table); void
  // CalculatePixelDataForSignedIntDataWithColorLut(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut); void
  // CalculatePixelDataForSignedIntDataWithOpacityTable(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::opacity_table *pup_Table);
  /*void CalculatePixelDataForSignedIntData(s32 pi_OutputBits, u8* pup_Output,
                                          s32 pi_Width, s32 pi_Height,
                                          u8* pup_Pixels,
                                          u8* pup_WindowLevelLut);*/
  // void CalculatePixelDataForUnsignedIntDataWithColorLutAndOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels,
  // u8 *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut,
  // onis::db::opacity_table *pup_Table); void
  // CalculatePixelDataForUnsignedIntDataWithColorLut(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut); void
  // CalculatePixelDataForUnsignedIntDataWithOpacityTable(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::opacity_table *pup_Table);
  /*void CalculatePixelDataForUnsignedIntData(s32 pi_OutputBits, u8* pup_Output,
                                            s32 pi_Width, s32 pi_Height,
                                            u8* pup_Pixels,
                                            u8* pup_WindowLevelLut);*/

  // void CalculatePixelDataForSignedShortDataWithColorLutAndOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels,
  // u8 *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut,
  // onis::db::opacity_table *pup_Table); void
  // CalculatePixelDataForSignedShortDataWithColorLut(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut); void
  // CalculatePixelDataForSignedShortDataWithOpacityTable(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::opacity_table *pup_Table);
  /*void CalculatePixelDataForSignedShortData(s32 pi_OutputBits, u8* pup_Output,
                                            s32 pi_Width, s32 pi_Height,
                                            u8* pup_Pixels,
                                            u8* pup_WindowLevelLut);*/
  // void CalculatePixelDataForUnsignedShortDataWithColorLutAndOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels,
  // u8 *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut,
  // onis::db::opacity_table *pup_Table); void
  // CalculatePixelDataForUnsignedShortDataWithColorLut(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut); void
  // CalculatePixelDataForUnsignedShortDataWithOpacityTable(s32 pi_OutputBits,
  // u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::opacity_table *pup_Table);
  /*void CalculatePixelDataForUnsignedShortData(s32 pi_OutputBits, u8*
     pup_Output, s32 pi_Width, s32 pi_Height, u8* pup_Pixels, u8*
     pup_WindowLevelLut);*/

  // void CalculatePixelDataForSignedByteDataWithColorLutAndOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels,
  // u8 *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut,
  // onis::db::opacity_table *pup_Table); void
  // CalculatePixelDataForSignedByteDataWithColorLut(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut); void
  // CalculatePixelDataForSignedByteDataWithOpacityTable(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::opacity_table *pup_Table);
  /*void CalculatePixelDataForSignedByteData(s32 pi_OutputBits, u8* pup_Output,
                                           s32 pi_Width, s32 pi_Height,
                                           u8* pup_Pixels,
                                           u8* pup_WindowLevelLut);*/
  // void CalculatePixelDataForUnsignedByteDataWithColorLutAndOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels,
  // u8 *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut,
  // onis::db::opacity_table *pup_Table); void
  // CalculatePixelDataForUnsignedByteDataWithColorLut(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut); void
  // CalculatePixelDataForUnsignedByteDataWithOpacityTable(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::opacity_table *pup_Table);
  /*void CalculatePixelDataForUnsignedByteData(s32 pi_OutputBits, u8*
     pup_Output, s32 pi_Width, s32 pi_Height, u8* pup_Pixels, u8*
     pup_WindowLevelLut);*/

  // void CalculatePixelDataFor24BitsRGBDataWithColorLutAndOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8
  // *pup_Pixels[3], u8 *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut,
  // onis::db::opacity_table *pup_Table); void
  // CalculatePixelDataFor24BitsRGBDataWithColorLut(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels[3], u8
  // *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut); void
  // CalculatePixelDataFor24BitsRGBDataWithOpacityTable(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels[3], u8
  // *pup_WindowLevelLut, onis::db::opacity_table *pup_Table);
  /*void CalculatePixelDataFor24BitsRGBData(s32 pi_OutputBits, u8* pup_Output,
                                          s32 pi_Width, s32 pi_Height,
                                          u8* pup_Pixels[3],
                                          u8* pup_WindowLevelLut);*/

  // void CalculatePixelDataFor32BitsRGBDataWithColorLutAndOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8
  // *pup_Pixels[3], u8 *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut,
  // onis::db::opacity_table *pup_Table); void
  // CalculatePixelDataFor32BitsRGBDataWithColorLut(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels[3], u8
  // *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut); void
  // CalculatePixelDataFor32BitsRGBDataWithOpacityTable(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels[3], u8
  // *pup_WindowLevelLut, onis::db::opacity_table *pup_Table);
  /*void CalculatePixelDataFor32BitsRGBData(s32 pi_OutputBits, u8* pup_Output,
                                          s32 pi_Width, s32 pi_Height,
                                          u8* pup_Pixels[3],
                                          u8* pup_WindowLevelLut);*/

  // void
  // CalculatePixelDataFor24BitsRGBData_MPEG_WithColorLutAndOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels,
  // u8 *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut,
  // onis::db::opacity_table *pup_Table); void
  // CalculatePixelDataFor24BitsRGBData_MPEG_WithColorLut(s32 pi_OutputBits, u8
  // *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels, u8
  // *pup_WindowLevelLut, onis::db::color_lut *pup_ColorLut);
  /*void CalculatePixelDataFor24BitsRGBData_MPEG(s32 pi_OutputBits,
                                               u8* pup_Output, s32 pi_Width,
                                               s32 pi_Height, u8* pup_Pixels,
                                               u8* pup_WindowLevelLut);*/
  // void CalculatePixelDataFor24BitsRGBData_MPEG_WithOpacityTable(s32
  // pi_OutputBits, u8 *pup_Output, s32 pi_Width, s32 pi_Height, u8 *pup_Pixels,
  // u8 *pup_WindowLevelLut, onis::db::opacity_table *pup_Table);

private:
  // utilities:
  void inter_to_display_window_level(double* center, double* width);
  void display_to_inter_window_level(double* center, double* width);

  void* merge_intermediate_pixel_data_with_overlays(std::size_t* count) const;

  void calculate_pixel_data_for_signed_int_data(
      std::int32_t output_bits, std::uint8_t* output, std::size_t width,
      std::size_t height, std::uint8_t* pixels, std::uint8_t* window_level_lut);

  void calculate_pixel_data_for_unsigned_int_data(
      std::int32_t output_bits, std::uint8_t* output, std::size_t width,
      std::size_t height, std::uint8_t* pixels, std::uint8_t* window_level_lut);

  void calculate_pixel_data_for_signed_short_data(
      std::int32_t output_bits, std::uint8_t* output, std::size_t width,
      std::size_t height, std::uint8_t* pixels, std::uint8_t* window_level_lut);

  void calculate_pixel_data_for_unsigned_short_data(
      std::int32_t output_bits, std::uint8_t* output, std::size_t width,
      std::size_t height, std::uint8_t* pixels, std::uint8_t* window_level_lut);

  void calculate_pixel_data_for_signed_byte_data(
      std::int32_t output_bits, std::uint8_t* output, std::size_t width,
      std::size_t height, std::uint8_t* pixels, std::uint8_t* window_level_lut);

  void calculate_pixel_data_for_unsigned_byte_data(
      std::int32_t output_bits, std::uint8_t* output, std::size_t width,
      std::size_t height, std::uint8_t* pixels, std::uint8_t* window_level_lut);

  void calculate_pixel_data_for_24_bits_rgb_data(
      std::int32_t output_bits, std::uint8_t* output, std::size_t width,
      std::size_t height, std::uint8_t* pixels[3],
      std::uint8_t* window_level_lut);

  void calculate_pixel_data_for_32_bits_rgb_data(
      std::int32_t output_bits, std::uint8_t* output, std::size_t width,
      std::size_t height, std::uint8_t* pixels[3],
      std::uint8_t* window_level_lut);

  void calculate_pixel_data_for_24_bits_rgb_data_mpeg(
      std::int32_t output_bits, std::uint8_t* output, std::size_t width,
      std::size_t height, std::uint8_t* pixels, std::uint8_t* window_level_lut);
};

typedef std::shared_ptr<dcmtk_dicom_frame> dcmtk_dicom_frame_ptr;

///////////////////////////////////////////////////////////////////////
// dicom_dcmtk_manager
///////////////////////////////////////////////////////////////////////

class dicom_dcmtk_manager : public onis::dicom_manager {
public:
  // static creator:
  static onis::dicom_manager_ptr create();

  // constructor:
  dicom_dcmtk_manager();

  // destructor:
  ~dicom_dcmtk_manager();

  // dicom objects:
  onis::dicom_file_ptr create_dicom_file() const;
  onis::dicom_dataset_ptr create_dicom_dataset() const;
  // onis::dicom_dir_ptr create_dicom_dir() const;

  // character sets:
  const onis::dicom_charset* find_character_set_by_code(
      const std::string& code) const;
  const onis::dicom_charset* find_character_set_by_escape(
      const std::string& escape, const onis::dicom_charset_info** info,
      bool* g0) const;
  const onis::dicom_charset* find_character_set_by_iso_number(
      const std::string& number, const onis::dicom_charset_info** info) const;
  const onis::dicom_charset* find_character_set_by_info(
      const onis::dicom_charset_info* info) const;
  const onis::dicom_charset_list* get_character_set_list() const;
  const onis::dicom_charset* get_default_character_set() const;

  // utilities:
  void create_instance_uid(std::int32_t level, std::string& uid) const;

protected:
  // members:
  onis::dicom_charset_list charsets;
  void init_character_set();
  std::string build_escape(std::uint8_t v1, std::uint8_t v2,
                           std::uint8_t v3 = 0);
  onis::dicom_charset* add_charset(const std::string& code,
                                   const std::string& name,
                                   const std::string& no_ext_term,
                                   const std::string& ext_term,
                                   bool single_byte, const std::string& g0,
                                   const std::string& g1,
                                   const std::string& code_page);
  void add_charset_info(onis::dicom_charset* set,
                        const std::string& no_ext_term,
                        const std::string& ext_term, bool single_byte,
                        const std::string& g0, const std::string& g1,
                        const std::string& code_page);

  // boost::random::random_device* _rng;
};