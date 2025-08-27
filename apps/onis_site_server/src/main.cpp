#include <iostream>
#include <string>
#include "../include/network/drogon/drogon_http_server.hpp"
#include "../include/services/requests/request_service.hpp"
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/core/thread.hpp"

////////////////////////////////////////////////////////////////////////////////
// main_thread class
////////////////////////////////////////////////////////////////////////////////

class main_thread : public dgc::thread {
public:
  main_thread() : thread() {
    std::cout << "Main thread constructor" << std::endl;
  }

  ~main_thread() {}

  void init_instance() {
    dgc::thread::init_instance();
    rqsrv_ = request_service::create();
    drogon_http_server_ = drogon_http_server::create(rqsrv_);
    drogon_http_server_->run();
    // drogon server will exit the application if it encounters a problem
    // to avoid crash, we pause the application here:
    std::this_thread::sleep_for(std::chrono::milliseconds(3));
  }

  void exit_instance() {
    if (drogon_http_server_ != nullptr) {
      drogon_http_server_->stop();
    }
    dgc::thread::exit_instance();
  }

private:
  drogon_http_server_ptr drogon_http_server_;
  request_service_ptr rqsrv_;
};

int main() {
  std::cout << "Starting process..." << std::endl;
  std::cout << "Initialize app..." << std::endl;
  main_thread th;
  th.run();
  std::cout << "Hit a key to stop the server" << std::endl;
  char cp_Buf[256];
  std::cin >> cp_Buf;
  std::cout << "Ending process..." << std::endl;
  th.stop();
  std::cout << "Process ended" << std::endl;
  return 0;
}