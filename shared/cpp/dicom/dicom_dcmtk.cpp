#include "./dicom_dcmtk.hpp"
#include <ctime>
#include <iomanip>
#include <random>
#include <sstream>
#include "../../../libs/onis_kit/include/core/result.hpp"
#include "../../../libs/onis_kit/include/utilities/dicom.hpp"
#include "../../../libs/onis_kit/include/utilities/filesystem.hpp"
#include "../../../libs/onis_kit/include/utilities/string.hpp"

void dcmtk_init() {
  OFBool opt_huffmanOptimize = OFTrue;
  OFCmdUnsignedInt opt_smoothing = 0;
  int opt_compressedBits = 0;  // 0=auto, 8/12/16=force
  E_CompressionColorSpaceConversion opt_compCSconversion = ECC_lossyYCbCr;
  E_DecompressionColorSpaceConversion opt_decompCSconversion =
      EDC_photometricInterpretation;
  E_SubSampling opt_sampleFactors = ESS_444;
  OFBool opt_useYBR422 = OFFalse;
  OFCmdUnsignedInt opt_fragmentSize = 0;  // 0=unlimited
  OFBool opt_createOffsetTable = OFTrue;
  int opt_windowType =
      0; /* default: no windowing; 1=Wi, 2=Wl, 3=Wm, 4=Wh, 5=Ww, 6=Wn, 7=Wr */
  OFCmdUnsignedInt opt_windowParameter = 0;
  OFCmdFloat opt_windowCenter = 0.0, opt_windowWidth = 0.0;
  E_UIDCreation opt_uidcreation = EUC_default;
  OFBool opt_secondarycapture = OFFalse;
  OFCmdUnsignedInt opt_roiLeft = 0, opt_roiTop = 0, opt_roiWidth = 0,
                   opt_roiHeight = 0;
  OFBool opt_usePixelValues = OFTrue;
  OFBool opt_useModalityRescale = OFFalse;
  OFBool opt_trueLossless = OFTrue;

  OFBool opt_acceptWrongPaletteTags = OFFalse;
  OFBool opt_acrNemaCompatibility = OFFalse;

  // register global decompression codecs
  DJDecoderRegistration::registerCodecs(opt_decompCSconversion,
                                        opt_uidcreation);

  // register global compression codecs
  DJEncoderRegistration::registerCodecs(
      opt_compCSconversion, opt_uidcreation, opt_huffmanOptimize,
      OFstatic_cast(int, opt_smoothing), opt_compressedBits,
      OFstatic_cast(Uint32, opt_fragmentSize), opt_createOffsetTable,
      opt_sampleFactors, opt_useYBR422, opt_secondarycapture, opt_windowType,
      opt_windowParameter, opt_windowCenter, opt_windowWidth, opt_roiLeft,
      opt_roiTop, opt_roiWidth, opt_roiHeight, opt_usePixelValues,
      opt_useModalityRescale, opt_acceptWrongPaletteTags,
      opt_acrNemaCompatibility, opt_trueLossless);

  DJLSEncoderRegistration::registerCodecs();
  DJLSDecoderRegistration::registerCodecs();
  DcmRLEDecoderRegistration::registerCodecs();
  DcmRLEEncoderRegistration::registerCodecs();
}

void dcmtk_deinit() {
  DJEncoderRegistration::cleanup();
  DJDecoderRegistration::cleanup();
  DJLSEncoderRegistration::cleanup();
  DJLSDecoderRegistration::cleanup();
  DcmRLEDecoderRegistration::cleanup();
  DcmRLEEncoderRegistration::cleanup();
}

///////////////////////////////////////////////////////////////////////
// dicom_file_tmp_buffer
///////////////////////////////////////////////////////////////////////

struct dicom_file_tmp_buffer {
  ~dicom_file_tmp_buffer() {
    delete[] data;
  }
  std::uint8_t* data{nullptr};
  std::uint32_t len{0};
};

///////////////////////////////////////////////////////////////////////
// dicom_dcmtk_base
///////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------
// lock
//-----------------------------------------------------------------------

void dicom_dcmtk_base::lock() {
  _mutex.lock();
}

void dicom_dcmtk_base::unlock() {
  _mutex.unlock();
}

//-----------------------------------------------------------------------
// vr
//-----------------------------------------------------------------------
bool dicom_dcmtk_base::get_vr(std::int32_t tag, std::string& vr) {
  bool ret = false;
  const DcmDataDictionary& globalDataDict = dcmDataDict.rdlock();

  unsigned short* ushp_tag = (unsigned short*)&tag;
  DcmTagKey u_tag(ushp_tag[1], ushp_tag[0]);

  const DcmDictEntry* dictRef = globalDataDict.findEntry(u_tag, 0);
  if (dictRef) {
    DcmVR u_VR = dictRef->getVR();
    vr = u_VR.getVRName();
    ret = true;
  }

  dcmDataDict.unlock();

  return ret;
}

//-----------------------------------------------------------------------
// get elements
//-----------------------------------------------------------------------
void* dicom_dcmtk_base::get_next_element(std::int32_t target, void* elem,
                                         std::int32_t* tag, std::string* vr,
                                         std::int32_t* vm) const {
  DcmObject* obj = nullptr;
  if (_file != nullptr) {
    if (target == 0) {
      if (_file->getMetaInfo() != nullptr)
        obj = _file->getMetaInfo()->nextInContainer((DcmObject*)elem);

    } else {
      if (_file->getDataset() != nullptr)
        obj = _file->getDataset()->nextInContainer((DcmObject*)elem);
    }

    if (obj != nullptr) {
      if (tag != nullptr) {
        unsigned short* res = (std::uint16_t*)tag;
        res[0] = obj->getETag();
        res[1] = (std::uint16_t)obj->getGTag();
      }

      if (vm != nullptr)
        *vm = (std::int32_t)obj->getVM();

      if (vr != nullptr) {
        switch (obj->getVR()) {
          case EVR_AE:
            *vr = "AE";
            break;
          case EVR_AS:
            *vr = "AS";
            break;
          case EVR_AT:
            *vr = "AT";
            break;
          case EVR_CS:
            *vr = "CS";
            break;
          case EVR_DA:
            *vr = "DA";
            break;
          case EVR_DS:
            *vr = "DS";
            break;
          case EVR_DT:
            *vr = "DT";
            break;
          case EVR_FL:
            *vr = "FL";
            break;
          case EVR_FD:
            *vr = "FD";
            break;
          case EVR_IS:
            *vr = "IS";
            break;
          case EVR_LO:
            *vr = "LO";
            break;
          case EVR_LT:
            *vr = "LT";
            break;
          case EVR_OB:
            *vr = "OB";
            break;
          case EVR_OF:
            *vr = "OF";
            break;
          case EVR_OW:
            *vr = "OW";
            break;
          case EVR_PN:
            *vr = "PN";
            break;
          case EVR_SH:
            *vr = "SH";
            break;
          case EVR_SL:
            *vr = "SL";
            break;
          case EVR_SQ:
            *vr = "SQ";
            break;
          case EVR_SS:
            *vr = "SS";
            break;
          case EVR_ST:
            *vr = "ST";
            break;
          case EVR_TM:
            *vr = "TM";
            break;
          case EVR_UI:
            *vr = "UI";
            break;
          case EVR_UL:
            *vr = "UL";
            break;
          case EVR_US:
            *vr = "US";
            break;
          case EVR_UT:
            *vr = "UT";
            break;
          case EVR_UNKNOWN:
            *vr = "UN";
            break;
          default:
            break;
        };
      }
    }
  }
  return obj;
}

bool dicom_dcmtk_base::get_string_from_element(std::string& output,
                                               void* elem) const {
  bool ret = false;
  if (elem != nullptr) {
    DcmElement* obj = (DcmElement*)elem;
    if (obj->getLength() <= 500) {
      OFString res;
      DcmEVR type = obj->getVR();
      bool read_array = false;

      if (type == EVR_AE || type == EVR_AS || type == EVR_AT ||
          type == EVR_CS || type == EVR_DA || type == EVR_DS ||
          type == EVR_DT || type == EVR_FL || type == EVR_FD ||
          type == EVR_IS || type == EVR_LO || type == EVR_LT ||
          type == EVR_OB || type == EVR_OF || type == EVR_OW ||
          type == EVR_PN || type == EVR_SH || type == EVR_SL ||
          type == EVR_SS || type == EVR_ST || type == EVR_TM ||
          type == EVR_UI || type == EVR_UL || type == EVR_US || type == EVR_UT)
        read_array = true;

      OFCondition cond =
          (read_array) ? obj->getOFStringArray(res) : obj->getOFString(res, 0);
      if (cond.good()) {
        output = res.data();
        ret = true;
      }
    }
  }
  return ret;
}

bool dicom_dcmtk_base::get_string_from_element(
    std::string& output, void* elem,
    std::string& specific_character_set) const {
  std::string res;
  if (!get_string_from_element(res, elem))
    return false;

  onis::dicom_manager_ptr manager = get_manager();
  if (manager == nullptr)
    return false;

  output = onis::util::dicom::convert_to_utf8(manager, res,
                                              specific_character_set, nullptr);
  return true;
}

bool dicom_dcmtk_base::get_string_element(std::string& output, std::int32_t tag,
                                          const std::string& type) const {
  bool ret = false;

  // prevent concurrency:
  _mutex.lock();

  // prepare the key to read:
  std::uint16_t* tmp = (std::uint16_t*)&tag;
  DcmTagKey dcmtk_tag(tmp[1], tmp[0]);
  OFString res;

  // should read array?
  bool read_array = false;
  if (type == "AE" || type == "AS" || type == "AT" || type == "CS" ||
      type == "DA" || type == "DS" || type == "DT" || type == "FL" ||
      type == "FD" || type == "IS" || type == "LO" || type == "LT" ||
      type == "OB" || type == "OF" || type == "OW" || type == "PN" ||
      type == "SH" || type == "SL" || type == "SS" || type == "ST" ||
      type == "TM" || type == "UI" || type == "UL" || type == "US" ||
      type == "UT")
    read_array = true;

  OFCondition u_cond;
  bool ok = false;
  if (_file != nullptr && tmp[1] == 0x0002) {
    // read from the meta info !
    if (_file->getMetaInfo()) {
      if (read_array)
        u_cond = _file->getMetaInfo()->findAndGetOFStringArray(dcmtk_tag, res);
      else
        u_cond = _file->getMetaInfo()->findAndGetOFString(dcmtk_tag, res);
      ok = true;
    }

  } else {
    DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
    if (dataset != nullptr) {
      if (read_array)
        u_cond = dataset->findAndGetOFStringArray(dcmtk_tag, res);
      else
        u_cond = dataset->findAndGetOFString(dcmtk_tag, res);
      ok = true;
    }
  }

  if (ok && u_cond.good()) {
    ret = true;
    output = res.data();
  }

  // unlock:
  _mutex.unlock();

  // return the result:
  return ret;
}

bool dicom_dcmtk_base::get_string_element(
    std::string& output, std::int32_t tag, const std::string& type,
    const std::string& specific_character_set,
    onis::dicom_charset_info_list* used_charset_infos) const {
  std::string res;
  if (!get_string_element(res, tag, type))
    return false;
  onis::dicom_manager_ptr manager = get_manager();
  if (manager == nullptr)
    return false;
  output = onis::util::dicom::convert_to_utf8(
      manager, res, specific_character_set, used_charset_infos);
  return true;
}

bool dicom_dcmtk_base::get_us_element(std::int32_t tag,
                                      std::uint16_t* value) const {
  bool ret = false;

  // prevent concurrency:
  _mutex.lock();

  // prepare the key to read:
  std::uint16_t* tmp = (std::uint16_t*)&tag;
  DcmTagKey dcmtk_tag(tmp[1], tmp[0]);
  Uint16 dicom_value = 0;

  OFCondition cond;
  bool ok = false;
  if (_file != nullptr && tmp[1] == 0x0002) {
    // read from the meta info !
    if (_file->getMetaInfo()) {
      cond = _file->getMetaInfo()->findAndGetUint16(dcmtk_tag, dicom_value);
      ok = true;
    }

  } else {
    DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
    if (dataset != nullptr) {
      cond = dataset->findAndGetUint16(dcmtk_tag, dicom_value);
      ok = true;
    }
  }

  if (ok && cond.good()) {
    ret = true;
    *value = dicom_value;
  }

  // unlock:
  _mutex.unlock();

  // return the result:
  return ret;
}

