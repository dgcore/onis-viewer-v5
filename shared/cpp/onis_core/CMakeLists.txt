# ONIS Core Library CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(onis_core VERSION 5.0.0)

set(ONIS_CORE_SOURCES
    onis_core.cpp
)

set(ONIS_CORE_HEADERS
    onis_core.h
)

# Create shared library
add_library(onis_core SHARED
    ${ONIS_CORE_SOURCES}
    ${ONIS_CORE_HEADERS}
)

# Set library properties
set_target_properties(onis_core PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION 5
    OUTPUT_NAME "onis_core"
)

# Include directories
target_include_directories(onis_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include/onis_core>
)

# Compiler definitions
target_compile_definitions(onis_core PRIVATE
    ONIS_CORE_EXPORTS
)

# Link libraries (will be added as needed)
# target_link_libraries(onis_core PRIVATE
#     ${DCMTK_LIBRARIES}
#     ${BOOST_LIBRARIES}
# )

# Installation
install(TARGETS onis_core
    EXPORT ONIS5Targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES ${ONIS_CORE_HEADERS}
    DESTINATION include/onis_core
)

# Export targets
install(EXPORT ONIS5Targets
    FILE ONIS5Targets.cmake
    NAMESPACE ONIS5::
    DESTINATION lib/cmake/ONIS5
) 