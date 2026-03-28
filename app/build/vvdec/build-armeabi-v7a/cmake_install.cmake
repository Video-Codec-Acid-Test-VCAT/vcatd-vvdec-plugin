# Install script for directory: /Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/src

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/install-armeabi-v7a")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "0")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/Users/davidronca/Library/Android/sdk/ndk/27.0.12077973/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/source/Lib/vvdec/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/source/App/vvdecapp/cmake_install.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/vvdec" TYPE FILE FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/vvdec/version.h")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include" TYPE DIRECTORY FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/src/include/vvdec")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  message( NOTICE "The vvdecapp binary is not installed by default any more. To also install vvdecapp set '-DVVDEC_INSTALL_VVDECAPP=ON' (with make: 'install-vvdecapp=1')" )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/src/lib/release-static/libvvdec.a")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/src/lib/release-static/libvvdec.a")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/src/lib/release-static/libvvdec.a")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/src/lib/release-static/libvvdec.a")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec" TYPE FILE FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/src/cmake/install/vvdecConfig.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec" TYPE FILE FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/vvdecConfigVersion.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake")
      file(DIFFERENT _cmake_export_file_changed FILES
           "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake"
           "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/CMakeFiles/Export/fd1c8426dfa2fe80b9245600e429799b/vvdecTargets-static.cmake")
      if(_cmake_export_file_changed)
        file(GLOB _cmake_old_config_files "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static-*.cmake")
        if(_cmake_old_config_files)
          string(REPLACE ";" ", " _cmake_old_config_files_text "${_cmake_old_config_files}")
          message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake\" will be replaced.  Removing files [${_cmake_old_config_files_text}].")
          unset(_cmake_old_config_files_text)
          file(REMOVE ${_cmake_old_config_files})
        endif()
        unset(_cmake_old_config_files)
      endif()
      unset(_cmake_export_file_changed)
    endif()
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec" TYPE FILE FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/CMakeFiles/Export/fd1c8426dfa2fe80b9245600e429799b/vvdecTargets-static.cmake")
  endif()
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec" TYPE FILE FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/CMakeFiles/Export/fd1c8426dfa2fe80b9245600e429799b/vvdecTargets-static-release.cmake")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake")
      file(DIFFERENT _cmake_export_file_changed FILES
           "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake"
           "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/CMakeFiles/Export/fd1c8426dfa2fe80b9245600e429799b/vvdecTargets-static.cmake")
      if(_cmake_export_file_changed)
        file(GLOB _cmake_old_config_files "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static-*.cmake")
        if(_cmake_old_config_files)
          string(REPLACE ";" ", " _cmake_old_config_files_text "${_cmake_old_config_files}")
          message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake\" will be replaced.  Removing files [${_cmake_old_config_files_text}].")
          unset(_cmake_old_config_files_text)
          file(REMOVE ${_cmake_old_config_files})
        endif()
        unset(_cmake_old_config_files)
      endif()
      unset(_cmake_export_file_changed)
    endif()
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec" TYPE FILE FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/CMakeFiles/Export/fd1c8426dfa2fe80b9245600e429799b/vvdecTargets-static.cmake")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake")
      file(DIFFERENT _cmake_export_file_changed FILES
           "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake"
           "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/CMakeFiles/Export/fd1c8426dfa2fe80b9245600e429799b/vvdecTargets-static.cmake")
      if(_cmake_export_file_changed)
        file(GLOB _cmake_old_config_files "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static-*.cmake")
        if(_cmake_old_config_files)
          string(REPLACE ";" ", " _cmake_old_config_files_text "${_cmake_old_config_files}")
          message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake\" will be replaced.  Removing files [${_cmake_old_config_files_text}].")
          unset(_cmake_old_config_files_text)
          file(REMOVE ${_cmake_old_config_files})
        endif()
        unset(_cmake_old_config_files)
      endif()
      unset(_cmake_export_file_changed)
    endif()
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec" TYPE FILE FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/CMakeFiles/Export/fd1c8426dfa2fe80b9245600e429799b/vvdecTargets-static.cmake")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake")
      file(DIFFERENT _cmake_export_file_changed FILES
           "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake"
           "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/CMakeFiles/Export/fd1c8426dfa2fe80b9245600e429799b/vvdecTargets-static.cmake")
      if(_cmake_export_file_changed)
        file(GLOB _cmake_old_config_files "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static-*.cmake")
        if(_cmake_old_config_files)
          string(REPLACE ";" ", " _cmake_old_config_files_text "${_cmake_old_config_files}")
          message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec/vvdecTargets-static.cmake\" will be replaced.  Removing files [${_cmake_old_config_files_text}].")
          unset(_cmake_old_config_files_text)
          file(REMOVE ${_cmake_old_config_files})
        endif()
        unset(_cmake_old_config_files)
      endif()
      unset(_cmake_export_file_changed)
    endif()
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/vvdec" TYPE FILE FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/CMakeFiles/Export/fd1c8426dfa2fe80b9245600e429799b/vvdecTargets-static.cmake")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig" TYPE FILE FILES "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/pkgconfig/libvvdec.pc")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
if(CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_COMPONENT MATCHES "^[a-zA-Z0-9_.+-]+$")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
  else()
    string(MD5 CMAKE_INST_COMP_HASH "${CMAKE_INSTALL_COMPONENT}")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INST_COMP_HASH}.txt")
    unset(CMAKE_INST_COMP_HASH)
  endif()
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/davidronca/AndroidStudioProjects/vcatd-vvdec-plugin/app/build/vvdec/build-armeabi-v7a/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
