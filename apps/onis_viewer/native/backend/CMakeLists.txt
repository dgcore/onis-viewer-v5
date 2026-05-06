cmake_minimum_required(VERSION 3.20)

# Prefer repo root when this target is built via the top-level ONIS5 CMakeLists.txt.
if(EXISTS "${CMAKE_SOURCE_DIR}/libs/onis_kit/CMakeLists.txt")
    set(ONIS_ROOT "${CMAKE_SOURCE_DIR}")
else()
    get_filename_component(ONIS_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../.." ABSOLUTE)
endif()

project(onis_backend LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(PNG REQUIRED)

add_library(onis_backend SHARED
    src/onis_backend.cpp
    ${ONIS_ROOT}/shared/cpp/dicom/dicom_dcmtk.cpp
)

target_include_directories(onis_backend
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE
        ${ONIS_ROOT}/shared/cpp
        ${ONIS_ROOT}/libs/onis_kit/include
        ${ONIS_ROOT}/libs
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/config/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/dcmdata/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/dcmimage/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/dcmimgle/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/dcmjpeg/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/dcmjpls/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/dcmnet/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/dcmpstat/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/dcmsr/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/ofstd/include
        ${ONIS_ROOT}/libs/dicom/dcmtk-3.6.0/oflog/include
        ${ONIS_ROOT}/libs/dicom/iconv/include
        ${ONIS_ROOT}/libs/dicom/onis_j2k_kit/public
        ${ONIS_ROOT}/shared/cpp/dicom
)

target_link_directories(onis_backend PRIVATE
    "${CMAKE_BINARY_DIR}/lib"
)

target_link_libraries(onis_backend PRIVATE
    onis_core
    onis_kit
    dcmtk-3.6.0
    ijg8
    ijg12
    ijg16
    iconv
    onis_j2k_kit
    PNG::PNG
)

target_compile_definitions(onis_backend PRIVATE
    USE_STD_CXX_INCLUDES
    HAVE_STD_NAMESPACE
    HAVE_SSTREAM
    HAVE_CLASS_TEMPLATE
    HAVE_STL
    HAVE_STDIO_H
)

if(APPLE)
    target_compile_definitions(onis_backend PRIVATE ONIS_FOR_MAC)
endif()

if(MSVC)
    target_compile_options(onis_backend PRIVATE /W4)
else()
    target_compile_options(onis_backend PRIVATE -Wall -Wextra -Wpedantic)
endif()

set_target_properties(onis_backend PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)
