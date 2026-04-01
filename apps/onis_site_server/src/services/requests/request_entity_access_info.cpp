#include "../../../include/services/requests/request_entity_access_info.hpp"
#include "../../../include/database/items/db_item.hpp"
#include "onis_kit/include/core/exception.hpp"

////////////////////////////////////////////////////////////////////////////////
// site_database_entity_access_info class
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

site_database_entity_access_info::site_database_entity_access_info(
    const std::string& partition_seq, const std::string album_seq,
    const std::string& patient_seq, const std::string& patient_id,
    const std::string& study_seq, const std::string& study_uid,
    const std::string& series_seq, const std::string& series_uid,
    const std::string& image_seq, const std::string& image_uid) {
  _partition_seq = partition_seq;
  _album_seq = album_seq;
  _patient_id = patient_id;
  _study_uid = study_uid;
  _series_uid = series_uid;
  _image_uid = image_uid;
  _patient_seq = patient_seq;
  _study_seq = study_seq;
  _series_seq = series_seq;
  _image_seq = image_seq;

  patient = nullptr;
  study = nullptr;
  series = nullptr;
  image = nullptr;

  patient_link = nullptr;
  study_link = nullptr;
  series_link = nullptr;
  image_link = nullptr;

  patient_links = Json::Value(Json::arrayValue);
  study_links = Json::Value(Json::arrayValue);
  series_links = Json::Value(Json::arrayValue);
  image_links = Json::Value(Json::arrayValue);
}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

site_database_entity_access_info::~site_database_entity_access_info() {
  delete patient;
  delete study;
  delete series;
  delete image;

  delete patient_link;
  delete study_link;
  delete series_link;
  delete image_link;
}

//------------------------------------------------------------------------------
// operations:
//------------------------------------------------------------------------------