bool dicom_dcmtk_base::get_binary_value(
    std::int32_t tag, const std::string& type, std::int32_t* length,
    std::uint8_t** data, const std::string& transfer_syntax) const {
  bool ret = false;

  // prevent concurrency:
  _mutex.lock();

  // prepare the key to read:
  std::uint16_t* tmp = (std::uint16_t*)&tag;
  DcmTagKey dcmtk_tag(tmp[1], tmp[0]);

  // get the original transfer syntax:
  E_TransferSyntax original_transfer = EXS_Unknown;
  if (_file != nullptr)
    original_transfer = _file->getMetaInfo()->getOriginalXfer();
  else if (_dataset != nullptr)
    original_transfer = _dataset->getOriginalXfer();

  // check if we will need a conversion of transfer syntax:
  E_TransferSyntax target_transfer;
  bool need_conversion = false;
  if (transfer_syntax.empty())
    target_transfer = original_transfer;
  else {
    std::int32_t compression;
    target_transfer = dicom_dcmtk_file::get_transfer_syntax_from_name(
        transfer_syntax, &compression);
    // if (target_transfer != original_transfer) need_conversion = true;
  }
  need_conversion = true;

  // search for the element to read data from:
  DcmElement* elt = nullptr;
  OFCondition cond;
  if (_file != nullptr && tmp[1] == 0x0002) {
    // read from the meta info !
    if (_file->getMetaInfo()) {
      cond = _file->getMetaInfo()->findAndGetElement(dcmtk_tag, elt, 0, true);
    }

  } else {
    DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
    if (dataset != nullptr) {
      cond = dataset->findAndGetElement(dcmtk_tag, elt, 0, true);
    }
  }

  ret = elt ? true : false;

  if (ret == true) {
    // convert the element to the new transfer syntax if necessary:
    if (need_conversion) {
      // copy the element in a stream:
      Uint32 total = 0;
      std::list<dicom_file_tmp_buffer*> list_copy;
      bool written = false;
      std::uint8_t buffer[2048];

      DcmOutputBufferStream streamout(buffer, 2048);
      elt->transferInit();
      bool finish = false;
      while (!finish) {
        if (!written) {
          OFCondition status = elt->write(streamout, target_transfer,
                                          EET_UndefinedLength, nullptr);
          if (status == EC_Normal)
            written = true;
          else if (status == EC_StreamNotifyClient) {
          } else {
            ret = false;
            finish = true;
          }
        }

        if (ret) {
          if (written)
            streamout.flush();  // flush stream including embedded compression
                                // codec. get buffer and its length, assign to
                                // local variable
          offile_off_t length;
          void* full_buf = nullptr;
          streamout.flushBuffer(full_buf, length);
          finish = written && streamout.isFlushed();
          if (length > 0) {
            // ui_Length could be odd
            if (length & 1) {
              // this should only happen if we use a stream compressed transfer
              // syntax and then only at the very end of the stream. Everything
              // else is a failure.
              if (!finish) {
                ret = false;
                finish = true;
                break;
              }
              // since the block size is always even, block size must be larger
              // than rtnLength, so we can safely add a pad byte (and hope that
              // the pad byte will not confuse the receiver's decompressor).
              std::uint8_t* cbuf = (std::uint8_t*)full_buf;
              cbuf[length++] = 0;  // add zero pad byte
            }
            // save the data:
            std::uint8_t* save_data = new std::uint8_t[length];
            memcpy(save_data, (std::uint8_t*)full_buf, length);
            dicom_file_tmp_buffer* packet = new dicom_file_tmp_buffer;
            packet->data = save_data;
            packet->len = (std::uint32_t)length;
            total += (std::uint32_t)length;
            list_copy.push_back(packet);
          }
        }
      }
      elt->transferEnd();

      // ok, we create a new element and copy the data in it:
      // first we read the header size:
      Uint32 header_size = 0;
      DcmXfer xferSyn(target_transfer);
      header_size = xferSyn.sizeofTagHeader(elt->getVR());
      if (total < header_size)
        ret = false;
      if (ret) {
        // DcmElement *new_elt = nullptr;
        // OFBool readAsUN = false;
        // OFCondition res2 = DcmItem::newDicomElement(new_elt, dcmtk_tag,
        // total-header_size, nullptr, readAsUN);

        // DcmElement *new_elt = newDicomElement(dcmtk_tag, total-header_size);
#//if defined(WIN32) || defined(_ONIS_FOR_LINUX_)
        DcmElement* new_elt = newDicomElement(dcmtk_tag, total - header_size);
        // #else
        //       DcmElement* new_elt =
        //         DcmDataset::newDicomElement(dcmtk_tag, total - header_size);
        // #endif
        if (new_elt) {
          DcmInputBufferStream streamin;
          if (streamin.good()) {
            new_elt->transferInit();
            if (total - header_size > 0) {
              bool first = true;
              OFCondition status = EC_Normal;
              std::list<dicom_file_tmp_buffer*>::iterator it1;
              for (it1 = list_copy.begin(); it1 != list_copy.end(); it1++) {
                // make the stream remember any unread bytes
                streamin.releaseBuffer();
                if (first) {
                  streamin.setBuffer(&(*it1)->data[header_size],
                                     (*it1)->len - header_size);
                  first = false;

                } else
                  streamin.setBuffer((*it1)->data, (*it1)->len);
                if (*it1 == list_copy.back())
                  streamin.setEos();
                status = new_elt->read(streamin, target_transfer);
                if (status != EC_Normal && status != EC_StreamNotifyClient) {
                  ret = false;
                  break;
                }
              }
            }
            new_elt->transferEnd();
          }

          if (ret) {
            delete elt;
            elt = new_elt;

          } else
            delete new_elt;

        } else
          ret = false;
      }

      // clean up:
      std::list<dicom_file_tmp_buffer*>::iterator it1;
      for (it1 = list_copy.begin(); it1 != list_copy.end(); it1++)
        delete *it1;
      list_copy.clear();
    }

    // we can read the binary data from the element:
    if (ret == true) {
      if (type == "AE" || type == "AS" || type == "CS" || type == "DA" ||
          type == "DS" || type == "DT" || type == "IS" || type == "LO" ||
          type == "LT" || type == "PN" || type == "SH" || type == "ST" ||
          type == "TM" || type == "UI" || type == "UT") {
        OFString val;
        OFCondition status = elt->getOFStringArray(val, false);
        // if (u_tag.getGroup() == 0x0002) u_status =
        // mup_file->getMetaInfo()->findAndGetOFStringArray(u_tag, s_val); else
        // u_status = mup_file->getDataset()->findAndGetOFStringArray(u_tag,
        // s_val);
        if (status == EC_Normal) {
          *length = (std::int32_t)val.length();
          *data = nullptr;
          if (*length > 0) {
            *data = new std::uint8_t[*length];
            memcpy(*data, val.data(), *length);
          }

        } else
          ret = false;

      } else if (type == "FL") {
        Float32* val = nullptr;
        unsigned long count = elt->getVM();
        OFCondition status = elt->getFloat32Array(val);
        // if (u_tag.getGroup() == 0x0002) u_status =
        // mup_file->getMetaInfo()->findAndGetFloat32Array(u_tag, fp_val,
        // &ul_count); else u_status =
        // mup_file->getDataset()->findAndGetFloat32Array(u_tag, fp_val,
        // &ul_count);
        if (status == EC_Normal && val) {
          *length = (std::int32_t)count * 4;
          *data = nullptr;
          if (*length > 0) {
            *data = new std::uint8_t[*length];
            memcpy(*data, val, *length);
          }

        } else
          ret = false;

      } else if (type == "FD") {
        Float64* val = nullptr;
        unsigned long count = elt->getVM();
        OFCondition status = elt->getFloat64Array(val);
        // if (u_tag.getGroup() == 0x0002) u_status =
        // mup_file->getMetaInfo()->findAndGetFloat64Array(u_tag, dp_val,
        // &ul_count); else u_status =
        // mup_file->getDataset()->findAndGetFloat64Array(u_tag, dp_val,
        // &ul_count);
        if (status == EC_Normal && val) {
          *length = (std::int32_t)count * 8;
          *data = nullptr;
          if (*length > 0) {
            *data = new std::uint8_t[*length];
            memcpy(*data, val, *length);
          }

        } else
          ret = false;

      } else if (type == "US") {
        Uint16* val = nullptr;
        unsigned long count = elt->getVM();
        OFCondition status = elt->getUint16Array(val);
        // if (u_tag.getGroup() == 0x0002) u_status =
        // mup_file->getMetaInfo()->findAndGetUint16Array(u_tag, ushp_val,
        // &ul_count); else u_status =
        // mup_file->getDataset()->findAndGetUint16Array(u_tag, ushp_val,
        // &ul_count);
        if (status == EC_Normal && val) {
          *length = (std::int32_t)count * 2;
          *data = nullptr;
          if (*length > 0) {
            *data = new std::uint8_t[*length];
            memcpy(*data, val, *length);
          }

        } else
          ret = false;

      } else if (type == "UL") {
        Uint32* val = nullptr;
        unsigned long count = elt->getVM();
        OFCondition status = elt->getUint32Array(val);
        // if (u_tag.getGroup() == 0x0002) u_status =
        // mup_file->getMetaInfo()->findAndGetUint32Array(u_tag, uip_val,
        // &ul_count); else u_status =
        // mup_file->getDataset()->findAndGetUint32Array(u_tag, uip_val,
        // &ul_count);
        if (status == EC_Normal && val) {
          *length = (std::int32_t)count * 4;
          *data = nullptr;
          if (*length > 0) {
            *data = new std::uint8_t[*length];
            memcpy(*data, val, *length);
          }

        } else
          ret = false;

      } else if (type == "SS") {
        Sint16* val = nullptr;
        unsigned long count = elt->getVM();
        OFCondition status = elt->getSint16Array(val);
        // if (u_tag.getGroup() == 0x0002) u_status =
        // mup_file->getMetaInfo()->findAndGetSint16Array(u_tag, shp_val,
        // &ul_count); else u_status =
        // mup_file->getDataset()->findAndGetSint16Array(u_tag, shp_val,
        // &ul_count);
        if (status == EC_Normal && val) {
          *length = (std::int32_t)count * 2;
          *data = nullptr;
          if (*length > 0) {
            *data = new std::uint8_t[*length];
            memcpy(*data, val, *length);
          }

        } else
          ret = false;
      } else if (type == "SL") {
        Sint32* val = nullptr;
        unsigned long count = elt->getVM();
        OFCondition status = elt->getSint32Array(val);
        // if (u_tag.getGroup() == 0x0002) u_status =
        // mup_file->getMetaInfo()->findAndGetSint32Array(u_tag, ip_val,
        // &ul_count); else u_status =
        // mup_file->getDataset()->findAndGetSint32Array(u_tag, ip_val,
        // &ul_count);
        if (status == EC_Normal && val) {
          *length = (std::int32_t)count * 4;
          *data = nullptr;
          if (*length > 0) {
            *data = new std::uint8_t[*length];
            memcpy(*data, val, *length);
          }

        } else
          ret = false;

      } else if (type == "OW") {
        Uint16* val = nullptr;
        unsigned long len = 2 * (elt->getLength() / 2);
        OFCondition status = elt->getUint16Array(val);
        if (status == EC_Normal && val) {
          *length = (std::int32_t)len;
          *data = nullptr;
          if (*length > 0) {
            *data = new std::uint8_t[*length];
            memcpy(*data, val, *length);
          }
        } else
          ret = false;
      }
    }
  }

  // clean up:
  delete elt;

  // unlock:
  _mutex.unlock();

  // return the result:
  return ret;
}

bool dicom_dcmtk_base::get_date_range_element(
    std::int32_t tag, onis::core::date_time* start,
    onis::core::date_time* stop) const {
  std::string value;
  bool found = get_string_element(value, tag, "DA", "");
  if (!found)
    return false;
  return onis::util::string::get_date_range_from_string(value, start, stop);
}

bool dicom_dcmtk_base::get_time_range_element(std::int32_t tag,
                                              onis::core::time* start,
                                              onis::core::time* stop) const {
  std::string value;
  bool found = get_string_element(value, tag, "TM", "");
  if (!found)
    return false;
  return onis::util::string::get_time_range_from_string(value, start, stop);
}

onis::dicom_sequence_item_ptr dicom_dcmtk_base::get_sequence_of_items(
    std::int32_t tag, bool create) {
  onis::dicom_sequence_item_ptr ret;
  /*_mutex.lock();
  if (_dataset != nullptr) {

  std::uint16_t *tmp = (std::uint16_t *)&tag;
  DcmTagKey dcmtk_tag(tmp[1], tmp[0]);

  if (create == true) {

  DcmItem *item = nullptr;
  _dataset->findOrCreateSequenceItem(dcmtk_tag, item, 0);
  if (item != nullptr) {

  ret = odicom_sequence_item::create(_app, shared_from_this(),
  onis::dicom_file_ptr(), onis::dicom_sequence_item_ptr());
  ((odicom_sequence_item *)ret.get())->_item = item;

  }

  }
  else {

  DcmItem *item = nullptr;
  _dataset->findAndGetSequenceItem(dcmtk_tag, item, 0, OFFalse);
  if (item != nullptr) {

  ret = odicom_sequence_item::create(_app, shared_from_this(),
  onis::dicom_file_ptr(), onis::dicom_sequence_item_ptr());
  ((odicom_sequence_item *)ret.get())->_item = item;

  }

  }

  }
  _mutex.unlock();*/

  return ret;
}

//-----------------------------------------------------------------------
// set elements
//-----------------------------------------------------------------------
bool dicom_dcmtk_base::set_string_element(std::int32_t tag,
                                          const std::string& type,
                                          const std::string& value,
                                          bool create) {
  bool ret = false;

  // prevent concurrency:
  _mutex.lock();

  // prepare the key to write:
  std::uint16_t* tmp = (std::uint16_t*)&tag;
  DcmTagKey dcmtk_tag(tmp[1], tmp[0]);

  // should write array?
  bool write_array = false;
  if (type == "AE" || type == "AS" || type == "AT" || type == "CS" ||
      type == "DA" || type == "DS" || type == "DT" || type == "FL" ||
      type == "FD" || type == "IS" || type == "LO" || type == "LT" ||
      type == "OB" || type == "OF" || type == "OW" || type == "PN" ||
      type == "SH" || type == "SL" || type == "SS" || type == "ST" ||
      type == "TM" || type == "UI" || type == "UL" || type == "US" ||
      type == "UT")
    write_array = true;

  // write:
  OFCondition cond;
  bool ok = false;
  if (_file != nullptr && tmp[1] == 0x0002) {
    // write to the meta info !
    if (_file->getMetaInfo()) {
      if (create || !_file->getMetaInfo()->tagExists(dcmtk_tag, OFTrue)) {
        if (write_array)
          cond = _file->getMetaInfo()->putAndInsertOFStringArray(dcmtk_tag,
                                                                 value.data());
        else
          cond =
              _file->getMetaInfo()->putAndInsertString(dcmtk_tag, value.data());
        ok = true;
      }
    }

  } else {
    DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
    if (dataset != nullptr) {
      if (create || !dataset->tagExists(dcmtk_tag, OFTrue)) {
        if (write_array)
          cond = dataset->putAndInsertOFStringArray(dcmtk_tag, value.data());
        else
          cond = dataset->putAndInsertString(dcmtk_tag, value.data());
        ok = true;
      }
    }
  }
  if (ok && cond.good())
    ret = true;

  // unlock:
  _mutex.unlock();

  // return the result:
  return ret;
}

bool dicom_dcmtk_base::_tag_exists(std::int32_t tag) {
  std::uint16_t* tmp = (std::uint16_t*)&tag;
  DcmTagKey dcmtk_tag(tmp[1], tmp[0]);
  if (_file != nullptr && tmp[1] == 0x0002) {
    // write to the meta info !
    if (_file->getMetaInfo()) {
      if (!_file->getMetaInfo()->tagExists(dcmtk_tag, OFTrue)) {
        return true;
      }
    }

  } else {
    DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
    if (dataset != nullptr) {
      if (!dataset->tagExists(dcmtk_tag, OFTrue)) {
        return true;
      }
    }
  }
  return false;
}

