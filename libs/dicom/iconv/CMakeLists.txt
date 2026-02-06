cmake_minimum_required(VERSION 3.8)

#if(MSVC)
#    
#    add_definitions(-D_AFXDLL)
#    add_definitions(-D_WINDOWS)
#    add_definitions(-D_USRDLL)
#    add_definitions(-DICONV_EXPORTS)
#    add_definitions(-DBUILDING_LIBICONV)
#    add_definitions(-DBUILDING_LIBCHARSET)
#    add_definitions(-DUNICODE)
#    add_definitions(-D_UNICODE)
#    
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_DEBUG            ${CMAKE_C_FLAGS_DEBUG})
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_MINSIZEREL       ${CMAKE_C_FLAGS_MINSIZEREL})
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_RELEASE          ${CMAKE_C_FLAGS_RELEASE})
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_RELWITHDEBINFO   ${CMAKE_C_FLAGS_RELWITHDEBINFO})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_DEBUG          ${CMAKE_CXX_FLAGS_DEBUG})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_MINSIZEREL     ${CMAKE_CXX_FLAGS_MINSIZEREL})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_RELEASE        ${CMAKE_CXX_FLAGS_RELEASE})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_RELWITHDEBINFO ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
#
#    include_directories("./include")
#
#else(MSVC)
#
#    add_definitions(-D_ONIS_FOR_LINUX_)
#    add_definitions(-DICONV_EXPORTS)
#    add_definitions(-DBUILDING_LIBICONV)
#    add_definitions(-DBUILDING_LIBCHARSET)
#
#    include_directories("./include")
#    #add_executable (dcmtk ${FILE_SOURCES})
#    #add_library(ijg8 SHARED ${FILE_SOURCES})
#    #target_include_directories(ijg8 PRIVATE ${FILE_INCLUDE_DIRS})
#
#endif(MSVC)


add_library(iconv SHARED 
    "iconv.c" 
    "localcharset.c" 
    "relocatable.c" 
)

target_include_directories(iconv PRIVATE . include)

