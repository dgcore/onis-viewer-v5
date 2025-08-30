#pragma once

#include <list>
#include <memory>
#include "./types.hpp"

namespace dgc {

///////////////////////////////////////////////////////////////////////////////
// object class
///////////////////////////////////////////////////////////////////////////////

class object {
public:
  object() {}
  virtual ~object() {}
};

typedef std::shared_ptr<object> object_ptr;
typedef std::weak_ptr<object> object_wptr;
typedef std::list<object_ptr> object_list;

}  // namespace dgc