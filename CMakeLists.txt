cmake_minimum_required(VERSION 3.20)
project(ONIS5 VERSION 5.0.0 LANGUAGES C CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Compiler flags
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Find required packages
find_package(PkgConfig REQUIRED)

# External libraries configuration
option(BUILD_DCMTK "Build DCMTK library" ON)
option(BUILD_BOOST "Build Boost libraries" ON)
option(BUILD_ONIS_CORE "Build ONIS Core library" ON)

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/shared/cpp
    ${CMAKE_SOURCE_DIR}/libs
)

# Add subdirectories
if(BUILD_ONIS_CORE)
    add_subdirectory(shared/cpp/onis_core)
endif()

# Add onis_kit library
if(EXISTS "${CMAKE_SOURCE_DIR}/libs/onis_kit")
    add_subdirectory(libs/onis_kit)
endif()

# Add DICOM libraries (must be built before site server)
if(EXISTS "${CMAKE_SOURCE_DIR}/libs/dicom")
    # Build dependencies first (DCMTK depends on these)
    if(EXISTS "${CMAKE_SOURCE_DIR}/libs/dicom/ijg8")
        add_subdirectory(libs/dicom/ijg8)
    endif()
    if(EXISTS "${CMAKE_SOURCE_DIR}/libs/dicom/ijg12")
        add_subdirectory(libs/dicom/ijg12)
    endif()
    if(EXISTS "${CMAKE_SOURCE_DIR}/libs/dicom/ijg16")
        add_subdirectory(libs/dicom/ijg16)
    endif()
    if(EXISTS "${CMAKE_SOURCE_DIR}/libs/dicom/iconv")
        add_subdirectory(libs/dicom/iconv)
    endif()
    if(EXISTS "${CMAKE_SOURCE_DIR}/libs/dicom/onis_j2k_kit")
        add_subdirectory(libs/dicom/onis_j2k_kit)
    endif()
    # Build DCMTK (depends on ijg8, ijg12, ijg16, onis_j2k_kit)
    if(EXISTS "${CMAKE_SOURCE_DIR}/libs/dicom/dcmtk-3.6.0")
        add_subdirectory(libs/dicom/dcmtk-3.6.0)
    endif()
endif()

# Add applications
if(EXISTS "${CMAKE_SOURCE_DIR}/apps/onis_site_server")
    add_subdirectory(apps/onis_site_server)
endif()

# External libraries setup
if(BUILD_DCMTK)
    # DCMTK configuration will be added here
    message(STATUS "DCMTK: Will be configured")
endif()

if(BUILD_BOOST)
    # Boost configuration will be added here
    message(STATUS "Boost: Will be configured")
endif()

# Print configuration summary
message(STATUS "ONIS5 Configuration:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Build DCMTK: ${BUILD_DCMTK}")
message(STATUS "  Build Boost: ${BUILD_BOOST}")
message(STATUS "  Build ONIS Core: ${BUILD_ONIS_CORE}") 