std::int32_t dicom_dcmtk_base::set_string_element(
    std::int32_t tag, const std::string& type, const std::string& utf8_value,
    std::list<const onis::dicom_charset*>* compatible_charsets, bool create) {
  std::int32_t ret = EOS_NONE;
  std::lock_guard<std::recursive_mutex> guard(_mutex);

  onis::dicom_manager_ptr manager = get_manager();
  if (manager == nullptr)
    return EOS_INTERNAL;

  if (create == true || _tag_exists(tag)) {
    if (type == "AE" || type == "AS" || type == "CS" || type == "DS" ||
        type == "IS" || type == "UI" || type == "TM" || type == "DA") {
      // the value must be compatible with the ISO-IR6 repertoire:
      if (onis::util::dicom::is_compatible_with_ir6(utf8_value)) {
        if (!set_string_element(tag, type, utf8_value, true))
          return EOS_TAG_INSERT;
      } else
        return EOS_TAG_VALUE_INVALID_WITH_DEFAULT_REPERTOIRE;
    } else {
      // get the file character sets:
      std::string specific_character_set;
      get_string_element(specific_character_set, TAG_SPECIFIC_CHARACTER_SET,
                         "CS");

      // make sure we have a single byte character set first:
      if (onis::util::dicom::ensure_single_byte_first_charset(
              manager, specific_character_set))
        set_string_element(TAG_SPECIFIC_CHARACTER_SET, "CS",
                           specific_character_set, true);

      // get the list of character sets currently used by the dicom object:
      std::list<const onis::dicom_charset*> file_charsets;
      std::vector<std::string> tmp;
      onis::util::string::split(specific_character_set, tmp, "\\");
      if (tmp.empty())
        file_charsets.push_back(manager->get_default_character_set());
      else
        for (auto& code : tmp) {
          const onis::dicom_charset* set = nullptr;
          if (code.empty())
            set = manager->get_default_character_set();
          else
            set = manager->find_character_set_by_iso_number(code, nullptr);
          if (set && std::find(file_charsets.begin(), file_charsets.end(),
                               set) == file_charsets.end())
            file_charsets.push_back(set);
        }

      // get the default character set used by the dicom object:
      const onis::dicom_charset* default_file_set = nullptr;
      const onis::dicom_charset_info* default_file_charset_info = nullptr;
      if (tmp.empty())
        default_file_set = manager->find_character_set_by_iso_number(
            "ISO 2022 IR 6", &default_file_charset_info);
      else
        default_file_set = manager->find_character_set_by_iso_number(
            tmp.front(), &default_file_charset_info);

      // if the default file charset info is not supported, we cannot process:
      if (default_file_charset_info == nullptr)
        return EOS_TAG_UNSUPPORTED_REPERTOIRE;
      else {
        // remember the character set we will use:
        std::vector<std::string> used_charsets;

        if (type == "PN") {
          // decode the new name:
          std::string N2[5], I2[5], P2[5];
          onis::util::dicom::decode_person_name(utf8_value, N2, I2, P2);

          // local list of compatible charsets (only used if not provided)
          std::list<const onis::dicom_charset*> local_compatible_charsets;

          // list of compatible charsets we can use:
          std::list<const onis::dicom_charset*>* compatible_charset_list =
              compatible_charsets ? compatible_charsets
                                  : &local_compatible_charsets;
          // get the list of compatible charsets if it was not provided:
          if (!compatible_charsets)
            onis::util::dicom::find_all_compatible_charsets_with_person_name(
                manager, true, N2, I2, P2, *compatible_charset_list);

          // find a common character set:
          const onis::dicom_charset* set_to_use = nullptr;
          for (auto& set : file_charsets) {
            if (std::find(compatible_charset_list->begin(),
                          compatible_charset_list->end(),
                          set) != compatible_charset_list->end()) {
              set_to_use = set;
              break;
            }
          }

          // if no common character is found, we will use the first compatible
          // character set:
          if (!set_to_use && !compatible_charset_list->empty())
            set_to_use = compatible_charset_list->front();
          if (set_to_use) {
            std::string def_esc = default_file_charset_info->esc_g0;

            // the first group cannot use escape sequence. We first check if it
            // will be the case:
            bool first_group_need_escape = false;
            if (!set_to_use->info.empty() &&
                set_to_use->info.front()->esc_g0 != def_esc)
              first_group_need_escape = true;
            if (first_group_need_escape)
              return EOS_TAG_VALUE_INVALID_WITH_DEFAULT_REPERTOIRE;
            else {
              std::string N3[5], I3[5], P3[5];
              for (std::int32_t i = 0; i < 5; i++) {
                N3[i] = onis::util::dicom::create_new_file_string(
                    manager, def_esc, N2[i], set_to_use, &used_charsets);
                I3[i] = onis::util::dicom::create_new_file_string(
                    manager, def_esc, I2[i], set_to_use, &used_charsets);
                P3[i] = onis::util::dicom::create_new_file_string(
                    manager, def_esc, P2[i], set_to_use, &used_charsets);
              }
              std::string final_value =
                  onis::util::dicom::build_person_name(manager, N3, I3, P3);

              // this first group cannot accept escape sequence.
              // we can't use this name if it starts by an escape sequence:
              if (!final_value.empty() &&
                  (std::uint8_t)final_value[0] == 0x1B) {
                // we should not come here, as it was supposed to be checked
                // before!
                return EOS_TAG_VALUE_INVALID_WITH_DEFAULT_REPERTOIRE;
              } else {
                // remove duplicated escapes:
                onis::util::dicom::remove_duplicated_escapes(
                    manager, final_value, def_esc);
                // DebugShowHexString(final_value);
                if (!set_string_element(tag, type, final_value, true))
                  return EOS_TAG_INSERT;
              }
            }

          } else {
            // no compatible repertoire, it is a failure:
            return EOS_TAG_NO_COMPATIBLE_REPERTOIRE;
          }

        } else if (type == "LO" || type == "LT" || type == "SH" ||
                   type == "ST" || type == "UT") {
          std::string current_value;
          get_string_element(current_value, tag, type, specific_character_set,
                             nullptr);
          if (current_value != utf8_value) {
            // local list of compatible charsets (only used if not provided)
            std::list<const onis::dicom_charset*> local_compatible_charsets;

            // list of compatible charsets we can use:
            std::list<const onis::dicom_charset*>* compatible_charset_list =
                compatible_charsets ? compatible_charsets
                                    : &local_compatible_charsets;
            // get the list of compatible charsets if it was not provided:
            if (!compatible_charsets)
              onis::util::dicom::find_all_compatible_charsets(
                  manager, utf8_value, *compatible_charset_list);
            // if (!compatible_charsets)
            // onis::util::dicom::find_all_compatible_charsets_with_person_name(_app,
            // true, N2, I2, P2, *compatible_charset_list);

            // find a common character set:
            const onis::dicom_charset* set_to_use = nullptr;
            for (auto& set : file_charsets) {
              if (std::find(compatible_charset_list->begin(),
                            compatible_charset_list->end(),
                            set) != compatible_charset_list->end()) {
                set_to_use = set;
                break;
              }
            }

            // if no common character is found, we will use the first compatible
            // character set:
            if (!set_to_use && !compatible_charset_list->empty())
              set_to_use = compatible_charset_list->front();
            if (set_to_use) {
              std::string def_esc = default_file_charset_info->esc_g0;
              std::string final_value =
                  onis::util::dicom::create_new_file_string(
                      manager, def_esc, utf8_value, set_to_use, &used_charsets);
              onis::util::dicom::remove_duplicated_escapes(manager, final_value,
                                                           def_esc);
              // DebugShowHexString(final_value);
              if (!set_string_element(tag, type, final_value, true))
                return EOS_TAG_INSERT;

            } else {
              // no compatible repertoire, it is a failure:
              return EOS_TAG_NO_COMPATIBLE_REPERTOIRE;
            }
          }
        }

        // modify the specific character set tag if necessary:
        if (ret == EOS_NONE && !used_charsets.empty()) {
          // create a new character set for the file:
          std::string new_file_charset =
              onis::util::dicom::construct_new_char_tag(
                  manager, specific_character_set, used_charsets);
          if (new_file_charset != specific_character_set)
            if (!set_string_element(TAG_SPECIFIC_CHARACTER_SET, "CS",
                                    new_file_charset, true))
              return EOS_TAG_INSERT;
        }
      }
    }
  }
  return ret;
}

bool dicom_dcmtk_base::set_us_element(std::int32_t tag, std::uint16_t value,
                                      bool create) {
  return set_binary_value(tag, "US", sizeof(std::uint16_t),
                          (std::uint8_t*)&value, create);
}

bool dicom_dcmtk_base::set_binary_value(std::int32_t tag,
                                        const std::string& type,
                                        std::int32_t length, std::uint8_t* data,
                                        bool create) {
  bool ret = false;

  // prevent concurrency:
  _mutex.lock();

  // prepare the key to write:
  std::uint16_t* tmp = (std::uint16_t*)&tag;
  DcmTagKey dcmtk_tag(tmp[1], tmp[0]);

  // create the new element:
  bool ok = true;
  // #if defined(WIN32) || defined(_ONIS_FOR_LINUX_)
  DcmElement* elt = newDicomElement(dcmtk_tag);
  // #else
  // DcmElement* elt = DcmDataset::newDicomElement(dcmtk_tag);
  // #endif
  //  set the element value:
  if (type == "AE" || type == "AS" || type == "CS" || type == "DA" ||
      type == "DS" || type == "DT" || type == "IS" || type == "LO" ||
      type == "LT" || type == "PN" || type == "SH" || type == "ST" ||
      type == "TM" || type == "UI" || type == "UT") {
    OFString val;
    for (std::int32_t i = 0; i < length; i++)
      val += (char)data[i];
    OFCondition status = elt->putOFStringArray(val);
    if (status != EC_Normal)
      ret = false;

  } else if (type == "FL") {
    Float32* val = (Float32*)data;
    OFCondition status = elt->putFloat32Array(val, length / 4);
    if (status != EC_Normal)
      ret = false;

  } else if (type == "FD") {
    Float64* val = (Float64*)data;
    OFCondition status = elt->putFloat64Array(val, length / 8);
    if (status != EC_Normal)
      ret = false;

  } else if (type == "US") {
    Uint16* val = (Uint16*)data;
    OFCondition status = elt->putUint16Array(val, length / 2);
    if (status != EC_Normal)
      ret = false;

  } else if (type == "UL") {
    Uint32* val = (Uint32*)data;
    OFCondition status = elt->putUint32Array(val, length / 4);
    if (status != EC_Normal)
      ret = false;

  } else if (type == "SS") {
    Sint16* val = (Sint16*)data;
    OFCondition status = elt->putSint16Array(val, length / 2);
    if (status != EC_Normal)
      ret = false;

  } else if (type == "SL") {
    Sint32* val = (Sint32*)data;
    OFCondition status = elt->putSint32Array(val, length / 4);
    if (status != EC_Normal)
      ret = false;

  } else if (type == "OB") {
    Uint8* val = (Uint8*)data;
    OFCondition status = elt->putUint8Array(val, length);
    if (status != EC_Normal)
      ret = false;

  } else if (type == "OW") {
    Uint16* val = (Uint16*)data;
    OFCondition status = elt->putUint16Array(val, length / 2);
    if (status != EC_Normal)
      ret = false;

  } else
    ok = false;

  // write:
  if (ok) {
    ok = false;
    OFCondition cond;
    bool ok = false;
    if (_file != nullptr && tmp[1] == 0x0002) {
      // write to the meta info:
      if (_file->getMetaInfo()) {
        if (create || !_file->getMetaInfo()->tagExists(dcmtk_tag, OFTrue)) {
          cond = _file->getMetaInfo()->insert(elt, true, true);
          ok = true;
        }
      }

    } else {
      DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
      if (dataset != nullptr) {
        if (create || !dataset->tagExists(dcmtk_tag, OFTrue)) {
          cond = dataset->insert(elt, true, false);
          ok = true;
        }
      }
    }
    if (ok && cond.good())
      ret = true;
  }

  // delete the element if it was not inserted:
  if (!ret)
    delete elt;

  // unlock:
  _mutex.unlock();

  // return the result:
  return ret;
}

bool dicom_dcmtk_base::set_date_element(std::int32_t tag,
                                        onis::core::date_time* dt,
                                        bool create) {
  // Format date as YYYYMMDD using standard C++
  std::ostringstream oss;
  oss << std::setfill('0') << std::setw(4) << dt->year() << std::setw(2)
      << dt->month() << std::setw(2) << dt->day();
  std::string date = oss.str();

  return set_string_element(tag, "DA", date, create);
}

bool dicom_dcmtk_base::set_time_element(std::int32_t tag, std::int32_t hour,
                                        std::int32_t minute,
                                        std::int32_t second,
                                        std::int32_t fraction, bool create) {
  // Format time as HHMMSS.FFFFFF using standard C++
  std::ostringstream oss;
  oss << std::setfill('0') << std::setw(2) << hour << std::setw(2) << minute
      << std::setw(2) << second << "." << std::setw(6) << fraction;
  std::string time = oss.str();

  return set_string_element(tag, "TM", time, create);
}

//-----------------------------------------------------------------------
// remove elements
//-----------------------------------------------------------------------
bool dicom_dcmtk_base::remove_element(std::int32_t tag) {
  bool ret = true;
  _mutex.lock();
  if (_dataset != nullptr) {
    std::uint16_t* tmp = (std::uint16_t*)&tag;
    DcmTagKey dcmtk_tag(tmp[1], tmp[0]);

    if (_file != nullptr && tmp[1] == 0x0002) {
      // write to the meta info !
      if (_file->getMetaInfo()) {
        DcmElement* elt = _file->getMetaInfo()->remove(dcmtk_tag);
        if (elt)
          delete elt;
      }

    } else {
      DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
      if (dataset != nullptr) {
        DcmElement* elt = dataset->remove(dcmtk_tag);
        if (elt)
          delete elt;
      }
    }
  }
  _mutex.unlock();
  return ret;
}

bool dicom_dcmtk_base::remove_pixel_data() {
  _mutex.lock();
  DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
  if (dataset != nullptr) {
    while (1) {
      DcmElement* elt = nullptr;
      elt = dataset->remove(DCM_PixelData);
      if (elt)
        delete elt;
      else
        break;
    }
  }
  _mutex.unlock();
  return true;
}

//-----------------------------------------------------------------------
// transfer
//-----------------------------------------------------------------------
void dicom_dcmtk_base::transfer_init() {
  // prevent concurrency:
  _mutex.lock();

  DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
  if (dataset != nullptr)
    dataset->transferInit();

  // unlock:
  _mutex.unlock();
}

void dicom_dcmtk_base::transfer_end() {
  // prevent concurrency:
  _mutex.lock();

  DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
  if (dataset != nullptr)
    dataset->transferEnd();

  // unlock:
  _mutex.unlock();
}

std::int32_t dicom_dcmtk_base::read(std::uint8_t* buffer, std::int32_t max_read,
                                    const std::string transfer_syntax,
                                    std::int32_t* read_out,
                                    onis::dcm_group_len_encoding group_encoding,
                                    std::uint32_t max_element_read_len) {
  std::int32_t ret = 2;

  // prevent concurrency:
  _mutex.lock();

  DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
  if (dataset == nullptr)
    ret = 2;
  else {
    bool search = true;
    E_TransferSyntax transfer = _save_read_trs;
    if (!transfer_syntax.empty()) {
      if (transfer_syntax == _save_read_trs_string) {
        transfer = _save_read_trs;
        search = false;
      }

    } else {
      transfer = EXS_Unknown;
      search = false;
    }

    if (search) {
      std::int32_t compression;
      transfer = dicom_dcmtk_file::get_transfer_syntax_from_name(
          transfer_syntax, &compression);
      _save_read_trs = transfer;
      _save_read_trs_string = transfer_syntax;
    }

    DcmInputBufferStream stream;
    stream.setBuffer(buffer, max_read);
    OFCondition cond =
        dataset->read(stream, transfer, (E_GrpLenEncoding)group_encoding,
                      max_element_read_len);
    *read_out = (std::uint32_t)stream.tell();
    stream.releaseBuffer();
    if (cond == EC_Normal)
      ret = 0;
    else if (cond == EC_StreamNotifyClient)
      ret = 1;
    else
      ret = 2;
  }

  // unlock:
  _mutex.unlock();

  // return the result:
  return ret;
}

std::int32_t dicom_dcmtk_base::write(
    std::uint8_t* buffer, std::int32_t length, std::string transfer_syntax,
    std::int32_t* write_out, onis::dcm_encoding_type encoding_type,
    onis::dcm_group_len_encoding group_encoding,
    onis::dcm_padding_encoding padding) {
  std::int32_t ret = 2;

  // prevent concurrency:
  _mutex.lock();

  DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
  if (dataset == nullptr)
    ret = 2;
  else {
    bool search = true;
    E_TransferSyntax transfer = _save_write_trs;
    if (!transfer_syntax.empty()) {
      if (transfer_syntax == _save_write_trs_string) {
        transfer = _save_write_trs;
        search = false;
      }

    } else {
      transfer = EXS_Unknown;
      search = false;
    }

    if (search) {
      std::int32_t compression;
      transfer = dicom_dcmtk_file::get_transfer_syntax_from_name(
          transfer_syntax, &compression);
      _save_write_trs = transfer;
      _save_write_trs_string = transfer_syntax;
    }

    OFCondition cond;
    DcmOutputBufferStream stream(buffer, length);

    cond = dataset->write(stream, transfer, (E_EncodingType)encoding_type,
                          nullptr, (E_GrpLenEncoding)group_encoding,
                          (E_PaddingEncoding)padding);
    *write_out = (std::int32_t)stream.tell();
    if (cond == EC_Normal)
      ret = 0;
    else if (cond == EC_StreamNotifyClient)
      ret = 1;
    else
      ret = 2;
  }

  // unlock:
  _mutex.unlock();

  // return the result:
  return ret;
}

