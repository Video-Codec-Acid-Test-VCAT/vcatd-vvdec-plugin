cmake_minimum_required(VERSION 3.22)
project(vcat_vvdec_jni LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

if(NOT ANDROID)
    message(FATAL_ERROR "Android/NDK build only")
endif()

# =========================
# Per-ABI install roots
# =========================
if(${ANDROID_ABI} STREQUAL "arm64-v8a")
    set(VVDEC_INSTALL_DIR "${VVDEC_INSTALL_ARM64_V8A}")
elseif(${ANDROID_ABI} STREQUAL "armeabi-v7a")
    set(VVDEC_INSTALL_DIR "${VVDEC_INSTALL_ARMEABI_V7A}")
else()
    message(FATAL_ERROR "Unsupported ABI: ${ANDROID_ABI}")
endif()

message(STATUS "ABI='${ANDROID_ABI}'")
message(STATUS "  VVDEC_INSTALL_DIR='${VVDEC_INSTALL_DIR}'")

# =========================
# vvdec (required)
# =========================
set(VVDEC_INCLUDE_DIR "${VVDEC_INSTALL_DIR}/include")
set(VVDEC_LIB_DIR     "${VVDEC_INSTALL_DIR}/lib")
set(VVDEC_STATIC      "${VVDEC_LIB_DIR}/libvvdec.a")

if(NOT EXISTS "${VVDEC_STATIC}")
    message(FATAL_ERROR "Static vvdec not found: ${VVDEC_STATIC}")
endif()

# =========================
# Sources
# =========================
add_library(vcat_vvdec_jni SHARED vvdec_jni.cc)

target_include_directories(vcat_vvdec_jni PRIVATE "${VVDEC_INCLUDE_DIR}")

find_library(log_lib     log)
find_library(android_lib android)

target_link_libraries(vcat_vvdec_jni
        PRIVATE
        "${VVDEC_STATIC}"
        ${log_lib}
        ${android_lib}
        c++_static
)

# 32-bit often needs libatomic
if(${ANDROID_ABI} STREQUAL "armeabi-v7a")
    find_library(atomic_lib atomic)
    if(atomic_lib)
        target_link_libraries(vcat_vvdec_jni PRIVATE ${atomic_lib})
    endif()
endif()

target_link_options(vcat_vvdec_jni PRIVATE -Wl,--no-undefined)
