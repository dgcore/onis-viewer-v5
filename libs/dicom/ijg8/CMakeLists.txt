cmake_minimum_required (VERSION 3.8)

#if(MSVC)
#
#    add_definitions(-D_AFXDLL)
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
#else(MSVC)
#    add_definitions(-D_ONIS_FOR_LINUX_)
#endif(MSVC)


include_directories("../dcmtk-3.6.0/config/include")

add_library(ijg8 STATIC 
    "jaricom.c" 
    "jaricom.c" 
    "jcapimin.c" 
    "jcapistd.c" 
    "jcarith.c" 
    "jccoefct.c" 
    "jccolor.c" 
    "jcdctmgr.c" 
    "jcdiffct.c" 
    "jchuff.c" 
    "jcinit.c" 
    "jclhuff.c" 
    "jclossls.c" 
    "jclossy.c" 
    "jcmainct.c" 
    "jcmarker.c" 
    "jcmaster.c" 
    "jcodec.c" 
    "jcomapi.c" 
    "jcparam.c" 
    "jcphuff.c" 
    "jcpred.c" 
    "jcprepct.c" 
    "jcsample.c" 
    "jcscale.c" 
    "jcshuff.c" 
    "jctrans.c" 
    "jdapimin.c" 
    "jdapistd.c" 
    "jdarith.c" 
    "jdatadst.c" 
    "jdatasrc.c" 
    "jdcoefct.c" 
    "jdcolor.c" 
    "jddctmgr.c" 
    "jddiffct.c" 
    "jdhuff.c" 
    "jdinput.c" 
    "jdlhuff.c" 
    "jdlossls.c" 
    "jdlossy.c" 
    "jdmainct.c" 
    "jdmarker.c" 
    "jdmaster.c" 
    "jdmerge.c" 
    "jdphuff.c" 
    "jdpostct.c" 
    "jdpred.c" 
    "jdsample.c" 
    "jdscale.c" 
    "jdshuff.c" 
    "jdtrans.c" 
    "jerror.c" 
    "jfdctflt.c" 
    "jfdctfst.c" 
    "jfdctint.c" 
    "jidctflt.c" 
    "jidctfst.c" 
    "jidctint.c" 
    "jidctred.c" 
    "jmemmgr.c" 
    "jmemnobs.c" 
    "jquant1.c" 
    "jquant2.c" 
    "jutils.c"
)

# Define C_INLINE for inline functions in C
target_compile_definitions(ijg8 PRIVATE C_INLINE=inline)
# Allow implicit function declarations for legacy C code
if(CMAKE_C_COMPILER_ID STREQUAL "Clang" OR CMAKE_C_COMPILER_ID STREQUAL "GNU")
    target_compile_options(ijg8 PRIVATE -Wno-error=implicit-function-declaration -Wno-implicit-function-declaration)
endif()

