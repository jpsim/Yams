
cmake_minimum_required(VERSION 3.15.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(Yams
  LANGUAGES C Swift)

option(BUILD_SHARED_LIBS "build shared libraries" ON)

find_package(dispatch CONFIG QUIET)
find_package(Foundation CONFIG QUIET)

if(CMAKE_VERSION VERSION_LESS 3.16 AND CMAKE_SYSTEM_NAME STREQUAL Windows)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
else()
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
endif()
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/swift)

include(SwiftSupport)

add_subdirectory(Sources)
add_subdirectory(cmake/modules)
