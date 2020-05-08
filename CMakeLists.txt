
cmake_minimum_required(VERSION 3.15.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(Yams
  LANGUAGES C Swift)

option(BUILD_SHARED_LIBS "build shared libraries" ON)

if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(USE_CORELIBS_FOUNDATION FALSE)
else()
  set(USE_CORELIBS_FOUNDATION TRUE)
endif()

if(USE_CORELIBS_FOUNDATION)
  find_package(Foundation CONFIG REQUIRED)
  set(CORELIBS_FOUNDATION "Foundation")
else()
  set(CORELIBS_FOUNDATION "")
endif()

include(SwiftSupport)

add_subdirectory(Sources)
add_subdirectory(cmake/modules)