//-----------------------------------------------------------------------
// regions
//-----------------------------------------------------------------------
void dicom_dcmtk_base::get_regions(onis::frame_region_list& list) const {
  _mutex.lock();
  DcmDataset* dataset = _file != nullptr ? _file->getDataset() : _dataset;
  if (dataset != nullptr) {
    bool done = false;
    std::int32_t width = 0;
    std::int32_t height = 0;
    std::string temp;
    get_string_element(temp, TAG_COLUMNS, "US");
    if (!temp.empty())
      width = onis::util::string::convert_to_s32(temp);
    temp = "";
    get_string_element(temp, TAG_ROWS, "US");
    if (!temp.empty())
      height = onis::util::string::convert_to_s32(temp);

    temp = "";
    get_string_element(temp, TAG_PIXEL_SPACING, "DS");
    size_t pos = temp.find('\\');
    if (pos != std::string::npos) {
      onis::frame_region_ptr region = onis::frame_region::create();
      region->original_spacing[1] =
          onis::util::string::convert_to_f32(temp.substr(0, pos));
      region->original_spacing[0] = onis::util::string::convert_to_f32(
          temp.substr(pos + 1, temp.length() - pos - 1));
      if (region->original_spacing[0] <= 0 ||
          region->original_spacing[1] <= 0) {
        region->original_spacing[0] = 1;
        region->original_spacing[1] = 1;
        region->original_unit[0] = onis::os_unit_none;
        region->original_unit[1] = onis::os_unit_none;

      } else {
        region->original_spacing[0] /= 10;
        region->original_spacing[1] /= 10;
        region->original_unit[0] = onis::os_unit_cm;
        region->original_unit[1] = onis::os_unit_cm;
      }
      region->calibrated_spacing[0] = region->original_spacing[0];
      region->calibrated_spacing[1] = region->original_spacing[1];
      region->calibrated_unit[0] = region->original_unit[0];
      region->calibrated_unit[1] = region->original_unit[1];

      region->x0 = 0;
      region->x1 = width - 1;
      region->y0 = 0;
      region->y1 = height - 1;
      list.push_back(region);
      done = true;
    }

    if (!done) {
      // no pixel spacing defined, try to read ultrasound regions:
      if (dataset != nullptr) {
        DcmItem* ditem = nullptr;
        unsigned long i = 0;
        while (dataset
                   ->findAndGetSequenceItem(DCM_SequenceOfUltrasoundRegions,
                                            ditem, i)
                   .good()) {
          if (!ditem->tagExists(DCM_PhysicalUnitsXDirection)) {
            i++;
            continue;
          }
          if (!ditem->tagExists(DCM_PhysicalUnitsYDirection)) {
            i++;
            continue;
          }
          if (!ditem->tagExists(DCM_PhysicalDeltaX)) {
            i++;
            continue;
          }
          if (!ditem->tagExists(DCM_PhysicalDeltaY)) {
            i++;
            continue;
          }
          if (!ditem->tagExists(DCM_RegionLocationMinX0)) {
            i++;
            continue;
          }
          if (!ditem->tagExists(DCM_RegionLocationMinY0)) {
            i++;
            continue;
          }
          if (!ditem->tagExists(DCM_RegionLocationMaxX1)) {
            i++;
            continue;
          }
          if (!ditem->tagExists(DCM_RegionLocationMaxY1)) {
            i++;
            continue;
          }

          long x0, x1, y0, y1;
          Uint16 physical_units_x_direction = 0;
          Uint16 physical_units_y_direction = 0;
          double physical_delta_x;
          double physical_delta_y;

          if (!ditem
                   ->findAndGetUint16(DCM_PhysicalUnitsXDirection,
                                      physical_units_x_direction)
                   .good()) {
            i++;
            continue;
          }
          if (!ditem
                   ->findAndGetUint16(DCM_PhysicalUnitsYDirection,
                                      physical_units_y_direction)
                   .good()) {
            i++;
            continue;
          }
          if (!ditem->findAndGetFloat64(DCM_PhysicalDeltaX, physical_delta_x)
                   .good()) {
            i++;
            continue;
          }
          if (!ditem->findAndGetFloat64(DCM_PhysicalDeltaY, physical_delta_y)
                   .good()) {
            i++;
            continue;
          }
          if (!ditem->findAndGetLongInt(DCM_RegionLocationMinX0, x0).good()) {
            i++;
            continue;
          }
          if (!ditem->findAndGetLongInt(DCM_RegionLocationMinY0, y0).good()) {
            i++;
            continue;
          }
          if (!ditem->findAndGetLongInt(DCM_RegionLocationMaxX1, x1).good()) {
            i++;
            continue;
          }
          if (!ditem->findAndGetLongInt(DCM_RegionLocationMaxY1, y1).good()) {
            i++;
            continue;
          }

          onis::frame_region_ptr region = onis::frame_region::create();
          region->original_spacing[0] = physical_delta_x;
          region->original_spacing[1] = physical_delta_y;

          for (std::int32_t j = 0; j < 2; j++) {
            std::int32_t onis_unit = 0;
            Uint16 unit = (j == 0) ? physical_units_x_direction
                                   : physical_units_y_direction;
            switch (unit) {
              case 0x02:
                onis_unit = onis::os_unit_decibel;
                break;
              case 0x04:
                onis_unit = onis::os_unit_second;
                break;
              case 0x06:
                onis_unit = onis::os_unit_decibel_per_second;
                break;
              case 0x08:
                onis_unit = onis::os_unit_cm2;
                break;
              case 0x0A:
                onis_unit = onis::os_unit_cm3;
                break;
              case 0x0C:
                onis_unit = onis::os_unit_degrees;
                break;
              case 0x01:
                onis_unit = onis::os_unit_percent;
                break;
              case 0x03:
                onis_unit = onis::os_unit_cm;
                break;
              case 0x05:
                onis_unit = onis::os_unit_hertz;
                break;
              case 0x07:
                onis_unit = onis::os_unit_cm_per_second;
                break;
              case 0x09:
                onis_unit = onis::os_unit_cm2_per_second;
                break;
              case 0x0B:
                onis_unit = onis::os_unit_cm3_per_second;
                break;
              default:
                break;
            };
            if (j == 0)
              region->original_unit[0] = onis_unit;
            else
              region->original_unit[1] = onis_unit;
          }

          region->calibrated_spacing[0] = region->original_spacing[0];
          region->calibrated_spacing[1] = region->original_spacing[1];
          region->calibrated_unit[0] = region->original_unit[0];
          region->calibrated_unit[1] = region->original_unit[1];

          region->x0 = 0;
          region->x1 = width - 1;
          region->y0 = 0;
          region->y1 = height - 1;
          list.push_back(region);
          done = true;

          i++;
        }
      }
    }

    if (!done) {
      // no pixel spacing and no us region defined.
      // try with imager pixel spacing:
      temp = "";
      get_string_element(temp, TAG_IMAGER_PIXEL_SPACING, "DS");
      size_t pos = temp.find('\\');
      if (pos != std::string::npos) {
        onis::frame_region_ptr region = onis::frame_region::create();
        region->original_spacing[1] =
            onis::util::string::convert_to_f32(temp.substr(0, pos));
        region->original_spacing[0] = onis::util::string::convert_to_f32(
            temp.substr(pos + 1, temp.length() - pos - 1));
        if (region->original_spacing[0] <= 0 ||
            region->original_spacing[1] <= 0) {
          region->original_spacing[0] = 1;
          region->original_spacing[1] = 1;
          region->original_unit[0] = onis::os_unit_none;
          region->original_unit[1] = onis::os_unit_none;

        } else {
          region->original_spacing[0] /= 10;
          region->original_spacing[1] /= 10;
          region->original_unit[0] = onis::os_unit_cm;
          region->original_unit[1] = onis::os_unit_cm;
        }
        region->calibrated_spacing[0] = region->original_spacing[0];
        region->calibrated_spacing[1] = region->original_spacing[1];
        region->calibrated_unit[0] = region->original_unit[0];
        region->calibrated_unit[1] = region->original_unit[1];

        region->x0 = 0;
        region->x1 = width - 1;
        region->y0 = 0;
        region->y1 = height - 1;
        list.push_back(region);
        done = true;
      }
    }

    if (!done) {
      // no pixel spacing, no us region defined and no imager pixel spacing.
      // try with pixel ratio:
      temp = "";
      get_string_element(temp, TAG_PIXEL_ASPECT_RATIO, "IS");
      size_t pos = temp.find('\\');
      if (pos != std::string::npos) {
        double value1 = onis::util::string::convert_to_f32(temp.substr(0, pos));
        double value2 = onis::util::string::convert_to_f32(
            temp.substr(pos + 1, temp.length() - pos - 1));
        if (value1 > 0 && value2 > 0) {
          onis::frame_region_ptr region = onis::frame_region::create();
          region->original_spacing[0] = 1.0;
          region->original_spacing[1] = value1 / value2;
          region->original_unit[0] = onis::os_unit_none;
          region->original_unit[1] = onis::os_unit_none;

          region->calibrated_spacing[0] = region->original_spacing[0];
          region->calibrated_spacing[1] = region->original_spacing[1];
          region->calibrated_unit[0] = region->original_unit[0];
          region->calibrated_unit[1] = region->original_unit[1];

          region->x0 = 0;
          region->x1 = width - 1;
          region->y0 = 0;
          region->y1 = height - 1;
          list.push_back(region);
        }
      }
    }

    if (!done) {
      // no pixel spacing, us region or aspect ratio defined.
      // create a default region:
      onis::frame_region_ptr region = onis::frame_region::create();
      region->x0 = 0;
      region->x1 = width - 1;
      region->y0 = 0;
      region->y1 = height - 1;
      list.push_back(region);
    }
  }
  _mutex.unlock();
}

///////////////////////////////////////////////////////////////////////
// odicom_dataset (dicom dataset without meta header)
///////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------
// static constructor
//-----------------------------------------------------------------------
onis::dicom_dataset_ptr dicom_dcmtk_dataset::create(
    const onis::dicom_manager_ptr& manager) {
  return std::make_shared<dicom_dcmtk_dataset>(manager);
}

//-----------------------------------------------------------------------
// constructor
//-----------------------------------------------------------------------

dicom_dcmtk_dataset::dicom_dcmtk_dataset(const onis::dicom_manager_ptr& manager)
    : onis::dicom_dataset(), dicom_dcmtk_base(manager) {
  _dataset = new DcmDataset;
}

//-----------------------------------------------------------------------
// destructor
//-----------------------------------------------------------------------
dicom_dcmtk_dataset::~dicom_dcmtk_dataset() {
  if (_dataset) {
    _dataset->clear();
    delete _dataset;
  }
}

///////////////////////////////////////////////////////////////////////
// odicom_file
///////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------
// static constructor
//-----------------------------------------------------------------------

onis::dicom_file_ptr dicom_dcmtk_file::create(
    const onis::dicom_manager_ptr& manager) {
  return std::make_shared<dicom_dcmtk_file>(manager);
}

//-----------------------------------------------------------------------
// constructor
//-----------------------------------------------------------------------
dicom_dcmtk_file::dicom_dcmtk_file(const onis::dicom_manager_ptr& manager)
    : onis::dicom_file(), dicom_dcmtk_base(manager) {
  _file = new DcmFileFormat;
}

//-----------------------------------------------------------------------
// destructor
//-----------------------------------------------------------------------

dicom_dcmtk_file::~dicom_dcmtk_file() {
  if (_file != nullptr) {
    _file->clear();
    delete _file;
  }

  // if (_lock_file != nullptr) _lock_file.reset();

  if (is_temporary_file_) {
    if (!path_.empty()) {
      onis::util::filesystem::delete_file(path_);
    }
  }
}

//-----------------------------------------------------------------------
// loading
//-----------------------------------------------------------------------

bool dicom_dcmtk_file::load_file(const std::string& path,
                                 std::int32_t retry_interval,
                                 std::int32_t limit) {
  bool loaded = false;

  // prevent concurrency access:
  _mutex.lock();

  // close the previous file:
  close();

  std::string file_path;
  file_path = path;

  // try to load the dicom file:
  _file = new DcmFileFormat;
  is_mpeg_frame_ = false;
  OFCondition status = _file->loadFile(file_path.data());
  if (status.good()) {
    // file was loaded !
    //_path = utf8_path;
    path_ = path;
    is_loaded_ = true;

  } else
    close();  // failed to load the file !

  // prepare the value to return:
  loaded = is_loaded_;

  //_stream_result.status = OSRSP_PENDING;
  //_stream_len = 0;

  _mutex.unlock();
  return loaded;
}

bool dicom_dcmtk_file::is_loaded() const {
  _mutex.lock();
  bool ret = is_loaded_;
  _mutex.unlock();
  return ret;
}

//-----------------------------------------------------------------------
// closing
//-----------------------------------------------------------------------

void dicom_dcmtk_file::close() {
  _mutex.lock();
  if (_file != nullptr) {
    _file->clear();
    delete _file;
    _file = nullptr;
  }
  // if (_lock_file != nullptr) _lock_file.reset();

  if (is_temporary_file_) {
    if (!path_.empty()) {
      onis::util::filesystem::delete_file(path_);
    }
  }
  path_.clear();
  //_is_mpeg_frame = false;
  _mutex.unlock();
}

//-----------------------------------------------------------------------
// properties
//-----------------------------------------------------------------------
bool dicom_dcmtk_file::is_temporary_file() const {
  _mutex.lock();
  bool ret = is_temporary_file_;
  _mutex.unlock();
  return ret;
}

void dicom_dcmtk_file::set_temporary_file(bool temp) {
  _mutex.lock();
  is_temporary_file_ = temp;
  _mutex.unlock();
}

std::string dicom_dcmtk_file::get_file_path() const {
  _mutex.lock();
  std::string path = path_;
  _mutex.unlock();
  return path;
}

