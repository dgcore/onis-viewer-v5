#include <iostream>
#include <string>
#include "../include/network/drogon/drogon_http_server.hpp"
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/core/thread.hpp"

////////////////////////////////////////////////////////////////////////////////
// main_thread class
////////////////////////////////////////////////////////////////////////////////

class main_thread : public dgc::thread {
public:
  main_thread() : thread() {}

  ~main_thread() {}

  void init_instance() {
    dgc::thread::init_instance();
    _drogon_http_server = drogon_http_server::create(/*_rqsrv*/);
    _drogon_http_server->run();
    // drogon server will exit the application if it encounters a problem
    // to avoid crash, we pause the application here:
    std::this_thread::sleep_for(std::chrono::milliseconds(3));
  }

  void exit_instance() {
    if (_drogon_http_server != NULL)
      _drogon_http_server->stop();
    dgc::thread::exit_instance();
  }

protected:
  drogon_http_server_ptr _drogon_http_server;
};

int main() {
  std::cout << "Starting process..." << std::endl;
  std::cout << "Initialize app..." << std::endl;
  main_thread th;
  th.run();
  std::cout << "Hit a key to stop the server" << std::endl;
  char cp_Buf[256];
  std::cin >> cp_Buf;
  th.stop();
  std::cout << "Process ended" << std::endl;
  return 0;
}