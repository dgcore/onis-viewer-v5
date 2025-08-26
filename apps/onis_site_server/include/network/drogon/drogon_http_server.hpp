#pragma once

#include <memory>
#include "onis_kit/include/core/thread.hpp"
// #include <drogon/drogon.h>
// #include "drogon_http_controller.hpp"

using namespace dgc;

///////////////////////////////////////////////////////////////////////
// drogon_http_server
///////////////////////////////////////////////////////////////////////

class drogon_http_server;
typedef std::shared_ptr<drogon_http_server> drogon_http_server_ptr;
typedef std::weak_ptr<drogon_http_server> drogon_http_server_wptr;

class drogon_http_server : public dgc::thread {
public:
  static drogon_http_server_ptr create(/*const request_service_ptr& srv*/);

  drogon_http_server(/*const request_service_ptr& srv*/);
  ~drogon_http_server();

  // init / exit:
  void init_instance();
  void exit_instance();

  // operations:
  /*u32 get_next_websocket_message_id();
  void broadcast_message(const std::string &msg);*/

  // properties:
  // u32 get_port();
  // request_service_ptr get_request_service();

protected:
  // static void worker_thread(drogon_http_server *server,
  // http_drogon_controller_ptr controller, mjpeg_drogon_controller_ptr
  // mjpeg_controller, websocket_drogon_controller_ptr websocket_controller);

  // std::thread th_;
  // request_service_ptr rqsrv_;
  // http_drogon_controller_ptr controller_;
  // mjpeg_drogon_controller_ptr mjpeg_controller_;
  // websocket_drogon_controller_ptr websocket_controller_;
  // std::recursive_mutex msg_mutex_;
  // u32 message_id_;
  // u32 port_;
  // u32 thread_count_;
};