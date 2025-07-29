#pragma once

#include "./types.hpp"
#include <list>
#include <memory>

namespace dgc {

//////////////////////////////////////////////////////////////////////////////////////////////
// object class
//////////////////////////////////////////////////////////////////////////////////////////////

class object {
public:
  object() {}
  virtual ~object() {}
};

typedef std::shared_ptr<object> object_ptr;
typedef std::weak_ptr<object> object_wptr;
typedef std::list<object_ptr> object_list;

} // namespace dgc