# ONIS Site Server CMakeLists.txt
cmake_minimum_required(VERSION 3.20)

project(onis_site_server VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Debug configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0")
    message(STATUS "Building in Debug mode with symbols")
endif()

# Libraries are already added in the root CMakeLists.txt

# Find Drogon and dependencies (installed via Homebrew)
set(DROGON_ROOT "/opt/homebrew/opt/drogon")
set(DROGON_INCLUDE_DIRS "${DROGON_ROOT}/include")
set(DROGON_LIBRARIES "${DROGON_ROOT}/lib/libdrogon.dylib" "${DROGON_ROOT}/lib/libtrantor.dylib")

# Find JsonCPP (required by Drogon)
set(JSONCPP_ROOT "/opt/homebrew/opt/jsoncpp")
set(JSONCPP_INCLUDE_DIRS "${JSONCPP_ROOT}/include")
set(JSONCPP_LIBRARIES "${JSONCPP_ROOT}/lib/libjsoncpp.dylib")

# Using JsonCPP only (required by Drogon)

# Find OpenSSL (required by jwt-cpp)
# Try Homebrew OpenSSL first (common on macOS)
if(EXISTS "/opt/homebrew/opt/openssl")
    set(OPENSSL_ROOT_DIR "/opt/homebrew/opt/openssl")
elseif(EXISTS "/usr/local/opt/openssl")
    set(OPENSSL_ROOT_DIR "/usr/local/opt/openssl")
endif()
find_package(OpenSSL REQUIRED)

# Find jwt-cpp
include(FetchContent)
FetchContent_Declare(
  jwt-cpp
  GIT_REPOSITORY https://github.com/Thalhammer/jwt-cpp.git
  GIT_TAG v0.7.0
)
FetchContent_MakeAvailable(jwt-cpp)

# Source files
set(SERVER_SOURCES
    src/main.cpp
    src/site_api.cpp
    src/network/drogon/drogon_http_server.cpp
    src/network/drogon/drogon_http_controller.cpp
    src/services/requests/request_data.cpp
    src/services/requests/request_service.cpp
    src/services/requests/request_service_authenticate.cpp
    src/services/requests/request_find_studies.cpp
    src/services/requests/request_import_dicom_file.cpp
    src/services/requests/sessions/request_session.cpp
    src/services/requests/request_database.cpp
    src/services/requests/sessions/request_session_access_cache.cpp
    src/services/requests/store/local_store_request.cpp
    src/services/config/config_service.cpp
    src/database/site_database.cpp
    src/database/site_database_compression.cpp
    src/database/site_database_organization.cpp
    src/database/site_database_permission.cpp
    src/database/site_database_site.cpp
    src/database/site_database_volume.cpp
    src/database/site_database_media.cpp
    src/database/site_database_role.cpp
    src/database/site_database_group.cpp
    src/database/site_database_user.cpp
    src/database/site_database_partition.cpp
    src/database/site_database_album.cpp
    src/database/site_database_smart_album.cpp
    src/database/site_database_patient.cpp
    src/database/site_database_study.cpp
    src/database/site_database_series.cpp
    src/database/site_database_image.cpp
    src/database/site_database_image.cpp
    src/database/sql_builder.cpp
    src/database/site_database_pool.cpp

    ../../shared/cpp/dicom/dicom_dcmtk.cpp
)

set(SERVER_HEADERS
)

# Create executable
add_executable(onis_site_server
    ${SERVER_SOURCES}
    ${SERVER_HEADERS}
)

# Get the project root directory - CMAKE_SOURCE_DIR is the root of the source tree
# Since this is a subdirectory, CMAKE_SOURCE_DIR points to the root CMakeLists.txt location
set(PROJECT_ROOT "${CMAKE_SOURCE_DIR}")

# Include directories
target_include_directories(onis_site_server PRIVATE
    ${CMAKE_SOURCE_DIR}/shared/cpp
    ${CMAKE_SOURCE_DIR}/../../libs/onis_kit/include
    ${CMAKE_SOURCE_DIR}/../../libs
    ${CMAKE_SOURCE_DIR}/include
    "/Applications/Postgres.app/Contents/Versions/15/include"
    ${DROGON_INCLUDE_DIRS}
    ${JSONCPP_INCLUDE_DIRS}
    ${jwt-cpp_SOURCE_DIR}/include
    # DICOM library includes - DCMTK headers use paths like "dcmtk/dcmdata/..."
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/config/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/dcmdata/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/dcmimage/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/dcmimgle/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/dcmjpeg/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/dcmjpls/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/dcmnet/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/dcmpstat/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/dcmsr/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/ofstd/include
    ${PROJECT_ROOT}/libs/dicom/dcmtk-3.6.0/oflog/include
    ${PROJECT_ROOT}/libs/dicom/iconv/include
    ${PROJECT_ROOT}/libs/dicom/onis_j2k_kit/public
    # Shared DICOM implementation
    ${PROJECT_ROOT}/shared/cpp/dicom
)

# Link libraries
target_link_libraries(onis_site_server PRIVATE
    onis_core
    onis_kit
    pq
    ${DROGON_LIBRARIES}
    ${JSONCPP_LIBRARIES}
    OpenSSL::SSL
    OpenSSL::Crypto
    jwt-cpp::jwt-cpp
    # DICOM libraries
    dcmtk-3.6.0
    ijg8
    ijg12
    ijg16
    iconv
    onis_j2k_kit
)

# Add library search directories
target_link_directories(onis_site_server PRIVATE
    ${CMAKE_SOURCE_DIR}/../../build/lib
    ${CMAKE_SOURCE_DIR}/../../libs/onis_kit/build
    "/Applications/Postgres.app/Contents/Versions/15/lib"
    # DICOM libraries will be built in the build directory
)

# Compiler definitions
target_compile_definitions(onis_site_server PRIVATE
    ONIS_SITE_SERVER
    # DCMTK requires these definitions to use modern C++ headers
    USE_STD_CXX_INCLUDES
    HAVE_STD_NAMESPACE
    HAVE_SSTREAM
    HAVE_CLASS_TEMPLATE
    HAVE_STL
    HAVE_STDIO_H
    ONIS_FOR_MAC
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

# Copy certificates
install(DIRECTORY certificates/
    DESTINATION etc/onis_site_server/certificates
    FILES_MATCHING PATTERN "*.crt" PATTERN "*.key"
) 