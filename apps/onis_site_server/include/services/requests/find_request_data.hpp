#pragma once

#include "request_data.hpp"

////////////////////////////////////////////////////////////////////////////////
// find_source struct
////////////////////////////////////////////////////////////////////////////////

struct find_source {
  std::string seq;
  std::string source_id;
  std::string name;
  std::int32_t type{-1};
  std::int32_t limit{500};
  bool reject_empty_request{true};
  std::int32_t have_conflict{0};
  std::string ip;
  std::int32_t port{0};
  std::string target_ae;
  std::string from_ae;
  std::string code_page;
  std::int32_t result{0};
};

////////////////////////////////////////////////////////////////////////////////
// find_request_data class
////////////////////////////////////////////////////////////////////////////////

class find_request_data : public request_data {
public:
  find_request_data() : request_data(request_type::kFindStudies) {}
  ~find_request_data() {}

  // members:
  std::vector<find_source> sources;
  std::int32_t current_index_source{-1};
};

using find_request_data_ptr = std::shared_ptr<find_request_data>;
