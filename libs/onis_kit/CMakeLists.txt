cmake_minimum_required(VERSION 3.20)
project(onis_kit VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(PkgConfig REQUIRED)

# PostgreSQL paths for Postgres.app installation
set(POSTGRESQL_INCLUDE_DIRS "/Applications/Postgres.app/Contents/Versions/15/include")
set(POSTGRESQL_LIBRARY_DIRS "/Applications/Postgres.app/Contents/Versions/15/lib")
set(POSTGRESQL_LIBRARIES "pq")

# Find SQLite3
pkg_check_modules(SQLITE3 REQUIRED sqlite3)

# Debug configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0")
    message(STATUS "Building onis_kit in Debug mode with symbols")
endif()

# Source files
set(ONIS_KIT_SOURCES
    src/core/result.cpp
    src/core/thread.cpp
    src/core/event.cpp
    src/core/date_time.cpp
    src/dicom/dicom.cpp
    src/database/postgresql/postgresql_connection.cpp
    src/database/postgresql/postgresql_query.cpp
    src/database/postgresql/postgresql_result.cpp
    src/database/sqlite/sqlite_connection.cpp
    src/database/sqlite/sqlite_query.cpp
    src/database/sqlite/sqlite_result.cpp
    src/utilities/uuid.cpp
    src/utilities/regex.cpp
    src/utilities/string.cpp
    src/utilities/dicom.cpp
    src/utilities/filesystem.cpp
    src/utilities/date_time.cpp
)

# Header files
set(ONIS_KIT_HEADERS
    include/core/result.hpp
    include/core/object.hpp
    include/core/thread.hpp
    include/core/event.hpp
    include/dicom/dicom.hpp
    include/database/database_interface.hpp
    include/database/postgresql/postgresql.hpp
    include/database/postgresql/postgresql_connection.hpp
    include/database/postgresql/postgresql_query.hpp
    include/database/postgresql/postgresql_result.hpp
    include/database/sqlite/sqlite.hpp
    include/database/sqlite/sqlite_connection.hpp
    include/database/sqlite/sqlite_query.hpp
    include/database/sqlite/sqlite_result.hpp
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
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include/onis_kit>
    ${POSTGRESQL_INCLUDE_DIRS}
    ${SQLITE3_INCLUDE_DIRS}
)

# Add iconv include directory for string conversion functions
# This ensures the libiconv header is used instead of system iconv.h
if(TARGET iconv)
    target_include_directories(onis_kit PRIVATE
        ${CMAKE_SOURCE_DIR}/libs/dicom/iconv/include
    )
endif()

# Compiler definitions
target_compile_definitions(onis_kit PRIVATE
    ONIS_KIT_LIBRARY
)

# Link libraries
target_link_libraries(onis_kit PRIVATE
    ${POSTGRESQL_LIBRARIES}
    ${SQLITE3_LIBRARIES}
    iconv  # Required for string conversion functions (built in libs/dicom/iconv)
)

# Add library directories
target_link_directories(onis_kit PRIVATE
    ${POSTGRESQL_LIBRARY_DIRS}
    ${SQLITE3_LIBRARY_DIRS}
)

# Installation
install(TARGETS onis_kit
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    PUBLIC_HEADER DESTINATION include/onis_kit
)

# Export targets (commented out due to iconv dependency export issue)
# install(EXPORT onis_kitTargets
#     FILE onis_kitTargets.cmake
#     NAMESPACE onis_kit::
#     DESTINATION lib/cmake/onis_kit
# ) 