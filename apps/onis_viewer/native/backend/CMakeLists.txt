cmake_minimum_required(VERSION 3.15)
project(onis_backend LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(onis_backend SHARED
  src/onis_backend.cpp
)

target_include_directories(onis_backend
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

if(MSVC)
  target_compile_options(onis_backend PRIVATE /W4)
else()
  target_compile_options(onis_backend PRIVATE -Wall -Wextra -Wpedantic)
endif()