void site_database_entity_access_info::find(const request_database& db,
                                            onis::database::lock_mode lock_mode,
                                            std::uint32_t patient_flags,
                                            std::uint32_t study_flags,
                                            std::uint32_t series_flags,
                                            std::uint32_t image_flags) {
  // to reduce the risk of deadlock, we always lock the entities before the
  // links and always from patient to image.

  // patient seq is mandatory
  if (_patient_seq.empty())
    throw onis::exception(EOS_PARAM, "Patient seq is mandatory");

  // if the study seq is provided, the patient seq must also be provided:
  if (!_study_seq.empty() && _patient_seq.empty())
    throw onis::exception(EOS_PARAM, "Study seq is mandatory");

  // if the series seq is provided, the study seq must also be provided:
  if (!_series_seq.empty() && _study_seq.empty())
    throw onis::exception(EOS_PARAM, "Series seq is mandatory");

  // if the image seq is provided, the series seq must also be provided:
  if (!_image_seq.empty() && _series_seq.empty())
    throw onis::exception(EOS_PARAM, "Image seq is mandatory");

  // now, we search the items from the database:

  if (_album_seq.empty()) {
    std::string patient_partition_seq;
    std::string study_patient_seq;
    std::string series_study_seq;
    std::string image_series_seq;

    // find the patient:
    patient = new Json::Value(Json::objectValue);
    db->find_patient_by_seq(_patient_seq, patient_flags, false, lock_mode,
                            *patient, &patient_partition_seq);
    /*if (lock_mode != onis::db::nolock)
      db->get_partition_patient_links(_patient_seq, lock_mode, patient_links,
                                      res);*/

    // find the study:
    if (!_study_seq.empty()) {
      study = new Json::Value(Json::objectValue);
      db->find_study_by_seq(_study_seq, study_flags, false, lock_mode, *study,
                            &study_patient_seq);
      /*if (lock_mode != onis::db::nolock)
        db->get_partition_study_links(_study_seq, lock_mode, study_links,
        res);*/
    }

    // find the series:
    if (!_series_seq.empty()) {
      series = new Json::Value(Json::objectValue);
      db->find_series_by_seq(_series_seq, series_flags, false, lock_mode,
                             *series, &series_study_seq);
      /*if (lock_mode != onis::db::nolock)
        db->get_partition_series_links(_series_seq, lock_mode, study_links,
                                       res);*/
    }

    // find the image:
    if (!_image_seq.empty()) {
      image = new Json::Value(Json::objectValue);
      db->find_image_by_seq(_image_seq, image_flags, false, lock_mode, *image,
                            &image_series_seq);
      /*if (lock_mode != onis::db::nolock)
        db->get_partition_image_links(_image_seq, lock_mode, study_links,
        res);*/
    }

    // verify:

    bool valid = true;
    if (patient == nullptr)
      valid = false;
    else if (study == nullptr && !_study_seq.empty())
      valid = false;
    else if (series == nullptr && !_series_seq.empty())
      valid = false;
    else if (image == nullptr && !_image_seq.empty())
      valid = false;
    else if (image != nullptr && image_series_seq != _series_seq)
      valid = false;
    else if (series != nullptr && series_study_seq != _study_seq)
      valid = false;
    else if (study != nullptr && study_patient_seq != _patient_seq)
      valid = false;
    else if (patient != nullptr && patient_partition_seq != _partition_seq)
      valid = false;
    else if (!_image_uid.empty() && image != nullptr &&
             (*image)[BASE_UID_KEY].asString() != _image_uid)
      valid = false;
    else if (!_series_uid.empty() && series != nullptr &&
             (*series)[BASE_UID_KEY].asString() != _series_uid)
      valid = false;
    else if (!_study_uid.empty() && study != nullptr &&
             (*study)[BASE_UID_KEY].asString() != _study_uid)
      valid = false;
    else if (!_patient_id.empty() && patient != nullptr &&
             (*patient)[BASE_UID_KEY].asString() != _patient_id)
      valid = false;
    if (!valid) {
      throw onis::exception(EOS_PARAM, "Invalid entity access info");
    }
  } else {
    // data comes from an album.
    // first, we retrieve an lock the patient pointed by the patient link:
    /*if (patient)
      delete patient;
    patient = new Json::Value(Json::objectValue);
    onis::astring patient_partition_seq;
    db->get_partition_patient_from_link(_patient_seq, patient_flags, lock_mode,
                                        *patient, &patient_partition_seq, res);
    // then we retrieve the patient link:
    if (patient_link)
      delete patient_link;
    patient_link = new Json::Value(Json::objectValue);
    db->find_partition_patient_link_by_seq(_patient_seq, lock_mode,
                                           *patient_link, res);
    // make sure the patient link comes from the right album:
    if (patient_link && (*patient_link)[PPL_ALBUM_KEY].asString() != _album_seq)
      res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);

    // then we lock the study.
    if (res.good() && !_study_seq.empty()) {
      if ((*patient_link)[PPL_ALL_STUDIES_KEY].asInt() == 0) {
        // the patient link does not display all the study. We should have a
        // study link for the study. first we lock the study pointed by the
        // study link:
        if (study)
          delete study;
        study = new Json::Value(Json::objectValue);
        onis::astring study_patient_seq;
        db->get_partition_study_from_link(_study_seq, study_flags, lock_mode,
                                          *study, &study_patient_seq, res);
        // make sure the study belongs to the patient:
        if (study_patient_seq != (*patient)[BASE_SEQ_KEY].asString())
          res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);
        // then we retrieve the study link:
        if (study_link)
          delete study_link;
        study_link = new Json::Value(Json::objectValue);
        db->find_partition_study_link_by_seq(_study_seq, lock_mode, *study_link,
                                             res);
        // make sure the study link belongs to the patient link:
        if (study_link && (*study_link)[PSTL_PARENT_SEQ_KEY].asString() !=
                              (*patient_link)[BASE_SEQ_KEY].asString())
          res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);

      } else {
        // the patient link displays all the studies, there are no study link
        // associated with the study:
        if (study)
          delete study;
        study = new Json::Value(Json::objectValue);
        onis::astring study_patient_seq;
        db->find_study_by_seq(_study_seq, study_flags, OSFALSE, lock_mode,
                              *study, &study_patient_seq, res);
        if (study_patient_seq != (*patient)[BASE_SEQ_KEY].asString())
          res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);
      }
    }

    // the we lock the series:
    if (res.good() && !_series_seq.empty()) {
      if (study_link && (*study_link)[PSTL_ALL_SERIES_KEY].asInt() == 0) {
        // the study link does not display all the series. We should have a
        // series link for the series. first we lock the series pointed by the
        // series link:
        if (series)
          delete series;
        series = new Json::Value(Json::objectValue);
        onis::astring series_study_seq;
        db->get_partition_series_from_link(_series_seq, series_flags, lock_mode,
                                           *series, &series_study_seq, res);
        // make sure the series belongs to the study:
        if (series_study_seq != (*study)[BASE_SEQ_KEY].asString())
          res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);
        // then we retrieve the series link:
        if (series_link)
          delete series_link;
        series_link = new Json::Value(Json::objectValue);
        db->find_partition_series_link_by_seq(_series_seq, lock_mode,
                                              *series_link, res);
        // make sure the series link belongs to the study link:
        if (series_link && (*series_link)[PSRL_PARENT_SEQ_KEY].asString() !=
                               (*study_link)[BASE_SEQ_KEY].asString())
          res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);

      } else {
        // there are no series link associated with the series:
        if (series)
          delete series;
        series = new Json::Value(Json::objectValue);
        onis::astring series_study_seq;
        db->find_series_by_seq(_series_seq, series_flags, OSFALSE, lock_mode,
                               *series, &series_study_seq, res);
        if (series_study_seq != (*study)[BASE_SEQ_KEY].asString())
          res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);
      }
    }

    // the we lock the image:
    if (res.good() && !_image_seq.empty()) {
      if (series_link && (*series_link)[PSRL_ALL_IMAGES_KEY].asInt() == 0) {
        // the series link does not display all the images. We should have an
        // image link for the image. first we lock the image pointed by the
        // image link:
        if (image)
          delete image;
        image = new Json::Value(Json::objectValue);
        onis::astring image_series_seq;
        db->get_partition_image_from_link(_image_seq, image_flags, lock_mode,
                                          *image, &image_series_seq, res);
        // make sure the series belongs to the study:
        if (image_series_seq != (*series)[BASE_SEQ_KEY].asString())
          res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);
        // then we retrieve the series link:
        if (image_link)
          delete image_link;
        image_link = new Json::Value(Json::objectValue);
        db->find_partition_image_link_by_seq(_image_seq, lock_mode, *image_link,
                                             res);
        // make sure the image link belongs to the series link:
        if (image_link && (*image_link)[PIML_PARENT_SEQ_KEY].asString() !=
                              (*series_link)[BASE_SEQ_KEY].asString())
          res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);

      } else {
        // there are no image link associated with the image:
        if (image)
          delete image;
        image = new Json::Value(Json::objectValue);
        onis::astring image_series_seq;
        db->find_image_by_seq(_image_seq, image_flags, OSFALSE, lock_mode,
                              *image, &image_series_seq, res);
        if (image_series_seq != (*series)[BASE_SEQ_KEY].asString())
          res.set(OSRSP_FAILURE, EOS_PARAM, "", OSFALSE);
      }
    }*/
  }
}

//-----------------------------------------------------------------------------
// utilities:
//-----------------------------------------------------------------------------

bool site_database_entity_access_info::image_belongs_to_patient_link(
    const Json::Value& patient_link, const std::string& image_seq) {
  return false;
}

bool site_database_entity_access_info::image_belongs_to_study_link(
    const Json::Value& study_link, const std::string& image_seq) {
  return false;
}

bool site_database_entity_access_info::image_belongs_to_series_link(
    const Json::Value& series_link, const std::string& image_seq) {
  return false;
}

bool site_database_entity_access_info::series_belongs_to_patient_link(
    const Json::Value& patient_link, const std::string& series_seq) {
  return false;
}

bool site_database_entity_access_info::series_belongs_to_study_link(
    const Json::Value& study_link, const std::string& series_seq) {
  return false;
}

bool site_database_entity_access_info::study_belongs_to_patient_link(
    const Json::Value& patient_link, const std::string& study_seq) {
  return false;
}

bool site_database_entity_access_info::is_series_link_child_of_study_link(
    const Json::Value& series_link, const Json::Value& study_link) {
  return false;
}

bool site_database_entity_access_info::is_study_link_child_of_patient_link(
    const Json::Value& study_link, const Json::Value& patient_link) {
  return false;
}
