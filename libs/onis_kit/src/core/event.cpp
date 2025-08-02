#include "../../public/core/event.hpp"

namespace dgc {

//-----------------------------------------------------------------------------
// event
//-----------------------------------------------------------------------------

event_ptr event::create_event() {
  return std::make_shared<event>();
}

event::event() {
  _is_signaled = false;
}

event::~event() {}

void event::reset() {
  std::lock_guard<std::mutex> lock(_mutex);
  _is_signaled = false;
}

void event::signal() {
  std::lock_guard<std::mutex> lock(_mutex);
  _is_signaled = true;
  _condition.notify_all();
}

bool event::wait(u32 millisec) {
  std::unique_lock<std::mutex> lock(_mutex);
  if (_is_signaled) {
    return true;
  }
  if (millisec == 0) {
    _condition.wait(lock, [this] { return _is_signaled; });
    return true;
  } else {
    return _condition.wait_for(lock, std::chrono::milliseconds(millisec),
                               [this] { return _is_signaled; });
  }
}

bool event::is_signaled() {
  std::lock_guard<std::mutex> lock(_mutex);
  return _is_signaled;
}

}  // namespace dgc