cmake_minimum_required(VERSION 3.20)
project(onis_kit VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Debug configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0")
    message(STATUS "Building onis_kit in Debug mode with symbols")
endif()

# Source files
set(ONIS_KIT_SOURCES
    src/core/result.cpp
)

# Header files
set(ONIS_KIT_HEADERS
    public/core/result.hpp
    public/core/object.hpp
    public/core/types.hpp
)

# Create shared library
add_library(onis_kit SHARED
    ${ONIS_KIT_SOURCES}
    ${ONIS_KIT_HEADERS}
)

# Set library properties
set_target_properties(onis_kit PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    PUBLIC_HEADER "${ONIS_KIT_HEADERS}"
)

# Include directories
target_include_directories(onis_kit PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/public>
    $<INSTALL_INTERFACE:include/onis_kit>
)

# Compiler definitions
target_compile_definitions(onis_kit PRIVATE
    ONIS_KIT_LIBRARY
)

# Installation
install(TARGETS onis_kit
    EXPORT onis_kitTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    PUBLIC_HEADER DESTINATION include/onis_kit
)

# Export targets
install(EXPORT onis_kitTargets
    FILE onis_kitTargets.cmake
    NAMESPACE onis_kit::
    DESTINATION lib/cmake/onis_kit
) 