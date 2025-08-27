#pragma once

#include <drogon/drogon.h>
#include <memory>
#include "../../../include/services/requests/request_service.hpp"
#include "./drogon_http_controller.hpp"
#include "onis_kit/include/core/thread.hpp"

using namespace dgc;

////////////////////////////////////////////////////////////////////////////////
// drogon_http_server
////////////////////////////////////////////////////////////////////////////////

class drogon_http_server;
typedef std::shared_ptr<drogon_http_server> drogon_http_server_ptr;
typedef std::weak_ptr<drogon_http_server> drogon_http_server_wptr;

class drogon_http_server : public dgc::thread {
public:
  static drogon_http_server_ptr create(const request_service_ptr& srv);

  drogon_http_server(const request_service_ptr& srv);
  ~drogon_http_server();

  // init / exit:
  void init_instance();
  void exit_instance();

  // properties:
  request_service_ptr get_request_service() const;

protected:
  static void worker_thread(drogon_http_server* server,
                            http_drogon_controller_ptr controller);

  std::thread th_;
  request_service_ptr rqsrv_;
  http_drogon_controller_ptr controller_;
};