cmake_minimum_required(VERSION 3.20)
project(runner LANGUAGES CXX)

set(BINARY_NAME "onis_viewer")

# Add the shared C++ library
add_library(onis_core SHARED
  ../../../shared/cpp/onis_core/onis_core.cpp
  ../../../shared/cpp/onis_core/onis_core.h
)

set_target_properties(onis_core PROPERTIES
  VERSION 5.0.0
  SOVERSION 5
  OUTPUT_NAME "onis_core"
)

target_include_directories(onis_core PUBLIC
  ../../../shared/cpp/onis_core
)

target_compile_definitions(onis_core PRIVATE
  ONIS_CORE_EXPORTS
)

# Link the shared library to the main executable
target_link_libraries(${BINARY_NAME} PRIVATE onis_core) 