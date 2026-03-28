# vvdecConfigVersion.cmake - checks version: major must match, minor must be less than or equal

set( PACKAGE_VERSION 3.0.0 )

if( "${PACKAGE_FIND_VERSION_MAJOR}" EQUAL "3" )
  if( "${PACKAGE_FIND_VERSION_MINOR}" EQUAL "0" )
    set( PACKAGE_VERSION_EXACT TRUE )
  elseif( "${PACKAGE_FIND_VERSION_MINOR}" LESS "0" )
     set( PACKAGE_VERSION_COMPATIBLE TRUE )
  else()
    set( PACKAGE_VERSION_UNSUITABLE TRUE )
  endif()
else()
  set( PACKAGE_VERSION_UNSUITABLE TRUE )
endif()
