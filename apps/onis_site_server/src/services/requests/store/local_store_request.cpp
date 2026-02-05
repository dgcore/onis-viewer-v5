#include "../../../../include/services/requests/store/local_store_request.hpp"

////////////////////////////////////////////////////////////////////////////////
// local_store_request class
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

local_store_request::local_store_request(const request_service_ptr& service)
    : service_(service) {}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------

local_store_request::~local_store_request() {}

//------------------------------------------------------------------------------
// init
//------------------------------------------------------------------------------

void local_store_request::init(const std::string& parameters,
                               const std::string& path, std::int32_t media,
                               const std::string& media_folder) {}

//------------------------------------------------------------------------------
// set origin
//------------------------------------------------------------------------------

void local_store_request::set_origin(const std::string& id,
                                     const std::string& name,
                                     const std::string& ip) {}

//------------------------------------------------------------------------------
// import file
//------------------------------------------------------------------------------

void local_store_request::import_file(request_database* db,
                                      const std::string& partition_seq,
                                      Json::Value* output,
                                      std::uint32_t* output_flags) {}

//------------------------------------------------------------------------------
// cleanup
//------------------------------------------------------------------------------

void local_store_request::cleanup() {}