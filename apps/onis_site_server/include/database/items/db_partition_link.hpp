#pragma once

#include "db_item.hpp"

using json = Json::Value;

#define PPL_ALBUM_KEY "album"
#define PPL_PATIENT_KEY "patient"
#define PPL_ALL_STUDIES_KEY "all"
#define PPL_STCNT_KEY "stcnt"
#define PPL_SRCNT_KEY "srcnt"
#define PPL_IMCNT_KEY "imcnt"

#define PSTL_PARENT_SEQ_KEY "parent"
#define PSTL_STUDY_KEY "study"
#define PSTL_ALL_SERIES_KEY "all"
#define PSTL_MODALITIES_KEY "modalities"
#define PSTL_BODYPARTS_KEY "bodyparts"
#define PSTL_STATIONS_KEY "stations"
#define PSTL_SRCNT_KEY "srcnt"
#define PSTL_IMdbdCNT_KEY "imcnt"
#define PSTL_RPTCNT_KEY "rptcnt"

#define PSRL_PARENT_SEQ_KEY "parent"
#define PSRL_SERIES_KEY "series"
#define PSRL_ALL_IMAGES_KEY "all"
#define PSRL_IMCNT_KEY "imcnt"

#define PIML_PARENT_SEQ_KEY "parent"
#define PIML_IMAGE_KEY "image"

namespace onis::database {

struct partition_patient_link {
  static void create(json& link) {
    if (!link.isObject()) {
      throw std::invalid_argument("partition_patient_link is not an object");
    }
    link.clear();
    link[BASE_SEQ_KEY] = "";
    link[PPL_ALBUM_KEY] = "";
    link[PPL_PATIENT_KEY] = "";
    link[PPL_ALL_STUDIES_KEY] = 0;
    link[PPL_STCNT_KEY] = 0;
    link[PPL_SRCNT_KEY] = 0;
    link[PPL_IMCNT_KEY] = 0;
  }
};

struct partition_study_link {
  static void create(json& link) {
    if (!link.isObject()) {
      throw std::invalid_argument("partition_study_link is not an object");
    }
    link.clear();
    link[BASE_SEQ_KEY] = "";
    link[PSTL_PARENT_SEQ_KEY] = "";
    link[PSTL_STUDY_KEY] = "";
    link[PSTL_ALL_SERIES_KEY] = 0;
    link[PSTL_MODALITIES_KEY] = "";
    link[PSTL_BODYPARTS_KEY] = "";
    link[PSTL_STATIONS_KEY] = "";
    link[PSTL_SRCNT_KEY] = 0;
    link[PSTL_IMCNT_KEY] = 0;
    link[PSTL_RPTCNT_KEY] = 0;
  }
};

struct partition_series_link {
  static void create(json& link) {
    if (!link.isObject()) {
      throw std::invalid_argument("partition_series_link is not an object");
    }
    link.clear();
    link[BASE_SEQ_KEY] = "";
    link[PSRL_PARENT_SEQ_KEY] = "";
    link[PSRL_SERIES_KEY] = "";
    link[PSRL_ALL_IMAGES_KEY] = 0;
    link[PSRL_IMCNT_KEY] = 0;
  }
};

struct partition_image_link {
  static void create(json& link) {
    if (!link.isObject()) {
      throw std::invalid_argument("partition_image_link is not an object");
    }
    link.clear();
    link[BASE_SEQ_KEY] = "";
    link[PIML_PARENT_SEQ_KEY] = "";
    link[PIML_IMAGE_KEY] = "";
  }
};

}  // namespace onis::database
