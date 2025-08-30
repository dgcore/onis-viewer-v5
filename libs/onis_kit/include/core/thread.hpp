#pragma once

#include <condition_variable>
#include <memory>
#include <mutex>
#include <queue>
#include <thread>
#include <unordered_map>

#include "./event.hpp"
#include "./types.hpp"

#define DGMSG_COMMAND 10
#define DGMSG_TIMER 15
#define DGMSG_IDLE 254
#define DGMSG_QUIT 255

namespace dgc {

//-----------------------------------------------------------------------------
// message
//-----------------------------------------------------------------------------

struct message {
  u32 id;
  u64 wParam;
  u64 lParam;
};

//-----------------------------------------------------------------------------
// timer_info
//-----------------------------------------------------------------------------

struct timer_info {
  u8 id;
  std::chrono::microseconds duration;
  bool pending;
  bool should_quit;
  std::thread thread;
  std::mutex mutex;
  std::condition_variable_any cond;
};

//-----------------------------------------------------------------------------
// thread
//-----------------------------------------------------------------------------

class thread : public std::enable_shared_from_this<thread> {
public:
  thread();
  virtual ~thread();
  thread& operator=(const thread&) = delete;
  thread(const thread&) = delete;

  virtual bool run();
  virtual void stop();
  virtual void init_instance();
  virtual void exit_instance();
  bool is_running();
  virtual void process_message(u32 id, u64 wParam, u64 lParam);
  virtual bool post_message_tothread_(u32 id, u64 wParam, u64 lParam);
  virtual bool on_idle();
  virtual bool set_timer(u8 timer_id, u32 milliSec);
  virtual bool kill_timer(u8 timer_id);
  virtual void on_timer(u8 timer_id);
  u64 get_pending_message_count();

private:
  std::queue<message*> messages_;
  std::unordered_map<u8, timer_info*> timers_;
  std::unique_ptr<std::thread> thread_;
  std::recursive_mutex _message_mutex;
  event message_event_;
  bool will_quit_;
  static void event_loop(thread* thiz);
};

}  // namespace dgc