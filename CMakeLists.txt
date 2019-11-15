
cmake_minimum_required(VERSION 3.15.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(Yams
  LANGUAGES C Swift)

option(BUILD_SHARED_LIBS "build shared libraries" ON)

find_package(Foundation CONFIG REQUIRED)

include(SwiftSupport)

add_subdirectory(Sources)
add_subdirectory(cmake/modules)
