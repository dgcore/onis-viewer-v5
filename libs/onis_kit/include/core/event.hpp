#pragma once

#include <condition_variable>
#include <memory>
#include <mutex>

#include "./types.hpp"

namespace onis {

//////////////////////////////////////////////////////////////////////////////////////////////
// event class
//////////////////////////////////////////////////////////////////////////////////////////////

class event;
typedef std::shared_ptr<event> event_ptr;

class event : public std::enable_shared_from_this<event> {
public:
  static event_ptr create_event();
  event();
  ~event();
  event& operator=(const event&) = delete;
  event(const event&) = delete;

  void reset();
  void signal();
  bool wait(std::uint32_t millisec = 0);
  bool is_signaled();

private:
  bool _is_signaled;
  std::mutex _mutex;
  std::condition_variable _condition;
};

}  // namespace onis