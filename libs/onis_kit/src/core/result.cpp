#include "../../include/core/result.hpp"

namespace onis {

//-----------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------

result::result() {
  status = OSRSP_SUCCESS;
  reason = EOS_NONE;
}

//-----------------------------------------------------------------------------
// Destructor
//-----------------------------------------------------------------------------

result::~result() {}

//-----------------------------------------------------------------------------
// Properties
//-----------------------------------------------------------------------------

bool result::good() const {
  return status == OSRSP_SUCCESS;
}

//-----------------------------------------------------------------------------
// Operations
//-----------------------------------------------------------------------------

void result::set(std::int32_t status, std::int32_t reason,
                 const std::string& info, bool force) {
  if (!force && this->status != OSRSP_SUCCESS) {
    return;
  }
  this->status = status;
  this->reason = reason;
  this->info = info;
}

}  // namespace onis