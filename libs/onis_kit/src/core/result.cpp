#include "../../public/core/result.hpp"

namespace dgc {

//---------------------------------------------------------------------
// Constructor
//---------------------------------------------------------------------

result::result() {
  status = OSRSP_SUCCESS;
  reason = EOS_NONE;
}

//---------------------------------------------------------------------
// Destructor
//---------------------------------------------------------------------

result::~result() {}

//---------------------------------------------------------------------
// Properties
//---------------------------------------------------------------------

b32 result::good() const { return status == OSRSP_SUCCESS ? OSTRUE : OSFALSE; }

b32 result::bad() const { return status == OSRSP_SUCCESS ? OSFALSE : OSTRUE; }

//---------------------------------------------------------------------
// Operations
//---------------------------------------------------------------------

void result::set(s32 status, s32 reason, const std::string &info, b32 force) {
  if (!force && this->status != OSRSP_SUCCESS) {
    return;
  }
  this->status = status;
  this->reason = reason;
  this->info = info;
}

} // namespace dgc