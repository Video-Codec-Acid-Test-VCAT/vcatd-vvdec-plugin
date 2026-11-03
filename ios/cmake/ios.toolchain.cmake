# Minimal, project-owned CMake toolchain file for cross-compiling vvdec to iOS/iOS Simulator
# (see ios/build_xcframework.sh, which invokes this). Deliberately small -- only what vvdec's own
# CMakeLists.txt actually needs (confirmed against vcatd-vvdec-plugin's app/build.gradle, which
# passes BUILD_SHARED_LIBS=OFF, VVDEC_ENABLE_TRACING=OFF, CMAKE_BUILD_TYPE=Release,
# CMAKE_INSTALL_PREFIX -- nothing here is speculative). Not a vendored third-party toolchain
# file (e.g. leetal/ios-cmake) -- a deliberate choice to keep this fully under project control
# and easy to audit, at the cost of needing our own iteration if an edge case turns up.
#
# Invoke with -DPLATFORM=OS64 (device, iphoneos) or -DPLATFORM=SIMULATORARM64
# (iphonesimulator) and -DDEPLOYMENT_TARGET=<iOS deployment target>, set by
# ios/build_xcframework.sh, per platform slice.

set(CMAKE_SYSTEM_NAME iOS)

if(NOT DEFINED DEPLOYMENT_TARGET)
    set(DEPLOYMENT_TARGET "17.0")
endif()
set(CMAKE_SYSTEM_VERSION "${DEPLOYMENT_TARGET}")
set(CMAKE_OSX_DEPLOYMENT_TARGET "${DEPLOYMENT_TARGET}" CACHE STRING "" FORCE)

if(NOT DEFINED PLATFORM)
    set(PLATFORM "OS64")
endif()

if(PLATFORM STREQUAL "OS64")
    # Real device -- arm64 only, matches this project's own TARGETED_DEVICE_FAMILY/arch set.
    set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "" FORCE)
    execute_process(
        COMMAND xcrun --sdk iphoneos --show-sdk-path
        OUTPUT_VARIABLE CMAKE_OSX_SYSROOT OUTPUT_STRIP_TRAILING_WHITESPACE
    )
elseif(PLATFORM STREQUAL "SIMULATORARM64")
    # Apple Silicon Simulator -- the only simulator arch this project's own toolchain targets
    # (matches build_dav1d.sh, which is also arm64-only for iphonesimulator).
    set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "" FORCE)
    execute_process(
        COMMAND xcrun --sdk iphonesimulator --show-sdk-path
        OUTPUT_VARIABLE CMAKE_OSX_SYSROOT OUTPUT_STRIP_TRAILING_WHITESPACE
    )
else()
    message(FATAL_ERROR "ios.toolchain.cmake: unsupported PLATFORM '${PLATFORM}' (expected OS64 or SIMULATORARM64)")
endif()

set(CMAKE_C_COMPILER   "clang")
set(CMAKE_CXX_COMPILER "clang++")

# Cross-compiling: look for libraries/headers only in the sysroot, never the host's own
# /usr/lib etc., but still allow finding host CMake programs (e.g. a generator-expression
# helper) on PATH.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
