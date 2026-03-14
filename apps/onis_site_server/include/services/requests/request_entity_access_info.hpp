#include "./request_database.hpp"

class site_database_entity_access_info {
public:
  site_database_entity_access_info(
      const std::string& partition_seq, const std::string album_seq,
      const std::string& patient_seq, const std::string& patient_id,
      const std::string& study_seq, const std::string& study_uid,
      const std::string& series_seq, const std::string& series_uid,
      const std::string& image_seq, const std::string& image_uid);

  // destructor:
  ~site_database_entity_access_info();

  // operations:
  void find(const request_database& db, onis::database::lock_mode lock_mode,
            std::uint32_t patient_flags, std::uint32_t study_flags,
            std::uint32_t series_flags, std::uint32_t image_flags);

  // utilities:
  bool image_belongs_to_patient_link(const Json::Value& patient_link,
                                     const std::string& image_seq);
  bool image_belongs_to_study_link(const Json::Value& study_link,
                                   const std::string& image_seq);
  bool image_belongs_to_series_link(const Json::Value& series_link,
                                    const std::string& image_seq);
  bool series_belongs_to_patient_link(const Json::Value& patient_link,
                                      const std::string& series_seq);
  bool series_belongs_to_study_link(const Json::Value& study_link,
                                    const std::string& series_seq);
  bool study_belongs_to_patient_link(const Json::Value& patient_link,
                                     const std::string& study_seq);
  bool is_series_link_child_of_study_link(const Json::Value& series_link,
                                          const Json::Value& study_link);
  bool is_study_link_child_of_patient_link(const Json::Value& study_link,
                                           const Json::Value& patient_link);

  Json::Value* patient;
  Json::Value* study;
  Json::Value* series;
  Json::Value* image;

  Json::Value patient_links;
  Json::Value study_links;
  Json::Value series_links;
  Json::Value image_links;

  Json::Value* patient_link;
  Json::Value* study_link;
  Json::Value* series_link;
  Json::Value* image_link;

protected:
  std::string _partition_seq;
  std::string _album_seq;
  std::string _patient_id;
  std::string _study_uid;
  std::string _series_uid;
  std::string _image_uid;
  std::string _patient_seq;
  std::string _study_seq;
  std::string _series_seq;
  std::string _image_seq;
};
