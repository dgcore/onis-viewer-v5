
#include "../../include/dicom/dicom.hpp"

namespace onis {

///////////////////////////////////////////////////////////////////////
// image_region
///////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------
// static constructor
//-----------------------------------------------------------------------

frame_region_ptr frame_region::create() {
  return std::make_shared<frame_region>();
}

//-----------------------------------------------------------------------
// operators
//-----------------------------------------------------------------------

bool frame_region::operator==(const frame_region& other) const {
  if (this == &other)
    return true;

  if (spatial_format != other.spatial_format)
    return false;
  if (data_type != other.data_type)
    return false;
  if (original_spacing[0] != other.original_spacing[0])
    return false;
  if (original_spacing[1] != other.original_spacing[1])
    return false;
  if (original_unit[0] != other.original_unit[0])
    return false;
  if (original_unit[1] != other.original_unit[1])
    return false;
  if (calibrated_spacing[0] != other.calibrated_spacing[0])
    return false;
  if (calibrated_spacing[1] != other.calibrated_spacing[1])
    return false;
  if (calibrated_unit[0] != other.calibrated_unit[0])
    return false;
  if (calibrated_unit[1] != other.calibrated_unit[1])
    return false;
  if (x0 != other.x0)
    return false;
  if (x1 != other.x1)
    return false;
  if (y0 != other.y0)
    return false;
  if (y1 != other.y1)
    return false;
  return true;
}

bool frame_region::operator!=(const frame_region& other) const {
  return !operator==(other);
}

//-----------------------------------------------------------------------
// clone
//-----------------------------------------------------------------------

frame_region_ptr frame_region::clone() const {
  frame_region_ptr copy = frame_region::create();

  copy->original_spacing[0] = original_spacing[0];
  copy->original_spacing[1] = original_spacing[1];
  copy->original_unit[0] = original_unit[0];
  copy->original_unit[1] = original_unit[1];
  copy->calibrated_spacing[0] = calibrated_spacing[0];
  copy->calibrated_spacing[1] = calibrated_spacing[1];
  copy->calibrated_unit[0] = calibrated_unit[0];
  copy->calibrated_unit[1] = calibrated_unit[1];
  copy->x0 = x0;
  copy->x1 = x1;
  copy->y0 = y0;
  copy->y1 = y1;
  return copy;
}

///////////////////////////////////////////////////////////////////////
// frame_region_info
///////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------
// static constructor
//-----------------------------------------------------------------------

frame_region_info_ptr frame_region_info::create() {
  return std::make_shared<frame_region_info>();
}

//-----------------------------------------------------------------------
// clone
//-----------------------------------------------------------------------

frame_region_info_ptr frame_region_info::clone() const {
  frame_region_info_ptr copy = frame_region_info::create();
  copy->dimensions[0] = dimensions[0];
  copy->dimensions[1] = dimensions[1];
  for (auto& region : regions) {
    frame_region_ptr rg = region->clone();
    if (rg != nullptr)
      copy->regions.push_back(rg);
  }
  return copy;
}

}  // namespace onis
