#include "../../include/core/thread.hpp"
#include <iostream>
namespace onis {

//----------------------------------------------------------------------------
// Contructor and destructor
//----------------------------------------------------------------------------

thread::thread() : message_event_() {
  thread_ = nullptr;
  will_quit_ = false;
}

thread::~thread() {
  stop();
}

//----------------------------------------------------------------------------
// Main thread control
//----------------------------------------------------------------------------

bool thread::run() {
  std::lock_guard<std::recursive_mutex> lock(_message_mutex);
  if (thread_)
    return false;
  will_quit_ = false;
  thread_ = std::make_unique<std::thread>(event_loop, this);
  return true;
}

void thread::stop() {
  {
    std::lock_guard<std::recursive_mutex> lock(_message_mutex);
    if (thread_ == nullptr)
      return;
    if (will_quit_) {
      throw std::logic_error(
          "Thread::stop() called more than once or concurrently.");
    }
    post_message_tothread_(DGMSG_QUIT, 0, 0);
    will_quit_ = true;
  }
  thread_->join();
  {
    std::lock_guard<std::recursive_mutex> lock(_message_mutex);
    thread_.reset();
    will_quit_ = false;
    timers_.clear();
  }
}

bool thread::is_running() {
  std::lock_guard<std::recursive_mutex> lock(_message_mutex);
  return thread_ != nullptr;
}

//----------------------------------------------------------------------------
// Event loop
//----------------------------------------------------------------------------

void thread::event_loop(thread* thiz) {
  // Init Instance:
  thiz->init_instance();
  // process the event loop:
  while (1) {
    bool lastMessage = false;
    // Wait for a message:
    thiz->message_event_.wait();
    // Retrieve the message to proceed:
    message* msg = nullptr;
    {
      std::lock_guard<std::recursive_mutex> lock(thiz->_message_mutex);
      if (!thiz->messages_.empty()) {
        msg = thiz->messages_.front();
        thiz->messages_.pop();
      }
      if (thiz->messages_.empty()) {
        // no more message to proceed, reset the event:
        lastMessage = true;
        thiz->message_event_.reset();
      }
    }

    // Process the message:
    if (msg) {
      if (msg->id == DGMSG_QUIT) {
        delete msg;
        break;
      } else if (msg->id == DGMSG_IDLE) {
        if (thiz->on_idle())
          thiz->post_message_tothread_(DGMSG_IDLE, 0, 0);
      } else if (msg->id == DGMSG_TIMER) {
        bool ignore = false;
        {
          std::lock_guard<std::recursive_mutex> lock(thiz->_message_mutex);
          bool found = false;
          auto it = thiz->timers_.find(msg->wParam);
          if (it != thiz->timers_.end()) {
            timer_info* timer = it->second;
            if (timer) {
              found = true;
              timer->pending = false;
              break;
            }
          }
          if (!found)
            ignore = true;
        }
        if (!ignore)
          thiz->on_timer((std::uint8_t)msg->wParam);
      } else {
        thiz->process_message(msg->id, msg->wParam, msg->lParam);
        if (lastMessage)
          thiz->post_message_tothread_(DGMSG_IDLE, 0, 0);
      }
      delete msg;
    }
  }
  // exit the instance:
  thiz->exit_instance();

  // clean up the timers:
  std::lock_guard<std::recursive_mutex> lock(thiz->_message_mutex);
  while (!thiz->timers_.empty()) {
    auto it = thiz->timers_.begin();
    thiz->kill_timer(it->first);
  }
}

//----------------------------------------------------------------------------
// Lifecycle hooks
//----------------------------------------------------------------------------

void thread::init_instance() {}

void thread::exit_instance() {}

//----------------------------------------------------------------------------
// Messaging
//----------------------------------------------------------------------------

void thread::process_message(std::uint32_t message_id, std::uint64_t wParam,
                             std::uint64_t lParam) {}

bool thread::on_idle() {
  return false;
}

bool thread::post_message_tothread_(std::uint32_t id, std::uint64_t wParam,
                                    std::uint64_t lParam) {
  std::lock_guard<std::recursive_mutex> lock(_message_mutex);
  if (thread_ == nullptr || will_quit_)
    return false;
  if (id == DGMSG_TIMER) {
    auto it = timers_.find(wParam);
    if (it != timers_.end()) {
      timer_info* timer = it->second;
      if (timer->pending)
        return true;
      timer->pending = true;
    } else {
      return false;
    }
  }
  messages_.push(new message{id, wParam, lParam});
  message_event_.signal();
  return true;
}

std::uint64_t thread::get_pending_message_count() {
  std::lock_guard<std::recursive_mutex> lock(_message_mutex);
  return messages_.size();
}

//----------------------------------------------------------------------------
// Timers
//----------------------------------------------------------------------------

bool thread::set_timer(std::uint8_t id, std::uint32_t millisec) {
  std::lock_guard<std::recursive_mutex> lock(_message_mutex);

  // Prevent duplicates
  auto it = timers_.find(id);
  if (it != timers_.end())
    return false;

  auto* timer = new timer_info{id,
                               std::chrono::milliseconds(millisec),
                               false,  // pending
                               false,  // should_quit
                               std::thread(),
                               std::mutex(),
                               std::condition_variable_any()};

  timer->thread = std::thread([this, timer]() {
    std::unique_lock<std::mutex> lock(timer->mutex);
    while (!timer->should_quit) {
      // Wait until timeout or quit requested
      if (timer->cond.wait_for(lock, timer->duration,
                               [&] { return timer->should_quit; }))
        break;

      // Timeout occurred and not quitting
      if (!timer->should_quit) {
        this->post_message_tothread_(DGMSG_TIMER, timer->id,
                                     reinterpret_cast<std::uint64_t>(timer));
      }
    }
  });

  timers_.insert({id, timer});
  return true;
}

bool thread::kill_timer(std::uint8_t id) {
  std::lock_guard<std::recursive_mutex> lock(_message_mutex);
  auto it = timers_.find(id);
  if (it == timers_.end())
    return false;
  timer_info* timer = it->second;

  {
    // Signal the timer thread to stop
    std::lock_guard<std::mutex> timer_lock(timer->mutex);
    timer->should_quit = true;
    timer->cond.notify_all();  // Interrupt wait_for()
  }

  // Join the thread to ensure it's stopped
  if (timer->thread.joinable()) {
    timer->thread.join();
  }

  // Clean up
  delete timer;
  timers_.erase(it);

  return true;
}

void thread::on_timer(std::uint8_t timer_id) {}

}  // namespace onis