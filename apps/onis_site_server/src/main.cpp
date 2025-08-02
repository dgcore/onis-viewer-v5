#include <iostream>
#include <string>
#include "core/result.hpp"

int main(int argc, char* argv[]) {
  std::cout << "ONIS Site Server v1.0.0" << std::endl;
  std::cout << "Simple console application" << std::endl;

  // Test onis_kit library
  dgc::result test_result;
  std::cout << "Testing onis_kit library..." << std::endl;
  std::cout << "Initial result status: "
            << (test_result.good() ? "GOOD" : "BAD") << std::endl;

  // Test setting an error
  test_result.set(OSRSP_FAILURE, EOS_NETWORK_CONNECTION, "Test network error",
                  true);
  std::cout << "After setting error - status: "
            << (test_result.good() ? "GOOD" : "BAD") << std::endl;
  std::cout << "Error info: " << test_result.info << std::endl;

  return 0;
}