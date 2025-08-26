// Test file to demonstrate onis_kit include paths
// This file shows how to include onis_kit headers in the onis_site_server app

#include <iostream>

// Test include for onis_kit headers
// With the current CMakeLists.txt setup, you should be able to include:
#include "onis_kit/include/core/result.hpp"
#include "onis_kit/include/core/thread.hpp"
#include "onis_kit/include/core/types.hpp"

int main() {
  std::cout << "Testing onis_kit include paths..." << std::endl;

  // Test that the headers are accessible
  std::cout << "Successfully included onis_kit headers!" << std::endl;

  return 0;
}