//-----------------------------------------------------------------------
// saving
//-----------------------------------------------------------------------
// bool odicom_file::save_file(const std::string &utf8_path, const
// std::string &transfer_syntax, bool set_file_path) {
bool dicom_dcmtk_file::save_file(const std::string& path,
                                 const std::string& transfer_syntax,
                                 bool set_file_path) {
  bool ret = false;
  _mutex.lock();
  if (_file != nullptr) {
    std::string path1;
    path1 = path;

    if (transfer_syntax.empty()) {
      OFCondition status = _file->saveFile(path1.data());
      if (status.good())
        ret = true;
      else {
      }

    } else {
      std::int32_t compression;
      E_TransferSyntax transfer =
          get_transfer_syntax_from_name(transfer_syntax, &compression);
      if (transfer != -1) {
        if (compression == CPR_DCM_NOCOMPRESS) {
          _file->chooseRepresentation(transfer, nullptr);
          if (_file->canWriteXfer(transfer)) {
            OFCondition status = _file->saveFile(path1.data(), transfer);
            if (status.good())
              ret = true;
          }

        } else if (compression == CPR_DCM_JPEG ||
                   compression == CPR_DCM_JPEG2000) {
          E_TransferSyntax opt_oxfer = transfer;
          // OFCmdUnsignedInt opt_selection_value = 6;
          // OFCmdUnsignedInt opt_point_transform = 0;
          DJ_RPLossy rp_lossy;
          const DcmRepresentationParameter* rp = &rp_lossy;

          _file->chooseRepresentation(opt_oxfer, rp);
          if (_file->canWriteXfer(opt_oxfer)) {
            OFCondition status = _file->saveFile(path1.data(), opt_oxfer);
            if (status.good())
              ret = true;
          }

        } else if (compression == CPR_DCM_JPEGLS ||
                   compression == CPR_DCM_JPEG2000LS) {
          DcmElement* derivation_description_elt = nullptr;
          DcmElement* derivation_code_sequence_elt = nullptr;
          DcmDataset* dataset = _file->getDataset();
          if (dataset != nullptr) {
            dataset->findAndGetElement(DcmTagKey(0x0008, 0x2111),
                                       derivation_description_elt, true,
                                       OFTrue);
            dataset->findAndGetElement(DcmTagKey(0x0008, 0x9215),
                                       derivation_code_sequence_elt, true,
                                       OFTrue);
          }

          E_TransferSyntax opt_oxfer = transfer;
          OFCmdUnsignedInt opt_selection_value = 6;
          OFCmdUnsignedInt opt_point_transform = 0;
          DJ_RPLossless rp_lossless((int)opt_selection_value,
                                    (int)opt_point_transform);
          const DcmRepresentationParameter* rp = &rp_lossless;

          _file->chooseRepresentation(opt_oxfer, rp);
          if (_file->canWriteXfer(opt_oxfer)) {
            if (dataset != nullptr) {
              if (derivation_description_elt) {
                OFCondition delete_status = dataset->findAndDeleteElement(
                    DcmTagKey(0x0008, 0x2111), true, true);
                if (delete_status.good()) {
                  OFCondition insert_status =
                      dataset->insert(derivation_description_elt, true);
                  if (insert_status.good())
                    derivation_description_elt = nullptr;
                }

                if (derivation_code_sequence_elt) {
                  OFCondition delete_status = dataset->findAndDeleteElement(
                      DcmTagKey(0x0008, 0x9215), true, true);
                  if (delete_status.good()) {
                    OFCondition insert_status =
                        dataset->insert(derivation_code_sequence_elt, true);
                    if (insert_status.good())
                      derivation_code_sequence_elt = nullptr;
                  }

                } else
                  dataset->findAndDeleteElement(DcmTagKey(0x0008, 0x9215), true,
                                                true);
              }
            }

            OFCondition status = _file->saveFile(path1.data(), opt_oxfer);
            if (status.good())
              ret = true;
          }

          if (derivation_description_elt) {
            derivation_description_elt->clear();
            delete derivation_description_elt;
          }

          if (derivation_code_sequence_elt) {
            derivation_code_sequence_elt->clear();
            delete derivation_code_sequence_elt;
          }

        } else if (compression == CPR_DCM_RLELS) {
          E_TransferSyntax opt_oxfer = transfer;
          // OFCmdUnsignedInt opt_selection_value = 6;
          // OFCmdUnsignedInt opt_point_transform = 0;
          DcmRLERepresentationParameter rp_rlerep;
          const DcmRepresentationParameter* rp = &rp_rlerep;
          _file->chooseRepresentation(opt_oxfer, rp);
          if (_file->canWriteXfer(opt_oxfer)) {
            OFCondition status = _file->saveFile(path1.data(), opt_oxfer);
            if (status.good())
              ret = true;
          }

        } else if (compression == CPR_DCM_MPEG) {
          OFCondition status = _file->saveFile(path1.data(), transfer);
          if (status.good())
            ret = true;
        }
      }
    }

    if (ret == true && set_file_path) {
      //_path = utf8_path;
      path_ = path;
      //_temp_file = false;
      is_loaded_ = true;
    }
  }

  _mutex.unlock();
  return ret;
}

//-----------------------------------------------------------------------
// palette
//-----------------------------------------------------------------------

onis::dicom_raw_palette* dicom_dcmtk_file::get_raw_palette(
    std::int32_t channel) const {
  /*std::int32_t tag_descriptor = 0;
  std::int32_t tag_data = 0;
  switch (channel) {
    case OSRED:
      tag_descriptor = TAG_RED_PALETTE_COLOR_LOOKUP_TABLE_DESCRIPTOR;
      tag_data = TAG_RED_PALETTE_COLOR_LOOKUP_TABLE_DATA;
      break;
    case OSGREEN:
      tag_descriptor = TAG_GREEN_PALETTE_COLOR_LOOKUP_TABLE_DESCRIPTOR;
      tag_data = TAG_GREEN_PALETTE_COLOR_LOOKUP_TABLE_DATA;
      break;
    case OSBLUE:
      tag_descriptor = TAG_BLUE_PALETTE_COLOR_LOOKUP_TABLE_DESCRIPTOR;
      tag_data = TAG_BLUE_PALETTE_COLOR_LOOKUP_TABLE_DATA;
      break;
  };

  std::string descriptor;
  get_string_element(descriptor, tag_descriptor, "US");
  if (descriptor.empty())
    return nullptr;
  else {
    std::vector<std::string> list;
    onis::util::string::split(descriptor, list, "\\");
    if (list.size() != 3)
      return nullptr;

    std::vector<std::string>::const_iterator it = list.begin();
    std::int32_t count = onis::util::string::convert_to_s32(*it);
    it++;
    std::int32_t value = onis::util::string::convert_to_s32(*it);
    it++;
    std::int32_t bits = onis::util::string::convert_to_s32(*it);
    if (bits != 8 && bits != 16)
      return nullptr;
    if (count == 0)
      count = 65536;

    std::int32_t data_len = 0;
    u8* data = nullptr;
    std::string new_tranfer_syntax = "1.2.840.10008.1.2.1";
    try {
      if (get_binary_value(tag_data, "OW", &data_len, &data,
                           new_tranfer_syntax)) {
        if (data_len > 0) {
          onis::dicom_raw_palette* output = new onis::dicom_raw_palette();
          output->bits = bits;
          output->value = value;
          output->count = count;
          output->data = data;
          output->data_len = data_len;
          return output;

        } else
          return nullptr;

      } else
        return nullptr;

    } catch (...) {
      delete[] data;
      return nullptr;
    }
  }*/
  return nullptr;
}

//-----------------------------------------------------------------------
// frames
//-----------------------------------------------------------------------
onis::dicom_frame_ptr dicom_dcmtk_file::extract_frame(std::int32_t index) {
  onis::dicom_frame_ptr image;
  /*onis::aresult res1;
  _mutex.lock();

  // the dicom file must exist:
  if (_file == nullptr) {
    res1.status = OSRSP_FAILURE;
    res1.reason = EOS_NO_FILE;

  } else {
    // create an image:
    image = std::static_pointer_cast<odicom_frame>(odicom_frame::create(_app));
    if (image == nullptr) {
      res1.status = OSRSP_FAILURE;
      res1.reason = EOS_MEMORY;

    } else {
      // is it a mpeg file?
      std::string transfer_syntax;
      get_string_element(transfer_syntax, TAG_TRANSFER_SYNTAX_UID, "UI");
      if (transfer_syntax == "1.2.840.10008.1.2.4.100" ||
          transfer_syntax == "1.2.840.10008.1.2.4.101" ||
          transfer_syntax == "1.2.840.10008.1.2.4.102" ||
          transfer_syntax == "1.2.840.10008.1.2.4.103") {
        // this is an mpeg file!
        // we prepare a bitmap to receive the pixel data:
        std::string tmp;
        get_string_element(tmp, TAG_ROWS, "US");
        u16 height = (u16)onis::util::string::convert_to_u32(tmp);
        get_string_element(tmp, TAG_COLUMNS, "US");
        u16 width = (u16)onis::util::string::convert_to_u32(tmp);
        if (width <= 8192 && height <= 8192) {
          // try to extract the bitmap:
          if (_mpeg_bmp == nullptr) {
            std::uint64_t start, stop;
            if (get_pixel_data_positions(&start, &stop)) {
              onis::graphics::mpeg_decoder_ptr decoder =
                  _app->get_graphic_manager()->create_mpeg_decoder();
              if (decoder != nullptr) {
                decoder->set_dicom_file(
                    std::static_pointer_cast<onis::dicom_file>(
                        shared_from_this()));
                decoder->set_should_loop(0);
                _mpeg_bmp = decoder->get_default_frame(0);

                if (_mpeg_bmp != nullptr)
                  _is_mpeg_frame = true;
              }
            }
          }

          image->_mpeg_bmp =
              (_mpeg_bmp == nullptr)
                  ? onis::bitmap::create(width, height, onis::pixfmt_24rgb)
                  : _mpeg_bmp->clone();
          image->set_original_window_level(128.0, 255.0);
          image->set_dicom_file(
              std::static_pointer_cast<odicom_file>(shared_from_this()));
          image->_is_mpeg_frame = true;

        } else {
          res1.status = OSRSP_FAILURE;
          res1.reason = EOS_INVALID_IMAGE;
        }

      } else {
        // read the photometric information:
        std::string photometric, voi_lut_function;
        get_string_element(voi_lut_function, 0x00281056UL, "CS");
        get_string_element(photometric, TAG_PHOTOMETRIC_INTERPRETATION, "CS");

        // is it an rgb images?
        bool is_rgb = false;
        if (photometric == "RGB" || photometric == "YBR_FULL_422" ||
            photometric == "YBR_FULL" || photometric == "YBR_RCT" ||
            photometric == "YBR_ICT")
          is_rgb = true;

        // if it is an rgb image, we may need to modify the photometric
        // information when this is a Jpeg image: this is to insure the right
        // color mode when dcmtk decompress the jpeg image
        std::string transfer;
        get_string_element(transfer, TAG_TRANSFER_SYNTAX_UID, "UI");
        std::string replace_to_rgb;
        if (transfer == "1.2.840.10008.1.2.4.50") {
          if (photometric == "RGB") {
            replace_to_rgb = "RGB";
            set_string_element(TAG_PHOTOMETRIC_INTERPRETATION, "CS",
                               "YBR_FULL_422", true);
          }
        }

        // set the index:
        image->set_frame_index(index);

        // get the rescale slope and intercept
        std::string intercept, slope;
        get_string_element(intercept, TAG_RESCALE_INTERCEPT, "DS");
        get_string_element(slope, TAG_RESCALE_SLOPE, "DS");
        if ((!intercept.empty()) && (!slope.empty()))
          image->set_rescale_and_intercept(
              onis::util::string::convert_to_f64(slope),
              onis::util::string::convert_to_f64(intercept));
        E_TransferSyntax xfer = _file->getDataset()->getOriginalXfer();
        DcmFileFormat* tmp = nullptr;

        try {
          tmp = (DcmFileFormat*)_file->clone();

        } catch (...) {
          res1.status = OSRSP_FAILURE;
          res1.reason = EOS_MEMORY;
          if (tmp)
            delete tmp;
          tmp = nullptr;
          image.reset();
        }

        if (tmp != nullptr) {
          unsigned long opt_compatibilityMode =
              CIF_MayDetachPixelData;  // | CIF_TakeOverExternalDataset;
          long fCount;
          _file->getDataset()->findAndGetLongInt(DCM_NumberOfFrames, fCount);
          int framecnt = (int)fCount;
          if (framecnt > 1) {
            DicomImage* toto = nullptr;
            try {
              if (is_rgb)
                toto = new DicomImage(
                    tmp, xfer, CIF_UsePartialAccessToPixelData, index, 1);
              else
                toto = new DicomImage(
                    tmp, xfer, 1, 0, CIF_UsePartialAccessToPixelData, index, 1);
              image->_image = toto->createDicomImage(0, 1);

            } catch (...) {
              res1.status = OSRSP_FAILURE;
              res1.reason = EOS_MEMORY;
              if (tmp)
                delete tmp;
              tmp = nullptr;
              image.reset();
            }
            if (toto)
              delete toto;

          } else {
            try {
              if (is_rgb)
                image->_image =
                    new DicomImage(tmp, xfer, opt_compatibilityMode, index, 1);
              else {
                image->_image = new DicomImage(tmp, xfer, 1, 0,
                                               opt_compatibilityMode, index, 1);
                image->_image->hideAllOverlays();
                for (unsigned int k = 0; k < 16; k++) {
                  if (k < image->_image->getOverlayCount()) {
                    if (!image->_image->showOverlay(k, EMO_Default)) {
                    } else {
                      std::uint32_t width, height;
                      const void* pixels = image->_image->getFullOverlayData(
                          k, width, height, 0, 8, 0xff, 0x0, 0);
                      if (pixels != nullptr) {
                        image->_overlays[k].show = false;
                        image->_overlays[k].width = width;
                        image->_overlays[k].height = height;
                        image->_overlays[k].data = new u8[width * height];
                        memcpy(image->_overlays[k].data, pixels,
                               width * height);
                        image->_image->deleteOverlayData();
                      }
                    }
                  }
                }
              }

            } catch (...) {
              res1.status = OSRSP_FAILURE;
              res1.reason = EOS_MEMORY;
              if (tmp)
                delete tmp;
              tmp = nullptr;
              image.reset();
            }
          }
          if (tmp)
            delete tmp;
        }

        if (!replace_to_rgb.empty())
          set_string_element(TAG_PHOTOMETRIC_INTERPRETATION, "CS", "RGB", true);

        if (image != nullptr) {
          if (image->_image) {
            // Handle the palette color:
            if (photometric == "PALETTE COLOR") {
              bool palette_ok = true;

              // Get the palette information for each component (Red, Green and
              // Blue)
              for (std::int32_t i = 0; i < 3; i++) {
                onis::dicom_palette* palette = nullptr;
                std::int32_t tag_descriptor = 0;
                std::int32_t tag_data = 0;
                switch (i) {
                  case 0:
                    palette = image->get_palette(OSRED);
                    tag_descriptor =
                        TAG_RED_PALETTE_COLOR_LOOKUP_TABLE_DESCRIPTOR;
                    tag_data = TAG_RED_PALETTE_COLOR_LOOKUP_TABLE_DATA;
                    break;
                  case 1:
                    palette = image->get_palette(OSGREEN);
                    tag_descriptor =
                        TAG_GREEN_PALETTE_COLOR_LOOKUP_TABLE_DESCRIPTOR;
                    tag_data = TAG_GREEN_PALETTE_COLOR_LOOKUP_TABLE_DATA;
                    break;
                  case 2:
                    palette = image->get_palette(OSBLUE);
                    tag_descriptor =
                        TAG_BLUE_PALETTE_COLOR_LOOKUP_TABLE_DESCRIPTOR;
                    tag_data = TAG_BLUE_PALETTE_COLOR_LOOKUP_TABLE_DATA;
                    break;
                };

                std::string descriptor;
                get_string_element(descriptor, tag_descriptor, "US");
                if (!descriptor.empty()) {
                  std::size_t pos = descriptor.find("\\");
                  if (pos == std::string::npos)
                    palette_ok = true;
                  else {
                    std::string left = descriptor.substr(pos);
                    std::string right = descriptor.substr(pos + 1);
                    palette->count = onis::util::string::convert_to_s32(left);
                    if (palette->count == 0)
                      palette->count = 65536;
                    std::size_t pos = (std::int32_t)right.find("\\");
                    if (pos == std::string::npos)
                      palette_ok = false;
                    else {
                      left = right.substr(pos);
                      right = right.substr(pos + 1);
                      if (right == "8")
                        palette->bits = 8;
                      else if (right == "16")
                        palette->bits = 16;
                      else
                        palette_ok = false;
                    }
                  }
                }

                if (palette_ok) {
                  // we need to read the palette data:
                  std::int32_t length = 0;
                  u8* data = nullptr;
                  std::string new_tranfer_syntax = "1.2.840.10008.1.2.1";

                  // copy the character set:
                  bool read_data_ok = false;
                  try {
                    read_data_ok = get_binary_value(tag_data, "OW", &length,
                                                    &data, new_tranfer_syntax);

                  } catch (...) {
                    res1.status = OSRSP_FAILURE;
                    res1.reason = EOS_MEMORY;
                    read_data_ok = false;
                    if (data)
                      delete[] data;
                    data = nullptr;
                    length = 0;
                  }

                  if (read_data_ok) {
                    if (palette->bits == 16) {
                      bool signed_data;
                      std::int32_t representation =
                          image->get_representation(&signed_data);
                      if (representation == 8) {
                        // the number of entry in the palette must correspond:
                        if (length == 512) {
                          // reduce the palette to 8 bits:
                          u8* palette_data = nullptr;
                          try {
                            palette_data = new u8[256];

                          } catch (...) {
                            res1.status = OSRSP_FAILURE;
                            res1.reason = EOS_MEMORY;
                            if (palette_data)
                              delete[] palette_data;
                            palette_data = nullptr;
                            palette_ok = false;
                          }

                          if (palette_data) {
                            for (std::int32_t z = 0; z < 256; z++)
                              palette_data[z] = (((u16*)data)[z] * 255) / 65535;
                            palette->data = palette_data;
                            delete[] data;
                            data = nullptr;
                          }

                        } else {
                          std::int32_t length_h = length / 2;
                          u8* palette_data = nullptr;
                          try {
                            palette_data = new u8[256];

                          } catch (...) {
                            res1.status = OSRSP_FAILURE;
                            res1.reason = EOS_MEMORY;
                            if (palette_data)
                              delete[] palette_data;
                            palette_data = nullptr;
                            palette_ok = false;
                          }

                          if (palette_data) {
                            if (length_h <= 256) {
                              memset(palette_data, 0, 256);
                              for (int z = 0; z < length_h; z++)
                                palette_data[z] =
                                    (((u16*)data)[z] * 255) / 65535;

                            } else {
                              for (int z = 0; z < 256; z++) {
                                std::int32_t data_index =
                                    (z * (length_h - 1)) / 255;
                                palette_data[z] =
                                    (((u16*)data)[data_index] * 255) / 65535;
                              }
                            }

                            palette->data = palette_data;
                            delete[] data;
                            data = nullptr;
                          }
                        }

                      } else if (representation == 16) {
                        if (length == 131072)
                          palette->data = data;
                        else
                          palette_ok = false;

                      } else
                        palette_ok = false;

                    } else if (palette->bits == 8) {
                      if (length == 256)
                        palette->data = data;
                      else
                        palette_ok = false;

                    } else
                      palette_ok = false;

                    if (!palette_ok && data)
                      delete[] data;

                  } else
                    palette_ok = false;
                }

                if (!palette_ok)
                  break;
              }

              if (!palette_ok) {
                if (res1.status == OSRSP_SUCCESS) {
                  res1.status = OSRSP_FAILURE;
                  res1.reason = EOS_INVALID_PALETTE;
                }
                image.reset();
              }
            }

            if (image != nullptr) {
              EI_Status u_status = image->_image->getStatus();
              if (u_status != EIS_Normal) {
                if (res1.status == OSRSP_SUCCESS) {
                  res1.status = OSRSP_FAILURE;
                  res1.reason = EOS_INVALID_IMAGE;
                }
                image.reset();
              }
            }

          } else {
            if (res1.status == OSRSP_SUCCESS) {
              res1.status = OSRSP_FAILURE;
              res1.reason = EOS_FAILED_TO_EXTRACT_IMAGE;
            }
            image.reset();
          }
        }

        // sometimes dcmtk will make a monochrome image from an image that is
        // supposed to be RGB if this is the case, we need to reconvert it as
        // rgb!
        if (image != nullptr && is_rgb && image->is_monochrome()) {
        }

        if (image != nullptr) {
#ifdef OS_ENABLE_SIGMOID_VOI
          if (voi_lut_function == "SIGMOID")
            image->set_voi_lut_function(1);
#endif

          if (photometric == "MONOCHROME1")
            image->_is_monochrome1 = true;
          if (image->is_monochrome()) {
            if (image->have_palette()) {
              image->set_original_window_level(128.0, 255.0);

            } else {
              f64 min_value, max_value;
              image->_image->getMinMaxValues(min_value, max_value);
              image->set_min_max_values(min_value, max_value, true);

              // set the original window level:
              f64 width, center;
              bool valid =
                  onis::util::dicom::get_window_level(this, &center, &width);
              if (!valid) {
                if (image->get_min_max_values(&min_value, &max_value, false)) {
                  width = (max_value - min_value) + 1.0;
                  center = min_value +
                           width * 0.5;  // (min_value + max_value) / 2.0;

                } else {
                  bool signed_data;
                  std::int32_t representation =
                      image->get_representation(&signed_data);
                  if (representation == 32 || representation == 16) {
                    width = 65536;
                    if (signed_data)
                      center = 0;
                    else
                      center = 32768;

                  } else {
                    width = 256;
                    if (signed_data)
                      center = 0;
                    else
                      center = 128;
                  }
                }
              }
              image->set_original_window_level(center, width);
              image->set_window_level(center, width);
            }

          } else {
            image->set_original_window_level(128.0, 256.0);
            image->set_window_level(128.0, 256.0);
          }

          // lock the dicom file as well:
          image->set_dicom_file(
              std::static_pointer_cast<odicom_file>(shared_from_this()));
        }
      }
    }
  }

  if (res)
    *res = res1;
  _mutex.unlock();*/
  return image;
}

