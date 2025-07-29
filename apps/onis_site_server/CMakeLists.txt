# ONIS Site Server CMakeLists.txt
cmake_minimum_required(VERSION 3.20)

project(onis_site_server VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Debug configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0")
    message(STATUS "Building in Debug mode with symbols")
endif()

# Add the shared C++ library first
add_subdirectory(${CMAKE_SOURCE_DIR}/../../shared/cpp/onis_core ${CMAKE_BINARY_DIR}/onis_core)

# Source files
set(SERVER_SOURCES
    src/main.cpp
    src/server.cpp
    src/dicom_handler.cpp
)

set(SERVER_HEADERS
    include/server.h
    include/dicom_handler.h
)

# Create executable
add_executable(onis_site_server
    ${SERVER_SOURCES}
    ${SERVER_HEADERS}
)

# Include directories
target_include_directories(onis_site_server PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/shared/cpp
)

# Link libraries
target_link_libraries(onis_site_server PRIVATE
    onis_core
    # Add other libraries as needed:
    # ${DCMTK_LIBRARIES}
    # ${BOOST_LIBRARIES}
)

# Compiler definitions
target_compile_definitions(onis_site_server PRIVATE
    ONIS_SITE_SERVER
)

# Installation
install(TARGETS onis_site_server
    RUNTIME DESTINATION bin
)

# Copy configuration files
install(DIRECTORY config/
    DESTINATION etc/onis_site_server
    FILES_MATCHING PATTERN "*.conf" PATTERN "*.json"
) 