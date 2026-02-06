#cmake_minimum_required (VERSION 3.8)

#if(MSVC)

#    add_definitions(-D_AFXDLL)

#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_DEBUG            ${CMAKE_C_FLAGS_DEBUG})
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_MINSIZEREL       ${CMAKE_C_FLAGS_MINSIZEREL})
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_RELEASE          ${CMAKE_C_FLAGS_RELEASE})
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_RELWITHDEBINFO   ${CMAKE_C_FLAGS_RELWITHDEBINFO})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_DEBUG          ${CMAKE_CXX_FLAGS_DEBUG})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_MINSIZEREL     ${CMAKE_CXX_FLAGS_MINSIZEREL})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_RELEASE        ${CMAKE_CXX_FLAGS_RELEASE})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_RELWITHDEBINFO ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})

#    include_directories("C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/include")
#    include_directories("C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/atlmfc/in#clude")
#    include_directories("C:/Program Files (x86)/Windows Kits/10/Include/10.0.10240.0/ucrt")
#    include_directories("C:/Program Files (x86)/Windows Kits/8.1/Include/um")
#    include_directories("C:/Program Files (x86)/Windows Kits/8.1/Include/shared")
#    include_directories("C:/Program Files (x86)/Windows Kits/8.1/Include/winrt")

#    include_directories("C:/Users/CEDRIC/Developments/visual studio/onis4/lib/boost_1_69_0")
    #include_directories("D:/visual studio/onis4/lib/openssl/openssl-1.0.2h-vs2015/include64")

#else(MSVC)

#    add_definitions(-D_ONIS_FOR_LINUX_)
#    include_directories("/home/parallels/Documents/boost_1_69_0")
#    include_directories("./")
    #add_executable (dcmtk ${FILE_SOURCES})
    #add_library(ijg8 STATIC ${FILE_SOURCES})
    #target_include_directories(ijg8 PRIVATE ${FILE_INCLUDE_DIRS})

#endif(MSVC)

add_library(onis_j2k_kit STATIC 
    "buffer_stream.cpp" 
    "decoder.cpp" 
    "encoder.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/bio.cpp"  
    "openjpeg-2.0.0/src/lib/openjp2/cio.cpp"  
    "openjpeg-2.0.0/src/lib/openjp2/dwt.cpp"  
    "openjpeg-2.0.0/src/lib/openjp2/event.cpp"  
    "openjpeg-2.0.0/src/lib/openjp2/function_list.cpp"  
    "openjpeg-2.0.0/src/lib/openjp2/image.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/invert.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/j2k.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/jp2.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/mct.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/mqc.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/openjpeg.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/opj_clock.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/pi.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/raw.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/t1.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/t2.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/tcd.cpp" 
    "openjpeg-2.0.0/src/lib/openjp2/tgt.cpp" 
)

target_include_directories(onis_j2k_kit PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/public
    ${CMAKE_CURRENT_SOURCE_DIR}/../../onis_kit/include
)

target_precompile_headers(onis_j2k_kit
  PUBLIC
    precompiled_header.hpp
  #PRIVATE
  #  [[]]
)