bool dicom_dcmtk_file::remove_private_tags_with_pixel_data() {
  /*bool ret = false;
  DcmDataset* dataset = _file->getDataset();
  std::list<DcmElement*> list;

  DcmStack stack;
  OFCondition condition = dataset->nextObject(stack, OFTrue);
  while (condition.good()) {
    for (std::int32_t i = 0; i < stack.card(); i++) {
      DcmElement* elt = (DcmElement*)stack.elem(i);
      if (elt->getGTag() == 0x7FE0 && elt->getETag() == 0x0010) {
        for (std::int32_t j = i; j < stack.card() - 1; j++) {
          list.push_front((DcmElement*)stack.elem(j));
        }
      }
    }
    condition = dataset->nextObject(stack, OFTrue);
  }

  std::list<DcmElement*>::iterator pos = list.begin();
  while (pos != list.end()) {
    DcmElement* elt = *pos;
    pos++;
    if (elt->getGTag() == 0x7FE0 && elt->getETag() == 0x0010) {
      // Do not delete this one!
      // printf("Should NOT delete: 0x%X-0x%X\n", up_elt->getGTag(),
      // up_elt->getETag());

    } else {
      // Delete this one if it is a private tag!
      if ((elt->getGTag() % 2) != 0) {
        // printf("Should delete: 0x%X-0x%X\n", up_elt->getGTag(),
        // up_elt->getETag());
        dataset->remove(elt);
        delete elt;
        ret = true;
      }

      // Go until the pixel data:
      while (pos != list.end()) {
        elt = *pos;
        pos++;
        if (elt->getGTag() == 0x7FE0 && elt->getETag() == 0x0010)
          break;
      }
    }
  }

  return ret;*/
  return false;
}

//-----------------------------------------------------------------------
// pixels
//-----------------------------------------------------------------------
bool dicom_dcmtk_file::get_pixel_data_positions(std::uint64_t* start,
                                                std::uint64_t* end) {
  bool res = false;
  /*_mutex.lock();
  if (_file != nullptr) {
    if (_file->getDataset() && _file->getMetaInfo()) {
      OFString current_transfer;
      OFCondition status = _file->getMetaInfo()->findAndGetOFStringArray(
          DCM_TransferSyntaxUID, current_transfer);
      if (status == EC_Normal) {
        DcmElement* delem = nullptr;
        if (_file->getDataset()
                ->findAndGetElement(DCM_PixelData, delem, OFFalse)
                .good()) {
          DcmPixelData* dpix = OFstatic_cast(DcmPixelData*, delem);
          E_TransferSyntax xfer = EXS_Unknown;
          const DcmRepresentationParameter* param = nullptr;
          dpix->getOriginalRepresentationKey(xfer, param);
          if ((xfer != EXS_Unknown) && DcmXfer(xfer).isEncapsulated()) {
            DcmPixelSequence* pixSeq = nullptr;
            if (dpix->getEncapsulatedRepresentation(xfer, param, pixSeq)
                    .good() &&
                (pixSeq != nullptr)) {
              std::uint32_t seqlen = pixSeq->card();
              bool get_start_pos = false;
              if (end)
                *end = 0;
              for (std::uint32_t i = 0; i < seqlen; i++) {
                DcmPixelItem* item;
                if (pixSeq->getItem(item, i).good()) {
                  unsigned long len = item->getLength();
                  if (len > 0) {
                    std::uint64_t fposstart = item->GetfLoadValueoffset();
                    std::uint64_t fposend = fposstart + len;

                    if (!get_start_pos) {
                      if (start)
                        *start = fposstart;
                      if (end)
                        *end = fposend;
                      get_start_pos = true;

                    } else {
                      if (end)
                        *end += (8 + len);
                    }

                    res = true;
                    // break;
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  _mutex.unlock();*/
  return res;
}

onis::dicom_frame_offsets* dicom_dcmtk_file::get_pixel_data_positions(
    std::int32_t& count) {
  // init the output
  onis::dicom_frame_offsets* offsets = nullptr;
  count = 0;

  /*_mutex.lock();
  if (_file != nullptr) {
    if (_file->getDataset() && _file->getMetaInfo()) {
      OFString current_transfer;
      OFCondition status = _file->getMetaInfo()->findAndGetOFStringArray(
          DCM_TransferSyntaxUID, current_transfer);
      if (status == EC_Normal) {
        DcmElement* delem = nullptr;
        if (_file->getDataset()
                ->findAndGetElement(DCM_PixelData, delem, OFFalse)
                .good()) {
          DcmPixelData* dpix = OFstatic_cast(DcmPixelData*, delem);
          E_TransferSyntax xfer = EXS_Unknown;
          const DcmRepresentationParameter* param = nullptr;
          dpix->getOriginalRepresentationKey(xfer, param);
          if ((xfer != EXS_Unknown) && DcmXfer(xfer).isEncapsulated()) {
            DcmPixelSequence* pixSeq = nullptr;
            if (dpix->getEncapsulatedRepresentation(xfer, param, pixSeq)
                    .good() &&
                (pixSeq != nullptr)) {
              std::uint32_t seqlen = pixSeq->card();
              if (seqlen >= 2) {
                std::uint64_t goffset = 0;
                DcmPixelItem* item1;
                if (pixSeq->getItem(item1, 1).good())
                  goffset = item1->GetfLoadValueoffset() - 8;

                // get the basic offset table information:
                DcmPixelItem* item;
                if (pixSeq->getItem(item, 0).good()) {
                  Uint8* table8 = nullptr;
                  unsigned long len = item->getLength();
                  bool valid = true;
                  if (len == 0) {
                    // there should be only one frame!
                    std::int32_t fragment_count = seqlen - 1;
                    if (fragment_count > 0) {
                      count = 1;
                      offsets = new onis::dicom_frame_offsets[count];
                      offsets[0].count = fragment_count;
                      offsets[0].offsets =
                          new std::uint64_t[fragment_count * 2];

                      // first fragment offsets:
                      offsets[0].offsets[0] = 0;
                      if (pixSeq->getItem(item, 1).good())
                        offsets[0].offsets[1] =
                            offsets[0].offsets[0] + 8 + item->getLength();
                      else
                        valid = false;

                      // additional fragment offsets:
                      for (std::int32_t j = 2; j < seqlen; j++) {
                        if (pixSeq->getItem(item, j).good()) {
                          offsets[0].offsets[j * 2] =
                              offsets[0].offsets[(j - 1) * 2 + 1];
                          offsets[0].offsets[j * 2 + 1] =
                              offsets[0].offsets[j * 2] + 8 + item->getLength();

                        } else {
                          valid = false;
                          break;
                        }
                      }
                    }

                  } else if (len != 0 && len % 4 == 0 &&
                             item->loadAllDataIntoMemory().good() &&
                             item->getUint8Array(table8).good()) {
                    count = len / 4;
                    Uint32* table = (Uint32*)table8;
                    offsets = new onis::dicom_frame_offsets[count];
                    std::int32_t index = 1;
                    for (std::int32_t i = 0; i < count; i++) {
                      // how many fragments make the frame?
                      std::int32_t fragment_count = 0;
                      if (i == count - 1) {
                        // the last frame use all remaining fragments:
                        fragment_count = seqlen - index;

                      } else {
                        // need to count until reaching the beginning of the
                        // next frame:
                        std::uint32_t next_frame_position = table[i + 1];
                        std::uint32_t start_pos = table[i];
                        std::uint32_t cur_pos = start_pos;
                        for (std::int32_t j = index; j < seqlen; j++) {
                          if (pixSeq->getItem(item, j).good()) {
                            cur_pos += 8 + item->getLength();
                            if (cur_pos >= next_frame_position) {
                              if (cur_pos == next_frame_position)
                                fragment_count++;
                              break;

                            } else
                              fragment_count++;

                          } else {
                            // problem!
                            fragment_count = 0;
                            break;
                          }
                        }
                      }
                      if (fragment_count <= 0)
                        valid = false;
                      else {
                        offsets[i].count = fragment_count;
                        offsets[i].offsets =
                            new std::uint64_t[fragment_count * 2];

                        // first fragment offsets:
                        offsets[i].offsets[0] = table[i];
                        if (pixSeq->getItem(item, index).good())
                          offsets[i].offsets[1] =
                              offsets[i].offsets[0] + 8 + item->getLength();
                        else
                          valid = false;

                        // additional fragment offsets:
                        for (std::int32_t j = 1; j < fragment_count; j++) {
                          if (pixSeq->getItem(item, index + j).good()) {
                            offsets[i].offsets[j * 2] =
                                offsets[i].offsets[(j - 1) * 2 + 1];
                            offsets[i].offsets[j * 2 + 1] =
                                offsets[i].offsets[j * 2] + 8 +
                                item->getLength();

                          } else
                            valid = false;
                        }
                        index += fragment_count;
                      }
                      if (!valid)
                        break;
                    }
                  }

                  if (valid) {
                    // correct the offsets:
                    for (std::int32_t i = 0; i < count; i++) {
                      for (std::int32_t j = 0; j < offsets[i].count; j++) {
                        offsets[i].offsets[j * 2] += 8 + goffset;
                        offsets[i].offsets[j * 2 + 1] += goffset - 1;
                      }
                    }

                  } else {
                    delete[] offsets;
                    count = 0;
                    offsets = nullptr;
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  _mutex.unlock();*/
  return offsets;
}

//-----------------------------------------------------------------------
// frames
//-----------------------------------------------------------------------
bool dicom_dcmtk_file::set_image(onis::dicom_image_info* info) {
  bool ret = true;
  /*_mutex.lock();
  if (_file == nullptr)
    ret = false;
  else {
    // we remove the existing frames if any:
    DcmElement* elt = _file->getDataset()->remove(DCM_PixelData);
    if (elt)
      delete elt;

    // modify the transfer syntax if necessary:
    if (!info->transfer_syntax.empty()) {
      std::int32_t compression;
      E_TransferSyntax transfer = odicom_file::get_transfer_syntax_from_name(
          info->transfer_syntax, &compression);
      if (transfer == EXS_Unknown)
        ret = false;
      else if (!modify_transfer_syntax(transfer))
        ret = false;
    }

    if (ret) {
      // modify the information:
      if (info->flags & IMGINFO_PHOTOINTERP)
        set_string_element(TAG_PHOTOMETRIC_INTERPRETATION, "CS",
                           info->photo_interpretation, true);

      // get the photmetric interpretation:
      std::string photo;
      get_string_element(photo, TAG_PHOTOMETRIC_INTERPRETATION, "CS");

      onis::string convert;
      if (info->flags & IMGINFO_DIMENSIONS) {
        set_us_element(TAG_COLUMNS, info->width);
        set_us_element(TAG_ROWS, info->height);
      }

      if (photo != "MONOCHROME1" && photo != "MONOCHROME2" &&
          photo != "PALETTE COLOR") {
        photo = "RGB";
        set_string_element(TAG_PHOTOMETRIC_INTERPRETATION, "CS", photo, true);

        set_us_element(TAG_BITS_ALLOCATED, 8);
        set_us_element(TAG_BITS_STORED, 8);
        set_us_element(TAG_PIXEL_REPRESENTATION, 0);
        set_us_element(TAG_SAMPLES_PER_PIXEL, 3);
        set_us_element(TAG_HIGH_BIT, 7);
        set_us_element(TAG_PLANAR_CONFIGURATION, 0);
        if (info->flags & IMGINFO_PLANAR)
          set_us_element(TAG_PLANAR_CONFIGURATION,
                         (u16)onis::util::string::convert_to_u32(
                             info->planar_configuration));

        // remove the window level values:
        elt = _file->getDataset()->remove(DCM_WindowCenter);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_WindowWidth);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_RescaleIntercept);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_RescaleSlope);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_RescaleType);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_WindowCenterWidthExplanation);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_VOILUTFunction);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_LUTDescriptor);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_LUTExplanation);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_ModalityLUTType);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_LUTData);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_VOILUTSequence);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_SoftcopyVOILUTSequence);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_SmallestImagePixelValue);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_LargestImagePixelValue);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_SmallestPixelValueInSeries);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_LargestPixelValueInSeries);
        if (elt)
          delete elt;
        // elt =
        // _file->getDataset()->remove(DCM_SmallestImagePixelValueInPlane); if
        // (elt) delete elt; elt =
        // _file->getDataset()->remove(DCM_LargestImagePixelValueInPlane); if
        // (elt) delete elt;

        // remove color palette LUTs (if any)
        elt = _file->getDataset()->remove(DCM_PaletteColorLookupTableUID);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(
            DCM_RedPaletteColorLookupTableDescriptor);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(
            DCM_GreenPaletteColorLookupTableDescriptor);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(
            DCM_BluePaletteColorLookupTableDescriptor);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_RedPaletteColorLookupTableData);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_GreenPaletteColorLookupTableData);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(DCM_BluePaletteColorLookupTableData);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(
            DCM_SegmentedRedPaletteColorLookupTableData);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(
            DCM_SegmentedGreenPaletteColorLookupTableData);
        if (elt)
          delete elt;
        elt = _file->getDataset()->remove(
            DCM_SegmentedBluePaletteColorLookupTableData);
        if (elt)
          delete elt;

      } else {
        if (info->flags & IMGINFO_BITS) {
          set_us_element(TAG_BITS_ALLOCATED, info->bits_alloc);
          set_us_element(TAG_BITS_STORED, info->bits_stored);
          set_us_element(TAG_PIXEL_REPRESENTATION, info->pixel_representation);
          set_us_element(TAG_SAMPLES_PER_PIXEL, info->sample_per_pixel);
          set_us_element(TAG_HIGH_BIT, info->high_bit);
        }

        if (info->flags & IMGINFO_RESCALE) {
          if (!info->rescale_intercept.empty())
            set_string_element(TAG_RESCALE_INTERCEPT, "DS",
                               info->rescale_intercept, true);
          else
            set_string_element(TAG_RESCALE_INTERCEPT, "DS", "0", true);
          if (!info->rescale_slope.empty())
            set_string_element(TAG_RESCALE_SLOPE, "DS", info->rescale_slope,
                               true);
          else
            set_string_element(TAG_RESCALE_SLOPE, "DS", "1", true);
          if (!info->rescale_type.empty())
            set_string_element(TAG_RESCALE_TYPE, "LO", info->rescale_type,
                               true);
          else
            set_string_element(TAG_RESCALE_TYPE, "LO", "", true);
        }

        if (info->flags & IMGINFO_PIXEL_PADDING) {
          if (!info->pixel_padding_value.empty()) {
            u16 value = (u16)onis::util::string::convert_to_u32(
                info->pixel_padding_value);
            set_us_element(TAG_PIXEL_PADDING_VALUE, value);
          }
        }

        if (photo == "PALETTE COLOR") {
          for (std::int32_t color = 0; color < 3; color++) {
            std::string descriptor;
            std::int32_t tag_desc;
            std::int32_t tag_data;
            std::int32_t palette_length = 0;
            u8* palette_data = nullptr;

            switch (color) {
              case 0:
                descriptor = info->red_palette_desc;
                tag_desc = TAG_RED_PALETTE_COLOR_LOOKUP_TABLE_DESCRIPTOR;
                tag_data = TAG_RED_PALETTE_COLOR_LOOKUP_TABLE_DATA;
                palette_length = info->red_palette_data_count;
                palette_data = info->red_palette_data;
                break;

              case 1:
                descriptor = info->green_palette_desc;
                tag_desc = TAG_GREEN_PALETTE_COLOR_LOOKUP_TABLE_DESCRIPTOR;
                tag_data = TAG_GREEN_PALETTE_COLOR_LOOKUP_TABLE_DATA;
                palette_length = info->green_palette_data_count;
                palette_data = info->green_palette_data;
                break;

              case 2:
                descriptor = info->blue_palette_desc;
                tag_desc = TAG_BLUE_PALETTE_COLOR_LOOKUP_TABLE_DESCRIPTOR;
                tag_data = TAG_BLUE_PALETTE_COLOR_LOOKUP_TABLE_DATA;
                palette_length = info->blue_palette_data_count;
                palette_data = info->blue_palette_data;
                break;

              default:
                break;
            };

            u16 descriptor_value[3];
            bool palette_ok = true;
            if (!descriptor.empty()) {
              std::size_t pos = descriptor.find("\\");
              if (pos == std::string::npos)
                palette_ok = false;
              else {
                std::string left = descriptor.substr(0, pos);
                std::string right = descriptor.substr(pos + 1);
                descriptor_value[0] = onis::util::string::convert_to_u32(left);

                std::size_t pos = right.find("\\");
                if (pos == std::string::npos)
                  palette_ok = false;
                else {
                  left = right.substr(0, pos);
                  right = right.substr(pos + 1);
                  descriptor_value[1] =
                      onis::util::string::convert_to_u32(left);
                  descriptor_value[2] =
                      onis::util::string::convert_to_u32(right);
                }
              }
            }

            if (palette_ok && palette_data) {
              set_binary_value(tag_desc, "US", 3 * sizeof(s16),
                               (u8*)&descriptor_value[0], true);
              set_binary_value(tag_data, "OW", palette_length, palette_data,
                               true);
            }
          }
        }
      }
    }

    // insert the image:
    if (ret) {
      // insert the pixel data:
      OFCondition status = _file->getDataset()->putAndInsertUint8Array(
          DCM_PixelData, info->pixels, info->length);
      if (!status.good())
        ret = false;
      else {
        std::string convert =
            boost::str(boost::format("%d") % info->frame_count);
        _file->getDataset()->putAndInsertString(DCM_NumberOfFrames,
                                                convert.data());
        _file->getDataset()->putAndInsertUint16(DCM_RepresentativeFrameNumber,
                                                1);
      }
    }
  }
  _mutex.unlock();*/
  return ret;
}

bool dicom_dcmtk_file::modify_transfer_syntax(
    E_TransferSyntax new_transfer_syntax) {
  bool ret = false;
  _mutex.lock();
  if (_file != nullptr) {
    std::string current_transfer;
    get_string_element(current_transfer, TAG_TRANSFER_SYNTAX_UID, "UI");
    if (current_transfer.empty())
      current_transfer = UID_LittleEndianImplicitTransferSyntax;

    std::int32_t compression;
    E_TransferSyntax dcmtk_transfer =
        get_transfer_syntax_from_name(current_transfer, &compression);
    if (dcmtk_transfer == -1) {
      _mutex.unlock();
      return false;
    }
    if (dcmtk_transfer == new_transfer_syntax) {
      _mutex.unlock();
      return true;
    }

    // modify the tranfer syntax:
    // modify the file in a stream:
    struct STMPBUF {
      STMPBUF() {
        data = nullptr;
        length = 0;
      }
      ~STMPBUF() {
        if (data)
          delete[] data;
      }
      std::uint8_t* data;
      std::uint32_t length;
    };
    std::list<STMPBUF*> list_copy;
    bool written = false;
    std::uint8_t buf[2048];

    DcmOutputBufferStream streamout(buf, 2048);
    _file->getDataset()->transferInit();
    bool finish = false;
    ret = true;
    while (!finish) {
      if (!written) {
        OFCondition status = _file->getDataset()->write(
            streamout, EXS_LittleEndianImplicit, EET_UndefinedLength, nullptr);
        if (status == EC_Normal)
          written = true;
        else if (status == EC_StreamNotifyClient) {
        } else {
          ret = false;
          finish = true;
        }
      }

      if (ret) {
        if (written)
          streamout
              .flush();  // flush stream including embedded compression codec.
                         // get buffer and its length, assign to local variable
        offile_off_t length;
        void* full_buf = nullptr;
        streamout.flushBuffer(full_buf, length);
        finish = written && streamout.isFlushed();
        if (length > 0) {
          // ui_Length could be odd
          if (length & 1) {
            // this should only happen if we use a stream compressed transfer
            // syntax and then only at the very end of the stream. Everything
            // else is a failure.
            if (!finish)
              return false;
            // since the block size is always even, block size must be larger
            // than rtnLength, so we can safely add a pad byte (and hope that
            // the pad byte will not confuse the receiver's decompressor).
            unsigned char* cbuf = (unsigned char*)full_buf;
            cbuf[length++] = 0;  // add zero pad byte
          }
          // save the data:
          std::uint8_t* tmp = new std::uint8_t[length];
          memcpy(tmp, (std::uint8_t*)full_buf, length);
          STMPBUF* up_new = new STMPBUF;
          up_new->data = tmp;
          up_new->length = (std::uint32_t)length;
          list_copy.push_back(up_new);
        }
      }
    }
    _file->getDataset()->transferEnd();

    DcmInputBufferStream streamin;
    if (streamin.good()) {
      _file->clear();
      _file->transferInit();
      OFCondition status = EC_Normal;
      std::list<STMPBUF*>::iterator it;
      for (it = list_copy.begin(); it != list_copy.end(); it++) {
        STMPBUF* tmp = *it;
        /* make the stream remember any unread bytes */
        streamin.releaseBuffer();
        streamin.setBuffer(tmp->data, tmp->length);

        std::list<STMPBUF*>::iterator it2 = it;
        it2++;
        if (it2 == list_copy.end())
          streamin.setEos();
        status = _file->read(streamin, new_transfer_syntax);
        if (status != EC_Normal && status != EC_StreamNotifyClient) {
          ret = false;
          break;
        }
      }
      _file->transferEnd();

    } else
      ret = false;

    // clean up:
    std::list<STMPBUF*>::iterator it;
    for (it = list_copy.begin(); it != list_copy.end(); it++)
      delete *it;
    list_copy.clear();
  }
  _mutex.unlock();
  return ret;
}

//-----------------------------------------------------------------------
// mpeg streaming
//-----------------------------------------------------------------------
bool dicom_dcmtk_file::start_streaming() {
  bool ret = false;
  /*_mutex.lock();
  if (_file != nullptr && _stream_file_path.empty()) {

  std::string transfer_syntax;
  get_string_element(transfer_syntax, TAG_TRANSFER_SYNTAX_UID, "UI");
  if (transfer_syntax == "1.2.840.10008.1.2.4.100" || transfer_syntax ==
  "1.2.840.10008.1.2.4.101" || transfer_syntax == "1.2.840.10008.1.2.4.102" ||
  transfer_syntax == "1.2.840.10008.1.2.4.103") {

  std::uint64_t start, stop;
  if (!get_pixel_data_positions(&start, &stop)) {

  _stream_file_path = _app->create_temporary_file_name();
  if (!_stream_file_path.empty()) {

  _stream_file = onis::file::open_file(_stream_file_path,
  onis::fflags::read_write | onis::fflags::create | onis::fflags::binary |
  onis::fflags::no_share_deny); if (_stream_file == nullptr)
  _stream_file_path.clear(); else {

  _stream_result.status = OSRSP_WAITING;
  _stream_len = 0;
  ret = true;

  }

  }

  }

  }

  }
  _mutex.unlock();*/
  return ret;
}

bool dicom_dcmtk_file::stop_streaming() {
  bool ret = false;
  /*_mutex.lock();
  if (_stream_file != nullptr) {

  _stream_file->close();
  _stream_file.reset();
  _stream_result = result;
  ret = true;

  }
  _mutex.unlock();*/
  return ret;
}

bool dicom_dcmtk_file::add_streaming_data(std::uint8_t* data, std::uint32_t len,
                                          std::uint64_t total_expected) {
  bool ret = false;

  /*_mutex.lock();
  if (_stream_file != nullptr) {

  if (total_expected != -1) _stream_expected_len = total_expected;
  if (len > 0) {

  std::uint32_t copy = _stream_file->write(data, len);
  if (copy > 0) _stream_len += copy;
  if (copy == len) ret = true;
  else {

  //_stream_result.status = OSRSP_FAILURE;
  //_stream_result.reason = EOS_FILE_WRITE;

  }

  }

  }
  _mutex.unlock();*/
  return ret;
}

bool dicom_dcmtk_file::is_streaming() {
  bool ret = false;
  /*_mutex.lock();
  if (_stream_file != nullptr) ret = true;
  _mutex.unlock();*/
  return ret;
}

bool dicom_dcmtk_file::streaming_is_complete() {
  bool ret = false;
  /*_mutex.lock();
  if (_stream_file == nullptr) {

  if (_stream_result.status != OSRSP_PENDING)
  ret = true;

  }
  _mutex.unlock();*/
  return ret;
}

std::uint64_t dicom_dcmtk_file::get_stream_data_len() {
  /*_mutex.lock();
  std::uint64_t ret = _stream_len;
  _mutex.unlock();
  return ret;*/
  return 0;
}

std::uint64_t dicom_dcmtk_file::get_stream_data_expected_len() {
  /*_mutex.lock();
  std::uint64_t ret = _stream_expected_len;
  _mutex.unlock();
  return ret;*/
  return 0;
}

std::uint32_t dicom_dcmtk_file::get_stream_bit_rate() {
  /*_mutex.lock();
  std::uint32_t ret = _stream_bit_rate;
  _mutex.unlock();
  return ret;*/
  return 0;
}

void dicom_dcmtk_file::set_stream_bit_rate(std::uint32_t rate) {
  /*_mutex.lock();
  _stream_bit_rate = rate;
  _mutex.unlock();*/
}

onis::file_ptr dicom_dcmtk_file::get_streaming_file() {
  /*if (!_stream_file_path.empty()) {

  onis::file_ptr fp = onis::file::open_file(_stream_file_path,
  onis::fflags::read | onis::fflags::binary | onis::fflags::no_share_deny);
  return fp;

  }*/
  return onis::file_ptr();
}

void dicom_dcmtk_file::get_streaming_status() {
  /*_mutex.lock();
  result = _stream_result;
  _mutex.unlock();*/
}

//-----------------------------------------------------------------------
// mpeg frame
//-----------------------------------------------------------------------
bool dicom_dcmtk_file::is_mpeg_frame() {
  _mutex.lock();
  bool ret = is_mpeg_frame_;
  _mutex.unlock();
  return ret;
}

/*onis::bitmap_ptr odicom_file::update_mpeg_frame(const onis::bitmap_ptr& bmp,
                                                bool can_retain) {
  onis::bitmap_ptr ret;
  _mutex.lock();

  ret = _mpeg_bmp;
  if (can_retain)
    _mpeg_bmp = bmp;
  else {
    if (bmp != nullptr)
      _mpeg_bmp = bmp->clone();
    else
      _mpeg_bmp.reset();
  }

  _is_mpeg_frame = true;

  _mutex.unlock();
  return ret;
}

onis::bitmap_ptr odicom_file::get_mpeg_frame(bool copy) {
  onis::bitmap_ptr ret;
  _mutex.lock();
  if (_is_mpeg_frame) {
    if (_mpeg_bmp != nullptr)
      ret = _mpeg_bmp->clone();
  }
  _mutex.unlock();
  return ret;
}*/

E_TransferSyntax dicom_dcmtk_file::get_transfer_syntax_from_name(
    const std::string& name, std::int32_t* compression) {
  *compression = CPR_DCM_NOCOMPRESS;
  if (name == UID_LittleEndianImplicitTransferSyntax)
    return EXS_LittleEndianImplicit;
  else if (name == UID_LittleEndianExplicitTransferSyntax)
    return EXS_LittleEndianExplicit;
  else if (name == UID_BigEndianExplicitTransferSyntax)
    return EXS_BigEndianExplicit;
  else if (name == UID_JPEGProcess1TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess1TransferSyntax;
  } else if (name == UID_JPEGProcess2_4TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess2_4TransferSyntax;
  } else if (name == UID_JPEGProcess3_5TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess3_5TransferSyntax;
  } else if (name == UID_JPEGProcess6_8TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess6_8TransferSyntax;
  } else if (name == UID_JPEGProcess7_9TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess7_9TransferSyntax;
  } else if (name == UID_JPEGProcess10_12TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess10_12TransferSyntax;
  } else if (name == UID_JPEGProcess11_13TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess11_13TransferSyntax;
  } else if (name == UID_JPEGProcess14TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess14TransferSyntax;
  } else if (name == UID_JPEGProcess15TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess15TransferSyntax;
  } else if (name == UID_JPEGProcess16_18TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess16_18TransferSyntax;
  } else if (name == UID_JPEGProcess17_19TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess17_19TransferSyntax;
  } else if (name == UID_JPEGProcess20_22TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess20_22TransferSyntax;
  } else if (name == UID_JPEGProcess21_23TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess21_23TransferSyntax;
  } else if (name == UID_JPEGProcess24_26TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess24_26TransferSyntax;
  } else if (name == UID_JPEGProcess25_27TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess25_27TransferSyntax;
  } else if (name == UID_JPEGProcess28TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess28TransferSyntax;
  } else if (name == UID_JPEGProcess29TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess29TransferSyntax;
  } else if (name == UID_JPEGProcess14SV1TransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGProcess14SV1TransferSyntax;
  } else if (name == UID_RLELosslessTransferSyntax) {
    *compression = CPR_DCM_RLELS;
    return EXS_RLELossless;
  } else if (name == UID_JPEGLSLosslessTransferSyntax) {
    *compression = CPR_DCM_JPEGLS;
    return EXS_JPEGLSLossless;
  } else if (name == UID_JPEGLSLossyTransferSyntax) {
    *compression = CPR_DCM_JPEG;
    return EXS_JPEGLSLossy;
  } else if (name == UID_DeflatedExplicitVRLittleEndianTransferSyntax)
    return EXS_DeflatedLittleEndianExplicit;
  else if (name == UID_JPEG2000LosslessOnlyTransferSyntax) {
    *compression = CPR_DCM_JPEG2000LS;
    return EXS_JPEG2000LosslessOnly;
  } else if (name == UID_JPEG2000TransferSyntax) {
    *compression = CPR_DCM_JPEG2000;
    return EXS_JPEG2000;
  } else if (name == UID_MPEG2MainProfileAtMainLevelTransferSyntax) {
    *compression = CPR_DCM_MPEG;
    return EXS_MPEG2MainProfileAtMainLevel;
  } else if (
      name ==
      UID_JPEG2000Part2MulticomponentImageCompressionLosslessOnlyTransferSyntax) {
    *compression = 3;
    return EXS_JPEG2000MulticomponentLosslessOnly;
  } else if (name ==
             UID_JPEG2000Part2MulticomponentImageCompressionTransferSyntax) {
    *compression = 3;
    return EXS_JPEG2000Multicomponent;
  } else if (name == UID_MPEG4HighProfileLevel4_1TransferSyntax) {
    *compression = CPR_DCM_MPEG;
    return EXS_MPEG4HighProfileLevel4_1;
  } else if (name == UID_MPEG4BDcompatibleHighProfileLevel4_1TransferSyntax) {
    *compression = CPR_DCM_MPEG;
    return EXS_MPEG4BDcompatibleHighProfileLevel4_1;
  } else
    return EXS_Unknown;
}

///////////////////////////////////////////////////////////////////////
// odicom_manager
///////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------
// static creator
//-----------------------------------------------------------------------

onis::dicom_manager_ptr dicom_dcmtk_manager::create() {
  return std::make_shared<dicom_dcmtk_manager>();
}

//-----------------------------------------------------------------------
// constructor
//-----------------------------------------------------------------------

dicom_dcmtk_manager::dicom_dcmtk_manager() : onis::dicom_manager() {
  init_character_set();
}

//-----------------------------------------------------------------------
// destructor
//-----------------------------------------------------------------------

dicom_dcmtk_manager::~dicom_dcmtk_manager() {
  for (auto charset : charsets) {
    delete charset;
  }
}

//-----------------------------------------------------------------------
// dicom objects
//-----------------------------------------------------------------------

onis::dicom_file_ptr dicom_dcmtk_manager::create_dicom_file() const {
  // shared_from_this() in const method returns shared_ptr<const T>
  // Need to cast to non-const for the create function
  return dicom_dcmtk_file::create(
      std::const_pointer_cast<onis::dicom_manager>(shared_from_this()));
}

onis::dicom_dataset_ptr dicom_dcmtk_manager::create_dicom_dataset() const {
  // shared_from_this() in const method returns shared_ptr<const T>
  // Need to cast to non-const for the create function
  return dicom_dcmtk_dataset::create(
      std::const_pointer_cast<onis::dicom_manager>(shared_from_this()));
}

// onis::dicom_dir_ptr dicom_dcmtk_manager::create_dicom_dir() const {
//  DICOM directory creation not yet implemented
//  return nullptr;
//}

//-----------------------------------------------------------------------
// character sets
//-----------------------------------------------------------------------

const onis::dicom_charset* dicom_dcmtk_manager::find_character_set_by_code(
    const std::string& code) const {
  for (auto charset : charsets) {
    if (charset->code == code)
      return charset;
  }
  return nullptr;
}

const onis::dicom_charset* dicom_dcmtk_manager::find_character_set_by_escape(
    const std::string& escape, const onis::dicom_charset_info** info,
    bool* g0) const {
  for (auto charset : charsets) {
    for (auto charset_info : charset->info) {
      if (escape == charset_info->esc_g0) {
        if (g0)
          *g0 = true;
        if (info)
          *info = charset_info;
        return charset;
      } else if (escape == charset_info->esc_g1) {
        if (g0)
          *g0 = false;
        if (info)
          *info = charset_info;
        return charset;
      }
    }
  }
  return nullptr;
}

const onis::dicom_charset*
dicom_dcmtk_manager::find_character_set_by_iso_number(
    const std::string& number, const onis::dicom_charset_info** info) const {
  for (auto charset : charsets) {
    for (auto charset_info : charset->info) {
      if (charset_info->defined_term == number ||
          charset_info->no_extention_term == number) {
        if (info)
          *info = charset_info;
        return charset;
      }
    }
  }
  return nullptr;
}

const onis::dicom_charset* dicom_dcmtk_manager::find_character_set_by_info(
    const onis::dicom_charset_info* info) const {
  for (auto charset : charsets) {
    for (auto charset_info : charset->info) {
      if (charset_info == info) {
        return charset;
      }
    }
  }
  return nullptr;
}

const onis::dicom_charset_list* dicom_dcmtk_manager::get_character_set_list()
    const {
  return &charsets;
}

const onis::dicom_charset* dicom_dcmtk_manager::get_default_character_set()
    const {
  return charsets.front();
}

std::string dicom_dcmtk_manager::build_escape(std::uint8_t v1, std::uint8_t v2,
                                              std::uint8_t v3) {
  std::string res;
  res += 0x1B;
  res += v1;
  res += v2;
  if (v3 != 0)
    res += v3;
  return res;
}

void dicom_dcmtk_manager::init_character_set() {
  add_charset("DEFAULT", "Default", "", "ISO 2022 IR 6", true,
              build_escape(0x28, 0x42), "", "ISO-IR-6");
  add_charset("LATIN1", "Latin 1", "ISO_IR 100", "ISO 2022 IR 100", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x41), "ISO-IR-100");
  add_charset("LATIN2", "Latin 2", "ISO_IR 101", "ISO 2022 IR 101", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x42), "ISO-IR-101");
  add_charset("LATIN3", "Latin 3", "ISO_IR 109", "ISO 2022 IR 109", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x43), "ISO-IR-109");
  add_charset("LATIN4", "Latin 4", "ISO_IR 110", "ISO 2022 IR 110", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x44), "ISO-IR-110");
  add_charset("LATIN5", "Latin 5", "ISO_IR 148", "ISO 2022 IR 148", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x4D), "ISO-IR-148");
  add_charset("CYRILLIC", "Cyrillic", "ISO_IR 144", "ISO 2022 IR 144", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x4C), "ISO-IR-144");
  add_charset("ARABIC", "Arabic", "ISO_IR 127", "ISO 2022 IR 127", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x47), "ISO-IR-127");
  add_charset("GREEK", "Greek", "ISO_IR 126", "ISO 2022 IR 126", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x46), "ISO-IR-126");
  add_charset("HEBREW", "Hebrew", "ISO_IR 138", "ISO 2022 IR 138", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x48), "ISO-IR-138");
  add_charset("THAI", "Thai", "ISO_IR 166", "ISO 2022 IR 166", true,
              build_escape(0x28, 0x42), build_escape(0x2D, 0x54), "ISO-IR-166");

  onis::dicom_charset* set = add_charset(
      "JAPANESE", "Japanese", "ISO_IR 13", "ISO 2022 IR 13", true,
      build_escape(0x28, 0x4A), build_escape(0x29, 0x49), "ISO-IR-13");
  add_charset_info(set, "ISO_IR 87", "ISO 2022 IR 87", false,
                   build_escape(0x24, 0x42),
                   "" /*build_escape(0x24, 0x29, 0x42)*/, "ISO-IR-87");
  add_charset_info(set, "ISO_IR 159", "ISO 2022 IR 159", false,
                   build_escape(0x24, 0x28, 0x44),
                   "" /*build_escape(0x24, 0x29, 0x44)*/, "ISO-IR-159");
  add_charset("UNICODE", "Unicode", "ISO_IR 192", "ISO 2022 IR 192", false, "",
              "", "UTF-8");
}

onis::dicom_charset* dicom_dcmtk_manager::add_charset(
    const std::string& code, const std::string& name,
    const std::string& no_ext_term, const std::string& ext_term,
    bool single_byte, const std::string& g0, const std::string& g1,
    const std::string& code_page) {
  onis::dicom_charset* set = new onis::dicom_charset;
  set->code = code;
  set->name = name;
  add_charset_info(set, no_ext_term, ext_term, single_byte, g0, g1, code_page);
  charsets.push_back(set);
  return set;
}
void dicom_dcmtk_manager::add_charset_info(
    onis::dicom_charset* set, const std::string& no_ext_term,
    const std::string& ext_term, bool single_byte, const std::string& g0,
    const std::string& g1, const std::string& code_page) {
  onis::dicom_charset_info* info = new onis::dicom_charset_info();
  info->defined_term = ext_term;
  info->no_extention_term = no_ext_term;
  info->single_byte = single_byte;
  info->esc_g0 = g0;
  info->esc_g1 = g1;
  info->code_page = code_page;
  set->info.push_back(info);
}

//-----------------------------------------------------------------------
// utilities
//-----------------------------------------------------------------------

void dicom_dcmtk_manager::create_instance_uid(std::int32_t level,
                                              std::string& uid) const {
  uid = "1.2.392.200193";
  switch (level) {
    case 0:
      uid += ".1.";
      break;
    case 1:
      uid += ".2.";
      break;
    case 2:
      uid += ".3.";
      break;
    case 3:
      uid += ".4.";
      break;
    default:
      uid += ".5.";
      break;
  };

  // Use standard C++ random number generation
  std::random_device rng;
  std::uniform_int_distribution<std::size_t> index_dist(0,
                                                        9);  // 0-9 for digits
  std::string chars("1234567890");

  // Generate first 10 random digits
  for (std::int32_t i = 0; i < 10; i++)
    uid += chars[index_dist(rng)];

  // get today date:
  onis::core::date_time dt;
  dt.init_current_time();

  // Format date as YYYYMMDD using standard C++
  std::ostringstream date_oss;
  date_oss << "." << std::setfill('0') << std::setw(4) << dt.year()
           << std::setw(2) << dt.month() << std::setw(2) << dt.day();
  uid += date_oss.str();

  // process the time:
  std::ostringstream time_oss;
  time_oss << "." << std::setfill('0') << std::setw(2) << dt.hour()
           << std::setw(2) << dt.minute() << std::setw(2) << dt.second() << "."
           << dt.millisecond() << ".";
  uid += time_oss.str();

  // another random characters:
  for (std::int32_t i = 0; i < 10; i++)
    uid += chars[index_dist(rng)];
}
